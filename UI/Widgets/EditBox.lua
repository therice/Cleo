local _, AddOn = ...
-- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
local Logging = AddOn:GetLibrary('Logging')

--- @class UI.Widgets.EditBox
local EditBox = AddOn.Package('UI.Widgets'):Class('EditBox', BaseWidget)

function EditBox:initialize(parent, name, maxLetters, numeric)
    BaseWidget.initialize(self, parent, name)
    self.maxLetters = maxLetters
    self.numeric = numeric
end

function EditBox:Create()
    local eb = CreateFrame("EditBox", self.name, self.parent, BackdropTemplateMixin and "BackdropTemplate")
    eb:EnableMouse(true)

    BaseWidget.Border(eb,0.24,0.25,0.3,1,1)

    eb.Background = eb:CreateTexture(nil,"BACKGROUND")
    eb.Background:SetColorTexture(0,0,0,.3)
    eb.Background:SetPoint("TOPLEFT")
    eb.Background:SetPoint("BOTTOMRIGHT")

    eb:SetFontObject("GameFontHighlightSmall")
    eb:SetTextInsets(4, 4, 0, 0)

    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    eb:SetAutoFocus(false)

    if self.maxLetters then eb:SetMaxLetters(self.maxLetters) end
    if self.numeric then eb:SetNumeric(true) end

    BaseWidget.Mod(
        eb,
        'Text', EditBox.SetText,
        'TextInsets', EditBox.SetTextInsets,
        'Tooltip', EditBox.SetTooltip,
        'ClearTooltip', EditBox.ClearTooltip,
        'OnChange', EditBox.OnChange,
        'OnFocus', EditBox.OnFocus,
        'InsideIcon', EditBox.InsideIcon,
        'InsideTexture', EditBox.InsideTexture,
        'AddSearchIcon',EditBox.AddSearchIcon,
        'LeftText', EditBox.AddLeftText,
        'TopText', EditBox.AddTopText,
        'BackgroundText',EditBox.AddBackgroundText,
        'GetBackgroundText',EditBox.GetBackgroundText,
        'ColorBorder', EditBox.ColorBorder,
        'GetTextHighlight', EditBox.GetTextHighlight,
        'OnDatasourceConfigured',  EditBox.OnDatasourceConfigured,
        'OnDatasourceCleared',  EditBox.OnDatasourceCleared,
        'AddXButton', EditBox.AddXButton,
        'Color', EditBox.Color
    )

    return eb
end

function EditBox.OnDatasourceConfigured(self)
    self:OnChange(Util.Functions.Noop)
    self:Text(self.ds:Get())
    self:OnChange(
        Util.Functions.Debounce(
            function(self, userInput)
                Logging:Trace("EditBox.OnChange(%s)", tostring(userInput))
                if userInput then
                    self.ds:Set(self:GetText())
                end
            end, -- function
            1, -- seconds
            true -- leading
        )
    )
end

function EditBox.OnDatasourceCleared(self)
    self:OnChange(Util.Functions.Noop)
    self:Text(nil)
end

function EditBox.Color(self, colR, colG, colB, colA)
    if Util.Objects.IsString(colR) then
        local r, g, b = colR:sub(-6, -5), colR:sub(-4, -3), colR:sub(-2, -1)
        colR, colG, colB = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
        colR = (colR or 255) / 255
        colG = (colG or 255) / 255
        colB = (colB or 255) / 255
    end
    self:SetTextColor(colR or 1, colG or 1, colB or 1, colA or 1)
    return self
end

