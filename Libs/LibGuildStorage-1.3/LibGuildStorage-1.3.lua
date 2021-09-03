local MAJOR_VERSION = "LibGuildStorage-1.3"
local MINOR_VERSION = 20502
local LIB_MESSAGE_PREFIX = "GuildStorage13"

--- @class LibGuildStorage
local lib, _ = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

C_ChatInfo.RegisterAddonMessagePrefix(LIB_MESSAGE_PREFIX)

local Logging       = LibStub("LibLogging-1.0")
local Class         = LibStub("LibClass-1.0")
local Util          = LibStub("LibUtil-1.1")
local Cbh           = LibStub("CallbackHandler-1.0")
local AceHook       = LibStub("AceHook-3.0")

if not lib.callbacks then
    lib.callbacks = Cbh:New(lib)
end

local callbacks = lib.callbacks

AceHook:Embed(lib)
lib:UnhookAll()

if lib.frame then
    lib.frame:UnregisterAllEvents()
    lib.frame:SetScript("OnEvent", nil)
    lib.frame:SetScript("OnUpdate", nil)
else
    lib.frame = CreateFrame("Frame", MAJOR_VERSION .. "_Frame")
end

lib.frame:Show()
lib.frame:SetScript(
        "OnEvent",
        function(self, event, ...)
            lib[event](lib, ...)
        end
)

local SendAddonMessage = _G.SendAddonMessage
if ChatThrottleLib then
    SendAddonMessage = function(...)
        ChatThrottleLib:SendAddonMessage("ALERT", LIB_MESSAGE_PREFIX, ...)
    end
end

local States = {
    Stale                   =   1,
    StaleAwaitingUpdate     =   2,
    Current                 =   3,
    PendingChanges          =   4,
    PersistingChanges       =   5,
}
lib.States = States

local StateNames = tInvert(States)

local StateTransitions = {
    [States.Stale]                  = { [States.Current] = true, [States.PersistingChanges] = true, [States.StaleAwaitingUpdate] = true },
    [States.StaleAwaitingUpdate]    = { [States.Stale] = true, [States.PendingChanges] = true },
    [States.Current]                = { [States.PendingChanges] = true, [States.PersistingChanges] = true, [States.Stale] = true },
    [States.PendingChanges]         = { [States.StaleAwaitingUpdate] = true },
    [States.PersistingChanges]      = { [States.StaleAwaitingUpdate] = true },
}

local Messages = {
    ChangesPending  = "ChangesPending",
    ChangesWritten  = "ChangesWritten",
}

lib.Events = {
    Initialized              =   "Initialized",
    StateChanged             =   "StateChanged",
    GuildInfoChanged         =   "GuildInfoChanged",
    GuildNameChanged         =   "GuildNameChanged",
    GuildOfficerNoteChanged  =   "GuildNoteChanged",
    GuildOfficerNoteConflict =   "GuildNoteConflict",
    GuildOfficerNoteWritten  =   "GuildOfficerNoteWritten",
    GuildMemberDeleted       =   "GuildMemberDeleted",
}

local state, initialized, index, cache, guildInfo, guildName =
    States.StaleAwaitingUpdate, false, nil, {}, nil, nil


local GuildStorageEntry = Class('GuildStorageEntry')

-- class : String - The class (Mage, Warrior, etc) of the player.
-- classTag : String - Upper-case English classname - localisation independant.
-- rank : String - The member's rank in the guild ( Guild Master, Member ...)
-- rankIndex : Number - The number corresponding to the guild's rank (already with 1 added to API return value)
-- guid : String - The player's globally unique id, https://wowwiki.fandom.com/wiki/API_UnitGUID
function GuildStorageEntry:initialize(
        name, class, classTag, rank,
        rankIndex, officerNote, guid
)
    self.name = name
    self.class = class
    self.classTag = classTag
    self.rank = rank
    self.rankIndex = rankIndex
    self.officerNote = officerNote
    self.guid = guid
    self.pendingOfficerNote = nil
    self.seen = nil
