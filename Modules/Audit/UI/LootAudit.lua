--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.ScrollingTable
local ST = AddOn.Require('UI.ScrollingTable')
--- @type UI.ScrollingTable.ColumnBuilder
local STColumnBuilder = AddOn.Package('UI.ScrollingTable').ColumnBuilder
--- @type UI.ScrollingTable.CellBuilder
local  STCellBuilder = AddOn.Package('UI.ScrollingTable').CellBuilder
--- @type UI.MoreInfo
local MI = AddOn.Require('UI.MoreInfo')
--- @type UI.DropDown
local DropDown = AddOn.Require('UI.DropDown')
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type Models.CompressedDb
local CDB = AddOn.Package('Models').CompressedDb
--- @type Models.Audit.LootRecord
local LootRecord = AddOn.Package('Models.Audit').LootRecord
--- @type LibEncounter
local LibEncounter = AddOn:GetLibrary("Encounter")
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")

--- @type LootAudit
local LootAudit = AddOn:GetModule("LootAudit", true)

local ScrollColumns =
	ST.ColumnBuilder()
        :column(""):width(20):sortnext(2)                                                    -- 1 (class icon)
        :column(_G.NAME):width(100):sortnext(3):defaultsort(STColumnBuilder.Ascending)              -- 2 (player name)
        :column(L['date']):width(125)                                                               -- 3 (date)
			:defaultsort(STColumnBuilder.Descending):sort(STColumnBuilder.Descending)
			:comparesort(function(...) return LootAudit.SortByTimestamp(...) end)
        :column(L['instance']):width(125)                                                           -- 4 (instance)
			:defaultsort(STColumnBuilder.Descending):sort(STColumnBuilder.Descending)
		:column(L['list']):width(125)                                                               -- 5 (list)
			:defaultsort(STColumnBuilder.Descending):sort(STColumnBuilder.Descending)
        :column(""):width(20)                                                                       -- 6 (item icon)
        :column(L['item']):width(200)                                                               -- 7 (item string)
			:defaultsort(STColumnBuilder.Ascending):sortnext(2)
            :comparesort(function(...) return LootAudit.SortByItem(...) end)
        :column(L['reason']):width(200)                                                             -- 8 (response)
			:defaultsort(STColumnBuilder.Ascending):sortnext(2)
            :comparesort(function(...) return LootAudit.SortByResponse(...) end)
        :column(""):width(20)                                                                       -- 9 (delete icon)
  :build()

local DateFilterColumns, InstanceFilterColumns, NameFilterColumns, DroppedByFilterColumns =
	ST.ColumnBuilder():column(L['date']):width(80)
		:sort(STColumnBuilder.Descending):defaultsort(STColumnBuilder.Descending)
		:comparesort(ST.SortFn(function(row) return Util.Tables.Max(row.timestamps) end))
		:build(),
	ST.ColumnBuilder():column(L['instance']):width(100):sort(STColumnBuilder.Ascending):build(),
	ST.ColumnBuilder():column(""):width(20):column(_G.NAME):width(100):sort(STColumnBuilder.Ascending):build(),
	ST.ColumnBuilder():column(L['dropped_by']):width(200):sort(STColumnBuilder.Ascending):build()

local RightClickMenu, FilterSelection, RecordSelection = nil,
	{
		dates = nil,
		instance = nil,
		name = nil,
		encounterId = nil,
		Clear = function(self)
			self.dates = nil
			self.instance = nil
			self.name = nil
			self.encounterId = nil
		end
	},
	{
		player = nil,
		id = nil,
		IsSet = function(self)
			return self.player and self.id
		end,
		Clear = function(self)
			self.player = nil
			self.id = nil
		end
	}

