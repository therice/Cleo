local MAJOR_VERSION = "LibGuildStorage-1.4"
local MINOR_VERSION = 40400
local LIB_MESSAGE_PREFIX = "GuildStorage14"

--- @class LibGuildStorage
local lib, _ = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then
    return
end

--- @type LibLogging
local Logging = LibStub("LibLogging-1.1")
--- @type LibClass
local Class = LibStub("LibClass-1.1")
--- @type LibUtil
local Util = LibStub("LibUtil-1.2")
--- @type CallbackHandler
local Cbh = LibStub("CallbackHandler-1.0")
--- @type AceEvent
local AceEvent = LibStub("AceEvent-3.0")

if not lib.callbacks then
    lib.callbacks = Cbh:New(lib)
end

local callbacks = lib.callbacks

AceEvent:Embed(lib)

lib:UnregisterAllEvents()

local States = {
    Stale                   =   1,
    StaleAwaitingUpdate     =   2,
    Current                 =   3,
}
lib.States = States

local StateNames = tInvert(States)

local StateTransitions = {
	[States.Stale]               = { [States.Current] = true, [States.StaleAwaitingUpdate] = true },
	[States.StaleAwaitingUpdate] = { [States.Stale] = true },
	[States.Current]             = { [States.Stale] = true, [States.StaleAwaitingUpdate] = true },
}

lib.Events = {
    Initialized              =   "Initialized",
    StateChanged             =   "StateChanged",
    GuildInfoChanged         =   "GuildInfoChanged",
    GuildNameChanged         =   "GuildNameChanged",
    GuildMemberDeleted       =   "GuildMemberDeleted",
    GuildMemberOnlineChanged =   "GuildMemberOnlineChanged",
}

local state, initialized, refreshing, index, cache, guildInfo, guildName =
    States.StaleAwaitingUpdate, false, false, nil, {}, nil, nil


local GuildStorageEntry = Class('GuildStorageEntry')

-- class : String - The class (Mage, Warrior, etc) of the player.
-- classTag : String - Upper-case English classname - localisation independent
-- rank : String - The member's rank in the guild ( Guild Master, Member ...)
-- rankIndex : Number - The number corresponding to the guild's rank (already with 1 added to API return value)
-- guid : String - The player's globally unique id, https://wowwiki.fandom.com/wiki/API_UnitGUID
function GuildStorageEntry:initialize(name, class, classTag, rank, rankIndex, level, officerNote, guid, online)
    self.name = name
    self.class = class
    self.classTag = classTag
    self.rank = rank
    self.rankIndex = rankIndex
    self.level = level
    self.officerNote = officerNote
    self.guid = guid
    self.online = online or false
    self.seen = nil
end

function SetState(value)
    Logging:Debug("SetState() : %s => %s", tostring(state), tostring(value))
    if state == value then
        return
    end
    
    if not StateTransitions[state][value] then
        Logging:Warn("Ignoring state change from '%s' to '%s'", StateNames[state], StateNames[value])
        return
    else
        Logging:Debug("State change from '%s' to '%s'", StateNames[state], StateNames[value])
        state = value
        callbacks:Fire(lib.Events.StateChanged, state)
    end
end

function lib:GetState()
    return state
end

function lib:GetGuildName()
    return guildName
end

function lib:IsStateCurrent()
    return state == States.Current
end

function lib:GetMembers()
    return cache
end

function lib:GetMember(name)
    -- return cache[name]
    local _, member =
        Util.Tables.FindFn(
            cache,
            function(g)
                return Util.Strings.Equal(g.name, name) or
                       Util.Strings.Equal(Ambiguate(g.name, "short"), name)
            end
        )
    return member
end

function lib:GetMemberAttribute(name, attr)
    local entry = self:GetMember(name)
    if entry and entry[attr] then return entry[attr] end
    return nil
end

function lib:GetOfficerNote(name)
    return self:GetMemberAttribute(name, 'officerNote')
end

function lib:GetClass(name)
    return self:GetMemberAttribute(name, 'class')
end

function lib:GetClassTag(name)
    return self:GetMemberAttribute(name, 'classTag')
end

-- @return member's rank and rankIndex
function lib:GetRank(name)
    local entry = self:GetMember(name)
    if entry then return entry.rank, entry.rankIndex end
	return nil, nil
end

function lib:GetGUID(name)
    return self:GetMemberAttribute(name, 'guid')
end

local Refresh

local function ScheduleRefresh()
	C_Timer.After(1, Refresh)
end

-- Fired when a player is gkicked, gquits, etc.
function lib:OnPlayerGuildUpdate(...)
    Logging:Trace("OnPlayerGuildUpdate(%d)", state)
    SetState(States.StaleAwaitingUpdate)
	ScheduleRefresh()
end

-- Fires when the player logs in, /reloads the UI or zones between map instances. Basically whenever the loading screen appears.
function lib:OnPlayerEnteringWorld(...)
    Logging:Trace("OnPlayerEnteringWorld()")
    lib:OnPlayerGuildUpdate(...)
end

-- Fired when the client's guild info cache has been updated after a call to GuildRoster or after any data change in
-- any of the guild's data, excluding the Guild Information window.
function lib:OnGuildRosterUpdate(_, canRequestRosterUpdate)
    Logging:Debug("OnGuildRosterUpdate(%s)", tostring(canRequestRosterUpdate))
    if canRequestRosterUpdate then
	    SetState(States.StaleAwaitingUpdate)
    else
        SetState(States.Stale)
        index = nil
    end
	ScheduleRefresh()
end

