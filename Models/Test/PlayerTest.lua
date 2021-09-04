local AddOnName, AddOn, Player, Util

describe("Player", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_Player')
        Player, Util = AddOn.Package('Models').Player, AddOn:GetLibrary('Util')
    end)

    teardown(function()
        After()
        Player.ReinitializeCache()
    end)

    describe("cache", function()
        teardown(function()
            Player.ReinitializeCache()
        end)
        it("is initialized(empty)", function()
            assert(not Player.GetCache())
        end)
        it("is initialized(db)", function()
            AddOn.db.global.cache.player = {
                ['Player-4372-00C1D806'] = {
                    guid = 'Player-4372-00C1D806',
                    name = 'Gnome-Atiesh',
                    class = 'WARLOCK',
                    realm = 'Atiesh',
                    timestamp = -1,
                },
            }
            Player.ReinitializeCache()
            assert.are.same(
                Player.GetCache(),
                AddOn.db.global.cache.player
            )
        end)
    end)

    describe("functional", function()
        before_each(function()
            AddOn.db.global.cache = {}
            Player.ReinitializeCache()
        end)
        it("Get", function()
            local p = Player:Get('Player2')
            assert.are.equal("Player2-Realm1", p:GetName())
            assert.are.equal("Player2", p:GetShortName())
            assert.are.equal("WARRIOR", p.class)
            assert.are.equal("Realm1", p.realm)
            assert.are.equal("Player-1-00000002", p.guid)
            assert.are.equal("WARRIOR", select(2, p:GetInfo()))
            assert.are.equal("1-00000002", p:ForTransmit())
        end)
        it("Get with invalid arguments", function()
            assert.has.errors(function() Player:Get() end, "nil is an invalid player")
            assert.has.errors(function() Player:Get(1) end, "1 is an invalid player")
        end)
        it("is printable", function()
            assert.are.equal(tostring(Player:Get('Player1')), 'Player1-Realm1 (Player-1-00000001)')
        end)
        it("is comparable", function()
            local p1 = Player:Get('Player1')
            local p2 = Player:Get('Player2')
            assert.are.equal(p1, p1)
            assert.are.equal(p2, p2)
            assert.are_not.equal(p1, p2)
        end)
        it("is cached", function()
            local p1 = Player:Get('Player1')
            local p2 = Player:Get('Player1')
            assert(p2.timestamp ~= nil and p2.timestamp > 0)
            assert.are.equal(p1, p2)
        end)
        it("fetches player from GUID (full)", function()
            local p = Player:Get('Player-1122-00000003')
            assert.are.equal('Player3-Realm2',p:GetName())
        end)
        it("fetches player from GUID (stripped)", function()
            local p = Player:Get('1-00000002')
            assert.are.equal('Player2-Realm1',p:GetName())
        end)
    end)
end)