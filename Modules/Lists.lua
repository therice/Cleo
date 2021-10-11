--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Models.List.Service
local ListsService = AddOn.Package('Models.List').Service

--- @class Lists
local Lists = AddOn:NewModule('Lists', "AceBucket-3.0", "AceTimer-3.0")

Lists.defaults = {
	profile = {

	},
	factionrealm = {
		configurations = {

		},
		lists = {

		},
	}
}

function Lists:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.Libs.AceDB:New(AddOn:Qualify('Lists'), self.defaults)
	self:InitializeService()
end

function Lists:InitializeService()
	--- @type Models.List.Service
	self.listsService = ListsService(
			{self, self.db.factionrealm.configurations},
			{self, self.db.factionrealm.lists}
	)
end

function Lists:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:RegisterBucketMessage(C.Messages.ConfigTableChanged, 5, "ConfigTableChanged")
end

function Lists:OnDisable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:UnregisterAllBuckets()
end

function Lists:EnableOnStartup()
	return true
end

function Lists:ConfigTableChanged(msg)
	Logging:Trace("Lists:ConfigTableChanged() : '%s", Util.Objects.ToString(msg))
end

function Lists:LaunchpadSupplement()
	return L["lists"], function(container) self:LayoutInterface(container) end , false
end


--- @return table<string, Models.List.Configuration>
function Lists:Configurations()
	Logging:Debug("Configurations()")
	return self.listsService:Configurations()
end

--- @return table<string, Models.List.List>
function Lists:Lists(configId)
	Logging:Debug("Lists(%s)", tostring(configId))
	return self.listsService:Lists(configId)
end

function Lists:UnassignedEquipmentLocations(configId)
	Logging:Debug("UnassignedEquipmentLocations(%s)", tostring(configId))
	return self.listsService:UnassignedEquipmentLocations(configId)
end

