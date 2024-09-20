--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type Models.Item.LootSource
local LootSource = AddOn.Package('Models.Item').LootSource

--- @class Testing.TestLootSource : Models.Item.LootSource
local TestLootSource = AddOn.Package('Testing'):Class('TestLootSource', LootSource)
function TestLootSource:initialize(id)
	LootSource.initialize(self, id)
end

function TestLootSource:GetName()
	return L['unknown_testing']
end

---
--- collection of utilities specifically intended to be used for testing/emulating functionality
--- these should not be used outside of explicit testing paths, both within and outside of the game
---

--- @class Testing.TradeTimes
local TradeTimes = {

}

function TradeTimes:Items()
	return AddOn:LootLedgerModule():GetTradeTimes().testItems
end

function TradeTimes:HasItems()
	return #self:Items() > 0
end

function TradeTimes:ContainsItem(itemId)
	return itemId and Util.Tables.ContainsValue(self:Items(), itemId)
end

function TradeTimes:SetItems(...)
	local itemIds, testItems = {...}, self:Items()

	for _, itemId in pairs(itemIds or {}) do
		if Util.Objects.IsNumber(itemId) then
			Util.Tables.Push(testItems, itemId)
		end
	end
end

function TradeTimes:ClearItems()
	Util.Tables.Wipe(self:Items())
end

--- @class Testing.LootLedger
local LootLedger = {
	--- @type Testing.TradeTimes
	TradeTimes = TradeTimes
}

function LootLedger:Toggle()
	AddOn:LootLedgerModule().testMode = not AddOn:LootLedgerModule().testMode
end

function LootLedger:Enable()
	AddOn:LootLedgerModule().testMode = false
end

function LootLedger:Disable()
	AddOn:LootLedgerModule().testMode = true
end

--- @class Testing.MasterLooter
local MasterLooter = {

}

--- @return boolean indicating if able to become master looter
function MasterLooter:Become()
	Logging:Debug("[Testing.MasterLooter] Become(%s)", tostring(AddOn:TestModeEnabled()))

	if AddOn:TestModeEnabled() then
		_, AddOn.masterLooter = AddOn:GetMasterLooter()
		if not AddOn:IsMasterLooter() then
			self:Print(L["error_test_as_non_leader"])
			return false
		end

		local ML = AddOn:MasterLooterModule()
		AddOn:CallModule(ML:GetName())
		ML:NewMasterLooter(AddOn.masterLooter)
		return true
	end

	return false
end

--- @return boolean indicating if able to resign master looter
function MasterLooter:Resign()
	Logging:Debug("[Testing.MasterLooter] Resign(%s)", tostring(AddOn:TestModeEnabled()))
	if AddOn:TestModeEnabled() then
		local ML = AddOn:MasterLooterModule()
		ML:DeactivateConfiguration()
		AddOn:StopHandleLoot()
		AddOn:ScheduleTimer(function() AddOn:NewMasterLooterCheck() end, 1)
		ML.testGroupMembers = nil
		return true
	end

	return false
end

--- @class Testing
local Testing = {
	warningTimer = nil,
	--- @type Testing.LootLedger
	LootLedger   = LootLedger,
	--- @type Testing.MasterLooter
	MasterLooter = MasterLooter,
	--- @type Testing.TestLootSource
	LootSource   = TestLootSource("Testing-0")
}

---
--- /run _G.Cleo.Testing:Enable()
---
function Testing:Enable()
	Logging:Debug("[Testing] Enable()")

	AddOn.mode:Enable(C.Modes.Test)
	if not self.warningTimer then
		self.warningTimer = AddOn:ScheduleRepeatingTimer(
			function() AddOn:PrintWarning(L['test_mode_is_enabled']) end, 10
		)
	end
end

---
--- /run _G.Cleo.Testing:EnableAndBecomeMasterLooter()
---
--- @return boolean indicating if able to enable test mode and become master looter
function Testing:EnableAndBecomeMasterLooter()
	Logging:Debug("[Testing] EnableAndBecomeMasterLooter(%s)", tostring(AddOn:TestModeEnabled()))
	self:Enable()
	if not self.MasterLooter:Become() then
		self:Disable()
		return false
	end

	return true
end

---
--- /run _G.Cleo.Testing:Disable()
---
function Testing:Disable()
	Logging:Debug("[Testing] Disable()")
	AddOn.mode:Disable(C.Modes.Test)
	if self.warningTimer then
		AddOn:CancelTimer(self.warningTimer)
		self.warningTimer = nil
	end
end

---
--- /run _G.Cleo.Testing:ResignMasterLooterAndDisable()
---
function Testing:ResignMasterLooterAndDisable()
	Logging:Debug("[Testing] ResignMasterLooterAndDisable(%s)", tostring(AddOn:TestModeEnabled()))
	if AddOn:TestModeEnabled() then
		self.MasterLooter:Resign()
		self:Disable()
	end
end

--- @type Testing
AddOn.Testing = Testing
