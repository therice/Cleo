--- @type AddOn
local _, AddOn = ...
local E = AddOn.Constants.Events

AddOn.Events = {
    [E.EncounterEnd]                = "EncounterEnd",
    [E.EncounterStart]              = "EncounterStart",
    [E.GroupFormed]                 = "GroupEvent",
    [E.GroupJoined]                 = "GroupEvent",
    [E.GroupLeft]                   = "GroupEvent",
    [E.LootClosed]                  = "LootClosed",
    [E.LootOpened]                  = "LootOpened",
    [E.LootReady]                   = "LootReady",
    [E.LootSlotCleared]             = "LootSlotCleared",
    [E.PartyLeaderChanged]          = "PartyEvent",
    [E.PartyLootMethodChanged]      = "PartyEvent",
    [E.PlayerEnteringWorld]         = "PlayerEnteringWorld",
    [E.PlayerRegenDisabled]         = "EnterCombat",
    [E.PlayerRegenEnabled]          = "LeaveCombat",
    [E.RaidInstanceWelcome]         = "RaidInstanceEnter",
}