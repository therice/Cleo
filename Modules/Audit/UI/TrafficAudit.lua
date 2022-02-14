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
local STCellBuilder = AddOn.Package('UI.ScrollingTable').CellBuilder
--- @type UI.MoreInfo
local MI = AddOn.Require('UI.MoreInfo')
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type Models.CompressedDb
local CDB = AddOn.Package('Models').CompressedDb
--- @type Models.Player
local Player = AddOn.Package('Models').Player
--- @type Models.Audit.TrafficRecord
local TrafficRecord = AddOn.ImportPackage('Models.Audit').TrafficRecord
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')

--- @type TrafficAudit
local TrafficAudit = AddOn:GetModule("TrafficAudit", true)

local FilterSelection = {dates = nil, action = nil, resource = nil}

local ScrollColumns =
	ST.ColumnBuilder()
		:column(""):width(20)                                                                   -- 1 (actor class icon)
        :column(L['actor']):width(100)                                                          -- 2 (actor)
        :column(L['date']):width(125)                                                           -- 3 (date)
            :defaultsort(STColumnBuilder.Descending):sort(STColumnBuilder.Descending)
            :comparesort(function(...) return TrafficAudit.SortByTimestamp(... )end)
		:column(""):width(20)                                                                   -- 6 (loot icon)
		:column(L['action']):width(50)                                                          -- 4 (action)
		:column(L['resource']):width(75)                                                        -- 5 (resource)
		:column(L['name']):width(150)                                                           -- 7 (resource name)
		:column(L['attribute']):width(75)                                                       -- 8 (resource attribute)
		:column(L['value']):width(200)                                                          -- 9 (resource attribute value)
		:column(""):width(20)                                                                   -- 10 (delete icon)
    :build()

local DateFilterColumns, ActionFilterColumns, ResourceFilterColumns  =
	ST.ColumnBuilder():column(L['date']):width(80)
		:sort(STColumnBuilder.Descending):defaultsort(STColumnBuilder.Descending)
		:comparesort(ST.SortFn(function(row) return Util.Tables.Max(row.timestamps) end))
		:build(),
	ST.ColumnBuilder():column(L['action']):width(50):sort(STColumnBuilder.Ascending):build(),
	ST.ColumnBuilder():column(L['resource']):width(75):sort(STColumnBuilder.Ascending):build()

local ActionTypesForDisplay, ResourceTypesForDisplay = {}, {}

do
	for key, value in pairs(TrafficRecord.ActionType) do
		Util.Tables.Push(
			ActionTypesForDisplay,
			{
				{ value = key, name = key, DoCellUpdate = ST.DoCellUpdateFn(function(_, frame, ...) TrafficAudit.SetAction(frame,  _, _, _, value) end)},
			}
		)
	end

	for key, value in pairs(TrafficRecord.ResourceType) do
		Util.Tables.Push(
			ResourceTypesForDisplay,
			{
				{ value = key, name = key, DoCellUpdate = ST.DoCellUpdateFn(function(_, frame, ...) TrafficAudit.SetResource(frame,  _, _, _, value) end)},
			}
		)
	end
end

