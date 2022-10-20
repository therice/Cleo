--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.ScrollingTable
local ST = AddOn.Require('UI.ScrollingTable')
--- @type UI.ScrollingTable.ColumnBuilder
local STColumnBuilder = AddOn.Package('UI.ScrollingTable').ColumnBuilder
--- @type UI.ScrollingTable.CellBuilder
local STCellBuilder = AddOn.Package('UI.ScrollingTable').CellBuilder
--- @type Models.CompressedDb
local CDB = AddOn.Package('Models').CompressedDb
--- @type Models.Audit.RaidRosterRecord
local RaidRosterRecord = AddOn.ImportPackage('Models.Audit').RaidRosterRecord
--- @type UI.MoreInfo
local MI = AddOn.Require('UI.MoreInfo')
--- @type UI.DropDown
local DropDown = AddOn.Require('UI.DropDown')
--- @type LibEncounter
local LibEncounter = AddOn:GetLibrary("Encounter")
--- @type Models.Audit.Audit
local Audit = AddOn.Package('Models.Audit').Audit

--- @type RaidAudit
local RA = AddOn:GetModule("RaidAudit", true)

local TrackingTypeDesc = {
	[RA.TrackingType.EncounterStart]       = L["encounter_start"],
	[RA.TrackingType.EncounterEnd]         = L["encounter_end"],
	[RA.TrackingType.EncounterStartAndEnd] = L["encounter_start_and_end"],
}

local TrackingTypeSort = { }

do
	local index = 1
	for _, v in Util.Tables.OrderedPairs(Util.Tables.Flip(TrackingTypeDesc)) do
		TrackingTypeSort[index] = v
		index = index + 1
	end
end

local cpairs = CDB.static.pairs

