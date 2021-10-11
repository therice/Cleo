local lib = LibStub("LibItemUtil-1.1", true)

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
    [22371] = { "HandsSlot" },                   -- Desecrated Gloves (Priest, Mage, Warlock)
    [22364] = { "HandsSlot" },                   -- Desecrated Handguards (Paladin, Hunter, Shaman, Paladin)
    [22357] = { "HandsSlot" },                   -- Desecrated Gauntlets (Warrior, Rogue)
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
    [29758] = { "HandsSlot" },                   -- Gloves of the Fallen Defender
    [29756] = { "HandsSlot" },                   -- Gloves of the Fallen Hero
    [29757] = { "HandsSlot" },                   -- Gloves of the Fallen Champion
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
    [32405] = { "NeckSlot"},                    -- Verdant Sphere
    -- TBC Classic P3 (T6) TODO
}

-- mapping from token to items (id) which are rewarded from turning in
-- currently only has TBC Classic P1 and on
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
    -- TBC Classic P2
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
    -- TBC Classic P3 (T6) TODO
}
