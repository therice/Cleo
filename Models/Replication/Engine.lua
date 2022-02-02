--- @type AddOn
local _, AddOn = ...
local C = AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type LibGuildStorage
local GuildStorage = AddOn:GetLibrary("GuildStorage")
--- @type Models.SemanticVersion
local SemanticVersion = AddOn.Package('Models').SemanticVersion
--- @type Models.List.Configuration
local Configuration = AddOn.Package('Models.List').Configuration
--- @type Models.List.List
local List = AddOn.Package('Models.List').List

local ReplicationMessageBus = {
	static = {
		messageHandlers = {},
		WithMessageHandlers = function(self, handlers)
			self.messageHandlers = handlers
		end
	},
	IsInitialized = function(self)
		return not Util.Objects.IsNil(self.comms) and not Util.Objects.IsNil(self.Send)
	end,
	WithComms = function(self, comms)
		Logging:Trace("WithComms(%s)", tostring(self))
		--- @type Core.Comm
		self.comms = comms
		self.comms:Register(C.CommPrefixes.Replication)
		self.Send = self.comms:GetSender(C.CommPrefixes.Replication)
		self.subscriptions = nil
		return self
	end,
	Dispose = function(self)
		Logging:Debug("Dispose()")
		self.comms = nil
		self.Send = nil
	end,
	SubscribeToComms = function(self)
		Logging:Trace("SubscribeToComms(%s)", tostring(self))
		if not Util.Tables.IsEmpty(self.clazz.static.messageHandlers) then
			self.subscriptions =
				self.comms:BulkSubscribe(
					C.CommPrefixes.Replication,
					--- map functions to implicitly pass 'self' as 1st argument
					Util.Tables.Copy(
						self.clazz.static.messageHandlers,
						function(handler)  return function(...) handler(self, ...) end end
					)
				)
		end
	end,
	UnsubscribeFromComms = function(self)
		Logging:Trace("UnsubscribeFromComms(%s)", tostring(self))
		if self.subscriptions then
			AddOn.Unsubscribe(self.subscriptions)
			self.subscriptions = nil
		end
	end,
}


--- a member represents and instance of player with the addon installed
--- multiple members participate as a group to elect a leader for a data replica
---
--- @class Models.Replication.Member
local Member = AddOn.Class('Models.Replication.Member')
--- @param id string the member id, which is typically a player name
--- @param isLocal boolean is the member local
--- @param term number|function the term for the member, used during election
function Member:initialize(id, isLocal, term)
	assert(Util.Objects.IsString(id) and Util.Objects.IsSet(id))
	self.id = id
	self.isLocal = isLocal
	self.term = term
end

local function TermFromEntity(entity, authz)
	local revision = entity and entity.revision or 0
	return revision, Util.Objects.Default(authz, 0)
end

function Member:IsLocal()
	return self.isLocal
end

function Member:Term()
	local revision, authz
	if Util.Objects.IsFunction(self.term) then
		revision, authz = TermFromEntity(self.term())
	else
		revision, authz = unpack(self.term)
	end

	return revision, authz
end

--- @param other Models.Replication.Member
--- @return boolean indicating if this member has priority over other member
function Member:HasPriority(other)
	Logging:Trace("HasPriority(iam=%s) : other=%s", tostring(self.id), tostring(other.id))

	-- (1) compare terms
	-- (2) if equal, look at ownership (owner > admin > none)
	-- (3) if multiple in same bucket for #2, then use id (alphabetical)
	local revisionOurs, authzOurs = self:Term()
	local revisionTheirs, authzTheirs = other:Term()

	Logging:Trace(
		"HasPriority(%s = %d, %d) : %s = %d, %d",
		tostring(self.id), revisionOurs, authzOurs,
		tostring(other.id), revisionTheirs, authzTheirs
	)

	local priority = false
	if revisionOurs > revisionTheirs then
		priority = true
	elseif revisionOurs == revisionTheirs then
		if authzOurs > authzTheirs then
			priority = true
		elseif authzOurs == authzTheirs then
			-- this is an alphabetical comparison
			-- a = "aA"
			-- b = "ab"
			-- a:lower() < b:lower()
			priority = self.id:lower() < other.id:lower()
		end
	end

	Logging:Trace("HasPriority(iam=%s) : other=%s, priority=%s", tostring(self.id), tostring(other.id), tostring(priority))

	return priority
