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
--- @type Models.Item.ContainerItem
local ContainerItem = AddOn.Package('Models.Item').ContainerItem
--- @type LibEncounter
local LibEncounter = AddOn:GetLibrary("Encounter")

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

--- @param name string|Models.Player the player name
--- @return string the player's name with the realm stripped
function AddOn.Ambiguate(name)
    if Util.Objects.IsTable(name) then name = name.name end
    if Util.Objects.IsEmpty(name) then error("name not specified") end
    return Ambiguate(name, "none")
end

-- Gets a unit's name formatted with realmName.
-- If the unit contains a '-' it's assumed it belongs to the realmName part.
-- Note: If 'unit' is a playername, that player must be in our raid or party!
-- @param u Any unit, except those that include '-' like "name-target".
-- @return Titlecased "unitName-realmName"
function AddOn:UnitName(u)
    --Logging:Debug("UnitName(%s)", tostring(u))
    if Util.Objects.IsEmpty(u) then return nil end

    local function qualify(name, realm)
        --Logging:Debug("UnitName.qualify(%s, %s)", tostring(name), tostring(realm))
        -- name = name:lower():gsub("^%l", string.upper)
        name = Util.Strings.UcFirstUtf8(name)
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
        -- name = name:lower():gsub("^%l", string.upper)
        name = Util.Strings.UcFirstUtf8(name)
        return qualify(name, realm)
    end

    -- Apparently functions like GetRaidRosterInfo() will return "real" name, while UnitName() won't
    -- always work with that (see ticket #145). We need this to be consistent, so just lowercase the unit:
    unit = unit:lower()
    -- Proceed with UnitName()
    local name, _ = UnitName(unit)
    -- realm will be the normalized realm the unit is from
    local realm = self:RealmName(unit)
    -- if the name isn't set then UnitName couldn't parse unit, most likely because we're not grouped.
    if not name then name = unit end
    -- Below won't work without name
    -- We also want to make sure the returned name is always title cased (it might not always be! ty Blizzard)
    local qualified = qualify(name, realm)
    --Logging:Debug("UnitName(%s) => %s", tostring(u), tostring(qualified))
    return qualified
end

--- @return string the normalized realm name
function AddOn:RealmName(u)
    local realm

    if Util.Strings.IsSet(u) then
        _, realm = UnitFullName(u:lower())
    end

    if Util.Strings.IsEmpty(realm) then
        realm = GetNormalizedRealmName() or GetRealmName() or ""
    end

    return gsub(realm, " ", "")
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

--- The link of same item generated from different players, or if two links are generated between player spec switch, are NOT the same
--- This function compares the raw item strings with link level and spec ID removed.
---
--- Also compare with unique id removed, because wowpedia says that:
--- "In-game testing indicates that the UniqueId can change from the first loot to successive loots on the same item."
--- Although log shows item in the loot actually has no uniqueId in Legion, but just in case Blizzard changes it in the future.
---
--- @return boolean true if two items are the same item, otherwise false
function AddOn.ItemIsItem(item1, item2)
    --Logging:Debug("ItemIsItem(%s, %s)", item1, item2)
    if (not Util.Objects.IsString(item1)) or (not Util.Objects.IsString(item2)) then
        return item1 == item2
    end

    item1 = ItemUtil:ItemLinkToItemString(item1)
    item2 = ItemUtil:ItemLinkToItemString(item2)
    if not (item1 and item2) then
        return false
    end

    return ItemUtil:NeutralizeItem(item1) == ItemUtil:NeutralizeItem(item2)
end

--- @return string
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

function AddOn.GetEquipmentLocation(name, alternateMapping)
    local location = C.EquipmentNameToLocation[name]
    --Logging:Debug("GetEquipmentLocation(%s) : %s", tostring(name), Util.Objects.ToString(alternateMapping))
    if Util.Strings.IsEmpty(location) and Util.Objects.IsTable(alternateMapping) then
        location, _ = Util.Tables.FindFn(
            alternateMapping,
            function(mapping) return Util.Strings.Equal(mapping, name) end,
            true
        )
    end

    return location
end

local GUIDPreamble = "^%a+%-.*"

--- @return boolean true if the passed string is a GUID, otherwise false
function AddOn:IsGUID(guid)
    if Util.Strings.IsEmpty(guid) then
        return false
    end

    return guid:match(GUIDPreamble)
end

--- @return string the GUID type if passed string is a GUID, otherwise nil
function AddOn:GetGUIDType(guid)
    if AddOn:IsGUID(guid) then
        return select(1, strsplit("-", guid))
    end

    return nil
end

local CreatureGUIDPattern = "Creature%-0%-%d+-%d+-%d+-%d+%-%x%x%x%x%x%x%x%x%x%x"
--- https://wowpedia.fandom.com/wiki/GUID#Creature
--- [unitType]-0-[serverID]-[instanceID]-[zoneUID]-[ID]-[spawnUID]
--- E.G.
---     Creature-0-1465-0-2105-448-000043F59F
---     Creature-0-4379-34-1065-46382-00076A3954
---     Creature-0-4379-34-1065-46383-00006A3954
---
--- where unitType is one of "Creature", "Pet", "GameObject", "Vehicle"
---
function AddOn:IsCreatureGUID(guid)
    if Util.Strings.IsEmpty(guid) then
        return false
    end

    return guid:match(CreatureGUIDPattern)
end

--- @see AddOn.IsCreatureGUID
--- @return number the id of the create for the passed guid or 0 if it cannot be extracted
function AddOn:ExtractCreatureId(guid)
    if AddOn:IsCreatureGUID(guid) then
        local id = select(6, strsplit("-", guid or ""))
        return tonumber(id or 0)
    end

    return 0
end

function AddOn:GetCreatureName(guid)
    local creatureId = self:ExtractCreatureId(guid)
    return creatureId > 0 and LibEncounter:GetCreatureName(creatureId) or nil
end

local ItemGUIDPattern = "Item%-%d+%-0%-%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x"
--- https://wowpedia.fandom.com/wiki/GUID#Item
--- Item-[serverID]-0-[spawnUID]
--- E.G.
---     Item-4372-0-400000033D4D1C15
---     Item-4372-0-400000032A8C4E67
---     Item-4372-0-4000000342062402
---     Item-4372-0-4000000342062C48
---
--- "Item%-(%d+)%-0%-([A-Z0-9]+)"
---
--- @return boolean true if a valid item GUID, otherwise false
function AddOn:IsItemGUID(guid)
    if Util.Strings.IsEmpty(guid) then
        return false
    end

    return guid:match(ItemGUIDPattern)
end

--- @return boolean true if a valid player GUID, otherwise false
function AddOn:IsPlayerGUID(guid)
    return Player.IsPlayerGUID(guid)
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

local IGNORED_ITEM_SLOTS = {INVSLOT_BODY, INVSLOT_TABARD}

local function IsIgnoredItemSlot(slot)
    return Util.Objects.IsNil(slot) or Util.Tables.ContainsValue(IGNORED_ITEM_SLOTS, slot)
end

local function GetAverageItemLevel()
    -- https://wowpedia.fandom.com/wiki/API_GetAverageItemLevel
    local _, avgItemLevelEquipped, _ = _G.GetAverageItemLevel()
    return avgItemLevelEquipped
end

local enchanting_localized_name
--- @return boolean, number, number
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
    return enchanter, enchanterLvl, avgItemLevel
end

function AddOn:UpdatePlayerGear(startSlot, endSlot)
    startSlot = startSlot or INVSLOT_FIRST_EQUIPPED
    endSlot = endSlot or INVSLOT_LAST_EQUIPPED
    --Logging:Trace("UpdatePlayerGear(%d, %d)", startSlot, endSlot)
    for i = startSlot, endSlot do
        if not IsIgnoredItemSlot(i) then
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
end

function AddOn:UpdatePlayerData()
    --Logging:Trace("UpdatePlayerData()")
    self.playerData.ilvl = GetAverageItemLevel()
    self:UpdatePlayerGear()
end

function AddOn:GetPlayersGear(link, equipLoc, current)
    current = current or self.playerData.gear
    --Logging:Trace("GetPlayersGear(%s, %s)", tostring(link), tostring(equipLoc))

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
            return GetInventoryItemLink(C.player, GetInventorySlotInfo("MainHandSlot")), GetInventoryItemLink(C.player, GetInventorySlotInfo("SecondaryHandSlot"))
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

local EncounterCreatures = Util.Memoize.Memoize(
    function(encounterId)
        if encounterId then
            -- the encounter has an overridden name that is the commonly used in reference
            -- e.g. Omnitron Defense System
            local encounterName = LibEncounter:GetEncounterName(encounterId)
            if Util.Strings.IsSet(encounterName) then
                return encounterName
            else
                local creatureIds = LibEncounter:GetEncounterCreatureId(encounterId)
                if creatureIds then
                    local creatureNames =
                        Util(creatureIds):Copy()
                            :Map(
                                function(id)
                                    local eh, name = geterrorhandler()
                                    Util.Functions.try(
                                        function()
                                            seterrorhandler(function(msg) Logging:Warn("%s", msg) end)
                                            name = LibEncounter:GetCreatureName(id)
                                        end
                                    ).finally(
                                        function()
                                            seterrorhandler(eh)
                                        end
                                    )
                                    return name
                                end
                            )()

                    return Util.Strings.Join(", ", Util.Tables.Values(creatureNames))
                end
            end
        end

        return nil
    end
)

function AddOn.GetEncounterCreatures(...)
    return EncounterCreatures(...)
end

function AddOn:PrintWarning(msg)
    AddOn:Print(format(L["warning_x"], msg))
end

function AddOn:PrintError(msg)
    AddOn:Print(format(L["error_x"], msg))
end

---
--- Based upon which usage/implementation of GetContainerItemInfo which is supported, normalizes the return
--- type to be unpacked attributes
---
--- @see AddOn.C_Container
--- @see GetContainerItemInfo
--- @see C_Container.GetContainerItemInfo
function AddOn:GetContainerItemInfo(bag, slot)
    local result = { AddOn.C_Container.GetContainerItemInfo(bag, slot) }
    if Util.Objects.IsTable(result[1])  then
        local info = result[1]
        return info.iconFileID, info.stackCount, info.isLocked, info.quality, info.isReadable, info.hasLoot,
                info.hyperlink, info.isFiltered, info.hasNoValue, info.itemID, info.isBound

    else
        return unpack(result)
    end
end

local TooltipFrameNameFormat = AddOn.TooltipFrame:GetName().."TextLeft%d"
local TradeTimeRemainingPattern = BIND_TRADE_TIME_REMAINING:gsub("%%s", ".*")

-- establish tables of localize time strings, with mapping to time in seconds
-- used for parsing remaining trade time from item tooltips
local TimeFormats = {
    [INT_SPELL_DURATION_HOURS] = 60 * 60,
    [INT_SPELL_DURATION_MIN]   = 60,
    [INT_SPELL_DURATION_SEC]   = 1
}
local TimeTable = {}

for pattern, coefficient in pairs(TimeFormats) do
    local prefix = ""

    pattern = pattern:gsub("%%d(%s?)", function(s) prefix = "(%d+)" .. s; return "" end)
    pattern = pattern:gsub("|4", ""):gsub("[:;]", " ")

    for s in pattern:gmatch("(%S+)") do
        TimeTable[prefix .. s] = coefficient
    end
end

---
--- If item is not bound to player and has no associated trade time (e.g. BOE, consumables, etc.), C.Item.NotBoundTradeTime is returned
--- If item is not bound and it is tradeable (e.g. BOP looted in last 2 hours), the remaining time to trade in seconds is returned
--- If item is bound or trade time has expired (e.g. Already equipped BOP item, BOP item looted longer than 2 hours ago), 0 is returned
---
--- @param tooltip table the GameTooltip to parse
--- @return number remaining time (in seconds) for item in bag at slot
function AddOn:GetTooltipItemTradeTimeRemaining(tooltip)
    local text, isBound = nil, false
    for i = 1, tooltip:NumLines() or 0 do
        local line = getglobal(TooltipFrameNameFormat:format(i))
        if line and line.GetText then
            text = line:GetText() or ""
            --Logging:Trace("GetTooltipItemTradeTimeRemaining() : Text=%s", text)
            if Util.Objects.In(text, ITEM_SOULBOUND, ITEM_ACCOUNTBOUND, ITEM_BNETACCOUNTBOUND) then
                isBound = true
            end

            if text:find(TradeTimeRemainingPattern) then
                break
            end

            text = nil
        end
    end

    if text then
        local timeRemainingInSecs = 0
        for pattern, coefficient in pairs(TimeTable) do
            local timeRemainingSegment = text:match(pattern)
            if timeRemainingSegment then
                timeRemainingInSecs = timeRemainingInSecs + (timeRemainingSegment * coefficient)
            end
        end

        return timeRemainingInSecs
    end

    if not isBound then
        return C.Item.NotBoundTradeTime
    end

    return 0
end

---
--- in test mode, will return a random amount of remaining time
--- when specific items are specified for testing , will return a random amount of remaining time for those items
---
--- @see AddOn.GetTooltipItemTradeTimeRemaining
--- @param bag number bag in which item is located
--- @param slot number slot within the bag
--- @return number remaining time (in seconds) for item in bag at slot
function AddOn:GetInventoryItemTradeTimeRemaining(bag, slot)
    Logging:Trace("GetInventoryItemTradeTimeRemaining(%d, %d)", bag, slot)
    local tooltip = AddOn.TooltipFrame
    tooltip:ClearLines()
    tooltip:SetBagItem(bag, slot)

    local timeRemainingInSecs = 0
    Util.Functions.try(
        function()
            timeRemainingInSecs = AddOn:GetTooltipItemTradeTimeRemaining(tooltip)
        end
    ).finally(
        function()
            tooltip:ClearLines()
        end
    )

    -- in test mode, return a random amount
    if self:TestModeEnabled() then
        local quality = select(4, self:GetContainerItemInfo(bag, slot))
        -- only do for epic and legendary items
        if Util.Objects.In(quality, 4, 5) then
            timeRemainingInSecs = random(1800, 7200)
        end
    end

    -- if specific items are being tested, return a random amount
    if self.Testing.LootLedger.TradeTimes:HasItems() then
        local itemId = select(10, self:GetContainerItemInfo(bag, slot))
        itemId = tonumber(itemId)

        if self.Testing.LootLedger.TradeTimes:ContainsItem(itemId) then
            timeRemainingInSecs = random(1800, 7200)
        end
    end

    Logging:Trace("GetInventoryItemTradeTimeRemaining(%d, %d) : %s seconds", bag, slot, tostring(timeRemainingInSecs))

    return timeRemainingInSecs
end

---
--- Executes passed function for each item in bags. Processing can be preempted by returning false from function
---
--- @param fn function<ItemLocationMixin, number, number> three arguments, 1st is an ItemLocationMixin, 2nd is the bag, 3rd is the slot within bag. returns boolean indicating if processing should continue, a nil return value is interpreted as true
function AddOn:ForEachItemInBags(fn)
    Logging:Trace("ForEachItemInBags(%d,%d)", BACKPACK_CONTAINER, NUM_BAG_SLOTS)

    local finished = false
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        --Logging:Trace("ForEachItemInBags(bag=%d)", bag)
        for slot = 1, self.C_Container.GetContainerNumSlots(bag) do
            --Logging:Trace("ForEachItemInBags(bag=%d,slot=%d)", bag, slot)
            local itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot)
            if itemLocation and C_Item.DoesItemExist(itemLocation) then
                finished = fn(itemLocation, bag, slot) == false
            end

            if finished then
                break
            end
        end

        if finished then
            return
        end
    end
