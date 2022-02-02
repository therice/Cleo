-- @type AddOn
local AddOn
local AddOnName
local C
--- @type LibUtil
local Util
--- @type Models.Replication.Replicate
local Replicate
--- @type Models.List.Service
local Service
--- @type Models.Player
local Player

describe("Replication", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_Replication')
		loadfile('Models/Replication/Test/EngineIntegrationTestData.lua')()
		Util, Replicate = AddOn:GetLibrary('Util'), AddOn.Require('Models.Replication.Replicate')
		Service = AddOn.Package('Models.List').Service
		Player = AddOn.Package('Models').Player
		C = AddOn.Constants
	end)

	teardown(function()
		After()
		AddOn.player = nil
	end)

	describe("Engine", function()
		function newdb(player)
			return NewAceDb(TestData[player])
		end

		--- @type table<string, Models.Player>
		local players = {}
		--- @type table<string, Models.Replication.Engine>
		local engines = {}

		local function CreateStub(player)
			print(format("CreateEngine(%s)", tostring(player)))
			local StubModule = AddOn:NewModule('Stub_' .. player)
			function StubModule:OnEnable() self.db = newdb(player) end
			function StubModule:OnDisable() self.db = nil end
			return StubModule
		end

		local function CreateEngine(player)
			print(format("CreateEngine(%s)", tostring(player)))
			local stub = CreateStub(player.name)
			stub:OnEnable()

			local service = Service(
				{stub, stub.db.factionrealm.configurations},
				{stub, stub.db.factionrealm.lists}
			)
			local engine = Replicate.Engine(player)
			engine.stubModule = stub

			local _SubscribeToComms, _Send = engine.SubscribeToComms, nil
			engine.SubscribeToComms = function(self, ...)
				_SubscribeToComms(self, ...)
				_Send = self.Send
				self.Send = function(module, target, command, ...)
					print(format("%s / %s / %s => %s",tostring(module),tostring(target),tostring(command),Util.Objects.ToString({...})))
					_Send(module, target, command, ...)

					local function shouldSend(to)
						--return true

						--print(format('shouldSend(%s, %s) : %s', tostring(to), tostring(self.member.name), tostring(target)))
						-- everyone in the test is  in our group, guild, and part
						if Util.Objects.In(Util.Strings.Lower(target), C.group, C.guild, C.party) then
							return true
						-- otherwise, only if the target is same as 'to'
						else
							return Util.Strings.Equal(target, to)
						end
					end

					local data = { ... }
					for _, e in pairs(engines) do
						--[[
						if command == "rer" then
							print(
								format(
									"/ rer to=%s, from=%s, engine=%s, shouldSend=%s",
									tostring(target), tostring(self.member.name), tostring(e.member.name), tostring(shouldSend(e.member.name))
								)
							)
						end
						--]]
						if e:IsInitialized() and shouldSend(e.member.name) then
							e.comms.private:FireCommand(
								C.CommPrefixes.Replication,
								target,
								self.member.name,
								command,
								data
							)
						end
					end
				end
			end

			engine.EntityProvider = function(self)
				return service
			end

			return engine
		end

		local function LeaderCallback(pname, delegate)
			return function(replica, leader)
				print(format("LeaderCallback(%s) : %s (%s)", tostring(pname), tostring(replica), tostring(leader)))
				if delegate then
					delegate(replica, leader)
				end
			end
		end

		local function CreateEngines()
			for pname, player in pairs(players) do
				engines[pname] = CreateEngine(player)
			end
		end

		setup(function()
			AddOnLoaded(AddOnName, true)
			GuildRoster()

			local player
			for _, p in pairs({'Gnomechómsky', 'Eliovak', 'Player3'}) do
				player = Player:Get(p)
				players[player:GetName()] = player
			end
		end)

		before_each(function()
			CreateEngines()
		end)

		after_each(function()
			for _, engine in pairs(engines) do
				engine.stubModule:OnDisable()
			end
		end)


		it("does the needful", Async(
			function(as)

				local leadershipChanges = {}

				local function cbtracker(replica, leader)
					if leader == nil then
						leader = "LOST"
					end

					local ls = leadershipChanges[replica]
					if not ls then
						ls = {}
						leadershipChanges[replica] = ls
					end

					local l = ls[leader]
					if not l then
						l = 0
					end

					ls[leader] = l + 1
				end

				for pname, engine in pairs(engines) do
					engine:Initialize(AddOn.Require('Core.Comm'), LeaderCallback(pname, cbtracker))
				end

				while not as.finished() do
					as.sleep(1)
				end

				for _, engine in pairs(engines) do
					assert.equal(Util.Tables.Count(engine.peers), 2)
					for _, r in pairs(engine.replicas) do
						--print(format("%s => %s", tostring(r), tostring(r.leader)))
						if Util.Strings.Equal(r.id, "Configuration:614A4F87-AF52-34B4-E983-B9E8929D44AF") then
							assert.equal(r.leader.id, "Gnomechómsky-Atiesh")
						elseif Util.Strings.Equal(r.id, "List:6154C617-5A91-7304-3DAD-EBE283795429") then
							assert.equal(r.leader.id, "Player3-Realm2")
						elseif Util.Strings.Equal(r.id, "List:61534E26-36A0-4F24-51D7-BE511B88B834") then
							assert.equal(r.leader.id, "Eliovak-Atiesh")
						end
					end
				end

				engines['Player3-Realm2']:Shutdown()
				engines['Player3-Realm2'] = nil

				--for _, engine in pairs(engines) do
				--	if engine:IsInitialized() then
				--		engine:OnPeerStatusChanged("Player3-Realm2", false)
				--	end
				--end

				while not as.finished() do
					as.sleep(1)
				end

				for _, engine in pairs(engines) do
					assert.equal(Util.Tables.Count(engine.peers), 1)
					for _, r in pairs(engine.replicas) do
						--print(format("%s => %s", tostring(r), tostring(r.leader)))
						if Util.Strings.Equal(r.id, "Configuration:614A4F87-AF52-34B4-E983-B9E8929D44AF") then
							assert.equal(r.leader.id, "Gnomechómsky-Atiesh")
						elseif Util.Strings.Equal(r.id, "List:6154C617-5A91-7304-3DAD-EBE283795429") then
							assert.equal(r.leader.id, "Gnomechómsky-Atiesh")
						elseif Util.Strings.Equal(r.id, "List:61534E26-36A0-4F24-51D7-BE511B88B834") then
							assert.equal(r.leader.id, "Eliovak-Atiesh")
						end
					end
				end

				print(Util.Objects.ToString(leadershipChanges))

				local lc = leadershipChanges['Configuration:614A4F87-AF52-34B4-E983-B9E8929D44AF']
				assert(Util.Tables.Count(lc), 1)
				assert(Util.Tables.ContainsKey(lc, 'Gnomechómsky-Atiesh'))

				lc = leadershipChanges['List:6154C617-5A91-7304-3DAD-EBE283795429']
				assert(Util.Tables.Count(lc), 3)
				assert(Util.Tables.ContainsKey(lc, 'LOST'))
				assert(Util.Tables.ContainsKey(lc, 'Player3-Realm2'))
				assert(Util.Tables.ContainsKey(lc, 'Gnomechómsky-Atiesh'))

				lc = leadershipChanges['List:61534E26-36A0-4F24-51D7-BE511B88B834']
				assert(Util.Tables.Count(lc), 1)
				assert(Util.Tables.ContainsKey(lc, 'Eliovak-Atiesh'))
			end
		))
	end)
end )