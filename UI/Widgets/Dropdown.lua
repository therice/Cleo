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
--- @class UI.Widgets.Dropdown
local Dropdown = AddOn.Package('UI.Widgets'):Class('Dropdown', BaseWidget)
--- @class UI.Widgets.DropdownItem
local DropdownItem = AddOn.Package('UI.Widgets'):Class('DropdownItem')
--- @class UI.Widgets.DropdownProperties
local DropdownProperties = AddOn.Package('UI.Widgets'):Class('DropdownProperties')

-- holds all the dropdown templates for reuse
local Templates, ReloadTemplates = {}, nil

Dropdown.Type = {
	Standard = 1,
	Radio    = 2,
	Checkbox = 3,
}

-- attributes of an individual item in dropdown
function DropdownItem:initialize(value, text)
	self.value = value
	self.text = text
end

-- attributes that apply to entire dropdown
function DropdownProperties:initialize(type, width, lines)
	self.type = type or Dropdown.Type.Standard
	self.width = width or 150
	self.lines = lines or 5
	-- this is an array due to possibility of multi-select
	self.value = {}
	self.textDecorator = function(item) return item and item.text or "???" end
	self.clickHandler = function(...) return true end
	self.valueChangedHandler = function(...)  end
end

function DropdownProperties:DecorateText(item)
	return self.textDecorator(item)
end

function DropdownProperties:SetValue(value)
	-- Logging:Debug("SetValue(%s)", tostring(value))
	self.value = { value }
	self:OnValueChanged()
end

function DropdownProperties:HasValue(value)
	return Util.Tables.ContainsValue(self.value, value)
end

function DropdownProperties:HandleClick(button, down, item)
	-- Logging:Debug("HandleClick(%s, %s) : %s", tostring(button), tostring(down), Util.Objects.ToString(item))
	if self.clickHandler(button, down, item) then
		self:DropDown():SetValue(item.value)
		return true
	end

	return false
end

function DropdownProperties:OnValueChanged()
	if self.valueChangedHandler then
		self.valueChangedHandler(unpack(self.value))
	end
end

function Dropdown:initialize(parent, name, type, width, lines)
	BaseWidget.initialize(self, parent, name)
	self.props = DropdownProperties(type, width, lines)
end

function Dropdown:Create()
	local dd = CreateFrame("Frame", self.name, self.parent)
	dd:SetSize(40,20)

	dd.Text = dd:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
	dd.Text:SetWordWrap(false)
	dd.Text:SetJustifyH("RIGHT")
	dd.Text:SetJustifyV("MIDDLE")
	dd.Text:SetSize(0,20)
	dd.Text:SetPoint("RIGHT",-24,0)
	dd.Text:SetPoint("LEFT",4,0)

	self.Border(dd,0.24,0.25,0.30,1,1)

	dd.Background = dd:CreateTexture(nil,"BACKGROUND")
	dd.Background:SetColorTexture(0,0,0,.3)
	dd.Background:SetPoint("TOPLEFT")
	dd.Background:SetPoint("BOTTOMRIGHT")

	dd.Button = self:CreateButton(dd)
	dd.Button:SetPoint("RIGHT",-2,0)

	dd.Button:SetScript("OnClick", Dropdown.OnClick)
	dd:SetScript("OnHide", function() Dropdown.Close() end)

	---@type table<number, UI.Widgets.DropdownItem>
	dd.List = {}
	---@type UI.Widgets.DropdownProperties
	dd.Props = self.props
	-- inject simple getter for reference to the dropdown
	dd.Props.DropDown = function() return dd end

	BaseWidget.Mod(
		dd,
		'SetEnabled',               function(self, enabled)  self.Button:SetEnabled(enabled) end,
	    'SetList',                  Dropdown.SetList,
		'GetListItem',              Dropdown.GetListItem,
		'MaxLines',                 Dropdown.SetMaxLines,
		'Tooltip',                  Dropdown.SetTooltip,
		'SetValue',                 Dropdown.SetValue,
		'SetValueFromText',         Dropdown.SetValueFromText,
		'ClearValue',               Dropdown.ClearValue,
		'HasValue',                 Dropdown.HasValue,
		'SetText',                  Dropdown.SetText,
		'IterateItems',             Dropdown.IterateItems,
		'SetTextDecorator',         function(self, fn) self.Props.textDecorator = fn return self end,
		'SetClickHandler',          function(self, fn) self.Props.clickHandler = fn return self  end,
		'OnValueChanged',           function(self, fn)  self.Props.valueChangedHandler = fn return self end,
		'OnDatasourceConfigured',   Dropdown.OnDatasourceConfigured
	)

	dd._Size = dd.Size
	dd._SetWidth = dd.SetWidth
	dd.Size = Dropdown.SetSize
	dd.SetWidth = Dropdown.SetSize
	dd:SetWidth(dd.Props.width)

	return dd
