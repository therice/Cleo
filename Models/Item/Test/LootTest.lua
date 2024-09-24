local AddOnName, AddOn
--- @type Models.Item.Item
local Item
---@type Models.Item.LootSlotInfo
local LootSlotInfo
--- @type Models.Item.LootTableEntry
local LootTableEntry
--- @type Models.Item.CreatureLootSource
local CreatureLootSource
--- @type Models.Item.PlayerLootSource
local PlayerLootSource
--- @type Models.Item.LootedItem
local LootedItem
--- @type Models.Player
local Player
--- @type LibUtil
local Util

describe("Item Model", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_Item_Loot')
		Item, Util, LootSlotInfo, LootTableEntry, CreatureLootSource, PlayerLootSource, LootedItem, Player =
			AddOn.Package('Models.Item').Item, AddOn:GetLibrary('Util'),
			AddOn.Package('Models.Item').LootSlotInfo, AddOn.Package('Models.Item').LootTableEntry,
			AddOn.Package('Models.Item').CreatureLootSource, AddOn.Package('Models.Item').PlayerLootSource,
			AddOn.Package('Models.Item').LootedItem, AddOn.Package('Models').Player
		SetTime()
	end)

	teardown(function()
		After()
	end)

	describe("CreatureLootSource", function()
		it("supports equality", function()
			local ls1 = CreatureLootSource("Creature-0-4379-34-1065-46382-00076A3954", 1)
			local ls2 = CreatureLootSource("Creature-0-4379-34-1065-46382-00076A3954", 1)
			local ls3 = CreatureLootSource("Creature-0-4379-34-1065-46383-00006A3954", 2)
			assert(ls1 == ls2)
			assert.equal(ls1, ls2)
			assert.are_not.equal(ls1, ls3)

			assert.are_not.equal(ls1, nil)
			assert.are_not.equal(ls2, nil)
			assert.are_not.equal(ls3, nil)
		end)
		it("raises errors", function()
			assert.has.errors(function() CreatureLootSource("x") end, "x is not a valid creature GUID")

			assert.has.errors(function() CreatureLootSource.FromCurrent() end, "loot slot must be a number")
			assert.has.errors(function() CreatureLootSource.FromCurrent(-1) end, "loot slot must greater than or equal to 1")

			local _GetNumLootItems, _GetLootSourceInfo = _G.GetNumLootItems, _G.GetLootSourceInfo

			_G.GetNumLootItems = function() return 1 end
			assert.has.errors(function() CreatureLootSource.FromCurrent(2) end, "2 is not a valid loot slot (1 available)")

			_G.GetLootSourceInfo = function(_) return nil, 0, nil, 0 end
			assert.has.errors(function() CreatureLootSource.FromCurrent(1) end, "loot slot source could not be obtained")

			finally(function()
				_G.GetNumLootItems = _GetNumLootItems
				_G.GetLootSourceInfo = _GetLootSourceInfo
			end)
		end)
	end)

	describe("PlayerLootSource", function()
		it("supports equality", function()
			local ps1 = PlayerLootSource("Player-4372-0232E2F9", "Item-4372-0-400000033D4D1C15")
			local ps2 = PlayerLootSource("Player-4372-0232E2F9", "Item-4372-0-400000032A8C4E67")
			local ps3 = PlayerLootSource("Player-4372-0232E2C8", "Item-4372-0-4000000342062402")
			assert(ps1 == ps2)
			assert.equal(ps1, ps2)
			assert.are_not.equal(ps1, ps3)

			assert.are_not.equal(ps1, nil)
			assert.are_not.equal(ps2, nil)
			assert.are_not.equal(ps3, nil)
		end)

		it("raises errors", function()
			assert.has.errors(function() PlayerLootSource("x") end, "x is not a valid player GUID")
			assert.has.errors(function() PlayerLootSource("Player-4372-0232E2F9") end, "nil is not a valid item GUID")
			assert.has.errors(function() PlayerLootSource("Player-4372-0232E2F9", "Player-4372-0232E2F9") end, "Player-4372-0232E2F9 is not a valid item GUID")

			assert.has.errors(function() PlayerLootSource.FromCurrentPlayer() end, "nil is not a valid item GUID")

			local _Player_Get, _UnitGUID = Player.Get, _G.UnitGUID
			Player.Get = function() return nil end
			assert.has.errors(function() PlayerLootSource.FromCurrentPlayer() end, "could not determine current player")
			Player.Get = _Player_Get
			_G.UnitGUID = function() return nil end
			assert.has.errors(function() PlayerLootSource.FromCurrentPlayer() end, "player is not valid")
			_G.UnitGUID = _UnitGUID
			Player.Get = function() return Player("Player-1122-00000003", "Unknown", "DEATHKNIGHT", "Atiesh") end
			assert.has.errors(function() PlayerLootSource.FromCurrentPlayer() end, "player is unknown")
			Player.Get = _Player_Get

			finally(function()
				Player.Get = _Player_Get
				_G.UnitGUID = _UnitGUID
			end)
		end)
	end)

	describe("LootSlotInfo", function()
		it("is created", function()
			local lsi = LootSlotInfo(1, "name", "item:1:0:0:0:0:0:0:0:60", 1, 4)
			assert.equal(lsi:GetSlot(), 1)
			assert.equal(lsi.item, "item:1:0:0:0:0:0:0:0:60")
		end)

		it("provides item", function()
			local lsi = LootSlotInfo(1, "name", "item:18832:0:0:0:0:0:0:0:60", 1, 4)
			local item = lsi:GetItem()
			assert(item)
			assert.equals(item.id, 18832)
			assert(item:IsValid())
			assert(not item:IsBoe())
		end)

		it("supports checking if from source", function()
			local lsi1 = LootSlotInfo(1, "name", "item:1:0:0:0:0:0:0:0:60", 1, 4)
			local lsi2 = LootSlotInfo(2, "name", "item:2:0:0:0:0:0:0:0:60", 1, 4)

			lsi1.source.id = 123456
			lsi2.source.id = 789012

			assert(lsi1:IsFromSource(lsi1.source))
			assert(lsi2:IsFromSource(lsi2.source))
			assert(not lsi1:IsFromSource(lsi2.source))
			assert(not lsi2:IsFromSource(lsi1.source))

			local source = CreatureLootSource.FromCurrent(1)
			source.id = 99999 -- make sure it doesn't pick up a random one that could be equivalent
			assert(not lsi1:IsFromSource(source))
			assert(not lsi2:IsFromSource(source))

			local lsi3 = LootSlotInfo(3, "name", "item:3:0:0:0:0:0:0:0:60", 1, 4)
			lsi3.source = nil
			assert(not lsi1:IsFromSource(nil))
			assert(lsi3:IsFromSource(nil))
		end)
	end)

	describe("LootTableEntry", function()
		it("is created", function()
			local lte = LootTableEntry(18832, CreatureLootSource.FromCurrent(1))
			assert.equal(lte.source.slot, 1)
			assert(not lte.awarded)
			assert(not lte.sent)
			assert.errors(function() LootTableEntry(18834) end, "loot source was not provided")
		end)
		it("provides item", function()
			local lte = LootTableEntry(18832, CreatureLootSource.FromCurrent(1))
			local item = lte:GetItem()
			assert(item)
			assert.equals(item.id, 18832)
			assert(item:IsValid())
			assert(not item:IsBoe())
		end)
		it("supports checking if from source", function()
			local lte1 = LootTableEntry(18832, CreatureLootSource.FromCurrent(1))
			local lte2 = LootTableEntry(18833, CreatureLootSource.FromCurrent(2))

			lte1.source.id = "Creature-0-4379-34-1065-46382-00076A3954"
			lte2.source.id = "Creature-0-4379-34-1065-46383-00006A3954"

			assert(lte1:IsFromSource(lte1.source))
			assert(lte2:IsFromSource(lte2.source))
			assert(not lte1:IsFromSource(lte2.source))
			assert(not lte2:IsFromSource(lte1.source))

			local source = CreatureLootSource.FromCurrent(1)
			source.id = "Creature-0-1465-0-2105-448-000043F59F" -- make sure it doesn't pick up a random one that could be equivalent
			assert(not lte1:IsFromSource(source))
			assert(not lte2:IsFromSource(source))
		end)
	end)

	describe("LootedItem", function()
		it("is created", function()
			local li = LootedItem("item:18832:0:0:0:0:0:0:0:60", LootedItem.State.AwardLater, "Item-4372-0-400000033D4D1C15")
			assert.equal("Item-4372-0-400000033D4D1C15", li.guid)
			assert.equal("item:18832:0:0:0:0:0:0:0:60", li.item)
			assert.equal(LootedItem.State.AwardLater, li.state)
			li = LootedItem("item:18833:0:0:0:0:0:0:0:60", LootedItem.State.AwardLater)
			assert(li.guid == nil)
			assert.equal("item:18833:0:0:0:0:0:0:0:60", li.item)
			assert.equal(LootedItem.State.AwardLater, li.state)
		end)
		it("is reconstituted", function()
			local li = LootedItem:reconstitute({guid = 'Item-4372-0-400000033D4D1C15', item = 'item:18832:0:0:0:0:0:0:0:60', added = 1724710817, state = 'AL'})
			assert.equal("Item-4372-0-400000033D4D1C15", li.guid)
			assert.equal("item:18832:0:0:0:0:0:0:0:60", li.item)
			assert.equal(LootedItem.State.AwardLater, li.state)
			assert.equal(1724710817, li.added)
			li = LootedItem:reconstitute({item = 'item:18833:0:0:0:0:0:0:0:60', added = 1724710818, state = 'AL'})
			assert(li.guid == nil)
			assert.equal("item:18833:0:0:0:0:0:0:0:60", li.item)
			assert.equal(LootedItem.State.AwardLater, li.state)
			assert.equal(1724710818, li.added)
		end)
		it("supports equality", function()
			local item1, item2 =
				LootedItem("|cffa335ee|Hitem:15917:::::::::::::::::|h[ItemName15917]|h|r", LootedItem.State.AwardLater, "Item-4372-0-400000033D4D1C15"),
				LootedItem("|cffa335ee|Hitem:15917:::::::::::::::::|h[ItemName15917]|h|r", LootedItem.State.AwardLater, "Item-4372-0-400000033D4D1C15")
			assert.equal(item1, item2)
		end)
		it("is validated upon creation/reconstitution", function()
			assert.has.errors(function() LootedItem(18832, LootedItem.State.AwardLater, "Item-4372-0-") end, "Item-4372-0- is not a valid item GUID")
			assert.has.errors(function() LootedItem(18832, LootedItem.State.AwardLater, "Item-4372-0-400000033D4D1C15") end, "18832 is not a valid item string")
			assert.has.errors(function() LootedItem(18832, LootedItem.State.AwardLater) end, "18832 is not a valid item string")
			assert.has.errors(function() LootedItem("item:18832:0:0:0:0:0:0:0:60", 'NA', "Item-4372-0-400000033D4D1C15") end, "NA is not a valid item state")
			assert.has.errors(function() LootedItem("item:18832:0:0:0:0:0:0:0:60", 'NA') end, "NA is not a valid item state")

			assert.has.errors(function() LootedItem:reconstitute({guid = 'Item-4372-0-', item = 18832, added = 0, state = 'AL'}) end, "Item-4372-0- is not a valid item GUID")
			assert.has.errors(function() LootedItem:reconstitute({guid = 'Item-4372-0-400000033D4D1C15', item = 18832, added = 0, state = 'AL'}) end, "18832 is not a valid item string")
			assert.has.errors(function() LootedItem:reconstitute({item = 18832, added = 0, state = 'AL'}) end, "18832 is not a valid item string")
			assert.has.errors(function() LootedItem:reconstitute({guid = 'Item-4372-0-400000033D4D1C15', item = 'item:18832:0:0:0:0:0:0:0:60', added = 0, state = 'NA'}) end, "NA is not a valid item state")
			assert.has.errors(function() LootedItem:reconstitute({ item = 'item:18832:0:0:0:0:0:0:0:60', added = 0, state = 'NA'}) end, "NA is not a valid item state")
		end)
		it("handles valid check", function()
			local li = LootedItem(select(2, GetItemInfo(18832)), LootedItem.State.AwardLater, "Item-4372-0-400000033D4D1C15")
			assert(li:IsValid())
			--li:SetTimeRemaining(GetServerTime(), 2700)
			--assert(li:IsValid())
			li = LootedItem(select(2, GetItemInfo(18832)), LootedItem.State.AwardLater)
			li.state = 'FB'
			assert(not li:IsValid())
			--li:SetTimeRemaining( GetServerTime(), 2700)
			--assert(li:IsValid())
		end)
		it("supports auxiliary methods", function()
			local item = LootedItem("|cffa335ee|Hitem:15917:::::::::::::::::|h[ItemName15917]|h|r", LootedItem.State.AwardLater, "Item-4372-0-400000033D4D1C15")
			item.added = 1727108404
			assert.has.match("09/23/2024 %d+%d+:20:04", item:FormattedTimestampAdded())
			assert.equal("Award Later", item:GetStateDescription())
			item.state = LootedItem.State.ToTrade
			assert.equal("To Trade", item:GetStateDescription())
		end)
	end)
end)