--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type Models.SemanticVersion
local SemanticVersion = AddOn.Package('Models').SemanticVersion
--- @type Models.Versioned
local Versioned = AddOn.Package('Models').Versioned
--- @type LibUtil.Bitfield.Bitfield
local Bitfield = Util.Bitfield.Bitfield
--- @type Models.Player
local Player = AddOn.ImportPackage('Models').Player
--- @type Models.Dao
local Dao = AddOn.Package('Models').Dao
local UUID = Util.UUID.UUID
--- @type Models.Date
local Date = AddOn.Package('Models').Date
--- @type Models.DateFormat
local DateFormat = AddOn.Package('Models').DateFormat
--- @type Models.Hashable
local Hashable = AddOn.Require('Models.Hashable')
--- @type Models.Referenceable
local Referenceable = AddOn.Require('Models.Referenceable')

--- @class Models.List.Configuration
local Configuration =
	AddOn.Package('Models.List'):Class('Configuration', Versioned)
		:include(Hashable.Includable('sha256'))
		:include(Referenceable.Includable())
Versioned.ExcludeAttrsInHash(Configuration)
Versioned.IncludeAttrsInRef(Configuration)
Configuration.static:AddTriggers("name", "permissions", "status", "default")
Configuration.static:IncludeAttrsInRef("id", {hash = function(self) return self:hash() end})

local Version = SemanticVersion(1, 0, 0)
local None = "None"
-- todo : do we really need 'None'? its one use is tracking previous owner/admins who have been removed
Configuration.Permissions = {
	[None]      =   0x01,
	Owner       =   0x02,
	Admin       =   0x04,
}

Configuration.Status = {
	Active      =   1,
	Inactive    =   2,
}

--- @class Models.List.Permission
local Permission = AddOn.Package('Models.List'):Class('Permission', Bitfield)
function Permission:initialize()
	Bitfield.initialize(self, Configuration.Permissions.None)
end

function Permission:__tostring()
	local perms = {}

	for p, bit in pairs(Configuration.Permissions) do
		if p ~= None and self:Enabled(bit) then
			Util.Tables.Push(perms, p)
		end
	end

	if Util.Tables.Count(perms) == 0 then
		Util.Tables.Push(perms, None)
	end

	return Util.Strings.Join(', ', perms)
end

function Configuration:initialize(id, name)
	Versioned.initialize(self, Version)
	self.id = id
	self.name = name
	--- @type table<string, Models.List.Permission>
	self.permissions = {}
	self.status = self.Status.Inactive
	self.default = false
end

function Configuration:afterReconstitute(instance)
	instance = Configuration.super:afterReconstitute(instance)
	instance.permissions = Util.Tables.Map(
		Util.Tables.Copy(instance.permissions),
		function(p)
			return Permission:reconstitute(p)
		end
	)
	return instance
end

local function PlayerId(player)
	player = Player.Resolve(player)
	return player.guid
end

function Configuration:GrantPermissions(player, ...)
	local playerId = PlayerId(player)

	if not Util.Tables.ContainsKey(self.permissions, playerId) then
		self.permissions[playerId] = Permission()
	end

	local current = self.permissions[playerId]
	current:Enable(...)
end

function Configuration:RevokePermissions(player, ...)
	local playerId = PlayerId(player)

	if not Util.Tables.ContainsKey(self.permissions, playerId) then
		return
	end

	local current = self.permissions[playerId]
	current:Disable(...)
end

function Configuration:PlayersWithPermission(p)
	local players = {}
	for player, permission in pairs(self.permissions) do
		Logging:Trace("GetPlayersWithPermissions() : Evaluating %s, %s", tostring(player), tostring(permission))
		if permission:Enabled(p) then
			Util.Tables.Push(players, Player:Get(player))
		end
	end
	return players
end

function Configuration:IsAdminOrOwner(p)
	p = Player.Resolve(p)
	return (p == self:GetOwner()) or Util.Tables.ContainsValue(self:GetAdministrators(), p)
end

function Configuration:GetOwner()
	local players = self:PlayersWithPermission(Configuration.Permissions.Owner)
	return #players == 1 and players[1] or nil
end

function Configuration:GetAdministrators()
	return self:PlayersWithPermission(Configuration.Permissions.Admin)
end

function Configuration:SetOwner(player)
	-- one and only one owner, need to revoke
	local players = self:PlayersWithPermission(Configuration.Permissions.Owner)
	for _, p in pairs(players) do
		self:RevokePermissions(p, Configuration.Permissions.Owner)
	end

	self:GrantPermissions(player, Configuration.Permissions.Owner)
end

function Configuration:__tostring()
	return self.name
end

function Configuration.CreateInstance(...)
	local uuid, name = UUID(), format("%s (%s)", L["configuration"], DateFormat.Full:format(Date()))
	Logging:Trace("Configuration.Create() : %s, %s", tostring(uuid), tostring(name))
	local configuration = Configuration(uuid, name)
	configuration:GrantPermissions(Player:Get("player").guid, Configuration.Permissions.Owner)
	return configuration
end

--- @class Models.List.ConfigurationDao
local ConfigurationDao = AddOn.Package('Models.List'):Class('ConfigurationDao', Dao)
function ConfigurationDao:initialize(module, db)
	Dao.initialize(self, module, db, Configuration)
end
