--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type Models.Item.ItemRef
local ItemRef = AddOn.Package('Models.Item').ItemRef
--- @type Models.Item.Item
local Item = AddOn.Package('Models.Item').Item
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
--- @type Models.Player
local Player = AddOn.ImportPackage('Models').Player
--- @type Models.Encounter
local Encounter = AddOn.ImportPackage('Models').Encounter
--- @type Models.DateFormat
local DateFormat = AddOn.Package('Models').DateFormat
--- @type Models.DateFormat
local fullDf = DateFormat("mm/dd/yyyy HH:MM:SS")
---
--- The source of loot, specifically the unique id (GUID)
---
--- @class Models.Item.LootSource
--- @field public id number the guid of the source of the loot
local LootSource = AddOn.Package('Models.Item'):Class('LootSource')
function LootSource:initialize(id)
	-- assert(AddOn:IsGUID(id), format("%s is not a valid GUID", tostring(id)))
	self.id = id
end

function LootSource:GetType()
	return L["unknown"]
end

function LootSource:GetName()
	return L["unknown"]
end

function LootSource:__eq(o)
	return self.id == o.id
end

function LootSource:tostring()
	return Util.Objects.ToString(self:toTable())
end

---
--- The source of loot obtained from a loot slot on a creature
---
--- @class Models.Item.CreatureLootSource : Models.Item.LootSource
--- @field public slot number the slot at which loot is located
local CreatureLootSource = AddOn.Package('Models.Item'):Class('CreatureLootSource', LootSource)
function CreatureLootSource:initialize(id, slot)
	assert(AddOn:IsCreatureGUID(id), format("%s is not a valid creature GUID", tostring(id)))
	assert(Util.Objects.IsNumber(slot), format("%s is not a valid loot slot", tostring(slot)))
	LootSource.initialize(self, id)
	self.slot = slot
end

--- @return string the type of the source
function CreatureLootSource:GetType()
	return "Creature"
end

--- @return string the name of the creature
function CreatureLootSource:GetName()
	return AddOn:GetCreatureName(self.id) or L['unknown_creature']
end

--- @return number
function CreatureLootSource:GetSlot()
	return self.slot
end

function CreatureLootSource:tostring()
	return Util.Objects.ToString(self:toTable())
end

--- @param slot number the slot at which loot is located
--- @return  Models.Item.CreatureLootSource
function CreatureLootSource.FromCurrent(slot)
	slot = tonumber(slot)
	assert(slot ~= nil, "loot slot must be a number")
	assert(slot >= 1, "loot slot must greater than or equal to 1")

	local numLootItems = GetNumLootItems()
	assert(slot <= numLootItems, format("%d is not a valid loot slot (%d available)", slot, numLootItems))

	local guid = GetLootSourceInfo(slot)
	assert(guid ~= nil, "loot slot source could not be obtained")

	return CreatureLootSource(guid, slot)
end

---
--- The source of loot obtained via a location in a player's bags
---
--- @class Models.Item.PlayerLootSource : Models.Item.LootSource
--- @field public item string the guid of the loot (item)
local PlayerLootSource =  AddOn.Package('Models.Item'):Class('PlayerLootSource', LootSource)
--- @param id string the player's GUID
--- @param item string the item's GUID
function PlayerLootSource:initialize(id, item)
	assert(AddOn:IsPlayerGUID(id), format("%s is not a valid player GUID", tostring(id)))
	assert(AddOn:IsItemGUID(item), format("%s is not a valid item GUID", tostring(item)))
	LootSource.initialize(self, id)
	self.item = item
end

--- @return string the type of the source
function PlayerLootSource:GetType()
	return "Player"
end

--- @return string the name of the player
function PlayerLootSource:GetName()
	local p = Player:Get(self.id)
	return p and p:GetShortName() or L['unknown_player']
end


--- @return string the item guid
function PlayerLootSource:GetItemGUID()
	return self.item