function EditBox.SetText(self, text)
    self:SetText(text or "")
    self:SetCursorPosition(text and #text or 0)
    return self
end

function EditBox.SetTextInsets(self, left, right, top, bottom)
    local l, r, t, b = self:GetTextInsets()

    left = Util.Objects.Default(left, l)
    right = Util.Objects.Default(right, r)
    top = Util.Objects.Default(top, t)
    bottom = Util.Objects.Default(bottom, b)

    self:SetTextInsets(left, right, top, bottom)
    return self
end


function EditBox.ClearTooltip(self)
    self.tipTitle = nil
    self.tipLines = nil
    self:SetScript("OnEnter", nil)
    self:SetScript("OnLeave", nil)
    return self
end

function EditBox.SetTooltip(self, title, ...)
    self.tipTitle = title
    self.tipLines = {...}

    self:SetScript(
        "OnEnter",
        function(self)
            local lines = Util.Tables.Copy(self.tipLines or {})
            UIUtil.ShowTooltip(self, nil, self.tipTitle, unpack(lines))
        end
    )

    self:SetScript("OnLeave", function() UIUtil:HideTooltip() end)

    return self
end

function EditBox.OnChange(self, fn)
    self:SetScript("OnTextChanged",fn)
    return self
end

function EditBox.OnFocus(self,gained,lost)
    self:SetScript("OnEditFocusGained",gained)
    self:SetScript("OnEditFocusLost",lost)
    return self
end

function EditBox.InsideIcon(self,texture,size,offset)
    self.insideIcon = self.insideIcon or self:CreateTexture(nil, "BACKGROUND",nil,2)
    self.insideIcon:SetPoint("RIGHT",-(offset or 2),0)
    self.insideIcon:SetSize(size or 14,size or 14)
    self.insideIcon:SetTexture(texture or "")
    return self
end

function EditBox.InsideTexture(self, texture, size, tcoord, color)
    self.insideTexture = self.insideTexture or self:CreateTexture(nil, "ARTWORK", nil, 2)
    self.insideTexture:SetTexture(texture)
    self.insideTexture:SetPoint("RIGHT", 2, 0)
    self.insideTexture:SetSize(size or 14,size or 14)
    if Util.Objects.IsTable(tcoord) then self.insideTexture:SetTexCoord(unpack(tcoord)) end
    if Util.Objects.IsTable(color) then self.insideTexture:SetVertexColor(unpack(color)) end
    return self
end

function EditBox.AddSearchIcon(self,size)
    return self:InsideIcon([[Interface\Common\UI-Searchbox-Icon]], size or 15)
end

function EditBox.AddXButton(self, size)
    self.xButton = NativeUI:New('ButtonClose', self):Point("RIGHT", 2, 0):Size(size or 14,size or 14)
    return self
end

function EditBox.AddLeftText(self,text,size)
    if self.leftText then
        self.leftText:SetText(text)
    else
        self.leftText = NativeUI:New('Text', self, text, size or 11):Point("RIGHT",self,"LEFT",-5,0):Right()
    end
    return self
end

function EditBox.AddTopText(self,text,size)
    if self.leftText then
        self.leftText:SetText(text)
    else
        self.leftText = NativeUI:New('Text', self, text, size or 11):Point("BOTTOM",self,"TOP",0,2)
    end
    return self
end

function EditBox.AddBackgroundText(self,text, preserve)
    preserve = Util.Objects.Default(preserve, false)

    if not self.backgroundText then
        self.backgroundText =
            NativeUI:New('Text', self, nil, 12, "GameFontNormalSmall")
                :Point("LEFT",2,0):Point("RIGHT",-2,0)
                :Color(.5,.5,.5)
    end

    local function FocusGained(self)
        if not preserve then
            self.backgroundText:SetText("")
        end
    end

    local function FocusLost(self)
        local text = self:GetText()
        if not text or text == "" then
            self.backgroundText:SetText(self.backText)
        end
    end

    local function BgCheck(self)
        local text = self:GetText()
        if (not text or Util.Strings.IsEmpty(text))and not self:HasFocus() then
            self.backgroundText:SetText(self.backText)
        else
            if not preserve then
                self.backgroundText:SetText("")
            end
        end
    end

    self.backText = text
    self:OnFocus(FocusGained, FocusLost)
    self.BackgroundTextCheck = BgCheck
    self:BackgroundTextCheck()
    return self
end

function EditBox.GetBackgroundText(self)
    return self.backText
end

function EditBox.ColorBorder(self,cR,cG,cB,cA)
    if Util.Objects.IsNumber(cR) then
        BaseWidget.Border(self,cR,cG,cB,cA,1)
    elseif cR then
        BaseWidget.Border(self,0.74,0.25,0.3,1,1)
    else
        BaseWidget.Border(self,0.24,0.25,0.3,1,1)
    end
    return self
end

function EditBox.GetTextHighlight(self)
    local text,cursor = self:GetText(),self:GetCursorPosition()
    self:Insert("")
    local textNew, cursorNew = self:GetText(), self:GetCursorPosition()
    self:SetText( text )
    self:SetCursorPosition( cursor )
    local spos, epos = cursorNew, #text - ( #textNew - cursorNew )
    self:HighlightText(spos, epos)
    return spos, epos
end

NativeUI:RegisterWidget('EditBox', EditBox)