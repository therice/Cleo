--- @type AddOn
local _, AddOn = ...
local E = AddOn.Constants.Events

AddOn.Events = {
    [E.EncounterEnd]                = "EncounterEnd",
    [E.EncounterStart]              = "EncounterStart",
    [E.GroupLeft]                   = "PartyEvent",
    [E.PlayerEnteringWorld]         = "PlayerEnteringWorld",
    [E.PartyLeaderChanged]          = "PartyEvent",
    [E.PartyLootMethodChanged]      = "PartyEvent",
    [E.LootClosed]                  = "LootClosed",
    [E.LootOpened]                  = "LootOpened",
    [E.LootReady]                   = "LootReady",
    [E.LootSlotCleared]             = "LootSlotCleared",
    [E.PlayerRegenDisabled]         = "EnterCombat",
    [E.PlayerRegenEnabled]          = "LeaveCombat",
    [E.RaidInstanceWelcome]         = "RaidInstanceEnter",
}