end

---
--- Finds all the bag and slot locations, with item guid, for a given item in format of
---     {item = link, bag = bag, slot = slot, guid = guid}
---
--- skipSoulBoundCheck
---     - when false, trade times are evaluated as an additional predicate. if located and not soul bound, it WILL be included.
---       if located and soul bound (no remaining trade time), it  WILL NOT be included
---     - when true, an item being soul bound (no trade time remaining) is ignored as a predicate for inclusion of located items in results
---
--- @param item string|number item link, item string, or item id
--- @param skipSoulBoundCheck boolean should check for soul bound items be ignored, defaults to false
--- @return table<Models.Item.ContainerItem>
function AddOn:FindItemsInBags(item, skipSoulBoundCheck)
    skipSoulBoundCheck = (skipSoulBoundCheck == true)
    Logging:Trace("FindItemsInBags(%s,%s)", tostring(item), tostring(skipSoulBoundCheck))

    local isItemLink = ItemUtil:ContainsItemString(item)
    local itemId = isItemLink and ItemUtil:ItemLinkToId(item) or tonumber(item)
    local results = {}

    self:ForEachItemInBags(
        function(location, bag, slot)
            local bagItemId, bagItemLink = C_Item.GetItemID(location), C_Item.GetItemLink(location)
            -- local _, _, _, _, _, _, bagItemLink, _, _, bagItemId = self:GetContainerItemInfo(bag, slot)
            Logging:Trace("FindItemsInBags(%d,%d) : %s / %s", tostring(bag), tostring(slot), tostring(bagItemId), tostring(bagItemLink))
            if (
                -- isn't the item we are looking for (id)
                (bagItemId ~= itemId) or
                -- isn't the item we are looking for (link)
                -- may not want to use ItemIsItem here and compare item strings directly
                (isItemLink and not self.ItemIsItem(item, bagItemLink)) or
                -- item is no longer tradeable
                (not skipSoulBoundCheck and self:GetInventoryItemTradeTimeRemaining(bag, slot) <= 0)
            ) then
                Logging:Trace("FindItemsInBags(%s,%s) : Skipping",  tostring(bag), tostring(slot))
                return true
            end

            Logging:Trace("FindItemsInBags(%s,%s) : Found",  tostring(bag), tostring(slot))
            Util.Tables.Push(results, ContainerItem(bagItemLink, bag, slot, C_Item.GetItemGUID(location)))
            return true
        end
    )

    return results
