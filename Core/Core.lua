--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type Models.Player
local Player = AddOn.ImportPackage('Models').Player
--- @type LibGuildStorage
local GuildStorage = AddOn:GetLibrary("GuildStorage")
--- @type Core.SlashCommands
local SlashCommands = AddOn.Require('Core.SlashCommands')
--- @type Models.Item.LootTableEntry
local LootTableEntry = AddOn.Package('Models.Item').LootTableEntry
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
--- @type Models.Item.Item
local Item = AddOn.Package('Models.Item').Item
local Dialog = AddOn:GetLibrary("Dialog")

local function ModeToggle(self, flag)
    local enabled

    if self.mode:Enabled(flag) then
        self.mode:Disable(flag)
        enabled = false
    else
        self.mode:Enable(flag)
        enabled = true
    end

    self:SendMessage(C.Messages.ModeChanged, self.mode, flag, enabled)
end

--- @return boolean
function AddOn:TestModeEnabled()
    return self.mode:Enabled(C.Modes.Test)
end

--- @return boolean
function AddOn:DevModeEnabled()
    return self.mode:Enabled(C.Modes.Develop)
end

--- @return boolean
function AddOn:PersistenceModeEnabled()
    return self.mode:Enabled(C.Modes.Persistence)
end

--- @return boolean
function AddOn:ReplicationModeEnabled()
    return self.mode:Enabled(C.Modes.Replication)
end

function AddOn:ModuleSettings(module)
    return AddOn.db.profile.modules[module]
end

function AddOn:CallModule(module)
    Logging:Trace("CallModule(%s)", module)
    if not self.enabled then return end
    self:EnableModule(module)
end

function AddOn:IsModuleEnabled(module)
    Logging:Trace("IsModuleEnabled(%s)", module)
    local m = self:GetModule(module)
    return m and m:IsEnabled()
end

function AddOn:YieldModule(module)
    Logging:Trace("YieldModule(%s)", module)
    self:DisableModule(module)
end

function AddOn:ToggleModule(module)
    Logging:Trace("ToggleModule(%s)", module)
    if self:IsModuleEnabled(module) then
        self:YieldModule(module)
    else
        self:CallModule(module)
    end
end

--- @return Logging
function AddOn:LoggingModule()
    return self:GetModule("Logging")
end

--- @return VersionCheck
function AddOn:VersionCheckModule()
    return self:GetModule("VersionCheck")
end

--- @return CustomItems
function AddOn:CustomItemsModule()
    return self:GetModule("CustomItems")
end

--- @return Lists
function AddOn:ListsModule()
    return self:GetModule("Lists")
end

--- @return ListsDataPlane
function AddOn:ListsDataPlaneModule()
    return self:GetModule("ListsDataPlane")
end

--- @return MasterLooter
function AddOn:MasterLooterModule()
    return self:GetModule("MasterLooter")
end

--- @return LootSession
function AddOn:LootSessionModule()
    return self:GetModule("LootSession")
end

--- @return LootAllocate
function AddOn:LootAllocateModule()
    return self:GetModule("LootAllocate")
end

--- @return Loot
function AddOn:LootModule()
    return self:GetModule("Loot")
end

--- @return LootAudit
function AddOn:LootAuditModule()
    return self:GetModule("LootAudit")
end

--- @return TrafficAudit
function AddOn:TrafficAuditModule()
    return self:GetModule("TrafficAudit")
end

--- @return TrafficAudit
function AddOn:TrafficAuditModule()
    return self:GetModule("TrafficAudit")
end

--- @return RaidAudit
function AddOn:RaidAuditModule()
    return self:GetModule("RaidAudit")
end

--- @return Sync
function AddOn:SyncModule()
    return self:GetModule("Sync")
end

--- @return LootLedger
function AddOn:LootLedgerModule()
    return self:GetModule("LootLedger")
end

--- @return LootTrade
function AddOn:LootTradeModule()
    return self:GetModule("LootTrade")
end

