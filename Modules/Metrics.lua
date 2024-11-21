--- @type AddOn
local _, AddOn = ...
local L = AddOn.Locale
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @type Core.Event
local Event = AddOn.RequireOnUse('Core.Event')
--- @type Core.Message
local Message = AddOn.RequireOnUse('Core.Message')

--- @class Metrics
local Metrics = AddOn:NewModule("Metrics")

local MetricsType = {
	Comms  = 1,
	Events = 2,
	Messages = 3,
}

Metrics.MetricsType = MetricsType

function Metrics:GetMetrics(metricType)
	--- @type table<number, Models.Metrics>
	local rawMetrics
	if Util.Objects.Equals(metricType, MetricsType.Comms) then
		rawMetrics = Comm():GetMetrics()
	elseif Util.Objects.Equals(metricType, MetricsType.Events) then
		rawMetrics = Event():GetMetrics()
	elseif Util.Objects.Equals(metricType, MetricsType.Messages) then
		rawMetrics = Message():GetMetrics()
	end

	local metrics = {}
	if rawMetrics then
		for _, metric in pairs(rawMetrics) do
			Util.Tables.Push(metrics, metric:Summarize())
		end
	end

	return metrics
end

function Metrics:LaunchpadSupplement()
	return L["metrics"], function(container) self:LayoutInterface(container) end, false
end