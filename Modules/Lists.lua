--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @type Models.List.Service
local ListsService = AddOn.Package('Models.List').Service
--- @type Models.List.Configuration
local Configuration = AddOn.Package('Models.List').Configuration
--- @type Models.List.List
local List = AddOn.Package('Models.List').List
--- @type Models.Dao
local Dao = AddOn.Package('Models').Dao
--- @type Models.Player
local Player = AddOn.Package('Models').Player
--- @type Models.Audit.LootRecord
local LootRecord = AddOn.Package('Models.Audit').LootRecord
--- @type Models.Audit.TrafficRecord
local TrafficRecord = AddOn.Package('Models.Audit').TrafficRecord


--- @class Lists
local Lists = AddOn:NewModule('Lists', "AceEvent-3.0", "AceBucket-3.0", "AceTimer-3.0", "AceHook-3.0")

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

local Base = AddOn.Class('Lists.Base')
local Request = AddOn.Class('Lists.Request', Base)
local Response = AddOn.Class('Lists.Response', Base)

function Lists:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.Libs.AceDB:New(AddOn:Qualify('Lists'), self.defaults)
	-- this is used for holding on to loot audit records temporarily
	-- so they can be associated with a traffic record that was a result of
	-- a loot allocation. it's used for nothing else and has weak values
	-- in case they are not properly removed when consumed
	self.laTemp = {}
	setmetatable(self.laTemp, { __mode = "v" }) -- give table weak values
	-- this is used for holding on to pending requests for configs and list
	-- for verifying responses were actually merited. it's used for nothing else and has weak values
	-- in case they are not properly removed when consumed
	self.requestsTemp = {}
	setmetatable(self.requestsTemp, { __mode = "v" }) -- give table weak values

	self:InitializeService()
	self.Send = Comm():GetSender(C.CommPrefixes.Lists)
end

function Lists:InitializeService()
	-- if it's being re-initialized - clear out callbacks
	self:UnregisterCallbacks()
	--- @type Models.List.Service
	self.listsService = ListsService(
			{self, self.db.factionrealm.configurations},
			{self, self.db.factionrealm.lists}
	)
	--- @type Models.List.ActiveConfiguration
	self.activeConfig = nil
	self:RegisterCallbacks()
end

function Lists:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:RegisterCallbacks()
	self:SubscribeToComms()
	self:RegisterMessage(C.Messages.ModeChanged, "OnModeChange")
end

function Lists:OnDisable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:UnregisterCallbacks()
	self:UnsubscribeFromComms()
	self:UnregisterMessage(C.Messages.ModeChanged)
end

function Lists:EnableOnStartup()
	return true
end

function Lists:SubscribeToComms()
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	self.commSubscriptionsMain = Comm():BulkSubscribe(C.CommPrefixes.Main, {
		[C.Commands.ActivateConfig] = function(data, sender)
			Logging:Debug("ActivateConfig from %s", tostring(sender))
			self:OnActivateConfigReceived(sender, unpack(data))
		end,
	})
	self.commSubscriptionsLists = Comm():BulkSubscribe(C.CommPrefixes.Lists, {
		[C.Commands.ConfigResourceRequest] = function(data, sender)
			Logging:Debug("ConfigResourceRequest from %s", tostring(sender))
			self:OnResourceRequest(sender, unpack(data))
		end,
		[C.Commands.ConfigResourceResponse] = function(data, sender)
			Logging:Debug("ConfigResourceResponse from %s", tostring(sender))
			self:OnResourceResponse(sender, unpack(data))
		end,
	})
end

function Lists:UnsubscribeFromComms()
	Logging:Debug("UnsubscribeFromComms(%s)", self:GetName())
	AddOn.Unsubscribe(self.commSubscriptionsLists)
	AddOn.Unsubscribe(self.commSubscriptionsMain)
	self.commSubscriptionsLists = nil
	self.commSubscriptionsMain = nil
end

function Lists:RegisterCallbacks()
	self.listsService:RegisterCallbacks(self, {
        [Configuration] = {
	        [Dao.Events.EntityCreated] = function(...) self:ConfigurationDaoEvent(...) end,
	        [Dao.Events.EntityDeleted] = function(...) self:ConfigurationDaoEvent(...) end,
	        [Dao.Events.EntityUpdated] = function(...) self:ConfigurationDaoEvent(...) end,
        },
        [List] = {
	        [Dao.Events.EntityCreated] = function(...) self:ListDaoEvent(...) end,
	        [Dao.Events.EntityDeleted] = function(...) self:ListDaoEvent(...) end,
	        [Dao.Events.EntityUpdated] = function(...) self:ListDaoEvent(...) end,
        },
    })