function AddOn:RegisterChatCommands()
    Logging:Debug("RegisterChatCommands(%s)", self:GetName())
    SlashCommands:BulkSubscribe(
            {
                { 'config', 'c' },
                L['chat_commands_config'],
                function() AddOn:ShowLaunchpadAndSelect(AddOn:SelectConfigModuleFn()) end,
            },
            {
                {'clearpc', 'cpc'},
                L['clear_player_cache_desc'],
                function()
                    AddOn.Package('Models').Player.ClearCache()
                    self:Print("Player cache cleared")
                end,
            },
            {
                {'togglepc', 'tpc'},
                L['toggle_player_cache_desc'],
                function()
                    AddOn.Package('Models').Player.ToggleCache()
                    self:Print(format("Player cache duration = %d days", AddOn.Package('Models').Player.GetCacheDurationInDays()))
                end,
            },
            {
                {'durationpc', 'dpc'},
                L['duration_player_cache_desc'],
                function()
                    self:Print(format("Player cache duration = %d days", AddOn.Package('Models').Player.GetCacheDurationInDays()))
                end,
            },
            {
                {'clearic', 'cic'},
                L['clear_item_cache_desc'],
                function()
                    AddOn.Package('Models.Item').Item.ClearCache()
                    self:Print("Item cache cleared")
                end,
            },
            {
                {'dev'},
                L['chat_commands_dev'],
                function()
                    ModeToggle(self, C.Modes.Develop)
                    self:Print("Development Mode = " .. tostring(self:DevModeEnabled()))
                end,
                true
            },
            {
                {'pm'},
                L['chat_commands_pm'],
                function()
                    ModeToggle(self, C.Modes.Persistence)
                    self:Print("Persistence Mode = " .. tostring(self:PersistenceModeEnabled()))
                end,
                true
            },
            {
                {'rm'},
                L['chat_commands_rm'],
                function()
                    ModeToggle(self, C.Modes.Replication)
                    self:Print("Replication Mode = " .. tostring(self:ReplicationModeEnabled()))
                end,
                true
            },
            {
                {'version', 'v', 'ver'},
                L['chat_commands_version'],
                function(showOutOfDate)
                    if showOutOfDate then
                        self:VersionCheckModule():DisplayOutOfDateClients()
                    else
                        self:CallModule('VersionCheck')
                    end
                end
            },
            {
                {'sync', 's'},
                L['chat_commands_sync'],
                function()
                    self:CallModule('Sync')
                end
            },
            {
                {'test', 't'},
                L['chat_commands_test'],
                function(count, players)
                    self:Test(tonumber(count) or 2, players and tonumber(players) or nil)
                end
            },
            {
                {'add', },
                L['chat_commands_add'],
                function(...)
                    local args = { ...}
                    Logging:Trace("ChatCommand(add) : %s, isMasterLooter=%s", Util.Objects.ToString(args), tostring(self.masterLooter))

                    if self:MasterLooterModule():IsHandled()  then
                        local function IsEligibleItemQuality(location)
                            return Util.Objects.In(C_Item.GetItemQuality(location), 4, 5)
                        end

                        local locatedItems
                        if Util.Objects.In(Util.Strings.Lower(args[1]), "all", "bags") then
                            locatedItems = self:FindItemsInBagsWithTradeTimeRemaining(
                            -- only consider epic and legendary
                            -- may want to also consider limiting to items which aren't BOE
                                function(location, _, _)
                                    -- documentation says should be able to use Enum.ItemQuality, but it's inconsistent
                                    -- e.g.It uses Standard instead of Common, Good instead of Uncommon
                                    -- therefore use the constants for Epic (4) and Legendary (5)
                                    --
                                    -- Patch 9.0.1 (2020-10-13): Renamed Standard, Good, Superior fields to Common, Uncommon, Rare
                                    return IsEligibleItemQuality(location)
                                end
                            )
                        else
                            local items = AddOn:SplitItemLinks(args)
                            locatedItems = self:FindItemsInBagsWithTradeTimeRemaining(
                                function(location, _, _)
                                    local bagItemLink = C_Item.GetItemLink(location)
                                    return IsEligibleItemQuality(location) and
                                        Util.Tables.FindFn(items, function(i) return self.ItemIsItem(i, bagItemLink) end)
                                end
                            )
                        end

                        Logging:Trace("ChatCommand(add all) : items=%s", Util.Objects.ToString(locatedItems))

                        for _, containerItem in pairs(locatedItems) do
                            AddOn:MasterLooterModule():AddLootTableItemFromContainer(containerItem)
                        end
                    else
                        self:Print(L["command_must_be_master_looter"])
                    end
                end
            },
            {
                {'trade'},
                L['chat_commands_trade'],
                function(...) self:LootTradeModule():Show(true) end
            }
    )
end

