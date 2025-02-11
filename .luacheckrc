std = "lua51"
max_line_length = false
self = false
max_code_line_length = false

exclude_files = {
	"Libs/",
	"**/Test/**",
	"node_modules/",
	".tools/",
	"Changelog.lua",
}

-- https://luacheck.readthedocs.io/en/stable/warnings.html
ignore = {
	"211", -- Unused local variable
	"212", -- Unused argument
	"213", -- Unused loop variable
	"311", -- Value of an argument is unused
	"431", -- Shadowing an upvalue
	"432", -- Shadowing an upvalue argument
	"542", -- An empty if branch
	"611", -- A line consists of nothing but whitespace
}

globals = {
	"Cleo",
	"RAID_CLASS_COLORS.a", -- seems suspcicious
}

read_globals = {
	-- native
	"bit",
	"ceil",
	"date",
	"difftime",
	"floor",
	"format",
	"getglobal",
	"gsub",
	"geterrorhandler",
	"seterrorhandler",
	"max",
	"mod",
	"min",
	"random",
	"strfind",
	"strjoin",
	"strmatch",
	"strsplit",
	"tContains",
	"tDeleteItem",
	"tInvert",
	"tinsert",
	"time",
	"tremove",
	"wipe",
	"debugprofilestop",

	-- 3rd party libraries
	"LibStub",
	"MSA_DropDownMenu_AddButton",
	"MSA_DropDownMenu_Create",
	"MSA_DropDownMenu_CreateInfo",
	"MSA_DropDownMenu_Initialize",
	"MSA_DropDownMenu_SetSelectedName",
	"MSA_DROPDOWNMENU_MENU_VALUE",
	"MSA_ToggleDropDownMenu",
	"MSA_HideDropDownMenu",

	-- API
	"escapePatternSymbols",
	"Ambiguate",
	"CanEditOfficerNote",
	"CheckInteractDistance",
	"ClearCursor",
	"ClickTradeButton",
	"CloseLoot",
	"CreateColor",
	"CreateFont",
	"C_Item",
	"C_Timer",
	"GameFontHighlightSmall",
	"GameFontHighlightSmallLeft",
	"GameFontNormal",
	"GameFontNormalSmall",
	"GetAddOnMetadata",
	"GetBuildInfo",
	"GetDifficultyInfo",
	"GetCursorPosition",
	"GetContainerNumFreeSlots",
	"GetGuildRosterInfo",
	"GetInstanceInfo",
	"GetAverageItemLevel",
	"GetInventoryItemLink",
	"GetInventorySlotInfo",
	"GetItemFamily",
	"GetItemInfo",
	"GetItemInfoInstant",
	"GetItemQualityColor",
	"GetItemStats",
	"GetItemSubClassInfo",
	"GetLocale",
	"GetLootMethod",
	"GetLootSlotInfo",
	"GetLootSlotLink",
	"GetLootSourceInfo",
	"GetLootThreshold",
	"GetMasterLootCandidate",
	"GetNormalizedRealmName",
	"GetNumGuildMembers",
	"GetNumGroupMembers",
	"GetNumLootItems",
	"GetNumSkillLines",
	"GetPlayerInfoByGUID",
	"GetRaidRosterInfo",
	"GetRealZoneText",
	"GetRealmName",
	"GetServerTime",
	"GetSkillLineInfo",
	"GetSpellBookItemInfo",
	"GetSpellInfo",
	"GetTime",
	"GetTradePlayerItemLink",
	"GetUnitName",
	"GiveMasterLoot",
	"GuildControlGetNumRanks",
	"GuildControlGetRankName",
	"GuildRoster",
	"HandleModifiedItemClick",
	"IsAltKeyDown",
	"InCombatLockdown",
	"IsControlKeyDown",
	"IsEquippableItem",
	"IsInGroup",
	"IsInGuild",
	"IsInInstance",
	"IsInRaid",
	"IsMasterLooter",
	"IsModifiedClick",
	"IsModifierKeyDown",
	"IsShiftKeyDown",
	"ItemLocation",
	"LootSlot",
	"LootSlotHasItem",
	"MouseIsOver",
	"PlaySoundFile",
	"RandomRoll",
	"SendChatMessage",
	"SetLootMethod",
	"SetLootThreshold",
	"UnitClass",
	"UnitGUID",
	"UnitInParty",
	"UnitInRaid",
	"UnitIsConnected",
	"UnitIsUnit",
	"UnitIsGroupLeader",
	"UnitFactionGroup",
	"UnitFullName",
	"UnitName",
	"UnitPosition",

	-- Frames
	"BackdropTemplateMixin",
	"GameFontHighlightLeft",
	"GameTooltip",
	"UIParent",
	"WorldFrame",
	"Frame",
	
	-- Frame API
	"ChatFrame_AddMessageEventFilter",
	"CreateFrame",
	"EnumerateFrames",
	"FauxScrollFrame_OnVerticalScroll",
	"GameTooltip_Hide",
	"GetScreenWidth",
	"PanelTemplates_SetDisabledTabState",
	"SliderOnMouseWheel",
	"UIDropDownMenu_StartCounting",
	"UIDropDownMenu_StopCounting",

	-- Constants
	"BACKPACK_CONTAINER",
	"BIND_TRADE_TIME_REMAINING",
	"CLASS_ICON_TCOORDS",
	"ENABLE",
	"ERR_CHAT_PLAYER_NOT_FOUND_S",
	"FRIENDS_FRIENDS_CHOICE_EVERYONE",
	"INT_SPELL_DURATION_HOURS",
	"INT_SPELL_DURATION_MIN",
	"INT_SPELL_DURATION_SEC",
	"INVSLOT_FIRST_EQUIPPED",
	"INVSLOT_LAST_EQUIPPED",
	"INVSLOT_BODY",
	"INVSLOT_TABARD",
	"INVTYPE_2HWEAPON",
	"INVTYPE_CHEST",
	"INVTYPE_CLOAK",
	"INVTYPE_FEET",
	"INVTYPE_FINGER",
	"INVTYPE_HAND",
	"INVTYPE_HEAD",
	"INVTYPE_HOLDABLE",
	"INVTYPE_LEGS",
	"INVTYPE_NECK",
	"INVTYPE_RANGED",
	"INVTYPE_RELIC",
	"INVTYPE_ROBE",
	"INVTYPE_SHIELD",
	"INVTYPE_SHOULDER",
	"INVTYPE_THROWN",
	"INVTYPE_TRINKET",
	"INVTYPE_WAIST",
	"INVTYPE_WAND",
	"INVTYPE_WEAPON",
	"INVTYPE_WEAPONMAINHAND",
	"INVTYPE_WEAPONOFFHAND",
	"INVTYPE_WRIST",
	"ITEM_QUALITY0_DESC",
	"ITEM_QUALITY1_DESC",
	"ITEM_QUALITY2_DESC",
	"ITEM_QUALITY3_DESC",
	"ITEM_QUALITY4_DESC",
	"ITEM_QUALITY5_DESC",
	"ITEM_QUALITY6_DESC",
	"ITEM_QUALITY_COLORS",
	"ITEM_SOULBOUND",
	"ITEM_ACCOUNTBOUND",
	"ITEM_BNETACCOUNTBOUND",
	"LOOT_ITEM_MULTIPLE",
	"LOOT_ITEM",
	"LOOT_ITEM_SELF_MULTIPLE",
	"LOOT_ITEM_SELF",
	"LE_ITEM_ARMOR_GENERIC",
	"LE_ITEM_ARMOR_IDOL",
	"LE_ITEM_ARMOR_LIBRAM",
    "LE_ITEM_ARMOR_TOTEM",
	"LE_ITEM_BIND_ON_ACQUIRE",
	"LE_ITEM_BIND_ON_ACQUIRE",
	"LE_ITEM_BIND_ON_EQUIP",
	"LE_ITEM_CLASS_ARMOR",
	"LE_ITEM_CLASS_MISCELLANEOUS",
	"LE_ITEM_CLASS_WEAPON",
	"LE_ITEM_CLASS_WEAPON",
	"LE_ITEM_MISCELLANEOUS_JUNK",
	"LE_ITEM_WEAPON_BOWS",
	"LE_ITEM_WEAPON_CROSSBOW",
	"LE_ITEM_WEAPON_GENERIC",
	"LE_ITEM_WEAPON_GUNS",
	"LE_ITEM_WEAPON_THROWN",
	"LE_ITEM_WEAPON_WAND",
	"MAX_RAID_MEMBERS",
	"NORMAL_FONT_COLOR",
	"NUM_BAG_SLOTS",
	"RAID_CLASS_COLORS",
	"RANK",
	"REQUEST_ROLL",
	"ROLL",
	"SHIELDSLOT",
}

