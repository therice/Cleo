local MAJOR_VERSION = "LibItemUtil-1.1"
local MINOR_VERSION = 20502

--- @class LibItemUtil
local lib, _ = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

local AceEvent = LibStub("AceEvent-3.0")
AceEvent:Embed(lib)

-- Inventory types are localized on each client. For this we need LibBabble-Inventory to unlocalize the strings.
-- Establish the lookup table for localized to english words
--local BabbleInv = LibStub("LibBabble-Inventory-3.0"):GetReverseLookupTable()
local Deformat = LibStub("LibDeformat-3.0")
local Logging  = LibStub("LibLogging-1.0")

-- Use the GameTooltip or create a new one and initialize it
-- Used to extract Class limitations for an item, upgraded ilvl, and binding type.
lib.tooltip = lib.tooltip or CreateFrame("GameTooltip", MAJOR_VERSION .. "_TooltipParse", nil, "GameTooltipTemplate")
local tooltip = lib.tooltip
tooltip:SetOwner(UIParent, "ANCHOR_NONE")
tooltip:UnregisterAllEvents()
tooltip:Hide()

-- mapping of item ids to item names
-- for items which are related to reputation
lib.ReputationItems = {

}

-- mapping of item ids to equipment locations
-- for items which are obained via tokens
lib.TokenEquipmentLocations = {
}

-- mapping of item ids to item ids
-- for items which are obained via tokens
lib.TokenItems = {
}