function LootAudit:LayoutInterface(container)
	Logging:Debug("LayoutInterface(%s)", tostring(container:GetName()))

	-- grab a reference to self for later use
	local module = self
	container:SetWide(1000)

	RightClickMenu = MSA_DropDownMenu_Create(C.DropDowns.LootAuditActions, container)
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

	-- todo : apply multi-selection on filter tables?
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

	container.name = ST.New(NameFilterColumns, 5, 20, nil, container, false)
	container.name.frame:SetPoint("TOPLEFT", container.date.frame, "TOPRIGHT", 20, 0)
	container.name:EnableSelection(true)
	container.name:RegisterEvents({
		["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
			if button == C.Buttons.Left and row then
				FilterSelection.name = data[realrow][column].name or nil
				self:Update()
			end
			return false
		end
	})

	container.nameClear =
		UI:New('ButtonClose', container)
		  :Point("BOTTOMRIGHT", container.name.frame, "TOPRIGHT", 5, 5)
		  :Size(18,18)
		  :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['name'])))
		  :OnClick(
				function(self)
					FilterSelection.name = nil
					self:GetParent().name:ClearSelection()
					module:Update()
				end
		)

	container.instance = ST.New(InstanceFilterColumns, 5, 20, nil, container, false)
	container.instance.frame:SetPoint("TOPLEFT", container.name.frame, "TOPRIGHT", 20, 0)
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
		  :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['instance'])))
		  :OnClick(
				function(self)
					FilterSelection.instance = nil
					self:GetParent().instance:ClearSelection()
					module:Update()
				end
		)

	container.droppedBy = ST.New(DroppedByFilterColumns, 5, 20, nil, container, false)
	container.droppedBy.frame:SetPoint("TOPLEFT", container.instance.frame, "TOPRIGHT", 20, 0)
	container.droppedBy:EnableSelection(true)
	container.droppedBy:RegisterEvents({
		["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
			if button == C.Buttons.Left and row then
				FilterSelection.encounterId = data[realrow].encounterId or nil
				self:Update()
			end
			return false
		end
	})

	container.droppedByClear =
		UI:New('ButtonClose', container)
	        :Point("BOTTOMRIGHT", container.droppedBy.frame, "TOPRIGHT", 5, 5)
	        :Size(18,18)
	        :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['dropped_by'])))
	        :OnClick(
				function(self)
					FilterSelection.encounterId = nil
					self:GetParent().droppedBy:ClearSelection()
					module:Update()
				end
			)

	container.warning =
		UI:New('Text', container, L["warning_record_filter_applied"])
	        :Point("LEFT", container.banner, "LEFT", 20, 0)
	        :Color(0.99216, 0.48627, 0.43137, 0.8)
	        :Right()
	        :FontSize(12)
	        :Shadow(true)
	container.warning:Hide()

	container.recordFilterClear =
		UI:New('ButtonClose', container)
		  :Point("LEFT", container.warning, "RIGHT", 0, 0)
		  :Size(18,18)
		  :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['record'])))
		  :OnClick(
			function(self)
				RecordSelection:Clear()
				container.warning:Hide()
				self:Hide()
				module:Update()
			end
		)
	container.recordFilterClear:Hide()

	container:SetScript("OnShow", function(self) module:BuildData(self) end)
	self.interfaceFrame = container
end

local cpairs = CDB.static.pairs

function LootAudit:RefreshData()
	if self:IsEnabled() and self.interfaceFrame and self.interfaceFrame:IsVisible() then
		self:BuildData(self.interfaceFrame)
	end
end

