--- @type AddOn
local _, AddOn = ...
local Logging = LibStub("LibLogging-1.0")

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

    -- TBC Classic P2
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

    -- TBC Classic P3
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

    -- TBC Classic P4
    [34848] = { 4, 154, "INVTYPE_WRIST" },              -- Bracers of the Forgotten Conqueror
    [34851] = { 4, 154, "INVTYPE_WRIST" },              -- Bracers of the Forgotten Protector
    [34852] = { 4, 154, "INVTYPE_WRIST" },              -- Bracers of the Forgotten Vanquisher
    [34856] = { 4, 154, "INVTYPE_FEET" },               -- Boots of the Forgotten Conqueror
    [34857] = { 4, 154, "INVTYPE_FEET" },               -- Boots of the Forgotten Protector
    [34858] = { 4, 154, "INVTYPE_FEET" },               -- Boots of the Forgotten Vanquisher
    [34853] = { 4, 154, "INVTYPE_WAIST" },              -- Belt of the Forgotten Conqueror
    [34854] = { 4, 154, "INVTYPE_WAIST" },              -- Belt of the Forgotten Protector
    [34855] = { 4, 154, "INVTYPE_WAIST" },              -- Belt of the Forgotten Vanquisher

}

AddOn.TestItems = {
    28797,28799,28796,28801,28795,28800,29763,29764,29762,28804,28803,28828,28827,28810,28824,28822,28823,28830,31750,
    29766,29767,29765,28802,28794,28825,28826,30056,32516,30050,30055,30047,30054,30048,30053,30052,33055,30664,30629,
    30049,30051,30064,30067,30062,30060,30066,30065,30057,30059,30061,33054,30665,30063,30058,30092,30097,30091,30096,
    30627,30095,30239,30240,30241,30100,30101,30099,30663,30626,30090,30245,30246,30247,30098,30079,30075,30085,30068,
    30084,30081,30008,30083,33058,30720,30082,30080,30107,30111,30106,30104,30102,30112,30109,30110,30621,30103,30108,
    30105,30242,30243,30244,29906,30027,30022,30620,30023,30021,30025,30324,30322,30323,30321,30280,30282,30283,30281,
    30308,30304,30305,30307,30306,30301,30303,30302,30183,32897,29925,29918,29947,29921,29922,29920,30448,30447,29923,
    32944,29948,29924,29949,29986,29984,29985,29983,32515,30619,30450,30248,30249,30250,29977,29972,29966,29976,29951,
    29965,29950,32267,30446,30449,29962,29981,29982,29992,29989,29994,29990,29987,29995,29991,29998,29997,29993,29996,
    29988,30236,30237,30238,32458,32405,29905,30024,30020,30029,30026,30030,30028,30324,30322,30323,30321,30280,30282,
    30283,30281,30308,30304,30305,30307,30306,30301,30303,30302,30183,32897,30871,30870,30863,30868,30864,30869,30873,
    30866,30862,30861,30865,30872,32459,30884,30888,30885,30879,30886,30887,30880,30878,30874,30881,30883,30882,30895,
    30916,30894,30917,30914,30891,30892,30919,30893,30915,30918,30889,30899,30898,30900,30896,30897,30901,31092,31094,
    31093,30913,30912,30905,30907,30904,30903,30911,30910,30902,30908,30909,30906,31097,31095,31096,32590,34010,32609,
    32592,32591,32589,34009,32946,32945,32428,32897,32285,32296,32303,32295,32298,32297,32289,32307,32239,32240,32377,
    32241,32234,32242,32232,32243,32245,32238,32247,32237,32236,32248,32256,32252,32259,32251,32258,32250,32260,32261,
    32257,32254,32262,32255,32253,32273,32270,32513,32265,32271,32264,32275,32276,32279,32278,32263,32268,32266,32361,
    32337,32338,32340,32339,32334,32342,32333,32341,32335,32501,32269,32344,32343,32353,32351,32347,32352,32517,32346,
    32354,32345,32349,32362,32350,32332,32363,32323,32329,32327,32324,32328,32510,32280,32512,32330,32348,32326,32325,
    32367,32366,32365,32370,32368,32369,31101,31103,31102,32331,32519,32518,32376,32373,32505,31098,31100,31099,32524,
    32525,32235,32521,32497,32483,32496,32837,32838,31089,31091,31090,32471,32500,32374,32375,32336,32590,34012,32609,
    32593,32592,32608,32606,32591,32589,32526,32528,32527,34009,32943,34011,32228,32231,32229,32249,32230,32227,32428,
    32897,32738,32739,32736,32737,32748,32744,32750,32751,32749,32745,32746,32747,32754,32755,32753,32752,
}

--[[
do
    for itemId, _ in pairs(AddOn.DefaultCustomItems) do
        tinsert(AddOn.TestItems, itemId)
    end
end
--]]