-- https://wow.gamepedia.com/ItemType
local DisallowedByClass = {
    DRUID = {
        [LE_ITEM_CLASS_ARMOR] = {
            [LE_ITEM_ARMOR_MAIL] = true,
            [LE_ITEM_ARMOR_PLATE] = true,
            [LE_ITEM_ARMOR_SHIELD] = true,
            [LE_ITEM_ARMOR_LIBRAM] = true,
            [LE_ITEM_ARMOR_SIGIL] = true,
            [LE_ITEM_ARMOR_TOTEM] = true,
        },
        [LE_ITEM_CLASS_WEAPON] = {
            [LE_ITEM_WEAPON_BOWS] = true,
            [LE_ITEM_WEAPON_CROSSBOW] = true,
            [LE_ITEM_WEAPON_GUNS] = true,
            [LE_ITEM_WEAPON_AXE1H] = true,
            [LE_ITEM_WEAPON_SWORD1H] = true,
            [LE_ITEM_WEAPON_AXE2H] = true,
            [LE_ITEM_WEAPON_SWORD2H] = true,
            [LE_ITEM_WEAPON_WAND] = true,
            [LE_ITEM_WEAPON_THROWN]  = true,
        },
    },
    HUNTER = {
        [LE_ITEM_CLASS_ARMOR] = {
            [LE_ITEM_ARMOR_PLATE] = true,
            [LE_ITEM_ARMOR_SHIELD] = true,
            [LE_ITEM_ARMOR_IDOL] = true,
            [LE_ITEM_ARMOR_LIBRAM] = true,
            [LE_ITEM_ARMOR_SIGIL] = true,
            [LE_ITEM_ARMOR_TOTEM] = true,
        },
        [LE_ITEM_CLASS_WEAPON] = {
            [LE_ITEM_WEAPON_MACE1H] = true,
            [LE_ITEM_WEAPON_MACE2H] = true,
            [LE_ITEM_WEAPON_WAND] = true,
        },
    },
    MAGE = {
        [LE_ITEM_CLASS_ARMOR] = {
            [LE_ITEM_ARMOR_LEATHER] = true,
            [LE_ITEM_ARMOR_MAIL] = true,
            [LE_ITEM_ARMOR_PLATE] = true,
            [LE_ITEM_ARMOR_SHIELD] = true,
            [LE_ITEM_ARMOR_IDOL] = true,
            [LE_ITEM_ARMOR_LIBRAM] = true,
            [LE_ITEM_ARMOR_SIGIL] = true,
            [LE_ITEM_ARMOR_TOTEM] = true,
        },
        [LE_ITEM_CLASS_WEAPON] = {
            [LE_ITEM_WEAPON_BOWS] = true,
            [LE_ITEM_WEAPON_CROSSBOW] = true,
            [LE_ITEM_WEAPON_GUNS] = true,
            [LE_ITEM_WEAPON_UNARMED] = true,
            [LE_ITEM_WEAPON_AXE1H] = true,
            [LE_ITEM_WEAPON_MACE1H] = true,
            [LE_ITEM_WEAPON_POLEARM] = true,
            [LE_ITEM_WEAPON_AXE2H] = true,
            [LE_ITEM_WEAPON_MACE2H] = true,
            [LE_ITEM_WEAPON_SWORD2H] = true,
            [LE_ITEM_WEAPON_THROWN]  = true,
        },
    },
    PALADIN = {
        [LE_ITEM_CLASS_ARMOR] = {
            [LE_ITEM_ARMOR_IDOL] = true,
            [LE_ITEM_ARMOR_SIGIL] = true,
            [LE_ITEM_ARMOR_TOTEM] = true,

        },
        [LE_ITEM_CLASS_WEAPON] = {
            [LE_ITEM_WEAPON_BOWS] = true,
            [LE_ITEM_WEAPON_CROSSBOW] = true,
            [LE_ITEM_WEAPON_GUNS] = true,
            [LE_ITEM_WEAPON_UNARMED] = true,
            [LE_ITEM_WEAPON_STAFF] = true,
            [LE_ITEM_WEAPON_WAND] = true,
            [LE_ITEM_WEAPON_THROWN]  = true,
        },
    },
    PRIEST = {
        [LE_ITEM_CLASS_ARMOR] = {
            [LE_ITEM_ARMOR_LEATHER] = true,
            [LE_ITEM_ARMOR_MAIL] = true,
            [LE_ITEM_ARMOR_PLATE] = true,
            [LE_ITEM_ARMOR_SHIELD] = true,
            [LE_ITEM_ARMOR_IDOL] = true,
            [LE_ITEM_ARMOR_LIBRAM] = true,
            [LE_ITEM_ARMOR_SIGIL] = true,
            [LE_ITEM_ARMOR_TOTEM] = true,
        },
        [LE_ITEM_CLASS_WEAPON] = {
            [LE_ITEM_WEAPON_BOWS] = true,
            [LE_ITEM_WEAPON_CROSSBOW] = true,
            [LE_ITEM_WEAPON_GUNS] = true,
            [LE_ITEM_WEAPON_UNARMED] = true,
            [LE_ITEM_WEAPON_AXE1H] = true,
            [LE_ITEM_WEAPON_SWORD1H] = true,
            [LE_ITEM_WEAPON_POLEARM] = true,
            [LE_ITEM_WEAPON_AXE2H] = true,
            [LE_ITEM_WEAPON_MACE2H] = true,
            [LE_ITEM_WEAPON_SWORD2H] = true,
            [LE_ITEM_WEAPON_THROWN]  = true,
        },
    },
    ROGUE = {
        [LE_ITEM_CLASS_ARMOR] = {
            [LE_ITEM_ARMOR_MAIL] = true,
            [LE_ITEM_ARMOR_PLATE] = true,
            [LE_ITEM_ARMOR_SHIELD] = true,
            [LE_ITEM_ARMOR_IDOL] = true,
            [LE_ITEM_ARMOR_LIBRAM] = true,
            [LE_ITEM_ARMOR_SIGIL] = true,
            [LE_ITEM_ARMOR_TOTEM] = true,
        },
        [LE_ITEM_CLASS_WEAPON] = {
            [LE_ITEM_WEAPON_POLEARM] = true,
            [LE_ITEM_WEAPON_STAFF] = true,
            [LE_ITEM_WEAPON_AXE1H] = true,
            [LE_ITEM_WEAPON_AXE2H] = true,
            [LE_ITEM_WEAPON_MACE2H] = true,
            [LE_ITEM_WEAPON_SWORD2H] = true,
            [LE_ITEM_WEAPON_WAND] = true,
        },
    },
    SHAMAN = {
        [LE_ITEM_CLASS_ARMOR] = {
            [LE_ITEM_ARMOR_PLATE] = true,
            [LE_ITEM_ARMOR_IDOL] = true,
            [LE_ITEM_ARMOR_LIBRAM] = true,
            [LE_ITEM_ARMOR_SIGIL] = true,
        },
        [LE_ITEM_CLASS_WEAPON] = {
            [LE_ITEM_WEAPON_BOWS] = true,
            [LE_ITEM_WEAPON_CROSSBOW] = true,
            [LE_ITEM_WEAPON_GUNS] = true,
            [LE_ITEM_WEAPON_SWORD1H] = true,
            [LE_ITEM_WEAPON_POLEARM] = true,
            [LE_ITEM_WEAPON_SWORD2H] = true,
            [LE_ITEM_WEAPON_THROWN]  = true,
            [LE_ITEM_WEAPON_WAND] = true,
        },
    },
    WARLOCK = {
        [LE_ITEM_CLASS_ARMOR] = {
            [LE_ITEM_ARMOR_LEATHER] = true,
            [LE_ITEM_ARMOR_MAIL] = true,
            [LE_ITEM_ARMOR_PLATE] = true,
            [LE_ITEM_ARMOR_SHIELD] = true,
            [LE_ITEM_ARMOR_IDOL] = true,
            [LE_ITEM_ARMOR_LIBRAM] = true,
            [LE_ITEM_ARMOR_SIGIL] = true,
            [LE_ITEM_ARMOR_TOTEM] = true,
        },
        [LE_ITEM_CLASS_WEAPON] = {
            [LE_ITEM_WEAPON_BOWS] = true,
            [LE_ITEM_WEAPON_CROSSBOW] = true,
            [LE_ITEM_WEAPON_GUNS] = true,
            [LE_ITEM_WEAPON_UNARMED] = true,
            [LE_ITEM_WEAPON_AXE1H] = true,
            [LE_ITEM_WEAPON_MACE1H] = true,
            [LE_ITEM_WEAPON_POLEARM] = true,
            [LE_ITEM_WEAPON_AXE2H] = true,
            [LE_ITEM_WEAPON_MACE2H] = true,
            [LE_ITEM_WEAPON_SWORD2H] = true,
            [LE_ITEM_WEAPON_THROWN]  = true,

        },
    },
    WARRIOR = {
        [LE_ITEM_CLASS_ARMOR] = {
            [LE_ITEM_ARMOR_IDOL] = true,
            [LE_ITEM_ARMOR_LIBRAM] = true,
            [LE_ITEM_ARMOR_SIGIL] = true,
            [LE_ITEM_ARMOR_TOTEM] = true,
        },
        [LE_ITEM_CLASS_WEAPON] = {
            [LE_ITEM_WEAPON_WAND] = true,
        },
    },
}

