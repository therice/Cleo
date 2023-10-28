--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
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

function Service:GetDao(class)
	if Util.Objects.IsString(class) then
		if Util.Strings.Equal(Configuration.name, class) then
			class = Configuration
		elseif Util.Strings.Equal(List.name, class) then
			class = List
		end
	end

	return Dao(self, class)
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

--- @param config Models.List.Configuration
function Service:ToCsv(config)
	local function WithQuotes(v)
		return "\"" .. v .. "\""
	end

	local csv, lists, priorities = {{WithQuotes(L['priority'])}}, self:Lists(config.id), 0
	local ordering, orderingIndex = {}, 1
	for v, _ in Util.Tables.OrderedPairs(Util.Tables.Flip(lists, function(l) return l.name end)) do
		ordering[orderingIndex] = v.id
		orderingIndex = orderingIndex + 1
	end

	for _, listId in pairs(ordering) do
		local list = lists[listId]
		Util.Tables.Push(csv[1], WithQuotes(list.name))
		priorities = math.max(priorities, table.maxn(list.players))
	end

	for index = 2, (priorities + 1) do
		csv[index] = {tostring(index - 1)}
		for _, listId in pairs(ordering) do
			local list = lists[listId]
			local player = list:GetPlayer(index - 1)
			Util.Tables.Push(csv[index], WithQuotes(player and player:GetShortName() or ""))
		end
	end

	return csv
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
	--Logging:Trace("UnassignedEquipmentLocations(assigned) : %s", Util.Objects.ToString(assigned))

	local equipmentLocations = Util(C.EquipmentLocations):Copy()()
	local selfReferencing = ItemUtil:GetCustomItemsSlotIsSelf()
	--Logging:Trace("UnassignedEquipmentLocations(selfReferencing) : %s", Util.Objects.ToString(selfReferencing))
	if selfReferencing and #selfReferencing > 0 then
		for _, item in ipairs(selfReferencing) do
			ItemUtil.QueryItem(
				item,
				function(i)
					equipmentLocations[tostring(item)] = ItemUtil.DisambiguateIfHeroicItem(i)
				end
			)
		end
	end
	--Logging:Trace("UnassignedEquipmentLocations(equipmentLocations) : %s", Util.Objects.ToString(equipmentLocations))

	local unassigned = Util(equipmentLocations):Keys():CopyExceptWhere(false, unpack(assigned)):Sort()()
	--Logging:Trace("UnassignedEquipmentLocations(unassigned) : %s", Util.Objects.ToString(unassigned))
	return equipmentLocations, unassigned
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

function Service:PlayerMappingFunction(configId)
	--- @type Models.List.Configuration
	local config

	if Util.Objects.IsSet(configId) then
		config = self.Configuration:Get(configId)
	else
		local configs = self:Configurations(true, true)
		if Util.Objects.IsTable(configs) then
			config = Util.Tables.Values(configs)[1]
		end
	end

	if config then
		return function(p)
			local resolved = config:ResolvePlayer(p)
			--Logging:Debug("Resolved %s to %s via %s", tostring(p), resolved and resolved:GetName() or 'nil', tostring(config))
			return resolved and resolved:GetShortName() or p
		end
	else
		-- couldn't construct a reasonable function, return identity one
		return Util.Functions.Id
	end
end


-- idOrConfig can be an instance of Configuration or Configuration Id (string)
--- @return Models.List.ActiveConfiguration
function Service:Activate(idOrConfig)
	local config =
		Util.Objects.IsInstanceOf(idOrConfig, Configuration) and
			idOrConfig or
			self.Configuration:Get(idOrConfig)

	if not config then
		error(format("No configuration found with id '%s'", tostring(idOrConfig)))
	end

	local lists = self:Lists(config.id)
	if not lists or Util.Tables.Count(lists) == 0 then
		error(format("No lists found with configuration id '%s'", config.id))
	end

	return ActiveConfiguration(self, config, lists)
end

