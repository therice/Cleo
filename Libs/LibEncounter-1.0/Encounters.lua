local lib = LibStub("LibEncounter-1.0", true)
-- todo : possibly collapse all into encounters
--
-- Currently supports the following raids
--
-- (40 person)
--  Molten Core
--  Onyxia's Lair
--  Blackwing Lair
--  Temple of Ahn'Qiraj
--  Naxxramas
--
-- (20 person)
--  Ancient Zul'Gurub
--  Ruins of Ahn'Qiraj
--
-- (10 person)
--  Karazhan
--
-- (25 person)
--  Gruul's Lair
--  Magtheridon's Lair
--  Serpentshrine Cavern
--  Tempest Keep'

-- Mapping from map id to details (name will be used as index for localization)
lib.Maps = {
    [309] = {
        name = 'Ancient Zul\'Gurub',
    },
    -- JournalInstance.ID = 743
    [509] = {
        name = 'Ruins of Ahn\'Qiraj',
    },
    -- JournalInstance.ID = 741
    [409] = {
        name = 'Molten Core',
    },
    -- JournalInstance.ID = 760
    [249] = {
        name = 'Onyxia\'s Lair',
    },
    -- JournalInstance.ID = 742
    [469] = {
        name = 'Blackwing Lair',
    },
    -- JournalInstance.ID = 744
    [531] = {
        name = 'Temple of Ahn\'Qiraj',
    },
    [533] = {
        name = 'Naxxramas',
    },
    -- JournalInstance.ID = 751
    --[[
    [564] = {
        name = 'Black Temple',
    },
    --]]
    -- JournalInstance.ID = 746
    [565] = {
        name = 'Gruul\'s Lair',
    },
    -- JournalInstance.ID = 750
    --[[
    [534] = {
        name = 'Hyjal Summit',
    },
    --]]
    -- JournalInstance.ID = 745
    [532] = {
        name = 'Karazhan',
    },
    -- JournalInstance.ID = 747
    [544] = {
        name = 'Magtheridon\'s Lair',
    },
    -- JournalInstance.ID = 748
    [548] = {
        name = 'Serpentshrine Cavern',
    },
    -- JournalInstance.ID = 752
    --[[
    [580] = {
        name = 'Sunwell Plateau',
    },
    --]]
    -- JournalInstance.ID = 749
    [550] = {
        name = 'Tempest Keep',
    },
}

