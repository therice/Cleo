--- @type AddOn
local _, AddOn = ...
local C = AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
---@type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
local Button = AddOn.Package('UI.Widgets'):Class('Button', BaseWidget)

function Button:initialize(parent, name, text)
    BaseWidget.initialize(self, parent, name)
    self.text = text or ""
end

-- Button()
function Button:Create()
    local b = CreateFrame("Button", self.name, self.parent)
    b:SetText("")
    b:SetSize(100, 20)

    b.textFont = b:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    b.textFont:SetPoint("CENTER", b, "CENTER")
    b.textFont:SetJustifyV("MIDDLE")
    b.Text = b.textFont
    b.Text:SetText(self.text)
    b:SetFontString(b.Text)

    b.HighlightTexture = b:CreateTexture()
    b.HighlightTexture:SetColorTexture(1,1,1,.3)
    b.HighlightTexture:SetAllPoints(b)
    b:SetHighlightTexture(b.HighlightTexture)

    b.PushedTexture = b:CreateTexture()
    b.PushedTexture:SetColorTexture(.9,.8,.1,.3)
    b.PushedTexture:SetAllPoints(b)
    b:SetPushedTexture(b.PushedTexture)

    b:SetNormalFontObject("GameFontNormal")
    b:SetHighlightFontObject("GameFontHighlight")
    b:SetDisabledFontObject("GameFontDisable")

    self.Border(b, 0, 0, 0, 1, 1)

    b.Texture = b:CreateTexture(nil,"BACKGROUND")
    b.Texture:SetColorTexture(1,1,1,1)
    BaseWidget.Textures.SetGradientAlpha(b.Texture,"VERTICAL",0.05,0.06,0.09,1, 0.20,0.21,0.25,1)
    b.Texture:SetAllPoints(b)

    b.DisabledTexture = b:CreateTexture()
    b.DisabledTexture:SetColorTexture(0.20,0.21,0.25,0.5)
    b.DisabledTexture:SetAllPoints(b)
    b:SetDisabledTexture(b.DisabledTexture)

    b.HideTextures = function(self)
        self.Texture:Hide()
        self.HighlightTexture:Hide()
        self.PushedTexture:Hide()
        self.DisabledTexture:Hide()
        self:HideBorders()
    end

    BaseWidget.Mod(
        b,
        'Tooltip', Button.SetTooltip,
        'GetTextObj', Button.GetTextObj,
        'FontSize', Button.SetFontSize
    )

    b._Disable = b.Disable
    b.Disable = Button.Disable

    return b
end

function Button:Disable()
    self:_Disable()
    return self
end

function Button:GetTextObj()
    for i = 1, self:GetNumRegions() do
        local obj = select(i, self:GetRegions())
        if obj.GetText and obj:GetText() == self:GetText() then
            return obj
        end
    end
end

function Button:SetFontSize(size)
    local obj = self:GetFontString()
    obj:SetFont(obj:GetFont(),size)
    return self
end

function Button:SetTooltip(tooltip)
    self.tooltip = self:GetText()
    if Util.Objects.IsEmpty(self.tooltip) or not self.tooltip then
        self.tooltip = tooltip
    else
        self.tooltipText = tooltip
    end
    self:SetScript(
        "OnEnter",
        function(self)
            UIUtil.ShowTooltip(
                    self,
                    "ANCHOR_RIGHT",
                    self.tooltip,
                   { Util.Objects.IsFunction(self.tooltipText) and self.tooltipText(self) or self.tooltipText, 1, 1, 1 }
            )
        end
    )
    self:SetScript("OnLeave", function() UIUtil:HideTooltip() end)
    return self
end

NativeUI:RegisterWidget('Button', Button)
