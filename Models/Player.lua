--- @type AddOn
local _, AddOn = ...
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
local Logging = AddOn:GetLibrary("Logging")
--- @type LibGuildStorage
local GuildStorage = AddOn:GetLibrary("GuildStorage")
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")

--- @class Models.Player
local Player = AddOn.Package('Models'):Class('Player')

--- @type Models.Date
local Date = AddOn.Package('Models').Date
--- @type Models.DateFormat
local DateFormat = AddOn.Package('Models').DateFormat

local GuidPatternPremable, GuidPatternRemainder = "Player%-", "%d?%d?%d?%d%-%x%x%x%x%x%x%x%x"
local GuidPattern = GuidPatternPremable .. GuidPatternRemainder
local cache

local function InitializeCache()
    cache = setmetatable(
            {},
            {
                __index = function(_, id)
                    if not AddOn.db.global.cache.player then
                        AddOn.db.global.cache.player = {}
                    end
                    return AddOn.db.global.cache.player[id]
                end,
                __newindex = function(_, id, v)
                    AddOn.db.global.cache.player[id] = v
                end,
            }
    )
end

local function Remove(guid)
    if guid then
        cache[guid] = nil
    end
end

local function Put(player)
    player.timestamp = GetServerTime()
    cache[player.guid] = player:toTable()
end

local SECS_IN_DAY = (60 * 60 * 24) -- seconds in a day
local DEFAULT_CACHE_DURATION = (SECS_IN_DAY * 7) -- 7 days
local CacheDuration = Util.Optional.empty()

local function GetCacheDuration()
    if AddOn._IsTestContext() then
        return 0
    else
        return CacheDuration:orElse(DEFAULT_CACHE_DURATION)
    end
end

local function IsCachedPlayerValid(player)
    if player and (GetServerTime() - player.timestamp <= GetCacheDuration()) then
        return true
    end

    return false
end

local function Get(guid)
    local player = cache[guid]


    if IsCachedPlayerValid(player) then
        return Player:reconstitute(player)
    else
        Logging:Trace('Get(%s) : Cached entry expired at %s', tostring(guid), player and DateFormat.Full:format(Date(player.timestamp)) or "(nil)")
        Remove(guid)
    end

    return nil
end

local function GUID(name)
    for guid, player in pairs(AddOn.db.global.cache.player) do
        if Util.Strings.Equal(Ambiguate(player.name, "short"), name) or Util.Strings.Equal(player.name, name) then
            return guid
        end
    end
end

InitializeCache()

function Player:initialize(guid, name, class, realm)
    self.guid = guid
    self.name = name and AddOn:UnitName(name) or nil
    self.class = class
    self.realm = realm
    self.timestamp = -1
    --Logging:Debug("Player(%s, %s, %s)", tostring(name), tostring(self.name), tostring(self.realm))
end

function Player:IsValid()
    return Util.Objects.IsSet(self.guid) and Util.Objects.IsSet(self.name) and Util.Objects.IsSet(self.class) and Util.Objects.IsSet(self.realm)
end

--- @return boolean indicating if player is 'Unknown'
function Player:IsUNK()
   return Util.Strings.Equal(self:GetShortName(), 'Unknown') or Util.Strings.Equal(Ambiguate(self:GetName(), "short"):lower(), _G.UNKNOWNOBJECT:lower())
end

function Player:GetName()
    return self.name
end

function Player:GetShortName()
    return Ambiguate(self.name, "short")
end

function Player:GetClassId()
    return self.class and ItemUtil.ClassTagNameToId[self.class] or 0
end

function Player:ForTransmit()
    return Player.StripGuidPrefix(self.guid)
end

function Player:Update(data)
    --Logging:Debug("Player[Before] : %s, Data : %s", Util.Objects.ToString(self:toTable()), Util.Objects.ToString(data))
    for k, v in pairs(data) do
        if v == AddOn.NIL then
            self[k] = nil
        else
            self[k] = v
        end
    end
    --Logging:Debug("Player[After] : %s", Util.Objects.ToString(self:toTable()))
    Put(self)
end

function Player:GetInfo()
    return GetPlayerInfoByGUID(self.guid)
end

function Player:__tostring()
    return self.name .. ' (' .. tostring(self.guid or '???') .. ')'
end

function Player:__lt(o)
    return self:GetShortName() < o:GetShortName()
end

function Player:__eq(o)
    return Util.Strings.Equal(self.guid, o.guid)
end

function Player.Available()
    local guid = UnitGUID(Ambiguate("player", "short"))
    local _, _, _, _, _, name = GetPlayerInfoByGUID(guid)
    return Util.Objects.IsSet(name)
end

Player.Nobody = Player()
Player.Nobody.name = "Nobody"
Player.Nobody.class = "DEATHKNIGHT"
Player.Nobody.guid = "Player-9999-XXXXXXXX"

