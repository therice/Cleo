-- @type AddOn
local AddOnName, AddOn = ...
-- @type LibLogging
local Logging = AddOn:GetLibrary('Logging')
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
---@type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @class UI.Widgets.Tabs
local Tabs = AddOn.Package('UI.Widgets'):Class('Tabs', BaseWidget)


function Tabs:initialize(parent, name, ...)
	BaseWidget.initialize(self, parent, name)
	self.args = {...}
end

function Tabs:Create()
	local tabGroup = CreateFrame("Frame", self.name, self.parent, BackdropTemplateMixin and "BackdropTemplate")
	tabGroup:SetBackdrop(
		{
			bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 5, right = 5, top = 5, bottom = 5 }
		}
	)
	tabGroup:SetBackdropColor(0, 0, 0, 0.5)
	tabGroup.Resize = Tabs.ResizeTab
	tabGroup.Select = Tabs.SelectTab
	tabGroup.Deselect = Tabs.DeselectTab

	tabGroup.tabs = {}
	-- Logging:Debug("Tabs.Create(%s)", Util.Objects.ToString(self.args))
	local tabCount = select('#', unpack(self.args))
	for i=1,tabCount do
		local tabName = tostring(select(i, unpack(self.args)) or i)
		-- Logging:Debug("Tabs.Create(%s)", tabName)

		tabGroup.tabs[i] = CreateFrame("Frame", "Tab_" .. tabName, tabGroup)
		tabGroup.tabs[i].name = tabName
		tabGroup.tabs[i]:SetPoint("TOPLEFT", 0,0)
		tabGroup.tabs[i].Tooltip = function(self, tooltip)
			self.button.tooltip = tooltip
			return self
		end

		tabGroup.tabs[i].button = Tabs.CreateTabButton(tabGroup, tabName)
		tabGroup.tabs[i].button:SetText(tabName)
		Tabs.ResizeTab(tabGroup.tabs[i].button, 0, nil, nil, tabGroup.tabs[i].button:GetFontString():GetStringWidth(), tabGroup.tabs[i].button:GetFontString():GetStringWidth())

		tabGroup.tabs[i].button.id = i
		tabGroup.tabs[i].button.mainFrame = tabGroup
		tabGroup.tabs[i].button:SetScript("OnClick", Tabs.ButtonClick)
		tabGroup.tabs[i].button:SetScript("OnEnter", Tabs.ButtonOnEnter)
		tabGroup.tabs[i].button:SetScript("OnLeave", Tabs.ButtonOnLeave)

		if i == 1 then
			tabGroup.tabs[i].button:SetPoint("TOPLEFT", 10, 24)
		else
			tabGroup.tabs[i].button:SetPoint("LEFT", tabGroup.tabs[i-1].button, "RIGHT", 0, 0)
			tabGroup.tabs[i]:Hide()
		end

		Tabs.DeselectTab(tabGroup.tabs[i].button)
		tabGroup.tabs[i].button.Resize = Tabs.ResizeTab
		tabGroup.tabs[i].button.SetIcon = Tabs.SetTabIcon
		tabGroup.tabs[i].button.Select = Tabs.SelectTab
		tabGroup.tabs[i].button.Deselect = Tabs.DeselectTab
	end

	Tabs.SelectTab(tabGroup.tabs[1].button)

	tabGroup.tabCount = tabCount
	tabGroup.selected = 1
	tabGroup.UpdateTabs = Tabs.UpdateTabs
	tabGroup.SelectTab = Tabs.SetSelected

	BaseWidget.Mod(
		tabGroup,
		'SetTo', Tabs.SetTo,
		'First', Tabs.First,
		'Get', Tabs.Get,
		'GetByName', Tabs.GetByName,
		'IterateTabs', Tabs.IterateTabs
	)

	tabGroup._Size = tabGroup.Size
	tabGroup.Size = Tabs.SetSize

	return tabGroup
end

function Tabs.IterateTabs(self)
	return pairs(self.tabs)
end

function Tabs.Get(self, index)
	return self.tabs[index]

end
function Tabs.First(self)
	return self:Get(1)
end

function Tabs.GetByName(self, name)
	for i = 1, self.tabCount do
		if Util.Strings.Equal(self.tabs[i].name, name) then
			return self.tabs[i]
		end
	end

	return nil
end

function Tabs.SetSize(self, width, height)
	--  Logging:Debug("SetSize(%s) : %d,%d", self:GetName(), width, height)
	self:SetSize(width, height)
	for i = 1, self.tabCount do
		self.tabs[i]:SetSize(width, height)
	end
	return self
end

