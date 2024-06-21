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
--- @type ListsDataPlane
local ListsDp

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

function Lists:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.Libs.AceDB:New(AddOn:Qualify('Lists'), self.defaults)
	-- this is used for holding on to loot audit records temporarily
	-- so they can be associated with a traffic record that was a result of
	-- a loot allocation
	self.laTemp = {}
	self:InitializeService()
	ListsDp = AddOn:ListsDataPlaneModule()
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
	self:RegisterMessage(C.Messages.ResourceRequestCompleted, "OnResourceRequestCompleted")
	AddOn.Timer.Schedule(function() AddOn.Timer.After(3, function() self:ValidateConfigurations() end) end)

end

function Lists:OnDisable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:UnregisterCallbacks()
	self:UnsubscribeFromComms()
	self:UnregisterMessage(C.Messages.ModeChanged)
	self:UnregisterMessage(C.Messages.ResourceRequestCompleted)
end

function Lists:EnableOnStartup()
	return true
end

function Lists:SubscribeToComms()
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	self.commSubscriptions = Comm():BulkSubscribe(C.CommPrefixes.Main, {
		[C.Commands.ActivateConfig] = function(data, sender)
			Logging:Debug("ActivateConfig from %s", tostring(sender))
			-- path for the ML activating configuration doesn't flow through communications (messaging)
			if not AddOn:IsMasterLooter() then
				self:OnActivateConfigReceived(sender, unpack(data))
			end
		end,
		[C.Commands.DeactivateConfig] = function(data, sender)
			Logging:Debug("DeactivateConfig from %s", tostring(sender))
			-- path for the ML deactivating configuration doesn't flow through communications (messaging)
			if not AddOn:IsMasterLooter() then
				self:DeactivateConfiguration(unpack(data))
			end
		end
	})
end

function Lists:UnsubscribeFromComms()
	Logging:Debug("UnsubscribeFromComms(%s)", self:GetName())
	AddOn.Unsubscribe(self.commSubscriptions)
	self.commSubscriptions = nil
end

function Lists:RegisterCallbacks()
	Logging:Trace("RegisterCallbacks")
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
	Logging:Trace("UnregisterCallbacks")
	if self.listsService then
		self.listsService:UnregisterAllCallbacks(self)
	end
end

--- @return Models.List.Service
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

function Lists:ValidateConfigurations()
	Logging:Debug("ValidateConfigurations()")
	local configs = self:GetService():Configurations(nil, true)
	if configs then
		local count = Util.Tables.Count(configs)
		Logging:Debug("ValidateConfigurations() : active and default configuration count = %d", count)
		if count > 1 then
			local sorted =
				Util(configs):Copy():Values()
					-- only consider active configurations
					:Filter(
						function(c)
							--Logging:Debug("Filter : %s", c.name)
							return c.status == Configuration.Status.Active
						end
					)
					:Sort(
						-- returns true when the first element must come before the second in the final order
						function (c1, c2)
							--Logging:Debug("Comparing : %s (c1) to %s (c2)", c1.name, c2.name)
							-- cannot base which should be default purely based upon last time configuration was updated
							-- instead should look at lists associated with configuration to see which was mostly
							-- recently updated
							local l1 = self:GetService():Lists(c1.id)
							local l2 = self:GetService():Lists(c2.id)

							-- if no lists for c1, then c2 comes 1st
							if Util.Objects.IsNil(l1) or Util.Tables.Count(l1) == 0 then
								return false
							end

							-- if no lists for c2, then c1 comes first
							if Util.Objects.IsNil(l2) or Util.Tables.Count(l2) == 0 then
								return true
							end

							-- sort the lists to find the most recent revision (date) for each
							local l1MostRecent = Util(l1):Values():Sort(function(l1, l2) return l1.revision > l2.revision end)()[1]
							local l2MostRecent = Util(l2):Values():Sort(function(l1, l2) return l1.revision > l2.revision end)()[1]

							-- if no most recent list for c1, then c2 comes 1st
							if Util.Objects.IsNil(l1MostRecent) then
								return false
							end

							-- if no most recent list for c2, then c1 comes 1st
							if Util.Objects.IsNil(l2MostRecent) then
								return true
							end

							--Logging:Debug("%s/%s (l1) %s/%s (l2)", l1MostRecent.name, tostring(Date(l1MostRecent.revision)), l2MostRecent.name, tostring(Date(l2MostRecent.revision)))

							-- compare most recent list revision for each configuration to determine which
							-- configuration should beecome default
							return l1MostRecent.revision > l2MostRecent.revision
						end)()

			local defaultConfig = sorted[1]
			if defaultConfig then
				Logging:Debug("ValidateConfigurations() : determined 'true' default configuration is %s (%s)", defaultConfig.name, defaultConfig.id)
				self:GetService():EnsureSingleDefaultConfiguration(defaultConfig)
			end
		end
	end
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
--- @param eventDetail table the event details, as key/value pairs
function Lists:_EnqueueEvent(queue, event, eventDetail)
	-- cancel any pending timer firing, as new events have been received
	if queue.timer then
		self:CancelTimer(queue.timer)
		queue.timer = nil
	end

	local path = Util.Tables.New()
	-- the queues are by class/type, no need to add it to path
	-- [id][event]
	Util.Tables.Push(path, eventDetail.entity.id)
	Util.Tables.Push(path, event)

	-- these two events are mutually exclusive, just overwrite any previous one
	if Util.Objects.In(event, Dao.Events.EntityCreated, Dao.Events.EntityDeleted) then
		-- insert new one
		-- [id][event] = {} [detail]
		Util.Tables.Set(queue.events, path, eventDetail)
		-- remove corollary
		Util.Tables.Pop(path)
		Util.Tables.Push(
			path,
			Util.Objects.Equals(event, Dao.Events.EntityCreated) and Dao.Events.EntityDeleted or Dao.Events.EntityCreated
		)
		Util.Tables.Set(queue.events, path, nil)
	-- any updates for the same attribute supplant previous ones
	elseif Util.Strings.Equal(event, Dao.Events.EntityUpdated) then
		-- [id][event][attr] = {} [detail]
		Util.Tables.Push(path, eventDetail.attr)
		-- [61730289-1315-8CD4-5D3B-E8EFB75A5601, EntityUpdated, name]
		Util.Tables.Set(queue.events, path, eventDetail)
	end

	Util.Tables.Release(path)

	-- when testing, just execute it immediately
	if  AddOn._IsTestContext() then
		self:_ProcessEvents(queue)
	-- otherwise, wait a bit of time for other events to be enqueued
	else
		-- every 5 seconds seems to aggressive, as typical loot session(s) have multiple items
		-- with a reasonable response time of 60 seconds
		-- likely still to aggressive at 30 seconds, but start conservatively with extending interval
		queue.timer = self:ScheduleTimer(function() self:_ProcessEvents(queue) end, 30 --[[ 5 --]])
	end
