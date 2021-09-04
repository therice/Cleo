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
        it("builds options", function()
            local opts = AddOn.BuildConfigOptions()
            local memoized1 = AddOn.ConfigOptions()
            local memoized2 = AddOn.ConfigOptions()
            assert(opts)
            assert(memoized1)
            assert(memoized2)

            -- these point to the actual addon, nil them out
            opts['handler'] = nil
            memoized1['handler'] = nil
            memoized2['handler'] = nil
            assert.is.same(memoized1, memoized2)
        end)
        it("toggles display", function()
            AddOn:RegisterConfig()
            AddOn.ToggleConfig()
            AddOn.HideConfig()
        end)
    end)
end)