end

function Dropdown.OnDatasourceConfigured(self)
	-- Logging:Debug("Dropdown.OnDatasourceConfigured(%s)", self.ds.key)
	-- remove any currently configured click handler
	self:SetClickHandler(Util.Functions.Noop)
	self:SetValue(self.ds:Get())
	-- establish callback for setting db value
	self:SetClickHandler(
			function(_, _, item)
				self.ds:Set(item.value)
				return true
			end
	)
end

function Dropdown:CreateButton(f)
	local button = CreateFrame("Button", f:GetName() .. '_Button', f)
	button:SetSize(16,16)
	button:SetMotionScriptsWhileDisabled(true)

	local iconsTexture = BaseWidget.ResolveTexture("DiesalGUIcons16x256x128")

	button.NormalTexture = button:CreateTexture()
	button.NormalTexture:SetSize(0,0)
	button.NormalTexture:SetTexture(iconsTexture)
	button.NormalTexture:SetTexCoord(0.25,0.3125,0.5,0.625)
	button.NormalTexture:SetVertexColor(1,1,1,.7)
	button.NormalTexture:ClearAllPoints()
	button.NormalTexture:SetPoint("TOPLEFT",-5,2)
	button.NormalTexture:SetPoint("BOTTOMRIGHT",5,-2)
	button:SetNormalTexture(button.NormalTexture)

	button.PushedTexture = button:CreateTexture()
	button.PushedTexture:SetSize(0,0)
	button.PushedTexture:SetTexture(iconsTexture)
	button.PushedTexture:SetTexCoord(0.25,0.3125,0.5,0.625)
	button.PushedTexture:SetVertexColor(1,1,1,1)
	button.PushedTexture:SetSize(0,0)
	button.PushedTexture:ClearAllPoints()
	button.PushedTexture:SetPoint("TOPLEFT",-5,1)
	button.PushedTexture:SetPoint("BOTTOMRIGHT",5,-3)
	button:SetPushedTexture(button.PushedTexture)

	button.DisabledTexture = button:CreateTexture()
	button.DisabledTexture:SetTexture(iconsTexture)
	button.DisabledTexture:SetTexCoord(0.25,0.3125,0.5,0.625)
	button.DisabledTexture:SetVertexColor(.4,.4,.4,1)
	button.DisabledTexture:SetSize(0,0)
	button.DisabledTexture:ClearAllPoints()
	button.DisabledTexture:SetPoint("TOPLEFT",-5,2)
	button.DisabledTexture:SetPoint("BOTTOMRIGHT",5,-2)
	button:SetDisabledTexture(button.DisabledTexture)

	button.HighlightTexture = button:CreateTexture()
	button.HighlightTexture:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
	button.HighlightTexture:SetSize(0,0)
	button.HighlightTexture:SetColorTexture(1,1,1,.3)
	button.HighlightTexture:SetSize(0,0)
	button.HighlightTexture:ClearAllPoints()
	button.HighlightTexture:SetPoint("TOPLEFT")
	button.HighlightTexture:SetPoint("BOTTOMRIGHT")
	button:SetHighlightTexture(button.HighlightTexture)

	self.Border(button,0.24,0.25,0.30,1,1)

	button.Background = button:CreateTexture(nil,"BACKGROUND")
	button.Background:SetColorTexture(0,0,0,.3)
	button.Background:SetPoint("TOPLEFT")
	button.Background:SetPoint("BOTTOMRIGHT")

	button:SetScript("OnClick", function(self) Dropdown.OnClickButton(self) end)

	return button
