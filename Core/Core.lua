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

--- @return Sync
function AddOn:SyncModule()
    return self:GetModule("Sync")
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
                function(count)
                    self:Test(tonumber(count) or 2)
                end
            }
    )
end

function AddOn:IsMasterLooter(unit)
    unit = Util.Objects.Default(unit, self.player)
    Logging:Trace("IsMasterLooter() : unit=%s, ml=%s", tostring(unit), tostring(self.masterLooter))
    return self.masterLooter and AddOn.UnitIsUnit(unit, self.masterLooter)
end

function AddOn:GetMasterLooter()
    Logging:Debug("GetMasterLooter()")
    local lootMethod, mlPartyId, mlRaidId = GetLootMethod()
    self.lootMethod = lootMethod
    Logging:Trace(
            "GetMasterLooter() : lootMethod='%s', mlPartyId=%s, mlRaidId=%s",
            self.lootMethod, tostring(mlPartyId), tostring(mlRaidId)
    )

    -- always the player when testing alone
    if GetNumGroupMembers() == 0 and (self:TestModeEnabled() or self:DevModeEnabled()) then
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

    -- ML is set, but it's an unknown player
    if Util.Objects.IsSet(self.masterLooter) and
            (
                Util.Strings.Equal(self.masterLooter:GetName(), "Unknown") or
                Util.Strings.Equal(Ambiguate(self.masterLooter:GetName(), "short"):lower(), _G.UNKNOWNOBJECT:lower())
            )
    then
        Logging:Warn("NewMasterLooterCheck() : Unknown Master Looter")
        return self:ScheduleTimer("NewMasterLooterCheck", 1)
    end

    -- at this point we can check if we're the ML, it's not changing
    local isML = self:IsMasterLooter()
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

    -- request ML DB if not received within 15 seconds
    self:ScheduleTimer(
            function()
                if Util.Objects.IsSet(self.masterLooter) then
                    -- base check on an attribute that should be present
                    if not self:HaveMasterLooterDb() then
                        self:Send(self.masterLooter, C.Commands.MasterLooterDbRequest)
                    end
                end
            end,
            15
    )

    -- Someone else has become ML, nothing additional to do
    if not isML and Util.Objects.IsSet(self.masterLooter) then
        Logging:Trace("NewMasterLooterCheck() : Another player is the Master Looter")
        return
    end

    -- not in raid and setting is to only use in raids
    if not IsInRaid() and ML:GetDbValue('onlyUseInRaids') then
        Logging:Trace("NewMasterLooterCheck() : Not in raid and configuration specifies not to use")
        return
    end

    -- already handling loot, just bail
    if self.handleLoot then
        Logging:Trace("NewMasterLooterCheck() : Already handling loot")
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
        return Dialog:Spawn(C.Popups.ConfirmUsage)
    end
end

function AddOn:StartHandleLoot()
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
    self:CallModule("MasterLooter")
    ML:NewMasterLooter(self.masterLooter)
    ML:OnHandleLootStart()
    -- this message is not currently used, so commented out
    -- self:Send(C.group, C.Commands.HandleLootStart)
end

function AddOn:StopHandleLoot()
    Logging:Debug("StopHandleLoot()")
    self:MasterLooterModule():OnHandleLootStop()
    -- must set this after, or call to OnHandleLootStop() won't be handled
    self.handleLoot = false
    -- this message is not currently used, so commented out
    -- self:Send(C.group, C.Commands.HandleLootStop)
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

    Logging:Trace("OnMasterLooterDbReceived() : %s", Util.Objects.ToString(self.mlDb, 4))
end

