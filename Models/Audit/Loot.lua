	--- @type AddOn
local _, AddOn = ...
local L = AddOn.Locale
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Package
local AuditPkg = AddOn.ImportPackage('Models.Audit')
--- @type Models.Date
local Date = AddOn.ImportPackage('Models').Date
--- @type Models.Player
local Player = AddOn.Package('Models').Player
--- @type Models.Audit.Audit
local Audit = AuditPkg.Audit
--- @type Models.Item.ItemAward
local ItemAward =  AddOn.ImportPackage('Models.Item').ItemAward

--- @class Models.Audit.LootRecord : Models.Audit.Audit
--- @field item string link to the awarded item
--- @field owner string who received the item
--- @field class string the class of the winner
--- @field instanceId number identifier for map (instance id)
--- @field encounterId number identifier for the encounter
--- @field responseOrigin number indicates if response was from an award reason (e.g. not from candidate's response)
--- @field response string the text of the candidate's response or award reason
--- @field responseId string|number the id of the candidate's response or award reason
--- @field configuration string  the list configuration name associated with award
--- @field list string the list name associated with award
local LootRecord = AuditPkg:Class('LootRecord', Audit)

function LootRecord:initialize(instant)
	Audit.initialize(self, instant)
	-- link to the awarded item
	self.item = nil
	-- who received the item (don't capture player guid because they could "disappear")
	self.owner = nil
	-- the class of the winner
	self.class = nil
	-- identifier for map (instance id)
	self.instanceId = nil
	-- identifier for the encounter
	self.encounterId = nil
	-- number indicating if response was taken from award reason or  candidate's response
	self.responseOrigin = 0
	-- the text of the candidate's response or award reason
	self.response = nil
	-- the id of the candidate's response or award reason
	self.responseId = nil
	-- the list configuration name associated with award
	self.configuration = nil
	-- the list name associated with award
	self.list = nil
end

--- @return boolean indicating whether loot was awarded based upon the candidate's response  (e.g. 'need')
function LootRecord:IsCandidateResponse()
	return self.responseOrigin == ItemAward.Origin.Response
end

--- @return boolean indicating whether loot was awarded for a 'reason' other than specified in candidate's response (e.g. 'free')
function LootRecord:IsAwardReason()
	return self.responseOrigin == ItemAward.Origin.Reaspm
end

function LootRecord:GetResponseId()
	local responseId
	if self:IsCandidateResponse() then
		responseId = self.responseId
	else
		-- see LootAllocate for the addition of 400 (as needed, there is a bug via the auto award path I need to track down)
		if self.responseId < 400 then
			responseId = self.responseId + 400
		else
			responseId = self.responseId
		end
	end

	return responseId
end

--- @param itemAward Models.Item.ItemAward
--- @return Models.Audit.LootRecord
function LootRecord.FromItemAward(itemAward)
	local loot = LootRecord()
	loot.item = itemAward.link
	loot.owner = itemAward.winner
	loot.class = itemAward.class
	loot.responseOrigin = itemAward.origin
	local nr = itemAward:NormalizedReason()
	loot.response = nr.text
	loot.responseId = nr.id

	-- this should have been populated via AddOn:EncounterEnd()
	if AddOn.encounter then
		loot.instanceId = AddOn.encounter.instanceId
		loot.encounterId = AddOn.encounter.id
	end

	-- will not have config or list populated
	return loot
end

--- @param item string the item link
--- @param winner string the winner of the item (player)
--- @param reason table the reason for the award
--- @return Models.Audit.LootRecord
function LootRecord.FromAutoAward(item, winner, reason)
	local record = LootRecord()
	record.item = item
	local p = Player:Get(winner)
	record.owner = p and p:GetShortName()
	record.class = p and p.class
	record.responseOrigin = ItemAward.Origin.Reason
	record.response = reason.text
	-- see ItemAward constructor for subtraction of 400
	record.responseId = reason.sort - 400

	if AddOn.encounter then
		record.instanceId = AddOn.encounter.instanceId
		record.encounterId = AddOn.encounter.id
	end

	return record
end

--- @class Models.Audit.LootStatistics
local LootStatistics = AuditPkg:Class('LootStatistics')
--- @class Models.Audit.LootStatisticsEntry
local LootStatisticsEntry = AuditPkg:Class('LootStatisticsEntry')

function LootStatistics:initialize()
	-- mapping from character name to associated stats
	self.entries = {}
end

function LootStatistics:Get(name)
	return self.entries[name]
end

function LootStatistics:GetOrAdd(name)
	local entry
	if not Util.Tables.ContainsKey(self.entries, name) then
		entry = LootStatisticsEntry()
		self.entries[name] = entry
	else
		entry = self.entries[name]
	end
	return entry
end

--- @param name string the character's name
--- @param entry Models.Audit.LootRecord loot history entry
--- @param entryIndex number index of entry in the loot history
function LootStatistics:ProcessEntry(name, entry, entryIndex)
	-- force entry into class instance
	if not Util.Objects.IsInstanceOf(entry, LootRecord) then
		entry = LootRecord:reconstitute(entry)
	end

	-- Logging:Debug("ProcessEntry(%s) : %d => %s", name, entryIndex, Util.Objects.ToString(entry, 2))
	local currentTs = Date()
	local id = entry:GetResponseId()

	-- track the response
	local statEntry = self:GetOrAdd(name)
	-- Logging:Debug("ProcessEntry(%s) : AddResponse(%d, %d)", name, id, entryIndex)
	statEntry:AddResponse(
			id,
			entry.response,
			entryIndex
	)

	-- track the award (only numeric responses - ones that were presented to players)
	if Util.Objects.IsNumber(id) and not entry:IsAwardReason() then
		-- Logging:Debug("ProcessEntry(%s) : AddAward(%d, %s)", name, entryIndex, entry.item)
		local ts = entry:TimestampAsDate()
		statEntry:AddAward(
				entry.item,
				format(L["n_ago"], AddOn.ConvertIntervalToString(currentTs:diff(ts):Duration())),
				entryIndex
		)
	end

	-- Logging:Debug("ProcessEntry(%s) : %s", name,  entry.instance)
	statEntry:AddRaid(entry)
	return entry
end

function LootStatisticsEntry:initialize()
	-- array of awarded items
	self.awards = {}
	-- map of response id to array of responses
	self.responses = {}
	-- array of raids (with true as value place holder)
	self.raids = {}

	self.totals = {
		responses = {

		},
		raids = {

		}
	}
	self.totalled = false
end

function LootStatisticsEntry:AddRaid(entry)
	local instanceId = entry.instanceId
	-- not all awards will be from a raid
	if instanceId then
		if not self.raids[instanceId] then
			self.raids[instanceId] = {}
		end

		-- consider combination of instance id and date as a raid occurrence
		-- fuzzy as could be in the same raid across a change in day, but close enough
		if not Util.Tables.ContainsValue(self.raids[instanceId], entry:FormattedDate()) then
			Util.Tables.Push(self.raids[instanceId], entry:FormattedDate())
		end

		self.totalled = false
	end
end

function LootStatisticsEntry:AddResponse(id, response, historyIndex)
	if not Util.Tables.ContainsKey(self.responses, id) then
		self.responses[id] = {}
	end

	Util.Tables.Push(self.responses[id], { response, historyIndex })
	self.totalled = false
end

function LootStatisticsEntry:AddAward(item, intervalText, historyIndex)
	Util.Tables.Push(self.awards, {item, intervalText, historyIndex})
	self.totalled = false
end

function LootStatisticsEntry:CalculatePending()
	return not self.totalled and
		(Util.Tables.Count(self.awards) > 0 or Util.Tables.Count(self.responses) > 0 or Util.Tables.Count(self.raids) > 0)
end

function LootStatisticsEntry:CalculateTotals()
	if self:CalculatePending() then
		-- the responses and number of responses
		for responseId, responses in pairs(self.responses) do
			local first = responses[1]
			local responseText = first[1]
			local count = Util.Tables.Count(responses)

			Util.Tables.Push(self.totals.responses, {responseText, count, responseId})
		end

		self.totals.count = Util.Tables.CountFn(
				self.responses,
				function(r)
					return Util.Tables.Count(r)
				end
		)

		local totalRaids = 0
		for raid, dates in pairs(self.raids) do
			local raidCount = Util.Tables.Count(dates)
			self.totals.raids[raid] = raidCount
			totalRaids = totalRaids + raidCount
		end

		self.totals.raids.count = totalRaids
		self.totalled = true
	end

	--[[
	{
		raids = {
			409 = 1,
			249 = 2,
			469 = 5,
			531 = 2
			count = 10,
		},
		responses = {
			{'Main-Spec (Need)', 6, 1},
			{'Off-Spec (Greed)', 1, 2},
			{'Disenchant', 3, 401},
			{'Free', 2, 402},
			{'Bank', 2, 403}
		},
		count = 14
	}
	--]]
	return self.totals
end

function LootStatisticsEntry:GetTotals()
	return self:CalculateTotals()
end