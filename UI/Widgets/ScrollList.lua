-- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
-- @type LibLogging
local Logging = AddOn:GetLibrary('Logging')
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @class UI.Widgets.ScrollList
local ScrollList = AddOn.Package('UI.Widgets'):Class('ScrollList', BaseWidget)

function ScrollList:initialize(parent, name, list)
	BaseWidget.initialize(self, parent, name)
	self.list = list
end

function ScrollList:Create()
	local sl = CreateFrame("Frame", self.name, self.parent)
	sl.frame = NativeUI:New('ScrollFrame', sl):Point(0, 0)

	BaseWidget.LayerBorder(sl, 2, .24, .25, .30, 1)
	BaseWidget.LayerBorder(sl, 1, 0, 0, 0, 1, 2, 1)

	-- these are all reasonable defaults, but can be changed
	sl.linesPerPage, sl.lineHeight, sl.linePaddingLeft = 1, 16, 7
	sl.fontName, sl.fontSize, sl.lineTexture, sl.ignoreBlend  = nil, 12, BaseWidget.ResolveTexture('white'), true
	sl.lineTextureHeight, sl.lineTextureColorHL, sl.lineTextureColorP = 24, {C.Colors.Grey:GetRGBA()} --[[{1.0, 1.0, 1.0, 0.5}--]], {C.Colors.Salmon:GetRGBA()} --[[{1.0, 0.82, 0.0, 0.6}--]]
	sl.enableHoverAnimation = true

	-- List tracks the actual display items
	-- L is the raw values (indexes) from which they are created
	sl.List = {}
	sl.L, sl.LDisabled = self.list or {}, {}

	BaseWidget.Mod(
		sl,
		'Update', ScrollList.Update,
		'FontSize', ScrollList.FontSize,
		'Font', ScrollList.Font,
		'LineHeight', ScrollList.SetLineHeight,
		'AddDrag', ScrollList.AddDrag,
		'HideBorders', ScrollList.HideBorders,
		'SetTo', ScrollList.SetTo
	)

	sl._Size = sl.Size
	sl.Size = ScrollList.SetSize
	sl.frame.ScrollBar:SetScript(
			"OnValueChanged",
			function(self, value)
				local parent = self:GetParent():GetParent()
				parent:SetVerticalScroll(value % (parent:GetParent().lineHeight))
				self:UpdateButtons()
				parent:GetParent():Update()
			end
	)
	sl:SetScript("OnShow", sl.Update)
	sl:SetScript(
			"OnMouseWheel",
			function(self, delta)
				if delta > 0 then
					self.frame.ScrollBar.buttonUp:Click("LeftButton")
				else
					self.frame.ScrollBar.buttonDown:Click("LeftButton")
				end
			end
	)

	return sl
end

function ScrollList.SetLineHeight(self, height)
	self.lineHeight = height
	return self
end

function ScrollList.FontSize(self,size)
	self.fontSize = size
	for i=1,#self.List do
		self.List[i].text:SetFont(self.List[i].text:GetFont(),size)
	end

	--[[
	if not self.T then
		for i=1,#self.List do
			self.List[i].text:SetFont(self.List[i].text:GetFont(),size)
		end
	else
		for i=1,#self.List do
			for j=1,#self.T do
				self.List[i]['text'..j]:SetFont(self.List[i]['text'..j]:GetFont(),size)
			end
		end
	end
	--]]
	return self
end

function ScrollList.Font(self, name , size)
	self.fontName = name
	self.fontSize = size
	for i=1,#self.List do
		self.List[i].text:SetFont(name,size)
	end

	--[[
	if not self.T then
		for i=1,#self.List do
			self.List[i].text:SetFont(name,size)
		end
	else
		for i=1,#self.List do
			for j=1,#self.T do
				self.List[i]['text'..j]:SetFont(name,size)
			end
		end
	end
	--]]
	return self
end

function ScrollList.AddDrag(self)
	self.dragAdded = true
	for _, line in ipairs(self.List) do
		line:SetMovable(true)
		line:RegisterForDrag("LeftButton")
	end
	return self
end

function ScrollList.HideBorders(self)
	BaseWidget.LayerBorder(self.frame, 0)
	BaseWidget.LayerBorder(self,0)
	BaseWidget.LayerBorder(self,0,nil,nil,nil,nil,nil,1)
	return self
end


function ScrollList.SetTo(self, index)
	self.selected = index
	self:Update()
	return self
end

