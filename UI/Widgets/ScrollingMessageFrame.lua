local _, AddOn = ...
local NativeUI = AddOn.Require('UI.Native')
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
local ScrollingMessageFrame = AddOn.Package('UI.Widgets'):Class('ScrollingMessageFrame', BaseWidget)

function ScrollingMessageFrame:initialize(parent, name)
    BaseWidget.initialize(self, parent, name)
end

local function ScrollingFunction(self, arg)
    if arg > 0 then
        if IsShiftKeyDown() then self:ScrollToTop() else self:ScrollUp() end
    elseif arg < 0 then
        if IsShiftKeyDown() then self:ScrollToBottom() else self:ScrollDown() end
    end
end

function ScrollingMessageFrame:Create()
    local smf = CreateFrame(
            "ScrollingMessageFrame",
            self.parent:GetName() .. '_' .. self.name,
            self.parent,
            BackdropTemplateMixin and "BackdropTemplate"
    )
    smf:SetFading(false)
    smf:SetFontObject(GameFontHighlightLeft)
    smf:EnableMouseWheel(true)
    smf:SetBackdrop(
            {
                bgFile   = BaseWidget.ResolveTexture('white'),
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile     = true, tileSize = 8, edgeSize = 4,
                insets   = { left = 2, right = 2, top = 2, bottom = 2 }
            }
    )
    smf:SetBackdropColor(0, 0, 0, 1)
    smf:SetBackdropBorderColor(0, 0, 0, 1)
    smf:SetWidth(self.parent:GetWidth() - 25)
    smf:SetHeight(self.parent:GetHeight() - 50)
    smf:SetPoint("CENTER", self.parent, "CENTER")
    smf:SetScript("OnMouseWheel", ScrollingFunction)
    return smf
end

NativeUI:RegisterWidget('ScrollingMessageFrame', ScrollingMessageFrame)