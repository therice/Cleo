local AddOnName, AddOn
--- @type Models.Item.Item
local Item
--- @type Models.Item.ItemRef
local ItemRef
--- @type LibUtil
local Util
--- @type LibItemUtil
local ItemUtil

describe("Item Model", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_Item_Item')
		Item, ItemRef, Util, ItemUtil =
			AddOn.Package('Models.Item').Item, AddOn.Package('Models.Item').ItemRef,
			AddOn:GetLibrary('Util'), AddOn:GetLibrary("ItemUtil")
	end)

	teardown(function()
		After()
	end)

	describe("Item", function()
		before_each(function()
			ItemUtil:SetCustomItems({})
			Item.ClearCache()
		end)
		it("is created from query", function()
			local item = Item.Get(18832)
			assert.equals(item.id, 18832)
			assert(item:IsValid())
			assert(not item:IsBoe())
		end)
		it("is created from custom item", function()
			ItemUtil:SetCustomItems({
				[18832] = {
					rarity = 4,
					item_level = 100,
					equip_location =  "INVTYPE_WAIST",
				}
            })

			local item = Item.Get(18832)
			assert.equals(item.id, 18832)
			assert(item:IsValid())
			assert.equals("100", item:GetLevelText())
			assert.equals("Waist", item:GetTypeText())
		end)
		it("is cloned", function()
			local item1 = Item.Get(18832)
			local item2 = item1:clone()
			assert.are.same(item1:toTable(), item2:toTable())
		end)
		it("provides expected text", function()
			local item = Item.Get(18832)
			assert.equals("One-Hand, One-Handed Swords", item:GetTypeText())
			assert.equals("70", item:GetLevelText())
		end)
	end)

	describe("ItemRef", function()
		it("provides item", function()
			assert.equal(ItemRef(18832):GetItem(), Item.Get(18832))
			assert.are.same(
					ItemRef("|cff9d9d9d|Hitem:18832:2564:0:0:0:0:0:0:60:0:0:0:0|h[Brutality Blade]|h|r"):GetItem():toTable(),
					Item.Get(18832):toTable()
			)
			assert.are.same(
					ItemRef("item:18832:2564:0:0:0:0:0:0:60:0:0:0:0"):GetItem():toTable(),
					Item.Get(18832):toTable()
			)
			assert.are.same(
					ItemRef("item:18832:0:0:0:0:0:0::"):GetItem():toTable(),
					Item.Get(18832):toTable()
			)
			assert.are.same(
					ItemRef("item:18832"):GetItem():toTable(),
					Item.Get(18832):toTable()
			)
			assert.equal(ItemRef("18832"):GetItem(), Item.Get(18832))
		end)
		it("provides transmission format", function()
			assert.equal("18832", ItemRef(18832):ForTransmit())
			assert.equal("18832", ItemRef("18832"):ForTransmit())
			assert.equal("18832::0:0:0:0:0::::0", ItemRef("|cff9d9d9d|Hitem:18832::0:0:0:0:0:0:60:0:0:0:0|h[Brutality Blade]|h|r"):ForTransmit())
			assert.equal("18832", ItemRef("item:18832:::::::::::::::::"):ForTransmit())
			assert.equal("18832:0:0:0:0:0:0", ItemRef("item:18832:0:0:0:0:0:0::"):ForTransmit())
			assert.equal("18832", ItemRef("item:18832"):ForTransmit())
			assert.equal("18832", ItemRef("item:18832:"):ForTransmit())
		end)
	end)
end)