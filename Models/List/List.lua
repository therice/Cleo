--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type Models.Player
local Player = AddOn.Package('Models').Player
--- @type Models.Dao
local Dao = AddOn.Package('Models').Dao
local UUID = Util.UUID.UUID
--- @type Models.Date
local Date = AddOn.Package('Models').Date
--- @type Models.DateFormat
local DateFormat = AddOn.Package('Models').DateFormat
--- @type Models.SemanticVersion
local SemanticVersion = AddOn.Package('Models').SemanticVersion
--- @type Models.Versioned
local Versioned = AddOn.Package('Models').Versioned
--- @type Models.Hashable
local Hashable = AddOn.Require('Models.Hashable')
--- @type Models.Referenceable
local Referenceable = AddOn.Require('Models.Referenceable')

local Version = SemanticVersion(1, 0, 0)

--- @class Models.List.List
local List =
	AddOn.Package('Models.List'):Class('List', Versioned)
		:include(Hashable.Includable('sha256'))
		:include(Referenceable.Includable())
Versioned.ExcludeAttrsInHash(List)
Versioned.IncludeAttrsInRef(List)
List.static:AddTriggers("name", "equipment", "players")
List.static:IncludeAttrsInRef("id", {hash = function(self) return self:hash() end})

function List:initialize(configId, id, name)
	Versioned.initialize(self, Version)
	self.configId = configId
	self.id = id
	self.name = name
	--- @type table<number, string> equipment types/locations to which list applies (e.g. INVTYPE_HEAD)
	self.equipment = {}
	-- a sparse array
	--- @type table<string, Models.Player>
	self.players = {}
end

local PlayerSerializer = function(p) return p:ForTransmit() end
--- we only want to serialize the player's stripped guid which is enough
function List:toTable()
	local t = List.super.toTable(self)
	t['players'] = self:GetPlayers(true, true)
	return t
end

local MaxResolutionAttempts = 3
local function resolve(self, guids, attempt)
	attempt = Util.Objects.Default(attempt, 1)
	local unresolved = {}

	for priority, guid in pairs(guids) do
		local player = Player:Get(guid)
		if player then
			self.players[priority] = player
			Logging:Trace("resolve(%s) : resolved %s at %d", self.id, guid, priority)
		else
			unresolved[priority] = guid
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

-- player's will be a table with stripped guids
function List:afterReconstitute(instance)
	instance = List.super:afterReconstitute(instance)
	local unresolved = {}

	instance.players =
		Util(instance.players)
			:Copy()
			:Map(
				function(p, priority)
					local player = Player:Get(p)
					if not player then
						player = Player.Unknown(p)
						unresolved[priority] = p
					end
					return player
				end, true
			)()

	if Util.Tables.Count(unresolved) > 0 then
		Logging:Warn("List:afterReconstitute() : there are unresolved players, scheduling resolution")
		AddOn:ScheduleTimer(resolve, 5, instance, unresolved, 1)
	end

	return instance
end

function List:AddEquipment(...)
	self.equipment = Util(self.equipment):Merge({...}, true):Sort()()
end

function List:RemoveEquipment(...)
	self.equipment = Util(self.equipment):CopyExceptWhere(false, ...):Sort()()
end

--- @param equipment string the equipment slot (e.g. INVTYPE_HEAD)
--- @return Models.List.List
function List:AppliesToEquipment(equipment)
	-- Logging:Trace("AppliesToEquipment(%s)", tostring(equipment))
	return Util.Tables.ContainsValue(self.equipment, equipment)
end

function List:GetEquipment(withNames)
	withNames = withNames or false
	if withNames then
		return Util.Tables.Flip(self.equipment, function(slot) return C.EquipmentLocations[slot] end)
	else
		return self.equipment
	end
end

function List:ClearPlayers()
	self.players = { }
end

function List:GetPlayerCount()
	return Util.Tables.Count(self.players)
end

--- warning - this returns a reference to actual list if no parameters are specified or asTable is false
--- @param asTable boolean indicates if a copy of players should be returned as a table
--- @param normalizePriorities boolean true results in priorities being normalized to 1 .. N, false returns original priorities
function List:GetPlayers(asTable, normalizePriorities)
	-- return asTable and self.players:toTable(PlayerSerializer) or self.players
	normalizePriorities = Util.Objects.Default(normalizePriorities, false)

	if asTable then
		if normalizePriorities then
			local players, index = {}, 1
			for _, player in Util.Tables.Sparse.ipairs(self.players) do
				players[index] = PlayerSerializer(player)
				index = index + 1
			end
			-- Logging:Trace("GetPlayers() : %s", Util.Objects.ToString(players))
			return players
		else
			return Util(self.players):Copy():Map(PlayerSerializer)()
		end
	else
		return self.players
	end
end

function List:GetPlayer(priority)
	return self.players[priority]