end

local EventToAction = {
	[Dao.Events.EntityCreated] = TrafficRecord.ActionType.Create,
	[Dao.Events.EntityDeleted] = TrafficRecord.ActionType.Delete,
	[Dao.Events.EntityUpdated] = TrafficRecord.ActionType.Modify,
}

function Lists:_ProcessEvents(queue)
	Logging:Trace("_ProcessEvents(%d)", Util.Tables.Count(queue.events))

	-- copy the event queue and set it back to empty for future ones
	local process = Util.Tables.Copy(queue.events)
	queue.events = {}
	queue.timer = nil

	-- capture some state which instructs us as to whether
	-- (1) we need to check for reactivation and
	-- (2) reactivation should occur
	-- (3) if the change has already been applied, in which case reactivation is not needed locally (still need to broadcast)
	local acId, reactivate, applied = nil, false, nil

	if AddOn:IsMasterLooter() and self:HasActiveConfiguration() then
		acId = self:GetActiveConfiguration().config.id
	end

	local function CheckReactivation(id, appendix)
		Logging:Trace("CheckReactivation(%s) : %s", id, Util.Objects.ToString(appendix))
		if acId and Util.Strings.Equal(acId, id) then
			reactivate = true

			-- reevaluate applied if currently true (or nil), as it just takes one mutation not having been applied
			-- to trigger a reactivation. once it transitions to false from nil, it sticks. in other words
			-- all events must have already been applied for it to finish as true
			--
			-- see ActiveConfiguration:OnLootEvent() and ActivateConfiguration:OnPlayerEvent()
			if Util.Objects.Default(applied, true) then
				applied = appendix and Util.Objects.Default(appendix.appliedToAc, false) or false
			end
		end
	end

	local function ProcessEvent(id, event, detail)
		local entity = detail.entity
		if not entity then return end

		Logging:Trace("ProcessEvent(%s)[%s] : %s", id, tostring(entity.clazz.name), event)

		--- @type Models.Audit.TrafficRecord
		local record

		-- this assumes the detail's 'extra' consists of a single element and it is a table
		local detailExtra = unpack(detail.extra)

		if Util.Objects.IsInstanceOf(entity, Configuration) then
			record = TrafficRecord.For(entity)
			CheckReactivation(entity.id, detailExtra)
		elseif Util.Objects.IsInstanceOf(entity, List) then
			record = TrafficRecord.For(self:GetService().Configuration:Get(entity.configId), entity)
			CheckReactivation(entity.configId, detailExtra)
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
	for id, events in pairs(process) do
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

	Logging:Trace("_ProcessEvents(%s) : reactivate=%s, applied=%s", tostring(acId), tostring(reactivate), tostring(applied))

	if reactivate then
		-- if reactivate has been flipped to true, applied will have been set as well
		Logging:Info("_ProcessEvents(%s) : active configuration has been modified, requires reactivation (applied=%s)", acId, tostring(applied))
		AddOn:MasterLooterModule():ReactivateConfiguration(applied)
	end
