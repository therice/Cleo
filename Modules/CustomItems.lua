--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type UI.Ace
local AceUI = AddOn.Require('UI.Ace')
--- @type LibGuildStorage
local GuildStorage = AddOn:GetLibrary("GuildStorage")
--- @type LibItemUtil
local ItemUtil =  AddOn:GetLibrary("ItemUtil")
--- @type Models.Item.Item
-- local Item = AddOn.Package('Models.Item').Item

local ACR = AddOn:GetLibrary('AceConfigRegistry')
--- @class CustomItems
local CustomItems  = AddOn:NewModule("CustomItems", "AceBucket-3.0")

CustomItems.defaults = {
	profile = {
		enabled = true,
		custom_items = {

		},
		ignored_default_items = {

		}
	}
}

local NoGuild = "No Guild"

function CustomItems:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.Libs.AceDB:New(AddOn:Qualify("CustomItems"), CustomItems.defaults, NoGuild)
	--[[
	AddOn:SyncModule():AddHandler(self:GetName(), L['gp_custom_sync_text'],
	                              function() return self.db.profile end,
	                              function(data) self:ImportData(data) end
	)
	--]]
end

function CustomItems:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	if IsInGuild() then
		GuildStorage.RegisterCallback(
				self,
				GuildStorage.Events.GuildNameChanged,
				function()
					GuildStorage.UnregisterCallback(self, GuildStorage.Events.GuildNameChanged)
					CustomItems:PerformEnable()
				end
		)
	else
		self:PerformEnable()
	end
end

function CustomItems:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self:UnregisterAllBuckets()
	ItemUtil:ResetCustomItems()
end

function CustomItems:PerformEnable()
	Logging:Debug("PerformEnable(%s) : %s", self:GetName(), tostring(GuildStorage:GetGuildName()))
	self.db:SetProfile(GuildStorage:GetGuildName() or NoGuild)
	self:AddDefaultCustomItems()
	self:ConfigureItemUtil()
	self:RegisterBucketMessage(C.Messages.ConfigTableChanged, 5, "ConfigTableChanged")
	Logging:Debug("PerformEnable(%s) : custom item count = %d", self:GetName(), Util.Tables.Count(self.db.profile.custom_items))
end

function CustomItems:ConfigTableChanged(msg)
	Logging:Trace("ConfigTableChanged() : '%s", Util.Objects.ToString(msg))
	for serializedMsg, _ in pairs(msg) do
		local success, module, _ = AddOn:Deserialize(serializedMsg)
		if success and self:GetName() == module then
			self:ConfigureItemUtil()
			break
		end
	end
end

function CustomItems:ConfigureItemUtil()
	Logging:Debug("ConfigureItemUtil(%s)", self:GetName())
	ItemUtil:SetCustomItems(self.db.profile.custom_items)
end

function CustomItems:AddItem(item)
	Logging:Debug("AddItem() : %s", Util.Objects.ToString(item))
	local id = item['id']
	if id then
		-- remove id from table, don't want to store it
		item['id'] = nil
		AddOn.SetDbValue(CustomItems, { 'custom_items.'.. id }, item)
		-- todo : this isn't going to refresh in the UI due to memoizing the options, need to fix
		-- Item.ClearCache(item)
		ACR:NotifyChange(C.name)
	end
end

function CustomItems:RemoveItem(item)
	Logging:Debug("RemoveItem() : %s", Util.Objects.ToString(item))
	item = tostring(item)
	local existingItem = self.db.profile.custom_items[item]
	if existingItem and existingItem.default then
		self.db.profile.ignored_default_items[item] = true
	end
	-- could do this, but don't get the callback for configuration change
	-- CustomItems.db.profile.custom_items[item] = nil
	AddOn.SetDbValue(CustomItems, { 'custom_items.'..item }, nil)
	-- Item.ClearCache(item)
	ACR:NotifyChange(C.name)
end

function CustomItems:AddDefaultCustomItems()
	Logging:Debug("AddDefaultCustomItems(%s)", self:GetName())
	local config = self.db.profile
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
						equip_location =  value[3],
						default = true,
					}
				end
			end
		end
	end
end

