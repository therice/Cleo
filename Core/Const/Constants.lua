--- @type AddOn
local name, AddOn = ...

local L = LibStub("AceLocale-3.0"):GetLocale(name)

-- this will be first non-library file to load
-- shim it here so available until re-established
if not AddOn._IsTestContext then AddOn._IsTestContext = function() return false end end

local NIL = {__tostring = function() return "NIL (FAUX)" end}
setmetatable(NIL, NIL)

AddOn.NIL = NIL

AddOn.Constants = {
    name        =   name,
    name_c      =   "|CFF87CEFA" .. name .. "|r",
    chat        =   "chat",
    group       =   "group",
    guild       =   "guild",
    player      =   "player",
    party       =   "party",

    Buttons = {
        Left    =   "LeftButton",
        Right   =   "RightButton",
    },

    CommPrefixes = {
        Audit       = name .. "_a",
        Main        = name,
        Lists       = name .. "_l",
        Replication = name .. "_r",
        Sync        = name .. '_s',
        Version     = name .. '_v',
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
        chat         = L['chat'],
        group        = _G.GROUP,
        GUILD        = _G.CHAT_MSG_GUILD,
        NONE         = _G.NONE,
        OFFICER      = _G.CHAT_MSG_OFFICER,
        PARTY        = _G.CHAT_MSG_PARTY,
        RAID         = _G.CHAT_MSG_RAID,
        RAID_WARNING = _G.CHAT_MSG_RAID_WARNING,
        SAY          = _G.CHAT_MSG_SAY,
        YELL         = _G.CHAT_MSG_YELL,
    },

    -- https://www.easyrgb.com/en/convert.php
    -- https://wowpedia.fandom.com/wiki/Quality
    Colors = {
        AdmiralBlue    = CreateColor(0.3, 0.35, 0.5, 1),
        Aluminum       = CreateColor(0.7, 0.7, 0.7, 1),
        Blue           = CreateColor(0, 0.44, 0.87, 1),
        Cream          = CreateColor(1.0, 0.99216, 0.81569, 1),
        Cyan           = CreateColor(0.61569,  0.85490, 0.90196, 1),
        DeathKnightRed = CreateColor(0.77, 0.12, 0.23, 1),
        Evergreen      = CreateColor(0, 1, 0.59, 1),
        Fuchsia        = CreateColor(1, 0, 1, 1),
        Green          = CreateColor(0, 1, 0, 1),
        Grey           = CreateColor(0.73725, 0.78824, 0.80392, 1),
        HunterGreen    = CreateColor(0.67,0.83, 0.45, 1),
        ItemArtifact   = _G.ITEM_QUALITY_COLORS[6].color,
        ItemCommon     = _G.ITEM_QUALITY_COLORS[1].color,
        ItemEpic       = _G.ITEM_QUALITY_COLORS[4].color,
        ItemHeirloom   = _G.ITEM_QUALITY_COLORS[7].color,
        ItemLegendary  = _G.ITEM_QUALITY_COLORS[5].color,
        ItemPoor       = _G.ITEM_QUALITY_COLORS[0].color,
        ItemRare       = _G.ITEM_QUALITY_COLORS[3].color,
        ItemUncommon   = _G.ITEM_QUALITY_COLORS[2].color,
        LightBlue      = CreateColor(0.62353,0.86275,0.89412, 1),
        LuminousOrange = CreateColor(1, 0, 0, 1),
        LuminousYellow = CreateColor(1, 1, 0, 1),
        MageBlue       = CreateColor(0.25, 0.78, 0.92, 1),
        Marigold       = CreateColor(0.7, 0.6, 0, 1),
        MonkGreen      = CreateColor(0.00,1.00, 0.60, 1),
        Nickel         = CreateColor(0.5, 0.5, 0.5, 1),
        PaladinPink    = CreateColor(0.96, 0.55, 0.73, 1),
        Peppermint     = CreateColor(0.14138, 0.60749, 0.29173, 1),
        Pumpkin        = CreateColor(0.8, 0.5, 0, 1),
        Purple         = CreateColor(0.53, 0.53, 0.93, 1),
        RoseQuartz     = CreateColor(0.89815,0.34566,0.35813, 1),
        RogueYellow    = CreateColor(1, 0.96, 0.41, 1),
        Salmon         = CreateColor(0.99216, 0.48627, 0.43137, 1),
        ShamanBlue     = CreateColor(0.00, 0.44,0.87, 1),
        White          = CreateColor(1, 1, 1, 1),
        YellowLight    = CreateColor(1, 0.86391, 0.39770, 1),
    },

    Commands = {
        ActivateConfig          =   "alc",      -- sent when a configuration should be activated (for loot priorities)
        Awarded                 =   "awd",
        ChangeResponse          =   "cr",
        ConfigBroadcast         =   "cb",       -- this is a broadcast to multiple recipients for a configuration and associated lists (for add/update)
        ConfigBroadcastRemove   =   "cbr",      -- this is a broadcast to multiple recipients for a configuration and associated lists (for remove)
        ConfigResourceRequest   =   "crr",      -- this is a request for a configuration or a list
        ConfigResourceResponse  =   "crrsp",    -- this is a response for a configuration or a list
        Coordinator             =   "rcl",      -- replication based message (coordinator/leader)
        DeactivateConfig        =   "dlc",      -- sent when a configuration should be deactivated (for loot priorities)
        Election                =   "rer",      -- replication based message (election request)
        HandleLootStart         =   "hlst",
        HandleLootStop          =   "hlstp",
        LootAuditAdd            =   "laa",
        LootAck                 =   "la",
        LootedToBags            =   "ltb",
        LootSessionEnd          =   "lse",
        LootTable               =   "lt",
        LootTableAdd            =   "lta",
        MasterLooterDb          =   "mldb",
        MasterLooterDbRequest   =   "mldbr",
        CheckIfOffline          =   "ot",
        Ok                      =   "rok",      -- replication based message (ok)
        PeerLeft                =   "rpl",      -- replication based message (peer left due to replication being stopped)
        PeerQuery               =   "rpq",      -- replication based message (query for peers)
        PeerReply               =   "rpr",      -- replication based message (reply to peer query)
        PeerUpdate              =   "rpu",      -- replication based message (update of an existing peer)
        PlayerInfo              =   "pi",
        PlayerInfoRequest       =   "pir",
        RaidRosterAuditAdd      =   "rraa",
        Reconnect               =   "rct",
        Response                =   "rsp",
        ReRoll                  =   "rer",
        Roll                    =   "roll",
        Rolls                   =   "rolls",
        Sync                    =   "sync",
        SyncACK                 =   "sack",
        SyncNACK                =   "snack",
        SyncSYN                 =   "ssyn",
        TrafficAuditAdd         =   "taa",
        VersionCheck            =   "vc",
        VersionCheckReply       =   "vcr",
        VersionPing             =   "vp",
        VersionPingReply        =   "vpr",
    },

    DropDowns = {
        AllocateRightClick  = name .. "_AllocateRightClick",
        AllocateFilter      = name .. "_AllocateFilter",
        ConfigActions       = name .. "_ConfigActions",
        ConfigAltActions    = name .. "_ConfigAltActions",
        Enchanters          = name .. "_AllocateEnchantersMenu",
        ListActions         = name .. "_ListActions",
        ListPriorityActions = name .. "_ListPriorityActions",
        ListPlayerActions   = name .. "_ListPlayerActions",
        LootAuditActions    = name .. "_LootAuditActions",
        RaidAuditActions    = name .. "_RaidAuditActions",
        TrafficAuditActions = name .. "_TrafficAuditActions",
        TradeTimeActions    = name .. "_TradeTimeActions",
    },

    Events = {
        BagUpdateDelayed       = "BAG_UPDATE_DELAYED",
        ChatMessageLoot        = "CHAT_MSG_LOOT",
        ChatMessageSystem      = "CHAT_MSG_SYSTEM",
        ChatMessageWhisper     = "CHAT_MSG_WHISPER",
        EncounterEnd           = "ENCOUNTER_END",
        EncounterStart         = "ENCOUNTER_START",
        GroupFormed            = "GROUP_FORMED",
        GroupJoined            = "GROUP_JOINED",
        GroupLeft              = "GROUP_LEFT",
        LoadingScreenDisabled  = "LOADING_SCREEN_DISABLED",
        LootClosed             = "LOOT_CLOSED",
        LootOpened             = "LOOT_OPENED",
        LootReady              = "LOOT_READY",
        LootSlotCleared        = "LOOT_SLOT_CLEARED",
        PartyLootMethodChanged = "PARTY_LOOT_METHOD_CHANGED",
        PartyLeaderChanged     = "PARTY_LEADER_CHANGED",
        PlayerAlive            = "PLAYER_ALIVE",
        PlayerEnteringWorld    = "PLAYER_ENTERING_WORLD",
        PlayerLogin            = "PLAYER_LOGIN",
        PlayerLogout           = "PLAYER_LOGOUT",
        PlayerUnghost          = "PLAYER_UNGHOST",
        PlayerRegenEnabled     = "PLAYER_REGEN_ENABLED",
        PlayerRegenDisabled    = "PLAYER_REGEN_DISABLED",
        RaidInstanceWelcome    = "RAID_INSTANCE_WELCOME",
        ZoneChanged            = "ZONE_CHANGED",
    },

    Item = {
        NotBoundTradeTime       = 86400, -- 24 hours
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
        AwardSuccess               = name .. "_AwardSuccess",
        AwardFailed                = name .. "_AwardFailed",
        ConfigTableChanged         = name .. "_ConfigTableChanged",
        LootItemReceived           = name .. "_LootItemReceived",
        LootTableAddition          = name .. "_LootTableAddition",
        MasterLooterAddItem        = name .. "_MasterLooterAddItem",
        ModeChanged                = name .. "_ModeChanged",
        PlayerJoinedGroup          = name .. "_PlayerJoinedGroup",
        PlayerLeftGroup            = name .. "_PlayerLeftGroup",
        PlayerNotFound             = name .. "_PlayerNotFound",
        ResourceRequestCompleted   = name .. "_ResourceRequestCompleted",
        TradeTimeItemsChanged      = name .. "_TradeTimeItemsChanged",
    },

    Modes = {
        Standard                =   0x01,   -- 00001
        Test                    =   0x02,   -- 00010
        Develop                 =   0x04,   -- 00100
        Persistence             =   0x08,   -- 01000
        Replication             =   0x10,   -- 10000
    },
    
    Popups = {
        ConfirmAbort            =   name .. "_ConfigAbort",
        ConfirmAward            =   name .. "_ConfirmAward",
        ConfirmBroadcastDelete  =   name .. "_ConfirmBroadcastDelete",
        ConfirmDeleteItem       =   name .. "_ConfirmDeleteItem",
        ConfirmDeleteListConfig =   name .. "_ConfirmDeleteListConfig",
        ConfirmDeleteListList   =   name .. "_ConfirmDeleteListList",
        ConfirmReannounceItems  =   name .. "_ConfirmReannounceItems",
        ConfirmSync             =   name .. "_ConfirmSync",
        ConfirmUsage            =   name .. "_ConfirmUsage",
        SelectConfiguration     =   name .. "_SelectConfiguration",
    },

    Responses = {
        Announced    = "ANNOUNCED",
        AutoPass     = "AUTOPASS",
        Awarded      = "AWARDED",
        Default      = "DEFAULT",
        Disabled     = "DISABLED",
        NotAnnounced = "NOTANNOUNCED",
        Nothing      = "NOTHING",
        NotInRaid    = "NOTINRAID",
        Pass         = "PASS",
        Removed      = "REMOVED",
        Roll         = "ROLL",
        Timeout      = "TIMEOUT",
        Wait         = "WAIT",
    },

    VersionStatus = {
        Current   = "c",
        OutOfDate = "o"
    }
}

