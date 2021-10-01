local AddOnName, AddOn
--- @type LibUtil
local Util
--- @type Models.List.List
local List
--- @type Models.Player
local Player

describe("Item Model", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_List_List')
		Util, List, Player =
			AddOn:GetLibrary('Util'), AddOn.Package('Models.List').List,
			AddOn.Package('Models').Player

	end)

	teardown(function()
		After()
	end)

	describe("List", function()
		local uuid = Util.UUID.UUID

		it("overrides toTable", function()
			local l1 = List(uuid(), uuid(), "ListName")
			l1.players:Add(Player:Get('Player1'))
			l1.players:AddFirst(Player:Get('Player2'))

			local t = l1:toTable()
			assert.equal(t.players[1], '1-00000002')
			assert.equal(t.players[2], '1-00000001')

			local l2 = List:reconstitute(t)
			-- print(Util.Objects.ToString(t))
			--print(Util.Objects.ToString(l2:toTable()))
			assert.equal(l2.players:Get(1).guid, 'Player-1-00000002')
			assert.equal(l2.players:Get(2).guid, 'Player-1-00000001')
			assert.same(t, l2:toTable())
		end)

		it("handles equipment add/remove", function()
			local l = List(uuid(), uuid(), "ListName")
			l:AddEquipment("INVTYPE_HEAD", "INVTYPE_FEET")
			l:AddEquipment("INVTYPE_HEAD", "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONMAINHAND")
			assert.same({"INVTYPE_HEAD", "INVTYPE_FEET", "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND"}, l.equipment)
			l:RemoveEquipment("INVTYPE_HEAD", "INVTYPE_WEAPONMAINHAND")
			assert.same({"INVTYPE_FEET", "INVTYPE_WEAPON"}, l.equipment)
			-- print(Util.Objects.ToString(l:toTable()))
		end)
	end)
end)