end

--- @return LootLedger.Entry the loot ledger entry for the item or nil if not present
function PlayerLootSource:GetLootLedgerEntry()
	return AddOn:LootLedgerModule():GetStorage():GetByItemGUID(self:GetItemGUID())
end

function PlayerLootSource:tostring()
	return Util.Objects.ToString(self:toTable())
end

--- @param itemGUID string the item's GUID
--- @return Models.Item.PlayerLootSource
function PlayerLootSource.FromCurrentPlayer(itemGUID)
	local player = Player:Get("player")
	assert(player, "could not determine current player")
	assert(player:IsValid(), "player is not valid")
	assert(not player:IsUNK(), "player is unknown")
	return PlayerLootSource(player.guid, itemGUID)
end

local function IsSameLootSource(source1, source2)
	-- both nil, this should evaluate to true
	if Util.Objects.IsNil(source1) and Util.Objects.IsNil(source2) then
		return true
	end

	if Util.Objects.IsNil(source1) then
		return false
	end

	-- is from the same source if (creature) id is equivalent
	return not Util.Objects.IsNil(source2) and (source1 == source2)
end

---
--- An item in a loot slot from a loot source
---
--- @class Models.Item.LootSlotInfo : Models.Item.ItemRef
--- @see Models.Item.ItemRef
--- @field public name string the item name
--- @field public quantity number the number of items
--- @field public quality number the quality of the item
--- @field public source Models.Item.CreatureLootSource the source of the loot, along with slot
--- @field public looted boolean has the item been looted
local LootSlotInfo = AddOn.Package('Models.Item'):Class('LootSlotInfo', ItemRef)
function LootSlotInfo:initialize(slot, name, link, quantity, quality)
	-- links work as item references
	ItemRef.initialize(self, link)
	--- @type Models.Item.CreatureLootSource
	self.source = CreatureLootSource.FromCurrent(slot)
	self.name = name
	self.quantity = quantity
	self.quality = quality
	self.looted = false
end

--- @return number the loot slot
function LootSlotInfo:GetSlot()
	return self.source.slot
end

--- @return string the full item link
function LootSlotInfo:GetItemLink()
	return self.item
end

--- @param source  Models.Item.LootSource
function LootSlotInfo:IsFromSource(source)
	return IsSameLootSource(source, self.source)
end

function LootSlotInfo:tostring()
	return Util.Objects.ToString(self:toTable())
end

---
--- An item from a loot table, appropriate for transmitting loot table to a player
---
--- @class Models.Item.LootTableEntry : Models.Item.ItemRef
--- @see Models.Item.ItemRef
--- @field public source Models.Item.LootSource  the source of the loot (item)
--- @field public awarded boolean|string has item been awarded and if so, to whom
--- @field public sent boolean has the item been transmitted to players
local LootTableEntry = AddOn.Package('Models.Item'):Class('LootTableEntry', ItemRef)
--- @param item any  ItemID|ItemString|ItemLink
--- @param source Models.Item.LootSource source from which loot was obtained
function LootTableEntry:initialize(item, source)
	assert(source, "loot source was not provided")
	ItemRef.initialize(self, item)
	--- @type Models.Item.LootSource
	self.source = source
	self.awarded = false
	self.sent = false
end

--- @param source  Models.Item.CreatureLootSource
function LootTableEntry:IsFromSource(source)
	return IsSameLootSource(source, self.source)
end

-- trims down the entry to minimal amount of needed information
-- in order to keep data transmission small
--- @return table<string, string>
function LootTableEntry:ForTransmit()
	return {
		ref = ItemRef.ForTransmit(self),
		owner = self.source:GetName()
	}
end

