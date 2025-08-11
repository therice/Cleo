--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @type Models.Item.LootAllocateEntry
local LootAllocateEntry = AddOn.Package('Models.Item').LootAllocateEntry
--- @type table
local LAA = AddOn.Package('Models.Item').LootAllocateResponse.Attributes
--- @type Models.Player
local Player = AddOn.ImportPackage('Models').Player
--- @type Models.Item.ItemRef
local ItemRef = AddOn.Package('Models.Item').ItemRef

--- @class LootAllocate
local LA = AddOn:NewModule("LootAllocate", "AceBucket-3.0", "AceEvent-3.0")

LA.defaults = {
	profile = {
		awardReasons = {

		}
	}
}

-- Copy defaults from MasterLooter into our defaults for award reasons
-- This actually should be done via the Addon's DB once it's initialized, but we currently
-- don't allow users to change these values (either here or from MasterLooter) so we can
-- do it before initialization. If we allow for these to be configured by user, then will
-- need to be copied from DB
do
	local ML = AddOn:GetModule("MasterLooter")
	local AwardReasons = LA.defaults.profile.awardReasons
	local NonUserVisibleAwards =
		Util(ML.AwardReasons)
			:CopyFilter(function (v) return not v.user_visible end, true, nil, true)
			:Keys()()

	AwardReasons.numAwardReasons = Util.Tables.Count(NonUserVisibleAwards)
	-- insert them at sort indexes after visible ones, but before ones that are boiler plate
	local sortLevel = 401
	-- award is the name of the key of entry in award_scaling
	for index, award in ipairs(NonUserVisibleAwards) do
		Util.Tables.Insert(AwardReasons, index,
		                   {
			                   color       = ML.AwardReasons[award].color,
			                   sort        = sortLevel,
			                   text        = L[award],
			                   key          = award,
			                   disenchant  = Util.Strings.StartsWith(Util.Strings.Lower(award), 'disenchant')
		                   }
		)
		sortLevel = sortLevel + 1
	end
end

function LA:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.db:RegisterNamespace(self:GetName(), LA.defaults)
	-- trigger an update to allocation window every 1/2 a second
	-- this may not always result in an actual update based upon when it was last refreshed
	self.alarm = AddOn.Alarm(0.5, function() self:Update() end)
	-- stopwatch that tracks how long since last refresh (update) occurred
	self.sw = AddOn.Stopwatch()
end

function LA:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self.session = 1
	--- @type table<number, Models.Item.LootAllocateEntry>
	self.lootTable = {}
	self:GetFrame()
	self.alarm:Enable()
	self:SubscribeToComms()
	self:RegisterMessage(C.Messages.LootTableAddition, "OnLootTableAddReceived")
	self:RegisterBucketEvent({"UNIT_PHASE", "ZONE_CHANGED_NEW_AREA"}, 1, "Update")
end

function LA:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self.session = 1
	-- intentionally don't wipe loot table on disable
	-- as the UI may still be visible and doing so will make it unusable
	-- wipe(self.lootTable)
	self.alarm:Disable()
	self:UnregisterAllMessages()
	self:UnregisterAllBuckets()
	self:UnsubscribeFromComms()
end

function LA:EnableOnStartup()
	return false
end

function LA:EndSession(hide)
	Logging:Debug("EndSession(%s) : enabled=%s", tostring(hide), tostring(self:IsEnabled()))
	if self:IsEnabled() then
		self:Update(true)
		self:Disable()
	end

	if hide then self:Hide() end
end

--- @param session number
--- @param entry Models.Item.LootAllocateEntry
function LA:SetupSession(session, entry)
	Logging:Debug("SetupSession(%d)", session)
	entry.added = true
	for name in AddOn:GroupIterator() do
		local player = Player:Get(name)
		entry:AddCandidate(player)
	end

	-- Init session toggle
	self.sessionButtons[session] = self:UpdateSessionButton(session, entry.texture, entry.link, entry.awarded)
	self.sessionButtons[session]:Show()
end