local C = AddOn.Constants

AddOn.Constants.EquipmentLocations = {
    INVTYPE_HEAD           = C.ItemEquipmentLocationNames.Head,
    INVTYPE_NECK           = C.ItemEquipmentLocationNames.Neck,
    INVTYPE_SHOULDER       = C.ItemEquipmentLocationNames.Shoulder,
    INVTYPE_CLOAK          = C.ItemEquipmentLocationNames.Cloak,
    INVTYPE_CHEST          = C.ItemEquipmentLocationNames.Chest,
    -- This needs mapped to chest where used
    -- INVTYPE_ROBE           = C.ItemEquipmentLocationNames.Chest,
    INVTYPE_WAIST          = C.ItemEquipmentLocationNames.Waist,
    INVTYPE_LEGS           = C.ItemEquipmentLocationNames.Legs,
    INVTYPE_FEET           = C.ItemEquipmentLocationNames.Feet,
    INVTYPE_WRIST          = C.ItemEquipmentLocationNames.Wrist,
    INVTYPE_HAND           = C.ItemEquipmentLocationNames.Hand,
    INVTYPE_FINGER         = C.ItemEquipmentLocationNames.Finger,
    INVTYPE_TRINKET        = C.ItemEquipmentLocationNames.Trinket,
    INVTYPE_WEAPON         = C.ItemEquipmentLocationNames.OneHandWeapon,
    INVTYPE_SHIELD         = C.ItemEquipmentLocationNames.Shield,
    INVTYPE_2HWEAPON       = C.ItemEquipmentLocationNames.TwoHandWeapon,
    INVTYPE_WEAPONMAINHAND = C.ItemEquipmentLocationNames.MainHandWeapon,
    INVTYPE_WEAPONOFFHAND  = C.ItemEquipmentLocationNames.OffHandWeapon,
    INVTYPE_HOLDABLE       = C.ItemEquipmentLocationNames.Holdable,
    INVTYPE_RANGED         = C.ItemEquipmentLocationNames.Ranged,
    -- This needs mapped to ranged where used
    -- INVTYPE_RANGEDRIGHT    = C.ItemEquipmentLocationNames.Ranged,
    INVTYPE_WAND           = C.ItemEquipmentLocationNames.Wand,
    INVTYPE_THROWN         = C.ItemEquipmentLocationNames.Thrown,
    INVTYPE_RELIC          = C.ItemEquipmentLocationNames.Relic,
}

AddOn.Constants.EquipmentNameToLocation = tInvert(AddOn.Constants.EquipmentLocations)

-- Populated later in Init.lua
AddOn.Constants.EquipmentLocationsSort = {}