function LootAudit:BuildData(container)
	local data = {}
	for name, entries in cpairs(self:GetHistory()) do
		for index, entryTable in pairs(entries) do
			local record = LootRecord:reconstitute(entryTable)
			local ts = record.timestamp

			if not Util.Tables.ContainsKey(data, ts) then
				data[ts] = {}
			end

			if not Util.Tables.ContainsKey(data[ts], name) then
				data[ts][name] = {}
			end

			if not Util.Tables.ContainsKey(data[ts][name], index) then
				data[ts][name][index] = {}
			end

			data[ts][name][index] = record
		end
	end

	table.sort(data)
	container.rows = {}

	local tsData, instanceData, nameData, droppedByData, row = {}, {}, {}, {}, 1
	for _, names in pairs(data) do
		for _, entries in pairs(names) do
			for index, entry in pairs(entries) do
				-- some strange corruption, where the entry's encounter id is a table instead of string/number
				-- just ignore them in results
				if not Util.Objects.IsTable(entry.encounterId) then
					local instanceName = LibEncounter:GetMapName(entry.instanceId) or "N/A"
					local droppedBy = AddOn.GetEncounterCreatures(entry.encounterId) or L['unknown']
					local player = AddOn.Ambiguate(entry.owner)
					container.rows[row] = {
						rownum = row,   -- this is the index in the rows table
						num = index,    -- this is the index within the player's table
						entry = entry,
						cols =
						STCellBuilder()
							:classIconCell(entry.class)
							:classColoredCell(player, entry.class)
							:cell(entry:FormattedTimestamp() or "")
							:cell(instanceName)
							:cell(entry.list)
							:itemIconCell(entry.item)
							:cell(entry.item)
							:cell(""):DoCellUpdate(ST.DoCellUpdateFn(function (...) LootAudit.SetCellResponse(...) end))
							:deleteCell(
								function(_, d, r)
									local name, num = d[r].entry.owner, d[r].num

									--Logging:Trace("LootAudit : Deleting %s, %s", tostring(name), tostring(num))

									local history = self:GetHistory()
									history:del(name, num)
									tremove(d, r)

									for _, v in pairs(d) do
										if v.name == name and v.num >= num then
											v.num = v.num - 1
										end
									end

									self.interfaceFrame.st:SortData()

									local charHistory = history:get(name)
									if #charHistory == 0 then
										--Logging:Trace("Last LootAudit entry deleted, removing %s", tostring(name))
										history:del(name)
									end
								end
							)
							:build()
					}

					-- keep a copy of all the timestamps that map to date (could probably calculate later)
					local fmtDate = entry:FormattedDate()
					if not Util.Tables.ContainsKey(tsData, fmtDate) then
						tsData[fmtDate] = {fmtDate, timestamps = {}}
					end
					Util.Tables.Push(tsData[fmtDate].timestamps, entry.timestamp)

					if not Util.Tables.ContainsKey(instanceData, instanceName) then
						instanceData[instanceName] = {instanceName, instanceId = entry.instanceId}
					end

					if not Util.Tables.ContainsKey(droppedByData, droppedBy) then
						droppedByData[droppedBy] = {droppedBy, encounterId = entry.encounterId}
					end

					if not Util.Tables.ContainsKey(nameData, player) then
						nameData[player] = {
							{ DoCellUpdate = ST.DoCellUpdateFn(function(_, frame, ...) UIUtil.ClassIconFn()(frame, entry.class) end)},
							{ value = player, color = UIUtil.GetClassColor(entry.class), name = player}
						}
					end
					row = row + 1

				end
			end
		end
	end

	-- Logging:Trace("%s", Util.Objects.ToString(container.rows, 3))

	container.st:SetData(container.rows)
	container.date:SetData(Util.Tables.Values(tsData), true)
	container.instance:SetData(Util.Tables.Values(instanceData), true)
	container.name:SetData(Util.Tables.Values(nameData), true)
	container.droppedBy:SetData(Util.Tables.Values(droppedByData), true)
end

function LootAudit:ClearFilter()
	FilterSelection:Clear()
end

function LootAudit:SelectRecord(player, id)
	self:ClearFilter()
	RecordSelection.player = player
	RecordSelection.id = id
	self.interfaceFrame.warning:Show()
	self.interfaceFrame.recordFilterClear:Show()
	self:Update()
end

function LootAudit.SetCellResponse(_, frame, data, _, _, realrow, ...)
	local entry = data[realrow].entry
	frame.text:SetText(entry.response)

	local responseId = entry:GetResponseId()
	if entry:IsCandidateResponse() then
		local response = AddOn:GetResponse(responseId)
		frame.text:SetTextColor(response.color:GetRGBA())
	else
		local response = AddOn.NonUserVisibleResponse(responseId)
		if response then
			frame.text:SetTextColor(response.color:GetRGBA())
		else
			frame.text:SetTextColor(1,1,1,1)
		end
	end
end

LootAudit.SortByTimestamp =
	ST.SortFn(
		function(row)
			return row.entry:TimestampAsDate()
		end
	)

LootAudit.SortByItem =
	ST.SortFn(
		function(row)
			return ItemUtil:ItemLinkToItemString(row.entry.item)
		end
	)

LootAudit.SortByResponse =
	ST.SortFn(
		function(row)
			return AddOn:GetResponse(row.entry:GetResponseId()).sort or 500
		end
	)

