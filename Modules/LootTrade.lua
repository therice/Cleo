--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @type Core.Event
local Event = AddOn.RequireOnUse('Core.Event')
--- @type Core.Message
local Message = AddOn.RequireOnUse('Core.Message')
--- @type LootLedger.Storage
local LedgerStorage = AddOn.Package('LootLedger').Storage
---@type LibDialog
local Dialog = AddOn:GetLibrary("Dialog")
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @class LootTrade
local LootTrade = AddOn:NewModule("LootTrade", "AceTimer-3.0")
LootTrade.defaults = {
	profile = {
		-- should items to be traded automatically be added to trade window
		autoTrade = false,
	}
}

local TradeAddDelay = 0.100 --[[ seconds --]]

function LootTrade:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.db:RegisterNamespace(self:GetName(), LootTrade.defaults)
	self.Send = Comm():GetSender(C.CommPrefixes.Main)
	self:SubscribeToMessages()
end

function LootTrade:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	-- is a trade interaction currently in-flight
	--- @type boolean
	self.trading = false
	-- name of the trade target
	--- @type string the player name
	self.target = nil
	-- what items are currently being traded, these are item links
	--- @type table<string>
	self.items = {}
	self:SubscribeToEvents()
	self:SubscribeToComms()
	self:Show()
end

function LootTrade:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self.trading = false
	self.target = nil
	wipe(self.items)
	self:UnsubscribeFromEvents()
	self:UnsubscribeFromComms()
	self:Hide()
end

function LootTrade:EnableOnStartup()
	return false
end

function LootTrade:SubscribeToEvents()
	Logging:Debug("SubscribeToEvents(%s)", self:GetName())
	self.eventSubscriptions = Event():BulkSubscribe({
		[C.Events.TradeShow] = function(_, ...)
			Logging:Trace("%s : %s", C.Events.TradeShow, Util.Objects.ToString({...}))
			self:OnTradeShow(...)
		end,
		[C.Events.TradeClosed] = function(_, ...)
			Logging:Trace("%s : %s", C.Events.TradeClosed, Util.Objects.ToString({...}))
			self:OnTradeClosed(...)
		end,
		[C.Events.TradeAcceptUpdate] = function(_, ...)
			Logging:Trace("%s : %s", C.Events.TradeAcceptUpdate, Util.Objects.ToString({...}))
			self:OnTradeAcceptUpdate(...)
		end,
		[C.Events.UIInfoMessage] = function(_, ...)
			Logging:Trace("%s : %s", C.Events.UIInfoMessage, Util.Objects.ToString({...}))
			self:OnUIInfoMessage(...)
		end,
	})
end

function LootTrade:UnsubscribeFromEvents()
	Logging:Trace("UnsubscribeFromEvents(%s)", self:GetName())
	AddOn.Unsubscribe(self.eventSubscriptions)
	self.eventSubscriptions = nil
end


function LootTrade:SubscribeToComms()
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	self.commSubscriptions = Comm():BulkSubscribe(C.CommPrefixes.Main, {
		[C.Commands.Awarded] = function(data, sender)
			-- only if we're the master looter and send the message ourselves
			if AddOn:IsMasterLooter() and AddOn:IsMasterLooter(sender) then
				self:OnAwarded(unpack(data))
			end
		end,
	})
end

function LootTrade:UnsubscribeFromComms()
	Logging:Trace("UnsubscribeFromComms(%s)", self:GetName())
	AddOn.Unsubscribe(self.commSubscriptions)
	self.commSubscriptions = nil
end

function LootTrade:SubscribeToMessages()
	Logging:Debug("SubscribeToMessages(%s)", self:GetName())
	-- don't track the subscriptions, we're never going to unsubscribe
	-- as it's the hook we use to enable/disable the loot trading module
	Message():BulkSubscribe({
		[C.Messages.HandleLootStart] = function(_, _)
			Logging:Debug("HandleLootStart()")
			if AddOn:MasterLooterModule():IsHandled() then
				AddOn:CallModule(self:GetName())
			end
		end,
		[C.Messages.HandleLootStop] = function(_, _)
			Logging:Debug("HandleLootStop()")
			if self:IsEnabled() then
				AddOn:YieldModule(self:GetName())
			end
		end
	})
end

