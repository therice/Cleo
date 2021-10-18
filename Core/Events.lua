--- @type  AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type Core.Event
local Event = AddOn.Require('Core.Event')
--- @type Models.Encounter
local Encounter = AddOn.ImportPackage('Models').Encounter
--- @type UI.Native
local UINative = AddOn.Require('UI.Native')
--- @type LibDialog
local Dialog = AddOn:GetLibrary("Dialog")

function AddOn:SubscribeToEvents()
    Logging:Debug("SubscribeToEvents(%s)", self:GetName())
    local events = {}
    for event, method in pairs(self.Events) do
        Logging:Trace("SubscribeToEvents(%s) : %s", self:GetName(), event)
        events[event] = function(evt, ...) self[method](self, evt, ...) end
    end
    self.eventSubscriptions = Event:BulkSubscribe(events)
end

function AddOn:UnsubscribeFromEvents()
    Logging:Debug("UnsubscribeFromEvents(%s)", self:GetName())
    if self.eventSubscriptions then
        for _, subscription in pairs(self.eventSubscriptions) do
            subscription:unsubscribe()
        end
        self.eventSubscriptions = nil
    end
end

-- track whether initial load of addon or has it been reloaded (either via login or explicit reload)
local initialLoad = true
-- this event is triggered when the player logs in, /reloads the UI, or zones between map instances
-- basically whenever the loading screen appears
--
-- initial login = true, false
-- reload ui = false, true
-- instance zone event = false, false
function AddOn:PlayerEnteringWorld(_, isLogin, isReload)
    Logging:Debug("PlayerEnteringWorld(%s) : isLogin=%s, isReload=%s, initialLoad=%s",
                  AddOn.player:GetName(), tostring(isLogin), tostring(isReload), tostring(initialLoad)
    )
    self:NewMasterLooterCheck()
    -- if we have not yet handled the initial entering world event
    if initialLoad then
        if not self:IsMasterLooter() and Util.Objects.IsSet(self.masterLooter) then
            Logging:Debug("Player '%s' entering world (initial load)", tostring(self.player))
            self:ScheduleTimer("Send", 2, self.masterLooter, C.Commands.Reconnect)
            self:Send(self.masterLooter, C.Commands.PlayerInfo, self:GetPlayerInfo())
        end
        self:UpdatePlayerData()
        initialLoad = false
    end
end

--  PartyLootMethodChanged, PartyLeaderChanged
function AddOn:PartyEvent(event, ...)
    Logging:Debug("PartyEvent(%s)", event)
    self:NewMasterLooterCheck()
end

-- https://wow.gamepedia.com/LOOT_READY
-- This is fired when looting begins, but before the loot window is shown.
-- Loot functions like GetNumLootItems will be available until LOOT_CLOSED is fired.
function AddOn:LootReady(_, ...)
    Logging:Debug("LootReady()")
    self:MasterLooterModule():OnLootReady(...)
end

-- https://wow.gamepedia.com/LOOT_OPENED
-- Fired when a corpse is looted, after LOOT_READY.
function AddOn:LootOpened(_, ...)
    Logging:Debug("LootOpened()")
    self:MasterLooterModule():OnLootOpened(...)
end

-- https://wow.gamepedia.com/LOOT_CLOSED
-- Fired when a player ceases looting a corpse.
-- Note that this will fire before the last CHAT_MSG_LOOT event for that loot.
function AddOn:LootClosed(_, ...)
    Logging:Debug("LootClosed()")
    self:MasterLooterModule():OnLootClosed(...)
end

--- https://wow.gamepedia.com/LOOT_SLOT_CLEARED
--- Fired when loot is removed from a corpse.
--- lootSlot : number
function AddOn:LootSlotCleared(_, ...)
    Logging:Debug("LootSlotCleared()")
    self:MasterLooterModule():OnLootSlotCleared(...)
end

-- https://wow.gamepedia.com/ENCOUNTER_START
-- ENCOUNTER_START: encounterID, "encounterName", difficultyID, groupSize
function AddOn:EncounterStart(_, ...)
    Logging:Debug("EncounterStart()")
    self.encounter = Encounter(...)
    self:UpdatePlayerData()
end

-- https://wow.gamepedia.com/ENCOUNTER_END
-- ENCOUNTER_END: encounterID, "encounterName", difficultyID, groupSize, success
function AddOn:EncounterEnd(_, ...)
    Logging:Debug("EncounterEnd()")
    self.encounter = Encounter(...)
    -- if master looter, need to check for EP
    --[[
    if self:IsMasterLooter() then
        self:EffortPointsModule():OnEncounterEnd(self.encounter)
    end
    --]]
end


-- https://wow.gamepedia.com/RAID_INSTANCE_WELCOME
function AddOn:RaidInstanceEnter(_, ...)
    Logging:Debug("RaidInstanceEnter()")
    local ML = self:MasterLooterModule()
    if not IsInRaid() and ML:GetDbValue('onlyUseInRaids') then return end
    if Util.Objects.IsEmpty(self.masterLooter) and UnitIsGroupLeader(C.player) then
        if ML:GetDbValue('usage.leader') then
            self.masterLooter = self.player
            self:StartHandleLoot()
        elseif ML:GetDbValue('usage.ask_leader') then
            Dialog:Spawn(C.Popups.ConfirmUsage)
        end
    end
end

local UIOptionsOldCancel = InterfaceOptionsFrameCancel:GetScript("OnClick")

-- https://wow.gamepedia.com/PLAYER_REGEN_DISABLED
-- Fired whenever you enter combat, as normal regen rates are disabled during combat.
-- This means that either you are in the hate list of a NPC or that you've been taking part in a pvp action
-- (either as attacker or victim).
function AddOn:EnterCombat(_, ...)
    Logging:Debug("EnterCombat()")
    InterfaceOptionsFrameCancel:SetScript(
        "OnClick",
        function() InterfaceOptionsFrameOkay:Click() end
    )
    self.inCombat = true
    if not self.db.profile.minimizeInCombat then return end
    UINative:MinimizeFrames()
end

-- https://wow.gamepedia.com/PLAYER_REGEN_ENABLED
-- Fired after ending combat, as regen rates return to normal. Useful for determining when a player has left combat.
-- This occurs when you are not on the hate list of any NPC, or a few seconds after the latest pvp attack that you were
-- involved with.
function AddOn:LeaveCombat(_, ...)
    Logging:Debug("LeaveCombat()")
    InterfaceOptionsFrameCancel:SetScript("OnClick", UIOptionsOldCancel)
    self.inCombat = false
    if not self.db.profile.minimizeInCombat then return end
    UINative:MaximizeFrames()
end