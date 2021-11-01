-- @type AddOn
local AddOnName, AddOn = ...
-- @type LibLogging
local Logging = AddOn:GetLibrary('Logging')
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @class UI.Widgets.ScrollBar
local ScrollBar = AddOn.Package('UI.Widgets'):Class('ScrollBar', BaseWidget)

function ScrollBar:initialize(parent, name)
	BaseWidget.initialize(self, parent, name)
end

function ScrollBar:Create()
	local sb = CreateFrame("Frame", self.name, self.parent)

	sb.slider = CreateFrame("Slider", AddOn:Qualify(self.name, 'Slider'), sb)
	sb.slider:SetPoint("TOPLEFT",0,-18)
	sb.slider:SetPoint("BOTTOMRIGHT",0,18)

	sb.bg = sb.slider:CreateTexture(nil, "BACKGROUND")
	sb.bg:SetPoint("TOPLEFT",0,1)
	sb.bg:SetPoint("BOTTOMRIGHT",0,-1)
	sb.bg:SetColorTexture(0, 0, 0, 0.3)

	sb.thumb = sb.slider:CreateTexture(nil, "OVERLAY")
	sb.thumb:SetColorTexture(0.44,0.45,0.50,.7)
	sb.thumb:SetSize(14,30)

	sb.slider:SetThumbTexture(sb.thumb)
	sb.slider:SetOrientation("VERTICAL")
	sb.slider:SetValue(2)

	sb.borderLeft = sb.slider:CreateTexture(nil, "BACKGROUND")
	sb.borderLeft:SetPoint("TOPLEFT",-1,1)
	sb.borderLeft:SetPoint("BOTTOMLEFT",-1,-1)
	sb.borderLeft:SetWidth(1)
	sb.borderLeft:SetColorTexture(0.24,0.25,0.30,1)

	sb.borderRight = sb.slider:CreateTexture(nil, "BACKGROUND")
	sb.borderRight:SetPoint("TOPRIGHT",1,1)
	sb.borderRight:SetPoint("BOTTOMRIGHT",1,-1)
	sb.borderRight:SetWidth(1)
	sb.borderRight:SetColorTexture(0.24,0.25,0.30,1)

	sb.buttonUp = NativeUI:New('ButtonUp', sb)
	sb.buttonUp:SetSize(16,16)
	sb.buttonUp:SetPoint("TOP",0,0)
	sb.buttonUp:SetScript("OnClick", function(self) ScrollBar.ButtonClick(self, true) end)
	sb.buttonUp:SetScript("OnMouseDown", function(self) ScrollBar.OnMouseDown(self, true) end)
	sb.buttonUp:SetScript("OnMouseUp",  ScrollBar.OnMouseUp)

	sb.buttonDown = NativeUI:New('ButtonDown', sb)
	sb.buttonDown:SetSize(16,16)
	sb.buttonDown:SetPoint("BOTTOM",0,0)
	sb.buttonDown:SetScript("OnClick", function(self) ScrollBar.ButtonClick(self, false) end)
	sb.buttonDown:SetScript("OnMouseDown", function(self) ScrollBar.OnMouseDown(self, false) end)
	sb.buttonDown:SetScript("OnMouseUp",  ScrollBar.OnMouseUp)

	sb.clickRange = 1
	sb._SetScript = sb.SetScript

	BaseWidget.Mod(
			sb,
			'Range', ScrollBar.Range,
			'SetValue', ScrollBar.SetValue,
			'SetTo', ScrollBar.SetValue,
			'GetValue', ScrollBar.GetValue,
			'GetMinMaxValues',ScrollBar.GetMinMaxValues,
			'SetMinMaxValues',ScrollBar.SetMinMaxValues,
			'SetScript', ScrollBar.SetScript,
			'OnChange', ScrollBar.OnChange,
			'UpdateButtons', ScrollBar.UpdateButtons,
			'ClickRange',  ScrollBar.ClickRange,
			'SetHorizontal', ScrollBar.SetHorizontal,
			'SetObey', ScrollBar.SetObey
	)

	sb.Size = ScrollBar.SetSize
	sb.slider.UpdateButtons = ScrollBar.UpdateSliderButtons

	return sb
end

function ScrollBar.Range(self, min, max, clickRange, unchanged)
	-- Logging:Debug("ScrollBar.Range(%d, %d, %d, %s)", tonumber(min), tonumber(max), tonumber(clickRange), tostring(unchanged))
	self.slider:SetMinMaxValues(min, max)
	self.clickRange = clickRange or self.clickRange
	if not unchanged then self.slider:SetValue(min) end
	return self
end

function ScrollBar.SetValue(self, value)
	-- Logging:Debug("ScrollBar.SetValue(%s)", tonumber(value))
	-- self.slider:SetValue(Util.Numbers.Round2(value))
	self.slider:SetValue(value)
	self:UpdateButtons()
	return self
end

function ScrollBar.SetSize(self, width, height)
	self:SetSize(width, height)
	if self.isHorizontal then
		self.thumb:SetHeight(height - 2)
		self.slider:SetPoint("TOPLEFT",height+2,0)
		self.slider:SetPoint("BOTTOMRIGHT",-height-2,0)
		self.buttonUp:SetSize(height,height)
		self.buttonDown:SetSize(height,height)
	else
		self.thumb:SetWidth(width - 2)
		self.slider:SetPoint("TOPLEFT",0,-width-2)
		self.slider:SetPoint("BOTTOMRIGHT",0,width+2)
		self.buttonUp:SetSize(width,width)
		self.buttonDown:SetSize(width,width)
	end

	return self
