local AddOn, UIUtil, Util

describe("UI Util", function()
    setup(function()
        _, AddOn = loadfile("Test/TestSetup.lua")(true, 'UI_Util')
        UIUtil = AddOn.Require('UI.Util')
        Util = AddOn:GetLibrary("Util")
    end)

    teardown(function()
        After()
    end)

    describe("basic operations", function()
        it("ColoredDecorator", function()
            assert(UIUtil.ColoredDecorator(1, 1, 1):decorate('Test') == "|cFFFFFFFFTest|r")
            assert(UIUtil.ColoredDecorator({1, 1, 1}):decorate('Test') == "|cFFFFFFFFTest|r")
            assert(UIUtil.ColoredDecorator(CreateColor(1, 1, 1, 1)):decorate('Test') == "|cFFFFFFFFTest|r")
        end)
    end)
end)
