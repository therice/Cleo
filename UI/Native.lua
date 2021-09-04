local _, AddOn = ...
local Logging = AddOn:GetLibrary('Logging')
local pkg = AddOn.Package('UI.Native')

--- @class UI.Native.Widget
local Widget = pkg:Class('Widget')
function Widget:initialize(parent, name)
    self.parent = parent
    self.name = name
end

function Widget:Create() error("Create() not implemented")end

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