function LA:Setup(entries)
	Logging:Debug("Setup(%d)", #entries)
	for session, entry in pairs(entries) do
		if not entry.added then
			self:SetupSession(session, entry)
		end
	end

	-- Hide unused session buttons
	for i = #self.lootTable + 1, #self.sessionButtons do
		self.sessionButtons[i]:Hide()
	end

	self.session = 1
	self:BuildScrollingTable()
	self:SwitchSession(self.session)

	if AddOn:IsMasterLooter() and AddOn:MasterLooterModule():GetDbValue('autoAddRolls') then
		self:DoAllRandomRolls()
	end
end

---@param lt table<number, Models.Item.ItemRef>
function LA:ReceiveLootTable(lt)
	Logging:Debug("ReceiveLootTable(START, %d) :", #lt)
	self.lootTable =
		Util(lt):Copy()
			:Map(
				function(ir, session)
					Logging:Trace("ReceiveLootTable() : session=%d, data=%s", session, Util.Objects.ToString(ir.toTable and ir:toTable() or ir))
					return LootAllocateEntry.FromItemRef(ir, session)
				end, true
		)()

	self:Setup(self.lootTable)
	if not AddOn.enabled then
		return
	end

	self:Show()
	Logging:Debug("ReceiveLootTable(END, %d) :", #self.lootTable)
end

function LA:NextUnawardedSession()
	for session, entry in pairs(self.lootTable) do
		if not entry.awarded then return session end
	end
	return nil
end

function LA:HaveUnawardedItems()
	for _,v in pairs(self.lootTable) do
		if not v.awarded then return true end
	end
	return false
end

function LA:HaveLootTable()
	return self.lootTable and next(self.lootTable) ~= nil
end


--- @return Models.Item.LootAllocateEntry
function LA:GetEntry(session)
	session = tonumber(session)
	assert(session, format("no session provided %s", tostring(session)))
	return self.lootTable[session]
end

--- @return Models.Item.LootAllocateEntry
function LA:CurrentEntry()
	return self:GetEntry(self.session)
end

---@return Models.Item.LootAllocateResponse
function LA:GetCandidateResponse(session, candidate)
	--Logging:Debug("GetCandidateResponse(%d, %s)", tonumber(session), tostring(candidate))
	local response = self:GetEntry(session):GetCandidateResponse(candidate)
	if not response then
		error(format("no loot allocation entry available for session %d, candidate %s", session, candidate))
	end
	return response
end

--- @param session number
--- @param candidate string
--- @param key any
--- @param value any
function LA:SetCandidateData(session, candidate, key, value)
	--Logging:Trace("SetCandidateData(%s, %s) : %s => %s", tostring(session), tostring(candidate), tostring(key), Util.Objects.ToString(value))
	---@param self LootAllocate
	local function Set(self, session, candidate, key, value)
		self:GetCandidateResponse(session, candidate):Set(key, value)
	end
	local success, result = pcall(Set, self, session, candidate, key, value)
	if not success then
		Logging:Warn("SetCandidateData(%d, %s) : %s", tonumber(session), tostring(candidate), result)
	end
end

--- @param session number
--- @param candidate string
--- @param key any
function LA:GetCandidateData(session, candidate, key)
	---@param self LootAllocate
	local function Get(self, sesion, candidate, key)
		return self:GetCandidateResponse(sesion, candidate):Get(key)
	end
	local success, result = pcall(Get, self, session, candidate, key)
	if not success then
		Logging:Warn("GetCandidateData(%d, %s) : %s", tonumber(session), tostring(candidate), result)
	end
	return result
end

--- @param session number the session id (if nil, will use current one)
--- @param candidate string the candidate name
--- @param reason table representing reason for which being awarded (if not player's response), e.g. 'Award For' in UI
--- @return Models.Item.ItemAward
function LA:GetItemAward(session, candidate, reason)
	session = Util.Objects.Default(session, self.session)
	return self:GetEntry(session):GetItemAward(candidate, reason)
end

--- Generate a 'count' number of rolls ranged from 1 to 100  and guarantee each roll is different
--- @param count number the number of rolls to generate (max 100)
--- @return table<number, number> roll number to roll value
function LA:GenerateNoRepeatRollTable(count)
	assert(count <= 100, "cannot generate more than 100 rolls at a time")

	local rolls = {}
	for i = 1, 100 do
		rolls[i] = i
	end

	local t = {}
	for i = 1, count do
		if #rolls > 0 then
			local roll = tremove(rolls, math.random(#rolls))
			t[i] = roll
		end
	end

	Logging:Debug("GenerateNoRepeatRollTable(%d) : %s", count, Util.Objects.ToString(t))
	return t
end

function LA:DoRandomRolls(session)
	session = Util.Objects.Default(session, self.session)
	local rolls = self:GenerateNoRepeatRollTable(AddOn:GroupMemberCount())
	for k, v in pairs(self.lootTable) do
		if AddOn.ItemIsItem(self:GetEntry(session).link, v.link) then
			AddOn:Send(AddOn.masterLooter, C.Commands.Rolls, k, rolls)
		end
	end
end

function LA:DoAllRandomRolls()
	local sessionsDone, rollCount = {}, AddOn:GroupMemberCount()

	for session, entry in pairs(self.lootTable) do
		-- Don't use auto rolls on a session requesting rolls from raid members
		if not sessionsDone[session] and not entry.isRoll then
			local rolls = self:GenerateNoRepeatRollTable(rollCount)
			for session2, entry2 in ipairs(self.lootTable) do
				if AddOn.ItemIsItem(entry.link, entry2.link) then
					sessionsDone[session2] = true
					AddOn:Send(AddOn.masterLooter, C.Commands.Rolls, session2, rolls)
				end
			end
		end
	end
end

function LA:AnnounceResponse(session, candidate)
	if AddOn:IsMasterLooter() then
		local ML = AddOn:MasterLooterModule()
		if ML:GetDbValue('announceResponses') then
			local candidateResponse = self:GetCandidateResponse(session, candidate)
			if candidateResponse and tonumber(candidateResponse.response) ~= nil then
				local entry = self:GetEntry(session)
				local response = AddOn:GetResponse(candidateResponse.response)
				local announceSettings = ML:GetDbValue('announceResponseText')
				local channel, announcement = announceSettings.channel, announceSettings.text

				-- "&p specified &r for &i (&ln - &lp)
				for repl, fn in pairs(ML.AwardStrings) do
					announcement =
						gsub(announcement, repl,
						     escapePatternSymbols(
								tostring(fn(candidate, ItemRef(entry.link):GetItem(), response.text, nil, session))
						     )
						)
				end
				AddOn:SendAnnouncement(announcement, channel)
			end
		end
	end
end

--- @param namePredicate boolean|string|function  determines what candidate should be re-announced. true to re-announce to all candidates. string for specific candidate.
--- @param sessionPredicate boolean|number|function determines what session should be re-announced. true to re-announce to all candidates. number k to re-announce to session k and other sessions with the same item as session k.
--- @param isRoll boolean determines whether we are requesting rolls. true will request rolls and clear the current rolls.
--- @param noAutoPass boolean determines whether we force no auto-pass
function LA:SolicitResponse(namePredicate, sessionPredicate, isRoll, noAutoPass)
	--- @type table<number, table<string, any>>
	local reRollTable = {}

	for session, entry in pairs(self.lootTable) do
		local rolls = {}
		if sessionPredicate == true or
			(Util.Objects.IsNumber(sessionPredicate) and AddOn.ItemIsItem(entry.link, self.lootTable[sessionPredicate].link)) or
			(Util.Objects.IsFunction(sessionPredicate) and sessionPredicate(session)) then

			Logging:Trace("SolicitResponse() : %s", Util.Objects.ToString(entry:toTable()))

			Util.Tables.Push(reRollTable, entry:GetReRollData(isRoll, noAutoPass))

			for name, _ in pairs(entry.candidates) do
				if namePredicate == true or
					(Util.Objects.IsString(namePredicate) and name == namePredicate) or
					(Util.Objects.IsFunction(namePredicate) and namePredicate(name)) then
					if not isRoll then
						AddOn:Send(C.group, C.Commands.ChangeResponse, session, name, C.Responses.Wait)
					end
					rolls[name] = ""
				end
			end
		end

		if isRoll then
			AddOn:Send(C.group, C.Commands.Rolls, session, rolls)
		end
	end

	if #reRollTable > 0 then
		AddOn:MasterLooterModule():AnnounceItems(reRollTable)

		if namePredicate == true then
			AddOn:Send(C.group, C.Commands.ReRoll, reRollTable)
		else
			for name, _ in pairs(self:GetEntry(self.session).candidates) do
				if (Util.Objects.IsString(namePredicate) and name == namePredicate) or
					(Util.Objects.IsFunction(namePredicate) and namePredicate(name)) then
					AddOn:Send(Player:Get(name), C.Commands.ReRoll, reRollTable)
				end
			end
		end
	end
end

function LA:OnLootAckReceived(candidate, ilvl, sessionData)
	--[[
	sessionData will be of the following format, where session key/value pairs have the session id as the key
		{
			response = { session = value, ... },
			diff = { session = value, ...},
			gear1 = { session = value, ...},
			gear2 = { session = value, ...},
		}

	E.G. { response = { 4 = false }, diff = { 4 = 127 }, gear1 = { 4 = '51::::::::2' }, gear2 = { } }
	--]]
	--- set current candidate data to what was in the response's session data
	for key, values in pairs(sessionData) do
		for session, value in pairs(values) do
			if Util.Objects.In(key, LAA.Gear1, LAA.Gear2) then
				self:SetCandidateData(session, candidate, key, AddOn.DeSanitizeItemString(value))
			-- handle response differently due to it's value being overloaded
			elseif Util.Objects.Equals(key, LAA.Response) then
				local current = self:GetCandidateData(session, candidate, LAA.Response)
				-- only replace previous response in situation where it was a boolean or not set
				if Util.Objects.IsNil(current) or Util.Objects.IsBoolean(current) then
					self:SetCandidateData(session, candidate, key, value)
				end
			else
				self:SetCandidateData(session, candidate, key, value)
			end
		end
	end

	-- iterate all current sessions
	for session = 1, #self.lootTable do
		self:SetCandidateData(session, candidate, LAA.Ilvl, ilvl)
		local sessionResponse = sessionData.response[session]
		-- if not data included in the user's response for the session
		-- this will be the case for no response for a session or value of 'false'
		if not sessionResponse then
			-- grab previous response (if present)
			local response = self:GetCandidateData(session, candidate, LAA.Response)
			if Util.Strings.Equal(response, C.Responses.Announced) then
				self:SetCandidateData(session, candidate, LAA.Response, C.Responses.Wait)
			end
		-- this is an auto-pass
		elseif sessionResponse == true then
			self:SetCandidateData(session, candidate, LAA.Response, C.Responses.AutoPass)
		end
	end

	self:Update()
end

function LA:OnResponseReceived(session, candidate, data)
	Logging:Debug("OnResponseReceived(%s, %d) : %s", tostring(candidate), tonumber(session), Util.Objects.ToString(data))
	for key, val in pairs(data) do
		self:SetCandidateData(session, candidate, key, val)
	end

	self:Update()

	-- Announce the response, this is relevant when run via Master Looter
	self:AnnounceResponse(session, candidate)
end

function LA:OnChangeResponseReceived(session, candidate, response)
	Logging:Debug("OnChangeResponseReceived(%s, %d)", tostring(candidate), tonumber(session))
	self:SetCandidateData(session, candidate, LAA.Response, response)
	self:Update()
end

function LA:OnLootTableAddReceived(_, lt)
	Logging:Debug("OnLootTableAddReceived(%d) : %d", Util.Tables.Count(lt), #self.lootTable)
	local oldLen = #self.lootTable
	for session, entry in pairs(lt) do
		--Logging:Trace("OnLootTableAddReceived() : adding %s to loot table at index %d", Util.Objects.ToString(entry:toTable()), session)
		self.lootTable[session] = LootAllocateEntry.FromItemRef(entry, session)
	end

	for session = oldLen + 1, #self.lootTable do
		self:SetupSession(session, self.lootTable[session])
		if AddOn:IsMasterLooter() and AddOn:MasterLooterModule():GetDbValue('autoAddRolls') then
			self:DoRandomRolls(session)
		end
	end

	self:SwitchSession(self.session)
end

function LA:OnAwarded(session, winner, ...)
	local entry = self:GetEntry(session)
	if not entry then
		Logging:Warn("OnAwarded() : no entry for session %d", session)
		return
	end

	local oldWinner = entry.awarded
	for session2, entry2 in ipairs(self.lootTable) do
		if AddOn.ItemIsItem(entry2.link, entry.link) then
			if oldWinner and not AddOn.UnitIsUnit(oldWinner, winner) then
				self:SetCandidateData(session2, oldWinner, LAA.Response, self:GetCandidateData(session2, oldWinner, LAA.ResponseActual))
			end
			self:SetCandidateData(session2, winner, LAA.ResponseActual, self:GetCandidateData(session2, winner, LAA.Response))
			self:SetCandidateData(session2, winner, LAA.Response, C.Responses.Awarded)
		end
	end

	entry.awarded = winner

	local nextSession = self:NextUnawardedSession()
	if AddOn:IsMasterLooter() and nextSession then
		self:SwitchSession(nextSession)
	else
		self:SwitchSession(self.session)
	end
end

function LA:OnLootedToBags(session, ...)
	local entry = self:GetEntry(session)
	if not entry then
		Logging:Warn("OnLootedToBags() : no entry for session %d", session)
		return
	end

	if AddOn:IsMasterLooter() and (session ~= Util.Tables.Count(self.lootTable)) then
		self:SwitchSession(session + 1)
	else
		self:SwitchSession(session)
	end
end

function LA:OnCheckIfOfflineReceived()
	Logging:Trace("OnCheckIfOfflineReceived()")
	local response
	for session = 1, #self.lootTable do
		for candidate in pairs(self:GetEntry(session).candidates) do
			response = self:GetCandidateData(session, candidate, LAA.Response)
			-- Logging:Debug("OnCheckIfOfflineReceived(%d, %s) :  %s", tostring(session), tostring(candidate), tostring(response))
			-- don't include WAIT, as that is the response used when loot has been acknowledged
			if Util.Objects.In(response, C.Responses.Announced) then
				self:SetCandidateData(session, candidate, LAA.Response, C.Responses.Nothing)
			end
		end
	end
	self:Update()
end

--- @see LootAllocate#GenerateNoRepeatRollTable
--- @param session number the session to which rolls are bound
--- @param rolls table<number, number> roll number to roll value
function LA:OnRollsReceived(session, rolls)
	Logging:Debug("OnRollsReceived(%d) : %s", session, Util.Objects.ToString(rolls))

	local candidates = {}
	for name, _ in pairs(self:GetEntry(session).candidates) do
		tinsert(candidates, name)
	end

	Util.Tables.Sort(candidates, function(c1, c2) return c1 > c2  end)

	for _, roll in pairs(rolls) do
		local candidate = tremove(candidates)
		if not candidate then
			break
		end

		self:SetCandidateData(session, candidate, LAA.Roll, roll)
	end
end

function LA:OnRollReceived(candidate, roll, sessions)
	for _, session in ipairs(sessions) do
		self:SetCandidateData(session, candidate, LAA.Roll, roll)
		self:UpdateIfSession(session)
	end
end

function LA:SubscribeToComms()
	-- FYI, these comms will implicitly only be subscribed when a player is the Master Looter
	-- as the Loot Allocate module is never enabled outside of that use case
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	-- LootTableAdd is handled through message hook in initializer
	self.commSubscriptions = Comm():BulkSubscribe(C.CommPrefixes.Main, {
		[C.Commands.LootAck] = function(data, sender)
			Logging:Debug("LootAck received from %s", tostring(sender))
			self:OnLootAckReceived(sender, unpack(data))
		end,
		[C.Commands.Response] = function(data, sender)
			Logging:Debug("Response received from %s", tostring(sender))
			self:OnResponseReceived(unpack(data))
		end,
		[C.Commands.ChangeResponse] = function(data, sender)
			Logging:Debug("ChangeResponse received from %s", tostring(sender))
			if AddOn:IsMasterLooter(sender) then
				self:OnChangeResponseReceived(unpack(data))
			end
		end,
		[C.Commands.Awarded] = function(data, sender)
			Logging:Debug("Awarded received from %s", tostring(sender))
			if AddOn:IsMasterLooter(sender) then
				self:OnAwarded(unpack(data))
			end
		end,
		[C.Commands.LootedToBags] = function(data, sender)
			Logging:Debug("LootedToBags received from %s", tostring(sender))
			if AddOn:IsMasterLooter(sender) then
				self:OnLootedToBags(unpack(data))
			end
		end,
		[C.Commands.CheckIfOffline] = function(_, sender)
			Logging:Debug("CheckIfOffline received from %s", tostring(sender))
			if AddOn:IsMasterLooter(sender) then
				self:OnCheckIfOfflineReceived()
			end
		end,
		[C.Commands.Rolls] = function(data, sender)
			Logging:Debug("Rolls received from %s", tostring(sender))
			if AddOn:IsMasterLooter(sender) then
				self:OnRollsReceived(unpack(data))
			end
		end,
		[C.Commands.Roll] = function(data, sender)
			Logging:Debug("Rolls received from %s -> %s", tostring(sender), Util.Objects.ToString(data))
			self:OnRollReceived(unpack(data))
		end,
	})
end

function LA:UnsubscribeFromComms()
	Logging:Debug("UnsubscribeFromComms(%s)", self:GetName())
	AddOn.Unsubscribe(self.commSubscriptions)
	self.commSubscriptions = nil
end
