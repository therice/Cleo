--- @type AddOn
local _, AddOn = ...
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")

-- retain up to 10 minutes worth of entries
local MaxRetentionInSecs = 60 * 10

--- @class Models.Snapshot
local Snapshot = AddOn.Package('Models'):Class('Snapshot')
--- @class Models.Metric
local Metric = AddOn.Package('Models'):Class('Metric')
--- @return Models.Metric
function Metric:initialize(name)
	self.name = name
	-- these will be ordered chronologically
	self.values = {

	}
end

function Metric:_prune()
	local st = GetServerTime()
	if #self.values >= 1 and (st > (self.values[1].t + MaxRetentionInSecs)) then
		self.values = Util.Tables.CopyFilter(
				self.values,
				function(e) return st < (e.t + MaxRetentionInSecs) end
		)
	end
end

--- @return table
function Metric:_entry(value, ...)
	-- t (timestamp) : number representing instant when added
	-- d (value) : the metric value
	return {t = GetServerTime(), v = value}
end

function Metric:Update(value, ...)
	tinsert(self.values, self:_entry(value, ...))
	-- todo : limit in some way so not called on every update
	self:_prune()
end

--- @return Models.Snapshot
function Metric:Snapshot()
	return Snapshot(self)
end

--- @class Models.Timer
local Timer = AddOn.Package('Models'):Class('Timer', Metric)
--- @return Models.Timer
function Timer:initialize(name)
	Metric.initialize(self, name)
end

function Timer:_entry(value, ...)
	local v = Timer.super:_entry(value, ...)
	-- 1 == success, 0 == failure
	v.r = Util.Objects.Default(select(1, ...), true) and 1 or 0
	return v
end

function Timer:Time(fn, ...)
	local start = debugprofilestop()
	local success, result = pcall(fn, ...)
	self:Update(debugprofilestop() - start, success)
	if not success then
		error(result)
	end
	return result
end

function Timer:Timed(fn)
	return function(...)
		self:Time(fn, ...)
	end
end


--- @class Models.Metrics
local Metrics = AddOn.Package('Models'):Class('Metrics')
--- @return Models.Metrics
function Metrics:initialize(group)
	self.group = group
	self.metrics = {

	}
end

function Metrics:_metric(class, name, ...)
	local metric = self.metrics[name]
	if not metric then
		metric = class(name, ...)
		self.metrics[name] = metric
	end
	return metric
end

--- @return Models.Timer
function Metrics:Timer(name)
	return self:_metric(Timer, name)
end

function Metrics:Summarize()
	local s = {
		[self.group] = {}
	}

	for n, m in pairs(self.metrics) do
		s[self.group][n] = m:Snapshot():Summarize()[n]
	end

	return s
end

function Snapshot:initialize(metric)
	self.name = metric.name
	self.values = Util.Tables.Copy(metric.values)
	-- we can cache these values as this is copy and
	-- values will not mutate
	self.min = -1
	self.max = -1
	self.count = #self.values
	self.sum = -1
	self.median = -1
	self.ss = -1
end

function Snapshot:Count()
	return self.count
end

function Snapshot:Min()
	if self.min == -1 and self.count > 0 then
		self.min = Util.Tables.Min(Util.Tables.Copy(self.values, function(v) return v.v end))
	end

	return math.max(self.min, 0)
end

function Snapshot:Max()
	if self.max == -1 and self.count > 0 then
		self.max = Util.Tables.Max(Util.Tables.Copy(self.values, function(v) return v.v end))
	end

	return math.max(self.max, 0)
end

function Snapshot:Sum()
	if self.sum == -1  then
		local sum = 0
		for _, v in pairs(self.values) do
			sum = sum + v.v
		end
		self.sum = sum
	end

	return self.sum
end

function Snapshot:Mean()
	return self:Sum() / self:Count()
end

function Snapshot:Quantile(q)
	assert(q >= 0 and q <= 1, "quantile must be between 0 and 1")

	-- deep copy table so that when we sort it, the original is unchanged
	local t = {}
	for _,v in  pairs(self.values) do table.insert(t, v.v) end
	table.sort(t)

	local position = #t * q + 0.5
	local mod = position % 1
	if position < 1 then
		return t[1]
	elseif position > #t then
		return t[#t]
	elseif mod == 0 then
		return t[position]
	else
		return mod * t[math.ceil(position)] + (1 - mod) * t[math.floor(position)]
	end
end

function Snapshot:Median()
	if self.median == -1 then
		self.median = self:Quantile(0.5)
	end

	return self.median
end

function Snapshot:SumSquares()
	if self.ss == -1 then
		local mean, sum = self:Mean(), 0
		for _,v in  pairs(self.values) do
			sum = sum + ((v.v - mean)^2)
		end
		self.ss = sum
	end
	return self.ss
end

function Snapshot:Var()
	return self:SumSquares() / (self:Count() - 1)
end

function Snapshot:StdDev()
	return math.sqrt(self:Var())
end

--- this is values recorded per second (cannot be more precise based upon available clock)
function Snapshot:Rate()
	local delta = 0
	if self:Count() >= 2 then
		delta = self.values[self:Count()].t - self.values[1].t
	else
		delta = 0
	end
	-- we're limited to second precision so bump up to 1 second if
	-- less than that tick has elapsed
	return self:Count() / math.max(delta, 1.0)
end

local NaN = "-nan(ind)"

function Snapshot:Summarize()
	local function ValueOrZero(v)
		return Util.Objects.Check(tostring(v) == NaN, 0, v)
	end

	return {
		[self.name] = {
			count  = self:Count(),
			sum    = self:Sum(),
			min    = ValueOrZero(self:Min()),
			max    = ValueOrZero(self:Max()),
			mean   = ValueOrZero(self:Mean()),
			median = ValueOrZero(self:Median()),
			stddev = ValueOrZero(self:StdDev()),
			rate   = ValueOrZero(self:Rate()),
		}
	}
end