end

function Member:__eq(o)
	return self.id == o.id
end

function Member:__tostring()
	return format("member[%s]", tostring(self.id))
end

--- @class Models.Replication.Replica
local Replica = AddOn.Class('Models.Replication.Replica')
--- @param id string
--- @param sender function
function Replica:initialize(id, sender)
	--- @type string
	self.id = id
	--- @type function
	self.Send = sender
	--- @type table<string, Models.Replication.Member>
	self.members = {}
	--- @type Models.Replication.Member
	self.leader = nil
	--- @type table see AceTimer
	self.electionTimer = nil
	--- @type boolean
	self.running = false
	--- @type function
	self.handler = nil
end

--- @param member Models.Replication.Member
function Replica:AddMember(member)
	if not self.members[member.id] then
		self.members[member.id] = member
	end
end

--- @return table<string, Models.Replication.Member>
function Replica:GetMembers(filter)
	filter = Util.Objects.IsFunction(filter) and filter or Util.Functions.True
	return Util(self.members):CopyFilter(function(member, id) return filter(id, member) end, true)()
end

--- @return Models.Replication.Member
function Replica:GetMember(member)
	local id = Util.Objects.IsInstanceOf(member, Member) and member.id or member
	if Util.Strings.IsSet(id) then
		return self.members[id]
	end

	return nil
end

function Replica:RemoveMember(member)
	local id = Util.Objects.IsInstanceOf(member, Member) and member.id or member
	if Util.Strings.IsSet(id) and self.members[id] then
		local removed = self.members[id]
		self.members[id] = nil
		if removed == self.leader then
			self:SetLeader(nil)
			self:ElectLeader()
		end
	end
end

--- @param id string member id
--- @param attrs table<string, any>
--- @return Models.Replication.Member
function Replica:EnsureMember(id, attrs)
	assert(Util.Strings.IsSet(id))
	assert(attrs and Util.Objects.IsTable(attrs))

	--- @see Models.Replication.Replica#SendMessage
	local term = attrs.term
	--- @type Models.Replication.Member
	local member
	if id and term then
		member = self:GetMember(id)
		if not member then
			member = Member(id, false, term)
			self:AddMember(member)
		else
			local revisionTheirs, authzTheirs = unpack(term)
			local revision, authz = member:Term()
			if (revisionTheirs ~= revision) or (authzTheirs ~= authz) then
				member.term = {revisionTheirs, authzTheirs}
			end
		end
	end

	return member
end


--- @return Models.Replication.Member
function Replica:LocalMember()
	local _, member = Util.Tables.FindFn(
		self.members,
		function(m) return m:IsLocal() end
	)

	return member
end

function Replica:HigherTermMembers()
	local localMember = self:LocalMember()
	Logging:Debug("HigherTermMembers(%s, %s) : %d, %d", tostring(self.id), tostring(localMember), localMember:Term())
	return self:GetMembers(
		function(_, member)
			return not Util.Strings.Equal(localMember.id, member.id) and member:HasPriority(localMember)
		end
	)
end

function Replica:OtherMembers()
	local localMember = self:LocalMember()
	Logging:Debug("OtherMembers(%s, %s)", tostring(self.id), tostring(localMember))
	return self:GetMembers(
		function(_, member)
			return not Util.Strings.Equal(localMember.id, member.id)
		end
	)
end

function Replica:Start()
	if not self.running then
		Logging:Debug("Start(%s)", tostring(self))
		self.running = true
		self:ElectLeader()
	end
end

