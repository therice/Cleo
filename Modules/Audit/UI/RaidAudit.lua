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

local ScrollColumns =
		ST.ColumnBuilder()
			:column(""):width(20)                                                       -- 1 (via class icon)
				:sortnext(2)
			:column(L['via']):width(100)                                                        -- 2 (via name)
				:sortnext(3):defaultsort(STColumnBuilder.Ascending)
			:column(L['date']):width(125)                                                       -- 3 (date)
				:defaultsort(STColumnBuilder.Descending):sort(STColumnBuilder.Descending)
				:comparesort(function(...) return RA.SortByTimestamp(...) end)
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

local FilterSelection = {
	dates = nil,
	instance = nil,
	encounter = nil,
	Clear = function(self)
		self.dates = nil
		self.instance = nil
		self.encounter = nil
	end
}

local DateFilterColumns, InstanceFilterColumns, EncounterFilterColumns  =
	ST.ColumnBuilder():column(L['date']):width(80)
	  :sort(STColumnBuilder.Descending):defaultsort(STColumnBuilder.Descending)
	  :comparesort(ST.SortFn(function(row) return Util.Tables.Max(row.timestamps) end))
	  :build(),
	ST.ColumnBuilder():column(L['instance']):width(125):sort(STColumnBuilder.Ascending):build(),
	ST.ColumnBuilder():column(L['encounter']):width(250):sort(STColumnBuilder.Ascending):build()

local RightClickMenu

function RA:LayoutInterface(container)
	-- grab a reference to self for later use
	local module = self
	container:SetWide(1000)

	RightClickMenu = MSA_DropDownMenu_Create(C.DropDowns.RaidAuditActions, container)
	RightClickMenu.module = module
	MSA_DropDownMenu_Initialize(RightClickMenu, self.RightClickMenu)

	local st = ST.New(ScrollColumns, 20, 20, nil, container)
	st:RegisterEvents({
		["OnClick"] = function(_, cellFrame, data, _, row, realrow, _, _, button, ...)
		  if button == C.Buttons.Left and row then
		      MI.Update(container, data, realrow)
		  elseif button == C.Buttons.Right then
		      MSA_ToggleDropDownMenu(1, nil, RightClickMenu, cellFrame, 0, 0)
		  end

		  return false
		end,
	})
	st.frame:SetPoint("TOPLEFT", container.banner, "TOPLEFT", 10, -200)
	st.frame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -15, 0)
	st:SetFilter(function(...) return self:FilterFunc(...) end)
	st:EnableSelection(true)

	MI.EmbedWidgets(self:GetName(), container, function(...) self:UpdateMoreInfo(...) end)
	container.moreInfoBtn:SetPoint("TOPRIGHT", container.banner, "TOPRIGHT", -5, -25)

	container.date = ST.New(DateFilterColumns, 5, 20, nil, container, false)
	container.date.frame:SetPoint("TOPLEFT", container.banner, "TOPLEFT", 10, -50)
	container.date:EnableSelection(true)
	container.date:RegisterEvents({
      ["OnClick"] = function(_, _, data, _, row, realrow, _, _, button, ...)
          if button == C.Buttons.Left and row then
              FilterSelection.dates = data[realrow].timestamps or nil
              self:Update()
          end
          return false
      end
	})

	container.dateClear =
		UI:New('ButtonClose', container)
		  :Point("BOTTOMRIGHT", container.date.frame, "TOPRIGHT", 5, 5)
		  :Size(18,18)
		  :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['date'])))
		  :OnClick(
			function(self)
				FilterSelection.dates = nil
				self:GetParent().date:ClearSelection()
				module:Update()
			end
		)

	container.instance = ST.New(InstanceFilterColumns, 5, 20, nil, container, false)
	container.instance.frame:SetPoint("TOPLEFT", container.date.frame, "TOPRIGHT", 20, 0)
	container.instance:EnableSelection(true)
	container.instance:RegisterEvents({
        ["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
            if button == C.Buttons.Left and row then
	            FilterSelection.instance = data[realrow].instanceId or nil
                self:Update()
            end
            return false
        end
    })

	container.instanceClear =
		UI:New('ButtonClose', container)
		  :Point("BOTTOMRIGHT", container.instance.frame, "TOPRIGHT", 5, 5)
		  :Size(18,18)
		  :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['encounter'])))
		  :OnClick(
			function(self)
				FilterSelection.instance = nil
				self:GetParent().instance:ClearSelection()
				module:Update()
			end
		)

	container.encounter = ST.New(EncounterFilterColumns, 5, 20, nil, container, false)
	container.encounter.frame:SetPoint("TOPLEFT", container.instance.frame, "TOPRIGHT", 20, 0)
	container.encounter:EnableSelection(true)
	container.encounter:RegisterEvents({
       ["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
           if button == C.Buttons.Left and row then
               FilterSelection.encounterId = data[realrow].encounterId or nil
               self:Update()
           end
           return false
       end
    })

	container.encounterClear =
		UI:New('ButtonClose', container)
		  :Point("BOTTOMRIGHT", container.encounter.frame, "TOPRIGHT", 5, 5)
		  :Size(18,18)
		  :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['encounter'])))
		  :OnClick(
			function(self)
				FilterSelection.encounterId = nil
				self:GetParent().encounter:ClearSelection()
				module:Update()
			end
		)

	container:SetScript("OnShow", function(self) module:BuildData(self) end)
	self.interfaceFrame = container