end

function Lists:UnregisterCallbacks()
	if self.listsService then
		self.listsService:UnregisterAllCallbacks(self)
	end
end

function Lists:GetService()
	return self.listsService
end

function Lists:HasActiveConfiguration()
	return not Util.Objects.IsNil(self.activeConfig)
end

--- @return  Models.List.ActiveConfiguration
function Lists:GetActiveConfiguration()
	return self.activeConfig
end

local function EventsQueue()
	return {
		timer = nil,
		events = {}
	}
end

--- this is entirely about batching events together in order to
--- (1) prevent excessive transmissions and (2) squash related events (i.e. name changes twice in window, add/remove)
---
--- @param queue table the queue in which to insert the event
--- @param event string the event name
--- @param entity any the instance of the entity which generated the event
--- @param attr string the attribute name if the event is an update
--- @param diff any the delta between attribute values if the event is an update
--- @param ref table the Referencable instance (as a table), which reflects the pre-update state
function Lists:_EnqueueEvent(queue, event, entity, attr, diff, ref)
	-- cancel any pending timer firing, as new events have been received
	if queue.timer then
		self:CancelTimer(queue.timer)
		queue.timer = nil
	end

	local path = Util.Tables.New()
	-- the queues are by class/type, no need to add it to path
	-- [id][event]
	Util.Tables.Push(path, entity.id)
	Util.Tables.Push(path, event)

	-- these two events are mutually exclusive, just overwrite any previous one
	if Util.Objects.In(event, Dao.Events.EntityCreated, Dao.Events.EntityDeleted) then
		-- insert new one
		-- [id][event] = {} [detail]
		Util.Tables.Set(queue.events, path, {entity=entity})
		-- remove corollary
		Util.Tables.Pop(path)
		Util.Tables.Push(
			path,
			Util.Objects.Equals(event, Dao.Events.EntityCreated) and
			Dao.Events.EntityDeleted or Dao.Events.EntityCreated
		)
		Util.Tables.Set(queue.events, path, nil)
	-- any updates for the same attribute supplant previous ones
	elseif Util.Strings.Equal(event, Dao.Events.EntityUpdated) then
		-- [id][event][attr] = {} [detail]
		Util.Tables.Push(path, attr)
		-- [61730289-1315-8CD4-5D3B-E8EFB75A5601, EntityUpdated, name]
		Util.Tables.Set(queue.events, path, {entity=entity, attr=attr, diff=diff, ref=ref})
	end


	Util.Tables.Release(path)

	if not AddOn._IsTestContext() then
		queue.timer = self:ScheduleTimer(function() self:_ProcessEvents(queue) end, 5)
	end
end

local EventToAction = {
	[Dao.Events.EntityCreated] = TrafficRecord.ActionType.Create,
	[Dao.Events.EntityDeleted] = TrafficRecord.ActionType.Delete,
	[Dao.Events.EntityUpdated] = TrafficRecord.ActionType.Modify,
}

function Lists:_ProcessEvents(queue)

	Logging:Trace("_ProcessEvents(%d)", Util.Tables.Count(queue.events))

	local function ProcessEvent(id, event, detail)
		Logging:Trace("ProcessEvent(%s)[%s] : %s", id, tostring(detail.entity.clazz.name), event)
		local entity = detail.entity
		if not entity then
			return
		end

		--- @type Models.Audit.TrafficRecord
		local record

		if Util.Objects.IsInstanceOf(entity, Configuration) then
			record = TrafficRecord.For(entity)
		elseif Util.Objects.IsInstanceOf(entity, List) then
			record = TrafficRecord.For(self:GetService().Configuration:Get(entity.configId), entity)
		end

		record:SetAction(EventToAction[event])

		if Util.Objects.Equals(event, Dao.Events.EntityUpdated) then
			record:SetReference(detail.ref)
			record:SetModification(detail.attr, detail.diff)

			-- if it's a list record and associated with priority change
			-- attach any available loot audit record
			if Util.Objects.IsInstanceOf(entity, List) and Util.Objects.In(detail.attr, 'players') then
				local lootRecord = self.laTemp[entity.id]
				if lootRecord then
					record:SetLootRecord(lootRecord)
					self.laTemp[entity.id] = nil
				end
			end
		end

		-- Logging:Trace("ProcessEvent(%s)[%s] : %s", id, tostring(detail.entity.clazz.name), Util.Objects.ToString(record:toTable()))
		AddOn:TrafficAuditModule():Broadcast(record)
	end

	-- string, table (of events)
	for id, events in pairs(queue.events) do
		--- event type (string), detail (either the detail (table) or attribute names (table))
		for event, detail in pairs(events) do
			if Util.Objects.In(event, Dao.Events.EntityCreated, Dao.Events.EntityDeleted) then
				ProcessEvent(id, event, detail)
			else
				-- EntityUpdated : additional level of keys which is the attribute name
				for _, attrDetail in pairs(detail) do
					ProcessEvent(id, event, attrDetail)
				end
			end
		end
	end

	queue.events = {}
	queue.timer = nil
