C_Container = {

}

-- https://wowpedia.fandom.com/wiki/API_C_Container.GetContainerNumSlots
function C_Container.GetContainerNumSlots(container)
	return 10
end

-- https://wowpedia.fandom.com/wiki/API_C_Container.GetContainerItemLink
function C_Container.GetContainerItemLink(container, slot)
	return nil
end

-- https://wowpedia.fandom.com/wiki/API_C_Container.GetContainerNumFreeSlots
function C_Container.GetContainerNumFreeSlots(container)
	return 4, 0
end

-- https://wowpedia.fandom.com/wiki/API_C_Container.GetContainerItemInfo
function C_Container.GetContainerItemInfo(container, slot)
	return nil
end


function C_Container.PickupContainerItem(container, slot)

end

_G.C_Container = C_Container