end

function Dropdown.InjectIntoTemplate(self, template)
	template.List  = self.List
	template.Props = self.Props
end

function Dropdown:IterateItems(fn)
	Util.Tables.Call(self.List, fn)
end


local function SortListFn(x, y)
	local num1, num2 = tonumber(x), tonumber(y)
	if num1 and num2 then
		return num1 < num2
	else
		return tostring(x) < tostring(y)
	end
end

function Dropdown:SetList(list, order)
	local SortList = {}
	self.List = {}
	if not Util.Objects.IsTable(order) then
		for v in pairs(list) do
			SortList[#SortList + 1] = v
		end
		Util.Tables.Sort(SortList, SortListFn)

		for i, key in ipairs(SortList) do
			self.List[i] = DropdownItem(key, list[key])
			SortList[i] = nil
		end
	else
		for i, key in ipairs(order) do
			self.List[i] = DropdownItem(key, list[key])
		end
	end
	return self
end

function Dropdown:GetListItem(index)
	return self.List[index]
end

function Dropdown:ClearValue()
	self.Props:SetValue(nil)
	self:SetText(nil)
end

function Dropdown:SetValue(value)
	local _, item = Util.Tables.FindFn(self.List, function(item) return item.value == value end)
	if item then
		self.Props:SetValue(item.value)
		self:SetText(self.Props:DecorateText(item))
	end
	return self
end

function Dropdown:SetValueFromText(text)
	local _, item = Util.Tables.FindFn(self.List, function(item) return item.text == text end)
	if item then
		self.Props:SetValue(item.value)
		self:SetText(self.Props:DecorateText(item))
	end

	return self
end

function Dropdown:HasValue()
	return not Util.Tables.IsEmpty(self.Props.value)
end

function Dropdown:SetMaxLines(lines)
	self.Props.lines = lines
	return self
end

function Dropdown:SetText(text)
	-- Logging:Debug("SetText(%s)", tostring(text))
	self.Text:SetText(text)
	return self
end

function Dropdown:SetTooltip(title, ...)
	self.tipTitle = title
	self.tipLines = {...}

	self:SetScript(
		"OnEnter",
		function(self)
			local lines = Util.Tables.Copy(self.tipLines or {})
			if self.Text:IsTruncated() then
				Util.Tables.Push(lines, self.Text:GetText())
			end

			UIUtil.ShowTooltip(self, nil, self.tipTitle, unpack(lines))
		end
	)
	self:SetScript("OnLeave", function() UIUtil:HideTooltip() end)
	return self
end

local DefaultPadding = 25
function Dropdown:SetSize(width)
	if self.Middle then
		self.Middle:SetWidth(width)
		self:_SetWidth(width + DefaultPadding + DefaultPadding)
		self.Text:SetWidth(width - DefaultPadding)
	else
		self:_SetWidth(width)
	end
	-- self.noResize = true
	return self
end

function Dropdown.OnClick(self, ...)
	Logging:Debug("Dropdown.OnClick()")

	local parent = self:GetParent()
	if parent.PreUpdate then
		parent.PreUpdate(parent)
	end

	Dropdown.OnClickButton(self, ...)
end

function Dropdown.OnClickButton(self)
	Logging:Debug("Dropdown.OnClickButton()")
	if Templates[1]:IsShown() then
		Dropdown.Close()
		return
	end

	Dropdown.ToggleDropDownMenu(self:GetParent())
end

function Dropdown.Close()
	Templates[1]:Hide()
	Dropdown.CloseSecondLevel()
end

function Dropdown.CloseSecondLevel(level)
	level = level or 1
	for i = (level + 1), #Templates do
		Templates[i]:Hide()
	end
end

function Dropdown.Update(self, elapsed)
	-- the showTimer and isCounting attributes are provided by Blizzard API
	if (not self.showTimer or not self.isCounting) then return end
	if (self.showTimer < 0) then
		self:Hide()
		self.showTimer = nil
		self.isCounting = nil
	else
		self.showTimer = self.showTimer - elapsed
	end
end

local function CreateTemplate(id)
	local template = CreateFrame("Button", AddOnName .. "_DropdownTemplate_" .. id, UIParent)
	template:SetFrameStrata("TOOLTIP")
	template:EnableMouse(true)
	template:Hide()

	BaseWidget.Border(template, 0, 0, 0, 1, 1)

	template.Background = template:CreateTexture(nil, "BACKGROUND")
	template.Background:SetColorTexture(0, 0, 0, .9)
	template.Background:SetPoint("TOPLEFT")
	template.Background:SetPoint("BOTTOMRIGHT")

	template:SetScript("OnEnter", function(self, motion) UIDropDownMenu_StopCounting(self, motion) end)
	template:SetScript("OnLeave", function(self, motion) UIDropDownMenu_StartCounting(self, motion) end)
	template:SetScript("OnClick", function(self) self:Hide() end)
	template:SetScript("OnShow",
	                   function(self)
		                   self:SetFrameLevel(1000)
		                   if self.OnShow then
			                   self:OnShow()
		                   end
	                   end
	)
	template:SetScript("OnHide", function(self) UIDropDownMenu_StopCounting(self) end)
	template:SetScript("OnUpdate", Dropdown.Update)

	return template
end

local function CreateTemplateMenuButton(parent, id)
	local b = CreateFrame("Button", AddOnName .. "_DropdownTemplateMenuButton_" .. id, parent)
	b:SetSize(100,16)

	b.Highlight = b:CreateTexture(nil,"BACKGROUND")
	b.Highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	b.Highlight:SetAllPoints()
	b.Highlight:SetBlendMode("ADD")
	b.Highlight:Hide()

	b.Texture = b:CreateTexture(nil,"BACKGROUND",nil,-8)
	b.Texture:Hide()
	b.Texture:SetAllPoints()

	b.Icon = b:CreateTexture(nil,"ARTWORK")
	b.Icon:SetSize(16,16)
	b.Icon:SetPoint("LEFT")
	b.Icon:Hide()

	b.Arrow = b:CreateTexture(nil,"ARTWORK")
	b.Arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
	b.Arrow:SetSize(16,16)
	b.Arrow:SetPoint("RIGHT")
	b.Arrow:Hide()

	b.NormalText = b:CreateFontString()
	b.NormalText:SetPoint("LEFT")

	b:SetFontString(b.NormalText)
	b:SetNormalFontObject("GameFontHighlightSmallLeft")
	b:SetHighlightFontObject("GameFontHighlightSmallLeft")
	b:SetDisabledFontObject("GameFontDisableSmallLeft")
	b:SetPushedTextOffset(1,-1)

	b:SetScript(
			"OnEnter",
			function(self)
				self.Highlight:Show()
				UIDropDownMenu_StopCounting(self:GetParent())
				-- todo : ELib.ScrollDropDown.OnButtonEnter(self)
				Dropdown.CloseSecondLevel(self.Level)
			end
	)
	b:SetScript(
			"OnLeave",
			function(self)
				self.Highlight:Hide()
				UIDropDownMenu_StartCounting(self:GetParent())
				-- todo
				-- ELib.ScrollDropDown.OnButtonLeave(self)
			end
	)
	b:SetScript(
			"OnClick",
			function(self, button, down)
				local dd = self:GetParent()
				if dd.Props:HandleClick(button, down, self.item) then
					if Util.Objects.In(dd.Props.type, Dropdown.Type.Standard, Dropdown.Type.Radio) then
						Dropdown.Close()
					end
				end
			end
	)
	b:SetScript(
			"OnLoad",
			function(self)
				self:SetFrameLevel(self:GetParent():GetFrameLevel() + 2)
			end
	)

	return b
end

local function CreateTemplateCheckButton(parent, id)
	local b = CreateFrame("CheckButton", AddOnName .. "_DropdownTemplateCheckButton_" .. id, parent)
	b:SetSize(20,20)

	b.text = b:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
	b.text:SetPoint("TOPLEFT",b,"TOPRIGHT",4,0)
	b.text:SetPoint("BOTTOMLEFT",b,"BOTTOMRIGHT",4,0)
	b.text:SetJustifyV("MIDDLE")
	b.Text = b.text

	b:SetFontString(b.text)

	BaseWidget.Border(b,0.24,0.25,0.3,1,1)

	b.Texture = b:CreateTexture(nil,"BACKGROUND")
	b.Texture:SetColorTexture(0,0,0,.3)
	b.Texture:SetPoint("TOPLEFT")
	b.Texture:SetPoint("BOTTOMRIGHT")

	b.CheckedTexture = b:CreateTexture()
	b.CheckedTexture:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	b.CheckedTexture:SetPoint("TOPLEFT",-4,4)
	b.CheckedTexture:SetPoint("BOTTOMRIGHT",4,-4)
	b:SetCheckedTexture(b.CheckedTexture)

	b.PushedTexture = b:CreateTexture()
	b.PushedTexture:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	b.PushedTexture:SetPoint("TOPLEFT",-4,4)
	b.PushedTexture:SetPoint("BOTTOMRIGHT",4,-4)
	b.PushedTexture:SetVertexColor(0.8,0.8,0.8,0.5)
	b.PushedTexture:SetDesaturated(true)
	b:SetPushedTexture(b.PushedTexture)

	b.DisabledTexture = b:CreateTexture()
	b.DisabledTexture:SetTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
	b.DisabledTexture:SetPoint("TOPLEFT",-4,4)
	b.DisabledTexture:SetPoint("BOTTOMRIGHT",4,-4)
	b:SetDisabledTexture(b.DisabledTexture)

	b.HighlightTexture = b:CreateTexture()
	b.HighlightTexture:SetColorTexture(1,1,1,.3)
	b.HighlightTexture:SetPoint("TOPLEFT")
	b.HighlightTexture:SetPoint("BOTTOMRIGHT")
	b:SetHighlightTexture(b.HighlightTexture)
	
	return b
end

local function CreateTemplateRadioButton(parent, id)
	local b = CreateFrame("CheckButton", AddOnName .. "_DropdownTemplateRadioButton_" .. id, parent)
	b:SetSize(16,16)

	b.text = b:CreateFontString(nil,"BACKGROUND","GameFontNormalSmall")
	b.text:SetPoint("LEFT",b,"RIGHT",5,0)
	b.Text = b.text
	b:SetFontString(b.text)

	local texure = BaseWidget.ResolveTexture('radioModern')
	b.NormalTexture = b:CreateTexture()
	b.NormalTexture:SetTexture(texure)
	b.NormalTexture:SetAllPoints()
	b.NormalTexture:SetTexCoord(0,0.25,0,1)
	b:SetNormalTexture(b.NormalTexture)

	b.HighlightTexture = b:CreateTexture()
	b.HighlightTexture:SetTexture(texure)
	b.HighlightTexture:SetAllPoints()
	b.HighlightTexture:SetTexCoord(0.5,0.75,0,1)
	b:SetHighlightTexture(b.HighlightTexture)

	b.CheckedTexture = b:CreateTexture()
	b.CheckedTexture:SetTexture(texure)
	b.CheckedTexture:SetAllPoints()
	b.CheckedTexture:SetTexCoord(0.25,0.5,0,1)
	b:SetCheckedTexture(b.CheckedTexture)
	
	return b
end

local function CreateTemplateButtons(index, level)
	level = level or 1
	Logging:Debug("CreateTemplateButton(index=%d, level=%d)", index, level)
	local dd = Templates[level]
	if dd.Buttons[index] then return end

	local ddButton = CreateTemplateMenuButton(dd, index)
	dd.Buttons[index] = ddButton
	-- drop down menu button
	ddButton:SetPoint("TOPLEFT", 8, -8 - (index-1) * 16)
	ddButton.NormalText:SetMaxLines(1)
	-- drop down check button
	ddButton.checkButton = CreateTemplateCheckButton(ddButton, index)
	ddButton.checkButton:SetPoint("LEFT",1,0)
	ddButton.checkButton:SetSize(12,12)
	-- drop down radio button
	ddButton.radioButton = CreateTemplateRadioButton(ddButton, index)
	ddButton.radioButton:SetPoint("LEFT",1,0)
	ddButton.radioButton:SetSize(12,12)
	ddButton.radioButton:EnableMouse(false)
	ddButton.checkButton:SetScript(
			"OnClick",
			function(self)
				local parent = self:GetParent()
				parent:GetParent().List[parent.index].checkState = self:GetChecked()
				if parent.checkFunc then
					parent.checkFunc(parent, self:GetChecked())
				end
			end
	)
	ddButton.checkButton:SetScript("OnEnter", function(self)  UIDropDownMenu_StopCounting(self:GetParent():GetParent()) end)
	ddButton.checkButton:SetScript("OnLeave", function(self)  UIDropDownMenu_StartCounting(self:GetParent():GetParent()) end)
	ddButton.checkButton:Hide()
	ddButton.radioButton:Hide()
	ddButton.Level = level
end

ReloadTemplates = function(level)
	level = level or -1
	Logging:Debug("ReloadTemplates(%d)", level)
	for templateIndex = 1, #Templates do
		local template = Templates[templateIndex]
		if template:IsShown() or level == templateIndex then
			local pos, len, index = template.Position, #template.List, 0
			for valueIndex = pos, len do
				local item = template.List[valueIndex]
				if not item.IsHidden then
					index = index + 1
					local button, props = template.Buttons[index], template.Props
					local text, icon = button.NormalText, button.Icon
					local paddingLeft = item.padding or 0

					if item.icon then
						icon:SetTexture(item.icon)
						paddingLeft = paddingLeft + 18
						icon:Show()
					else
						icon:Hide()
					end

					button:SetNormalFontObject(GameFontHighlightSmallLeft)
					button:SetHighlightFontObject(GameFontHighlightSmallLeft)

					text:SetText(props:DecorateText(item))
					text:ClearAllPoints()

					local type = props.type
					if Util.Objects.In(type, Dropdown.Type.Radio, Dropdown.Type.Checkbox) then
						text:SetPoint("LEFT", paddingLeft + 16, 0)
					else
						text:SetPoint("LEFT", paddingLeft, 0)
					end
					text:SetPoint("RIGHT", button, "RIGHT", 0, 0)
					text:SetJustifyH(item.justifyH or "LEFT")

					if type == Dropdown.Type.Checkbox then
						button.checkButton:SetChecked(props:HasValue(item.value))
						button.checkButton:Show()
					else
						button.checkButton:Hide()
					end

					if type == Dropdown.Type.Radio then
						button.radioButton:SetChecked(props:HasValue(item.value))
						button.radioButton:Show()
					else
						button.radioButton:Hide()
					end

					--[[
					if item.texture then
						button.Texture:SetTexture(item.texture)
						button.Texture:Show()
					else
						button.Texture:Hide()
					end

					if item.subMenu then
						button.Arrow:Show()
					else
						button.Arrow:Hide()
					end

					if item.isTitle then
						button:SetEnabled(false)
					else
						button:SetEnabled(true)
					end
					--]]

					button.index = index
					--[[
					button.arg1 = item.arg1
					button.arg2 = item.arg2
					button.arg3 = item.arg3
					button.arg4 = item.arg4
					button.func = item.func
					button.hoverFunc = item.hoverFunc
					button.leaveFunc = item.leaveFunc
					button.hoverArg = item.hoverArg
					button.checkFunc = item.checkFunc
					button.tooltip = item.tooltip

					if not item.checkFunc then
						button.checkFunc = function(self) self:Click() end
					end

					button.subMenu = item.subMenu
					--]]

					button.Lines = item.Lines
					button.item = item
					button:Show()

					if index >= template.LinesNow then
						break
					end
				end
			end

			for i=(index+1), Templates[templateIndex].MaxLines do
				Templates[templateIndex].Buttons[i]:Hide()
			end
		end
	end
end

for i = 1, 2 do
	local template = CreateTemplate(i)
	Templates[i]   = template

	template:SetClampedToScreen(true)
	template.Border   = BaseWidget.Shadow(template, 20)
	template.Buttons  = {}
	template.MaxLines = 0
	do
		template.Animation = CreateFrame("Frame", nil, template)
		template.Animation:SetSize(1, 1)
		template.Animation:SetPoint("CENTER")
		template.Animation.P      = 0
		template.Animation.parent = template
		template.Animation:SetScript(
				"OnUpdate",
				function(self, elapsed)
					self.P  = self.P + elapsed
					local P = self.P
					if P > 2.5 then
						P = P % 2.5
						self.P = P
					end
					local color  = P <= 1 and P / 2 or P <= 1.5 and 0.5 or (2.5 - P) / 2
					local parent = self.parent
					parent.BorderTop:SetColorTexture(color, color, color, 1)
					parent.BorderLeft:SetColorTexture(color, color, color, 1)
					parent.BorderBottom:SetColorTexture(color, color, color, 1)
					parent.BorderRight:SetColorTexture(color, color, color, 1)
				end
		)
	end

	template.Slider = NativeUI:New('Slider', template, false)
	template.Slider:SetScript(
			"OnValueChanged",
			function(self, value)
				Logging:Debug("Slider.OnValueChanged(%s)", tostring(value))
				value = Util.Numbers.Round2(value)
				self:GetParent().Position = value
				ReloadTemplates()
			end
	)
	template.Slider:SetScript("OnEnter", function(self) UIDropDownMenu_StopCounting(self:GetParent()) end)
	template.Slider:SetScript("OnLeave", function(self) UIDropDownMenu_StartCounting(self:GetParent()) end)
	template:SetScript(
			"OnMouseWheel",
			function(self, delta)
				local min, max = self.Slider:GetMinMaxValues()
				local val = self.Slider:GetValue()
				if (val - delta) < min then
					self.Slider:SetValue(min)
				elseif (val - delta) > max then
					self.Slider:SetValue(max)
				else
					self.Slider:SetValue(val - delta)
				end
			end
	)
end


function Dropdown.ToggleDropDownMenu(self, level)
	level = level or 1
	Logging:Debug("ToggleDropDownMenu(%d)", level)
	if self.ToggleUpadte then self:ToggleUpadte() end
	for i = (level + 1), #Templates do Templates[i]:Hide() end

	local template, width = Templates[level], Util.Objects.IsNumber(self.Props.width) and self.Props.width or 200
	Dropdown.InjectIntoTemplate(self, template)

	local count = #template.List
	local maxLines = self.Props.lines or count
	for i = (template.MaxLines + 1), maxLines do
		CreateTemplateButtons(i, level)
	end
	template.MaxLines = max(template.MaxLines, maxLines)

	local isSliderHidden = max(count - maxLines + 1, 1) == 1
	for i = 1, maxLines do
		template.Buttons[i]:SetSize(width - 16 - (isSliderHidden and 0 or 12), 16)
	end

	template.Position = 1
	template.LinesNow = maxLines
	template.Slider:SetValue(1)
	template:ClearAllPoints()
	template:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -16, 0)
	template.Slider:SetMinMaxValues(1, max(count - maxLines + 1, 1))
	template:SetSize(width, 16 + 16 * maxLines)
	template.Slider:SetHeight(maxLines * 16)
	if isSliderHidden then template.Slider:Hide() else template.Slider:Show() end

	template:ClearAllPoints()
	if level > 1 then
		if width and width + Templates[level - 1]:GetRight() > GetScreenWidth() then
			template:SetPoint("TOP", self, "TOP", 0, 8)
			template:SetPoint("RIGHT", Templates[level - 1], "LEFT", -5, 0)
		else
			template:SetPoint("TOPLEFT", self, "TOPRIGHT", level > 1 and Templates[level - 1].Slider:IsShown() and 24 or 12, 8)
		end
	else
		local toggleX = self.toggleX or -16
		local toggleY = self.toggleY or 0
		template:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", toggleX, toggleY)
	end

	template.parent = self
	template:Show()
	template:SetFrameLevel(0)
	ReloadTemplates()
end

NativeUI:RegisterWidget('Dropdown', Dropdown)