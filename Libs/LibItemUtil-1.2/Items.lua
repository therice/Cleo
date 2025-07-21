local lib = LibStub("LibItemUtil-1.2", true)

lib.ReputationItems = {
    -- Zul'Gurub
    -- Coins
    [19698] = "Zulian Coin",
    [19699] = "Razzashi Coin",
    [19700] = "Hakkari Coin",
    [19701] = "Gurubashi Coin",
    [19702] = "Vilebranch Coin",
    [19703] = "Witherbark Coin",
    [19704] = "Sandfury Coin",
    [19705] = "Skullsplitter Coin",
    [19706] = "Bloodscalp Coin",
    -- Bijous
    [19707] = "Red Hakkari Bijou",
    [19708] = "Blue Hakkari Bijou",
    [19709] = "Yellow Hakkari Bijou",
    [19710] = "Orange Hakkari Bijou",
    [19711] = "Green Hakkari Bijou",
    [19712] = "Purple Hakkari Bijou",
    [19713] = "Bronze Hakkari Bijou",
    [19714] = "Silver Hakkari Bijou",
    [19715] = "Gold Hakkari Bijou",
    -- Ahn'Qiraj
    -- Scarabs
    [20858] = "Stone Scarab",
    [20859] = "Gold Scarab",
    [20860] = "Silver Scarab",
    [20861] = "Bronze Scarab",
    [20862] = "Crystal Scarab",
    [20863] = "Clay Scarab",
    [20864] = "Bone Scarab",
    [20865] = "Ivory Scarab",
    -- Naxx
    -- Wartorn ... ?
}

