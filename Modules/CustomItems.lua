--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type LibItemUtil
local ItemUtil =  AddOn:GetLibrary("ItemUtil")
--- @type Models.Item.Item
local Item = AddOn.Package('Models.Item').Item

--- @class CustomItems
local CustomItems  = AddOn:NewModule("CustomItems", "AceBucket-3.0", "AceTimer-3.0")

CustomItems.defaults = {
	profile = {
		enabled = true,
	},
	factionrealm = {
		custom_items = {

		},
		ignored_default_items = {

		}
	}
}

function CustomItems:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.Libs.AceDB:New(AddOn:Qualify("CustomItems"), CustomItems.defaults)
	AddOn:SyncModule():AddHandler(self:GetName(), L['custom_items_sync_text'],
	                              function() return self.db.profile end,
	                              function(data) self:ImportData(data) end
	)
end

function CustomItems:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:AddDefaultCustomItems()
	self:ConfigureItemUtil()
	self:RegisterBucketMessage(C.Messages.ConfigTableChanged, 5, "ConfigTableChanged")
	Logging:Debug("OnEnable(%s) : custom item count = %d", self:GetName(), Util.Tables.Count(self.db.factionrealm.custom_items))
end

function CustomItems:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self:UnregisterAllBuckets()
	ItemUtil:ResetCustomItems()
end

function CustomItems:GenerateConfigChangedEvents()
	return true
end

function CustomItems:ConfigTableChanged(msg)
	Logging:Trace("ConfigTableChanged() : '%s", Util.Objects.ToString(msg))
	for serializedMsg, _ in pairs(msg) do
		local success, module, _ = AddOn:Deserialize(serializedMsg)
		if success and Util.Strings.Equal(self:GetName(), module) then
			self:ConfigureItemUtil()
			break
		end
	end
end

function CustomItems:ConfigureItemUtil()
	Logging:Debug("ConfigureItemUtil(%s)", self:GetName())
	ItemUtil:SetCustomItems(self.db.factionrealm.custom_items)
end

function CustomItems:AddItem(item)
	Logging:Debug("AddItem() : %s", Util.Objects.ToString(item))
	local id = item['id']
	if id then
		-- remove id from table, don't want to store it
		item['id'] = nil
		self:SetDbValue(self.db.factionrealm, { 'custom_items.'.. id }, item)
		Item.ClearCache(id)
	end
end

function CustomItems:RemoveItem(item)
	Logging:Debug("RemoveItem() : %s", Util.Objects.ToString(item))
	item = tostring(item)
	local existingItem = self.db.factionrealm.custom_items[item]
	if existingItem and existingItem.default then
		self.db.profile.ignored_default_items[item] = true
	end
	self:SetDbValue(self.db.factionrealm, { 'custom_items.'..item }, nil)
	Item.ClearCache(item)
end

function CustomItems:AddDefaultCustomItems()
	Logging:Debug("AddDefaultCustomItems(%s)", self:GetName())
	local config = self.db.factionrealm
	if not config.custom_items then config.custom_items = { } end
	local custom_items = config.custom_items
	local ignored_default_items = config.ignored_default_items

	local faction = UnitFactionGroup("player")
	local defaultCustomItems = AddOn.DefaultCustomItems

	if Util.Tables.Count(defaultCustomItems) > 0 then
		for id, value in pairs(defaultCustomItems) do
			-- make sure the item applies to player's faction
			if not Util.Objects.IsSet(value[4]) or Util.Objects.Equals(value[4], faction) then
				local id_key = tostring(id)
				if not custom_items[id_key] and not ignored_default_items[id_key] then
					Logging:Trace("AddDefaultCustomItems() : adding item id=%s", id_key)
					custom_items[id_key] = {
						rarity = value[1],
						item_level = value[2],
						equip_location = value[3],
						default = true,
					}
				end
			end
		end
	end
end

function CustomItems:LaunchpadSupplement()
	return L["custom_items"], function(container) self:LayoutInterface(container) end , true
end