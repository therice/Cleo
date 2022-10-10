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

    -- WOTLK P1
    -- 10 player
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
}

-- todo : this could use some housekeeping to eliminate test items that aren't from current phase
AddOn.TestItems = {
    -- WOTLK P1 START
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
    -- WOTLK P1 END
}

--[[
do
    for itemId, _ in pairs(AddOn.DefaultCustomItems) do
        tinsert(AddOn.TestItems, itemId)
    end
end
--]]