---@return Models.Item.ItemRef
function LootTableEntry.ItemRefFromTransmit(t, session)
	if not t or not t.ref then error("no reference provided") end
	local ir = ItemRef.FromTransmit(t.ref)

	if Util.Objects.IsSet(session) then
		ir.session = session
	end

	-- there may be additional attributes that are specified
	-- if so, make sure we carry them along
	for attr, value in pairs(t) do
		if not Util.Strings.Equal(attr, 'ref') then
			ir[attr] = value
		end
	end

	return ir
end

--- @return string the name of the entity which currently owns the loot. if unavailable or unable to be determined, will return 'Unknown'
function LootTableEntry:GetOwner()
	return self.source:GetName() or L['unknown']
end

---
--- Will only be non-empty if the loot source is a Models.Item.CreatureLootSource
---
--- @return LibUtil.Optional.Optional an optional, which if present will be the numeric loot slot
function LootTableEntry:GetSlot()
	return Util.Optional.ofNillable(self.source.GetSlot and self.source:GetSlot() or nil)
end

--- Will only be non-empty if the loot source is a Models.Item.PlayerLootSource
---
---
-- @return LibUtil.Optional.Optional an optional, which if present will be the GUID of the item (uniquely identifies in a player's bags)
function LootTableEntry:GetItemGUID()
	return Util.Optional.ofNillable(self.source.GetItemGUID and self.source:GetItemGUID() or nil)
end

---
--- Can only be non-empty if the loot source is a Models.Item.PlayerLootSource, but even in that case
--- it may be empty if the item has not yet been added to the LootLedger
---
---
--- @return LibUtil.Optional.Optional an optional, which if present will be a LootLedger.Entry
function LootTableEntry:GetLootLedgerEntry()
	return Util.Optional.ofNillable(self.source.GetLootLedgerEntry and self.source:GetLootLedgerEntry() or nil)
end

function LootTableEntry:tostring()
	return Util.Objects.ToString(self:toTable())
end
---
--- An item from a loot table queue, used for triggering functions after the associated loot slot is cleared
---
--- @class Models.Item.LootQueueEntry
--- @field public slot number the index at which loot is located on the loot table, cannot be nil
--- @field public callback function function to invoke after entry is cleared, can be nil
--- @field public args table parameters to pass to callback function, can be nil
--- @field public timer AceTimer timer which will invoke associated callback, can be nil
local LootQueueEntry = AddOn.Package('Models.Item'):Class('LootQueueEntry')
--- @param slot number  index of the item within the loot table, can be Nil if item was not added from a loot table
--- @param callback function function to invoke after entry is cleared, can be nil
--- @param args table parameters to pass to callback function, can be nil
function LootQueueEntry:initialize(slot, callback, args)
	-- verify non-numeric values aren't passed
	self.slot = tonumber(slot)
	self.callback = callback
	self.args = args
	self.timer = nil
end

---@param awarded boolean was entry cleared as  result of successful award
---@param reason string if not awarded, the reason for failure
function LootQueueEntry:Cleared(awarded, reason)
	-- Logging:Trace("Cleared() : %s, %s", tostring(awarded), tostring(reason))
	if self.callback then
		self.callback(awarded, reason, unpack(self.args))
	end
end

---
--- An item for presentation to a player through the Loot interface. Some additional attributes may be present
--- if specified in message received via comms (e.g. isRoll via LootAllocateEntry:GetReRollData)
---
--- @class Models.Item.LootEntry : Models.Item.Item
--- @see Models.Item.Item
--- @field public rolled boolean has player responded
--- @field public sessions table the sessions associated with the loot
--- @field public timeLeft number|boolean how much time is left for response or false if timeout not being used
--- @field public responders table players who have responded to loot
local LootEntry = AddOn.Package('Models.Item'):Class('LootEntry', Item)
function LootEntry:initialize(session, timeout)
	Item.initialize(self)
	self.rolled = false
	self.sessions = Util.Objects.Check(session, {session}, {})
	self.timeLeft = Util.Objects.Default(timeout, false)
	self.responders = {}
end

function LootEntry:TrackResponse(name, response)
	local responses = self.responders[response]
	if not responses then
		responses = {}
		self.responders[response] = responses
	end

	if not Util.Tables.ContainsValue(responses, name) then
		Util.Tables.Push(responses, name)
	end
end


--- @param itemRef Models.Item.ItemRef
--- @param session number
--- @param timeout number
--- @return Models.Item.LootEntry
function LootEntry.FromItemRef(itemRef, session, timeout)
	return itemRef:Embed(LootEntry, Util.Objects.Check(itemRef.session, itemRef.session, session), timeout)
end

--- @return Models.Item.LootEntry
function LootEntry.Rolled()
	local entry = LootEntry()
	entry.rolled = true
	return entry
end

---
--- A player's response, associated with the process of allocating loot (item)
---
--- @class Models.Item.LootAllocateResponse
--- @field public name string the player's name
--- @field public class string the player's class
--- @field public response string the player's response (key/id)
--- @field public ilvl number the player's average equipped item level
--- @field public diff number the difference in item level between equipped and item associated with the response
--- @field public gear1 string the item currently equipped (1)
--- @field public gear2 string the item currently equipped (2)
--- @field public roll number if a player roll was requested, what number was rolled
local LootAllocateResponse = AddOn.Package('Models.Item'):Class('LootAllocateResponse')
--- @type table
LootAllocateResponse.Attributes = {
	Ilvl            =   "ilvl",
	Response        =   "response",         -- tracks the player's response to an item
	ResponseActual  =   "response_actual",  -- when an item is awarded, this is the original response (otherwise, unset)
	Roll            =   "roll",
	Gear1           =   "gear1",
	Gear2           =   "gear2",
}

function LootAllocateResponse:initialize(player)
	self.name      = player:GetName()
	self.class     = player.class or L['unknown']
	self.response  = C.Responses.Announced
	-- could be cached (see PlayerInfo communications handling)
	self.ilvl      = player.ilvl or 0
	self.diff      = 0
	self.gear1     = nil
	self.gear2     = nil
	self.roll      = nil
end

function LootAllocateResponse:Set(key, value)
	self[key] = value
end

function LootAllocateResponse:Get(key)
	return self[key]
end

--- @field public session number the session associated with the loot
--- @field public link string the item link
--- @field public winner string the player who is being awarded the item
--- @field public class string the player's class, which is really a convenience attribute based upon winner
--- @field public equipLoc string the item's equipment location, required for mapping to appropriate list
--- @field public origin number the origin of the award, either from a player's response or another user non-visible reason
--- @field public awardReason string|number the key (string/number) of the award reason
--- @field public normalizedReason table normalized response/reason for consistent access (1 .. N indexes)
--- @class Models.Item.ItemAwardMixin
local ItemAwardMixin = {
	--- what was the origin of the award, either from the player's response (1) or another non-visible to user reason (2)
	--- @type table<string, number>
	Origin = {
		Response = 1,
		Reason   = 2,
	},
	--- @param self Models.Item.ItemAwardMixin the instance of the mixin
	--- @param session number the session associated with the award
	WithSession = function(self, session)
		self.session = tonumber(session)
		return self
	end,
	--- @param self Models.Item.ItemAwardMixin the instance of the mixin
	--- @param item number|string the item associated with the award
	WithItem = function(self, item)
		if ItemUtil:ContainsItemString(item) then
			self.link = item
		elseif Util.Objects.IsNumber(item) then
			local itemInstance = Item.Get(item, function(i) self.link = i.link end)
			if itemInstance then
				self.link = itemInstance.link
			end
		else
			error("unsupported item format %s", tostring(item))
		end
		return self
	end,
	--- @param self Models.Item.ItemAwardMixin the instance of the mixin
	--- @param winner string the player who is being awarded the item
	--- @param class string the player's class, if nil will be derived from Player
	WithWinner = function(self, winner, class)
		self.winner = winner
		if class then
			self.class = class
		else
			local p = Player:Get(winner)
			self.class = p and p.class or nil
		end
		return self
	end,
	--- @param self Models.Item.ItemAwardMixin the instance of the mixin
	--- @param equipLoc string the item's equipment location, required for mapping to appropriate list
	WithEquipmentLocation = function(self, equipLoc)
		self.equipLoc = equipLoc
		return self
	end,
	--- @param self Models.Item.ItemAwardMixin the instance of the mixin
	--- @param response string|number the candidate's (player) response key/id (see Constants.Responses and ML DB's responses)
	--- @param reason string|table if award is for a reason other than candidate's (player) response, this should be provided
	WithReason = function(self, response, reason)
		self.origin = reason and self.Origin.Reason or self.Origin.Response

		-- please note, if you change any of the attribute names from here onwards in the function
		-- you will need to update LootedItem
		local responseAttrs, awardReason = AddOn:GetResponse(response), nil
		-- if reason is provided, it overrides candidate's response
		-- it will be entry from ML's responses table. for example, Award For : Disenchant|Bank|Free
		if reason and Util.Objects.IsTable(reason) then
			awardReason = reason.key
		-- otherwise, being awarded for the actual response
		else
			awardReason = responseAttrs.key and responseAttrs.key or response
		end

		-- the name (key) of the award reason
		self.awardReason = awardReason

		-- normalize the response/reason divergence for consistent access (1 .. N indexes)
		self.normalizedReason = {
			id    = reason and reason.sort - 400 or response,
			text  = reason and reason.text or responseAttrs.text,
			color = reason and reason.color or responseAttrs.color
		}

		return self
	end,
	--- @param self Models.Item.ItemAwardMixin the instance of the mixin
	--- @return table indicating the attributes associated with the resolved reason for the item award (player response vs award reason)
	NormalizedReason = function(self)
		return self.normalizedReason
	end,
	--- @param self Models.Item.ItemAwardMixin the instance of the mixin
	--- @return string representation of the mixin
	tostring = function(self)
		return Util.Objects.ToString(self:toTable())
	end
}

