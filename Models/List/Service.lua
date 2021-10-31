--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type Models.List.Configuration
local Configuration = AddOn.Package('Models.List').Configuration
--- @type Models.List.ConfigurationDao
local ConfigurationDao = AddOn.Package('Models.List').ConfigurationDao
--- @type Models.List.List
local List = AddOn.Package('Models.List').List
--- @type Models.List.ListDao
local ListDao = AddOn.Package('Models.List').ListDao
--- @type Models.Player
local Player = AddOn.Package('Models').Player
--- @type Models.Referenceable
local Referenceable = AddOn.Require('Models.Referenceable')
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

local function Dao(self, class)
	if class == Configuration then
		return self.Configuration
	elseif class == List then
		return self.List
	else
		error(format("Invalid '%s' for registering callbacks", tostring(class)))
	end
end

function Service:RegisterCallbacks(target, callbacks)
	for class, eventFns in pairs(callbacks) do
		local dao = Dao(self, class)
		for event, fn in pairs(eventFns) do
			dao.RegisterCallback(target, event, fn)
		end
	end
end

function Service:UnregisterCallbacks(target, callbacks)
	for class, events in pairs(callbacks) do
		local dao = Dao(self, class)
		for _, event in pairs(events) do
			dao.UnregisterCallback(target, event)
		end
	end
end

function Service:UnregisterAllCallbacks(target)
	for _, class in pairs({Configuration, List}) do
		Dao(self, class).UnregisterAllCallbacks(target)
	end
end

--- @return table<string, Models.List.Configuration>
function Service:Configurations(active, default)
	return self.Configuration:GetAll(
		function(config)
			local select = true

			-- nil means ignore the filter
			if not Util.Objects.IsNil(active) then
				if active then
					select = (config.status == Configuration.Status.Active)
				else
					select = (config.status == Configuration.Status.Inactive)
				end
			end

			-- nil means ignore the filter
			if not Util.Objects.IsNil(default) then
				select = select and (config.default == default)
			end

			return select
		end
	)
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

function Service:ToggleDefaultConfiguration(configId, default)
	local configs = self:Configurations()
	local config = configs[configId]

	if config then
		-- only flip state (and others) if not the specified value
		if config.default ~= default then
			-- update the specified configuration to specified value
			config.default = default
			self.Configuration:Update(config, 'default')

			-- only need to continue if default was set to true
			if default then
				-- flip the current default configuration to not
				for id, c in pairs(configs) do
					if not Util.Strings.Equal(id, configId) and c.default then
						c.default = false
						self.Configuration:Update(c, 'default')
					end
				end
			end
		end
	end

	return configs
end

-- there are a bunch of assumptions in this function. if violated, you're going to have a bad time
-- specifically, the reference is to an instance of a class which is handled by this service and
-- supports Referenceable (along with expected attributes)
--
-- if there are keys (number or not) in the passed refs table, they are retained in the returned result and the
-- resolved references will be their value
--
-- if a reference cannot be found, a nil object will be inserted instead. if there are keys, this will result
-- in a sparse table (e.g. reference at index 3 cannot be found => {ref_1, ref_2, [4]=ref_3})
function Service:LoadRefs(refs)
	Logging:Trace("LoadRefs() : %s", Util.Objects.ToString(refs))

	local function resolveRef(ref)
		Logging:Trace("resolveRef() : %s", Util.Objects.ToString(ref))
		if ref then
			local instance = Referenceable.FromRef(ref)
			Logging:Trace("resolveRef(%s)", tostring(ref.id))
			if instance then
				Logging:Trace("resolveRef(%s) : resolved to %s", instance.id, instance.clazz.name)
				if Util.Objects.IsInstanceOf(instance, Configuration) then
					return self.Configuration:Get(instance.id)
				elseif Util.Objects.IsInstanceOf(instance, List) then
					return self.List:Get(instance.id)
				else
					Logging:Warn("resolveRef(%s) : referenced class is not supported", instance.id, instance.clazz.name)
				end
			else
				Logging:Warn("resolveRef(%s) : reference could not be resolved", tostring(ref.id))
			end
		end

		return nil
	end

	local loaded = {}

	for key, ref in pairs(refs) do
		if Util.Objects.IsTable(ref) then
			-- if it's a list, it's the actual reference
			if not Util.Tables.IsList(ref) then
				Util.Tables.Insert(loaded, key, resolveRef(ref))
			-- otherwise it is a collection of references
			else
				Util.Tables.Insert(loaded, key, self:LoadRefs(ref))
			end
		end
	end

	return loaded
