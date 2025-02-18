--- @type AddOn
local _, AddOn = ...
--- @type LibLogging
local Logging = LibStub("LibLogging-1.1")
--- @type LibItemUtil
local ItemUtil = LibStub("LibItemUtil-1.2")

-- The ['*'] key defines a default table for any key that was not explicitly defined in the defaults.
-- The second magic key is ['**']. It works similar to the ['*'] key, except that it'll also be inherited by all the keys in the same table.
AddOn.defaults = {
    global = {
      cache = {},
      versions = {},
    },
    profile = {
        logThreshold        = Logging.Level.Trace,
        minimizeInCombat    = false,
        minimap = {
            shown       = true,
            locked      = false,
            minimapPos  = 218,
        },
        -- user interface element positioning and scale
        ui = {
            ['**'] = {
                y           = 0,
                x		    = 0,
                point	    = "CENTER",
                scale	    = 1.0,
            },
        },
        -- module specific data storage
        modules = {
            ['*'] = {
                -- by default, following are included
                filters = {
                    ['*'] = true,
                    class = {
                        ['*'] = true,
                    },
                    member_of = {
                        ['*'] = false,
                    },
                    response = {
                        ['*'] = true,
                    }
                },
                alwaysShowTooltip = false,
            },
        },
    }
}

