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
local  Item = AddOn.Package('Models.Item').Item

---
--- The source of loot, specifically the id and name
---
--- @class Models.Item.LootSlotSource
--- @field public id number the id of the source of the loot
--- @field public name string the name of the source of the loot
local LootSlotSource = AddOn.Package('Models.Item'):Class('LootSlotSource')
function LootSlotSource:initialize(id, name)
	self.id = id
	-- may not need to collect the source's name
	self.name = name
end

function LootSlotSource:__eq(o)
	return self.id == o.id
end

--- @return  Models.Item.LootSlotSource
function LootSlotSource.FromCurrent(slot)
	-- if no slot provided, find a random slot to use
	-- they will be from the same source
	if Util.Objects.IsEmpty(slot) then
		-- it doesn't matter which one it is
		slot = GetNumLootItems()
	else
		slot = tonumber(slot)
	end

	local id

	-- https://wow.gamepedia.com/API_GetLootSourceInfo
	-- the creature being looted
	if not Util.Objects.IsNil(slot) and slot > 0 then
		id = AddOn:ExtractCreatureId(GetLootSourceInfo(slot))
	end

	-- we're looting a creature, so the target will be that creature
	-- could potentially use LibEncounter here with id
	local name = GetUnitName("target")

	return LootSlotSource(id, name)
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
--- @class Models.Item.LootSlotInfo
--- @see Models.Item.ItemRef
--- @field public slot number the loot slot index
--- @field public name string the item name
--- @field public quantity number the number of items
--- @field public quality number the quality of the item
--- @field public source Models.Item.LootSlotSource the source of the loot
--- @field public looted boolean has the item been looted
local LootSlotInfo = AddOn.Package('Models.Item'):Class('LootSlotInfo', ItemRef)
function LootSlotInfo:initialize(slot, name, link, quantity, quality)
	-- links work as item references
	ItemRef.initialize(self, link)
	self.slot = slot
	self.name = name
	self.quantity = quantity
	self.quality = quality
	--- @type Models.Item.LootSlotSource
	self.source = LootSlotSource.FromCurrent(self.slot)
	self.looted = false
end

--- @return string the full item link
function LootSlotInfo:GetItemLink()
	return self.item
end

--- @param source  Models.Item.LootSlotSource
function LootSlotInfo:IsFromSource(source)
	return IsSameLootSource(source, self.source)
end

---
--- An item from a loot table, appropriate for transmitting loot table to a player
---
--- @class Models.Item.LootTableEntry
--- @see Models.Item.ItemRef
--- @field public slot number index of the item within the loot table, can be Nil if item was not added from a loot table
--- @field public source Models.Item.LootSlotSource the source of the loot (item), can be Nil if item was not added from a loot table
--- @field public awarded boolean has the item been awarded
--- @field public sent boolean has the item been transmitted to players
local LootTableEntry = AddOn.Package('Models.Item'):Class('LootTableEntry', ItemRef)
--- @param slot number  index of the item within the loot table, can be Nil if item was not added from a loot table
--- @param item any  ItemID|ItemString|ItemLink
--- @param source Models.Item.LootSlotSource source from which loot (slot) was obtained, can be Nil if item was not added from a loot table
function LootTableEntry:initialize(slot, item, source)
	ItemRef.initialize(self, item)
	self.slot = slot
	--- @type Models.Item.LootSlotSource
	self.source = source
	self.awarded = false
	self.sent = false
	Logging:Trace("LootTableEntry() : %s", Util.Objects.ToString(self:toTable()))
end


--- @param source  Models.Item.LootSlotSource
function LootTableEntry:IsFromSource(source)
	return IsSameLootSource(source, self.source)
end

