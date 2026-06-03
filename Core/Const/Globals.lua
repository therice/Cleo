--- @type AddOn
local _, AddOn = ...

AddOn.C_Container = _G.C_Container or {
	GetContainerNumSlots     = _G.GetContainerNumSlots,
	GetContainerItemLink     = _G.GetContainerItemLink,
	GetContainerNumFreeSlots = _G.GetContainerNumFreeSlots,
	GetContainerItemInfo     = _G.GetContainerItemInfo,
	PickupContainerItem      = _G.PickupContainerItem,
}

AddOn.C_AddOns = _G.C_AddOns or {
	GetAddOnMetadata = _G.GetAddOnMetadata,
	IsAddOnLoaded    = _G.IsAddOnLoaded,
}

AddOn.C_PartyInfo = _G.C_PartyInfo or {
	GetLootMethod           = _G.GetLootMethod,
	SetLootMethod           = _G.SetLootMethod
}
