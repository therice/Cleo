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
--- @type Models.Audit.RaidStatistics
local RaidStatistics =  AddOn.ImportPackage('Models.Audit').RaidStatistics

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
		trackingType = RA.TrackingType.EncounterEnd,
		autoPurge = {
			enabled     = true, -- is auto purging enabled
			ageInDays   = 60,   -- purge threshold
			recurrence  = 3,    -- how often to auto-purge
			lts         = nil,  -- last time purge was completed
		}
	},
	factionrealm = {

	}
}

local cpairs = CDB.static.pairs

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
		raid = {
			stale = true,
			value = { },
		},
		MarkAsStale = function(self)
			self.attendance.stale = true
			self.attendance.raid = true
		end
	}
	self.intervalCache = {}

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

--- @param sd Models.Date the start date for history
--- @param ed Models.Date the end date for history
--- @return function
function RA:GetHistoryFiltered(sd, ed)
	assert(sd and ed, "start and end dates were not provided")
    return function()
	    return cpairs(
		    self:GetHistory(),
		    function(_, v)
			    local d = Date(v.timestamp)
			    return d >= sd and d <= ed
		    end
	    )
    end
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
	Util.Tables.Wipe(self.intervalCache)
end

--- @param record Models.Audit.RaidRosterRecord
function RA:Broadcast(record)
	-- if in test mode and not development mode, return
	if (AddOn:TestModeEnabled() and not AddOn:DevModeEnabled()) then
		return
	end

	local channel = (IsInRaid() or IsInGroup()) and C.group or (IsInGuild() and C.guild or C.player)
	self:Send(channel, C.Commands.RaidRosterAuditAdd, record)
end

local UTCOffset = Util.Memoize.Memoize(
	function()
		return (Date():tzone() / 3600)
	end
)


