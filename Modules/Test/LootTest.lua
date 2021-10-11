local AddOnName, AddOn, Util, ItemRef, Player, C


describe("Loot", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_Loot')
		C = AddOn.Constants
		Util, ItemRef, Player =
			AddOn:GetLibrary('Util'),
			AddOn.Package('Models.Item').ItemRef,
			AddOn.Package('Models').Player
		AddOnLoaded(AddOnName, true)
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		teardown(function()
			AddOn:YieldModule("Loot")
		end)

		it("is disabled on startup", function()
			local loot = AddOn:LootModule()
			assert(loot)
			assert(not loot:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("Loot")
			local loot = AddOn:LootModule()
			assert(loot)
			assert(loot:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("Loot")
			local loot = AddOn:LootModule()
			assert(loot)
			assert(not loot:IsEnabled())
		end)
	end)

	describe("functional", function()
		--- @type Loot
		local loot

		setup(function()
			AddOn:MasterLooterModule().db.profile.showLootResponses = true
			AddOn:MasterLooterModule():UpdateDb()
			AddOn:ToggleModule("Loot")
			loot = AddOn:LootModule()
			WoWAPI_FireUpdate()
		end)

		teardown(function()
			AddOn:YieldModule("Loot")
		end)

		it("starts session", function()
			local ir = ItemRef('item:18831')
			ir.autoPass = true

			local lt = {
				ItemRef('item:18832'),
				ItemRef('item:18833'),
				ir
			}
			loot:Start(lt, false)
			assert.equal(#loot.items, 3)
			loot:Stop()
		end)
		it("adds single item", function()
			loot:AddSingleItem(ItemRef('item:18835'))
			local ir = ItemRef('item:18836')
			ir.autoPass = true
			loot:AddSingleItem(ir)
			assert.equal(#loot.items, 2)
			loot:Stop()
		end)
		it("handles duplicates", function()
			local lt = {
				ItemRef('item:18833'),
				ItemRef('item:18833'),
			}
			loot:Start(lt, false)
			assert.equal(#loot.items, 2)
			assert.are.same(loot.items[1].sessions, {1, 2})
			loot:Stop()
		end)
		it("handles response(s)", function()
			local lt = {
				ItemRef('item:18832'),
				ItemRef('item:18835'),
			}
			loot:Start(lt, false)
			AddOn:SendResponse(C.group, 1, 1)
			WoWAPI_FireUpdate(GetTime() + 10)
			assert(loot.items[1].responders[1][1] == 'Player1-Realm1')
			loot:Stop()
		end)
		it("handles event(s)", function()
			_G.UnitIsUnit = function(unit1, unit2) return true end
			AddOn.handleLoot = true
			AddOn.player = Player:Get("Player1")
			AddOn.masterLooter = AddOn.player

			local lt = {
				ItemRef('item:18832'),
				ItemRef('item:18835'),
			}
			loot:Start(lt, false)

			local item = loot.items[1]
			item.isRoll = true

			local entry = loot.EntryManager:GetEntry(item)
			loot.EntryManager:Recycle(entry)
			entry = loot.EntryManager:GetEntry(item)

			loot:OnRoll(entry, C.Responses.Roll)
			WoWAPI_FireUpdate(GetTime() + 10)
			assert.equal(#loot.awaitingRolls, 0)
			assert(tonumber(entry.rollResult:GetText()) >= 0)
		end)
		it("handles non-rolls", function()
			local lt = {
				ItemRef('item:18832'),
				ItemRef('item:18835'),
			}
			loot:Start(lt, false)
			local i1, i2 = loot.items[1], loot.items[2]
			loot:OnRoll(loot.EntryManager:GetEntry(i1), 1)
			loot:OnRoll(loot.EntryManager:GetEntry(i2), 3)
			WoWAPI_FireUpdate(GetTime() + 10)
			assert(i1.rolled)
			assert(i2.rolled)
		end)
	end)
end)