end

function Service:LoadAuditRefs(auditRef)
	local config, list = nil, nil
	if Util.Objects.IsInstanceOf(auditRef, AddOn.Package('Models.Audit').TrafficRecord) then
		if auditRef.config then
			config = self.Configuration:Get(auditRef.config.id)
			if auditRef.list then
				list = self.List:Get(auditRef.list.id)
			end
		end
	end

	return config, list
end

-- idOrConfig can be an instance of Configuration or Configuration Id (string)
--- @return Models.List.ActiveConfiguration
function Service:Activate(idOrConfig)
	local config =
		Util.Objects.IsInstanceOf(idOrConfig, Configuration) and
			idOrConfig or
			self.Configuration:Get(idOrConfig)

	if not config then
		error(format("No configuration found with id ='%d'", tostring(idOrConfig)))
	end

	local lists = self:Lists(config.id)
	if not lists or Util.Tables.Count(lists) == 0 then
		error(format("No lists found with configuration id ='%s'", config.id))
	end

	return ActiveConfiguration(self, config, lists)
end

function ActiveConfiguration:initialize(service, config, lists)
	--- @type Models.List.Service
	self.service = service
	--- @type Models.List.Configuration
	self.config = config
	-- Players who are not currently in the raid do not move up or down in the lists.
	--- @type table<string, Models.List.List>
	self.lists = lists
	-- create a copy of each list and clear the players priority
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

function ActiveConfiguration:__tostring()
	return format("%s (%s)", self.config.name, self.config.id)
end
--- @return table<string, Models.List.List> the list in it's original state when activated
function ActiveConfiguration:GetOriginalList(listId)
	return self.lists[listId]
end

--- @return table<string, Models.List.List> the list in it's current form as a result of mutations (players add, loot given, etc.)
function ActiveConfiguration:GetActiveList(listId)
	return self.listsActive[listId]
end

-- returns a table with following contents, with the following potential attributes
-- v (table) => {verified = result (boolean), ah = active hash (string), ch = comparison hash (string)}
-- lid (string) => id for the list
--
-- [1] = 'v' for configuration
-- [2] = lists results (table with 3 entries)
--  [1] (present)   = table of 'lid' => 'v'
--  [2] (missing)   = table of 'lid' => list ids present in active config, but missing in passed lists
--  [3] (extra)     = table of 'lid' => list ids present in passed lists, but missing in active config
function ActiveConfiguration:Verify(config, lists)
	local verification = {}
	-- configuration 1st
	-- {verified, active hash (ah), comparison hash (ch)}
	local verified, ah, ch = self.config:Verify(config)
	Util.Tables.Push(verification, {verified = verified, ah = ah, ch = ch})
	-- only go through lists if configuration was verified
	-- as lists are bound to a configuration and all bets are off if config
	-- is not verified
	if verified then
		-- lvs - id(s) to verification of ones which are present in both self.lists and lists
		-- missing - id(s) of ones which are present in self.lists, but missing in lists
		-- extra - id(s) of ones which are present in lists, but missing in self.lists
		local lvs, missing, extra = {}, {}, {}

		for _, lref in pairs(lists) do
			local alist = self.lists[lref.id]
			if not alist then
				Util.Tables.Push(extra, lref.id)
			else
				verified, ah, ch = alist:Verify(lref)
				Util.Tables.Insert(lvs, alist.id, { verified = verified, ah = ah, ch = ch})
			end
		end

		for id, _ in pairs(self.lists) do
			if not Util.Tables.FindFn(lists, function(r) return r.id == id end) then
				Util.Tables.Push(missing, id)
			end
		end

		Util.Tables.Push(verification, {lvs, missing, extra})
	end

	return verification
