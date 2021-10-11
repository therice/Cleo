--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @class LootSession
local LootSession = AddOn:NewModule('LootSession', "AceTimer-3.0")

function LootSession:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
end

function LootSession:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	---@type MasterLooter
	self.ml = AddOn:MasterLooterModule()
	self.loadingItems = false
	self.showPending  = false
end

function LootSession:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self.loadingItems = false
	self.showPending  = false
	self:Hide()
end

function LootSession:EnableOnStartup()
	return false
end

function LootSession:Start()
	Logging:Debug("Start()")
	if self.loadingItems then
		return AddOn:Print(L["session_items_not_loaded"])
	end

	if not self.ml.lootTable or Util.Tables.Count(self.ml.lootTable) == 0 then
		AddOn:Print(L["session_no_items"])
		Logging:Debug("Session cannot be started as there are no items")
		return
	end

	if InCombatLockdown() then
		return AddOn:Print(L["session_in_combat"])
	else
		self.ml:StartSession()
	end

	self:Disable()
end

function LootSession:Cancel()
	Logging:Debug("Cancel()")
	self.ml.lootTable = {}
	self:Disable()
end
