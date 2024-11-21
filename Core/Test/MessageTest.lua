--- @type string
local AddOnName
--- @type AddOn
local AddOn
--- @type LibUtil
local Util
--- @type table
local C

describe("Messages", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Core_Messages')
		C, Util = AddOn.Constants, AddOn:GetLibrary('Util')
		SetTime()
	end)
	teardown(function()
		local allMetrics = AddOn.Require('Core.Message'):GetMetrics()
		print(Util.Objects.ToString(allMetrics[1]:Summarize()))
		print(Util.Objects.ToString(allMetrics[2]:Summarize()))
		After()
	end)


	describe("basics", function()
		local Message = AddOn.Require('Core.Message')
		describe("Subscribe", function()
			it("fails on invalid arguments", function()
				assert.has.errors(function() Message:Subscribe() end, "'message' was not provided")
				assert.has.errors(function() Message:Subscribe(true) end, "'message' was not provided")
				assert.has.errors(function() Message:Subscribe({}) end, "'message' was not provided")
				assert.has.errors(function() Message:Subscribe({1}) end, "'message' was not provided")
				assert.has.errors(function() Message:Subscribe("Cleo_Message1") end, "'func' was not provided")
				assert.has.errors(function() Message:Subscribe("Cleo_Message1", true) end, "'func' was not provided")
				assert.has.errors(function() Message:Subscribe("Cleo_Message1", "desc") end, "'func' was not provided")
			end)
		end)
		describe("BulkSubscribe", function()
			it("fails on invalid arguments", function()
				assert.has.errors(function() Message:BulkSubscribe() end, "each 'func' table entry must be an message(string) to function mapping")
				assert.has.errors(function() Message:BulkSubscribe(true) end, "each 'func' table entry must be an message(string) to function mapping")
				assert.has.errors(
					function()
						Message:BulkSubscribe({
							a = {},
						})
					end,
					"each 'func' table entry must be an message(string) to function mapping"
				)
				assert.has.errors(
					function()
						Message:BulkSubscribe({
		                    a = function () end,
		                    b = true,
	                    })
					end,
					"each 'func' table entry must be an message(string) to function mapping"
				)
			end)
		end)
		describe("Send", function()
			it("fails for invalid arguments", function()
				assert.has.errors(function() Message:Send() end, "'message' was not provided")
				assert.has.errors(function() Message:Send({}) end, "'message' was not provided")
				assert.has.errors(function() Message:Send(true) end, "'message' was not provided")
			end)
		end)
	end)

	describe("functional", function()
		local Message = AddOn.Require('Core.Message')
		local match = require "luassert.match"

		describe("sends", function()
			local _ = match._
			local onReceiveSpy, _sub
			local t = {
				receiver =
				function(message, ...)
					print(format('receiver() -> message=%s, args=%s', message, Util.Objects.ToString({...})))
					return ...
				end
			}

			setup(function()
				_sub = Message:Subscribe("Cleo_TestMessage", function(...) t.receiver(...) end)
			end)

			before_each(function()
				onReceiveSpy = spy.on(t, "receiver")
			end)

			teardown(function()
				local allMetrics = AddOn.Require('Core.Message'):GetMetrics()
				print(Util.Objects.ToString(allMetrics[1]:Summarize()))
				print(Util.Objects.ToString(allMetrics[2]:Summarize()))
				_sub:unsubscribe()
			end)

			-- this also implicitly tests receive via _sub
			it("basics", function()
				Message:Send("Cleo_TestMessage", true, 1, "a")
				assert.spy(onReceiveSpy).was_called(1)
				assert.spy(onReceiveSpy).was_called_with('Cleo_TestMessage', true, 1, "a")
				assert.spy(onReceiveSpy).returned_with(true, 1, "a")
				Message:Send("Cleo_TestMessage", true, 2, "a")
				Message:Send("Cleo_TestMessage", true, 3, "a")
				Message:Send("Cleo_TestMessage", true, 4, "a")
				assert.spy(onReceiveSpy).was_called(4)
			end)
		end)

		describe("receives", function()
			it("the same data from different origins", function()
				local r1, r2
				Message:BulkSubscribe({
					["ViaMessage"] = function(_, ...) r1 = {...} end,
					["ViaModule"] = function(_, ...) r2 = {...} end,
                })

				Message:Send("ViaMessage", true, 2, "a")
				AddOn:SendMessage("ViaModule", true, 2, "a")
				assert.are.same(r1, r2)
			end)
			it("handles unsubscribe", function()
				local s = spy.new(function(message, ...) return ... end)
				local sub =  Message:Subscribe("Cleo_TestMessage2", s)

				Message:Send("Cleo_TestMessage2", 1, 2, 3)

				assert.spy(s).was_called(1)
				assert.spy(s).returned_with(1, 2, 3)

				sub:unsubscribe()
				Message:Send("Cleo_TestMessage2", 3, 4, 5)
				Message:Send("Cleo_TestMessage2", 6, 7, 8)

				assert.spy(s).was_called(1)
				assert.spy(s).returned_with(1, 2, 3)

			end)
		end)
	end)
end)