--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Log =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type UI.Ace
local AceUI = AddOn.Require('UI.Ace')

--- @class Logging
local Logging = AddOn:NewModule("Logging")
local accum

if not AddOn._IsTestContext() then
    accum = {}
    Log:SetWriter(
        function(msg)
            Util.Tables.Push(accum, msg)
        end
    )
end

local LoggingLevels = {
    [Log:GetThreshold(Log.Level.Disabled)] = Log.Level.Disabled,
    [Log:GetThreshold(Log.Level.Fatal)]    = Log.Level.Fatal,
    [Log:GetThreshold(Log.Level.Error)]    = Log.Level.Error,
    [Log:GetThreshold(Log.Level.Warn)]     = Log.Level.Warn,
    [Log:GetThreshold(Log.Level.Info)]     = Log.Level.Info,
    [Log:GetThreshold(Log.Level.Debug)]    = Log.Level.Debug,
    [Log:GetThreshold(Log.Level.Trace)]    = Log.Level.Trace,
}

function Logging:OnInitialize()
    Log:Debug("OnInitialize(%s)", self:GetName())
    self:BuildFrame()
    --@debug@
    self:Toggle()
    --@end-debug@
end

function Logging:OnEnable()
    Log:Debug("OnEnable(%s)", self:GetName())
    if not AddOn._IsTestContext() then
        self:SwitchDestination(accum)
        accum = nil
    end
end

function Logging:EnableOnStartup()
    return true
end

function Logging.GetLoggingLevels()
    return Util.Tables.Copy(LoggingLevels)
end

function Logging:SetLoggingThreshold(threshold)
    AddOn:SetDbValue({'logThreshold'}, threshold)
    Log:SetRootThreshold(threshold)
end

local Options = Util.Memoize.Memoize(function ()
    return AceUI.ConfigBuilder()
                 :group(Logging:GetName(), L['logging']):desc(L['logging_desc'])
                     :args()
                        :header("spacer1", ""):order(1)
                        :description('help', L['logging_help']):order(2)
                        :header("spacer2", ""):order(3)
                        :select('logThreshold', L['logging_threshold']):desc(L['logging_threshold_desc']):order(4)
                            :set('values', Logging.GetLoggingLevels())
                            :set('get', function() return Log:GetRootThreshold() end)
                            :set('set', function(_, logThreshold) Logging:SetLoggingThreshold(logThreshold) end)
                        :header('spacer3', ""):order(5)
                        :execute('toggleWindow', L['logging_window_toggle']):desc(L['logging_window_toggle_desc']):order(6)
                            :set('func', function() Logging:Toggle() end)
                 :build()
end)

function Logging:BuildConfigOptions()
   local options = Options()
    return options[self:GetName()], false
end

