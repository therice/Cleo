
local AddOnName, AddOn, Util, C
--- @type Models.List.Configuration
local Configuration
--- @type Models.List.List
local List

describe("Lists", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_Lists')
		AddOnLoaded(AddOnName, true)
		Util, C = AddOn:GetLibrary('Util'), AddOn.Constants
		Configuration, List = AddOn.Package('Models.List').Configuration, AddOn.Package('Models.List').List
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		it("is disabled on startup", function()
			local module = AddOn:ListsModule()
			assert(module)
			assert(module:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("Lists")
			local module = AddOn:ListsModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("Lists")
			local module = AddOn:ListsModule()
			assert(module)
			assert(module:IsEnabled())
		end)
	end)

	describe("functional", function()
		--- @type Lists
		local lists

		setup(function()
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
								["615247A9-311F-57E4-0503-CC3F53E61597"] = {
									["configId"] = "614A4F87-AF52-34B4-E983-B9E8929D44AF",
									["players"] = {
									},
									["name"] = "Chest, Shoulders, and Legs",
									["equipment"] = {
										"INVTYPE_CHEST", -- [1]
										"INVTYPE_SHOULDER", -- [2]
										"INVTYPE_LEGS", -- [3]
									},
								},
								["61534E26-36A0-4F24-51D7-BE511B88B834"] = {
									["configId"] = "614A4F87-AF52-34B4-E983-B9E8929D44AF",
									["equipment"] = {
										"INVTYPE_HEAD", -- [1]
									},
									["name"] = "Head, Feet, Wrist",
									["players"] = {
									},
								},
							},
						}
					}
			)
			lists = AddOn:ListsModule()
			lists.db = db
			lists:InitializeService()
		end)

		teardown(function()
			lists = nil
		end)

		it("provides configurations", function()
			local configs = lists:GetService():Configurations()
			assert(configs)
			assert.equal(1, Util.Tables.Count(configs))
			local config = Util.Tables.Values(configs)[1]
			assert(config)
			assert.equal("Tempest Keep", config.name)
			assert.equal("Player-4372-01FC8D1A", config:GetOwner().guid)
			local admins = config:GetAdministrators()
			assert.equal(2, #admins)
			assert.equal("Player-4372-01D08047", admins[1].guid)
			assert.equal("Player-4372-011C6125", admins[2].guid)
		end)

		it("provides lists", function()
			local ls = lists:GetService():Lists("614A4F87-AF52-34B4-E983-B9E8929D44AF")
			assert(ls)
			assert.equal(2, Util.Tables.Count(ls))
			local l = Util.Tables.Values(ls)[1]
			assert(l)
			assert.equal("Chest, Shoulders, and Legs", l.name)
			local e = l:GetEquipment()
			assert.equal(3, Util.Tables.Count(e))
			assert.equal("INVTYPE_CHEST", e[1])
			assert.equal("INVTYPE_SHOULDER", e[2])
			assert.equal("INVTYPE_LEGS", e[3])

			l = Util.Tables.Values(ls)[2]
			assert(l)
			assert.equal("Head, Feet, Wrist", l.name)
			e = l:GetEquipment()
			assert.equal(1, Util.Tables.Count(e))
			assert.equal("INVTYPE_HEAD", e[1])
		end)
		it("provides unassigned equipment", function()
			local ua = lists:GetService():UnassignedEquipmentLocations("614A4F87-AF52-34B4-E983-B9E8929D44AF")
			assert.same(
				{"INVTYPE_SHIELD", "INVTYPE_WEAPONOFFHAND", "INVTYPE_RANGED", "INVTYPE_WEAPON", "INVTYPE_2HWEAPON", "INVTYPE_WRIST", "INVTYPE_TRINKET", "INVTYPE_NECK", "INVTYPE_WAND", "INVTYPE_CLOAK", "INVTYPE_FEET", "INVTYPE_RELIC", "INVTYPE_THROWN", "INVTYPE_FINGER", "INVTYPE_HOLDABLE", "INVTYPE_HAND", "INVTYPE_WAIST", "INVTYPE_WEAPONMAINHAND"},
				ua
			)
		end)
		it("handles dao events", function()
			--- @type Models.Audit.TrafficRecord
			local TrafficRecord = AddOn.Package('Models.Audit').TrafficRecord
			local S = lists:GetService()
			--- @type Models.List.Configuration
			local C = Configuration.CreateInstance()
			--- @type Models.List.List
			local L = List.CreateInstance(C.id)

			local records = {
				[TrafficRecord.ResourceType.Configuration] = {
					[TrafficRecord.ActionType.Create] = 0,
					[TrafficRecord.ActionType.Delete] = 0,
					[TrafficRecord.ActionType.Modify] = {

					},
				},
				[TrafficRecord.ResourceType.List] = {
					[TrafficRecord.ActionType.Create] = 0,
					[TrafficRecord.ActionType.Delete] = 0,
					[TrafficRecord.ActionType.Modify] = {

					},
				},
			}

			--- @param record  Models.Audit.TrafficRecord
			local function IncrementAuditCount(record)
				local resourceType = record:GetResourceType()

				if record.action == TrafficRecord.ActionType.Modify then
					local attr = record:GetModifiedAttribute()
					if not records[resourceType][record.action][attr] then
						records[resourceType][record.action][attr] = 0
					end

					records[resourceType][record.action][attr] =
						records[resourceType][record.action][attr] + 1
				else
					records[resourceType][record.action] =
						records[resourceType][record.action] + 1
				end
			end

			local LA = AddOn:TrafficAuditModule()
			local _Broadcast = LA.Broadcast
			LA.Broadcast = function(self, record)
				IncrementAuditCount(record)
			end

			S.Configuration:Add(C)
			C.name = "An Updated Name"
			C:RevokePermissions("Player1", Configuration.Permissions.Owner)
			C:GrantPermissions("Player1", Configuration.Permissions.Admin)
			C:GrantPermissions("Player2", Configuration.Permissions.Owner)
			S.Configuration:Update(C, 'name')
			S.Configuration:Update(C, 'permissions')
			lists:_ProcessEvents(lists:GetConfigurationEvents())

			L:AddPlayer("Player1")
			L:AddPlayer("Player2")
			L:AddPlayer("Player3")
			S.List:Add(L)
			L:AddEquipment("INVTYPE_WEAPON", "INVTYPE_2HWEAPON")
			S.List:Update(L, 'equipment')
			L:DropPlayer("Player2")
			S.List:Update(L, 'players')
			lists:_ProcessEvents(lists:GetListEvents())

			S.List:Remove(L)
			S.Configuration:Remove(C)

			LA.Broadcast = _Broadcast

			assert.equal(1, records[TrafficRecord.ResourceType.Configuration][TrafficRecord.ActionType.Create])
			assert.equal(0, records[TrafficRecord.ResourceType.Configuration][TrafficRecord.ActionType.Delete])
			assert.equal(1, records[TrafficRecord.ResourceType.Configuration][TrafficRecord.ActionType.Modify]['name'])
			assert.equal(1, records[TrafficRecord.ResourceType.Configuration][TrafficRecord.ActionType.Modify]['permissions'])

			assert.equal(1, records[TrafficRecord.ResourceType.List][TrafficRecord.ActionType.Create])
			assert.equal(0, records[TrafficRecord.ResourceType.List][TrafficRecord.ActionType.Delete])
			assert.equal(1, records[TrafficRecord.ResourceType.List][TrafficRecord.ActionType.Modify]['equipment'])
			assert.equal(1, records[TrafficRecord.ResourceType.List][TrafficRecord.ActionType.Modify]['players'])
		end)
	end)
end)