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
    [30245] = { 4, 120, "INVTYPE_LEGS" },               -- Leggings of the Vanquished Champion

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
    30283,30281,30308,30304,30305,30307,30306,30301,30303,30302,30183,32897
}

--[[
do
    for itemId, _ in pairs(AddOn.DefaultCustomItems) do
        tinsert(AddOn.TestItems, itemId)
    end
end
--]]