function AddOn:IsMasterLooter(unit)
    unit = Util.Objects.Default(unit, self.player)
    --Logging:Trace("IsMasterLooter() : unit=%s, ml=%s", tostring(unit), tostring(self.masterLooter))
    return Util.Objects.IsSet(self.masterLooter) and not Player.IsUnknown(self.masterLooter) and self.masterLooter:IsValid() and AddOn.UnitIsUnit(unit, self.masterLooter)
end

--- @return boolean, Models.Player
function AddOn:GetMasterLooter()
    -- lootMethod   : One of 'freeforall', 'roundrobin', 'master', 'group', 'needbeforegreed', 'personalloot'
    -- mlPartyId    : Returns 0 if player is the master looter, 1-4 if party member is master looter (corresponding to party1-4)
    --                and nil if the master looter isn't in the player's party or master looting is not used.
    -- mlRaidId     : Returns index of the master looter in the raid (corresponding to a raidX unit), or nil if the player
    --                is not in a raid or master looting is not used.
    local lootMethod, mlPartyId, mlRaidId = GetLootMethod()
    self.lootMethod = lootMethod
    Logging:Debug(
        "GetMasterLooter() : lootMethod='%s', mlPartyId=%s, mlRaidId=%s",
        self.lootMethod, tostring(mlPartyId), tostring(mlRaidId)
    )

    -- always the player when testing alone
    -- if GetNumGroupMembers() == 0 and (self:TestModeEnabled() or self:DevModeEnabled()) then
    if GetNumGroupMembers() == 0 and self:TestModeEnabled() then
        self:ScheduleTimer(
                function()
                    if Util.Objects.IsSet(self.masterLooter) then
                        -- base check on an attribute that should be present
                        if not self:HaveMasterLooterDb() then
                            self:Send(self.masterLooter, C.Commands.MasterLooterDbRequest)
                        end
                    end
                end,
                5
        )
        Logging:Debug("GetMasterLooter() : ML is '%s' (no group OR test mode)", tostring(self.player))
        return true, self.player
    end

    if Util.Strings.Equal(lootMethod, "master") then
        local name
        -- Someone in raid
        if mlRaidId then
            name = self:UnitName("raid" .. mlRaidId)
        -- Player in party
        elseif mlPartyId == 0 then
            name = self.player:GetName()
        -- Someone in party
        elseif mlPartyId then
            name = self:UnitName("party" .. mlPartyId)
        end

        Logging:Debug("GetMasterLooter() : ML is '%s'", tostring(name))
        return IsMasterLooter(), Player:Get(name)
    end

    Logging:Warn("GetMasterLooter() : Unsupported loot method '%s'", tostring(self.lootMethod))
    return false, nil
end

function AddOn:NewMasterLooterCheck()
    Logging:Debug("NewMasterLooterCheck()")

    local oldMl, oldLm = self.masterLooter, self.lootMethod
    _, self.masterLooter = self:GetMasterLooter()
    self.lootMethod = GetLootMethod()

    -- ML is set, but it's not valid or an unknown player
    if Util.Objects.IsSet(self.masterLooter) and (not self.masterLooter:IsValid() or Player.IsUnknown(self.masterLooter)) then
        Logging:Warn("NewMasterLooterCheck() : Unknown Master Looter")
        AddOn.Timer.Schedule(function() AddOn.Timer.After(1, function() self:NewMasterLooterCheck() end) end)
        return
    end

    -- at this point we can check if we're the ML, it's not changing
    local isML = self:IsMasterLooter()
    Logging:Debug("NewMasterLooterCheck() : isML=%s", tostring(isML))

    -- old ML is us, but no longer ML
    if self.UnitIsUnit(oldMl, "player") and not isML then
        self:StopHandleLoot()
    end

    -- is current ML unset
    if Util.Objects.IsEmpty(self.masterLooter) then
        Logging:Warn("NewMasterLooterCheck() : Master Looter is empty")
        return
    end

    -- old ML is us, new ML is us (implied by check above) and loot method has not changed
    if self.UnitIsUnit(oldMl, self.masterLooter) and Util.Strings.Equal(oldLm, self.lootMethod) then
        Logging:Debug("NewMasterLooterCheck() : No Master Looter change (%s / %s)", tostring(oldMl), tostring(self.masterLooter))
        return
    end

    local ML = self:MasterLooterModule()
    -- settings say to never use
    if ML:GetDbValue('usage.state') == ML.UsageType.Never then
        Logging:Trace("NewMasterLooterCheck() : Configuration specifies to never use")
        return
    end

    -- request ML DB if not received within 5 seconds
    self:ScheduleTimer(
            function()
                if Util.Objects.IsSet(self.masterLooter) then
                    -- base check on an attribute that should be present
                    if not self:HaveMasterLooterDb() then
                        self:Send(self.masterLooter, C.Commands.MasterLooterDbRequest)
                    end
                end
            end,
            5
    )

    -- Someone else has become ML, nothing additional to do
    if not isML and Util.Objects.IsSet(self.masterLooter) then
        Logging:Debug("NewMasterLooterCheck() : Another player is the Master Looter")
        return
    end

    -- not in raid and setting is to only use in raids
    if not IsInRaid() and ML:GetDbValue('onlyUseInRaids') then
        Logging:Debug("NewMasterLooterCheck() : Not in raid and configuration specifies not to use")
        return
    end

    -- already handling loot, just bail
    if self.handleLoot then
        Logging:Debug("NewMasterLooterCheck() : Already handling loot")
        return
    end

    local _, type = IsInInstance()
    -- don't use in arena an PVP
    if Util.Objects.In(type, 'arena', 'pvp') then return end

    Logging:Debug("NewMasterLooterCheck() : isMasterLooter=%s", tostring(self:IsMasterLooter()))

    -- we're the ML and settings say to use when ML
    if isML and ML:GetDbValue('usage.state') == ML.UsageType.Always then
        self:StartHandleLoot()
    -- we're the ML and settings say to ask
    elseif isML and ML:GetDbValue('usage.state')  == ML.UsageType.Ask then
        Dialog:Spawn(C.Popups.ConfirmUsage)
    end