end

function RA:FilterFunc(_, row)

	local function SelectionFilter(entry)
		local include = true

		if Util.Tables.IsSet(FilterSelection.dates) then
			include = Util.Tables.ContainsValue(FilterSelection.dates, entry.timestamp)
		end

		if include and Util.Objects.IsSet(FilterSelection.instance) then
			include = (entry.instanceId == FilterSelection.instance)
		end

		if include and Util.Objects.IsNumber(FilterSelection.encounterId) then
			include = entry.encounterId == FilterSelection.encounterId
		end

		return include
	end

	return SelectionFilter(row.entry)
end

function RA:RefreshData()
	if self:IsEnabled() and self.interfaceFrame and self.interfaceFrame:IsVisible() then
		self:BuildData(self.interfaceFrame)
	end
end

local cpairs = CDB.static.pairs

function RA:BuildData(container)
	container.rows = {}

	local tsData, instanceData, encounterData = {}, {}, {}

	for row, entryData in cpairs(self:GetHistory()) do
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
					:cell(""):DoCellUpdate(ST.DoCellUpdateFn(function(...) RA.SetCellResult(...) end))
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
							self.interfaceFrame.st:SortData()
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

function RA:Update()
	local interfaceFrame = self.interfaceFrame
	if interfaceFrame then
		interfaceFrame.st:SortData()
	end
end

function RA.SetCellResult(_, frame, data, _, _, realrow, column, ...)
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

RA.SortByTimestamp =
	ST.SortFn(
	function(row)
		return row.entry:TimestampAsDate()
	end
)

local MaxPlayers = 40

function RA:UpdateMoreInfo(f, data, row)
	local proceed, entry = MI.Context(f, data, row, 'entry')
	if proceed then
		local tip, playerCount = f.moreInfo, Util.Tables.Count(entry.players)
		tip:SetOwner(f, "ANCHOR_RIGHT")
		tip:AddDoubleLine(L["members"], playerCount)
		tip:AddLine(" ")

		local shown, class, name, color = 0, nil, nil, nil

		for _, member in pairs(Util.Tables.Sort(entry.players, function (p1, p2) return p1[2] < p2[2] end)) do
			if shown < MaxPlayers then
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

local RightClickMenuEntriesBuilder =
	DropDown.EntryBuilder()
		-- level 1
        :nextlevel()
            :add():text(L["delete"]):set('isTitle', true):checkable(false):disabled(true)
            :add():text(L["older_than"]):value("DELETE_OLDER_THAN"):checkable(false):arrow(true)
		-- level 2
            :nextlevel()
                :add():set('special', "DELETE_OLDER_THAN")
RA.RightClickMenuEntries = RightClickMenuEntriesBuilder:build()
RA.RightClickMenu = DropDown.RightClickMenu(
	Util.Functions.True,
	RA.RightClickMenuEntries,
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
					self:RefreshData()
				end
				MSA_DropDownMenu_AddButton(info, level)
				info = MSA_DropDownMenu_CreateInfo()
			end
		end
	end
)