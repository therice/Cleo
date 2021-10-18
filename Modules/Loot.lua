--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Core.Event
local Event = AddOn.RequireOnUse('Core.Event')
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @type Models.Item.LootEntry
local LootEntry = AddOn.Package('Models.Item').LootEntry

--- @class Loot
local Loot = AddOn:NewModule("Loot", "AceTimer-3.0")

local RANDOM_ROLL_PATTERN =
_G.RANDOM_ROLL_RESULT:gsub("%(", "%%(")
  :gsub("%)", "%%)")
  :gsub("%%%d%$", "%%")
  :gsub("%%s", "(.+)")
  :gsub("%%d", "(%%d+)")

local ROLL_TIMEOUT, ROLL_SHOW_RESULT_TIME = 5, 5

function Loot:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
end

function Loot:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	---@type table<number, Models.Item.LootEntry>
	self.items = {}
	self.awaitingRolls = {}
	self:GetFrame()
	self:SubscribeToEvents()
	-- only register comms if support is enabled by ML
	local showLootResponses = AddOn:MasterLooterDbValue('showLootResponses')
	if Util.Objects.Default(showLootResponses, false) then
		self:SubscribeToComms()
	end
end

function Loot:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self:Stop()
	self:UnsubscribeFromEvents()
	self:UnsubscribeFromComms()
end

function Loot:EnableOnStartup()
	return false
end

function Loot:SubscribeToComms()
	self.commSubscriptions = Comm():BulkSubscribe(C.CommPrefixes.Main, {
		[C.Commands.Response] = function(data, sender)
			Logging:Debug("Response from %s", tostring(sender))
			self:OnResponseReceived(unpack(data))
		end,
	})
end

function Loot:SubscribeToEvents()
	Logging:Debug("SubscribeToEvents(%s)", self:GetName())
	self.eventSubscriptions = Event():BulkSubscribe({
	    [C.Events.ChatMessageSystem] = function(_, msg)
	        Logging:Debug("%s - %s",C.Events.ChatMessageSystem, Util.Objects.ToString(msg))
	        self:OnChatMessage(msg)
	    end
    })
end

function Loot:UnsubscribeFromEvents()
	Logging:Debug("UnsubscribeFromEvents(%s)", self:GetName())
	AddOn.Unsubscribe(self.eventSubscriptions)
	self.eventSubscriptions = nil
end

function Loot:UnsubscribeFromComms()
	Logging:Debug("UnsubscribeFromComms(%s)", self:GetName())
	AddOn.Unsubscribe(self.commSubscriptions)
	self.commSubscriptions = nil
end

function Loot:OnResponseReceived(session, candidate, data)
	if Util.Tables.ContainsKey(data, 'response') then
		---@type Models.Item.LootEntry
		local _, item = Util.Tables.FindFn(
			self.items,
			function(e) return Util.Objects.In(session, e.sessions) end
		)

		if item then
			item:TrackResponse(candidate, data.response)
		end
	end
end