function Replica:Stop()
	if self.running then
		Logging:Debug("Stop(%s)", tostring(self))
		self.running = false
	end
end

--- @param leader Models.Replication.Member
function Replica:SetLeader(leader)
	local localMember = self:LocalMember()
	Logging:Debug("SetLeader(%s, %s) : %s", tostring(self), tostring(localMember), tostring(leader))
	self.leader = leader
	if self.handler then
		self.handler(self.id, self.leader and self.leader.id or nil)
	end
end

function Replica:ElectLeader()
	local localMember = self:LocalMember()
	Logging:Debug("ElectLeader(%s, %s)", tostring(self), tostring(localMember))
	-- get a list of candidate members
	-- these are members who have terms greater than the local member
	local candidates = self:HigherTermMembers()
	Logging:Debug("ElectLeader(%s) : %s", tostring(self), Util.Objects.ToString(candidates))
	-- the local member has highest term, promote it to the leader and announce
	if Util.Tables.IsEmpty(candidates) then
		self:BecomeLeader()
	else
		self:StartElection()
	end
end

function Replica:BecomeLeader()
	local localMember = self:LocalMember()
	Logging:Debug("BecomeLeader(%s, %s)", tostring(self) ,tostring(localMember))
	self:SetLeader(localMember)
	self:SendCoordinatorMessage()
end

function Replica:StopElection()
	local localMember = self:LocalMember()
	Logging:Debug("StopElection(%s, %s)", tostring(self), tostring(localMember))

	if self.electionTimer then
		Logging:Debug("StopElection(%s, %s) : Cancelling timer", tostring(self), tostring(localMember))
		AddOn:CancelTimer(self.electionTimer)
		self.electionTimer = nil
	end
end

local ElectionTimeoutInSeconds = 7

function Replica:StartElection()
	local localMember = self:LocalMember()
	Logging:Debug("StartElection(%s, %s)", tostring(self), tostring(localMember))
	self:StopElection()
	self:SendElectionMessage()
	self.electionTimer = AddOn:ScheduleTimer(
		function()
			Logging:Debug(
				"StartElection(%s, %s) : No response to election, becoming leader",
				tostring(self), tostring(localMember)
			)
			self:BecomeLeader()
		end,
		ElectionTimeoutInSeconds
	)
end

function Replica:OnCoordinator(sender, message)
	local localMember = self:LocalMember()
	Logging:Debug("OnCoordinator(%s, %s) : %s from %s", tostring(self), tostring(localMember), Util.Objects.ToString(message), tostring(sender))
	if Util.Objects.IsTable(message) then
		-- this is the remote peer (sender)
		local member = self:EnsureMember(sender, message)
		if member then
			-- only accept remote as leader if it has priority over us
			if member:HasPriority(localMember) then
				self:StopElection()
				self:SetLeader(member)
			-- if not, we need to initiate a new election
			else
				self:StartElection()
			end
		end
	end
end

function Replica:OnElection(sender, message)
	local localMember = self:LocalMember()
	Logging:Debug("OnElection(%s, %s) : %s from %s", tostring(self), tostring(localMember), Util.Objects.ToString(message), tostring(sender))
	if Util.Objects.IsTable(message) then
		-- this is the remote peer (sender)
		local member = self:EnsureMember(sender, message)
		if member then
			-- if the remote peer has priority, halt any local election
			if member:HasPriority(localMember) then
				self:StopElection()
			-- peer does not have priority, send them an OK and start our own
			else
				self:SendMessage(sender, C.Commands.Ok)
				self:StartElection()
			end
		end
	end
end

function Replica:OnOk(sender, message)
	local localMember = self:LocalMember()
	Logging:Debug("OnOk(%s, %s) : %s from %s", tostring(self), tostring(localMember), Util.Objects.ToString(message), tostring(sender))
	if Util.Objects.IsTable(message) then
		-- this is the remote peer (sender)
		local member = self:EnsureMember(sender, message)
		if member then
			if member:HasPriority(localMember) then
				self:StopElection()
			end
		end
	end
