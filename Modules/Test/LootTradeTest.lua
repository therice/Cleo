--- @type AddOn
local AddOn
local AddOnName

--- @type LibUtil
local Util
--- @type Core.Message
local Message
local C

insulate("LootTrade", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_LootTrade')
		Util = AddOn.Libs.Util
		AddOnLoaded(AddOnName, true)
		SetTime()
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		it("is disabled on startup", function()
			local module = AddOn:LootTradeModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("LootTrade")
			local module = AddOn:LootTradeModule()
			assert(module)
			assert(module:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("LootTrade")
			local module = AddOn:LootTradeModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
	end)
end)

insulate("LootTrade", function()

	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_LootTrade')
		loadfile('Modules/Test/MasterLooterTestData.lua')()
		C = AddOn.Constants
		Util = AddOn.Libs.Util
		Message = AddOn.RequireOnUse('Core.Message')
		AddOnLoaded(AddOnName, true)
		SetTime()
		WoWAPI_FireUpdate(GetTime() + 10)
	end)

	teardown(function()
		After()
	end)

	local function BecomeMasterLooter()
		-- all of this stuff is to setup necessary stubs and data
		-- so that test can assume ML role
		_G.UnitIsUnit = function(unit1, unit2)
			if Util.Objects.In("player", unit1, unit2) and unit1 ~= unit2 then
				return true
			end

			return unit1 == unit2
		end

		local ML = AddOn:MasterLooterModule()
		ML.db.profile.usage = {
			state  = 1,
			whenLeader = true,
		}
		ML.db.profile.lcSelectionMethod = 1

		AddOn:ListsModule().db = NewAceDb(ListDataComplete)
		AddOn:ListsModule():InitializeService()
		AddOn.Testing:EnableAndBecomeMasterLooter()
	end

	describe("messages", function()
		setup(function()
			BecomeMasterLooter()
		end)

		teardown(function()
			AddOn.Testing:ResignMasterLooterAndDisable()
		end)

		it("handles loot start", function()
			local module = AddOn:LootTradeModule()
			assert(module)
			assert(module:IsEnabled())
		end)

		it("handles loot stop", function()
			AddOn.Testing.MasterLooter:Resign()
			local module = AddOn:LootTradeModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
	end)

	describe("events", function()
		--- @type LootTrade
		local lootTrade
		local twItems = {}

		setup(function()
			loadfile('Modules/Test/ModuleTestUtil.lua')(AddOn)
			BecomeMasterLooter()
			lootTrade = AddOn:LootTradeModule()
			lootTrade.db.profile.autoTrade = true
		end)

		teardown(function()
			AddOn.Testing:ResignMasterLooterAndDisable()
		end)

		it("handles TRADE_SHOW (No Target)", function()
			WoWAPI_FireEvent("TRADE_SHOW")
			assert(lootTrade.trading)
			assert.equal(lootTrade.target, "Npc-Realm1")
			assert.equal(#lootTrade.items, 0)
		end)

		it("handles TRADE_SHOW (Player Target)", function()

			_G.TradeFrameRecipientNameText = {
				GetText = function(self)
					return "Player520"
				end
			}

			--[[
			      award={
        equipLoc="INVTYPE_WRIST",
        reason="minor_upgrade",
        origin=1,
        responseId=3,
        winner="Annasthétic-Atiesh",
        session=1,
        response="Minor Upgrade"
      }
			--]]
			ModuleWithData(AddOn:LootLedgerModule(), {
				['deb99e6d9ac4e323b91b161229a720ae75e49c7e9af2bf84a341175afde20dae'] = -- 09/04/24 09:02:32
					{
						state = 'TT', item = '|cffa335ee|Hitem:15917:::::::::::::::::|h[ItemName15917]|h|r',
						guid = 'Item-4372-0-400000033D4D1C17',  added = 1725462152,
						supplemental = {
							award = {
								equipLoc="INVTYPE_HEAD",
								reason="ms_need",
								origin=1,
								responseId=1,
								winner = 'Player520-Realm1',
								response="Suicide",
							}
						}
					},
				['4a154b00055db56f26ed2249bbfdff40710747efb669aaea4527e77648cc44a6'] = -- 09/04/24 08:33:10
					{
						state = 'TT', item = '|cffa335ee|Hitem:15918:::::::::::::::::|h[ItemName15918]|h|r',
						guid = 'Item-4372-0-400000033D4D1C16', added = 1725460390,
						supplemental = {
							award = {
								equipLoc="INVTYPE_WRIST",
								reason="minor_upgrade",
								origin=1,
								responseId=3,
								winner = 'Player520-Realm1',
								response="Minor Upgrade",
							}
						}
					},
				['255d65a327fa1d1e58ffe80dc10a87922377f34e8b2fefb4a10e20cd11325d61'] = -- 09/04/24 08:32:15
					{
						state = 'AL', item = '|cffa335ee|Hitem:15919:::::::::::::::::|h[ItemName15919]|h|r',
						guid = 'Item-4372-0-400000033D4D1C18', added = 1725460335
					},
				['655e6616e3a818c5568a8bd6d671fef27ba9aaf3c0e64de86569d588203c1bda'] = -- 09/04/24 08:57:28
					{
						state = 'TT', item = '|cffa335ee|Hitem:15920:::::::::::::::::|h[ItemName15920]|h|r',
						guid = 'Item-4372-0-400000033D4D1C19', added = 1725461848,
						supplemental = {
							award = {
								equipLoc="INVTYPE_TRINKET",
								reason="os_greed",
								origin=1,
								responseId=2,
								winner = 'Player504-Realm1',
								response="Open Roll",
							}
						}
					},
			}, true)

			local _GetBagAndSlotByGUID, _AddItemsToTradeWindow  =
				AddOn.GetBagAndSlotByGUID, lootTrade.AddItemsToTradeWindow

			AddOn.GetBagAndSlotByGUID = function(_, guid)
				if guid == 'Item-4372-0-400000033D4D1C17' then
					return 1, 4
				elseif guid == 'Item-4372-0-400000033D4D1C16' then
					return 1, 5
				elseif guid == 'Item-4372-0-400000033D4D1C18' then
					return 3, 9
				elseif guid == 'Item-4372-0-400000033D4D1C19' then
					return 4, 1
				end

				return _GetBagAndSlotByGUID(AddOn, guid)
			end

			lootTrade.AddItemsToTradeWindow = function(_, items)
				twItems = Util.Tables.Merge(twItems, items)
			end

			WoWAPI_FireEvent("TRADE_SHOW")
			assert(lootTrade.trading)
			assert.equal(lootTrade.target, "Player520-Realm1")
			assert.equal(#lootTrade.items, 0)
			assert.equal(#twItems, 2)

			finally(function()
				_G.TradeFrameRecipientNameText = nil
				AddOn.GetBagAndSlotByGUID = _GetBagAndSlotByGUID
				lootTrade.AddItemsToTradeWindow = _AddItemsToTradeWindow
			end)
		end)

		it("handles TRADE_ACCEPT_UPDATE", function()
			assert.equal(#twItems, 2)
			local _GetTradePlayerItemLink = _G.GetTradePlayerItemLink

			_G.GetTradePlayerItemLink = function(index)
				if index <= #twItems then
					return twItems[index].item
				end

				return nil
			end

			WoWAPI_FireEvent("TRADE_ACCEPT_UPDATE", 1, 1)
			assert.equal(#lootTrade.items, 2)

			finally(function()
				_G.GetTradePlayerItemLink = _GetTradePlayerItemLink
			end)
		end)

		it("handles UI_INFO_MESSAGE", function()
			-- no error type, should result in nothing being done
			WoWAPI_FireEvent("UI_INFO_MESSAGE")
			-- with appropriate error type
			WoWAPI_FireEvent("UI_INFO_MESSAGE", _G.LE_GAME_ERR_TRADE_COMPLETE)
			WoWAPI_FireUpdate(GetTime() + 25)
		end)

		it("handles TRADE_CLOSED", function()
			WoWAPI_FireEvent("TRADE_CLOSED")
			assert(not lootTrade.trading)
		end)
	end)
end)