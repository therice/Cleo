local AddOnName, AddOn, Util, CDB, Encounter

local function NewTrafficAuditDb(ta, data)
	local db = NewAceDb(ta.defaults)
	for k, history in pairs(data) do
		db.factionrealm[k] = history
	end
	ta.db = db
	ta.history = CDB(db.factionrealm)
end


--- @type Models.Audit.RaidRosterRecord
local RaidRosterRecord
--- @type Models.Audit.RaidAttendanceStatistics
local RaidAttendanceStatistics

describe("Raid Audit", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_TrafficAudit')
		loadfile('Modules/Audit/Test/RaidAuditTestData.lua')()
		Util, CDB, Encounter = AddOn:GetLibrary('Util'), AddOn.ImportPackage('Models').CompressedDb, AddOn:GetLibrary("Encounter")
		RaidRosterRecord = AddOn.Package('Models.Audit').RaidRosterRecord
		RaidAttendanceStatistics = AddOn.Package('Models.Audit').RaidAttendanceStatistics
		AddOnLoaded(AddOnName, true)
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

		it("attendance statistics", function()
			NewTrafficAuditDb(ra, RaidAuditTestData_1)
			local stats =
				RaidAttendanceStatistics.For(function() return cpairs(ra:GetHistory()) end)
			local totals = stats:GetTotals(30)
			print(Util.Objects.ToString(totals))
			assert(Util.Tables.Count(totals) > 0)
		end)
	end)
end)