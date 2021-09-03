local MAJOR_VERSION = "LibGearPoints-1.2"
local MINOR_VERSION = 20502

--- @class LibGearPoints
local lib, _ = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

local Logging, ItemUtil, BabbleInv =
    LibStub("LibLogging-1.0"), LibStub("LibItemUtil-1.1"), LibStub("LibBabble-Inventory-3.0"):GetReverseLookupTable()

-- Allows for specification of an alternative function for string repr
local ToStringFn = function(x) return x end
function lib:SetToStringFn(fn) ToStringFn = fn end

-- The default quality threshold, below which no GP will be calculated
-- 0 - Poor
-- 1 - Uncommon
-- 2 - Common
-- 3 - Rare
-- 4 - Epic
-- 5 - Legendary
-- 6 - Artifact
local QualityThreshold = 4
-- Set the minimum quality threshold.
-- @param itemQuality Lowest allowed item quality.
function lib:SetQualityThreshold(itemQuality)
    itemQuality = itemQuality and tonumber(itemQuality)
    if not itemQuality or itemQuality > 6 or itemQuality < 0 then
        error("Usage: SetQualityThreshold(itemQuality): 'itemQuality' - number [0,6].", 3)
    end

    QualityThreshold = itemQuality
end

function lib:GetQualityThreshold()
    return QualityThreshold
end

-- inputs for GP formula, initialized with defaults
local FormulaInputs = {
    Base = nil,
    CoefficientBase = nil,
    ItemLevelDivisor = 26,
    ItemRaritySubtrahend = 4,
    Multiplier = nil
}

-- base, coefficientBase, multiplier
function lib:GetFormulaInputs()
    return FormulaInputs.Base, FormulaInputs.CoefficientBase, FormulaInputs.Multiplier
end

-- base : the base GP value
-- coefficientBase : the base for calculating coefficient
-- multiplier : the multiplier for GP
function lib:SetFormulaInputs(base, coefficientBase, multiplier)
    FormulaInputs.Base = base or FormulaInputs.Base
    FormulaInputs.CoefficientBase = coefficientBase or FormulaInputs.CoefficientBase
    FormulaInputs.Multiplier = multiplier or  FormulaInputs.Multiplier
end

function lib:ResetFormulaInputs()
    lib:SetFormulaInputs(4.8, 2.5, 1)
end

-- set them to defaults on initialization
lib:ResetFormulaInputs()

-- initialize the configuration for scaling values to empty
--[[
Format as follows, with ordering of tuples after equipment location dictating order (1, 2, 3, ..., N)
Comment does not need to be provided
A minimum of 1 entry per equipLoc is required

{
    equipLoc1 = {
        {scale, comment},
        {scale, comment},
        ...,
        {scale, comment},
    },
    ...
    equipLocN = {
        {scale, comment},
        {scale, comment},
        ...,
        {scale, comment},
    },
}

For example:

ScalingConfig = {
    weapon = {
        {1.5, 'Main Hand Weapon'},
        {0.5, 'Off Hand Weapon / Tank Main Hand Weapon'},
        {0.15, 'Hunter One Hand Weapon'},
    },
    ranged = {
        {2.0, 'Hunter Ranged'},
        {0.3, 'Non-Hunter Ranged'},
    }
}
--]]
local ScalingConfig = {}

function lib:GetScalingConfig()
    return ScalingConfig
end