---
--- An award of an item to a player
---
--- @class Models.Item.ItemAward : Models.Item.ItemAwardMixin
--- @field public class string the player's class, which is really a convenience attribute based upon winner
local ItemAward = AddOn.Package('Models.Item'):Class('ItemAward'):include(ItemAwardMixin)

---
--- A deferred award of an item to a player, which will occur sometime in the future. It's the minimal amount of information
--- needed to represent an award in the 'do this later' workflow.
---
--- @class Models.Item.DeferredItemAward : Models.Item.ItemAwardMixin
local DeferredItemAward = AddOn.Package('Models.Item'):Class('DeferredItemAward'):include(ItemAwardMixin)
--- @param session number the session umber
--- @param item any ItemID|ItemString|ItemLink
function DeferredItemAward:initialize(session, item)
	self.origin = 0
	self:WithSession(session)
	self:WithItem(item)
end

--- @class Models.Item.PartialItemAward : Models.Item.DeferredItemAward
local PartialItemAward = AddOn.Package('Models.Item'):Class('PartialItemAward', DeferredItemAward)
function PartialItemAward:initialize(session, item, origin)
	DeferredItemAward.initialize(self, session, item)
	self.origin = origin
end

---
--- An loot allocation entry, associated with an item, which tracks player's responses
---
--- @class Models.Item.LootAllocateEntry : Models.Item.Item
--- @see Models.Item.Item
--- @field public session number the session associated with the loot
--- @field public added string has entry been added to allocation interface
--- @field public awarded string|boolean has item been awarded and if so, to whom
--- @field public candidates  table<string, Models.Item.LootAllocateResponse> player's response to the loot
local LootAllocateEntry = AddOn.Package('Models.Item'):Class('LootAllocateEntry', Item)
function LootAllocateEntry:initialize(session)
	Item.initialize(self)
	self.session = session
	self.added = false
	-- initialized as boolean indicating not awarded, but once awarded will be changed to winner's name
	self.awarded = false
	--- @type table<string, Models.Item.LootAllocateResponse>
	self.candidates = {}
