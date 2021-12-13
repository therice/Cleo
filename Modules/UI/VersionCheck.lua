--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.ScrollingTable.ColumnBuilder
local STColumnBuilder = AddOn.Package('UI.ScrollingTable').ColumnBuilder
--- @type UI.ScrollingTable.CellBuilder
local STCellBuilder = AddOn.Package('UI.ScrollingTable').CellBuilder
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.ScrollingTable
local ST = AddOn.Require('UI.ScrollingTable')

--- @type VersionCheck
local VersionCheck = AddOn:GetModule("VersionCheck", true)

local ScrollColumns =
	STColumnBuilder()
			:column(""):width(20):sortnext(2)                                                       -- class icon (1)
			:column(_G.NAME):width(100):defaultsort(STColumnBuilder.Ascending)                      -- name (2)
			:column(L['version']):width(150):set('align', 'RIGHT')                                  -- version(3)
				:sortnext(2):defaultsort(STColumnBuilder.Descending)
				:comparesort(function(...) return VersionCheck.SortByVersion(...) end)
			:build()

function VersionCheck:GetFrame()
	if not self.frame then
		Logging:Trace("VersionCheck:GetFrame()")
		local f = UI:NewNamed('Frame', UIParent, 'VersionCheck', self:GetName(), L['frame_version_check'], 350, 325)
		local st = ST.New(ScrollColumns, 12, 20, nil, f)
		st:RegisterEvents({
			  ["OnEnter"] = function(rowFrame, _, data, _, row, realrow, ...)
				  if row then VersionCheck.ModeTooltip(data[realrow].mode, rowFrame.cols[3] --[[ always anchor at last column --]]) end
				  return false
			  end,
			  ["OnLeave"] = function(...)
				  VersionCheck.ModeTooltip()
				  return false
			  end,
		})

		st.frame:SetWidth(320)
		f:SetWidth(st.frame:GetWidth() + 20)

		local close = UI:New('Button', f.content)
		close:SetText(_G.CLOSE)
		close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -20)
		close:SetScript("OnClick", function() self:Disable() end)
		f.close = close

		local guild = UI:New('Button', f.content)
		guild:SetText(_G.GUILD)
		guild:SetPoint("RIGHT", f.close, "LEFT", -10, 0)
		guild:SetScript("OnClick", function() self:Query(C.guild) end)
		f.guild = guild

		local group = UI:New('Button', f.content)
		group:SetText(_G.GROUP)
		group:SetPoint("RIGHT", f.guild, "LEFT", -10, 0)
		group:SetScript("OnClick", function() self:Query(C.group) end)
		f.group = group

		f.rows = {}
		self.frame = f
	end
end

function VersionCheck:ClearEntries()
	if self.frame then
		self.frame.rows = {}
		self.frame.st:SetData(self.frame.rows)
	end
end

--- @param name string
--- @param class string
--- @param verson Models.SemanticVersion
--- @param mode Core.Mode
function VersionCheck:AddEntry(name, class, version, mode)
	name = AddOn:UnitName(name)
	Logging:Debug("AddEntry(%s) : %s, %s, %s", tostring(name), tostring(class), tostring(version), tostring(mode))
	if version and (self.mostRecentVersion < version) then
		self.mostRecentVersion = version
	end

	local function Row(name, class, version, mode)
		return {
			name    = name,
			class   = class,
			version = version,
			mode    = mode,
			cols    = STCellBuilder()
						:classIconCell(class)
						:classColoredCell(name, class)
						:cell(version and tostring(version) or L["waiting_for_response"])
							:DoCellUpdate(ST.DoCellUpdateFn(function(...) VersionCheck.SetCellVersion(...) end))
						:build()
		}
	end

	local rows = self.frame.rows
	for i, v in ipairs(rows) do
		if AddOn.UnitIsUnit(v.name, name) then
			rows[i] = Row(v.name, class, version, mode)
			return self:Update()
		end
	end

	Util.Tables.Push(
		rows,
		Row(name, class, version, mode)
	)
	self:Update()
end

--- @param verson Models.SemanticVersion
--- @param mode Core.Mode
function VersionCheck.GetVersionColor(version, mode)
	if mode and mode:Enabled(C.Modes.Develop) then return C.Colors.RogueYellow end
	if version and (version == VersionCheck.mostRecentVersion) then return C.Colors.Green end
	if version and (version < VersionCheck.mostRecentVersion) then return C.Colors.DeathKnightRed end
	return C.Colors.Aluminum
end

local ModeDecorator = UIUtil.ColoredDecorator(C.Colors.LuminousYellow)
local ModeTooltipDecorator = UIUtil.ColoredDecorator(C.Colors.Green)

function VersionCheck.ModeTooltip(mode, parent)
	if mode then
		local modes = {}
		for k, v in pairs(C.Modes) do
			if v ~= C.Modes.Standard and mode:Enabled(v) then
				Util.Tables.Push(modes, ModeDecorator:decorate(tostring(k)))
			end
		end

		UIUtil.ShowTooltip(parent, "ANCHOR_RIGHT", ModeTooltipDecorator:decorate(L['modes'] .. '\n'), unpack(modes))
	else
		UIUtil:HideTooltip()
	end
end

function VersionCheck.SetCellVersion(_, frame, data, _, _, realrow, column, ...)
	local r = data[realrow]
	local version, mode = r.version, r.mode
	Logging:Trace("SetCellVersion() : version=%s / mode=%s / value=%s", tostring(version), tostring(mode), tostring(r.cols[column].value))
	frame.text:SetText(version and tostring(version) or r.cols[column].value)
	frame.text:SetTextColor(VersionCheck.GetVersionColor(version, mode):GetRGBA())
end

VersionCheck.SortByVersion =
	ST.SortFn(
		function(row)
			return row.version or VersionCheck.VersionZero
		end
	)

function VersionCheck:QueryTimer()
	Logging:Trace("QueryTimer()")
	if self.frame then
		for k, _ in pairs(self.frame.rows) do
			local cell = self.frame.st:GetCell(k, 3)
			if cell and Util.Strings.Equal(cell.value,  L["waiting_for_response"]) then
				cell.value = L["not_installed"]
			end
		end

		self:Update()
	end
end

function VersionCheck:Update()
	if self.frame then
		self.frame.st:SortData()
	end
end

function VersionCheck:Show()
	if self.frame then
		self.frame:Show()
		self.frame.st:SetData(self.frame.rows)
	end
end

function VersionCheck:Hide()
	if self.frame then
		self.frame:Hide()
		self.frame.rows = {}
	end
end