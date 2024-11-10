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
        SetTime()
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
        it("IsItemGUID", function()
            assert(AddOn:IsItemGUID("Item-4372-0-400000033D4D1C15"))
            assert(not AddOn:IsItemGUID("Creature-0-1465-0-2105-448-000043F59F"))
            assert(not AddOn:IsItemGUID("Player-4372-0232E2F9"))
        end)
        it("IsCreatureGUID", function()
            assert(AddOn:IsCreatureGUID("Creature-0-1465-0-2105-448-000043F59F"))
            assert(AddOn:IsCreatureGUID("Vehicle-0-4378-720-7697-53134-00002EBC6A"))
            assert(AddOn:IsCreatureGUID("GameObject-0-4378-720-7697-53134-00002EBC6A"))
            assert(AddOn:IsCreatureGUID("Pet-0-4234-0-6610-165189-0202F859E9"))
            assert(not AddOn:IsCreatureGUID("Item-4372-0-400000033D4D1C15"))
            assert(not AddOn:IsCreatureGUID("Player-4372-0232E2F9"))
            assert.equal(448, AddOn:ExtractCreatureId("Creature-0-1465-0-2105-448-000043F59F"))
        end)
        it("IsPlayerGUID", function()
            assert(AddOn:IsPlayerGUID("Player-4372-0232E2F9"))
            assert(not AddOn:IsPlayerGUID("Item-4372-0-400000033D4D1C15"))
            assert(not AddOn:IsPlayerGUID("Creature-0-1465-0-2105-448-000043F59F"))
        end)

        it("IsItemGUID", function()
            assert(AddOn:IsGUID("Player-4372-0232E2F9"))
            assert(AddOn:IsGUID("Item-4372-0-400000033D4D1C15"))
            assert(AddOn:IsGUID("Creature-0-1465-0-2105-448-000043F59F"))
            assert(not AddOn:IsGUID("0"))
            assert(not AddOn:IsGUID("Animal"))
            assert(not AddOn:IsGUID("A012C-"))
            assert.equal("Player", AddOn:GetGUIDType("Player-4372-0232E2F9"))
            assert.equal("Item", AddOn:GetGUIDType("Item-4372-0-400000033D4D1C15"))
            assert.equal("Creature", AddOn:GetGUIDType("Creature-0-1465-0-2105-448-000043F59F"))
        end)

        it("ForEachItemInBags", function()
            local invocations, stopAfter = 0, 0
            local itemFn = function(...)
                invocations = invocations + 1
                if stopAfter >0 and invocations >= stopAfter then
                    return false
                end

                return true
            end

            AddOn:ForEachItemInBags(itemFn)
            -- see C_Container.GetContainerNumSlots for the multiple of 10
            assert.equal((NUM_BAG_SLOTS + 1 --[[ backpack is index 0 --]]) * 10, invocations)

            invocations = 0
            stopAfter = 11

            AddOn:ForEachItemInBags(itemFn)
            assert.equal(stopAfter, invocations)
        end)

        local function AssertLocation(location, bag, slot)
            assert(not Util.Tables.IsEmpty(location))
            assert.equal(bag, location.bag)
            assert.equal(slot, location.slot)
            assert.Is.Not.Nil(location.guid)
            assert(AddOn:IsItemGUID(location.guid))
        end

        it("FindItemInBags", function()
            local _GetItemID = _G.C_Item.GetItemID

            _G.C_Item.GetItemID = function(location)
                local container, slot = location.bagID, location.slotIndex
                if container == 1 and slot == 4 then
                    return 12345
                elseif container == 1 and slot == 6 then
                    return 67890
                elseif container == 2 and slot == 1 then
                    return 12345
                end

                return _GetItemID(location)
            end

            local location = AddOn:FindItemInBags(12345)
            AssertLocation(location, 1, 4)
            location = AddOn:FindItemInBags("item:12345:::::::::::::::::")
            AssertLocation(location, 1, 4)
            location = AddOn:FindItemInBags(12345, true)
            AssertLocation(location, 1, 4)

            local _GetInventoryItemTradeTimeRemaining = AddOn.GetInventoryItemTradeTimeRemaining
            AddOn.GetInventoryItemTradeTimeRemaining = function(_, bag, slot)
                if bag == 1 and slot == 6 then
                    return 0
                end

                return _GetInventoryItemTradeTimeRemaining(AddOn, bag, slot)
            end

            location = AddOn:FindItemInBags(67890)
            assert.same({}, location)
            location = AddOn:FindItemInBags(67890, true)
            AssertLocation(location, 1, 6)

            finally(function()
                _G.C_Item.GetItemID = _GetItemID
                AddOn.GetInventoryItemTradeTimeRemaining = _GetInventoryItemTradeTimeRemaining
            end)
        end)

        local function AssertLocations(locations, contains)
            assert(#locations == #contains)
            for index, location in ipairs(locations) do
                AssertLocation(location, unpack(contains[index]))
            end
        end

        it("FindItemsInBags", function()
            local _GetItemID = _G.C_Item.GetItemID

            _G.C_Item.GetItemID = function(location)
                local container, slot = location.bagID, location.slotIndex
                if container == 1 and slot == 4 then
                    return 12345
                elseif container == 1 and slot == 6 then
                    return 67890
                elseif container == 1 and slot == 7 then
                    return 67891
                elseif container == 2 and slot == 1 then
                    return 12345
                end

                return _GetItemID(location)
            end


            local locations = AddOn:FindItemsInBags(12345)
            AssertLocations(locations,{{1, 4}, {2,1}})
            locations = AddOn:FindItemsInBags("item:12345:::::::::::::::::")
            AssertLocations(locations,{{1, 4}, {2,1}})
            locations = AddOn:FindItemsInBags(12345, true)
            AssertLocations(locations,{{1, 4}, {2,1}})

            local _GetInventoryItemTradeTimeRemaining = AddOn.GetInventoryItemTradeTimeRemaining
            AddOn.GetInventoryItemTradeTimeRemaining = function(_, bag, slot)
                if bag == 1 and slot == 4 then
                    return 0
                end

                return _GetInventoryItemTradeTimeRemaining(AddOn, bag, slot)
            end

            locations = AddOn:FindItemsInBags(12345)
            AssertLocations(locations,{{2,1}})
            locations = AddOn:FindItemsInBags(12345, true)
            AssertLocations(locations,{{1, 4}, {2,1}})

            finally(function()
                _G.C_Item.GetItemID = _GetItemID
                AddOn.GetInventoryItemTradeTimeRemaining = _GetInventoryItemTradeTimeRemaining
            end)
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
            if elapsed >= 2.5 then
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

            assert.is.near(invoked, 2, 1)
        end))
    end)

    describe("Stopwatch", function()
        local sw = AddOn.Stopwatch()

        it("functions", function()
            sw:Start()
            sleep(0.5)
            sw:Stop()
            --print(tostring(sw))
            assert.is.near(sw:Elapsed(), 500.0, 0.25)
            sw:Restart()
            sleep(0.2)
            sw:Stop()
            --print(tostring(sw))
            assert.is.near(sw:Elapsed(), 200.0, 0.25)
        end)
    end)
end)