end

local ConfigurationEvents = EventsQueue()
function Lists:ConfigurationDaoEvent(event, eventDetail)
	Logging:Debug("ConfigurationDaoEvent(%s) : %s", event, Util.Objects.ToString(eventDetail))
	self:_EnqueueEvent(ConfigurationEvents, event, eventDetail)
end

local ListEvents = EventsQueue()
function Lists:ListDaoEvent(event, eventDetail)
	Logging:Debug("ListDaoEvent(%s) : %s", event, Util.Objects.ToString(eventDetail))
	self:_EnqueueEvent(ListEvents, event, eventDetail)
end

--- @param self Lists
local function GetListAndPriority(self, equipment, player, active, relative)
	player = player and Player.Resolve(player) or AddOn.player
	active = Util.Objects.Default(active, true)
	relative = Util.Objects.Default(relative, false)

	--Logging:Trace("GetListAndPriority(%s, %s, %s, %s)", tostring(player), tostring(equipment), tostring(active), tostring(relative))

	--- @type Models.List.List
	local list, prio = nil, nil
	if equipment and self:HasActiveConfiguration() then
		local activeConfiguration = self:GetActiveConfiguration()
		if active then
			_, list = activeConfiguration:GetActiveListByEquipment(equipment)
		else
			_, list = activeConfiguration:GetOverallListByEquipment(equipment)
		end

		if list then
			-- need to resolve via any potential alts in this code path
			prio, _ = list:GetPlayerPriority(activeConfiguration.config:ResolvePlayer(player), relative)
		end
	end

	--[[
	Logging:Trace(
		"GetListAndPriority(%s, %s, %s, %s) : list=%s, prio=%s",
		tostring(player), tostring(equipment),  tostring(active), tostring(relative),
		list and list.id or '?', tostring(prio)
	)
	--]]

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

function Lists:DeactivateConfiguration(idOrConfig)
	local id = Util.Objects.IsInstanceOf(idOrConfig, Configuration) and idOrConfig.id or idOrConfig
	Logging:Debug("DeactivateConfiguration(%s)", tostring(idOrConfig))
	if self:HasActiveConfiguration() then
		local currentActive = self.activeConfig
		if Util.Strings.Equal(id, currentActive.config.id) then
			self.activeConfig = nil
			AddOn:Print(format(L["deactivated_configuration"], tostring(currentActive.config.name)))
		end
	end
end

--- @param idOrConfig string|Models.List.Configuration the configuration to activate
--- @param callback function<boolean, Models.List.ActiveConfiguration> callback after activation is attempted
function Lists:ActivateConfiguration(idOrConfig, callback)
	Logging:Debug("ActivateConfiguration(%s)", tostring(idOrConfig))

	if Util.Objects.IsSet(idOrConfig) then
		-- a request to activate a new configuration means any current one must be discarded
		self.activeConfig = nil
		local success, activated = pcall(
			function()
				return self.listsService:Activate(idOrConfig)
			end
		)

		if success then
			self.activeConfig = activated
			Logging:Debug("ActivateConfiguration() : Activated %s", tostring(activated))
		else
			Logging:Warn("ActivateConfiguration() : Could not activate %s - %s", tostring(idOrConfig), tostring(activated))
		end

		if Util.Objects.IsFunction(callback) then
			callback(success, self.activeConfig)
		end

		return success, self.activeConfig
	end

	return false, nil
end

local MaxActivationReattempts = 3

