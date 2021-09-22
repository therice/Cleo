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
	self.db = AddOn.Libs.AceDB:New(AddOn:Qualify('Lists'), Lists.defaults)
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
	Logging:Debug("Configurations()")

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

---- @class Lists.Configuration
Lists.Configuration = { }

function Lists.Configuration.Key(configuration, attr)
	return configuration.id .. '.' .. attr
end

function Lists.Configuration.Create()
	local uuid, name =
		Util.UUID.UUID(), format("%s (%s)", L["configuration"], DateFormat.Full:format(Date()))
	Logging:Trace("Configuration.Create() : %s, %s", tostring(uuid), tostring(name))
	local configuration = Configuration(uuid, name)
	configuration:GrantPermissions(Player:Get("player").guid, Configuration.Permissions.Owner)
	return configuration
end

function Lists.Configuration.Reconstitute(uuid, attrs)
	local configuration = Configuration:reconstitute(attrs)
	configuration.id = uuid
	Logging:Trace("Configuration.Reconstitute(%s) : %s", tostring(uuid), Util.Objects.ToString(configuration:toTable()))
	return configuration
end

function Lists.Configuration.Add(configuration)
	local asTable = configuration:toTable()
	asTable['id'] = nil
	Logging:Trace("Configuration.Add(%s) : %s", configuration.id, Util.Objects.ToString(asTable))
	Lists:SetDbValue(Lists.db.factionrealm.configurations, configuration.id, asTable)
end

function Lists.Configuration.Remove(configuration)
	Logging:Trace("Configuration.Remove(%s)", configuration.id)
	Lists:SetDbValue(Lists.db.factionrealm.configurations, configuration.id, nil)
end

function Lists.Configuration.Update(configuration, attr)
	local key = Lists.Configuration.Key(configuration, attr)
	Lists:SetDbValue(
		Lists.db.factionrealm.configurations,
		key,
		configuration:toTable()[attr]
	)
end