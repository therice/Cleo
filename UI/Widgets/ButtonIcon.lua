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
--- @class UI.Widgets.ButtonMinus
local ButtonMinus = AddOn.Package('UI.Widgets'):Class('ButtonMinus', ButtonIcon)
--- @class UI.Widgets.ButtonLeft
local ButtonLeft = AddOn.Package('UI.Widgets'):Class('ButtonLeft', ButtonIcon)
--- @class UI.Widgets.ButtonRight
local ButtonRight = AddOn.Package('UI.Widgets'):Class('ButtonRight', ButtonIcon)
--- @class UI.Widgets.ButtonLeftLarge
local ButtonLeftLarge = AddOn.Package('UI.Widgets'):Class('ButtonLeftLarge', ButtonIcon)
--- @class UI.Widgets.ButtonRightLarge
local ButtonRightLarge = AddOn.Package('UI.Widgets'):Class('ButtonRightLarge', ButtonIcon)
--- @class UI.Widgets.ButtonRefresh
local ButtonRefresh = AddOn.Package('UI.Widgets'):Class('ButtonRefresh', ButtonIcon)

---@type UI.Util
local UIUtil = AddOn.Require('UI.Util')

local Type = {
    Close      = 1,
    Home       = 2,
    Up         = 3,
    Down       = 4,
    Trash      = 5,
    Plus       = 6,
    Minus      = 7,
    Left       = 8,
    Right      = 9,
    LeftLarge  = 10,
    RightLarge = 11,
    DotDotDot  = 12,
    Refresh    = 13,
}

ButtonIcon.Type = Type

-- [1] => {left, right, top, bottom}
local TypeMetadata = {
    [ButtonIcon.Type.Close]      = { { 0.5, 0.5625, 0.5, 0.625 }, { 1, 1, 1, .7 }, { .8, 0, 0, 1 } },
    [ButtonIcon.Type.Home]       = { { 0.1875, 0.25, 0.5, 0.625 }, { 1, 1, 1, .7 }, { 0.9, 0.75, 0, 1 } },
    [ButtonIcon.Type.Up]         = { { 0.3125, 0.375, 0.5, 0.625 }, { 1, 1, 1, .7 }, 0, { 1, 1, 1, 1 }, { .3, .3, .3, .7 } },
    [ButtonIcon.Type.Down]       = { { 0.25, 0.3125, 0.5, 0.625 }, { 1, 1, 1, .7 }, 0, { 1, 1, 1, 1 }, { .3, .3, .3, .7 } },
    [ButtonIcon.Type.Trash]      = { { 0.7568, 0.81176, 0.5, 0.625 }, { 1, 1, 1, .7 }, { .8, 0, 0, 1 } },
    [ButtonIcon.Type.Plus]       = { { 0.0039, 0.0588, 0.625, 0.75 }, { 0, 1, 0, 0.3 }, { 0, 1, 0, 1 } },
    [ButtonIcon.Type.Minus]      = { { 0.0667, 0.1216, 0.625, 0.75 }, { 0.8, 0, 0, 0.3 }, { .8, 0, 0, 1 } },
    [ButtonIcon.Type.Left]       = { { 0.4414, 0.5, 0.5, 0.625 }, { 1, 1, 1, .7 }, 0, { 1, 1, 1, 1 }, { .3, .3, .3, .7 } },
    [ButtonIcon.Type.Right]      = { { 0.375, 0.4414, 0.5, 0.625 }, { 1, 1, 1, .7 }, 0, { 1, 1, 1, 1 }, { .3, .3, .3, .7 } },
    [ButtonIcon.Type.LeftLarge]  = { { 0.18359, 0.25, 0.0, 0.1328 }, { 1, 1, 1, .7 }, 0, { 1, 1, 1, 1 }, { .3, .3, .3, .7 } },
    [ButtonIcon.Type.RightLarge] = { { 0.125, 0.18359, 0.0, 0.1328 }, { 1, 1, 1, .7 }, 0, { 1, 1, 1, 1 }, { .3, .3, .3, .7 } },
    [ButtonIcon.Type.DotDotDot]  = { { 0.871, 0.9375, 0.5, 0.625 } },
    [ButtonIcon.Type.Refresh]    = { { 0.12549, 0.18823, 0.5, 0.625 }, { 0.25, 0.78, 0.92, .7 }, { 0.25, 0.78, 0.92, .9 }, { 0.25, 0.78, 0.92, 1 }},
}
ButtonIcon.TypeMetadata = TypeMetadata