end

--- @param ... any list of arguments that will be passed to constituent functions
function AddOn:StartHandleLoot(...)
    Logging:Debug("StartHandleLoot()")
    local lootMethod = GetLootMethod()
    if not Util.Strings.Equal(lootMethod, "master") and GetNumGroupMembers() > 0 then
        self:Print(L["changing_loot_method_to_ml"])
        SetLootMethod("master", self.Ambiguate(self.player:GetName()))
    end

    local ML, lootThreshold = self:MasterLooterModule(), GetLootThreshold()
    local autoAwardLowerThreshold = ML:GetDbValue('autoAwardLowerThreshold')
    if ML:GetDbValue('autoAward') and lootThreshold ~= 2 and lootThreshold > autoAwardLowerThreshold then
        self:Print(L["changing_loot_threshold_auto_awards"])
        SetLootThreshold(autoAwardLowerThreshold >= 2 and autoAwardLowerThreshold or 2)
    end

    self:Print(format(L["player_handles_looting"], self.player:GetName()))
    self.handleLoot = true
    self:CallModule(ML:GetName())
    ML:NewMasterLooter(self.masterLooter)
    ML:OnHandleLootStart(...)
    -- sending as message instead of comms to target/group, as only currently consumed
    -- by master looter. recipients will need to evaluate whether to handle based upon
    -- current state of loot management
    self:SendMessage(C.Messages.HandleLootStart) -- self:Send(C.group, C.Commands.HandleLootStart)
end

function AddOn:StopHandleLoot()
    Logging:Debug("StopHandleLoot()")
    self:MasterLooterModule():OnHandleLootStop()
    -- must set this after, or call to OnHandleLootStop() won't be handled
    self.handleLoot = false

    -- sending as message instead of comms to target/group, as only currently consumed
    -- by master looter. recipients will need to evaluate whether to handle based upon
    -- current state of loot management
    self:SendMessage(C.Messages.HandleLootStop) -- self:Send(C.group, C.Commands.HandleLootStop)
end

function AddOn:HaveMasterLooterDb()
    return self.mlDb and next(self.mlDb) ~= nil
end

function AddOn:MasterLooterDbValue(...)
    return Util.Tables.Get(self.mlDb, Util.Strings.Join('.', ...))
end

function AddOn:OnMasterLooterDbReceived(mlDb)
    Logging:Debug("OnMasterLooterDbReceived()")
    local ML = self:MasterLooterModule()

    self.mlDb = Util.Tables.ContainsKey(mlDb, 'db') and mlDb['db'] or mlDb

    if not self.mlDb.responses then self.mlDb.responses = {} end
    setmetatable(self.mlDb.responses, {__index = ML:GetDefaultDbValue('profile.responses')})

    if not self.mlDb.buttons then self.mlDb.buttons = {} end
    setmetatable(self.mlDb.buttons, {__index = ML:GetDefaultDbValue('profile.buttons')})

    --Logging:Trace("OnMasterLooterDbReceived() : %s", Util.Objects.ToString(self.mlDb, 4))
