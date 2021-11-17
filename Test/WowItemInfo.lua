-- https://wowwiki.fandom.com/wiki/API_GetItemInfo
-- https://wowwiki.fandom.com/wiki/ItemString
--
-- itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
-- itemEquipLoc, itemIcon, itemSellPrice, typeId, subTypeId, bindType, expacID, itemSetID
-- isCraftingReagent
--
-- itemLink - e.g. |cFFFFFFFF|Hitem:12345:0:0:0|h[Item Name]|h|r
-- itemType : Localized name of the item’s class/type.
-- itemSubType : Localized name of the item’s subclass/subtype.
-- itemEquipLoc : Non-localized token identifying the inventory type of the item
local Items = {
    -- https://classic.wowhead.com/item=18832/brutality-blade
    [18832] = {
        'Brutality Blade',
        -- there are attributes in this link which aren't standard/plain, but bonuses (e.g. enchant at 2564)
        '|cff9d9d9d|Hitem:18832:2564:0:0:0:0:0:0:80:0:0:0:0|h[Brutality Blade]|h|r',
        4, --itemRarity
        70, --itemLevel
        60, --itemMinLevel
        "Weapon", --itemType
        'One-Handed Swords', --itemSubType
        1, --itemStackCount
        "INVTYPE_WEAPON", --itemEquipLoc
        135313,--itemIcon
        104089, --itemSellPrice
        2, --typeId
        7, --subTypeId
        1, --bindType
        254, --expacID
        nil, --itemSetID
        false --isCraftingReagent
    },
    [21232] = {
        'Imperial Qiraji Armaments',
        '|cff9d9d9d|Hitem:21232:0:0:0:0:0:0:0:80:0:0:0:0|h[Imperial Qiraji Armaments]|h|r',
    },
    [18646] = {
        'The Eye of Divinity',
        '|cff9d9d9d|Hitem:18646:0:0:0:0:0:0:0:80:0:0:0:0|h[The Eye of Divinity]|h|r',
    },
    [17069] = {
        'Striker\'s Mark',
        '|cff9d9d9d|Hitem:17069:0:0:0:0:0:0:0:80:0:0:0:0|h[Striker\'s Mark]|h|r',
    },
    [22356] = {
        'Desecrated Waistguard',
        '|cff9d9d9d|Hitem:22356:0:0:0:0:0:0:0:80:0:0:0:0|h[Desecrated Waistguard]|h|r',
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        133828
    }
}

local function ItemId(item)
    if type(item) == 'string' then
        if string.match(item,"^%d+$") then
            item = tonumber(item)
        else
            item = tonumber(strmatch(item or "", ".*item:(%d+):?"))
        end
    end
    return item
end

-- item can be one of following input types
-- 	Numeric ID of the item. e.g. 30234
-- 	Name of an item owned by the player at some point during this play session, e.g. "Nordrassil Wrath-Kilt"
--  A fragment of the itemString for the item, e.g. "item:30234:0:0:0:0:0:0:0" or "item:30234"
--  The full itemLink (e.g. |cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0|h[Broken Fang]|h|r )
local function ItemInfo(item)
    local id = ItemId(item)
    return id, Items[id] or {}
end

_G.GetItemInfo = function(item)
    local id, info = ItemInfo(item)
    -- print(tostring(item) .. ' -> ' .. tostring(id))
    if info and #info > 0 then
        return unpack(info)
    else
        return "ItemName" .. id, "item:" .. id ..":0:0:0:0:0:0:0:" .. random(60), 4, 70, 60,  "Weapon", 'One-Handed Swords', 1, "INVTYPE_WEAPON"
    end
end

-- itemID, itemType, itemSubType, itemEquipLoc, icon, itemClassID, itemSubClassID
-- GetItemInfoInstant(itemID or "itemString" or "itemName" or "itemLink")
-- https://wow.gamepedia.com/API_GetItemInfoInstant
_G.GetItemInfoInstant = function(item)
    local id, info = ItemInfo(item)
    if id > 0 then
        return id,
        info and info[6] or nil,
        info and info[7] or nil,
        info and info[9] or nil,
        info and info[10] or nil,
        info and info[12] or nil,
        info and info[13] or nil
    end
end
