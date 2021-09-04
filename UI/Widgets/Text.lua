local _, AddOn = ...
local NativeUI = AddOn.Require('UI.Native')
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
local Text = AddOn.Package('UI.Widgets'):Class('Text', BaseWidget)

function Text:initialize(parent, name, text)
    BaseWidget.initialize(self, parent, name)
    self.text = text
end

function Text:Create()
    local f = CreateFrame(
            "Frame",
            self.parent:GetName() .. '_' .. self.name,
            self.parent
    )
    local t = f:CreateFontString(self.parent:GetName().."_Text", "OVERLAY", "GameFontNormal")
    f.text = t
    t:SetPoint("CENTER")
    t:SetText(self.text)
    local height, width = f.SetHeight, f.SetWidth
    function f:SetHeight (h)
        height(self,h)
        t:SetHeight(h)
    end
    function f:SetWidth(w)
        width(self, w)
        t:SetWidth(w)
    end
    function f:SetTextColor(...)
        t:SetTextColor(...)
    end
    function f:SetText(...)
        t:SetText(...)
    end
    function f:GetStringWidth()
        return t:GetStringWidth()
    end
    return f
end

NativeUI:RegisterWidget('Text', Text)