function Tabs.ResizeTab(self, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)
	--[[
	Logging:Debug(
			"Tabs.ResizeTab(%s) : padding=%s, absoluteSize=%s, minWidth=%s, maxWidth=%s, absoluteTextSize=%s",
			self:GetName(), tostring(padding), tostring(absoluteSize), tostring(minWidth), tostring(maxWidth), tostring(absoluteTextSize))
	--]]
	local buttonMiddle, buttonMiddleDisabled = self.Middle, self.MiddleDisabled

	if self.Icon then
		if maxWidth then
			maxWidth = maxWidth + 18
		end
		if absoluteTextSize then
			absoluteTextSize = absoluteTextSize + 18
		end
	end

	local sideWidths = 2 * self.Left:GetWidth()
	local tabText = self.Text
	local width, tabWidth
	local textWidth
	if ( absoluteTextSize ) then
		textWidth = absoluteTextSize
	else
		tabText:SetWidth(0)
		textWidth = tabText:GetWidth()
	end
	-- If there's an absolute size specified then use it
	if ( absoluteSize ) then
		if ( absoluteSize < sideWidths) then
			width = 1
			tabWidth = sideWidths
		else
			width = absoluteSize - sideWidths
			tabWidth = absoluteSize
		end
		tabText:SetWidth(width)
	else
		-- Otherwise try to use padding
		if ( padding ) then
			width = textWidth + padding
		else
			width = textWidth + 24
		end
		-- If greater than the maxWidth then cap it
		if ( maxWidth and width > maxWidth ) then
			if ( padding ) then
				width = maxWidth + padding
			else
				width = maxWidth + 24
			end
			tabText:SetWidth(width)
		else
			tabText:SetWidth(0)
		end
		if (minWidth and width < minWidth) then
			width = minWidth
		end
		tabWidth = width + sideWidths
	end

	do
		local offsetX = self.Icon and 18 or 0
		local offsetY = self.ButtonState and -2 or -3
		self.Text:SetPoint("CENTER", self, "CENTER", offsetX, offsetY)
	end

	if ( buttonMiddle ) then
		buttonMiddle:SetWidth(width)
	end
	if ( buttonMiddleDisabled ) then
		buttonMiddleDisabled:SetWidth(width)
	end

	self:SetWidth(tabWidth)
	local highlightTexture = self.HighlightTexture
	if ( highlightTexture ) then
		highlightTexture:SetWidth(tabWidth)
	end

	-- Logging:Debug("Tabs.ResizeTab(%s) : %d, %d", self:GetName(), self:GetWidth(), self:GetHeight())
end

function Tabs.SetSelected(self, id)
	-- Logging:Debug("SetSelected(%d)", tostring(id))
	self.selected = id
	self:UpdateTabs()
end

function Tabs.SetTo(self, tab)
	-- Logging:Debug("SetTo(%s)", tostring(self:GetName()))
	Tabs.ButtonClick(self.tabs[tab or 1].button)
	return self
end

function Tabs.SelectTab(self)
	-- Logging:Debug("SelectTab(%s)", tostring(self:GetName()))
	self.Left:Hide()
	self.Middle:Hide()
	self.Right:Hide()

	self:Disable()
	local offsetX = self.Icon and 8 or 0
	self.Text:SetPoint("CENTER", self, "CENTER", offsetX, -2)

	self.LeftDisabled:Show()
	self.MiddleDisabled:Show()
	self.RightDisabled:Show()

	self.ButtonState = true
end

function Tabs.DeselectTab(self)
	-- Logging:Debug("DeselectTab(%s)", tostring(self:GetName()))
	self.Left:Show()
	self.Middle:Show()
	self.Right:Show()

	self:Enable()
	local offsetX = self.Icon and 8 or 0
	self.Text:SetPoint("CENTER", self, "CENTER", offsetX, -3)

	self.LeftDisabled:Hide()
	self.MiddleDisabled:Hide()
	self.RightDisabled:Hide()

	self.ButtonState = false
end

function Tabs.SetTabIcon(self, icon)
	-- Logging:Debug("SetTabIcon(%s)", tostring(self:GetName()))

	if not icon then
		self.Icon = nil
		if self.icon then self.icon:Hide() end
		self:Resize(0, nil, nil, self:GetFontString():GetStringWidth(), self:GetFontString():GetStringWidth())
		return
	end

	if not self.icon then
		self.icon = self:CreateTexture(nil,"BACKGROUND")
		self.icon:SetSize(16,16)
		self.icon:SetPoint("LEFT",12,-3)
	end

	self.Icon = icon
	self.icon:SetTexture(icon)
	self.icon:Show()
	self:Resize(0, nil, nil, self:GetFontString():GetStringWidth(), self:GetFontString():GetStringWidth())
end

