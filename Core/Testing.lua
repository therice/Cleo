--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type Models.Item.LootSource
local LootSource = AddOn.Package('Models.Item').LootSource
--- @type Core.Event
local Event = AddOn.RequireOnUse('Core.Event')
--- @type LootLedger.Storage
local LootLedgerStorage = AddOn.Package('LootLedger').Storage
--- @type Models.List.Configuration
local Configuration = AddOn.Package('Models.List').Configuration
--- @type Models.List.List
local List = AddOn.Package('Models.List').List

--- @class Testing.TestLootSource : Models.Item.LootSource
local TestLootSource = AddOn.Package('Testing'):Class('TestLootSource', LootSource)
function TestLootSource:initialize(id)
	LootSource.initialize(self, id)
end

--- @return string the type of the source
function TestLootSource:GetType()
	return "Test"
end

function TestLootSource:GetName()
	return L['unknown_testing']
end

---
--- collection of utilities specifically intended to be used for testing/emulating functionality
--- these should not be used outside of explicit testing paths, both within and outside of the game
---

--- @class Testing.LootLedger.TradeTimes
local TradeTimes = {

}

---
--- Items which are included for testing will have faux and random trade time remaining values
---
--- @see AddOn#GetInventoryItemTradeTimeRemaining
--- @return table<number> the item id(s) which are included for testing purposes.
function TradeTimes:Items()
	return AddOn:LootLedgerModule():GetTradeTimes().testItems
end

--- @return boolean are there any included items for testing purposes
function TradeTimes:HasItems()
	return #self:Items() > 0
end

--- @param itemId number the item id to check whether being tested
function TradeTimes:ContainsItem(itemId)
	return itemId and Util.Tables.ContainsValue(self:Items(), itemId)
end

--- @param ... number one ore more items to include for testing purposes
function TradeTimes:SetItems(...)
	local itemIds, testItems = {...}, self:Items()

	for _, itemId in pairs(itemIds or {}) do
		if Util.Objects.IsNumber(itemId) then
			Util.Tables.Push(testItems, itemId)
		end
	end
end

--- Clears any items included for testing purposes
function TradeTimes:ClearItems()
	Util.Tables.Wipe(self:Items())
end

---
--- Persistent storage for loot ledger
---
--- @class Testing.LootLedger.TestStorage : LootLedger.Storage
local TestStorage =  AddOn.Package('Testing.LootLedger'):Class('TestStorage', LootLedgerStorage)
function TestStorage:initialize()
	LootLedgerStorage.initialize(self, AddOn:LootLedgerModule(), {})
end

--- Overrides persistence to always write to the test storage
function TestStorage.ShouldPersist()
	return true
end

--- @class Testing.LootLedger.Storage
local Storage = {
	--- @type LootLedger.Storage
	original  = nil,
	--- @type table<number, rx.Subscription>
	eventSubs = nil,
}

---
--- Replaces current storage with one that is entirely in memory (will not be persisted)
--- The original storage will be restored on an explicit call to Restore() or logout
---
--- /run _G.CleoTesting.LootLedger.Storage:Replace()
function Storage:Replace()
	Logging:Debug("[Testing.LootLedger.Storage] Replace()")

	if not self.original then
		local lootLedgerModule = AddOn:LootLedgerModule()
		self.original = lootLedgerModule.storage
		self.eventSubs = Event():BulkSubscribe({
			[C.Events.PlayerLogout] = function()
				self:Restore()
			end
		})
		lootLedgerModule:UnregisterStorageCallbacks()
		lootLedgerModule.storage = TestStorage()
		lootLedgerModule:RegisterStorageCallbacks()
	end
end

---
--- If previously replaced, restores original storage (replaces test storage)
---
--- /run _G.CleoTesting.LootLedger.Storage:Restore()
function Storage:Restore()
	Logging:Debug("[Testing.LootLedger.Storage] Restore()")
	if self.original then
		local lootLedgerModule = AddOn:LootLedgerModule()
		lootLedgerModule:UnregisterStorageCallbacks()
		lootLedgerModule.storage = self.original
		lootLedgerModule:RegisterStorageCallbacks()

		self.original = nil
		if self.eventSubs then
			AddOn.Unsubscribe(self.eventSub)
			self.eventSubs = nil
		end
	end
end

--- @class Testing.LootLedger
local LootLedger = {
	--- @type Testing.LootLedger.TradeTimes
	TradeTimes = TradeTimes,
	--- @type Testing.LootLedger.Storage
	Storage    = Storage
}

--- Toggles testing mode for LootLedger. If disabled, will be enabled. If enabled, will be disabled.
function LootLedger:Toggle()
	AddOn:LootLedgerModule().testMode = not AddOn:LootLedgerModule().testMode
end

--- Enables testing mode for LootLedger
function LootLedger:Enable()
	AddOn:LootLedgerModule().testMode = true
end

--- Disables testing mode for LootLedger
function LootLedger:Disable()
	AddOn:LootLedgerModule().testMode = false
end

--- @class Testing.MasterLooter
local MasterLooter = {

}

