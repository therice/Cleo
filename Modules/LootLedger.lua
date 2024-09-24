--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
--- @type Models.Dao
local Dao = AddOn.Package('Models').Dao
--- @type Models.Item.LootedItem
local LootedItem = AddOn.Package('Models.Item').LootedItem
--- @type AceBucket
local AceBucket = AddOn:GetLibrary("AceBucket")
--- @type Core.Message
local Message = AddOn.RequireOnUse('Core.Message')
--- @type Core.Event
local Event = AddOn.RequireOnUse('Core.Event')
--- @type LibDeformat
local Deformat =  AddOn:GetLibrary("Deformat")
--- @type LibUtil.UUID
local UUID = Util.UUID

---
--- Persistent storage for loot ledger
---
--- @class LootLedger.Storage : Models.Dao
local Storage = AddOn.Package("LootLedger"):Class("Storage", Dao)
---
--- Extension to LootedItem which provides a unique key and compatible with Dao
---
--- @class LootLedger.Entry : Models.Item.LootedItem
--- @field id string the entry's id
local Entry = AddOn.Package("LootLedger"):Class("Entry", LootedItem)
---
--- Watches for items being looted by current player
---
--- @class LootLedger.Watcher
local Watcher = AddOn.Package("LootLedger"):Class("Watcher")
---
--- Tracks remaining trade time for applicable items which are in player's bags
---
--- @class LootLedger.TradeTimes
local TradeTimes = AddOn.Package("LootLedger"):Class("TradeTimes")
AceBucket:Embed(TradeTimes)
---
--- Tracks remaining time for a tradeable item which is in a player's bags
---
--- @class LootLedger.TradeTime
local TradeTime = AddOn.Package("LootLedger"):Class("TradeTime")

----- @type LootLedger.TradeTimesOverview
local TradeTimesOverview = AddOn.RequireOnUse("LootLedger.TradeTimesOverview")

---[[ LootLedger START --]]
---
--- Functionality supporting items that were looted, but have not yet been allocated (awarded) to the recipient (player)
---
--- @class LootLedger
local LootLedger = AddOn:NewModule("LootLedger",  "AceTimer-3.0")
LootLedger.defaults = {
	profile = {
		lootStorage = {

		}
	}
}

--- @param self LootLedger
--- @param db table
local function SetDb(self, db)
	self.storage = Storage(self, db.profile.lootStorage)
	--replacing storage, need to schedule validation
	self:ScheduleStorageValidation()
end

function LootLedger:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	SetDb(self, AddOn.Libs.AceDB:New(AddOn:Qualify("LootLedger"), self.defaults))
	self.testMode = false
	-- due to semantics of how items are looted prior to being added to ledger,
	-- disabled the loot watcher in favor of direct dispatch
	-- self.watcher = Watcher()
	self.tradeTimes = TradeTimes()
end

function LootLedger:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:SubscribeToMessages()
	-- due to semantics of how items are looted prior to being added to ledger,
	-- disabled the loot watcher in favor of direct dispatch
	-- self.watcher:Start()
	self.tradeTimes:Start()
	TradeTimesOverview():Enable()
end

function LootLedger:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self:UnsubscribeFromMessages()
	self.tradeTimes:Stop()
	--self.watcher:Stop()
	TradeTimesOverview():Disable()
end

function LootLedger:EnableOnStartup()
	return true
end

--- @return boolean indicating if events, messages, and other game hooks should be processed
function LootLedger:IsHandled()
	return self:IsEnabled() and (self.testMode or not self:GetStorage():IsEmpty() or AddOn:MasterLooterModule():IsHandled())
end

--- @return LootLedger.Storage
function LootLedger:GetStorage()
	return self.storage
end

--[[
--- @return LootLedger.Watcher
function LootLedger:GetWatcher()
	return self.watcher
end
--]]

--- @return LootLedger.TradeTimes
function LootLedger:GetTradeTimes()
	return self.tradeTimes
end