function Tabs.UpdateTabs(self)
	-- Logging:Debug("UpdateTabs(%s)", tostring(self:GetName()))

	for i=1,self.tabCount do
		if i == self.selected then
			self.tabs[i].button:Select()
		else
			self.tabs[i].button:Deselect()
		end
		self.tabs[i]:Hide()

		if self.tabs[i].disabled then
			PanelTemplates_SetDisabledTabState(self.tabs[i].button)
		end
	end

	if self.selected and self.tabs[self.selected] then
		self.tabs[self.selected]:Show()
	end

	if self.navigation then
		if self.disabled then
			self.navigation:SetEnabled(nil)
		else
			self.navigation:SetEnabled(true)
		end
	end
end

function Tabs.ButtonClick(self)
	local tabFrame = self.mainFrame
	--  Logging:Debug("ButtonClick(%s [id=%s]) : mf=%s ", tostring(self:GetName()), self.id, tostring(tabFrame:GetName()))
	tabFrame:SelectTab(self.id)

	--tabFrame.selected = self.id
	--tabFrame:UpdateTabs()

	--[[
	if tabFrame.buttonAdditionalFunc then
		tabFrame:buttonAdditionalFunc()
	end
	if self.additionalFunc then
		self:additionalFunc()
	end
	--]]
end

function Tabs.ButtonOnEnter(self)
	-- Logging:Debug("ButtonOnEnter(%s)", tostring(self.tooltip))
	if Util.Objects.IsSet(self.tooltip) then
		UIUtil.ShowTooltip(self, nil, self:GetText(), {self.tooltip, 1, 1, 1})
	end
end

function Tabs.ButtonOnLeave(self)
	UIUtil:HideTooltip()
end

function Tabs.CreateTabButton(parent, name)
	-- Logging:Debug("CreateTabButton(%s)", name)

	local tabButton = CreateFrame("Button", "TabButton_" .. name, parent)
	tabButton:SetSize(115,24)

	tabButton.LeftDisabled = tabButton:CreateTexture(nil, "BORDER")
	tabButton.LeftDisabled:SetPoint("BOTTOMLEFT", 0, -3)
	tabButton.LeftDisabled:SetSize(12, 24)

	tabButton.MiddleDisabled = tabButton:CreateTexture(nil, "BORDER")
	tabButton.MiddleDisabled:SetPoint("LEFT", tabButton.LeftDisabled, "RIGHT")
	tabButton.MiddleDisabled:SetSize(88, 24)

	tabButton.RightDisabled = tabButton:CreateTexture(nil, "BORDER")
	tabButton.RightDisabled:SetPoint("LEFT", tabButton.MiddleDisabled, "RIGHT")
	tabButton.RightDisabled:SetSize(12, 24)

	tabButton.Left = tabButton:CreateTexture(nil, "BORDER")
	tabButton.Left:SetPoint("TOPLEFT")
	tabButton.Left:SetSize(12, 24)

	tabButton.Middle = tabButton:CreateTexture(nil, "BORDER")
	tabButton.Middle:SetPoint("LEFT", tabButton.Left, "RIGHT")
	tabButton.Middle:SetSize(88, 24)

	tabButton.Right = tabButton:CreateTexture(nil, "BORDER")
	tabButton.Right:SetPoint("LEFT", tabButton.Middle, "RIGHT")
	tabButton.Right:SetSize(12, 24)

	tabButton.Text = tabButton:CreateFontString()
	tabButton.Text:SetPoint("CENTER", 0, -3)
	tabButton:SetFontString(tabButton.Text)

	tabButton:SetNormalFontObject(BaseWidget.FontGrayName)
	tabButton:SetHighlightFontObject("GameFontHighlightSmall")
	tabButton:SetDisabledFontObject("GameFontNormalSmall")

	tabButton.HighlightTexture = tabButton:CreateTexture()
	tabButton.HighlightTexture:SetColorTexture(1, 1, 1, .3)
	tabButton.HighlightTexture:SetPoint("TOPLEFT", 0, -4)
	tabButton.HighlightTexture:SetPoint("BOTTOMRIGHT")
	tabButton:SetHighlightTexture(tabButton.HighlightTexture)


	-- Logging:Debug("CreateTabButton(%s) : %d, %d", name, tabButton:GetWidth(), tabButton:GetHeight())

	tabButton:SetScript(
			"OnShow",
			function(self)
				-- Logging:Debug("TabButton.OnShow(%s) : width=%d", self:GetName(), self:GetTextWidth() )
				self:GetParent().Resize(self, 0)
				self.HighlightTexture:SetWidth(self:GetTextWidth() + 30)
			end
	)

	return tabButton
end

NativeUI:RegisterWidget('Tabs', Tabs)
NativeUI:RegisterWidget('TabGroup', Tabs)