end

---@param player Models.Player
function LootAllocateEntry:AddCandidate(player)
	Logging:Trace("AddCandidate(%s)", tostring(player))
	self.candidates[player:GetName()] = LootAllocateResponse(player)
end

---@param name string
---@return Models.Item.LootAllocateResponse
function LootAllocateEntry:GetCandidateResponse(name)
	--Logging:Debug("GetCandidateResponse(%s) : %s", tostring(name), Util.Objects.ToString(self.candidates))
	local lar = self.candidates[name]
	assert(lar, format("no response available for candidate %s", tostring(name)))
	return lar
end

-- todo : handle 'award later' -> 'to trade'
--- @return Models.Item.ItemAward
function LootAllocateEntry:GetItemAward(candidate, reason)
	-- Logging:Debug("%s", Util.Objects.ToString(self.clazz))
	return ItemAward(self, candidate, reason)
end

--- @return table<string, any>
function LootAllocateEntry:GetReRollData(isRoll, noAutoPass)
	return {
		ref        = AddOn.TransmittableItemString(self.link),
		session    = self.session,
		isRoll     = isRoll,
		noAutoPass = noAutoPass,
		-- this may not be set if not originally sent with loot table
		-- which is where the data would be extracted and set on the entry
		owner      = self.owner,
	}
