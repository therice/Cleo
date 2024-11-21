--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type Models.Item.DeferredItemAward
local DeferredItemAward = AddOn.Package('Models.Item').DeferredItemAward

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
	self.awardLater = false
	self.pendingEndSession = false
end

function LootSession:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self.loadingItems = false
	self.showPending  = false
	self.awardLater = false
	self.pendingEndSession = false
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

	local lootTable = self.ml:GetLootTable()
	local lootTableEntries = lootTable and Util.Tables.Count(lootTable) or 0
	if not lootTable or lootTableEntries == 0 then
		AddOn:Print(L["session_no_items"])
		Logging:Debug("Session cannot be started as there are no items")
		return
	end

	if self.awardLater then
		local awardedCount = 0
		-- we're going to end the session after all of the items in the current loot table are looted for 'award later'
		self.pendingEndSession = true
		for session, entry in pairs(lootTable) do
			self.ml:Award(
				DeferredItemAward(session, entry:GetItem().link),
				function(...)
					awardedCount = awardedCount + 1
					if awardedCount >= lootTableEntries then
						-- all have been looted, now end the session
						self.pendingEndSession = false
						AddOn.Timer.Schedule(function() self.ml:EndSession() end)
					end
				end
			)
		end
	else
		if InCombatLockdown() then
			return AddOn:Print(L["session_in_combat"])
		else
			self.ml:StartSession()
		end
	end

	self:Disable()
end

function LootSession:Cancel()
	Logging:Debug("Cancel()")
	self.ml:ClearLootTable()
	self:Disable()
end
