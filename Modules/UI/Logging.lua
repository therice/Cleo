--- @type AddOn
local _, AddOn = ...
local L, Log, Util = AddOn.Locale, AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.Ace
local AceUI = AddOn.Require('UI.Ace')

--- @type Logging
local Logging = AddOn:GetModule("Logging", true)

function Logging:BuildFrame()
    if not self.frame then
        local frame = UI:NewNamed('Frame', UIParent, 'Console', 'Logging', L['frame_logging'], 750, 400, false)
        frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

        local msg = UI:NewNamed('ScrollingMessageFrame', frame.content, 'Messages')
        msg:SetMaxLines(10000)
        msg:SetPoint("CENTER", frame.content, "CENTER", 0, 10)
        frame.msg = msg

        local close = UI:NewNamed('Button', frame.content, "Close")
        close:SetText(_G.CLOSE)
        close:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -13, 5)
        close:SetScript("OnClick", function() frame:Hide() end)
        frame.close = close

        local clear = UI:NewNamed("Button", frame.content, "Clear")
        clear:SetText(L['clear'])
        clear:SetPoint("RIGHT", frame.close, "LEFT", -10, 0)
        clear:SetScript("OnClick", function() frame.msg:Clear() end)
        frame.clear = clear

        local threshold =
            AceUI('Dropdown')
                .SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 7)
                .SetLabel(nil)
                .SetParent(frame)()
        threshold:SetList(Logging.GetLoggingLevels())
        threshold:SetValue(Log:GetRootThreshold())
        threshold:SetCallback(
                "OnValueChanged",
                function (_, _, threshold) Logging:SetLoggingThreshold(threshold) end
        )
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