end

function Replica:SendElectionMessage()
	local higherTermMembers = self:HigherTermMembers()
	Logging:Trace("SendElectionMessage(%s, %s) : %s", tostring(self), tostring(self:LocalMember()), Util.Objects.ToString(higherTermMembers))
	self:SendMessage(higherTermMembers, C.Commands.Election)
end

function Replica:SendCoordinatorMessage()
	local otherMembers = self:OtherMembers()
	Logging:Trace("SendCoordinatorMessage(%s, %s) : %s", tostring(self), tostring(self:LocalMember()), Util.Objects.ToString(otherMembers))
	self:SendMessage(otherMembers, C.Commands.Coordinator)
end

function Replica:SendMessage(to, type, extra)
	local recipients
	if not Util.Objects.IsNil(to) then
		if Util.Strings.IsSet(to) then
			recipients = { to }
		elseif Util.Objects.IsTable(to) then
			recipients = to
		else
			error("'to' type (%s) is not supported", tostring(type(to)))
		end
	else
		recipients = Util.Tables.Values(self:OtherMembers())
	end

	local message = {
		replica = self.id,
		term  = { self:LocalMember():Term() },
	}

	if extra then
		Util.Tables.CopyInto(message, extra)
	end

	for _, recipient in pairs(recipients) do
		-- map recipient unto a player name, in case of recipient being a member it will the id attribute
		recipient = Util.Objects.IsString(recipient) and recipient or recipient.id
		Logging:Debug("SendMessage(%s, %s) : %s / %s", tostring(self), tostring(recipient), tostring(type), Util.Objects.ToString(message, 3))
		self:Send(recipient, type, message)
	end
end

function Replica:__tostring()
	return format("replica[%s]", tostring(self.id))
end

--- @class Models.Replication.Engine
local Engine = AddOn.Class('Models.Replication.Engine'):include(ReplicationMessageBus)
Engine.static:WithMessageHandlers({
	--- @param self Models.Replication.Engine
	[C.Commands.PeerQuery] = function(self, data, sender)
		Logging:Debug("PeerQuery(%s) : from %s", tostring(self.member), tostring(sender))
	    if not AddOn.UnitIsUnit(sender, self.member) then
	        self:OnPeerQuery(sender, unpack(data))
	    end
	end,
	--- @param self Models.Replication.Engine
	[C.Commands.PeerReply] = function(self, data, sender)
		Logging:Debug("PeerReply(%s) : from %s", tostring(self.member), tostring(sender))
	    if not AddOn.UnitIsUnit(sender, self.member) then
			self:OnPeerReply(sender, unpack(data))
	    end
	end,
	[C.Commands.PeerLeft] = function(self, _, sender)
		Logging:Debug("PeerLeft(%s) : from %s",  tostring(self.member), tostring(sender))
		if not AddOn.UnitIsUnit(sender, self.member) then
			self:OnPeerStatusChanged(sender, false)
		end
	end,
	[C.Commands.Coordinator] = function(self, data, sender)
		Logging:Debug("Coordinator(%s) : from %s",  tostring(self.member), tostring(sender))
	    if not AddOn.UnitIsUnit(sender, self.member) then
		    local message = unpack(data)
		    Logging:Trace("Coordinator(%s) : from %s with %s", tostring(self.member), tostring(sender), Util.Objects.ToString(message))
		    -- the message will have a replica id and term
		    --- @type Models.Replication.Replica
		    local replica = self:GetReplica(message)
		    if replica then
			    replica:OnCoordinator(sender, message)
		    end
	    end
	end,
	[C.Commands.Election] = function(self, data, sender)
		Logging:Debug("Election(%s) : from %s",  tostring(self.member), tostring(sender))
		if not AddOn.UnitIsUnit(sender, self.member) then
			local message = unpack(data)
			Logging:Trace("Election(%s) : from %s with %s", tostring(self.member), tostring(sender), Util.Objects.ToString(message))
			-- the message will have a replica id and term
			--- @type Models.Replication.Replica
			local replica = self:GetReplica(message)
			if replica then
				replica:OnElection(sender, message)
			end
		end
	end,
	[C.Commands.Ok] = function(self, data, sender)
		Logging:Debug("Ok(%s) : from %s",  tostring(self.member), tostring(sender))
		if not AddOn.UnitIsUnit(sender, self.member) then
			local message = unpack(data)
			Logging:Trace("Ok(%s) : from %s with %s", tostring(self.member), tostring(sender), Util.Objects.ToString(message))
			-- the message will have a replica id and term
			--- @type Models.Replication.Replica
			local replica = self:GetReplica(message)
			if replica then
				replica:OnOk(sender, message)
			end
		end
	end
})