function RA:LayoutConfigSettings(container)
	local module = self

	container:Tooltip(L["attendance_desc"])
	container.enabled =
		UI:New('Checkbox', container, L["track_attendance"], false)
			:Point(20, -25)
	        :TextSize(12)
	        :Tooltip(L["track_attendance_desc"])
	        :Datasource(
				module,
				module.db.profile,
				'enabled',
				nil,
				function(value) container.trackingType:SetEnabled(value) end
			)
	container.enabled:SetSize(14, 14)

	container.trackingTypeLabel =
		UI:New('Text', container, L["tracking_type"])
	        :Point("TOPLEFT", container.enabled, "BOTTOMLEFT", 0, -15)
	container.trackingType =
		UI:New('Dropdown', container, nil, container:GetWidth() / 3, #TrackingTypeDesc)
			:Tooltip(L["tracking_type_desc"])
			:Point("TOPLEFT", container.trackingTypeLabel, "BOTTOMLEFT", 0, -7)
			:SetList(Util.Tables.Copy(TrackingTypeDesc), TrackingTypeSort)
			:Datasource(
				module,
				module.db.profile,
				'trackingType'
			)
end


local TabContainer = AddOn.Class('TabContainer')
function TabContainer:initialize(tab)
	self.tab = tab
end

local Tabs = {
	[L["raids"]]             = L["attendance_audit"],
	[L["raid_stats"]]        = L["raid_stats_desc"],
	[L["raid_player_stats"]] = L["raid_player_stats_desc"],
}

function RA:LayoutInterface(container)
	container:SetWide(1000)
	container.tabs =
		UI:New('Tabs', container, unpack(Util.Tables.Sort(Util.Tables.Keys(Tabs))))
	        :Point(0, -36):Size(1000, 597):SetTo(3)
	container.tabs:SetBackdropBorderColor(0, 0, 0, 0)
	container.tabs:SetBackdropColor(0, 0, 0, 0)
	container.tabs:First():SetPoint("TOPLEFT", 0, 20)

	for index, key in ipairs(Util.Tables.Sort(Util.Tables.Keys(Tabs))) do
		container.tabs.tabs[index]:Tooltip(Tabs[key])
	end

	self:LayoutRaidTab(container.tabs:GetByName(L['raids']))
	self:LayoutRaidStatsTab(container.tabs:GetByName(L['raid_stats']))
	self:LayoutPlayerStatsTab(container.tabs:GetByName(L['raid_player_stats']))

	self.interfaceFrame = container
end

function RA:Refresh()
	if not self:IsEnabled() then
		return
	end

	local ok, msg = pcall(
		function()
			if self.interfaceFrame then
				if self.raidTab:IsVisible() then
					self.raidTab:Refresh()
				end

				if self.raidStatsTab:IsVisible() then
					self.raidStatsTab:Refresh()
				end
			end
		end
	)


	if not ok then
		Logging:Error("Refresh() : %s", tostring(msg))
	end
end


local RaidTab = AddOn.Class('RaidTab', TabContainer)
function RaidTab:initialize(tab)
	TabContainer.initialize(self, tab)
end

local RaidScrollColumns =
		ST.ColumnBuilder()
			:column(""):width(20)                                                       -- 1 (via class icon)
				:sortnext(2)
			:column(L['via']):width(100)                                                        -- 2 (via name)
				:sortnext(3):defaultsort(STColumnBuilder.Ascending)
			:column(L['date']):width(125)                                                       -- 3 (date)
				:defaultsort(STColumnBuilder.Descending):sort(STColumnBuilder.Descending)
				:comparesort(function(...) return RaidTab.SortByTimestamp(...) end)
			:column(L["instance"]):width(125)                                                   -- 4 (instance)
				:defaultsort(STColumnBuilder.Ascending):sort(STColumnBuilder.Descending)
			:column(L["encounter"]):width(250)                                                  -- 5 (encounter)
				:defaultsort(STColumnBuilder.Ascending):sort(STColumnBuilder.Descending)
			:column(L["difficulty"]):width(50)                                                  -- 6 (difficulty)
			:column(L["members"]):width(50)                                                     -- 7 (members)
			:column(L['phase']):width(50)                                                       -- 8 (phase)
			:column(L['result']):width(50)                                                      -- 9 (result)
			:column(""):width(20)                                                               -- 10 (delete icon)
		:build()

local RaidFilterSelection = {
	dates = nil,
	instance = nil,
	encounter = nil,
	Clear = function(self)
		self.dates = nil
		self.instance = nil
		self.encounter = nil
	end
}

local RaidDateFilterColumns, RaidInstanceFilterColumns, RaidEncounterFilterColumns =
	ST.ColumnBuilder()
		:column(L['date']):width(80)
	    :sort(STColumnBuilder.Descending):defaultsort(STColumnBuilder.Descending)
	    :comparesort(ST.SortFn(function(row) return Util.Tables.Max(row.timestamps) end))
		:build(),
	ST.ColumnBuilder():column(L['instance']):width(125):sort(STColumnBuilder.Ascending):build(),
	ST.ColumnBuilder():column(L['encounter']):width(250):sort(STColumnBuilder.Ascending):build()

local RaidRightClickMenu

function RA:LayoutRaidTab(tab)
	tab:SetPoint("BOTTOMRIGHT", tab:GetParent(), "BOTTOMRIGHT", 0, 0)

	-- grab a reference to self for later use
	local module, raidTab = self, RaidTab(tab)

	RaidRightClickMenu = MSA_DropDownMenu_Create(C.DropDowns.RaidAuditActions, tab)
	RaidRightClickMenu.module = module
	MSA_DropDownMenu_Initialize(RaidRightClickMenu, self.RaidRightClickMenu)

	local st = ST.New(RaidScrollColumns, 20, 20, nil, tab)
	st:RegisterEvents({
		["OnClick"] = function(_, cellFrame, data, _, row, realrow, _, _, button, ...)
		  if button == C.Buttons.Left and row then
		      MI.Update(tab, data, realrow)
		  elseif button == C.Buttons.Right then
		      MSA_ToggleDropDownMenu(1, nil, RaidRightClickMenu, cellFrame, 0, 0)
		  end

		  return false
		end,
	})
	st.frame:SetPoint("TOPLEFT", tab:GetParent(), "TOPLEFT", 10, -180)
	st.frame:SetPoint("BOTTOMRIGHT", tab:GetParent(), "BOTTOMRIGHT", -15, 0)
	st:SetFilter(function(...) return raidTab:FilterFunc(...) end)
	st:EnableSelection(true)

	MI.EmbedWidgets(self:GetName(), tab, function(f, data, row) raidTab:UpdateMoreInfo(f, data, row, tab:GetParent()) end)
	tab.moreInfoBtn:SetPoint("TOPRIGHT", tab:GetParent(), "TOPRIGHT", -7, -5)

	tab.date = ST.New(RaidDateFilterColumns, 5, 20, nil, tab, false)
	tab.date.frame:SetPoint("TOPLEFT", tab:GetParent(), "TOPLEFT", 10, -30)
	tab.date:EnableSelection(true)
	tab.date:RegisterEvents({
      ["OnClick"] = function(_, _, data, _, row, realrow, _, _, button, ...)
          if button == C.Buttons.Left and row then
              RaidFilterSelection.dates = data[realrow].timestamps or nil
	          raidTab:Update()
          end
          return false
      end
	})

	tab.dateClear =
		UI:New('ButtonClose', tab)
		  :Point("BOTTOMRIGHT", tab.date.frame, "TOPRIGHT", 5, 5)
		  :Size(18,18)
		  :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['date'])))
		  :OnClick(
			function(self)
				RaidFilterSelection.dates = nil
				self:GetParent().date:ClearSelection()
				raidTab:Update()
			end
		)

	tab.instance = ST.New(RaidInstanceFilterColumns, 5, 20, nil, tab, false)
	tab.instance.frame:SetPoint("TOPLEFT", tab.date.frame, "TOPRIGHT", 20, 0)
	tab.instance:EnableSelection(true)
	tab.instance:RegisterEvents({
        ["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
            if button == C.Buttons.Left and row then
	            RaidFilterSelection.instance = data[realrow].instanceId or nil
	            raidTab:Update()
            end
            return false
        end
    })

	tab.instanceClear =
		UI:New('ButtonClose', tab)
		  :Point("BOTTOMRIGHT", tab.instance.frame, "TOPRIGHT", 5, 5)
		  :Size(18,18)
		  :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['encounter'])))
		  :OnClick(
			function(self)
				RaidFilterSelection.instance = nil
				self:GetParent().instance:ClearSelection()
				raidTab:Update()
			end
		)

	tab.encounter = ST.New(RaidEncounterFilterColumns, 5, 20, nil, tab, false)
	tab.encounter.frame:SetPoint("TOPLEFT", tab.instance.frame, "TOPRIGHT", 20, 0)
	tab.encounter:EnableSelection(true)
	tab.encounter:RegisterEvents({
       ["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
           if button == C.Buttons.Left and row then
               RaidFilterSelection.encounterId = data[realrow].encounterId or nil
	           raidTab:Update()
           end
           return false
       end
    })

	tab.encounterClear =
		UI:New('ButtonClose', tab)
		  :Point("BOTTOMRIGHT", tab.encounter.frame, "TOPRIGHT", 5, 5)
		  :Size(18,18)
		  :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['encounter'])))
		  :OnClick(
			function(self)
				RaidFilterSelection.encounterId = nil
				self:GetParent().encounter:ClearSelection()
				raidTab:Update()
			end
		)

	tab:SetScript("OnShow", function() raidTab:BuildData() end)
	self.raidTab = raidTab
