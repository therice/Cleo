--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Models.Date
local Date = AddOn.ImportPackage('Models').Date
--- this is a UI exclusive module for laying out settings for all audit modules
--- @class Audit
local Audit = AddOn:NewModule("Audit")

function Audit:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	AddOn.Timer.Schedule(function() AddOn.Timer.After(5, function() self:AutoPurge() end) end)
end

function Audit:EnableOnStartup()
	return true
end

function Audit:AutoPurge()
	Logging:Debug("AutoPurge()")
	for _, m in pairs({AddOn:LootAuditModule(), AddOn:TrafficAuditModule(), AddOn:RaidAuditModule()}) do
		Logging:Debug("AutoPurge() : Evaluating %s (enabled=%s)", m:GetName(), tostring(m:IsEnabled()))
		if m:IsEnabled() then
			local autoPurgeSettings = m.db.profile.autoPurge
			Logging:Debug("AutoPurge(%s) : %s", m:GetName(), Util.Objects.ToString(autoPurgeSettings))
			if autoPurgeSettings.enabled then
				local lts = autoPurgeSettings.lts and Date(autoPurgeSettings.lts) or nil
				local now, next = Date(), lts and Date(lts):add {day = autoPurgeSettings.recurrence} or nil

				Logging:Debug(
					"AutoPurge(%s) : last executed '%s', next execution '%s'",
					m:GetName(),
					lts and tostring(lts) or 'NEVER',
					lts and tostring(next) or 'NOW'
				)

				if not lts or (now >= next) then
					Logging:Debug("AutoPurge(%s) : purging older than %d days", m:GetName(), autoPurgeSettings.ageInDays)
					m:Delete(autoPurgeSettings.ageInDays)
					autoPurgeSettings.lts = Date().time
				end
			end
		end
	end
end

function Audit:ConfigSupplement()
	return L["history"], function(container) self:LayoutConfigSettings(container) end
end

