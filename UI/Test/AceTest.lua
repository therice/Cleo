local AddOn, AceUI, Util


describe("Ace UI", function()
    setup(function()
        _, AddOn = loadfile("Test/TestSetup.lua")(true, 'UI_Ace')
        AceUI = AddOn.Require('UI.Ace')
        Util = AddOn:GetLibrary("Util")
    end)

    teardown(function()
        After()
    end)

    describe("is", function()
        it("loaded and initialized", function()
            assert(AceUI)
        end)
    end)

    describe("widget creation", function()
        it("succeeds for Button", function()
            local b = AceUI('Button').SetText("Test")()
            assert(b.type == 'Button')
        end)
        it("succeeds for Dropdown", function()
            local d = AceUI('Dropdown')()
            assert(d)
        end)
        it("succeeds for Slider", function()
            local s = AceUI('Slider')()
            assert(s)
        end)
        it("succeeds for InlineGroup", function()
            local ig = AceUI('InlineGroup')()
            assert(ig)
        end)
        it("succeeds for MultiLineEditBox", function()
            local eb = AceUI('MultiLineEditBox')()
            assert(eb)
        end)
        it("succeeds for EditBox", function()
            local eb = AceUI('EditBox')()
            assert(eb)
        end)
    end)
end)