end

function RaidTab:Refresh()
	if self.tab:IsVisible() then
		self:BuildData()
	end
end

function RaidTab:Update()
	if self.tab:IsVisible() then
		self.tab.st:SortData()
		self.tab.st:SortData()
	end
end

function RaidTab:FilterFunc(_, row)

	local function SelectionFilter(entry)
		local include = true

		if Util.Tables.IsSet(RaidFilterSelection.dates) then
			include = Util.Tables.ContainsValue(RaidFilterSelection.dates, entry.timestamp)
		end

		if include and Util.Objects.IsSet(RaidFilterSelection.instance) then
			include = (entry.instanceId == RaidFilterSelection.instance)
		end

		if include and Util.Objects.IsNumber(RaidFilterSelection.encounterId) then
			include = entry.encounterId == RaidFilterSelection.encounterId
		end

		return include
	end

	return SelectionFilter(row.entry)
end


function RaidTab:BuildData()
	local container = self.tab
	container.rows = {}

	local tsData, instanceData, encounterData = {}, {}, {}

	for row, entryData in cpairs(RA:GetHistory()) do
		--- @type Models.Audit.RaidRosterRecord
		local entry = RaidRosterRecord:reconstitute(entryData)
		container.rows[row] = {
			num = row,
			entry = entry,
			cols =
				STCellBuilder()
					:classAndPlayerIconColoredNameCell(unpack(entry.actor))
					:cell(entry:FormattedTimestamp() or "")
					:cell(entry:GetInstanceName())
					:cell(entry:GetEncounterName())
					:cell(entry.groupSize and entry.groupSize or 0)
					:cell(entry.players and #entry.players or 0)
					:cell(Util.Objects.IsNil(entry.success) and L["start"] or L["end"])
					:cell(""):DoCellUpdate(ST.DoCellUpdateFn(function(...) RaidTab.SetCellResult(...) end))
					:deleteCell(
						function(_, d, r)
							local num = d[r].num
							Logging:Debug("RaidHistory : Deleting %s", tostring(num))
							local history = self:GetHistory()
							history:del(num)
							tremove(d, r)
							for _, v in pairs(d) do
								if v.num >= num then
									v.num = v.num - 1
								end
							end
							container.st:SortData()
						end
					)
				:build()
		}

		local fmtDate = entry:FormattedDate()
		if not Util.Tables.ContainsKey(tsData, fmtDate) then
			tsData[fmtDate] = {entry:FormattedDate(), timestamps = {}}
		end
		Util.Tables.Push(tsData[fmtDate].timestamps, entry.timestamp)

		local instanceName = entry:GetInstanceName()
		if not Util.Tables.ContainsKey(instanceData, instanceName) then
			instanceData[instanceName] = {instanceName, instanceId = entry.instanceId}
		end

		local encounterName = entry:GetEncounterName()
		if not Util.Tables.ContainsKey(encounterData, encounterName) then
			encounterData[encounterName] = {encounterName, encounterId = entry.encounterId}
		end
	end

	container.st:SetData(container.rows)
	container.date:SetData(Util.Tables.Values(tsData), true)
	container.instance:SetData(Util.Tables.Values(instanceData), true)
	container.encounter:SetData(Util.Tables.Values(encounterData), true)
end


function RaidTab.SetCellResult(_, frame, data, _, _, realrow, column, ...)
	local record = data[realrow].entry
	local result
	if  Util.Objects.IsNil(record.success) then
		result = ""
	else
		result = record.success and
			UIUtil.ColoredDecorator(C.Colors.Green):decorate(L["kill"]) or
			UIUtil.ColoredDecorator(C.Colors.DeathKnightRed):decorate(L["defeat"])
	end

	frame.text:SetText(result)
	data[realrow].cols[column].value = result
end

RaidTab.SortByTimestamp =
	ST.SortFn(
	function(row)
		return row.entry:TimestampAsDate()
	end
)

function RaidTab:UpdateMoreInfo(f, data, row, anchor)
	local proceed, entry = MI.Context(f, data, row, 'entry')
	if proceed then
		local tip, playerCount = f.moreInfo, Util.Tables.Count(entry.players)
		tip:SetOwner(anchor, "ANCHOR_RIGHT")
		tip:AddDoubleLine(L["members"], playerCount)
		tip:AddLine(" ")

		local shown, class, name, color = 0, nil, nil, nil

		for _, member in pairs(Util.Tables.Sort(entry.players, function (p1, p2) return p1[2] < p2[2] end)) do
			if shown < 40 then
				class, name = unpack(member)
				color = UIUtil.GetClassColor(class)
				tip:AddLine(AddOn.Ambiguate(name), color.r, color.g, color.b)
				shown = shown + 1
			else
				tip:AddLine("... (" .. tostring(playerCount - shown) .. " more)")
				break
			end
		end

		tip:Show()
		tip:SetAnchorType("ANCHOR_RIGHT", 0, -tip:GetHeight())
	end
end

local RaidRightClickMenuEntriesBuilder =
	DropDown.EntryBuilder()
		-- level 1
        :nextlevel()
            :add():text(L["delete"]):set('isTitle', true):checkable(false):disabled(true)
            :add():text(L["older_than"]):value("DELETE_OLDER_THAN"):checkable(false):arrow(true)
		-- level 2
        :nextlevel()
            :add():set('special', "DELETE_OLDER_THAN")
RaidTab.RaidRightClickMenuEntries = RaidRightClickMenuEntriesBuilder:build()
RaidTab.RaidRightClickMenu = DropDown.RightClickMenu(
	Util.Functions.True,
	RaidTab.RaidRightClickMenuEntries,
	function(info, menu, level, entry, value)
		--- @type RaidAudit
		local self = menu.module
		if Util.Strings.Equal(value, "DELETE_OLDER_THAN") and Util.Strings.Equal(entry.special, value) then
			for _, days in pairs({7, 30, 60, 90, 120, 365}) do
				info.text = format(L['n_days'], days)
				info.checkable = false
				info.arg1 = days
				info.func = function(_, ageInDays)
					self:Delete(ageInDays)
					self:Refresh()
				end
				MSA_DropDownMenu_AddButton(info, level)
				info = MSA_DropDownMenu_CreateInfo()
			end
		end
	end
)

local RaidStatsTab = AddOn.Class('RaidStatsTab', TabContainer)
function RaidStatsTab:initialize(tab)
	TabContainer.initialize(self, tab)
end

local RaidStatsScrollColumns =
	ST.ColumnBuilder()
		:column(L["instance"]):width(125)
			:sortnext(2):defaultsort(STColumnBuilder.Ascending)
		:column(L["encounter"]):width(250)
			:sortnext(6):defaultsort(STColumnBuilder.Ascending)
		:column(L["kills"]):width(60)
		:column(L["defeats"]):width(60)
		:column(L["total"]):width(60)
		:column(L["success_rate"]):width(125)
	:build()

local RaidStatsFilterSelection = {
	interval = nil,
	instance = nil,
	encounter = nil,
	Clear = function(self)
		self.interval = nil
		self.instance = nil
		self.encounter = nil
	end
}

local RaidStatsIntervalFilterColumns =
	ST.ColumnBuilder()
        :column(L['date_range']):width(80)
        :sort(STColumnBuilder.Ascending):defaultsort(STColumnBuilder.Ascending)
		:comparesort(ST.SortFn(function(row) return row.v end))
        :build()

function RA:LayoutRaidStatsTab(tab)

	tab:SetPoint("BOTTOMRIGHT", tab:GetParent(), "BOTTOMRIGHT", 0, 0)

	local raidStatsTab =  RaidStatsTab(tab)

	local st = ST.New(RaidStatsScrollColumns, 20, 20, nil, tab)
	st.frame:SetPoint("TOPLEFT", tab:GetParent(), "TOPLEFT", 10, -180)
	st.frame:SetPoint("BOTTOMRIGHT", tab:GetParent(), "BOTTOMRIGHT", -15, 0)
	st:SetFilter(function(...) return raidStatsTab:FilterFunc(...) end)
	st:EnableSelection(true)

	tab.interval = ST.New(RaidStatsIntervalFilterColumns, 5, 20, nil, tab, false)
	tab.interval.frame:SetPoint("TOPLEFT", tab:GetParent(), "TOPLEFT", 10, -30)
	tab.interval:EnableSelection(true)
	tab.interval:RegisterEvents({
        ["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
			if button == C.Buttons.Left and row then
				RaidStatsFilterSelection.interval = data[realrow].v or nil
				raidStatsTab:Refresh()
			end
			return false
		end
	})

	local intervals = {}
	for _, interval in pairs({7, 14, 30, 60, 90}) do
		Util.Tables.Push(intervals, {format("%s %s", L['past'], format(L['n_days'], interval)), v = interval})
	end
	tab.interval:SetData(intervals, true)

	tab.intervalClear =
		UI:New('ButtonClose', tab)
	        :Point("BOTTOMRIGHT", tab.interval.frame, "TOPRIGHT", 5, 5)
	        :Size(18,18)
	        :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['date_range'])))
	        :OnClick(
				function(self)
					RaidStatsFilterSelection.interval = nil
					self:GetParent().interval:ClearSelection()
					raidStatsTab:Refresh()
				end
			)

	tab.instance = ST.New(RaidInstanceFilterColumns, 5, 20, nil, tab, false)
	tab.instance.frame:SetPoint("TOPLEFT", tab.interval.frame, "TOPRIGHT", 20, 0)
	tab.instance:EnableSelection(true)
	tab.instance:RegisterEvents({
        ["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
            if button == C.Buttons.Left and row then
                RaidStatsFilterSelection.instance = data[realrow].instanceId or nil
                raidStatsTab:Update()
            end
            return false
        end
    })

	tab.instanceClear =
		UI:New('ButtonClose', tab)
		  :Point("BOTTOMRIGHT", tab.instance.frame, "TOPRIGHT", 5, 5)
		  :Size(18,18)
		  :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['encounter'])))
		  :OnClick(
			function(self)
				RaidStatsFilterSelection.instance = nil
				self:GetParent().instance:ClearSelection()
				raidStatsTab:Update()
			end
		)

	tab.encounter = ST.New(RaidEncounterFilterColumns, 5, 20, nil, tab, false)
	tab.encounter.frame:SetPoint("TOPLEFT", tab.instance.frame, "TOPRIGHT", 20, 0)
	tab.encounter:EnableSelection(true)
	tab.encounter:RegisterEvents({
         ["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
             if button == C.Buttons.Left and row then
	             RaidStatsFilterSelection.encounterId = data[realrow].encounterId or nil
	             raidStatsTab:Update()
             end
             return false
         end
     })

	tab.encounterClear =
		UI:New('ButtonClose', tab)
		  :Point("BOTTOMRIGHT", tab.encounter.frame, "TOPRIGHT", 5, 5)
		  :Size(18,18)
		  :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['encounter'])))
		  :OnClick(
			function(self)
				RaidStatsFilterSelection.encounterId = nil
				self:GetParent().encounter:ClearSelection()
				raidStatsTab:Update()
			end
		)

	tab:SetScript("OnShow", function() raidStatsTab:BuildData() end)
	self.raidStatsTab = raidStatsTab
