local AddOnName, AddOn
--- @type Models.Item.Item
local Item
---@type Models.Item.LootSlotInfo
local LootSlotInfo
--- @type Models.Item.LootTableEntry
local LootTableEntry
--- @type Models.Item.LootSlotSource
local LootSlotSource
--- @type LibUtil
local Util

describe("Item Model", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_Item_Loot')
		Item, Util, LootSlotInfo, LootTableEntry, LootSlotSource =
			AddOn.Package('Models.Item').Item, AddOn:GetLibrary('Util'),
			AddOn.Package('Models.Item').LootSlotInfo, AddOn.Package('Models.Item').LootTableEntry,
			AddOn.Package('Models.Item').LootSlotSource
	end)

	teardown(function()
		After()
	end)


	describe("LootSlotSource", function()
		it("supports equality", function()
			local ls1 = LootSlotSource(1, nil)
			local ls2 = LootSlotSource(1, "xyz")
			local ls3 = LootSlotSource(2, "xyz")
			assert(ls1 == ls2)
			assert.equal(ls1, ls2)
			assert.are_not.equal(ls1, ls3)

			assert.are_not.equal(ls1, nil)
			assert.are_not.equal(ls2, nil)
			assert.are_not.equal(ls3, nil)
		end)
	end)

	describe("LootSlotInfo", function()
		it("is created", function()
			local lsi = LootSlotInfo(1, "name", "item:1:0:0:0:0:0:0:0:60", 1, 4)
			assert.equal(lsi.slot, 1)
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

			local source = LootSlotSource.FromCurrent()
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
			local lte = LootTableEntry(1, 18832)
			assert.equal(lte.slot, 1)
			assert(not lte.awarded)
			assert(not lte.sent)
		end)

		it("provides item", function()
			local lte = LootTableEntry(1, 18832)
			local item = lte:GetItem()
			assert(item)
			assert.equals(item.id, 18832)
			assert(item:IsValid())
			assert(not item:IsBoe())
		end)

		it("supports checking if from source", function()
			local lte1 = LootTableEntry(1, 18832, LootSlotSource.FromCurrent(1))
			local lte2 = LootTableEntry(2, 18833, LootSlotSource.FromCurrent(2))

			lte1.source.id = 123456
			lte2.source.id = 789012

			assert(lte1:IsFromSource(lte1.source))
			assert(lte2:IsFromSource(lte2.source))
			assert(not lte1:IsFromSource(lte2.source))
			assert(not lte2:IsFromSource(lte1.source))

			local source = LootSlotSource.FromCurrent()
			source.id = 99999 -- make sure it doesn't pick up a random one that could be equivalent
			assert(not lte1:IsFromSource(source))
			assert(not lte2:IsFromSource(source))

			local lte3 = LootTableEntry(3, 18834)
			assert(not lte1:IsFromSource(nil))
			assert(lte3:IsFromSource(nil))
		end)
	end)
end)