local function GetNumClasses()
    return _G.MAX_CLASSES
end

lib.ClassDisplayNameToId = {}
lib.ClassTagNameToId = {}
lib.ClassIdToDisplayName = {}
lib.ClassIdToFileName = {}

do
    for i=1, GetNumClasses() do
        local info = C_CreatureInfo.GetClassInfo(i)
        -- could be nil
        if info then
            lib.ClassDisplayNameToId[info.className] = i
            lib.ClassTagNameToId[info.classFile] = i
        end
    end

    local druid = C_CreatureInfo.GetClassInfo(11)
    lib.ClassDisplayNameToId[druid.className] = 11
    lib.ClassTagNameToId[druid.classFile] = 11
end

lib.ClassIdToDisplayName = tInvert(lib.ClassDisplayNameToId)
lib.ClassIdToFileName = tInvert(lib.ClassTagNameToId)

function lib:ClassTransitiveMapping(class)
    if lib.ClassTagNameToId[class] ~= nil then
        return lib.ClassIdToDisplayName[lib.ClassTagNameToId[class]]
    elseif lib.ClassDisplayNameToId[class] ~= nil then
        return lib.ClassIdToFileName[lib.ClassDisplayNameToId[class]]
    else
       error("Could not find transitive mapping for " .. class)
    end
end

-- https://wowwiki-archive.fandom.com/wiki/ItemEquipLoc
-- https://wowwiki-archive.fandom.com/wiki/InventorySlotName
local EquipLocationToGearSlots = {
    INVTYPE_HEAD            = {"HeadSlot"},
    INVTYPE_NECK            = {"NeckSlot"},
    INVTYPE_SHOULDER        = {"ShoulderSlot"},
    INVTYPE_CLOAK           = {"BackSlot"},
    INVTYPE_CHEST           = {"ChestSlot"},
    INVTYPE_ROBE            = {"ChestSlot"},
    INVTYPE_WRIST           = {"WristSlot"},
    INVTYPE_HAND            = {"HandsSlot"},
    INVTYPE_WAIST           = {"WaistSlot"},
    INVTYPE_LEGS            = {"LegsSlot"},
    INVTYPE_FEET            = {"FeetSlot"},
    INVTYPE_SHIELD          = {"SecondaryHandSlot"},
    INVTYPE_ROBE            = {"ChestSlot"},
    INVTYPE_2HWEAPON        = {"MainHandSlot", "SecondaryHandSlot"},
    INVTYPE_WEAPONMAINHAND  = {"MainHandSlot"},
    INVTYPE_WEAPONOFFHAND   = {"SecondaryHandSlot", ["or"] = "MainHandSlot"},
    INVTYPE_WEAPON          = {"MainHandSlot", "SecondaryHandSlot"},
    INVTYPE_THROWN          = {"MainHandSlot", ["or"] = "SecondaryHandSlot"},
    INVTYPE_RANGED          = {"MainHandSlot", ["or"] = "SecondaryHandSlot"},
    INVTYPE_RANGEDRIGHT     = {"MainHandSlot", ["or"] = "SecondaryHandSlot"},
    INVTYPE_FINGER          = {"Finger0Slot", "Finger1Slot"},
    INVTYPE_HOLDABLE        = {"SecondaryHandSlot", ["or"] = "MainHandSlot"},
    INVTYPE_TRINKET         = {"Trinket0Slot", "Trinket1Slot"},
    INVTYPE_RELIC           = {"SecondaryHandSlot"},
}