function ScrollList.SetSize(self, width, height)
	self:_Size(width,height)
	self.frame:Size(width,height):Height(height+self.lineHeight)
	self.linesPerPage = height / self.lineHeight + 1
	self.frame.ScrollBar:Range(0, max(0, #self.L * self.lineHeight - 1 - height)):UpdateButtons()
	self:Update()
	return self
end

function ScrollList.LineClick(self, button, ...)
	Logging:Debug("ScrollList.LineClick")

	local parent = self.mainFrame
	ScrollList.SetTo(parent, self.index)
	if parent.SetListValue then
		parent:SetListValue(self.index, button, ...)
	end
end

function ScrollList.LineEnter(self)
	local parent = self.mainFrame
	Logging:Debug("ScrollList.LineEnter : %s", Util.Objects.ToString(parent:GetName()))
	if parent.HoverListValue then
		parent:HoverListValue(true, self.index, self)
		parent.hoveredLine = self
	end

	if parent.enableHoverAnimation then
		if not self.anim then
			self.anim = self:CreateAnimationGroup()
			self.anim:SetLooping("NONE")
			self.anim.timer = self.anim:CreateAnimation()
			self.anim.timer:SetDuration(.25)
			self.anim.timer.line = self
			self.anim.timer.main = parent
			self.anim.timer:SetScript("OnUpdate", function(self, _)
				local p = self:GetProgress()
				local cR, cG, cB, cA =
					self.fR + (self.tR - self.fR) * p,
					self.fG + (self.tG - self.fG) * p,
					self.fB + (self.tB - self.fB)* p,
					self.fA + (self.tA - self.fA) * p
				self.cR, self.cG, self.cB, self.cA = cR, cG, cB, cA
				self.line.AnimTexture:SetColorTexture(cR,cG,cB,cA)
			end)
			self.HighlightTexture:SetVertexColor(0,0,0,0)
			self.anim.timer.cR, self.anim.timer.cG, self.anim.timer.cB, self.anim.timer.cA = 0.5, 0.5, 0.5, 0.2

			self.anim:SetScript("OnFinished", function(self, _)
				if self.timer.hideOnEnd then
					local t = self:GetParent().AnimTexture
					t:Hide()
					t:SetColorTexture(.5, .5, .5, .2)
					self.timer.cR, self.timer.cG, self.timer.cB, self.timer.cA = 0.5, 0.5, 0.5, 0.2
				end
			end)

			self.AnimTexture = self:CreateTexture()
			self.AnimTexture:SetPoint("LEFT",0,0)
			self.AnimTexture:SetPoint("RIGHT",0,0)
			self.AnimTexture:SetHeight(parent.lineTextureHeight or 15)
			self.AnimTexture:SetColorTexture(self.anim.timer.cR, self.anim.timer.cG, self.anim.timer.cB, self.anim.timer.cA)
		end

		if self.anim:IsPlaying() then self.anim:Stop() end
		local t = self.anim.timer
		t.fR, t.fG, t.fB, t.fA = t.cR, t.cG, t.cB, t.cA
		-- Logging:Debug("ScrollList.LineEnter: lineTextureColorHL=%s", Util.Objects.ToString(parent.lineTextureColorHL))
		if parent.lineTextureColorHL then
			t.tR, t.tG, t.tB, t.tA = unpack(parent.lineTextureColorHL)
		else
			t.tR, t.tG, t.tB, t.tA = 1, 1, 1, 1
		end
		t.hideOnEnd = false
		self.anim:Play()
		self.AnimTexture:Show()
	end
end

function ScrollList.LineLeave(self)
	local parent = self.mainFrame
	if parent.HoverListValue then
		parent:HoverListValue(false, self.index, self)
	end
	parent.hoveredLine = nil

	if parent.enableHoverAnimation then
		if self.anim:IsPlaying() then self.anim:Stop() end
		local t = self.anim.timer
		t.fR, t.fG, t.fB, t.fA = t.cR, t.cG, t.cB, t.cA
		t.tR, t.tG, t.tB, t.tA = .5, .5, .5, 0
		t.hideOnEnd = true
		self.anim:Play()
	end
end

function ScrollList.LineOnDragStart(self)
	if self:IsMovable() then
		if self.ignoreDrag then return end
		self.points = {}
		for i = 1, self:GetNumPoints() do
			self.points[i] = { self:GetPoint() }
		end

		GameTooltip_Hide()
		self:StartMoving()
	end
end

function ScrollList.LineOnDragEnd(self)
	self:StopMovingOrSizing()
	if not self.points then return end

	local parent = self.mainFrame
	if parent.OnDragFunction then
		local swapLine
		for _, line in ipairs(parent.List) do
			if line ~= self and line:IsShown() and MouseIsOver(line) then
				swapLine = line
				break
			end
		end
		if swapLine then
			parent:OnDragFunction(self, swapLine)
		end
	end

	self:ClearAllPoints()
	for i=1,#self.points do
		self:SetPoint(unpack(self.points[i]))
	end
	self.points = nil
end

function ScrollList.AddLine(self, index)
	local line = CreateFrame("Button", nil, self.frame.content)
	self.List[index] = line
	line:SetPoint("TOPLEFT", 0, -(index - 1) * self.lineHeight)
	line:SetPoint("BOTTOMRIGHT", self.frame.content, "TOPRIGHT", 0, -index * self.lineHeight)
	line.text =
		NativeUI:New('Text', line, "List" .. tostring(index), self.fontSize or 12)
			:Point("LEFT", --[[(self.isCheckList and 24 or 3)--]] 3  + self.linePaddingLeft ,0)
			:Point("RIGHT",-3,0)
			:Size(0, self.lineHeight)
			:Color():Shadow()

	if self.fontName then line.text:Font(self.fontName, self.fontSize) end
	line:SetFontString(line.text)
	line:SetPushedTextOffset(2, -1)

	line.background = line:CreateTexture(nil, "BACKGROUND")
	line.background:SetPoint("TOPLEFT")
	line.background:SetPoint("BOTTOMRIGHT")

	line.HighlightTexture = line:CreateTexture()
	line.HighlightTexture:SetTexture(self.lineTexture or "Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	if not self.ignoreBlend then line.HighlightTexture:SetBlendMode("ADD") end
	line.HighlightTexture:SetPoint("LEFT",0,0)
	line.HighlightTexture:SetPoint("RIGHT",0,0)
	line.HighlightTexture:SetHeight(self.lineTextureHeight or 15)
	if self.lineTextureColorHL then
		line.HighlightTexture:SetVertexColor(unpack(self.lineTextureColorHL))
	else
		line.HighlightTexture:SetVertexColor(1,1,1,1)
	end
	line:SetHighlightTexture(line.HighlightTexture)

	line.PushedTexture = line:CreateTexture()
	line.PushedTexture:SetTexture(self.lineTexture or "Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	if not self.ignoreBlend then line.PushedTexture:SetBlendMode("ADD") end
	line.PushedTexture:SetPoint("LEFT",0,0)
	line.PushedTexture:SetPoint("RIGHT",0,0)
	line.PushedTexture:SetHeight(self.lineTextureHeight or 15)
	if self.lineTextureColorP then
		line.PushedTexture:SetVertexColor(unpack(self.lineTextureColorP))
	else
		line.PushedTexture:SetVertexColor(1,1,0,1)
	end
	line:SetDisabledTexture(line.PushedTexture)

	line.iconRight = line:CreateTexture()
	line.iconRight:SetPoint("RIGHT",-3,0)
	line.iconRight:SetSize(self.lineHeight, self.lineHeight)

	line.mainFrame = self
	line.id = index
	line:SetScript("OnClick", ScrollList.LineClick)
	line:SetScript("OnEnter", ScrollList.LineEnter)
	line:SetScript("OnLeave", ScrollList.LineLeave)
	line:RegisterForClicks("LeftButtonUp","RightButtonUp")
	line:SetScript("OnDragStart", ScrollList.LineOnDragStart)
	line:SetScript("OnDragStop", ScrollList.LineOnDragEnd)

	return line
end

function ScrollList.Update(self)
	local val, index = floor(self.frame.ScrollBar:GetValue() / self.lineHeight) + 1, 0
	-- Logging:Debug("ScrollList.Update(value=%d)", val)

	for current = val, #self.L do
		index = index + 1
		-- Logging:Debug("ScrollList.Update(current=%d, index=%d)", current, index)
		local line = self.List[index]
		if not line then line = ScrollList.AddLine(self, index) end

		local l = self.L[current]
		if Util.Objects.IsTable(l) then
			line:SetText(l[1])
		else
			line:SetText(l)
		end

		if not self.dontDisable then
			if current ~= self.selected then
				line:SetEnabled(true)
				line.ignoreDrag = false
			else
				line:SetEnabled(nil)
				line.ignoreDrag = true
			end
		end

		--[[
		if self.LDisabled then
			if self.LDisabled[current] then
				line:SetEnabled(false)
				line.ignoreDrag = true
				line.text:Color(.5,.5,.5,1)
				line.PushedTexture:SetAlpha(0)
			else
				line.text:Color()
				line.PushedTexture:SetAlpha(1)
			end
		end
		--]]

		line:Show()
		line.index = current
		line.table = self.L[current]
		if (index >= #self.L) or (index >= self.linesPerPage) then
			break
		end
	end

	for hideIndex=(index+1), #self.List do
		self.List[hideIndex]:Hide()
	end

	self.frame.ScrollBar:Range(0, max(0, #self.L * self.lineHeight - 1 - self:GetHeight()), self.lineHeight, true):UpdateButtons()

	--[[
	Logging:Debug(
		"ScrollList.Update() : height=%d, lineHeight=%d, #L=%d, evaluating=%d",
		self:GetHeight(), self.lineHeight, #self.L, (self:GetHeight() / self.lineHeight - #self.L)
	)
	--]]

	if (self:GetHeight() / self.lineHeight - #self.L) > 0 then
		-- Logging:Debug("ScrollList.Update() : Hiding ScrollBar (width=%d)", self.frame:GetWidth())
		self.frame.ScrollBar:Hide()
		self.frame.content:SetWidth(self.frame:GetWidth())
	else
		-- Logging:Debug("ScrollList.Update() : Showing ScrollBar (width=%d)", self.frame:GetWidth() - self.lineHeight)
		self.frame.ScrollBar:Show()
		self.frame.content:SetWidth(self.frame:GetWidth() - self.lineHeight)
	end

	if self.hoveredLine then
		local hovered = self.hoveredLine
		ScrollList.LineLeave(hovered)
		ScrollList.LineEnter(hovered)
	end

	return self
end


NativeUI:RegisterWidget('ScrollList', ScrollList)