--- @param member Models.Player
function Engine:initialize(member)
	-- the local member, which is a Player
	-- typically this will be the player who is using the addon, but in testing it's allowed for it to be overridden
	--- @type Models.Player
	self.member = member
	--- @type table<string, Models.Replication.Replica>
	self.replicas = {}
	--- peers is a table of player to associated data, which can potentially be converted to members
	--- not all peers necessarily become members
	--- @type table<string, table>
	self.peers = {}
	-- this is a function which is invoked when a leader is elected for a replica
	self.handler = Util.Functions.Noop
end


function Engine:LocalMemberId()
	return self.member.name
end

function Engine:CreateReplicaDefinitions()
	Logging:Trace("CreateReplicaDefinitions()")

	local replicaDefs = {}
	--- @type  Models.List.Service
	local entityProvider = self:EntityProvider()

	local function replica(entity)
		local replicaId =
			Util.Memoize.Memoize(
				function() return Util.Strings.Join(':', entity.clazz.name, entity.id) end
			)
		local entitySupplier = function()
			local e, authzSource = entityProvider:GetDao(entity.clazz):Get(entity.id), nil
			if Util.Objects.IsInstanceOf(entity, Configuration) then
				authzSource = e
			-- if the entity is a List, we need to get authz from Configuration (which must be loaded)
			elseif Util.Objects.IsInstanceOf(entity, List) then
				authzSource = entityProvider:GetDao(Configuration):Get(entity.configId)
			end

			return e, authzSource:PlayerPermissionsToOrdinal(self.member)
		end

		return {
			-- will be of form <Type>:<Id>, e.g. "Configuration:61534E26-36A0-4F24-51D7-BE511B88B834"
			id = replicaId,
			-- a function which returns the entity represented by the id and the player's authorization (e.g. Models.List.Configuration instance)
			entity = entitySupplier
		}
	end

	local configs, lists = entityProvider:Configurations(true), nil

	for id, config in pairs(configs) do
		Util.Tables.Push(replicaDefs, replica(config))
		lists = entityProvider:Lists(id)
		for _, list in pairs(lists) do
			Util.Tables.Push(replicaDefs, replica(list))
		end
	end

	Logging:Trace("CreateReplicaDefinitions() : %d", Util.Tables.Count(replicaDefs))

	return replicaDefs
end

function Engine:OnPeerQuery(sender, message)
	Logging:Debug("OnPeerQuery(%s): from %s", tostring(self.member),  tostring(sender))
	if Util.Objects.IsTable(message) then
		local version, replicas = SemanticVersion(message.version), message.replicas
		-- nil out prerelease as not relevant but significant for comparison
		version.prerelease = nil

		Logging:Debug(
			"OnPeerQuery(%s, %s) : processing %s",
			tostring(sender), tostring(version), Util.Objects.ToString(replicas)
		)

		-- a query also indicates the addition of a peer
		self:AddPeer(sender, replicas)

		local response = {
			version = AddOn.version,
			replicas = {}
		}

		for _, replica in pairs(self.replicas) do
			local lmember = replica:LocalMember()
			Logging:Debug("OnPeerQuery(%s) : %s / %s", tostring(lmember), tostring(replica), tostring(replica))
			response.replicas[replica.id] = { lmember:Term() }
		end

		Logging:Trace("OnPeerQuery(%s) : sending %s to %s", tostring(self.member), Util.Objects.ToString(response, 3),  tostring(sender))
		self:Send(sender, C.Commands.PeerReply, response)
	end
