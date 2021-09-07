local _, AddOn = ...
local Logging = AddOn:GetLibrary('Logging')
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
local pkg = AddOn.Package('UI.Native')

--- @class UI.Native.Widget
local Widget = pkg:Class('Widget')
function Widget:initialize(parent, name)
    self.parent = parent
    self.name = name
    -- Logging:Debug("Widget(%s, %s)", tostring(parent and parent:GetName() or "Nil"), tostring(name))
end

function Widget.ResolveTexture(texture)
    return "Interface\\Addons\\" .. AddOn.name .. "\\Media\\Textures\\" ..texture
end

function Widget.Border(self,cR,cG,cB,cA,size,offsetX,offsetY)
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

function Widget.Shadow(parent, size, edgeSize)
    local shadow = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
    shadow:SetPoint("LEFT", -size, 0)
    shadow:SetPoint("RIGHT", size, 0)
    shadow:SetPoint("TOP", 0, size)
    shadow:SetPoint("BOTTOM", 0, -size)
    shadow:SetBackdrop({ edgeFile = Widget.ResolveTexture('shadow'), edgeSize = edgeSize or 28, insets = { left = size, right = size, top = size, bottom = size } })
    shadow:SetBackdropBorderColor(0, 0, 0, .45)
    return shadow
end

do
    local function Widget_SetPoint(self, arg1, arg2, arg3, arg4, arg5)
        if arg1 == 'x' then arg1 = self:GetParent() end
        if arg2 == 'x' then arg2 = self:GetParent() end

        if Util.Objects.IsNumber(arg1) and Util.Objects.IsNumber(arg2) then
            arg1, arg2, arg3 = "TOPLEFT", arg1, arg2
        end

        if Util.Objects.IsTable(arg1) and not arg2 then
            self:SetAllPoints(arg1)
            return self
        end

        if arg5 then
            self:SetPoint(arg1, arg2, arg3, arg4, arg5)
        elseif arg4 then
            self:SetPoint(arg1, arg2, arg3, arg4)
        elseif arg3 then
            self:SetPoint(arg1, arg2, arg3)
        elseif arg2 then
            self:SetPoint(arg1, arg2)
        else
            self:SetPoint(arg1)
        end

        return self
    end

    local function Widget_SetSize(self, ...)
        self:SetSize(...)
        return self
    end

    local function Widget_SetNewPoint(self, ...)
        self:ClearAllPoints()
        self:Point(...)
        return self
    end

    local function Widget_SetScale(self, ...)
        self:SetScale(...)
        return self
    end

    local function Widget_OnClick(self, func)
        self:SetScript("OnClick", func)
        return self
    end

    local function Widget_OnShow(self, func, disableFirstRun)
        if not func then
            self:SetScript("OnShow", nil)
            return self
        end
        self:SetScript("OnShow", func)
        if not disableFirstRun then
            func(self)
        end
        return self
    end

    local function Widget_Run(self, func, ...)
        func(self, ...)
        return self
    end

    local function Widget_Shown(self, bool)
        if bool then
            self:Show()
        else
            self:Hide()
        end
        return self
    end

    local function Widget_OnEnter(self, func)
        self:SetScript("OnEnter", func)
        return self
    end

    local function Widget_OnLeave(self, func)
        self:SetScript("OnLeave", func)
        return self
    end

    function Widget.Mod(self, ...)
        self.Point    = Widget_SetPoint
        self.Size     = Widget_SetSize
        self.NewPoint = Widget_SetNewPoint
        self.Scale    = Widget_SetScale
        self.OnClick  = Widget_OnClick
        self.OnShow   = Widget_OnShow
        self.Run      = Widget_Run
        self.Shown    = Widget_Shown
        self.OnEnter  = Widget_OnEnter
        self.OnLeave  = Widget_OnLeave

        for i = 1, select("#", ...) do
            if i % 2 == 1 then
                local funcName, func = select(i, ...)
                self[funcName] = func
            end
        end
    end
end

function Widget:Create() error("Create() not implemented") end

-- Class UI.Natives
--- @class UI.AceConfig.Natives
local Natives = AddOn.Class('Natives')
function Natives:initialize()
    self.widgets = {}   -- mapping of widget type to widget class
    self.count = {}     -- mapping of widget type to count of instances created without an explicit name
    self.frames = {}    -- all native frames which have been created via Native widget
end

function Natives:TrackFrame(f)
    tinsert(self.frames, f)
end

function Natives:MinimizeFrames()
    for _, frame in ipairs(self.frames) do
        if frame:IsVisible() and not frame.combatMinimized then
            frame.combatMinimized = true
            frame:Minimize()
        end
    end
end

function Natives:MaximizeFrames()
    for _, frame in ipairs(self.frames) do
        if frame.combatMinimized then
            frame.combatMinimized = false
            frame:Maximize()
        end
    end
end

function Natives:New(widgetType, parent, name, ...)
    assert(widgetType and type(widgetType) == 'string', 'Widget type was not provided')
    local widget = self.widgets[widgetType]
    if widget then
        parent = parent or _G.UIParent
        if not name then
            if not self.count[widgetType] then self.count[widgetType] = 0 end
            self.count[widgetType] = self.count[widgetType] + 1
            name = format("%s_UI_%s_%d", AddOn.Constants.name, widgetType, self.count[widgetType])
        end
        return self:Embed(widget(parent, name, ...):Create())
    else
        Logging:Warn("Natives:New() : No widget available for type '%s'", widgetType)
        error(format("(Native UI) No widget available for type '%s'", widgetType))
    end
end

local _Embeds = {
    ["SetMultipleScripts"] =
        function(object, scripts)
            for k, v in pairs(scripts) do
                object:SetScript(k, v)
            end
        end
}

function Natives:Embed(object)
    for k, v in pairs(_Embeds) do
        object[k] = v
    end
    return object
end

--- @class UI.Native
local Native = AddOn.Instance(
        'UI.Native',
        function()
            return {
                private = Natives()
            }
        end
)

function Native:New(type, parent, ...)
    return self.private:New(type, parent, nil, ...)
end

function Native:NewNamed(type, parent, name, ...)
    return self.private:New(type, parent, name, ...)
end

function Native:RegisterWidget(widgetType, class)
    assert(widgetType and type(widgetType) == 'string', "Widget type was not provided")
    assert(class and type(class) == 'table', "Widget class was not provided")
    self.private.widgets[widgetType] = class
end

function Native:TrackFrame(f)
    self.private:TrackFrame(f)
end

function Native:MinimizeFrames()
    self.private:MinimizeFrames()
end

function Native:MaximizeFrames()
    self.private:MaximizeFrames()
end

if AddOn._IsTestContext('UI_Native') then
    function Native:UnregisterWidget(type)
        self.private.widgets[type] = nil
    end
end