end

function GuildStorageEntry:HasPendingOfficerNote()
    return self.pendingOfficerNote ~= nil
end

function SetState(value)
    if state == value then return end
    
    if not StateTransitions[state][value] then
        Logging:Trace("Ignoring state change from '%s' to '%s'", StateNames[state], StateNames[value])
        return
    else
        Logging:Trace("State change from '%s' to '%s'", StateNames[state], StateNames[value])
        state = value
        if value == States.PendingChanges then
            SendAddonMessage(Messages.ChangesPending, "GUILD")
        end
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

function lib:SetOfficeNote(name, note)
    local entry = self:GetMember(name)
    if entry then
        if entry:HasPendingOfficerNote() then
            Logging:Warn("SetOfficeNote() : Pending officer note update for %s", name)
            DEFAULT_CHAT_FRAME:AddMessage(
                    format(MAJOR_VERSION .. " : ignoring attempt to set officer note before persisting pending officer note for %s", name)
            )
        else
            Logging:Trace("SetOfficeNote() : Officer note for %s set to %s", name, note)
            entry.pendingOfficerNote = note
            SetState(States.PendingChanges)
        end
        
        return entry.pendingOfficerNote
    else
        Logging:Warn("SetOfficeNote() : Could not set officer not for %s", name)
    end
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
end

function lib:GetGUID(name)
    return self:GetMemberAttribute(name, 'guid')
end

lib.frame:RegisterEvent("CHAT_MSG_ADDON")
-- https://wow.gamepedia.com/PLAYER_GUILD_UPDATE
lib.frame:RegisterEvent("PLAYER_GUILD_UPDATE")
lib.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- https://wow.gamepedia.com/GUILD_ROSTER_UPDATE
lib.frame:RegisterEvent("GUILD_ROSTER_UPDATE")

function lib:CHAT_MSG_ADDON(prefix, msg, type, sender)
    -- only look at messages from this library and ignore ones from yourself
    if prefix ~= LIB_MESSAGE_PREFIX or UnitIsUnit(Ambiguate(sender, "short"), "player") then return end
    Logging:Trace("CHAT_MSG_ADDON: %s, %s, %s, %s", prefix, msg, type, sender)

    if msg == Messages.ChangesPending then
        SetState(States.PersistingChanges)
    elseif msg == Messages.ChangesWritten then
        SetState(States.StaleAwaitingUpdate)
    end
end

function lib:PLAYER_GUILD_UPDATE()
    -- Logging:Debug("PLAYER_GUILD_UPDATE(%d)", state)
    if IsInGuild() then
        lib.frame:Show()
    else
        lib.frame:Hide()
    end
    SetState(States.StaleAwaitingUpdate)
end

function lib:PLAYER_ENTERING_WORLD()
    -- Logging:Debug("PLAYER_ENTERING_WORLD()")
    lib:PLAYER_GUILD_UPDATE()
end

function lib:GUILD_ROSTER_UPDATE(canRequestRosterUpdate)
    -- Logging:Debug("GUILD_ROSTER_UPDATE(%s)", tostring(canRequestRosterUpdate))
    if canRequestRosterUpdate then
        SetState(States.PendingChanges)
    else
        SetState(States.Stale)
        index = nil
    end
end