CustomItems.EquipmentLocations = {
	INVTYPE_HEAD           = C.ItemEquipmentLocationNames.Head,
	INVTYPE_NECK           = C.ItemEquipmentLocationNames.Neck,
	INVTYPE_SHOULDER       = C.ItemEquipmentLocationNames.Shoulder,
	INVTYPE_CHEST          = C.ItemEquipmentLocationNames.Chest,
	INVTYPE_WAIST          = C.ItemEquipmentLocationNames.Waist,
	INVTYPE_LEGS           = C.ItemEquipmentLocationNames.Legs,
	INVTYPE_FEET           = C.ItemEquipmentLocationNames.Feet,
	INVTYPE_WRIST          = C.ItemEquipmentLocationNames.Wrist,
	INVTYPE_HAND           = C.ItemEquipmentLocationNames.Hand,
	INVTYPE_FINGER         = C.ItemEquipmentLocationNames.Finger,
	INVTYPE_TRINKET        = C.ItemEquipmentLocationNames.Trinket,
	INVTYPE_CLOAK          = C.ItemEquipmentLocationNames.Cloak,
	INVTYPE_WEAPON         = C.ItemEquipmentLocationNames.OneHandWeapon,
	INVTYPE_SHIELD         = C.ItemEquipmentLocationNames.Shield,
	INVTYPE_2HWEAPON       = C.ItemEquipmentLocationNames.TwoHandWeapon,
	INVTYPE_WEAPONMAINHAND = C.ItemEquipmentLocationNames.MainHandWeapon,
	INVTYPE_WEAPONOFFHAND  = C.ItemEquipmentLocationNames.OffHandWeapon,
	INVTYPE_HOLDABLE       = C.ItemEquipmentLocationNames.Holdable,
	INVTYPE_RANGED         = C.ItemEquipmentLocationNames.Ranged,
	INVTYPE_WAND           = C.ItemEquipmentLocationNames.Wand,
	INVTYPE_THROWN         = C.ItemEquipmentLocationNames.Thrown,
	INVTYPE_RELIC          = C.ItemEquipmentLocationNames.Relic,
}

local EquipmentLocationsSort = {}

do
	for i, v in pairs(Util.Tables.ASort(CustomItems.EquipmentLocations, function(a, b) return a[2] < b[2] end)) do
		EquipmentLocationsSort[i] = v[1]
	end
end

local function AddItemToConfigOptions(self, builder, id)
	local name, link, _, _, _, _, _, _, _, texture = GetItemInfo(tonumber(id))
	Logging:Trace('AddItemToConfigOptions(%s) : %s', tostring(id), tostring(name))
	if name then
		local paramPrefix = 'custom_items.' .. id .. '.'
		builder
			:group(id, name):set('icon', texture)
				:set('get',
		             function(i)
			             self.selectedItem = Util.Strings.Split(tostring(i[#i]), '.')[2]
			             return AddOn.GetDbValue(self, i)
		             end
				)
				:set('hidden',
		             function()
			             local item = self.db.profile.custom_items[tostring(id)]
			             if item == nil then return true else return false end
		             end
				)
				:args()
					:description(paramPrefix .. 'header', link):order(1):fontSize('large')
						:set('image', texture)
					:header(paramPrefix .. 'filler', ""):order(2)
					:select(paramPrefix .. 'rarity', L['quality']):order(3)
						:desc(L['quality_desc']):set('width', 'double')
						:set('values', Util.Tables.Copy(C.ItemQualityDescriptions))
					:range(paramPrefix .. 'item_level', L['item_lvl'], 1, 200):order(4)
						:desc(L['item_lvl_desc']):set('width', 'double')
					:select(paramPrefix .. 'equip_location', L['equipment_loc']):order(5)
						:desc(L['equipment_loc_desc']):set('width', 'double')
						:set('values', self.EquipmentLocations)
						:set('sorting', EquipmentLocationsSort)
				:close()
	else
		-- Logging:Trace('AddItemToConfigOptions() : Item %s not available, submitting query', tostring(id))
		ItemUtil:QueryItemInfo(id, function() AddItemToConfigOptions(self, builder, id) end)
	end
end

local function BuildOptions(self)
	Logging:Debug("BuildOptions()")
	local builder = AceUI.ConfigBuilder()
	builder
			:group(CustomItems:GetName(), L["custom_items"]):desc(L["custom_items_desc"])
			:args()
				:header("spacer1",""):order(1)
				:description("help", L["custom_items_help"]):order(2)
				:header("spacer2",""):order(3)
				:execute("add", "Add"):desc("Add a new custom item"):order(4)
					:set('func',function(...) self:OnAddItemClick(...) end)
				:execute("remove", "Delete"):desc("Delete current custom item"):order(5)
					:set('func', function(...) self:OnDeleteItemClick(...) end)
				:header("spacer3",""):order(6)

	for _, id in pairs(Util.Tables.Sort(Util.Tables.Keys(self.db.profile.custom_items))) do
		AddItemToConfigOptions(self, builder, id)
	end

	return builder:build()
end

local Options = Util.Memoize.Memoize(BuildOptions)

function CustomItems:BuildConfigOptions()
	Logging:Debug("BuildConfigOptions()")
	local options = Options(self)
	return options[self:GetName()], true
end