AddOn.DefaultCustomItems = {
    -- Classic P2
    --[[
    [18422] = { 4, 74, "INVTYPE_NECK", "Horde" },       -- Head of Onyxia
    [18423] = { 4, 74, "INVTYPE_NECK", "Alliance" },    -- Head of Onyxia
    [18646] = { 4, 75, "INVTYPE_2HWEAPON" },            -- The Eye of Divinity
    [18703] = { 4, 75, "INVTYPE_RANGED" },              -- Ancient Petrified Leaf
    --]]

    -- Classic P3
    --[[
    [19002] = { 4, 83, "INVTYPE_NECK", "Horde" },      -- Head of Nefarian
    [19003] = { 4, 83, "INVTYPE_NECK", "Alliance" },   -- Head of Nefarian
    --]]

    -- Classic P5
    --[[
    [20928] = { 4, 78, "INVTYPE_SHOULDER" },    -- T2.5 shoulder, feet (Qiraji Bindings of Command)
    [20932] = { 4, 78, "INVTYPE_SHOULDER" },    -- T2.5 shoulder, feet (Qiraji Bindings of Dominance)
    [20930] = { 4, 81, "INVTYPE_HEAD" },        -- T2.5 head (Vek'lor's Diadem)
    [20926] = { 4, 81, "INVTYPE_HEAD" },        -- T2.5 head (Vek'nilash's Circlet)
    [20927] = { 4, 81, "INVTYPE_LEGS" },        -- T2.5 legs (Ouro's Intact Hide)
    [20931] = { 4, 81, "INVTYPE_LEGS" },        -- T2.5 legs (Skin of the Great Sandworm)
    [20929] = { 4, 81, "INVTYPE_CHEST" },       -- T2.5 chest (Carapace of the Old God)
    [20933] = { 4, 81, "INVTYPE_CHEST" },       -- T2.5 chest (Husk of the Old God
    [21221] = { 4, 88, "INVTYPE_NECK" },        -- Neck, Back, Finger (Eye of C'Thun)
    [21232] = { 4, 79, "INVTYPE_WEAPON" },      -- Weapon, Shield (Imperial Qiraji Armaments)
    [21237] = { 4, 79, "INVTYPE_2HWEAPON" },    -- 2H Weapon (Imperial Qiraji Regalia)
    --]]

    -- Classic P6
    --[[
    [22349] = { 4, 88, "INVTYPE_CHEST" },       -- Desecrated Breastplate
    [22350] = { 4, 88, "INVTYPE_CHEST" },       -- Desecrated Tunic
    [22351] = { 4, 88, "INVTYPE_CHEST" },       -- Desecrated Robe
    [22352] = { 4, 88, "INVTYPE_LEGS" },        -- Desecrated Legplates
    [22359] = { 4, 88, "INVTYPE_LEGS" },        -- Desecrated Legguards
    [22366] = { 4, 88, "INVTYPE_LEGS" },        -- Desecrated Leggings
    [22353] = { 4, 88, "INVTYPE_HEAD" },        -- Desecrated Helmet
    [22360] = { 4, 88, "INVTYPE_HEAD" },        -- Desecrated Headpiece
    [22367] = { 4, 88, "INVTYPE_HEAD" },        -- Desecrated Circlet
    [22354] = { 4, 88, "INVTYPE_SHOULDER" },    -- Desecrated Pauldrons
    [22361] = { 4, 88, "INVTYPE_SHOULDER" },    -- Desecrated Spaulders
    [22368] = { 4, 88, "INVTYPE_SHOULDER" },    -- Desecrated Shoulderpads
    [22355] = { 4, 88, "INVTYPE_WRIST" },       -- Desecrated Bracers
    [22362] = { 4, 88, "INVTYPE_WRIST" },       -- Desecrated Wristguards
    [22369] = { 4, 88, "INVTYPE_WRIST" },       -- Desecrated Bindings
    [22356] = { 4, 88, "INVTYPE_WAIST" },       -- Desecrated Waistguard
    [22363] = { 4, 88, "INVTYPE_WAIST" },       -- Desecrated Girdle
    [22370] = { 4, 88, "INVTYPE_WAIST" },       -- Desecrated Belt
    [22357] = { 4, 88, "INVTYPE_HAND" },        -- Desecrated Gauntlets
    [22364] = { 4, 88, "INVTYPE_HAND" },        -- Desecrated Handguards
    [22371] = { 4, 88, "INVTYPE_HAND" },        -- Desecrated Gloves
    [22358] = { 4, 88, "INVTYPE_FEET" },        -- Desecrated Sabatons
    [22365] = { 4, 88, "INVTYPE_FEET" },        -- Desecrated Boots
    [22372] = { 4, 88, "INVTYPE_FEET" },        -- Desecrated Sandals
    [22520] = { 4, 90, "INVTYPE_TRINKET" },     -- The Phylactery of Kel'Thuzad
    [22726] = { 5, 90, "INVTYPE_2HWEAPON" },    -- Splinter of Atiesh
    --]]

    -- TBC Classic P1
    --[[
    [29761] = { 4, 120, "INVTYPE_HEAD" },               -- Helm of the Fallen Defender
    [29759] = { 4, 120, "INVTYPE_HEAD" },               -- Helm of the Fallen Hero
    [29760] = { 4, 120, "INVTYPE_HEAD" },               -- Helm of the Fallen Champion
    [29764] = { 4, 120, "INVTYPE_SHOULDER" },           -- Pauldrons of the Fallen Defender
    [29762] = { 4, 120, "INVTYPE_SHOULDER" },           -- Pauldrons of the Fallen Hero
    [29763] = { 4, 120, "INVTYPE_SHOULDER" },           -- Pauldrons of the Fallen Champion
    [29753] = { 4, 120, "INVTYPE_CHEST" },              -- Chestguard of the Fallen Defender
    [29755] = { 4, 120, "INVTYPE_CHEST" },              -- Chestguard of the Fallen Hero
    [29754] = { 4, 120, "INVTYPE_CHEST" },              -- Chestguard of the Fallen Champion
    [29758] = { 4, 120, "INVTYPE_HAND" },               -- Gloves of the Fallen Defender
    [29756] = { 4, 120, "INVTYPE_HAND" },               -- Gloves of the Fallen Hero
    [29757] = { 4, 120, "INVTYPE_HAND" },               -- Gloves of the Fallen Champion
    [29767] = { 4, 120, "INVTYPE_LEGS" },               -- Leggings of the Fallen Defender
    [29765] = { 4, 120, "INVTYPE_LEGS" },               -- Leggings of the Fallen Hero
    [29766] = { 4, 120, "INVTYPE_LEGS" },               -- Leggings of the Fallen Champion
    [32385] = { 4, 125, "INVTYPE_FINGER", "Alliance" }, -- Magtheridon's Head
    [32386] = { 4, 125, "INVTYPE_FINGER", "Horde" },    -- Magtheridon's Head
    --]]

    -- TBC Classic P2
    --[[
    [30243] = { 4, 133, "INVTYPE_HEAD" },               -- Helm of the Vanquished Defender
    [30244] = { 4, 133, "INVTYPE_HEAD" },               -- Helm of the Vanquished Hero
    [30242] = { 4, 133, "INVTYPE_HEAD" },               -- Helm of the Vanquished Champion
    [30249] = { 4, 133, "INVTYPE_SHOULDER" },           -- Pauldrons of the Vanquished Defender
    [30250] = { 4, 133, "INVTYPE_SHOULDER" },           -- Pauldrons of the Vanquished Hero
    [30248] = { 4, 133, "INVTYPE_SHOULDER" },           -- Pauldrons of the Vanquished Champion
    [30237] = { 4, 133, "INVTYPE_CHEST" },              -- Chestguard of the Vanquished Defender
    [30238] = { 4, 133, "INVTYPE_CHEST" },              -- Chestguard of the Vanquished Hero
    [30236] = { 4, 133, "INVTYPE_CHEST" },              -- Chestguard of the Vanquished Champion
    [30240] = { 4, 133, "INVTYPE_HAND" },               -- Gloves of the Vanquished Defender
    [30241] = { 4, 133, "INVTYPE_HAND" },               -- Gloves of the Vanquished Hero
    [30239] = { 4, 133, "INVTYPE_HAND" },               -- Gloves of the Vanquished Champion
    [30246] = { 4, 133, "INVTYPE_LEGS" },               -- Leggings of the Vanquished Defender
    [30247] = { 4, 133, "INVTYPE_LEGS" },               -- Leggings of the Vanquished Hero
    [30245] = { 4, 133, "INVTYPE_LEGS" },               -- Leggings of the Vanquished Champion
    --]]

    -- TBC Classic P3
    --[[
    [31097] = { 4, 146, "INVTYPE_HEAD"},                -- Helm of the Forgotten Conqueror
    [31095] = { 4, 146, "INVTYPE_HEAD"},                -- Helm of the Forgotten Protector
    [31096] = { 4, 146, "INVTYPE_HEAD"},                -- Helm of the Forgotten Vanquisher
    [31101] = { 4, 146, "INVTYPE_SHOULDER"},            -- Pauldrons of the Forgotten Conqueror
    [31103] = { 4, 146, "INVTYPE_SHOULDER"},            -- Pauldrons of the Forgotten Protector
    [31102] = { 4, 146, "INVTYPE_SHOULDER"},            -- Pauldrons of the Forgotten Vanquisher
    [31089] = { 4, 146, "INVTYPE_CHEST"},               -- Chestguard of the Forgotten Conqueror
    [31091] = { 4, 146, "INVTYPE_CHEST"},               -- Chestguard of the Forgotten Protector
    [31090] = { 4, 146, "INVTYPE_CHEST"},               -- Chestguard of the Forgotten Vanquisher
    [31092] = { 4, 146, "INVTYPE_HAND"},                -- Gloves of the Forgotten Conqueror
    [31094] = { 4, 146, "INVTYPE_HAND"},                -- Gloves of the Forgotten Protector
    [31093] = { 4, 146, "INVTYPE_HAND"},                -- Gloves of the Forgotten Vanquisher
    [31098] = { 4, 146, "INVTYPE_LEGS"},                -- Leggings of the Forgotten Conqueror
    [31100] = { 4, 146, "INVTYPE_LEGS"},                -- Leggings of the Forgotten Protector
    [31099] = { 4, 146, "INVTYPE_LEGS"},                -- Leggings of the Forgotten Vanquisher
    --]]

    -- TBC Classic P4
    --[[
    [34848] = { 4, 154, "INVTYPE_WRIST" },              -- Bracers of the Forgotten Conqueror
    [34851] = { 4, 154, "INVTYPE_WRIST" },              -- Bracers of the Forgotten Protector
    [34852] = { 4, 154, "INVTYPE_WRIST" },              -- Bracers of the Forgotten Vanquisher
    [34856] = { 4, 154, "INVTYPE_FEET" },               -- Boots of the Forgotten Conqueror
    [34857] = { 4, 154, "INVTYPE_FEET" },               -- Boots of the Forgotten Protector
    [34858] = { 4, 154, "INVTYPE_FEET" },               -- Boots of the Forgotten Vanquisher
    [34853] = { 4, 154, "INVTYPE_WAIST" },              -- Belt of the Forgotten Conqueror
    [34854] = { 4, 154, "INVTYPE_WAIST" },              -- Belt of the Forgotten Protector
    [34855] = { 4, 154, "INVTYPE_WAIST" },              -- Belt of the Forgotten Vanquisher
    --]]

    -- WOTLK P1
    -- 10 player
    --[[
    [40616] = { 4, 200, "INVTYPE_HEAD" },               -- Helm of the Lost Conqueror
    [40617] = { 4, 200, "INVTYPE_HEAD" },               -- Helm of the Lost Protector
    [40618] = { 4, 200, "INVTYPE_HEAD" },               -- Helm of the Lost Vanquisher
    [40613] = { 4, 200, "INVTYPE_HAND" },               -- Gloves of the Lost Conqueror
    [40614] = { 4, 200, "INVTYPE_HAND" },               -- Gloves of the Lost Protector
    [40615] = { 4, 200, "INVTYPE_HAND" },               -- Gloves of the Lost Vanquisher
    [40610] = { 4, 200, "INVTYPE_CHEST" },              -- Chestguard of the Lost Conqueror
    [40611] = { 4, 200, "INVTYPE_CHEST" },              -- Chestguard of the Lost Protector
    [40612] = { 4, 200, "INVTYPE_CHEST" },              -- Chestguard of the Lost Vanquisher
    [40619] = { 4, 200, "INVTYPE_LEGS" },               -- Leggings of the Lost Conqueror
    [40620] = { 4, 200, "INVTYPE_LEGS" },               -- Leggings of the Lost Protector
    [40621] = { 4, 200, "INVTYPE_LEGS" },               -- Leggings of the Lost Vanquisher
    [40622] = { 4, 200, "INVTYPE_SHOULDER" },           -- Spaulders of the Lost Conqueror
    [40623] = { 4, 200, "INVTYPE_SHOULDER" },           -- Spaulders of the Lost Protector
    [40624] = { 4, 200, "INVTYPE_SHOULDER" },           -- Spaulders of the Lost Vanquisher
    -- 25 player
    [40631] = { 4, 213, "INVTYPE_HEAD" },               -- Crown of the Lost Conqueror
    [40632] = { 4, 213, "INVTYPE_HEAD" },               -- Crown of the Lost Protector
    [40633] = { 4, 213, "INVTYPE_HEAD" },               -- Crown of the Lost Vanquisher
    [40628] = { 4, 213, "INVTYPE_HAND" },               -- Gauntlets of the Lost Conqueror
    [40629] = { 4, 213, "INVTYPE_HAND" },               -- Gauntlets of the Lost Protector
    [40630] = { 4, 213, "INVTYPE_HAND" },               -- Gauntlets of the Lost Vanquisher
    [40625] = { 4, 213, "INVTYPE_CHEST" },              -- Breastplate of the Lost Conqueror
    [40626] = { 4, 213, "INVTYPE_CHEST" },              -- Breastplate of the Lost Protector
    [40627] = { 4, 213, "INVTYPE_CHEST" },              -- Breastplate of the Lost Vanquisher
    [40634] = { 4, 213, "INVTYPE_LEGS" },               -- Legplates of the Lost Conqueror
    [40635] = { 4, 213, "INVTYPE_LEGS" },               -- Legplates of the Lost Protector
    [40636] = { 4, 213, "INVTYPE_LEGS" },               -- Legplates of the Lost Vanquisher
    [40637] = { 4, 213, "INVTYPE_SHOULDER" },           -- Mantle of the Lost Conqueror
    [40638] = { 4, 213, "INVTYPE_SHOULDER" },           -- Mantle of the Lost Protector
    [40639] = { 4, 213, "INVTYPE_SHOULDER" },           -- Mantle of the Lost Vanquisher

    -- WOTLK P2
    -- 10 player
    [45647] = { 4, 225, "INVTYPE_HEAD" },               -- Helm of the Wayward Conqueror
    [45648] = { 4, 225, "INVTYPE_HEAD" },               -- Helm of the Wayward Protector
    [45649] = { 4, 225, "INVTYPE_HEAD" },               -- Helm of the Wayward Vanquisher
    [45644] = { 4, 225, "INVTYPE_HAND" },               -- Gloves of the Wayward Conqueror
    [45645] = { 4, 225, "INVTYPE_HAND" },               -- Gloves of the Wayward Protector
    [45646] = { 4, 225, "INVTYPE_HAND" },               -- Gloves of the Wayward Vanquisher
    [45635] = { 4, 225, "INVTYPE_CHEST" },              -- Chestguard of the Wayward Conqueror
    [45636] = { 4, 225, "INVTYPE_CHEST" },              -- Chestguard of the Wayward Protector
    [45637] = { 4, 225, "INVTYPE_CHEST" },              -- Chestguard of the Wayward Vanquisher
    [45650] = { 4, 225, "INVTYPE_LEGS" },               -- Leggings of the Wayward Conqueror
    [45651] = { 4, 225, "INVTYPE_LEGS" },               -- Leggings of the Wayward Protector
    [45652] = { 4, 225, "INVTYPE_LEGS" },               -- Leggings of the Wayward Vanquisher
    [45659] = { 4, 225, "INVTYPE_SHOULDER" },           -- Spaulders of the Wayward Conqueror
    [45660] = { 4, 225, "INVTYPE_SHOULDER" },           -- Spaulders of the Wayward Protector
    [45661] = { 4, 225, "INVTYPE_SHOULDER" },           -- Spaulders of the Wayward Vanquisher
    -- 25 player
    [45638] = { 4, 232, "INVTYPE_HEAD" },               -- Crown of the Wayward Conqueror
    [45639] = { 4, 232, "INVTYPE_HEAD" },               -- Crown of the Wayward Protector
    [45640] = { 4, 232, "INVTYPE_HEAD" },               -- Crown of the Wayward Vanquisher
    [45641] = { 4, 232, "INVTYPE_HAND" },               -- Gauntlets of the Wayward Conqueror
    [45642] = { 4, 232, "INVTYPE_HAND" },               -- Gauntlets of the Wayward Protector
    [45643] = { 4, 232, "INVTYPE_HAND" },               -- Gauntlets of the Wayward Vanquisher
    [45632] = { 4, 232, "INVTYPE_CHEST" },              -- Breastplate of the Wayward Conqueror
    [45633] = { 4, 232, "INVTYPE_CHEST" },              -- Breastplate of the Wayward Protector
    [45634] = { 4, 232, "INVTYPE_CHEST" },              -- Breastplate of the Wayward Vanquisher
    [45653] = { 4, 232, "INVTYPE_LEGS" },               -- Legplates of the Wayward Conqueror
    [45654] = { 4, 232, "INVTYPE_LEGS" },               -- Legplates of the Wayward Protector
    [45655] = { 4, 232, "INVTYPE_LEGS" },               -- Legplates of the Wayward Vanquisher
    [45656] = { 4, 232, "INVTYPE_SHOULDER" },           -- Mantle of the Wayward Conqueror
    [45657] = { 4, 232, "INVTYPE_SHOULDER" },           -- Mantle of the Wayward Protector
    [45658] = { 4, 232, "INVTYPE_SHOULDER" },           -- Mantle of the Wayward Vanquisher

    -- WOTLK P3
    -- 10 player
    [47242] = { 4, 245, ItemUtil.CustomItemInvTypeSelf },   -- Trophy of the Crusade (also in 25)
    -- 25 player
    [47557] = { 4, 258, ItemUtil.CustomItemInvTypeSelf },   -- Regalia of the Grand Conqueror (Paladin, Priest, Warlock)
    [47558] = { 4, 258, ItemUtil.CustomItemInvTypeSelf },   -- Regalia of the Grand Protector (Warrior, Hunter, Shaman)
    [47559] = { 4, 258, ItemUtil.CustomItemInvTypeSelf },   -- Regalia of the Grand Vanquisher (Rogue, Death Knight, Mage, Druid)

    -- WOTLK P4
    [52025] = { 4, 264, ItemUtil.CustomItemInvTypeSelf },   -- Vanquisher's Mark of Sanctification (Rogue, Death Knight, Mage, Druid)
    [52026] = { 4, 264, ItemUtil.CustomItemInvTypeSelf },   -- Protector's Mark of Sanctification (Warrior, Hunter, Shaman)
    [52027] = { 4, 264, ItemUtil.CustomItemInvTypeSelf },   -- Conqueror's Mark of Sanctification (Paladin, Priest, Warlock)
    [52028] = { 4, 277, ItemUtil.CustomItemInvTypeSelf },   -- Vanquisher's Mark of Sanctification - Heroic (Rogue, Death Knight, Mage, Druid)
    [52029] = { 4, 277, ItemUtil.CustomItemInvTypeSelf },   -- Protector's Mark of Sanctification - Heroic (Warrior, Hunter, Shaman)
    [52030] = { 4, 277, ItemUtil.CustomItemInvTypeSelf },   -- Conqueror's Mark of Sanctification - Heroic (Paladin, Priest, Warlock)
    --]]


    -- CATA P1
    -- T11 https://www.wowhead.com/cata/guide=cataclysm&tier-11
    --[[
    [63683] = { 4, 359, "INVTYPE_HEAD" },                       -- Helm of the Forlorn Conqueror
    [63684] = { 4, 359, "INVTYPE_HEAD" },                       -- Helm of the Forlorn Protector
    [63682] = { 4, 359, "INVTYPE_HEAD" },                       -- Helm of the Forlorn Vanquisher
    [65001] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Crown of the Forlorn Conqueror
    [65000] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Crown of the Forlorn Protector
    [65002] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Crown of the Forlorn Vanquisher
    [67429] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Gauntlets of the Forlorn Conqueror
    [67430] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Gauntlets of the Forlorn Protector
    [67431] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Gauntlets of the Forlorn Vanquisher
    [67423] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Chest of the Forlorn Conqueror
    [67424] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Chest of the Forlorn Protector
    [67425] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Chest of the Forlorn Vanquisher
    [67428] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Leggings of the Forlorn Conqueror
    [67427] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Leggings of the Forlorn Protector
    [67426] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Leggings of the Forlorn Vanquisher
    [64315] = { 4, 359, "INVTYPE_SHOULDER" },                   -- Mantle of the Forlorn Conqueror
    [64316] = { 4, 359, "INVTYPE_SHOULDER" },                   -- Mantle of the Forlorn Protector
    [64314] = { 4, 359, "INVTYPE_SHOULDER" },                   -- Mantle of the Forlorn Vanquisher
    [65088] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Shoulders of the Forlorn Conqueror
    [65087] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Shoulders of the Forlorn Protector
    [65089] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Shoulders of the Forlorn Vanquisher
    [66998] = { 4, 372, ItemUtil.CustomItemInvTypeSelf },       -- Essence of the Forlorn (can be used to purchase any Heroic armor token)

    -- CATA P3 (Firelands)
    -- T12
    [71675] = { 4, 378, "INVTYPE_HEAD" },                   -- Helm of the Fiery Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [71682] = { 4, 378, "INVTYPE_HEAD" },                   -- Helm of the Fiery Protector (Warrior, Hunter, Shaman) [NORMAL]
    [71668] = { 4, 378, "INVTYPE_HEAD" },                   -- Helm of the Fiery Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [71677] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Crown of the Fiery Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [71684] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Crown of the Fiery Protector (Warrior, Hunter, Shaman) [HEROIC]
    [71670] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Crown of the Fiery Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [71676] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Gauntlets of the Fiery Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [71683] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Gauntlets of the Fiery Protector (Warrior, Hunter, Shaman) [HEROIC]
    [71669] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Gauntlets of the Fiery Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [71679] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Chest of the Fiery Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [71686] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Chest of the Fiery Protector (Warrior, Hunter, Shaman) [HEROIC]
    [71672] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Chest of the Fiery Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [71678] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Leggings of the Fiery Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [71685] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Leggings of the Fiery Protector (Warrior, Hunter, Shaman) [HEROIC]
    [71671] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Leggings of the Fiery Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [71681] = { 4, 378, "INVTYPE_SHOULDER" },               -- Mantle of the Fiery Conqueror (Warrior, Hunter, Shaman) [NORMAL]
    [71688] = { 4, 378, "INVTYPE_SHOULDER" },               -- Mantle of the Fiery Protector (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [71674] = { 4, 378, "INVTYPE_SHOULDER" },               -- Mantle of the Fiery Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [71680] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Shoulders of the Fiery Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [71687] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Shoulders of the Fiery Protector (Warrior, Hunter, Shaman) [HEROIC]
    [71673] = { 4, 391, ItemUtil.CustomItemInvTypeSelf },   -- Shoulders of the Fiery Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    -- Omitting for now, but keeping placeholder
    -- [71617] = { }, -- Crystallized Firestone (can be used to upgrade gear, not enumerating)
    --]]

    -- CATA P4 (Dragon Soup)
    -- T13
    [78182] = { 4, 397, "INVTYPE_HEAD" },                   -- Crown of the Corrupted Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [78177] = { 4, 397, "INVTYPE_HEAD" },                   -- Crown of the Corrupted Protector (Warrior, Hunter, Shaman) [NORMAL]
    [78172] = { 4, 397, "INVTYPE_HEAD" },                   -- Crown of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [78850] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Crown of the Corrupted Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [78851] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Crown of the Corrupted Protector (Warrior, Hunter, Shaman) [HEROIC]
    [78852] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Crown of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [78183] = { 4, 397, "INVTYPE_HAND" },                   -- Gauntlets of the Corrupted Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [78178] = { 4, 397, "INVTYPE_HAND" },                   -- Gauntlets of the Corrupted Protector (Warrior, Hunter, Shaman) [NORMAL]
    [78173] = { 4, 397, "INVTYPE_HAND" },                   -- Gauntlets of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid)) [NORMAL]
    [78853] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Gauntlets of the Corrupted Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [78854] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Gauntlets of the Corrupted Protector (Warrior, Hunter, Shaman) [HEROIC]
    [78855] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Gauntlets of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [78184] = { 4, 397, "INVTYPE_CHEST" },                  -- Chest of the Corrupted Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [78179] = { 4, 397, "INVTYPE_CHEST" },                  -- Chest of the Corrupted Protector (Warrior, Hunter, Shaman) [NORMAL]
    [78174] = { 4, 397, "INVTYPE_CHEST" },                  -- Chest of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [78847] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Chest of the Corrupted Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [78848] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Chest of the Corrupted Protector (Warrior, Hunter, Shaman) [HEROIC]
    [78849] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Chest of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [78181] = { 4, 397, "INVTYPE_LEGS" },                   -- Leggings of the Corrupted Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [78176] = { 4, 397, "INVTYPE_LEGS" },                   -- Leggings of the Corrupted Protector (Warrior, Hunter, Shaman) [NORMAL]
    [78171] = { 4, 397, "INVTYPE_LEGS" },                   -- Leggings of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [78856] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Leggings of the Corrupted Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [78857] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Leggings of the Corrupted Protector (Warrior, Hunter, Shaman) [HEROIC]
    [78858] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Leggings of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [78180] = { 4, 397, "INVTYPE_SHOULDER" },               -- Shoulders of the Corrupted Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [78175] = { 4, 397, "INVTYPE_SHOULDER" },               -- Shoulders of the Corrupted Protector (Warrior, Hunter, Shaman) [NORMAL]
    [78170] = { 4, 397, "INVTYPE_SHOULDER" },               -- Shoulders of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [78859] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Shoulders of the Corrupted Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [78860] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Shoulders of the Corrupted Protector (Warrior, Hunter, Shaman) [HEROIC]
    [78861] = { 4, 410, ItemUtil.CustomItemInvTypeSelf },   -- Shoulders of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
}

AddOn.TestItems = {
    ---- WOTLK P1 START
    --[[
    40616,40617,40618,40613,40614,40615,40610,40611,40612,40619,40620,40621,40622,40623,40624,40631,40632,40633,40628,
    40629,40630,40625,40626,40627,40634,40635,40636,40637,40638,40639,39192,39190,39191,39189,39188,39139,39146,39193,
    39141,39140,39719,39721,39720,39722,39701,39702,39718,39704,39703,39717,39706,40071,40065,40069,40064,40080,40075,
    40107,40074,39714,40208,39716,39712,39216,39215,39196,39217,39194,39198,39195,39197,39199,39200,39732,39731,39733,
    39735,39756,39727,39724,39734,39723,39725,39729,39726,40071,40065,40069,40064,40080,40075,40107,40108,40074,39757,
    39728,39730,39225,39230,39224,39228,39232,39231,39229,39226,39221,39233,40250,40254,40252,40253,40251,40062,40060,
    39768,40063,39765,39761,40061,39762,39760,39767,39764,39759,40257,40255,40258,40256,39766,39763,39758,39241,39242,
    39240,39237,39243,39236,39239,39235,39234,39244,40602,40198,40197,40186,40200,40193,40196,40184,40185,40188,40187,
    40071,40065,40069,40064,40080,40075,40107,40074,40192,40191,40189,40190,39252,39254,39247,39248,39251,39249,39246,
    39250,39245,39255,40250,40254,40252,40253,40251,40234,40236,40238,40205,40235,40209,40201,40237,40203,40210,40204,
    40206,40257,40255,40258,40256,40207,40208,40233,39259,39260,39258,39257,39256,40247,40246,40249,40243,40242,40241,
    40240,40244,40239,40245,39297,39310,39309,39299,39308,39307,39306,39298,39311,39296,40325,40326,40305,40319,40323,
    40315,40324,40327,40306,40316,40317,40318,40320,40071,40065,40069,40064,40080,40075,40107,40074,40321,40322,39390,
    39386,39391,39379,39345,39369,39392,39389,39388,39344,40250,40254,40252,40253,40251,40339,40338,40329,40341,40333,
    40340,40331,40328,40334,40332,40330,40257,40255,40258,40256,40342,40337,40336,40335,39396,39397,39395,39393,39394,
    40349,40344,40352,40347,40350,40345,40343,40348,40346,39272,39273,39275,39274,39267,39262,39261,39271,39270,40271,
    40269,40260,40270,40262,40272,40261,40263,40259,40071,40065,40069,40064,40080,40075,40107,40074,40273,40267,40268,
    40264,40266,40265,39284,39285,39283,39279,39278,39280,39282,39277,39281,39276,40250,40254,40252,40253,40251,40287,
    40286,40351,40289,40277,40285,40288,40283,40282,40275,40279,40274,40278,40257,40255,40258,40256,40281,40280,40284,
    39272,39284,39396,39309,39237,39279,39191,39215,39294,39248,39194,39251,39379,39188,39345,39146,39232,39193,39388,
    39200,39344,39281,39394,40247,40289,40602,39733,40303,40326,40296,39768,40319,40260,40205,40270,40193,40209,40302,
    39718,40242,39760,40185,40203,40332,40188,40259,40204,39717,40206,40297,40350,40191,40281,39714,39730,40343,40239,
    40280,39716,40265,40346,39295,39294,39293,39292,39291,40303,40301,40296,40304,40299,40302,40298,40294,40297,40300,
    39415,39404,39409,39408,39399,39405,39403,39398,39401,39407,44569,40381,40380,40376,40362,40379,40367,40366,40377,
    40365,40363,40378,40374,40369,40370,40375,40371,40373,40372,40382,40368,44577,39425,39421,39416,39424,39420,39417,
    39423,39422,39426,39419,40405,40403,40398,40387,40399,40383,40386,40396,40402,40384,40395,40388,40401,40400,40385,
    39467,39472,39470,39427,39468,39473,40410,40409,40414,40412,40408,40407,40406,40526,40519,40511,40486,40474,40491,
    40488,40489,40497,40475,43952,44569,44650,40562,40555,40194,40561,40560,40558,40594,40539,40541,40566,40543,40588,
    40564,40549,40590,40589,40592,40591,40532,40531,43952,44577,44651,40428,40427,40426,40433,40430,40429,40613,40614,
    40615,43345,43347,40437,40439,40451,40438,40453,40446,40433,40431,40432,40455,40628,40629,40630,43345,43346,43988,
    43990,43991,43989,43992,43995,43998,43996,43994,43993,44002,44003,44004,44000,44005,44008,44007,44011,44006,43954,
    --]]
    ---- WOTLK P1 END
    ---- WOTLK P2 START
    --[[
    45289,45291,45288,45283,45285,45292,45286,45284,45287,45282,45293,45300,45295,45297,45296,45117,45119,45108,45118,
    45109,45107,45111,45116,45113,45106,45112,45115,45114,45110,45086,45038,45135,45136,45134,45133,45132,45317,45318,
    45312,45316,45321,45310,45313,45314,45311,45309,45186,45185,45162,45164,45187,45167,45161,45166,45157,45168,45158,
    45169,45165,45171,45170,45038,45306,45302,45301,45307,45299,45305,45304,45303,45308,45298,45138,45150,45146,45149,
    45141,45151,45143,45140,45139,45148,45510,45144,45142,45147,45137,45038,45694,45677,45686,45687,45679,45676,45680,
    45675,45685,45682,45869,45867,45871,45868,45870,45253,45258,45260,45259,45249,45251,45252,45248,45250,45247,45254,
    45255,45246,45256,45257,45038,45446,45444,45445,45443,45442,45322,45423,45324,45378,45329,45333,45330,45418,45332,
    45331,45455,45447,45456,45449,45448,45506,45224,45240,45238,45237,45232,45227,45239,45226,45225,45228,45193,45236,
    45235,45233,45234,45038,45242,45245,45244,45241,45243,45607,45857,45704,45701,45697,45698,45696,45699,45702,45703,
    45700,45695,45272,45275,45273,45265,45274,45264,45269,45268,45267,45262,45263,45271,45270,45266,45261,45038,46042,
    46045,46050,46043,46049,46044,46037,46039,46041,46047,46040,46048,46046,46038,46051,46052,45665,45619,45611,45616,
    45610,45615,45594,45599,45609,45620,45607,45612,45613,45587,45570,45617,45038,46053,45832,45865,45864,45709,45711,
    45712,45708,45866,45707,45713,45319,45435,45441,45439,45325,45440,45320,45334,45434,45326,45438,45436,45437,45315,
    45327,45038,45873,45464,45874,45458,45872,45888,45876,45886,45887,45877,45786,45650,45651,45652,45453,45454,45452,
    45451,45450,45461,45462,45460,45459,45612,45457,45815,45038,45632,45633,45634,45893,45927,45894,45895,45892,45928,
    45933,45931,45929,45930,45784,45659,45660,45661,45468,45467,45469,45466,45463,45473,45474,45472,45471,45570,45470,
    45817,45038,45638,45639,45640,45940,45941,45935,45936,45934,45943,45945,45946,45947,45294,45788,45644,45645,45646,
    46110,45483,45482,45481,45480,45479,45486,45488,45487,45485,45484,45613,45814,45038,45653,45654,45655,46110,45973,
    45976,45974,45975,45972,45993,45989,45982,45988,45990,45787,45647,45648,45649,45493,45492,45491,45490,45489,45496,
    45497,45663,45495,45494,45620,45816,45038,45641,45642,45643,46014,46013,46012,46009,46346,45997,46008,46015,46010,
    46011,45996,46032,46034,46036,46035,46033,45514,45508,45512,45504,45513,45502,45505,45501,45503,45515,45507,45509,
    45145,45498,45511,45038,45520,45519,45517,45518,45516,46030,46019,46028,46022,46021,46024,46016,46031,46025,46018,
    45635,45636,45637,46068,46095,46096,46097,46067,46312,45529,45532,45523,45524,45531,45525,45530,45522,45527,45521,
    45038,45656,45657,45658,45537,45536,45534,45535,45533,45693,46341,46347,46344,46346,46345,46340,46343,46339,46351,
    46350,46342,45541,45549,45547,45548,45543,45544,45542,45540,45539,45538,45605,45089,45088,45092,45090,45093,45091,
    45100,45094,45096,45095,45101,45098,45099,45097,45104,45102,45105,45103,46027,46348,
    --]]
    ---- WOTLK P2 END
    -- WOTLK P3 START
    -- trophies and regalia
    -- 47242, 47557, 47558, 47559,
    -- the rest
    --[[
    47617,47613,47608,47616,47610,47611,47609,47615,47614,47607,47578,47612,47921,47923,47919,47926,47916,47918,47917,
    47924,47925,47915,47920,47922,46970,46976,46992,46972,46974,46988,46960,46990,46962,46961,46985,47242,46959,46979,
    46958,46963,46971,46977,46993,46973,46975,46989,46965,46991,46968,46967,46986,47242,46966,46980,46969,46964,47663,
    47620,47669,47621,49235,47683,47680,47711,47619,47679,47618,47703,47676,47927,47931,47929,47932,49238,47933,47935,
    47937,47930,47939,47928,47934,47938,47042,47051,47000,47055,47056,46999,47057,47052,46997,47242,47043,47223,47041,
    47053,46996,46994,47063,47062,47004,47066,47068,47002,47067,47061,47003,47242,47060,47224,47059,47064,47001,46995,
    47721,47719,47718,47717,47720,47728,47727,47726,47725,47724,47940,47945,47942,47943,47944,47947,47949,47946,47948,
    47941,47089,47081,47092,47094,47071,47073,47083,47090,47082,47093,47072,47242,47070,47080,47069,47079,47095,47084,
    47097,47096,47077,47074,47087,47099,47086,47098,47076,47242,47075,47088,47078,47085,47745,49231,47746,47739,47744,
    47738,47747,47700,47742,47736,47737,47743,47740,47956,49234,47959,47954,47961,47952,47957,47955,47958,47953,47951,
    47960,47950,47126,47141,47107,47140,47106,47142,47108,47121,47116,47105,47139,47115,47138,47242,47104,47114,47129,
    47143,47112,47145,47109,47147,47111,47132,47133,47110,47144,47131,47146,47242,47113,47130,47838,47837,47832,47813,
    47829,47811,47836,47830,47810,47814,47808,47809,47816,47834,47815,47835,47812,47741,47974,47977,47972,47965,47969,
    47964,47976,47970,47967,47971,47966,47962,47973,47979,47968,47978,47963,47975,47225,47183,47203,47235,47187,47194,
    47151,47186,47204,47152,47184,47234,47195,47150,47242,47054,47149,47182,47148,47193,47233,47238,47192,47208,47236,
    47189,47205,47155,47190,47209,47153,47191,47240,47207,47154,47242,47237,47157,47188,47156,47206,47239,47556,48712,
    48714,48709,48708,48711,48710,48713,49044,48674,48673,48675,48671,48672,47506,47526,47517,47519,47521,47524,47515,
    47547,47545,47549,49096,47552,47553,47622,47623,47627,47626,47624,47625,47629,47635,47631,47630,47628,47634,47632,
    47633,47654,47655,47656,47657,49307,49304,49437,49298,49303,49296,49299,49297,49302,49301,49305,49308,49306,49309,
    49636,49463,49310,49644,49295,49294,49491,49494,49465,49499,49495,49501,49498,49500,49496,49497,49493,49490,49492,
    49489,49636,49464,49488,49644,49295,49294,
    --]]
    -- WOTLK P3 END

    -- WOTLK P4 START
    --[[
    -- marks
    52025, 52026, 52027, 52028, 52029, 52030,
    -- the rest
    49908, 49919, 49949, 49950, 49951, 49952, 49960, 49964, 49967, 49968, 49975, 49976, 49977, 49978, 49979, 49980,
    49981, 49982, 49983, 49985, 49986, 49987, 49988, 49989, 49990, 49991, 49992, 49993, 49994, 49995, 49996, 49997,
    49998, 49999, 50000, 50001, 50002, 50003, 50005, 50006, 50008, 50009, 50010, 50011, 50012, 50014, 50015, 50016,
    50019, 50020, 50021, 50022, 50023, 50024, 50025, 50026, 50027, 50028, 50030, 50032, 50033, 50034, 50035, 50036,
    50037, 50038, 50040, 50041, 50042, 50056, 50059, 50060, 50061, 50062, 50063, 50064, 50065, 50067, 50068, 50069,
    50070, 50071, 50072, 50073, 50074, 50075, 50170, 50171, 50172, 50173, 50174, 50175, 50176, 50177, 50178, 50179,
    50180, 50181, 50182, 50183, 50184, 50185, 50186, 50187, 50188, 50190, 50192, 50195, 50199, 50202, 50205, 50226,
    50231, 50274, 50333, 50339, 50340, 50341, 50342, 50343, 50344, 50345, 50346, 50348, 50349, 50351, 50352, 50353,
    50354, 50359, 50360, 50361, 50362, 50363, 50364, 50365, 50366, 50411, 50412, 50413, 50414, 50415, 50416, 50417,
    50418, 50421, 50423, 50424, 50425, 50426, 50427, 50428, 50429, 50444, 50447, 50449, 50450, 50451, 50452, 50453,
    50472, 50603, 50604, 50605, 50606, 50607, 50608, 50609, 50610, 50611, 50612, 50613, 50614, 50615, 50616, 50617,
    50618, 50619, 50620, 50621, 50622, 50623, 50624, 50625, 50626, 50627, 50628, 50629, 50630, 50631, 50632, 50633,
    50635, 50636, 50638, 50639, 50640, 50641, 50642, 50643, 50644, 50645, 50646, 50647, 50648, 50649, 50650, 50651,
    50652, 50653, 50654, 50655, 50656, 50657, 50658, 50659, 50660, 50661, 50663, 50664, 50665, 50667, 50668, 50670,
    50671, 50672, 50673, 50674, 50675, 50676, 50677, 50678, 50679, 50680, 50681, 50682, 50684, 50685, 50686, 50687,
    50688, 50689, 50690, 50691, 50692, 50693, 50694, 50695, 50696, 50697, 50698, 50699, 50700, 50701, 50702, 50703,
    50704, 50705, 50706, 50707, 50708, 50709, 50710, 50711, 50712, 50713, 50714, 50715, 50716, 50717, 50718, 50719,
    50720, 50721, 50722, 50723, 50724, 50725, 50726, 50727, 50728, 50729, 50730, 50731, 50732, 50733, 50734, 50735,
    50736, 50737, 50738, 50759, 50760, 50761, 50762, 50763, 50764, 50771, 50772, 50773, 50774, 50775, 50776, 50777,
    50778, 50779, 50780, 50781, 50782, 50783, 50784, 50785, 50786, 50787, 50788, 50789, 50790, 50791, 50792, 50793,
    50794, 50795, 50796, 50797, 50798, 50799, 50800, 50801, 50802, 50803, 50804, 50805, 50806, 50807, 50808, 50809,
    50810, 50811, 50812, 50818, 50852, 50858, 50859, 50966, 50967, 50985, 50986, 50988, 50990, 50998, 51000, 51001,
    51002, 51003, 51004, 51005, 51006, 51007, 51008, 51009, 51010, 51011, 51012, 51013, 51014, 51015, 51016, 51017,
    51018, 51019, 51020, 51021, 51022, 51023, 51024, 51025, 51325, 51326, 51379, 51380, 51381, 51382, 51383, 51384,
    51385, 51386, 51387, 51548, 51550, 51551, 51552, 51553, 51554, 51555, 51556, 51561, 51562, 51563, 51564, 51565,
    51566, 51582, 51583, 51584, 51585, 51586, 51777, 51779, 51782, 51783, 51784, 51785, 51786, 51787, 51788, 51789,
    51790, 51791, 51792, 51795, 51796, 51797, 51798, 51799, 51800, 51801, 51802, 51803, 51811, 51812, 51813, 51814,
    51815, 51816, 51817, 51818, 51819, 51820, 51821, 51822, 51823, 51824, 51825, 51826, 51827, 51828, 51829, 51830,
    51831, 51832, 51833, 51834, 51835, 51836, 51837, 51838, 51839, 51840, 51841, 51842, 51843, 51844, 51845, 51846,
    51847, 51848, 51849, 51850, 51851, 51852, 51853, 51854, 51855, 51856, 51857, 51858, 51859, 51860, 51861, 51862,
    51863, 51864, 51865, 51866, 51867, 51868, 51869, 51870, 51871, 51872, 51873, 51874, 51875, 51876, 51877, 51878,
    51879, 51881, 51882, 51883, 51884, 51885, 51886, 51887, 51888, 51889, 51890, 51891, 51892, 51893, 51894, 51895,
    51896, 51897, 51898, 51899, 51900, 51901, 51902, 51903, 51904, 51905, 51906, 51907, 51908, 51909, 51910, 51911,
    51912, 51913, 51914, 51915, 51916, 51917, 51918, 51919, 51920, 51921, 51922, 51923, 51924, 51925, 51926, 51927,
    51928, 51929, 51930, 51931, 51932, 51933, 51934, 51935, 51936, 51937, 51938, 51939, 51940, 51941, 51942, 51943,
    51944, 51945, 51946, 51947, 52025, 52026, 52027, 52028, 52029, 52030

    -- CATA P1 START
    59117, 59118, 59119, 59120, 59121, 59122, 59216, 59217, 59218, 59219, 59220, 59221, 59222, 59223, 59224, 59225,
    59233, 59234, 59310, 59311, 59312, 59313, 59314, 59315, 59316, 59317, 59318, 59319, 59320, 59321, 59322, 59324,
    59325, 59326, 59327, 59328, 59329, 59330, 59331, 59332, 59333, 59334, 59335, 59336, 59337, 59340, 59341, 59342,
    59343, 59344, 59346, 59347, 59348, 59349, 59350, 59351, 59352, 59353, 59354, 59355, 59356, 59441, 59442, 59443,
    59444, 59450, 59451, 59452, 59454, 59457, 59459, 59469, 59470, 59471, 59472, 59473, 59474, 59475, 59476, 59481,
    59482, 59483, 59484, 59485, 59486, 59487, 59490, 59492, 59494, 59495, 59497, 59498, 59499, 59500, 59501, 59502,
    59503, 59504, 59505, 59506, 59507, 59508, 59509, 59510, 59511, 59512, 59513, 59514, 59515, 59516, 59517, 59518,
    59519, 60226, 60227, 60228, 60229, 60230, 60231, 60232, 60233, 60234, 60235, 60236, 60237, 60238, 63041, 63488,
    63489, 63490, 63491, 63492, 63493, 63494, 63495, 63496, 63497, 63498, 63499, 63500, 63501, 63502, 63503, 63504,
    63505, 63506, 63507, 63531, 63532, 63533, 63534, 63535, 63536, 63540, 63679, 63680, 63682, 63683, 63684, 64314,
    64315, 64316, 65000, 65001, 65002, 65003, 65004, 65007, 65017, 65018, 65019, 65020, 65021, 65022, 65023, 65024,
    65025, 65026, 65027, 65028, 65029, 65030, 65031, 65032, 65033, 65034, 65035, 65036, 65037, 65038, 65039, 65040,
    65041, 65042, 65043, 65044, 65045, 65046, 65047, 65048, 65049, 65050, 65051, 65052, 65053, 65054, 65055, 65056,
    65057, 65058, 65059, 65060, 65061, 65062, 65063, 65064, 65065, 65066, 65067, 65068, 65069, 65070, 65071, 65072,
    65073, 65074, 65075, 65076, 65077, 65078, 65079, 65080, 65081, 65082, 65083, 65084, 65085, 65086, 65087, 65088,
    65089, 65090, 65091, 65092, 65093, 65094, 65095, 65096, 65105, 65106, 65107, 65108, 65109, 65110, 65111, 65112,
    65113, 65114, 65115, 65116, 65117, 65118, 65119, 65120, 65121, 65122, 65123, 65124, 65125, 65126, 65127, 65128,
    65129, 65130, 65131, 65132, 65133, 65134, 65135, 65136, 65137, 65138, 65139, 65140, 65141, 65142, 65143, 65144,
    65145, 65367, 65368, 65369, 65370, 65371, 65372, 65373, 65374, 65375, 65376, 65377, 65378, 65379, 65380, 65381,
    65382, 65383, 65384, 65385, 65386, 66998, 67423, 67424, 67425, 67426, 67427, 67428, 67429, 67430, 67431, 68127,
    68128, 68129, 68130, 68131, 68132, 68600, 69827, 69828, 69829, 69830, 69831, 69833, 69834, 69835, 69878, 69879,
    69880, 69881, 69882, 69883, 69884, 69885,
    -- CATA P1 END

    -- CATA P2 OMITTED (Troll 5 Player Dungeons)

    -- CATA P3 START
    71041, 71040, 71044, 71031, 71030, 71042, 71043, 70914, 71029, 71032, 68981, 70922, 71039, 71038, 71407, 71411,
    71410, 71402, 71403, 71412, 71413, 71405, 71404, 71401, 69138, 71406, 71409, 71408, 70992, 71011, 71003, 71010,
    71005, 71009, 71004, 70993, 71007, 70912, 71012, 71006, 70991, 71415, 71421, 71416, 71424, 71417, 71425, 71418,
    71419, 71426, 71420, 71423, 71422, 71414, 70990, 70989, 70735, 70987, 70985, 70986, 70736, 70734, 70737, 70988,
    70739, 70738, 68983, 70733, 71665, 71434, 71435, 71428, 71436, 71438, 71437, 71429, 71430, 71432, 71439, 71431,
    71433, 69149, 71427, 71679, 71686, 71672, 71023, 71025, 71020, 71018, 71027, 71026, 71021, 71028, 70913, 71019,
    71024, 71022, 71014, 71013, 71447, 71450, 71440, 71442, 71451, 71452, 71443, 71453, 71444, 71446, 71449, 71448,
    71445, 71441, 71678, 71685, 71671, 71343, 71345, 71314, 71341, 71340, 71315, 71342, 70916, 70917, 68982, 71323,
    71312, 70915, 71461, 71456, 71455, 71463, 71464, 71457, 71465, 71459, 71458, 69139, 71462, 71454, 71460, 71676,
    71683, 71669, 71350, 71349, 71313, 71346, 71344, 70920, 71351, 71348, 68927, 68926, 69897, 71347, 71681, 71688,
    71674, 71471, 71474, 71467, 71468, 71469, 71470, 71475, 71472, 69112, 69111, 71466, 71473, 71680, 71687, 71673,
    71358, 71357, 71356, 70921, 71354, 68994, 68925, 68995, 71355, 71352, 71798, 71353, 71675, 71682, 71668, 69224,
    71614, 71613, 71616, 71612, 71610, 69150, 69110, 69167, 71615, 70723, 71797, 71611, 71677, 71684, 71670, 69224,
    71779, 71787, 71785, 71780, 71776, 71782, 71775, 71141, 69815, 69237, 71778, 71786, 71784, 71781, 71777, 71783,
    71774, 71141, 69815, 69237, 71617, 71640, 71365, 70929, 71367, 68972, 68915, 71359, 71362, 71361, 71360, 71366,
    71641, 71561, 71563, 71564, 69113, 69109, 71560, 71562, 71557, 71559, 71558, 71579, 71575, 71590, 71587, 71577,
    71567, 71580, 71568, 71593, 71592, 71617, 69976, 69966, 69975, 69965, 69962, 69960, 69971, 69974, 69972, 69961,
    69963, 69973, 69970, 69969, 69968, 69958, 69957, 69959,
    -- CATA P3 END
    --]]

    -- CATA P4 START
    71999, 72000, 72001, 72002, 72003, 72004, 72005, 72006, 72007, 72008, 72009, 72010, 72011, 72012, 72013, 72014,
    72015, 72016, 77067, 77069, 77188, 77189, 77190, 77191, 77192, 77193, 77194, 77195, 77196, 77197, 77198, 77199,
    77200, 77201, 77202, 77203, 77204, 77205, 77206, 77207, 77208, 77209, 77210, 77211, 77212, 77213, 77214, 77215,
    77216, 77217, 77218, 77219, 77220, 77221, 77223, 77224, 77225, 77226, 77227, 77228, 77229, 77230, 77231, 77232,
    77234, 77235, 77236, 77237, 77238, 77239, 77240, 77241, 77242, 77243, 77244, 77245, 77246, 77247, 77248, 77249,
    77250, 77251, 77252, 77253, 77254, 77255, 77257, 77258, 77259, 77260, 77261, 77262, 77263, 77265, 77266, 77267,
    77268, 77269, 77270, 77271, 77938, 77969, 77970, 77971, 77972, 77973, 77974, 77975, 77976, 77977, 77978, 77979,
    77980, 77981, 77982, 77983, 77989, 77990, 77991, 77992, 77993, 77994, 77995, 77996, 77997, 77998, 77999, 78000,
    78001, 78002, 78003, 78011, 78012, 78013, 78170, 78171, 78172, 78173, 78174, 78175, 78176, 78177, 78178, 78179,
    78180, 78181, 78182, 78183, 78184, 78357, 78359, 78361, 78362, 78363, 78364, 78365, 78366, 78367, 78368, 78369,
    78370, 78371, 78372, 78373, 78375, 78376, 78377, 78378, 78380, 78381, 78382, 78384, 78385, 78386, 78387, 78388,
    78389, 78390, 78391, 78392, 78393, 78395, 78396, 78397, 78398, 78399, 78400, 78401, 78402, 78403, 78404, 78405,
    78406, 78408, 78411, 78412, 78413, 78414, 78415, 78416, 78417, 78418, 78419, 78420, 78421, 78422, 78423, 78424,
    78425, 78427, 78428, 78429, 78430, 78431, 78432, 78433, 78434, 78435, 78436, 78438, 78439, 78440, 78441, 78442,
    78443, 78444, 78445, 78446, 78447, 78448, 78449, 78450, 78451, 78452, 78454, 78455, 78456, 78457, 78458, 78460,
    78461, 78462, 78463, 78464, 78465, 78466, 78467, 78468, 78469, 78470, 78471, 78472, 78473, 78474, 78475, 78476,
    78477, 78478, 78479, 78480, 78481, 78482, 78483, 78484, 78485, 78486, 78487, 78488, 78489, 78490, 78491, 78492,
    78493, 78494, 78495, 78496, 78497, 78498, 78847, 78848, 78849, 78850, 78851, 78852, 78853, 78854, 78855, 78856,
    78857, 78858, 78859, 78860, 78861, 78862, 78863, 78864, 78865, 78866, 78867, 78868, 78869, 78870, 78871, 78872,
    78873, 78874, 78875, 78876, 78878, 78879, 78882, 78884, 78885, 78886, 78887, 78888, 78889
    -- CATA P4 START
}