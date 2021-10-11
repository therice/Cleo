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
--- @type Models.Item.ItemRef
local ItemRef = AddOn.Package('Models.Item').ItemRef
--- @type Models.Item.LootSlotInfo
local LootSlotInfo = AddOn.Package('Models.Item').LootSlotInfo
--- @type Models.Item.LootTableEntry
local LootTableEntry = AddOn.Package('Models.Item').LootTableEntry
--- @type Models.Item.LootQueueEntry
local LootQueueEntry = AddOn.Package('Models.Item').LootQueueEntry
local LAR = AddOn.Package('Models.Item').LootAllocateResponse.Attributes
--- @type Models.Player
local Player = AddOn.Package('Models').Player
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type MasterLooterDb
local MasterLooterDb = AddOn.Require('MasterLooterDb')
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary('ItemUtil')

--- @class MasterLooter
local ML = AddOn:NewModule("MasterLooter", "AceEvent-3.0", "AceBucket-3.0", "AceTimer-3.0", "AceHook-3.0")

ML.AutoAwardType = {
	Equipable    = 1,
	NotEquipable = 2,
	All          = 99,
}

ML.AutoAwardRepItemsMode = {
	Person     = 1,
	RoundRobin = 2
}

-- these are reasons for an item award, some user visible and some are not
ML.AwardReasons = {
	ms_need = {
		user_visible = true,
		color        = C.Colors.Evergreen,
	},
	os_greed = {
		user_visible = true,
		color        = C.Colors.RogueYellow,
	},
	disenchant = {
		user_visible = false,
		color        = C.Colors.MageBlue,
	},
	bank = {
		user_visible = false,
		color        = C.Colors.Purple,
	},
	free = {
		user_visible = false,
		color        = C.Colors.Blue,
	}
}

ML.NonVisibleAwardReasons = {}

ML.AwardStringsDesc = {
	L["announce_&i_desc"],
	L["announce_&l_desc"],
	L["announce_&n_desc"],
	L["announce_&p_desc"],
	L["announce_&r_desc"],
	L["announce_&s_desc"],
	L["announce_&t_desc"],
	L["announce_&z_desc"],
}

ML.AnnounceItemStringsDesc = {
	L["announce_&i_desc"],
	L["announce_&l_desc"],
	L["announce_&s_desc"],
	L["announce_&t_desc"],
	L["announce_&z_desc"],
}

ML.UsageType= {
	Always  = 1,
	Ask     = 2,
	Never   = 99,
}

ML.defaults = {
	profile = {
		usage = {
			-- this applies when player is master looter
			state       = ML.UsageType.Ask,
			-- this applies when player is leader (should state setting be used then as well)
			whenLeader  = true,
		},
		-- should it only be enabled in raids
		onlyUseInRaids = true,
		-- is 'out of raid' support enabled (specifies auto-responses when user not in instance, but in raid)
		outOfRaid = true,
		-- should a session automatically be started with all eligible items
		autoStart  = false,
		-- automatically add all eligible equipable items to session
		autoAdd = true,
		-- automatically add all eligible non-equipable items to session (e.g. mounts)
		autoAddNonEquipable = false,
		-- automatically add all BoE (Bind on Equip) items to a session
		autoAddBoe = false,
		-- how long (in seconds) does a candidate have to respond to an item
		timeout = {
			enabled = true, duration = 60
		},
		-- are player's responses available (shown) in the loot dialogue
		showLootResponses = false,
		-- are whispers supported for candidate responses
		acceptWhispers = true,
		-- are awards announced via specified channel
		announceAwards = true,
		-- where awards are announced, channel + message
		announceAwardText = { channel = "group", text = "&p was awarded &i for &r (&z)"},
		-- are items under consideration announced via specified channel
		announceItems = true,
		-- the prefix/preamble to use for announcing items
		announceItemPrefix = "Items under consideration:",
		-- where items are announced, channel + message
		announceItemText = { channel = "group", text = "&s: &i (&z)"},
		-- are player's responses to items announced via specified channel
		announceResponses = true,
		-- where player's responses to items are announced, channel + message
		announceResponseText = { channel = "group", text = "&p specified &r for &i (&z)"},
		-- enables the auto-awarding of items that meet specific criteria
		autoAward = false,
		-- what types of items should be auto-awarded, supports
		-- equipable, non-equipable, and all currently
		autoAwardType = ML.AutoAwardType.Equipable,
		-- the lower threshold for item quality for auto-award
		autoAwardLowerThreshold = 2,
		-- the upper threshold for item quality for auto-award
		autoAwardUpperThreshold = 2,
		-- to whom any auto-awarded items should be assigned
		autoAwardTo = L["nobody"],
		-- the reason associated with auto-awarding of items
		autoAwardReason = 'free',
		-- dynamically constructed below
		-- example data left behind for illustration
		-- we don't support multiple categories/types of buttons, only the 'default'
		buttons = {
			--[[
			  numButtons = 2,
			  { text = L["ms_need"],          whisperKey = L["whisperkey_ms_need"], },
			  { text = L["os_greed"],         whisperKey = L["whisperkey_os_greed"], },
			--]]
		},
		-- we don't support multiple categories/types of responses, only the 'default'
		responses = {
			[C.Responses.Awarded]      = { color = C.Colors.White,              sort = 0.1, text = L["awarded"], },
			[C.Responses.NotAnnounced] = { color = C.Colors.Fuchsia,            sort = 501, text = L["not_announced"], },
			[C.Responses.Announced]    = { color = C.Colors.Fuchsia,            sort = 502, text = L["announced_awaiting_answer"], },
			[C.Responses.Wait]         = { color = C.Colors.LuminousYellow,     sort = 503, text = L["candidate_selecting_response"], },
			[C.Responses.Timeout]      = { color = C.Colors.LuminousOrange,     sort = 504, text = L["candidate_no_response_in_time"], },
			[C.Responses.Removed]      = { color = C.Colors.Pumpkin,            sort = 505, text = L["candidate_removed"], },
			[C.Responses.Nothing]      = { color = C.Colors.Nickel,             sort = 506, text = L["offline_or_not_installed"], },
			[C.Responses.Pass]         = { color = C.Colors.Aluminum,           sort = 800, text = _G.PASS, },
			[C.Responses.AutoPass]     = { color = C.Colors.Aluminum,           sort = 801, text = L["auto_pass"], },
			[C.Responses.Disabled]     = { color = C.Colors.AdmiralBlue,        sort = 802, text = L["disabled_addon"], },
			[C.Responses.NotInRaid]    = { color = C.Colors.Marigold,           sort = 803, text = L["not_in_instance"] },
			[C.Responses.Default]      = { color = C.Colors.LuminousOrange,     sort = 899, text = L["response_unavailable"] },
			-- dynamically constructed below
			-- example data left behind for illustration
			--[[
			{ color = {0,1,0,1},        sort = 1,   text = L["ms_need"], },         [1]
			{ color = {1,0.5,0,1},	    sort = 2,	text = L["os_greed"], },        [2]
			--]]
		}
	}
}

