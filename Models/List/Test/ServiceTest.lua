local AddOnName, AddOn
--- @type LibUtil
local Util
--- @type Models.List.Service
local Service


describe("Service Model", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_List_Service')
		Util, Service = AddOn:GetLibrary('Util'), AddOn.Package('Models.List').Service
	end)

	teardown(function()
		After()
	end)

	describe("Service", function()
		local db = NewAceDb(
				{
					factionrealm = {
						configurations = {
							["614A4F87-AF52-34B4-E983-B9E8929D44AF"] = {
								["permissions"] = {
									["Player-4372-01D08047"] = {
										["bitfield"] = 5,
									},
									["Player-4372-011C6125"] = {
										["bitfield"] = 5,
									},
									["Player-4372-01FC8D1A"] = {
										["bitfield"] = 3,
									},
									["Player-4372-0000835A"] = {
										["bitfield"] = 1,
									},
									["Player-4372-000054BB"] = {
										["bitfield"] = 1,
									},
								},
								["name"] = "Tempest Keep",
							},
						},
						lists = {
							["61534E26-36A0-4F24-51D7-BE511B88B834"] = {
								["configId"] = "614A4F87-AF52-34B4-E983-B9E8929D44AF",
								["players"] = {
									"4372-00706FE5",
									"4372-01C6940A",
									"4372-01642E85",
									"1-00000031",
									"4372-011C6125",
									"4372-00C1D806",
									"1-00000045",
									"4372-000054BB",
									"4372-0034311C",
									"4372-0004FD18",
									"1-00000001",
								},
								["name"] = "Head, Feet, Wrist",
								["equipment"] = {
									"INVTYPE_HEAD", -- [1]
									"INVTYPE_FEET", -- [2]
									"INVTYPE_WRIST", -- [3]
								},
							},
							["6154C617-5A91-7304-3DAD-EBE283795429"] = {
								["players"] = {
									"1-00000031",
									"1-00000045",
									"4372-01C6940A",
									"4372-01642E85",
									"4372-00C1D806",
									"4372-000054BB",
									"4372-0034311C",
									"4372-00706FE5",
									"4372-0004FD18",
									"1-00000001",
									"4372-011C6125",
								},
								["equipment"] = {
									"INVTYPE_RELIC", -- [1]
									"INVTYPE_HOLDABLE", -- [2]
								},
								["name"] = "Misc",
								["configId"] = "614A4F87-AF52-34B4-E983-B9E8929D44AF",
							},
							["6154C601-3450-00C4-6D98-D3BF57AB9FA4"] = {
								["players"] = {
									"1-00000031",
									"1-00000045",
									"4372-01642E85",
									"4372-00C1D806",
									"4372-000054BB",
									"4372-0034311C",
									"4372-00706FE5",
									"4372-0004FD18",
									"1-00000001",
									"4372-011C6125",
								},
								["equipment"] = {
									"INVTYPE_WEAPONMAINHAND", -- [1]
									"INVTYPE_WEAPONOFFHAND", -- [2]
									"INVTYPE_WEAPON", -- [3]
									"INVTYPE_RANGED", -- [4]
									"INVTYPE_2HWEAPON", -- [5]
									"INVTYPE_TRINKET", -- [6]
								},
								["name"] = "Weapon",
								["configId"] = "614A4F87-AF52-34B4-E983-B9E8929D44AF",
							},
						},
					}
				}
		)

		local StubModule, S

		setup(function()
			StubModule = AddOn:NewModule('Stub')

			function StubModule:OnEnable()
				self.db = db
			end

			function StubModule:EnableOnStartup()
				return true
			end

			AddOnLoaded(AddOnName, true)

			S = Service(
					{StubModule, StubModule.db.factionrealm.configurations},
					{StubModule, StubModule.db.factionrealm.lists}
			)
		end)

		teardown(function()
			AddOn:YieldModule('Stub')
			StubModule = nil
		end)

		it("is initialized", function()
			local configs = S:Configurations()
			assert(configs)
			assert.equal(1, Util.Tables.Count(configs))
			local config = Util.Tables.First(configs)
			local lists = S:Lists(config.id)
			assert(lists)
			assert.equal(3, Util.Tables.Count(lists))
		end)

		it("is activated", function()
			--- @type  Models.List.ActiveConfiguration
			local ac = S:Activate("614A4F87-AF52-34B4-E983-B9E8929D44AF")
			assert.equal("614A4F87-AF52-34B4-E983-B9E8929D44AF", ac.config.id)
			assert(Util.Tables.Count(ac.lists), Util.Tables.Count(ac.lists))
			for _, list in pairs(ac.listsActive) do
				assert.equal(0, list:GetPlayerCount())
			end
		end)

		it("handles player joined event", function()
			--- @type  Models.List.ActiveConfiguration
			local ac = S:Activate("614A4F87-AF52-34B4-E983-B9E8929D44AF")
			ac:OnPlayerEvent("4372-01C6940A", true)
			ac:OnPlayerEvent("1-00000031", true)
			ac:OnPlayerEvent("4372-0004FD18", true)
			ac:OnPlayerEvent("1-00000001", true)
			ac:OnPlayerEvent("4372-01642E85", true)
			ac:OnPlayerEvent("4372-00C1D806", true)
			ac:OnPlayerEvent("1-00000099", true)

			local list = ac:GetOriginalList("61534E26-36A0-4F24-51D7-BE511B88B834")
			assert.same(
					{
						"4372-00706FE5",
						"4372-01C6940A",
						"4372-01642E85",
						"1-00000031",
						"4372-011C6125",
						"4372-00C1D806",
						"1-00000045",
						"4372-000054BB",
						"4372-0034311C",
						"4372-0004FD18",
						"1-00000001",
						"1-00000099"
					},
					list:GetPlayers(true)
			)

			list = ac:GetActiveList("61534E26-36A0-4F24-51D7-BE511B88B834")
			assert(list)
			assert.same(
					{
						"4372-01C6940A",
						"4372-01642E85",
						"1-00000031",
						"4372-00C1D806",
						"4372-0004FD18",
						"1-00000001",
						"1-00000099"
					},
					list:GetPlayers(true, true)
			)

		end)

		it("handles player joined event (duplicate)", function()
			--- @type  Models.List.ActiveConfiguration
			local ac = S:Activate("614A4F87-AF52-34B4-E983-B9E8929D44AF")
			ac:OnPlayerEvent("4372-01C6940A", true)
			ac:OnPlayerEvent("4372-01C6940A", true)
			local list = ac:GetActiveList("61534E26-36A0-4F24-51D7-BE511B88B834")
			assert(list)
			assert.same(
					{
						"4372-01C6940A",
					},
					list:GetPlayers(true, true)
			)
		end)

		it("handles player joined event (at random and dupes)", function()
			--- @type  Models.List.ActiveConfiguration
			local ac = S:Activate("614A4F87-AF52-34B4-E983-B9E8929D44AF")

			local allPlayers = {}
			for _, list in pairs(db.factionrealm.lists) do
				Util.Tables.CopyInto(allPlayers, list.players)
			end

			allPlayers = Util.Tables.Unique(allPlayers)
			Util.Tables.Shuffle(allPlayers)
			ac:OnPlayerEvent("Player-1-00000031", true)

			for _, p in pairs(allPlayers) do
				ac:OnPlayerEvent(p, true)
			end

			local list, players
			for listId, origList in pairs(db.factionrealm.lists) do
				list = ac:GetActiveList(listId)
				players = list:GetPlayers(true, true)

				-- there could have been extra players added to list, as
				-- no all test lists contained all players
				local compareTo = Util.Tables.Sub(players, 1, #origList.players)
				assert.same(
					origList.players,
					compareTo
				)
				--[[
				print(listId .. '(raw) => ' .. Util.Objects.ToString(list:GetPlayers(true, false)))
				print(listId .. '(normalized) => ' .. Util.Objects.ToString(list:GetPlayers(true, true)))
				print(listId .. '(extra) => ' .. Util.Objects.ToString(Util.Tables.Sub(players, #origList.players)))
				--]]
			end
		end)

		it("handles loot event", function()
			--- @type  Models.List.ActiveConfiguration
			local ac = S:Activate("614A4F87-AF52-34B4-E983-B9E8929D44AF")
			ac:OnPlayerEvent("4372-00706FE5", true)
			ac:OnPlayerEvent("1-00000001", true)
			ac:OnPlayerEvent("4372-000054BB", true)
			ac:OnPlayerEvent("4372-01642E85", true)
			ac:OnPlayerEvent("1-00000031", true)
			--[[
				6154C601-3450-00C4-6D98-D3BF57AB9FA4 => {1-00000031, 4372-01642E85, 4372-000054BB, 4372-00706FE5, 1-00000001}
				61534E26-36A0-4F24-51D7-BE511B88B834 => {4372-00706FE5, 4372-01642E85, 1-00000031, 4372-000054BB, 1-00000001}
				6154C617-5A91-7304-3DAD-EBE283795429 => {1-00000031, 4372-01642E85, 4372-000054BB, 4372-00706FE5, 1-00000001}
			--]]

			local al, ol =
				ac:GetActiveList("61534E26-36A0-4F24-51D7-BE511B88B834"),
				ac:GetOriginalList("61534E26-36A0-4F24-51D7-BE511B88B834")
			assert.same (
				{'4372-00706FE5', '4372-01C6940A', '4372-01642E85', '1-00000031', '4372-011C6125', '4372-00C1D806', '1-00000045', '4372-000054BB', '4372-0034311C', '4372-0004FD18', '1-00000001'},
				ol:GetPlayers(true)
			)
			-- BEFORE
			-- {4372-00706FE5, 3 = 4372-01642E85, 4 = 1-00000031, 8 = 4372-000054BB, 11 = 1-00000001}
			assert.same(
					{'4372-00706FE5', [3] = '4372-01642E85', [4] = '1-00000031', [8] = '4372-000054BB', [11] = '1-00000001'},
					al:GetPlayers(true)
			)
			ac:OnLootEvent("4372-01642E85", "INVTYPE_HEAD")
			-- AFTER
			-- {4372-00706FE5, 3 = 1-00000031, 4 = 4372-000054BB, 8 = 1-00000001, 11 = 4372-01642E85}
			assert.same(
					{'4372-00706FE5', [3] = '1-00000031', [4] = '4372-000054BB', [8] = '1-00000001', [11] = '4372-01642E85'},
					al:GetPlayers(true)
			)

			-- BEFORE
			-- {4372-00706FE5, 4372-01C6940A, 4372-01642E85, 1-00000031, 4372-011C6125, 4372-00C1D806, 1-00000045, 4372-000054BB, 4372-0034311C, 4372-0004FD18, 1-00000001}
			-- AFTER
			-- {4372-00706FE5, 4372-01C6940A, 1-00000031, 4372-000054BB, 4372-011C6125, 4372-00C1D806, 1-00000045, 1-00000001, 4372-0034311C, 4372-0004FD18, 4372-01642E85
			assert.same (
					{'4372-00706FE5', '4372-01C6940A', '1-00000031', '4372-000054BB', '4372-011C6125', '4372-00C1D806', '1-00000045',  '1-00000001', '4372-0034311C', '4372-0004FD18', '4372-01642E85'},
					ol:GetPlayers(true)
			)
		end)

		it("handles player left event", function()
			--- @type  Models.List.ActiveConfiguration
			local ac = S:Activate("614A4F87-AF52-34B4-E983-B9E8929D44AF")
			ac:OnPlayerEvent("4372-01C6940A", true)
			ac:OnPlayerEvent("1-00000031", true)
			ac:OnPlayerEvent("4372-0004FD18", true)
			ac:OnPlayerEvent("1-00000001", true)
			ac:OnPlayerEvent("4372-01642E85", true)
			ac:OnPlayerEvent("4372-00C1D806", true)
			ac:OnPlayerEvent("1-00000099", true)

			local al, ol =
				ac:GetActiveList("61534E26-36A0-4F24-51D7-BE511B88B834"),
				ac:GetOriginalList("61534E26-36A0-4F24-51D7-BE511B88B834")

			assert(al)
			assert.same(
					{
					[2] = "4372-01C6940A",
					[3] = "4372-01642E85",
					[4] = "1-00000031",
					[6] = "4372-00C1D806",
					[10] = "4372-0004FD18",
					[11] = "1-00000001",
					[12] = "1-00000099"
				},
					al:GetPlayers(true)
			)
			assert.same (
					{'4372-00706FE5', '4372-01C6940A', '4372-01642E85', '1-00000031', '4372-011C6125', '4372-00C1D806', '1-00000045', '4372-000054BB', '4372-0034311C', '4372-0004FD18', '1-00000001', '1-00000099'},
					ol:GetPlayers(true)
			)

			ac:OnPlayerEvent("1-00000001", false)
			assert.same(
					{
						[2] = "4372-01C6940A",
						[3] = "4372-01642E85",
						[4] = "1-00000031",
						[6] = "4372-00C1D806",
						[10] = "4372-0004FD18",
						[12] = "1-00000099"
					},
					al:GetPlayers(true)
			)
			assert.same (
					{'4372-00706FE5', '4372-01C6940A', '4372-01642E85', '1-00000031', '4372-011C6125', '4372-00C1D806', '1-00000045', '4372-000054BB', '4372-0034311C', '4372-0004FD18', '1-00000001', '1-00000099'},
					ol:GetPlayers(true)
			)

			ac:OnPlayerEvent("1-00000031", false)
			assert.same(
					{
						[2] = "4372-01C6940A",
						[3] = "4372-01642E85",
						[6] = "4372-00C1D806",
						[10] = "4372-0004FD18",
						[12] = "1-00000099"
					},
					al:GetPlayers(true)
			)
			assert.same (
					{'4372-00706FE5', '4372-01C6940A', '4372-01642E85', '1-00000031', '4372-011C6125', '4372-00C1D806', '1-00000045', '4372-000054BB', '4372-0034311C', '4372-0004FD18', '1-00000001', '1-00000099'},
					ol:GetPlayers(true)
			)
		end)
	end)
end)