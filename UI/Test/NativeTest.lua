local AddOn, NativeUI, Class

local function CustomWidget()
    local NativeWidget = AddOn.ImportPackage('UI.Native').Widget
    local Widget = Class('CustomWidget', NativeWidget)
    function Widget:initialize(parent, name, ...)
        NativeWidget.initialize(self, parent, name)
        self.args = {...}
    end

    function Widget:Create()
        return self
    end

    return Widget
end

describe("Native UI", function()
    setup(function()
        _, AddOn = loadfile("Test/TestSetup.lua")(true, 'UI_Native')
        NativeUI = AddOn.Require('UI.Native')
        Class = AddOn:GetLibrary('Class')
    end)

    teardown(function()
        After()
    end)

    describe("is", function()
        it("loaded and initialized", function()
            assert(NativeUI)
        end)
    end)

    describe("widget registration", function()
        it("fails with invalid arguments", function()
            assert.has.errors(function () NativeUI:RegisterWidget() end, "Widget type was not provided")
            assert.has.errors(function () NativeUI:RegisterWidget('awidget') end, "Widget class was not provided")
            assert.has.errors(function () NativeUI:RegisterWidget('awidget', true) end, "Widget class was not provided")
        end)
        it("succeeds with valid arguments", function()
            NativeUI:RegisterWidget('awidget', CustomWidget())
            NativeUI:UnregisterWidget('awidget')
        end)
    end)

    describe("widget creation", function()
        it("fails with invalid arguments", function()
            assert.has.errors(function () NativeUI:New('xyz') end, "(Native UI) No widget available for type 'xyz'")
            assert.has.errors(function () NativeUI:New() end, "Widget type was not provided")
        end)
        it("succeeds with valid arguments", function()
            NativeUI:RegisterWidget('awidget', CustomWidget())
            local w = NativeUI:New('awidget')
            assert(w.clazz.name == 'CustomWidget')
            assert(w.name == format('%s_UI_awidget_%d', AddOn.Constants.name, 1))
            assert(w.parent == _G.UIParent)
            -- assert(w.SetMultipleScripts and type(w.SetMultipleScripts) == 'function')
            w = NativeUI:NewNamed('awidget', {}, 'WidgetName')
            assert(w.clazz.name == 'CustomWidget')
            assert(w.name == 'WidgetName')
            assert.are.same(w.parent, { })
            -- assert(w.SetMultipleScripts and type(w.SetMultipleScripts) == 'function')
            NativeUI:UnregisterWidget('awidget')
        end)
    end)
end)