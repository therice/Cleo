--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Models.CompressedDb
local CDB = AddOn.ImportPackage('Models').CompressedDb
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @type Models.Date
local Date = AddOn.ImportPackage('Models').Date
--- @type Models.Audit.RaidRosterRecord
local RaidRosterRecord =  AddOn.ImportPackage('Models.Audit').RaidRosterRecord
--- @type Models.Audit.RaidAttendanceStatistics
local RaidAttendanceStatistics =  AddOn.ImportPackage('Models.Audit').RaidAttendanceStatistics

--- @class RaidAudit
local RA = AddOn:NewModule("RaidAudit")

RA.TrackingType = {
	EncounterStart       = 1,
	EncounterEnd         = 2,
	EncounterStartAndEnd = 3,
}

RA.defaults = {
	profile  = {
		enabled      = true,
		trackingType = RA.TrackingType.EncounterEnd
	},
	factionrealm = {

	}
}

function RA:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.Libs.AceDB:New(AddOn:Qualify('RaidAudit'), RA.defaults)
	self.history = CDB(self.db.factionrealm)
	-- cache of various stats which could be used elsewhere
	self.stats = {
		attendance = {
			stale = true,
			value = { },
		},
		MarkAsStale = function(self)
			self.attendance.stale = true
		end
	}
	self.Send = Comm():GetSender(C.CommPrefixes.Audit)
	AddOn:SyncModule():AddHandler(
		self:GetName(),
		L['attendance_audit'],
		function () return self:GetDataForSync() end,
		function(data) self:ImportDataFromSync(data) end
	)
end

function RA:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:SubscribeToComms()
end

function RA:OnDisable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:UnsubscribeFromComms()
end

--- @return Models.CompressedDb
function RA:GetHistory()
	return self.history
end

function RA:SubscribeToComms()
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	self.commSubscriptions = Comm():BulkSubscribe(C.CommPrefixes.Audit, {
		[C.Commands.RaidRosterAuditAdd] = function(data, sender)
			Logging:Debug("RaidRosterAuditAdd from %s", tostring(sender))
			local record = RaidRosterRecord:reconstitute(unpack(data))
			self:OnRecordAdd(record)
		end
	})
end

function RA:UnsubscribeFromComms()
	Logging:Debug("UnsubscribeFromComms(%s)", self:GetName())
	AddOn.Unsubscribe(self.commSubscriptions)
	self.commSubscriptions = nil
end

--- @param encounter Models.Encounter
function RA:OnEncounterEvent(encounter)
	Logging:Trace("OnEncounterEvent() : %s", Util.Objects.ToString())
	-- create record and broadcast if settings dictate it should be done
	-- pre-requisites for this being called is already evaluated (valid encounter, is ML, and Cleo handling loot)
	local enabled, trigger = self.db.profile.enabled, self.db.profile.trackingType
	-- we are tracking raids and
	--  'encounter start' and no success data OR
	--  'encounter end' and success data
	--  'encounter start and end'
	if enabled and
		((trigger == RA.TrackingType.EncounterStart and encounter.success == nil) or
		 (trigger == RA.TrackingType.EncounterEnd and encounter.success ~= nil) or
		 (trigger == RA.TrackingType.EncounterStartAndEnd)) then
		self:Broadcast(RaidRosterRecord.For(encounter))
	end
end

--- @param record Models.Audit.RaidRosterRecord
function RA:OnRecordAdd(record)
	Logging:Trace("OnRecordAdd() : %s", Util.Objects.ToString(record and record:toTable() or {}))
	self:GetHistory():insert(record:toTable())
	self.stats:MarkAsStale()
end

--- @param record Models.Audit.RaidRosterRecord
function RA:Broadcast(record)
	-- if in test mode and not development mode, return
	if (AddOn:TestModeEnabled() and not AddOn:DevModeEnabled()) then return end
	local channel = (IsInRaid() or IsInGroup()) and C.group or (IsInGuild() and C.guild or C.player)
	self:Send(channel, C.Commands.RaidRosterAuditAdd, record)
end

local cpairs = CDB.static.pairs

function RA:GetAttendanceStatistics(intervalInDays)
	Logging:Trace("GetAttendanceStatistics()")
	local check, ret = pcall(
		function()
			if  self.stats.attendance.stale or
				Util.Tables.IsEmpty(self.stats.attendance.value) or
				Util.Tables.IsEmpty(self.stats.attendance.value[intervalInDays]) then
				local stats = RaidAttendanceStatistics.For(function() return cpairs(self:GetHistory()) end)
				if stats then
					self.stats.attendance.value[intervalInDays] = stats:GetTotals(intervalInDays)
					self.stats.attendance.stale = false
				end
			end

			return self.stats.attendance.value[intervalInDays] or {}
		end
	)

	if not check then
		Logging:Warn("Error processing Raid Audit : %s", tostring(ret))
		AddOn:Print("Error processing Raid Audit")
	else
		return ret
	end
end

function RA:GetDataForSync()
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

function RA:ImportDataFromSync(data)
	Logging:Debug(
		"ImportDataFromSync() : current history count is %d, import history count is %d",
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
			self.stats:MarkAsStale()
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

function RA:Delete(ageInDays)
	if ageInDays then
		local cutoff = Date()
		cutoff:add{day = -ageInDays}
		Logging:Debug("Delete(%d) : Deleting history before %s", ageInDays, tostring(cutoff))
		local history = self:GetHistory()

		-- cannot mutate as you iterated, so capture data to retain
		local retain, deleteCount = {}, 0
		for row, data in cpairs(history) do
			--- @type Models.Audit.RaidRosterRecord
			local entry = RaidRosterRecord:reconstitute(data)
			local ts = Date(entry.timestamp)
			if ts < cutoff then
				Logging:Debug("Delete() : deleting entry %s (%s)", row, tostring(ts))
				deleteCount = deleteCount + 1
			else
				Util.Tables.Push(retain, data)
			end
		end

		-- probably a better way to do this than clearing and re-inserting
		-- however, i'm feeling lazy today
		if deleteCount > 0 and #retain > 0 then
			history:clear()
			for _, data in pairs(retain) do
				history:insert(data)
			end
		end
	end
end


function RA:ConfigSupplement()
	return L["attendance_audit"], function(container) self:LayoutConfigSettings(container) end
end

function RA:LaunchpadSupplement()
	return L["attendance_audit"], function(container) self:LayoutInterface(container) end , true
end