lib:RegisterEvent("PLAYER_GUILD_UPDATE", function(...) lib:OnPlayerGuildUpdate(...) end)
lib:RegisterEvent("PLAYER_ENTERING_WORLD", function(...) lib:OnPlayerEnteringWorld(...) end)
lib:RegisterEvent("GUILD_ROSTER_UPDATE", function(...) lib:OnGuildRosterUpdate(...) end)

-- Order of events and functions when first logging into game
--  PLAYER_ENTERING_WORLD
--  PLAYER_GUILD_UPDATE(StaleAwaitingUpdate[2])
--      OnUpdate(StaleAwaitingUpdate[2])
--      GuildRoster()
--  GUILD_ROSTER_UPDATE(false)
--      StaleAwaitingUpdate -> Stale
--  GUILD_ROSTER_UPDATE(false)
--      OnUpdate(1)
--      bunch of GuildOfficerNoteChanged
--      initialized
--      Stale -> Current
--
Refresh = function(...)
    Logging:Trace("Refresh(active=%s,state=%s)", tostring(refreshing), tostring(state))

    -- don't allow more than one refresh operation to occur concurrently
    if refreshing then
        return
    end

    Util.Functions.try(
        function()
            refreshing = true

            if state == States.Current then
                return
            end

            if state == States.StaleAwaitingUpdate then
                GuildRoster()
                return
            end

            local start = debugprofilestop()

            local guildMemberCount = GetNumGuildMembers()
            if guildMemberCount == 0 then
                Logging:Trace("No Guild Members, exiting...")
                return
            end

            if not index or index >= guildMemberCount then
                Logging:Trace("Re-setting index(%s) to 1", tostring(index))
                index = 1
            end

            if index == 1 then
                local newGuildName = GetGuildInfo("player") or nil
                if newGuildName ~= guildName then
                    guildName = newGuildName
                    callbacks:Fire(lib.Events.GuildNameChanged)
                end

                local newGuildInfo = GetGuildInfoText() or nil
                if newGuildInfo ~= guildInfo then
                    guildInfo = newGuildInfo
                    callbacks:Fire(lib.Events.GuildInfoChanged)
                end
            end

            Logging:Trace("Current index = %d, Guild Member Count = %d", index and index or -1, guildMemberCount)
            local lastIndex =  math.min(index + 100, guildMemberCount)
            if not initialized then
                Logging:Trace("Setting lastIndex to %d", guildMemberCount)
                lastIndex = guildMemberCount
            end

            Logging:Trace("Processing guild members from %d to %s", index, lastIndex)
            for i = index, lastIndex do
                -- https://wowwiki.fandom.com/wiki/API_GetGuildRosterInfo
                local name, rank, rankIndex, level, class, _, _, officerNote, online, _, classTag, _, _, _, _, _, guid =
                    GetGuildRosterInfo(i)
                -- The Rank Index starts at 0, add 1 to correspond with the index
                -- for usage in GuildControlGetRankName(index)
                rankIndex = rankIndex + 1

                if name then
                    local entry = lib:GetMember(name)
                    -- Logging:Trace("BEFORE(%s) = %s", name, Util.Objects.ToString(entry))
                    if not entry then
                        entry = GuildStorageEntry(name, class, classTag, rank, rankIndex, level, officerNote, guid, online)
                        cache[name] = entry
                    else
	                    entry.class = class
	                    entry.classTag = classTag
                        entry.rank = rank
                        entry.rankIndex = rankIndex
                        entry.level = level
	                    entry.officerNote = officerNote
                        entry.guid = guid
                    end
                    entry.seen = true

                    -- Logging:Trace("AFTER(%s) = %s", name, Util.Objects.ToString(entry))

                    online = Util.Objects.Default(online, false)
                    if entry.online ~= online then
                        entry.online = online
                        if initialized then
                            Logging:Trace("Firing Events.GuildMemberOnlineChanged for %s", name)
                            callbacks:Fire(lib.Events.GuildMemberOnlineChanged, name, online)
                        end
                    end
                end
            end

            index = lastIndex
            Logging:Trace("Initialized(%s) / State(%d) : index=%d, guildMemberCount=%d", tostring(initialized), state, index, guildMemberCount)
	        if index >= guildMemberCount then
		        for name, entry in pairs(cache) do
			        if entry.seen then
				        entry.seen = nil
			        else
				        cache[name] = nil
				        Logging:Trace("Firing Events.GuildMemberDeleted for %s", name)
				        callbacks:Fire(lib.Events.GuildMemberDeleted, name)
			        end
		        end

		        if not initialized then
			        initialized = true
			        callbacks:Fire(lib.Events.Initialized)
			        Logging:Trace("Initialized")
		        end

		        if state == States.Stale then
			        SetState(States.Current)
		        end
	        else
		        ScheduleRefresh()
	        end

	        local elapsed = (debugprofilestop() - start)
            Logging:Debug("Refresh(state=%d) : %d guild members, %d ms elapsed, current index %d", state, function() return Util.Tables.Count(cache) end, elapsed, index and index or -1)
        end
    ).finally(
	    function()
		    refreshing = false
	    end
    )
end


-- this is to work around issues with testing and a stub/mock scheduler
-- which is used, resulting in stack overflows
--
-- in this case, we have a "proper" C_Timer and can rely upon it
if C_Timer.IsMock and C_Timer.IsMock() then
	if lib.frame then
		lib.frame:UnregisterAllEvents()
		lib.frame:SetScript("OnEvent", nil)
		lib.frame:SetScript("OnUpdate", nil)
	else
		lib.frame = CreateFrame("Frame", MAJOR_VERSION .. "_Frame")
	end

	lib.frame:Show()
	GuildRoster()
end