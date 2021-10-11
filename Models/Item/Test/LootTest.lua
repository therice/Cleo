local AddOnName, AddOn
--- @type Models.Item.Item
local Item
---@type Models.Item.LootSlotInfo
local LootSlotInfo
--- @type Models.Item.LootTableEntry
local LootTableEntry
--- @type LibUtil
local Util

describe("Item Model", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_Item_Loot')
		Item, Util, LootSlotInfo, LootTableEntry =
			AddOn.Package('Models.Item').Item, AddOn:GetLibrary('Util'),
			AddOn.Package('Models.Item').LootSlotInfo, AddOn.Package('Models.Item').LootTableEntry
	end)

	teardown(function()
		After()
	end)

	describe("LootSlotInfo", function()
		it("is created", function()
			local lsi = LootSlotInfo(1, "name", "item:1:0:0:0:0:0:0:0:60", 1, 4, "BossGUID", "BossName")
			assert.equal(lsi.slot, 1)
			assert.equal(lsi.item, "item:1:0:0:0:0:0:0:0:60")
		end)

		it("provides item", function()
			local lsi = LootSlotInfo(1, "name", "item:18832:0:0:0:0:0:0:0:60", 1, 4, "BossGUID", "BossName")
			local item = lsi:GetItem()
			assert(item)
			assert.equals(item.id, 18832)
			assert(item:IsValid())
			assert(not item:IsBoe())
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
	end)
end)