end

--- @param lists table<string,Models.List.List>
local function EnsurePresent(lists, player)
	local addedTo = {}

	for listId, list in pairs(lists) do
		if not list:ContainsPlayer(player) then
			Logging:Warn(
				"EnsurePresent(%s, %s) : Missing from original on list - Adding",
				tostring(player), listId
			)
			list:AddPlayer(player)
			Util.Tables.Push(addedTo, listId)
		end
	end

	return addedTo
end

-- this handles events related top players joining and leaving the party
-- only time this mutates the priority list is if the player is not present on a list
-- and configuration dictates that they are added
function ActiveConfiguration:OnPlayerEvent(player, joined)
	player = Player.Resolve(player)
	Logging:Trace("OnPlayerEvent(%s, %s)", tostring(player), tostring(joined))

	-- make sure player is present on original list(s)
	-- todo : (maybe) allow for a configuration setting on how to insert them
	if joined then
		local addedTo = EnsurePresent(self.lists, player)
		-- persist any lists were the player was added
		for _, listId in pairs(addedTo) do
			self.service.List:Update(
				self.lists[listId],
				'players'
			)
		end
	end

	local prios = {}
	-- based upon joining or leaving, capture current priority from appropriate lists
	for listId, list in pairs(joined and self.lists or self.listsActive) do
		prios[listId] = list:GetPlayerPriority(player) or -1
	end

	Logging:Trace("OnPlayerEvent(%s, %s) : Working Priorities %s",  tostring(player), tostring(joined), Util.Objects.ToString(prios))

	--- @type Models.List.List
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

--- @return string, number, number, number, number :
---     list id, active prio (before), active prio (after), original prio (before), orginal prio (after)
function ActiveConfiguration:OnLootEvent(player, equipment)
	player = Player.Resolve(player)
	Logging:Debug("OnLootEvent(%s, %s)", tostring(player), tostring(equipment))

	-- locate the current active list for the equipment
	local listId, list = self:GetActiveListByEquipment(equipment)

	if (listId and list) then
		Logging:Trace(
			"OnLootEvent(%s, %s) : Located List(%s, '%s'), 'suiciding' player",
			tostring(player), tostring(equipment), tostring(listId), list.name
		)
		-- 'suicide' the player on active list and then apply to master list
		local apb = list:GetPlayerPriority(player, true)
		list:DropPlayer(player)
		local apa = list:GetPlayerPriority(player, true)
		-- apply the adjusted priorities back to master (original) list
		local origList = self.lists[listId]
		local opb, opa

		Util.Functions.try(
			function()
				opb = origList:GetPlayerPriority(player, true)
				origList:ApplyPlayerPriorities(list:GetPlayers())
				opa = origList:GetPlayerPriority(player, true)
			end
		).finally(
			function()
				-- persist the list now
				self.service.List:Update(
					origList,
					'players'
				)
			end
		)

		Logging:Trace(
			"OnLootEvent(%s) : %s -> %s [Active] %s -> %s [Original]",
			listId,
			tostring(apb), tostring(apa),
			tostring(opb), tostring(opa)
		)

		return listId, apb, apa, opb, opa
	else
		Logging:Error("OnLootEvent(%s, %s) : No applicable list found - no change in priority will be applied", player.guid, tostring(equipment))
	end
end

local function GetListByEquipment(lists, equipment)
	return Util.Tables.FindFn(
		lists,
		function(list)
			return list:AppliesToEquipment(equipment)
		end
	)
end

--- @return Models.List.List
function ActiveConfiguration:GetOverallListByEquipment(equipment)
	return GetListByEquipment(self.lists, equipment)
end

--- @return string, Models.List.List
function ActiveConfiguration:GetActiveListByEquipment(equipment)
	return GetListByEquipment(self.listsActive, equipment)
end
