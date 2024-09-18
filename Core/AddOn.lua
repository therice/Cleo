--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type Models.Player
local Player = AddOn.ImportPackage('Models').Player
--- @type Models.Encounter
local Encounter = AddOn.ImportPackage('Models').Encounter
--- @type Core.SlashCommands
local SlashCommands = AddOn.Require('Core.SlashCommands')
--- @type Core.Comm
local Comm = AddOn.Require('Core.Comm')
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type LibGuildStorage
local GuildStorage =  AddOn:GetLibrary('GuildStorage')
--- @type Models.SemanticVersion
local SemanticVersion  = AddOn.Package('Models').SemanticVersion

function AddOn:OnInitialize()
    Logging:Debug("OnInitialize(%s)", self:GetName())

    local version, build, date, tocVersion = GetBuildInfo()
    AddOn.BuildInfo = {
        version =  SemanticVersion(version),
        build = build,
        date = date,
        tocVersion = tocVersion,

        -- technically, this is wrath "classic" but that's the only flavor which exists right now
        IsWrath = function(self) return self.version.major == 3 and self.version.minor == 4 end,
        IsWrathP1 = function(self) return self:IsWrath() and self.version.patch == 0 end, -- Naxx
        IsWrathP2 = function(self) return self:IsWrath() and self.version.patch == 1 end, -- Ulduar
        IsWrathP3 = function(self) return self:IsWrath() and self.version.patch == 2 end, -- TOGC
        IsWrathP4 = function(self) return self:IsWrath() and self.version.patch == 3 end, -- ICC

        IsCataclysm = function(self) return self.version.major == 4 and self.version.minor == 4 end,
    }

    Logging:Debug("OnInitialize(%s) : BuildInfo(%s)", self:GetName(), Util.Objects.ToString(AddOn.BuildInfo))

    -- convert to a semantic version
    self.version = SemanticVersion(self.version)
    -- bitfield which keeps track of our operating mode
    --- @type Core.Mode
    self.mode = AddOn.Package('Core').Mode()
    -- is the addon enabled, can be altered at runtime
    self.enabled = true
    -- tracks information about the player at time of login and when encounters begin
    self.playerData = {
        -- slot number -> item link
        gear = {
        }
    }
    -- the ML DB, sent by the master looter
    -- it contains settings as controlled by the ML
    self.mlDb = {}
    -- the master looter (Player)
    self.masterLooter = nil
    -- capture looting method for later required checks
    self.lootMethod = GetLootMethod() or "freeforall"
    -- does addon handle loot?
    self.handleLoot = false
    -- are we currently engaged in combat
    self.inCombat = false
    -- the current encounter
    --- @type Models.Encounter
    self.encounter = Encounter.None
    ---@type table<number, Models.Item.ItemRef>
    self.lootTable = {}
    ---@type table<string, boolean>
    self.group = {}

    self.db = self:GetLibrary("AceDB"):New(self:Qualify('DB'), self.defaults)
    if not AddOn._IsTestContext() then
        Logging:SetRootThreshold(self.db.profile.logThreshold)
    end

    -- register slash commands
    SlashCommands:Register()
    self:RegisterChatCommands()
    self:VersionCheckModule():ClearExpiredVersions()

    -- bootstrap comms
    Comm:Register(C.CommPrefixes.Main)
    Comm:Register(C.CommPrefixes.Version)
    Comm:Register(C.CommPrefixes.Lists)
    Comm:Register(C.CommPrefixes.Audit)
    self.Send = Comm:GetSender(C.CommPrefixes.Main)

    -- subscribe to comms
    self:SubscribeToComms()

    -- register events
    self:SubscribeToEvents()
end