end

---
--- Finds the first bag and slot, with item guid, for a given item in format of
---     {bag = bag, slot = slot, guid = guid}
---
--- @see AddOn.FindItemsInBags
--- @param item string|number item link, item string, or item id
--- @param skipSoulBoundCheck boolean should check for soul bound items be ignored, defaults to false
--- @return Models.Item.ContainerItem
function AddOn:FindItemInBags(item, skipSoulBoundCheck)
    Logging:Trace("FindItemInBags(%s,%s)", tostring(item), tostring(skipSoulBoundCheck))
    local results = self:FindItemsInBags(item, skipSoulBoundCheck)
    --Logging:Trace("FindItemInBags(%s,%s) : %s", tostring(item), tostring(skipSoulBoundCheck), Util.Objects.ToString(results))
    return #results >= 1 and results[1] or {}
end

--- @return table<Models.Item.ContainerItem>
function AddOn:FindItemsInBagsWithTradeTimeRemaining(predicate)
    predicate = Util.Objects.IsFunction(predicate) and predicate or Util.Functions.True
    local results = {}

    self:ForEachItemInBags(
        function(location, bag, slot)
            if predicate(location, bag, slot) then
                local tradeTimeRemaining = self:GetInventoryItemTradeTimeRemaining(bag, slot)
                if tradeTimeRemaining > 0 then
                    Util.Tables.Push(results, ContainerItem(C_Item.GetItemLink(location), bag, slot, C_Item.GetItemGUID(location)))
                end
            end
        end
    )

    return results
