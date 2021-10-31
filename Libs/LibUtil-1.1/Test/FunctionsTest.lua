local Util

describe("LibUtil", function()
	setup(function()
		loadfile("Test/TestSetup.lua")(false, 'LibUtil')
		loadfile("Libs/LibUtil-1.1/Test/BaseTest.lua")()
		LoadDependencies()
		ConfigureLogging()
		Util = LibStub:GetLibrary('LibUtil-1.1')
	end)

	teardown(function()
		After()
	end)

	describe('Functions', function()
		it("Call", function()
			Util.Functions.Call(Util.Functions.Noop)
			Util.Functions.Call(Util.Functions.Noop, nil, nil, true, true)
			Util.Functions.Call(Util.Functions.Noop, nil, nil, true)
			Util.Functions.Call(Util.Functions.Noop, nil, nil, false, true)
		end)
		it("Val", function()
			local r = Util.Functions.Val(Util.Functions.Add, 1, 2)
			assert.equal(r, 3)
			r = Util.Functions.Val(Util.Functions.Inc, 1)
			assert.equal(r, 2)
			r = Util.Functions.Val(Util.Functions.Dec, 1)
			assert.equal(r, 0)
			r = Util.Functions.Val(Util.Functions.Sub, 3, 0)
			assert.equal(r, 3)
			r = Util.Functions.Val(Util.Functions.Mul, 3, 2)
			assert.equal(r, 6)
			r = Util.Functions.Val(Util.Functions.Div, 6, 2)
			assert.equal(r, 3)
		end)
		it("Dispatch", function()
			local d = Util.Functions.Dispatch(Util.Functions.Add, Util.Functions.Inc, Util.Functions.Inc)
			local r = d(3, 5)
			assert.equal(r, 8)
		end)
		it("Filter", function()
			local function f(_, v)
				return v % 10 == 0
			end

			for _, v in Util.Functions.Filter(f, pairs({1, 10, 234, 100, 120})) do
				assert(v % 10 == 0)
			end
		end)
		it("Throttle", function()
			local fn = Util.Functions.Throttle(Util.Functions.Id, 2)
			fn()
			fn()
		end)
		it("Debounce", function()
			local fn = Util.Functions.Debounce(Util.Functions.Id, 2)
			fn()
			fn()
		end)
		it("Try/Finally", function()
			local finalized = false
			Util.Functions.try(
				function()

				end
			).finally(
				function()
					finalized = true
				end
			)

			assert(finalized)

			Util.Functions.try(
					function()
						error("try error simulated")
					end
			).finally(
					function()
						finalized = false
					end
			)

			assert(not finalized)
		end)

	end)
end )