end

function RaidStatsTab:Refresh()
	if self.tab:IsVisible() then
		self:BuildData()
		self:Update()
	end
end

function RaidStatsTab:Update()
	if self.tab:IsVisible() then
		self.tab.st:SortData()
		self.tab.st:SortData()
	end
end

function RaidStatsTab:FilterFunc(_, row)
	local function SelectionFilter(row)
		local include = true

		if include and Util.Objects.IsSet(RaidStatsFilterSelection.instance) then
			include = (row.instanceId == RaidStatsFilterSelection.instance)
		end

		if include and Util.Objects.IsNumber(RaidStatsFilterSelection.encounterId) then
			include = row.encounterId == RaidStatsFilterSelection.encounterId
		end

		return include
	end

	return SelectionFilter(row)
end

function RaidStatsTab:BuildData(intervalInDays)
	intervalInDays = tonumber(intervalInDays) or RaidStatsFilterSelection.interval or 30
	Logging:Debug("BuildData(%d)", intervalInDays)
	local container = self.tab
	container.rows = {}

	local row, instanceData, encounterData, raidStats = 1, {}, {}, RA:GetRaidStatistics(intervalInDays)

	local function AddRow(instanceId, encounterId, stats)
		local instanceName, encounterName =
			LibEncounter:GetMapName(instanceId),
			(encounterId and stats.name or L["all"])

		if not Util.Tables.ContainsKey(instanceData, instanceName) then
			instanceData[instanceName] = {instanceName, instanceId = instanceId}
		end

		if not Util.Tables.ContainsKey(encounterData, encounterName) then
			encounterData[encounterName] = {encounterName, encounterId = encounterId or -1}
		end

		return STCellBuilder()
					:cell(instanceName)
					:cell(encounterName)
					:cell(stats.victories)
					:cell(stats.defeats)
					:cell(stats.total)
					:cell(""):DoCellUpdate(ST.DoCellUpdateFn(function(...) RaidStatsTab.SetCellPercent(...) end))
				:build()
	end

	for instanceId, istats in pairs(raidStats.instances) do
		container.rows[row] = {
			entry = istats,
			instanceId = instanceId,
			encounterId = -1,
			cols  = AddRow(instanceId, nil, istats)
		}
		row = row + 1

		for encounterId, estats in pairs(istats.encounters) do
			container.rows[row] = {
				entry = estats,
				instanceId = instanceId,
				encounterId = encounterId,
				cols = AddRow(instanceId, encounterId, estats)
			}

			row = row + 1
		end
	end

	container.st:SetData(container.rows)
	container.instance:SetData(Util.Tables.Values(instanceData), true)
	container.encounter:SetData(Util.Tables.Values(encounterData), true)
