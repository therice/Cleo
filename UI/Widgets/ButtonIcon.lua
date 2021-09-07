-- @type AddOn
local _, AddOn = ...
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @class UI.Widgets.ButtonIcon
local ButtonIcon = AddOn.Package('UI.Widgets'):Class('ButtonIcon', BaseWidget)

local Type = {
    Close = 1,
    Home  = 2,
}

ButtonIcon.Type = Type

local TypeMetadata = {
    [ButtonIcon.Type.Close] = { { 0.5, 0.5625, 0.5, 0.625 }, { 1, 1, 1, .7 }, { .8, 0, 0, 1 } },
    [ButtonIcon.Type.Home]  = { { 0.1875, 0.25, 0.5, 0.625 }, { 1, 1, 1, .7 }, { 0.9, 0.75, 0, 1 } },
}


ButtonIcon.TypeMetadata = TypeMetadata

function ButtonIcon:initialize(parent, name, type)
    BaseWidget.initialize(self, parent, name)
    self.type = type
end

function ButtonIcon:Create()
    local b = CreateFrame("Button", self.parent:GetName() .. '_' .. self.name, self.parent)

    local metadata = ButtonIcon.TypeMetadata[self.type]
    local iconsTexture = BaseWidget.ResolveTexture("DiesalGUIcons16x256x128")

    b.NormalTexture = b:CreateTexture(nil,"ARTWORK")
    b.NormalTexture:SetTexture(iconsTexture)
    b.NormalTexture:SetPoint("TOPLEFT")
    b.NormalTexture:SetPoint("BOTTOMRIGHT")
    b.NormalTexture:SetVertexColor(unpack(metadata[2]))
    b.NormalTexture:SetTexCoord(unpack(metadata[1]))
    b:SetNormalTexture(b.NormalTexture)

    if Util.Objects.IsTable(metadata[3]) then
        b.HighlightTexture = b:CreateTexture(nil,"ARTWORK")
        b.HighlightTexture:SetTexture(iconsTexture)
        b.HighlightTexture:SetPoint("TOPLEFT")
        b.HighlightTexture:SetPoint("BOTTOMRIGHT")
        b.HighlightTexture:SetVertexColor(unpack(metadata[3]))
        b.HighlightTexture:SetTexCoord(unpack(metadata[1]))
        b:SetHighlightTexture(b.HighlightTexture)
    end

    if Util.Objects.IsTable(metadata[4]) then
        b.PushedTexture = b:CreateTexture(nil,"ARTWORK")
        b.PushedTexture:SetTexture(iconsTexture)
        b.PushedTexture:SetPoint("TOPLEFT")
        b.PushedTexture:SetPoint("BOTTOMRIGHT")
        b.PushedTexture:SetVertexColor(unpack(metadata[4]))
        b.PushedTexture:SetTexCoord(unpack(metadata[1]))
        b:SetPushedTexture(b.PushedTexture)
    end

    if Util.Objects.IsTable(metadata[5]) then
        b.DisabledTexture = b:CreateTexture(nil,"ARTWORK")
        b.DisabledTexture:SetTexture(iconsTexture)
        b.DisabledTexture:SetPoint("TOPLEFT")
        b.DisabledTexture:SetPoint("BOTTOMRIGHT")
        b.DisabledTexture:SetVertexColor(unpack(metadata[5]))
        b.DisabledTexture:SetTexCoord(unpack(metadata[1]))
        b:SetDisabledTexture(b.DisabledTexture)
    end

    return b
end

NativeUI:RegisterWidget('ButtonIcon', ButtonIcon)