function lib:SetScalingConfig(config)

    ScalingConfig = {}
    for k, v in pairs(config) do
        local equipLoc = k
        local scaling = v
        Logging:Trace("SetScalingConfig() : equipLoc=%s scaling=%s type=%s", equipLoc, ToStringFn(scaling), type(scaling))

        -- split by '_' to determine if this is a composite key containing location and one (or more) scaling values
        -- e.g. weaponmainh_scale_1, weaponmainh_comment_1
        -- this would be necessary if setting configuration from AceDB
        local parts = {strsplit('_', equipLoc)}
        if #parts == 1 then
            local entryType = type(scaling)
            if entryType == 'number' or entryType == 'table' then
                -- blech, this is assuming that if value is a number it is the only entry
                -- and it's the scale value w/ no comment
                if entryType == 'number' then scaling = {{scaling, nil}} end
                Logging:Trace("SetScalingConfig(SET) : equipLoc=%s scaling=%s", equipLoc, ToStringFn(scaling))
                ScalingConfig[equipLoc] = scaling
            else
                Logging:Warn("SetScalingConfig(IGNORE_1) : ignoring equipLoc=%s scaling=%s type=%s", equipLoc,  ToStringFn(scaling), type(scaling))
            end
        elseif #parts == 3 then
            -- index #1 is the equipment location
            equipLoc = parts[1]
            -- index #2 is the name of the value in the tuple (e.g. comment 'name' or scale 'name')
            local tupleIndexName = parts[2]
            local tupleIndex
            if      tupleIndexName == 'scale'   then tupleIndex = 1
            elseif  tupleIndexName == 'comment' then tupleIndex = 2
            else
                Logging:Warn("SetScalingConfig(IGNORE_3) : Ignoring equipLoc=%s tupleIndexName=%s", equipLoc, tupleIndexName)
                tupleIndex = -1
            end

            if tupleIndex > 0 then
                -- index #3 is the order of the tuple in table (e.g. 1 = first priority, 2 = second priority)
                local priority = tonumber(parts[3])
                -- table of all tuples associated with equipment location
                scaling = ScalingConfig[equipLoc] or {}
                -- tuple at the specified priority
                local scalingTuple = scaling[priority] or {}
                scalingTuple[tupleIndex] = config[k]
                -- assign the tuple to specified priority in table
                scaling[priority] = scalingTuple
                Logging:Trace("SetScalingConfig(SET) : equipLoc=%s scaling=%s", equipLoc, ToStringFn(scaling))
                -- now set configuration for equipment location to scaling data
                ScalingConfig[equipLoc] = scaling
            end
        else
            Logging:Warn("SetScalingConfig(IGNORE_%s) : ignoring equipLoc=%s", #parts, equipLoc)
        end
    end
end

function lib:ResetScalingConfig()
    ScalingConfig = {}
end

-- These are mappings from the non-localized token identifying an item's equipment location to the key (prefix) used
-- for specifying scaling value for GP calculation [see GetScale()]
-- https://wowwiki.fandom.com/wiki/ItemEquipLoc
--
-- Also, there are entries that aren't strict equipment locations but mappings from
-- english translation of sub-type for cases where we refine further than equipment location
-- https://wow.gamepedia.com/ItemType
local EquipmentLocationMappings = {
    ["INVTYPE_HEAD"]            = "head",
    ["INVTYPE_NECK"]            = "neck",
    ["INVTYPE_SHOULDER"]        = "shoulder",
    ["INVTYPE_CHEST"]           = "chest",
    ["INVTYPE_ROBE"]            = "chest",
    ["INVTYPE_WAIST"]           = "waist",
    ["INVTYPE_LEGS"]            = "legs",
    ["INVTYPE_FEET"]            = "feet",
    ["INVTYPE_WRIST"]           = "wrist",
    ["INVTYPE_HAND"]            = "hand",
    ["INVTYPE_FINGER"]          = "finger",
    ["INVTYPE_TRINKET"]         = "trinket",
    ["INVTYPE_CLOAK"]           = "cloak",
    ["INVTYPE_WEAPON"]          = "weapon",
    ["INVTYPE_SHIELD"]          = "shield",
    ["INVTYPE_2HWEAPON"]        = "weapon2H",
    ["INVTYPE_WEAPONMAINHAND"]  = "weaponMainH",
    ["INVTYPE_WEAPONOFFHAND"]   = "weaponOffH",
    ["INVTYPE_HOLDABLE"]        = "holdable",
    ["INVTYPE_RANGED"]          = "ranged",
    ["INVTYPE_THROWN"]          = "ranged",
    ["INVTYPE_RELIC"]           = "relic",
    ["INVTYPE_WAND"]            = "wand",
    -- From here down are english representations of GetItemSubClassInfo calls for ranged sub-classes
    -- See GearPoints.lua
    ["Bows"]                    = "ranged",         -- GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_BOWS)
    ["Guns"]                    = "ranged",         -- GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_GUNS)
    ["Crossbows"]               = "ranged",         -- GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_CROSSBOW)
    ["Wands"]                   = "wand",           -- GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_WAND)
    ["Thrown"]                  = "thrown",         -- GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_THROWN)
}