end

local ConfigurationEvents = EventsQueue()
function Lists:ConfigurationDaoEvent(event, entity, attr, diff, ref)
	Logging:Debug("ConfigurationDaoEvent(%s) : %s (%s)", event, entity.clazz.name, entity.id)
	self:_EnqueueEvent(ConfigurationEvents, event, entity, attr, diff, ref)
end

local ListEvents = EventsQueue()
function Lists:ListDaoEvent(event, entity, attr, diff, ref)
	Logging:Debug("ListDaoEvent(%s) : %s (%s)", event, entity.clazz.name, entity.id)
	self:_EnqueueEvent(ListEvents, event, entity, attr, diff, ref)
end

--- @param self Lists
local function GetListAndPriority(self, equipment, player, active, relative)
	player = player and Player.Resolve(player) or AddOn.player
	active = Util.Objects.Default(active, true)
	relative = Util.Objects.Default(relative, false)

	local list, prio = nil, nil
	if equipment and self:HasActiveConfiguration() then
		if active then
			_, list =
				self:GetActiveConfiguration():GetActiveListByEquipment(equipment)
		else
			_, list =
				self:GetActiveConfiguration():GetOverallListByEquipment(equipment)
		end

		if list then
			prio, _ = list:GetPlayerPriority(player, relative)
		end
	end

	return list, prio
end

-- for passed equipment location, this returns the active list for the item
-- along with the specified player's priority
function Lists:GetActiveListAndPriority(equipment, player)
	return GetListAndPriority(self, equipment, player, true, true)
end

-- for passed equipment location, this returns the overall list for the item
-- along with the specified player's priority
function Lists:GetOverallListAndPriority(equipment, player)
	return GetListAndPriority(self, equipment, player, false)
end

local MaxActivationReattempts = 3