-- https://wowpedia.fandom.com/wiki/InventorySlotId
lib.TokenEquipmentLocations = {
    -- AQ Tier 2.5 tokens
    -- AQ20
    [20884] = { "Finger0Slot", "Finger1Slot" }, -- Magisterial Ring
    [20885] = { "BackSlot" },                   -- Martial Drape
    [20886] = { "Weapon" },                     -- Spiked Hilt
    [20888] = { "Finger0Slot", "Finger1Slot" }, -- Ceremonial Ring
    [20889] = { "BackSlot" },                   -- Regal Drape
    [20890] = { "Weapon" },                     -- Ornate Hilt
    -- AQ40
    [20926] = { "HeadSlot" },                   -- Vek'nilash's Circlet
    [20927] = { "LegsSlot" },                   -- Ouro's Intact Hide
    [20928] = { "ShoulderSlot", "FeetSlot" },   -- Bindings of Command
    [20929] = { "HeadSlot" },                   -- Veklors Diadem
    [20930] = { "ChestSlot" },                  -- Carapace of the Old God
    [20931] = { "LegsSlot" },                   -- Skin of the Great Sandworm
    [20932] = { "ShoulderSlot", "FeetSlot" },   -- Bindings of Dominance
    [20933] = { "ChestSlot" },                  -- Husk of the Old God
    -- Naxx
    [22351] = { "ChestSlot" },                  -- Desecrated Robe (Priest, Mage, Warlock)
    [22350] = { "ChestSlot" },                  -- Desecrated Tunic (Paladin, Hunter, Shaman, Paladin)
    [22349] = { "ChestSlot" },                  -- Desecrated Breastplate (Warrior, Rogue)
    [22366] = { "LegsSlot" },                   -- Desecrated Leggings (Priest, Mage, Warlock)
    [22359] = { "LegsSlot" },                   -- Desecrated Legguards (Paladin, Hunter, Shaman, Paladin)
    [22352] = { "LegsSlot" },                   -- Desecrated Legplates (Warrior, Rogue)
    [22366] = { "HeadSlot" },                   -- Desecrated Circlet (Priest, Mage, Warlock)
    [22360] = { "HeadSlot" },                   -- Desecrated Headpiece (Paladin, Hunter, Shaman, Paladin)
    [22353] = { "HeadSlot" },                   -- Desecrated Helmet (Warrior, Rogue)
    [22369] = { "WristSlot" },                  -- Desecrated Bindings (Priest, Mage, Warlock)
    [22362] = { "WristSlot" },                  -- Desecrated Wristguards (Paladin, Hunter, Shaman, Paladin)
    [22355] = { "WristSlot" },                  -- Desecrated Bracers (Warrior, Rogue)
    [22371] = { "HandsSlot" },                  -- Desecrated Gloves (Priest, Mage, Warlock)
    [22364] = { "HandsSlot" },                  -- Desecrated Handguards (Paladin, Hunter, Shaman, Paladin)
    [22357] = { "HandsSlot" },                  -- Desecrated Gauntlets (Warrior, Rogue)
    [22372] = { "FeetSlot" },                   -- Desecrated Sandals (Priest, Mage, Warlock)
    [22365] = { "FeetSlot" },                   -- Desecrated Boots (Paladin, Hunter, Shaman, Paladin)
    [22358] = { "FeetSlot" },                   -- Desecrated Sabatons (Warrior, Rogue)
    [22370] = { "WaistSlot" },                  -- Desecrated Belt (Priest, Mage, Warlock)
    [22363] = { "WaistSlot" },                  -- Desecrated Girdle (Paladin, Hunter, Shaman, Paladin)
    [22356] = { "WaistSlot" },                  -- Desecrated Waistguard (Warrior, Rogue)
    [22368] = { "ShoulderSlot" },               -- Desecrated Shoulderpads (Priest, Mage, Warlock)
    [22361] = { "ShoulderSlot" },               -- Desecrated Spaulders (Paladin, Hunter, Shaman, Paladin)
    [22354] = { "ShoulderSlot" },               -- Desecrated Pauldrons (Warrior, Rogue)
    [22520] = { "Trinket0Slot", "Trinket1Slot"},-- The Phylactery of Kel'Thuzad
    -- TBC Classic P1 (T4)
    [29761] = { "HeadSlot" },                   -- Helm of the Fallen Defender
    [29759] = { "HeadSlot" },                   -- Helm of the Fallen Hero
    [29760] = { "HeadSlot" },                   -- Helm of the Fallen Champion
    [29764] = { "ShoulderSlot" },               -- Pauldrons of the Fallen Defender
    [29762] = { "ShoulderSlot" },               -- Pauldrons of the Fallen Hero
    [29763] = { "ShoulderSlot" },               -- Pauldrons of the Fallen Champion
    [29753] = { "ChestSlot" },                  -- Chestguard of the Fallen Defender
    [29755] = { "ChestSlot" },                  -- Chestguard of the Fallen Hero
    [29754] = { "ChestSlot" },                  -- Chestguard of the Fallen Champion
    [29758] = { "HandsSlot" },                  -- Gloves of the Fallen Defender
    [29756] = { "HandsSlot" },                  -- Gloves of the Fallen Hero
    [29757] = { "HandsSlot" },                  -- Gloves of the Fallen Champion
    [29767] = { "LegsSlot" },                   -- Leggings of the Fallen Defender
    [29765] = { "LegsSlot" },                   -- Leggings of the Fallen Hero
    [29766] = { "LegsSlot" },                   -- Leggings of the Fallen Champion
    [32385] = { "Finger0Slot", "Finger1Slot" }, -- Magtheridon's Head
    [32386] = { "Finger0Slot", "Finger1Slot" }, -- Magtheridon's Head
    -- TBC Classic P2 (T5)
    [30243] = { "HeadSlot" },                   -- Helm of the Vanquished Defender
    [30244] = { "HeadSlot" },                   -- Helm of the Vanquished Hero
    [30242] = { "HeadSlot" },                   -- Helm of the Vanquished Champion
    [30249] = { "ShoulderSlot" },               -- Pauldrons of the Vanquished Defender
    [30250] = { "ShoulderSlot" },               -- Pauldrons of the Vanquished Hero
    [30248] = { "ShoulderSlot" },               -- Pauldrons of the Vanquished Champion
    [30237] = { "ChestSlot" },                  -- Chestguard of the Vanquished Defender
    [30238] = { "ChestSlot" },                  -- Chestguard of the Vanquished Hero
    [30236] = { "ChestSlot" },                  -- Chestguard of the Vanquished Champion
    [30240] = { "HandsSlot" },                  -- Gloves of the Vanquished Defender
    [30241] = { "HandsSlot" },                  -- Gloves of the Vanquished Hero
    [30239] = { "HandsSlot" },                  -- Gloves of the Vanquished Champion
    [30246] = { "LegsSlot" },                   -- Leggings of the Vanquished Defender
    [30247] = { "LegsSlot" },                   -- Leggings of the Vanquished Hero
    [30245] = { "LegsSlot" },                   -- Leggings of the Vanquished Champion
    [32405] = { "NeckSlot" },                  -- Verdant Sphere
    -- TBC Classic P3 (T6)
    [31097] = { "HeadSlot" },                   -- Helm of the Forgotten Conqueror
    [31095] = { "HeadSlot" },                   -- Helm of the Forgotten Protector
    [31096] = { "HeadSlot" },                   -- Helm of the Forgotten Vanquisher
    [31101] = { "ShoulderSlot" },               -- Pauldrons of the Forgotten Conqueror
    [31103] = { "ShoulderSlot" },               -- Pauldrons of the Forgotten Protector
    [31102] = { "ShoulderSlot" },               -- Pauldrons of the Forgotten Vanquisher
    [31089] = { "ChestSlot" },                  -- Chestguard of the Forgotten Conqueror
    [31091] = { "ChestSlot" },                  -- Chestguard of the Forgotten Protector
    [31090] = { "ChestSlot" },                  -- Chestguard of the Forgotten Vanquisher
    [31092] = { "HandsSlot" },                  -- Gloves of the Forgotten Conqueror
    [31094] = { "HandsSlot" },                  -- Gloves of the Forgotten Protector
    [31093] = { "HandsSlot" },                  -- Gloves of the Forgotten Vanquisher
    [31098] = { "LegsSlot" },                   -- Leggings of the Forgotten Conqueror
    [31100] = { "LegsSlot" },                   -- Leggings of the Forgotten Protector
    [31099] = { "LegsSlot" },                   -- Leggings of the Forgotten Vanquisher
    -- TBC Classic P3 (T6)
    [34848] = { "WristSlot" },                  -- Bracers of the Forgotten Conqueror
    [34851] = { "WristSlot" },                  -- Bracers of the Forgotten Protector
    [34852] = { "WristSlot" },                  -- Bracers of the Forgotten Vanquisher
    [34856] = { "FeetSlot" },                   -- Boots of the Forgotten Conqueror
    [34857] = { "FeetSlot" },                   -- Boots of the Forgotten Protector
    [34858] = { "FeetSlot" },                   -- Boots of the Forgotten Vanquisher
    [34853] = { "WaistSlot" },                  -- Belt of the Forgotten Conqueror
    [34854] = { "WaistSlot" },                  -- Belt of the Forgotten Protector
    [34855] = { "WaistSlot" },                  -- Belt of the Forgotten Vanquisher
    -- WOTLK Classic P1 (T7)
    -- 10 player
    [40616] = { "HeadSlot" },                   -- Helm of the Lost Conqueror
    [40617] = { "HeadSlot" },                   -- Helm of the Lost Protector
    [40618] = { "HeadSlot" },                   -- Helm of the Lost Vanquisher
    [40613] = { "HandsSlot" },                  -- Gloves of the Lost Conqueror
    [40614] = { "HandsSlot" },                  -- Gloves of the Lost Protector
    [40615] = { "HandsSlot" },                  -- Gloves of the Lost Vanquisher
    [40610] = { "ChestSlot" },                  -- Chestguard of the Lost Conqueror
    [40611] = { "ChestSlot" },                  -- Chestguard of the Lost Protector
    [40612] = { "ChestSlot" },                  -- Chestguard of the Lost Vanquisher
    [40619] = { "LegsSlot" },                   -- Leggings of the Lost Conqueror
    [40620] = { "LegsSlot" },                   -- Leggings of the Lost Protector
    [40621] = { "LegsSlot" },                   -- Leggings of the Lost Vanquisher
    [40622] = { "ShoulderSlot" },               -- Spaulders of the Lost Conqueror
    [40623] = { "ShoulderSlot" },               -- Spaulders of the Lost Protector
    [40624] = { "ShoulderSlot" },               -- Spaulders of the Lost Vanquisher
    [44569] = { "NeckSlot" },                   -- Key to the Focusing Iris
    -- 25 player
    [40631] = { "HeadSlot" },                   -- Crown of the Lost Conqueror
    [40632] = { "HeadSlot" },                   -- Crown of the Lost Protector
    [40633] = { "HeadSlot" },                   -- Crown of the Lost Vanquisher
    [40628] = { "HandsSlot" },                  -- Gauntlets of the Lost Conqueror
    [40629] = { "HandsSlot" },                  -- Gauntlets of the Lost Protector
    [40630] = { "HandsSlot" },                  -- Gauntlets of the Lost Vanquisher
    [40625] = { "ChestSlot" },                  -- Breastplate of the Lost Conqueror
    [40626] = { "ChestSlot" },                  -- Breastplate of the Lost Protector
    [40627] = { "ChestSlot" },                  -- Breastplate of the Lost Vanquisher
    [40634] = { "LegsSlot" },                   -- Legplates of the Lost Conqueror
    [40635] = { "LegsSlot" },                   -- Legplates of the Lost Protector
    [40636] = { "LegsSlot" },                   -- Legplates of the Lost Vanquisher
    [40637] = { "ShoulderSlot" },               -- Mantle of the Lost Conqueror
    [40638] = { "ShoulderSlot" },               -- Mantle of the Lost Protector
    [40639] = { "ShoulderSlot" },               -- Mantle of the Lost Vanquisher
    [44577] = { "NeckSlot" },                   -- Heroic Key to the Focusing Iris
    -- WOTLK Classic P2 (T8)
    -- 10 player
    [45647] = { "HeadSlot" },                   -- Helm of the Wayward Conqueror
    [45648] = { "HeadSlot" },                   -- Helm of the Wayward Protector
    [45649] = { "HeadSlot" },                   -- Helm of the Wayward Vanquisher
    [45644] = { "HandsSlot" },                  -- Gloves of the Wayward Conqueror
    [45645] = { "HandsSlot" },                  -- Gloves of the Wayward Protector
    [45646] = { "HandsSlot" },                  -- Gloves of the Wayward Vanquisher
    [45635] = { "ChestSlot" },                  -- Chestguard of the Wayward Conqueror
    [45636] = { "ChestSlot" },                  -- Chestguard of the Wayward Protector
    [45637] = { "ChestSlot" },                  -- Chestguard of the Wayward Vanquisher
    [45650] = { "LegsSlot" },                   -- Leggings of the Wayward Conqueror
    [45651] = { "LegsSlot" },                   -- Leggings of the Wayward Protector
    [45652] = { "LegsSlot" },                   -- Leggings of the Wayward Vanquisher
    [45659] = { "ShoulderSlot" },               -- Spaulders of the Wayward Conqueror
    [45660] = { "ShoulderSlot" },               -- Spaulders of the Wayward Protector
    [45661] = { "ShoulderSlot" },               -- Spaulders of the Wayward Vanquisher
    [46052] = { "Finger0Slot", "BackSlot" },    -- "All Is Well That Ends Well"
    -- 25 player
    [45638] = { "HeadSlot" },                   -- Crown of the Wayward Conqueror
    [45639] = { "HeadSlot" },                   -- Crown of the Wayward Protector
    [45640] = { "HeadSlot" },                   -- Crown of the Wayward Vanquisher
    [45641] = { "HandsSlot" },                  -- Gauntlets of the Wayward Conqueror
    [45642] = { "HandsSlot" },                  -- Gauntlets of the Wayward Protector
    [45643] = { "HandsSlot" },                  -- Gauntlets of the Wayward Vanquisher
    [45632] = { "ChestSlot" },                  -- Breastplate of the Wayward Conqueror
    [45633] = { "ChestSlot" },                  -- Breastplate of the Wayward Protector
    [45634] = { "ChestSlot" },                  -- Breastplate of the Wayward Vanquisher
    [45653] = { "LegsSlot" },                   -- Legplates of the Wayward Conqueror
    [45654] = { "LegsSlot" },                   -- Legplates of the Wayward Protector
    [45655] = { "LegsSlot" },                   -- Legplates of the Wayward Vanquisher
    [45656] = { "ShoulderSlot" },               -- Mantle of the Wayward Conqueror
    [45657] = { "ShoulderSlot" },               -- Mantle of the Wayward Protector
    [45658] = { "ShoulderSlot" },               -- Mantle of the Wayward Vanquisher
    [46053] = { "Finger0Slot", "BackSlot" },    -- Heroic: All Is Well That Ends Well
    -- WOTLK Classic P3 (T9)
    --[[
    How does tier work in TOC?

    Each set consists of five pieces, with 3 types of item levels

    ___ of Conquest iLVL 232, purchased with Emblems of Triumph OR drop in VOA (10)
    ___ of Triumph iLVL 245, purchased with Emblems of Triumph and Trophy of the Crusade OR drop VOA (25)
    ___ of Heroic Triumph iLVL 258, purchased with Regalia from 25 Heroic

    NEITHER Trophies or Regalia are bound to an item slot. They are used to purchase Chest, Hands, Head, Legs, and Shoulders.

    Regalia are bound to classes
        - Grand Conqueror (Paladin, Priest, Warlock)
        - Grand Protector (Warrior, Hunter, Shaman)
        - Grand Vanquisher (Rogue, Death Knight, Mage, Druid)


    ** Where do I get Trophy of the Crusade?

        10 Normal : 0 Trophies
        10 Heroic : 0-4 Trophies Total (loot chest)
            - 1-24 attempts remaining, 2 trophies
            - >45 attempts remaining, 2 trophies
        25 Normal : 2 Trophies Per Boss (5 Bosses, 10 Total)
        25 Heroic : 2 Trophies Per Boss (5 Bosses, 10 Total)


    ** Where do I get Regalia?

        25 Heroic, based upon remaining attempts (wipes reduce attempts count).
        These are cumulative buckets. E.G. 24-44 attempts would get 2 Regalia and 1 Weapon


        1-24 : 2 Regalia
        24-44 : 1 Weapon
        45-49 : 2 Regalia
        50 : Cape

        Total : 0 - 4 Regalia

    --]]
    -- Trophies and Regalia are used for Chest, Hands, Head, Legs, and Shoulders
    -- 10 player
    [47242]  = { "ChestSlot", "HandsSlot", "HeadSlot", "LegsSlot", "ShoulderSlot" },  -- Trophy of the Crusade, same item for 25 player
    -- 25 player
    [47557]  = { "ChestSlot", "HandsSlot", "HeadSlot", "LegsSlot", "ShoulderSlot" },  -- Regalia of the Grand Conqueror (Paladin, Priest, Warlock)
    [47558]  = { "ChestSlot", "HandsSlot", "HeadSlot", "LegsSlot", "ShoulderSlot" },  -- Regalia of the Grand Protector (Warrior, Hunter, Shaman)
    [47559]  = { "ChestSlot", "HandsSlot", "HeadSlot", "LegsSlot", "ShoulderSlot" },  -- Regalia of the Grand Vanquisher (Rogue, Death Knight, Mage, Druid)

    -- WOTLK Classic P4 (T10)
    --[[

    How does tier work in ICC?

    Item Level 251 (Tier 10) : Emblem of Frost
    Item Level 264 (Tier 10.25) : Item Level 251 (Tier 10) item and Mark of Sanctification (Normal)
    Item Level 277 (Tier 10.5) :  Item Level 264 (Tier 10.25) item and Mark of Sanctification (Heroic)

    --]]
    -- 10/25 player
    [52025] = { "ChestSlot", "HandsSlot", "HeadSlot", "LegsSlot", "ShoulderSlot" },   -- Vanquisher's Mark of Sanctification (Rogue, Death Knight, Mage, Druid)
    [52026] = { "ChestSlot", "HandsSlot", "HeadSlot", "LegsSlot", "ShoulderSlot" },   -- Protector's Mark of Sanctification (Warrior, Hunter, Shaman)
    [52027] = { "ChestSlot", "HandsSlot", "HeadSlot", "LegsSlot", "ShoulderSlot" },   -- Conqueror's Mark of Sanctification (Paladin, Priest, Warlock)
    [52028] = { "ChestSlot", "HandsSlot", "HeadSlot", "LegsSlot", "ShoulderSlot" },   -- Vanquisher's Mark of Sanctification - Heroic (Rogue, Death Knight, Mage, Druid)
    [52029] = { "ChestSlot", "HandsSlot", "HeadSlot", "LegsSlot", "ShoulderSlot" },   -- Protector's Mark of Sanctification - Heroic (Warrior, Hunter, Shaman)
    [52030] = { "ChestSlot", "HandsSlot", "HeadSlot", "LegsSlot", "ShoulderSlot" },   -- Conqueror's Mark of Sanctification - Heroic (Paladin, Priest, Warlock)

    -- CATA Classic P1 (T11)
    [63683] = { "HeadSlot" },       -- Helm of the Forlorn Conqueror
    [63684] = { "HeadSlot" },       -- Helm of the Forlorn Protector
    [63682] = { "HeadSlot" },       -- Helm of the Forlorn Vanquisher
    [65001] = { "HeadSlot" },       -- Crown of the Forlorn Conqueror
    [65000] = { "HeadSlot" },       -- Crown of the Forlorn Protector
    [65002] = { "HeadSlot" },       -- Crown of the Forlorn Vanquisher
    [67429] = { "HandsSlot" },      -- Gauntlets of the Forlorn Conqueror
    [67430] = { "HandsSlot" },      -- Gauntlets of the Forlorn Protector
    [67431] = { "HandsSlot" },      -- Gauntlets of the Forlorn Vanquisher
    [67423] = { "ChestSlot" },      -- Chest of the Forlorn Conqueror
    [67424] = { "ChestSlot" },      -- Chest of the Forlorn Protector
    [67425] = { "ChestSlot" },      -- Chest of the Forlorn Vanquisher
    [67428] = { "LegsSlot" },       -- Leggings of the Forlorn Conqueror
    [67427] = { "LegsSlot" },       -- Leggings of the Forlorn Protector
    [67426] = { "LegsSlot" },       -- Leggings of the Forlorn Vanquisher
    [65088] = { "ShoulderSlot" },   -- Shoulders of the Forlorn Conqueror
    [65087] = { "ShoulderSlot" },   -- Shoulders of the Forlorn Protector
    [65089] = { "ShoulderSlot" },   -- Shoulders of the Forlorn Vanquisher
    [64315] = { "ShoulderSlot" },   -- Mantle of the Forlorn Conqueror
    [64316] = { "ShoulderSlot" },   -- Mantle of the Forlorn Protector
    [64314] = { "ShoulderSlot" },   -- Mantle of the Forlorn Vanquisher      
    [66998] = { "ChestSlot", "HandsSlot", "HeadSlot", "LegsSlot", "ShoulderSlot" },  -- Essence of the Forlorn (can be used to purchase any Heroic armor token)

    -- MOP Classic P1 (T14)
    -- This does not include Celestial gear, as it is obtained via dungeons and August Stone Fragments
    [89234] = { "HeadSlot" },       -- Helm of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [NORMAL]
    [89258] = { "HeadSlot" },       -- Helm of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [HEROIC]
    [89235] = { "HeadSlot" },       -- Helm of the Shadowy Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [89259] = { "HeadSlot" },       -- Helm of the Shadowy Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [89236] = { "HeadSlot" },       -- Helm of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [NORMAL]
    [89260] = { "HeadSlot" },       -- Helm of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [HEROIC]
    [89242] = { "HandsSlot" },      -- Gauntlets of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [NORMAL]
    [89255] = { "HandsSlot" },      -- Gauntlets of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [HEROIC]
    [89240] = { "HandsSlot" },      -- Gauntlets of the Shadowy Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [89253] = { "HandsSlot" },      -- Gauntlets of the Shadowy Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [89241] = { "HandsSlot" },      -- Gauntlets of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [NORMAL]
    [89257] = { "HandsSlot" },      -- Gauntlets of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [HEROIC]
    [89239] = { "ChestSlot" },      -- Chest of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [NORMAL]
    [89249] = { "ChestSlot" },      -- Chest of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [HEROIC]
    [89237] = { "ChestSlot" },      -- Chest of the Shadowy Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [89250] = { "ChestSlot" },      -- Chest of the Shadowy Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [89238] = { "ChestSlot" },      -- Chest of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [NORMAL]
    [89251] = { "ChestSlot" },      -- Chest of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [HEROIC]
    [89245] = { "LegsSlot" },       -- Leggings of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [NORMAL]
    [89252] = { "LegsSlot" },       -- Leggings of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [HEROIC]
    [89243] = { "LegsSlot" },       -- Leggings of the Shadowy Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [89253] = { "LegsSlot" },       -- Leggings of the Shadowy Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [89244] = { "LegsSlot" },       -- Leggings of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [NORMAL]
    [89254] = { "LegsSlot" },       -- Leggings of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [HEROIC]
    [89248] = { "ShoulderSlot" },   -- Shoulders of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [NORMAL]
    [89261] = { "ShoulderSlot" },   -- Shoulders of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [HEROIC]
    [89246] = { "ShoulderSlot" },   -- Shoulders of the Shadowy Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [89262] = { "ShoulderSlot" },   -- Shoulders of the Shadowy Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [89247] = { "ShoulderSlot" },   -- Shoulders of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [NORMAL]
    [89263] = { "ShoulderSlot" },   -- Shoulders of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [HEROIC]
}

