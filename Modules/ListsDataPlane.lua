--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @type Models.List.Configuration
local Configuration = AddOn.Package('Models.List').Configuration
--- @type Models.List.List
local List = AddOn.Package('Models.List').List
--- @class ListsDataPlane
local ListsDP = AddOn:NewModule('ListsDataPlane', "AceEvent-3.0", "AceBucket-3.0", "AceTimer-3.0", "AceHook-3.0")
--- @type Lists
local Lists
--- @type Models.Replication.Replicate
local Replicate = AddOn.RequireOnUse('Models.Replication.Replicate')

local Base = AddOn.Class('Lists.Base')
--- @class Lists.Request
local Request = AddOn.Package('Lists'):Class('Request', Base)
--- @class Lists.Response
local Response = AddOn.Package('Lists'):Class('Response', Base)

function ListsDP:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	-- this is used for holding on to pending requests for configs and list
	-- for verifying responses were actually merited. it's used for nothing else
	self.requestsTemp = {}
	Lists = AddOn:ListsModule()
	self.Send = Comm():GetSender(C.CommPrefixes.Lists)
end

function ListsDP:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:SubscribeToComms()
	self:RegisterMessage(C.Messages.ModeChanged, "OnModeChange")
	self:ScheduleTimer(
		function()
			if not AddOn._IsTestContext() then
				self:InitiateReplication()
			end
		end,
		5
	)
end

function ListsDP:OnDisable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:UnsubscribeFromComms()
	self:UnregisterMessage(C.Messages.ModeChanged)
end

function ListsDP:EnableOnStartup()
	return true
end

function ListsDP:SubscribeToComms()
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	self.commSubscriptions = Comm():BulkSubscribe(C.CommPrefixes.Lists, {
		[C.Commands.ConfigResourceRequest] = function(data, sender)
			Logging:Debug("ConfigResourceRequest from %s", tostring(sender))
			self:OnResourceRequest(sender, unpack(data))
		end,
		[C.Commands.ConfigResourceResponse] = function(data, sender)
			Logging:Debug("ConfigResourceResponse from %s", tostring(sender))
			self:OnResourceResponse(sender, unpack(data))
		end,
		[C.Commands.ConfigBroadcast] = function(data, sender)
			Logging:Debug("ConfigBroadcast from %s", tostring(sender))
			--don't consume our own broadcast (unless we're in dev mode)
			if not AddOn.UnitIsUnit(sender, AddOn.player) or AddOn:DevModeEnabled() then
				self:OnBroadcastReceived(unpack(data))
			end
		end,
	})
end

function ListsDP:UnsubscribeFromComms()
	Logging:Debug("UnsubscribeFromComms(%s)", self:GetName())
	AddOn.Unsubscribe(self.commSubscriptions)
	self.commSubscriptions = nil
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

--- @return Lists.Request
function ListsDP:CreateRequest(type, id)
	return Request(type, id)
end

function ListsDP:SendRequest(to, callback, ...)
	to = to or AddOn.masterLooter
	callback = callback or Util.Functions.Noop

	Logging:Trace("SendRequest(%s)", (to and tostring(to) or nil))

	if not to then
		Logging:Warn("SendRequest() : target not specified, not sending")
		return
	end

	for _, r in Util.Objects.Each(Util.Tables.Temp(...)) do
		self.requestsTemp[r.cid] = callback
		self:Send(to, C.Commands.ConfigResourceRequest, r)
	end
end

function ListsDP:OnResourceRequest(sender, payload)
	Logging:Trace("OnResourceRequest() : from %s", tostring(sender))

	--- @type Lists.Request
	local request = Request:reconstitute(payload)
	if request then
		Logging:Trace("OnResourceRequest() : %s from %s", tostring(request), tostring(sender))
		if request:IsValid() then
			local resource

			if Util.Strings.Equal(request.type, Configuration.name) then
				resource = Lists:GetService().Configuration:Get(request.id)
			elseif Util.Strings.Equal(request.type, List.name) then
				resource = Lists:GetService().List:Get(request.id)
			else
				Logging:Warn("OnResourceRequest() : unsupported request type %s", request.type)
				return
			end

			local response = Response(request.type, request.id, request.cid)
			response.payload = resource:toTable()
			self:SendResponse(sender, response)
		end
	end
end

function ListsDP:SendResponse(to, ...)
	if not to then
		Logging:Warn("SendResponse() : target not specified, not sending")
		return
	end
	Logging:Trace("SendResponse() : to %s", tostring(to))

	for _, r in Util.Objects.Each(Util.Tables.Temp(...)) do
		self:Send(to, C.Commands.ConfigResourceResponse, r)
	end
end

