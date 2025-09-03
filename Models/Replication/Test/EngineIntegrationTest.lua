--- @type AddOn
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

describe("Replication #travisignore", function()
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
		--- @type ListsDataPlane
		local listsDp
		--- @type Lists
		local lists

		local function CreateStub(player)
			print(format("CreateEngine(%s)", tostring(player)))
			local StubModule = AddOn:NewModule('Stub_' .. player)
			function StubModule:OnEnable()
				AddOn.mode.Disable(C.Modes.Develop)
				self.db = newdb(player)
			end
			function StubModule:OnDisable()
				self.db = nil
			end
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
						--if command == "rpu" then
						--	print(
						--		format(
						--			"/ %s to=%s, from=%s, engine=%s, shouldSend=%s",
						--			tostring(command), tostring(target), tostring(self.member.name), tostring(e.member.name), tostring(shouldSend(e.member.name))
						--		)
						--	)
						--end
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

			-- override call to Configurations to only return active ones (as it could be modified by various addon modes, e.g. develop)
			local _configurations = service.Configurations
			service.Configurations = function(self, _, default)
				return _configurations(self, true, default)
			end

			engine.EntityProvider = function(self)
				return service
			end

			return engine
		end

		local function LeaderCallback(pname, dp, delegate)
			return function(replica)
				print(format("LeaderCallback(%s) : %s (%s)", tostring(pname), tostring(replica), tostring(replica.leader)))
				if delegate then
					delegate(replica)
				end

				if dp then
					dp:OnReplicaLeaderChanged(replica)
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
			listsDp = AddOn:ListsDataPlaneModule()
			lists = AddOn:ListsModule()
		end)

		after_each(function()
			for _, engine in pairs(engines) do
				engine.stubModule:OnDisable()
			end
		end)


		it("does the needful", async(
			function(as)

				local leadershipChanges = {}
				local function cbtracker(replica)
					local id, leader = replica.id, replica.leader
					if leader == nil then
						leader = "LOST"
					else
						leader = leader.id
					end

					local ls = leadershipChanges[id]
					if not ls then
						ls = {}
						leadershipChanges[id] = ls
					end


					local l = ls[leader]
					if not l then
						l = 0
					end

					ls[leader] = l + 1
				end

				for pname, engine in pairs(engines) do
					engine:Initialize(AddOn.NewComms(), LeaderCallback(pname, listsDp, cbtracker))
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
				assert.Is.Not.Nil(lc)
				assert(Util.Tables.Count(lc), 1)
				assert(Util.Tables.ContainsKey(lc, 'Gnomechómsky-Atiesh'))


				lc = leadershipChanges['List:6154C617-5A91-7304-3DAD-EBE283795429']
				assert.Is.Not.Nil(lc)
				assert(Util.Tables.Count(lc), 3)
				assert(Util.Tables.ContainsKey(lc, 'LOST'))
				assert(Util.Tables.ContainsKey(lc, 'Player3-Realm2'))
				assert(Util.Tables.ContainsKey(lc, 'Gnomechómsky-Atiesh'))

				lc = leadershipChanges['List:61534E26-36A0-4F24-51D7-BE511B88B834']
				assert.Is.Not.Nil(lc)
				assert(Util.Tables.Count(lc), 1)
				assert(Util.Tables.ContainsKey(lc, 'Eliovak-Atiesh'))

				-- up to this point the data plane is not handling data replication due to
				-- messages not being sent and consumed

				-- this is hokey as hell, but trying to emulate multiple players having addon loaded
				-- in separate games within same process
				listsDp.Send = function(_, to, cmd, data)
					print(format("ListDataPlane.Send() : %s, %s, %s",  tostring(to), tostring(cmd), Util.Objects.ToString(data)))

					local sender
					if Util.Objects.Equals(to, "Eliovak-Atiesh") then
						sender = "Gnomechómsky-Atiesh"
					else
						sender = "Eliovak-Atiesh"
					end

					local originalService, replacementService =  lists:GetService(), engines[to]:EntityProvider()

					Util.Functions.try(
						function()
							lists.listsService = replacementService

							if Util.Objects.Equals(cmd, C.Commands.ConfigResourceRequest) then
								listsDp:OnResourceRequest(sender, data:toTable())
							elseif Util.Objects.Equals(cmd, C.Commands.ConfigResourceResponse) then
								listsDp:OnResourceResponse(sender, data:toTable())
							end
						end
					).finally(
						function()
							lists.listsService = originalService
						end
					)
				end

				-- perform an update on an entity, resulting in an update to peers and new election
				local entityProvider = engines['Eliovak-Atiesh']:EntityProvider()
				local config = entityProvider.Configuration:Get("614A4F87-AF52-34B4-E983-B9E8929D44AF")
				config.name = "Engine Integration Configuration (Modified)"
				entityProvider.Configuration:Update(config, "name")

				while not as.finished() do
					as.sleep(1)
				end

				for _, engine in pairs(engines) do
					for _, r in pairs(engine.replicas) do
						--print(format("%s => %s", tostring(r), tostring(r.leader)))
						if Util.Strings.Equal(r.id, "Configuration:614A4F87-AF52-34B4-E983-B9E8929D44AF") then
							assert.equal(r.leader.id, "Eliovak-Atiesh")
						elseif Util.Strings.Equal(r.id, "List:6154C617-5A91-7304-3DAD-EBE283795429") then
							assert.equal(r.leader.id, "Gnomechómsky-Atiesh")
						elseif Util.Strings.Equal(r.id, "List:61534E26-36A0-4F24-51D7-BE511B88B834") then
							assert.equal(r.leader.id, "Eliovak-Atiesh")
						end
					end
				end

				local leaderEngine, followerEngine =
					engines["Eliovak-Atiesh"], engines["Gnomechómsky-Atiesh"]
				local leaderReplica, followerReplica =
					leaderEngine.replicas["Configuration:614A4F87-AF52-34B4-E983-B9E8929D44AF"],
					followerEngine.replicas["Configuration:614A4F87-AF52-34B4-E983-B9E8929D44AF"]
				local leaderTerm, _ = leaderReplica:LocalMember():Term()
				local followerTerm, _ = followerReplica:LocalMember():Term()
				assert.equal(leaderTerm, followerTerm)
			end
		))
	end)
end )