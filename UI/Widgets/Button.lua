local _, AddOn = ...
local NativeUI = AddOn.Require('UI.Native')
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
local Button = AddOn.Package('UI.Widgets'):Class('Button', BaseWidget)

function Button:initialize(parent, name)
    BaseWidget.initialize(self, parent, name)
end

function Button:Create()
    local b = CreateFrame("Button", self.parent:GetName() .. '_' .. self.name, self.parent)
    b:SetText("")
    b:SetSize(100,20)

    b.text = b:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    -- b.text:SetPoint("TOPLEFT",b,"TOPRIGHT",4,0)
    -- b.text:SetPoint("BOTTOMLEFT",b,"BOTTOMRIGHT",4,0)
    b.text:SetPoint("CENTER", b, "CENTER")
    b.text:SetJustifyV("MIDDLE")
    b.Text = b.text

    b:SetFontString(b.Text)

    b.HighlightTexture = b:CreateTexture()
    b.HighlightTexture:SetColorTexture(1,1,1,.3)
    b.HighlightTexture:SetPoint("TOPLEFT")
    b.HighlightTexture:SetPoint("BOTTOMRIGHT")
    b:SetHighlightTexture(b.HighlightTexture)

    b.PushedTexture = b:CreateTexture()
    b.PushedTexture:SetColorTexture(.9,.8,.1,.3)
    b.PushedTexture:SetPoint("TOPLEFT")
    b.PushedTexture:SetPoint("BOTTOMRIGHT")
    b:SetPushedTexture(b.PushedTexture)

    b:SetNormalFontObject("GameFontNormal")
    b:SetHighlightFontObject("GameFontHighlight")
    b:SetDisabledFontObject("GameFontDisable")

    self.Border(b, 0, 0, 0, 1, 1)

    b.Texture = b:CreateTexture(nil,"BACKGROUND")
    b.Texture:SetColorTexture(1,1,1,1)
    b.Texture:SetGradientAlpha("VERTICAL",0.05,0.06,0.09,1, 0.20,0.21,0.25,1)
    b.Texture:SetPoint("TOPLEFT")
    b.Texture:SetPoint("BOTTOMRIGHT")

    b.DisabledTexture = b:CreateTexture()
    b.DisabledTexture:SetColorTexture(0.20,0.21,0.25,0.5)
    b.DisabledTexture:SetPoint("TOPLEFT")
    b.DisabledTexture:SetPoint("BOTTOMRIGHT")
    b:SetDisabledTexture(b.DisabledTexture)

    b.HideTextures = function(self)
        self.HighlightTexture:Hide()
        self.PushedTexture:Hide()
        self.Texture:Hide()
        self.DisabledTexture:Hide()
        self:HideBorders()
    end

    return b
end

function Button.Border(self,cR,cG,cB,cA,size,offsetX,offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    self.BorderTop = self:CreateTexture(nil,"BACKGROUND")
    self.BorderTop:SetColorTexture(cR,cG,cB,cA)
    self.BorderTop:SetPoint("TOPLEFT",-size-offsetX,size+offsetY)
    self.BorderTop:SetPoint("BOTTOMRIGHT",self,"TOPRIGHT",size+offsetX,offsetY)

    self.BorderLeft = self:CreateTexture(nil,"BACKGROUND")
    self.BorderLeft:SetColorTexture(cR,cG,cB,cA)
    self.BorderLeft:SetPoint("TOPLEFT",-size-offsetX,offsetY)
    self.BorderLeft:SetPoint("BOTTOMRIGHT",self,"BOTTOMLEFT",-offsetX,-offsetY)

    self.BorderBottom = self:CreateTexture(nil,"BACKGROUND")
    self.BorderBottom:SetColorTexture(cR,cG,cB,cA)
    self.BorderBottom:SetPoint("BOTTOMLEFT",-size-offsetX,-size-offsetY)
    self.BorderBottom:SetPoint("TOPRIGHT",self,"BOTTOMRIGHT",size+offsetX,-offsetY)

    self.BorderRight = self:CreateTexture(nil,"BACKGROUND")
    self.BorderRight:SetColorTexture(cR,cG,cB,cA)
    self.BorderRight:SetPoint("BOTTOMRIGHT",size+offsetX,offsetY)
    self.BorderRight:SetPoint("TOPLEFT",self,"TOPRIGHT",offsetX,-offsetY)

    self.HideBorders = function(self)
        self.BorderTop:Hide()
        self.BorderLeft:Hide()
        self.BorderBottom:Hide()
        self.BorderRight:Hide()
    end
end

NativeUI:RegisterWidget('Button', Button)
