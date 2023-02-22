--- @type AddOn
local _, AddOn = ...
-- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @type LibLogging
local Logging = AddOn:GetLibrary('Logging')
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")

--- @class UI.Widgets.MultiEditBox
local MultiEditBox = AddOn.Package('UI.Widgets'):Class('MultiEditBox', BaseWidget)

function MultiEditBox:initialize(parent, name)
	BaseWidget.initialize(self, parent, name)
end

function MultiEditBox:Create()
	local meb = NativeUI:New('ScrollFrame', self.parent)
	meb._Size = meb.Size

	meb.editBox =
		NativeUI:NewNamed('EditBox', meb.content, AddOn:Qualify(self.name, 'EditBox'))
			:Point("TOPLEFT", meb.content, 0, 0)
			:Point("TOPRIGHT", meb.content, 0, 0)
			:Point("BOTTOM", meb.content, 0, 0)
			:OnChange(MultiEditBox.OnTextChanged)

	meb.editBox.ScrollFrame = meb
	meb.editBox:SetFont(_G.GameFontNormal:GetFont(), 12, "")
	--meb.editBox:SetAutoFocus( false )
	meb.editBox:SetMultiLine(true)
	meb.editBox:SetBackdropColor(0, 0, 0, 0)
	meb.editBox:SetBackdropBorderColor(0, 0, 0, 0)
	meb.editBox:SetTextInsets(5,5,2,2)
	meb.editBox:SetScript("OnCursorChanged", MultiEditBox.OnCursorChanged)

	meb.content:SetScript("OnMouseDown", MultiEditBox.OnFrameClick)
	meb:SetScript("OnMouseWheel", MultiEditBox.OnMouseWheel)

	BaseWidget.Mod(
		meb,
		'SetText', MultiEditBox.SetText,
		'GetText', MultiEditBox.GetText,
		'Insert', MultiEditBox.Insert,
		'Append', MultiEditBox.Append,
		'HighlightText', MultiEditBox.HighlightText,
		'GetHighlightText', MultiEditBox.GetHighlightText,
		'Font', MultiEditBox.Font,
		'OnChange', MultiEditBox.OnChange,
		'OnCursorChanged', MultiEditBox.OnCursorChanged,
		'SetFocus', MultiEditBox.SetFocus
	)

	meb.Size = MultiEditBox.SetSize

	return meb
end


function MultiEditBox.SetFocus(self)
	self.editBox:SetFocus()
end

function MultiEditBox.SetSize(self,  width, height)
	--Logging:Debug("MultiEditBox.SetSize(%s, %d, %d)", tostring(self:GetName()), tonumber(width), tonumber(height))
	self:_Size(width, height)
	self.editBox:SetSize(width, height)
	return self
end

function MultiEditBox.OnTextChanged(self, ...)
	--Logging:Debug("OnTextChanged()")
	local parent, height = self.ScrollFrame, self:GetHeight()
	local _, prevMax = parent.ScrollBar:GetMinMaxValues()
	local changeToMax = parent.ScrollBar:GetValue() >= prevMax

	parent:SetNewHeight(max(height, parent:GetHeight()))
	if changeToMax then
		local _, max = parent.ScrollBar:GetMinMaxValues()
		parent.ScrollBar:SetValue(max)
	end

	if parent.OnTextChanged then
		parent.OnTextChanged(self,...)
	elseif self.OnTextChanged then
		self:OnTextChanged(...)
	end
end

function MultiEditBox.OnCursorChanged(self, x, y, _, height)
	--Logging:Debug("OnCursorChanged()")
	y = math.abs(y)
	local parent = self.ScrollFrame
	local scrollNow, heightNow = parent:GetVerticalScroll(), parent:GetHeight()

	if y < scrollNow then
		parent.ScrollBar:SetValue(max(floor(y),0))
	elseif (y + height) > (scrollNow + heightNow) then
		local _,scrollMax = parent.ScrollBar:GetMinMaxValues()
		parent.ScrollBar:SetValue(min(ceil( y + height - heightNow ),scrollMax))
	end

	if parent.OnCursorChanged then
		local _, obj = self:GetRegions()
		parent.OnCursorChanged(self, obj, x, y)
	end
end

function MultiEditBox.OnFrameClick(self)
	self:GetParent().editBox:SetFocus()
end

function MultiEditBox.OnMouseWheel(self,delta)
	local min,max = self.ScrollBar:GetMinMaxValues()
	delta = delta * (self.mouseWheelRange or 20)
	local val = self.ScrollBar:GetValue()
	--Logging:Debug("OnMouseWheel(%d, %d, %d, %d)", min, max, delta, val)

	if (val - delta) < min then
		self.ScrollBar:SetValue(min)
	elseif (val - delta) > max then
		self.ScrollBar:SetValue(max)
	else
		self.ScrollBar:SetValue(val - delta)
	end
end

function MultiEditBox.Insert(self, text)
	self.editBox:Insert(text)
	return self
end

function MultiEditBox.Append(self, text)
	local ctext = self:GetText()
	self.editBox:SetCursorPosition(ctext and ctext:len() or 0)
	self:Insert(text)
end

function MultiEditBox.SetText(self, text)
	self.editBox:SetText(text)
	return self
end

function MultiEditBox.GetText(self)
	return self.editBox:GetText()
end

function MultiEditBox.HighlightText(self, ...)
	return self.editBox:HighlightText(...)
end

function MultiEditBox.GetHighlightText(self)
	local text,cursor = self:GetText(),self:GetCursorPosition()
	self:Insert("")
	local textNew, cursorNew = self:GetText(), self:GetCursorPosition()
	self:SetText(text)
	self:SetCursorPosition(cursor)
	local spos, epos = cursorNew, #text - ( #textNew - cursorNew )
	self:HighlightText(spos, epos)
	return spos, epos
end

function MultiEditBox.Font(self, font, size, params, ...)
	if Util.Objects.IsEmpty(font) then
		font = self.editBox:GetFont() or nil
	end
	params = Util.Objects.Default(params, "")
	self.editBox:SetFont(font, size, params, ...)
	return self
end

function MultiEditBox.OnChange(self, fn)
	self.editBox.OnTextChanged = fn
	return self
end

function MultiEditBox.OnCursorChanged(self, fn)
	self.OnCursorChanged = fn
	return self
end

NativeUI:RegisterWidget('MultiEditBox', MultiEditBox)
NativeUI:RegisterWidget('MultiLineEditBox', MultiEditBox)