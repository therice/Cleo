-- https://github.com/Gethe/wow-ui-source/blob/703e072b4f993d3242317ee84d6739c80066391b/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua
--
-- partial implementation of https://wowpedia.fandom.com/wiki/Category:API_namespaces/C_Item
--
C_Item = {}

function C_Item.GetItemInfo(item)
	return GetItemInfo(item)
end

function C_Item.GetItemInfoInstant(item)
	return GetItemInfoInstant(item)
end

-- This isn't accurate as to the format of spawnUD, only length and in HEX
-- Item-[serverID]-0-[spawnUID]
function C_Item.GetItemGUID(location)
	return "Item-4372-0-" .. randomHexBytes(8)
end

function C_Item.GetItemID(location)
	return random(50000)
end

function C_Item.GetItemLink(location)
	local id = C_Item.GetItemID(location)
	return "|cffa335ee|Hitem:" .. id .. format(":::::::::::::::::|h[%s]|h|r", "ItemName" .. id)
end

function C_Item.DoesItemExist(itemLocation)
	return true
end

function C_Item.DoesItemExistByID(item)
	return true
end

function C_Item.RequestLoadItemDataByID(item)

end

_G.C_Item = C_Item