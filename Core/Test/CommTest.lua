local AddOnName, AddOn, C, Util, Player

describe("Comm", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Core_Comm')
        C, Util = AddOn.Constants, AddOn:GetLibrary('Util')
        Player = AddOn.Package('Models').Player
        AddOn.player = Player:Get("Player1")
    end)
    teardown(function()
        After()
        AddOn.realmName = nil
        AddOn.player = nil
    end)

    describe("basics", function()
        local Comm = AddOn.Require('Core.Comm')
        local Subscription = AddOn:GetLibrary("Rx").rx.Subscription
        describe("Subscribe", function()
            it("fails on an invalid prefix", function()
                assert.has.errors(function() Comm:Subscribe() end, "subscription prefix was not provided")
                assert.has.errors(function() Comm:Subscribe("invalid") end, "'invalid' is not a registered prefix")
            end)
            it("returns a subscription", function()
                local sub = Comm:Subscribe(C.CommPrefixes.Main, "cmd", function () end)
                assert.is_a(sub, Subscription)
            end)
            it("returns different subscriptions", function()
                local sub1 = Comm:Subscribe(C.CommPrefixes.Main, "cmd", function () end)
                local sub2 = Comm:Subscribe(C.CommPrefixes.Main, "cmd", function () end)
                assert.is_a(sub1, Subscription)
                assert.is_a(sub2, Subscription)
                assert.are_not.equal(sub1, sub2)
            end)
        end)
        describe("BulkSubscribe", function()
            it("fails for invalid arguments", function()
                assert.has.errors(function() Comm:BulkSubscribe() end, "functions must be a table")
            end)
            it("returns an array of subscriptions", function()
                local subscriptions = Comm:BulkSubscribe(
                        C.CommPrefixes.Main,
                        {
                            one = function() end,
                            two = function() end,
                            three = function() end,
                            four = function() end,
                        }
                )
                assert.is.table(subscriptions)
                assert.equals(4, #subscriptions)
                for _,v in ipairs(subscriptions) do
                    assert.is_a(v, Subscription)
                end
            end)
        end)
        describe("GetSender", function()
            it("fails for invalid arguments", function()
                assert.has.errors(function() Comm:GetSender() end, "prefix was not provided")
                assert.has.errors(function() Comm:GetSender(nil) end, "prefix was not provided")
                assert.has.errors(function() Comm:GetSender(false) end, "prefix was not provided")
                assert.has.errors(function() Comm:GetSender("") end, "prefix was not provided")
                assert.has.errors(function() Comm.GetSender("prefix") end, "prefix was not provided")
            end)
            it("returns a function", function()
                assert.is.Function(Comm:GetSender("prefix"))
            end)
        end)
        describe("Send", function()
            it("fails for invalid arguments", function()
                assert.has.errors(function() Comm:Send() end, "args must be a table")
                assert.has.errors(function() Comm:Send({}) end, "command was not provided")
                assert.has.errors(function() Comm:Send({data=true}) end, "command was not provided")
            end)
        end)
        describe("RegisterPrefix", function()
            it("fails for invalid arguments", function()
                assert.has.errors(function() Comm.RegisterPrefix() end , "prefix was not provided")
                assert.has.errors(function() Comm:RegisterPrefix(nil) end, "prefix was not provided")
                assert.has.errors(function() Comm:RegisterPrefix(false) end, "prefix was not provided")
                assert.has.errors(function() Comm:RegisterPrefix("") end, "prefix was not provided")
                assert.has.errors(function() Comm.RegisterPrefix("prefix") end, "prefix was not provided")
            end)
            it("succeeds with proper prefix", function()
                assert.has_no.errors(function() Comm:RegisterPrefix("yabba") end)
            end)
        end)
    end)

    describe("functional", function()
        local Comm = AddOn.Require('Core.Comm')
        local match = require "luassert.match"
        describe("sends", function()
            local _ = match._
            local onReceiveSpy, _sub
            local t = {
                receiver =
                    function(data, sender, ...)
                        print(format('receiver() -> from=%s, data=%s, extra=%s', sender, Util.Objects.ToString(data), Util.Objects.ToString({...})))
                        return unpack(data)
                    end
            }

            setup(function()
                _sub = Comm:Subscribe(C.CommPrefixes.Main, "test_cmd", function(...) t.receiver(...) end)
            end)

            teardown(function()
                print(Util.Objects.ToString(Comm.private.metricsSend:Summarize()))
                print(Util.Objects.ToString(Comm.private.metricsRecv:Summarize()))
                print(Util.Objects.ToString(Comm.private.metricsFired:Summarize()))
                _sub:unsubscribe()
            end)

            before_each(function()
                _G.IsInRaidVal = true
                onReceiveSpy = spy.on(t, "receiver")
            end)

            it("via GetSender", function()
                local data = "test data"
                Comm:GetSender(C.CommPrefixes.Main)(AddOn, C.group, "test_cmd", data)
                WoWAPI_FireUpdate(GetTime()+10)
                assert.spy(onReceiveSpy).was_called(1)
                assert.spy(onReceiveSpy).returned_with(data)
                assert.spy(onReceiveSpy).was_called_with(match.is_table(), "Player1-Realm1", "test_cmd", C.Channels.Raid)

                Comm:GetSender(C.CommPrefixes.Main)(C.group, "test_cmd", data)
                WoWAPI_FireUpdate(GetTime()+10)
                assert.spy(onReceiveSpy).was_called(2)
                assert.spy(onReceiveSpy).returned_with(data)
                assert.spy(onReceiveSpy).was_called_with(match.is_table(), "Player1-Realm1", "test_cmd", C.Channels.Raid)

                onReceiveSpy:clear()

                local mock = {}
                mock.Send = Comm:GetSender(C.CommPrefixes.Main)
                mock:Send(C.group, "test_cmd", data)
                WoWAPI_FireUpdate(GetTime()+10)
                assert.spy(onReceiveSpy).was_called(1)
                assert.spy(onReceiveSpy).returned_with(data)
                assert.spy(onReceiveSpy).was_called_with(match.is_table(), "Player1-Realm1", "test_cmd", C.Channels.Raid)

                mock.Send(C.group, "test_cmd", data)
                WoWAPI_FireUpdate(GetTime()+10)
                assert.spy(onReceiveSpy).was_called(2)
                assert.spy(onReceiveSpy).returned_with(data)
                assert.spy(onReceiveSpy).was_called_with(match.is_table(), "Player1-Realm1", "test_cmd", C.Channels.Raid)
            end)

            it("via GetSender with multiple arguments", function()
                local arg1,arg2,arg3 = 3, "test", {"args"}
                Comm:GetSender(C.CommPrefixes.Main)(C.group, "test_cmd", arg1,arg2,arg3)
                WoWAPI_FireUpdate(GetTime()+10)
                assert.spy(onReceiveSpy).was_called(1)
                assert.spy(onReceiveSpy).returned_with(arg1,arg2,arg3)
                assert.spy(onReceiveSpy).was_called_with(match.is_table(), "Player1-Realm1", "test_cmd", C.Channels.Raid)
            end)

            it("via GetSender with different prefix", function()
                local prefix = "foo"
                local s = spy.new(function(...) return ... end)
                Comm:RegisterPrefix(prefix)
                Comm:Subscribe(prefix, "test_cmd", s)
                Comm:Send({
                    prefix = prefix,
                    command = "test_cmd",
                    data = "wacka wacka"
                })
                WoWAPI_FireUpdate(GetTime()+10)
                assert.spy(s).was_called(1)
            end)

            describe("in different group types", function()
                before_each(function()
                    _G.IsInRaidVal = false
                    _G.IsInGroupVal = false
                end)
                it("party", function()
                    _G.IsInGroupVal = true
                    Comm:GetSender(C.CommPrefixes.Main)(C.group, "test_cmd")
                    WoWAPI_FireUpdate(GetTime()+10)
                    assert.spy(onReceiveSpy).was_called(1)
                    assert.spy(onReceiveSpy).returned_with()
                    assert.spy(onReceiveSpy).was_called_with(match.is_table(), "Player1-Realm1", "test_cmd", C.Channels.Party)
                end)
                it("guild", function()
                    Comm:GetSender(C.CommPrefixes.Main)(C.guild, "test_cmd")
                    WoWAPI_FireUpdate(GetTime()+10)
                    assert.spy(onReceiveSpy).was_called(1)
                    assert.spy(onReceiveSpy).returned_with()
                    assert.spy(onReceiveSpy).was_called_with(match.is_table(), "Player1-Realm1", "test_cmd", C.Channels.Guild)
                end)
                it("none", function()
                    Comm:GetSender(C.CommPrefixes.Main)(C.group, "test_cmd")
                    WoWAPI_FireUpdate(GetTime()+10)
                    assert.spy(onReceiveSpy).was_called(1)
                    assert.spy(onReceiveSpy).returned_with()
                    assert.spy(onReceiveSpy).was_called_with(match.is_table(), "Player1-Realm1", "test_cmd", C.Channels.Whisper)
                end)
            end)

            describe("via Send", function()
                it("basics", function()
                    local data = "test2"
                    Comm:Send({
                        prefix = C.CommPrefixes.Main,
                        command = "test_cmd",
                        data = data
                    })

                    WoWAPI_FireUpdate(GetTime()+10)
                    assert.spy(onReceiveSpy).was_called(1)
                    assert.spy(onReceiveSpy).returned_with(data)
                    assert.spy(onReceiveSpy).was_called_with(match.is_table(), "Player1-Realm1", "test_cmd", C.Channels.Raid)
                end)
                it("with 'ALERT' priority", function()
                    local data = "ALERT PRIO"
                    Comm:Send({
                        prefix = C.CommPrefixes.Main,
                        command = "test_cmd",
                        data = data,
                        prio = "ALERT"
                    })

                    WoWAPI_FireUpdate(GetTime()+10)
                    assert.spy(onReceiveSpy).was_called(1)
                    assert.spy(onReceiveSpy).returned_with(data)
                    assert.spy(onReceiveSpy).was_called_with(match.is_table(), "Player1-Realm1", "test_cmd", C.Channels.Raid)
                end)
                it("with 'BULK' priority", function()
                    local data = "BULK PRIO"
                    Comm:Send({
                        prefix = C.CommPrefixes.Main,
                        command = "test_cmd",
                        data = data,
                        prio = "BULK"
                    })

                    WoWAPI_FireUpdate(GetTime()+10)
                    assert.spy(onReceiveSpy).was_called(1)
                    assert.spy(onReceiveSpy).returned_with(data)
                    assert.spy(onReceiveSpy).was_called_with(match.is_table(), "Player1-Realm1", "test_cmd", C.Channels.Raid)
                end)
                it("with callback func", function()
                    local s = spy.new(function(...) end)
                    local data = "a"
                    Comm:Send({
                        prefix = C.CommPrefixes.Main,
                        command = "test_cmd",
                        data = data,
                        callback = s,
                    })

                    WoWAPI_FireUpdate(GetTime()+10)
                    assert.spy(onReceiveSpy).was_called(1)
                    assert.spy(onReceiveSpy).returned_with(data)
                    assert.spy(onReceiveSpy).was_called_with(match.is_table(), "Player1-Realm1", "test_cmd", C.Channels.Raid)

                    assert.spy(s).was_called(1)
                    assert.spy(s).was_called_with(nil, match.is_number(), match.is_number())
                end)
                it("with callback func multiple messages", function()
                    --Comm:RegisterPrefix(C.CommPrefixes.Main)

                    local s = spy.new(function(...) print('callback1 -> ' .. Util.Objects.ToString({...})) end)
                    -- Now to construct data that will produce two messages with LibDeflate :/
                    local data = {}
                    for i=1,150 do
                        data[i] = {string.char(i)}
                    end
                    Comm:Send({
                        prefix = C.CommPrefixes.Main,
                        command = "test_cmd",
                        data = {data},
                        callback = s,
                    })

                    WoWAPI_FireUpdate(GetTime()+10)
                    assert.spy(onReceiveSpy).was_called(1)
                    assert.spy(onReceiveSpy).returned_with(data)
                    assert.spy(onReceiveSpy).was_called_with(match.is_table(), "Player1-Realm1", "test_cmd", C.Channels.Raid)

                    assert.spy(s).was_called(2)
                    assert.spy(s).was_called_with(nil, match.is_number(), match.is_number())
                end)
                it("with callback func and arg", function()
                    local s = spy.new(function(...) --[[print('callback1 -> ' .. Util.Objects.ToString(...)) --]] end)
                    local data = "a"
                    local arg = {}
                    Comm:Send({
                        prefix = C.CommPrefixes.Main,
                        command = "test_cmd",
                        data = data,
                        callback = s,
                        callbackarg = arg
                    })

                    WoWAPI_FireUpdate(GetTime()+10)
                    assert.spy(onReceiveSpy).was_called(1)
                    assert.spy(onReceiveSpy).returned_with(data)
                    assert.spy(onReceiveSpy).was_called_with(match.is_table(), "Player1-Realm1", "test_cmd", C.Channels.Raid)

                    assert.spy(s).was_called(1)
                    assert.spy(s).was_called_with(arg, match.is_number(), match.is_number())
                end)
            end)
        end)

        describe("receives", function()
            it("the same data with both sender types", function()
                local rec1, rec2
                local prefix = C.CommPrefixes.Version
                local cmd1, cmd2 = ":GetSender", ":Send"
                local data1, data2 = {
                    "test",
                    ["our"] = "data"
                }, "structure"

                Comm:BulkSubscribe(prefix, {
                    [cmd1] = function(data)
                        --print(':GetSender(callback) -> ' .. Util.Objects.ToString(data))
                        rec1 = data
                    end,
                    [cmd2] = function(data)
                        --print(':Send(callback) -> ' .. Util.Objects.ToString(data))
                        rec2 = data
                    end
                })

                Comm:GetSender(prefix)(C.group, cmd1, data1, data2)
                Comm:Send({
                    prefix = prefix,
                    command = cmd2,
                    data = {data1, data2}
                })

                WoWAPI_FireUpdate(GetTime()+10)
                assert.are.same(rec1, rec2)
            end)
            it("handles unsubscribe", function()
                local s = spy.new(function(data,sender,command, dist) return unpack(data) end)
                local sub = Comm:Subscribe(C.CommPrefixes.Main, "test_cmd", s)

                local data = "test"
                Comm:Send({
                    prefix = C.CommPrefixes.Main,
                    command = "test_cmd",
                    data = data
                })

                WoWAPI_FireUpdate(GetTime()+10)
                assert.spy(s).was_called(1)
                assert.spy(s).returned_with(data)

                sub:unsubscribe()

                Comm:Send({
                    prefix = C.CommPrefixes.Main,
                    command = "something else that shouldn't be received",
                    data = data
                })

                WoWAPI_FireUpdate(GetTime()+10)
                assert.spy(s).was_called(1)
                assert.spy(s).returned_with(data)
            end)
        end)

        it("should send to a specific target", function()
            local s = spy.new(function(data,sender,command, dist) return unpack(data) end)
            Comm:Subscribe(C.CommPrefixes.Main, "test_cmd", s)

            local target = Player:Get("Player1")
            _G.UnitIsUnit = function(unit1, unit2)
                return true
            end

            local data = "test"
            Comm:Send({
                command = "test_cmd",
                data = data,
                target = target
            })

            WoWAPI_FireUpdate(GetTime()+10)
            assert.spy(s).was_called(1)
            assert.spy(s).returned_with(data)

            AddOn.UnitIsUnit = function(self, unit1, unit2)
                return false
            end

            Comm:Send({
                command = "test_cmd",
                data = data,
                target = 'Player1'
            })
            WoWAPI_FireUpdate(GetTime()+10)
            assert.spy(s).was_called(2)
            assert.spy(s).returned_with(data)

            Comm:Send({
                command = "test_cmd",
                data = data,
                target = 'Player1-Realm1'
            })
            WoWAPI_FireUpdate(GetTime()+10)
            assert.spy(s).was_called(3)
            assert.spy(s).returned_with(data)
            _G.UnitIsUnit = nil
        end)
    end)
end)