local AddOnName, AddOn
--- @type LibUtil
local Util
--- @type Models.Replication.Replicate
local Replicate
--- @type Models.Player
local Player


describe("Replication", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_Replication')
		Util, Replicate = AddOn:GetLibrary('Util'), AddOn.Require('Models.Replication.Replicate')
		Player = AddOn.Package('Models').Player
		AddOn.player = Player:Get("Player1")
	end)

	teardown(function()
		After()
		AddOn.player = nil
	end)

	describe("Member", function()
		it("created for player (noop term)", function()
			local member = Replicate.Member(AddOn.player.name, true, Util.Functions.Noop)
			assert.equal(AddOn.player.name, member.id)
			assert.same({0, 0}, {member:Term()})
		end)
		it("created for player (function term)", function()
			local function Term()
				return { revision = 1 }, 50
			end
			local member = Replicate.Member(AddOn.player.name, true, Term)
			assert.equal(AddOn.player.name, member.id)
			assert.same({1, 50}, {member:Term()})
		end)
		it("created for player (table term)", function()
			local member = Replicate.Member(AddOn.player.name, true, {2, 100})
			assert.equal(AddOn.player.name, member.id)
			assert.same({2, 100}, {member:Term()})
		end)
		it("has priority (revision only)", function()
			local m1 = Replicate.Member(AddOn.player.name, true, {3, 100})
			local m2 = Replicate.Member(Player:Get("Player2").name, false, {2, 100})
			assert(m1:HasPriority(m2))
			assert(not m2:HasPriority(m1))
		end)
		it("has priority (authz tie breaker)", function()
			local m1 = Replicate.Member(AddOn.player.name, true, {2, 100})
			local m2 = Replicate.Member(Player:Get("Player2").name, false, {2, 10})
			assert(m1:HasPriority(m2))
			assert(not m2:HasPriority(m1))
		end)
		it("has priority (id tie breaker)", function()
			local m1 = Replicate.Member(AddOn.player.name, true, {2, 100})
			local m2 = Replicate.Member(Player:Get("Player2").name, false, {2, 100})
			assert(m1:HasPriority(m2))
			assert(not m2:HasPriority(m1))
		end)
	end)

	describe("Replica", function()

		local function sender()
			return Util.Functions.Noop
		end

		it("created", function()
			local group = Replicate.Replica("Configuration:61534E26-36A0-4F24-51D7-BE511B88B834", sender)
			assert.equal(group.id, "Configuration:61534E26-36A0-4F24-51D7-BE511B88B834")
		end)

		it("add/get/remove member", function()
			local replica = Replicate.Replica("Configuration:61534E26-36A0-4F24-51D7-BE511B88B834", sender)
			local m1 = Replicate.Member(AddOn.player.name, true, Util.Functions.Noop)
			replica:AddMember(m1)
			local m2 = replica:GetMember(m1)
			assert(m1 == m2)
			replica:RemoveMember(m2.id)
			assert.Nil(replica:GetMember(m1.id))
		end)
		it("provides local members", function()
			local group = Replicate.Replica("Configuration:61534E26-36A0-4F24-51D7-BE511B88B834", sender)
			local m1 = Replicate.Member(AddOn.player.name, true, {3, 100})
			group:AddMember(m1)
			assert(group:LocalMember() == m1)
		end)
		it("provides higher term members", function()
			local replica = Replicate.Replica("Configuration:61534E26-36A0-4F24-51D7-BE511B88B834", sender)
			local m1, m2, m3 =
				Replicate.Member(AddOn.player.name, true, {3, 100}),
				Replicate.Member(Player:Get("Player2").name, false, {2, 100}),
				Replicate.Member(Player:Get("Player3").name, false, {1, 100})

			replica:AddMember(m1)
			replica:AddMember(m2)
			replica:AddMember(m3)

			local ms = replica:HigherTermMembers()
			assert.same({}, ms)

			replica:RemoveMember(m2)
			replica:RemoveMember(m3)
			m2 = Replicate.Member(Player:Get("Player2").name, false, {5, 100})
			replica:AddMember(m2)
			ms = replica:HigherTermMembers()
			assert(#ms == 1)
			assert(ms[1] == m2)
			m3 = Replicate.Member(Player:Get("Player3").name, false, {5, 100})
			replica:AddMember(m3)
			ms = replica:HigherTermMembers()
			assert(#ms == 2)
			assert(Util.Tables.ContainsValue(ms, m2))
			assert(Util.Tables.ContainsValue(ms, m3))
		end)

		it("provides other members", function()
			local replica = Replicate.Replica("Configuration:61534E26-36A0-4F24-51D7-BE511B88B834", sender)
			local m1, m2, m3 =
				Replicate.Member(AddOn.player.name, true, {3, 100}),
				Replicate.Member(Player:Get("Player2").name, false, {2, 100}),
				Replicate.Member(Player:Get("Player3").name, false, {1, 100})

			replica:AddMember(m1)
			replica:AddMember(m2)
			replica:AddMember(m3)
			local ms = replica:OtherMembers()
			assert(#ms == 2)
			assert(Util.Tables.ContainsValue(ms, m2))
			assert(Util.Tables.ContainsValue(ms, m3))
		end)
	end)
end)