function Loot:OnChatMessage(msg)
	Logging:Debug("OnChatMessage() : %s", msg)
	local name, roll, low, high = msg:match(RANDOM_ROLL_PATTERN)
	roll, low, high = tonumber(roll), tonumber(low), tonumber(high)
	Logging:Trace("OnChatMessage(%s) : %s, %d (%d - %d)",
	              tostring(#self.awaitingRolls), tostring(name), tonumber(roll), tonumber(low), tonumber(high)
	)

	if name and low == 1 and high == 100 and
		AddOn.UnitIsUnit(Ambiguate(name, "short"), "player") and
		self.awaitingRolls[1]
	then
		local el = self.awaitingRolls[1]
		tremove(self.awaitingRolls, 1)
		self:CancelTimer(el.timer)
		local entry = el.entry
		AddOn:Send(AddOn.masterLooter, C.Commands.Roll, AddOn.player:GetName(), roll, entry.item.sessions)
		AddOn:SendAnnouncement(format(L["roll_result"], AddOn.Ambiguate(AddOn.player), roll, entry.item.link), C.group)
		entry:SetResult(roll)
		self:ScheduleTimer("OnRollTimeout", ROLL_SHOW_RESULT_TIME, el)
	end
end

function Loot:Stop()
	Logging:Debug("Stop()")
	self:Hide()
	self.EntryManager:RecycleAll()
	self.items = {}
	self:CancelAllTimers()
end

--- @param offset number
--- @param session number
--- @param itemRef Models.Item.ItemRef
function Loot:AddItem(offset, session, itemRef)
	Logging:Debug("AddItem(%d, %d) : %s", offset, session, itemRef.item)
	local lootEntry = LootEntry.FromItemRef(itemRef, session, AddOn:MasterLooterDbValue('timeout.duration'))
	Logging:Debug("AddItem(%d, %d) : %s", offset, session, Util.Objects.ToString(lootEntry:toTable()))
	self.items[offset + session] = lootEntry
end

--- @param itemRef Models.Item.ItemRef
function Loot:AddSingleItem(itemRef)
	Logging:Debug("AddSingleItem() : %s, %d", itemRef.item, Util.Tables.Count(self.items))

	if not self:IsEnabled() then self:Enable() end
	if itemRef.autoPass then
		self.items[#self.items + 1] = LootEntry.Rolled()
	else
		self:AddItem(0, #self.items + 1, itemRef)
		self:Show()
	end
end

function Loot:CheckDuplicates(size, offset)
	for k = offset + 1, offset + size do
		if not self.items[k].rolled then
			for j = offset + 1, offset + size do
				if j ~= k and AddOn.ItemIsItem(self.items[k].link, self.items[j].link) and not self.items[j].rolled then
					Logging:Warn(
							"CheckDuplicates() : %s is a duplicate of %s",
							Util.Objects.ToString(self.items[k].link),
							Util.Objects.ToString(self.items[j].link)
					)

					Util.Tables.Push(self.items[k].sessions, self.items[j].sessions[1])
					-- Pretend we have rolled it
					self.items[j].rolled = true
				end
			end
		end
	end
end

--- @param lt table<number, Models.Item.ItemRef>
function Loot:Start(lt, reRoll)
	reRoll = Util.Objects.Default(reRoll, false)
	Logging:Debug("Start(%d, %s)", #lt, tostring(reRoll))

	local offset = 0
	if reRoll then
		offset = #self.items
	elseif #self.items > 0 then
		-- must start over if not a re-roll and already
		-- showing loot interface
		self:Stop()
	end

	for session = 1, #lt do
		-- autoPass could be set in AddOn:DoAutoPass()
		if Util.Objects.Default(lt[session].autoPass, false) then
			self.items[offset + session] = LootEntry.Rolled()
		else
			self:AddItem(offset, session, lt[session])
		end
	end

	self:CheckDuplicates(#lt, offset)
	self:Show()
end

function Loot:ReRoll(lt)
	Logging:Debug("ReRoll(%d)", Util.Tables.Count(lt))
	self:Start(lt, true)
end

function Loot:OnRoll(entry, button)
	local item = entry.item
	if not item.isRoll then
		for _, session in ipairs(item.sessions) do
			-- send to group and not master looter to support
			-- showing responses during loot window
			AddOn:SendResponse(C.group, session, button)
		end

		local response = AddOn:GetResponse(button)
		-- todo
		--[[
		local me = AddOn:StandingsModule():GetEntry(AddOn.player)
		--]]
		AddOn:Print(
			format(L["response_to_item"], AddOn.GetItemTextWithCount(item.link,#item.sessions)) ..
			" : " .. (response and response.text or "???")
		)

		item.rolled = true
		self.EntryManager:Recycle(entry)
		self:Update()
	else
		if button == C.Responses.Roll then
			local el = { sessions = item.sessions, entry = entry}
			Util.Tables.Push(self.awaitingRolls, el)
			-- for test context, scheduled timers are executed immediately
			-- don't want that during this workflow
			if not AddOn._IsTestContext() then
				-- In case roll result is not received within time limit, discard the result.
				el.timer = self:ScheduleTimer("OnRollTimeout", ROLL_TIMEOUT, el)
			end
			RandomRoll(1, 100)
			entry:DisableButtons()
		else
			item.rolled = true
			self.EntryManager:Recycle(entry)
			self:Update()
			AddOn:Send(C.group, C.Commands.Roll, AddOn.player:GetName(), "-", item.sessions)
		end
	end
end

function Loot:OnRollTimeout(el)
	Logging:Debug("OnRollTimeout()")
	tDeleteItem(self.awaitingRolls, el)
	el.entry.item.rolled = true
	self.EntryManager:Recycle(el.entry)
	self:Update()
end