function ListsDP:OnResourceResponse(sender, payload)
	-- Logging:Trace("OnResourceResponse(%s) : %s", tostring(sender), Util.Objects.ToString(payload))
	--- @type Lists.Response
	local response = Response:reconstitute(payload)
	Logging:Trace("OnResourceResponse() : %s from %s", tostring(response and response or nil), tostring(sender))
	if response then
		local resource = response:ResolvePayload()
		if resource then

			local callback = self.requestsTemp[response.cid]
			if Util.Objects.IsNil(callback) then
				Logging:Warn("OnResourceResponse() : no pending request %s for response from %s", tostring(response.cid),  tostring(sender))
				return
			end

			Logging:Trace("OnResourceResponse() : Adding %s (%s) from %s",  tostring(resource.clazz.name), tostring(resource.id), tostring(sender))
			-- todo : should add some logic here for ignoring the update if two admins (or owner) are interacting
			-- todo : as they could have different/conflicting versions of resource
			-- todo : this is unlikely to be right place to do that though and instead in the requesting code

			-- persist the payload
			-- intentionally do not fire callbacks on the adds as they could result in
			-- traffic audit events being generated, configuration re-activation (when unnecessary), etc.
			-- these adds are a direct result of a resource being out of date or missing with another authoritative player
			if Util.Objects.IsInstanceOf(resource, Configuration) then
				Lists:GetService().Configuration:Add(resource, false)
			elseif Util.Objects.IsInstanceOf(resource, List) then
				Lists:GetService().List:Add(resource, false)
			end

			Util.Functions.try(
				function()
					Logging:Trace("OnResourceResponse() : invoking callback with %s (from %s)", tostring(resource), tostring(sender))
					callback(resource)
				end
			).finally(
				function()
					self.requestsTemp[response.cid] = nil
					self:SendMessage(C.Messages.ResourceRequestCompleted, resource)
				end
			)
		end
	end
end

--- broadcasts the specified configuration and any associated lists to specified target
---
--- @param configId number the configuration identifier
--- @param target string the target channel to which to broadcast
function ListsDP:Broadcast(configId, target)
	Logging:Debug("Broadcast(%s, %s)", tostring(configId), tostring(target))

	if Util.Strings.IsSet(configId) and Util.Strings.IsSet(target) then
		local config = Lists:GetService().Configuration:Get(configId)
		if config and config:IsAdminOrOwner(AddOn.player) then
			local lists = Lists:GetService():Lists(configId)
			self:Send(target, C.Commands.ConfigBroadcast, {config = config, lists = lists or {}})
		end
	end
end

-- todo : if admin or owner make sure we don't overwrite local changes
function ListsDP:OnBroadcastReceived(payload)
	Logging:Debug("OnBroadcastReceived()")

	local config = Configuration:reconstitute(payload.config)
	if config then
		local lists = Util.Tables.Map(payload.lists, function(v) return List:reconstitute(v) end)
		Logging:Debug("OnBroadcastReceived() : config id = %s, list count = %d", tostring(config.id), Util.Tables.Count(lists))
		local service = Lists:GetService()
		-- todo : fire callbacks?
		-- add will overwrite any current data (no need to delete in advance)
		service.Configuration:Add(config, false)
		Logging:Debug("OnBroadcastReceived() : updated/added config id = %s", tostring(config.id))

		for _, list in pairs(lists) do
			service.List:Add(list, false)
			Logging:Debug("OnBroadcastReceived() : updated/added config id = %s, list id = %s", tostring(config.id), tostring(list.id))
		end

		Lists:Refresh()

		-- we just received a broadcast of a configuration and the associated lists
		-- could re-query peers for updated details, but easier to just restart replication
		-- and let normal bootstrap process update them
		self:RestartReplication()
	end
end

--- @param replica Models.Replication.Replica the replica for which the leader has changed
function ListsDP:OnReplicaLeaderChanged(replica)
	Logging:Debug("OnReplicaLeaderChanged() : %s", tostring(replica))

	local localMember, leader = replica:LocalMember(), replica.leader
	-- if a leader was established then see if we need to request an update on data (not us and term is greater)
	if leader and not Util.Objects.Equals(leader, localMember) then
		local behind = localMember:IsBehind(leader)
		Logging:Debug(
			"OnReplicaLeaderChanged(%s - %s [LOCAL]) : %s [LEADER] BEHIND(%s)",
			tostring(replica), tostring(localMember), tostring(leader), tostring(behind)
		)

		if behind then
			local typeAndId = Util.Strings.Split(replica.id, ':')
			self:SendRequest(leader.id, function() replica:LocalMemberUpdated(false) end, self:CreateRequest(typeAndId[1], typeAndId[2]))
		end
	end
end

function ListsDP:GetReplicaLeader(entity)
	if Replicate():IsRunning() then
		return Replicate():GetLeader(entity)
	else
		return nil
	end
end

function ListsDP:OnModeChange(_, _, flag, enabled)
	-- ignore it unless the flag was replication
	if flag == C.Modes.Replication then
		local running = Replicate():IsRunning()
		if enabled and not running then
			self:InitiateReplication()
		elseif not enabled and running then
			Replicate():Shutdown()
		end
	end
end

function ListsDP:OnGroupEvent()
	if AddOn:ReplicationModeEnabled() then
		local inGroup, replicationRunning = IsInGroup(), Replicate():IsRunning()
		-- in a group and replication is running, stop it
		if inGroup and replicationRunning then
			Replicate():Shutdown()
			-- not in a group and replication is not running, start it
		elseif not inGroup and not replicationRunning then
			self:InitiateReplication()
		end
	end
end

function ListsDP:RestartReplication()
	Logging:Debug("RestartReplication()")
	if AddOn:ReplicationModeEnabled() and Replicate:IsRunning() then
		Replicate():Shutdown()
		-- use a random delay between 2 and 5 seconds so replication election is somewhat
		-- staggered between players
		AddOn.Timer.After(math.random(2, 5), function() self:InitiateReplication() end)
	end
end

function ListsDP:InitiateReplication()
	Logging:Debug("InitiateReplication()")
	if AddOn:ReplicationModeEnabled() then
		Replicate():Initialize(Comm(), function(...) self:OnReplicaLeaderChanged(...) end)
	end
end

if AddOn._IsTestContext() then
	function ListsDP:ReconstructResponse(payload)
		return Response:reconstitute(payload)
	end
end