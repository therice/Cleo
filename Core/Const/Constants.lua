--- @type AddOn
local name, AddOn = ...

local L = LibStub("AceLocale-3.0"):GetLocale(name)

-- this will be first non-library file to load
-- shim it here so available until re-established
if not AddOn._IsTestContext then AddOn._IsTestContext = function() return false end end

AddOn.Constants = {
    name    =   name,
    name_c  =   "|CFF87CEFA" .. name .. "|r",
    chat    =   "chat",
    group   =   "group",
    guild   =   "guild",
    player  =   "player",
    party   =   "party",

    Buttons = {
        Left    =   "LeftButton",
        Right   =   "RightButton",
    },

    CommPrefixes = {
      Main      =   name,
      Version   =   name .. 'v',
      Sync      =   name .. 's',
    },

    Channels = {
        None        =   "NONE",
        Guild       =   "GUILD",
        Instance    =   "INSTANCE_CHAT",
        Officer     =   "OFFICER",
        Party       =   "PARTY",
        Raid        =   "RAID",
        RaidWarning =   "RAID_WARNING",
        Whisper     =   "WHISPER",
    },

    ChannelDescriptions = {
        NONE         = _G.NONE,
        SAY          = _G.CHAT_MSG_SAY,
        YELL         = _G.CHAT_MSG_YELL,
        PARTY        = _G.CHAT_MSG_PARTY,
        GUILD        = _G.CHAT_MSG_GUILD,
        OFFICER      = _G.CHAT_MSG_OFFICER,
        RAID         = _G.CHAT_MSG_RAID,
        RAID_WARNING = _G.CHAT_MSG_RAID_WARNING,
        group        = _G.GROUP,
        chat         = L['chat']
    },

    Colors = {
        AdmiralBlue     =   CreateColor(0.3,0.35,0.5, 1),
        Aluminum        =   CreateColor(0.7, 0.7, 0.7, 1),
        Blue            =   CreateColor(0, 0.44, 0.87, 1),
        DeathKnightRed  =   CreateColor(0.77,0.12,0.23,1),
        Evergreen       =   CreateColor(0, 1, 0.59, 1),
        Fuchsia         =   CreateColor(1, 0, 1, 1),
        Green           =   CreateColor(0, 1, 0, 1),
        ItemArtifact    =   _G.ITEM_QUALITY_COLORS[6].color,
        ItemCommon      =   _G.ITEM_QUALITY_COLORS[1].color,
        ItemEpic        =   _G.ITEM_QUALITY_COLORS[4].color,
        ItemHeirloom    =   _G.ITEM_QUALITY_COLORS[7].color,
        ItemLegendary   =   _G.ITEM_QUALITY_COLORS[5].color,
        ItemPoor        =   _G.ITEM_QUALITY_COLORS[0].color,
        ItemRare        =   _G.ITEM_QUALITY_COLORS[3].color,
        ItemUncommon    =   _G.ITEM_QUALITY_COLORS[2].color,
        LuminousOrange  =   CreateColor(1, 0, 0, 1),
        LuminousYellow  =   CreateColor(1, 1, 0, 1),
        MageBlue        =   CreateColor(0.25, 0.78, 0.92, 1),
        Marigold        =   CreateColor(0.7, 0.6, 0, 1),
        Nickel          =   CreateColor(0.5,0.5,0.5,1),
        PaladinPink     =   CreateColor(0.96,0.55,0.73,1),
        Pumpkin         =   CreateColor(0.8,0.5,0,1),
        Purple          =   CreateColor(0.53, 0.53, 0.93, 1),
        RogueYellow     =   CreateColor(1,0.96,0.41,1),
        White           =   CreateColor(1, 1, 1, 1)
    },
    
    Commands = {
        PlayerInfo              =   "pi",
        PlayerInfoRequest       =   "pir",
        VersionCheck            =   "vc",
        VersionCheckReply       =   "vcr",
        VersionPing             =   "vp",
        VersionPingReply        =   "vpr",
    },

    DropDowns = {

    },

    Events = {
        ChatMessageSystem       =   "CHAT_MSG_SYSTEM",
        ChatMessageWhisper      =   "CHAT_MSG_WHISPER",
        EncounterEnd            =   "ENCOUNTER_END",
        EncounterStart          =   "ENCOUNTER_START",
        GroupLeft               =   "GROUP_LEFT",
        LootClosed              =   "LOOT_CLOSED",
        LootOpened              =   "LOOT_OPENED",
        LootReady               =   "LOOT_READY",
        LootSlotCleared         =   "LOOT_SLOT_CLEARED",
        PlayerEnteringWorld     =   "PLAYER_ENTERING_WORLD",
        PartyLootMethodChanged  =   "PARTY_LOOT_METHOD_CHANGED",
        PartyLeaderChanged      =   "PARTY_LEADER_CHANGED",
        PlayerRegenEnabled      =   "PLAYER_REGEN_ENABLED",
        PlayerRegenDisabled     =   "PLAYER_REGEN_DISABLED",
        RaidInstanceWelcome     =   "RAID_INSTANCE_WELCOME",
    },

    -- this is probably a misnomer since it's mixed names, but whatever...
    ItemEquipmentLocationNames = {
        Bows            =   GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_BOWS),
        Chest           =   _G.INVTYPE_CHEST,
        Cloak           =   _G.INVTYPE_CLOAK,
        Crossbows       =   GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_CROSSBOW),
        Feet            =   _G.INVTYPE_FEET,
        Finger          =   _G.INVTYPE_FINGER,
        Guns            =    GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_GUNS),
        Head            =   _G.INVTYPE_HEAD,
        Hand            =   _G.INVTYPE_HAND,
        Holdable        =   _G.INVTYPE_HOLDABLE,
        Idol            =   GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_IDOL),
        Legs            =   _G.INVTYPE_LEGS,
        Libram          =   GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_LIBRAM),
        MainHandWeapon  =   ("%s %s"):format(_G.INVTYPE_WEAPONMAINHAND, _G.WEAPON),
        Neck            =   _G.INVTYPE_NECK,
        OffHandWeapon   =   ("%s %s"):format(_G.INVTYPE_WEAPONOFFHAND, _G.WEAPON),
        OneHandWeapon   =   ("%s %s"):format(_G.INVTYPE_WEAPON, _G.WEAPON),
        Ranged          =   _G.INVTYPE_RANGED,
        Relic           =   _G.INVTYPE_RELIC,
        Shield          =   _G.SHIELDSLOT,
        Shoulder        =   _G.INVTYPE_SHOULDER,
        Thrown          =   GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_THROWN),
        Totem           =   GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_TOTEM),
        Trinket         =   _G.INVTYPE_TRINKET,
        TwoHandWeapon   =   ("%s %s"):format(_G.INVTYPE_2HWEAPON, _G.WEAPON),
        Waist           =   _G.INVTYPE_WAIST,
        Wand            =   GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_WAND),
        WeaponMainHand  =   _G.INVTYPE_WEAPONMAINHAND,
        WeaponOffHand   =   _G.INVTYPE_WEAPONOFFHAND,
        WeaponTwoHand   =   _G.INVTYPE_2HWEAPON,
        Wrist           =   _G.INVTYPE_WRIST,
    },

    ItemQualityDescriptions = {
        [0] = _G.ITEM_QUALITY0_DESC, -- Poor
        [1] = _G.ITEM_QUALITY1_DESC, -- Common
        [2] = _G.ITEM_QUALITY2_DESC, -- Uncommon
        [3] = _G.ITEM_QUALITY3_DESC, -- Rare
        [4] = _G.ITEM_QUALITY4_DESC, -- Epic
        [5] = _G.ITEM_QUALITY5_DESC, -- Legendary
        [6] = _G.ITEM_QUALITY6_DESC, -- Artifact
    },

    ItemQualityColoredDescriptions = {
        [0] = _G.ITEM_QUALITY_COLORS[0].hex .. _G.ITEM_QUALITY0_DESC, -- Poor
        [1] = _G.ITEM_QUALITY_COLORS[1].hex .. _G.ITEM_QUALITY1_DESC, -- Common
        [2] = _G.ITEM_QUALITY_COLORS[2].hex .. _G.ITEM_QUALITY2_DESC, -- Uncommon
        [3] = _G.ITEM_QUALITY_COLORS[3].hex .. _G.ITEM_QUALITY3_DESC, -- Rare
        [4] = _G.ITEM_QUALITY_COLORS[4].hex .. _G.ITEM_QUALITY4_DESC, -- Epic
        [5] = _G.ITEM_QUALITY_COLORS[5].hex .. _G.ITEM_QUALITY5_DESC, -- Legendary
        [6] = _G.ITEM_QUALITY_COLORS[6].hex .. _G.ITEM_QUALITY6_DESC, -- Artifact
    },

    Messages = {

    },

    Modes = {
        Standard                =   0x01,
        Test                    =   0x02,
        Develop                 =   0x04,
        Persistence             =   0x08,
    },
    
    Popups = {

    },

    Responses = {

    },

    VersionStatus = {
        Current   = "c",
        OutOfDate = "o"
    }
}