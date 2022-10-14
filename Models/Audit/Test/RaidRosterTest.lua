local AddOnName, AddOn
local RaidRosterRecord, Util, CDB, Player, Encounter
local history = {}

describe("Raid Roster Audit Record", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Audit_RaidRoster')
		local AuditPkg= AddOn.Package('Models.Audit')
		RaidRosterRecord = AuditPkg.RaidRosterRecord
		CDB = AddOn.Package('Models').CompressedDb
		Encounter = AddOn.Package('Models').Encounter
		Util, Player = AddOn:GetLibrary('Util'), AddOn.Package('Models').Player
		AddOnLoaded(AddOnName, true)
		AddOn.player = Player:Get("Player501")
	end)

	teardown(function()
		history = {}
		AddOn.player = nil
		After()
	end)

	describe("creation", function()
		it("from no args", function()
			local record = RaidRosterRecord()
			assert(record:FormattedTimestamp() ~= nil)
			assert(record.id:match("(%d+)-(%d+)"))
		end)
		it("from instant #travisignore", function()
			local record = RaidRosterRecord(1585928063)
			assert(record:FormattedTimestamp() == "04/03/2020 09:34:23")
			assert(record.id:match("1585928063-(%d+)"))
		end)
		it("for encounter ", function()
			local e = Encounter.Start(1, 'Test Encounter', 4, 25)
			local record = RaidRosterRecord.For(e)
			assert(record.actor)
			assert(not record.players)

			local rv, m = _G.IsInRaidVal, _G.MAX_RAID_MEMBERS
			_G.IsInRaidVal = true
			_G.MAX_RAID_MEMBERS = 25

			e = Encounter.End(e, 1, 'Test Encounter', 4, 25, 1)
			record = RaidRosterRecord.For(e)
			assert(record.actor)
			assert(record.players)
			assert(Util.Tables.Count(record.players) == 25)
			_G.IsInRaidVal = rv
			_G.MAX_RAID_MEMBERS = m
		end)
	end)

	describe("marshalling", function()
		it("to table", function()
			local record = RaidRosterRecord(1585928063)
			local asTable = record:toTable()
			assert(asTable.timestamp == 1585928063)
			assert(asTable.auditVersion ~= nil)
			assert(asTable.auditVersion.major >= 1)
		end)
		it("from table", function()
			local rv, m = _G.IsInRaidVal, _G.MAX_RAID_MEMBERS
			_G.IsInRaidVal = true
			_G.MAX_RAID_MEMBERS = 25
			local e = Encounter.Start(1, 'Test Encounter', 4, 25)
			local record1 = RaidRosterRecord.For(e)
			local asTable = record1:toTable()

			local record2 = RaidRosterRecord:reconstitute(asTable)
			assert.equals(record1.id, record2.id)
			assert.equals(record1.timestamp, record2.timestamp)
			assert.equals(record1.auditVersion.major, record2.auditVersion.major)
			-- invoke to make sure class meta-data came back with reconstitute
			record2.auditVersion:nextMajor()
			assert.equals(tostring(record1.auditVersion), tostring(record2.auditVersion))

			_G.IsInRaidVal = rv
			_G.MAX_RAID_MEMBERS = m
		end)
	end)
end)