end

function Engine:OnPeerReply(sender, message)
	Logging:Debug("OnPeerReply(%s): %s from %s", tostring(self.member), Util.Objects.ToString(message), tostring(sender))
	if Util.Objects.IsTable(message) then
		local version, replicas = SemanticVersion(message.version), message.replicas
		-- nil out prerelease as not relevant but significant for comparison
		version.prerelease = nil

		Logging:Debug(
			"OnPeerReply(%s) : processing %s / %s from %s",
			tostring(self.member), tostring(version), Util.Objects.ToString(replicas), tostring(sender)
		)

		self:AddPeer(sender, replicas)
	end
end

--- @return Models.List.Service
function Engine:EntityProvider()
	return AddOn:ListsModule():GetService()
end

--- @param replica Models.Replication.Replica
function Engine:AddReplica(replica)
	if replica then
		replica.handler = self.handler
		self.replicas[replica.id] = replica
	end

	return replica
end

--- @return Models.Replication.Replica
function Engine:GetReplica(id)
	id = Util.Objects.IsTable(id) and id.replica or id
	return self.replicas[id]
end

function Engine:AddPeer(peer, data)
	Logging:Trace("AddPeer(%s) : %s", Util.Objects.ToString(peer), Util.Objects.ToString(data))
	self.peers[peer] = Util.Tables.Copy(data)
end

function Engine:RemovePeer(peer)
	if self.peers[peer] then
		self.peers[peer] = nil
		for _, replica in pairs(self.replicas) do
			replica:RemoveMember(peer)
		end
	end
end

function Engine:SetPeers(peers)
	self.peers = Util.Tables.Copy(peers)
end

function Engine:OnPeerStatusChanged(peer, online)
	Logging:Trace("OnPeerStatusChanged(%s, %s)", tostring(peer), tostring(online))
	-- we don't need to handle a player coming online, just offline
	-- as we'll detect new players (peers) through them initiating an election themselves
	if not online then
		self:RemovePeer(peer)
	end
end

--- @param processor function post processing function of peers
function Engine:QueryPeers(processor)
	Logging:Debug("QueryPeers()")
	local message = {
		version = AddOn.version,
		replicas  = {}
	}

	--- @type Models.Replication.Replica
	for _, replica in pairs(self.replicas) do
		message.replicas[replica.id] = {replica:LocalMember():Term()}
	end

	-- reset peers before we query
	self:SetPeers({})
	self:Send(C.guild, C.Commands.PeerQuery, message)

	if Util.Objects.IsFunction(processor) then
		-- 7 seconds should be sufficient to get responses from peers via PeerQuery
		AddOn.Timer.After(
			7,
			function()
				processor(self.peers)
				-- also register callbacks for status changes (online/offline)
				-- this allows peer list ot be maintained as players status change
				GuildStorage.RegisterCallback(
					self,
					GuildStorage.Events.GuildMemberOnlineChanged,
					function(_, player, online) self:OnPeerStatusChanged(player, online) end
				)
			end
		)
	end
end

