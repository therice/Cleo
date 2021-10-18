local AddOnName, AddOn
--- @type LibUtil
local Util
--- @type Models.List.List
local List
--- @type Models.Player
local Player

describe("List Model", function()
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

		it("handles players", function()
			local l1 = List(uuid(), uuid(), "ListName")
			l1:AddPlayer(Player:Get('Player1'))
			l1:AddPlayer(Player:Get('Player3'), 100)
			l1:AddPlayer(Player:Get('Eliovak'), 4)
			l1:AddPlayer(Player:Get('Player2'), 1)

			local t = l1:toTable()
			print(Util.Objects.ToString(t.players))
			assert.equal(t.players[1], '1-00000002')
			assert.equal(t.players[2], '1-00000001')
			assert.equal(t.players[3], '4372-00706FE5')
			assert.equal(t.players[4], '1122-00000003')

			local l2 = List:reconstitute(t)
			assert.equal(l2:GetPlayer(1), Player:Get('Player2'))
			assert.equal(l2:GetPlayer(2), Player:Get('Player1'))
			assert.equal(l2:GetPlayer(3), Player:Get('Eliovak'))
			assert.equal(l2:GetPlayer(4), Player:Get('Player3'))
			assert.same(t, l2:toTable())

			assert.same(
				{"1-00000002", "1-00000001", "4372-00706FE5", "1122-00000003"},
				l2:GetPlayers(true)
			)

			local prio, player = l2:GetPlayerPriority("Player2"), nil
			assert.equal(1, prio)

			l2:SetPlayers("Eliovak", "Folsom", "Gnomechómsky")
			assert.equal(l2:GetPlayer(1), Player:Get('Eliovak'))
			assert.equal(l2:GetPlayer(2), Player:Get('Folsom'))
			assert.equal(l2:GetPlayer(3), Player:Get('Gnomechómsky'))

			prio, player = l2:RemovePlayer("Eliovak")
			assert.equal(prio, 1)
			assert.equal(player, Player:Get('Eliovak'))
			assert.equal(2, Util.Tables.Count(l2.players))
			-- the remove shifts everyone else up in priority
			assert.equal(l2:GetPlayer(1), Player:Get('Folsom'))
			assert.equal(l2:GetPlayer(2), Player:Get('Gnomechómsky'))

			l1 = List(uuid(), uuid(), "ListName")
			l1:AddPlayer(Player:Get('Player1'))
			l1:AddPlayer(Player:Get('Player4'), 4)
			l1:AddPlayer(Player:Get('Player3'), 100)
			l1:AddPlayer(Player:Get('Eliovak'), 15)
			l1:AddPlayer(Player:Get('Player2'), 1)
			assert.equal(l1:GetPlayer(1), Player:Get('Player2'))
			prio, player = l1:RemovePlayer("Player1", false)
			assert.equal(1, l1:GetPlayerPriority('Player2'))
			assert.equal(4, l1:GetPlayerPriority('Player4'))
			assert.equal(100, l1:GetPlayerPriority('Player3'))
			prio, player = l1:RemovePlayer("Player4", true)
			assert.equal(1, l1:GetPlayerPriority('Player2'))
			assert.equal(14, l1:GetPlayerPriority('Eliovak'))
			assert.equal(99, l1:GetPlayerPriority('Player3'))

			prio, player = l1:GetPlayerPriority('Player2', true)
			assert.equal(1, prio)
			prio, player = l1:GetPlayerPriority('Eliovak', true)
			assert.equal(2, prio)
			prio, player = l1:GetPlayerPriority('Player3', true)
			assert.equal(3, prio)
		end)
		it("handles equipment add/remove", function()
			local l = List(uuid(), uuid(), "ListName")
			l:AddEquipment("INVTYPE_HEAD", "INVTYPE_FEET")
			l:AddEquipment("INVTYPE_HEAD", "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONMAINHAND")
			assert.same({"INVTYPE_FEET", "INVTYPE_HEAD", "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND"}, l.equipment)
			l:RemoveEquipment("INVTYPE_HEAD", "INVTYPE_WEAPONMAINHAND")
			assert.same({"INVTYPE_FEET", "INVTYPE_WEAPON"}, l.equipment)
		end)
		it("is hashable", function()
			local l = List(uuid(), uuid(), "ListName")
			l:AddEquipment("INVTYPE_HEAD", "INVTYPE_FEET")
			l:AddEquipment("INVTYPE_HEAD", "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONMAINHAND")
			l:AddPlayer(Player:Get('Player1'))
			l:AddPlayer(Player:Get('Player4'), 4)
			l:AddPlayer(Player:Get('Player3'), 100)
			l:AddPlayer(Player:Get('Eliovak'), 15)
			l:AddPlayer(Player:Get('Player2'), 1)
			local h1, h2 = l:hash(), nil
			print(h1)
			l:RemovePlayer(Player:Get('Eliovak'))
			l:RemoveEquipment("INVTYPE_HEAD", "INVTYPE_WEAPONMAINHAND")
			h2 = l:hash()
			assert.Not.equal(h1, h2)
			l:AddPlayer(Player:Get('Eliovak'), 15)
			l:AddEquipment("INVTYPE_HEAD", "INVTYPE_WEAPONMAINHAND")
			h2 = l:hash()
			assert.equal(h1, h2)
			l:NewRevision(GetServerTime() + 10)
			h2 = l:hash()
			assert.equal(h1, h2)
		end)
		it("is referenceable", function()
			local l = List(uuid(), uuid(), "ListName")
			l:AddEquipment("INVTYPE_HEAD", "INVTYPE_FEET")
			l:AddEquipment("INVTYPE_HEAD", "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONMAINHAND")
			l:AddPlayer(Player:Get('Player1'))
			l:AddPlayer(Player:Get('Player4'), 4)
			l:AddPlayer(Player:Get('Player3'), 100)
			l:AddPlayer(Player:Get('Eliovak'), 15)
			l:AddPlayer(Player:Get('Player2'), 1)
			local ref = l:ToRef()
			print(Util.Objects.ToString(ref))
			assert(ref)
			assert(ref.id)
			assert(ref.hash)
			assert(ref.revision)
			assert(ref.version)
			assert.equal('Models.List', ref.pkg)
			assert.equal('List', ref.clz)

			local l2 = AddOn.Require('Models.Referenceable').FromRef(ref)

			print(Util.Objects.ToString(l2:toTable()))
		end)
	end)
end)