end

function List:GetPlayerPriority(player, relative)
	player = Player.Resolve(player)
	relative = Util.Objects.Default(relative, false)

	Logging:Trace(
		"GetPlayerPriority(%s, %s) : %s",
		tostring(player), tostring(relative),
		Util.Objects.ToString(Util.Tables.Copy(self.players, function(p) return p:GetName() end))
	)

	local priority

	if relative then
		local index = 1
		local flipped =
			Util(self.players)
				:Flip(
					function()
						local key = index
						index = index + 1
						return key
					end
				)()

		_, priority =
			Util.Tables.FindFn(
				flipped,
				function(_, prioPlayer)
					return prioPlayer == player
				end,
				true
			)
	else
		priority, _ = Util.Tables.Find(self.players, player)
	end

	return priority, player
end

function List:AddPlayer(player, priority)
	player = Player.Resolve(player)
	-- if an associated priority and no one in that slot, just set it directly
	if priority and not self.players[priority] then
		self.players[priority] = player
	-- otherwise, insert with respect to existing priorities (potentially shifting others)
	else
		Util.Tables.Insert(self.players, priority, player)
	end
end


local function ReorderPlayers(self, mapper)
	local u = Util.Tables.New()
	for prio, player in Util.Tables.Sparse.ipairs(self.players) do
		local key, value = mapper(prio, player)
		u[key] = value
	end
	self.players = u
end

--- @param player Models.Player player to remove
--- @param shift boolean should players with a lower priority (higher #) have their priority adjusted up (lower #)
function List:RemovePlayer(player, shift)
	shift = Util.Objects.Default(shift, true)
	Logging:Trace("RemovePlayer(%s, %s)", tostring(player), tostring(shift))

	local priority, p = self:GetPlayerPriority(player)
	Logging:Trace("RemovePlayer(%s) : priority %d", tostring(player), tostring(priority))

	if priority then
		-- Logging:Debug("%s", Util.Objects.ToString(self:GetPlayers(true, false)))
		self.players[priority] = nil
		-- Logging:Debug("%s", Util.Objects.ToString(self:GetPlayers(true, false)))
		if shift then
			ReorderPlayers(
				self,
				function(prio, p)
					return Util.Objects.Check(prio > priority, prio - 1, prio), p
				end
			)
			Logging:Trace("%s", Util.Objects.ToString(self:GetPlayers(true, false)))
		end

		return priority, p
	end
end

--- this will drop a player ('suicide') from their current priority to bottom priority
--- all players with a lower priority will be promoted into the previous priority on the list
--- the dropped player will be added back with lowest priority
--- @param player Models.Player player to drop
function List:DropPlayer(player)
	local priority, _ = self:RemovePlayer(player, false)

	if priority then
		ReorderPlayers(
				self,
				function(prio, p)
					Logging:Trace("DropPlayer() : Evaluating %s [%d]", tostring(p), prio)
					local newPriority = prio
					if prio > priority then
						newPriority = priority
						priority = prio
					end

					Logging:Trace("DropPlayer() : Result %s [%d => %d]", tostring(p), prio, newPriority)

					return newPriority, p
				end
		)
		self:AddPlayer(player, priority)
	end
end

function List:ApplyPlayerPriorities(priorities)
	ReorderPlayers(
		self,
		function(prio, p)
			Logging:Trace("ApplyPlayerPriorities() : Evaluating %s [current=%d]", tostring(p), prio)
			local new = priorities[prio]
			if new and (new ~= p) then
				Logging:Trace("ApplyPlayerPriorities() : Mapped %s [priority=%d]", tostring(new), prio)
				return prio, new
			else
				Logging:Trace("ApplyPlayerPriorities() : Unchanged [priority=%d]", prio)
				return prio, p
			end
		end
	)
end

function List:ContainsPlayer(player)
	return Util.Tables.ContainsValue(self.players, Player.Resolve(player))
end

function List:SetPlayers(...)
	local count = select("#", ...)
	Logging:Trace("SetPlayers(%d)", count)

	if count >= 0 then
		self:ClearPlayers()
		for i=1, count do
			local p = select(i, ...)
			local player = Player.Resolve(p)
			Logging:Trace("SetPlayers(%d) : %s", i, player:GetName())
			self:AddPlayer(p, i)
		end
	end
end

function List.CreateInstance(configId)
	local uuid, name = UUID(), format("%s (%s)", L["list"], DateFormat.Full:format(Date()))
	Logging:Trace("List.Create() : %s, %s, %s", tostring(configId), tostring(uuid), tostring(name))
	return List(configId, uuid, name)
end


--- @class Models.List.ListDao
local ListDao = AddOn.Package('Models.List'):Class('ListDao', Dao)
function ListDao:initialize(module, db)
	Dao.initialize(self, module, db, List)
end