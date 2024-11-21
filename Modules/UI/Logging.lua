--- @type AddOn
local _, AddOn = ...
local L, Log, Util, C = AddOn.Locale, AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util"), AddOn.Constants
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
---@type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.Widgets.Dropdown
local Dropdown = AddOn.ImportPackage('UI.Widgets').Dropdown
--- @type Logging
local Logging = AddOn:GetModule("Logging", true)

local function CreateLevelDropdown(parent)
    local threshold =
        UI:NewNamed('Dropdown', parent, "LoggingLevel", Dropdown.Type.Radio, 100, 5)
            :SetTextDecorator(
                function(item)
                    local c = Log:GetLevelRGBColor(item.key)
                    return (c and #c > 0) and UIUtil.ColoredDecorator(c):decorate(item.value) or item.value
                end
            )
            :SetClickHandler(
                function(_, _, item)
                    Logging:SetLoggingThreshold(item.key)
                    return true
                end
            )
            :SetList(Logging.GetLoggingLevels())
            :SetViaKey(Log:GetRootThreshold())
            :Tooltip(L["logging_threshold"], L["logging_threshold_desc"])
    return threshold
end

function Logging:BuildFrame()
    if not self.frame then
        local frame = UI:NewNamed('Frame', UIParent, 'Console', self:GetName(), L['frame_logging'], 750, 400)
        frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
        frame:CreateShadow(20)
        frame:ShadowInside()

        local msg = UI:NewNamed('ScrollingMessageFrame', frame.content, 'Messages')
        msg:SetMaxLines(10000)
        msg:SetPoint("CENTER",frame.content, "CENTER", 0, 10)
        frame.msg = msg

        local clear = UI:NewNamed("Button", frame.content or frame, "Clear", L['clear'])
        clear:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -13, 5)
        clear:SetScript("OnClick", function() frame.msg:Clear() end)
        frame.clear = clear

        local capture = UI:NewNamed("Button", frame.content or frame, "Capture", L['capture'])
        capture:SetPoint("RIGHT", clear, "LEFT", -5, 0)
        capture:SetScript("OnClick", function() self:WriteHistory() end)
        frame.capture = capture

        local captureAndClear = UI:NewNamed("Button", frame.content or frame, "CaptureAndClear", L['capture_and_clear'])
        captureAndClear:SetPoint("RIGHT", capture, "LEFT", -5, 0)
        captureAndClear:SetScript("OnClick", function() self:WriteHistory(); frame.msg:Clear() end)
        frame.captureAndClear = captureAndClear

        --- @type UI.Widgets.Dropdown
        local threshold = CreateLevelDropdown(frame.content or frame)
        threshold:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 7)
        frame.threshold = threshold

        self.frame = frame
    end

    return self.frame
end

function Logging:LayoutConfigSettings(container)
    container:Tooltip(L['logging_help'])
    container.thresholdText = UI:New('Text', container, L['logging_threshold'], 11):Point(20, -20):Top()
    container.threshold =
        CreateLevelDropdown(container)
            :Point("TOPLEFT", container.thresholdText, "BOTTOMLEFT", 0, -10)
    container.toggle =
        UI:New("Button", container, L["logging_window_toggle"]):Size(150, 20)
            :Point("TOPLEFT", container.threshold, "BOTTOMLEFT", 0, -20)
            :Tooltip(L["logging_window_toggle_desc"])
            :OnClick(function() Logging:Toggle() end)
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