--- @param configId string id of the configuration to activate, if nil won't be activated
--- @return boolean indicating if able to become master looter
function MasterLooter:Become(configId)
	Logging:Debug("[Testing.MasterLooter] Become(%s) : %s", tostring(AddOn:TestModeEnabled()), tostring(configId))

	if AddOn:TestModeEnabled() then
		_, AddOn.masterLooter = AddOn:GetMasterLooter()
		if not AddOn:IsMasterLooter() then
			self:Print(L["error_test_as_non_leader"])
			return false
		end

		AddOn:StartHandleLoot(configId)

		--[[
		local ML = AddOn:MasterLooterModule()
		AddOn:CallModule(ML:GetName())
		ML:NewMasterLooter(AddOn.masterLooter)

		if configId then
			local config = AddOn:ListsModule():GetService().Configuration:Get(configId)
			if config then
				ML:ActivateConfiguration(config)
			end
		end
		--]]

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

--- @class Testing.ListsDataPlane
local ListsDataPlane = {
	--- @return ListsDataPlane
	GetDataPlaneModule = function(_)
		--Logging:Debug("GetDataPlaneModule()")
		return AddOn:ListsDataPlaneModule()
	end,
	--- @return Lists
	GetListsModule = function(_)
		--Logging:Debug("GetListsModule()")
		return AddOn:ListsModule()
	end,
	--- @return Models.List.Service
	GetListsService = function(self)
		--Logging:Debug("GetListsService()")
		return self:GetListsModule():GetService()
	end,
	--- @param self Testing.ListsDataPlane
	--- @param configId string
	GetConfig = function(self, configId)
		--Logging:Debug("GetConfig(%s)", tostring(configId))
		if Util.Strings.IsSet(configId) then
			return self:GetListsService().Configuration:Get(configId)
		end
	end,
	GetLists = function(self, configId)
		if Util.Strings.IsSet(configId) then
			return self:GetListsService():Lists(configId)
		end
	end,
	GetList = function(self, listId)
		if Util.Strings.IsSet(listId) then
			return self:GetListsService().List:Get(listId)
		end
	end,
	CreateRequest = function(self, entity)
		return self:GetDataPlaneModule():CreateRequest(entity:getClassName(), entity.id)
	end,
	SendRequest = function(self, to, ...)
		self:GetDataPlaneModule():SendRequest(to or AddOn.player, nil, ...)
	end
}

---
--- Simulates a request for a configuration from another player
---	/run _G.Cleo.Testing.ListsDataPlane:SendConfigurationRequest("688FD610-1B93-3614-01FE-C5E43CB06896")
---
function ListsDataPlane:SendConfigurationRequest(configId, player)
	local config = self:GetConfig(configId)
	if config then
		self:SendRequest(player, self:CreateRequest(config))
	end
end

---
--- Simulates a request for a list from another player
---	/run _G.Cleo.Testing.ListsDataPlane:SendListRequest("688FD65A-693E-4C24-5936-E12CBAE6DB4F")
---
function ListsDataPlane:SendListRequest(listId, player)
	local list = self:GetList(listId)
	if list then
		self:SendRequest(player, self:CreateRequest(list))
	end
end

---
--- Simulates a request for a configuration and lists from another player
---	/run _G.Cleo.Testing.ListsDataPlane:SendAllRequest("688FD610-1B93-3614-01FE-C5E43CB06896")
---
function ListsDataPlane:SendAllRequest(configId, player)
	local config = self:GetConfig(configId)
	if config then
		local requests = Util.Tables.Push({}, self:CreateRequest(config))
		local lists = self:GetLists(configId)
		for _, list in pairs(lists) do
			Util.Tables.Push(requests, self:CreateRequest(list))
		end

		self:SendRequest(player, unpack(requests))
	end
end

--- @class Testing
local Testing = {
	warningTimer   = nil,
	--- @type Testing.LootLedger
	LootLedger     = LootLedger,
	--- @type Testing.MasterLooter
	MasterLooter   = MasterLooter,
	--- @type Testing.ListsDataPlane
	ListsDataPlane = ListsDataPlane,
	--- @type Testing.TestLootSource
	LootSource     = TestLootSource("Testing-0"),
}

---
--- Enables testing mode for AddOn
--- /run _G.Cleo.Testing:Enable()
---
function Testing:Enable()
	Logging:Debug("[Testing] Enable()")
	AddOn.mode:Enable(C.Modes.Test)
	-- don't startup the warning timer in test context (not in game), as it will
	-- result in unnecessary output and stack overflows unless test is async
	if not self.warningTimer and not AddOn._IsTestContext() then
		self.warningTimer = AddOn:ScheduleRepeatingTimer(
			function() AddOn:PrintWarning(L['test_mode_is_enabled']) end, 10
		)
	end
end

---
--- Enables testing mode for AddOn and becomes the master looter
--- /run _G.Cleo.Testing:EnableAndBecomeMasterLooter()
---
--- @param configId string id of the configuration to activate, if nil won't be activated
--- @return boolean indicating if able to enable test mode and become master looter
function Testing:EnableAndBecomeMasterLooter(configId)
	Logging:Debug("[Testing] EnableAndBecomeMasterLooter(%s)", tostring(AddOn:TestModeEnabled()))
	self:Enable()
	if not self.MasterLooter:Become(configId) then
		self:Disable()
		return false
	end

	return true
end

---
--- Disables testing mode for AddOn
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
--- Disables testing mode for AddOn and resigns as master looter
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