-- functions for obtaining scaling factor based upon item attributes
function lib:GetScaleKey(equipLoc, subClass)
    -- 1st try the equipment location
    -- if not present, then use english variation of localized sub-class to attempt next lookup
    local name = EquipmentLocationMappings[equipLoc] or EquipmentLocationMappings[BabbleInv[subClass]]
    if name then
        return string.lower(name)
    end
end

-- the arguments here should be itemEquipLoc (Non-localized token) and itemSubType (Localized name) from GetItemInfo()
function lib:GetScale(equipLoc, subClass)
    local name = self:GetScaleKey(equipLoc, subClass)
    Logging:Trace("GearPoints.GetScale(%s, %s) -> %s",
                  tostring(equipLoc), tostring(subClass), tostring(name)
    )
    if name then
        -- configuration supports multiple scaling entries (factors), but current implementation only uses one
        -- that one being the first index
        local scale_config = ScalingConfig[name]

        Logging:Trace("GearPoints.GetScale(%s, %s, %s) -> %s",
                      tostring(equipLoc), tostring(subClass), tostring(name), ToStringFn(scale_config))

        if type(scale_config) == 'table' then
            return scale_config[1][1], scale_config[1][2]
        elseif type(scale_config) == 'number' then
            return scale_config, nil
        end
    end
end

-- calculate GP from scale, item level, and rarity
function lib:CalculateFromScale(scale, ilvl, rarity)
    -- Debug("GearPoints:CalculateGPFromScale(%s, %s, %s)", tostring(scale or 'nil'), tostring(ilvl), rarity)
    if not scale then return nil end
    local coefficient = (
            (FormulaInputs.CoefficientBase ^ (
                    (ilvl / FormulaInputs.ItemLevelDivisor) + (rarity - FormulaInputs.ItemRaritySubtrahend)
                )
            )
        * scale
    )
    return math.floor(FormulaInputs.Base * coefficient * FormulaInputs.Multiplier)
end

-- calculate GP from equipment location, sub-class, item level, and rarity
function lib:CalculateFromEquipmentLocation(equipLoc, subClass, ilvl, rarity)
    local scale, comment = self:GetScale(equipLoc, subClass)
    local gp = self:CalculateFromScale(scale, ilvl, rarity)
    return gp, comment, ilvl
end

-- calculates the GP for specified item
function lib:GetValue(item)
    Logging:Trace("GearPoints.GetValue(%s)", item)

    if not item then return end

    local _, itemLink, rarity, ilvl, _, _, itemSubClass, _, equipLoc = GetItemInfo(item)
    if not itemLink then return end

    -- Get the item ID to check against known token IDs
    local itemId = itemLink:match("item:(%d+)")
    if not itemId then return end
    itemId = tostring(itemId)

    -- Check to see if there is custom data for this item ID
    local customItem = ItemUtil:GetCustomItem(itemId)
    -- if gp_custom_config.enabled and gp_custom_config.custom_items then
    if customItem then
        Logging:Trace("GetValue(%s) : custom item found for item %s", item, itemId)
        --  1. rarity, int, 4 = epic
        --  2. ilvl, int
        --  3. inventory slot, string
        --  4. faction (Horde/Alliance), string
        rarity = customItem['rarity']
        ilvl = customItem['item_level']
        equipLoc = customItem['equip_location']
        Logging:Trace("GetValue(%s/%s) : rarity=%s, ilvl=%s, equipLoc=%s", item, itemId, rarity, ilvl, equipLoc)
    end

    -- Is the item above our minimum threshold?
    if not rarity or rarity < QualityThreshold then
        return nil, "Rarity below threshold", ilvl
    end

    if equipLoc == "CUSTOM_SCALE" then
        return self:CalculateFromScale(customItem.scale, ilvl, rarity), "Custom Scale", ilvl
    elseif equipLoc == "CUSTOM_GP" then
        return customItem.gp, "Custom GP", ilvl
    else
        return self:CalculateFromEquipmentLocation(equipLoc, itemSubClass, ilvl, rarity)
    end
end