function Engine:StartReplicas(peers)
	peers = Util.Objects.Default(peers, self.peers)
	Logging:Debug("StartReplicas() : peers => %s", Util.Objects.ToString(peers))

	--- @type Models.Replication.Replica
	local replica
	--- @type Models.Replication.Member
	local member

	-- this iterates all the current peers and makes sure
	-- they are added to the replica
	for peerId, peerData in pairs(peers) do
		for replicaId, term in pairs(peerData) do
			replica = self:GetReplica(replicaId)
			-- if this is a new replica, create it now
			-- this indicates a peer with a data partition (id) we don't currently have
			-- as opposed to one we have, but may be out of date
			if not replica then
				replica = self:AddReplica(Replica(replicaId, self.Send))
				member = Member(self:LocalMemberId(), true, term)
				replica:AddMember(member)
			end

			-- always add the remote peer to replica
			member = Member(peerId, false, term)
			replica:AddMember(member)
		end
	end

	Logging:Debug("StartReplicas() : replicas => %s", Util.Objects.ToString(self.replicas))

	-- finally, start the replica
	for _, r in pairs(self.replicas) do
		r:Start()
	end
end


--- @param comm Core.Comm
--- @param handler function
function Engine:Initialize(comm, handler)
	if self:IsInitialized() then
		error("Replication has already been initialized")
	end

	Logging:Debug("Initialize()")

	self.handler = Util.Objects.Default(handler, Util.Functions.Noop)
	if not self.member then
		self.member = AddOn.player
	end

	local function Initiate(replicas)
		-- there can be multiple replicas, each consisting of a different
		-- set of members (e.g. when a member doesn't know about a given replica)
		--- @type Models.Replication.Replica
		local replica
		--- @type Models.Replication.Member
		local member
		-- this establishes replicas and adds current player
		-- as a member, peers are queried and potentially added as members after
		for _, replicaMeta in pairs(replicas) do
			replica = self:AddReplica(Replica(replicaMeta.id(), self.Send))
			member = Member(self:LocalMemberId(), true, replicaMeta.entity)
			replica:AddMember(member)
		end

		Logging:Debug("Initialize[Initiate]() : replicas => %s", Util.Objects.ToString(Util.Tables.Keys(self.replicas)))

		--- query members in advance of starting replicas
		self:QueryPeers(function(peers) self:StartReplicas(peers) end)
	end

	-- only perform election while in guild (group is handled elsewhere)
	if IsInGuild() then
		self:WithComms(comm):SubscribeToComms()
		local replicas = self:CreateReplicaDefinitions()

		-- need to wait for guild storage to settle, then can proceed
		-- otherwise, could prematurely initiate election and miss potential members
		if GuildStorage:GetState() == GuildStorage.States.Current then
			Initiate(replicas)
		else
			GuildStorage.RegisterCallback(
				self,
				GuildStorage.Events.StateChanged,
				function(_, state)
					if state == GuildStorage.States.Current then
						GuildStorage.UnregisterCallback(self, GuildStorage.Events.StateChanged)
						Initiate(replicas)
					end
				end
			)
		end
	end
end

function Engine:Shutdown()
	if self:IsInitialized() then
		Logging:Debug("Shutdown()")

		for _, replica in pairs(self.replicas) do
			replica:Stop()
		end

		self.replicas = {}
		self.peers = {}

		--- the engine is being shutdown, but player is not necessarily going offline
		--- send a message so other peers know this is occurring
		--- possible this should just be set to other peers and not guild
		self:Send(C.guild, C.Commands.PeerLeft)
		self:UnsubscribeFromComms()
		self:Dispose()
	end
end

--- @class Models.Replication.Replicate
--- @field public engine Models.Replication.Engine
local Replicate = AddOn.Instance(
	'Models.Replication.Replicate',
	function()
		return {
			--- @type Models.Replication.Engine
			engine = Engine()
		}
	end
)

--- @param comm Core.Comm
--- @param handler function<string, string>
function Replicate:Initialize(comm, handler)
	self.engine:Initialize(comm, handler)
end

--- @return boolean is replication running
function Replicate:IsRunning()
	return self.engine:IsInitialized()
end

function Replicate:Shutdown()
	self.engine:Shutdown()
end

if AddOn._IsTestContext('Models_Replication') then
	function Replicate.Member(...)
		return Member(...)
	end

	function Replicate.Replica(...)
		return Replica(...)
	end

	function Replicate.Engine(...)
		return Engine(...)
	end
end