---
--- Most of the necessary heavy lifting for awards is handled in MasterLooter (see RegisterAndAnnounceAward), but
--- there may be some extra stuff that needs done after should the
---
--- @param _ number the loot session identifier
--- @param _ string the winner of the item
--- @param owner string the person who currently has the item
--- @param ledgerId string the ide of the ledger entry
function LootTrade:OnAwarded(_, _, owner, ledgerId)
	-- we currently own the item (and are implicitly ML) and there is a ledger id
	if AddOn.UnitIsUnit(owner, "player") and Util.Strings.IsSet(ledgerId) then
		-- if there are no items for trade, this call will not display the UI
		-- this means we don't need to check additional predicates for the award being on that will occur via trade
		self:Show()
	end
end

---
--- Handles callback for loot ledger storage events
---
function LootTrade:OnLootLedgerStorageEvent(event, detail)
	Logging:Trace("OnLootLedgerStorageEvent(%s) : %s", event, Util.Objects.ToString(detail))
	self:Refresh()
end

---
--- Handles event for trade window close
---
function LootTrade:OnTradeClosed(...)
	self.trading = false
end

---
--- Handles event for trade window show
---
function LootTrade:OnTradeShow(...)
	-- event should only be dispatched if we are enabled due to registration for events, so don't
	-- recheck it here
	self.trading = true
	wipe(self.items)
	-- capture trade target via UI
	local target = _G.TradeFrameRecipientNameText and _G.TradeFrameRecipientNameText:GetText() or nil
	if not Util.Strings.IsSet(target) then
		target = "NPC"
	end

	self.target = AddOn:UnitName(target)
	local items = { }
	AddOn:LootLedgerModule():GetStorage():ForEach(
		function(_, entry)
			if entry then
				Util.Tables.Push(items, entry)
			end
		end, nil,
		LedgerStorage.Filters.ToTrade(),
		LedgerStorage.Filters.IsRecipient(self.target),
		LedgerStorage.Filters.HasTradeTimeRemaining()
	)

	if #items > 0 then
		if self.db.profile.autoTrade then
			self:AddItemsToTradeWindow(items)
		else
			Dialog:Spawn(C.Popups.ConfirmTradeItems, items)
		end
	end
end

function LootTrade:OnTradeAcceptUpdate(...)

end

function LootTrade:OnUIInfoMessage(...)

end
---
--- Adds all passed items to trade window, provided there are enough slots
---
--- @param items table<LootLedger.Entry>
function LootTrade:AddItemsToTradeWindow(items)
	Logging:Trace("AddItemsToTradeWindow(%d)", #items)
	--- @type number|LootLedger.Entry
	for i, item in ipairs(items) do
		-- all available slots used (last slot is "Will not be traded" slot)
		if i > _G.MAX_TRADE_ITEMS - 1 then
			break
		end

		if self.trading then
			Logging:Trace("AddItemsToTradeWindow() : scheduling trade window add for %s", tostring(item.item))
			-- this locates the item in bags and adds them to the trade window
			self:ScheduleTimer(
				--- @param index number the trade button index
				--- @param e LootLedger.Entry the ledger entry
				function(index, e)
					-- this is only to declare type for help with completion in IDE
					--- @type LootLedger.Entry
					local entry = e
					local bag, slot = entry:GetBagAndSlot()
					if not bag or not slot then
						Logging:Warn("AddItemToTradeWindow() : %s could not be found in your inventory", tostring(entry.item))
						AddOn:PrintWarning(format(L['item_to_trade_not_found'], tostring(entry.item)))
						return
					end

					local link = select(7, AddOn:GetContainerItemInfo(bag, slot))
					if AddOn.ItemIsItem(link, entry.item) then
						Logging:Trace("AddItemToTradeWindow() : trading %s from bag=%d/slot=%d", tostring(entry.item), bag, slot)
						ClearCursor()
						AddOn.C_Container.PickupContainerItem(bag, slot)
						ClickTradeButton(index)
					else
						Logging:Warn("AddItemToTradeWindow() : %s in bag=%d/slot=%d is not %s", link, tostring(entry.item))
						AddOn:PrintWarning(format(L['item_to_trade_changed'], tostring(entry.item)))
					end
				end,
				TradeAddDelay * i, i, item
			)
		end
	end
end

--- Callback from popup for modifying UI
---
--- @param frame Frame
--- @param items table<LootLedger.Entry>
function LootTrade:PerformTradeOnShow(frame, items)
	UIUtil.DecoratePopup(frame)
	frame.text:SetText(
		format(
			L['confirm_add_to_trade_window'],
			#items,
			UIUtil.PlayerClassColorDecorator(self.target):decorate(self.target)
		)
	)
end

--- Callback from popup when OK is clicked
---
--- @param _ Frame
--- @param items table<LootLedger.Entry>
function LootTrade:PerformTradeOnClickYes(_, items)
	self:AddItemsToTradeWindow(items)
end
