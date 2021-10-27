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


function AddOn:OnInitialize()
    Logging:Debug("OnInitialize(%s)", self:GetName())
    -- convert to a semantic version
    self.version = AddOn.Package('Models').SemanticVersion(self.version)
    -- bitfield which keeps track of our operating mode
    self.mode = AddOn.Package('Core').Mode()
    -- is the addon enabled, can be altered at runtime
    self.enabled = true
    -- tracks information about the player at time of login and when encounters begin
    self.playerData = {
        -- slot number -> item link
        gear = {
        }
    }
    -- our guild (start off as unguilded, will get callback when ready to populate)
    self.guildRank = L["unguilded"]
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
    self.encounter = Encounter.None
    ---@type table<number, Models.Item.ItemRef>
    self.lootTable = {}
    ---@type table<string, boolean>
    self.group = {}

    self.db = self:GetLibrary("AceDB"):New(self:Qualify('DB'), self.defaults)
    if not AddOn._IsTestContext() then Logging:SetRootThreshold(self.db.profile.logThreshold) end

    -- register slash commands
    SlashCommands:Register()
    self:RegisterChatCommands()
    self:VersionCheckModule():ClearExpiredVersions()

    -- setup comms
    Comm:Register(C.CommPrefixes.Main)
    Comm:Register(C.CommPrefixes.Version)
    Comm:Register(C.CommPrefixes.Lists)
    Comm:Register(C.CommPrefixes.Audit)
    self.Send = Comm:GetSender(C.CommPrefixes.Main)
    self:SubscribeToPermanentComms()
end

function AddOn:OnEnable()
    Logging:Debug("OnEnable(%s) : Mode=%s", self:GetName(), tostring(self.mode))

    --@debug@
    -- this enables certain code paths that wouldn't otherwise be available in normal usage
    self.mode:Enable(AddOn.Constants.Modes.Develop)
    --@end-debug@

    -- this enables flag for persistence of stuff like lists, history, and sync payloads
    -- it can be disabled as needed through /cleo pm
    self.mode:Disable(AddOn.Constants.Modes.Persistence)
    --- @type Models.Player
    self.player = Player:Get("player")

    Logging:Debug("OnEnable(%s) : %s", self:GetName(), tostring(self.player))
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

    if IsInGuild() then
        -- Register with guild storage for state change callback
        GuildStorage.RegisterCallback(
                self,
                GuildStorage.Events.StateChanged,
                function(event, state)
                    Logging:Debug("GuildStorage.Callback(%s, %s)", tostring(event), tostring(state))
                    if state == GuildStorage.States.Current then
                        local me = GuildStorage:GetMember(AddOn.player:GetName())
                        if me then
                            AddOn.guildRank = me.rank
                            GuildStorage.UnregisterCallback(self, GuildStorage.Events.StateChanged)
                            Logging:Debug("GuildStorage.Callback() : Guild Rank = %s", AddOn.guildRank)
                        else
                            Logging:Debug("GuildStorage.Callback() : Not Found")
                            AddOn.guildRank = L["not_found"]
                        end
                    end
                end
        )
    end

    -- register events
    self:SubscribeToEvents()
    self:RegisterBucketEvent("GROUP_ROSTER_UPDATE", 5, "UpdateGroupMembers")

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
            Logging:Trace("%s - %s", msg, character)
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
    SlashCommands:Unregister()
end

function AddOn:Test(count)
    Logging:Debug("Test(%d)", count)
    local items = Util.Tables.Temp()
    for _ =1, count do
        Util.Tables.Push(items, AddOn.TestItems[random(1, #AddOn.TestItems)])
    end

    self.mode:Enable(C.Modes.Test)
    self.isMasterLooter, self.masterLooter = self:GetMasterLooter()

    if not self.isMasterLooter then
        self:Print(L["error_test_as_non_leader"])
        self.mode:Disable(C.Modes.Test)
        return
    end

    self:CallModule("MasterLooter")
    local ML = self:MasterLooterModule()
    ML:NewMasterLooter(self.masterLooter)
    ML:Test(items)
end