-- @return a table containing corresponding gear slots (or nil if not found)
function lib:GetGearSlots(equipLoc)
    if not equipLoc then return nil end
    return EquipLocationToGearSlots[equipLoc]
end

-- Support for custom item definitions
--
-- keys are item ids and values are tuple where index is
--  1. rarity, int, 4 = epic
--  2. ilvl, int
--  3. inventory slot, string (supports special keywords such as CUSTOM_SCALE and CUSTOM_GP)
--  4. faction (Horde/Alliance), string
--[[
For example:

{
    -- Classic P2
    [18422] = { 4, 74, "INVTYPE_NECK", "Horde" },       -- Head of Onyxia
    [18423] = { 4, 74, "INVTYPE_NECK", "Alliance" },    -- Head of Onyxia
    -- Classic P5
    [20928] = { 4, 78, "INVTYPE_SHOULDER" },    -- T2.5 shoulder, feet (Qiraji Bindings of Command)
    [20932] = { 4, 78, "INVTYPE_SHOULDER" },    -- T2.5 shoulder, feet (Qiraji Bindings of Dominance)
}
--]]
local CustomItems = {}

function lib:GetCustomItems()
    return CustomItems
end

function lib:SetCustomItems(data)
    CustomItems = {}
    for k, v in pairs(data) do
        CustomItems[tonumber(k)] = v
    end
end

function lib:ResetCustomItems()
    lib:SetCustomItems({})
end

function lib:AddCustomItem(itemId, rarity, ilvl, slot, faction)
    CustomItems[itemId] = { rarity, ilvl, slot, faction}
end

function lib:RemoveCustomItem(itemId)
    CustomItems[itemId] = nil
end

function lib:GetCustomItem(itemId)
    return CustomItems[itemId]
end

--- Convert an itemlink to itemID
--  @param itemlink of which you want the itemID from
--  @returns number or nil
function lib:ItemLinkToId(link)
    return tonumber(strmatch(link or "", "item:(%d+):?"))
end

-- returns the 'itemString' from an item link
-- https://wowwiki.fandom.com/wiki/ItemString
-- e.g. 'item:22356:0:0:0:0:0:0:0:60'
-- item:6098::::::::2 OR item:6098:0:0:0:0:0:0:0:2
-- 9 indexes in classic wow
function lib:ItemLinkToItemString(link)
    return strmatch(strmatch(link or "", "item:[%d:-]+") or "", "(item:.-):*$")
end

-- returns an item name from the item link
-- e.g. '|cff9d9d9d|Hitem:22356:0:0:0:0:0:0::|h[Desecrated Waistguard]|h|r' -> 'Desecrated Waistguard'
function lib:ItemLinkToItemName(link)
    return strmatch(link or "", "%[(.+)%]")
end

-- returns the hex color code from an item link
-- e.g. '|cff9d9d9d|Hitem:22356:0:0:0:0:0:0::|h[Desecrated Waistguard]|h|r' -> '|cff9d9d9d'
function lib:ItemLinkToColor(link)
    return strmatch(link or "", "(|c[A-Za-z0-9]*)|")
end

--- @param item string
--- @return boolean indicating if passed string contains an item string
function lib:ContainsItemString(item)
    -- nil or not a string -> false
    if not item or type(item) ~= 'string' then return false end
    ---- empty string -> false
    if item:trim() == "" then return false end

    return strmatch(item, "item[%-?%d:]+") and true or false
end

-- itemId (1), enchantId (2), gemId1 (3), gemId2 (4), gemId3(5), gemId4(6), suffixId(7), uniqueId(8), linkLevel(9)
-- neutralization removes uniqueId and linkLevel, leaving rest unchanged
local NEUTRALIZE_ITEM_PATTERN = "item:(%d*):(%d*):(%d*):(%d*):(%d*):(%d*):(%d*):%d*:%d*"
local NEUTRALIZE_ITEM_REPLACEMENT = "item:%1:%2:%3:%4:%5:%6:%7::"

