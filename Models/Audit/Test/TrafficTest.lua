local AddOnName, AddOn
local TrafficRecord, Util, CDB
local Configuration, List, Player
local history = {}

describe("Loot Audit Record", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Audit_Loot')
		local AuditPkg = AddOn.Package('Models.Audit')
		TrafficRecord = AuditPkg.TrafficRecord
		CDB = AddOn.Package('Models').CompressedDb
		Util,Player = AddOn:GetLibrary('Util'), AddOn.Package('Models').Player
		Configuration, List = AddOn.Package('Models.List').Configuration, AddOn.Package('Models.List').List
		AddOn.player = Player:Get("Player1")
	end)

	teardown(function()
		history = {}
		AddOn.player = nil
		After()
	end)

	describe("creation", function()
		it("from no args", function()
			local entry = TrafficRecord()
			assert(entry:FormattedTimestamp() ~= nil)
			assert(entry.id:match("(%d+)-(%d+)"))
		end)
		it("from instant #travisignore", function()
			local entry = TrafficRecord(1585928063)
			assert(entry:FormattedTimestamp() == "04/03/2020 09:34:23")
			assert(entry.id:match("1585928063-(%d+)"))
		end)
		it("for config/list ", function()
			local c = Configuration.CreateInstance()
			local l = List.CreateInstance(c.id)
			local record = TrafficRecord.For(c)
			assert(record.config)
			assert(not record.list)
			--print(Util.Objects.ToString(record:toTable()))
			record = TrafficRecord.For(c, l)
			assert(record.config)
			assert(record.list)
			print(Util.Objects.ToString(record:toTable()))
		end)
	end)

	--[[
	describe("marshalling", function()
		it("to table", function()
			local entry = TrafficRecord(1585928063)
			local asTable = entry:toTable()
			assert(asTable.timestamp == 1585928063)
			assert(asTable.auditVersion ~= nil)
			assert(asTable.auditVersion.major >= 1)
		end)
		it("from table", function()
			local entry1 = TrafficRecord(1585928063)
			local asTable = entry1:toTable()
			local entry2 = TrafficRecord:reconstitute(asTable)
			assert.equals(entry1.id, entry2.id)
			assert.equals(entry1.timestamp, entry2.timestamp)
			assert.equals(entry1.auditVersion.major, entry2.auditVersion.major)
			-- invoke to make sure class meta-data came back with reconstitute
			entry2.auditVersion:nextMajor()
			assert.equals(tostring(entry1.auditVersion), tostring(entry2.auditVersion))
		end)
	end)
	--]]

	--[[
	describe("stats", function()
		it("creation", function()
			local stats = LootStatistics()
			for k,  e in pairs(history) do
				for i, v in ipairs(e) do
					stats:ProcessEntry(k, v, i)
				end
			end

			local se = stats:Get('Gnomechómsky-Atiesh')
			local totals = se:CalculateTotals()
			assert(totals.count == 14)
			assert(totals.raids.count == 10)

			print(Util.Objects.ToString(totals))
		end)
	end)
	--]]
end )