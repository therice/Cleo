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
--- @type Models.Item.PlayerLootSource
local PlayerLootSource = AddOn.Package('Models.Item').PlayerLootSource
--- @type Models.Item.CreatureLootSource
local CreatureLootSource = AddOn.Package('Models.Item').CreatureLootSource
--- @type Models.Item.LootSlotInfo
local LootSlotInfo = AddOn.Package('Models.Item').LootSlotInfo
--- @type Models.Item.LootTableEntry
local LootTableEntry = AddOn.Package('Models.Item').LootTableEntry
--- @type Models.Item.LootQueueEntry
local LootQueueEntry = AddOn.Package('Models.Item').LootQueueEntry
--- @type LootLedger.Entry
local LootLedgerEntry = AddOn.Package('LootLedger').Entry
--- @type Models.Item.PartialItemAward
local PartialItemAward = AddOn.Package('Models.Item').PartialItemAward
--- @type table<string, string>
local LAR = AddOn.Package('Models.Item').LootAllocateResponse.Attributes
--- @type Models.Player
local Player = AddOn.Package('Models').Player
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type MasterLooterDb
local MasterLooterDb = AddOn.Require('MasterLooterDb')
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary('ItemUtil')
--- @type Models.Item.ContainerItem
local ContainerItem = AddOn.Package('Models.Item').ContainerItem
-- handles to globals
local SendChatMessage = _G.SendChatMessage

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
	ms_need       = {
		user_visible  = true,
		suicide       = true,
		suicide_amt   = nil,
		color         = C.Colors.Evergreen,
		display_order = 1,
	},
	minor_upgrade = {
		user_visible  = true,
		suicide       = true,
		suicide_amt   = 5,
		color         = C.Colors.PaladinPink,
		display_order = 2,
	},
	os_greed      = {
		user_visible  = true,
		suicide       = true,
		suicide_amt   = 2,
		color         = C.Colors.RogueYellow,
		display_order = 3,
	},
	disenchant = {
		user_visible = false,
		suicide      = false,
		color        = C.Colors.MageBlue,
	},
	bank = {
		user_visible = false,
		suicide      = false,
		color        = C.Colors.Purple,
	},
	free = {
		user_visible = false,
		suicide      = false,
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
	L["announce_&o_desc"],
	L["announce_&ln_desc"],
	L["announce_&lp_desc"],
}

ML.AnnounceItemStringsDesc = {
	L["announce_&i_desc"],
	L["announce_&l_desc"],
	L["announce_&s_desc"],
	L["announce_&t_desc"],
	L["announce_&o_desc"],
	L["announce_&ln_desc"],
}

ML.UsageType= {
	Always  = 1,
	Ask     = 2,
	Never   = 99,
}

-- available methods for selecting a list configuration to use when master looter
ML.ListConfigSelectionMethod = {
	Default = 1,
	Ask     = 2,
}

