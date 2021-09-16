-- @type AddOn
local _, AddOn = ...
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
---@type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @class UI.Widgets.Checkbox
local Checkbox = AddOn.Package('UI.Widgets'):Class('Checkbox', BaseWidget)


function Checkbox:initialize(parent, name, text, state)
	BaseWidget.initialize(self, parent, name)
	self.text = text or ""
	self.state = state and true or false
end

function Checkbox:Create()
	local cb = CreateFrame("CheckButton", self.name, self.parent)
	cb:SetSize(20, 20)

	cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	cb.text:SetPoint("TOPLEFT", cb, "TOPRIGHT", 4, 0)
	cb.text:SetPoint("BOTTOMLEFT", cb, "BOTTOMRIGHT", 4, 0)
	cb.text:SetJustifyV("MIDDLE")

	cb:SetFontString(cb.text)

	BaseWidget.Border(cb, 0.24, 0.25, 0.3, 1, 1)

	cb.Texture = cb:CreateTexture(nil, "BACKGROUND")
	cb.Texture:SetColorTexture(0, 0, 0, .3)
	cb.Texture:SetPoint("TOPLEFT")
	cb.Texture:SetPoint("BOTTOMRIGHT")

	cb.CheckedTexture = cb:CreateTexture()
	cb.CheckedTexture:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	cb.CheckedTexture:SetPoint("TOPLEFT", -4, 4)
	cb.CheckedTexture:SetPoint("BOTTOMRIGHT", 4, -4)
	cb:SetCheckedTexture(cb.CheckedTexture)

	cb.PushedTexture = cb:CreateTexture()
	cb.PushedTexture:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	cb.PushedTexture:SetPoint("TOPLEFT", -4, 4)
	cb.PushedTexture:SetPoint("BOTTOMRIGHT", 4, -4)
	cb.PushedTexture:SetVertexColor(0.8, 0.8, 0.8, 0.5)
	cb.PushedTexture:SetDesaturated(true)
	cb:SetPushedTexture(cb.PushedTexture)

	cb.DisabledTexture = cb:CreateTexture()
	cb.DisabledTexture:SetTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
	cb.DisabledTexture:SetPoint("TOPLEFT", -4, 4)
	cb.DisabledTexture:SetPoint("BOTTOMRIGHT", 4, -4)
	cb:SetDisabledTexture(cb.DisabledTexture)

	cb.HighlightTexture = cb:CreateTexture()
	cb.HighlightTexture:SetColorTexture(1, 1, 1, .3)
	cb.HighlightTexture:SetPoint("TOPLEFT")
	cb.HighlightTexture:SetPoint("BOTTOMRIGHT")
	cb:SetHighlightTexture(cb.HighlightTexture)

	cb.text:SetText(self.text)
	cb:SetChecked(self.state)
	cb:SetScript("OnEnter", Checkbox.OnEnter)
	cb:SetScript("OnLeave", function() UIUtil:HideTooltip() end)
	cb._SetSize = cb.SetSize

	BaseWidget.Mod(
			cb,
			'Tooltip', Checkbox.Tooltip,
			'Left', Checkbox.Left,
			'TextSize', Checkbox.TextSize,
			'ColorState', Checkbox.ColorState,
			'AddColorState', Checkbox.AddColorState,
			'OnDatasourceConfigured', Checkbox.OnDatasourceConfigured
	)

	return cb
end

function Checkbox.OnDatasourceConfigured(self)
	-- remove any currently configured click handler
	self:OnClick(Util.Functions.Noop)
	-- get current value from datasource
	self.state = self.ds:Get()
	self:SetChecked(self.state)
	-- establish callback for setting db value
	self:OnClick(
			function(self)
				self.ds:Set(self:GetChecked())
			end
	)
end

function Checkbox.Tooltip(self, text)
	self.tooltipText = text
	return self
end

function Checkbox.OnEnter(self)
	local tooltipTitle, tooltipText = self.text:GetText(), self.tooltipText
	if Util.Strings.IsEmpty(tooltipTitle) or not tooltipTitle then
		tooltipTitle = tooltipText
		tooltipText = nil
	end
	UIUtil.ShowTooltip(self, "ANCHOR_RIGHT", tooltipTitle, {tooltipText,1,1,1})
end

function Checkbox.Left(self, x)
	self.text:ClearAllPoints()
	self.text:SetPoint("RIGHT",self,"LEFT", x and x * (-1) or -2, 0)
	return self
end

function Checkbox.TextSize(self, size)
	self.text:SetFont(self.text:GetFont(),size)
	return self
end

function Checkbox.ColorState(self, isBorderInsteadText)
	if isBorderInsteadText then
		local cR, cG, cB
		if self.disabled or not self:IsEnabled() then
			cR, cG, cB = .5, .5, .5
		elseif self:GetChecked() then
			cR, cG, cB = .2, .8, .2
		else
			cR, cG, cB = .8, .2, .2
		end
		self.BorderTop:SetColorTexture(cR, cG, cB, 1)
		self.BorderLeft:SetColorTexture(cR, cG, cB, 1)
		self.BorderBottom:SetColorTexture(cR, cG, cB, 1)
		self.BorderRight:SetColorTexture(cR, cG, cB, 1)
	elseif self.disabled or not self:IsEnabled() then
		self.text:SetTextColor(.5, .5, .5, 1)
	elseif self:GetChecked() then
		self.text:SetTextColor(.3, 1, .3, 1)
	else
		self.text:SetTextColor(1, .4, .4, 1)
	end
	return self
end

function Checkbox.AddColorState(self, isBorderInsteadText)
	self:SetScript("PostClick", function() self:ColorState(isBorderInsteadText) end )
	self:ColorState(isBorderInsteadText)
	self._SetChecked = self.SetChecked
	self.SetChecked  = function(self, ...)
		self._SetChecked(...)
		self:ColorState(isBorderInsteadText)
	end
	return self
end

NativeUI:RegisterWidget('CheckBox', Checkbox)
NativeUI:RegisterWidget('Checkbox', Checkbox)