-- this only deals with full "raid" weeks, anything less than a week will be ignored
local function GetNormalizedInterval(self, intervalInDays)
	assert(Util.Objects.IsNumber(intervalInDays) and intervalInDays >= 0, "intervalInDays must be a positive number")
	-- determine number of weeks and days which make up the interval
	local weeks, remainder, raid_weeks =
		floor(intervalInDays / 7), (intervalInDays % 7), {}
	local now = Date():hour(15 + UTCOffset()):min(0):sec(0)

	Logging:Debug("GetNormalizedInterval(%d) : weeks=%d, remainder=%d(days) will be ignored, \"now\"=%s", intervalInDays, weeks, remainder, tostring(now))

	-- weeks needs to be converted to raid weeks
	if weeks > 0 then
		-- US raid lockout start (week) occurs on Tuesdays at 15:00 UTC (adjust for offset)
		local rws, rwe = Date({hour = 15 + UTCOffset(), min = 0, sec = 0})

		Logging:Debug("GetNormalizedInterval(%d) : %s (searching from)", weeks, tostring(rws))

		-- (1) find previous tuesday
		while(rws:wday() ~= 3) do
			rws:add {day = -1}
		end

		Logging:Debug("GetNormalizedInterval(%d) : %s (starting at)", weeks, tostring(rws))

		-- iterate through the weeks, finding raid week start and end
		while (weeks > 0) do
			rwe = Date(rws):add { day = 7 }
			if rwe <= now then
				Util.Tables.Push(raid_weeks, {rws, rwe, false})
				weeks = weeks -1
			end

			rws = Date(rws):add { day = -7 }
		end
	else
		Logging:Warn("GetNormalizedInterval(%d) : specified interval was less than a week", intervalInDays)
	end

	if Logging:IsEnabledFor(Logging.Level.Debug) then
		Util.Tables.Call(
			raid_weeks,
			function(rw)
				Logging:Debug(
					"GetNormalizedInterval(%d) : %s (start) -> %s (end)",
					intervalInDays,
					tostring(rw[1]:toLocal()),
					tostring(rw[2]:toLocal())
				)
			end
		)
	end

	local orderedHistory = {}
	for _, e in cpairs(self:GetHistory()) do
		Util.Tables.Push(orderedHistory, e)
	end
	Util.Tables.Sort(
		orderedHistory,
		function(a, b) return a.timestamp > b.timestamp end
	)

	for idx, rw in pairs(raid_weeks) do
		local rws, rwe, index = rw[1], rw[2]

		for i, v in pairs(orderedHistory) do
			local d = Date(v.timestamp)
			if d and (d >= rws and d <= rwe) then
				index = i
				break
			end

			if d and (d <= rws and d <= rwe) then
				break
			end
		end


		raid_weeks[idx][3] = index and true or false
		-- could not find a raid during the week, look for another
		if not index then
			local lrws, lrwe = raid_weeks[#raid_weeks][1], raid_weeks[#raid_weeks][2]
			local _, _, lrwdd = lrwe:diff(lrws):Duration()
			-- if the last raid week window was 7 days (full week) add another raid week to search
			if lrwdd == 7 then
				rwe = Date(lrws)
				rws =  Date(rwe):add { day = -7 }
				Util.Tables.Push(raid_weeks, {rws, rwe})
			end
		end
	end

	if Logging:IsEnabledFor(Logging.Level.Trace) then
		Util.Tables.Call(
			raid_weeks,
			function(rw)
				Logging:Trace(
					"GetNormalizedInterval(%d) : %s (start) -> %s (end) / found = %s",
					intervalInDays,
					tostring(rw[1]:toLocal()),
					tostring(rw[2]:toLocal()),
					tostring(rw[3])
				)
			end
		)
	end

	local sdate, edate = raid_weeks[#raid_weeks][1], raid_weeks[1][2]
	local interval = (edate.time - sdate.time) / (24 * 60 * 60)

	Logging:Debug(
		"GetNormalizedInterval(%d) : %s (start) -> %s (end) [days=%d])",
		intervalInDays, tostring(sdate:toLocal()), tostring(edate:toLocal()), interval
	)

	return sdate, edate, interval
end

RA.GetNormalizedInterval = Util.Memoize.Memoize(
	function(self, intervalInDays)
		return GetNormalizedInterval(self, intervalInDays)
	end
)

--- @param sd Models.Date|number the start date for history, or a number specifying days will be calculated
--- @param ed Models.Date the end date for history, can be nil if first parameter is a number
--- @param playerMappingFn  function<string> yields the name of passed player (string) to 'main' as/if needed
function RA:GetAttendanceStatistics(sd, ed, playerMappingFn)
	-- if a number, calculate the date range
	if Util.Objects.IsNumber(sd) then
		local now = Date():clear_time()
		local start = Date(now):add {day = -sd}
		sd, ed = start, now
	end
	assert(sd and ed, "start and end dates were not provided")

	local cacheKey = Util.Strings.Join('_', tostring(sd), tostring(ed))
	local check, ret = pcall(
		function()
			local reload = self.stats.attendance.stale or
				Util.Tables.IsEmpty(self.stats.attendance.value) or
				Util.Tables.IsEmpty(self.stats.attendance.value[cacheKey])

			Logging:Debug("GetAttendanceStatistics(%s, %s, %s)[%s, %s]", tostring(sd), tostring(ed), tostring(playerMappingFn), cacheKey, tostring(reload))

			if reload then
				local stats = RaidAttendanceStatistics.For(
					function() return self:GetHistoryFiltered(sd, ed)() end,
					playerMappingFn
				)
				if stats then
					self.stats.attendance.value[cacheKey] = stats:GetTotals()
					self.stats.attendance.stale = false
				end
			end

			return self.stats.attendance.value[cacheKey] or {}
		end
	)

	if not check then
		Logging:Warn("Error processing Raid Audit : %s", tostring(ret))
		AddOn:Print("Error processing Raid Audit")
	else
		return ret
	end
end

function RA:GetRaidStatistics(sd, ed)
	-- if a number, calculate the date range
	if Util.Objects.IsNumber(sd) then
		local now = Date()
		local start = Date(now):add {day = -sd}
		sd, ed = start, now
	end
	assert(sd and ed, "start and end dates were not provided")
	local cacheKey = Util.Strings.Join('_', tostring(sd), tostring(ed))

	local check, ret = pcall(
		function()
			if  self.stats.raid.stale or
				Util.Tables.IsEmpty(self.stats.raid.value) or
				Util.Tables.IsEmpty(self.stats.raid.value[cacheKey]) then
				local stats = RaidStatistics.For(function() return self:GetHistoryFiltered(sd, ed)() end)
				if stats then
					self.stats.raid.value[cacheKey] = stats:GetTotals()
					self.stats.raid.stale = false
				end
			end

			return self.stats.raid.value[cacheKey] or {}
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
			Util.Tables.Wipe(self.intervalCache)
			self:Refresh()
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

--[[
function RA:ConfigSupplement()
	return L["attendance_audit"], function(container) self:LayoutConfigSettings(container) end
end
--]]

function RA:LaunchpadSupplement()
	return L["attendance_audit"], function(container) self:LayoutInterface(container) end , true
end