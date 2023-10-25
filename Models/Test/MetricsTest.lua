local AddOnName, AddOn
--- @type LibUtil
local Util
--- @type Models.Metrics
local Metrics
--- @type Models.Metric
local Metric

describe("Stats", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Core_Stats')
		Util, Metrics, Metric =
			AddOn:GetLibrary('Util'), AddOn.Package('Models').Metrics, AddOn.Package('Models').Metric

	end)
	teardown(function()
		After()
	end)

	describe("functional", function()
		local metrics, timerA, timerB, ssA, ssB

		setup(function()
			metrics = Metrics("test")
			timerA = metrics:Timer('A')
			timerB = metrics:Timer('B')

			timerA:Time(function() sleep(0.02) end)
			timerA:Time(function() sleep(0.03) end)
			timerA:Timed(function() sleep(0.02) end)()
			assert.has.error(function() timerA:Time(function() sleep(0.02); error(); end) end)
			assert.has.error(function() timerA:Time(function() sleep(0.01); error(); end) end)
			timerB:Time(function() sleep(0.22) end)
			timerB:Timed(function(x) sleep(x) end)(0.25)
			assert.has.error(function() timerB:Time(function() sleep(0.20); error(); end) end)
			assert.has.error(function() timerB:Time(function() sleep(0.30); error(); end) end)

			ssA, ssB = timerA:Snapshot(), timerB:Snapshot()
		end)
		--
		it("tracks invocations", function()
			assert.equal(ssA:Count(), 5)
			assert.equal(ssB:Count(), 4)
		end)
		it("min", function()
			assert.is.near(ssA:Min(), 10.018, 0.1)
			assert.is.near(ssB:Min(), 200.026, 0.1)
		end)
		it("max", function()
			assert.is.near(ssA:Max(), 30.016, 0.1)
			assert.is.near(ssB:Max(), 300.057, 0.1)
		end)
		it("mean", function()
			assert.is.near(ssA:Mean(), 20.0, 0.1)
			assert.is.near(ssB:Mean(), 242.5, 0.5)
		end)
		it("median", function()
			assert.is.near(ssA:Median(), 20.0, 0.1)
			assert.is.near(ssB:Median(), 235.0, 0.2)
		end)
		it("stddev", function()
			assert.is.near(ssA:StdDev(), 7.07, 0.01)
			assert.is.near(ssB:StdDev(), 43.49, 0.05)
		end)
		it("summarizes snapshot", function()
			local summary = ssA:Summarize()
			assert(summary)
			print(Util.Objects.ToString(summary))

			summary = ssB:Summarize()
			assert(summary)
			print(Util.Objects.ToString(summary))
		end)

		it("summarizes metrics", function()
			local summary = metrics:Summarize()
			assert(summary)
			print(Util.Objects.ToString(summary, 10))
			assert(summary['test'])
			assert(summary['test']['A'])
			assert(summary['test']['B'])
		end)
	end)

	describe("prunes", function()
		it("stale entries", function()
			local m,ts = Metric('m'), GetServerTime()
			tinsert(m.values, { t = ts - 711})
			tinsert(m.values, { t = ts - 601})
			tinsert(m.values, { t = ts - 600})
			tinsert(m.values, { t = ts - 60})
			tinsert(m.values, { t = ts - 50})
			tinsert(m.values, { t = ts - 40})
			tinsert(m.values, { t = ts - 30})
			tinsert(m.values, { t = ts - 20})
			tinsert(m.values, { t = ts - 10})
			assert(#m.values == 9)
			m:_prune()
			assert(#m.values == 6)
		end)
	end)
end)