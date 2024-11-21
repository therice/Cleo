local AddOnName, AddOn, C, Util, Event

describe("Event", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Core_Event')
        C, Util, Event = AddOn.Constants, AddOn:GetLibrary('Util'), AddOn.Require('Core.Event')
    end)
    teardown(function()
        After()
    end)

    describe("basics", function()
        describe("Subscribe", function()
            it("fails on invalid arguments", function()
                assert.has.errors(function() Event:Subscribe() end, "'event' was not provided")
                assert.has.errors(function() Event:Subscribe(true) end, "'event' was not provided")
                assert.has.errors(function() Event:Subscribe({}) end, "'event' was not provided")
                assert.has.errors(function() Event:Subscribe({1}) end, "'event' was not provided")
                assert.has.errors(function() Event:Subscribe("PLAYER_ENTERING_WORLD") end, "'func' was not provided")
                assert.has.errors(function() Event:Subscribe("PLAYER_ENTERING_WORLD", true) end, "'func' was not provided")
                assert.has.errors(function() Event:Subscribe("PLAYER_ENTERING_WORLD", "desc") end, "'func' was not provided")
            end)
        end)
        describe("BulkSubscribe", function()
            it("fails on invalid arguments", function()
                assert.has.errors(function() Event:BulkSubscribe() end, "each 'func' table entry must be an event(string) to function mapping")
                assert.has.errors(function() Event:BulkSubscribe(true) end, "each 'func' table entry must be an event(string) to function mapping")
                assert.has.errors(
                        function()
                            Event:BulkSubscribe({
                                a = {},
                            })
                        end,
                        "each 'func' table entry must be an event(string) to function mapping"
                )
                assert.has.errors(
                        function()
                            Event:BulkSubscribe({
                                a = function () end,
                                b = true,
                            })
                        end,
                        "each 'func' table entry must be an event(string) to function mapping"
                )
            end)
        end)
    end)
    describe("functional", function()

        local match = require "luassert.match"
        describe("receive", function()
            local _ = match._
            local onReceiveSpy, _sub
            local t = {
                receiver = function(event, ...)
                    print(format('receiver() -> event=%s, args=%s', tostring(event), Util.Objects.ToString({...})))
                    return ...
                end
            }

            setup(function()
                _sub = Event:Subscribe(
                        "PLAYER_ENTERING_WORLD",
                        function(event, ...) t.receiver(event, ...) end
                )
            end)

            before_each(function()
                onReceiveSpy = spy.on(t, 'receiver')
                _G.IsLoggedIn = function() return true end
                _G.IsAddOnLoaded = function() return false end
            end)


            teardown(function()
                print(Util.Objects.ToString(Event.private.metricsRcv:Summarize()))
                _sub:unsubscribe()
                _G.IsLoggedIn = function() return false end
            end)

            it("not invoked for unsubscribed event", function()
                WoWAPI_FireEvent('AN_EVENT', 'a', true, {})
                assert.spy(onReceiveSpy).was_called(0)
            end)

            it("invoked for subscribed event", function()
                WoWAPI_FireEvent('PLAYER_ENTERING_WORLD', 'a', true)
                assert.spy(onReceiveSpy).was_called(1)
                assert.spy(onReceiveSpy).was_called_with('PLAYER_ENTERING_WORLD', 'a', true)
                assert.spy(onReceiveSpy).returned_with('a', true)
                WoWAPI_FireEvent('PLAYER_ENTERING_WORLD')
                WoWAPI_FireEvent('PLAYER_ENTERING_WORLD')
                assert.spy(onReceiveSpy).was_called(3)
                assert.spy(onReceiveSpy).was_called_with('PLAYER_ENTERING_WORLD')
                assert.spy(onReceiveSpy).returned_with()
                assert.spy(onReceiveSpy).was_called_with('PLAYER_ENTERING_WORLD')
                assert.spy(onReceiveSpy).returned_with()
            end)

            it("invoked for manually fired and subscribed event", function()
                Event:Fire('PLAYER_ENTERING_WORLD', 1, true)
                assert.spy(onReceiveSpy).was_called(1)
                assert.spy(onReceiveSpy).was_called_with('PLAYER_ENTERING_WORLD', 1, true)
                assert.spy(onReceiveSpy).returned_with(1, true)
            end)
        end)
        describe("bulk receive", function()
            local _ = match._
            local onReceiveSpy, _subs
            local t = {
                receiver = function(event, ...)
                    print(format('receiver() -> event=%s, args=%s', tostring(event), Util.Objects.ToString({...})))
                    return ...
                end
            }

            setup(function()
                _subs = Event:BulkSubscribe({
                    ["PLAYER_ENTERING_WORLD"] = function(event, ...) t.receiver(event, ...) end,
                    ["PLAYER_REGEN_ENABLED"] = function(event, ...) t.receiver(event, ...) end,
                })

                Util.Tables.Insert(_subs,
                        Event:BulkSubscribe({
                            ["PLAYER_ENTERING_WORLD"] = function(event, ...)
                                t.receiver(event, ...)
                            end,
                        })
                )
            end)

            before_each(function()
                onReceiveSpy = spy.on(t, 'receiver')
                _G.IsLoggedIn = function() return true end
            end)


            teardown(function()
                print(Util.Objects.ToString(Event.private.metricsRcv:Summarize()))
                for _, _sub in pairs(_subs) do
                    _sub:unsubscribe()
                end
                _G.IsLoggedIn = function() return false end
            end)
            it("invokes all", function()
                WoWAPI_FireEvent('PLAYER_ENTERING_WORLD', 'a')
                assert.spy(onReceiveSpy).was_called(2)
                assert.spy(onReceiveSpy).was_called_with('PLAYER_ENTERING_WORLD', 'a')
                assert.spy(onReceiveSpy).returned_with('a')
                assert.spy(onReceiveSpy).was_called_with('PLAYER_ENTERING_WORLD', 'a')
                assert.spy(onReceiveSpy).returned_with('a')
                WoWAPI_FireEvent('PLAYER_REGEN_ENABLED', true)
                assert.spy(onReceiveSpy).was_called(3)
                assert.spy(onReceiveSpy).was_called_with('PLAYER_REGEN_ENABLED', true)
                assert.spy(onReceiveSpy).returned_with(true)
            end)
        end)
    end)
end)