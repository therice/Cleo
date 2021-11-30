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
	self.Send = Comm():GetSender(C.CommPrefixes.Audit)
	AddOn:SyncModule():AddHandler(
			self:GetName(),
			L['traffic_audit'],
			function () return self:GetDataForSync() end,
			function(data) self:ImportDataFromSync(data) end
	)
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
end

--- @param record Models.Audit.TrafficRecord
function TrafficAudit:Broadcast(record)
	-- if in test mode and not development mode, return
	if (AddOn:TestModeEnabled() and not AddOn:DevModeEnabled()) then return end

	local channel = (IsInRaid() or IsInGroup()) and C.group or (IsInGuild() and C.guild or C.player)
	self:Send(channel, C.Commands.TrafficAuditAdd, record)
end

local cpairs = CDB.static.pairs

function TrafficAudit:GetDataForSync()
	Logging:Debug("GetDataForSync()")
	if AddOn:DevModeEnabled() then
		Logging:Debug("GetDataForSync() : count=%d", Util.Tables.Count(self.db.factionrealm))

		local db = self.db.factionrealm
		local send = {}

		while Util.Tables.Count(send) < math.min(10, Util.Tables.Count(db)) do
			local v = Util.Tables.Random(db)
			if Util.Objects.IsString(v) then
				table.insert(send, v)
			end
		end


		Logging:Debug("GetDataForSync() : randomly selected entries count is %d", #send)
		return send
	else
		return self.db.factionrealm
	end
end

function TrafficAudit:ImportDataFromSync(data)
	Logging:Debug("ImportDataFromSync() : current history count is %d, import history count is %d",
	              Util.Tables.Count(self.db.factionrealm),
	              Util.Tables.Count(data)
	)

	local persist = (not AddOn:DevModeEnabled() and AddOn:PersistenceModeEnabled()) or AddOn._IsTestContext()
	if Util.Tables.Count(data) > 0 then
		-- make a copy of current history and sort it by timestamp
		-- will take a one time hit here, but will make searching able to be short circuited when
		-- timestamp of existing history is past any import entry
		local orderedHistory = {}
		for _, e in cpairs(self.history) do Util.Tables.Push(orderedHistory, e) end
		Util.Tables.Sort(orderedHistory, function(a, b) return a.timestamp < b.timestamp end)

		local function FindExistingEntry(importe)
			for i , e in pairs(orderedHistory) do
				-- if we've gone further into future than import record, it won't be found
				if e.timestamp > importe.timestamp then
					Logging:Debug(
						"FindExistingEntry(%s) : current history ts '%d' is after import ts '%d', aborting search...",
						e.id, e.timestamp, importe.timestamp
					)
					break
				end

				if e.timestamp == importe.timestamp then
					Logging:Debug(
						"FindExistingEntry(%s) : current history ts '%d' is equal to import ts '%d', performing final evaluation",
						e.id, e.timestamp, importe.timestamp
					)

					if Util.Strings.Equal(e.id, importe.id) then
						return i, e
					end
				end
			end
		end

		local cdb = CDB(data)
		local imported, skipped = 0, 0
		for _, entryTable in cpairs(cdb) do
			Logging:Debug("ImportDataFromSync(%s) : examining import entry", entryTable.id)
			local _, existing = FindExistingEntry(entryTable)
			if existing then
				Logging:Debug("ImportDataFromSync(%s) : found existing entry in history, skipping...", entryTable.id)
				skipped = skipped + 1
			else
				Logging:Debug("ImportDataFromSync(%s) : entry does not exist in history, adding...", entryTable.id)
				if persist then
					self.history:insert(entryTable)
				end
				imported = imported + 1
			end
		end

		if imported > 0 then
			self:RefreshData()
		end

		Logging:Debug("ImportDataFromSync(%s) : imported %s history entries, skipped %d import history entries, new history entry count is %d",
		              tostring(persist),
		              imported,
		              skipped,
		              Util.Tables.Count(self.db.factionrealm)
		)
		AddOn:Print(format(L['import_successful_with_count'], AddOn.GetDateTime(), self:GetName(), imported))
	else
		AddOn:Print(format(L['import_successful_with_count'], AddOn.GetDateTime(), self:GetName(), 0))
	end
end

function TrafficAudit:LaunchpadSupplement()
	return L["traffic_audit"], function(container) self:LayoutInterface(container) end , true
end