--- @param sender string
--- @param activation table
function Lists:OnActivateConfigReceived(sender, activation, attempt)
	attempt = Util.Objects.Default(attempt, 0)
	Logging:Debug("OnActivateConfigReceived(%s, %d)", tostring(sender), attempt)

	-- configuration activation should only originate from ML
	if not AddOn:IsMasterLooter(sender) then
		Logging:Warn("OnActivateConfigReceived() : Sender is not the master looter, ignoring")
		AddOn:PrintError(format(L["invalid_configuration_received"], tostring(sender)))
		return
	end

	if AddOn:IsMasterLooter() then
		Logging:Error("OnActivateConfigReceived() : Message should not be dispatched to Master Looter")
		AddOn:PrintError(format(L["invalid_configuration_received_ml"], tostring(sender)))
		return
	end

	local maxActivationReattemptsExceeded = (attempt > MaxActivationReattempts)
	if maxActivationReattemptsExceeded then
		Logging:Warn("OnActivateConfigReceived() : Maximum activation (re)attempts exceeded, giving up")
		AddOn:PrintError(L["invalid_configuration_max_attempts"])
	end

	-- TODO : if we're an admin or owner, but not the ML, we shouldn't send blanket requests (could overwrite local changes)
	local function EnqueueRequest(to, id, type)
		Logging:Trace("EnqueueRequest(%s, %s)",tostring(id), tostring(type))
		Util.Tables.Push(to, ListsDp:CreateRequest(type, id))
	end

	-- see MasterLooter:ActivateConfiguration() for 'activation' message contents
	-- only load reference for configuration, as activation is going to load lists
	if (not maxActivationReattemptsExceeded) and activation and Util.Tables.Count(activation) >= 1 then
		local configForActivation, toRequest = activation['config'], {}
		local resolved = self.listsService:LoadRefs({configForActivation})

		-- could not resolve the configuration for activation, will need to request it
		-- and reschedule activation
		if not resolved or #resolved ~= 1 then
			EnqueueRequest(toRequest, configForActivation.id, Configuration.name)
		else
			local activate = resolved[1]
			self:ActivateConfiguration(
				activate,
				-- this callback is entirely about verifying what we activated
				-- matches what was requested
				function(success, activated)
					if not success then
						EnqueueRequest(toRequest, activate.id, Configuration.name)
						Logging:Warn("OnActivateConfigReceived() : Could not activate configuration '%s'", activate.id)
					else
						Logging:Debug("OnActivateConfigReceived() : Activated '%s'", tostring(activated))
						-- do some checks to see if we have the correct data
						-- this is entirely for requesting the most recent data in case we are behind

						-- no need to check version and revision here, just compare hashes of data
						--
						-- we intentionally pass 'activate' as that is what was requested and we need to compare
						-- the active configuration against it
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
							-- index 2 is the list verifications
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
								Logging:Warn("OnActivateConfigReceived(%s)[List] : Extra (this should not occur unless player is the admin/owner and not current master looter)", id)
								-- no request for an extra one, the sender won't have it
								-- signifies an issue with owners/admins not having synchronized config/list data
							end
						end
					end
				end
			)
		end

		-- we have missing data, request it and reschedule activation
		if Util.Tables.Count(toRequest) > 0 then
			Logging:Warn("OnActivateConfigReceived() : Requesting %s", Util.Objects.ToString(Util.Tables.Copy(toRequest, function(r) return tostring(r) end)))
			ListsDp:SendRequest(AddOn.masterLooter, nil, unpack(toRequest))
			self:ScheduleTimer(function() self:OnActivateConfigReceived(sender, activation, attempt + 1) end, 10)
			return
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
		-- it's possible the award reason wasn't one which we display to the user
		-- E.G. ML decides to assign it to someone that passed without changing their response
		if reason and reason.suicide then
			local suicideAmt

			-- this code path is only ever invoked by ML, so don't look at ML DB, use our local settings instead
			-- we don't transmit button meta-information over the wire, which means without direct access to settings
			-- you cannot access the required meta-information
			--
			-- locate the button associated with the award reason to see if there is a modifier for suicide (spots)
			local _, button = Util.Tables.FindFn(AddOn:MasterLooterModule().db.profile.buttons, function(b) return b.key == itemAward.awardReason end)
			if button and button.suicide_amt then
				suicideAmt = tonumber(button.suicide_amt)
			end

			--Logging:Trace("OnAwardItem - %s", Util.Objects.ToString(AddOn:MasterLooterModule().db.profile.buttons))
			--Logging:Trace("OnAwardItem(%s, %s, %s)", tostring(itemAward.winner), tostring(itemAward.equipLoc), tostring(suicideAmt))

			local lid, apb, apa, opb, opa =
				self:GetActiveConfiguration():OnLootEvent(
						itemAward.winner,
						itemAward.equipLoc,
						suicideAmt
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
			_, list = self:GetActiveConfiguration():GetActiveListByEquipment(itemAward.equipLoc)
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
				if list and list.id then
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

	function Lists:SetService(service, config)
		self:UnregisterCallbacks()
		self.listsService = service
		self.activeConfig = config
		self:RegisterCallbacks()
	end
end