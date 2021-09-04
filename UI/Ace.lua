local _, AddOn = ...
local Logging, Util, AceGUI = AddOn:GetLibrary('Logging'), AddOn:GetLibrary('Util'), AddOn:GetLibrary('AceGUI')
---@type UI.AceConfig.ConfigBuilder
local AceConfigBuilder = AddOn.ImportPackage('UI.AceConfig').ConfigBuilder

--- @class UI.Ace
local Ace = AddOn.Instance(
        'UI.Ace',
        function()
            return {
                Chain = {
                    widget = nil,
                    key = nil,
                }
            }
        end
)

--- @return UI.AceConfig.ConfigBuilder
function Ace.ConfigBuilder(options, ...)
    return AceConfigBuilder(options, ...)
end

local AceChainFn = function(...)
    local chain, widget, key = Ace.Chain, rawget(Ace.Chain, "widget"), rawget(Ace.Chain, "key")
    -- key is the function to invoke
    if key == "AddTo" then
        local parent, beforeWidget = ...
        if parent.type == "Dropdown-Pullout" then
            parent:AddItem(widget)
        elseif not parent.children or beforeWidget == false then
            (widget.frame or widget):SetParent(parent.frame or parent)
        else
            parent:AddChild(widget, beforeWidget)
        end
    else
        if key == "Toggle" then key = (...) and "Show" or "Hide" end

        local obj = widget[key] and widget
                or widget.frame and widget.frame[key] and widget.frame
                or widget.image and widget.image[key] and widget.image
                or widget.label and widget.label[key] and widget.label
                or widget.content and widget.content[key] and widget.content
        Logging:Trace("AceChainFn() : Object = %s, Key = %s", tostring(obj.type), key)

        obj[key](obj, ...)

        -- Fix Label's stupid image anchoring
        if Util.Objects.In(obj.type, "Label", "InteractiveLabel") and Util.Objects.In(key, "SetText", "SetFont", "SetFontObject", "SetImage") then
            local strWidth, imgWidth = obj.label:GetStringWidth(), obj.imageshown and obj.image:GetWidth() or 0
            local width = Util.Numbers.Round(strWidth + imgWidth + (min(strWidth, imgWidth) > 0 and 4 or 0), 1)
            obj:SetWidth(width)
        end
    end
    return chain
end

setmetatable(Ace.Chain, {
    __index = function (chain, key)
        chain.key = Util.Strings.UcFirst(key)
        return AceChainFn
    end,
    __call = function (chain, index)
        local widget = rawget(chain, "widget")
        if index ~= nil then
            return widget[index]
        else
            return widget
        end
    end
})

setmetatable(Ace, {
    __call = function (_, widget, ...)
        Ace.Chain.widget = type(widget) == "string" and AceGUI:Create(widget, ...) or widget
        Ace.Chain.key = nil
        return Ace.Chain
    end
})