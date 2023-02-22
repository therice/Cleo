local AddOnName, AddOn
--- @type LibUtil
local Util
--- @type Models.List.Service
local Service
--- @type Models.Dao
local Dao
--- @type Models.List.Configuration
local Configuration
--- @type Models.List.List
local List

describe("Service Model", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_List_Service')
		Util, Service = AddOn:GetLibrary('Util'), AddOn.Package('Models.List').Service
		Dao =  AddOn.Package('Models').Dao
		Configuration, List = AddOn.Package('Models.List').Configuration, AddOn.Package('Models.List').List
	end)

	teardown(function()
		After()
	end)

	describe("Service", function()
		function newdb()
			return NewAceDb(
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
								["Player-1-00000001"] = {
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
							["revision"] = 1634059874,
							["version"] = {
								["minor"] = 0,
								["patch"] = 0,
								["major"] = 1,
							},
							["status"] = 1,
							["default"] = true,
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
							["version"] = {
								["minor"] = 0,
								["patch"] = 0,
								["major"] = 1,
							},
							["revision"] = 1633983642,
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
							["revision"] = 1633983813,
							["version"] = {
								["minor"] = 0,
								["patch"] = 0,
								["major"] = 1,
							},
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
							["revision"] = 1633983647,
							["version"] = {
								["minor"] = 0,
								["patch"] = 0,
								["major"] = 1,
							},
						},
					},
				}
			})
		end

		local StubModule
		--- @type Models.List.Service
		local S

		setup(function()
			StubModule = AddOn:NewModule('Stub')

			function StubModule:OnEnable()
				self.db = newdb()
			end

			function StubModule:OnDisable()
				self.db = nil
			end

			function StubModule:EnableOnStartup()
				return false
			end
		end)

		before_each(function()
			AddOnLoaded(AddOnName, true)
			AddOn:CallModule('Stub')

			S = Service(
					{StubModule, StubModule.db.factionrealm.configurations},
					{StubModule, StubModule.db.factionrealm.lists}
			)
		end)

		--teardown(function()
		after_each(function()
			AddOn:YieldModule('Stub')
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
		it("provides callbacks", function()

			local r = {}

			assert.error(
					function()
						S:RegisterCallbacks(r, {
							[Configuration] = {},
							[List] = {},
							[Dao] = {},
			            })
					end
			)

			S:RegisterCallbacks(r, {
                [Configuration] = {
	                [Dao.Events.EntityCreated] = function() end,
	                [Dao.Events.EntityDeleted] = function() end,
                },
                [List] = {
	                [Dao.Events.EntityUpdated] = function() end,
                },
			})

			S:UnregisterCallbacks(r, {
				[Configuration] = { Dao.Events.EntityCreated, Dao.Events.EntityDeleted },
				[List]          = { Dao.Events.EntityUpdated }
			})

			S:UnregisterAllCallbacks(r)


			local C = Configuration.CreateInstance()
			local L = List.CreateInstance(C.id)

			local events = {
				[C] = {
					[Dao.Events.EntityCreated] = 0,
					[Dao.Events.EntityDeleted] = 0,
					[Dao.Events.EntityUpdated] = {

					},
				},
				[L] = {
					[Dao.Events.EntityCreated] = 0,
					[Dao.Events.EntityDeleted] = 0,
					[Dao.Events.EntityUpdated] = {

					},
				}
			}

			local function IncrementEventCount(eventDetail, event)
				local entity, attr = eventDetail.entity, eventDetail.attr
				if attr then
					if not events[entity][event][attr] then
						events[entity][event][attr] = 0
					end
					events[entity][event][attr] = events[entity][event][attr] + 1
				else
					events[entity][event] = events[entity][event] + 1
				end
			end

			local x = {
				EntityCreated = function(_, event, eventDetail)
					print('EntityCreated')
					IncrementEventCount(eventDetail, event)
				end,
				EntityDeleted = function(_, event, eventDetail)
					print('EntityDeleted')
					IncrementEventCount(eventDetail, event)
				end,
				EntityUpdated = function(_, event, eventDetail)
					-- print(format('EntityUpdated (%s) => %s', attr, Util.Objects.ToString(diff)))
					-- print(format('EntityUpdated %s / %s', entity:hash(), asRef.hash))
					IncrementEventCount(eventDetail, event)
					local entity, ref, attr = eventDetail.entity, eventDetail.ref, eventDetail.attr
					assert.Not.equal(entity:hash(), ref.hash)
					if entity:TriggersNewRevision(attr) then
						print('Expect new revision -> ' .. tostring(attr))
						assert.Not.equal(entity.revision, ref.revision)
					end
				end
			}

			S:RegisterCallbacks(x, {
                [Configuration] = {
                    [Dao.Events.EntityCreated] = function(...) x:EntityCreated(...) end,
                    [Dao.Events.EntityDeleted] = function(...) x:EntityDeleted(...) end,
                    [Dao.Events.EntityUpdated] = function(...) x:EntityUpdated(...) end,
                },
                [List] = {
	                [Dao.Events.EntityCreated] = function(...) x:EntityCreated(...) end,
	                [Dao.Events.EntityDeleted] = function(...) x:EntityDeleted(...) end,
	                [Dao.Events.EntityUpdated] = function(...) x:EntityUpdated(...) end,
                },
            })

			S.Configuration:Add(C)
			S.List:Add(L)
			assert.equal(1, events[C][Dao.Events.EntityCreated])
			assert.equal(1, events[L][Dao.Events.EntityCreated])

			C.name = "An Updated Name"
			S.Configuration:Update(C, 'name')
			C.status = Configuration.Status.Inactive
			S.Configuration:Update(C, 'status')
			assert.equal(1, events[C][Dao.Events.EntityUpdated]['name'])
			assert.equal(1, events[C][Dao.Events.EntityUpdated]['status'])

			L:AddEquipment("INVTYPE_WEAPONOFFHAND")
			S.List:Update(L, 'equipment')
			L:AddPlayer("Player2")
			S.List:Update(L, 'players')
			assert.equal(1, events[L][Dao.Events.EntityUpdated]['equipment'])
			assert.equal(1, events[L][Dao.Events.EntityUpdated]['players'])

			S.List:Remove(L)
			S.Configuration:Remove(C)
			assert.equal(1, events[C][Dao.Events.EntityDeleted])
			assert.equal(1, events[L][Dao.Events.EntityDeleted])

			S:UnregisterAllCallbacks(x)
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
		it("marhsalls as CSV", function()
			local cs = S:Configurations(true, true)
			for _, c in pairs(cs) do
				assert(c ~= nil)
			end
		end)

		it("handles refs", function()
			local cs = S:Configurations(true, true)
			assert(cs and Util.Tables.Count(cs) == 1)
			local c = Util.Tables.Values(cs)[1]
			local ls = S:Lists(c.id)
			assert(ls and Util.Tables.Count(ls) == 3)
			local refs, subRefs = {}, {}
			Util.Tables.Push(refs, c:ToRef())
			for _, l in pairs(ls) do
				Util.Tables.Push(subRefs, l:ToRef())
			end
			Util.Tables.Push(refs, subRefs)
			local loaded = S:LoadRefs(refs)
			assert.same(loaded[1]:toTable(), c:toTable())
			assert(type(loaded[2]) == 'table')
			for _, ll in pairs(loaded[2]) do
				assert.same(ls[ll.id]:toTable(), ll:toTable())
			end

			refs = { }
			Util.Tables.Push(refs, c:ToRef())
			Util.Tables.Set(refs, 'lists', subRefs)

			loaded = S:LoadRefs(refs)
			assert.same(loaded[1]:toTable(), c:toTable())
			assert(type(loaded['lists']) == 'table')
			assert(#loaded['lists'] == 3)

			local subRefsSparse = Util.Tables.Copy(subRefs)
			subRefsSparse[2].id = 'WILL-NOT-BE-FOUND'
			refs = { }
			Util.Tables.Push(refs, c:ToRef())
			Util.Tables.Push(refs, subRefsSparse)
			loaded = S:LoadRefs(refs)
			assert(type(loaded[2]) == 'table')
			-- ref at index 2 was given a bogus id, it won't be resolved
			-- this means the returned list will be sparse
			assert(#loaded[2] == 1)
			assert(Util.Tables.Count(loaded) == 2)
		end)
		it("verifies activated", function()
			local cs = S:Configurations(true, true)
			local c = Util.Tables.Values(cs)[1]
			local ls = S:Lists(c.id)
			local refs, subRefs = {}, {}
			Util.Tables.Push(refs, c:ToRef())
			for _, l in pairs(ls) do
				Util.Tables.Push(subRefs, l:ToRef())
			end
			Util.Tables.Push(refs, subRefs)

			local ac = S:Activate("614A4F87-AF52-34B4-E983-B9E8929D44AF")
			local vs = ac:Verify(refs[1], refs[2])
			assert(vs)
			assert(#vs == 2)
			local v, l = vs[1], vs[2]
			assert(v)
			assert(v.verified)
			assert(l)
			assert(#l == 3)

			local subRefsSparse = Util.Tables.Copy(subRefs)
			subRefsSparse[2].id = 'WILL-NOT-BE-FOUND'
			refs = { }
			Util.Tables.Push(refs, c:ToRef())
			Util.Tables.Push(refs, subRefsSparse)
			--[[ Example
			{
				{verified = true, ah = c1593923b6bc76e4ab3b45bd2ac9282c16eac93280c68b61647b1cbefdaa1556, ch = c1593923b6bc76e4ab3b45bd2ac9282c16eac93280c68b61647b1cbefdaa1556},
				{
					{
						6154C601-3450-00C4-6D98-D3BF57AB9FA4 = {verified = true, ah = 49a04b4c41a7c93784973b94cc1703b365d79d1aa1c8796a91d9879fd2b7c5ba, ch = 49a04b4c41a7c93784973b94cc1703b365d79d1aa1c8796a91d9879fd2b7c5ba},
						6154C617-5A91-7304-3DAD-EBE283795429 = {verified = true, ah = c5bf108803dac6fecd179578f613731be442f85f710cfaa2ca44d876dfe1f8be, ch = c5bf108803dac6fecd179578f613731be442f85f710cfaa2ca44d876dfe1f8be}
					},
					{
						61534E26-36A0-4F24-51D7-BE511B88B834
					},
					{
						WILL-NOT-BE-FOUND
					}
				}
			} --]]
			vs = ac:Verify(refs[1], refs[2])
			assert(vs)
			assert(#vs == 2)
			v, l = vs[1], vs[2]
			assert(v)
			assert(v.verified)
			assert(l)
			--print(Util.Objects.ToString(l, 4))
			assert(#l == 3)
			assert.equal(2, Util.Tables.Count(l[1]))
			local lv = l[1]
			assert(Util.Tables.ContainsKey(lv, '6154C601-3450-00C4-6D98-D3BF57AB9FA4'))
			assert(lv['6154C601-3450-00C4-6D98-D3BF57AB9FA4'].verified)
			assert.equal(1, Util.Tables.Count(l[2]))
			lv = l[2]
			assert.equal('61534E26-36A0-4F24-51D7-BE511B88B834', lv[1])
			assert.equal(1, Util.Tables.Count(l[3]))
			lv = l[3]
			assert.equal('WILL-NOT-BE-FOUND', lv[1])

			--print( AddOn.Package('Models.List').Configuration.name)
			--print( AddOn.Package('Models.List').List.name)
		end)
		it("handles player joined event", function()
			--- @type  Models.List.ActiveConfiguration
			local ac = S:Activate("614A4F87-AF52-34B4-E983-B9E8929D44AF")

			--- @type Lists
			local L = AddOn:ListsModule()
			L:SetService(S, ac)

			local ML = AddOn:MasterLooterModule()
			local _IsMasterLooter = AddOn.IsMasterLooter
			local _IsHandled = ML.IsHandled
			AddOn.IsMasterLooter = function(self) return true end
			ML.IsHandled = function(self) return true end


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

			finally(function()
				L:InitializeService()
				AddOn.IsMasterLooter = _IsMasterLooter
				ML._IsHandled = _IsHandled
			end)
		end)

		it("handles player joined event (duplicate)", function()
			local ML = AddOn:MasterLooterModule()
			local _IsMasterLooter = AddOn.IsMasterLooter
			local _IsHandled = ML.IsHandled
			AddOn.IsMasterLooter = function(self) return true end
			ML.IsHandled = function(self) return true end

			local cs = S:Configurations(true, true)
			local c = Util.Tables.Values(cs)[1]
			--- @type  Models.List.ActiveConfiguration
			local ac = S:Activate(c)

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

			finally(function()
				AddOn.IsMasterLooter = _IsMasterLooter
				ML._IsHandled = _IsHandled
			end)
		end)

		it("handles player joined event (at random and dupes)", function()
			local ML = AddOn:MasterLooterModule()
			local _IsMasterLooter = AddOn.IsMasterLooter
			local _IsHandled = ML.IsHandled
			AddOn.IsMasterLooter = function(self) return true end
			ML.IsHandled = function(self) return true end

			--- @type  Models.List.ActiveConfiguration
			local ac = S:Activate("614A4F87-AF52-34B4-E983-B9E8929D44AF")

			local allPlayers = {}
			for _, list in pairs(StubModule.db.factionrealm.lists) do
				Util.Tables.CopyInto(allPlayers, list.players)
			end

			allPlayers = Util.Tables.Unique(allPlayers)
			Util.Tables.Shuffle(allPlayers)
			ac:OnPlayerEvent("Player-1-00000031", true)

			for _, p in pairs(allPlayers) do
				ac:OnPlayerEvent(p, true)
			end

			local list, players
			for listId, origList in pairs(StubModule.db.factionrealm.lists) do
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

			finally(function()
				AddOn.IsMasterLooter = _IsMasterLooter
				ML._IsHandled = _IsHandled
			end)
		end)

		it("handles loot event", function()
			--- @type  Models.List.ActiveConfiguration
			local ac = S:Activate("614A4F87-AF52-34B4-E983-B9E8929D44AF")

			--- @type Lists
			local L = AddOn:ListsModule()
			L:SetService(S, ac)

			local ML = AddOn:MasterLooterModule()
			local _IsMasterLooter = AddOn.IsMasterLooter
			local _IsHandled = ML.IsHandled
			AddOn.IsMasterLooter = function(self) return true end
			ML.IsHandled = function(self) return true end

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

			finally(function()
				L:InitializeService()
				AddOn.IsMasterLooter = _IsMasterLooter
				ML._IsHandled = _IsHandled
			end)
		end)

		it("handles player left event", function()
			--- @type  Models.List.ActiveConfiguration
			local ac = S:Activate("614A4F87-AF52-34B4-E983-B9E8929D44AF")

			--- @type Lists
			local L = AddOn:ListsModule()
			L:SetService(S, ac)

			local ML = AddOn:MasterLooterModule()
			local _IsMasterLooter = AddOn.IsMasterLooter
			local _IsHandled = ML.IsHandled
			AddOn.IsMasterLooter = function(self) return true end
			ML.IsHandled = function(self) return true end

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

			finally(function()
				L:InitializeService()
				AddOn.IsMasterLooter = _IsMasterLooter
				ML._IsHandled = _IsHandled
			end)
		end)
	end)
end)