function AddOn:OnEnable()
    local piAvailable = Player.Available()
    Logging:Debug("OnEnable(%s) : Mode=%s, Player Info Available=%s", self:GetName(), tostring(self.mode), tostring(piAvailable))

    -- seems to be client regression introduced in 2.5.4 where the needed API calls to get a player's information
    -- isn't always available on initial login, so reschedule
    if not piAvailable then
        Logging:Warn("OnEnable(%s) : Rescheduling enable due to missing player information", self:GetName())
        AddOn.Timer.Schedule(function() self:ScheduleTimer(function() self:OnEnable() end, 1) end)
        return
    end

    --@debug@
    -- this enables certain code paths that wouldn't otherwise be available in normal usage
    self.mode:Enable(AddOn.Constants.Modes.Develop)
    --@end-debug@

    --@debug@
    -- this enables real time replication of data, only via switch and debug builds for now
    --self.mode:Enable(AddOn.Constants.Modes.Replication)
    --@end-debug@

    -- in debug mode, parse the version from the Changelog
    --@debug@
    local _, latestVersion = AddOn.GetParsedChangeLog()
    if latestVersion then
        AddOn.version = SemanticVersion(tostring(latestVersion) .. '-dev')
    end
    --@end-debug@

    -- this enables flag for persistence of stuff like lists, history, and sync payloads
    -- it can be disabled as needed through /cleo pm
    self.mode:Enable(AddOn.Constants.Modes.Persistence)

    --- @type Models.Player
    self.player = Player:Get("player")
    -- UpdateGroupMembers relies upon player having been established, so do it after
    -- batches events for up to 5 seconds prior to firing
    self:RegisterBucketEvent("GROUP_ROSTER_UPDATE", 5, function() self:UpdateGroupMembers() end)

    Logging:Debug("OnEnable(%s) : %s", self:GetName(), tostring(self.player))

    -- purge expired player cache entries
    AddOn.Timer.Schedule(function() AddOn.Timer.After(2, function() Player.MaintainCache() end) end)


    local configSupplements, lpadSupplements = {}, {}
    for name, module in self:IterateModules() do
        Logging:Debug("OnEnable(%s) : Examining module (startup) '%s'", self:GetName(), name)
        if module:EnableOnStartup() then
            Logging:Debug("OnEnable(%s) : Enabling module (startup) '%s'", self:GetName(), name)
            module:Enable()
        end

        -- extract module's configuration supplement for later application
        local cname, cfn = self:GetConfigSupplement(module)
        if cname and cfn then
            configSupplements[cname] = cfn
        end

        local mname, metadata = self:GeLaunchpadSupplement(module)
        if mname and metadata then
            lpadSupplements[mname] = metadata
        end
    end

    -- track launchpad (UI) supplements for application as needed
    -- will only be applied the first time the UI is displayed
    -- {applied [boolean], configuration supplements [table], launchpad supplements [table]}
    self.supplements = {false, configSupplements, lpadSupplements}
    -- add minimap button
    self:AddMinimapButton()
    self:Print(format(L["chat_version"], tostring(self.version)) .. " is now loaded.")

    -- this filters out any responses to whispers related to addon
    local ChatMsgWhisperInformFilter = function(_, event, msg, player, ...)
        return strfind(msg, "[[" .. self:GetName() .. "]]:")
    end
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ChatMsgWhisperInformFilter)

    -- this filters (and captures) relevant messages related to attempting to contact individual players
    local ChatMsgFilter = function(f, event, msg, player, ...)
        if msg:match(string.format(ERR_CHAT_PLAYER_NOT_FOUND_S, "(.+)")) then
            local regex = gsub(ERR_CHAT_PLAYER_NOT_FOUND_S, "%%s", "(.+)")
            local _, _, character = strfind(msg, regex)
            --Logging:Trace("%s - %s", msg, character)
            -- if a player is not found, dispatch the message and let subscribers handle as they see fit
            self:SendMessage(C.Messages.PlayerNotFound, character)
        end

        -- don't muck with workflow here, just return what was passed and let it flow onward
        return false, msg, player, ...
    end

    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", ChatMsgFilter)
end

function AddOn:OnDisable()
    Logging:Debug("OnDisable(%s)", self:GetName())
    self:UnregisterAllBuckets()
    self:UnsubscribeFromEvents()
    self:UnsubscribeFromComms()
    SlashCommands:Unregister()
end

--- @param itemCount number
--- @param playerCount number
function AddOn:Test(itemCount, playerCount)
    playerCount = Util.Objects.IsSet(playerCount) and tonumber(playerCount) or nil
    Logging:Debug("Test(%d, %d)", itemCount, playerCount or -1)

    local items = Util.Tables.Temp()
    for _ = 1, itemCount do
        Util.Tables.Push(items, AddOn.TestItems[random(1, #AddOn.TestItems)])
    end

    local players = {}
    if Util.Objects.IsNumber(playerCount) and IsInGuild() then
        local candidates = Util.Tables.Keys(GuildStorage:GetMembers())
        Util.Tables.Shuffle(candidates)

        for _ , name in pairs(candidates) do
            if Util.Objects.IsNil(name) then
                break
            end

            if not Util.Strings.Equal(AddOn.player:GetName(), name) and Player.Resolve(name) then
                Util.Tables.Push(players, name)

                playerCount = playerCount - 1
                if playerCount <= 0 then
                    break
                end
            end
        end
    end

    -- attempt to enable test mode and become master looter
    -- if not successful, test mode will be disabled so return
    if not self.Testing:EnableAndBecomeMasterLooter() then
        return
    end
    -- below is the previous implementation, kept as reference for an interim amount of time
    --[[
    self.mode:Enable(C.Modes.Test)
    _, self.masterLooter = self:GetMasterLooter()

    if not self:IsMasterLooter() then
        self:Print(L["error_test_as_non_leader"])
        self.Testing:Disable()
        return
    end

    local ML = self:MasterLooterModule()
    self:CallModule(ML:GetName())
    ML:NewMasterLooter(self.masterLooter)
    --]]

    self:MasterLooterModule():Test(items, Util.Tables.Count(players) > 0 and players or nil)
end