end

--- this only returns a value when in test mode and a number of players has been specified, never relevant outside
--- of test mode
local function ExtraGroupMembers()
    if AddOn:TestModeEnabled() and AddOn:IsMasterLooter() then
        return AddOn:MasterLooterModule().testGroupMembers
    end

    return nil
end

function AddOn:UpdateGroupMembers()
    Logging:Trace("UpdateGroupMembers() : current count is %d", Util.Tables.Count(self.group))

    local group, groupCount, name = {}, GetNumGroupMembers(), nil
    for i = 1, groupCount do
        name = GetRaidRosterInfo(i)
        if Util.Objects.IsSet(name) then
            group[self:UnitName(name)] = true
        else
            Logging:Debug("UpdateGroupMembers(%d) : raid roster info (at slot) not yet available", i)
        end
    end

    -- make sure we are present in the group, no reason we should be omitted
    -- this is just a "safety net"
    -- e.g. {'Jackburtón-Atiesh' = true}
    if self.player then
        group[self:UnitName(self.player:GetName())] = true
    end

    --Logging:Debug("%s", Util.Objects.ToString(group))

    -- if the number of collected group members is less than the count of members, reschedule it
    -- this shouldn't happen, but GetRaidRosterInfo has been shown to intermittently not return results
    if  (Util.Tables.Count(group) < groupCount) then
        -- reschedule another attempt, don't mutate current state
        Logging:Warn("UpdateGroupMembers() : raid roster incomplete, rescheduling")
        self:ScheduleTimer("UpdateGroupMembers", 1)
    else
        -- this section is only applicable in test mode, will return nil if that's not the case
        local testGroupMembers = ExtraGroupMembers()
        if Util.Objects.IsSet(testGroupMembers) and Util.Objects.IsTable(testGroupMembers) and Util.Tables.Count(testGroupMembers) > 0 then
            for _, p in pairs(testGroupMembers) do
                -- e.g. group[self:UnitName("Avalona-Atiesh")] = true
                group[self:UnitName(p)] = true
            end
        end

        -- this section is all about Player joining and leaving the group and dispatching associated messages
        -- currently, this is only consumed by the Master Looter, so don't bother with it unless
        -- the current player is the master looter and the associated module is active and handling loot
        if self:MasterLooterModule():IsHandled() then
            -- go through previous state and dispatch player messages (as necessary)
            -- self.group is the previous state (reflects previous roster)
            -- group is the current state (reflects current roster)
            --
            -- the SendMessage() calls are by default synchronous (inline), unless any subscriber
            -- has registered interest in a manner that dictates different semantics (e.g. bucket messages on a timer)
            for player, _ in pairs(self.group) do
                if not group[player] then
                    Logging:Debug("UpdateGroupMembers() : dispatching PlayerLeftGroup for %s", tostring(player))
                    self:SendMessage(C.Messages.PlayerLeftGroup, player)
                end
            end

            for player, _ in pairs(group) do
                if not self.group[player] then
                    Logging:Debug("UpdateGroupMembers() : dispatching PlayerJoinedGroup for %s", tostring(player))
                    self:SendMessage(C.Messages.PlayerJoinedGroup, player)
                end
            end
        end

        -- track current state
        -- currently, nothing in the code path which consumes player joined/left messages relies
        -- upon the current state here being up to date
        -- if that were to change, could collect the messages to be dispatched in for loops above
        -- then dispatch them after the group (state) has been updated to reflect current group
        self.group = group
    end

    --Logging:Trace("UpdateGroupMembers() : %s", Util.Objects.ToString(self.group))

    return self.group
end

function AddOn:GroupIterator()
    Logging:Trace("GroupIterator()")
    local groupMembers, index = {}, 1
    for name, _ in pairs(self:UpdateGroupMembers()) do
        groupMembers[index] = name
        index = index + 1
    end

    index = 0
    local total = #groupMembers
    return function()
        index = index + 1
        if index <= total then return groupMembers[index] end
    end
end

function AddOn:GroupMemberCount()
    return Util.Tables.Count(self:UpdateGroupMembers())
end

function AddOn:GuildIterator()
    Logging:Trace("GuildIterator()")
    local guildMembers, index = {}, 1

    for name, _ in pairs(GuildStorage:GetMembers()) do
        guildMembers[index] = name
        index = index + 1
    end

    index = 0
    local total = #guildMembers
    return function()
        index = index + 1
        if index <= total then return guildMembers[index] end
    end