function LootLedger:SubscribeToMessages()
	Logging:Debug("SubscribeToMessages(%s)", self:GetName())
	if self.messageSubscriptions == nil then
		self.messageSubscriptions = Message():BulkSubscribe({
            [C.Messages.LootItemReceived] = function(_, item)
                Logging:Debug("%s", C.Messages.LootItemReceived)
                self:OnItemReceived(item)
            end,
        })
	end
end

function LootLedger:UnsubscribeFromMessages()
	Logging:Debug("UnsubscribeFromMessages(%s)", self:GetName())
	if self.messageSubscriptions ~= nil then
		AddOn.Unsubscribe(self.messageSubscriptions)
		self.messageSubscriptions = nil
	end
end

function LootLedger:LaunchpadSupplement()
	return L["loot_ledger"], function(container) self:LayoutInterface(container) end, false
end

function LootLedger:ScheduleStorageValidation()
	-- don't validate during testing, it can interfere with test outcomes
	if not AddOn._IsTestContext() then
		AddOn.Timer.Schedule(function()
			-- if there is an existing schedule to perform storage validation, which has not yet fired, then cancel it
			if self.timer then
				AddOn:CancelTimer(self.timer)
				self.timer = nil
			end

			--Logging:Warn("ScheduleStorageValidation() : Scheduling timer")
			self.timer = self:ScheduleTimer(function() self:ValidateEntries() end, 5)
		end)
	end
end