-- Order of events and functions when first logging into game
--  PLAYER_ENTERING_WORLD
--  PLAYER_GUILD_UPDATE(2)
--      OnUpdate(2)
--      GuildRoster()
--  GUILD_ROSTER_UPDATE(false)
--      StaleAwaitingUpdate -> Stale
--  GUILD_ROSTER_UPDATE(false)
--      OnUpdate(1)
--      bunch of GuildOfficerNoteChanged
--      initialized
--      Stale -> Current
--
local function OnUpdate()
    if state == States.Current then return end
    
    if state == States.StaleAwaitingUpdate then
        -- Logging:Trace("Invoking GuildRoster()")
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
    local lastIndex = math.min(index + 100, guildMemberCount)
    if not initialized then
        Logging:Trace("Setting lastIndex to %d", guildMemberCount)
        lastIndex = guildMemberCount
    end
    
    Logging:Trace("Processing guild members from %d to %s", index, lastIndex)
    for i = index, lastIndex do
        -- https://wowwiki.fandom.com/wiki/API_GetGuildRosterInfo
        local name, rank, rankIndex, _, class, _, _, officerNote, _, _, classTag, _, _, _, _, _, guid =
            GetGuildRosterInfo(i)
        -- The Rank Index starts at 0, add 1 to correspond with the index
        -- for usage in GuildControlGetRankName(index)
        rankIndex = rankIndex + 1
    
        if name then
            local entry = lib:GetMember(name)
            -- Logging:Trace("BEFORE(%s) = %s", name, Util.Objects.ToString(entry))
            if not entry then
                entry = GuildStorageEntry(name, class, classTag, rank, rankIndex, officerNote, guid)
                cache[name] = entry
            else
                entry.rank = rank
                entry.rankIndex = rankIndex
                entry.class = class
                entry.classTag = classTag
                entry.guid = guid
            end
            entry.seen = true
            
            -- Logging:Trace("AFTER(%s) = %s", name, Util.Objects.ToString(entry))
            
            if entry.officerNote ~= officerNote then
                entry.officerNote = officerNote
                if initialized then
                    Logging:Trace("Firing Events.GuildOfficerNoteChanged for %s", name)
                    callbacks:Fire(lib.Events.GuildOfficerNoteChanged, name, officerNote)
                end
                if entry:HasPendingOfficerNote() then
                    Logging:Trace("Firing Events.GuildOfficerNoteConflict for %s", name)
                    callbacks:Fire(lib.Events.GuildOfficerNoteConflict, name, officerNote, entry.officerNote, entry.pendingOfficerNote)
                end
            end
    
            if entry:HasPendingOfficerNote() then
                Logging:Trace("Writing note '%s' for '%s'", entry.pendingOfficerNote, entry.name)
                GuildRosterSetOfficerNote(i, entry.pendingOfficerNote)
                local note = entry.pendingOfficerNote
                entry.pendingOfficerNote = nil
                Logging:Trace("Firing Events.GuildOfficerNoteWritten for %s", name)
                callbacks:Fire(lib.Events.GuildOfficerNoteWritten, name, note)
            end
        end
    end
    
    index = lastIndex
    Logging:Trace("(%s / %d) %d >= %d", tostring(initialized), state, index, guildMemberCount)
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
            for name, entry in pairs(cache) do
                Logging:Trace("Firing Events.GuildOfficerNoteChanged for %s", name)
                callbacks:Fire(lib.Events.GuildOfficerNoteChanged, name, entry.officerNote)
            end
            initialized = true
            callbacks:Fire(lib.Events.Initialized)
            Logging:Trace("initalized")
        end
        
        if state == States.Stale then
            SetState(States.Current)
        elseif state == States.PendingChanges then
            Logging:Trace("State is States.ChangesPending - checking pending count")
            local pendingCount = Util.Tables.CountFn(cache,
                function(entry)
                   if entry.pendingOfficerNote then return 1 else return 0 end
                end
            )
            Logging:Trace("Pending Count = %d", pendingCount)
            if pendingCount == 0 then
                SetState(States.StaleAwaitingUpdate)
                Logging:Trace("Firing Messages.ChangesWritten")
                SendAddonMessage(Messages.ChangesWritten, "GUILD")
            end
        end
    end
    
    Logging:Trace("OnUpdate(%d) : %d guild members, %d ms elapsed, current index %d", state, Util.Tables.Count(cache), debugprofilestop() - start, index and index or -1)
end

lib.frame:SetScript("OnUpdate", OnUpdate)
GuildRoster()