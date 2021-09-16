local AddOnName, AddOn

describe("Core", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Core_Config')
        AddOnLoaded(AddOnName, true)
    end)
    teardown(function()
        After()
    end)

    describe("Config", function()
        it("handles config supplement", function()
            local n,f = AddOn:GetConfigSupplement({
                GetName = function() return "Dummy" end
            })

            assert.Is.Nil(n)
            assert.Is.Nil(f)

            n,f = AddOn:GetConfigSupplement({
                GetName = function() return "Dummy" end,
                ConfigSupplement = function(...)  return "", function() end end
            })

            assert.Is.Nil(n)
            assert.Is.Nil(f)

            n,f = AddOn:GetConfigSupplement({
                GetName = function() return "Dummy" end,
                ConfigSupplement = function(...)  return "Dummy", function() end end
            })

            assert.Is.Not.Nil(n)
            assert.Is.Not.Nil(f)
        end)

        it("handles launchpad supplement", function()
            local n, m = AddOn:GeLaunchpadSupplement({
              GetName = function() return "Dummy" end
            })

            assert.Is.Nil(n)
            assert.Is.Nil(m)

            n,m = AddOn:GeLaunchpadSupplement({
                GetName = function() return "Dummy" end,
                LaunchpadSupplement = function(...)  return "", function() end , true end
            })

            assert.Is.Nil(n)
            assert.Is.Nil(m)

            n,m = AddOn:GeLaunchpadSupplement({
                GetName = function() return "Dummy" end,
                LaunchpadSupplement = function(...)  return "Dummy", function() end, true end
            })

            assert.Is.Not.Nil(n)
            assert.Is.Not.Nil(m[1])
            assert.Is.Not.Nil(m[2])
            assert.equal(m[3], true)
        end)
    end)
end)