-- Mapping from creature id to details (name will be used as index for localization)
-- key is Creature.ID
lib.Creatures = {
    [15348] = {
        name = 'Kurinnaxx',
    },
    [15341] = {
        name = 'General Rajaxx',
    },
    [15340] = {
        name = 'Moam',
    },
    [15370] = {
        name = 'Buru the Gorger',
    },
    [15369] = {
        name = 'Ayamiss the Hunter',
    },
    [15339] = {
        name = 'Ossirian the Unscarred',
    },
    [14507] = {
        name = 'High Priest Venoxis',
    },
    [14517] = {
        name = 'High Priestess Jeklik',
    },
    [14510] = {
        name = 'High Priestess Mar\'li',
    },
    [14509] = {
        name = 'High Priest Thekal',
    },
    [14515] = {
        name = 'High Priestess Arlokk',
    },
    [11382] = {
        name = 'Bloodlord Mandokir',
    },
    [15114] = {
        name = 'Gahz\'ranka',
    },
    [15085] = {
        name = 'Wushoolay',
    },
    [15084] = {
        name = 'Renataki',
    },
    [15082] = {
        name = 'Gri\'lek',
    },
    [15083] = {
        name = 'Hazza\'rah',
    },
    [11380] = {
        name = 'Jin\'do the Hexxer',
    },
    [14834] = {
        name = 'Hakkar',
    },
    [12118] = {
        name = 'Lucifron',
    },
    [11982] = {
        name = 'Magmadar',
    },
    [12259] = {
        name = 'Gehennas',
    },
    [12057] = {
        name = 'Garr',
    },
    [12056] = {
        name = 'Baron Geddon',
    },
    [12264] = {
        name = 'Shazzrah',
    },
    [12098] = {
        name = 'Sulfuron Harbinger',
    },
    [11988] = {
        name = 'Golemagg the Incinerator',
    },
    [12018] = {
        name = 'Majordomo Executus',
    },
    [11502] = {
        name = 'Ragnaros',
    },
    [10184] = {
        name = 'Onyxia',
    },
    [12435] = {
        name = 'Razorgore the Untamed',
    },
    [13020] = {
        name = 'Vaelastrasz the Corrupt',
    },
    [12017] = {
        name = 'Broodlord Lashlayer',
    },
    [11983] = {
        name = 'Firemaw',
    },
    [14601] = {
        name = 'Ebonroc',
    },
    [11981] = {
        name = 'Flamegor',
    },
    [14020] = {
        name = 'Chromaggus',
    },
    [11583] = {
        name = 'Nefarian',
    },
    [15263] = {
        name = 'The Prophet Skeram',
    },
    [15544] = {
        name = 'Vem'
    },
    [15511] = {
        name = 'Lord Kri'
    },
    [15543] = {
        name = 'Princess Yauj'
    },
    [15516] = {
        name = 'Battleguard Sartura'
    },
    [15510] = {
        name = 'Fankriss the Unyielding'
    },
    [15299] = {
        name = 'Viscidus'
    },
    [15509] = {
        name = 'Princess Huhuran'
    },
    [15276] = {
        name = 'Emperor Vek\'lor'
    },
    [15275] = {
        name = 'Emperor Vek\'nilash'
    },
    [15517] = {
        name = 'Ouro'
    },
    [15727] = {
        name = 'C\'Thun'
    },
    [15956] = {
        name = 'Anub\'Rekhan'
    },
    [15953] = {
        name = 'Grand Widow Faerlina'
    },
    [15952] = {
        name = 'Maexxna'
    },
    [15954] = {
        name = 'Noth the Plaguebringer'
    },
    [15936] = {
        name = 'Heigan the Unclean'
    },
    [16011] = {
        name = 'Loatheb'
    },
    [16061] = {
        name = 'Instructor Razuvious'
    },
    [16060] = {
        name = 'Gothik the Harvester'
    },
    [16062] = {
        name = 'Highlord Mograine'
    },
    [16063] = {
        name = 'Sir Zeliek'
    },
    [16064] = {
        name = 'Thane Korth\'azz'
    },
    [16065] = {
        name = 'Lady Blaumeux'
    },
    [16028] = {
        name = 'Patchwerk'
    },
    [15931] = {
        name = 'Grobbulus'
    },
    [15932] = {
        name = 'Gluth'
    },
    [15928] = {
        name = 'Thaddius'
    },
    [15989] = {
        name = 'Sapphiron'
    },
    [15990] = {
        name = 'Kel\'Thuzad'
    },
    [18831] = {
        name = 'High King Maulgar'
    },
    [18832] = {
        name = 'Krosh Firehand'
    },
    [18834] = {
        name = 'Olm the Summoner'
    },
    [18835] = {
        name = 'Kiggler the Crazed'
    },
    [18836] = {
        name = 'Blindeye the Seer'
    },
    [19044] = {
        name = 'Gruul the Dragonkiller'
    },
    [17257] = {
        name = 'Magtheridon'
    },
    [16151] = {
        name = 'Midnight'
    },
    [16152] = {
        name = 'Attumen the Huntsman'
    },
    [15687] = {
        name = 'Moroes'
    },
    [16457] = {
        name = 'Maiden of Virtue'
    },
    [17521] = {
        name = 'The Big Bad Wolf'
    },
    [17533] = {
        name = 'Romulo'
    },
    [17534] = {
        name = 'Julianne'
    },
    [18168] = {
        name = 'The Crone'
    },
    [15691] = {
        name = 'The Curator'
    },
    [21752] = {
        name = 'Warchief Blackhand Piece'
    },
    [21684] = {
        name = 'King Llane Piece'
    },
    [15688] = {
        name = 'Terestian Illhoof'
    },
    [16524] = {
        name = 'Shade of Aran'
    },
    [15689] = {
        name = 'Netherspite'
    },
    [17225] = {
        name = 'Nightbane'
    },
    [15690] = {
        name = 'Prince Malchezaar'
    },
    [21216] = {
        name = 'Hydross the Unstable'
    },
    [21217] = {
        name = 'The Lurker Below'
    },
    [21215] = {
        name = 'Leotheras the Blind'
    },
    [21214] = {
        name = 'Fathom-Lord Karathress'
    },
    [21964] = {
        name = 'Fathom-Guard Caribdis'
    },
    [21965] = {
        name = 'Fathom-Guard Tidalvess'
    },
    [21966] = {
        name = 'Fathom-Guard Sharkkis'
    },
    [21213] = {
        name = 'Morogrim Tidewalker'
    },
    [21212] = {
        name = 'Lady Vashj'
    },
    [19514] = {
        name = 'Al\'ar'
    },
    [19516] = {
        name = 'Void Reaver'
    },
    [18805] = {
        name = 'High Astromancer Solarian'
    },
    [19622] = {
        name = 'Kael\'thas Sunstrider'
    },
    --[] = {
    --    name = ''
    --},
}

