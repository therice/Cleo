--- @type string
local AddOnName
--- @type AddOn
local AddOn
--- @type LibUtil
local Util
--- @type Models.Player
local Player
local C
--- @type Models.Item.CreatureLootSource
local CreatureLootSource

describe("MasterLooter", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_MasterLooter')
		loadfile('Modules/Test/MasterLooterTestData.lua')()
		C = AddOn.Constants
		Util, Player, CreatureLootSource =
			AddOn:GetLibrary('Util'), AddOn.Package('Models').Player, AddOn.Package('Models.Item').CreatureLootSource
		AddOnLoaded(AddOnName, true)
		SetTime()
	end)

	teardown(function()
		--print(Util.Objects.ToString( AddOn.Require('Core.Event').private.metricsRcv:Summarize()))
		--print(Util.Objects.ToString( AddOn.Require('Core.Comm').private.metricsSend:Summarize()))
		--print(Util.Objects.ToString( AddOn.Require('Core.Comm').private.metricsRecv:Summarize()))
		--print(Util.Objects.ToString( AddOn.Require('Core.Comm').private.metricsFired:Summarize()))
		After()
	end)

	describe("lifecycle", function()
		teardown(function()
			AddOn:YieldModule("LootSession")
			AddOn:YieldModule("MasterLooter")
		end)

		it("is disabled on startup", function()
			local module = AddOn:MasterLooterModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("MasterLooter")
			local module = AddOn:MasterLooterModule()
			assert(module)
			assert(module:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("MasterLooter")
			local module = AddOn:MasterLooterModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
	end)

	describe("setup", function()
		local module, LM, Send

		before_each(function()
			_G.IsInRaidVal = true
			Send = AddOn.Send
			AddOn.player = Player:Get("Player1")
			AddOn:CallModule("MasterLooter")
			AddOn:CallModule("Lists")
			LM = AddOn:ListsModule()
			module = AddOn:MasterLooterModule()
			module.db.profile.usage = {
				state  = 1,
				whenLeader = true,
			}
			module.db.profile.lcSelectionMethod = 1
			_G.UnitIsUnit = function(unit1, unit2) return true end
			AddOn.Send = function(...)
				Send(...)
				WoWAPI_FireUpdate(GetTime()+10)
			end
		end)

		after_each(function()
			AddOn:YieldModule("LootSession")
			AddOn:YieldModule("Lists")
			AddOn:YieldModule("MasterLooter")
			AddOn:StopHandleLoot()
			AddOn.Send = Send
			AddOn.masterLooter = nil
			AddOn.player = nil
			module, LM = nil, nil
		end)

		it("when no configuration is specified", function()
			PlayerEnteredWorld()
			assert(module:IsDisabled())
		end)

		it("when ml is not configuration admin/owner", function()
			local db = NewAceDb(ListDataConfigNoAdmin)
			LM.db = db
			LM:InitializeService()
			PlayerEnteredWorld()
			assert(module:IsDisabled())
		end)

		it("when configuration has no lists", function()
			local db = NewAceDb(ListDataConfigAdminNoLists)
			LM.db = db
			LM:InitializeService()
			PlayerEnteredWorld()
			assert(module:IsDisabled())
		end)

		it("with valid configuration", function()
			local db = NewAceDb(ListDataComplete)
			LM.db = db
			LM:InitializeService()
			PlayerEnteredWorld()
			assert(module:IsEnabled())
		end)
	end)

	describe("events", function()
		local module, LM, Send

		setup(function()
			_G.IsInRaidVal = true
			AddOn.player = Player:Get("Player1")
			Send = AddOn.Send
			AddOn.Send = function(...)
				Send(...)
				WoWAPI_FireUpdate(GetTime()+10)
			end
			AddOn:CallModule("Lists")
			LM = AddOn:ListsModule()
			LM.db = NewAceDb(ListDataComplete)
			LM:InitializeService()
			AddOn:CallModule("MasterLooter")
			module = AddOn:MasterLooterModule()
			module.db.profile.usage = {
				state  = 1,
				whenLeader = true,
			}
			module.db.profile.lcSelectionMethod = 1
			_G.UnitIsUnit = function(unit1, unit2) return true end
			PlayerEnteredWorld()
		end)

		teardown(function()
			AddOn:YieldModule("LootSession")
			AddOn:YieldModule("Lists")
			AddOn:StopHandleLoot()
			AddOn.Send = Send
			AddOn.masterLooter = nil
			module = nil
		end)

		--
		-- FYI regarding semantics of testing and stubbed WOW API calls (see Testing/WowApi.lua)
		--
		-- GetNumLootItems returns 3
		-- LootSlotHasItem returns true if mod 2 is not 0 (slot 1 and 3 returns true, 2 is false)
		-- GetLootSourceInfo returns a random creature, independent of the slot
		it("handles LOOT_READY", function()
			WoWAPI_FireEvent("LOOT_READY")
			assert(module:IsEnabled())
			assert(module:GetLootSlot(1))
			assert(not module:GetLootSlot(2))
			assert(module:GetLootSlot(3))
		end)

		it("handles LOOT_OPENED", function()
			WoWAPI_FireEvent("LOOT_OPENED")
			assert(module:IsEnabled())
			assert(module:GetLootSlot(1))
			assert(not module:GetLootSlot(2))
			assert(module:GetLootSlot(3))
			assert(module:GetLootTableEntry(1))
			assert(module:GetLootTableEntry(2))
			assert(not module:GetLootTableEntry(3))
			local lt = module:GetLootTableForTransmit()
			assert(#lt == 2)
			for _, e in pairs(lt) do
				assert(e.ref)
				assert(e.owner)
				assert(not e.awarded)
				assert(not e.sent)
			end
		end)
		it("handles LOOT_SLOT_CLEARED", function()
			WoWAPI_FireEvent("LOOT_SLOT_CLEARED", 1)
			assert(module:IsEnabled())
			assert(module:GetLootSlot(1).looted)
		end)

		it("handles LOOT_CLOSED", function()
			WoWAPI_FireEvent("LOOT_CLOSED")
			assert(module:IsEnabled())
			assert(module.lootOpen == false)
		end)
	end)

	describe("functionality", function()
		--- @type MasterLooter
		local ml
		--- @type LootAllocate
		local la
		local LM, Send
		setup(function()
			_G.IsInRaidVal = true
			_G.UnitIsGroupLeaderVal = true
			_G.UnitIsUnit = function(unit1, unit2) return true end
			AddOn.player = Player:Get("Player1")
			Send = AddOn.Send
			AddOn.Send = function(...)
				Send(...)
				WoWAPI_FireUpdate(GetTime()+10)
			end
			AddOn:CallModule("Lists")
			LM = AddOn:ListsModule()
			LM.db = NewAceDb(ListDataComplete)
	        LM:InitializeService()
			-- AddOn.masterLooter = AddOn.player
			AddOn:CallModule("MasterLooter")
			ml = AddOn:MasterLooterModule()
			ml.db.profile.autoStart = true
			ml.db.profile.autoAdd = true
			ml.db.profile.outOfRaid = true
			ml.db.profile.acceptWhispers = true
			-- there is an edge case in the testing framework where OnUpdate
			-- is called repeatedly for timeout bar which results in endless loop
			-- just disable it, the functionality is tested elsewhere
			ml.db.profile.timeout.enabled = false
			ml.db.profile.usage = {
				state  = 1,
				whenLeader = true,
			}
			ml.db.profile.lcSelectionMethod = 1
			ml.db.profile.announceItemText = { channel = "group", text = "&s: &i Item Level (&l) Item Type (&t) Owner(&o) List(&ln)"}
			la = AddOn:LootAllocateModule()
			PlayerEnteredWorld()
			assert(ml:IsEnabled())
			assert(AddOn:IsMasterLooter())
			GuildRosterUpdate()
		end)

		teardown(function()
			AddOn:YieldModule("MasterLooter")
			AddOn:StopHandleLoot()
			AddOn:YieldModule("Loot")
			AddOn:YieldModule("LootAllocate")
			AddOn:YieldModule("Lists")
			AddOn.Send = Send
			AddOn.masterLooter = nil
			AddOn.player = nil
			AddOn.handleLoot = false
			ml, la = nil, nil
		end)

		it("sends LootTable", function()
			-- override testing behavior for test suite
			_G.LootSlotHasItem = function() return true end
			WoWAPI_FireEvent("LOOT_READY")
			WoWAPI_FireEvent("LOOT_OPENED")
			WoWAPI_FireUpdate(GetTime()+10)
			assert(AddOn.lootTable)
			assert(#AddOn.lootTable >= 1)
		end)

		it("handles Reconnect", function ()
			AddOn:Send(AddOn.masterLooter, C.Commands.Reconnect)
			_G.UnitIsUnit = function(unit1, unit2) return false end
			WoWAPI_FireUpdate(GetTime()+10)
			_G.UnitIsUnit = function(unit1, unit2) return true end
		end)

		it("HaveUnawardedItems", function()
			assert(ml:HaveUnawardedItems())
		end)

		it("UpdateLootSlots (with no changes)", function()
			ml:UpdateLootSlots()
		end)

		it("CanGiveLoot", function()
			ml.lootOpen = false
			local ok, cause = ml:CanGiveLoot(nil, 1, AddOn.player:GetName())
			assert(not ok)
			assert(cause == ml.AwardStatus.Failure.LootNotOpen)

			ml.lootOpen = true
			ok, cause = ml:CanGiveLoot( nil, 5, AddOn.player:GetName())
			assert(not ok)
			assert.equal(cause, ml.AwardStatus.Failure.LootGone)

			local _CreatureLootSource_FromCurrent = CreatureLootSource.FromCurrent
			CreatureLootSource.FromCurrent = function(slot) return CreatureLootSource("Creature-0-4379-34-1065-46382-00076A3954", slot) end
			ok, cause = ml:CanGiveLoot(nil, 1,  AddOn.player:GetName())
			assert(not ok)
			assert.equal(cause, ml.AwardStatus.Failure.LootSourceMismatch)

			local lootSlotInfo = ml:GetLootSlot(1)

			CreatureLootSource.FromCurrent = function(slot) return ml:GetLootSlot(slot).source end
			ok, cause = ml:CanGiveLoot("item:999999:0:0:0:0:0:0:0:233", 1, AddOn.player:GetName())
			assert(not ok)
			assert.equal(cause, ml.AwardStatus.Failure.LootGone)

			local _GetContainerNumFreeSlots = _G.C_Container.GetContainerNumFreeSlots
			_G.C_Container.GetContainerNumFreeSlots = function(container)
				return 0, 0
			end
			lootSlotInfo = ml:GetLootSlot(1)
			ok, cause = ml:CanGiveLoot(lootSlotInfo.item, 1, AddOn.player:GetName())
			assert(not ok)
			assert.equal(cause, ml.AwardStatus.Failure.MLInventoryFull)

			_G.C_Container.GetContainerNumFreeSlots = function(container)
				return 4, 0
			end
			_G.UnitIsUnit = function(unit1, unit2) return false end
			_G.UnitIsConnected = function(unit) return false end
			lootSlotInfo = ml:GetLootSlot(1)
			ok, cause = ml:CanGiveLoot( lootSlotInfo.item, 1, AddOn.player:GetName())
			assert(not ok)
			assert.equal(cause, ml.AwardStatus.Failure.Offline)

			_G.UnitIsConnected = function(unit) return true end
			lootSlotInfo = ml:GetLootSlot(1)
			ok, cause = ml:CanGiveLoot( lootSlotInfo.item, 1, AddOn.player:GetName())
			assert(not ok)
			assert.equal(cause, ml.AwardStatus.Failure.NotBop)

			_G.UnitIsUnit = function(unit1, unit2) return true end
			lootSlotInfo = ml:GetLootSlot(1)
			ok, cause = ml:CanGiveLoot( lootSlotInfo.item, 1,  AddOn.player:GetName())
			assert(ok)
			assert(cause == nil)

			finally(function()
				CreatureLootSource.FromCurrent = _CreatureLootSource_FromCurrent
				_G.C_Container.GetContainerNumFreeSlots = _GetContainerNumFreeSlots
			end)
		end)

		it("Award", function()
			local cbFired = false
			local function Cb(awarded, session, winner, status, award, ...)
				cbFired = true
				assert(awarded)
				assert.equal(1, session)
				assert.equal("Player1-Realm1", winner)
				assert.equal("Normal", status)
				assert(award)
				--print(Util.Objects.ToString(award:toTable()))
				assert.equal("ms_need", award.awardReason)
			end

			local _CreatureLootSource_FromCurrent = CreatureLootSource.FromCurrent
			CreatureLootSource.FromCurrent = function(slot) return ml:GetLootSlot(slot).source end

			WoWAPI_FireUpdate(GetTime() + 10)

			-- partial suicide workflow
			la:OnResponseReceived(2, "Player504-Realm1", {response = 3})
			local award = AddOn:LootAllocateModule():GetItemAward(2, "Player504-Realm1")
			ml:Award(award, Util.Functions.Noop, award)
			WoWAPI_FireEvent("LOOT_SLOT_CLEARED", 2)
			WoWAPI_FireUpdate(GetTime() + 10)

			-- normal suicide workflow
			AddOn:SendResponse(C.group, 1, 1)
			WoWAPI_FireUpdate(GetTime() + 10)
			award = AddOn:LootAllocateModule():GetItemAward(1, AddOn.player:GetName())
			ml:Award(award, Cb, award)
			WoWAPI_FireEvent("LOOT_SLOT_CLEARED", 1)
			assert(cbFired)
			WoWAPI_FireUpdate(GetTime() + 10)

			-- this handles the testing of alt mapping
			la:OnResponseReceived(3, "Player525-Realm1", {response = 1})
			award = AddOn:LootAllocateModule():GetItemAward(3, "Player525-Realm1")
			ml:Award(award, Util.Functions.Noop, award)
			WoWAPI_FireEvent("LOOT_SLOT_CLEARED", 3)

			finally(function()
				CreatureLootSource.FromCurrent = _CreatureLootSource_FromCurrent
			end)
		end)

		it("Auto Award", function()
			ml.db.profile.autoAward = true
			ml.db.profile.autoAwardReason = 'bank'
			ml.db.profile.autoAwardUpperThreshold = 3
			ml.db.profile.autoAwardType = ml.AutoAwardType.All
			ml.db.profile.autoAwardTo = AddOn.player:GetShortName()
			ml:AddLootSlot(2)

			local loot = ml:GetLootSlot(2)
			loot.quality = 3

			local shouldAutoAward, _, awardTo = ml:ShouldAutoAward(loot.item, loot.quality)
			assert(shouldAutoAward)
			assert.equal(ml.db.profile.autoAwardTo, awardTo)

			local _CreatureLootSource_FromCurrent = CreatureLootSource.FromCurrent
			CreatureLootSource.FromCurrent = function(slot) return loot.source end

			local awarded = ml:AutoAward(loot.item, 2, loot.quality, ml.db.profile.autoAwardTo, "normal")
			assert(awarded)

			finally(function()
				CreatureLootSource.FromCurrent = _CreatureLootSource_FromCurrent
			end)
		end)

		it("handles whispers", function()
			WoWAPI_FireEvent("LOOT_READY")
			WoWAPI_FireEvent("LOOT_OPENED")
			WoWAPI_FireUpdate(GetTime()+10)

			SendChatMessage("!help", "WHISPER")
			SendChatMessage("!items", "WHISPER")
			SendChatMessage("!item 2 1", "WHISPER")
			WoWAPI_FireUpdate(GetTime() + 10)

			local cr2 = la:GetCandidateResponse(2, AddOn.player:GetName())
			assert(cr2)
			assert.equal(cr2.response, 1)
		end)

		it("UpdateLootSlots (with potential changes)", function()
			local _ItemIsItem = AddOn.ItemIsItem
			AddOn.ItemIsItem = function() return true end

			ml:UpdateLootSlots()

			finally(function()
				AddOn.ItemIsItem = _ItemIsItem
			end)
		end)

		it("ends session", function()
			ml:EndSession()
			assert(not ml.running)
		end)
	end)
end)