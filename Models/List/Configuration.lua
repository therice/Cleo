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
Configuration.static:AddTriggers("name", "permissions", "alts", "status", "default")
Configuration.static:IncludeAttrsInRef("id", {hash = function(self) return self:hash() end})

local Version = SemanticVersion(1, 0, 0)
local None = "None"
-- todo : do we really need 'None'? its one use is tracking previous owner/admins who have been removed
Configuration.Permissions = {
	None        =   0x01,
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
	--- @type table<string, table<Models.Player>>
	self.alts = {}
	self.status = self.Status.Inactive
	self.default = false
end

function Configuration:toTable()
	local t = Configuration.super.toTable(self)
	t['alts'] =
		Util(self.alts)
			-- this creates a copy, but values point to original
			:MapKeys(function(_, p) return Player.StripGuidPrefix(p) end, true)
			:Map(
				function(alts)
					-- need to copy the values, as it will be pointer to original
					return Util(alts):Copy()
							:Map(function(a) return a:ForTransmit() end)
							:Sort(function(a1, a2) return a1 < a2 end)()
				end
			):Sort2(false)()

	return t
end

local MaxResolutionAttempts = 3
local function resolve(self, guids, attempt)
	attempt = Util.Objects.Default(attempt, 1)
	local unresolved = {}

	for main, alts in pairs(guids) do
		for _, alt in pairs(alts) do
			local player = Player:Get(alt)
			if player then
				local t = self.alts[main]
				local index, _ = Util.Tables.FindFn(t, function(p) return p.guid == player.guid end)
				if index then
					t[index] = player
					Logging:Trace("resolve(%s) : resolved %s", self.id, alt)
				else
					Logging:Warn("resolve(%s) : couldn't locate %s in 'alts'", alt)
				end
			else
				if not unresolved[main] then
					unresolved[main] = {}
				end
				Util.Tables.Push(unresolved[main], alt)
			end
		end
	end

	local remaining = Util.Tables.Count(unresolved)
	Logging:Debug("resolve(%s) : %d outstanding resolutions remaining", self.id, remaining)

	if remaining > 0 then
		if attempt + 1 > MaxResolutionAttempts then
			Logging:Warn("resolve(%s) : max resolution attempts exceeded", self.id)
		else
			AddOn:ScheduleTimer(resolve, 3, self, unresolved, attempt + 1)
		end
	end
end

function Configuration:afterReconstitute(instance)
	instance = Configuration.super:afterReconstitute(instance)
	instance.permissions = Util.Tables.Copy(instance.permissions,
		function(p)
			return Permission:reconstitute(p)
		end
	)

	local unresolved = {}

	instance.alts =
		Util(instance.alts)
			-- this creates a copy, but values point to original
			:MapKeys(
				function(_, main)
					-- attempt to resolve the player
					-- if resolved then use the GUID
					-- otherwise, 'main' is a stripped GUID so parse it to expected format
					local player = Player:Get(main)
					return player and player.guid or Player.ParseGuid(main)
				end, true
			)
			:Map(
				function(alts, main)
					return
						-- need to copy the values, as it will be pointer to original
						Util(alts):Copy()
							:Map(
								function(alt)
									local player = Player:Get(alt)
									if not player then
										-- couldn't be resolved, add it to list to be processed later
										-- main (guid) => alts (table<guid>)
										player = Player.Unknown(alt)
										if not unresolved[main] then
											unresolved[main] = {}
										end
										Util.Tables.Push(unresolved[main], alt)
									end

									return player
								end
							)
							:Sort(function(a1, a2) return a1.guid < a2.guid end)()
				end, true
			):Sort2(false)()

	if Util.Tables.Count(unresolved) > 0 then
		Logging:Warn("Configuration:afterReconstitute() : there are unresolved players, scheduling resolution")
		AddOn:ScheduleTimer(resolve, 5, instance, unresolved, 1)
	end

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

--- @param p Models.Player the player to evaluate, if nil will use the current player
function Configuration:IsOwner(p)
	p = p and Player.Resolve(p) or AddOn.player
	return (p == self:GetOwner())
end

--- @param p Models.Player the player to evaluate, if nil will use the current player
function Configuration:IsAdmin(p)
	p = p and Player.Resolve(p) or AddOn.player
	return Util.Tables.ContainsValue(self:GetAdministrators(), p)
end

--- @param p Models.Player the player to evaluate, if nil will use the current player
function Configuration:IsAdminOrOwner(p)
	p = p and Player.Resolve(p) or AddOn.player
	return self:IsOwner(p) or self:IsAdmin(p)
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

function Configuration:SetAlternates(player, ...)
	player = Player.Resolve(player)
	local alts = {}
	for _, p in Util.Objects.Each(Util.Tables.Temp(...)) do
		Util.Tables.Push(alts, Player.Resolve(p))
	end

	-- sort both keys (mains) and values (alts)  to retain ordering
	self.alts[player.guid] = Util.Tables.Sort(alts, function(p1, p2) return p1.guid < p2.guid end)
	self.alts = Util.Tables.Sort2(self.alts, false)
end


--- @param player string|Models.Player
--- @return table<string, table<Models.Player>>
function Configuration:GetAlternates(player)
	if Util.Objects.IsSet(player) then
		player = player and Player.Resolve(player) or nil
		return player and self.alts[player.guid] or {}
	end

	return self.alts
end

--- @return boolean
function Configuration:HasAlternates(player)
	return Util.Tables.IsSet(self:GetAlternates(player))
end

--- resolves specified player with respect to any configured alts
--- if no alts are configured, the passed player will be resolved as a Player
--- if alts are configured and the passed player is a main, the passed player will be resolved as a Player
--- if alts are configured and the passed players is an alt, the passed player will be resolved to the main as a Player
--- @param player string|Models.Player
function Configuration:ResolvePlayer(player)
	player = player and Player.Resolve(player) or nil
	if player and Util.Tables.Count(self.alts) > 0 then
		-- the player is not a main
		if not self.alts[player.guid] then
			-- go through the alts looking for the player in an ALT list
			for main, alts in pairs(self.alts) do
				if Util.Tables.ContainsValue(alts, player) then
					player = Player.Resolve(main)
					break
				end
			end
		end
	end

	return player
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