function LootAudit:FilterFunc(_, row)
	-- Logging:Trace("FilterFunc()")
	local settings = AddOn:ModuleSettings(self:GetName())

	local function SelectionFilter(entry)
		local include = true

		if Util.Tables.IsSet(FilterSelection.dates) then
			include = Util.Tables.ContainsValue(FilterSelection.dates, entry.timestamp)
		end

		if include and Util.Objects.IsNumber(FilterSelection.instance) then
			include = entry.instanceId == FilterSelection.instance
		end

		if include and Util.Objects.IsNumber(FilterSelection.encounterId) then
			include = entry.encounterId == FilterSelection.encounterId
		end

		if include and Util.Strings.IsSet(FilterSelection.name) then
			include = AddOn.UnitIsUnit(FilterSelection.name, entry.owner)
		end

		return include
	end

	local function ClassFilter(class)
		return settings.filters.class and settings.filters.class[ItemUtil:ClassTransitiveMapping(class)]
	end

	local function ResponseFilter(entry)
		local include, responseId = true, entry:GetResponseId()

		if Util.Objects.IsNumber(responseId) then
			include =  settings.filters.response and settings.filters.response[responseId]
		end

		return include
	end

	local function RecordFilter(entry)
		--Logging:Trace(
		--	"RecordFilter(%s, %s) : %s, %s",
		--	RecordSelection.player, RecordSelection.id,
		--	tostring(entry.owner), tostring(entry.id)
		--)
		return AddOn.UnitIsUnit(RecordSelection.player, entry.owner) and (entry.id == RecordSelection.id)
	end

	local entry = row.entry

	-- if there's a specific record selection, apply it
	if RecordSelection:IsSet() then
		return RecordFilter(entry)
	end

	-- otherwise, just apply the normal filter
	local selectionFilter, classFilter, responseFilter = SelectionFilter(entry), true, true
	if settings and settings.filters then
		classFilter = ClassFilter(entry.class)
		responseFilter = ResponseFilter(entry)
	end

	return selectionFilter and classFilter and responseFilter
end

local RightClickMenuEntriesBuilder =
	DropDown.EntryBuilder()
		-- level 1
		:nextlevel()
			:add():text(_G.FILTER):set('isTitle', true):checkable(false):disabled(true)
			:add():text(_G.CLASS):value("FILTER_CLASS"):checkable(false):arrow(true)
			:add():text(L["reason"]):value("FILTER_REASON"):checkable(false):arrow(true)
			:add():text(L["delete"]):set('isTitle', true):checkable(false):disabled(true)
			:add():text(L["older_than"]):value("DELETE_OLDER_THAN"):checkable(false):arrow(true)
		-- level 2
		:nextlevel()
			:add():set('special', "FILTER_CLASS")
			:add():set('special', "FILTER_REASON")
			:add():set('special', "DELETE_OLDER_THAN")

