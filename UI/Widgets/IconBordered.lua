local _, AddOn = ...
local NativeUI = AddOn.Require('UI.Native')
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
local IconBordered = AddOn.Package('UI.Widgets'):Class('IconBordered', BaseWidget)

function IconBordered:initialize(parent, name, texture)
    BaseWidget.initialize(self, parent, name)
    self.texture = texture
end

function IconBordered:Create()
    local b = CreateFrame(
            "Button",
            self.parent:GetName() .. '_' .. self.name,
            self.parent,
            BackdropTemplateMixin and "BackdropTemplate"
    )
    b:SetSize(40,40)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    b:GetHighlightTexture():SetBlendMode("ADD")
    b:SetNormalTexture(self.texture or "Interface\\InventoryItems\\WoWUnknownItem01")
    b:GetNormalTexture():SetDrawLayer("BACKGROUND")
    b:SetBackdrop({
        bgFile = "",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 18,
    })
    b:SetScript("OnLeave", function() AddOn.Require('UI.Util'):HideTooltip() end)
    b:EnableMouse(true)
    b:RegisterForClicks("AnyUp")
    b.SetBorderColor = function(self, color)
        if color == "green" then
            self:SetBackdropBorderColor(0,1,0,1)
            self:GetNormalTexture():SetVertexColor(0.8,0.8,0.8)
        elseif color == "yellow" then
            self:SetBackdropBorderColor(1,1,0,1)
            self:GetNormalTexture():SetVertexColor(1,1,1)
        elseif color == "grey" or color == "gray" then
            self:SetBackdropBorderColor(0.75,0.75,0.75,1)
            self:GetNormalTexture():SetVertexColor(1,1,1)
        elseif color == "red" then
            self:SetBackdropBorderColor(1,0,0,1)
            self:GetNormalTexture():SetVertexColor(1,1,1)
        elseif color == "purple" then
            self:SetBackdropBorderColor(0.65,0.4,1,1)
            self:GetNormalTexture():SetVertexColor(1,1,1)
        -- Default to white
        else
            self:SetBackdropBorderColor(1,1,1,1)
            self:GetNormalTexture():SetVertexColor(0.5,0.5,0.5)
        end
    end
    b.Desaturate = function(self)
        return self:GetNormalTexture():SetDesaturated(true)
    end
    return b
end

NativeUI:RegisterWidget('IconBordered', IconBordered)