end

--- @return number, number the bag and slot for passed item GUID, or nil if it cannot be located
function AddOn:GetBagAndSlotByGUID(itemGuid)
    local itemBag, itemSlot
    self:ForEachItemInBags(
        function(location, bag, slot)
            if C_Item.GetItemGUID(location) == itemGuid then
                itemBag, itemSlot = bag, slot
                return false
            end
        end
    )

    return itemBag, itemSlot
end

function AddOn:SplitItemLinks(links)
    local result = {}

    for _, connected in ipairs(links) do
        local startPos, endPos = 1, nil
        while (startPos) do
            if connected:sub(1, 2) == "|c" then
                startPos, endPos = connected:find("|c.-|r", startPos)
            elseif connected:sub(1, 2) == "|H" then
                startPos, endPos = connected:find("|H.-|h.-|h", startPos)
            else
                startPos = nil
            end
            if startPos then
                Util.Tables.Push(result, connected:sub(startPos, endPos))
                startPos = startPos + 1
            end
        end
    end

    return result
end

local Alarm = AddOn.Class('Alarm')
function Alarm:initialize(interval, fn)
    self.interval = interval
    self.fn = fn
    self.timer = nil
end

function Alarm:_Fire()
    --Logging:Trace("Alarm:_Fire()")
    self.fn()