LootAudit.RightClickMenuEntries = RightClickMenuEntriesBuilder:build()
LootAudit.RightClickMenu = DropDown.RightClickMenu(
		Util.Functions.True,
		LootAudit.RightClickMenuEntries,
		function(info, menu, level, entry, value)
			local self = menu.module
			local settings = AddOn:ModuleSettings(self:GetName())
			if not settings.filters then settings.filters = {} end
			local filters = settings.filters

			local function setfilter(section, key, update)
				update = Util.Objects.Default(update, true)
				filters[section][key] = not filters[section][key]
				if update then
					self:Update()
				end
			end

			Logging:Debug("%s : %s", tostring(value), Util.Objects.ToString(entry))

			if Util.Strings.Equal(value, "FILTER_CLASS") and Util.Strings.Equal(entry.special, value) then
				-- these will be a table of sorted display class names
				local classes =
					Util(ItemUtil.ClassDisplayNameToId)
						:Keys():Sort():Copy()()

				for _, class in pairs(classes) do
					info.text = class
					info.colorCode = "|cff" .. UIUtil.GetClassColorRGB(class)
					info.keepShownOnClick = true
					info.func = function() setfilter('class', class) end
					info.checked = function() return filters.class[class] end
					MSA_DropDownMenu_AddButton(info, level)
					info = MSA_DropDownMenu_CreateInfo()
				end

				-- there is an issue here with display reflecting what is selected
				-- with the '(de)select all'
				info = MSA_DropDownMenu_CreateInfo()
				info.text = L['deselect_all']
				info.notCheckable = true
				info.keepShownOnClick = true
				info.func = function()
					for _, k in pairs(classes) do
						setfilter('class', k, false)
						MSA_DropDownMenu_SetSelectedName(RightClickMenu, k, false)
					end
					self:Update()
				end
				MSA_DropDownMenu_AddButton(info, level)
			elseif Util.Strings.Equal(value, "FILTER_REASON") and Util.Strings.Equal(entry.special, value) then
				local data = { }

				for i = 1, AddOn:GetButtonCount() do
					data[i] = i
				end

				for k in ipairs(data) do
					local r = AddOn:GetResponse(k)
					info.text = r.text
					info.keepShownOnClick = true
					info.colorCode = UIUtil.RGBToHexPrefix(r.color:GetRGB())
					info.func = function() setfilter('response', k) end
					info.checked = filters.response[k]
					MSA_DropDownMenu_AddButton(info, level)
					info = MSA_DropDownMenu_CreateInfo()
				end

				for index, r in pairs(AddOn:LootAllocateModule().db.profile.awardReasons) do
					if Util.Objects.IsNumber(index) then
						info.text = r.text
						info.keepShownOnClick = true
						info.colorCode = UIUtil.RGBToHexPrefix(r.color:GetRGB())
						info.func = function() setfilter('response', r.sort) end
						info.checked = filters.response[r.sort]
						MSA_DropDownMenu_AddButton(info, level)
						info = MSA_DropDownMenu_CreateInfo()
					end
				end
			elseif Util.Strings.Equal(value, "DELETE_OLDER_THAN") and Util.Strings.Equal(entry.special, value) then
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


function LootAudit:Update()
	--[[
	local function IsFiltering()
		local settings = AddOn:ModuleSettings(self:GetName())
		for _, v in pairs(settings.filters.class) do
			if not v then return true end
		end
		for _, v in pairs(settings.filters.response) do
			if not v then return true end
		end
		return false
	end
	--]]

	local interfaceFrame = self.interfaceFrame

	if interfaceFrame then
		interfaceFrame.st:SortData()
		--[[
		if IsFiltering() then
			interfaceFrame.filter.Text:SetTextColor(0.86,0.5,0.22) -- #db8238
		else
			interfaceFrame.filter.Text:SetTextColor(_G.NORMAL_FONT_COLOR:GetRGB()) --#ffd100
		end
		--]]
	end
end

function LootAudit:UpdateMoreInfo(f, data, row)
	local proceed, entry = MI.Context(f, data, row, 'entry')
	if proceed then
		local tip = f.moreInfo
		tip:SetOwner(f, "ANCHOR_RIGHT")
		local color = UIUtil.GetClassColor(entry.class)
		tip:AddLine(AddOn.Ambiguate(entry.owner), color.r, color.g, color.b)
		tip:AddLine(" ")
		tip:AddDoubleLine(L["date"] .. ":", entry:FormattedTimestamp() or _G.UNKNOWN, 1,1,1, 1,1,1)
		tip:AddDoubleLine(L["loot_won"] .. ":", entry.item or _G.UNKNOWN, 1,1,1, 1,1,1)
		tip:AddDoubleLine(L["dropped_by"] .. ":", AddOn.GetEncounterCreatures(entry.encounterId) or _G.UNKNOWN, 1,1,1, 0.862745, 0.0784314, 0.235294)
		tip:AddLine(" ")

		local stats, interval = self:GetStatistics():Get(entry.owner), LootAudit.StatsIntervalInDays
		if stats then
			stats:CalculateTotals()
			tip:AddLine(L["total_awards"] .. " for the past " .. tostring(interval) .. " days")
			tip:AddLine(" ")

			table.sort(
				stats.totals.responses,
	            function(a, b)
					local responseId1, responseId2 = a[3], b[3]
					return Util.Objects.IsNumber(responseId1) and Util.Objects.IsNumber(responseId2) and responseId1 < responseId2 or false
				end
			)
			-- v => {text, count, id}
			for _, v in pairs(stats.totals.responses) do
				local text, count, id = v[1], v[2], v[3]
				local r, g, b = AddOn:GetResponseColor(id)
				tip:AddDoubleLine(text, count, r, g, b, 1, 1, 1)
			end

			tip:AddLine(" ")
			tip:AddDoubleLine(L["number_of_raids_from_which_loot_was_received"] .. ":", stats.totals.raids.count, 1,1,1, 1,1,1)
			tip:AddDoubleLine(L["total_items_won"] .. ":", stats.totals.count, 1,1,1, 0,1,0)

		else
			tip:AddLine("No awards in the past " .. tostring(interval) .. " days")
		end

		tip:Show()
		tip:SetAnchorType("ANCHOR_RIGHT", 0, -tip:GetHeight())
	end
end