-- trims down the entry to minimal amount of needed information
-- in order to keep data transmission small
function LootTableEntry:ForTransmit()
	return {
		ref = ItemRef.ForTransmit(self)
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

---
--- An item from a loot table queue, used for triggering functions after the associated loot slot is cleared
---
--- @class Models.Item.LootQueueEntry
--- @field public slot number index of the item within the loot table, can be Nil if item was not added from a loot table
--- @field public callback function function to invoke after entry is cleared, can be nil
--- @field public args table parameters to pass to callback function, can be nil
--- @field public timer AceTimer timer which will invoke associated callback, can be nil
local LootQueueEntry = AddOn.Package('Models.Item'):Class('LootQueueEntry')
--- @param slot number  index of the item within the loot table, can be Nil if item was not added from a loot table
--- @param callback function function to invoke after entry is cleared, can be nil
--- @param args table parameters to pass to callback function, can be nil
function LootQueueEntry:initialize(slot, callback, args)
	self.slot = tonumber(slot) -- verify people are not passing non-numeric values
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
--- An item for presentation to a player through the Loot interface
---
--- @class Models.Item.LootEntry
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
--- @field public response string the player's response
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

---
--- The award of an item to a player
---
--- @class Models.Item.ItemAward
--- @field public session number the session associated with the loot
--- @field public winner string the player who is being awarded the item
--- @field public class string the player's class
--- @field public gear1 string the item currently equipped (1)
--- @field public gear2 string the item currently equipped (2)
--- @field public link string the item link
--- @field public equipLoc string the item's equipment location
--- @field public texture string the item's texture (picture)
--- @field public responseId string the player's actual response
--- @field public reason string the reason for the award, if not the player's response this does not need to be provided
--- @field public awardReason string the name (key) of the award reason
--- @field public normalizedReason table normalized response/reason  for consistent access (1 .. N indexes)
local ItemAward = AddOn.Package('Models.Item'):Class('ItemAward')

---
--- An loot allocation entry, associated with an item, which tracks player's responses
---
--- @class Models.Item.LootAllocateEntry
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
	Logging:Debug("AddCandidate(%s)", tostring(player))
	self.candidates[player:GetName()] = LootAllocateResponse(player)
end

---@param name string
---@return Models.Item.LootAllocateResponse
function LootAllocateEntry:GetCandidateResponse(name)
	--Logging:Debug("GetCandidateResponse(%s) : %s", tostring(name), Util.Objects.ToString(self.candidates))
	local lar = self.candidates[name]
	assert(lar, format("No response available for candidate %s", tostring(name)))
	return lar
end

--- @return Models.Item.ItemAward
function LootAllocateEntry:GetItemAward(candidate, reason)
	-- Logging:Debug("%s", Util.Objects.ToString(self.clazz))
	return ItemAward(self, candidate, reason)
end

function LootAllocateEntry:GetReRollData(isRoll, noAutoPass)
	return {
		ref        = AddOn.TransmittableItemString(self.link),
		session    = self.session,
		isRoll     = isRoll,
		noAutoPass = noAutoPass,
	}
end

--- @return Models.Item.LootAllocateEntry
function LootAllocateEntry.FromItemRef(itemRef, session)
	return itemRef:Embed(
			LootAllocateEntry,
			Util.Objects.Check(itemRef.session, itemRef.session, session)
	)
end

--- @param entry Models.Item.LootAllocateEntry
--- @param candidate string
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
	-- Logging:Trace("ItemAward() : Candidate Response (raw) is %s", Util.Objects.ToString(cr and cr:toTable() or {}))

	local awardReason
	-- if reason is provided, it overrides candidate's response
	-- it will be entry from ML's responses table
	-- for example, Award For : Disenchant|Bank|Free
	if reason and Util.Objects.IsTable(reason) then
		awardReason = reason.key
	else
		local response = AddOn:GetResponse(cr.response)
		-- Logging:Trace("ItemAward() : Candidate Response (normalized) %s => %s", tostring(cr.response), Util.Objects.ToString(response))
		awardReason = response.key and response.key or cr.response
	end

	-- Logging:Trace("ItemAward() : Candidate Award Reason is %s", Util.Objects.ToString(awardReason))

	self.session = entry.session
	self.winner = candidate
	self.class = cr.class
	self.gear1 = cr.gear1
	self.gear2 = cr.gear2
	self.link = entry.link
	-- needed for selecting appropriate list
	self.equipLoc = entry:GetEquipmentLocation()
	self.texture = entry.texture
	-- the actual player's response
	self.responseId = cr.response
	-- the reason for the award, if not the player's response
	-- this does not need to be provided
	self.reason = reason
	-- the name (key) of the award reason
	self.awardReason = awardReason

	-- normalize the response/reason divergence for consistent access (1 .. N indexes)
	local r = AddOn:GetResponse(self.responseId)
	self.normalizedReason = {
		id    = self.reason and self.reason.sort - 400 or self.responseId,
		text  = self.reason and self.reason.text or r.text,
		color = self.reason and self.reason.color or r.color
	}
end

--- @return table indicating the attributes associated with the resolved reason for the item award (player response vs award reason)
function ItemAward:NormalizedReason()
	return self.normalizedReason
end