function ActiveConfiguration:initialize(service, config, lists)
	--- @type Models.List.Service
	self.service = service
	--- @type Models.List.Configuration
	self.config = config
	-- Players who are not currently in the raid do not move up or down in these lists
	--- @type table<string, Models.List.List>
	self.lists = lists
	-- create a copy of each list and clear the players priority
	-- as players enter the raid they will be added based upon position in original list
	--- @type table<string, Models.List.List>
	self.listsActive =
		Util(self.lists)
			:Copy()
			:Map(
				--- @param list  Models.List.List
				function(list)
					local copy = list:clone()
					copy:ClearPlayers()
					return copy
				end
			)()
end

--  todo : unify this logic with OnPlayerEvent()
---
--- this function is to create a view of the active list's priorities when
--- it's not being actively maintained (which is case of a player where not the master looter)
---
--- @param self Models.List.ActiveConfiguration
--- @param list Models.List.List
--- @return Models.List.List
local function CreateActiveListView(self, list)
	--- @type Models.List.List
	local view

	Logging:Trace("CreateActiveListView() : %s", Util.Objects.ToString(list))

	if list then
		-- get the original list from which to obtain overall priorities
		local origList = self:GetOriginalList(list.id)
		Logging:Trace("CreateActiveListView() : %s", Util.Objects.ToString(origList))
		if origList then
			view = list:clone()
			view:ClearPlayers()

			local player, priority
			for name, _ in AddOn:GroupIterator() do
				-- resolve player through configuration as it has potential to be an ALT
				player = self.config:ResolvePlayer(name)
				-- capture current overall priority from original ist
				priority, _ = origList:GetPlayerPriority(player)
				-- if for some reason could not obtain priority, ignore
				if priority then
					view:AddPlayer(player, priority)
				end
			end
		end
	end

	return view
end

--- @return Models.List.List the list in it's original state when activated
function ActiveConfiguration:GetOriginalList(listId)
	return self.lists[listId]
end

--- @return Models.List.List the list in it's current form as a result of mutations (players add, loot given, etc.)
function ActiveConfiguration:GetActiveList(listId)
	local list = self.listsActive[listId]
	Logging:Trace("GetActiveList(%s) : %s", tostring(listId), Util.Objects.ToString(list))

	if AddOn:IsMasterLooter() then
		return list
	else
		return CreateActiveListView(self, list)
	end
end

--- @param lists table<string,Models.List.List>
--- @param  equipment string the equipment slot (e.g. INVTYPE_HEAD)
--- @return  string, Models.List.List
local function GetListByEquipment(lists, equipment)
	return Util.Tables.FindFn(
		lists,
		function(list)
			return list:AppliesToEquipment(equipment)
		end
	)
end

--- @param equipment string the equipment slot (e.g. INVTYPE_HEAD)
--- @return string, Models.List.List the overall list for specified equipment slot
function ActiveConfiguration:GetOverallListByEquipment(equipment)
	return GetListByEquipment(self.lists, equipment)
end

--- @param equipment string the equipment slot (e.g. INVTYPE_HEAD)
--- @return string, Models.List.List the active list for specified equipment slot
function ActiveConfiguration:GetActiveListByEquipment(equipment)
	local id, list = GetListByEquipment(self.listsActive, equipment)
	if AddOn:IsMasterLooter() then
		return id, list
	else
		return id, CreateActiveListView(self, list)
	end
end


function ActiveConfiguration:__tostring()
	return format("%s (%s)", self.config.name, self.config.id)
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
	-- this goes through Hashable:Verify()
	local verified, ah, ch = self.config:Verify(config)
	Util.Tables.Push(verification, {verified = verified, ah = ah, ch = ch})
	-- only go through lists if configuration was verified
	-- as lists are bound to a configuration and all bets are off if the config is not verified
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
				-- this goes through Hashable:Verify()
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
				"EnsurePresent(%s, %s) : Missing from original on list, adding",
				tostring(player), listId
			)
			list:AddPlayer(player)
			Util.Tables.Push(addedTo, listId)
		end
	end

	return addedTo
end