end

function RaidStatsTab.SetCellPercent(_, frame, data, _, _, realrow, column, ...)
	local stats = data[realrow].entry
	frame.text:SetText(format("%d%%", Util.Numbers.Round(stats.pct, 2) * 100))
	data[realrow].cols[column].value = stats.pct
end

local PlayerStatsTab = AddOn.Class('PlayerStatsTab', TabContainer)
function PlayerStatsTab:initialize(tab)
	TabContainer.initialize(self, tab)
end

local PlayerStatsScrollColumns =
	ST.ColumnBuilder()
		:column(""):width(20)
            :sortnext(2)
		:column(L['player']):width(200)
			:defaultsort(STColumnBuilder.Ascending)
			:sortnext(5)
		:column(format("%s %s", L['raids'], L['attended'])):width(100)
		:column(format("%s %s", L['total'], L['raids'])):width(100)
		:column(L['attendance']):width(100)
			:defaultsort(STColumnBuilder.Descending)
			:sortnext(6)
		:column(L['last_raid_date']):width(250)
			:defaultsort(STColumnBuilder.Descending)
			:comparesort(function(...) return PlayerStatsTab.SortByTimestamp(...) end)
    :build()


local PlayerStatsFilterSelection = {
	interval = nil,
	Clear = function(self)
		self.interval = nil
	end
}

