local _, AddOn = ...
local NativeUI = AddOn.Require('UI.Native')
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
local GameTooltip = AddOn.Package('UI.Widgets'):Class('GameTooltip', BaseWidget)

function GameTooltip:initialize(parent, name)
    BaseWidget.initialize(self, parent, name)
end

function GameTooltip:Create()
    local tt = CreateFrame("GameTooltip", self.name, self.parent, "GameTooltipTemplate")
    tt:SetClampedToScreen(false)
    tt:SetScale(self.parent:GetScale() * 0.95 or 1)
    if self.parent.content then
        self.parent.content:SetScript(
            "OnSizeChanged",
            function()
                tt:SetScale(self.parent:GetScale() * 0.95 or 1)
            end
        )
    end
    return tt
end

NativeUI:RegisterWidget('GameTooltip', GameTooltip)