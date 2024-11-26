--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Log = AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @class Logging
local Logging = AddOn:NewModule("Logging")

local accum= {}
if not AddOn._IsTestContext() then
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

Logging.defaults = {
    profile = {
        history = {

        }
    }
}

function Logging:OnInitialize()
    Log:Debug("OnInitialize(%s)", self:GetName())
    self.db = AddOn.Libs.AceDB:New(AddOn:Qualify('LogAudit'), Logging.defaults)

    self:BuildFrame()
    --@debug@
    -- self:Toggle()
    --@end-debug@
end

function Logging:OnEnable()
    Log:Debug("OnEnable(%s)", self:GetName())
    if not AddOn._IsTestContext() then
        self:SwitchDestination(accum)
        Util.Tables.Wipe(accum)
    end
end

function Logging:EnableOnStartup()
    return true
end

function Logging.GetLoggingLevels()
    return Util.Tables.Copy(LoggingLevels)
end

function Logging:WriteHistory()
    local history = {}
    for index = 1, self.frame.msg:GetNumMessages() do
        Util.Tables.Push(history,  self.frame.msg:GetMessageInfo(index))
    end

    self.db.profile.history[AddOn.GetDateTime()] = history
end

function Logging:SetLoggingThreshold(threshold)
    AddOn:SetDbValue(AddOn.db.profile, {'logThreshold'}, threshold)
    Log:SetRootThreshold(threshold)
end

function Logging:ConfigSupplement()
    return L["logging"], function(container) self:LayoutConfigSettings(container) end
end
