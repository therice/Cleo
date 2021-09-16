--- @type AddOn
local _, AddOn = ...
local C = AddOn.Constants
-- @type LibLogging
local Logging = AddOn:GetLibrary('Logging')
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @class UI.Widgets.Slider
local Slider = AddOn.Package('UI.Widgets'):Class('Slider', BaseWidget)
local GameTooltip = GameTooltip

function Slider:initialize(parent, name, horizontal, width, height, x, y, relativePoint, minVal, maxVal, defVal, text)
	BaseWidget.initialize(self, parent, name)
	self.horizontal = Util.Objects.IsBoolean(horizontal) and horizontal or false
	self.width = width
	self.height = height
	self.x = x
	self.y = y
	self.relativePoint = relativePoint
	self.minVal = minVal
	self.maxVal = maxVal
	self.defVal = defVal or self.maxVal
	self.text = text or ""
end

function Slider:Create()
	local slider = CreateFrame("Slider", self.name, self.parent)
	slider:SetOrientation(self.horizontal and "HORIZONTAL" or "VERTICAL")
	slider.IsVertical = not self.horizontal
	if self.horizontal then slider:SetSize(144, 10) else slider:SetSize(10, 144) end

	slider.Text = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	slider.Text:SetPoint("BOTTOM", slider, "TOP", 0, 1)
	slider.Text:SetText(self.text)
	slider.text = slider.Text
	slider:SetValueStep(1)

	slider.Low = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	if self.horizontal then
		slider.Low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", -2,- 3)
	else
		slider.Low:SetPoint("TOPLEFT", slider, "TOPRIGHT", 1, -1)
	end

	slider.High = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	if self.horizontal then
		slider.High:SetPoint("TOPRIGHT", slider,"BOTTOMRIGHT", 2,-3)
	else
		slider.High:SetPoint("BOTTOMLEFT", slider, "BOTTOMRIGHT", 1, 1)
	end

	if self.horizontal then
		BaseWidget.Border(slider, 0.24, 0.25, 0.3, 1, 1, 1, 0)
	else
		BaseWidget.Border(slider, 0.24, 0.25, 0.3, 1, 1, 0, 1)
	end

	slider.Thumb = slider:CreateTexture()
	slider.Thumb:SetColorTexture(0.44,0.45,0.50,0.7)
	if self.horizontal then slider.Thumb:SetSize(16,8) else slider.Thumb:SetSize(8,16) end
	slider:SetThumbTexture(slider.Thumb)

	if not self.horizontal then
		slider.Low:Hide()
		slider.High:Hide()
		slider.Text:Hide()
	end

	slider:SetScript("OnMouseWheel", SliderOnMouseWheel)
	slider.ShowTooltip = Slider.ShowTooltip
	slider.HideTooltip = Slider.HideTooltip
	slider.ReloadTooltip = Slider.ReloadTooltip
	slider:SetScript("OnEnter", self.ShowTooltip)
	slider:SetScript("OnLeave", self.HideTooltip)

	BaseWidget.Mod(
		slider,
		'SetText', Slider.SetText,
		'TooltipTitle', Slider.SetTooltipTitle,
		'Tooltip', Slider.SetTooltip,
		'EditBox', Slider.WithEditBox,
		'OnDatasourceConfigured', Slider.OnDatasourceConfigured
	)

	slider.Range = Slider.Range
	slider.SetTo = Slider.SetTo
	slider.OnChange = Slider.OnChange
	slider.Obey = Slider.SetObey

	slider._Size = slider.Size
	slider.Size = Slider.SetSize

	slider._SetEnabled = slider.SetEnabled
	slider.SetEnabled = Slider.SetEnabled

	slider.Text:SetFont(slider.text:GetFont(), 10)
	slider.Low:SetFont(slider.Low:GetFont(), 10)
	slider.High:SetFont(slider.High:GetFont(), 10)


	if self.width and self.height then
		slider:Size(self.width, self.height)
	end

	if self.relativePoint and self.x and self.y then
		slider:SetPoint(self.relativePoint, self.x, self.y)
	end

	if self.minVal and self.maxVal then
		slider:Range(self.minVal, self.maxVal)
	end

	if self.defVal or self.maxVal then
		slider:SetTo(self.defVal or self.maxVal)
	end

	return slider
end

function Slider.SetEnabled(self, enabled)
	self:_SetEnabled(enabled)
	if self.editBox then
		self.editBox:SetEnabled(enabled)
	end
end

function Slider.OnDatasourceConfigured(self)
	-- remove any currently configured callback function
	self:OnChange(Util.Functions.Noop)
	-- set the current value
	self:SetTo(tonumber(self.ds:Get()))
	-- establish callback for setting db value
	self:OnChange(
		function(self, value)
			local v = Util.Numbers.Round2(value)
			self.ds:Set(v)
			self:SetTo(v)
		end
	)
end

function Slider.Range(self, min, max, hideRange)
	-- Logging:Debug("Slider.Range()")
	self.Low:SetText(min)
	self.High:SetText(max)
	self:SetMinMaxValues(min, max)
	if not self.IsVertical then
		self.Low:SetShown(not hideRange)
		self.High:SetShown(not hideRange)
	end
	return self
end

function Slider.WithEditBox(self)
	if not self.editBox then
		self.editBox =
			NativeUI:New('EditBox', self:GetParent(), nil, true)
				:Point("CENTER", self, "CENTER", 0, -15)
				:ColorBorder(C.Colors.ItemArtifact:GetRGB())
				:Size(50, 10)
		self.editBox:SetFontObject(GameFontHighlightSmall)
		self.editBox:SetJustifyH("CENTER")
		self.editBox:SetScript(
				"OnEnterPressed",
				function(eb)
					self:SetValue(tonumber(eb:GetText()))
				end
		)
	end

	return self
end

function Slider.SetSize(self, size)
	if self:GetOrientation() == "VERTICAL" then
		self:SetHeight(size)
	else
		self:SetWidth(size)
	end
	return self
end

function Slider.SetTooltipTitle(self, tooltipTitle)
	self.tooltipTitle = tooltipTitle
	return self
end

function Slider.SetTooltip(self, tooltipText)
	self.tooltipText = tooltipText
	return self
end

function Slider.ShowTooltip(self)
	local text = self.text:GetText()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(self.tooltipTitle or text or "")
	GameTooltip:AddLine(self.tooltipText or "", 1, 1, 1)
	GameTooltip:Show()
end

function Slider.HideTooltip(self)
	GameTooltip:Hide()
end

function Slider.ReloadTooltip(self)
	if GameTooltip:IsVisible() then
		self:HideTooltip()
		self:ShowTooltip()
	end
end

function Slider.SetText(self, text)
	self.text:SetText(text)
	return self
end

function Slider.SetTo(self, value)
	Logging:Debug("SetTo(%s)", tostring(value))
	if not value then
		local _, max = self:GetMinMaxValues()
		value = max
	end
	self:Tooltip(value)
	self:SetValue(value)
	if self.editBox then self.editBox:SetText(value) end
	self:ReloadTooltip()
	return self
end

function Slider.OnChange(self, func)
	self:SetScript("OnValueChanged",func)
	return self
end

function Slider.SetObey(self, val)
	self:SetObeyStepOnDrag(val)
	return self
end

NativeUI:RegisterWidget('Slider', Slider)