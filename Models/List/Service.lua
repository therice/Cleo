--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type Models.List.ConfigurationDao
local ConfigurationDao = AddOn.Package('Models.List').ConfigurationDao
--- @type Models.List.ListDao
local ListDao = AddOn.Package('Models.List').ListDao
--- @type Models.Player
local Player = AddOn.Package('Models').Player
--- @class Models.List.ActiveConfiguration
local ActiveConfiguration = AddOn.Package('Models.List'):Class('ActiveConfiguration')

--- @class Models.List.Service
local Service = AddOn.Package('Models.List'):Class('Service')
function Service:initialize(configDb, listDb)
	assert(Util.Objects.IsTable(configDb) and #configDb == 2)
	assert(Util.Objects.IsTable(listDb) and #listDb == 2)
	--- @type Models.List.ConfigurationDao
	self.Configuration = ConfigurationDao(configDb[1], configDb[2])
	--- @type Models.List.ListDao
	self.List = ListDao(listDb[1], listDb[2])
end

--- @return table<string, Models.List.Configuration>
function Service:Configurations()
	return self.Configuration:GetAll()
end

--- @return table<string, Models.List.List>
function Service:Lists(configId)
	return self.List:GetAll(
			function(list)
				return Util.Objects.Equals(list.configId, configId)
			end
	)
end

--- @return table<number, string>
function Service:UnassignedEquipmentLocations(configId)
	local assigned =
		Util(self:Lists(configId))
			:Copy()
			:Map(
				function(list)
					return list.equipment
				end
			)
			:Values():Flatten()()

	return Util(C.EquipmentLocations):Keys():CopyExceptWhere(false, unpack(assigned))()
end

function Service:Activate(configId)
	local config = self.Configuration:Get(configId)
	if not config then
		error(format("No configuration found with id ='%d'", configId))
	end
	local lists = self:Lists(configId)
	if not lists or Util.Tables.Count(lists) == 0 then
		error(format("No lists found with configuration id ='%s'", configId))
	end

	return ActiveConfiguration(self, config, lists)
end

function ActiveConfiguration:initialize(service, config, lists)
	self.service = service
	self.config = config
	-- Players who are not currently in the raid do not move up or down in the lists.
	--- @type table<string, Models.List.List>
	self.lists = lists
	-- create a copy of each list and clear the players
	-- as players enter the raid they will be added based upon position in original list
	--- @type table<string, Models.List.List>
	self.listsActive =
		Util(self.lists)
			:Copy()
			:Map(
				function(list)
					local copy = list:clone()
					copy:ClearPlayers()
					return copy
				end
			)()
end

--- @return table<string, Models.List.List> the list in it's original state when activated
function ActiveConfiguration:GetOriginalList(listId)
	return self.lists[listId]
end

--- @return table<string, Models.List.List> the list in it's current form as a result of mutations (players add, loot given, etc.)
function ActiveConfiguration:GetActiveList(listId)
	return self.listsActive[listId]
end

local function EnsurePresent(lists, player)
	for listId, list in pairs(lists) do
		if not list:ContainsPlayer(player) then
			Logging:Warn(
					"EnsurePresent(%s, %s) : Missing from original on list - Adding",
					tostring(player), listId)
			list:AddPlayer(player)
		end
	end
end


function ActiveConfiguration:OnPlayerEvent(player, joined)
	player = Player.Resolve(player)
	Logging:Trace("OnPlayerEvent(%s, %s)", tostring(player), tostring(joined))

	-- make sure player is present on original list(s)
	if joined then EnsurePresent(self.lists, player) end

	local prios = {}
	-- based upon joining or leaving, capture current priority from appropriate lists
	for listId, list in pairs(joined and self.lists or self.listsActive) do
		prios[listId] = list:GetPlayerPriority(player) or -1
	end

	Logging:Trace("OnPlayerEvent(%s, %s) : Working Priorities %s",  tostring(player), tostring(joined), Util.Objects.ToString(prios))

	local list

	for listId, priority in pairs(prios) do
		list = self.listsActive[listId]

		if joined then
			-- don't allow for duplicates from multiple join events for same player
			if list:ContainsPlayer(player) then
				Logging:Warn(
						"OnPlayerEvent(%s, %s, %s) : Already on working list (?duplicate event?) - Ignoring",
						tostring(player), tostring(joined), listId)
				return
			end

			if priority == -1 then
				Logging:Error(
						"OnPlayerEvent(%s, %s, %s) : Couldn't resolve priority, missing from original list?",
						tostring(player), tostring(joined), listId
				)
			else
				Logging:Trace(
						"OnPlayerEvent(%s, %s, %s) : Adding at priority %d",
						tostring(player), tostring(joined), listId, priority
				)

				list:AddPlayer(player, priority)
			end
		else
			if not list:ContainsPlayer(player) then
				Logging:Warn(
						"OnPlayerEvent(%s, %s, %s) : Missing from original list - Ignoring",
						tostring(player), tostring(joined), listId)
				return
			end

			Logging:Trace(
					"OnPlayerEvent(%s, %s, %s) : Removing",
					tostring(player), tostring(joined), listId
			)


			list:RemovePlayer(player, false)
		end
	end
end

function ActiveConfiguration:OnLootEvent(player, equipment)
	player = Player.Resolve(player)
	Logging:Debug("OnLootEvent(%s, %s)", tostring(player), tostring(equipment))

	local listId, list =
		Util.Tables.FindFn(
			self.listsActive,
				function(list) return list:AppliesToEquipment(equipment)
			end
		)

	if (listId and list) then
		Logging:Debug("OnLootEvent(%s, %s) : Located List(%s, '%s'), 'suiciding' player", tostring(player), tostring(equipment), tostring(listId), list.name)
		list:DropPlayer(player)
		self.lists[listId]:ApplyPlayerPriorities(list:GetPlayers())
	else
		Logging:Error("OnLootEvent(%s, %s) : No applicable list found", player.guid, tostring(equipment))
	end
end