--- @param sender string
--- @param activation table
function Lists:OnActivateConfigReceived(sender, activation, attempt)
	attempt = Util.Objects.Default(attempt, 0)

	Logging:Trace("OnActivateConfigReceived(%s, %d)", tostring(sender), attempt)

	if attempt > MaxActivationReattempts then
		Logging:Warn("OnActivateConfigReceived() : Maximum activation (re)attempts exceeded, giving up")
		return
	end

	if not AddOn:IsMasterLooter(sender) then
		Logging:Warn("OnActivateConfigReceived() : Sender is not the master looter, ignoring")
		return
	end

	-- TODO TODO TODO TODO : if we're an admin or owner, but no ML - we shouldn't send blanket requests (could overwrite local changes)
	local function EnqueueRequest(to, id, type)
		Logging:Trace("EnqueueRequest(%s, %s)",tostring(id), tostring(type))
		Util.Tables.Push(to, Request(type, id))
	end

	local isMl = AddOn:IsMasterLooter()

	-- see MasterLooter:ActivateConfiguration() for 'activation' message contents
	-- only load reference for configuration, as activation is going to load lists
	if activation and Util.Tables.Count(activation) >= 1 then
		-- a valid request to activate a new configuration means any current one must be discarded
		self.activeConfig = nil

		local configForActivation, toRequest = activation['config'], {}
		local resolved = self.listsService:LoadRefs({configForActivation})

		-- could not resolve the configuration for activation
		-- will need to request it
		--
		-- in practice, we should never be missing (or requesting) information
		-- if we're the master looter the activation message originated from us
		-- if that were to occur, that's a regression
		if not resolved or #resolved ~= 1 then
			-- if we're the master looter and could not resolve the configuration
			-- that's fatal and must result in abrupt halt
			if isMl then
				Logging:Fatal("OnActivateConfigReceived() : Could not resolve configuration '%s'", configForActivation)
				local message = format("Could not resolve configuration '%s'", configForActivation)
				AddOn:PrintError(message)
				error(message)
			end

			EnqueueRequest(toRequest, configForActivation.id, Configuration.name)
		else
			local activate = resolved[1]
			local result, activated = pcall(
				function()
					return self.listsService:Activate(activate)
				end
			)

			--Logging:Trace("OnActivateConfigReceived(%s) => %s/%s", tostring(activate.id), tostring(result), Util.Objects.ToString(activated))
			if not result then
				-- if we're the master looter and could not active the resolved configuration
				-- that's fatal and must result in abrupt halt
				if isMl then
					Logging:Fatal("OnActivateConfigReceived() : Could not activate configuration '%s'", tostring(activate.id))
					local message = format("Could not activate configuration '%s'", tostring(activate.id))
					AddOn:PrintError(message)
					error(message)
				end

				EnqueueRequest(toRequest, activate.id, Configuration.name)
				Logging:Warn("OnActivateConfigReceived() : Could not activate configuration '%s' => %s", activate.id, tostring(activated))
			else
				self.activeConfig = activated
				Logging:Debug("OnActivateConfigReceived() : Activated '%s'", activate.id)

				-- we aren't the ML, do some checks to see if we have the correct data
				-- this is entirely for requesting up to date data in case we are behind
				if not isMl or AddOn:DevModeEnabled() then
					-- no need to check version and revision here
					-- just compare hashes of data
					local verification = self.activeConfig:Verify(activate, activation['lists'])
					-- index 1 is always the configuration verification
					local v = verification[1]
					if not v.verified then
						Logging:Warn(
							"OnActivateConfigReceived(%s)[Configuration] : Failed hash verification %s / %s",
							self.activeConfig.config.id,
							v.ah,
							v.ch
						)
						EnqueueRequest(toRequest, activate.id, Configuration.name)
					-- only handle potential list requests in face of a verified configuration
					-- otherwise, could result in ordering issues with responses
					-- this means it will take multiple passes to reconcile (send a request, receive a response)
					else
						-- index 1 is always the list verifications
						local listResults = verification[2]
						local verifications, missing, extra = listResults[1], listResults[2], listResults[3]

						for id, vfn in pairs(verifications) do
							if not vfn.verified then
								Logging:Warn(
									"OnActivateConfigReceived(%s)[List] : failed hash verification %s / %s",
									id,
									vfn.ah,
									vfn.ch
								)
								EnqueueRequest(toRequest, id, List.name)
							end
						end

						for _, id in pairs(missing) do
							Logging:Warn("OnActivateConfigReceived(%s)[List] : Missing", id)
							EnqueueRequest(toRequest, id, List.name)
						end

						for _, id in pairs(extra) do
							Logging:Warn("OnActivateConfigReceived(%s)[List] : Extra (this should not occur unless admin/owner which is not current master looter)", id)
							-- no request for an extra one, the sender won't have it
							-- signifies an issue with owners/admins not having synchronized config/list data
						end
					end
				end
			end

			if Util.Tables.Count(toRequest) > 0 then
				Logging:Warn("%s", Util.Objects.ToString(toRequest))
				--self:_SendRequest(AddOn.masterLooter, unpack(toRequest))
				--self:ScheduleTimer(function() self:OnActivateConfigReceived(sender, activation, attempt + 1) end, 5)
			end
		end
	end

	if self.activeConfig then
		Logging:Debug("OnActivateConfigReceived() : Activated configuration %s", tostring(self.activeConfig.config.name))
		AddOn:Print(format(L["activated_configuration"], tostring(self.activeConfig.config.name)))
	else
		Logging:Warn("OnActivateConfigReceived() : No active configuration")
		AddOn:Print(L["invalid_configuration"])
	end
end

--- @param itemAward Models.Item.ItemAward
function Lists:OnAwardItem(itemAward)
	Logging:Trace("OnAwardItem() : %s", Util.Objects.ToString(itemAward and itemAward:toTable() or {}))
	if not itemAward then error('No item award provided') end

	-- the exceptional case should never occur as this is only invoked by Master Looter who implicitly needs
	-- an active configuration to do an award
	if self:HasActiveConfiguration() then
		-- only apply if the associated award reason dictate a suicide occur
		local reason, list = AddOn:MasterLooterModule().AwardReasons[itemAward.awardReason], nil
		if reason.suicide then
			local lid, apb, apa, opb, opa =
				self:GetActiveConfiguration():OnLootEvent(
						itemAward.winner,
						itemAward.equipLoc
				)
			list = self:GetActiveConfiguration():GetActiveList(lid)

			AddOn:SendAnnouncement(
				format(
					L["list_priority_announcement"],
			        list and list.name or L['unknown'],
					AddOn.Ambiguate(itemAward.winner),
					tostring(apb or '?'),
					tostring(apa or '?'),
					tostring(opb or '?'),
					tostring(opa or '?')
				),
				C.group
			)
		end

		if not list then
			list = self:GetActiveConfiguration():GetActiveListByEquipment(itemAward.equipLoc)
		end

		local audit = LootRecord.FromItemAward(itemAward)
		Util.Functions.try(
			function()
				audit.configuration = self:GetActiveConfiguration().config.name
				audit.list = list and list.name or L['unknown']
				AddOn:LootAuditModule():Broadcast(audit)
			end
		).finally(
			-- track the loot audit record for association with traffic record
			function()
				if list then
					self.laTemp[list.id] = audit
				end
			end
		)
	else
		Logging:Error("OnAwardItem() : No active configuration, cannot handle item award")
		-- error out here, we don't want this to go unnoticed
		error("No active configuration, cannot handle item award")
	end
