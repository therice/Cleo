local AddOnName, AddOn, Util, CDB

describe("Loot Audit", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_LootAudit')
		Util, CDB = AddOn:GetLibrary('Util'), AddOn.ImportPackage('Models').CompressedDb
		AddOnLoaded(AddOnName, true)
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		it("is enabled on startup", function()
			local lh = AddOn:LootAuditModule()
			assert(lh)
			assert(lh:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("LootAudit")
			local lh = AddOn:LootAuditModule()
			assert(lh)
			assert(not lh:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("LootAudit")
			local lh = AddOn:LootAuditModule()
			assert(lh)
			assert(lh:IsEnabled())
		end)
	end)
	describe("functional", function()

		--- @type LootAudit
		local la
		setup(function()
			AddOn:CallModule("LootAudit")
			la = AddOn:LootAuditModule()
			-- NewLootHistoryDb(lh, LootHistoryTestData_M)
		end)

		teardown(function()
			la = nil
		end)
	end)
end)