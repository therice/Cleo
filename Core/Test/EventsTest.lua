local AddOnName, AddOn, Util, Player

describe("Events", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Core_Events')
		Util, Player = AddOn:GetLibrary('Util'), AddOn.Package('Models').Player
		AddOnLoaded(AddOnName, true)
		SetTime()
	end)
	teardown(function()
		print(Util.Objects.ToString( AddOn.Require('Core.Event').private.metricsRcv:Summarize()))
		print(Util.Objects.ToString( AddOn.Require('Core.Comm').private.metricsSend:Summarize()))
		print(Util.Objects.ToString( AddOn.Require('Core.Comm').private.metricsRecv:Summarize()))
		print(Util.Objects.ToString( AddOn.Require('Core.Comm').private.metricsFired:Summarize()))
		After()
	end)

	describe("basics", function()
		before_each(function()
			_G.IsInRaidVal = true
			_G.UnitIsGroupLeaderVal = true
			AddOn.player = Player:Get("Player1")
			PlayerEnteredWorld()
			AddOn:MasterLooterModule().db = NewAceDb({ profile = { usage = { state = 1, whenLeader = true } } })
			GuildRosterUpdate()
		end)
		teardown(function()
			AddOn.player = nil
			AddOn:MasterLooterModule().db = nil
		end)
		it("PLAYER_ENTERING_WORLD", function()
			AddOn.player = Player:Get('Player2-Realm1')
			PlayerEnteredWorld()
			assert(not AddOn:IsMasterLooter())
			assert(#AddOn.playerData.gear > 0)
			assert(AddOn.playerData.ilvl >= 0)
		end)
		it("GROUP_LEFT", function()
			WoWAPI_FireEvent("GROUP_LEFT")
			assert(AddOn:IsMasterLooter())
		end)
		it("PARTY_LEADER_CHANGED", function()
			WoWAPI_FireEvent("PARTY_LEADER_CHANGED")
			assert(AddOn:IsMasterLooter())
		end)
		it("PARTY_LOOT_METHOD_CHANGED", function()
			WoWAPI_FireEvent("PARTY_LOOT_METHOD_CHANGED")
			assert(AddOn:IsMasterLooter())
		end)
		it("RAID_INSTANCE_WELCOME", function()
			AddOn.masterLooter = nil
			assert(not AddOn:IsMasterLooter())
			WoWAPI_FireEvent("RAID_INSTANCE_WELCOME")
			assert(AddOn:IsMasterLooter())
			assert(AddOn.handleLoot)
		end)
		it("ENCOUNTER_START", function()
			WoWAPI_FireEvent("ENCOUNTER_START", 100, "AnEncounter", 1, 40)
			assert(AddOn.encounter)
			assert.equal(AddOn.encounter.id, 100)
			assert.equal(AddOn.encounter:IsSuccess():isEmpty(), true)
		end)
		it("ENCOUNTER_END", function()
			WoWAPI_FireEvent("ENCOUNTER_END", 200, "AnEncounter", 1, 40, 0)
			assert(AddOn.encounter)
			assert.equal(AddOn.encounter.id, 100)
			assert.equal(AddOn.encounter:IsSuccess():get(), false)

			-- flip tp false to not fire the EP portions
			AddOn.handleLoot = false
			WoWAPI_FireEvent("ENCOUNTER_END", 716, "encounterName", 1, 40, 1)
			assert(AddOn.encounter)
			assert.equal(AddOn.encounter.id, 716)
			assert.equal(AddOn.encounter:IsSuccess():get(), true)

			AddOn.encounter = nil
			WoWAPI_FireEvent("ENCOUNTER_END", 999, "encounterName2", 1, 40, 0)
			assert(AddOn.encounter)
			assert.equal(AddOn.encounter.id, 999)
			assert.equal(AddOn.encounter:IsSuccess():get(), false)

			AddOn.handleLoot = true
		end)
		it("PLAYER_REGEN_DISABLED", function()
			WoWAPI_FireEvent("PLAYER_REGEN_DISABLED")
		end)
		it("PLAYER_REGEN_ENABLED", function()
			WoWAPI_FireEvent("PLAYER_REGEN_ENABLED")
		end)
	end)
end)