-- mapping from token to items (id) which are rewarded from turning in
-- currently only has TBC Classic P1 and onwards
lib.TokenItems = {
    -- TBC Classic P1 (T4)
    [29761] = { 29011, 29021, 29049, 29058, 29086, 29093, 29098 },  -- Helm of the Fallen Defender
    [29759] = { 29081, 29076, 28963 },                              -- Helm of the Fallen Hero
    [29760] = { 29061, 29068, 29073, 29044, 29028, 29035, 29040 },  -- Helm of the Fallen Champion
    [29764] = { 29016, 29023, 29054, 29060, 29100, 29095, 29089 },  -- Pauldrons of the Fallen Defender
    [29762] = { 29084, 29079, 28967 },                              -- Pauldrons of the Fallen Hero
    [29763] = { 29064, 29070, 29075, 29047, 29037, 29031, 29043 },  -- Pauldrons of the Fallen Champion
    [29753] = { 29012, 29019, 29050, 29056, 29087, 29091, 29096 },  -- Chestguard of the Fallen Defender
    [29755] = { 29082, 29077, 28964 },                              -- Chestguard of the Fallen Hero
    [29754] = { 29071, 29066, 29062, 29045, 29038, 29033, 29029 },  -- Chestguard of the Fallen Champion
    [29758] = { 29017, 29020, 29055, 29057, 29090, 29092, 29097 },  -- Gloves of the Fallen Defender
    [29756] = { 29085, 29080, 28968 },                              -- Gloves of the Fallen Hero
    [29757] = { 29065, 29067, 29072, 29048, 29032, 29034, 29039 },  -- Gloves of the Fallen Champion
    [29767] = { 29022, 29015, 29059, 29053, 29094, 29099, 29088 },  -- Leggings of the Fallen Defender
    [29765] = { 29083, 29078, 28966 },                              -- Leggings of the Fallen Hero
    [29766] = { 29074, 29063, 29069, 29046, 29030, 29036, 29042 },  -- Leggings of the Fallen Champion
    [32385] = { 28791, 28790, 28793, 28792 },                       -- Magtheridon's Head
    [32386] = { 28791, 28790, 28793, 28792 },                       -- Magtheridon's Head
    -- TBC Classic P2 (T5)
    [30243] = { 30120, 30115, 30161, 30152, 30228, 30219, 30233 },  -- Helm of the Vanquished Defender
    [30244] = { 30141, 30206, 30212 },                              -- Helm of the Vanquished Hero
    [30242] = { 30125, 30136, 30131, 30146, 30166, 30171, 30190 },  -- Helm of the Vanquished Champion
    [30249] = { 30117, 30122, 30154, 30163, 30221, 30230, 30235 },  -- Pauldrons of the Vanquished Defender
    [30250] = { 30143, 32047, 30215 },                              -- Pauldrons of the Vanquished Hero
    [30248] = { 30127, 30133, 30138, 30149, 30168, 30173, 30194 },  -- Pauldrons of the Vanquished Champion
    [30237] = { 30113, 30118, 30150, 30159, 30216, 30222, 30231 },  -- Chestguard of the Vanquished Defender
    [30238] = { 30139, 30196, 30214 },                              -- Chestguard of the Vanquished Hero
    [30236] = { 30123, 30129, 30134, 30144, 30164, 30169, 30185 },  -- Chestguard of the Vanquished Champion
    [30240] = { 30114, 30119, 30160, 30151, 30223, 30217, 30232 },  -- Gloves of the Vanquished Defender
    [30241] = { 30140, 30205, 30211 },                              -- Gloves of the Vanquished Hero
    [30239] = { 30130, 30135, 30124, 30145, 30189, 30165, 30170 },  -- Gloves of the Vanquished Champion
    [30246] = { 30121, 30116, 30153, 30162, 30229, 30220, 30234 },  -- Leggings of the Vanquished Defender
    [30247] = { 30142, 30207, 30213 },                              -- Leggings of the Vanquished Hero
    [30245] = { 30132, 30137, 30126, 30148, 30172, 30167, 30192 },  -- Leggings of the Vanquished Champion
    [32405] = { 30018, 30017, 30007, 30015 },                       -- Verdant Sphere
    -- TBC Classic P3 (T6)
    [31097] = { 31063, 31064, 31051, 30987, 30988, 30989 },         -- Helm of the Forgotten Conqueror
    [31095] = { 31003, 30972, 30974, 31015, 31014, 31012 },         -- Helm of the Forgotten Protector
    [31096] = { 31056, 31037, 31040, 31039, 31027 },                -- Helm of the Forgotten Vanquisher
    [31101] = { 30996, 30997, 30998, 31069, 31054, 31070 },         -- Pauldrons of the Forgotten Conqueror
    [31103] = { 31006, 30979, 30980, 31023, 31024, 31002 },         -- Pauldrons of the Forgotten Protector
    [31102] = { 31059, 31030, 31048, 31049, 31047 },                -- Pauldrons of the Forgotten Vanquisher
    [31089] = { 30990, 30991, 30992, 31052, 31065, 31066 },         -- Chestguard of the Forgotten Conqueror
    [31091] = { 31004, 30975, 30976, 31017, 31016, 31018 },         -- Chestguard of the Forgotten Protector
    [31090] = { 31057, 31028, 31042, 31041, 31043 },                -- Chestguard of the Forgotten Vanquisher
    [31092] = { 31060, 31050, 31061, 30982, 30983, 30985 },         -- Gloves of the Forgotten Conqueror
    [31094] = { 31001, 30969, 30970, 31008, 31007, 31011 },         -- Gloves of the Forgotten Protector
    [31093] = { 31055, 31026, 31034, 31032, 31035 },                -- Gloves of the Forgotten Vanquisher
    [31098] = { 31068, 31067, 31053, 30993, 30994, 30995 },         -- Leggings of the Forgotten Conqueror
    [31100] = { 31005, 30977, 30978, 31019, 31020, 31021 },         -- Leggings of the Forgotten Protector
    [31099] = { 31058, 31029, 31044, 31045, 31046 },                -- Leggings of the Forgotten Vanquisher
    -- TBC Classic P4 (T6)
    [34848] = { 34434, 34436, 34435, 34431, 34432, 34433 },         -- Bracers of the Forgotten Conqueror
    [34851] = { 34443, 34441, 34442, 34437, 34438, 34439 },         -- Bracers of the Forgotten Protector
    [34852] = { 34447, 34448, 34446, 34445, 34444 },                -- Bracers of the Forgotten Vanquisher
    [34856] = { 34562, 34564, 34561, 34560, 34559, 34563 },         -- Boots of the Forgotten Conqueror
    [34857] = { 34570, 34568, 34569, 34565, 34567, 34566 },         -- Boots of the Forgotten Protector
    [34858] = { 34574, 34575, 34571, 34572, 34573 },                -- Boots of the Forgotten Vanquisher
    [34853] = { 34527, 34541, 34528, 34487, 34485, 34488 },         -- Belt of the Forgotten Conqueror
    [34854] = { 34549, 34546, 34547, 34543, 34542, 34545 },         -- Belt of the Forgotten Protector
    [34855] = { 34557, 34558, 34554, 34555, 34556 },                -- Belt of the Forgotten Vanquisher
    -- WOTLK Classic P1 (T7)
    -- 10 player
    [40616] = { 39496, 39514, 39521, 39628, 39635, 39640 },         -- Helm of the Lost Conqueror
    [40617] = { 39605, 39610, 39578, 39583, 39594, 39602 },         -- Helm of the Lost Protector
    [40618] = { 39531, 39545, 39553, 39561, 39491, 39619, 39625 },  -- Helm of the Lost Vanquisher
    [40613] = { 39500, 39519, 39530, 39632, 39634, 39639 },         -- Gloves of the Lost Conqueror
    [40614] = { 39609, 39622, 39582, 39591, 39593, 39601 },         -- Gloves of the Lost Protector
    [40615] = { 39543, 39544, 39557, 39560, 39495, 39618, 39624 },  -- Gloves of the Lost Vanquisher
    [40610] = { 39497, 39515, 39523, 39629, 39633, 39638 },         -- Chestguard of the Lost Conqueror
    [40611] = { 39606, 39611, 39579, 39588, 39592, 39597 },         -- Chestguard of the Lost Protector
    [40612] = { 39538, 39547, 39554, 39558, 39492, 39617, 39623 },  -- Chestguard of the Lost Vanquisher
    [40619] = { 39498, 39517, 39528, 39630, 39636, 39641 },         -- Leggings of the Lost Conqueror
    [40620] = { 39607, 39612, 39580, 39589, 39595, 39603 },         -- Leggings of the Lost Protector
    [40621] = { 39539, 39546, 39555, 39564, 39493, 39620, 39626 },  -- Leggings of the Lost Vanquisher
    [40622] = { 39499, 39518, 39529, 39631, 39637, 39642 },         -- Spaulders of the Lost Conqueror
    [40623] = { 39608, 39613, 39581, 39590, 39596, 39604 },         -- Spaulders of the Lost Protector
    [40624] = { 39542, 39548, 39556, 39565, 39494, 39621, 39627 },  -- Spaulders of the Lost Vanquisher
    [44569] = { 44582 },                                            -- Key to the Focusing Iris
    -- 25 player
    [40631] = { 40421, 40447, 40456, 40571, 40576, 40581 },         -- Crown of the Lost Conqueror
    [40632] = { 40528, 40546, 40505, 40510, 40516, 40521 },         -- Crown of the Lost Protector
    [40633] = { 40461, 40467, 40473, 40499, 40416, 40554, 40565},   -- Crown of the Lost Vanquisher
    [40628] = { 40420, 40445, 40454, 40570, 40575, 40580 },         -- Gauntlets of the Lost Conqueror
    [40629] = { 40527, 40545, 40504, 40509, 40515, 40520 },         -- Gauntlets of the Lost Protector
    [40630] = { 40460, 40466, 40472, 40496, 40415, 40552, 40563 },  -- Gauntlets of the Lost Vanquisher
    [40625] = { 40423, 40449, 40458, 40569, 40574, 40579 },         -- Breastplate of the Lost Conqueror
    [40626] = { 40525, 40544, 40503, 40508, 40514, 40523 },         -- Breastplate of the Lost Protector
    [40627] = { 40463, 40469, 40471, 40495, 40418, 40550, 40559 },  -- Breastplate of the Lost Vanquisher
    [40634] = { 40422, 40448, 40457, 40572, 40577, 40583 },         -- Legplates of the Lost Conqueror
    [40635] = { 40529, 40547, 40506, 40512, 40517, 40522 },         -- Legplates of the Lost Protector
    [40636] = { 40462, 40468, 40493, 40500, 40417, 40556, 40567 },  -- Legplates of the Lost Vanquisher
    [40637] = { 40424, 40450, 40459, 40573, 40578, 40584 },         -- Mantle of the Lost Conqueror
    [40638] = { 40530, 40548, 40507, 40513, 40518, 40524 },         -- Mantle of the Lost Protector
    [40639] = { 40465, 40470, 40494, 40502, 40419, 40557, 40568 },  -- Mantle of the Lost Vanquisher
    [44577] = { 44581 },                                            -- Heroic Key to the Focusing Iris
    -- WOTLK Classic P2 (T8)
    -- x=45649; grep -Po "\[(\d*)\] =.*${x}" source-wrath.lua | sed "s/\[\([0-9]*\)\].*/\1/g" |  tr -s '\n' ' ' |  paste | sed 's/ /, /g' | sed 's/..$//'
    -- 10 player
    [45647] = { 45372, 45377, 45382, 45386, 45391, 45417 },         -- Helm of the Wayward Conqueror
    [45648] = { 45361, 45402, 45408, 45412, 45425, 45431 },         -- Helm of the Wayward Protector
    [45649] = { 45336, 45342, 45346, 45356, 45365, 45398, 46313 },  -- Helm of the Wayward Vanquisher
    [45644] = { 45370, 45376, 45383, 45387, 45392, 45419 },         -- Gloves of the Wayward Conqueror
    [45645] = { 45360, 45401, 45406, 45414, 45426, 45430 },         -- Gloves of the Wayward Protector
    [45646] = { 45337, 45341, 45345, 45351, 45355, 45397, 46131 },  -- Gloves of the Wayward Vanquisher
    [45635] = { 45374, 45375, 45381, 45389, 45395, 45421 },         -- Chestguard of the Wayward Conqueror
    [45636] = { 45364, 45405, 45411, 45413, 45424, 45429 },         -- Chestguard of the Wayward Protector
    [45637] = { 45335, 45340, 45348, 45354, 45358, 45368, 45396 },  -- Chestguard of the Wayward Vanquisher
    [45650] = { 45371, 45379, 45384, 45388, 45394, 45420 },         -- Leggings of the Wayward Conqueror
    [45651] = { 45362, 45403, 45409, 45416, 45427, 45432 },         -- Leggings of the Wayward Protector
    [45652] = { 45338, 45343, 45347, 45353, 45357, 45367, 45399 },  -- Leggings of the Wayward Vanquisher
    [45659] = { 45373, 45380, 45385, 45390, 45393, 45422 },         -- Spaulders of the Wayward Conqueror
    [45660] = { 45363, 45404, 45410, 45415, 45428, 45433 },         -- Spaulders of the Wayward Protector
    [45661] = { 45339, 45344, 45349, 45352, 45359, 45369, 45400 },  -- Spaulders of the Wayward Vanquisher
    -- Archivum Data Disc -> Archivum Data Disc (Quest) -> The Celestial Planetarium (Quest) -> Sigils (4) -> Algalon -> All Is Well That Ends Well
    [46052] = { 46320, 46321, 46322, 46323},                        -- Reply-Code Alpha
    -- 25 player
    [45638] = { 46140, 46156, 46172, 46175, 46180, 46197 },         -- Crown of the Wayward Conqueror
    [45639] = { 46143, 46151, 46166, 46201, 46209, 46212 },         -- Crown of the Wayward Protector
    [45640] = { 46115, 46120, 46125, 46129, 46161, 46184, 46191 },  -- Crown of the Wayward Vanquisher
    [45641] = { 46135, 46155, 46163, 46174, 46179, 46188 },         -- Gauntlets of the Wayward Conqueror
    [45642] = { 46142, 46148, 46164, 46199, 46200, 46207 },         -- Gauntlets of the Wayward Protector
    [45643] = { 46113, 46119, 46124, 46132, 46158, 46183, 46189 },  -- Gauntlets of the Wayward Vanquisher
    [45632] = { 46137, 46154, 46168, 46173, 46178, 46193 },         -- Breastplate of the Wayward Conqueror
    [45633] = { 46141, 46146, 46162, 46198, 46205, 46206 },         -- Breastplate of the Wayward Protector
    [45634] = { 46111, 46118, 46123, 46130, 46159, 46186, 46194 },  -- Breastplate of the Wayward Vanquisher
    [45653] = { 46139, 46153, 46170, 46176, 46181, 46195 },         -- Legplates of the Wayward Conqueror
    [45654] = { 46144, 46150, 46169, 46202, 46208, 46210 },         -- Legplates of the Wayward Protector
    [45655] = { 46116, 46121, 46126, 46133, 46160, 46185, 46192 },  -- Legplates of the Wayward Vanquisher
    [45656] = { 46136, 46152, 46165, 46177, 46182, 46190 },         -- Mantle of the Wayward Conqueror
    [45657] = { 46145, 46149, 46167, 46203, 46204, 46211 },         -- Mantle of the Wayward Protector
    [45658] = { 46117, 46122, 46127, 46134, 46157, 46187, 46196 },  -- Mantle of the Wayward Vanquisher
    -- Archivum Data Disc -> Heroic: Archivum Data Disc (Quest) -> Heroic: The Celestial Planetarium (Quest) -> Heroic Sigils (4) ->  Heroic: Algalon -> Heroic: All Is Well That Ends Well
    [46053] = { 45588, 45608, 45614, 45618},                        -- Heroic : Reply-Code Alpha
    -- WOTLK Classic P3 (T9)
    -- 10 player (matches to a minimum of 5 items per class, typically more. not enumerating)
    [47242] = {},
    -- 25 player (matches to a minimum of 5 items per associated classes, typically more. not enumerating)
    [47557] = {},
    [47558] = {},
    [47559] = {},
    -- WOTLK Classic P4 (T10)
    -- 10/25 player (matches to a minimum of 5 items per associated classes, typically more. not enumerating)
    [52025] = { },   -- Vanquisher's Mark of Sanctification (Rogue, Death Knight, Mage, Druid)
    [52026] = { },   -- Protector's Mark of Sanctification (Warrior, Hunter, Shaman)
    [52027] = { },   -- Conqueror's Mark of Sanctification (Paladin, Priest, Warlock)
    [52028] = { },   -- Vanquisher's Mark of Sanctification - Heroic (Rogue, Death Knight, Mage, Druid)
    [52029] = { },   -- Protector's Mark of Sanctification - Heroic (Warrior, Hunter, Shaman)
    [52030] = { },   -- Conqueror's Mark of Sanctification - Heroic (Paladin, Priest, Warlock)
    -- CATA Classic P1 (T11)
    -- https://www.wowhead.com/cata/guide=cataclysm&tier-11  (as of 05.10.2024 appear to have mantle and shoulders swapped in NORMAL vs HEROIC)
    [63683] = { 60258, 60256, 60356, 60359, 60346, 60249 },             -- Helm of the Forlorn Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [63684] = { 60328, 60325, 60308, 60315, 60320, 60303 },             -- Helm of the Forlorn Protector (Warrior, Hunter, Shaman) [NORMAL]
    [63682] = { 60243, 60351, 60341, 60282, 60286, 60277, 60299 },      -- Helm of the Forlorn Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [65001] = { 65230, 65235, 65226, 65221, 65216, 65260 },             -- Crown of the Forlorn Conqueror [HEROIC]
    [65000] = { 65271, 65266, 65246, 65256, 65251, 65206 },             -- Crown of the Forlorn Protector [HEROIC]
    [65002] = { 65210, 65186, 65181, 65200, 65190, 65195, 65241 },      -- Crown of the Forlorn Vanquisher [HEROIC]
    [67429] = { 65234, 65229, 65215, 65220, 65225, 65259 },             -- Gauntlets of the Forlorn Conqueror
    [67430] = { 65265, 65270, 65255, 65250, 65245, 65205 },             -- Gauntlets of the Forlorn Protector
    [67431] = { 65209, 65180, 65185, 65199, 65189, 65194, 65240 },      -- Gauntlets of the Forlorn Vanquisher
    [67423] = { 65232, 65237, 65214, 65219, 65224, 65262 },             -- Chest of the Forlorn Conqueror
    [67424] = { 65249, 65264, 65269, 65254, 65204, 65244 },             -- Chest of the Forlorn Protector
    [67425] = { 65212, 65179, 65184, 65192, 65197, 65202, 65239 },      -- Chest of the Forlorn Vanquisher
    [67428] = { 65236, 65231, 65222, 65227, 65217, 65261 },             -- Leggings of the Forlorn Conqueror
    [67427] = { 65272, 65267, 65257, 65252, 65247, 65207 },             -- Leggings of the Forlorn Protector
    [67426] = { 65211, 65187, 65182, 65201, 65191, 65196, 65242 },      -- Leggings of the Forlorn Vanquisher
    [64315] = { 60262, 60253, 60362, 60348, 60358, 60252 },             -- Mantle of the Forlorn Conqueror  [NORMAL]
    [64316] = { 60327, 60331, 60306, 60311, 60317, 60322 },             -- Mantle of the Forlorn Protector  [NORMAL]
    [64314] = { 60246, 60343, 60353, 60279, 60284, 60289, 60302 },      -- Mantle of the Forlorn Vanquisher  [NORMAL]
    [65088] = { 65233, 65238, 65223, 65218, 65228, 65263 },             -- Shoulders of the Forlorn Conqueror [HEROIC]
    [65087] = { 65268, 65273, 65208, 65248, 65258, 65253 },             -- Shoulders of the Forlorn Protector [HEROIC]
    [65089] = { 65213, 65183, 65188, 65198, 65203, 65193, 65243 },      -- Shoulders of the Forlorn Vanquisher [HEROIC]
    [66998] = { },                                                      -- Essence of the Forlorn (can be used to purchase any Heroic armor token, not enumerating)
    -- CATA P2 OMITTED (Troll 5 Player Dungeons)
    -- CATA Classic P3 (T12)
    [71675] = { 71282, 71093, 71065, 70948, 71272, 71277 },             -- Helm of the Fiery Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [71682] = { 71070, 70944, 71051, 71298, 71303, 71293 },             -- Helm of the Fiery Protector (Warrior, Hunter, Shaman) [NORMAL]
    [71668] = { 71047, 71287, 71060, 70954, 71098, 71103, 71108 },      -- Helm of the Fiery Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [71677] = { 71514, 71519, 71524, 71528, 71533, 71595 },             -- Crown of the Fiery Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [71684] = { 71599, 71606, 71503, 71544, 71549, 71554 },             -- Crown of the Fiery Protector (Warrior, Hunter, Shaman) [HEROIC]
    [71670] = { 71539, 71508, 71478, 71483, 71488, 71492, 71497 },      -- Crown of the Fiery Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [71676] = { 71513, 71518, 71523, 71527, 71532, 71594 },             -- Gauntlets of the Fiery Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [71683] = { 71601, 71605, 71502, 71543, 71548, 71553 },             -- Gauntlets of the Fiery Protector (Warrior, Hunter, Shaman) [HEROIC]
    [71669] = { 71538, 71507, 71477, 71482, 71487, 71491, 71496 },      -- Gauntlets of the Fiery Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [71679] = { 71512, 71517, 71522, 71530, 71535, 71597 },             -- Chest of the Fiery Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [71686] = { 71600, 71604, 71501, 71542, 71547, 71552 },             -- Chest of the Fiery Protector (Warrior, Hunter, Shaman) [HEROIC]
    [71672] = { 71537, 71510, 71476, 71481, 71486, 71494, 71499 },      -- Chest of the Fiery Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [71678] = { 71515, 71520, 71525, 71529, 71534, 71596 },             -- Leggings of the Fiery Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [71685] = { 71602, 71607, 71504, 71545, 71550, 71555 },             -- Leggings of the Fiery Protector (Warrior, Hunter, Shaman) [HEROIC]
    [71671] = { 71540, 71509, 71479, 71484, 71489, 71493, 71498 },      -- Leggings of the Fiery Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [71681] = { 71067, 71095, 70946, 71275, 71280, 71285 },             -- Mantle of the Fiery Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [71688] = { 71072, 70941, 71053, 71300, 71305, 71295 },             -- Mantle of the Fiery Protector (Warrior, Hunter, Shaman) [NORMAL]
    [71674] = { 71049, 71290, 71062, 70951, 71101, 71106, 71111 },      -- Mantle of the Fiery Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [71680] = { 71516, 71521, 71526, 71531, 71536, 71598 },             -- Shoulders of the Fiery Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [71687] = { 71603, 71608, 71505, 71546, 71551, 71556 },             -- Shoulders of the Fiery Protector (Warrior, Hunter, Shaman) [HEROIC]
    [71673] = { 71541, 71511, 71480, 71485, 71490, 71495, 71500 },      -- Shoulders of the Fiery Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [71617] = { }, -- Crystallized Firestone (can be used to upgrade gear, not enumerating)
    -- CATA Classic P4 (T13)
    -- Does NOT include LFR items, only Normal and Heroic
    [78182] = { 76342, 76347, 76876, 76767, 77005, 76358 },             -- Crown of the Corrupted Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [78177] = { 76758, 76983, 76990, 77030, 77037, 77042 },             -- Crown of the Corrupted Protector (Warrior, Hunter, Shaman) [NORMAL]
    [78172] = { 76213, 76750, 76976, 77010, 77015, 77019, 77025 },      -- Crown of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [78850] = { 78692, 78693, 78695, 78700, 78702, 78703 },             -- Crown of the Corrupted Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [78851] = { 78685, 78686, 78688, 78689, 78691, 78698 },             -- Crown of the Corrupted Protector (Warrior, Hunter, Shaman) [HEROIC]
    [78852] = { 78687, 78690, 78694, 78696, 78697, 78699, 78701 },      -- Crown of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [78183] = { 76343, 76348, 76357, 76766, 76875, 77004 },             -- Gauntlets of the Corrupted Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [78178] = { 76757, 76985, 76989, 77029, 77038, 77041 },             -- Gauntlets of the Corrupted Protector (Warrior, Hunter, Shaman) [NORMAL]
    [78173] = { 76212, 76749, 76975, 77009, 77014, 77018, 77024 },      -- Gauntlets of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid)) [NORMAL]
    [78853] = { 78673, 78675, 78677, 78681, 78682, 78683 },             -- Gauntlets of the Corrupted Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [78854] = { 78666, 78667, 78668, 78669, 78672, 78674 },             -- Gauntlets of the Corrupted Protector (Warrior, Hunter, Shaman) [HEROIC]
    [78855] = { 78670, 78671, 78676, 78678, 78679, 78680, 78684 },      -- Gauntlets of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [78184] = { 76340, 76345, 76360, 76765, 76874, 77003 },             -- Chest of the Corrupted Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [78179] = { 76756, 76984, 76988, 77028, 77039, 77040 },             -- Chest of the Corrupted Protector (Warrior, Hunter, Shaman) [NORMAL]
    [78174] = { 76215, 76752, 76974, 77008, 77013, 77021, 77023 },      -- Chest of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [78847] = { 78726, 78727, 78728, 78730, 78731, 78732 },             -- Chest of the Corrupted Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [78848] = { 78657, 78658, 78661, 78723, 78724, 78725 },             -- Chest of the Corrupted Protector (Warrior, Hunter, Shaman) [HEROIC]
    [78849] = { 78659, 78660, 78662, 78663, 78664, 78665, 78729 },      -- Chest of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [78181] = { 76341, 76346, 76359, 76768, 76877, 77006 },             -- Leggings of the Corrupted Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [78176] = { 76759, 76986, 76991, 77031, 77036, 77043 },             -- Leggings of the Corrupted Protector (Warrior, Hunter, Shaman) [NORMAL]
    [78171] = { 76214, 76751, 76977, 77011, 77016, 77020, 77026 },      -- Leggings of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [78856] = { 78712, 78715, 78717, 78719, 78721, 78722 },             -- Leggings of the Corrupted Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [78857] = { 78704, 78705, 78706, 78709, 78711, 78718 },             -- Leggings of the Corrupted Protector (Warrior, Hunter, Shaman) [HEROIC]
    [78858] = { 78707, 78708, 78710, 78713, 78714, 78716, 78720 },      -- Leggings of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    [78180] = { 76339, 76344, 76361, 76769, 76878, 77007 },             -- Shoulders of the Corrupted Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [78175] = { 76760, 76987, 76992, 77032, 77035, 77044 },             -- Shoulders of the Corrupted Protector (Warrior, Hunter, Shaman) [NORMAL]
    [78170] = { 76216, 76753, 76978, 77012, 77017, 77022, 77027 },      -- Shoulders of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [NORMAL]
    [78859] = { 78742, 78745, 78746, 78747, 78749, 78750 },             -- Shoulders of the Corrupted Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [78860] = { 78733, 78734, 78735, 78737, 78739, 78741 },             -- Shoulders of the Corrupted Protector (Warrior, Hunter, Shaman) [HEROIC]
    [78861] = { 78736, 78738, 78740, 78743, 78744, 78748, 78751 },      -- Shoulders of the Corrupted Vanquisher (Rogue, Mage, Death Knight, Druid) [HEROIC]
    -- MOP Classic P1 (T14)
    -- This does not include Celestial gear, as it is obtained via dungeons and August Stone Fragments
    -- Celestial is 483, Normal is 496, Heroic is 509
    [89234] = { 85301, 85316, 85336, 85377, 85307, 85311, 85381, 85357 },           -- Helm of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [NORMAL]
    [89258] = { 87126, 86920, 86915, 87008, 86934, 86925, 86940, 86929 },           -- Helm of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [HEROIC]
    [89235] = { 85346, 85321, 85341, 85362, 85365, 85370 },                         -- Helm of the Shadowy Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [89259] = { 87106, 87111, 87101, 87115, 87120, 87188 },                         -- Helm of the Shadowy Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [89236] = { 85333, 85326, 85296, 85291, 85286, 85351, 85386, 85390, 85396 },    -- Helm of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [NORMAL]
    [89260] = { 87192, 87199, 87004, 87141, 87136, 87131, 87096, 87090, 87086 },    -- Helm of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [HEROIC]
    [89242] = { 85302, 85317, 85337, 85378, 85308, 85312, 85380, 85358 },           -- Gauntlets of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [NORMAL]
    [89255] = { 87125, 86919, 86914, 87007, 86933, 86924, 86939, 86928 },           -- Gauntlets of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [HEROIC]
    [89240] = { 85347, 85322, 85342, 85363, 85364, 85369 },                         -- Gauntlets of the Shadowy Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [89253] = { 87105, 87110, 87100, 87114, 87119, 87187 },                         -- Gauntlets of the Shadowy Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [89241] = { 85331, 85327, 85297, 85290, 85287, 85352, 85387, 85389, 85395 },    -- Gauntlets of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [NORMAL]
    [89257] = { 87194, 87198, 87003, 87140, 87135, 87130, 87095, 87089, 87085 },    -- Gauntlets of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [HEROIC]
    [89239] = { 85303, 85318, 85338, 85375, 85305, 85313, 85379, 85355 },           -- Chest of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [NORMAL]
    [89249] = { 87124, 86918, 86913, 87010, 86936, 86923, 86938, 86931 },           -- Chest of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [HEROIC]
    [89237] = { 85348, 85323, 85343, 85360, 85367, 85372 },                         -- Chest of the Shadowy Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [89250] = { 87104, 87109, 87099, 87117, 87122, 87190 },                         -- Chest of the Shadowy Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [89238] = { 85332, 85328, 85298, 85292, 85288, 85353, 85388, 85392, 85394 },    -- Chest of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [NORMAL]
    [89251] = { 87193, 87197, 87002, 87142, 87134, 87129, 87094, 87092, 87084 },    -- Chest of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [HEROIC]
    [89245] = { 85300, 85315, 85335, 85376, 85306, 85310, 85382, 85356 },           -- Leggings of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [NORMAL]
    [89252] = { 87127, 86921, 86916, 87009, 86935, 86926, 86941, 86930 },           -- Leggings of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [HEROIC]
    [89243] = { 85345, 85320, 85340, 85361, 85366, 85371 },                         -- Leggings of the Shadowy Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [89253] = { 87107, 87112, 87102, 87116, 87121, 87189 },                         -- Leggings of the Shadowy Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [89244] = { 85330, 85325, 85295, 85292, 85285, 85350, 85385, 85391, 85397 },    -- Leggings of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [NORMAL]
    [89254] = { 87195, 87200, 87005, 87142, 87137, 87132, 87097, 87091, 87087 },    -- Leggings of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [HEROIC]
    [89248] = { 85299, 85314, 85334, 85374, 85304, 85309, 85383, 85354 },           -- Shoulders of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [NORMAL]
    [89261] = { 87128, 86922, 86917, 87011, 86937, 86927, 86942, 86932 },           -- Shoulders of the Shadowy Vanquisher (Rogue, DK, Mage, Druid) [HEROIC]
    [89246] = { 85344, 85319, 85339, 85359, 85368, 85373 },                         -- Shoulders of the Shadowy Conqueror (Paladin, Priest, Warlock) [NORMAL]
    [89262] = { 87108, 87113, 87103, 87118, 87123, 87191 },                         -- Shoulders of the Shadowy Conqueror (Paladin, Priest, Warlock) [HEROIC]
    [89247] = { 85329, 85324, 85294, 85293, 85284, 85349, 85384, 85393, 85398 },    -- Shoulders of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [NORMAL]
    [89263] = { 87196, 87201, 87006, 87143, 87138, 87133, 87098, 87093, 87088 },    -- Shoulders of the Shadowy Protector (Warrior, Hunter, Shaman, Monk) [HEROIC]
}
