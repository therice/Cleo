--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Models.CompressedDb
local CDB = AddOn.ImportPackage('Models').CompressedDb
--- @type Models.Date
local Date = AddOn.ImportPackage('Models').Date
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @type Models.Audit.TrafficRecord
local TrafficRecord = AddOn.ImportPackage('Models.Audit').TrafficRecord

--- @class TrafficAudit
local TrafficAudit = AddOn:NewModule("TrafficAudit")

TrafficAudit.defaults = {
	profile = {
		enabled = true,
	},
	factionrealm = {

	}
}
TrafficAudit.StatsIntervalInDays = 90


function TrafficAudit:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.Libs.AceDB:New(AddOn:Qualify('TrafficAudit'), TrafficAudit.defaults)
	self.history = CDB(self.db.factionrealm)
	self.stats = {stale = true, value = nil}
	self.Send = Comm():GetSender(C.CommPrefixes.Audit)
	--[[
	AddOn:SyncModule():AddHandler(
			self:GetName(),
			L['traffic_history'],
			function () return self:GetDataForSync() end,
			function(data) self:ImportDataFromSync(data) end
	)
	--]]
end

function TrafficAudit:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:SubscribeToComms()
end

function TrafficAudit:OnDisable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:UnsubscribeFromComms()
end

--- @return Models.CompressedDb
function TrafficAudit:GetHistory()
	return self.history
end

function TrafficAudit:SubscribeToComms()
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	self.commSubscriptions = Comm():BulkSubscribe(C.CommPrefixes.Audit, {
		[C.Commands.TrafficAuditAdd] = function(data, sender)
			Logging:Debug("TrafficAuditAdd from %s", tostring(sender))
			local record = TrafficRecord:reconstitute(unpack(data))
			self:OnRecordAdd(record)
		end
	})
end

function TrafficAudit:UnsubscribeFromComms()
	Logging:Debug("UnsubscribeFromComms(%s)", self:GetName())
	AddOn.Unsubscribe(self.commSubscriptions)
	self.commSubscriptions = nil
end

--- @param record Models.Audit.TrafficRecord
function TrafficAudit:OnRecordAdd(record)
	Logging:Trace("OnRecordAdd() : %s", Util.Objects.ToString(record and record:toTable() or {}))
	self:GetHistory():insert(record:toTable())
	self.stats.stale = true
end

--- @param record Models.Audit.TrafficRecord
function TrafficAudit:Broadcast(record)
	-- if in test mode and not development mode, return
	if (AddOn:TestModeEnabled() and not AddOn:DevModeEnabled()) then return end

	local channel = (IsInRaid() or IsInGroup()) and C.group or (IsInGuild() and C.guild or C.player)
	self:Send(channel, C.Commands.TrafficAuditAdd, record)
end

function TrafficAudit:LaunchpadSupplement()
	return L["traffic_audit"], function(container) self:LayoutInterface(container) end , true
end