-- @type AddOn
local _, AddOn = ...
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Native
local NativeUI = AddOn.Require('UI.Native')
--- @type UI.Native.Widget
local BaseWidget = AddOn.ImportPackage('UI.Native').Widget
--- @class UI.Widgets.ButtonIcon
local ButtonIcon = AddOn.Package('UI.Widgets'):Class('ButtonIcon', BaseWidget)
--- @class UI.Widgets.ButtonIconBase
local ButtonIconBase = AddOn.Package('UI.Widgets'):Class('ButtonIconBase', ButtonIcon)
--- @class UI.Widgets.ButtonUp
local ButtonUp = AddOn.Package('UI.Widgets'):Class('ButtonUp', ButtonIconBase)
--- @class UI.Widgets.ButtonDown
local ButtonDown = AddOn.Package('UI.Widgets'):Class('ButtonDown', ButtonIconBase)
--- @class UI.Widgets.ButtonClose
local ButtonClose = AddOn.Package('UI.Widgets'):Class('ButtonClose', ButtonIcon)
--- @class UI.Widgets.ButtonTrash
local ButtonTrash = AddOn.Package('UI.Widgets'):Class('ButtonTrash', ButtonIcon)
--- @class UI.Widgets.ButtonAdd
local ButtonAdd = AddOn.Package('UI.Widgets'):Class('ButtonAdd', ButtonIcon)

---@type UI.Util
local UIUtil = AddOn.Require('UI.Util')

local Type = {
    Close = 1,
    Home  = 2,
    Up    = 3,
    Down  = 4,
    Trash = 5,
    Plus  = 6,
}

ButtonIcon.Type = Type

local TypeMetadata = {
    [ButtonIcon.Type.Close] = { { 0.5, 0.5625, 0.5, 0.625 }, { 1, 1, 1, .7 }, { .8, 0, 0, 1 } },
    [ButtonIcon.Type.Home]  = { { 0.1875, 0.25, 0.5, 0.625 }, { 1, 1, 1, .7 }, { 0.9, 0.75, 0, 1 } },
    [ButtonIcon.Type.Up]    = { { 0.3125, 0.375, 0.5, 0.625 }, { 1, 1, 1, .7 }, 0, { 1, 1, 1, 1 }, { .3, .3, .3, .7 } },
    [ButtonIcon.Type.Down]  = { { 0.25, 0.3125, 0.5, 0.625 }, { 1, 1, 1, .7 }, 0, { 1, 1, 1, 1 }, { .3, .3, .3, .7 } },
    [ButtonIcon.Type.Trash] = { { 0.7568, 0.81176, 0.5, 0.625 }, { 1, 1, 1, .7 }, { .8, 0, 0, 1 } },
    [ButtonIcon.Type.Plus] = { { 0.0039, 0.0588, 0.625, 0.75 }, { 1, 1, 1, .7 }, { 0, 1, 0, 1 } },
}


ButtonIcon.TypeMetadata = TypeMetadata

function ButtonIcon:initialize(parent, name, type)
    BaseWidget.initialize(self, parent, name)
    self.type = type
end

function ButtonIcon:Create()
    local b = CreateFrame("Button", self.name, self.parent)

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

    BaseWidget.Mod(
        b,
        'Tooltip', ButtonIcon.SetTooltip
    )

    return b
end

function ButtonIcon.SetTooltip(self, tooltip)
    self.tooltip = tooltip
    self:SetScript(
            "OnEnter",
            function(self)
                if self.tooltip then
                    UIUtil.ShowTooltip(self, nil, nil, self.tooltip)
                end
            end
    )
    self:SetScript("OnLeave", function() UIUtil:HideTooltip() end)
    return self
end


function ButtonIconBase:initialize(parent, name, type)
    ButtonIcon.initialize(self, parent, name, type)
end

function ButtonIconBase:Create()
    local b = ButtonIcon.Create(self)
    b:SetSize(16,16)

    BaseWidget.Border(b,0.24,0.25,0.3,1,1)

    b.Background = b:CreateTexture(nil,"BACKGROUND")
    b.Background:SetColorTexture(0,0,0,.3)
    b.Background:SetPoint("TOPLEFT")
    b.Background:SetPoint("BOTTOMRIGHT")

    b.NormalTexture:SetPoint("TOPLEFT",-5,2)
    b.NormalTexture:SetPoint("BOTTOMRIGHT",5,-2)

    b.PushedTexture:SetPoint("TOPLEFT",-5,1)
    b.PushedTexture:SetPoint("BOTTOMRIGHT",5,-3)

    b.DisabledTexture:SetPoint("TOPLEFT",-5,2)
    b.DisabledTexture:SetPoint("BOTTOMRIGHT",5,-2)

    b.HighlightTexture = b:CreateTexture()
    b.HighlightTexture:SetColorTexture(1,1,1,.3)
    b.HighlightTexture:SetPoint("TOPLEFT")
    b.HighlightTexture:SetPoint("BOTTOMRIGHT")
    b:SetHighlightTexture(b.HighlightTexture)

    return b
end

function ButtonUp:initialize(parent, name)
    ButtonIconBase.initialize(self, parent, name, ButtonIcon.Type.Up)
end

function ButtonDown:initialize(parent, name)
    ButtonIconBase.initialize(self, parent, name, ButtonIcon.Type.Down)
end

function ButtonClose:initialize(parent, name)
    ButtonIconBase.initialize(self, parent, name, ButtonIcon.Type.Close)
end

function ButtonTrash:initialize(parent, name)
    ButtonIconBase.initialize(self, parent, name, ButtonIcon.Type.Trash)
end

function ButtonAdd:initialize(parent, name)
    ButtonIconBase.initialize(self, parent, name, ButtonIcon.Type.Plus)
end


NativeUI:RegisterWidget('ButtonIcon', ButtonIcon)
NativeUI:RegisterWidget('ButtonUp', ButtonUp)
NativeUI:RegisterWidget('ButtonDown', ButtonDown)
NativeUI:RegisterWidget('ButtonClose', ButtonClose)
NativeUI:RegisterWidget('ButtonTrash', ButtonTrash)
NativeUI:RegisterWidget('ButtonAdd', ButtonAdd)