local PlayerStatsIntervalFilterColumns =
	ST.ColumnBuilder()
		:column(L['date_range']):width(80)
	    :sort(STColumnBuilder.Ascending):defaultsort(STColumnBuilder.Ascending)
	    :comparesort(ST.SortFn(function(row) return row.v end))
    :build()

function RA:LayoutPlayerStatsTab(tab)
	tab:SetPoint("BOTTOMRIGHT", tab:GetParent(), "BOTTOMRIGHT", 0, 0)

	local playerStatsTab = PlayerStatsTab(tab)

	local st = ST.New(PlayerStatsScrollColumns, 20, 20, nil, tab)
	st.frame:SetPoint("TOPLEFT", tab:GetParent(), "TOPLEFT", 10, -180)
	st.frame:SetPoint("BOTTOMRIGHT", tab:GetParent(), "BOTTOMRIGHT", -15, 0)
	st:SetFilter(function(...) return playerStatsTab:FilterFunc(...) end)
	st:EnableSelection(true)

	tab.interval = ST.New(PlayerStatsIntervalFilterColumns, 5, 20, nil, tab, false)
	tab.interval.frame:SetPoint("TOPLEFT", tab:GetParent(), "TOPLEFT", 10, -30)
	tab.interval:EnableSelection(true)
	tab.interval:RegisterEvents({
        ["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
            if button == C.Buttons.Left and row then
	            PlayerStatsFilterSelection.interval = data[realrow].v or nil
	            playerStatsTab:Refresh()
            end
            return false
        end
    })

	local intervals = {}
	for _, interval in pairs({7, 14, 30, 60, 90}) do
		Util.Tables.Push(intervals, {format("%s %s", L['past'], format(L['n_days'], interval)), v = interval})
	end
	tab.interval:SetData(intervals, true)

	tab.intervalClear =
		UI:New('ButtonClose', tab)
			:Point("BOTTOMRIGHT", tab.interval.frame, "TOPRIGHT", 5, 5)
			:Size(18,18)
			:Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['date_range'])))
			:OnClick(
				function(self)
					PlayerStatsFilterSelection.interval = nil
					self:GetParent().interval:ClearSelection()
					playerStatsTab:Refresh()
				end
			)

	tab:SetScript("OnShow", function() playerStatsTab:BuildData() end)
	self.playerStatsTab = playerStatsTab
