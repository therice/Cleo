local _, AddOn = ...
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @class UI.Widgets.Text
local Text = AddOn.Package('UI.Widgets'):Class('Text', BaseWidget)

function Text:initialize(parent, name, text, size, font)
    BaseWidget.initialize(self, parent, name)
    self.text = text or ""
    self.size = size or 12
    self.font = font or "GameFontNormalSmall"
end

function Text:Create()
    local text = self.parent:CreateFontString(nil, "ARTWORK", self.font)
    if self.size then
        local fn = text:GetFont()
        if fn then text:SetFont(fn, self.size) end
    end

    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    text:SetText(self.text)

    BaseWidget.Mod(
            text,
            'Font', Text.SetFont,
            'Color', Text.Color,
            'Left', Text.Left,
            'Center', Text.Center,
            'Right', Text.Right,
            'Top', Text.Top,
            'Middle', Text.Middle,
            'Bottom', Text.Bottom,
            'Shadow', Text.Shadow,
            'Outline', Text.Outline,
            'FontSize', Text.FontSize,
            -- 'Tooltip', Text.Tooltip,
            'MaxLines', Text.MaxLines
    )

    return text
end

function Text.SetFont(self, ...)
    self:SetFont(...)
    return self
end

function Text.Color(self, colR, colG, colB, colA)
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

function Text.Left(self)
    self:SetJustifyH("LEFT")
    return self
end

function Text.Center(self)
    self:SetJustifyH("CENTER")
    return self
end

function Text.Right(self)
    self:SetJustifyH("RIGHT")
    return self
end

function Text.Top(self)
    self:SetJustifyV("TOP")
    return self
end

function Text.Middle(self)
    self:SetJustifyV("MIDDLE")
    return self
end

function Text.Bottom(self)
    self:SetJustifyV("BOTTOM")
    return self
end

function Text.Shadow(self,disable)
    self:SetShadowColor(0,0,0,disable and 0 or 1)
    self:SetShadowOffset(1,-1)
    return self
end

function Text.Outline(self, disable)
    local filename, fontSize = self:GetFont()
    self:SetFont(filename, fontSize, (not disable) and "OUTLINE")
    return self
end

function Text.FontSize(self, size)
    local filename, _, fontParam1, fontParam2, fontParam3 = self:GetFont()
    self:SetFont(filename, size, fontParam1, fontParam2, fontParam3)
    return self
end

function Text.MaxLines(self,num)
    self:SetMaxLines(num)
    return self
end

NativeUI:RegisterWidget('Text', Text)