function Player.Create(guid, info)
    --Logging:Debug("Create(%s) : info=%s", tostring(guid), tostring(Util.Objects.IsSet(info)))
    if Util.Strings.IsEmpty(guid) then return Player(nil, 'Unknown', nil, nil) end

    -- https://wow.gamepedia.com/API_GetPlayerInfoByGUID
    -- The information is not encoded in the GUID itself; as such, no data is available until
    -- the client has encountered the queried GUID.
    -- localizedClass, englishClass, localizedRace, englishRace, sex, name, realm
    local _, class, _, _, _, name, realm = GetPlayerInfoByGUID(guid)
    --Logging:Debug("Create(%s) : info query -> class=%s, name=%s, realm=%s", guid, tostring(class), tostring(name), tostring(realm))

    -- if the name is not set, means the query did not complete. likely because the player was not
    -- encountered. therefore, just return nil
    if Util.Objects.IsEmpty(name) then
        --Logging:Debug("Create(%s) : Unable to obtain player information via GetPlayerInfoByGUID", guid)
        if info and Util.Strings.IsSet(info.name) then
            --Logging:Debug("Create(%s) : Using provided player information", guid)
            name = info.name
            class = info.classTag or info.class
        else
            return nil
        end
    end

    if Util.Objects.IsEmpty(realm) then
        realm = AddOn:RealmName()
    end

    local player = Player(guid, name, class, realm)
    Logging:Trace("Create(%s) : created %s", guid, Util.Objects.ToString(player:toTable()))
    Put(player)
    return player
end

--/run print(Cleo.Package('Models').Player:Get('Eliovak'))
--/run print(Cleo.Package('Models').Player:Get('Eliovak-Atiesh'))
--/run print(Cleo.Package('Models').Player:Get('Gnomechómsky'))
function Player:Get(input)
    local guid, info
    --Logging:Trace("Get(%s)", tostring(input))

    if Util.Strings.IsSet(input) then
        guid = Player.ParseGuid(input)
        --Logging:Debug("Get(%s) : %s", tostring(input), tostring(guid))

        if Util.Objects.IsNil(guid) then
            local name = Ambiguate(input, "short")
            -- For players: Player-[server ID]-[player UID] (Example: "Player-976-0002FD64")
            guid = UnitGUID(name)
            --Logging:Debug("Get(%s) : %s / %s", tostring(input), tostring(name), tostring(guid))
            -- GUID(s) are only available for people we're grouped with
            -- so attempt a few other approaches if not available
            --
            -- via existing cached players
            if Util.Strings.IsEmpty(guid) then
                guid = GUID(name)
                -- last attempt is try via the guild
                if Util.Strings.IsEmpty(guid) then
                    -- fully qualify the name for guild query
                    info = GuildStorage:GetMember(AddOn:UnitName(name))
                    if info then guid = info.guid end
                end
            end

            -- if the name is 'player', grab some extra information in case it's not available at login
            -- this is an edge case for player using addon on initial login
            if Util.Strings.Equal(Util.Strings.Lower(name), AddOn.Constants.player) and not info then
                local n, _ = UnitName(name)
                local _, c = UnitClass(name)

                info = {
                    name = n,
                    class = c,
                }
            end
        end
    else
        error(format("'%s' (%s) is an invalid player", Util.Objects.ToString(input), type(input)), 2)
    end

    -- Logging:Trace("Get(%s) : GUID=%s", tostring(input), tostring(guid))

    if Util.Strings.IsEmpty(guid) then
        Logging:Warn("Get(%s) : unable to determine GUID", tostring(input))
    end

    return Get(guid) or Player.Create(guid, info)
end

--- @return Models.Player
function Player.Resolve(p)
    if Util.Objects.IsInstanceOf(p, Player) then
        return p
    elseif Util.Objects.IsString(p) then
        return Player:Get(p)
    else
        return nil
    end
end

function Player.ParseGuid(input)
    local guid

    if not strmatch(input, GuidPatternPremable) and strmatch(input, GuidPatternRemainder) then
        guid = "Player-" .. input
    elseif strmatch(input, GuidPattern) then
        guid = input
    end

    return guid
end

function Player.StripGuidPrefix(input)
    return gsub(input, GuidPatternPremable, "")
end

function Player.IsUnknown(p)
    --- @type Models.Player
    local player = Player.Resolve(p)
    return Util.Objects.IsNil(player) or player:IsUNK()
end

function Player.Unknown(guid)
    return Player(Player.ParseGuid(guid), 'Unknown','DEATHKNIGHT', select(2, UnitFullName("player")))
end

function Player.ToggleCache()
    if CacheDuration:isEmpty() then
        CacheDuration = Util.Optional.of(0)
    else
        CacheDuration = Util.Optional.empty()
    end
end

function Player.GetCacheDurationInDays()
    return GetCacheDuration() / SECS_IN_DAY
end

function Player.ClearCache()
    AddOn.db.global.cache.player = {}
end

function Player.MaintainCache()
    if AddOn.db then
        -- We wrap the db as 'cache' for access (above), but cannot use it directly due to setmetatable semantics
        -- Certainly there's a way to access it consistently, but not investing time and instead access underlying
        -- storage directly
        local playerCache = Util.Tables.Get(AddOn.db, "global.cache.player")
        if playerCache then
            for guid, entry in pairs(playerCache) do
                if not IsCachedPlayerValid(entry) then
                    Logging:Debug("MaintainCache(%s, %s) : Removing from player cache", guid, Util.Objects.ToString(entry))
                    Remove(guid)
                end
            end
        end
    end
end

if AddOn._IsTestContext('Models_Player') then
    function Player.GetCache()
        return AddOn.db.global.cache.player
    end

    function Player.ReinitializeCache()
        cache = nil
        InitializeCache()
    end

    if not AddOn.db then AddOn.db = {} end
    if not Util.Tables.Get(AddOn.db, 'global.cache') then
        Util.Tables.Set(AddOn.db, 'global.cache', {})
    end

    Player.ReinitializeCache()
end

