--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.ScrollingTable
local ST = AddOn.Require('UI.ScrollingTable')
--- @type UI.ScrollingTable.ColumnBuilder
local STColumnBuilder = AddOn.Package('UI.ScrollingTable').ColumnBuilder
--- @type UI.ScrollingTable.CellBuilder
local STCellBuilder = AddOn.Package('UI.ScrollingTable').CellBuilder

--- @type Metrics
local Metrics = AddOn:GetModule('Metrics')

local Tabs = {
	[L["metrics_comms"]]    = L["metrics_comms_desc"],
	[L["metrics_events"]]   = L["metrics_events_desc"],
	[L["metrics_messages"]] = L["metrics_messages_desc"],
}

function Metrics:LayoutInterface(container)
	Logging:Debug("LayoutInterface(%s)", tostring(container:GetName()))

	container.tabs =
		UI:New('Tabs', container, unpack(Util.Tables.Sort(Util.Tables.Keys(Tabs))))
			:Point(0, -36):Size(1000, 580):SetTo(1)
	container.tabs:SetBackdropBorderColor(0, 0, 0, 0)
	container.tabs:SetBackdropColor(0, 0, 0, 0)
	container.tabs:First():SetPoint("TOPLEFT", 0, 20)

	for index, description in pairs(Util.Tables.Values(Tabs)) do
		container.tabs.tabs[index]:Tooltip(description)
	end

	self:LayoutMetricsTab(container.tabs:Get(1), self.MetricsType.Comms)
	self:LayoutMetricsTab(container.tabs:Get(2), self.MetricsType.Events)
	self:LayoutMetricsTab(container.tabs:Get(3), self.MetricsType.Messages)

	self.interfaceFrame = container
end

-- sorting here may be borked, particularly on updates
local ScrollColumns =
	STColumnBuilder()
        :column(L["category"]):width(175)
			:sort(STColumnBuilder.Ascending)
			:sortnext(2)
        :column(L["metric"]):width(100)
			:defaultsort(STColumnBuilder.Ascending)
			:sortnext(3)
        :column(L["count"]):width(45)
			:defaultsort(STColumnBuilder.Descending)
			:sortnext(4)
		:column(format("%s (ms)", L["min"])):width(60)
			:defaultsort(STColumnBuilder.Descending)
			:sortnext(5)
		:column(format("%s (ms)", L["max"])):width(60)
			:defaultsort(STColumnBuilder.Descending)
			:sortnext(6)
        :column(format("%s (ms)", L["mean"])):width(60)
			:defaultsort(STColumnBuilder.Descending)
			:sortnext(7)
        :column(format("%s (ms)", L["median"])):width(60)
			:defaultsort(STColumnBuilder.Descending)
			:sortnext(8)
		:column(format("%s (ms)", L["stddev"])):width(60)
			:defaultsort(STColumnBuilder.Descending)
			:sortnext(9)
        :column(format("%s (per sec)", L["rate"])):width(85)
			:defaultsort(STColumnBuilder.Descending)
			:sortnext(10)
		:column(format("%s (ms)", L["sum"])):width(60)
			:defaultsort(STColumnBuilder.Descending)
    :build()


-- build data, refresh

function Metrics:LayoutMetricsTab(tab, type)
	tab.metricType = type

	local st = ST.New(ScrollColumns, 12, 20, nil, tab)
	st.frame:ClearAllPoints()
	st.frame:SetHeight(240)
	st.frame:SetWidth(800)
	st.frame:SetPoint("TOPLEFT", tab:GetParent():GetParent().banner, "BOTTOMLEFT", 20, -50)
	st:EnableSelection(true)

	local refresh = UI:New('ButtonRefresh', tab)
	refresh:SetSize(18,18)
	refresh:SetPoint("BOTTOMRIGHT", st.frame, "TOPRIGHT", 0, 10)
	refresh:SetScript("OnClick", function() self:BuildScrollingTable(tab) end)
	tab.refresh = refresh

	tab:SetScript("OnShow", function(t) self:BuildScrollingTable(t) end)
end

function Metrics:BuildScrollingTable(tab)
	local st = tab.st
	if st then
		local rows, row, metrics = {}, 1, self:GetMetrics(tab.metricType)
		for  _, metricGroup in pairs(metrics) do
			for category, categoryMetrics in pairs(metricGroup) do
				for metricName, metric in pairs(categoryMetrics) do
					-- Logging:Debug("BuildData(%d) : %s/%s => %s", self.metricType, category, metricName, Util.Objects.ToString(metric))
					rows[row] = {
						num = row,
						cols =
							STCellBuilder()
								:cell(metricName):color(C.Colors.Salmon)
								:cell(Util.Strings.Split(Util.Strings.FromCamelCase(category), " ")[3]):color(C.Colors.MageBlue)
								:cell(metric.count or 0)
								:cell(metric.min and Util.Numbers.Round(metric.min, 2) or 0)
								:cell(metric.max and Util.Numbers.Round(metric.max, 2) or 0)
								:cell(metric.mean and Util.Numbers.Round(metric.mean, 2) or 0)
								:cell(metric.median and Util.Numbers.Round(metric.median, 2) or 0)
								:cell(metric.stddev and Util.Numbers.Round(metric.stddev, 2) or 0)
								:cell(metric.rate and Util.Numbers.Round(metric.rate, 2) or 0)
								:cell(metric.sum and Util.Numbers.Round(metric.sum, 2) or 0)
							:build()
					}

					row = row + 1
				end
			end
		end

		st:SetData(rows)
		st:SortData()
		st:SortData()
	end
end