end

function PlayerStatsTab:Refresh()
	if self.tab:IsVisible() then
		self:BuildData()
		self:Update()
	end
end

function PlayerStatsTab:Update()
	if self.tab:IsVisible() then
		self.tab.st:SortData()
		self.tab.st:SortData()
	end
end

function PlayerStatsTab:FilterFunc(_, row)
	return true
end

function PlayerStatsTab:BuildData(intervalInDays)
	intervalInDays = tonumber(intervalInDays) or PlayerStatsFilterSelection.interval or 30
	Logging:Debug("BuildData(%d)", intervalInDays)
	local container = self.tab
	container.rows = {}

	local row, playerStats = 0, RA:GetAttendanceStatistics(intervalInDays)
	for p, stats in pairs(playerStats.players) do
		container.rows[row] = {
			entry = stats,
			cols =
				STCellBuilder()
					:playerIconAndColoredNameCell(p)
					:cell(stats.count)
					:cell(playerStats.total)
					:cell(""):DoCellUpdate(ST.DoCellUpdateFn(function(...) PlayerStatsTab.SetCellPercent(...) end))
					:cell(Audit.ShortDf:format(stats.lastRaid))
				:build()
		}

		row = row + 1
	end

	container.st:SetData(container.rows)
end

PlayerStatsTab.SortByTimestamp =
	ST.SortFn(
	function(row)
		return row.entry.lastRaid
	end
)

function PlayerStatsTab.SetCellPercent(_, frame, data, _, _, realrow, column, ...)
	local stats = data[realrow].entry
	frame.text:SetText(format("%d%%", Util.Numbers.Round(stats.pct, 2) * 100))
	data[realrow].cols[column].value = stats.pct
end