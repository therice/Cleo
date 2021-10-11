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

--- @class Models.Item.LootSlotInfo
local LootSlotInfo = AddOn.Package('Models.Item'):Class('LootSlotInfo', ItemRef)
function LootSlotInfo:initialize(slot, name, link, quantity, quality, bossGuid, bossName)
	-- links work as item references
	ItemRef.initialize(self, link)
	self.slot = slot
	self.name = name
	self.quantity = quantity
	self.quality = quality
	self.bossGuid = bossGuid
	self.bossName = bossName
	self.looted = false
end

--- @return string the full item link
function LootSlotInfo:GetItemLink()
	return self.item
end

--- @class Models.Item.LootTableEntry
local LootTableEntry = AddOn.Package('Models.Item'):Class('LootTableEntry', ItemRef)
function LootTableEntry:initialize(slot, item)
	ItemRef.initialize(self, item)
	self.slot    = slot
	self.awarded = false
	self.sent    = false
	Logging:Debug("LootTableEntry : %s", Util.Objects.ToString(self:toTable()))
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

--- @class Models.Item.LootQueueEntry
local LootQueueEntry = AddOn.Package('Models.Item'):Class('LootQueueEntry')
function LootQueueEntry:initialize(slot, callback, args)
	self.slot = slot
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


--- used for presenting items to a player through the Loot interface
--- @class Models.Item.LootEntry
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


--- @class Models.Item.LootAllocateResponse
local LootAllocateResponse = AddOn.Package('Models.Item'):Class('LootAllocateResponse')
--- @type table
LootAllocateResponse.Attributes = {
	Ilvl            =   "ilvl",
	Response        =   "response",         -- tracks the player's response to an item
	ResponseActual  =   "response_actual",  -- when an item is awarded, this is the original response (otherwise, unset)
	Roll            =   "roll",
}

function LootAllocateResponse:initialize(player)
	self.name      = player:GetName()
	self.class     = player.class or "Unknown"
	self.guildRank = player.guildRank or "Unknown"
	self.response  = C.Responses.Announced
	self.ilvl      = 0
	self.diff      = 0
	self.gear1     = nil
	self.gear2     = nil
	self.roll      = nil
end

function LootAllocateResponse:Set(key, value) self[key] = value end

function LootAllocateResponse:Get(key) return self[key] end

---@class Models.Item.ItemAward
local ItemAward = AddOn.Package('Models.Item'):Class('ItemAward')
--- @class Models.Item.LootAllocateEntry
local LootAllocateEntry = AddOn.Package('Models.Item'):Class('LootAllocateEntry', Item)
function LootAllocateEntry:initialize(session)
	Item.initialize(self)
	self.session = session
	self.added = false
	-- initialized as boolean indicating not awarded, but once awarded
	-- will be changed to winner's name
	self.awarded = false
	--- @type table<string, Models.Item.LootAllocateResponse>
	self.candidates = {}
end

---@param player Models.Player
function LootAllocateEntry:AddCandidate(player)
	self.candidates[player:GetName()] = LootAllocateResponse(player)
end

---@param name string
---@return Models.Item.LootAllocateResponse
function LootAllocateEntry:GetCandidateResponse(name)
	return self.candidates[name]
end

--- @return Models.Item.ItemAward
function LootAllocateEntry:GetItemAward(candidate, reason)
	Logging:Debug("%s", Util.Objects.ToString(self.clazz))
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
	return itemRef:Embed(LootAllocateEntry, Util.Objects.Check(itemRef.session, itemRef.session, session))
end

--- @param entry Models.Item.LootAllocateEntry
--- @param candidate string
--- @param reason string|table if award is for a reason other than candidates' response, this will be provided
function ItemAward:initialize(entry, candidate, reason)
	if not entry or not Util.Objects.IsInstanceOf(entry, LootAllocateEntry) --[[entry:isInstanceOf(LootAllocateEntry)--]] then
		Logging:Warn("%s", tostring(entry))
		error("the provided 'entry' instance was not of type LootAllocateEntry : " .. type(entry))
	end

	--[[
	Examples of response/reason permutations

	Candidate responded with MS/Need, but awarded for 'Bank'
		{ responseId = 1, reason = { color = {...}, text = 'Bank', sort = 403, award_scale = 'bank', ...}, awardReason = 'bank', ...

	Candidate responded with MS/Need and awarded for that reason
		{ responseId = 1, reason = nil, awardReason = 'ms_need', ...
	--]]
	local cr = entry:GetCandidateResponse(candidate)
	local awardReason, baseGp, awardGp = nil, nil, nil
	-- if reason is provided, it overrides candidate's response
	-- it will be entry from ML's responses table
	--
	-- award_scale is the name of the entry in
	-- the GearPoints module's award_scaling table
	if reason and Util.Objects.IsTable(reason) then
		awardReason = reason.award_scale
	else
		awardReason = AddOn:GetResponse(cr.response).award_scale
	end

	baseGp, awardGp = entry:GetGp(awardReason)

	self.session = entry.session
	self.winner = candidate
	self.class = cr.class
	self.gear1 = cr.gear1
	self.gear2 = cr.gear2
	self.link = entry.link
	-- the actual player's response
	self.responseId = cr.response
	-- the reason for the award, if not the player's response
	-- this does not need to be provided
	self.reason = reason
	self.texture = entry.texture

	-- normalize the response/reason divergence for consistent access
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