local AddOnName, AddOn, Util, CDB

local function NewTrafficAuditDb(ta, data)
	local db = NewAceDb(ta.defaults)
	for k, history in pairs(data) do
		db.factionrealm[k] = history
	end
	ta.db = db
	ta.history = CDB(db.factionrealm)
end

--- @type Models.List.Configuration
local Configuration
--- @type Models.List.List
local List
--- @type Models.Audit.TrafficRecord
local TrafficRecord


describe("Traffic Audit", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_TrafficAudit')
		loadfile('Modules/Audit/Test/TrafficAuditTestData.lua')()
		Util, CDB = AddOn:GetLibrary('Util'), AddOn.ImportPackage('Models').CompressedDb
		Configuration, List = AddOn.Package('Models.List').Configuration, AddOn.Package('Models.List').List
		TrafficRecord = AddOn.Package('Models.Audit').TrafficRecord
		AddOnLoaded(AddOnName, true)
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		it("is enabled on startup", function()
			local ta = AddOn:TrafficAuditModule()
			assert(ta)
			assert(ta:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("TrafficAudit")
			local ta = AddOn:TrafficAuditModule()
			assert(ta)
			assert(not ta:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("TrafficAudit")
			local ta = AddOn:TrafficAuditModule()
			assert(ta)
			assert(ta:IsEnabled())
		end)
	end)

	describe("functional", function()

		--- @type TrafficAudit
		local ta
		local cpairs = CDB.static.pairs

		setup(function()
			AddOn:CallModule("TrafficAudit")
			ta = AddOn:TrafficAuditModule()
			NewTrafficAuditDb(ta, { })
		end)

		teardown(function()
			ta = nil
		end)

		it("broadcasts records", function()
			--- @type Models.List.Configuration
			local C = Configuration.CreateInstance()
			--- @type Models.List.List
			local L = List.CreateInstance(C.id)

			local record = TrafficRecord.For(C)
			record:SetAction(TrafficRecord.ActionType.Create)
			ta:Broadcast(record)
			WoWAPI_FireUpdate(GetTime() + 10)

			record = TrafficRecord.For(C, L)
			record:SetAction(TrafficRecord.ActionType.Create)
			ta:Broadcast(record)
			WoWAPI_FireUpdate(GetTime() + 10)

			record = TrafficRecord.For(C)
			record:SetAction(TrafficRecord.ActionType.Modify)
			record:SetModification('name', 'Y')
			ta:Broadcast(record)
			WoWAPI_FireUpdate(GetTime() + 10)

			record = TrafficRecord.For(C, L)
			record:SetAction(TrafficRecord.ActionType.Modify)
			record:SetModification('name', 'N')
			ta:Broadcast(record)
			WoWAPI_FireUpdate(GetTime() + 10)

			local history, count = ta:GetHistory(), 0
			for i, r in cpairs(history) do
				count = count + 1
				assert(TrafficRecord:reconstitute(r))
			end

			assert.equal(4, count)
		end)
		--[[
		it("scratch", function()
			NewTrafficAuditDb(ta, TrafficAuditTestData_1)
			local history = ta:GetHistory()
			for i, r in cpairs(history) do
				local record = TrafficRecord:reconstitute(r)
				local n, v = record:GetModifiedAttribute(), record:GetModifiedAttributeValue()
				if Util.Objects.In(n, 'permissions') then
					record:ParseModification(
						function(player, permissions)
							print(tostring(player) .. ' -> ' .. tostring(permissions))
						end
					)
				elseif Util.Objects.In(n, 'equipment') then
					record:ParseModification(
						function(index, equipment)
							print(tostring(index) .. ' -> ' .. tostring(equipment))
						end
					)
				elseif Util.Objects.In(n, 'players') then
					record:ParseModification(
						function(priority, player)
							print(tostring(priority) .. ' -> ' .. tostring(player))
						end
					)
				end
				print('------------------------------')

				--if Util.Objects.IsTable(v) then
				--	print(n .. ' -> ' .. Util.Objects.ToString(v))
				--
				--	for k, v in Util.Tables.Sparse.ipairs(v) do
				--		print(tostring(k) .. ' -> ' .. Util.Objects.ToString(v))
				--	end
				--end
			end
		end)
		--]]

	end)
end)