end

--- @param itemRef Models.Item.ItemRef
--- @param session number
--- @return Models.Item.LootAllocateEntry
function LootAllocateEntry.FromItemRef(itemRef, session)
	return itemRef:Embed(
			LootAllocateEntry,
			Util.Objects.Check(itemRef.session, itemRef.session, session)
	)
end

--- @param entry Models.Item.LootAllocateEntry
--- @param candidate string the player for award
--- @param reason string|table if award is for a reason other than candidates' response, this will be provided
function ItemAward:initialize(entry, candidate, reason)
	if not entry or not Util.Objects.IsInstanceOf(entry, LootAllocateEntry) then
		Logging:Warn("%s", tostring(entry))
		error("the provided 'entry' instance was not of type LootAllocateEntry : " .. type(entry))
	end
	--[[
	Examples of response/reason permutations

	Candidate responded with MS/Need, but awarded for 'Bank'
		{ responseId = 1, reason = { color = {...}, text = 'Bank', sort = 403, key = 'bank', ...}, awardReason = 'bank', ...

	Candidate responded with MS/Need and awarded for that reason
		{ responseId = 1, reason = nil, awardReason = 'ms_need', ...

	--]]
	local cr = entry:GetCandidateResponse(candidate)
	self:WithSession(entry.session)
	self:WithItem(entry.link)
	self:WithWinner(candidate, cr.class)
	-- needed for selecting appropriate list
	self:WithEquipmentLocation(entry:GetEquipmentLocation())
	self:WithReason(cr.response, reason)
end

local State = {
	AwardLater = "AL",
	ToTrade    = "TT",
}
local StateNames = tInvert(State)

---
--- An item, which has been looted by a player (master looter) for later distribution
---
--- @class Models.Item.LootedItem : Models.Item.ItemRef
--- @see Models.Item.ItemRef
--- @field item string the item string
--- @field state string the state of the bagged item
--- @field guid string the item GUID, which must be in inventory (bags or bank). will be nil if not yet in inventory and evaluated
--- @field added number timestamp when item added (seconds since the epoch), not necessarily when it entered bags
--- @field supplemental table<string, any> key/value attributes which can differ by 'type' and 'source' of looted item
local LootedItem = AddOn.Package('Models.Item'):Class('LootedItem', ItemRef)
LootedItem.State = State
LootedItem.StateNames = StateNames

--- @param item Models.Item.LootedItem
--- @param skipNilCheck boolean should validation omit check for nil attributes before evaluating
--- @return Models.Item.LootedItem
local function validate(item, skipNilCheck)
	skipNilCheck = (skipNilCheck == true)

	if Util.Objects.IsNil(item) then
		error("LootedItem is nil")
	end

	-- GUID isn't available until item is actually bagged, so don't obey skipNilCheck here
	if Util.Objects.IsSet(item.guid) and not AddOn:IsItemGUID(item.guid) then
		error(format("%s is not a valid item GUID", tostring(item.guid)))
	end

	if (skipNilCheck or Util.Objects.IsSet(item.item)) and not ItemUtil:ContainsItemString(item.item) then
		error(format("%s is not a valid item string", tostring(item.item)))
	end

	if (skipNilCheck or Util.Objects.IsSet(item.state)) and not StateNames[item.state] then
		error(format("%s is not a valid item state", tostring(item.state)))
	end

	return item
end

-- well known and supported supplemental attributes
local SupplementalAttributes = {
	Award     = 'award',
	Encounter = 'encounter',
}

-- minimal attributes needed for encounter representation
local EncounterAttributes = {
	Id         = 'id',
	InstanceId = 'instanceId'
}

local AwardAttributes = {
	EquipmentLocation = 'equipLoc',
	Origin            = 'origin',
	Reason            = 'reason',
	Response          = 'response',
	ResponseId        = 'responseId',
	Session           = 'session',
	Winner            = 'winner',
}

--- @return Models.Item.LootedItem
function LootedItem:initialize(item, state, guid)
	ItemRef.initialize(self, item)
	-- the state of the looted item
	self.state = state
	-- the item GUID
	self.guid = guid
	-- timestamp when item added (not necessarily when it entered bags)
	self.added = GetServerTime()
	-- key/value attributes which can differ by 'type' and 'source' of looted item
	self.supplemental = {}
	validate(self)
end

function LootedItem:__eq(other)
	return AddOn.ItemIsItem(self.item, other.item) and Util.Strings.Equal(self.guid, other.guid)
end

function LootedItem:afterReconstitute(instance)
	return validate(instance, true)
end

--- @return number time, in seconds, since item was added
function LootedItem:TimeSinceAdded()
	return (GetServerTime() - self.added)
end

--- @return string the entry's added timestamp formatted in local TZ in format of mm/dd/yyyy HH:MM:SS
function LootedItem:FormattedTimestampAdded()
	return fullDf:format(self.added)
end

--- @return boolean true if item's attributes are valid
function LootedItem:IsValid()
	return ItemUtil:ContainsItemString(self.item) and Util.Tables.ContainsKey(StateNames, self.state)
end

--- @return string a human readable description of the state
function LootedItem:GetStateDescription()
	-- BLECH
	return Util.Strings.Join(" ",
		Util.Strings.Split(Util.Strings.FromCamelCase(LootedItem.StateNames[self.state]), " ")
	)
end
---
--- Marks the item as 'award later'
---
--- @return Models.Item.LootedItem
function LootedItem:AwardLater()
	self.state = LootedItem.State.AwardLater
	return self
end

---
--- Marks the item as 'to trade'
---
--- @return Models.Item.LootedItem
function LootedItem:ToTrade()
	self.state = LootedItem.State.ToTrade
	return self
end

--- @see AddOn.GetBagAndSlotByGUID
--- @return number, number the bag and slot for associated item GUID, or nil if it cannot be located
function LootedItem:GetBagAndSlot()
	return AddOn:GetBagAndSlotByGUID(self.guid)
end

--- @see AddOn.GetInventoryItemTradeTimeRemaining
--- @return number remaining time (in seconds) for associated item
function LootedItem:GetTradeTimeRemaining()
	local bag, slot = self:GetBagAndSlot()
	if bag and slot then
		return AddOn:GetInventoryItemTradeTimeRemaining(bag, slot)
	end

	return 0
end

--- @param encounter Models.Encounter
function LootedItem:WithEncounter(encounter)
	if encounter and encounter ~= Encounter.None then
		-- could just 'toTable' the encounter itself, but has an additional
		-- 3-4 fields which are not needed for award path taken from a looted item
		self.supplemental[SupplementalAttributes.Encounter] = {
			[EncounterAttributes.InstanceId] = encounter.instanceId,
			[EncounterAttributes.Id]         = encounter.id,
		}
	end

	return self
end

--- @return LibUtil.Optional.Optional an optional, which if present will be the associated encounter
function LootedItem:GetEncounter()
	local encounterAttrs = self.supplemental[SupplementalAttributes.Encounter]
	if encounterAttrs then
		-- create an empty encounter and only assign the attributes we capture
		local encounter = Encounter()
		for _, attr in pairs(EncounterAttributes) do
			encounter[attr] = encounterAttrs[attr]
		end

		return Util.Optional.of(encounter)
	end

	return Util.Optional.empty()
end

--- @param award Models.Item.ItemAward
function LootedItem:WithAward(award)
	-- an award is being assigned, transition state into 'to trade'
	self:ToTrade()
	if award then
		local normalizedReason = award:NormalizedReason()
		-- could just 'toTable' the award itself, but has an additional
		-- number fields which are not needed for award path taken from a looted item
		self.supplemental[SupplementalAttributes.Award] = {
			-- the equipment location, later used for mapping to appropriate list
			[AwardAttributes.EquipmentLocation] = award.equipLoc,
			-- this will be the award reason key, mapping into MasterLooter.AwardReasons
			-- it's used for determining if it a suicide occurs and, if so, how many spots
			[AwardAttributes.Reason]            = award.awardReason,
			-- the 'text' of the response
			[AwardAttributes.Response]          = normalizedReason.text,
			-- the 'id' of the response
			[AwardAttributes.ResponseId]        = normalizedReason.id,
			-- did the response originate from player or another reason (e.g. 'award for ...')
			[AwardAttributes.Origin]            = award.origin,
			-- this is the loot session from which the item is associated
			-- i'm not so sure it's needed other than potentially helping
			-- locate the item in absence of other information
			[AwardAttributes.Session]           = award.session,
			-- duh, the actual winner
			[AwardAttributes.Winner]            = award.winner,
		}
	end
	return self
end

--- @return LibUtil.Optional.Optional an optional, which if present will be the associated item award
function LootedItem:GetItemAward()
	local awardAttrs = self.supplemental[SupplementalAttributes.Award]
	if self:IsToTrade() and awardAttrs then
		local award = PartialItemAward(
			awardAttrs[AwardAttributes.Session],
			self.item,
			awardAttrs[AwardAttributes.Origin]
		)

		award = award:WithWinner(awardAttrs[AwardAttributes.Winner]):WithEquipmentLocation(AwardAttributes.EquipmentLocation)
		-- these attributes should probably be handled via ItemAwardMixin, however they are mostly derived and
		-- we've stored the individual attribute that were pre-calculated. just manipulate then directly
		award.awardReason = awardAttrs[AwardAttributes.Reason]
		award.normalizedReason = {
			id =  awardAttrs[AwardAttributes.ResponseId],
			text = awardAttrs[AwardAttributes.Response],
			-- this shouldn't be needed, but making it a non-class color for easy identification if used
			color = C.Colors.ItemLegendary
		}

		return Util.Optional.of(award)
	end

	return Util.Optional.empty()
end

--- @return boolean true if state is 'award later', otherwise false
function LootedItem:IsAwardLater()
	return self.state == LootedItem.State.AwardLater
end

--- @return boolean true if state is 'to trade', otherwise false
function LootedItem:IsToTrade()
	return self.state == LootedItem.State.ToTrade
end