function AddOn:UpdateGroupMembers()
    Logging:Trace("UpdateGroupMembers() : current count is %d", #self.group)

    local group, name, reschedule = {}, nil, false
    for i = 1, GetNumGroupMembers() do
        name = GetRaidRosterInfo(i)
        if not name then
            Logging:Warn("UpdateGroupMembers(%d) : raid roster info not yet available, rescheduling", i)
            reschedule = true
            break
        end

        group[self:UnitName(name)] = true
    end


    if reschedule then
        -- reschedule another attempt, don't mutate current state
        self:ScheduleTimer("UpdateGroupMembers", 1)
    else
        -- make sure we are present
        -- e.g. {'Jackburtón-Atiesh' = true}
        group[self:UnitName(self.player:GetName())] = true
        --[[
        group[self:UnitName("Avalona-Atiesh")] = true
        group[self:UnitName("Octane-Atiesh")] = true
        group[self:UnitName("Djbrave-Atiesh")] = true
        --]]

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


        -- track current state
        -- currently, nothing in the code path which consumes player joined/left messages relies
        -- upon the current state here being up to date
        -- if that were to change, could collect the messages to be dispatched in for loops above
        -- then dispatch them after the group (state) has been updated to reflect current group
        self.group = group
    end

    Logging:Trace("UpdateGroupMembers() : %s", Util.Objects.ToString(self.group))

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

    if Util.Objects.IsNil(ordering) or Util.Tables.Count(ordering) == 0 then
        ordering = {}

        for i = 1, self:GetButtonCount() do
            ordering[i] = i
        end
    end

    return Util.Tables.Copy(ordering)
end

function AddOn:GetButtons()
    return self:MasterLooterDbValue('buttons') or {}
end

--- Fetches a response for given name, based on the group leader's settings if possible
--- @param name number|string the name or index of the response
--- @see MasterLooterDb
--- @return table a table of attributes for named response, if available
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
    Logging:Debug("DoAutoPass(%d, %d)", Util.Tables.Count(lt), skip)
    for session, entry in pairs(lt) do
        session = entry.session or session
        Logging:Debug("DoAutoPass(%d) : noAutoPass=%s", tonumber(session), tostring(entry.noAutoPass))
        if session > (skip or 0) then
            if not Util.Objects.Default(entry.noAutoPass, false) then
                --- @type Models.Item.Item
                local item = entry:GetItem()
                if not item:IsBoe() then
                    if self:AutoPassCheck(self.player.class, item.equipLoc, item.typeId, item.subTypeId, item.classes) then
                        Logging:Trace("DoAutoPass() : Auto-passing on %s", item.link)
                        self:Print(format(L["auto_passed_on_item"], item.link))
                        entry.autoPass = true
                    end
                else
                    Logging:Trace("DoAutoPass() : skipped auto-pass on %s as it's BOE", item.link)
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
function AddOn:_PreProcessLootTable(lt, uncachedCallback)
    Logging:Debug("_PreProcessLootTable(%d)", Util.Tables.Count(lt))

    --- return continue, lt
    if not self.enabled then
        for i = 1, #lt do
            self:SendResponse(self.masterLooter, i, C.Responses.Disabled)
        end
        Logging:Trace("Sent 'disabled' response for all loot table entries")
        return false, nil
    end

    -- lootTable will a table of session to LootTableEntry (as ItemRef) representations
    -- each representations will be generated via LootTableEntry:ForTransmit()
    -- ref = ItemRef:ForTransmit()
    -- E.G.
    -- {{ref = 15037:0:0:0:0:0:0::}, {ref = 25798:0:0:0:0:0:0::}}

    -- convert transmitted reference into a LootTableEntry
    local interim = Util.Tables.Map(
            Util.Tables.Copy(lt),
            function(e, session)
                return LootTableEntry.ItemRefFromTransmit(e, session)
            end,
            true
    )

    -- Logging:Debug("%s", Util.Objects.ToString(interim, 4))
    -- determine how many uncached items there are
    local uncached = Util.Tables.CountFn(
            interim,
            function(i)
                return not i:GetItem()
            end
    )

    Logging:Debug("_PreProcessLootTable(%d) : %d, %d", Util.Tables.Count(lt), Util.Tables.Count(interim), uncached)

    -- uh, oh.. try again
    if uncached > 0 then
        self:ScheduleTimer(uncachedCallback, 0, lt)
        return false, nil
    end

    return true, interim
end

function AddOn:OnLootTableReceived(lt)
    Logging:Debug("OnLootTableReceived() : %d", Util.Tables.Count(lt))
    local continue, processed = self:_PreProcessLootTable(lt, "OnLootTableReceived")
    -- could not be pre-processed, will have been rescheduled
    if not continue then return end

    -- index will be the session, entry will be an LootTableEntry
    -- no need for additional processing, as the ItemRef will pointed to a cached item
    --
    -- these references may be augmented with additional attributes as needed
    -- but nothing else, by default, except the item reference
    self.lootTable = processed

    -- received LootTable without having received MasterLooterDb, well...
    if not self:HaveMasterLooterDb() then
        Logging:Warn("OnLootTableReceived() : received LootTable without having received MasterLooterDb from %s", tostring(self.masterLooter))
        self:Send(self.masterLooter, C.Commands.MasterLooterDbRequest)
        self:ScheduleTimer('OnLootTableReceived', 5, lt)
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
        Logging:Debug("OnLootTableReceived() : raid member, but not in the instance. responding to each item to that affect.")
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

    Logging:Debug("OnLootTableReceived() : %d", Util.Tables.Count(self.lootTable))
end

function AddOn:OnLootTableAddReceived(lt)
    Logging:Debug("OnLootTableAddReceived() : %d", Util.Tables.Count(lt))

    local continue, processed =
        self:_PreProcessLootTable(lt, "OnLootTableAddReceived")
    -- could not be pre-processed, will have been rescheduled
    if not continue then return end

    Logging:Debug("OnLootTableAddReceived() : %s", Util.Objects.ToString(processed, 4))

    self:DoAutoPass(processed)
    self:SendLootAck(processed)

    local oldLen = #self.lootTable
    for session, entry in pairs(processed) do
        Logging:Debug("OnLootTableAddReceived() : adding %s to loot table at index %d", Util.Objects.ToString(entry:toTable()), session)
        self.lootTable[session] = entry
    end

    local Loot = AddOn:LootModule()
    for i = oldLen + 1, #self.lootTable do
        Logging:Debug("OnLootTableAddReceived() : AddSingleItem(%d)", i)
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
    Logging:Debug("OnReRollReceived(%s) : %s", tostring(sender), Util.Objects.ToString(lt))

    -- if we get a callback from 1st pass at pre-processing not succeeding
    -- we won't pass back in sender, it only needs announced one time
    if Util.Objects.IsSet(sender) then
        AddOn:Print(format(L["player_requested_reroll"], self.Ambiguate(sender)))
    end

    local continue, processed = self:_PreProcessLootTable(lt, "OnReRollReceived")

    -- could not be pre-processed, will have been rescheduled
    if not continue then return end

    for _, entry in pairs(processed) do
        Logging:Debug("OnReRollReceived() : %s", Util.Objects.ToString(entry:toTable()))
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
            -- award resasons had 400 added to them, but not consistent throughout usage
            function(e) return (e.sort == responseId) or (responseId > 400 and e.sort == (responseId - 400)) end
        )
        return response
    end
)