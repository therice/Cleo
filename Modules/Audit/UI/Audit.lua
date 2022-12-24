--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type Models.DateFormat
local DateFormat = AddOn.ImportPackage('Models').DateFormat
--- @type Models.Date
local Date = AddOn.ImportPackage('Models').Date

--- @type Audit
local Audit = AddOn:GetModule("Audit", true)

local Tabs = {
	[L["loot_audit"]]       = L["todo"],
	[L["traffic_audit"]]    = L["todo"],
	[L["attendance_audit"]] = L["todo"],
}

function Audit:LayoutConfigSettings(container)
	container:Tooltip(L["history_desc"])

	container.tabs = UI:New('Tabs', container, unpack(Util.Tables.Sort(Util.Tables.Keys(Tabs))))
	                   :Point(0, -36):Size(container:GetWidth(), container:GetHeight()):SetTo(1)
	container.tabs:SetBackdropBorderColor(0, 0, 0, 0)
	container.tabs:SetBackdropColor(0, 0, 0, 0)
	container.tabs:First():SetPoint("TOPLEFT", 0, 20)

	for index, description in pairs(Tabs) do
		container.tabs:GetByName(index):Tooltip(description)
	end

	UI:New('DecorationLine', container.tabs, true, "BACKGROUND",-5)
	  :Point("TOPLEFT", container.tabs, 0, 20)
	  :Point("BOTTOMRIGHT", container.tabs:GetParent(),"TOPRIGHT", -2, -37)
	  :Color(0.25, 0.78, 0.92, 1, 0.50)

	self:AddPurgeSettings(
		AddOn:LootAuditModule(),
		container.tabs:GetByName(L["loot_audit"])
	)
	self:AddPurgeSettings(
		AddOn:TrafficAuditModule(),
		container.tabs:GetByName(L["traffic_audit"]),
		20
	)
	self:AddPurgeSettings(
		AddOn:RaidAuditModule(),
		container.tabs:GetByName(L["attendance_audit"]),
		20
	)

	AddOn:RaidAuditModule():LayoutConfigSettings(container.tabs:GetByName(L["attendance_audit"]))
end

function Audit:AddPurgeSettings(module, container, yD)
	container.autoPurgeGroup =
		UI:New('InlineGroup',container)
			:Point("TOPLEFT", container, "TOPLEFT", 5, (-40 + (yD or 0)))
			:Point("TOPRIGHT", container, "TOPRIGHT", -20, 0)
	        :SetHeight(150)
	        :Title(L["purging"])

	local content = container.autoPurgeGroup.content

	container.autoPurgeEnabled =
		UI:New('Checkbox', content, L["auto_purge"], false)
	        :Point(20, -10):TextSize(12):Tooltip(L["auto_purge_desc"])
	        :Datasource(
				module,
				module.db.profile,
				'autoPurge.enabled',
				nil,
				function(value)
					container.autoPurgeAgeInDays:SetEnabled(value)
					container.autoPurgeRecurrence:SetEnabled(value)
				end
			)
	container.autoPurgeEnabled:SetSize(14, 14)

	container.autoPurgeAgeInDays =
		UI:New('Slider', content, true)
			:Size(250):EditBox()
			:SetText(L["age_purge"]):Tooltip(L["age_purge_desc"])
			:Point("TOPLEFT", container.autoPurgeEnabled, "BOTTOMLEFT", 0, -15)
			:Range(1, 180)
			:Datasource(
				module,
				module.db.profile,
				'autoPurge.ageInDays'
			)

	container.autoPurgeRecurrence =
		UI:New('Slider', content, true)
		  :Size(250):EditBox()
		  :SetText(L["recurrence"]):Tooltip(L["recurrence_desc"])
		  :Point("LEFT", container.autoPurgeAgeInDays, "RIGHT", 15, 0)
		  :Range(1, 30)
		  :Datasource(
			module,
			module.db.profile,
			'autoPurge.recurrence'
		)

	container.autoPurgeLtsLabel =
		UI:New('Text', content, L["last_occurrence"])
	        :Point("TOPLEFT", container.autoPurgeAgeInDays, "BOTTOMLEFT", 0, -30)

	container.autoPurgeLts =
		UI:New('Text', content)
	        :Point("LEFT", container.autoPurgeLtsLabel, "RIGHT", 10, 0)
			:Color(1, 1, 1, 1)
			:Datasource(
				module,
				module.db.profile,
				'autoPurge.lts',
				nil,
				nil,
				function(value)
					if not value then
						return L['never']
					else
						return DateFormat.Full:format(Date(value):toLocal())
					end
				end
			)
end