--- @type AddOn
local _, AddOn = ...
local C = AddOn.Constants
local Logging = AddOn:GetLibrary('Logging')
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
local pkg = AddOn.Package('UI.Native')
local CreateColor = _G.CreateColor

--- @class UI.Native.Widget
local Widget = pkg:Class('Widget')

function Widget:initialize(parent, name)
    self.parent = parent
    self.name = name
end

function Widget.ResolveTexture(texture)
    return "Interface\\Addons\\" .. AddOn.name .. "\\Media\\Textures\\" ..texture
end

function Widget.Border(self, cR, cG, cB, cA, size, offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    self.BorderTop = self.BorderTop or self:CreateTexture(nil,"BACKGROUND")
    self.BorderTop:SetColorTexture(cR,cG,cB,cA)
    self.BorderTop:SetPoint("TOPLEFT",-size-offsetX,size+offsetY)
    self.BorderTop:SetPoint("BOTTOMRIGHT",self,"TOPRIGHT",size+offsetX,offsetY)

    self.BorderLeft = self.BorderLeft or self:CreateTexture(nil,"BACKGROUND")
    self.BorderLeft:SetColorTexture(cR,cG,cB,cA)
    self.BorderLeft:SetPoint("TOPLEFT",-size-offsetX,offsetY)
    self.BorderLeft:SetPoint("BOTTOMRIGHT",self,"BOTTOMLEFT",-offsetX,-offsetY)

    self.BorderBottom = self.BorderBottom or self:CreateTexture(nil,"BACKGROUND")
    self.BorderBottom:SetColorTexture(cR,cG,cB,cA)
    self.BorderBottom:SetPoint("BOTTOMLEFT",-size-offsetX,-size-offsetY)
    self.BorderBottom:SetPoint("TOPRIGHT",self,"BOTTOMRIGHT",size+offsetX,-offsetY)

    self.BorderRight = self.BorderRight or self:CreateTexture(nil,"BACKGROUND")
    self.BorderRight:SetColorTexture(cR,cG,cB,cA)
    self.BorderRight:SetPoint("BOTTOMRIGHT",size+offsetX, -offsetY)
    self.BorderRight:SetPoint("TOPLEFT",self,"TOPRIGHT",offsetX,offsetY)

    self.HideBorders = function(self)
        self.BorderTop:Hide()
        self.BorderLeft:Hide()
        self.BorderBottom:Hide()
        self.BorderRight:Hide()
    end

    self.ShowBorders = function(self)
        self.BorderTop:Show()
        self.BorderLeft:Show()
        self.BorderBottom:Show()
        self.BorderRight:Show()
    end
end


function Widget.LayerBorder(parent, size, cR, cG, cB, cA, outside, layer)
    outside = outside or 0
    layer = Util.Objects.Default(layer, "")

    local function GetLayerBorderName(position)
        -- e.g. BorderTop1
        local suffix = Util.Strings.IsEmpty(layer) and layer or Util.Strings.UcFirst(layer)
        return Util.Strings.Join("", "Border", (Util.Strings.UcFirst(position) .. suffix))
    end

    local function GetLayerBorder(position, from)
        from = from or parent
        return from[GetLayerBorderName(position)]
    end

    if size == 0 then
        if GetLayerBorder("Top") then
            GetLayerBorder("Top"):Hide()
            GetLayerBorder("Bottom"):Hide()
            GetLayerBorder("Left"):Hide()
            GetLayerBorder("Right"):Hide()
        end
        return
    end

    local textureOwner = parent.CreateTexture and parent or parent:GetParent()

    local function GetOrCreateLayerBorder(position)
        local border = GetLayerBorder(position)
        if not border then
            border = textureOwner:CreateTexture(nil, "BORDER")
        end

        parent[GetLayerBorderName(position)] = border
        return border
    end

    local top, bottom, left, right =
        GetOrCreateLayerBorder("Top"), GetOrCreateLayerBorder("Bottom"),
        GetOrCreateLayerBorder("Left"), GetOrCreateLayerBorder("Right")

    top:SetPoint("TOPLEFT", parent, "TOPLEFT", -size - outside, size + outside)
    top:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", size + outside, outside)

    bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", -size - outside, -size - outside)
    bottom:SetPoint("TOPRIGHT", parent, "BOTTOMRIGHT", size + outside, -outside)

    left:SetPoint("TOPLEFT", parent, "TOPLEFT", -size - outside, outside)
    left:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT", -outside, -outside)

    right:SetPoint("TOPLEFT", parent, "TOPRIGHT", outside, outside)
    right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", size + outside, -outside)

    top:SetColorTexture(cR, cG, cB, cA)
    bottom:SetColorTexture(cR, cG, cB, cA)
    left:SetColorTexture(cR, cG, cB, cA)
    right:SetColorTexture(cR, cG, cB, cA)

    top:Show()
    bottom:Show()
    left:Show()
    right:Show()

    parent.SetBorderColor = function(self, cR, cG, cB, cA, layer)
        layer = Util.Objects.Default(layer, "")
        local top, bottom, left, right =
            GetLayerBorder("Top", self), GetLayerBorder("Bottom", self),
            GetLayerBorder("Left", self), GetLayerBorder("Right", self)

        top:SetColorTexture(cR, cG, cB, cA)
        bottom:SetColorTexture(cR, cG, cB, cA)
        left:SetColorTexture(cR, cG, cB, cA)
        right:SetColorTexture(cR, cG, cB, cA)
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

function Widget.ShadowInside(self, enableBorder, enableLine)
    local offset = enableBorder and 4 or 0
    local notOffset = enableBorder and 0 or 4

    self.ShadowCornerTopLeft = self:CreateTexture(nil,"BORDER",nil,2)
    self.ShadowCornerTopLeft:SetPoint("TOPLEFT",offset,-offset)
    self.ShadowCornerTopLeft:SetAtlas("collections-background-shadow-large",true)

    self.ShadowCornerTopRight = self:CreateTexture(nil,"BORDER",nil,2)
    self.ShadowCornerTopRight:SetPoint("TOPRIGHT",-offset,-offset)
    self.ShadowCornerTopRight:SetAtlas("collections-background-shadow-large",true)
    self.ShadowCornerTopRight:SetTexCoord(1,0,0,1)

    self.ShadowCornerBottomLeft = self:CreateTexture(nil,"BORDER",nil,2)
    self.ShadowCornerBottomLeft:SetPoint("BOTTOMLEFT",offset,offset)
    self.ShadowCornerBottomLeft:SetAtlas("collections-background-shadow-large",true)
    self.ShadowCornerBottomLeft:SetTexCoord(0,1,1,0)

    self.ShadowCornerBottomRight = self:CreateTexture(nil,"BORDER",nil,2)
    self.ShadowCornerBottomRight:SetPoint("BOTTOMRIGHT",-offset,offset)
    self.ShadowCornerBottomRight:SetAtlas("collections-background-shadow-large",true)
    self.ShadowCornerBottomRight:SetTexCoord(1,0,1,0)

    self.ShadowCornerTop = self:CreateTexture(nil,"BORDER",nil,2)
    self.ShadowCornerTop:SetPoint("TOPLEFT",149-notOffset,-offset)
    self.ShadowCornerTop:SetPoint("TOPRIGHT",-149+notOffset,-offset)
    self.ShadowCornerTop:SetAtlas("collections-background-shadow-large",true)
    self.ShadowCornerTop:SetTexCoord(0.9999,1,0,1)

    self.ShadowCornerLeft = self:CreateTexture(nil,"BORDER",nil,2)
    self.ShadowCornerLeft:SetPoint("TOPLEFT",offset,-151+notOffset)
    self.ShadowCornerLeft:SetPoint("BOTTOMLEFT",offset,151-notOffset)
    self.ShadowCornerLeft:SetAtlas("collections-background-shadow-large",true)
    self.ShadowCornerLeft:SetTexCoord(0,1,0.9999,1)

    self.ShadowCornerRight = self:CreateTexture(nil,"BORDER",nil,2)
    self.ShadowCornerRight:SetPoint("TOPRIGHT",-offset,-151+notOffset)
    self.ShadowCornerRight:SetPoint("BOTTOMRIGHT",-offset,151-notOffset)
    self.ShadowCornerRight:SetAtlas("collections-background-shadow-large",true)
    self.ShadowCornerRight:SetTexCoord(1,0,0.9999,1)

    self.ShadowCornerBottom = self:CreateTexture(nil,"BORDER",nil,2)
    self.ShadowCornerBottom:SetPoint("BOTTOMLEFT",149-notOffset,offset)
    self.ShadowCornerBottom:SetPoint("BOTTOMRIGHT",-149+notOffset,offset)
    self.ShadowCornerBottom:SetAtlas("collections-background-shadow-large",true)
    self.ShadowCornerBottom:SetTexCoord(0.9999,1,1,0)

    self.HideShadow = function(self)
        self.ShadowCornerTopLeft:Hide()
        self.ShadowCornerTopRight:Hide()
        self.ShadowCornerBottomLeft:Hide()
        self.ShadowCornerBottomRight:Hide()
        self.ShadowCornerTop:Hide()
        self.ShadowCornerLeft:Hide()
        self.ShadowCornerRight:Hide()
        self.ShadowCornerBottom:Hide()
    end

    self.ShowShadow = function(self)
        self.ShadowCornerTopLeft:Show()
        self.ShadowCornerTopRight:Show()
        self.ShadowCornerBottomLeft:Show()
        self.ShadowCornerBottomRight:Show()
        self.ShadowCornerTop:Show()
        self.ShadowCornerLeft:Show()
        self.ShadowCornerRight:Show()
        self.ShadowCornerBottom:Show()
    end
end


Widget.Textures = {
    SetGradientAlpha = function(texture, orientation, ...)
        Logging:Trace("SetGradientAlpha(%s) : %s", orientation, Util.Objects.ToString({...}))

        if texture and Util.Objects.IsTable(texture) and (Util.Objects.IsFunction(texture['SetGradientAlpha']) or Util.Objects.IsFunction(texture['SetGradient'])) then
            if AddOn.BuildInfo:IsWrathP1() then
                texture:SetGradientAlpha(orientation, ...)
            else
                local args = {...}
                local c1 = Util.Objects.IsTable(args[1]) and args[1] or CreateColor(args[1], args[2], args[3], args[4])
                local c2 = Util.Objects.IsTable(args[2]) and args[2] or CreateColor(args[5], args[6], args[7], args[8])
                texture:SetGradient(orientation, c1, c2)
            end
        end
    end
}

do
    local function SetPoint(self, arg1, arg2, arg3, arg4, arg5)
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

    local function SetSize(self, ...)
        --Logging:Debug("Native.SetSize(%s) : %s", tostring(self:GetName()), Util.Objects.ToString(Util.Tables.New(...)))
        self:SetSize(...)
        return self
    end

    local function SetNewPoint(self, ...)
        self:ClearAllPoints()
        self:Point(...)
        return self
    end

    local function SetScale(self, ...)
        self:SetScale(...)
        return self
    end

    local function OnEnter(self, fn)
        self:SetScript("OnEnter", fn)
        return self
    end

    local function OnLeave(self, fn)
        self:SetScript("OnLeave", fn)
        return self
    end

    local function OnClick(self, fn)
        self:SetScript("OnClick", fn)
        return self
    end

    local function OnShow(self, fn, disableFirstRun)
        if not fn then
            self:SetScript("OnShow", nil)
            return self
        end
        self:SetScript("OnShow", fn)
        if not disableFirstRun then
            fn(self)
        end
        return self
    end

    local function Run(self, fn, ...)
        fn(self, ...)
        return self
    end

    local function Shown(self, bool)
        if bool then
            self:Show()
        else
            self:Hide()
        end
        return self
    end

    local function SetMultipleScripts(self, scripts)
        -- event, function
        for k, v in pairs(scripts) do
            self:SetScript(k, v)
        end
        return self
    end


    --- @param handler any the instance which supports [Get|Set]DbValue
    --- @param db table the datasource on which values will be read/written
    --- @param key string the key used for reading/writing values in db
    --- @param before_write function<any> a function to be invoked before writing value to db which returns value to be written
    --- @param after_write function<any> a function to be invoked after writing a value to db
    --- @param after_read function<any> a function to be invoked after reading a value from db which returns modified value
    local function SetDatasource(self, handler, db, key, before_write, after_write, after_read)
        if Util.Objects.IsSet(handler) and Util.Objects.IsSet(key) then
            if not handler.GetDbValue then
                error("Datasource 'handler' does not support 'GetDbValue'")
            end

            if not handler.SetDbValue then
                error("Datasource 'handler' does not support 'SetDbValue'")
            end

            self.ds = {
                handler = handler,
                db =  db,
                key = key,
                before_write = before_write,
                after_write = after_write,
                after_read = after_read,
                Set = function(ds, value)
                    -- Logging:Trace("Widget.DataSource.Set(%s) : %s, %s", tostring(ds.key), Util.Objects.ToString(value), Util.Objects.ToString(ds.before_write))
                    local v = value
                    if ds.before_write then v = ds.before_write(value) end
                    ds.handler:SetDbValue(ds.db, ds.key, v)
                    if ds.after_write then ds.after_write(value) end
                end,
                Get = function(ds, ...)
                    -- Logging:Trace("Widget.DataSource.Get(%s)", tostring(ds.key))
                    local v = ds.handler:GetDbValue(ds.db, ds.key, ...)
                    if ds.after_read then v = ds.after_read(v) end
                    return v
                end,
            }
        else
            Logging:Warn("SetDatasource() : Either 'handler' or 'key' not specified")
        end

        if not self.OnDatasourceConfigured then
            Logging:Warn("%s : 'OnDatasourceConfigured()' unavailable, any usage must be manually managed", self:GetWidgetType())
        else
            self:OnDatasourceConfigured()
        end

        return self
    end

    local function ClearDatasource(self)
        self.ds = nil

        if not self.OnDatasourceCleared then
            Logging:Warn("%s : 'OnDatasourceCleared()' unavailable, any usage must be manually managed", self:GetWidgetType())
        else
            self:OnDatasourceCleared()
        end

        return self
    end

    function Widget.Mod(self, ...)
        self.Point                      = SetPoint
        self.Size                       = SetSize
        self.NewPoint                   = SetNewPoint
        self.Scale                      = SetScale
        self.OnClick                    = OnClick
        self.OnShow                     = OnShow
        self.Shown                      = Shown
        self.OnEnter                    = OnEnter
        self.OnLeave                    = OnLeave
        self.Run                        = Run
        self.LayerBorder                = Widget.LayerBorder
        self.Border                     = Widget.Border
        self.SetMultipleScripts         = SetMultipleScripts
        self.Datasource                 = SetDatasource
        self.ClearDatasource            = ClearDatasource
        for i = 1, select("#", ...) do
            if i % 2 == 1 then
                local funcName, func = select(i, ...)
                self[funcName] = func
            end
        end
    end
end

function Widget:Create() error("Create() not implemented") end

--- @class Natives
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
        if frame:IsVisible() and not frame.minimized then
            frame.minimized = true
            frame:Minimize()
        end
    end
end

function Natives:MaximizeFrames()
    for _, frame in ipairs(self.frames) do
        if frame.minimized then
            frame.minimized = false
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
        local instance = widget(parent, name, ...):Create()
        instance.GetWidgetType = function() return widgetType end
        return instance
    else
        Logging:Warn("Natives:New() : No widget available for type '%s'", widgetType)
        error(format("(Native UI) No widget available for type '%s'", widgetType))
    end
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

function Native:Popup(...)
    local p = self:NewNamed('Frame', ...)
    p.banner =
        self:New('DecorationLine', p.content, true, "BACKGROUND")
            :Point("TOPLEFT", p, 0, -16)
            :Point("BOTTOMRIGHT", p, "TOPRIGHT", 0, -36)


    p:CreateShadow(20)
    p:ShadowInside()

    return p
end

function Native.Border(...)
    return Widget.Border(...)
end

function Native.LayerBorder(...)
    return Widget.LayerBorder(...)
end

function Native.ResolveTexture(texture)
    return Widget.ResolveTexture(texture)
end

if AddOn._IsTestContext('UI_Native') then
    function Native:UnregisterWidget(type)
        self.private.widgets[type] = nil
    end
end