do
	-- now add additional dynamic options needed
	local DefaultButtons = ML.defaults.profile.buttons
	local DefaultResponses = ML.defaults.profile.responses

	-- these are the responses available to player when presented with a loot decision
	-- we only select ones that are "user visible", as others are only available to
	-- master looter (e.g. 'Free', 'Disenchant', 'Bank', etc.)
	local UserVisibleResponses =
		Util(ML.AwardReasons)
			:CopyFilter(function (v) return v.user_visible end, true, nil, true)()
	local UserNonVisibleResponses =
		Util(ML.AwardReasons)
			:CopyFilter(function (v) return not v.user_visible end, true, nil, true)()

	-- establish the number of user visible buttons
	DefaultButtons.numButtons = Util.Tables.Count(UserVisibleResponses)
	local index = 1
	for response, value in pairs(UserVisibleResponses) do
		-- these are entries that represent buttons available to player at time of loot decision
		Util.Tables.Push(DefaultButtons, {color = value.color, text = L[response], whisperKey = L['whisperkey_' .. response]})
		-- the are entries of the universe of possible responses, which are a super set of ones presented to the player
		Util.Tables.Push(DefaultResponses, {color = value.color, sort = index, text = L[response]})
		index = index + 1
	end

	for response, value in pairs(UserNonVisibleResponses) do
		ML.NonVisibleAwardReasons[response] = UIUtil.ColoredDecorator(value.color):decorate(L[response])
	end
end

function ML:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.db:RegisterNamespace(self:GetName(), ML.defaults)
	self.Send = Comm():GetSender(C.CommPrefixes.Main)
	--[[
	AddOn:SyncModule():AddHandler(
			self:GetName(),
			format("%s %s", L['ml'], L['settings']),
			function() return self.db.profile end,
			function(data) self:ImportData(data) end
	)
	--]]
end

function ML:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	-- is the ML's loot window open or closed
	self.lootOpen = false
	-- table of slot to loot information
	-- this is NOT the same as the loot table, as not all available loot
	-- is handled by addon based upon settings and item type
	--- @type table<number, Models.Item.LootSlotInfo>
	self.lootSlots = {}
	-- the ML's current loot table
	--- @type table<number, Models.Item.LootTableEntry>
	self.lootTable = {}
	-- for keeping a backup of loot table on session end
	--- @type table<number, Models.Item.LootTableEntry>
	self.lootTableOld = {}
	-- item(s) the ML has attempted to give out and waiting
	--- @type table<number, Models.Item.LootQueueEntry>
	self.lootQueue = {}
	-- is a session in flight
	self.running = false
	self:SubscribeToEvents()
	self:RegisterBucketMessage(C.Messages.ConfigTableChanged, 5, "ConfigTableChanged")
	self:SubscribeToComms()
end

function ML:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self:UnsubscribeFromEvents()
	self:UnregisterAllBuckets()
	self:UnregisterAllMessages()
	self:UnhookAll()
	self:UnsubscribeFromComms()
end

function ML:EnableOnStartup()
	return false
end

function ML:SubscribeToEvents()
	Logging:Debug("SubscribeToEvents(%s)", self:GetName())
	self.eventSubscriptions = Event():BulkSubscribe({
        [C.Events.ChatMessageWhisper] = function(_, ...)
	        self:OnChatMessageWhisper(...)
        end,
    })
end