-- this handles events related top players joining and leaving the party
-- only time this mutates the original priority list is if the player is not present on a list
-- and configuration dictates that they are added
function ActiveConfiguration:OnPlayerEvent(player, joined)
	Logging:Trace("OnPlayerEvent(%s, %s)", tostring(player), tostring(joined))
	-- resolve player through configuration as it has potential to be an ALT
	-- if that is the case, all priorities will be tied to the main with which it is associated
	-- otherwise, the player stands alone
	player = self.config:ResolvePlayer(player)
	Logging:Trace("OnPlayerEvent(%s, %s)", tostring(player), tostring(joined))

	-- make sure player is present on original list(s)
	-- todo : (maybe) allow for a configuration setting on how to insert them
	if joined then
		local addedTo = EnsurePresent(self.lists, player)
		-- persist any lists were the player was added
		for _, listId in pairs(addedTo) do
			self.service.List:Update(
				self.lists[listId],
				'players',
				true,
				-- extra detail related to reactivation of configuration
				-- all modifications performed via this path are already applied and active
				-- there is no need to reactivate it as the messages will originate from us (as ML)
				-- still need to dispatch to other raid members via comms
				-- see Lists:_ProcessEvents()
				{appliedToAc = true, via = 'OnPlayerEvent'}
			)
		end
	end

	local prios = {}
	-- based upon joining or leaving, capture current priority from appropriate lists
	for listId, list in pairs(joined and self.lists or self.listsActive) do
		local priority, _ = list:GetPlayerPriority(player)
		prios[listId] = priority or -1
	end

	Logging:Debug("OnPlayerEvent(%s, %s) : Working Priorities %s",  tostring(player), tostring(joined), Util.Objects.ToString(prios))

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
				Logging:Debug(
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

			Logging:Debug(
					"OnPlayerEvent(%s, %s, %s) : Removing",
					tostring(player), tostring(joined), listId
			)

			list:RemovePlayer(player, false)
		end

		--Logging:Trace(
		--	"OnPlayerEvent[after](%s, %s, %s) : %s",
		--	tostring(player), tostring(joined), tostring(listId),
		--	Util.Objects.ToString(Util.Tables.Copy(list.players, function(p) return p:toTable() end))
		--)
	end
end

--- @param player string|Models.Player the player receiving the loot
--- @param equipment string the equipment slot for loot (e.g. INVTYPE_HEAD)
--- @param count number|nil the number of slots to drop the player on list as result of receiving item
--- @return string, number, number, number, number :
---     list id, active prio (before), active prio (after), original prio (before), orginal prio (after)
function ActiveConfiguration:OnLootEvent(player, equipment, count)
	Logging:Debug("OnLootEvent(%s, %s, %s)", tostring(player), tostring(equipment), tostring(count))
	-- resolve player through configuration as it has potential to be an ALT
	-- if that is the case, all priorities will be tied to the main with which it is associated
	-- otherwise, the player stands alone
	player = self.config:ResolvePlayer(player)
	Logging:Debug("OnLootEvent(%s, %s, %s)", tostring(player), tostring(equipment), tostring(count))

	-- locate the current active list for the equipment
	local listId, list = self:GetActiveListByEquipment(equipment)

	if (listId and list) then
		Logging:Trace(
			"OnLootEvent(%s, %s, %s) : Located List(%s, '%s'), 'suiciding' player (with respect to count of spots to drop)",
			tostring(player), tostring(equipment), tostring(count), tostring(listId), list.name
		)

		-- apb : active priority before
		-- apa : active priority after
		-- opb : original priority before
		-- opa : original priority after

		-- 'suicide' the player on active list and then apply to master list
		-- note that this may not result in a drop to bottom of list if a count was specified
		local apb = list:GetPlayerPriority(player, true)
		list:DropPlayer(player, count)
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
					'players',
					true,
					-- extra detail related to reactivation of configuration
					-- all modifications performed via this path are already applied and active
					-- there is no need to reactivate it as the messages will originate from us (as ML)
					-- still need to dispatch to other raid members via comms
					-- see Lists:_ProcessEvents()
					{appliedToAc = true, via = 'OnLootEvent'}
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
		AddOn:PrintError(format("No list found - no change in priority will be applied for %s", player and player:GetShortName() or L["unknown"]))
	end
end