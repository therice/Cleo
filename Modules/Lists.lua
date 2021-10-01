--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Models.Date
local Date = AddOn.Package('Models').Date
--- @type Models.DateFormat
local DateFormat = AddOn.Package('Models').DateFormat
--- @type Models.List.Configuration
local Configuration = AddOn.Package('Models.List').Configuration
--- @type Models.List.List
local List = AddOn.Package('Models.List').List
--- @type Models.Player
local Player = AddOn.Package('Models').Player
local UUID = Util.UUID.UUID


--- @class Lists
local Lists = AddOn:NewModule('Lists', "AceBucket-3.0", "AceTimer-3.0")

--- @class Lists.Dao
local Dao = AddOn.Package('Lists'):Class('Dao')
function Dao:initialize(module, db, entityClass)
	self.module = module
	self.db = db
	self.entityClass = entityClass
end

function Dao.Key(entity, attr)
	return entity.id .. '.' .. attr
end

function Dao:Reconstitute(id, attrs)
	local entity = self.entityClass:reconstitute(attrs)
	entity.id = id
	Logging:Trace("Dao.Reconstitute(%s) : %s", tostring(id), Util.Objects.ToString(entity:toTable()))
	return entity
end

-- C(reate)
function Dao:Add(entity)
	local asTable = entity:toTable()
	asTable['id'] = nil
	Logging:Trace("Dao.Add(%s) : %s", entity.id, Util.Objects.ToString(asTable))
	self.module:SetDbValue(self.db, entity.id, asTable)
end

-- R(ead)
function Dao:Get(id)
	return self:Reconstitute(id, self.db[id])
end

-- U(pdate)
function Dao:Update(entity, attr)
	local key = self.Key(entity, attr)
	self.module:SetDbValue(
			self.db,
			key,
			entity:toTable()[attr]
	)
end

-- D(elete)
function Dao:Remove(entity)
	Logging:Trace("Dao.Remove(%s)", entity.id)
	self.module:SetDbValue(self.db, entity.id, nil)
end


--- @class Lists.ConfigurationDao
local ConfigurationDao = AddOn.Package('Lists'):Class('ConfigurationDao', Dao)
function ConfigurationDao:initialize(module)
	Dao.initialize(self, module, module.db.factionrealm.configurations, Configuration)
end

--- @class Lists.ListDao
local ListDao = AddOn.Package('Lists'):Class('ListDao', Dao)
function ListDao:initialize(module)
	Dao.initialize(self, module, module.db.factionrealm.lists, List)
end

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
	self:InitializeDao()
end

function Lists:InitializeDao()
	--- @type Lists.ConfigurationDao
	self.Configuration = ConfigurationDao(self)
	--- @type Lists.ListDao
	self.List = ListDao(self)
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

-- YES, you need to copy the backing db elements... otherwise, mutations occur without explicit persistence

--- @return table<string, Models.List.Configuration>
function Lists:Configurations()
	Logging:Debug("Configurations()")
	return Util(self.Configuration.db)
			:Copy()
			:Map(
				function(config, id)
					return self.Configuration:Reconstitute(id, config)
				end,
				true
			)
			:Sort(function(a, b) return a.name < b.name end)()
end

--- @return table<string, Models.List.List>
function Lists:Lists(configId)
	Logging:Debug("Lists(%s)", tostring(configId))
	return Util(self.List.db)
			:Copy()
			:Filter(
				function(list)
					return Util.Objects.Equals(list.configId, configId)
				end
			)
			:Map(
				function(list, id)
					return self.List:Reconstitute(id, list)
				end,
				true
			)
			:Sort(function(a, b) return a.name < b.name end)()
end

function Lists:UnassignedEquipmentLocations(configId)
	Logging:Debug("UnassignedEquipmentLocations(%s)", tostring(configId))
	local assigned =
		Util(self.List.db)
			:Copy()
			:Filter(
				function(list)
					return Util.Objects.Equals(list.configId, configId)
				end
			)
			:Map(
				function(list)
					return list.equipment
				end
			)
			:Values():Flatten()()

	return Util(C.EquipmentLocations):Keys():CopyExceptWhere(false, unpack(assigned))()
end


function ConfigurationDao.Create()
	local uuid, name = UUID(), format("%s (%s)", L["configuration"], DateFormat.Full:format(Date()))
	Logging:Trace("ConfigurationDao.Create() : %s, %s", tostring(uuid), tostring(name))
	local configuration = Configuration(uuid, name)
	configuration:GrantPermissions(Player:Get("player").guid, Configuration.Permissions.Owner)
	return configuration
end

function ListDao.Create(configId)
	local uuid, name = UUID(), format("%s (%s)", L["list"], DateFormat.Full:format(Date()))
	Logging:Trace("ListDao.Create() : %s, %s, %s", tostring(configId), tostring(uuid), tostring(name))
	return List(configId, uuid, name)
end