end

--- @param group boolean should group members be included
--- @param guild boolean should guild members be included
--- @param ambiguate boolean should player names be disambiguated (no realm name included)
--- @return table<string, Models.Player>
function AddOn:Players(group, guild, ambiguate)
    group = Util.Objects.Default(group, false)
    guild = Util.Objects.Default(guild, false)
    ambiguate = Util.Objects.Default(ambiguate, false)
    Logging:Trace("Players(%s, %s, %s)", tostring(group), tostring(guild), tostring(ambiguate))

    local players = {}

    if group then
        for name, _ in self:GroupIterator() do
            players[ambiguate and self.Ambiguate(name) or name] = Player:Get(name)
        end
    end

    if guild then
        for name, _ in self:GuildIterator() do
            players[ambiguate and self.Ambiguate(name) or name] = Player:Get(name)
        end
    end

    Util.Tables.Sort(
        players,
        function(p1, p2) return p1:GetName() < p2:GetName() end
    )

    return players
end

function AddOn:GetButtonCount()
    if not self:HaveMasterLooterDb() or not self:MasterLooterDbValue('buttons') then
        local buttons = self:MasterLooterModule():GetDbValue('buttons')
        return buttons and buttons.numButtons or 0
    end

    return self:MasterLooterDbValue('buttons.numButtons') or 0
end

function AddOn:GetButtonOrder()
    local ordering
    if not self:HaveMasterLooterDb() or not self:MasterLooterDbValue('buttons') then
        local buttons = self:MasterLooterModule():GetDbValue('buttons')
        ordering = buttons.ordering
    else
        ordering = self:MasterLooterDbValue('buttons.ordering')
    end

    --Logging:Warn("GetButtonOrder(1) : %s", Util.Objects.ToString(ordering))

    if Util.Objects.IsNil(ordering) or Util.Tables.Count(ordering) == 0 then
        ordering = {}

        for i = 1, self:GetButtonCount() do
            ordering[i] = i
        end
    end

    --Logging:Warn("GetButtonOrder(2) : %s", Util.Objects.ToString(ordering))

    return Util.Tables.Sort2(Util.Tables.Copy(ordering))
end

function AddOn:GetButtons()
    return self:MasterLooterDbValue('buttons') or {}
end

--- Fetches a response for given name, based on the group leader's settings if possible
--- @param name number|string the name or index of the response
--- @see MasterLooterDb
--- @see MasterLooter.defaults
--- @return table a table of attributes for named response, if available. otherwise, an empty table
function AddOn:GetResponse(name)
    --Logging:Warn('GetResponse(%s)', tostring(name))

    -- this is the MasterLooter profile db, for use in fallback cases
    -- it's not guaranteed to be consistent with the master looter in situations where
    -- master looter's db has not been received
    local ML = self:MasterLooterModule()

    -- this uses the received master looter db
    local function MasterLooterDbValue()
        if self:HaveMasterLooterDb() then
            return self:MasterLooterDbValue('responses')[name] or nil
        end
        return nil
    end

    -- this access the master looter module's db directly
    local function MasterLooterModuleDbValue()
        return ML:GetDbValue('responses')[name] or nil
    end

    local ResponseValue = Util.Functions.Dispatch(MasterLooterDbValue, MasterLooterModuleDbValue)
    return ResponseValue() or {}
end

function AddOn:AutoPassCheck(class, equipLoc, typeId, subTypeId, classes)
    --Logging:Debug(
    --        "AutoPassCheck() : %s, %s, %s, %s, %s",
    --        tostring(class), tostring(equipLoc), tostring(typeId), tostring(subTypeId), tostring(classes)
    --)
    return not ItemUtil:ClassCanUse(class, classes, equipLoc, typeId, subTypeId)
end

function AddOn:DoAutoPass(lt, skip)
    skip = Util.Objects.Default(skip, 0)
    --Logging:Debug("DoAutoPass(%d, %d)", Util.Tables.Count(lt), skip)
    for session, entry in pairs(lt) do
        session = entry.session or session
        --Logging:Debug("DoAutoPass(%d) : noAutoPass=%s", tonumber(session), tostring(entry.noAutoPass))
        if session > (skip or 0) then
            if not Util.Objects.Default(entry.noAutoPass, false) then
                --- @type Models.Item.Item
                local item = entry:GetItem()
                if not item:IsBoe() then
                    if self:AutoPassCheck(self.player.class, item.equipLoc, item.typeId, item.subTypeId, item.classes) then
                        --Logging:Trace("DoAutoPass() : Auto-passing on %s", item.link)
                        self:Print(format(L["auto_passed_on_item"], item.link))
                        entry.autoPass = true
                    end
                --else
                --    Logging:Trace("DoAutoPass() : skipped auto-pass on %s as it's BOE", item.link)
                end
            end
        end
    end
