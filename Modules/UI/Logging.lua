--- @type AddOn
local _, AddOn = ...
local L, Log, Util, C = AddOn.Locale, AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util"), AddOn.Constants
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
---@type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.Ace
-- local AceUI = AddOn.Require('UI.Ace')
--- @type UI.Widgets.Dropdown
local Dropdown = AddOn.ImportPackage('UI.Widgets').Dropdown
--- @type UI.Widgets.Dropdown
local Dropdown = AddOn.ImportPackage('UI.Widgets').Dropdown
--- @type Logging
local Logging = AddOn:GetModule("Logging", true)

function Logging:BuildFrame()
    if not self.frame then
        local frame = UI:NewNamed('Frame', UIParent, 'Console', self:GetName(), L['frame_logging'], 750, 400, false)
        -- frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

        local msg = UI:NewNamed('ScrollingMessageFrame', frame.content, 'Messages')
        msg:SetMaxLines(10000)
        msg:SetPoint("CENTER", frame.content, "CENTER", 0, 10)
        frame.msg = msg

        local clear = UI:NewNamed("Button", frame.content, "Clear")
        clear:SetText(L['clear'])
        clear:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -13, 5)
        clear:SetScript("OnClick", function() frame.msg:Clear() end)
        frame.clear = clear

        --- @type UI.Widgets.Dropdown
        local threshold = UI:NewNamed("Dropdown", frame.content, "LoggingLevel", Dropdown.Type.Radio, 100, 5)
        threshold:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 7)
        threshold:SetTextDecorator(
                function(item)
                    local c = Log:GetLevelRGBColor(item.value)
                    return (c and #c > 0) and UIUtil.ColoredDecorator(c):decorate(item.text) or item.text
                end
        )
        threshold:SetClickHandler(
                function(_, _, item)
                    Logging:SetLoggingThreshold(item.value)
                    return true
                end
        )
        threshold:SetList(Logging.GetLoggingLevels())
        threshold:SetValue(Log:GetRootThreshold())

        frame.threshold = threshold

        self.frame = frame
    end

    return self.frame
end

function Logging:SwitchDestination(msgs)
    if self.frame then
        if msgs then
            Util.Tables.Call(msgs,
                    function(line)
                        self.frame.msg:AddMessage(line, 1.0, 1.0, 1.0, nil, false)
                    end
            )
        end
        ---- now set logging to emit to frame
        Log:SetWriter(function(msg) self.frame.msg:AddMessage(msg) end)
    end
end

function Logging:Toggle()
    if self.frame then
        if self.frame:IsVisible() then
            self.frame:Hide()
        else
            self.frame:Show()
        end
    end
end