--- @see LootLedger.Watcher#OnChatMessageLoot
--- @param item table<number, string, number, string, number> named key/value pairs as follows, id (itemId) link (itemLink) count (itemCount) player (playerName) when (timestamp)
--- @return table<LootLedger.Entry> all located and updated Loot Ledger entries which correspond to the item. they will be sorted from oldest to most recent creation time
function LootLedger:OnItemReceived(item)
	local isHandled = LootLedger:IsHandled()
	Logging:Debug("OnItemReceived(handled=%s) : items=%s", tostring(isHandled), function() return Util.Objects.ToString(item) end)

	--- @type table<LootLedger.Entry>
	local entries = {}

	if isHandled then
		-- only care about received items that have an entry in storage for which a guid has not been assigned
		local receivedCount, candidates, assigned = item.count, {}, {}
		self.storage:ForEach(
		function(_, entry)
			-- the entry is for the received item
			if entry and AddOn.ItemIsItem(entry.item, item.link) then
				-- an already assigned guid for the item, track it so we don't reassign
				if not Util.Strings.IsEmpty(entry.guid) then
					Util.Tables.Push(assigned, entry.guid)
				-- guid is not assigned and it was added to storage before the item was received
				elseif entry.added <= item.when then
					Util.Tables.Push(candidates, entry)
				end
			end
		end)

		if #candidates > 0 then
			-- sort candidates from oldest added to most recently added
			Util(candidates):Sort(function(e1, e2) return e1.added < e2.added end)()
			Logging:Trace(
				"OnItemReceived() : existing assigned GUIDs %s | candidates %s",
				function() return Util.Objects.ToString(assigned) end,
				function() return Util.Objects.ToString(candidates) end
			)

			-- locate all instance(s) of the item in bags which have remaining trade time (>0 secs)
			-- and remove any of those which have a guid which is already assigned to another entry
			-- and sort with least remaining trade time being 1st
			local items = Util(AddOn:FindItemsInBags(item.link, false))
				:Filter(function(i) return not Util.Tables.ContainsValue(assigned, i.guid) end)
				-- capture it as an attribute so not repeatedly querying time remaining
				:Call(function(i) i.remaining = i:TradeTimeRemaining() end)
				:Filter(function(i) return i.remaining > 0 end)
				:Sort(function(i1, i2) return i1.remaining < i2.remaining end)()

			-- should receive items one at a time based upon what type of items are being tracked and being
			-- looted (allocated) to the master individually
			-- log item counts for identification if it becomes an issue
			Logging:Debug("OnItemReceived(%s) : received=%d | storage=%d | bags=%d", item.link, receivedCount, #candidates, #items)

			if Util.Tables.IsSet(items) then
				Logging:Trace("OnItemReceived(%s) : located at %s",  item.link, function() return Util.Objects.ToString(items) end)
				-- only assign guids to items based upon the count of received
				--
				-- could process all entries in storage which have a corresponding index in located items
				-- which will result in any entries/items not processed previously being picked up on a subsequent
				-- item of the same type being received (which seems incorrect, at least at this time)
				for index, entry in ipairs(candidates) do
					if index > receivedCount then
						Logging:Warn(
							"OnItemReceived(%s) : skipping %d entries based upon %d received",
							item.link, (#candidates - (index - 1)), receivedCount
						)
						break
					end

					if items[index] then
						entry.guid = items[index].guid
						self.storage:Update(entry, 'guid')
						Util.Tables.Push(entries, entry)
					end
				end
			else
				Logging:Debug("OnItemReceived(%s) : no corresponding items located in bags", item.link)
			end
		else
			Logging:Debug("OnItemReceived(%s) : no corresponding entries located in storage", item.link)
		end
	end

	-- sort the located entries from eldest to most recent
	Util(entries):Sort(function(e1, e2) return e1.added < e2.added end)()

	return entries
end

---
--- Iterates all entries in storage, validating they are complete, valid, and not expired
---
function LootLedger:ValidateEntries()
	Logging:Debug("ValidateStorage() : validated=%s", tostring(self.storage.validated))
	-- only need to run validation once
	if not self.storage.validated then
		local toRemove = {}
		self.storage:ForEach(
			function(id, entry)
				if Util.Objects.IsNil(entry) then
					Logging:Warn("ValidateEntries() : NIL item | %s", tostring(id))
					-- only need the id for remove call
					Util.Tables.Push(toRemove, {id = id})
				else
					-- validate basic required attributes of entry
					if not entry:IsValid() then
						Logging:Warn("ValidateEntries() : invalid item | %s", Util.Objects.ToString(entry:toTable()))
						Util.Tables.Push(toRemove, entry)
					-- no GUID and added over 3 hours in the past, infers item was never received or a reasonable
					-- amount of time to award and trade has elapsed
					elseif Util.Objects.IsEmpty(entry.guid) and entry:TimeSinceAdded() >  10800 --[[ 3 hours --]] then
						Logging:Warn("ValidateEntries() : item is missing GUID and added over 3 hours ago | %s", Util.Objects.ToString(entry:toTable()))
						Util.Tables.Push(toRemove, entry)
					else
						local bag, slot = AddOn:GetBagAndSlotByGUID(entry.guid)
						-- could not find the item in bags
						if not bag or not slot then
							Logging:Warn("ValidateEntries() : item is no longer in bags | %s", Util.Objects.ToString(entry:toTable()))
							Util.Tables.Push(toRemove, entry)
						else
							local timeRemaining = AddOn:GetInventoryItemTradeTimeRemaining(bag, slot)
							if timeRemaining <= 0 then
								Logging:Warn("ValidateEntries() : item trade time has expired | %s", Util.Objects.ToString(entry:toTable()))
								Util.Tables.Push(toRemove, entry)
							end
						end
					end
				end
			end
		)

		-- remove entries that have been identified as no longer needing to be retained
		for _, remove in pairs(toRemove) do
			self.storage:Remove(remove)
		end

		self.storage.validated = true
	end
end

if AddOn._IsTestContext('Modules_MasterLooter') then
	function LootLedger:SetDb(db)
		SetDb(self, db)
	end
end
---[[ LootLedger END --]]

---[[ LootLedger.Watcher BEGIN --]]
function Watcher:initialize()
	self.running = false
	self.subscriptions = nil
end

--- @return boolean
function Watcher:IsRunning()
	return self.running
end

function Watcher:Start()
	Logging:Trace("Start() : running=%s", tostring(self.running))
	if not self:IsRunning() then
		self.subscriptions = Event():BulkSubscribe({
			[C.Events.ChatMessageLoot] = function(_, message)
				Logging:Debug("Watcher(%s)", C.Events.ChatMessageLoot)
				self:OnChatMessageLoot(message)
			end
        })

		self.running = true
	end
end

function Watcher:Stop()
	Logging:Trace("Stop() : running=%s", tostring(self.running))
	if self:IsRunning() then
		if self.subscriptions then
			AddOn.Unsubscribe(self.subscriptions)
			self.subscriptions = nil
		end
		self.running = false
	end
end

--- @see LootLedger#OnItemReceived
function Watcher:OnChatMessageLoot(message)
	local isHandled = LootLedger:IsHandled()
	Logging:Debug("OnChatMessageLoot(handled=%s) : %s", tostring(isHandled), tostring(message))

	if isHandled then
		local itemLink, playerName, itemCount = self.GetMessageItemDetails(message)
		-- only handle items that could be extracted from message and was awarded to current player
		if Util.Strings.IsEmpty(itemLink) or not Util.Strings.Equal(AddOn.player:GetName(), playerName) then
			return
		end

		local itemId = ItemUtil:ItemLinkToId(itemLink)
		if not itemId then
			return
		end

		Logging:Trace("OnChatMessageLoot() : %s received %s (x%d)", playerName, itemLink, itemCount)
		Message():Send(C.Messages.LootItemReceived, {
			id     = itemId,
			link   = itemLink,
			count  = itemCount,
			player = playerName,
			when   = GetServerTime()
		})
	end
end

--- @return string, string, number item link, player name, and item count OR nil if item details cannot be extracted
function Watcher.GetMessageItemDetails(message)
	-- (1) someone else received multiple items
	local playerName, itemLink, itemCount = Deformat(message, LOOT_ITEM_MULTIPLE)

	-- (2) someone else received a single item
	if Util.Strings.IsEmpty(playerName) then
		itemCount = 1
		playerName, itemLink = Deformat(message, LOOT_ITEM)
	end

	-- (3) we received multiple items
	if Util.Strings.IsEmpty(playerName) then
		playerName = AddOn.player:GetName() -- will be fully qualified player name (with realm)
		itemLink, itemCount = Deformat(message, LOOT_ITEM_SELF_MULTIPLE)
	end

	-- (4) we received a single item
	if Util.Strings.IsEmpty(itemLink) then
		itemCount = 1
		itemLink = Deformat(message, LOOT_ITEM_SELF)
	end

	if Util.Strings.IsEmpty(itemLink) then
		return nil
	end

	itemCount = tonumber(itemCount) or 1
	return itemLink, playerName, itemCount
end

---[[ LootLedger.Watcher END --]]

---[[ LootLedger.TradeTime BEGIN --]]
function TradeTime:initialize(id, guid, link, measured, remaining)
	self.id = id
	self.guid = guid
	self.link = link
	self.texture = select(5, GetItemInfoInstant(link))
	self.measured = measured
	self.remaining = remaining
end

function TradeTime:tostring()
	return Util.Objects.ToString(self:toTable())
end

---
--- @return number time at which ability to trade expires
function TradeTime:ExpirationTime()
	return (self.measured + self.remaining)
end

--- @return number remaining time, in seconds, for item to be traded
function TradeTime:TimeUntilExpiration()
	return self:ExpirationTime() - GetServerTime()
end

--- @return boolean true if item has expired (can no longer be traded), otherwise false
function TradeTime:HasExpired()
	return self:TimeUntilExpiration() <= 0
end

--- @param guid string item gUID
--- @param location ItemLocationMixin
--- @param timeRemaining number seconds remaining to trade
function TradeTime.Create(guid, location, timeRemaining)
	return TradeTime(
		C_Item.GetItemID(location),     -- id
		guid,                           -- guid
		C_Item.GetItemLink(location),   -- link
		GetServerTime(),                -- measured
		timeRemaining                   -- remaining
	)
end
---[[ LootLedger.TradeTime END --]]

---
---[[ LootLedger.TradeTimes BEGIN --]]
function TradeTimes:initialize()
	--- @type table<string, LootLedger.TradeTime>
	self.state = {}
	self.testItems = {}
	self.running = false
end

--- @return table<string, LootLedger.TradeTime>
function TradeTimes:GetState()
	return self.state
end

--- @return boolean
function TradeTimes:IsRunning()
	return self.running
end

function TradeTimes:Start()
	Logging:Trace("Start() : running=%s", tostring(self.running))
	if not self:IsRunning() then
		-- watch for the following events, batching them for a minimum of 5 seconds before processing
		self:RegisterBucketEvent(
			{C.Events.ZoneChanged, C.Events.PlayerEnteringWorld, C.Events.PlayerUnghost, C.Events.PlayerAlive, C.Events.LoadingScreenDisabled, C.Events.BagUpdateDelayed},
			-- during testing, don't delay firing for ease of validation
			AddOn._IsTestContext() and 0 or 5, function() self:Process() end
		)
		self.running = true
	end
end

function TradeTimes:Stop()
	Logging:Trace("Stop() : running=%s", tostring(self.running))
	if self:IsRunning() then
		self:UnregisterAllBuckets()
		self.running = false
	end
end

--[[
Examples of commands to test from within game

/run local TT = _G.Cleo.Testing.LootLedger.TradeTimes; TT:SetItems(56394, 59348, 62471, 59223); _G.Cleo:LootLedgerModule():GetTradeTimes():Process(true); TT:ClearItems()
/run _G.Cleo:LootLedgerModule():GetTradeTimes():Process(true)
--]]
function TradeTimes:Process(force)
	-- process trade times if we have items in storage or we are the master looter and operations are being handled
	local proceed = (force == true) or LootLedger:IsHandled()
	Logging:Debug("Process(%s) : proceed=%s", tostring(force), tostring(proceed))
	if not proceed then
		return
	end

	--Logging:Trace("Process(BEFORE_STATE) : %s", Util.Objects.ToString(self.state))
	local processed, mutated, start, examined, added, removed = {}, false, debugprofilestop(), 0, 0, 0
	AddOn:ForEachItemInBags(
		function(location, bag, slot)
			examined = examined +1
			local timeRemaining = AddOn:GetInventoryItemTradeTimeRemaining(bag, slot)
			-- trade time has expired or not bound to player w/ no expiration (e.g. BOE)
			--      item could have previously had remaining time and no longer does which means it will be "removed"
			--      items which aren't bound to player and have no associated trade time (and will not be tracked)
			if (timeRemaining <= 0) or (timeRemaining == C.Item.NotBoundTradeTime) then
				Logging:Trace("Process(%s, %s) : Expired or NotBoundTradeTime", tostring(bag), tostring(slot))
				return true
			end

			local itemGUID = C_Item.GetItemGUID(location)
			if not itemGUID then
				Logging:Warn("Process(%s, %s) : could not determine item GUID", tostring(bag), tostring(slot))
				return true
			end

			processed[itemGUID] = TradeTime.Create(itemGUID, location, timeRemaining)
			-- Sometimes the item name isn't in the link, but the rest of the stuff is there. This was verifying that
			-- Logging:Trace("%s", gsub(link or "", "\124", "\124\124"))
			Logging:Trace("Process(%s, %s) : %s", tostring(bag), tostring(slot), function() return Util.Objects.ToString(processed[itemGUID]:toTable()) end)

			-- a new item with a trade time
			if not self.state[itemGUID] then
				mutated = true
				added = added + 1
			end

			return true
		end
	)

	-- nothing new, but maybe something was removed
	if not mutated then
		for itemGuid, _ in pairs(self.state) do
			if not processed[itemGuid] then
				--Logging:Trace("Process) : Removed Item GUID %s", tostring(itemGuid))
				mutated = true
				removed = removed + 1
				-- commented out so can track removal count for debugging, without tracking it should be reintroduced
				-- break
			end
		end
	end

	-- always update state to most recent data, even if items weren't added or removed
	-- this guarantees it's reflective of most recent measurement for expirations
	-- technically, this isn't required as measure/remaining would change but be equivalent to previous measurement
	self.state = processed
	Logging:Debug("Process() : %d items examined (%d added, %d removed), %d items tracked, %d ms elapsed", examined, added, removed, Util.Tables.Count(self.state), debugprofilestop() - start)
	--Logging:Debug("Process(AFTER_STATE) : %s", function() return Util.Objects.ToString(self.state) end)

	-- items were added or removed
	if mutated then
		Logging:Trace("Process(): sending %s", C.Messages.TradeTimeItemsChanged)
		Message():Send(C.Messages.TradeTimeItemsChanged, processed)
	end
end

---[[ LootLedger.TradeTimes END --]]

---[[ LootLedger.Entry BEGIN --]]
--- @see Models.Item.LootedItem
function Entry:initialize(item, state, guid)
	LootedItem.initialize(self, item, state, guid)
	self.id = UUID.UUID()
end

function Entry:tostring()
	return Util.Objects.ToString(self:toTable())
end
---[[ LootLedger.Entry END --]]

---[[ LootLedger.Storage BEGIN --]]
function Storage:initialize(module, db)
	Dao.initialize(self, module, db, Entry)
	-- has the storage been validated since creation
	self.validated = false
	self.guidIndex = {}

	-- keep an index of guid to id for quick lookup
	self:ForEach(
		function(id, entry)
			if entry and Util.Strings.IsSet(entry.guid) then
				self.guidIndex[entry.guid] = id
			end
		end
	)
end

--- @param event string the event type
--- @param detail EventDetail the associated detail
function Storage:FireCallbacks(event, detail)
	--- @type LootLedger.Entry
	local entity = detail.entity
	if entity and Util.Strings.IsSet(entity.guid) then
		if Util.Objects.In(event, Dao.Events.EntityCreated, Dao.Events.EntityUpdated) then
			self.guidIndex[entity.guid] = entity.id
		elseif Util.Strings.Equal(event, Dao.Events.EntityDeleted) then
			self.guidIndex[entity.guid] = nil
		end
	end

	Storage.super.FireCallbacks(self, event, detail)
end

function Storage:RegisterCallbacks(target, callbacks)
	for event, fn in pairs(callbacks) do
		self.RegisterCallback(target, event, fn)
	end
end

function Storage:UnregisterCallbacks(target, callbacks)
	for _ , event in pairs(callbacks) do
		self.UnregisterCallback(target, event)
	end
end

function Storage:IsEmpty()
	return next(self.db) == nil
end

function Storage:Count()
	return Util.Tables.Count(self.db)
end

--- @return LootLedger.Storage
function Storage:Clear()
	if self.ShouldPersist() then
		self.db = {}
	end
	return self
end

--- @param itemGUID string
--- @return LootLedger.Entry
function Storage:GetByItemGUID(itemGUID)
	if Util.Strings.IsSet(itemGUID) and self.guidIndex[itemGUID] then
		return self:Get(self.guidIndex[itemGUID])
	end
end

---
--- Executes passed function for each entry in Storage. Processing can be preempted by returning false from function
---
--- @param fn function<string, LootLedger.Entry> two arguments, 1st is the entry's id (key) and 2nd is associated LootLedger.Entry. 2nd argument can be nil if it failed to reconstitute. returns boolean indicating if processing should continue, a nil return value is interpreted as true
--- @param sort function<table, table> optional function for sorting iteration based upon raw values (not reconstituted)
function Storage:ForEach(fn, sort)
	local entry

	--- @return function
	local function _generator()
		if Util.Objects.IsFunction(sort) then
			return Util.Tables.SortedByValue(self.db, sort)
		else
			return pairs(self.db)
		end
	end

	local finished = false

	for id, _ in _generator() do
		Util.Functions.try(
			function() entry = self:Get(id) end
		).catch(
			function(err)
				Logging:Error(
					"ForEach() : could not reconstitute Entry with id %s - %s",
					tostring(id), Util.Objects.ToString(err)
				)
				entry = nil
			end
		)

		finished = fn(id, entry) == false
		if finished then
			break
		end
	end
end
---[[ LootLedger.Storage END --]]