ML.defaults = {
	profile = {
		usage = {
			-- this applies when player is master looter
			state       = ML.UsageType.Ask,
			-- this applies when player is leader (should the 'state' setting be used then as well)
			--
			-- E.G. if whenLeader is true and state is 'Ask', the player will be prompted
			-- whether to use cleo when they are leader
			--
			-- E.G. if whenLeader is true and state is 'Always', then it would automatically use cleo
			-- when the player is the leader
			--
			-- if whenLeader is false, the state has no impact when player is the leader
			whenLeader  = false,
		},
		-- what method should be used for selecting the active configuration (lists are attached to a config)
		lcSelectionMethod = ML.ListConfigSelectionMethod.Ask,
		-- should it only be enabled in raids
		onlyUseInRaids = true,
		-- is 'out of raid' support enabled (specifies auto-responses when user not in instance, but in raid)
		outOfRaid = true,
		-- should a session automatically be started with all eligible items
		autoStart = false,
		-- should a random roll between 1 and 100 (inclusive) be added to all sessions
		autoAddRolls = false,
		-- automatically add all eligible equipable items to session
		autoAdd = true,
		-- automatically add all eligible non-equipable items to session (e.g. mounts)
		autoAddNonEquipable = false,
		-- automatically add all BoE (Bind on Equip) items to a session
		autoAddBoe = false,
		-- should 'award later' be checked by default on loot session interface
		awardLater = false,
		-- how long (in seconds) does a candidate have to respond to an item
		timeout = {
			enabled = true, duration = 60
		},
		-- are player's responses available (shown) in the loot dialogue
		showLootResponses = false,
		-- are player's given option to roll on armor which isn't of their preferred type (e.g. leather)
		showNonPreferredArmorTypes = false,
		-- are whispers supported for candidate responses
		acceptWhispers = true,
		-- are awards announced via specified channel
		announceAwards = true,
		-- where awards are announced, channel + message
		announceAwardText = { channel = "group", text = "&p was awarded &i for &r (Priority #&lp : &ln)"},
		-- are items under consideration announced via specified channel
		announceItems = true,
		-- the prefix/preamble to use for announcing items
		announceItemPrefix = "Items under consideration:",
		-- where items are announced, channel + message
		announceItemText = { channel = "group", text = "&s: &i (&ln)"},
		-- are player's responses to items announced via specified channel
		announceResponses = true,
		-- where player's responses to items are announced, channel + message
		announceResponseText = { channel = "group", text = "&p specified &r for &i (Priority #&lp : &ln)"},
		-- enables the auto-awarding of items that meet specific criteria
		autoAward = false,
		-- where auto awards are announced, channel + message
		autoAwardText = { channel = "group", text = "&p was auto awarded &i for &r"},
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
			  numButtons = 3,
			  ordering = {1, 3, 5},
			  {color = ..., text = L["ms_need"], whisperKey = L["whisperkey_ms_need"], suicide_amt = nil, key = 'ms_need'},
			  {color = ..., text = L["minor_upgrade"], whisperKey = L["whisperkey_minor_upgrade"], suicide_amt = 5, key = 'minor_upgrade''},
			  {color = ..., text = L["os_greed"], whisperKey = L["whisperkey_os_greed"], suicide_amt = 2, key = 'os_greed''},
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
			{ color = {0,1,0,1},        sort = 1,   text = L["ms_need"], key = 'ms_need'},              [1]
			{ color = {0,1,0,1},        sort = 2,   text = L["minor_upgrade"], key = 'minor_upgrade'},  [2]
			{ color = {1,0.5,0,1},	    sort = 3,	text = L["os_greed"], key = 'os_greed' },           [3]
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

	-- establish the number of user visible buttons and display order
	DefaultButtons.numButtons = Util.Tables.Count(UserVisibleResponses)
	DefaultButtons.ordering = { }

	local index = 1
	for response, value in pairs(UserVisibleResponses) do
		DefaultButtons.ordering[value.display_order] = index
		-- these are entries that represent buttons available to player at time of loot decision
		Util.Tables.Push(DefaultButtons, {color = value.color, text = L[response], whisperKey = L['whisperkey_' .. response], suicide_amt = value.suicide_amt, key = response})
		-- the are entries of the universe of possible responses, which are a super set of ones presented to the player
		Util.Tables.Push(DefaultResponses, {color = value.color, sort = value.display_order or index, text = L[response], key = response})
		index = index + 1
	end

	DefaultButtons.ordering = Util.Tables.Compact(DefaultButtons.ordering)

	for response, value in pairs(UserNonVisibleResponses) do
		ML.NonVisibleAwardReasons[response] = UIUtil.ColoredDecorator(value.color):decorate(L[response])
	end
end

function ML:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.db:RegisterNamespace(self:GetName(), ML.defaults)
	self.Send = Comm():GetSender(C.CommPrefixes.Main)
	AddOn:SyncModule():AddHandler(
			self:GetName(),
			format("%s %s", L["master_looter"], L['settings']),
			function() return self.db.profile end,
			function(data) self:ImportData(data) end
	)
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
	--- extra players to add to group for testing
	--- @type table<number, string>
	self.testGroupMembers = nil
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
			Logging:Trace("MasterLooterDbRequest from %s", tostring(sender))
			-- previously this was sending to group, but why? a specific person asked for it
			-- so changed the send to be targeted to that player only
			MasterLooterDb:Send(Player:Get(sender))
		end,
		[C.Commands.Reconnect] = function(_, sender)
			Logging:Trace("Reconnect from %s", tostring(sender))
			-- only handle for other players, not ourselves
			if not AddOn.UnitIsUnit(sender, AddOn.player) then
				self:OnReconnectReceived(sender)
			end
		end,
		[C.Commands.LootTable] = function(_, sender)
			Logging:Trace("LootTable from %s", tostring(sender))
			-- if the sender was ourself, which implies we are ML (otherwise this module wouldn't be active)
			if AddOn.UnitIsUnit(sender, AddOn.player) then
				-- this is only used in the loot allocation interface
				-- which is implicitly limited to ML, so only send to ourselves
				--
				-- schedule the callback to be shortly after any response timeout, which is a reasonable amount of time
				-- having passed for a response to be received and to transition response from announced after
				-- starting the loot session
				self:ScheduleTimer(
					function() self:Send(AddOn.player, C.Commands.CheckIfOffline) end,
					15 + (0.5 * #self.lootTable)
				)
			end
		end,
		[C.Commands.TradeComplete] = function(data, sender)
			Logging:Trace("TradeComplete from %s", tostring(sender))
			-- only if the sender was ourself, which implies we are ML
			if AddOn.UnitIsUnit(sender, AddOn.player) then
				self:OnTradeComplete(unpack(data))
			end
		end,
		[C.Commands.TradeWrongWinner] = function(data, sender)
			Logging:Trace("TradeWrongWinner from %s", tostring(sender))
			-- only if the sender was ourself, which implies we are ML
			if AddOn.UnitIsUnit(sender, AddOn.player) then
				self:OnTradeWrongWinner(unpack(data))
			end
		end,
		--[[
		[C.Commands.HandleLootStart] = function(_, sender)
			Logging:Trace("HandleLootStart from %s", tostring(sender))
			if AddOn:IsMasterLooter() then
				self:OnHandleLootStart()
			end
		end,
		--]]
	})
end

function ML:UnsubscribeFromEvents()
	Logging:Trace("UnsubscribeFromEvents(%s)", self:GetName())
	AddOn.Unsubscribe(self.eventSubscriptions)
	self.eventSubscriptions = nil
end

function ML:UnsubscribeFromComms()
	Logging:Trace("UnsubscribeFromComms(%s)", self:GetName())
	AddOn.Unsubscribe(self.commSubscriptions)
	self.commSubscriptions = nil
end

-- the are unregistered in OnDisable()
function ML:RegisterPlayerMessages()
	if self:IsHandled() then
		Logging:Trace("RegisterPlayerMessages()")
		self:RegisterMessage(C.Messages.PlayerJoinedGroup, function(...) self:OnPlayerEvent(...) end)
		self:RegisterMessage(C.Messages.PlayerLeftGroup, function(...) self:OnPlayerEvent(...) end)
	end
end

function ML:UnregisterPlayerMessages()
	if self:IsHandled() then
		Logging:Trace("UnregisterPlayerMessages()")
		self:UnregisterMessage(C.Messages.PlayerJoinedGroup)
		self:UnregisterMessage(C.Messages.PlayerLeftGroup)
	end
end

function ML:GetLootTable()
	return self.lootTable
end

function ML:ClearLootTable()
	self.lootTable = {}
end

function ML:OnPlayerEvent(event, player)
	if self:IsHandled() then
		Logging:Trace("OnPlayerEvent(%s) : %s", tostring(event), tostring(player))
		local ac = AddOn:ListsModule():GetActiveConfiguration()
		ac:OnPlayerEvent(player, Util.Strings.Equal(event, C.Messages.PlayerJoinedGroup))
		if Util.Strings.Equal(event, C.Messages.PlayerJoinedGroup) then
			-- send a request for player info upon joining, as the group can change after
			-- establishing the master looter
			Util.Functions.try(
				function()
					self:Send(player, C.Commands.PlayerInfoRequest)
				end
			)
			.catch(
				function(err)
					Logging:Error("OnPlayerEvent(PlayerInfoRequest, %s) : %s / %s", tostring(event), tostring(player), Util.Objects.ToString(err))
				end
			)

			self:SendActiveConfig(player, ac.config)

			-- send a version ping to player when they join group so we can proactively notify them that
			-- Cleo is not installed and will not be able to use it for loot responses
			Util.Functions.try(
				function()
					local vc = AddOn:VersionCheckModule()
					vc:SendVersionPing(player)
					self:ScheduleTimer(function() vc:NotifyIfNotInstalled(player) end, 5)
				end
			)
		    .catch(
				function(err)
					Logging:Error("OnPlayerEvent(VersionPing, %s) : %s / %s", tostring(event), tostring(player), Util.Objects.ToString(err))
				end
			)
		end
	end
end

function ML:GenerateConfigChangedEvents()
	return true
end

-- when the db is changed, need to check if we must broadcast the new MasterLooter Db
-- the msg will be in the format of 'ace serialized message' = 'count of event'
-- where the deserialized message will be a tuple of 'module of origin' (e.g MasterLooter), 'db key name' (e.g. outOfRaid)
function ML:ConfigTableChanged(msg)
	Logging:Debug("ConfigTableChanged(%s)", self:GetName())

	local updateDb = not AddOn:HaveMasterLooterDb()

	for serializedMsg, _ in pairs(msg) do
		local success, module, val = AddOn:Deserialize(serializedMsg)
		Logging:Trace("ConfigTableChanged(%s) : %s",  Util.Objects.ToString(module), Util.Objects.ToString(val))
		if success and Util.Strings.Equal(module, self:GetName()) then
			if not updateDb then
				for key in pairs(AddOn.mlDb) do
					Logging:Trace("ConfigTableChanged() : examining %s, %s, %s", tostring(module), tostring(key), tostring(val))
					if Util.Strings.StartsWith(val, key) or Util.Strings.Equal(val, key)then
						updateDb = true
						break
					end
				end
			end
		end
		if updateDb then
			Logging:Trace("ConfigTableChanged() : Updating ML Db")
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
	SendChatMessage(L["whisper_guide_1"], C.Channels.Whisper, nil, target)
	local msg, db = nil, self.db.profile
	for i = 1, db.buttons.numButtons do
		msg = "[" .. C.name .. "]: ".. db.buttons[i]["text"] .. ":  "
		msg = msg .. "" .. db.buttons[i]["whisperKey"]
		SendChatMessage(msg, C.Channels.Whisper, nil, target)
	end
	SendChatMessage(L["whisper_guide_2"], C.Channels.Whisper, nil, target)
end

function ML:SendWhisperItems(target)
	Logging:Trace("SendWhisperHelp(%s)", target)
	SendChatMessage(L["whisper_items"], C.Channels.Whisper, nil, target)
	if #self.lootTable == 0 then
		SendChatMessage(L["whisper_items_none"], C.Channels.Whisper, nil, target)
	else
		for session, item in pairs(self.lootTable) do
			SendChatMessage(format("[%d] : %s", session, tostring(item:GetItem().link)), C.Channels.Whisper, nil, target)
		end
	end
end

function ML:GetItemsFromMessage(msg, sender)
	Logging:Trace("GetItemsFromMessage(%s) : %s", sender, msg)

	local sessionArg, responseArg = AddOn:GetArgs(msg, 2)
	sessionArg = tonumber(sessionArg)

	if not sessionArg or not Util.Objects.IsNumber(sessionArg) or sessionArg > #self.lootTable then
		return
	end

	if not responseArg then
		return
	end

	Logging:Trace(
		"GetItemsFromMessage() : sender=%s, session=%s, response=%s",
		sender, tostring(sessionArg), tostring(responseArg)
	)

	-- default to response #1 if not specified
	local response = 1
	local whisperKeys = {}
	for k, v in pairs(self.db.profile.buttons) do
		if k ~= 'numButtons' and k ~= 'ordering' then
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
	--Logging:Debug("UpdateDb")
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
	--[[
	Logging:Trace("IsHandled() : %s, %s, %s, %s",
	              tostring(self:IsEnabled()), tostring(AddOn:IsMasterLooter()),
	              tostring(AddOn.enabled), tostring(AddOn.handleLoot)
	)
	--]]
	return self:IsEnabled() and AddOn:IsMasterLooter() and AddOn.enabled and (AddOn.handleLoot or AddOn:TestModeEnabled())
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

	local forTransmit = self:GetLootTableForTransmit()
	if self.running then
		self:Send(C.group, C.Commands.LootTableAdd, forTransmit)
	else
		self:Send(C.group, C.Commands.LootTable, forTransmit)
	end

	-- don't re-announce items that were previously sent only the new ones
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

	-- will only resign ML if test mode is enabled
	-- will also disable test mode after resigning
	AddOn.Testing:ResignMasterLooterAndDisable()
	-- below is the previous implementation, kept as reference for an interim amount of time
	--[[
	if AddOn:TestModeEnabled() then
		-- deactivate the configuration 1st
		self:DeactivateConfiguration()
		AddOn:StopHandleLoot()
		AddOn:ScheduleTimer(function() AddOn:NewMasterLooterCheck() end, 1)
		self.testGroupMembers = nil
		AddOn.Testing:Disable()
	end
	--]]
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
	["&l"] = function(_, item) return item and item:GetLevelText() or "" end,
	["&t"] = function(_, item) return item and item:GetTypeText() or "" end,
	["&o"] = function(_, _, owner) return owner or "" end,
	["&ln"] = function(_, item)
		if item then
			local LM = AddOn:ListsModule()
			if LM:HasActiveConfiguration() then
				local _, list = LM:GetActiveConfiguration():GetActiveListByEquipment(item:GetEquipmentLocation())
				if list then return list.name end
			end
		end

		return L['unknown']
	end,
}

--- @param items table<number, Models.Item.LootTableEntry> | table<number, string>
function ML:AnnounceItems(items)
	if not self:GetDbValue('announceItems') then
		return
	end

	local channel, template = self:GetDbValue('announceItemText.channel'), self:GetDbValue('announceItemText.text')
	AddOn:SendAnnouncement(self:GetDbValue('announceItemPrefix'), channel)

	-- iterate the items and announce each
	Util.Tables.Iter(
		items,
		function(e, i)
			local itemRef = ItemRef.Resolve(e)
			--Logging:Trace("AnnounceItems() : %d (index) [%s] %s => [%s] %s", i, tostring(e), Util.Objects.ToString(e), tostring(itemRef), Util.Objects.ToString(itemRef:toTable()))

			local msg = template
			for repl, fn in pairs(self.AnnounceItemStrings) do
				msg = gsub(msg, repl, escapePatternSymbols(tostring(
					fn(
						e.session or i,
						itemRef:GetItem(),
						e.owner or (e.GetOwner and e:GetOwner() or nil)
					)
				)))
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
	["&r"] = function(_, _, response) return response or "" end,
	["&n"] = function(_, _, _, roll) return roll or "" end,
	["&l"] = function(_, item) return item and item:GetLevelText() or "" end,
	["&t"] = function(_, item) return item and item:GetTypeText() or "" end,
	["&o"] = function(_, _, _, _, session)
		local entry = AddOn:MasterLooterModule():GetLootTableEntry(session)
		return entry and entry:GetOwner() or L['unknown']
	end,
	["&ln"] = function(_, item)
		if item then
			local LM = AddOn:ListsModule()
			if LM:HasActiveConfiguration() then
				local _, list = LM:GetActiveConfiguration():GetActiveListByEquipment(item:GetEquipmentLocation())
				if list then return list.name end
			end
		end

		return L['unknown']
	end,
	["&lp"] = function(name, item, ...)
		if item then
			local LM = AddOn:ListsModule()
			if LM:HasActiveConfiguration() then
				local _, priority = LM:GetActiveListAndPriority(item:GetEquipmentLocation(), name)
				if priority then return tostring(priority) end
			end
		end

		return "?"
	end,
}


--- @param winner string the winner's name
--- @param link string the item link
--- @param response string the reason for the award
--- @param roll string the roll value, if applicable
--- @param session number the loot session
--- @param changeAward boolean|string is the item is being re-awarded (changed)
--- @param isAuto boolean is the award an automatic one
function ML:AnnounceAward(winner, link, response, roll, session, changeAward, isAuto)
	if not self:GetDbValue('announceAwards') then
		return
	end

	isAuto = Util.Objects.Default(isAuto, false)
	Logging:Trace("AnnounceAward(%d) : winner=%s, item=%s", session, winner, tostring(link))

	local channel, announcement
	if isAuto then
		channel, announcement = self:GetDbValue('autoAwardText.channel'), self:GetDbValue('autoAwardText.text')
	else
		channel, announcement = self:GetDbValue('announceAwardText.channel'), self:GetDbValue('announceAwardText.text')
	end

	for repl, fn in pairs(self.AwardStrings) do
		announcement =
			gsub(announcement,
			     repl,
			     escapePatternSymbols(tostring(fn(winner, ItemRef(link):GetItem(), response, roll, session)))
			)
	end

	if changeAward then
		announcement = "(" .. L["change_award"] .. ") " .. announcement
	end

	AddOn:SendAnnouncement(announcement, channel)
end

--- @param configId string the configuration id to activate, which overrides selection method. if nil, this is ignored
function ML:OnHandleLootStart(configId)
	Logging:Debug("OnHandleLootStart(%s)", tostring(configId))

	if self:IsHandled() then
		-- always grab the list service, it wouldn't affect any active configuration
		local listService = AddOn:ListsModule():GetService()
		local SelectionEnum = self.ListConfigSelectionMethod
		local configSelectionMethod = self:GetDbValue('lcSelectionMethod')

		if Util.Strings.IsSet(configId) then
			local config = listService.Configuration:Get(configId)
			if config then
				self:ActivateConfiguration(config)
			else
				local errMsg = format("Specified configuration id '%s' is not available", configId)
				AddOn:PrintError(errMsg)
				error(errMsg)
			end
		elseif configSelectionMethod == SelectionEnum.Ask then
			-- this will callback into ActivateConfiguration()
			self:PromptForConfigSelection()
		elseif configSelectionMethod == SelectionEnum.Default then
			local configs = listService:Configurations(true, true)
			local count = configs and Util.Tables.Count(configs) or -1
			Logging:Trace("OnHandleLootStart() : %d viable configurations (should be 1)", count)
			local config = (count == 1) and Util.Tables.Values(configs)[1] or nil
			self:ActivateConfiguration(config)
		else
			Logging:Error("OnHandleLootStart() : Specified configuration selection method '%d' is not supported", configSelectionMethod)
			local errMsg = format("Specified configuration selection method '%d' is not supported", configSelectionMethod)
			AddOn:PrintError(errMsg)
			error(errMsg)
		end
	end
end

function ML:BuildActiveConfig(config)
	if self:IsHandled() and config then
		local activeConfig = {
			config = {},
			lists = {}
		}

		Util.Tables.Set(activeConfig, 'config', config:ToRef())
		local lists = AddOn:ListsModule():GetService():Lists(config.id)
		for _, list in pairs(lists) do
			local ref = list:ToRef()
			-- Logging:Trace("SendActiveConfig(%s) : %s", tostring(list.id), Util.Objects.ToString(ref))
			Util.Tables.Push(activeConfig.lists, ref)
		end

		return activeConfig
	end

	return nil
end

function ML:SendActiveConfig(target, config)
	if self:IsHandled() then
		Logging:Debug("SendActiveConfig(%s) : %s", tostring(target), tostring(config.id))
		-- dispatch the config activation message to target
		-- include information about the associated lists as well
		-- this is necessary to make sure what we are activating is aligned with the master looter's view
		local toSend = self:BuildActiveConfig(config)
		Logging:Trace("SendActiveConfig(%s) : %s", tostring(config.id), function() return  Util.Objects.ToString(toSend) end)
		AddOn:Send(target, C.Commands.ActivateConfig, toSend)
	end
end

--- this will reload current configuration/lists and activate
--- used when the underlying configuration or list(s) are mutated while active
---
--- @param applied boolean have the changes which resulted in reactivation been applied locally
function ML:ReactivateConfiguration(applied)
	applied = Util.Objects.Default(applied, false)
	Logging:Debug("ReactivateConfiguration(%s)", tostring(applied))

	if self:IsHandled() then
		if not AddOn:ListsModule():HasActiveConfiguration() then
			Logging:Warn("ReactivateConfiguration() : No active configuration, cannot reactivate")
			return
		end

		local ac = AddOn:ListsModule():GetActiveConfiguration()
		-- reload the current active configuration, as reactivation was likely a result of a mutation
		local config = AddOn:ListsModule():GetService().Configuration:Get(ac.config.id)
		if not config then
			Logging:Warn(
				"ReactivateConfiguration(%s) : Current active configuration not found, cannot reactivate",
				ac.config.id
			)
			return
		end

		Logging:Info("ReactivateConfiguration(%s) : activating", config.id)
		self:ActivateConfiguration(config, applied)
	end
end

--- if there is currently an active configuration, deactivates it and broadcasts to group
function ML:DeactivateConfiguration()
	local LM = AddOn:ListsModule()

	Logging:Debug("DeactivateConfiguration(%s, %s)", tostring(self:IsHandled()), tostring(LM:HasActiveConfiguration()))

	if self:IsHandled() then
		local activeConfig = LM:GetActiveConfiguration()
		Logging:Trace("DeactivateConfiguration(%s)", tostring(activeConfig))
		if activeConfig then
			LM:DeactivateConfiguration(activeConfig.config)
			AddOn:Send(C.group, C.Commands.DeactivateConfig, activeConfig.config.id)
		end
	end
end


--- @param config Models.List.Configuration
--- @param dispatchOnly boolean should activation only be dispatched (not activated ourselves)
function ML:ActivateConfiguration(config, dispatchOnly)
	-- by default, we both dispatch and activate
	dispatchOnly = Util.Objects.Default(dispatchOnly, false)

	Logging:Trace("ActivateConfiguration(%s, %s)", config and config.id or "NIL", tostring(dispatchOnly))

	if self:IsHandled() then
		if not config then
			Logging:Warn("ActivateConfiguration() : No configuration specified")
			AddOn:Print(L["invalid_configuration_ml"])
			AddOn:StopHandleLoot()
		else
			-- make sure we're an admin or owner, otherwise cannot mutate it
			if not config:IsAdminOrOwner(AddOn.player) then
				Logging:Warn("ActivateConfiguration(%s) : Not an admin or owner, cannot activate configuration", config.id)
				AddOn:Print(format(L["invalid_configuration_ml_owner_admin"], config.name))
				AddOn:StopHandleLoot()
				return
			end

			local LM, activationSuccess = AddOn:ListsModule(), nil
			-- only activate configuration if the call was limited to dispatching
			if not dispatchOnly then
				-- unregister player messages during activation, otherwise we could duplicate events.
				-- while they could be handled, they are unnecessary
				self:UnregisterPlayerMessages()
				activationSuccess, _ =
					LM:ActivateConfiguration(
						config,
						function(success, activated)
							Logging:Trace("ActivateConfiguration(%s) : Callback", tostring(config))
							if not success then
								Logging:Warn("ActivateConfiguration() : No active configuration, stopping the handling of loot")
								AddOn:Print(L["invalid_configuration_ml"])
								AddOn:StopHandleLoot()
							else
								Logging:Debug("ActivateConfiguration() : Configuration activated")
								AddOn:Print(format(L["activated_configuration"], tostring(activated.config.name)))
								-- this will generate player joined/left messages for current group
								-- register for those messages until after
								for name, _ in AddOn:GroupIterator() do
									activated:OnPlayerEvent(name, true)
								end
								-- we register for callbacks after activation here
								self:RegisterPlayerMessages()
							end
						end
					)
			else
				Logging:Trace("ActivateConfiguration(%s) : dispatch only, skipping activation", tostring(config))
			end

			-- this broadcasts to entire group, but message handling will not process in case of
			-- receiving player being the ML (which is the case here)
			if Util.Objects.Default(activationSuccess, true) then
				Logging:Trace("ActivateConfiguration(%s) : sending active configuration to 'group'", tostring(config))
				self:SendActiveConfig(C.group, config)
			end
		end
	end
end

function ML:OnHandleLootStop(...)
	Logging:Debug("OnHandleLootStop")
	-- cannot call IsHandled() here as the workflow may have already captured
	-- the new ML (even if current player was the previous ML)
	-- see NewMasterLooterCheck()
	if self:IsEnabled() then
		self:Disable()
	end
end

-- This is fired when looting begins, but before the loot window is shown.
-- Loot functions like GetNumLootItems will be available until LOOT_CLOSED is fired.
-- boolean
function ML:OnLootReady(...)
	--Logging:Debug("OnLootReady() : %s", Util.Objects.ToString({...}))
	if self:IsHandled() then
		wipe(self.lootSlots)

		if not IsInInstance() then
			return
		end

		if GetNumLootItems() <= 0 then
			return
		end

		self.lootOpen = true
		self:ProcessLootSlots(
			function(...)
				local args = {...}
				return self:ScheduleTimer(function() self:OnLootReady(unpack(args)) end, 0)
			end,
			...
		)
	end
end

-- Fires when a corpse is looted, after LOOT_READY.
-- Documentation says it should be autoLoot (boolean), isFromItem (boolean)
-- However, from testing it's only one argument which is autoLoot (verified to be one argument - boolean on 12.15.24)
function ML:OnLootOpened(...)
	-- Logging:Debug("OnLootOpened() : %s", Util.Objects.ToString({...}))
	if self:IsHandled() then
		self.lootOpen = true

		local rescheduled =
			self:ProcessLootSlots(
				function(...)
					-- failure processing loot slots, go no further
					local autoLoot, attempt = ...
					if not attempt then
						attempt = 1
					else
						attempt = attempt + 1
					end

					return self:ScheduleTimer(function() self:OnLootOpened(autoLoot, attempt) end, attempt / 10)
				end,
				...
			)

		-- we made it through the loot slots (not rescheduled) so we can continue
		-- to processing the loot table
		if Util.Objects.IsNil(rescheduled) then
			wipe(self.lootQueue)
			if not InCombatLockdown() then
				self:BuildLootTable()
			else
				AddOn:Print(L['cannot_start_loot_session_in_combat'])
			end
		end
	end
end

-- Fired when a player ceases looting a corpse.
-- Note that this will fire before the last CHAT_MSG_LOOT event for that loot.
function ML:OnLootClosed(...)
	if self:IsHandled() then
		self.lootOpen = false
	end
end

-- Fired when loot is removed from a corpse.
function ML:OnLootSlotCleared(slot)
	Logging:Debug("OnLootSlotCleared(%d)", slot)
	if self:IsHandled() then
		local lootSlotInfo = self:GetLootSlot(slot)
		Logging:Debug("OnLootSlotCleared(slot=%d) : %s", slot, function() return Util.Objects.ToString(lootSlotInfo) end)

		if lootSlotInfo and not lootSlotInfo.looted then
			lootSlotInfo.looted = true

			if not self.lootQueue or Util.Tables.Count(self.lootQueue) == 0 then
				Logging:Warn("OnLootSlotCleared() : loot queue is nil or empty")
				return
			end

			for i = #self.lootQueue, 1, -1 do
				local entry = self.lootQueue[i]
				-- Logging:Debug("OnLootSlotCleared(%d) : %s", slot, Util.Objects.ToString(entry:toTable()))

				-- You don't need to verify the source here because loot queue is only appended to
				-- when awarding an item. This means it was implicitly generated from the act of looting the
				-- appropriate source.
				--
				-- also, this event won't be triggered if the loot source isn't one that has slots
				-- in other words, not going to trigger for awarding loot from a player's bags
				if entry ~= nil and (entry.slot == slot) then
					if entry.timer then
						self:CancelTimer(entry.timer)
					end
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
	-- send the requesting player the ML Db
	local player = Player:Get(sender)
	MasterLooterDb:Send(player)

	--- if we have an active configuration send to user
	local ac = AddOn:ListsModule():GetActiveConfiguration()
	if ac then
		self:SendActiveConfig(player, ac.config)
	end
	
	-- if currently running, send the loot table
	if self.running then
		self:ScheduleTimer("Send", 4, player, C.Commands.LootTable, self:GetLootTableForTransmit(true))
	end
end

function ML:OnTradeComplete(item, recipient, trader, awardData)
	Logging:Trace("OnTradeComplete()")
	if self:IsHandled() then
		AddOn:Print(format(L['item_trade_complete'], AddOn.Ambiguate(trader), item, AddOn.Ambiguate(recipient)))
		--- @type Models.Item.PartialItemAward
		local award = PartialItemAward:reconstitute(awardData)
		AddOn:ListsModule():OnAwardItem(award)
	end
end

function ML:OnTradeWrongWinner(item, recipient, trader, awardData)
	if self:IsHandled() then
		--- @type Models.Item.PartialItemAward
		local award = PartialItemAward:reconstitute(awardData)
		AddOn:Print(format(L["item_trade_wrong_winner"], AddOn.Ambiguate(trader), item, AddOn.Ambiguate(recipient), AddOn.Ambiguate(award.winner)))
	end
end

--- @param slot number the loot slot
--- @return Models.Item.LootSlotInfo
function ML:GetLootSlot(slot)
	return self.lootSlots and self.lootSlots[slot] or nil
end

--- @param onFailure function a function to be invoked should a loot slot be unhandled
--- @return table the value returned from 'onFailure' or nil if all loot slots are handled
function ML:ProcessLootSlots(onFailure, ...)
	local numItems = GetNumLootItems()
	Logging:Debug("ProcessLootSlots(count=%d)", numItems)
	if numItems > 0 then
		-- iterate through the available items, tracking each individual loot slot
		for slot = 1, numItems do
			-- see if we have already added it, because of callbacks
			local lootSlotInfo = self:GetLootSlot(slot)
			local missing = (lootSlotInfo == nil and LootSlotHasItem(slot))
			local itemChanged = (lootSlotInfo ~= nil and not AddOn.ItemIsItem(lootSlotInfo:GetItemLink(), GetLootSlotLink(slot)))

			if missing or itemChanged then
				Logging:Debug(
				"ProcessLootSlots(slot=%d, missing=%s, itemChanged=%s): attempting to (re)add info for %s",
					slot, tostring(missing), tostring(itemChanged), (missing and "<missing>" or tostring(lootSlotInfo.item))
				)

				if not self:AddLootSlot(slot, ...) then
					Logging:Warn("ProcessLootSlots(slot=%d) : uncached item in loot table, invoking 'onFailure' (function) ...", slot)
					return onFailure(...)
				end
			end
		end
	end
end

--- @param slot number the loot slot index
--- @return boolean indicating if loot slot was handled (not necessarily added to loot slots, i.e. currency or blacklisted)
function ML:AddLootSlot(slot, ...)
	Logging:Debug("AddLootSlot(slot=%d)", slot)
	-- https://wow.gamepedia.com/API_GetLootSlotInfo
	local texture, name, quantity, currencyId, quality = GetLootSlotInfo(slot)
	if texture then
		-- return's the link for item at specified slot
		-- https://wow.gamepedia.com/API_GetLootSlotLink
		local link = GetLootSlotLink(slot)
		--[[
		Logging:Trace(
			"AddLootSlot(slot=%d) : link=%s, texture=%s, name=%s, quantity=%s, currencyId=%s, quality=%s",
			slot, tostring(link), tostring(texture), tostring(name), tostring(quantity), tostring(currencyId), tostring(quality)
		)
		--]]
		if currencyId then
			Logging:Trace("AddLootSlot(slot=%d) : ignoring %s as it's currency", slot, tostring(link))
		elseif not AddOn:IsItemBlacklisted(link) then
			local lootSlotInfo = LootSlotInfo(slot, name, link, quantity, quality)
			self.lootSlots[slot] = lootSlotInfo
			Logging:Trace("AddLootSlot(slot=%d) : added %s to loot table",
			              slot, function() return Util.Objects.ToString(lootSlotInfo) end
			)
		end

		return true
	end

	return false
end

function ML:UpdateLootSlots()
	-- this implicitly requires loot window to be open
	if not self.lootOpen then
		Logging:Warn("UpdateLootSlots() : attempting to update loot slots without an open loot window")
		return
	end

	local numLootItems, processedLootSessions = GetNumLootItems(), {}
	Logging:Trace("UpdateLootSlots() : numLootItems=%d",numLootItems)

	for slot = 1, numLootItems do
		local item = GetLootSlotLink(slot)
		for session = 1, #self.lootTable do
			--- @type Models.Item.LootTableEntry
			local ltEntry = self:GetLootTableEntry(session)
			if not ltEntry.awarded and not processedLootSessions[session] then
				-- this will create a loot source for the entry's slot based upon the currently targeted source's loot
				-- it may not necessarily be the same source, which we need to verify before updating anything
				local source = CreatureLootSource.FromCurrent(slot)
				if AddOn.ItemIsItem(item, ltEntry.item) and ltEntry:IsFromSource(source) then
					local changed, previousSlot = ltEntry:SetSlot(slot)
					if changed then
						Logging:Debug("UpdateLootSlots(session=%d) : item %s previously at slot=%d, now at slot=%d", session, ltEntry.item, previousSlot, slot)
					end
					processedLootSessions[session] = true
					break
				end
			end
		end
	end

end

--- @param session number the session id
--- @return Models.Item.LootTableEntry
function ML:GetLootTableEntry(session)
	return self.lootTable and self.lootTable[session] or nil
end

--- @param session number the session id
function ML:RemoveLootTableEntry(session)
	--Logging:Debug("RemoveLootTableEntry(%d)", session)
	Util.Tables.Remove(self.lootTable, session)
end

function ML:BuildLootTable()
	local numItems = GetNumLootItems()
	Logging:Debug("BuildLootTable(%d, %s)", numItems, tostring(self.running))

	if numItems > 0 then
		local LS = AddOn:LootSessionModule()
		if self.running or LS:IsRunning() then
			self:UpdateLootSlots()
		else
			for slot = 1, numItems do
				local lootSlotInfo = self:GetLootSlot(slot)
				if lootSlotInfo then
					self:ScheduleTimer("HookLootButton", 0.5, slot)

					local link, quantity, quality = lootSlotInfo:GetItemLink(), lootSlotInfo.quantity, lootSlotInfo.quality
					local autoAward, mode, winner = self:ShouldAutoAward(link, quality)

					if autoAward and quantity > 0 then
						self:AutoAward(link, slot, quality, winner, mode)
					elseif link and quantity > 0 and self:ShouldAddItem(link, quality) then
						-- item that should be added
						self:AddLootTableItem(link, lootSlotInfo.source)
					elseif quantity == 0 then
						-- currency
						LootSlot(slot)
					end
				end
			end

			Logging:Debug("BuildLootTable(%d, %s)", #self.lootTable, tostring(self.running))

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

--- @param item any  ItemID|ItemString|ItemLink
--- @param source Models.Item.LootSource source from which loot was obtained
function ML:AddLootTableItem(item, source)
	Logging:Trace(
		"AddLootTableItem(item=%s, source=%s)",
		tostring(item), function() return Util.Objects.ToString(source  or {}) end
	)

	local entry = LootTableEntry(item, source)
	Util.Tables.Push(self.lootTable, entry)
	Logging:Debug(
		"AddLootTableItem() : %s (source %s) added to loot table at index %d",
		tostring(item), function() return Util.Objects.ToString(source or {}) end, tostring(#self.lootTable)
	)

	-- make a call to get item information, it may not be available immediately
	-- but this will submit a query
	local itemRef = entry:GetItem()
	if not itemRef or not itemRef:IsValid() then
		-- no need to schedule another invocation of this
		-- the call to GetItem() submitted a query, it should be available by time it's needed
		Logging:Trace("AddLootTableItem() : item info unavailable for %s, but query has been initiated", tostring(item))
	else
		AddOn:SendMessage(C.Messages.MasterLooterAddItem, item, entry)
	end
end

--- Adds item from a container to the loot table and then starts a loot session
---
--- @param containerItem Models.Item.ContainerItem the item to add to the loot session
--- @param disableAwardLater boolean should option for awarding later be disabled on loot session
function ML:AddLootTableItemFromContainer(containerItem, disableAwardLater)
	Logging:Trace("AddLootTableItemFromContainer(%s)", function() return Util.Objects.ToString(containerItem) end)
	self:AddLootTableItem(containerItem.item, PlayerLootSource.FromCurrentPlayer(containerItem.guid))
	-- show the loot session with added item
	local LS = AddOn:LootSessionModule()
	AddOn:CallModule(LS:GetName())
	LS:Show(self.lootTable, disableAwardLater)
end

--- Adds item from a container, identified by a GUID, to the loot table and then starts a loot session
---
--- @param itemGUID string the item GUID (unique id for it in a container)
--- @param disableAwardLater boolean should option for awarding later be disabled on loot session
function ML:AddLootTableItemByGUID(itemGUID, disableAwardLater)
	if itemGUID then
		local bag, slot = AddOn:GetBagAndSlotByGUID(itemGUID)
		if bag and slot then
			local itemLink = C_Item.GetItemLink(ItemLocation:CreateFromBagAndSlot(bag, slot))
			if itemLink then
				self:AddLootTableItemFromContainer(ContainerItem(itemLink, bag, slot, itemGUID), disableAwardLater)
			end
		end
	end
end

---
--- For example
---     {1 = { ref = '18832' },  2 = { ref = '18834::0:0:0:0:0::::0' }, ... }
---
--- @see Models.Item.LootTableEntry#ForTransmit
--- @return table<number, table<string, string>>
function ML:GetLootTableForTransmit(overrideSent)
	overrideSent = Util.Objects.Default(overrideSent, false)
	Logging:Trace("GetLootTableForTransmit(%s)", tostring(overrideSent))
	local lt =
		Util(self.lootTable):Copy()
			:Map(
				function(e)
					if not overrideSent and e.sent then
						return nil
					else
						return e:ForTransmit()
					end
				end
			)()
	Logging:Trace("GetLootTableForTransmit() : %s", Util.Objects.ToString(lt))
	return lt
end

function ML:HookLootButton(slot)
	local lootButton = getglobal("LootButton".. slot)
	-- ElvUI
	if getglobal("ElvLootSlot".. slot) then
		lootButton = getglobal("ElvLootSlot".. slot)
	end

	local hooked = self:IsHooked(lootButton, "OnClick")
	if lootButton and not hooked then
		Logging:Debug("HookLootButton(%d)", slot)
		self:HookScript(lootButton, "OnClick", "LootOnClick")
	end
end

function ML:LootOnClick(button)
	if not IsAltKeyDown() or IsShiftKeyDown() or IsControlKeyDown() then
		Logging:Debug("LootOnClick() : Appropriate key not 'down', returning")
		return
	end

	Logging:Trace("LootOnClick() : Loot Table(size=%d)", #self.lootTable)

	local slot

	if getglobal("ElvLootFrame") then
		slot = tonumber(button:GetID())
	else
		slot = tonumber(button.slot)
	end

	local source = CreatureLootSource.FromCurrent(slot)
	-- verify the item in the slot isn't already on the loot table
	for _, v in ipairs(self.lootTable) do
		Logging:Trace("LootOnClick() : examining button(slot=%s) / lootTable(slot=%s)", tostring(slot), tostring(v.slot))
		-- if the same slot from the same source, don't add it
		if v:GetSlot():ifPresent(function(s) return slot == s end) and v:IsFromSource(source) then
			Logging:Trace("LootOnClick() : button(slot=%s) already present on loot table", tostring(button.slot))
			AddOn:Print(format(L["item_already_on_loot_table"], tostring(button.slot)))
			return
		end
	end

	local LS = AddOn:LootSessionModule()
	local slotLink = GetLootSlotLink(slot)
	Logging:Trace(
		"LootOnClick() : adding to lootTable for button(slot=%s), link=%s, source=%s",
		tostring(slot), slotLink, function() return Util.Objects.ToString(source) end
	)
	self:AddLootTableItem(slotLink, source)
	AddOn:CallModule(LS:GetName())
	LS:Show(self.lootTable)
end

---@param item string the item link
---@param quality number the item quality
---@return boolean should item be added to the loot table
function ML:ShouldAddItem(item, quality)
	local addItem = false

	-- item is available (AND)
	-- auto-adding of items is enabled (AND)
	-- item is equipable OR auto-adding non-equipable items is enabled (AND)
	-- quality is set AND >= our threshold (AND)
	-- item is not BOE or auto-adding of BOE is enabled
	if item then
		if self.db.profile.autoAdd and
			(IsEquippableItem(item) or self.db.profile.autoAddNonEquipable) and
			(quality and quality >= GetLootThreshold()) then
			addItem = self.db.profile.autoAddBoe or not AddOn.IsItemBoe(item)
		end
	end

	Logging:Trace("ShouldAddItem(%s, %s) : %s", tostring(item), tostring(quality), tostring(addItem))
	return addItem
end

ML.AwardStatus = {
	Failure = {
		AwardLaterCannotRepeat  = "AwardLaterCannotRepeat",
		AwardedCannotAwardLater = "AwardedCannotAwardLater",
		LootAmbiguity           = "LootAmbiguity",
		LootGone                = "LootGone",
		LootNotOpen             = "LootNotOpen",
		LootSourceMismatch      = "LootSourceMismatch",
		LootSourceMissing       = "LootSourceMissing",
		MLInventoryFull         = "MLInventoryFull",
		MLNotInInstance         = "MLNotInInstance",
		NotBop                  = "NotBop",
		NotInGroup              = "NotInGroup",
		NotMLCandidate          = "NotMLCandidate",
		Offline                 = "Offline",
		OutOfInstance           = "OutOfInstance",
		QualityBelowThreshold   = "QualityBelowThreshold",
		Timeout                 = "Timeout",
	},
	Success = {
		Indirect      = "Indirect",
		ManuallyAdded = "ManuallyAdded",
		Normal        = "Normal",
	},
	Neutral = {
		AwardLaterAlreadyInBags = "AwardLaterAlreadyInBags",
		AwardLaterFromBags      = "AwardLaterAlreadyInBags",
		TestMode                = "TestMode",
	}
}

--- @param item string ItemID|ItemString|ItemLink
--- @param slot number index of the item within the loot table
--- @param winner string name of the player which won the item
--- @return boolean, string 'can the loot be given', 'if not, why not?'
function ML:CanGiveLoot(item, slot, winner)
	local AS, lootSlotInfo = self.AwardStatus, self:GetLootSlot(slot)
	local source

	-- attempt to determine the loot source, which should be from the current creature being looted
	-- if that's not the case, then it will be ignored for purposes of determining result
	Util.Functions.try(
		function()
			source = CreatureLootSource.FromCurrent(slot)
		end
	).catch(
		function(err)
			Logging:Warn("CanGiveLoot(slot=%s, item=%s) : could not determine loot source '%s'", slot, tostring(item), tostring(err))
		end
	)

	Logging:Debug(
		"CanGiveLoot(slot=%d, item=%s, source=%s, winner=%s) : lootsSlot=%s",
		slot, tostring(item), Util.Objects.ToString(source), tostring(winner),
		function() return Util.Objects.ToString(lootSlotInfo) end
	)

	if not self.lootOpen then
		return false, AS.Failure.LootNotOpen
	elseif Util.Objects.IsNil(lootSlotInfo) then
		return false, AS.Failure.LootGone
	-- only check source if one was provided
	elseif not Util.Objects.IsNil(source) and not lootSlotInfo:IsFromSource(source) then
		return false, AS.Failure.LootSourceMismatch
	elseif not AddOn.ItemIsItem(lootSlotInfo.item, item) then
		return false, AS.Failure.LootGone
	elseif AddOn.UnitIsUnit(winner, C.player) and not self:HaveFreeSpaceForItem(item) then
		return false, AS.Failure.MLInventoryFull
	elseif not AddOn.UnitIsUnit(winner, C.player) then
		-- item quality below loot threshold
		if lootSlotInfo.quality < GetLootThreshold() then
			return false, AS.Failure.QualityBelowThreshold
		end

		local shortName = Ambiguate(winner, "short"):lower()
		-- winner is not in the group
		if not UnitInParty(shortName) and not UnitInRaid(shortName) then
			return false, AS.Failure.NotInGroup
		end

		-- winner is offline
		if not UnitIsConnected(shortName) then
			return false, AS.Failure.Offline
		end

		-- ML leaves the instance during a session
		if not IsInInstance() then
			return false, AS.Failure.MLNotInInstance
		end

		-- winner not in the same instance as ML
		if select(4, UnitPosition(Ambiguate(winner, "short"))) ~= select(4, UnitPosition("player")) then
			return false, AS.Failure.OutOfInstance
		end

		local found = false
		for i = 1, _G.MAX_RAID_MEMBERS do
			if AddOn.UnitIsUnit(GetMasterLootCandidate(slot, i), winner) then
				found = true
				break
			end
		end

		if not found then
			local bindType = select(14, GetItemInfo(item))
			if bindType ~= LE_ITEM_BIND_ON_ACQUIRE then
				return false, AS.Failure.NotBop
			else
				return false, AS.Failure.NotMLCandidate
			end
		end
	end

	return true, nil
end


-- Do we have free space in our bags to hold this item?
function ML:HaveFreeSpaceForItem(item)
	local itemFamily = GetItemFamily(item)
	local equipSlot = select(4, GetItemInfoInstant(item))
	if equipSlot == "INVTYPE_BAG" then
		itemFamily = 0
	end

	for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local freeSlots, bagFamily = AddOn.C_Container.GetContainerNumFreeSlots(bag)
		if freeSlots and freeSlots > 0 and (bagFamily == 0 or bit.band(itemFamily, bagFamily) > 0) then
			return true
		end
	end

	return false
end

---@param award Models.Item.ItemAward
function ML:RegisterAndAnnounceAward(award)
	local session, winner, response =
		award.session, award.winner, award:NormalizedReason().text
	Logging:Debug("RegisterAndAnnounceAwarded(%d, %s) : %s", session, winner, tostring(award))

	local ltEntry = self:GetLootTableEntry(session)
	local changeAward = ltEntry.awarded
	ltEntry.awarded = winner -- true

	-- if this item is in a player's bags (loot ledger), then change it's status indicate it needs traded
	local ledgerEntry = ltEntry:GetLootLedgerEntry()
	if ledgerEntry:isPresent() then
		-- this will modify the state on the entry to 'to trade', assign the various award attributes,
		-- and then update it in the ledger's storage
		AddOn:LootLedgerModule():GetStorage():UpdateAll(
			ledgerEntry:map(function(e) return e:WithAward(award) end)
				:orElseThrow("unable to assign award to loot ledger entry")
		)
	end

	-- owner in this message could be a creature name, player name, or testing (fake name).
	-- practically, only will be used when it is a player. could send the player GUID (id), but would require
	-- translation on the receiver's end. if there is an associated ledger entry, include the id for easy lookup
	self:Send(C.group, C.Commands.Awarded, session, winner, ltEntry:GetOwner(), ledgerEntry:map(function(e) return e.id end):orElse(nil))

	-- perform award announcement first (as the priority will be changed after actual award)
	Util.Functions.try(
		function()
			-- winner, link, response, roll, session, changeAward, isAuto
			self:AnnounceAward(
				winner,
				ltEntry.item,
				response,
				AddOn:LootAllocateModule():GetCandidateData(session, winner, LAR.Roll),
				session,
				changeAward
			)
		end
	).finally(
		function()
			-- only apply to list if the award is occurring now, if it's for 'later' then handle on trade
			-- for items that are traded later they are handled via
			--      'Awarded' message if ML is winner
			--      'TradeComplete' message if another player is the winner
			if ledgerEntry:isEmpty() then
				AddOn:ListsModule():OnAwardItem(award)
			end
		end
	)

	-- not more items to award, end the session
	if not self:HaveUnawardedItems() then
		AddOn:Print(L["all_items_have_been_awarded"])
		self:ScheduleTimer(function() self:EndSession() end, 1)
	end
end

--- @param session number the loot session
function ML:RegisterAndAnnounceLootedToBags(session)
	local lootEntry = self:GetLootTableEntry(session)
	assert(lootEntry, format("no loot table entry available for session %d", session))
	local ledgerEntry = LootLedgerEntry(
		lootEntry.item,
		LootLedgerEntry.State.AwardLater,
		lootEntry:GetItemGUID():orElse(nil)
	):WithEncounter(AddOn.encounter)

	AddOn:LootLedgerModule():GetStorage():Add(ledgerEntry)

	-- item is from a loot slot, going to be (or has been) looted to ML
	if lootEntry:GetSlot():isPresent() or self.running then
		-- implicitly ML or this code path wouldn't run
		self:AnnounceAward(AddOn.player:GetShortName(), lootEntry.item, L['item_looted_for_award_later'], nil, session)
		-- this is called after the item has been looted to the ML's bags, so identify the corresponding ledger entry
		-- and then update the loot entry's source
		--
		-- it would be nice if this wasn't necessary and it could be done automatically via LootLedger's Watcher
		-- however, the message for item being received will occur after the actual loot enters the bags
		-- and that event happens before the LootLedger entry is created here (at beginning of function)
		--
		-- therefore, do a manual invocation to update the entry's GUID with looted item
		--- @type table<LootLedger.Entry>
		local ledgerEntries = AddOn:LootLedgerModule():OnItemReceived({
			id     = ItemUtil:ItemLinkToId(lootEntry.item),
			link   = lootEntry.item,
			count  = 1,
			player = AddOn.player:GetName(),
			when   = GetServerTime()
		})

		-- only one entry should be updated and returned based upon semantics of OnItemReceived
		-- and count of 1 in the item parameter
		if #ledgerEntries == 1 then
			local updatedLedgerEntry = ledgerEntries[1]
			if Util.Strings.Equal(ledgerEntry.id, updatedLedgerEntry.id) then
				lootEntry.source = PlayerLootSource.FromCurrentPlayer(updatedLedgerEntry.guid)
			else
				Logging:Warn(
					"RegisterAndAnnounceLootedToBags() : unable to update loot ledger entry with looted item, updated entry was incorrect (expected %s, received %s)",
					ledgerEntry.id, Util.Objects.ToString(updatedLedgerEntry)
				)
				error("unable to update loot ledger entry with looted item, updated entry was incorrect")
			end
		else
			Logging:Warn("RegisterAndAnnounceLootedToBags() : unable to update loot ledger entry with looted item, updated %s entries", #ledgerEntries)
			error(format("unable to update loot ledger entry with looted item, updated entries count is %d", #ledgerEntries))
		end
	-- item is from a player and won't need to be updated later, as GUID was provided as part of LootLedgerEntry creation
	else
		AddOn:Print(format(L['item_added_to_award_later'], lootEntry.item))
	end

	if self.running then
		self:Send(C.group, C.Commands.LootedToBags, session, AddOn.player:GetName())
	end
end

function ML:PrintLootError(cause, item, winner)
	winner = winner or L['unknown']

	local AS = self.AwardStatus

	if Util.Objects.Equals(cause, AS.Failure.LootNotOpen) then
		AddOn:Print(L["unable_to_give_loot_without_loot_window_open"])
	elseif Util.Objects.Equals(cause, AS.Failure.Timeout) then
		AddOn:Print(
			format(L["timeout_giving_item_to_player"], item, UIUtil.PlayerClassColorDecorator(winner):decorate(AddOn.Ambiguate(winner))),
			" : ",
			_G.ERR_INV_FULL
		)
	else
		local prefix =
			format(
				L["unable_to_give_item_to_player"],
				item,
				UIUtil.PlayerClassColorDecorator(winner):decorate(AddOn.Ambiguate(winner)) .. " : "
			)

		if Util.Objects.Equals(cause, AS.Failure.LootAmbiguity) then
			AddOn:Print(prefix, L['item_ambiguous_source'])
		elseif Util.Objects.Equals(cause, AS.Failure.AwardLaterCannotRepeat) then
			AddOn:Print(prefix, L['award_later_cannot_repeat'])
		elseif Util.Objects.Equals(cause, AS.Failure.AwardedCannotAwardLater) then
			AddOn:Print(prefix, L['awarded_cannot_award_later'])
		elseif Util.Objects.Equals(cause, AS.Failure.LootGone) then
			AddOn:Print(prefix, _G.LOOT_GONE)
		elseif Util.Objects.Equals(cause, AS.Failure.LootSourceMissing) then
			AddOn:Print(prefix, L["item_no_source"])
		elseif Util.Objects.Equals(cause, AS.Failure.LootSourceMismatch) then
			AddOn:Print(prefix, L["item_from_different_source"])
		elseif Util.Objects.Equals(cause, AS.Failure.MLInventoryFull) then
			AddOn:Print(prefix, _G.ERR_INV_FULL)
		elseif Util.Objects.Equals(cause, AS.Failure.QualityBelowThreshold) then
			AddOn:Print(prefix, L["item_quality_below_threshold"])
		elseif Util.Objects.Equals(cause, AS.Failure.NotInGroup) then
			AddOn:Print(prefix, L["player_not_in_group"])
		elseif Util.Objects.Equals(cause, AS.Failure.Offline) then
			AddOn:Print(prefix, L["player_offline"])
		elseif Util.Objects.Equals(cause, AS.Failure.MLNotInInstance) then
			AddOn:Print(prefix, L["you_are_not_in_instance"])
		elseif Util.Objects.Equals(cause, AS.Failure.OutOfInstance) then
			AddOn:Print(prefix, L["player_not_in_instance"])
		elseif Util.Objects.Equals(cause, AS.Failure.NotMLCandidate) then
			AddOn:Print(prefix, L["player_ineligible_for_item"])
		elseif Util.Objects.Equals(cause, AS.Failure.NotBop) then
			AddOn:Print(prefix, L["item_only_able_to_be_looted_by_you_bop"])
		else
			AddOn:Print(prefix)
		end
	end
end

function ML:AwardResult(success, session, winner, status, callback, ...)
	local ltEntry = self:GetLootTableEntry(session)
	-- these messages aren't currently being consumed by the addon itself
	-- regardless of success or failure
	AddOn:SendMessage(
		success and C.Messages.AwardSuccess or C.Messages.AwardFailed,
		session, winner, status, ltEntry and ltEntry.item or nil
	)

	if callback then
		callback(success, session, winner, status, ...)
	end
end

--- @param lqEntry Models.Item.LootQueueEntry
function ML:OnGiveLootTimeout(lqEntry)
	-- remove entry from queue
	for k, v in pairs(self.lootQueue) do
		if Util.Objects.Equals(v, lqEntry) then
			tremove(self.lootQueue, k)
		end
	end

	lqEntry:Cleared(false, self.AwardStatus.Failure.Timeout)
end

function ML:GiveLoot(slot, winner, callback, ...)
	Logging:Debug("GiveLoot(slot=%d) : winner=%s", slot, tostring(winner))
	if self.lootOpen then
		local lqEntry = LootQueueEntry(slot, callback, {...})
		if not AddOn._IsTestContext() then
			lqEntry.timer = self:ScheduleTimer(function() self:OnGiveLootTimeout(lqEntry) end, 5)
		end

		Util.Tables.Push(self.lootQueue, lqEntry)

		for i = 1, _G.MAX_RAID_MEMBERS do
			local candidate = GetMasterLootCandidate(slot, i)
			if AddOn.UnitIsUnit(candidate, winner) then
				Logging:Debug("GiveLoot(slot=%d, playerIndex=%d) : candidate=%s, winner=%s", slot, i, candidate, winner)
				GiveMasterLoot(slot, i)
				break
			end
		end
	end
end


---@param award Models.Item.ItemAward | Models.Item.DeferredItemAward
---@param callback function This function will be called as callback(awarded, session, winner, status, ...)
---@return boolean true if award is success. false if award is failed. nil if we don't know the result yet.
function ML:Award(award, callback, ...)
	assert(Util.Objects.IsSet(award), "no award specified")
	-- the winner can be nil (false) if it's being awarded later (loot to ML inventory)
	local session, winner = award.session, award.winner
	assert(Util.Objects.IsNumber(session), "no session specified for item award")
	Logging:Debug("Award(session=%d) : winner=%s", session, tostring(winner))

	if not self.lootTable or #self.lootTable == 0 then
		if self.oldLootTable and #self.oldLootTable > 0 then
			self.lootTable = self.oldLootTable
		else
			Logging:Error("Award() : neither loot table (current or old) is populated")
			return false
		end
	end

	local AS, args = self.AwardStatus, {...}
	local ltEntry = self:GetLootTableEntry(session)
	assert(Util.Objects.IsSet(ltEntry), format("no loot table entry for session %d", session))
	local link, source = award.link, ltEntry.source
	assert(not Util.Strings.IsEmpty(link), format("no item available for loot table entry for session %d", session))
	assert(Util.Objects.IsSet(source), format("no source available for loot table entry for session %d", session))

	Logging:Debug("Award(session=%d) : award=%s, lte=%s", session, Util.Objects.ToString(award), Util.Objects.ToString(ltEntry))

	-- these are optional attributes, which will be either set of empty based upon the source of the loot
	--      a creature loot source WILL have a slot, but NO "bagged" item reference
	--      a player loot source WILL NOT have a slot, but MAY have a "bagged" item reference
	--      a test loot source WILL NOT have EITHER
	local slot, ledgerEntry = ltEntry:GetSlot(), ltEntry:GetLootLedgerEntry()

	--
	-- some various sanity checks, which should never occur unless there is a regression
	--

	-- ambiguous loot source, available from both creature and player
	if slot:isPresent() and ledgerEntry:isPresent() then
		self:AwardResult(false, session, winner, AS.Failure.LootAmbiguity, callback, ...)
		self:PrintLootError(AS.Failure.LootAmbiguity, link)
		return false
	end

	-- loot is destined for or available via player's bags, but no winner specified
	-- attempt to award later an item that is already for award later
	if ledgerEntry:isPresent() and not winner then
		self:AwardResult(false, session, winner, AS.Failure.AwardLaterCannotRepeat, callback, ...)
		self:PrintLootError(AS.Failure.AwardLaterCannotRepeat, link)
		return false
	end

	-- loot is being re-awarded, but no winner
	if ltEntry.awarded and not winner then
		self:AwardResult(false, session, winner, AS.Failure.AwardedCannotAwardLater, callback, ...)
		self:PrintLootError(AS.Failure.AwardedCannotAwardLater, link)
		return false
	end

	-- previously awarded, change the award
	if ltEntry.awarded then
		self:RegisterAndAnnounceAward(award)

		-- manual addition via '/cleo add' or testing
		if slot:isEmpty() and ledgerEntry:isEmpty() then
			self:AwardResult(true, session, winner, AddOn:TestModeEnabled() and AS.Neutral.TestMode or AS.Success.ManuallyAdded, callback, ...)
		-- (re) awarding via entry in the loot ledger
		elseif ledgerEntry:isPresent() then
			self:AwardResult(true, session, winner, AS.Success.Indirect, callback, ...)
		else
			self:AwardResult(true, session, winner, AS.Success.Normal, callback, ...)
		end

		return true
	end

	--
	-- not previously awarded
	--

	-- missing slot and not previously stored in the ledger, e.g. manual addition via '/cleo add' or testing
	if slot:isEmpty() and ledgerEntry:isEmpty() then
		-- a winner was assigned, announce it but don't actually take any further action
		if winner then
			self:AwardResult(true, session, winner, AddOn:TestModeEnabled() and AS.Neutral.TestMode or AS.Success.ManuallyAdded, callback, ...)
			self:RegisterAndAnnounceAward(award)
			return true
		else
			-- testing path and dev mode is disabled
			if AddOn:TestModeEnabled() and not AddOn:DevModeEnabled() then
				self:AwardResult(false, session, nil, AS.Neutral.TestMode, callback, ...)
				AddOn:Print(L['award_later_not_supported'] .. ' : ' .. link)
				return false
			-- award later when added manually via '/cleo add'
			else
				self:RegisterAndAnnounceLootedToBags(session)
				self:AwardResult(false, session, nil, AS.Neutral.AwardLaterAlreadyInBags, callback, ...)
				return false
			end
		end
	end

	-- entry is already in player's bags
	if ledgerEntry:isPresent() then
		self:RegisterAndAnnounceAward(award)
		self:AwardResult(true, session, winner, AS.Success.Indirect, callback, ...)
		return true
	end

	--
	-- remainder are direct loot allocation from the loot window
	--
	if self.lootOpen then
		local lootSlotLink = GetLootSlotLink(slot:get())
		if not AddOn.ItemIsItem(link, lootSlotLink) then
			Logging:Debug("Award(session=%d) : Loot slot (%d) changed before award completed, award=%s, slot=%s", session, slot:orElse("<EMPTY>"), link, lootSlotLink)
			-- will verify that the source is from current target's loot table before mutating loot slots
			self:UpdateLootSlots()
		end
	end

	local ok, cause = self:CanGiveLoot(link, slot:get(),winner or AddOn.player:GetName())
	Logging:Debug("Award(session=%d) : canGiveLoot=%s, cause=%s", award.session, tostring(ok), tostring(cause))
	if not ok then
		-- could be an extra case to handle here for items below loot threshold or BOE, but whatever...
		-- ... that should be handled via auto-loot and thresholds being set appropriately
		self:AwardResult(false, session, winner, cause, callback, ... )
		self:PrintLootError(cause, link, winner or AddOn.player:GetName())
		return false
	else
		-- actually give the loot to a player (winner)
		if winner then
			self:GiveLoot(
				slot:get(),
				winner,
				function(awarded, cause)
					if awarded then
						self:RegisterAndAnnounceAward(award)
						self:AwardResult(awarded, session, winner, AS.Success.Normal, callback, unpack(args))
						return true
					else
						self:AwardResult(awarded, session, winner, cause, callback, unpack(args))
						self:PrintLootError(cause, link, winner)
						return false
					end
				end
			)
		-- add to loot ledger for award later, it's implicitly going to current player (master looter)
		else
			self:GiveLoot(
				slot:get(),
				AddOn.player:GetName(),
				function(awarded, cause)
					if awarded then
						self:RegisterAndAnnounceLootedToBags(session)
						self:AwardResult(false, session, nil, AS.Neutral.AwardLaterFromBags, callback, unpack(args))
					else
						self:AwardResult(false, session, nil, cause, callback, unpack(args))
						self:PrintLootError(cause, link, AddOn.player:GetName())

					end
					return false
				end
			)
		end
	end
end

-- Modes for distinguishing between types of auto awards
local AutoAwardMode = {
	Normal          =   "normal",
	-- not currently used
	-- ReputationItem  =   "rep_item",
}

---@param item any the item
---@param quality number the item quality
---@return boolean true if able to be auto-awarded, otherwise false
---@return string the auto-award mode
---@return string the player which to auto-award
function ML:ShouldAutoAward(item, quality)
	if not item then return false end
	Logging:Debug(
		"ShouldAutoAward() : item=%s, quality=%d, autoAwardEnabled=%s",
		tostring(item), quality, tostring(self.db.profile.autoAward)
	)

	local db = self.db.profile

	local function IsEligibleUnit(unit)
		Logging:Trace("IsEligibleUnit(%s)", tostring(unit))
		return UnitInRaid(unit) or UnitInParty(unit)
	end

	local function IsEligibleItem(item)
		local itemId = ItemUtil:ItemLinkToId(item)
		Logging:Trace("IsEligibleItem(%s) : %d", tostring(item), tonumber(itemId))
		-- reputation items are handled separately, always false
		if itemId and ItemUtil:IsReputationItem(itemId) then
			return false
		end

		local isEquippable = IsEquippableItem(item)
		Logging:Trace(
			"IsEligibleItem(%d) : isEquippable=%s, autoAwardType=%s",
			itemId, tostring(isEquippable), tostring(db.autoAwardType)
		)
		return (db.autoAwardType == ML.AutoAwardType.All) or
				(db.autoAwardType == ML.AutoAwardType.Equippable and isEquippable) or
				(db.autoAwardType == ML.AutoAwardType.NotEquippable and not isEquippable)
	end

	Logging:Trace(
		"ShouldAutoAward() : quality=%d, autoAwardLowerThreshold=%d, autoAwardUpperThreshold=%d, lootThreshold=%d",
		quality, db.autoAwardLowerThreshold, db.autoAwardUpperThreshold, GetLootThreshold()
	)

	if db.autoAward and
		quality >= db.autoAwardLowerThreshold and
		quality <= db.autoAwardUpperThreshold and
		IsEligibleItem(item)
	then
		if db.autoAwardLowerThreshold >= GetLootThreshold() or db.autoAwardLowerThreshold < 2 then
			-- E.G. ["autoAwardTo"] = "Zùùl"
			if IsEligibleUnit(db.autoAwardTo) then
				return true, AutoAwardMode.Normal, db.autoAwardTo
			else
				AddOn:Print(L["cannot_auto_award"])
				AddOn:Print(format(L["could_not_find_player_in_group"], db.autoAwardTo))
				return false
			end
		else
			AddOn:Print(format(L["could_not_auto_award_item"], tostring(item)))
		end
	end

	return false
end

--- @param item string ItemID|ItemString|ItemLink
--- @param slot number index of the item within the loot table, can be Nil if item was not added from a loot table
--- @param quality number item quality
--- @param winner string name of the player which won the item
--- @param mode string the auto-award mode
--- @return boolean true if auto-awarded, otherwise false
function ML:AutoAward(item, slot, quality, winner, mode)
	winner = AddOn:UnitName(winner)
	Logging:Debug(
			"AutoAward() : slot=%s, item=%s, quality=%d, winner=%s, mode=%s",
			tostring(slot), tostring(item), tonumber(quality), winner, tostring(mode)
	)

	local db = self.db.profile
	if Util.Strings.Equal(mode, AutoAwardMode.Normal) then
		-- Perform an extra check for normal auto-awards, as Blizzard prevents you from
		-- looting items below a specific quality threshold to anyone except yourself
		-- 0 == Poor
		-- 1 == Common
		-- 2 == Uncommon
		if db.autoAwardLowerThreshold < 2 and quality < 2 and not AddOn.UnitIsUnit(winner, "player") then
			AddOn:Print(
				format(
					L["cannot_auto_award_quality"],
					_G.ITEM_QUALITY_COLORS[2].hex .. _G.ITEM_QUALITY2_DESC .. "|r"
				)
			)
			return false
		end
	end

	local canGiveLoot, cause = self:CanGiveLoot(item, slot, winner)
	if not canGiveLoot then
		AddOn:Print(L["cannot_auto_award"])
		self:PrintLootError(cause, item, winner)
		return false
	else
		local awardReason
		if Util.Strings.Equal(mode, AutoAwardMode.Normal) then
			-- db.autoAwardReason
			-- 'autoAwardReason' is going to something like 'bank', 'free', etc.
			-- this is the key attribute for locating the actual award entry
			 _, awardReason = Util.Tables.FindFn(
				AddOn:LootAllocateModule().db.profile.awardReasons,
				function(e) return Util.Strings.Equal(db.autoAwardReason, e.key) end
			)

			-- safety net, just take first one
			if not awardReason then
				Logging:Warn("AutoAward() : Could not find award reason for '%s', using random one", tostring(db.autoAwardReason))
				awardReason = AddOn:LootAllocateModule().db.profile.awardReasons[1]
			end

			Logging:Trace("AutoAward() : awardReason=%s", function() return Util.Objects.ToString(awardReason) end)
		else
			AddOn:Print(L["cannot_auto_award"])
			AddOn:Print(format(L["auto_award_invalid_mode"], mode))
			return false
		end

		self:GiveLoot(
				slot,
				winner,
				function(awarded, cause)
					if awarded then
						self:AnnounceAward(winner, item, awardReason.text, nil, nil, false, true)
						return true
					else
						AddOn:Print(L["cannot_auto_award"])
						self:PrintLootError(cause, item, winner)
						return false
					end
				end
		)
		return true
	end
end

function ML.AwardOnShow(frame, award)
	UIUtil.DecoratePopup(frame)
	frame.text:SetText(
		format(L["confirm_award_item_to_player"],
		       award.link,
		       UIUtil.ClassColorDecorator(award.class):decorate(AddOn.Ambiguate(award.winner))
		)
	)
	frame.icon:SetTexture(award.texture)
end

--- @param award Models.Item.ItemAward
function ML.AwardOnClickYes(_, award)
	--Logging:Debug('AwardOnClickYes() : %s', Util.Objects.ToString(award:toTable()))
	ML:Award(award)
end

function ML.AwardLaterOnShow(frame, award)
	UIUtil.DecoratePopup(frame)
	frame.text:SetText(format(L["confirm_award_later"], award.link))
end

function ML.AwardLaterOnClickYes(_, award)
	-- this is distinct from the AwardOnClickYes due to semantics of how
	-- 'award later' is handled based upon source (loot slot on creature or item in player's bags)
	-- during testing, with specific switches enabled, we allow code paths to be executed where not all information
	-- will necessarily be available. for example, 'test' execution and 'award later' for a testing item
	-- therefore, just capture and log the error via this path knowing that a developer/tester will have
	-- sufficient knowledge to interpret the output based upon what is being executed
	Util.Functions.try(
		function() ML:Award(award) end
	).catch(
		function(err)
			Logging:Error("AwardLaterOnClickYes(%s) : %s", Util.Objects.ToString(award), Util.Objects.ToString(err))
		end
	)
end

--- @param items table<number>
--- @param players table<string>
function ML:Test(items, players)
	Logging:Debug("Test(%d, %d)", #items, players and #players or -1)

	AddOn:StartHandleLoot()

	for _, item in ipairs(items) do
		self:AddLootTableItem(item, AddOn.Testing.LootSource)
	end

	if self.db.profile.autoStart then
		AddOn:Print("Auto start isn't supported when testing")
	end

	-- if not in a group or raid, simulate a player joined event
	if not IsInGroup() and not IsInRaid() then
		local function SimulatePlayerJoinedEvent()
			local activeConfiguration = AddOn:ListsModule():GetActiveConfiguration()
			if activeConfiguration then
				activeConfiguration:OnPlayerEvent(AddOn.player, true)

				if Util.Objects.IsTable(players) then
					self.testGroupMembers = players
					for _, p in pairs(self.testGroupMembers) do
						-- e.g. activeConfiguration:OnPlayerEvent("Avalona", true)
						activeConfiguration:OnPlayerEvent(p, true)
					end
				end

				return true
			end

			return false
		end

		local function PlayerJoinedEvent()
			local eventGenerated = SimulatePlayerJoinedEvent()
			if not eventGenerated then
				AddOn:ScheduleTimer(PlayerJoinedEvent, 1)
			end
		end

		PlayerJoinedEvent()
	end

	AddOn:CallModule("LootSession")
	AddOn:GetModule("LootSession"):Show(self.lootTable)
end

function ML:ConfigSupplement()
	return L["master_looter"], function(container) self:LayoutConfigSettings(container) end
end