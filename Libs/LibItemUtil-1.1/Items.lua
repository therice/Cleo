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
}