local DefaultTexture = BaseWidget.ResolveTexture("DiesalGUIcons16x256x128")
ButtonIcon.DefaultTexture = DefaultTexture

function ButtonIcon:initialize(parent, name, type, texture)
    BaseWidget.initialize(self, parent, name)
    self.metadata = Util.Objects.IsNumber(type) and TypeMetadata[type] or (Util.Objects.IsTable(type) and type or {})
    self.texture = texture or DefaultTexture
end

function ButtonIcon:Create()
    local b = CreateFrame("Button", self.name, self.parent)
    b.NormalTexture = b:CreateTexture(nil,"ARTWORK")
    b.NormalTexture:SetTexture(self.texture)
    b.NormalTexture:SetPoint("TOPLEFT")
    b.NormalTexture:SetPoint("BOTTOMRIGHT")
    if self.metadata[2] and Util.Objects.IsTable(self.metadata[2]) then
        b.NormalTexture:SetVertexColor(unpack(self.metadata[2]))
    end
    if self.metadata[1] and Util.Objects.IsTable(self.metadata[1]) then
        b.NormalTexture:SetTexCoord(unpack(self.metadata[1]))
    end
    b:SetNormalTexture(b.NormalTexture)

    if Util.Objects.IsTable(self.metadata[3]) then
        b.HighlightTexture = b:CreateTexture(nil,"ARTWORK")
        b.HighlightTexture:SetTexture(self.texture)
        b.HighlightTexture:SetPoint("TOPLEFT")
        b.HighlightTexture:SetPoint("BOTTOMRIGHT")
        b.HighlightTexture:SetVertexColor(unpack(self.metadata[3]))
        b.HighlightTexture:SetTexCoord(unpack(self.metadata[1]))
        b:SetHighlightTexture(b.HighlightTexture)
    end

    if Util.Objects.IsTable(self.metadata[4]) then
        b.PushedTexture = b:CreateTexture(nil,"ARTWORK")
        b.PushedTexture:SetTexture(self.texture)
        b.PushedTexture:SetPoint("TOPLEFT")
        b.PushedTexture:SetPoint("BOTTOMRIGHT")
        b.PushedTexture:SetVertexColor(unpack(self.metadata[4]))
        b.PushedTexture:SetTexCoord(unpack(self.metadata[1]))
        b:SetPushedTexture(b.PushedTexture)
    end

    if Util.Objects.IsTable(self.metadata[5]) then
        b.DisabledTexture = b:CreateTexture(nil,"ARTWORK")
        b.DisabledTexture:SetTexture(self.texture)
        b.DisabledTexture:SetPoint("TOPLEFT")
        b.DisabledTexture:SetPoint("BOTTOMRIGHT")
        b.DisabledTexture:SetVertexColor(unpack(self.metadata[5]))
        b.DisabledTexture:SetTexCoord(unpack(self.metadata[1]))
        b:SetDisabledTexture(b.DisabledTexture)
    end

    BaseWidget.Mod(
        b,
        'Tooltip', ButtonIcon.SetTooltip,
        'Rotate', ButtonIcon.Rotate,
        'HideExtraTextures', ButtonIcon.HideExtraTextures
    )

    return b
end

function ButtonIcon.HideExtraTextures(self)

    self.HighlightTexture:Hide()
    self.PushedTexture:Hide()
    self.DisabledTexture:Hide()
end