end

function AddOn:SendLootAck(lt, skip)
    skip = Util.Objects.Default(skip, 0)
    Logging:Debug("SendLootAck(%d, %d)", Util.Tables.Count(lt), skip)
    local hasData, reattempt, toSend = false, false, { gear1 = {}, gear2 = {}, diff = {}, response = {} }
    for session, entry in pairs(lt) do
        session = entry.session or session
        Logging:Debug("SendLootAck(%d)", tonumber(session))
        if session > (skip or 0) then
            hasData = true
            --- @type Models.Item.Item
            local item = entry:GetItem()
            if ItemUtil:IsTokenBasedItem(item.id) then
                local tokenItems = ItemUtil:GetTokenItems(item.id)
                if tokenItems and #tokenItems > 0 then
                    item = Item.Get(tokenItems[1])
                end
            end

            if item then
                local g1, g2 = self:GetPlayersGear(item.link, item.equipLoc)
                local diff = self:GetItemLevelDifference(item.link, g1, g2)
                toSend.gear1[session] = g1 and AddOn.SanitizeItemString(g1) or nil
                toSend.gear2[session] = g2 and AddOn.SanitizeItemString(g2) or nil
                toSend.diff[session] = diff
                toSend.response[session] = Util.Objects.Default(entry.autoPass, false)
            else
                -- the item may not currently be available, set flag and continue
                -- that way we at least try all of the items on this invocation
                -- and callback will likely have them all available (without a need to reattempt again)
                reattempt = true
            end
        end
    end

    if reattempt then
        Logging:Debug("SendLootAck() : re-attemping...")
        self:ScheduleTimer("SendLootAck", 1, lt, skip)
        return
    end

    if hasData then
        self:Send(self.masterLooter, C.Commands.LootAck, self.playerData.ilvl or 0, toSend)
    end
end

--- @return boolean, table<number, Models.Item.ItemRef>
function AddOn:PreProcessLootTable(lt, uncachedCallback)
    --Logging:Debug("PreProcessLootTable(%d)", Util.Tables.Count(lt))
    if not self.enabled then
        for i = 1, #lt do
            self:SendResponse(self.masterLooter, i, C.Responses.Disabled)
        end
        --Logging:Trace("Sent 'disabled' response for all loot table entries")
        return false, nil
    end

    -- lootTable will a table of session to LootTableEntry (as ItemRef) representations
    -- each representations will be generated via LootTableEntry:ForTransmit()
    -- ref = ItemRef:ForTransmit()
    -- E.G. {{ref = 15037:0:0:0:0:0:0::}, {ref = 25798:0:0:0:0:0:0::}}

    -- convert transmitted reference into a LootTableEntry

    --- @type table<number, Models.Item.ItemRef>
    local interim = Util.Tables.Map(
            Util.Tables.Copy(lt),
            function(e, session)
                return LootTableEntry.ItemRefFromTransmit(e, session)
            end,
            true
    )

    -- Logging:Debug("%s", Util.Objects.ToString(interim, 4))
    -- determine how many uncached items there are
    local uncached = Util.Tables.CountFn(interim, function(i) return not i:GetItem() end)

    --Logging:Debug("PreProcessLootTable(%d) : %d, %d", Util.Tables.Count(lt), Util.Tables.Count(interim), uncached)

    -- uh, oh.. try again
    if uncached > 0 then
        self:ScheduleTimer(uncachedCallback, 0, lt)
        return false, nil
    end

    return true, interim
end

