--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @type Models.Player
local Player = AddOn.Package('Models').Player

--- @class Sync
local Sync = AddOn:NewModule("Sync")

local Responses = {
	Declined    = { id = 1, msg = L['sync_response_declined'] },
	Unavailable = { id = 2, msg = L['sync_response_unavailable'] },
	Unsupported = { id = 3, msg = L['sync_response_unsupported'] },
}
Sync.Responses = Responses

local IdToResponseKey = Util(Responses):Copy():Map(function (e) return e.id end):Flip()()
local function GetResponseById(id)
	local key = IdToResponseKey[tonumber(id)]
	if key then
		return Responses[key]
	else
		return {}
	end
end

function Sync:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.handlers = {}
	self.streams = {}
	self.ts = 0
	self.Send = Comm():GetSender(C.CommPrefixes.Sync)
	self:SubscribeToComms()
end

function Sync:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:SubscribeToTransientComms()
	self:GetFrame()
	self:Show()
end

function Sync:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self:Hide()
	AddOn.Unsubscribe(self.commSubscriptionsTransient)
	self.commSubscriptionsTransient = {}
end

function Sync:EnableOnStartup()
	return false
end

function Sync:SubscribeToComms()
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	self.commSubscriptions = Comm():BulkSubscribe(C.CommPrefixes.Sync, {
		[C.Commands.SyncSYN] = function(data, sender)
			Logging:Debug("SyncSYN from %s", tostring(sender))
			self:SyncSYNReceived(Player:Get(sender), unpack(data))
		end,
		[C.Commands.SyncNACK] = function(data, sender)
			Logging:Debug("SyncNACK from %s", tostring(sender))
			self:SyncNACKReceived(Player:Get(sender), unpack(data))
		end
	})
end

function Sync:SubscribeToTransientComms()
	self.commSubscriptionsTransient = Comm():BulkSubscribe(C.CommPrefixes.Sync, {
		[C.Commands.SyncACK] = function(data, sender)
			Logging:Debug("SyncACK from %s", tostring(sender))
			self:SyncACKReceived(Player:Get(sender), unpack(data))
		end,
		[C.Commands.Sync] = function(data, sender)
			Logging:Debug("Sync from %s", tostring(sender))
			self:SyncDataReceived(Player:Get(sender), unpack(data))
		end
	})
end

function Sync:AddHandler(name, desc, send, receive)
	if AddOn._IsTestContext(self:GetName()) and not self.handlers then return end

	if Util.Strings.IsEmpty(name) then error("AddHandler() : must provide name") end
	if Util.Strings.IsEmpty(desc) then error("AddHandler() : must provide description") end
	if not Util.Objects.IsFunction(send) then error("AddHandler() : must provide a function for send()") end
	if not Util.Objects.IsFunction(receive) then error("AddHandler() : must provide a function for receive()") end

	self.handlers[name] = {
		desc = desc,
		send = send,
		receive = receive,
	}
end

function Sync:HandlersSelect()
	return Util(self.handlers):Copy():Map(function (e) return e.desc end)()
end

function Sync:AddStream(name, type, data)
	Logging:Debug("AddStream() : %s, %s", name, AddOn:UnitName(name))
	self.streams[name] = {[type] = data}
end

function Sync:GetStream(name)
	Logging:Debug("GetStream() : %s, %s", name, AddOn:UnitName(name))
	return self.streams[name]
end

function Sync:DropStream(name)
	Logging:Debug("DropStream() : %s, %s", name, AddOn:UnitName(name))
	self.streams[name] = nil
end

function Sync:OnSyncAccept(data)
	Logging:Debug("OnSyncAccept() : %s", Util.Objects.ToString(data))
	local sender, type = unpack(data)
	self:Send(sender, C.Commands.SyncACK, type)
	self:UpdateStatus(nil, _G.RETRIEVING_DATA)
end

function Sync:OnSyncDeclined(data)
	Logging:Debug("OnSyncDelcine() : %s", Util.Objects.ToString(data))
	local sender, type = unpack(data)
	self:DeclineSync(sender, type, Sync.Responses.Declined.id)
end

function Sync:DeclineSync(sender, type, reason)
	Logging:Debug("DeclineSync() : %s, %s, %s", tostring(sender), tostring(type), tostring(reason))
	self:Send(sender, C.Commands.SyncNACK, type, reason)
