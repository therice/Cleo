local AddOnName, AddOn, Util, CDB, Encounter, Date, DateFormat, df

local function NewTrafficAuditDb(ta, data)
	local db = NewAceDb(ta.defaults)
	for k, history in pairs(data) do
		db.factionrealm[k] = history
	end
	ta.db = db
	ta.history = CDB(db.factionrealm)
end

function parse_date(s)
	return df:parse(s)
end

function parse_utc(s)
	local d = parse_date(s)
	return d:toUTC()
end


--- @type Models.Audit.RaidRosterRecord
local RaidRosterRecord
--- @type Models.Audit.RaidAttendanceStatistics
local RaidAttendanceStatistics
--- @type Models.Audit.RaidStatistics
local RaidStatistics

describe("Raid Audit", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_TrafficAudit')
		loadfile('Modules/Audit/Test/RaidAuditTestData.lua')()
		Util, CDB, Encounter = AddOn:GetLibrary('Util'), AddOn.ImportPackage('Models').CompressedDb, AddOn:GetLibrary("Encounter")
		RaidRosterRecord = AddOn.Package('Models.Audit').RaidRosterRecord
		RaidAttendanceStatistics = AddOn.Package('Models.Audit').RaidAttendanceStatistics
		RaidStatistics = AddOn.Package('Models.Audit').RaidStatistics
		AddOnLoaded(AddOnName, true)
		Date, DateFormat = AddOn.Package('Models').Date, AddOn.Package('Models').DateFormat
		df = DateFormat()
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		it("is enabled on startup", function()
			local ra = AddOn:RaidAuditModule()
			assert(ra)
			assert(ra:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("RaidAudit")
			local ra = AddOn:RaidAuditModule()
			assert(ra)
			assert(not ra:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("RaidAudit")
			local ra = AddOn:RaidAuditModule()
			assert(ra)
			assert(ra:IsEnabled())
		end)
	end)

	describe("functional", function()
		--- @type RaidAudit
		local ra
		local cpairs = CDB.static.pairs

		setup(function()
			AddOn:CallModule("RaidAudit")
			ra = AddOn:RaidAuditModule()
			NewTrafficAuditDb(ra, { })
		end)

		teardown(function()
			ra = nil
		end)

		it("raid statistics", function()
			NewTrafficAuditDb(ra, RaidAuditTestData_1)
			local stats = RaidStatistics.For(function() return cpairs(ra:GetHistory()) end)
			local totals = stats:GetTotals(7)
			assert(Util.Tables.Count(totals.instances) == 3)
		end)
		it("raid statistics filtered by dates", function()
			NewTrafficAuditDb(ra, RaidAuditTestData_2)
			local sd, ed = parse_utc('2022-11-08T15:00:00Z'), parse_utc('2022-12-06T15:00:00Z')
			local stats = ra:GetRaidStatistics(sd, ed)
			--print(Util.Objects.ToString(stats))
			assert(Util.Tables.Count(stats.instances) == 4)
		end)
		it("raid statistics filtered by days", function()
			NewTrafficAuditDb(ra, RaidAuditTestData_2)
			local stats = ra:GetRaidStatistics(14)
			--print(Util.Objects.ToString(stats))
			assert(Util.Tables.Count(stats.instances) <= 4)
		end)
		it("attendance statistics", function()
			NewTrafficAuditDb(ra, RaidAuditTestData_1)
			local stats = RaidAttendanceStatistics.For(function() return cpairs(ra:GetHistory()) end)
			local totals = stats:GetTotals(30)
			--print(Util.Objects.ToString(totals))
			assert(Util.Tables.Count(totals) > 0)
		end)
		it("attendance statistics filtered by dates", function()
			NewTrafficAuditDb(ra, RaidAuditTestData_2)
			local sd, ed = parse_utc('2022-11-08T15:00:00Z'), parse_utc('2022-12-06T15:00:00Z')
			local stats = ra:GetAttendanceStatistics(sd, ed)
			assert(stats.total == 12)
		end)
		it("attendance statistics filtered by days", function()
			NewTrafficAuditDb(ra, RaidAuditTestData_2)
			local stats = ra:GetAttendanceStatistics(14)
			assert(stats.total <= 8)
		end)
		it("normalizes interval", function()
			NewTrafficAuditDb(ra, RaidAuditTestData_2)
			local sd, ed, interval = ra:GetNormalizedInterval(36)
			--print(format("%s -> %s : %s", tostring(sd:toUTC()), tostring(ed:toUTC()), tostring(interval)))
			assert(tostring(sd:toUTC()) == '2022-11-08T15:00:00Z')
			assert(tostring(ed:toUTC()) == '2022-12-20T15:00:00Z')
			assert(interval == 42)
			sd, ed, interval = ra:GetNormalizedInterval(30)
			--print(format("%s -> %s : %s", tostring(sd:toUTC()), tostring(ed:toUTC()), tostring(interval)))
			assert(tostring(sd:toUTC()) == '2022-11-15T15:00:00Z')
			assert(tostring(ed:toUTC()) == '2022-12-20T15:00:00Z')
			assert(interval == 35)

			--sd, ed, interval = ra:GetNormalizedInterval(27)
		end)
		it("filtered iterator", function()
			NewTrafficAuditDb(ra, RaidAuditTestData_2)

			local sd, ed, d = parse_utc('2022-11-08T15:00:00Z'), parse_utc('2022-11-22T15:00:00Z')
			for k, v in ra:GetHistoryFiltered(sd, ed)() do
				d = Date(v.timestamp)
				--print(tostring(k) .. ' -> ' .. tostring(Date(v.timestamp)))
				assert(d >= sd and d <= ed)
			end
		end)
	end)
end)