function ButtonIcon.SetTooltip(self, tooltip)
    self.tooltip = tooltip
    self:SetScript(
            "OnEnter",
            function(self)
                if self.tooltip then
                    UIUtil.ShowTooltip(self, nil, self.tooltip)
                end
            end
    )
    self:SetScript("OnLeave", function() UIUtil:HideTooltip() end)
    return self
end

-- key is Clockwise (CW)
local TextCoord = {
    [true] = {0, 1, 1, 1, 0, 0, 1, 0},
    [false] = {0, 0, 1, 0, 0, 1, 1, 1}
}

function ButtonIcon.Rotate(self, cw)
    local coords = TextCoord[Util.Objects.IsNil(cw) and true or cw]
    self.NormalTexture:SetTexCoord(unpack(coords))
    if self.HighlightTexture then
        self.HighlightTexture:SetTexCoord(unpack(coords))
    end
    if self.PushedTexture then
        self.PushedTexture:SetTexCoord(unpack(coords))
    end
    if self.DisabledTexture then
        self.DisabledTexture:SetTexCoord(unpack(coords))
    end
    return self
end


function ButtonIconBase:initialize(parent, name, type, texture)
    ButtonIcon.initialize(self, parent, name, type, texture)
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

    if b.PushedTexture then
        b.PushedTexture:SetPoint("TOPLEFT",-5,1)
        b.PushedTexture:SetPoint("BOTTOMRIGHT",5,-3)
    end

    if b.DisabledTexture then
        b.DisabledTexture:SetPoint("TOPLEFT",-5,2)
        b.DisabledTexture:SetPoint("BOTTOMRIGHT",5,-2)
    end

    if not b.HighlightTexture then
        b.HighlightTexture = b:CreateTexture()
        b.HighlightTexture:SetColorTexture(1,1,1,.3)
        b.HighlightTexture:SetPoint("TOPLEFT")
        b.HighlightTexture:SetPoint("BOTTOMRIGHT")
        b:SetHighlightTexture(b.HighlightTexture)
    end

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

function ButtonMinus:initialize(parent, name)
    ButtonIconBase.initialize(self, parent, name, ButtonIcon.Type.Minus)
end

function ButtonLeft:initialize(parent, name)
    ButtonIconBase.initialize(self, parent, name, ButtonIcon.Type.Left)
end

function ButtonRight:initialize(parent, name)
    ButtonIconBase.initialize(self, parent, name, ButtonIcon.Type.Right)
end

function ButtonLeftLarge:initialize(parent, name)
    ButtonIconBase.initialize(self, parent, name, ButtonIcon.Type.LeftLarge)
end

function ButtonRightLarge:initialize(parent, name)
    ButtonIconBase.initialize(self, parent, name, ButtonIcon.Type.RightLarge)
end

function ButtonRefresh:initialize(parent, name)
    ButtonIconBase.initialize(self, parent, name, ButtonIcon.Type.Refresh)
end

NativeUI:RegisterWidget('ButtonIcon', ButtonIcon)
NativeUI:RegisterWidget('ButtonUp', ButtonUp)
NativeUI:RegisterWidget('ButtonDown', ButtonDown)
NativeUI:RegisterWidget('ButtonClose', ButtonClose)
NativeUI:RegisterWidget('ButtonTrash', ButtonTrash)
NativeUI:RegisterWidget('ButtonAdd', ButtonAdd)
NativeUI:RegisterWidget('ButtonPlus', ButtonAdd)
NativeUI:RegisterWidget('ButtonMinus', ButtonMinus)
NativeUI:RegisterWidget('ButtonLeft', ButtonLeft)
NativeUI:RegisterWidget('ButtonRight', ButtonRight)
NativeUI:RegisterWidget('ButtonLeftLarge', ButtonLeftLarge)
NativeUI:RegisterWidget('ButtonRightLarge', ButtonRightLarge)
NativeUI:RegisterWidget('ButtonRefresh', ButtonRefresh)