function ML:SubscribeToComms()
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	self.commSubscriptions = Comm():BulkSubscribe(C.CommPrefixes.Main, {
		[C.Commands.MasterLooterDbRequest] = function(_, sender)
			Logging:Debug("MasterLooterDbRequest from %s", tostring(sender))
			MasterLooterDb:Send(C.group)
		end,
		[C.Commands.Reconnect] = function(_, sender)
			Logging:Debug("Reconnect from %s", tostring(sender))
			if not AddOn.UnitIsUnit(sender, AddOn.player) then
				self:OnReconnectReceived(sender)
			end
		end,
		[C.Commands.LootTable] = function(_, sender)
			Logging:Debug("LootTable from %s", tostring(sender))
			if AddOn.UnitIsUnit(sender, AddOn.player) then
				-- schedule an offline timer to be sent in ~15 seconds
				-- this signals a reasonable amount of time has passed for a response to be received
				-- and to transition response from announced after session has started
				self:ScheduleTimer("OnLootTableReceived", 15 + 0.5 * #self.lootTable)
			end
		end,
	})
end

function ML:UnsubscribeFromEvents()
	Logging:Debug("UnsubscribeFromEvents(%s)", self:GetName())
	AddOn.Unsubscribe(self.eventSubscriptions)
	self.eventSubscriptions = nil
end

function ML:UnsubscribeFromComms()
	Logging:Debug("UnsubscribeFromComms(%s)", self:GetName())
	AddOn.Unsubscribe(self.commSubscriptions)
	self.commSubscriptions = nil
end

-- when the db is changed, need to check if we must broadcast the new MasterLooter Db
-- the msg will be in the format of 'ace serialized message' = 'count of event'
-- where the deserialized message will be a tuple of 'module of origin' (e.g MasterLooter), 'db key name' (e.g. outOfRaid)
function ML:ConfigTableChanged(msg)
	Logging:Debug("ConfigTableChanged(%s)", self:GetName())

	local updateDb = not AddOn:HaveMasterLooterDb()

	for serializedMsg, _ in pairs(msg) do
		local success, module, val = AddOn:Deserialize(serializedMsg)
		Logging:Debug("ConfigTableChanged(%s) : %s",  Util.Objects.ToString(module), Util.Objects.ToString(val))
		if success and Util.Objects.In(module, self:GetName()) then
			if not updateDb then
				for key in pairs(AddOn.mlDb) do
					Logging:Debug("ConfigTableChanged() : examining %s, %s, %s", tostring(module), tostring(key), tostring(val))
					if Util.Strings.StartsWith(val, key) or Util.Strings.Equal(val, key)then
						updateDb = true
						break
					end
				end
			end
		end
		if updateDb then
			Logging:Debug("ConfigTableChanged() : Updating ML Db")
			self:UpdateDb()
		end
	end
end

function ML:OnChatMessageWhisper(...)
	Logging:Trace("OnChatMessageWhisper() : %s", Util.Objects.ToString({...}))
	if self:IsHandled() and self:GetDbValue('acceptWhispers') then
		local msg, sender = ...
		if Util.Strings.Equal(msg, '!help') then
			self:SendWhisperHelp(sender)
		elseif Util.Strings.Equal(msg, '!items') then
			self:SendWhisperItems(sender)
		elseif Util.Strings.StartsWith(msg, "!item") and self.running then
			self:GetItemsFromMessage(gsub(msg, "!item", ""):trim(), sender)
		end
	end
end

function ML:SendWhisperHelp(target)
	Logging:Trace("SendWhisperHelp(%s)", target)
	SendChatMessage(L["whisper_guide_1"], "WHISPER", nil, target)
	local msg, db = nil, self.db.profile
	for i = 1, db.buttons.numButtons do
		msg = "[" .. C.name .. "]: ".. db.buttons[i]["text"] .. ":  "
		msg = msg .. "" .. db.buttons[i]["whisperKey"]
		SendChatMessage(msg, "WHISPER", nil, target)
	end
	SendChatMessage(L["whisper_guide_2"], "WHISPER", nil, target)
end

function ML:SendWhisperItems(target)
	Logging:Trace("SendWhisperHelp(%s)", target)
	SendChatMessage(L["whisper_items"], "WHISPER", nil, target)
	if #self.lootTable == 0 then
		SendChatMessage(L["whisper_items_none"], "WHISPER", nil, target)
	else
		for session, item in pairs(self.lootTable) do
			SendChatMessage(format("[%d] : %s", session, tostring(item:GetItem().link)), "WHISPER", nil, target)
		end
	end
end

function ML:GetItemsFromMessage(msg, sender)
	Logging:Trace("GetItemsFromMessage(%s) : %s", sender, msg)

	local sessionArg, responseArg = AddOn:GetArgs(msg, 2)
	sessionArg = tonumber(sessionArg)

	if not sessionArg or not Util.Objects.IsNumber(sessionArg) or sessionArg > #self.lootTable then return end
	if not responseArg then return end

	Logging:Trace(
		"GetItemsFromMessage() : sender=%s, session=%s, response=%s",
		sender, tostring(sessionArg), tostring(responseArg)
	)

	-- default to response #1 if not specified
	local response = 1
	local whisperKeys = {}
	for k, v in pairs(self.db.profile.buttons) do
		if k ~= 'numButtons' then
			-- extract the whisperKeys to a table
			gsub(v.whisperKey, '[%w]+', function(x) tinsert(whisperKeys, {key = x, num = k}) end)
		end
	end

	for _,v in ipairs(whisperKeys) do
		if strmatch(responseArg, v.key) then
			response = v.num
			break
		end
	end

	local toSend = {
		gear1    = nil,
		gear2    = nil,
		ilvl     = 0,
		diff     = 0,
		response = response,
		note     = L["auto_extracted_from_whisper"],
	}

	local count = 0
	local link = self.lootTable[sessionArg].item
	for session, lte in ipairs(self.lootTable) do
		if AddOn.ItemIsItem(lte.item, link) then
			self:Send(C.group, C.Commands.Response, session, sender, toSend)
			count = count + 1
		end
	end

	AddOn:Print(format(L["item_response_ack_from_s"], link, AddOn.Ambiguate(sender)))
	SendChatMessage(
			format(L["whisper_item_ack"],
			       AddOn.GetItemTextWithCount(link, count),
			       AddOn:GetResponse(response).text
			), C.Channels.Whisper, nil, sender)
end

function ML:UpdateDb()
	Logging:Debug("UpdateDb")
	AddOn:OnMasterLooterDbReceived(MasterLooterDb:Get(true))
	MasterLooterDb:Send(C.group)
end
--
--- @return boolean indicating if ML operations are being handled
function ML:IsHandled()
	-- this module is enabled (and)
	-- we are the master looter (and)
	-- the addon is enabled (and)
	-- the addon is handling loot
	--Logging:Trace("IsHandled() : %s, %s, %s, %s",
	--              tostring(self:IsEnabled()), tostring(AddOn:IsMasterLooter()),
	--              tostring(AddOn.enabled), tostring(AddOn.handleLoot)
	--)
	return self:IsEnabled() and AddOn:IsMasterLooter() and AddOn.enabled and AddOn.handleLoot
end

----- @param ml Models.Player
function ML:NewMasterLooter(ml)
	Logging:Debug("NewMasterLooter(%s)", tostring(ml))
	if AddOn.UnitIsUnit(ml, C.player) then
		self:Send(C.group, C.Commands.PlayerInfoRequest)
		self:UpdateDb()
	else
		self:Disable()
	end
end

function ML:StartSession()
	Logging:Debug("StartSession(%s)", tostring(self.running))

	local forTransmit = self:_GetLootTableForTransmit()
	if self.running then
		self:Send(C.group, C.Commands.LootTableAdd, forTransmit)
	else
		self:Send(C.group, C.Commands.LootTable, forTransmit)
	end

	-- don't re-announce items that were previously sent
	-- only the new ones
	local announce = {}
	for session, _ in pairs(forTransmit) do
		announce[session] = self.lootTable[session]
	end

	Util.Tables.Call(self.lootTable, function(e) e.sent = true end)
	self.running = true
	self:AnnounceItems(announce)
end

function ML:EndSession()
	Logging:Debug("EndSession()")

	self.oldLootTable = self.lootTable
	self.lootTable = {}
	self:Send(C.group, C.Commands.LootSessionEnd)
	self.running = false
	self:CancelAllTimers()
	if AddOn:TestModeEnabled() then
		AddOn:ScheduleTimer("NewMasterLooterCheck", 1)
		AddOn.mode:Disable(C.Modes.Test)
	end
end

function ML:HaveUnawardedItems()
	for i = 1, #self.lootTable do
		if not self.lootTable[i].awarded then
			return true
		end
	end
	return false
end

ML.AnnounceItemStrings = {
	["&s"] = function(session) return session end,
	["&i"] = function(_, item) return item and item.link or "[???]" end,
	["&l"] = function(_, item)
		return item and item:GetLevelText() or "" end,
	["&t"] = function(_, item)
		return item and item:GetTypeText() or "" end,
	["&z"] = function(_, item) return "UNKNOWN" end,
}

function ML:AnnounceItems(items)
	if not self:GetDbValue('announceItems') then return end
	local channel, template = self:GetDbValue('announceItemText.channel'), self:GetDbValue('announceItemText.text')
	AddOn:SendAnnouncement(self:GetDbValue('announceItemPrefix'), channel)

	-- iterate the items and announce each
	Util.Tables.Iter(
		items,
		function(e, i)
			Logging:Debug("AnnounceItems() : %d => %s", i, Util.Objects.ToString(e))
			local itemRef = ItemRef.Resolve(e)
			local msg = template
			for repl, fn in pairs(self.AnnounceItemStrings) do
				msg = gsub(msg, repl,
				           escapePatternSymbols(
						           tostring(
								           fn(e.session or i, itemRef:GetItem())
						           )
				           )
				)
			end
			if e.isRoll then
				msg =  _G.ROLL .. ": " .. msg
			end
			AddOn:SendAnnouncement(msg, channel)
		end
	)
end

ML.AwardStrings = {
	["&s"] = function(_, _, _, _, session) return session or "" end,
	["&p"] = function(name) return AddOn.Ambiguate(name) end,
	["&i"] = function(_, item) return item and item.link or "[?]" end,
	["&r"] = function(...) return select(3, ...) or "" end,
	["&n"] = function(...) return select(4, ...) or "" end,
	["&l"] = function(_, item)
		return item and item:GetLevelText() or "" end,
	["&t"] = function(_, item)
		return item and item:GetTypeText() or "" end,
	["&z"] = function(...) return "UNKNOWN" end,
}

--
--
----- @param changeAward boolean if the item is being re-awarded (changed)
-----
--function ML:AnnounceAward(winner, link, response, roll, session, changeAward, gp)
--	if not self:GetDbValue('announceAwards') then return end
--
--	Logging:Debug("AnnounceAward(%d) : winner=%s, item=%s", session, winner, tostring(link))
--
--	for _, announceSettings in pairs(self:GetDbValue('announceAwardText')) do
--		local msg = announceSettings.text
--		for repl, fn in pairs(self.AwardStrings) do
--			msg = gsub(msg, repl,
--			           escapePatternSymbols(
--				           tostring(
--								fn(
--									winner,
--									ItemRef(link):GetItem(),
--									response,
--									roll,
--									session,
--									gp
--								)
--							)
--			           )
--					)
--		end
--
--		if changeAward then msg = "(" .. L["change_award"] .. ") " .. msg end
--		AddOn:SendAnnouncement(msg, announceSettings.channel)
--	end
--end

function ML:OnLootReady(...)
	if self:IsHandled() then
		wipe(self.lootSlots)
		if not IsInInstance() then return end
		if GetNumLootItems() <= 0 then return end
		self.lootOpen = true
		self:_ProcessLootSlots(
			function(...)
				return self:ScheduleTimer("OnLootReady", 0, C.Events.LootReady, ...)
			end,
			...
		)
	end
end

function ML:OnLootOpened(...)
	if self:IsHandled() then
		self.lootOpen = true

		local rescheduled =
			self:_ProcessLootSlots(
					function(...)
						-- failure processing loot slots, go no further
						local _, autoLoot, attempt = ...
						if not attempt then attempt = 1 else attempt = attempt + 1 end
						return self:ScheduleTimer("OnLootOpened", attempt / 10, C.Events.LootOpened, autoLoot, attempt)
					end,
					...
			)

		-- we made it through the loot slots (not rescheduled) so we can continue
		-- to processing the loot table
		if Util.Objects.IsNil(rescheduled) then
			wipe(self.lootQueue)
			if not InCombatLockdown() then
				self:_BuildLootTable()
			else
				AddOn:Print(L['cannot_start_loot_session_in_combat'])
			end
		end
	end
end

function ML:OnLootClosed(...)
	if self:IsHandled() then
		self.lootOpen = false
	end
end

function ML:OnLootSlotCleared(...)
	if self:IsHandled() then
		local slot = ...
		local loot = self:_GetLootSlot(slot)
		Logging:Debug("OnLootSlotCleared(%d)", slot)
		if loot and not loot.looted then
			loot.looted = true

			if not self.lootQueue or Util.Tables.Count(self.lootQueue) == 0 then
				Logging:Warn("OnLootSlotCleared() : loot queue is nil or empty")
				return
			end

			for i = #self.lootQueue, 1, -1 do
				local entry = self.lootQueue[i]
				-- Logging:Debug("OnLootSlotCleared(%d) : %s", slot, Util.Objects.ToString(entry:toTable()))
				if entry and entry.slot then
					if entry.timer then self:CancelTimer(entry.timer) end
					tremove(self.lootQueue, i)
					entry:Cleared(true, nil)
					-- only one entry in queue which corresponds to slot
					break
				end
			end
		end
	end
end

function ML:OnReconnectReceived(sender)
	Logging:Trace("OnReconnectReceived(%s)", sender)
	local player = Player:Get(sender)
	MasterLooterDb:Send(player)
	if self.running then
		self:ScheduleTimer("Send", 4, player, C.Commands.LootTable, self:_GetLootTableForTransmit(true))
	end
end

function ML:OnLootTableReceived()
	-- this is only used in the loot allocation interface,
	-- which is implicitly limited to ML, so only send there
	self:Send(AddOn.masterLooter, C.Commands.OfflineTimer)
end

--- @return Models.Item.LootSlotInfo
function ML:_GetLootSlot(slot)
	return self.lootSlots and self.lootSlots[slot] or nil
end

--- @param onFailure function a function to be invoked should a loot slot be unhandled
--- @return table reference to any schedule that resulted from invoking onFailure
function ML:_ProcessLootSlots(onFailure, ...)
	local numItems = GetNumLootItems()
	Logging:Debug("_ProcessLootSlots(%d)", numItems)
	if numItems > 0 then
		-- iterate through the available items, tracking each individual loot slot
		for slot = 1, numItems do
			-- see if we have already added it, because of callbacks
			local loot = self:_GetLootSlot(slot)
			if (not loot and LootSlotHasItem(slot)) or (loot and not AddOn.ItemIsItem(loot:GetItemLink(), GetLootSlotLink(slot))) then
				Logging:Debug(
						"_ProcessLootSlots(%d): attempting to (re) add loot info at slot, existing=%s",
						slot, tostring(not Util.Objects.IsNil(loot))
				)
				if not self:_AddLootSlot(slot, ...) then
					Logging:Warn(
							"_ProcessLootSlots(%d) : uncached item in loot table, invoking 'onFailure' (function) ...",
							slot
					)
					return onFailure(...)
				end
			end
		end
	end
end

--- @return boolean indicating if loot slot was handled (not necessarily added to loot slots, i.e. currency or blacklisted)
function ML:_AddLootSlot(slot, ...)
	Logging:Debug("_AddLootSlot(%d)", slot)
	-- https://wow.gamepedia.com/API_GetLootSlotInfo
	local texture, name, quantity, currencyId, quality = GetLootSlotInfo(slot)
	-- https://wow.gamepedia.com/API_GetLootSourceInfo
	-- the creature being looted
	local guid = AddOn:ExtractCreatureId(GetLootSourceInfo(slot))
	if texture then
		-- return's the link for item at specified slot
		-- https://wow.gamepedia.com/API_GetLootSlotLink
		local link = GetLootSlotLink(slot)
		if currencyId then
			Logging:Debug("_AddLootSlot(%d) : ignoring %s as it's currency", slot, tostring(link))
		elseif not AddOn:IsItemBlacklisted(link) then
			Logging:Debug("_AddLootSlot(%d) : adding %s from creature %s to loot table", slot, tostring(link), tostring(guid))
			self.lootSlots[slot] = LootSlotInfo(
					slot,
					name,
					link,
					quantity,
					quality,
					guid,
					GetUnitName("target") -- we're looting a creature, so the target will be that creature
			)
		end

		return true
	end

	return false
end

function ML:_UpdateLootSlots()
	Logging:Debug("_UpdateLootSlots()")

	if not self.lootOpen then
		Logging:Warn("UpdateLootSlots() : attempting to update loot slots without an open loot window")
		return
	end

	local updatedLootSlots = {}
	for slot = 1, GetNumLootItems() do
		local item = GetLootSlotLink(slot)
		for session = 1, #self.lootTable do
			local itemEntry = self:_GetLootTableEntry(session)
			if not itemEntry.awarded and not updatedLootSlots[session] then
				if AddOn.ItemIsItem(item, itemEntry.item) then
					if slot ~= itemEntry.slot then
						Logging:Debug("_UpdateLootSlots(%d) : previously at %d, not at %d", session, itemEntry.slot, slot)
					end
					itemEntry.slot = slot
					updatedLootSlots[session] = true
					break
				end
			end
		end
	end

end

--- @return Models.Item.LootTableEntry
function ML:_GetLootTableEntry(session)
	return self.lootTable and self.lootTable[session] or nil
end

function ML:RemoveLootTableEntry(session)
	Logging:Debug("RemoveLootTableEntry(%d)", session)
	Util.Tables.Remove(self.lootTable, session)
end

function ML:_BuildLootTable()
	local numItems = GetNumLootItems()
	Logging:Debug("_BuildLootTable(%d, %s)", numItems, tostring(self.running))

	if numItems > 0 then
		local LS = AddOn:LootSessionModule()
		if self.running or LS:IsRunning() then
			self:_UpdateLootSlots()
		else
			for slot = 1, numItems do
				local item = self:_GetLootSlot(slot)
				if item then
					self:ScheduleTimer("HookLootButton", 0.5, slot)
					local link, quantity, quality = item:GetItemLink(), item.quantity, item.quality
					local autoAward, mode, winner = self:ShouldAutoAward(link, quality)
					if autoAward and quantity > 0 then
						self:AutoAward(slot, link, quality, winner, mode)
					elseif link and quantity > 0 and self:ShouldAddItem(link, quality) then
						-- item that should be added
						self:_AddLootTableEntry(slot, link)
					elseif quantity == 0 then
						-- currency
						LootSlot(slot)
					end
				end
			end

			Logging:Debug("_BuildLootTable(%d, %s)", #self.lootTable, tostring(self.running))

			if #self.lootTable > 0 and not self.running then
				if self.db.profile.autoStart then
					self:StartSession()
				else
					AddOn:CallModule(LS:GetName())
					LS:Show(self.lootTable)
				end
			end
		end
	end
end

--- @param slot number  index of the item within the loot table, can be Nil if item was not added froma  loot table
--- @param item any  ItemID|ItemString|ItemLink
function ML:_AddLootTableEntry(slot, item)
	Logging:Trace("_AddLootTableEntry(%d, %s)", tostring(slot), tostring(item))

	local entry = LootTableEntry(slot, item)
	Util.Tables.Push(self.lootTable, entry)
	Logging:Debug(
			"_AddLootTableEntry() : %s (slot %d) added to loot table at index %d",
			tostring(item), tostring(slot), tostring(#self.lootTable)
	)

	-- make a call to get item information, it may not be available immediately
	-- but this will submit a query
	local itemRef = entry:GetItem()
	if not itemRef or not itemRef:IsValid() then
		-- no need to schedule another invocation of this
		-- the call to GetItem() submitted a query, it should be available by time it's needed
		Logging:Trace("_AddLootTableEntry() : item info unavailable for %s, but query has been initiated", tostring(item))
	else
		AddOn:SendMessage(C.Messages.MasterLooterAddItem, item, entry)
	end
end

function ML:_GetLootTableForTransmit(overrideSent)
	overrideSent = Util.Objects.Default(overrideSent, false)
	Logging:Trace("_GetLootTableForTransmit(%s)", tostring(overrideSent))
	local lt =
		Util(self.lootTable)
			:Copy()
			:Map(
				function(e)
					if not overrideSent and e.sent then
						return nil
					else
						return e:ForTransmit()
					end
				end
			)()
	Logging:Trace("_GetLootTableForTransmit() : %s", Util.Objects.ToString(lt))
	return lt
end

function ML:HookLootButton(slot)
	local lootButton = getglobal("LootButton".. slot)
	-- ElvUI
	if getglobal("ElvLootSlot".. slot) then lootButton = getglobal("ElvLootSlot".. slot) end
	local hooked = self:IsHooked(lootButton, "OnClick")
	if lootButton and not hooked then
		Logging:Debug("HookLootButton(%d)", slot)
		self:HookScript(lootButton, "OnClick", "LootOnClick")
	end
end

function ML:LootOnClick(button)
	if not IsAltKeyDown() or IsShiftKeyDown() or IsControlKeyDown() then return end
	Logging:Debug("LootOnClick(%s)", Util.Objects.ToString(button))

	if getglobal("ElvLootFrame") then button.slot = button:GetID() end

	-- check that we're not already looting that item
	for _, v in ipairs(self.lootTable) do
		if button.slot == v.slot then
			AddOn:Print(L["loot_already_on_list"])
			return
		end
	end

	local LS = AddOn:LootSessionModule()
	self:_AddLootTableEntry(button.slot, GetLootSlotLink(button.slot))
	AddOn:CallModule(LS:GetName())
	LS:Show(self.lootTable)
end

---@param item any
---@param quality number
---@return boolean
function ML:ShouldAddItem(item, quality)
	local addItem = false

	-- item is available (AND)
	-- auto-adding of items is enabled (AND)
	-- item is equipable or auto-adding non-equipable items is enabled (AND)
	-- quality is set and >= our threshold (AND)
	-- item is not BOE or auto-adding of BOE is enabled
	if item and quality then
		if self.db.profile.autoAdd and
			(IsEquippableItem(item) or self.db.profile.autoAddNonEquipable) and
			quality >= GetLootThreshold() then
			addItem = self.db.profile.autoAddBoe or not AddOn.IsItemBoe(item)
		end
	end

	Logging:Debug("ShouldAddItem(%s, %s) : %s", tostring(item), tostring(quality), tostring(addItem))
	return addItem
end

--ML.AwardStatus = {
--	Failure = {
--		LootGone                  = "LootGone",
--		LootNotOpen               = "LootNotOpen",
--		MLInventoryFull           = "MLInventoryFull",
--		MLNotInInstance           = "MLNotInInstance",
--		NotBop                    = "NotBop",
--		NotInGroup                = "NotInGroup",
--		NotMLCandidate            = "NotMLCandidate",
--		Offline                   = "Offline",
--		OutOfInstance             = "OutOfInstance",
--		QualityBelowThreshold     = "QualityBelowThreshold",
--		Timeout                   = "Timeout",
--	},
--	Success = {
--		ManuallyAdded = "ManuallyAdded",
--		Normal        = "Normal",
--	},
--	Neutral = {
--		TestMode = "TestMode",
--	}
--}
--
--function ML:CanGiveLoot(slot, item, winner)
--	local AS, lootSlotInfo = self.AwardStatus, self:_GetLootSlot(slot)
--	if not self.lootOpen then
--		return false, AS.Failure.LootNotOpen
--	elseif not lootSlotInfo or not AddOn.ItemIsItem(lootSlotInfo.item, item) then
--		return false, AS.Failure.LootGone
--	elseif AddOn.UnitIsUnit(winner, C.player) and not self:HaveFreeSpaceForItem(item) then
--		return false, AS.Failure.MLInventoryFull
--	elseif not AddOn.UnitIsUnit(winner, C.player) then
--		-- item quality below loot threshold
--		if lootSlotInfo.quality < GetLootThreshold() then
--			return false, AS.Failure.QualityBelowThreshold
--		end
--
--		local shortName = Ambiguate(winner, "short"):lower()
--		-- winner is not in the group
--		if not UnitInParty(shortName) and not UnitInRaid(shortName) then
--			return false, AS.Failure.NotInGroup
--		end
--
--		-- winner is offline
--		if not UnitIsConnected(shortName) then
--			return false, AS.Failure.Offline
--		end
--
--		-- ML leaves the instance during a session
--		if not IsInInstance() then
--			return false, AS.Failure.MLNotInInstance
--		end
--
--		-- winner not in the same instance as ML
--		if select(4, UnitPosition(Ambiguate(winner, "short"))) ~= select(4, UnitPosition("player")) then
--			return false, AS.Failure.OutOfInstance
--		end
--
--		local found = false
--		for i = 1, _G.MAX_RAID_MEMBERS do
--			if AddOn.UnitIsUnit(GetMasterLootCandidate(slot, i), winner) then
--				found = true
--				break
--			end
--		end
--
--		if not found then
--			local bindType = select(14, GetItemInfo(item))
--			if bindType ~= LE_ITEM_BIND_ON_ACQUIRE then
--				return false, AS.Failure.NotBop
--			else
--				return false, AS.Failure.NotMLCandidate
--			end
--		end
--	end
--
--	return true, nil
--end

-- Do we have free space in our bags to hold this item?
function ML:HaveFreeSpaceForItem(item)
	local itemFamily = GetItemFamily(item)
	local equipSlot = select(4, GetItemInfoInstant(item))
	if equipSlot == "INVTYPE_BAG" then itemFamily = 0 end

	for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local freeSlots, bagFamily = GetContainerNumFreeSlots(bag)
		if freeSlots and freeSlots > 0 and (bagFamily == 0 or bit.band(itemFamily, bagFamily) > 0) then
			return true
		end
	end

	return false
end

----- @param award Models.Item.ItemAward
--function ML:RegisterAndAnnounceAward(session, winner, response, reason, gp)
--	Logging:Debug("RegisterAndAnnounceAwarded(%d) : %s", session, winner)
--	local ltEntry = self:_GetLootTableEntry(session)
--	local previousWinner = ltEntry.awarded
--	ltEntry.awarded = winner
--
--	self:Send(C.group, C.Commands.Awarded, session, winner)
--	self:AnnounceAward(
--			winner,
--			ltEntry.item,
--			reason and reason.text or response,
--			AddOn:LootAllocateModule():GetCandidateData(session, winner, LAR.Roll),
--			session,
--			previousWinner,
--			gp
--	)
--
--	-- not more items to award, end the session
--	if not self:HaveUnawardedItems() then
--		AddOn:Print(L["all_items_have_been_awarded"])
--		self:ScheduleTimer('EndSession', 2)
--	end
--
--	return true
--end
--
--function ML:PrintLootError(cause, item, winner)
--	local AS = self.AwardStatus
--
--	if Util.Objects.Equals(cause, AS.Failure.LootNotOpen) then
--		AddOn:Print(L["unable_to_give_loot_without_loot_window_open"])
--	elseif Util.Objects.Equals(cause, AS.Failure.Timeout) then
--		AddOn:Print(
--			format(L["timeout_giving_item_to_player"], item, UIUtil.PlayerClassColorDecorator(winner):decorate(AddOn.Ambiguate(winner))),
--			" - ",
--			_G.ERR_INV_FULL
--		)
--	else
--		local prefix =
--			format(
--				L["unable_to_give_item_to_player'"],
--				item,
--				UIUtil.PlayerClassColorDecorator(winner):decorate(AddOn.Ambiguate(winner)) .. " - "
--			)
--
--		if Util.Objects.Equals(cause, AS.Failure.LootGone) then
--			AddOn:Print(prefix, _G.LOOT_GONE)
--		elseif Util.Objects.Equals(cause, AS.Failure.MLInventoryFull) then
--			AddOn:Print(prefix, _G.ERR_INV_FULL)
--		elseif Util.Objects.Equals(cause, AS.Failure.QualityBelowThreshold) then
--			AddOn:Print(prefix, L["item_quality_below_threshold"])
--		elseif Util.Objects.Equals(cause, AS.Failure.NotInGroup) then
--			AddOn:Print(prefix, L["player_not_in_group"])
--		elseif Util.Objects.Equals(cause, AS.Failure.Offline) then
--			AddOn:Print(prefix, L["player_offline"])
--		elseif Util.Objects.Equals(cause, AS.Failure.MLNotInInstance) then
--			AddOn:Print(prefix, L["you_are_not_in_instance"])
--		elseif Util.Objects.Equals(cause, AS.Failure.OutOfInstance) then
--			AddOn:Print(prefix, L["player_not_in_instance"])
--		elseif Util.Objects.Equals(cause, AS.Failure.NotMLCandidate) then
--			AddOn:Print(prefix, L["player_ineligible_for_item"])
--		elseif Util.Objects.Equals(cause, AS.Failure.NotBop) then
--			AddOn:Print(prefix, L["item_only_able_to_be_looted_by_you_bop"])
--		else
--			AddOn:Print(prefix)
--		end
--	end
--end
--
--function ML:AwardResult(success, session, winner, status, callback, ...)
--	AddOn:SendMessage(success and C.Messages.AwardSuccess or C.Messages.AwardFailed, session, winner, status)
--	if callback then
--		callback(success, session, winner, status, ...)
--	end
--end
--
--function ML:OnGiveLootTimeout(lqEntry)
--	-- remove entry from queue
--	for k, v in pairs(self.lootQueue) do
--		if Util.Objects.Equals(v, lqEntry) then
--			tremove(self.lootQueue, k)
--		end
--	end
--
--	lqEntry:Cleared(false, self.AwardStatus.Failure.Timeout)
--end
--
--function ML:GiveLoot(slot, winner, callback, ...)
--	Logging:Debug("GiveLoot() : slot=%d, winner=%s", slot, tostring(winner))
--	if self.lootOpen then
--		local lqEntry = LootQueueEntry(slot, callback, {...})
--		if not AddOn._IsTestContext() then
--			lqEntry.timer = self:ScheduleTimer(function() self:OnGiveLootTimeout(lqEntry) end, 5)
--		end
--
--		Util.Tables.Push(self.lootQueue, lqEntry)
--
--		for i = 1, MAX_RAID_MEMBERS do
--			if AddOn.UnitIsUnit(GetMasterLootCandidate(slot, i), winner) then
--				Logging:Debug("GiveLoot(%d, %d)", slot, i)
--				GiveMasterLoot(slot, i)
--				break
--			end
--		end
--
--		if AddOn.UnitIsUnit(winner, C.player) then
--			Logging:Debug("GiveLoot(%d) : Giving to ML", slot)
--			LootSlot(slot)
--		end
--	end
--end
--
--
-----@param callback function This function will be called as callback(awarded, session, winner, status, ...)
-----@return boolean true if award is success. false if award is failed. nil if we don't know the result yet.
---- function ML:Award(award, callback, ...)
--function ML:Award(session, winner, response, reason, callback, ...)
--	Logging:Debug("Award(%d) : winner=%s", session, tostring(winner))
--	if not self.lootTable or #self.lootTable == 0 then
--		if self.oldLootTable and #self.oldLootTable > 0 then
--			self.lootTable = self.oldLootTable
--		else
--			Logging:Error("Award() : neither loot table (current or old) is populated")
--			return false
--		end
--	end
--
--	assert(Util.Objects.IsSet(winner), "No winner specified for item award")
--
--	local AS = self.AwardStatus
--	local args = {...}
--	local award, ltEntry = args[1], self:_GetLootTableEntry(session)
--	local link, gp, slot = award.link, award:GetGp(), ltEntry.slot
--
--	Logging:Debug("Award() : award=%s, lte=%s, slot=%d, item=%s",
--	              Util.Objects.ToString(award and award:toTable() or {}),
--	              Util.Objects.ToString(ltEntry:toTable()),
--	              slot,
--	              tostring(link)
--	)
--
--	-- previously awarded
--	if ltEntry.awarded then
--		self:RegisterAndAnnounceAward(session, winner, response, reason, gp)
--		-- the entry could be missing a loot slot if not added from a loot table
--		if not ltEntry.slot then
--			self:AwardResult(true, session, winner, AddOn:TestModeEnabled() and AS.Neutral.TestMode or AS.Success.ManuallyAdded, callback, ...)
--		else
--			self:AwardResult(true, session, winner, AS.Success.Normal, callback, ...)
--		end
--		return true
--	end
--
--	-- not previously awarded
--	-- the entry could be missing a loot slot if not added from a loot table
--	if not slot then
--		self:AwardResult(true, session, winner, AddOn:TestModeEnabled() and AS.Neutral.TestMode or AS.Success.ManuallyAdded, callback, ...)
--		self:RegisterAndAnnounceAward(session, winner, response, reason, gp)
--		return true
--	end
--
--	if self.lootOpen and not AddOn.ItemIsItem(link, GetLootSlotLink(slot)) then
--		Logging:Debug("Award(%d) : Loot slot changed before award completed", session)
--		self:_UpdateLootSlots()
--	end
--
--	local ok, cause = self:CanGiveLoot(slot, link, winner or AddOn.player:GetName())
--	Logging:Debug("Award(%d) : canGiveLoot=%s, cause=%s", award.session, tostring(ok), tostring(cause))
--	if not ok then
--		self:AwardResult(false, session, winner, cause, callback, ... )
--		self:PrintLootError(cause, link, winner or AddOn.player:GetName())
--		return false
--	else
--		self:GiveLoot(
--			slot,
--			winner,
--			function(awarded, cause)
--				if awarded then
--					self:RegisterAndAnnounceAward(session, winner, response, reason, award:GetGp())
--					self:AwardResult(awarded, session, winner, AS.Success.Normal, callback, unpack(args))
--					return true
--				else
--					self:AwardResult(awarded, session, winner, cause, callback, unpack(args))
--					self:PrintLootError(cause, link, winner)
--					return false
--				end
--            end
--		)
--	end
--end
--
---- Modes for distinguising between types of auto awards
--local AutoAwardMode = {
--	Normal          =   "normal",
--	ReputationItem  =   "rep_item",
--}
--
-----@param item any
-----@param quality number
-----@return boolean
-----@return string
-----@return string
--function ML:ShouldAutoAward(item, quality)
--	if not item then return false end
--	Logging:Debug("ShouldAutoAward() : item=%s, quality=%d", tostring(item), quality)
--
--	local db = self.db.profile
--
--	local function IsEligibleUnit(unit)
--		return UnitInRaid(unit) or UnitInParty(unit)
--	end
--
--	local function IsEligibleItem(item)
--		local itemId = ItemUtil:ItemLinkToId(item)
--		-- reputation items are handled separately, always false
--		if itemId and ItemUtil:IsReputationItem(itemId) then
--			return false
--		end
--
--		local isEquippable = IsEquippableItem(item)
--		return  (db.autoAwardType == AutoAwardType.All) or
--				(db.autoAwardType == AutoAwardType.Equippable and isEquippable) or
--				(db.autoAwardType == AutoAwardType.NotEquippable and not isEquippable)
--	end
--
--	if db.autoAward and
--		quality >= db.autoAwardLowerThreshold and
--		quality <= db.autoAwardUpperThreshold and
--		IsEligibleItem(item)
--	then
--		if db.autoAwardLowerThreshold >= GetLootThreshold() or db.autoAwardLowerThreshold < 2 then
--			-- E.G. ["autoAwardTo"] = "Zùùl"
--			if IsEligibleUnit(db.autoAwardTo) then
--				return true, AutoAwardMode.Normal, db.autoAwardTo
--			else
--				AddOn:Print(L["cannot_auto_award"])
--				AddOn:Print(format(L["could_not_find_player_in_group"], db.autoAwardTo))
--				return false
--			end
--		else
--			AddOn:Print(format(L["could_not_auto_award_item"], tostring(item)))
--		end
--	end
--
--	if db.autoAwardRepItems then
--		local itemId = ItemUtil:ItemLinkToId(item)
--		if itemId and ItemUtil:IsReputationItem(itemId) then
--			-- E.G. ["autoAwardRepItemsTo"] = "Zùùl"
--			local awardTo = db.autoAwardRepItemsTo
--			-- todo
--			--[[
--			if db.autoAwardRepItemsMode == AutoAwardRepItemsMode.RoundRobin then
--                if not self.repItemsRR then
--                    Logging:Warn("ShouldAutoAward() : Round-robin awarding enabled, but no tracked state. Attempting to use 'autoAwardRepItemsTo'")
--                else
--                    -- we return the next person to which award should be made
--                    -- state mutation and persistence will only occur after award
--                    --
--                    -- there is a window of opportunity here that returned person may have
--                    -- left the raid, but it's very small so not accounting for ATM
--                    awardTo = Ambiguate(self.repItemsRR:peek().id, "short")
--                end
--			end
--			--]]
--
--			if IsEligibleUnit(awardTo) then
--				return true, AutoAwardMode.ReputationItem, awardTo
--			else
--				AddOn:Print(L["cannot_auto_award"])
--				AddOn:Print(format(L["could_not_find_player_in_group"], awardTo))
--				return false
--			end
--		end
--	end
--
--	return false
--end
--
----- @return boolean
--function ML:AutoAward(slot, item, quality, winner, mode)
--	winner = AddOn:UnitName(winner)
--	Logging:Debug(
--			"AutoAward() : slot=%d, item=%s, quality=%d, winner=%s, mode=%s",
--			tonumber(slot), tostring(item), tonumber(quality), winner, tostring(mode)
--	)
--
--	local db = self.db.profile
--	if Util.Strings.Equal(mode, AutoAwardMode.Normal) then
--		-- Perform an extra check for normal auto-awards, as Blizzard prevents you from
--		-- looting items below a specific quality threshold to anyone except yourself
--		-- 0 == Poor
--		-- 1 == Common
--		-- 2 == Uncommon
--		if db.autoAwardLowerThreshold < 2 and quality < 2 and not AddOn:UnitIsUnit(winner, "player") then
--			AddOn:Print(
--					format(
--							L["cannot_auto_award_quality"],
--							_G.ITEM_QUALITY_COLORS[2].hex .. _G.ITEM_QUALITY2_DESC .. "|r"
--					)
--			)
--			return false
--		end
--	end
--
--	local function PostAutoAward(success)
--		-- in face of boolean not being specified, just exit
--		if not Util.Objects.IsBoolean(success) then return end
--
--		-- todo : rr rep items
--		--[[
--		if Util.Strings.Equal(mode, AutoAwardMode.ReputationItem) and self:AutoAwardRepItemsIsRR() then
--			if success then
--				-- updates the award count and sends them back of line for next award
--				Logging:Debug("AutoAward() : Success, updating number of awards and moving %s to back of the line", winner)
--				self.repItemsRR:next()
--			else
--				-- not a success, maybe the candidate isn't online or has full bags
--				-- skip over them for now, considering next candidate
--				Logging:Warn("AutoAward() : Failure, skipping %s", winner)
--				self.repItemsRR:skip()
--			end
--
--			self:AutoAwardRepItemsPersist()
--		end
--		--]]
--	end
--
--
--	local canGiveLoot, cause = self:CanGiveLoot(slot, item, winner)
--	if not canGiveLoot then
--		AddOn:Print(L["cannot_auto_award"])
--		self:PrintLootError(cause, item, winner)
--		PostAutoAward(false)
--		return false
--	else
--		local awardReasonIdx
--		if Util.Strings.Equal(mode, AutoAwardMode.Normal) then
--			awardReasonIdx = db.autoAwardReason
--		elseif Util.Strings.Equal(mode, AutoAwardMode.ReputationItem) then
--			awardReasonIdx = db.autoAwardRepItemsReason
--		else
--			AddOn:Print(L["cannot_auto_award"])
--			AddOn:Print(format(L["auto_award_invalid_mode"], mode))
--			return false
--		end
--
--		local awardReason = AddOn:LootAllocateModule().db.profile.awardReasons[awardReasonIdx]
--		self:GiveLoot(
--				slot,
--				winner,
--				function(awarded, cause)
--					if awarded then
--						self:AnnounceAward(winner, item, awardReason.text)
--						PostAutoAward(true)
--						-- todo : track history
--						return true
--					else
--						AddOn:Print(L["cannot_auto_award"])
--						self:PrintLootError(cause, item, winner)
--						PostAutoAward(false)
--						return false
--					end
--				end
--		)
--		return true
--	end
--end
--
--function ML.AwardOnShow(frame, award)
--	UIUtil.DecoratePopup(frame)
--	frame.text:SetText(
--			format(L["confirm_award_item_to_player"],
--			       award.link,
--			       UIUtil.ClassColorDecorator(award.class):decorate(AddOn.Ambiguate(award.winner))
--			)
--	)
--	frame.icon:SetTexture(award.texture)
--end
--
----- @param award Models.Item.ItemAward
----- @param callback function
--function ML.AwardOnClickYes(_, award, callback, ...)
--	Logging:Debug('AwardOnClickYes() : %s', Util.Objects.ToString(award:toTable()))
--	local function PostAward(awarded, session, winner, status, award, callback, ...)
--		if callback and Util.Objects.IsFunction(callback) then
--			callback(awarded, session, winner, status, award, ...)
--		end
--
--		if awarded then
--			AddOn:GearPointsModule():OnAwardItem(award)
--		end
--	end
--
--	ML:Award(
--		award.session,
--		award.winner,
--		award:NormalizedReason().text,
--		award.reason,
--		PostAward,
--		award,
--		callback,
--		...)
--end
--
function ML:Test(items)
	Logging:Debug("Test(%d)", #items)

	for _, item in ipairs(items) do
		self:_AddLootTableEntry(nil, item)
	end

	if self.db.profile.autoStart then
		AddOn:Print("Auto start isn't supported when testing")
	end

	AddOn:CallModule("LootSession")
	AddOn:GetModule("LootSession"):Show(self.lootTable)
end

function ML:ConfigSupplement()
	return L["master_looter"], function(container) self:LayoutConfigSettings(container) end
end