-- 'item:22356:0:0:0:0:0:0:0:60' -> 'item:22356:0:0:0:0:0:0::'
-- input can be an item link or item string, in each case the item string is neutralized
function lib:NeutralizeItem(item)
    return item:gsub(NEUTRALIZE_ITEM_PATTERN, NEUTRALIZE_ITEM_REPLACEMENT)
end

local restrictedClassFrameNameFormat = tooltip:GetName().."TextLeft%d"

-- @return The bitwise flag indicates the classes allowed for the item, as specified on the tooltip by "Classes: xxx"
-- If the tooltip does not specify "Classes: xxx" or if the item is not cached, return 0xffffffff
-- This function only checks the tooltip and does not consider if the item is equipable by the class.
-- Item must have been cached to get the correct result.
--
-- If the number at binary bit i is 1 (bit 1 is the lowest bit), then the item works for the class with ID i.
-- 0b100,000,000,010 indicates the item works for Paladin(classID 2) and DemonHunter(class ID 12)
function lib:GetItemClassesAllowedFlag(itemLink)
    if type(itemLink) == "string" and itemLink:trim() == "" then return 0 end
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetHyperlink(itemLink)

    Logging:Trace("GetItemClassesAllowedFlag(%s) : NumLines=%s", itemLink, tooltip:NumLines())

    local delimiter = ", "
    for i = 1, tooltip:NumLines() or 0 do
        local line = getglobal(restrictedClassFrameNameFormat:format(i))
        if line and line.GetText then
            local text = line:GetText() or ""
            Logging:Trace("GetItemClassesAllowedFlag(%s) : Text=%s", itemLink, text)
            local classesText = Deformat(text, ITEM_CLASSES_ALLOWED)
            Logging:Trace("GetItemClassesAllowedFlag(%s) : classesText=%s", itemLink, classesText or 'nil')
            if classesText then
                tooltip:Hide()
                if LIST_DELIMITER and LIST_DELIMITER ~= "" and classesText:find(LIST_DELIMITER:gsub("%%s","")) then
                    delimiter = LIST_DELIMITER:gsub("%%s","")
                elseif PLAYER_LIST_DELIMITER and PLAYER_LIST_DELIMITER ~= "" and classesText:find(PLAYER_LIST_DELIMITER) then
                    delimiter = PLAYER_LIST_DELIMITER
                end

                local result = 0
                for className in string.gmatch(classesText..delimiter, "(.-)"..delimiter) do
                    local classId = self.ClassDisplayNameToId[className]
                    if classId then
                        Logging:Trace("GetItemClassesAllowedFlag(%s) : ClassName=%s ClassId=%s", itemLink, className, classId)
                        result = result + bit.lshift(1, classId -1)
                    else
                        Logging:Warn("Error while getting classes flag of %s  Class %s does not exist", itemLink, className)
                    end
                end

                Logging:Trace("GetItemClassesAllowedFlag(%s) : Result=%s", itemLink, result)
                return result
            end
        end
    end

    tooltip:Hide()
    return 0xffffffff -- The item works for all classes
end

--[[
ClassCanUse(PRIEST) : Classes=4294967295 EquipLoc=[Helm of Endless Rage], TypeId=INVTYPE_HEAD, SubTypeId=4
--]]
function lib:ClassCanUse(class, classesFlag, equipLoc, typeId, subTypeId)
    Logging:Trace("ClassCanUse(%s) : Classes=%s EquipLoc=%s, TypeId=%s, SubTypeId=%s",
            class, classesFlag, tostring(equipLoc), tostring(typeId), tostring(subTypeId))

    local classId = self.ClassTagNameToId[class]
    --Logging:Trace("ClassCanUse(%s) : ClassId=%s", class, classId)
    -- if the classes flag, parsed from tooltip, doesn't contain the class id then it cannot be used
    if bit.band(classesFlag, bit.lshift(1, classId-1)) == 0 then
        return false
    end

    if not equipLoc ~= "INVTYPE_CLOAK" then
        if DisallowedByClass[class] and DisallowedByClass[class][typeId] then
            local canUse = DisallowedByClass[class][typeId][subTypeId]
            if canUse then return not canUse end
        end
    end

    return true
end

function lib:IsTokenBasedItem(itemId)
    return lib.TokenEquipmentLocations[itemId] and true or false
end

function lib:GetTokenBasedItemLocations(itemId)
    return lib.TokenEquipmentLocations[itemId]
end

function lib:GetTokenItems(itemId)
    return lib.TokenItems[itemId]
end

function lib:IsReputationItem(itemId)
    return lib.ReputationItems[itemId] and true or false
end