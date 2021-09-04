local AddOnName, AddOn, C, Util, SC

describe("SlashCommands", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Core_SlashCommands')
        C, Util, SC = AddOn.Constants, AddOn:GetLibrary('Util'), AddOn.Require('Core.SlashCommands')
        ConfigureLogging()
    end)
    teardown(function()
        After()
    end)

    describe("basics", function()
        describe("Subscribe", function()
            it("fails on invalid arguments", function()
                assert.has.errors(function() SC:Subscribe() end, "'cmds' must be a table of strings with at least one entry")
                assert.has.errors(function() SC:Subscribe(true) end, "'cmds' must be a table of strings with at least one entry")
                assert.has.errors(function() SC:Subscribe({}) end, "'cmds' must be a table of strings with at least one entry")
                assert.has.errors(function() SC:Subscribe({1}) end, "'cmds' must be a table of strings with at least one entry")
                assert.has.errors(function() SC:Subscribe({"1", 2}) end, "'cmds' must be a table of strings with at least one entry")
                assert.has.errors(function() SC:Subscribe({"1"}) end, "'desc' was not provided")
                assert.has.errors(function() SC:Subscribe({"1"}, true) end, "'desc' was not provided")
                assert.has.errors(function() SC:Subscribe({"1"}, "desc") end, "'func' was not provided")
                assert.has.errors(function() SC:Subscribe({"1"}, "desc", true) end, "'func' was not provided")
            end)
        end)
        describe("BulkSubscribe", function()
            it("fails on invalid arguments", function()
                assert.has.errors(function() SC:BulkSubscribe() end, "each 'cmd' parameter must be a table")
                assert.has.errors(function() SC:BulkSubscribe(true) end, "each 'cmd' parameter must be a table")
            end)
        end)
    end)

    describe("functional", function()
        local match = require "luassert.match"
        describe("receive", function()
            local _ = match._
            local onReceiveSpy, _sub
            local t = {
                receiver = function(...)
                    print(format('receiver() -> args=%s', Util.Objects.ToString({...})))
                    return ...
                end
            }

            setup(function()
                _sub = SC:Subscribe(
                        {'test', 't', 'Test'},
                        "test description",
                        function(...) t.receiver(...) end
                )
            end)

            before_each(function()
                SC:Register()
                onReceiveSpy = spy.on(t, 'receiver')
            end)


            teardown(function()
                _sub:unsubscribe()
                SC:Unregister()
            end)


            it("not invoked with no arguments", function()
                __WOW_Input('/cleo')
                assert.spy(onReceiveSpy).was_called(0)
            end)

            it("invoked with arguments", function()
                __WOW_Input('/cleo test')
                assert.spy(onReceiveSpy).was_called(1)
                assert.spy(onReceiveSpy).returned_with()
                assert.spy(onReceiveSpy).was_called_with()

                __WOW_Input('/cleo test 1 2')
                assert.spy(onReceiveSpy).was_called(2)
                assert.spy(onReceiveSpy).returned_with('1', '2')
                assert.spy(onReceiveSpy).was_called_with('1', '2')

                __WOW_Input('/cleo t 99')
                assert.spy(onReceiveSpy).was_called(3)
                assert.spy(onReceiveSpy).returned_with('99')
                assert.spy(onReceiveSpy).was_called_with('99')

                __WOW_Input('/cleo tESt x1')
                assert.spy(onReceiveSpy).was_called(4)
                assert.spy(onReceiveSpy).returned_with('x1')
                assert.spy(onReceiveSpy).was_called_with('x1')
            end)
        end)
        describe("bulk receive", function()
            local _ = match._
            local onReceiveSpy, _subs
            local t = {
                receiver = function(cmd, ...)
                    print(format('receiver() -> cmd=%s, args=%s', tostring(cmd) ,Util.Objects.ToString({...})))
                    return ...
                end
            }

            setup(function()
                _subs = SC:BulkSubscribe(
                    {
                        {'test', 't', 'Test'},
                        "test description",
                        function(...) t.receiver('test', ...) end
                    },
                    {
                        {'foo', 'f', 'fOo'},
                        "foo description",
                        function(...) t.receiver('foo', ...) end
                    }
                )
            end)

            before_each(function()
                SC:Register()
                onReceiveSpy = spy.on(t, 'receiver')
            end)


            teardown(function()
                for _, _sub in pairs(_subs) do
                    _sub:unsubscribe()
                end
                SC:Unregister()
            end)

            it("invokes all", function()
                __WOW_Input('/cleo')
                assert.spy(onReceiveSpy).was_called(0)

                __WOW_Input('/cleo test')
                __WOW_Input('/cleo foo')
                assert.spy(onReceiveSpy).was_called(2)
                assert.spy(onReceiveSpy).was_called_with('test')
                assert.spy(onReceiveSpy).returned_with()
                assert.spy(onReceiveSpy).was_called_with('foo')
                assert.spy(onReceiveSpy).returned_with()

                __WOW_Input('/cleo test 1 2 3')
                __WOW_Input('/cleo foo 9 8 6')
                assert.spy(onReceiveSpy).was_called(4)
                assert.spy(onReceiveSpy).was_called_with('test', '1', '2', '3')
                assert.spy(onReceiveSpy).returned_with('1', '2', '3')
                assert.spy(onReceiveSpy).was_called_with('foo', '9', '8', '6')
                assert.spy(onReceiveSpy).returned_with('9', '8', '6')
            end)
        end)
    end)
end)