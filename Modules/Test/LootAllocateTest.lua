local AddOnName
--- @type AddOn
local AddOn
local Util, Player, LootAllocateEntry, ItemRef, C


describe("LootAllocate", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_LootAllocate')
		Util = AddOn:GetLibrary('Util')
		Player = AddOn.Package('Models').Player
		LootAllocateEntry = AddOn.Package('Models.Item').LootAllocateEntry
		ItemRef = AddOn.Package('Models.Item').ItemRef
		C = AddOn.Constants
		AddOnLoaded(AddOnName, true)
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		it("is disabled on startup", function()
			local module = AddOn:LootAllocateModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("LootAllocate")
			local module = AddOn:LootAllocateModule()
			assert(module)
			assert(module:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("LootAllocate")
			local module = AddOn:LootAllocateModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
	end)

	describe("functionality", function()
		--- @type LootAllocate
		local la

		setup(function()
			_G.UnitIsUnit = function(unit1, unit2) return true end
			AddOn.enabled = true
			AddOn.handleLoot = true
			AddOn.player = Player:Get("Player1")
			AddOn.masterLooter = AddOn.player
			local ml = AddOn:MasterLooterModule()
			ml.db.profile.showLootResponses = true
			ml.db.profile.outOfRaid = false
			ml.db.profile.announceItemText = { channel = "group", text = "&s: &i Item Level (&l) Item Type (&t) Owner(&o) List(&ln)"}
			ml:UpdateDb()
			AddOn:CallModule("LootAllocate")
			la = AddOn:LootAllocateModule()
			WoWAPI_FireUpdate()
		end)

		teardown(function()
			AddOn:YieldModule("LootAllocate")
		end)

		it("receives loot table", function()

			local lt = {
				{
					ref = ItemRef('item:18832'):ForTransmit(),
					owner = "Edwin VanCleef"
				},
				{
					ref = ItemRef('item:18833'):ForTransmit(),
					owner = "Jackburton"
				}
			}

			-- this will trigger LA to receive loot table as well
			AddOn:OnLootTableReceived(lt)
			assert.equal(#la.lootTable, 2)
		end)
		it("adds to loot table", function()
			WoWAPI_FireUpdate(GetTime() + 10)
			AddOn:OnLootTableAddReceived({
				nil,
				nil,
				{
					ref = ItemRef('item:18834'):ForTransmit()
				}
			})
			assert.equal(#la.lootTable, 3)
		end)

		it("handles LootAck", function()
			local cr1 = la:GetCandidateResponse(1, AddOn.player:GetName())
			local cr2 = la:GetCandidateResponse(2, AddOn.player:GetName())
			assert(cr1.response == C.Responses.Wait)
			assert(cr2.response == C.Responses.Wait)
		end)

		it("handles CheckIfOffline", function()
			local cr1 = la:GetCandidateResponse(1, AddOn.player:GetName())
			local cr2 = la:GetCandidateResponse(2, AddOn.player:GetName())

			WoWAPI_FireUpdate(GetTime() + 5)
			la:SetCandidateData(1, AddOn.player:GetName(), "response", C.Responses.Announced)
			la:SetCandidateData(2, AddOn.player:GetName(), "response", C.Responses.Announced)
			AddOn:Send(C.group, C.Commands.CheckIfOffline, AddOn.player:GetName())
			WoWAPI_FireUpdate(GetTime() + 10)

			--print(Util.Objects.ToString(cr1))
			--print(Util.Objects.ToString(cr2))

			assert(cr1.response == C.Responses.Nothing)
			assert(cr2.response == C.Responses.Nothing)
		end)

		it("does all random rolls", function()
			la:DoAllRandomRolls()
		end)

		it("does random roll", function()
			la:DoRandomRolls(1)
		end)

		it("handles Response", function()
			AddOn:SendResponse(C.group, 1, 1)
			AddOn:SendResponse(C.group, 2, 2)
			WoWAPI_FireUpdate(GetTime() + 10)

			local cr1 = la:GetCandidateResponse(1, AddOn.player:GetName())
			local cr2 = la:GetCandidateResponse(2, AddOn.player:GetName())
			assert(cr1.response == 1)
			assert(cr2.response == 2)
		end)

		it("handles ChangeResponse", function()
			AddOn:Send(C.group, C.Commands.ChangeResponse, 1, AddOn.player:GetName(), 2)
			AddOn:Send(C.group, C.Commands.ChangeResponse, 2, AddOn.player:GetName(), 1)
			WoWAPI_FireUpdate(GetTime() + 10)

			local cr1 = la:GetCandidateResponse(1, AddOn.player:GetName())
			local cr2 = la:GetCandidateResponse(2, AddOn.player:GetName())
			assert(cr1.response == 2)
			assert(cr2.response == 1)
		end)

		it("handles Rolls", function()
			AddOn:Send(C.group, C.Commands.Rolls, 1, {61, 58, 24, 63, 35, 78, 19, 12, 16, 4, 26, 10, 6, 71, 48, 67, 57, 8, 85, 51, 75, 65, 83, 49, 59, 7})
			AddOn:Send(C.group, C.Commands.Rolls, 2, {29, 62, 61, 78, 18, 67, 57, 93, 73, 38, 74, 37, 81, 77, 64, 50, 54, 12, 39, 51, 65, 46, 59, 16, 24, 9})
			WoWAPI_FireUpdate(GetTime() + 10)
			local cr1 = la:GetCandidateResponse(1, AddOn.player:GetName())
			local cr2 = la:GetCandidateResponse(2, AddOn.player:GetName())
			assert.equal(cr1.roll, 61)
			assert.equal(cr2.roll, 29)
		end)

		it("handles Roll", function()
			AddOn:Send(C.group, C.Commands.Roll, AddOn.player:GetName(), 99, {2})
			WoWAPI_FireUpdate(GetTime() + 10)
			local cr2 = la:GetCandidateResponse(2, AddOn.player:GetName())
			assert.equal(cr2.roll, 99)
		end)

		it("handles Awarded", function()
			AddOn:Send(C.group, C.Commands.Awarded, 1, AddOn.player:GetName())
			WoWAPI_FireUpdate(GetTime() + 10)
			local cr1 = la:GetCandidateResponse(1, AddOn.player:GetName())
			assert(cr1.response == C.Responses.Awarded)
			assert(cr1.response_actual == 2)
		end)

		it("solicits response", function()
			la:SolicitResponse(AddOn.player:GetName(), 1, false, false)
		end)

		it("updates(forced)", function()
			AddOn.db.profile.modules.LootAllocate.alwaysShowTooltip = true
			la:SwitchSession(1)
			la:Update(true)
		end)

		it("solicits responses", function()
			_G.MSA_DROPDOWNMENU_MENU_VALUE = "_CANDIDATE"
			la.SolicitResponseButton(AddOn.player:GetName(), true, la)
			la.SolicitResponseButton(AddOn.player:GetName(), false, la)
			_G.MSA_DROPDOWNMENU_MENU_VALUE = "_GROUP"
			la.SolicitResponseButton(AddOn.player:GetName(), true, la)
			la.SolicitResponseButton(AddOn.player:GetName(), false, la)
			_G.MSA_DROPDOWNMENU_MENU_VALUE = "_RESPONSE"
			la.SolicitResponseButton(AddOn.player:GetName(), true, la)
			la.SolicitResponseButton(AddOn.player:GetName(), false, la)
			_G.MSA_DROPDOWNMENU_MENU_VALUE = ""
			la.SolicitResponseButton(AddOn.player:GetName(), true, la)
		end)

		it("ends session", function()
			la:EndSession(true)
			assert(not la.frame:IsVisible())
			assert(not la:IsEnabled())
		end)
	end)
end)