end

function Base:initialize(type, id, cid)
	self.type = type
	self.id = id
	-- correlation id for request/response pairing
	self.cid = cid or Util.UUID.UUID()
end

function Base:IsValid()
	return Util.Strings.IsSet(self.type) and Util.Strings.IsSet(self.id)
end

function Base:__tostring()
	return format("[%s] : %s[%s(%s)]", self.cid, self.clazz.name, tostring(self.type), tostring(self.id))
end

function Request:initialize(type, id)
	Base.initialize(self, type, id)
end

function Response:initialize(type, id, cid)
	Base.initialize(self, type, id, cid)
	self.payload = nil
end

function Response:ResolvePayload()
	if self.payload then
		if Util.Strings.Equal(self.type, Configuration.name) then
			return Configuration:reconstitute(self.payload)
		elseif Util.Strings.Equal(self.type, List.name) then
			return List:reconstitute(self.payload)
		end
	end

	return nil
end

function Lists:_SendRequest(to, ...)
	to = to or AddOn.masterLooter
	Logging:Trace("_SendRequest(%s)", (to and tostring(to) or nil))

	if not to then
		Logging:Warn("_SendRequest() : target not specified, not sending")
		return
	end

	for _, r in Util.Objects.Each(Util.Tables.Temp(...)) do
		self.requestsTemp[r.cid] = true
		self:Send(AddOn.player, C.Commands.ConfigResourceRequest, r)
	end
end

function Lists:OnResourceRequest(sender, payload)
	Logging:Trace("OnResourceRequest(%s)", tostring(sender))

	local request = Request:reconstitute(payload)
	if request then
		Logging:Trace("OnResourceRequest() : %s", tostring(request))
		if request:IsValid() then
			local resource

			if Util.Strings.Equal(request.type, Configuration.name) then
				resource = self:GetService().Configuration:Get(request.id)
			elseif Util.Strings.Equal(request.type, List.name) then
				resource = self:GetService().List:Get(request.id)
			else
				Logging:Warn("OnResourceRequest() : unsupported request type %s", request.type)
				return
			end

			local response = Response(request.type, request.id, request.cid)
			response.payload = resource
			self:_SendResponse(sender, response)
		end
	end
end

function Lists:_SendResponse(to, ...)
	if not to then
		Logging:Warn("_SendResponse() : target not specified, not sending")
		return
	end
	Logging:Trace("_SendResponse(%s)", tostring(to))

	for _, r in Util.Objects.Each(Util.Tables.Temp(...)) do
		self:Send(to, C.Commands.ConfigResourceResponse, r)
	end
end


function Lists:OnResourceResponse(sender, payload)
	-- Logging:Trace("OnResourceResponse(%s) : %s", tostring(sender), Util.Objects.ToString(payload))
	local response = Response:reconstitute(payload)
	Logging:Trace("OnResourceResponse(%s) : %s", tostring(sender), tostring(response and response or nil))
	if response then
		local resource = response:ResolvePayload()
		if resource then
			if not self.requestsTemp[response.cid] then
				Logging:Trace("OnResourceResponse(%s, %s) : no pending request found", tostring(sender), tostring(response.cid))
				return
			end

			if Util.Objects.IsInstanceOf(resource, Configuration) then
				self:GetService().Configuration:Add(resource, false)
			elseif Util.Objects.IsInstanceOf(resource, List) then
				self:GetService().List:Add(resource, false)
			end

			self.requestsTemp[response.cid] = nil
		end
	end
end

function Lists:LaunchpadSupplement()
	return L["lists"], function(container) self:LayoutInterface(container) end , false
end

if AddOn._IsTestContext() then
	function Lists:GetConfigurationEvents()
		return ConfigurationEvents
	end

	function Lists:GetListEvents()
		return ListEvents
	end

	function Lists:CreateRequest(type, id)
		return Request(type, id)
	end

	function Lists:ReconstructResponse(payload)
		return Response:reconstitute(payload)
	end
end