--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
--- @type Models.Player
local Player = AddOn.ImportPackage('Models').Player
--- @type LibUtil.Bitfield.Bitfield
local Bitfield = Util.Bitfield.Bitfield

--- @class Core.Mode
local Mode = AddOn.Package('Core'):Class('Mode', Bitfield)
function Mode:initialize()
    Bitfield.initialize(self, AddOn.Constants.Modes.Standard)
end

function AddOn:Qualify(...)
    return Util.Strings.Join('_', C.name, ...)
end

function AddOn:IsInNonInstance()
    local instanceType = select(2, IsInInstance())
    if Util.Objects.In(instanceType, 'pvp', 'arena') then
        return true
    else
        return false
    end
end

function AddOn.Ambiguate(name)
    if Util.Objects.IsTable(name) then name = name.name end
    if Util.Objects.IsEmpty(name) then error("name not specified") end
    return Ambiguate(name, "none")
end

local UnitNames = {}

-- Gets a unit's name formatted with realmName.
-- If the unit contains a '-' it's assumed it belongs to the realmName part.
-- Note: If 'unit' is a playername, that player must be in our raid or party!
-- @param u Any unit, except those that include '-' like "name-target".
-- @return Titlecased "unitName-realmName"
function AddOn:UnitName(u)
    if Util.Objects.IsEmpty(u) then return nil end
    if UnitNames[u] then return UnitNames[u] end

    local function qualify(name, realm)
        name = name:lower():gsub("^%l", string.upper)
        return name .. "-" .. realm
    end

    -- First strip any spaces
    local unit = gsub(u, " ", "")
    -- Then see if we already have a realm name appended
    local find = strfind(unit, "-", nil, true)
    -- "-" isn't the last character
    if find and find < #unit then
        -- Let's give it same treatment as below so we're sure it's the same
        local name, realm = strsplit("-", unit, 2)
        name = name:lower():gsub("^%l", string.upper)
        return qualify(name, realm)
    end
    -- Apparently functions like GetRaidRosterInfo() will return "real" name, while UnitName() won't
    -- always work with that (see ticket #145). We need this to be consistent, so just lowercase the unit:
    unit = unit:lower()
    -- Proceed with UnitName()
    local name, realm = UnitName(unit)
    -- Extract our own realm
    if Util.Strings.IsEmpty(realm) then realm = GetRealmName() or "" end
    -- if the name isn't set then UnitName couldn't parse unit, most likely because we're not grouped.
    if not name then name = unit end
    -- Below won't work without name
    -- We also want to make sure the returned name is always title cased (it might not always be! ty Blizzard)
    local qualified = qualify(name, realm)
    UnitNames[u] = qualified
    return qualified
end


-- Custom, better UnitIsUnit() function.
-- Blizz UnitIsUnit() doesn't know how to compare unit-realm with unit.
-- Seems to be because unit-realm isn't a valid unitid.
function AddOn.UnitIsUnit(unit1, unit2)
    if Util.Objects.IsTable(unit1) then unit1 = unit1.name end
    if Util.Objects.IsTable(unit2) then unit2 = unit2.name end
    if not unit1 or not unit2 then return false end

    -- Remove realm names, if any
    if strfind(unit1, "-", nil, true) ~= nil then
        unit1 = Ambiguate(unit1, "short")
    end
    if strfind(unit2, "-", nil, true) ~= nil then
        unit2 = Ambiguate(unit2, "short")
    end

    -- There's problems comparing non-ascii characters of different cases using UnitIsUnit()
    -- I.e. UnitIsUnit("Foo", "foo") works, but UnitIsUnit("Æver", "æver") doesn't.
    -- Since I can't find a way to ensure consistent returns from UnitName(),
    -- just lowercase units here before passing them.
    return UnitIsUnit(unit1:lower(), unit2:lower())
end

function AddOn:UnitClass(name)
    local player = Player:Get(name)
    if player and Util.Strings.IsSet(player.class) then return player.class end
    return select(2, UnitClass(Ambiguate(name, "short")))
end

-- The link of same item generated from different players, or if two links are generated between player spec switch, are NOT the same
-- This function compares the raw item strings with link level and spec ID removed.
--
-- Also compare with unique id removed, because wowpedia says that:
-- "In-game testing indicates that the UniqueId can change from the first loot to successive loots on the same item."
-- Although log shows item in the loot actually has no uniqueId in Legion, but just in case Blizzard changes it in the future.
--
-- @return true if two items are the same item
function AddOn.ItemIsItem(item1, item2)
    if not Util.Objects.IsString(item1) or not Util.Objects.IsString(item2) then return item1 == item2 end
    item1 = ItemUtil:ItemLinkToItemString(item1)
    item2 = ItemUtil:ItemLinkToItemString(item2)
    if not (item1 and item2) then return false end
    return ItemUtil:NeutralizeItem(item1) ==  ItemUtil:NeutralizeItem(item2)
end

function AddOn.TransmittableItemString(item)
    local transmit = ItemUtil:ItemLinkToItemString(item)
    transmit = ItemUtil:NeutralizeItem(transmit)
    return AddOn.SanitizeItemString(transmit)
end

function AddOn.NormalizeEquipmentLocation(equipLoc, subType)
    if Util.Strings.Equal(subType, C.ItemEquipmentLocationNames.Wand) then return "INVTYPE_WAND" end
    if Util.Strings.Equal(equipLoc, "INVTYPE_RANGEDRIGHT") then return "INVTYPE_RANGED" end
    if Util.Strings.Equal(equipLoc, "INVTYPE_ROBE") then return "INVTYPE_CHEST" end
    return equipLoc
end

---@param item string any value to be prefaced with 'item:'
function AddOn.DeSanitizeItemString(item)
    return "item:" .. (item or "0")
end

---@param link string any string containing an item link
function AddOn.SanitizeItemString(link)
    return gsub(ItemUtil:ItemLinkToItemString(link), "item:", "")
end

function AddOn.GetEquipmentLocation(name)
    return C.EquipmentNameToLocation[name]
end

function AddOn.EquipmentLocationToName(...)
    local names = {}
    for _, loc in Util.Objects.Each(...) do
        Util.Tables.Push(names, C.EquipmentLocations[loc])
    end
    return names
end

function AddOn:ExtractCreatureId(guid)
    if not guid then return nil end
    local id = guid:match(".+(%b--)")
    return id and (id:gsub("-", "")) or nil
end

local BlacklistedItemClasses = {
    [0]  = { -- Consumables
        all = true
    },
    [5]  = { -- Reagents
        all = true
    },
    [7]  = { -- Trade-skills
        all = true
    },
    [15] = { -- Misc
        [1] = true, -- Reagent
    }
}

function AddOn:IsItemBlacklisted(item)
    if not item then return false end
    local _, _, _, _, _, itemClassId, itemsubClassId = GetItemInfoInstant(item)
    if not (itemClassId and itemsubClassId) then return false end
    if BlacklistedItemClasses[itemClassId] then
        if  BlacklistedItemClasses[itemClassId].all or
            BlacklistedItemClasses[itemClassId][itemsubClassId] then
            return true
        end
    end
    return false
end


function AddOn.IsItemBindType(item, bindType)
    if not item then return false end
    return select(14, GetItemInfo(item)) == bindType
end

function AddOn.IsItemBoe(item)
    return AddOn.IsItemBindType(item, LE_ITEM_BIND_ON_EQUIP)
end

function AddOn.IsItemBop(item)
    return AddOn.IsItemBindType(item, LE_ITEM_BIND_ON_ACQUIRE)
end

local function GetAverageItemLevel()
    local sum, count = 0, 0
    for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local link = GetInventoryItemLink(C.player, i)
        if not Util.Strings.IsEmpty(link)  then
            local ilvl = select(4, GetItemInfo(link)) or 0
            sum = sum + ilvl
            count = count + 1
        end
    end
    return Util.Numbers.Round(sum / count, 2)
end

local enchanting_localized_name
function AddOn:GetPlayerInfo()
    Logging:Trace("GetPlayerInfo()")
    if not enchanting_localized_name then
        enchanting_localized_name = GetSpellInfo(7411)
    end

    local enchanter, enchanterLvl = false, 0
    for i = 1, GetNumSkillLines() do
        -- Cycle through all lines under "Skill" tab on char
        local skillName, _, _, skillRank  = GetSkillLineInfo(i)
        if Util.Strings.Equal(skillName, enchanting_localized_name) then
            enchanter, enchanterLvl = true, skillRank
            break
        end
    end

    local avgItemLevel = GetAverageItemLevel()
    return self.guildRank, enchanter, enchanterLvl, avgItemLevel
end


function AddOn:UpdatePlayerGear(startSlot, endSlot)
    startSlot = startSlot or INVSLOT_FIRST_EQUIPPED
    endSlot = endSlot or INVSLOT_LAST_EQUIPPED
    Logging:Trace("UpdatePlayerGear(%d, %d)", startSlot, endSlot)
    for i = startSlot, endSlot do
        local link = GetInventoryItemLink("player", i)
        if link then
            local name = GetItemInfo(link)
            if name then
                self.playerData.gear[i] = link
            else
                self:ScheduleTimer("UpdatePlayerGear", 1, i, i)
            end
        else
            self.playerData.gear[i] = nil
        end
    end
end

function AddOn:UpdatePlayerData()
    Logging:Trace("UpdatePlayerData()")
    self.playerData.ilvl = GetAverageItemLevel()
    self:UpdatePlayerGear()
end

function AddOn:GetPlayersGear(link, equipLoc, current)
    current = current or self.playerData.gear
    Logging:Trace("GetPlayersGear(%s, %s)", tostring(link), tostring(equipLoc))

    local GetInventoryItemLink = GetInventoryItemLink
    if Util.Tables.Count(current) > 0 then
        GetInventoryItemLink = function(_, slot) return current[slot] end
    end

    -- this is special casing for token based items, which require a different approach
    local itemId = ItemUtil:ItemLinkToId(link)
    if itemId and ItemUtil:IsTokenBasedItem(itemId) then
        local equipLocs = ItemUtil:GetTokenBasedItemLocations(itemId)
        Logging:Trace("GetPlayersGear(%d) : Token => %s", itemId, Util.Objects.ToString(equipLocs))
        if #equipLocs > 1 then
            local items = {true, true}
            -- at most two equipment slots
            for i = 1, 2 do
                items[i] = GetInventoryItemLink(C.player, GetInventorySlotInfo(equipLocs[i]))
            end
            return unpack(items)
        elseif equipLocs[1] == "Weapon" then
            return
            GetInventoryItemLink(C.player, GetInventorySlotInfo("MainHandSlot")),
            GetInventoryItemLink(C.player, GetInventorySlotInfo("SecondaryHandSlot"))
        else
            return GetInventoryItemLink(C.player, GetInventorySlotInfo(equipLocs[1]))
        end
    end

    local gearSlots = ItemUtil:GetGearSlots(equipLoc)
    if not gearSlots then return nil, nil end
    -- index 1 will always have a value if returned
    local item1, item2 = GetInventoryItemLink(C.player, GetInventorySlotInfo(gearSlots[1])), nil
    if not item1 and gearSlots['or'] then
        item1 = GetInventoryItemLink(C.player, GetInventorySlotInfo(gearSlots['or']))
    end
    if gearSlots[2] then
        item2 = GetInventoryItemLink(C.player, GetInventorySlotInfo(gearSlots[2]))
    end
    return item1, item2
end


function AddOn:GetItemLevelDifference(item, g1, g2)
    if not g1 and g2 then error("You can't provide g2 without g1 in GetItemLevelDifference()") end
    local _, link, _, ilvl, _, _, _, _, equipLoc = GetItemInfo(item)
    if not g1 then
        g1, g2 = self:GetPlayersGear(link, equipLoc, self.playerData.gear)
    end

    -- trinkets and rings have two slots
    if Util.Objects.In(equipLoc, "INVTYPE_TRINKET", "INVTYPE_FINGER") then
        local itemId = ItemUtil:ItemLinkToId(link)
        if itemId == ItemUtil:ItemLinkToId(g1) then
            local ilvl1 = select(4, GetItemInfo(g1))
            return ilvl - ilvl1
        elseif g2 and itemId == ItemUtil:ItemLinkToId(g2) then
            local ilvl2 = select(4, GetItemInfo(g2))
            return ilvl - ilvl2
        end
    end

    local diff = 0
    local g1diff, g2diff = g1 and select(4, GetItemInfo(g1)), g2 and select(4, GetItemInfo(g2))
    if g1diff and g2diff then
        diff = g1diff >= g2diff and ilvl - g2diff or ilvl - g1diff
    elseif g1diff then
        diff = ilvl - g1diff
    end

    return diff
end

function AddOn.ConvertIntervalToString(years, months, days)
    local text = format(L["n_days"], days)
    if years > 0 then
        text = format(L["n_years_and_n_months_and_n_days"], years, months, text)
    elseif months > 0 then
        text = format(L["n_months_and_n_days"], months, text)
    end
    return text
end

function AddOn.GetItemTextWithCount(link, count)
    return link .. (count and count > 1 and (" x" .. count) or "")
end

--- @param subscriptions table<number, rx.Subscription>
function AddOn.Unsubscribe(subscriptions)
    if Util.Objects.IsSet(subscriptions) then
        for _, subscription in pairs(subscriptions) do
            subscription:unsubscribe()
        end
    end
end

local GuildRanks = Util.Memoize.Memoize(
    function()
        local ranks = {}
        if IsInGuild() then
            GuildRoster()
            for i = 1, GuildControlGetNumRanks() do
                ranks[GuildControlGetRankName(i)] = i
            end
        end
        return ranks
    end
)
function AddOn.GetGuildRanks()
    return GuildRanks()
end

function AddOn.GetDateTime()
    return date("%m/%d/%y %H:%M:%S", time())
end

function AddOn:PrintError(msg)
    AddOn:Print(format(L["error_x"], msg))
end

local Alarm = AddOn.Class('Alarm')
function Alarm:initialize(interval, fn)
    self.interval = interval
    self.fn = fn
    self.timer = nil
end

function Alarm:_Fire()
    -- Logging:Trace("Alarm:_Fire()")
    self.fn()
end

function Alarm:Start()
    Logging:Trace('Start')
    -- the backing API for the scheduling stuff isn't available in test mode (or I haven't properly implemented it)
    -- don't register the schedule
    if not self.timer and not AddOn._IsTestContext() then
        self.timer = AddOn:ScheduleRepeatingTimer(function() self:_Fire() end, self.interval)
    end
end

function Alarm:Stop()
    Logging:Trace('Stop')
    if self.timer then
        AddOn:CancelTimer(self.timer)
        self.timer = nil
    end
end

function AddOn.Alarm(interval, fn)
    local alarm = Alarm(interval, fn)
    -- something odd is going on in the test framework in which events/messages aren't being
    -- fired without a frame with the name 'AlarmFrame', so create it here under those conditions
    -- it probably merits some extra investigation
    if AddOn._IsTestContext() then CreateFrame('Frame', 'AlarmFrame')  end
    return alarm
end
