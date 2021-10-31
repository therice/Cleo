--- @type AddOn
local _, AddOn = ...
local Util, Logging, GuildStorage = AddOn:GetLibrary("Util"), AddOn:GetLibrary("Logging"), AddOn:GetLibrary("GuildStorage")

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
                    if not AddOn.db.global.cache.player then AddOn.db.global.cache.player = {} end
                    return AddOn.db.global.cache.player[id]
                end,
                __newindex = function(_, id, v)
                    AddOn.db.global.cache.player[id] = v
                end
            }
    )
end

local function Put(player)
    player.timestamp = GetServerTime()
    cache[player.guid] = player:toTable()
end

-- none of the cached stuff is going to change, bump retention from 2 days to 30
local CACHE_TIME = Util.Memoize.Memoize(
    function()
        return AddOn:DevModeEnabled() and 0  or (60 * 60 * 24 * 30) -- 30 days
    end
)

local function Get(guid)
    local player = cache[guid]
    if player then
        Logging:Trace('Get(%s) : %s', tostring(guid), Util.Objects.ToString(player))
        if GetServerTime() - player.timestamp <= CACHE_TIME() then
            return Player:reconstitute(player)
        else
            Logging:Warn('Get(%s) : Cached entry expired at %s', tostring(guid), DateFormat.Full:format(Date(player.timestamp)))
        end
    else
        Logging:Trace("Get(%s) : No cached entry", tostring(guid))
    end

    return nil
end

local function GUID(name)
    for guid, player in pairs(AddOn.db.global.cache.player) do
        if Util.Strings.Equal(Ambiguate(player.name, "short"), name) then
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
end

function Player:IsValid()
    return Util.Objects.IsSet(self.guid) and Util.Objects.IsSet(self.name)
end

function Player:GetName()
    return self.name
end

function Player:GetShortName()
    return Ambiguate(self.name, "short")
end

function Player:ForTransmit()
    return gsub(self.guid, GuidPatternPremable, "")
end

function Player:Update(data)
    for k, v in pairs(data) do
        self[k] = v
    end
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

Player.Nobody = Player()
Player.Nobody.name = "Nobody"
Player.Nobody.class = "DEATHKNIGHT"
Player.Nobody.guid = "Player-9999-XXXXXXXX"

function Player.Create(guid, info)
    Logging:Trace("Create(%s) : info=%s", tostring(guid), tostring(Util.Objects.IsSet(info)))
    if Util.Strings.IsEmpty(guid) then return Player(nil, 'Unknown', nil, nil) end

    -- https://wow.gamepedia.com/API_GetPlayerInfoByGUID
    -- The information is not encoded in the GUID itself; as such, no data is available until
    -- the client has encountered the queried GUID.
    -- localizedClass, englishClass, localizedRace, englishRace, sex, name, realm
    local _, class, _, _, _, name, realm = GetPlayerInfoByGUID(guid)
    Logging:Trace("Create(%s) : info query -> class=%s, name=%s, realm=%s", guid, tostring(class), tostring(name), tostring(realm))
    -- if the name is not set, means the query did not complete. likely because the player was not
    -- encountered. therefore, just return nil
    if Util.Objects.IsEmpty(name) then
        Logging:Warn("Create(%s) : Unable to obtain player information via GetPlayerInfoByGUID", guid)
        if info and Util.Strings.IsSet(info.name) then
            --Logging:Trace("Create(%s) : Using provided player information", guid)
            name = info.name
            class = info.classTag or info.class
        else
            return nil
        end
    end

    if Util.Objects.IsEmpty(realm) then realm = select(2, UnitFullName("player")) end

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
    -- Logging:Debug("Get(%s)", tostring(input))

    if Util.Strings.IsSet(input) then
        guid = Player.ParseGuid(input)

        if Util.Objects.IsNil(guid) then
            local name = Ambiguate(input, "short")
            -- For players: Player-[server ID]-[player UID] (Example: "Player-976-0002FD64")
            guid = UnitGUID(name)
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
        end
    else
        error(format("%s (%s) is an invalid player", Util.Objects.ToString(input), type(input)), 2)
    end

    -- Logging:Trace("Get(%s) : GUID=%s", tostring(input), tostring(guid))

    if Util.Strings.IsEmpty(guid) then
        Logging:Warn("Get(%s) : unable to determine GUID", tostring(input))
    end

    return Get(guid) or Player.Create(guid, info)
end

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

function Player.Unknown(guid)
    return Player(Player.ParseGuid(guid), 'Unknown','DEATHKNIGHT', select(2, UnitFullName("player")))
end

function Player.ClearCache()
    AddOn.db.global.cache.player = {}
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