end

local SyncSYNInterval = 15

function Sync:SendSyncSYN(target, type, data)
	Logging:Debug("SendSyncSYN() : %s, %s", target, type)

	if time() - self.ts < (AddOn:DevModeEnabled() and 0 or SyncSYNInterval) then
		return AddOn:Print(format(L["sync_rate_exceeded"], SyncSYNInterval))
	end

	-- targets could be an individual player or a keyword that indicates a group of players
	-- handle that here, then iterate through each
	local targets = {}
	if Util.Objects.In(target, C.guild, C.group) then
		if Util.Strings.Equal(target, C.guild) then
			targets = self:AvailableGuildTargets()
		elseif Util.Strings.Equal(target, C.group) then
			targets = self:AvailableGroupTargets()
		end
		targets = Util.Tables.Keys(targets)
	else
		Util.Tables.Push(targets, target)
	end

	Logging:Debug("SendSyncSYN() : %s => %s", target, Util.Objects.ToString(targets))
	if Util.Tables.Count(targets) == 0 then
		AddOn:Print(format(L["sync_target_none_avail"], target))
		Logging:Debug("SendSyncSYN() : No sync targets available for selection %s", target)
		return
	end

	for _, t in pairs(targets) do
		Logging:Debug("SendSyncSYN() : Sending 'SyncSYN' to %s", t)
		self:Send(t, C.Commands.SyncSYN, type)
		self:AddStream(t, type, data)
	end

	self.ts = time()
end

function Sync:SendSyncData(target, type)
	Logging:Debug("SendSyncData() : Sending %s to %s", type, target:GetName())
	self:SendBulk(target, C.Commands.Sync, type, self:GetStream(target:GetName())[type])
	Logging:Debug("SendSyncData() : Sent %s to %s", type, target:GetName())
end

function Sync:SyncSYNReceived(sender, type)
	Logging:Debug("SyncSYNReceived() : %s, %s", sender:GetName(), type)
	--
	-- don't allow for other players to spam sync requests should
	-- we not have the sync interface open
	--
	-- prevents malicious activity and also general interruption of game play
	--
	if not self:IsEnabled() or not self:IsVisible() then
		return self:DeclineSync(sender, type, Responses.Unavailable.id)
	end

	local handler = self.handlers[type]
	if handler then
		local data = {sender, type, handler.desc}
		if AddOn._IsTestContext() then
			self:OnSyncAccept(data)
		else
			Sync.ConfirmSyncShow(data)
		end
	else
		self:DeclineSync(sender, type, Responses.Unsupported.id)
	end
end

function Sync:SyncNACKReceived(sender, type, responseId)
	Logging:Debug("SyncNACKReceived() : %s, %s, %s",  sender:GetName(), type, tostring(responseId))
	self:DropStream(sender:GetName())
	local response = GetResponseById(responseId)
	AddOn:Print(format(response.msg, sender:GetName(), type))
end

function Sync:SyncACKReceived(sender, type)
	Logging:Debug("SyncACKReceived() : %s, %s", sender:GetName(), type)
	local stream = self:GetStream(sender:GetName())
	if not stream or not stream[type] then
		Logging:Warn("SyncACKReceived() : '%s' data unavailable for syncing to %s", type, sender:GetName())
		return AddOn:Print(format(L["sync_error"], type, sender:GetName()))
	end
	self:SendSyncData(sender, type)
	self:DropStream(sender:GetName())
	AddOn:Print(format(L['sync_starting'], AddOn.GetDateTime(), type, sender:GetName()))
end

function Sync:SyncDataReceived(sender, type, data)
	Logging:Debug("SyncDataReceived() : %s, %s", sender:GetName(), tostring(type))
	self:UpdateStatus(nil, L["data_received"])
	local handler = self.handlers[type]
	if handler then
		AddOn:Print(format(L['sync_receipt_compelete'], AddOn.GetDateTime(), type, sender:GetName()))
		handler.receive(data)
	else
		Logging:Warn("SyncDataReceived() : unsupported type %s from %s", type, sender:GetName())
	end
end

function Sync:SendBulk(target, command, ...)
	Comm():Send {
		prefix = C.CommPrefixes.Sync,
		target = target,
		command = command,
		data = {...},
		prio = 'BULK',
		callback =  self.OnDataTransmit,
		callbackarg = self
	}
end
