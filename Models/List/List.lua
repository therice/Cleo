--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type LibClass
local Class = LibStub("LibClass-1.0")
--- @type Models.Player
local Player = AddOn.Package('Models').Player
--- @type Models.Dao
local Dao = AddOn.Package('Models').Dao
local UUID = Util.UUID.UUID
--- @type Models.Date
local Date = AddOn.Package('Models').Date
--- @type Models.DateFormat
local DateFormat = AddOn.Package('Models').DateFormat

-- dumb, doing this for a workaround to get native LibClass toTable() functionality
local B = Class("B")
--- @class Models.List.List
local List = AddOn.Package('Models.List'):Class('List', B)
function List:initialize(configId, id, name)
	B.initialize(self)
	self.configId = configId
	self.id = id
	self.name = name
	--- @type table<number, string> equipment types/locations to which list applies (e.g. INVTYPE_HEAD)
	self.equipment = {}
	--- @type table<number, Models.Player>
	-- a sparse array
	self.players = {}
end

local PlayerSerializer =  function(p) return p:ForTransmit() end

--- we only want to serialize the player's stripped guid which is enough
function List:toTable(playerFn)
	local t =  List.super.toTable(self)
	t['players'] = self:GetPlayers(true, true)
	return t
end

-- player's will be a table with stripped guids
function List:afterReconstitute(instance)
	instance.players =
		Util(instance.players)
			:Copy():Map(function(p) return Player:Get(p) end)()
	return instance
end

function List:AddEquipment(...)
	self.equipment = Util(self.equipment):Merge({...}, true)()
end

function List:RemoveEquipment(...)
	self.equipment = Util(self.equipment):CopyExceptWhere(false, ...)()
end

function List:AppliesToEquipment(equipment)
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

function List:GetPlayerPriority(player)
	-- return self.players:IndexOf(Player.Resolve(player))
	return Util.Tables.Find(self.players, Player.Resolve(player))
end

function List:AddPlayer(player, priority)
	player = Player.Resolve(player)
	-- if an associated priority and no one in that slot, just set it directly
	if priority and not self.players[priority] then
		self.players[priority] = player
	-- otherwise, insert with respect to existing prioirties (potentially shifting others)
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

	if count > 0 then
		self:ClearPlayers()
		for i=1, count do
			local p = select(i, ...)
			local player = Player.Resolve(p)
			Logging:Trace("SetPlayers(%d) : %s", i, player:GetName())
			self:AddPlayer(p, i)
		end
	end
end

function List.Create(configId)
	local uuid, name = UUID(), format("%s (%s)", L["list"], DateFormat.Full:format(Date()))
	Logging:Trace("List.Create() : %s, %s, %s", tostring(configId), tostring(uuid), tostring(name))
	return List(configId, uuid, name)
end


--- @class Models.List.ListDao
local ListDao = AddOn.Package('Models.List'):Class('ListDao', Dao)
function ListDao:initialize(module, db)
	Dao.initialize(self, module, db, List)
end