--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Models.CompressedDb
local CDB = AddOn.ImportPackage('Models').CompressedDb
--- @type Models.Audit.LootRecord
local LootRecord =  AddOn.ImportPackage('Models.Audit').LootRecord
--- @type Models.Audit.LootStatistics
local LootStatistics =  AddOn.ImportPackage('Models.Audit').LootStatistics
--- @type Models.Date
local Date = AddOn.ImportPackage('Models').Date
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')

--- @class LootAudit
local LootAudit = AddOn:NewModule("LootAudit")

LootAudit.defaults = {
	profile = {
		enabled = true,
	},
	factionrealm = {

	}
}
LootAudit.StatsIntervalInDays = 90

function LootAudit:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.Libs.AceDB:New(AddOn:Qualify('LootAudit'), LootAudit.defaults)
	self.history = CDB(self.db.factionrealm)
	self.stats = {stale = true, value = nil}
	self.Send = Comm():GetSender(C.CommPrefixes.Audit)
	--[[
	AddOn:SyncModule():AddHandler(
			self:GetName(),
			L['loot_history'],
			function() return self:GetDataForSync() end,
			function(data) self:ImportDataFromSync(data) end
	)
	--]]
end

function LootAudit:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:SubscribeToComms()
end

function LootAudit:OnDisable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:UnsubscribeFromComms()
end

--- @return Models.CompressedDb
function LootAudit:GetHistory()
	return self.history
end

function LootAudit:SubscribeToComms()
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	self.commSubscriptions = Comm():BulkSubscribe(C.CommPrefixes.Audit, {
		[C.Commands.LootAuditAdd] = function(data, sender)
			Logging:Debug("LootAuditAdd from %s", tostring(sender))
			local record = LootRecord:reconstitute(unpack(data))
			self:OnRecordAdd(record)
		end
	})
end

function LootAudit:UnsubscribeFromComms()
	Logging:Debug("UnsubscribeFromComms(%s)", self:GetName())
	AddOn.Unsubscribe(self.commSubscriptions)
	self.commSubscriptions = nil
end

--- @param record Models.Audit.LootRecord
function LootAudit:OnRecordAdd(record)
	Logging:Trace("OnRecordAdd() : %s", Util.Objects.ToString(record and record:toTable() or {}))
	local winner, history = record.owner, self:GetHistory()
	local winnerHistory = history:get(winner)
	if winnerHistory then
		history:insert(record:toTable(), winner)
	else
		history:put(winner, {record:toTable()})
	end
	self.stats.stale = true
end

--- @param record Models.Audit.LootRecord
function LootAudit:Broadcast(record)
	-- if in test mode and not development mode, return
	if (AddOn:TestModeEnabled() and not AddOn:DevModeEnabled()) then return end

	self:Send(C.group, C.Commands.LootAuditAdd, record)
end

local cpairs = CDB.static.pairs
--- @return Models.Audit.LootStatistics
function LootAudit:GetStatistics()
	Logging:Trace("GetStatistics()")

	local check, ret = pcall(
		function()
			if self.stats.stale or Util.Objects.IsNil(self.stats.value) then
				local cutoff = Date()
				cutoff:add{day = -LootAudit.StatsIntervalInDays}
				Logging:Debug("GetStatistics() : Processing History after %s", tostring(cutoff))

				local s = LootStatistics()
				for name, data in cpairs(self:GetHistory()) do
					for i = #data, 1, -1 do
						local entry = LootRecord:reconstitute(data[i])
						local ts = Date(entry.timestamp)
						if ts > cutoff then
							s:ProcessEntry(name, entry, i)
						end
					end
				end

				self.stats.stale = false
				self.stats.value = s
			end

			return self.stats.value
		end
	)

	if not check then
		Logging:Warn("Error processing Loot Audit : %s", tostring(ret))
		AddOn:Print("Error processing Loot Audit")
	else
		return ret
	end
end

function LootAudit:LaunchpadSupplement()
	return L["loot_audit"], function(container) self:LayoutInterface(container) end , true
end