end

function ScrollBar.GetValue(self)
	return self.slider:GetValue()
end

function ScrollBar.GetMinMaxValues(self)
	return self.slider:GetMinMaxValues()
end

function ScrollBar.SetMinMaxValues(self, ...)
	self.slider:SetMinMaxValues(...)
	self:UpdateButtons()
	return self
end

function ScrollBar.SetScript(self,...)
	self.slider:SetScript(...)
	return self
end

function ScrollBar.OnChange(self, fn)
	self.slider:SetScript("OnValueChanged",fn)
	return self
end

function ScrollBar.SetObey(self, value)
	self.slider:SetObeyStepOnDrag(value)
	return self
end

function ScrollBar.SetHorizontal(self)
	self.slider:SetOrientation("HORIZONTAL")
	self.buttonUp:ClearAllPoints()
	self.buttonUp:SetPoint("LEFT", 0, 0)
	self.buttonUp.NormalTexture:SetTexCoord(0.4375, 0.5, 0.5, 0.625)
	self.buttonUp.HighlightTexture:SetTexCoord(0.4375, 0.5, 0.5, 0.625)
	self.buttonUp.PushedTexture:SetTexCoord(0.4375, 0.5, 0.5, 0.625)
	self.buttonUp.DisabledTexture:SetTexCoord(0.4375, 0.5, 0.5, 0.625)

	self.buttonDown:ClearAllPoints()
	self.buttonDown:SetPoint("RIGHT", 0, 0)
	self.buttonDown.NormalTexture:SetTexCoord(0.375, 0.4375, 0.5, 0.625)
	self.buttonDown.HighlightTexture:SetTexCoord(0.375, 0.4375, 0.5, 0.625)
	self.buttonDown.PushedTexture:SetTexCoord(0.375, 0.4375, 0.5, 0.625)
	self.buttonDown.DisabledTexture:SetTexCoord(0.375, 0.4375, 0.5, 0.625)

	self.thumb:SetSize(30, 14)

	self.slider:SetPoint("TOPLEFT", 18, 0)
	self.slider:SetPoint("BOTTOMRIGHT", -18, 0)

	self.borderLeft:ClearAllPoints()
	self.borderLeft:SetSize(0, 1)
	self.borderLeft:SetPoint("BOTTOMLEFT", self.slider, "TOPLEFT", -1, 0)
	self.borderLeft:SetPoint("BOTTOMRIGHT", self.slider, "TOPRIGHT", 1, 0)

	self.borderRight:ClearAllPoints()
	self.borderRight:SetSize(0, 1)
	self.borderRight:SetPoint("TOPLEFT", self.slider, "BOTTOMLEFT", -1, 0)
	self.borderRight:SetPoint("TOPRIGHT", self.slider, "BOTTOMRIGHT", 1, 0)

	self.isHorizontal = true

	return self
end

function ScrollBar.UpdateButtons(self)
	local slider = self.slider
	local value = Util.Numbers.Round2(slider:GetValue())
	local min,max = slider:GetMinMaxValues()
	-- Logging:Debug("ScrollBar.UpdateButtons() : raw=%s, value=%s, min=%s, max=%s, eval=%s", slider:GetValue(), tostring(value), tostring(min), tostring(max), tostring(value >= max))
	min, max = Util.Numbers.Round2(min), Util.Numbers.Round2(max)

	if max == min then
		-- Logging:Debug("max == min")
		self.buttonUp:SetEnabled(false)
		self.buttonDown:SetEnabled(false)
	elseif value <= min then
		-- Logging:Debug("value <= min")
		self.buttonUp:SetEnabled(false)
		self.buttonDown:SetEnabled(true)
	elseif value >= max then
		-- Logging:Debug("value >= max")
		self.buttonUp:SetEnabled(true)
		self.buttonDown:SetEnabled(false)
	else
		-- Logging:Debug("none")
		self.buttonUp:SetEnabled(true)
		self.buttonDown:SetEnabled(true)
	end
	return self
end

function ScrollBar.ClickRange(self, value)
	self.clickRange = value or 1
	return self
end

function ScrollBar.UpdateSliderButtons(self)
	self:GetParent():UpdateButtons()
	return self
end

function ScrollBar.ButtonClick(self, up)
	Logging:Debug("ButtonClick(%s)", tostring(up))
	local scrollBar = self:GetParent()
	if not scrollBar.GetMinMaxValues then
		scrollBar = scrollBar.slider
	end

	local min, max = scrollBar:GetMinMaxValues()
	local val = scrollBar:GetValue()
	local clickRange = self:GetParent().clickRange

	Logging:Debug("ButtonClick(%s) : %d, %d / %d, %d", tostring(up), min, max, val, clickRange)
	if up then
		if (val - clickRange) < min then
			scrollBar:SetValue(min)
		else
			scrollBar:SetValue(val - clickRange)
		end
	else
		if (val + clickRange) > max then
			scrollBar:SetValue(max)
		else
			scrollBar:SetValue(val + clickRange)
		end
	end
end

function ScrollBar.OnMouseDown(self, up)
	Logging:Debug("OnMouseDown(%s)", tostring(up))
	local counter = 0
	self.ticker = C_Timer.NewTicker(.03,function()
		counter = counter + 1
		if counter > 10 then
			ScrollBar.ButtonClick(self, up)
		end
	end)
end

function ScrollBar.OnMouseUp(self)
	if self.ticker then
		self.ticker:Cancel()
	end
end


NativeUI:RegisterWidget('ScrollBar', ScrollBar)