function AddOn:OnLootTableReceived(lt)
    --Logging:Debug("OnLootTableReceived() : %d", Util.Tables.Count(lt))
    local continue, processed = self:PreProcessLootTable(lt, "OnLootTableReceived")
    -- could not be pre-processed, will have been rescheduled
    if not continue then
        return
    end

    -- index will be the session, entry will be an LootTableEntry
    -- no need for additional processing, as the ItemRef will pointed to a cached item
    --
    -- these references may be augmented with additional attributes as needed
    -- but nothing else, by default, except the item reference
    self.lootTable = processed

    -- received LootTable without having received MasterLooterDb, well we should ask them for it...
    if not self:HaveMasterLooterDb() then
        Logging:Warn("OnLootTableReceived() : received LootTable without having received MasterLooterDb from %s", tostring(self.masterLooter))
        self:Send(self.masterLooter, C.Commands.MasterLooterDbRequest)
        -- something weird is going on, we asked for ML DB, let's reprocess the loot table after a short delay
        self:ScheduleTimer('OnLootTableReceived', 2, lt)
        return
    end

    -- we're the master looter, start allocation
    if self:IsMasterLooter() then
        AddOn:CallModule("LootAllocate")
        AddOn:LootAllocateModule():ReceiveLootTable(self.lootTable)
    end

    -- for anyone that is currently part of group, but outside of instances
    -- automatically respond to each item (if support is enabled)
    if self:MasterLooterDbValue('outOfRaid') and GetNumGroupMembers() >= 8 and not IsInInstance() then
        --Logging:Debug("OnLootTableReceived() : raid member, but not in the instance. responding to each item to that affect.")
        Util.Tables.Call(
                self.lootTable,
                function(_ , session)
                    self:SendResponse(self.masterLooter, session, C.Responses.NotInRaid)
                end,
                true -- need the index for session id
        )
        return
    end

    self:DoAutoPass(self.lootTable)
    self:SendLootAck(self.lootTable)

    AddOn:CallModule("Loot")
    AddOn:LootModule():Start(self.lootTable)

    Logging:Trace("OnLootTableReceived() : %d", Util.Tables.Count(self.lootTable))
end

function AddOn:OnLootTableAddReceived(lt)
    Logging:Trace("OnLootTableAddReceived() : %d", Util.Tables.Count(lt))

    local continue, processed =
        self:PreProcessLootTable(lt, "OnLootTableAddReceived")
    -- could not be pre-processed, will have been rescheduled
    if not continue then
        return
    end

    --Logging:Trace("OnLootTableAddReceived() : %s", Util.Objects.ToString(processed, 2))

    self:DoAutoPass(processed)
    self:SendLootAck(processed)

    local oldLen = #self.lootTable
    for session, entry in pairs(processed) do
        --Logging:Trace("OnLootTableAddReceived() : adding %s to loot table at index %d", Util.Objects.ToString(entry:toTable()), session)
        self.lootTable[session] = entry
    end

    local Loot = AddOn:LootModule()
    for i = oldLen + 1, #self.lootTable do
        --Logging:Trace("OnLootTableAddReceived() : AddSingleItem(%d)", i)
        Loot:AddSingleItem(self.lootTable[i])
    end

    self:SendMessage(C.Messages.LootTableAddition, processed)
end

function AddOn:OnLootSessionEnd()
    if not self.enabled then return end
    self:Print(format(L["player_ended_session"], self.Ambiguate(self.masterLooter:GetName())))
    self:LootModule():Disable()
    self:LootAllocateModule():EndSession(false)
    self.lootTable = {}
end

function AddOn:OnReRollReceived(sender, lt)
    --Logging:Debug("OnReRollReceived(%s) : %s", tostring(sender), Util.Objects.ToString(lt))

    -- if we get a callback from 1st pass at pre-processing not succeeding
    -- we won't pass back in sender, it only needs announced one time
    if Util.Objects.IsSet(sender) then
        AddOn:Print(format(L["player_requested_reroll"], self.Ambiguate(sender)))
    end

    local continue, processed = self:PreProcessLootTable(lt, "OnReRollReceived")

    -- could not be pre-processed, will have been rescheduled
    if not continue then
        return
    end

    self:DoAutoPass(processed)
    self:SendLootAck(processed)

    self:CallModule("Loot")
    self:LootModule():ReRoll(processed)
end

AddOn.NonUserVisibleResponse = Util.Memoize.Memoize(
    function(responseId)
        local reasons = Util.Tables.CopyFilter(
            AddOn:LootAllocateModule().db.profile.awardReasons,
            function(e) return Util.Objects.IsTable(e) end
        )

        local _, response = Util.Tables.FindFn(
            reasons,
            -- the extra check w/ subtraction of 400 is due to a previous regression where some non user visible
            -- award reasons had 400 added to them, but not consistent throughout usage
            function(e) return (e.sort == responseId) or (responseId > 400 and e.sort == (responseId - 400)) end
        )
        return response
    end
)