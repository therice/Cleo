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
--- @type Models.Player
local Player = AddOn.Package('Models').Player

--- @class Lists
local Lists = AddOn:NewModule('Lists', "AceBucket-3.0", "AceTimer-3.0")

--- @class Lists.Dao
local Dao = AddOn.Package('Lists'):Class('Dao')
function Dao:initialize(module, db)
	self.module = module
	self.db = db
end

--- @class Lists.ConfigurationDao
local ConfigurationDao = AddOn.Package('Lists'):Class('ConfigurationDao', Dao)
function ConfigurationDao:initialize(module)
	Dao.initialize(self, module, module.db.factionrealm.configurations)
end

--- @class Lists.ListDao
local ListDao = AddOn.Package('Lists'):Class('ListDao', Dao)
function ListDao:initialize(module)
	Dao.initialize(self, module, module.db.factionrealm.lists)
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
	--- @type Lists.ConfigurationDao
	self.Configuration = ConfigurationDao(self)
	--- @type Lists.Dao
	--self.List = ListDao(self)
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
	Logging:Trace("ConfigTableChanged() : '%s", Util.Objects.ToString(msg))
end

function Lists:LaunchpadSupplement()
	return L["lists"], function(container) self:LayoutInterface(container) end , false
end

function Lists:Configurations()
	Logging:Debug("Configurations() : %s", Util.Objects.ToString(self.db))

	local configs = {}
	for id, attrs in pairs(self.db.factionrealm.configurations) do
		Util.Tables.Push(configs, self.Configuration.Reconstitute(id, attrs))
	end

	Util.Tables.Sort(
		configs,
		function(a, b) return a.name < b.name end
	)
	return configs
end


function ConfigurationDao.Key(configuration, attr)
	return configuration.id .. '.' .. attr
end

function ConfigurationDao.Create()
	local uuid, name =
		Util.UUID.UUID(), format("%s (%s)", L["configuration"], DateFormat.Full:format(Date()))
	Logging:Trace("Configuration.Create() : %s, %s", tostring(uuid), tostring(name))
	local configuration = Configuration(uuid, name)
	configuration:GrantPermissions(Player:Get("player").guid, Configuration.Permissions.Owner)
	return configuration
end

function ConfigurationDao.Reconstitute(uuid, attrs)
	local configuration = Configuration:reconstitute(attrs)
	configuration.id = uuid
	Logging:Trace("Configuration.Reconstitute(%s) : %s", tostring(uuid), Util.Objects.ToString(configuration:toTable()))
	return configuration
end

-- C(reate)
function ConfigurationDao:Add(configuration)
	local asTable = configuration:toTable()
	asTable['id'] = nil
	Logging:Trace("Configuration.Add(%s) : %s", configuration.id, Util.Objects.ToString(asTable))
	self.module:SetDbValue(self.db, configuration.id, asTable)
end

-- R(ead)
function ConfigurationDao:Get(id)
	return self.Reconstitute(id, self.db[id])
end

-- U(pdate)
function ConfigurationDao:Update(configuration, attr)
	local key = self.Key(configuration, attr)
	self.module:SetDbValue(
		self.db,
		key,
		configuration:toTable()[attr]
	)
end

-- D(elete)
function ConfigurationDao:Remove(configuration)
	Logging:Trace("Configuration.Remove(%s)", configuration.id)
	self.module:SetDbValue(self.db, configuration.id, nil)
end


function ListDao.Key(list, attr)
	return list.id .. '.' .. attr
end
