-- @type AddOn
local _, AddOn = ...
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

function Slider:initialize(parent, name, horizontal, width, height, x, y, relativePoint, minVal, maxVal, defVal,text)
	BaseWidget.initialize(self, parent, name)
	self.horizontal = Util.Objects.IsBoolean(horizontal) and horizontal or false
	self.width = width or 10
	self.height = height or 170
	self.x = x or -8
	self.y = y or -8
	self.relativePoint = relativePoint or "TOPRIGHT"
	self.minVal = minVal or 1
	self.maxVal = maxVal or 10
	self.defVal = defVal or self.maxVal
	self.text = text or ""
end

function Slider:Create()
	Logging:Debug("Slider(%s)", self.parent:GetName() .. '_' .. self.name)

	local slider = CreateFrame("Slider", self.parent:GetName() .. '_' .. self.name, self.parent)
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
		slider.Low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -1)
	else
		slider.Low:SetPoint("TOPLEFT", slider, "TOPRIGHT", 1, -1)
	end

	slider.High = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	if self.horizontal then
		slider.High:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -1)
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

	--slider:SetScript(
	--		"OnMouseWheel",
	--		function(self, delta)
	--			Logging:Debug("Slider.OnMouseWheel(%s)", tostring(delta))
	--
	--		end
	--)
	-- Tooltip Stuff
	--slider:SetScript("OnEnter", Slider.OnEnter)
	--slider:SetScript("OnLeave", Slider.OnLeave)

	slider.Range = Slider.Range
	slider.SetTo = Slider.SetTo
	slider.OnChange = Slider.OnChange

	slider:SetPoint(self.relativePoint, self.x, self.y)
	slider:Range(self.minVal, self.maxVal)
	slider:SetTo(self.defVal or self.maxVal)

	return slider
end

function Slider.Range(self, min, max, hideRange)
	Logging:Debug("Slider.Range()")
	self.Low:SetText(min)
	self.High:SetText(max)
	self:SetMinMaxValues(min, max)
	if not self.IsVertical then
		self.Low:SetShown(not hideRange)
		self.High:SetShown(not hideRange)
	end
end

function Slider.SetTo(self, value)
	Logging:Debug("Slider.SetTo()")
	if not value then
		local _, max = self:GetMinMaxValues()
		value = max
	end
	self:SetValue(value)
end

function Slider.OnChange(self, func)
	Logging:Debug("Slider.OnChange()")
	self:SetScript("OnValueChanged",func)
end

--[[
function Slider.OnEnter(self)
	Logging:Debug("Slider.OnEnter")
	local text = self.Text:GetText()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(self.TooltipText or "")
	GameTooltip:AddLine(text or "",1,1,1)
	GameTooltip:Show()
end

function Slider.OnLeave(self)
	Logging:Debug("Slider.OnLeave")
	GameTooltip:Hide()
end
--]]

NativeUI:RegisterWidget('Slider', Slider)