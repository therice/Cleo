-- @type AddOn
local _, AddOn = ...
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type LibLogging
local Logging = AddOn:GetLibrary('Logging')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @class UI.Widgets.ScrollFrame
local ScrollFrame = AddOn.Package('UI.Widgets'):Class('ScrollFrame', BaseWidget)

function ScrollFrame:initialize(parent, name)
	BaseWidget.initialize(self, parent, name)
end

function ScrollFrame:Create()
	local sf = CreateFrame("ScrollFrame", self.name, self.parent)
	BaseWidget.LayerBorder(sf, 2, 0.24, 0.25, 0.30, 1)

	sf.content = CreateFrame("Frame", self.name .. '_Content', sf)
	sf:SetScrollChild(sf.content)

	sf.ScrollBar = NativeUI:New('ScrollBar', sf)
	sf.ScrollBar:Size(16, 0):Point("TOPRIGHT",-3,-3):Point("BOTTOMRIGHT",-3,3):Range(0, 1):SetTo(0):ClickRange(20)
	sf.ScrollBar.slider:SetScript("OnValueChanged", ScrollFrame.ScrollBarValueChanged)
	sf.ScrollBar:UpdateButtons()

	sf:SetScript("OnMouseWheel", ScrollFrame.OnMouseWheel)
	sf.SetNewHeight = ScrollFrame.SetNewHeight
	sf.Height = ScrollFrame.SetNewHeight
	sf.Width = ScrollFrame.SetNewWidth
	sf.AddHorizontal = ScrollFrame.AddHorizontal
	sf.HideScrollOnNoScroll = ScrollFrame.HideScrollOnNoScroll

	BaseWidget.Mod(
		sf,
		'MouseWheelRange', ScrollFrame.SetMouseWheelRange
	)

	sf._Size = self.Size
	sf.Size = ScrollFrame.SetSize

	return sf
end

function ScrollFrame.SetMouseWheelRange(self, range)
	self.mouseWheelRange = range
	return self
end

function ScrollFrame.SetSize(self, width, height)
	--Logging:Debug("ScrollFrame.SetSize(%s, %d, %d)", tostring(self:GetName()), tonumber(width), tonumber(height))
	self:SetSize(width,height)
	self.content:SetWidth(width - 16 - 4)

	if height < 65 then
		self.ScrollBar.IsThumbSmalled = true
		self.ScrollBar.thumb:SetHeight(5)
	elseif self.ScrollBar.IsThumbSmalled then
		self.ScrollBar.IsThumbSmalled = nil
		self.ScrollBar.thumb:SetHeight(30)
	end

	return self
end

function ScrollFrame.ScrollBarValueChanged(self, value)
	local parent = self:GetParent():GetParent()
	parent:SetVerticalScroll(value)
	self:UpdateButtons()
	ScrollFrame.CheckHideScroll(self)
end

function ScrollFrame.ScrollBarValueChangedH(self, value)
	local parent = self:GetParent():GetParent()
	parent:SetHorizontalScroll(value)
	self:UpdateButtons()
end

function ScrollFrame.CheckHideScroll(self)
	if not self.HideOnNoScroll then return end

	if not self.buttonUp:IsEnabled() and not self.buttonDown:IsEnabled() then
		self:Hide()
	else
		self:Show()
	end
end

function ScrollFrame.OnMouseWheel(self, delta)
	-- Logging:Debug("ScrollFrame.OnMouseWheel(%d)", tonumber(delta))
	delta = delta * (self.mouseWheelRange or 20)
	local min,max = self.ScrollBar.slider:GetMinMaxValues()
	local val = self.ScrollBar:GetValue()
	if (val - delta) < min then
		self.ScrollBar:SetValue(min)
	elseif (val - delta) > max then
		self.ScrollBar:SetValue(max)
	else
		self.ScrollBar:SetValue(val - delta)
	end
end

function ScrollFrame.SetNewHeight(self, height)
	-- Logging:Debug("ScrollFrame.SetNewHeight(%d)", height)
	self.content:SetHeight(height)
	self.ScrollBar:Range(0, max(height - self:GetHeight(), 0), nil, true)
	self.ScrollBar:UpdateButtons()
	ScrollFrame.CheckHideScroll(self.ScrollBar)
	return self
end

function ScrollFrame.SetNewWidth(self, width)
	-- Logging:Debug("ScrollFrame.SetNewWidth(%d)", width)
	self.content:SetWidth(width)
	self.ScrollBarHorizontal:Range(0,max(width-self:GetWidth(),0),nil,true)
	self.ScrollBarHorizontal:UpdateButtons()
	return self
end

function ScrollFrame.AddHorizontal(self, outside)
	self.ScrollBarHorizontal =
		NativeUI:New('ScrollBar', self)
				:SetHorizontal()
				:Size(0,16)
				:Point("BOTTOMLEFT", 3, 3-(outside and 18 or 0))
				:Point("BOTTOMRIGHT",-3-18, 3-(outside and 18 or 0))
				:Range(0,1):SetTo(0):ClickRange(20)

	self.ScrollBarHorizontal.slider:SetScript("OnValueChanged", ScrollFrame.ScrollBarValueChangedH)
	self.ScrollBarHorizontal:UpdateButtons()

	self.ScrollBar:Point("BOTTOMRIGHT",-3,3+(outside and 0 or 18))

	self.SetNewWidth = ScrollFrame.SetNewWidth
	self.Width = ScrollFrame.SetNewWidth

	return self
end

function ScrollFrame.HideScrollOnNoScroll(self)
	self.ScrollBar.HideOnNoScroll = true
	self.ScrollBar:UpdateButtons()
	ScrollFrame.CheckHideScroll(self.ScrollBar)
	return self
end

NativeUI:RegisterWidget('ScrollFrame', ScrollFrame)