end

function Alarm:Enable()
    --Logging:Trace('Enable(%d)', tonumber(self.interval))
    -- the backing API for the scheduling stuff isn't available in test mode unless run in async mode
    if not self.timer and (not AddOn._IsTestContext() or (AddOn._IsTestContext() and _G.IsAsync())) then
        self.timer = AddOn:ScheduleRepeatingTimer(function() self:_Fire() end, self.interval)
    end
end

function Alarm:Disable()
    Logging:Trace('Disable')
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
    if AddOn._IsTestContext() then CreateFrame('Frame', 'AlarmFrame') end
    return alarm
end

local Stopwatch = AddOn.Class('Stopwatch')
function Stopwatch:initialize(ticker)
    self.ticker = Util.Objects.IsFunction(ticker) and ticker or _G.debugprofilestop
    self.isRunning = false
    self.startTick = 0
    self.elapsed = 0
end

function Stopwatch:IsRunning()
    return self.isRunning
end

function Stopwatch:Start()
    assert(not self.isRunning, "this stopwatch is already running")
    self.isRunning = true
    self.startTick = self.ticker()
    return self
end

function Stopwatch:Stop()
    local tick = self.ticker()
    assert(self.isRunning, "this stopwatch is already stopped")
    self.isRunning = false
    self.elapsed =  self.elapsed + (tick - self.startTick)
    return self
end

function Stopwatch:Reset()
    self.elapsed = 0
    self.isRunning = false
    return self
end

function Stopwatch:Restart()
    self:Reset():Start()
end

function Stopwatch:Elapsed()
    return self.isRunning and (self.ticker() - self.startTick) or self.elapsed
end

function Stopwatch:__tostring()
    local elapsed = self:Elapsed()

    return format("Stopwatch(%s, %d, %.2f)", tostring(self.isRunning), self.startTick, elapsed)
end

function AddOn.Stopwatch()
    return Stopwatch()
end
