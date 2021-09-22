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

local function ModeToggle(self, flag)
    if self.mode:Enabled(flag) then self.mode:Disable(flag) else self.mode:Enable(flag) end
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

function AddOn:RegisterChatCommands()
    Logging:Debug("RegisterChatCommands(%s)", self:GetName())
    SlashCommands:BulkSubscribe(
            {
                { 'config', 'c' },
                L['chat_commands_config'],
                function() AddOn.ToggleConfig() end,
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
            }
    )
end


function AddOn:UpdateGroupMembers()
    Logging:Trace("UpdateGroupMembers()")
    for i = 1, GetNumGroupMembers() do
        self.group[self:UnitName(GetRaidRosterInfo(i))] = true
    end
    -- make sure we are present
    self.group[self.player.name] = true

    --in test mode, add some other players to help with testing
    --if AddOn:TestModeEnabled() then
    --    self.group['Gnomechómsky-Atiesh'] = true
    --    self.group['Cerrendel-Atiesh'] = true
    --end

    return self.group
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
        -- todo
        -- self:ScheduleTimer("Timer", 5, AddOn.Constants.Commands.MasterLooterDbCheck)
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

    --[[
    -- at this point we can check if we're the ML, it's not changing
    local isML = self:IsMasterLooter()
    -- old ML is us, but no longer ML
    if self:UnitIsUnit(oldMl, "player") and not isML then
        self:StopHandleLoot()
    end

    -- is current ML unset
    if Util.Objects.IsEmpty(self.masterLooter) then return end

    -- old ML is us, new ML is us (implied by check above) and loot method has not changed
    if self:UnitIsUnit(oldMl, self.masterLooter) and Util.Strings.Equal(oldLm, self.lootMethod) then
        Logging:Debug("NewMasterLooterCheck() : No Master Looter change")
        return
    end

    local ML = self:MasterLooterModule()
    -- settings say to never use
    if ML:GetDbValue('usage.never') then
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
    if isML and ML:GetDbValue('usage.ml') then
        self:StartHandleLoot()
        -- we're the ML and settings say to ask
    elseif isML and ML:GetDbValue('usage.ask_ml') then
        return Dialog:Spawn(C.Popups.ConfirmUsage)
    end
    --]]
end


function AddOn:UpdateGroupMembers()
    Logging:Trace("UpdateGroupMembers()")
    for i = 1, GetNumGroupMembers() do
        self.group[self:UnitName(GetRaidRosterInfo(i))] = true
    end
    -- make sure we are present
    self.group[self.player.name] = true

    --in test mode, add some other players to help with testing
    --if AddOn:TestModeEnabled() then
    --    self.group['Gnomechómsky-Atiesh'] = true
    --    self.group['Cerrendel-Atiesh'] = true
    --end

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