-- Mapping from encounter id to details
-- key is DungeonEncounter.ID
lib.Encounters = {
    -- Kurinaxx
    [718] = {
        map_id = 509,
        creature_id = {15348},
    },
    -- Rajaxx
    [719] = {
        map_id = 509,
        creature_id = {15341},
    },
    -- Moam
    [720] = {
        map_id = 509,
        creature_id = {15340},
    },
    -- Buru
    [721] = {
        map_id = 509,
        creature_id = {15370},
    },
    -- Ayamiss
    [722] = {
        map_id = 509,
        creature_id = {15369},
    },
    -- Ossirian
    [723] = {
        map_id = 509,
        creature_id = {15339},
    },
    -- Venoxis
    [784] = {
        map_id = 309,
        creature_id = {14507},
    },
    -- Jeklik
    [785] = {
        map_id = 309,
        creature_id = {14517},
    },
    -- Marli
    [786] = {
        map_id = 309,
        creature_id = {14510},
    },
    -- Thekal
    [789] = {
        map_id = 309,
        creature_id = {14509},
    },
    -- Arlokk
    [791] = {
        map_id = 309,
        creature_id = {14515},
    },
    -- Mandokir
    [787] = {
        map_id = 309,
        creature_id = {11382},
    },
    -- Gahzranka
    [790] = {
        map_id = 309,
        creature_id = {15114},
    },
    -- Edge of Madness
    [788] = {
        map_id = 309,
        creature_id = {15082, 15083, 15084, 15085},
    },
    -- Jindo
    [792] = {
        map_id = 309,
        creature_id = {11380},
    },
    -- Hakkar
    [793] = {
        map_id = 309,
        creature_id = {14834},
    },
    -- Lucifron
    [663] = {
        map_id = 409,
        creature_id = {12118},
    },
    -- Magmadar
    [664] = {
        map_id = 409,
        creature_id = {11982},
    },
    -- Gehennas
    [665] = {
        map_id = 409,
        creature_id = {12259},
    },
    -- Garr
    [666] = {
        map_id = 409,
        creature_id = {12057},
    },
    -- Geddon
    [668] = {
        map_id = 409,
        creature_id = {12056},
    },
    -- Shazzrah
    [667] = {
        map_id = 409,
        creature_id = {12264},
    },
    -- Sulfuron
    [669] = {
        map_id = 409,
        creature_id = {12098},
    },
    -- Golemagg
    [670] = {
        map_id = 409,
        creature_id = {11988},
    },
    -- Majordomo
    [671] = {
        map_id = 409,
        creature_id = {12018},
    },
    -- Ragnaros
    [672] = {
        map_id = 409,
        creature_id = {11502},
    },
    -- Onyxia
    [1084] = {
        map_id = 249,
        creature_id = {10184},
    },
    -- Razorgore
    [610] = {
        map_id = 469,
        creature_id = {12435},
    },
    -- Vaelastrasz
    [611] = {
        map_id = 469,
        creature_id = {13020},
    },
    -- Broodlord
    [612] = {
        map_id = 469,
        creature_id = {12017},
    },
    -- Firemaw
    [613] = {
        map_id = 469,
        creature_id = {11983},
    },
    -- Ebonroc
    [614] = {
        map_id = 469,
        creature_id = {14601},
    },
    -- Flamegor
    [615] = {
        map_id = 469,
        creature_id = {11981},
    },
    -- Chromaggus
    [616] = {
        map_id = 469,
        creature_id = {14020},
    },
    -- Nefarian
    [617] = {
        map_id = 469,
        creature_id = {11583},
    },
    -- Skeram
    [709] = {
        map_id = 531,
        creature_id = {15263},
    },
    -- Silithid Royalty (Three Bugs)
    [710] = {
        map_id = 531,
        creature_id = {15544, 15511, 15543},
    },
    -- Battleguard Sartura
    [711] = {
        map_id = 531,
        creature_id = {15516},
    },
    -- Fankriss the Unyielding
    [712] = {
        map_id = 531,
        creature_id = {15510},
    },
    -- Viscidus
    [713] = {
        map_id = 531,
        creature_id = {15299},
    },
    -- Princess Huhuran
    [714] = {
        map_id = 531,
        creature_id = {15509},
    },
    -- Twin Emperors
    [715] = {
        map_id = 531,
        creature_id = {15275, 15276},
    },
    -- Ouro
    [716] = {
        map_id = 531,
        creature_id = {15517},
    },
    -- C'Thun
    [717] = {
        map_id = 531,
        creature_id = {15727},
    },
    -- Anub'Rekhan
    [1107] = {
        map_id = 533,
        creature_id = {15956},
    },
    -- Faerlina
    [1110] = {
        map_id = 533,
        creature_id = {15953},
    },
    -- Maexxna
    [1116] = {
        map_id = 533,
        creature_id = {15952},
    },
    -- Noth
    [1117] = {
        map_id = 533,
        creature_id = {15954},
    },
    -- Heigan
    [1112] = {
        map_id = 533,
        creature_id = {15936},
    },
    -- Loatheb
    [1115] = {
        map_id = 533,
        creature_id = {16011},
    },
    -- Razuvious
    [1113] = {
        map_id = 533,
        creature_id = {16061},
    },
    -- Gothik
    [1109] = {
        map_id = 533,
        creature_id = {16060},
    },
    -- Four Horsemen
    [1121] = {
        map_id = 533,
        creature_id = {16062, 16063, 16064, 16065},
    },
    -- Patchwerk
    [1118] = {
        map_id = 533,
        creature_id = {16028},
    },
    -- Grobbulus
    [1111] = {
        map_id = 533,
        creature_id = {15931},
    },
    -- Gluth
    [1108] = {
        map_id = 533,
        creature_id = {15932},
    },
    -- Thaddius
    [1120] = {
        map_id = 533,
        creature_id = {15928},
    },
    -- Sapphiron
    [1119] = {
        map_id = 533,
        creature_id = {15989},
    },
    -- Kel'Thuzad
    [1114] = {
        map_id = 533,
        creature_id = {15990},
    },
    -- High King Maulgar
    [649] = {
        map_id = 565,
        creature_id = {18831, 18832, 18834, 18835, 18836},
    },
    -- Gruul the Dragonkiller
    [650] = {
        map_id = 565,
        creature_id = {19044},
    },
    -- Magtheridon
    [651] = {
        map_id = 544,
        creature_id = {17257},
    },
    -- Attumen the Huntsman
    [652] = {
        map_id = 532,
        creature_id = {16151, 16152},
    },
    -- Moroes
    [653] = {
        map_id = 532,
        creature_id = {15687},
    },
    -- Maiden of Virtue
    [654] = {
        map_id = 532,
        creature_id = {16457},
    },
    -- The Opera Event
    [655] = {
        map_id = 532,
        creature_id = {17521, 17533, 17534, 18168},
    },
    -- Curator
    [656] = {
        map_id = 532,
        creature_id = {15691},
    },
    -- Chess Event
    [660] = {
        map_id = 532,
        creature_id = {21752, 21684},
    },
    -- Terestian Illhoof
    [657] = {
        map_id = 532,
        creature_id = {15688},
    },
    -- Shade of Aran
    [658] = {
        map_id = 532,
        creature_id = {16524},
    },
    -- Netherspite
    [659] = {
        map_id = 532,
        creature_id = {15689},
    },
    -- Nightbane
    [662] = {
        map_id = 532,
        creature_id = {17225},
    },
    -- Prince Malchezaar
    [661] = {
        map_id = 532,
        creature_id = {15690},
    },
    -- Hydross the Unstable
    [623] = {
        map_id = 548,
        creature_id = {21216},
    },
    -- The Lurker Below
    [624] = {
        map_id = 548,
        creature_id = {21217},
    },
    -- Leotheras the Blind
    [625] = {
        map_id = 548,
        creature_id = {21215},
    },
    -- Fathom-Lord Karathress
    [626] = {
        map_id = 548,
        creature_id = {21214, 21964, 21965, 21966},
    },
    -- Morogrim Tidewalker
    [627] = {
        map_id = 548,
        creature_id = {21213},
    },
    -- Lady Vashj
    [628] = {
        map_id = 548,
        creature_id = {21212},
    },
    -- A'lar
    [730] = {
        map_id = 550,
        creature_id = {19514},
    },
    -- Void Reaver
    [731] = {
        map_id = 550,
        creature_id = {19516},
    },
    -- High Astromancer Solarian
    [732] = {
        map_id = 550,
        creature_id = {19516},
    },
    -- Kael'thas Sunstrider
    [733] = {
        map_id = 550,
        creature_id = {19622},
    },
    --[] = {
    --    map_id = ,
    --    creature_id = {},
    --},
}