function TrafficAudit:LayoutInterface(container)
	Logging:Debug("LayoutInterface(%s)", tostring(container:GetName()))

	-- grab a reference to self for later use
	local module = self
	container:SetWide(1000)

	local st = ST.New(ScrollColumns, 20, 20, nil, container)
	st:RegisterEvents({
		["OnClick"] = function(_, cellFrame, data, _, row, realrow, _, _, button, ...)
			if button == C.Buttons.Left and row then
				MI.Update(container, data, realrow)
		    elseif button == C.Buttons.Right then
				-- MSA_ToggleDropDownMenu(1, nil, FilterMenu, cellFrame, 0, 0)
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

	container.action = ST.New(ActionFilterColumns, 5, 20, nil, container, false)
	container.action.frame:SetPoint("TOPLEFT", container.date.frame, "TOPRIGHT", 20, 0)
	container.action:EnableSelection(true)
	container.action:RegisterEvents({
      ["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
          if button == C.Buttons.Left and row then
	          FilterSelection.action = data[realrow][column].name or nil
              self:Update()
          end
          return false
      end
    })

	container.actionClear =
		UI:New('ButtonClose', container)
	        :Point("BOTTOMRIGHT", container.action.frame, "TOPRIGHT", 5, 5)
	        :Size(18,18)
	        :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['action'])))
	        :OnClick(
				function(self)
					FilterSelection.action = nil
					self:GetParent().action:ClearSelection()
					module:Update()
				end
			)

	container.resource = ST.New(ResourceFilterColumns, 5, 20, nil, container, false)
	container.resource.frame:SetPoint("TOPLEFT", container.action.frame, "TOPRIGHT", 20, 0)
	container.resource:EnableSelection(true)
	container.resource:RegisterEvents({
        ["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
            if button == C.Buttons.Left and row then
                FilterSelection.resource = data[realrow][column].name or nil
                self:Update()
            end
            return false
        end
    })

	container.resourceClear =
		UI:New('ButtonClose', container)
		  :Point("BOTTOMRIGHT", container.resource.frame, "TOPRIGHT", 5, 5)
		  :Size(18,18)
		  :Tooltip(format(L["clear_x_filter"], Util.Strings.Lower(L['action'])))
		  :OnClick(
				function(self)
					FilterSelection.resource = nil
					self:GetParent().resource:ClearSelection()
					module:Update()
				end
		)


	container:SetScript("OnShow", function(self) module:BuildData(self) end)
	self.interfaceFrame = container
end

TrafficAudit.SortByTimestamp =
	ST.SortFn(
		function(row)
			return row.entry:TimestampAsDate()
		end
	)


function TrafficAudit:FilterFunc(_, row)
	--Logging:Trace("FilterFunc() : %s", Util.Objects.ToString(FilterSelection))
	--local settings = AddOn:ModuleSettings(self:GetName())

	local function SelectionFilter(entry)
		local include = true
		-- Logging:Debug("%s", Util.Objects.ToString(FilterSelection))
		if Util.Tables.IsSet(FilterSelection.dates) then
			include = Util.Tables.ContainsValue(FilterSelection.dates, entry.timestamp)
		end

		if include and Util.Objects.IsSet(FilterSelection.action) then
			include =  entry.action == TrafficRecord.ActionType[FilterSelection.action]
		end

		if include and Util.Strings.IsSet(FilterSelection.resource) then
			include =  entry:GetResourceType() == TrafficRecord.ResourceType[FilterSelection.resource]
		end

		return include
	end

	local entry = row.entry
	local selectionFilter = SelectionFilter(entry)

	return selectionFilter
end

function TrafficAudit:RefreshData()
	if self:IsEnabled() and self.interfaceFrame and self.interfaceFrame:IsVisible() then
		self:BuildData(self.interfaceFrame)
	end
end

local cpairs = CDB.static.pairs
function TrafficAudit:BuildData(container)
	local LM = AddOn:ListsModule()

	container.rows = {}
	local tsData = {}
	for row, entryData in cpairs(self:GetHistory()) do
		--- @type Models.Audit.TrafficRecord
		local entry = TrafficRecord:reconstitute(entryData)

		container.rows[row] = {
			num = row,
			entry = entry,
			-- just load all of the associated resources, they'll be needed at some point
			resources = {LM:GetService():LoadAuditRefs(entry)},
			cols =
				STCellBuilder()
					:playerIconAndColoredNameCell(entry.actor) -- this adds two columns (icon and name)
					:cell(entry:FormattedTimestamp() or "")
					:cell(""):DoCellUpdate(ST.DoCellUpdateFn(function(...) self:SetCellLootRecord(...) end))
					:cell(entry.action):DoCellUpdate(ST.DoCellUpdateFn(function(...) TrafficAudit.SetCellAction(...) end))
					:cell(entry:GetResourceType()):DoCellUpdate(ST.DoCellUpdateFn(function(...) TrafficAudit.SetCellResource(...) end))
					:cell(""):DoCellUpdate(ST.DoCellUpdateFn(function(...) TrafficAudit.SetCellResourceName(...) end))
					:cell(""):DoCellUpdate(ST.DoCellUpdateFn(function(...) TrafficAudit.SetCellResourceAttribute(...) end))
					:cell(""):DoCellUpdate(ST.DoCellUpdateFn(function(...) TrafficAudit.SetCellResourceAttributeValue(...) end))
					:deleteCell(
						function(_, d, r)
							local num = d[r].num
							Logging:Debug("TrafficHistory : Deleting %s", tostring(num))
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
	end

	container.st:SetData(container.rows)
	container.date:SetData(Util.Tables.Values(tsData), true)
	container.action:SetData(ActionTypesForDisplay, true)
	container.resource:SetData(ResourceTypesForDisplay, true)
end

function TrafficAudit:Update()
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

function TrafficAudit.SetCellAction(_, frame, data, _, _, realrow, column, _)
	TrafficAudit.SetAction(frame, data, realrow, column, data[realrow].entry.action)
end

function TrafficAudit.SetAction(frame, data, realrow, column, actionType)
	actionType = actionType or data[realrow][column].args[1]
	frame.text:SetText(TrafficRecord.TypeIdToAction[actionType])
	frame.text:SetTextColor(UIUtil.GetActionTypeColor(actionType):GetRGB())
end

function TrafficAudit.SetCellResource(_, frame, data, _, _, realrow, column, _)
	TrafficAudit.SetResource(frame, data, realrow, column, data[realrow].entry:GetResourceType())
end

function TrafficAudit.SetResource(frame, data, realrow, column, resourceType)
	resourceType = resourceType or data[realrow][column].args[1]
	frame.text:SetText(TrafficRecord.TypeIdToResource[resourceType])
	frame.text:SetTextColor(UIUtil.GetResourceTypeColor(resourceType):GetRGB())
end

function TrafficAudit.SetCellResourceName(_, frame, data, _, _, realrow, column, _)
	local resources, entry, resource = data[realrow].resources, data[realrow].entry, nil

	if entry:GetResourceType() == TrafficRecord.ResourceType.Configuration then
		resource = resources[1]
	elseif entry:GetResourceType() == TrafficRecord.ResourceType.List then
		resource = resources[2]
	end

	-- Logging:Trace("%s", Util.Objects.ToString(resource and resource:toTable() or {}))
	if resource then
		frame.text:SetText(resource.name)
		frame.text:SetTextColor(C.Colors.White:GetRGB())
	else
		frame.text:SetText(L['unknown'])
		frame.text:SetTextColor(C.Colors.Aluminum:GetRGB())
	end
end

function TrafficAudit.SetCellResourceAttribute(_, frame, data, _, _, realrow, column, _)
	local record = data[realrow].entry
	if Util.Objects.In(record.action, TrafficRecord.ActionType.Create, TrafficRecord.ActionType.Delete) then
		frame.text:SetText(L["na"])
	else
		-- we could do a mapping here from attribute name to text
		-- right now it just shows the actual name from the code (with uppercase first letter)
		frame.text:SetText(Util.Strings.UcFirst(record:GetModifiedAttribute()))
	end
end

function TrafficAudit.SetCellResourceAttributeValue(_, frame, data, _, _, realrow, column, _)
	local record = data[realrow].entry
	if Util.Objects.In(record.action, TrafficRecord.ActionType.Create, TrafficRecord.ActionType.Delete) then
		frame.text:SetText(L["na"])
		frame.text:SetFont(frame.text:GetFont(), 11)
		frame.text:SetTextColor(C.Colors.White:GetRGB())
	else
		local value = record:GetModifiedAttributeValue()
		if Util.Objects.IsTable(value) then
			frame.text:SetText("...")
			frame.text:SetFont(frame.text:GetFont(), 16)
			frame.text:SetTextColor(C.Colors.ItemArtifact:GetRGB())
		else
			frame.text:SetText(Util.Objects.ToString(value))
			frame.text:SetFont(frame.text:GetFont(), 11)
			frame.text:SetTextColor(C.Colors.White:GetRGB())
		end

	end
end

function TrafficAudit:SetCellLootRecord(_, frame, data, _, _, realrow, _, _)
	local record = data[realrow].entry
	local playerId, lrId = record:GetLootRecord()
	if playerId and lrId then

		local player = Player.Resolve(playerId)

		frame:SetNormalTexture(133784)
		frame:GetNormalTexture():SetTexCoord(0,1,0,1)
		frame:SetScript(
			"OnEnter",
			function(f)
				UIUtil.ShowTooltip(
					f, nil,
					format(
						L['item_awarded_to_click_to_view'],
						UIUtil.PlayerClassColorDecorator(player:GetName()):decorate(player:GetShortName())
					)
				)
			end
		)
		frame:SetScript("OnLeave", function() UIUtil:HideTooltip() end)
		frame:SetScript(
			"OnClick",
			function()
				-- select the loot audit tab
				AddOn:LootAuditModule():SelectRecord(player:GetName(), lrId)
				self.interfaceFrame:GetLaunchPad()
					:SetModuleIndex(self.interfaceFrame.moduleIndex - 2)
			end
		)
	else
		frame:SetNormalTexture(nil)
		frame:SetScript("OnEnter", nil)
		frame:SetScript("OnLeave", nil)
		frame:SetScript("OnClick", nil)
	end
end

local ColorConfiguration, ColorList, ColorUnknown =
	{UIUtil.GetResourceTypeColor(TrafficRecord.ResourceType.Configuration):GetRGB()},
	{UIUtil.GetResourceTypeColor(TrafficRecord.ResourceType.List):GetRGB()},
	{C.Colors.Aluminum:GetRGB()}

local AttributeChangeHandlers = {
	['permissions'] = function(tip, player, permissions)
		local c = UIUtil.GetPlayerClassColor(player:GetShortName())
		-- Logging:Debug("%s", Util.Objects.ToString(c))
		tip:AddDoubleLine(
			AddOn.Ambiguate(player),
			permissions,
			c.r, c.g, c.b, 1, 1, 1
		)
	end,
	['equipment'] = function(tip, index, equipment)
		if equipment then
			tip:AddLine(equipment, 0.12, 1.00, 0.00)
		else
			tip:AddLine(format("%s [#%s]", L['removed'], tostring(index)), 0.99216, 0.48627, 0.43137)
		end
	end,
	['players'] = function(tip, priority, player)
		local c = player and UIUtil.GetPlayerClassColor(player:GetShortName()) or C.Colors.Aluminum
		tip:AddDoubleLine(
			format("%s #%s", L['priority'], tostring(priority)),
			player and AddOn.Ambiguate(player) or L['unknown'],
			1, 1, 1,
			c.r, c.g, c.b
		)
	end,
	['alts'] = function(tip, main, alts)
		-- Logging:Debug("%s => %s", tostring(main), Util.Objects.ToString(alts))

		local c = main and UIUtil.GetPlayerClassColor(main:GetShortName()) or C.Colors.Aluminum
		tip:AddLine(
			main and AddOn.Ambiguate(main) or L['unknown'],
			c.r, c.g, c.b
		)

		local removed, added = 0, {}
		for _, alt in pairs(alts) do
			if Util.Objects.IsBoolean(alt) and not alt then
				removed = removed + 1
			else
				Util.Tables.Push(added, alt)
			end
		end

		for _, alt in pairs(added) do
			c = alt and UIUtil.GetPlayerClassColor(alt:GetShortName()) or C.Colors.Aluminum
			tip:AddDoubleLine(
				L['added'],
				alt and AddOn.Ambiguate(alt) or L['unknown'],
				1, 1, 1,
				c.r, c.g, c.b
			)
		end

		if removed > 0 then
			tip:AddDoubleLine(
				L['removed'],
				tostring(removed),
				1, 1, 1,
				1, 1, 1
			)
		end
	end
}

function TrafficAudit:UpdateMoreInfo(f, data, row)
	local proceed, entry = MI.Context(f, data, row, 'entry')
	local resources
	if proceed then
		proceed, resources = MI.Context(f, data, row, 'resources')
	end

	if proceed then
		local function GetNameColor(resource)
			if resource then
				return 1, 1, 1
			else
				return unpack(ColorUnknown)
			end
		end

		local resourceType, config, list = entry:GetResourceType(), resources[1], resources[2]

		local tip = f.moreInfo
		tip:SetOwner(f, "ANCHOR_RIGHT")

		-- everything is attached to a configuration
		tip:AddDoubleLine(
			L['configuration'],
			config and config.name or L['unknown'],
			ColorConfiguration[1], ColorConfiguration[2], ColorConfiguration[3],
			GetNameColor(config)
		)

		-- if a list, add additional contet
		if resourceType == TrafficRecord.ResourceType.List then
			tip:AddDoubleLine(
				L['list'],
				list and list.name or L['unknown'],
				ColorList[1], ColorList[2], ColorList[3],
				GetNameColor(list)
			)
		end

		tip:AddLine(" ")
		tip:AddLine(L['version'])
		tip:AddLine(" ")

		local refs = {entry:GetResource(), entry.ref}
		local refCount = Util.Tables.Count(refs)
		-- iterate through associated resources (after and before)
		-- adding versioning information (hash and revision)
		for _, attr in pairs({'hash', 'revision'}) do
			for index, ref in pairs(refs) do
				tip:AddDoubleLine(
					L[attr] .. (refCount == 1 and '' or format(" (%s)", (index == 1 and L['after'] or L['before']))),
					ref[attr],
					0.90, 0.80, 0.50,
					1, 1, 1
				)
			end
		end


		if entry:ParseableModification() then
			local parser = AttributeChangeHandlers[entry:GetModifiedAttribute()]
			if parser then
				tip:AddLine(" ")
				tip:AddLine(L['changes'])
				tip:AddLine(" ")
				entry:ParseModification(function(k, v) parser(tip, k, v) end)
			end
		end

		tip:Show()
		tip:SetAnchorType("ANCHOR_RIGHT", 0, -tip:GetHeight())
	end
end