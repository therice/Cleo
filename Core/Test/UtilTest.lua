local AddOnName
--- @type AddOn
local AddOn
--- @type LibUtil
local Util

describe("Util", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Core_Util')
        Util = AddOn:GetLibrary('Util')
        AddOnLoaded(AddOnName, false)
    end)
    teardown(function()
        After()
    end)

    describe("functions", function()
        it("Qualify", function()
            assert(AddOn:Qualify("Test") == format("%s_%s", AddOn.Constants.name, "Test"))
            assert(AddOn:Qualify("Test", "Another") == format("%s_%s_%s", AddOn.Constants.name, "Test", "Another"))
        end)
        it("UnitName", function()
            assert(AddOn:UnitName('foo-realm') == 'Foo-realm')
            assert(AddOn:UnitName('player') == 'Player1-Realm1')
            assert(AddOn:UnitName('Fluffy') == 'Fluffy-Realm1')
            assert(not AddOn:UnitName())
        end)
        it("UnitIsUnit", function()
            assert(not AddOn.UnitIsUnit(nil, nil))
            assert(not AddOn.UnitIsUnit('foo', nil))
            assert(not AddOn.UnitIsUnit(nil, 'bar'))

            assert(not AddOn.UnitIsUnit({name = nil}, {name = nil}))
            assert(not AddOn.UnitIsUnit(nil, {name = 'bar'}))
            assert(not AddOn.UnitIsUnit({name = 'foo'}, nil))

            assert(AddOn.UnitIsUnit('player', 'player') == 1)
            assert(AddOn.UnitIsUnit('Player', 'plaYer') == 1)
            assert(AddOn.UnitIsUnit('Player1-Realm1', 'Player1') == 1)
            assert(AddOn.UnitIsUnit('Player1-Realm1', 'Player1-Realm1') == 1)
            assert(AddOn.UnitIsUnit('Player1-Realm1', 'Player1') == 1)
        end)
        it("UnitClass", function()
            assert(AddOn:UnitClass("player") == 'WARRIOR')
            assert(AddOn:UnitClass("Eliovak") == 'ROGUE')
            assert(AddOn:UnitClass("Gnomechómsky-Atiesh") == 'WARLOCK')
            assert(AddOn:UnitClass("Fluffybunny") == 'HUNTER')
            assert(AddOn:UnitClass("noguid") == 'WARRIOR')
        end)
        it("GetPlayerInfo", function()
            local enchanter, enchantLvl, avgItemLevel = AddOn:GetPlayerInfo()
            assert.equal(enchanter, true)
            assert.equal(enchantLvl, 298)
            -- see GetAverageItemLevel in WowApi.lua
            assert(avgItemLevel < 401)
            assert(avgItemLevel > 100)
        end)
        it("UpdatePlayerData", function()
            AddOn:UpdatePlayerData()
            -- see GetAverageItemLevel in WowApi.lua
            assert(AddOn.playerData.ilvl < 401)
            assert(AddOn.playerData.ilvl > 100)
            assert(#AddOn.playerData.gear > 0) -- see GetItemInfo in WowItemInfo.lua
        end)
    end)

    describe("Alarm", function()
        local invoked, tick, interval, alarm = 0, 0, 1.5, nil

        local function Elapsed()
            return (os.time() - tick)
        end

        local function AlarmFn(viaAlarm)
            local elapsed = Elapsed()

            assert(Util.Objects.Default(viaAlarm, false))

            invoked = invoked + 1
            if elapsed >= 4.0 then
                alarm:Disable()
            end
        end

        it("functions", async(function(as)
            alarm = AddOn.Alarm(interval, function() AlarmFn(true) end)
            tick = os.time()
            alarm:Enable()

            while not as.finished() do
                as.sleep(1)
            end

            assert.is.near(invoked, 3, 1)
        end))
    end)

    describe("Stopwatch", function()
        local sw = AddOn.Stopwatch()

        it("functions", function()
            sw:Start()
            sleep(0.5)
            sw:Stop()
            --print(tostring(sw))
            assert.is.near(sw:Elapsed(), 500.0, 0.10)
            sw:Restart()
            sleep(0.2)
            sw:Stop()
            --print(tostring(sw))
            assert.is.near(sw:Elapsed(), 200.0, 0.10)
        end)
    end)
end)