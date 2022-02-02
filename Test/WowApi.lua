_G.getfenv = function() return _G end
_G.random = math.random
-- need to set random seed and invoke once to avoid non-random behavior
math.randomseed(os.time())
math.random()


-- utility function for "dumping" a number of arguments (return a string representation of them)
function dump(...)
    local t = {}
    for i=1,select("#", ...) do
        local v = select(i, ...)
        if type(v)=="string" then
            tinsert(t, string.format("%q", v))
        elseif type(v)=="table" then
            tinsert(t, tostring(v).." #"..#v)
        else
            tinsert(t, tostring(v))
        end
    end
    return "<"..table.concat(t, "> <")..">"
end

require('bit')
_G.bit = bit
_G.tInvert = function(tbl)
    local inverted = {};
    for k, v in pairs(tbl) do
        inverted[v] = k;
    end
    return inverted;
end
_G.getfenv = function() return _G end
-- define required function pointers in global space which won't be available in testing
_G.format = string.format
-- https://wowwiki.fandom.com/wiki/API_debugstack
-- debugstack([thread, ][start[, count1[, count2]]]])
-- ignoring count2 currently (lines at end)
_G.debugstack = function (start, count1, count2)
    -- UGH => https://lua-l.lua.narkive.com/ebUKEGpe/confused-by-lua-reference-manual-5-3-and-debug-traceback
    -- If message is present but is neither a string nor nil, this function returns message without further processing.
    -- Otherwise, it returns a string with a traceback of the call stack. An optional message string is appended at the
    -- beginning of the traceback. An optional level number tells at which level to start the traceback
    -- (default is 1, the function calling traceback).
    local stack = debug.traceback()
    local chunks = {}
    for chunk in stack:gmatch("([^\n]*)\n?") do
        -- remove leading and trailing spaces
        local stripped = string.gsub(chunk, '^%s*(.-)%s*$', '%1')
        table.insert(chunks, stripped)
    end

    -- skip first line that looks like 'stack traceback:'
    local start_idx = math.min(start + 2, #chunks)
    -- where to stop, it's the start index + count1 - 1 (to account for counting line where we start)
    local end_idx = math.min(start_idx + count1 - 1, #chunks)
    return table.concat(chunks, '\n', start_idx, end_idx)
end
_G.strmatch = string.match
_G.strjoin = function(delimiter, ...)
    return table.concat({...}, delimiter)
end
_G.string.trim = function(s)
    -- from PiL2 20.4
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

_G.strfind = string.find
_G.gsub = string.gsub
_G.date = os.date
_G.time = os.time
_G.difftime = os.difftime
_G.tinsert = table.insert
_G.tremove = table.remove
_G.floor = math.floor
_G.strlower = string.lower
_G.strupper = string.upper
_G.mod = function(a,b) return a - math.floor(a/b) * b end
_G.max = math.max
_G.min = math.min
_G.ceil = math.ceil
_G.frexp = math.frexp
_G.ldexp = math.ldexp

-- https://wowwiki.fandom.com/wiki/API_strsplit
-- A list of strings. Not a table. If the delimiter is not found in the string, the whole subject string will be returned.
_G.strsplit = function(delimiter, str, max)
    local record = {}
    if string.len(str) > 0 then
        max = max or -1

        local field, start = 1, 1
        local first, last = string.find(str, delimiter, start, true)
        while first and max ~= 0 do
            record[field] = string.sub(str, start, first -1)
            field = field +1
            start = last +1
            first, last = string.find(str, delimiter, start, true)
            max = max -1
        end
        record[field] = string.sub(str, start)
    end

    return unpack(record)
end
string.split = _G.strsplit
_G.strsub = string.sub
_G.strbyte = string.byte
_G.strchar = string.char
_G.pack = table.pack
_G.unpack = table.unpack
_G.sort = table.sort

_G.tDeleteItem = function(tbl, item)
    local index = 1;
    while tbl[index] do
        if ( item == tbl[index] ) then
            tremove(tbl, index);
        else
            index = index + 1;
        end
    end
end

--[[ Test code for debugprofilestop

		local clock = os.clock
		function sleep(n)  -- seconds
			local t0 = clock()
			while clock() - t0 <= n do end
		end

        t = debugprofilestop()
        sleep(2)
        print(format("%.2f", debugprofilestop() - t))
--]]
function sleep(n)  -- seconds
    local t = os.clock()
    while os.clock() - t <= n do end
end


-- this mostly works
_G.debugprofilestop = function() return os.clock() * 1000 end


function getglobal(k)
    return _G[k]
end

function setglobal(k, v)
    _G[k] = v
end


local wow_api_locale = 'enUS'
function GetLocale()
    return wow_api_locale
end

function SetLocale(locale)
    wow_api_locale = locale
end

C_Timer = {}
local timer = require("copas.timer")
local timerCount = 1
function C_Timer.After(duration, callback)
    local ref = timerCount
    timerCount = timerCount + 1

    print(format('C_Timer.After[START](%d, %d, %d)', ref, duration, os.time()))
    if _G.IsAsync() then
        return timer.new({
             delay = duration,
             recurring = false,
             callback = function()
                 print(format('C_Timer.After[END](%d, %d, %d)', ref, duration, os.time()))
                 callback()
             end
         })
    else
        callback()
        return nil
    end
end

function C_Timer.NewTimer(duration, callback)  end
function C_Timer.NewTicker(duration, callback, iterations)  end
function C_Timer.Cancel(t)
    print(format('C_Timer.Cancel[EVAL]()'))
    if t and t.cancel then
        print(format('C_Timer.Cancel[EXEC]()'))
        t:cancel()
    end
end

if not wipe then
    function wipe(tbl)
        for k in pairs(tbl) do
            tbl[k]=nil
        end
        return tbl
    end

    if not table.wipe then
        table.wipe = wipe
    end
end

function hooksecurefunc(func_name, post_hook_func)
    local orig_func = _G[func_name]
    _G[func_name] =
    function (...)
        local ret = { orig_func(...) }
        post_hook_func(...)
        return unpack(ret)
    end
end

_time = 0
function GetTime()
    return _time
end

function SetTime(time)
    if not time then time = GetServerTime() end
    _time = time
end

function GetFramerate()
    return 60
end

function GetServerTime()
    return os.time()
end

function GetAddOnMetadata(name, attr)
    if string.lower(attr) == 'version' then
        return "2021.1.0-dev"
    else
        return nil
    end
end

function GetAddOnInfo()
    return
end

function GetCurrentRegion()
    return 1 -- "US"
end

function GuildRoster ()
    -- dubious to work around issues with library using this function
    -- being called before addon is loaded
    if _G.IsAddOnLoaded('Cleo') then
        -- print('GuildRoster')
        GuildRosterUpdate()
    end
end

function IsInGuild() return 1 end

function IsInRaid() return _G.IsInRaidVal end

function UnitInRaid() return _G.IsInRaidVal end

function IsInGroup() return _G.IsInGroupVal end

function UnitInParty() return _G.IsInGroupVal end

-- https://wow.gamepedia.com/API_UnitIsUnit
function UnitIsUnit(a, b)
    -- extremely rudimentary, doesnt' handle things like resolving targettarget, player, etc
    -- print('UnitIsUnit -> ' .. tostring(a) .. '/' .. tostring(b))
    if a == b then return 1 else return nil end
end

function InCombatLockdown() return false end

function GetLootThreshold() return 2 end

function GetNumLootItems() return 3 end

function LootSlotHasItem(slot) return (slot % 2 ~= 0)  end

function GetLootSlotInfo(slot)
    return random(2500), "Item"..slot, 1, nil, 4
end

local CreatureGuid = 'Creature-0-970-0-11-31146-000136DF91'
function GetLootSourceInfo(slot)
    return CreatureGuid
end

function GetUnitName(unit)
    if unit == "target" then
        return "C'Thun"
    end

    return "Unknown"
end

function GetLootSlotLink(slot)
    return GetInventoryItemLink(nil, slot)
end

function LootSlot(slot)
    -- todo : fire event
end

function IsEquippableItem(item)
    return true
end

function IsInInstance()
    local type = "none"
    if _G.IsInGroupVal then
        type = "party"
    elseif _G.IsInRaidVal then
        type = "raid"
    end
    return (IsInGroup() or IsInRaid()), type
end


local PlayerToGuid = {
    ['Annasthétic'] = {
        guid = 'Player-4372-011C6125',
        name = 'Annasthétic-Atiesh',
        realm = 'Atiesh',
        class = 'PRIEST',
    },
    Eliovak = {
        guid = 'Player-4372-00706FE5',
        name = 'Eliovak-Atiesh',
        realm = 'Atiesh',
        class = 'ROGUE',
    },
    Folsom = {
        guid = 'Player-4372-007073FE',
        name = 'Folsom-Atiesh',
        realm = 'Atiesh',
        class = 'WARRIOR',
    },
    ['Gnomechómsky'] = {
        guid = 'Player-4372-00C1D806',
        name = 'Gnomechómsky-Atiesh',
        realm = 'Atiesh',
        class = 'WARLOCK',
    },
    Player1 = {
        guid = "Player-1-00000001",
        name = "Player1-Realm1",
        realm = "Realm1",
        class = "WARRIOR"
    },
    Player2 = {
        guid = "Player-1-00000002",
        name = "Player2-Realm1",
        realm = "Realm1",
        class = "WARRIOR"
    },
    Player3 = {
        guid = "Player-1122-00000003",
        name = "Player3-Realm2",
        realm = "Realm2",
        class = "WARRIOR"
    },
}

local PlayerGuidInfo = {}
for _, info in pairs(PlayerToGuid) do
    PlayerGuidInfo[info.guid] = info
end

function AddPlayerGuid(name, guid, realm, class)
    if not PlayerToGuid[name] then
        local info = {
            guid = guid,
            name = name .. '-' .. realm,
            realm = realm,
            class = class
        }
        PlayerToGuid[name] = info
        PlayerGuidInfo[guid] = info
        -- print(format('AddPlayerGuid added %s, %s', name, guid))
    end
end

function GetGuildInfo(unit) return "The Black Watch", "Quarter Master", 1, nil end

function GetGuildInfoText() return "This is my guild info" end

function GetNumGuildMembers() return 10  end

function GetGuildRosterInfo(index)
    local workingIdx = 100 + index
    local name, guid, realm = "Player" .. workingIdx, 'Player-1-' .. string.format("%08d", workingIdx), 'Realm1'
    local classInfo = C_CreatureInfo.GetClassInfo(math.random(1,5))

    AddPlayerGuid(name, guid, realm, classInfo.classFile)

    --  name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID

    return
        name .. '-' .. realm, 'Member', 2,760, classInfo.className, 'IronForge', "", "1240,34", 1, 0, classInfo.classFileName,
        -1, 64, false, false, 3, guid
end

function GetRealmName() return 'Realm1' end

function UnitName(unit)
    if unit == "player" then
        return "Player1"
    elseif unit == "raid1" then
        return "Player1"
    else
        return unit --, "Realm1"
    end
end

function UnitFullName(unit)
    return UnitName(unit), GetRealmName()
end

function UnitClass(unit)
    if unit == "player" then
        return "Warlock", "WARLOCK"
    else
        return "Warrior", "WARRIOR"
    end
end

function UnitRace(unit)
    if unit == "player" then
        return "Gnome", "Gnome"
    else
        return "Human", "Human"
    end
end

function UnitPosition(unit)
    return 0, 0, 0, 531
end

function Ambiguate(name, context)
    if context == "short" then
        name = gsub(name, "%-.+", "")
    end
    return name
end

function GetRaidRosterInfo(i)
    local workingIdx = 500 + i
    local name, guid, realm = "Player" .. workingIdx, 'Player-1-' .. string.format("%08d", workingIdx), 'Realm1'
    local classInfo = C_CreatureInfo.GetClassInfo(math.random(1,5))
    AddPlayerGuid(name, guid, realm, classInfo.classFile)

    -- https://wow.gamepedia.com/API_GetRaidRosterInfo
    -- name, rank, subgroup, level, class, fileName, zone, online
    -- return name, nil, nil, nil, nil, nil, classInfo.classFile, 1
    return name, nil, nil, nil, nil, classInfo.classFile, 'ZONE', 1
end

-- _, _, _, _, _, _, _, mapId
function GetInstanceInfo()
    local ii = _G.InstanceInfo
    return ii and ii.name or "Temple of Ahn\'Qiraj", "raid", 1, "40 Player", 40, 0, false, ii and ii.mapid or 531, nil
end

function IsLoggedIn() return false end

function GetLootMethod() return "master", nil, 1 end

function IsMasterLooter() return true end

function UnitHealthMax() return 100  end

function UnitHealth() return 50 end

_G.MAX_RAID_MEMBERS = 25

function GetNumRaidMembers() return _G.MAX_RAID_MEMBERS  end

function GetMasterLootCandidate(slot, i) return "Player" ..  i end

function GetNumPartyMembers() return 5 end

function GetNumGroupMembers() return 25 end

function UnitIsDeadOrGhost(name) return false end

function InCinematic() return false end

function UnitIsGroupLeader(name)
    if _G.UnitIsGroupLeaderVal then return true end
    return false
end

function UnitGUID (name)
    if name == 'player' then name = UnitName(name) end
    if name == 'noguid' then return nil end
    --print(format('UnitGUID(%s)', name))
    return PlayerToGuid[name] and PlayerToGuid[name].guid or "Player-FFF-ABCDF012"
end

function GetPlayerInfoByGUID (guid)
    local player = PlayerGuidInfo[guid]
    if player then
        return nil,player.class, nil,nil,nil, player.name, player.realm
    else
        return nil, "HUNTER", nil,nil,nil, "Unknown", "Unknown"
    end
end

function GetInventorySlotInfo(slot)

end

function GetItemFamily(item)
    return "INVTYPE_BAG"
end

function GetContainerNumFreeSlots(bag)
    return 4, 0

end
_G.BACKPACK_CONTAINER = 0
_G.NUM_BAG_SLOTS = 4

function escapePatternSymbols(value)
    return value
end

FACTION_HORDE = "Horde"
FACTION_ALLIANCE = "Alliance"

function UnitFactionGroup(unit)
    return FACTION_ALLIANCE, FACTION_ALLIANCE
end

function GetSpellInfo(id)
    if id == 7411 then return "Enchanting" end
    return nil
end

function GetNumSkillLines()
    return 20
end

function GetSkillLineInfo(index)
    if index == 4 then return "Enchanting", nil, nil, 298 end

    return "Unknown" .. index, nil, nil, random(300)
end

function GetInventoryItemLink(unit, slotId)
  return "item:" .. random(50000) ..":0:0:0:0:0:0:0:" .. random(60)
end

function GiveMasterLoot(slot, i)

end

function CanEditOfficerNote() return true end

function ChatFrame_AddMessageEventFilter(event, fn)  end

-- dubious
local function SenderName()
    local player, realm = UnitFullName("player")
    return  player .. '-' .. realm
end

function SendChatMessage(text, chattype, language, destination)
    -- print('SendChatMessage -> ' .. tostring(destination))
    assert(#text<255)
    WoWAPI_FireEvent("CHAT_MSG_"..strupper(chattype), text, SenderName(), language or "Common")
end

local registeredPrefixes = {}
function RegisterAddonMessagePrefix(prefix)
    assert(#prefix<=16)	-- tested, 16 works /mikk, 20110327
    registeredPrefixes[prefix] = true
end

function SendAddonMessage(prefix, message, distribution, target)
    --print('SendAddonMessage -> ' .. tostring(distribution) .. '/' .. tostring(target))
    if RegisterAddonMessagePrefix then --4.1+
        assert(#message <= 255,
                string.format("SendAddonMessage: message too long (%d bytes > 255)",
                        #message))
        -- CHAT_MSG_ADDON(prefix, message, distribution, sender)
        WoWAPI_FireEvent("CHAT_MSG_ADDON", prefix, message, distribution, SenderName())
    else -- allow RegisterAddonMessagePrefix to be nilled out to emulate pre-4.1
        assert(#prefix + #message < 255,
                string.format("SendAddonMessage: message too long (%d bytes)",
                        #prefix + #message))
        -- CHAT_MSG_ADDON(prefix, message, distribution, sender)
        WoWAPI_FireEvent("CHAT_MSG_ADDON", prefix, message, distribution, SenderName())
    end
end

_G.C_ChatInfo = {}
_G.C_ChatInfo.RegisterAddonMessagePrefix = RegisterAddonMessagePrefix
_G.C_ChatInfo.SendAddonMessage = SendAddonMessage

C_FriendList = {}

_G.MAX_CLASSES = 9

C_CreatureInfo = {}
C_CreatureInfo.ClassInfo = {
    [1] = {
        "Warrior", "WARRIOR"
    },
    [2] = {
        "Paladin", "PALADIN"
    },
    [3] = {
        "Hunter", "HUNTER"
    },
    [4] = {
        "Rogue", "ROGUE"
    },
    [5] = {
        "Priest", "PRIEST"
    },
    [6] = nil,
    [7] = {
        "Shaman", "SHAMAN"
    },
    [8] = {
        "Mage", "MAGE"
    },
    [9] = {
        "Warlock", "WARLOCK"
    },
    [10] = nil,
    [11] = {
        "Druid", "DRUID"
    },
    [12] = nil,
}

-- className (localized name, e.g. "Warrior"), classFile (non-localized name, e.g. "WARRIOR"), classID
function C_CreatureInfo.GetClassInfo(classID)
    local classInfo = C_CreatureInfo.ClassInfo[classID]
    if classInfo then
        return {
            className = classInfo[1],
            classFile = classInfo[2],
            classID = classID
        }
    end
    return nil
end

local function CreatePlayerLocationMixin()
    return {
        guid = nil,
        SetGUID = function(self, guid)
            self.guid = guid
        end
    }
end

PlayerLocation = {}
function PlayerLocation:CreateFromGUID(guid)
    local playerLocation = CreatePlayerLocationMixin()
    playerLocation:SetGUID(guid)
    return playerLocation
end

C_PlayerInfo = {}
function C_PlayerInfo.IsConnected(playerLocation)
    return true
end


SlashCmdList = {}
hash_SlashCmdList = {}

function __WOW_Input(text)
    local a, b = string.find(text, "^/%w+")
    local arg, text = string.sub(text, a, b), string.sub(text, b + 2)
    for k, handler in pairs(SlashCmdList) do
        local i = 0
        while true do
            i = i + 1
            if not _G["SLASH_" .. k .. i] then
                break
            elseif _G["SLASH_" .. k .. i] == arg then
                handler(text)
                return
            end
        end
    end;
    -- print("No command found:", text)
end

local ChatFrameTemplate = {
    AddMessage = function(self, text)
        print((string.gsub(text, "|c%x%x%x%x%x%x%x%x(.-)|r", "%1")))
    end
}

for i = 1, 7 do
    local f = {}
    for k, v in pairs(ChatFrameTemplate) do
        f[k] = v
    end
    _G["ChatFrame"..i] = f
end
DEFAULT_CHAT_FRAME = ChatFrame1

local Color = {}
function Color:New(r, g, b, a)
    local c = {r=r, g=g, b=b, a=a}
    c['GetRGB'] = function() return c.r, c.g, c.b end
    c['GetRGBA'] = function() return c.r, c.g, c.b, c.a end
    c.hex = string.format("%02X%02X%02X", math.floor(255*c.r), math.floor(255*c.g), math.floor(255*c.b))
    return c
end

_G.CreateColor = function(r, g, b, a)
    return Color:New(r, g, b, a)
end

_G.NORMAL_FONT_COLOR = Color:New(1, 1, 1, 1)

_G.ITEM_QUALITY_COLORS = {
    {color = Color:New(1, 0, 0, 0)},
    {color = Color:New(2, 0, 0, 0)},
    {color = Color:New(3, 0, 0, 0)},
    {color = Color:New(4, 0, 0, 0)},
    {color = Color:New(5, 0, 0, 0)},
    {color = Color:New(6, 0, 0, 0)},
    {color = Color:New(7, 0, 0, 0)},
}
_G.ITEM_QUALITY_COLORS[0] = {color = Color:New(0, 0, 0, 0)}

for _, c in pairs(_G.ITEM_QUALITY_COLORS) do
    c.hex = c.color.hex
end

function GetItemQualityColor(rarity)
    return _G.ITEM_QUALITY_COLORS[rarity].color
end


_G.CreateFont = function(name)
    local font = {}

    font.GetFont = function(self)  return {} end
    font.SetFont = function()  end
    font.SetShadowColor = function()  end
    font.SetShadowOffset = function()  end
    font.SetShadowOffset = function()  end
    font.SetTextColor = function()  end

    return font
end
_G.GetFont = _G.CreateFont()
_G.GameFontNormal = _G.CreateFont()
_G.GameFontHighlightSmall = _G.CreateFont()


_G.RAID_CLASS_COLORS = {}

-- https://github.com/Gethe/wow-ui-source/tree/classic
_G.INVTYPE_HEAD = "Head"
_G.INVTYPE_NECK = "Neck"
_G.INVTYPE_SHOULDER = "Shoulder"
_G.INVTYPE_CHEST = "Chest"
_G.INVTYPE_WAIST = "Waist"
_G.INVTYPE_LEGS = "Legs"
_G.INVTYPE_FEET = "Feet"
_G.INVTYPE_WRIST = "Wrist"
_G.INVTYPE_HAND = "Hands"
_G.INVTYPE_FINGER = "Finger"
_G.INVTYPE_TRINKET = "Trinket"
_G.INVTYPE_CLOAK = "Back"
_G.SHIELDSLOT = "Shield"
_G.INVTYPE_HOLDABLE = "Held In Off-Hand"
_G.INVTYPE_RANGED = "Ranged"
_G.INVTYPE_RELIC =  "Relic"
_G.INVTYPE_WEAPON = "One-Hand"
_G.INVTYPE_2HWEAPON = "Two-Handed"
_G.INVTYPE_WEAPONMAINHAND = "Main Hand"
_G.INVTYPE_WEAPONOFFHAND = "Off Hand"
_G.WEAPON = "Weapon"
_G.LE_ITEM_WEAPON_AXE1H = 0
_G.LE_ITEM_WEAPON_AXE2H = 1
_G.LE_ITEM_WEAPON_BOWS = 2
_G.LE_ITEM_WEAPON_GUNS = 3
_G.LE_ITEM_WEAPON_MACE1H = 4
_G.LE_ITEM_WEAPON_MACE2H = 5
_G.LE_ITEM_WEAPON_POLEARM = 6
_G.LE_ITEM_WEAPON_SWORD1H = 7
_G.LE_ITEM_WEAPON_SWORD2H = 8
_G.LE_ITEM_WEAPON_WARGLAIVE = 9
_G.LE_ITEM_WEAPON_STAFF = 10
_G.LE_ITEM_WEAPON_BEARCLAW = 11
_G.LE_ITEM_WEAPON_CATCLAW = 12
_G.LE_ITEM_WEAPON_UNARMED = 13
_G.LE_ITEM_WEAPON_GENERIC = 14
_G.LE_ITEM_WEAPON_DAGGER = 15
_G.LE_ITEM_WEAPON_THROWN = 16
_G.LE_ITEM_WEAPON_CROSSBOW = 18
_G.LE_ITEM_WEAPON_WAND = 19
_G.LE_ITEM_ARMOR_GENERIC = 0
_G.LE_ITEM_ARMOR_CLOTH = 1
_G.LE_ITEM_ARMOR_LEATHER = 2
_G.LE_ITEM_ARMOR_MAIL = 3
_G.LE_ITEM_ARMOR_PLATE = 4
_G.LE_ITEM_ARMOR_COSMETIC = 5
_G.LE_ITEM_ARMOR_SHIELD = 6
_G.LE_ITEM_ARMOR_LIBRAM = 7
_G.LE_ITEM_ARMOR_IDOL = 8
_G.LE_ITEM_ARMOR_TOTEM = 9
_G.LE_ITEM_ARMOR_SIGIL = 10
_G.LE_ITEM_ARMOR_RELIC = 11
_G.LE_ITEM_CLASS_WEAPON = 2
_G.LE_ITEM_CLASS_ARMOR = 4
-- not colored
_G.ITEM_QUALITY0_DESC = 'Poor'
_G.ITEM_QUALITY1_DESC = 'Common'
_G.ITEM_QUALITY2_DESC = 'Uncommon'
_G.ITEM_QUALITY3_DESC = 'Rare'
_G.ITEM_QUALITY4_DESC = 'Epic'
_G.ITEM_QUALITY5_DESC = 'Legendary'
_G.ITEM_QUALITY6_DESC = 'Artifact'

_G.INVSLOT_AMMO           = 0
_G.INVSLOT_HEAD           = 1
_G.INVSLOT_NECK           = 2
_G.INVSLOT_SHOULDER       = 3
_G.INVSLOT_BODY           = 4
_G.INVSLOT_CHEST          = 5
_G.INVSLOT_WAIST          = 6
_G.INVSLOT_LEGS           = 7
_G.INVSLOT_FEET           = 8
_G.INVSLOT_WRIST          = 9
_G.INVSLOT_HAND           = 10
_G.INVSLOT_FINGER1        = 11
_G.INVSLOT_FINGER2        = 12
_G.INVSLOT_TRINKET1       = 13
_G.INVSLOT_TRINKET2       = 14
_G.INVSLOT_BACK           = 15
_G.INVSLOT_MAINHAND       = 16
_G.INVSLOT_OFFHAND        = 17
_G.INVSLOT_RANGED         = 18
_G.INVSLOT_TABARD         = 19
_G.INVSLOT_FIRST_EQUIPPED = _G.INVSLOT_HEAD
_G.INVSLOT_LAST_EQUIPPED  = _G.INVSLOT_TABARD

_G.RANDOM_ROLL_RESULT = "%s rolls %d (%d-%d)"

_G.RandomRoll = function(low, high)
    local result = random(low, high)
    SendChatMessage(
            format(_G.RANDOM_ROLL_RESULT, UnitName('player'), result, low, high),
            'SYSTEM'
    )
end

_G.RETRIEVING_ITEM_INFO = "Retrieving item information"
_G.ERR_CHAT_PLAYER_NOT_FOUND_S = "No player named '%s' is currently playing."
_G.TOOLTIP_DEFAULT_BACKGROUND_COLOR = {
    r = 0,
    g = 0,
    b = 0,
}
_G.TOOLTIP_DEFAULT_COLOR = {
    r = 0,
    g = 0,
    b = 0,
}

_G.LE_ITEM_BIND_ON_EQUIP = 2
_G.LE_ITEM_BIND_ON_ACQUIRE = 1

_G.AUTO_LOOT_DEFAULT_TEXT = "Auto Loot"
_G.ITEM_LEVEL_ABBR = "Item Level"

_G.ROLL = "Roll"
_G.GENERAL = "General"
_G.UNKNOWNOBJECT = "Unknown"
_G.StaticPopup_DisplayedFrames = {}

_G.PlaySound = function(...) end

_G.FauxScrollFrame_Update = function() end
_G.FauxScrollFrame_GetOffset = function() return 0 end
_G.CLASS_ICON_TCOORDS = {}
_G.ENABLE = "Enable"
_G.CLOSES_IN = "Time remaining"
_G.FRIENDS_FRIENDS_CHOICE_EVERYONE = "Everyone"

-- https://wow.gamepedia.com/API_GetItemSubClassInfo
function GetItemSubClassInfo(classId, subClassId)
    if classId == LE_ITEM_CLASS_WEAPON then
        if subClassId == LE_ITEM_WEAPON_BOWS then
            return "Bows"
        elseif subClassId == LE_ITEM_WEAPON_CROSSBOW then
            return "Crossbows"
        elseif subClassId == LE_ITEM_WEAPON_GUNS then
            return "Guns"
        elseif subClassId == LE_ITEM_WEAPON_WAND then
            return "Wands"
        elseif subClassId == LE_ITEM_WEAPON_THROWN then
            return "Thrown"
        end
    elseif classId == LE_ITEM_CLASS_ARMOR then
        if subClassId == LE_ITEM_ARMOR_LIBRAM then
            return "Libram"
        elseif subClassId == LE_ITEM_ARMOR_IDOL then
            return "Idol"
        elseif subClassId == LE_ITEM_ARMOR_TOTEM then
            return "Totem"
        end
    end
    return ""
end

loadfile('Test/WowItemInfo.lua')()
loadfile('Test/WowApiUI.lua')()

