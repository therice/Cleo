local _, AddOn = ...
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")

local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
local IconBordered = AddOn.Package('UI.Widgets'):Class('IconBordered', BaseWidget)

function IconBordered:initialize(parent, name, texture)
    BaseWidget.initialize(self, parent, name)
    self.texture = texture
end

function IconBordered:Create()
    local b = CreateFrame("Button", self.name, self.parent, BackdropTemplateMixin and "BackdropTemplate")
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
        if Util.Objects.IsTable(color) then
            local r, g, b, a = 1, 1, 1, 1
            if color.color then
                r, g, b, a = color.color:GetRGBA()
            elseif color.r and color.g and color.b then
                r, g, b = color.r, color.g, color.b
            else
                r, g, b, a = unpack(color)
            end
            self:SetBackdropBorderColor(r, g, b, a)
        elseif Util.Objects.IsString(color) then
            if Util.Strings.Equal(color, "green") then
                self:SetBackdropBorderColor(0,1,0,1)
                self:GetNormalTexture():SetVertexColor(0.8,0.8,0.8)
            elseif Util.Strings.Equal(color, "yellow") then
                self:SetBackdropBorderColor(1,1,0,1)
                self:GetNormalTexture():SetVertexColor(1,1,1)
            elseif Util.Strings.Equal(color, "grey") or Util.Strings.Equal(color, "gray") then
                self:SetBackdropBorderColor(0.75,0.75,0.75,1)
                self:GetNormalTexture():SetVertexColor(1,1,1)
            elseif Util.Strings.Equal(color, "red") then
                self:SetBackdropBorderColor(1,0,0,1)
                self:GetNormalTexture():SetVertexColor(1,1,1)
            elseif Util.Strings.Equal(color, "purple") then
                self:SetBackdropBorderColor(0.65,0.4,1,1)
                self:GetNormalTexture():SetVertexColor(1,1,1)
            -- Default to white
            else
                self:SetBackdropBorderColor(1,1,1,1)
                self:GetNormalTexture():SetVertexColor(0.5,0.5,0.5)
            end
        end

    end
    b.Desaturate = function(self)
        return self:GetNormalTexture():SetDesaturated(true)
    end

    BaseWidget.Mod(b)

    return b
end

NativeUI:RegisterWidget('IconBordered', IconBordered)