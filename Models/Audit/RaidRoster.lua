--- @type AddOn
local _, AddOn = ...
local L = AddOn.Locale
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Package
local AuditPkg = AddOn.ImportPackage('Models.Audit')
--- @type Models.Date
local Date = AddOn.ImportPackage('Models').Date
--- @type Models.DateFormat
local DateFormat = AddOn.ImportPackage('Models').DateFormat
--- @type Models.Player
local Player = AddOn.Package('Models').Player
--- @type LibEncounter
local LibEncounter = AddOn:GetLibrary("Encounter")
--- @type Models.Audit.Audit
local Audit = AuditPkg.Audit

--- @class Models.Audit.RaidRosterRecord : Models.Audit.Audit
local RaidRosterRecord = AuditPkg:Class('RaidRosterRecord', Audit)

function RaidRosterRecord:initialize(instant)
	Audit.initialize(self, instant)
	self.instanceId = nil
	self.encounterId = nil
	self.encounterName = nil
	self.encounterDifficultyId = nil
	self.groupSize = nil
	self.success = nil
	-- a table of tables, with class id and player name (short)
	-- e.g. {{1, 'Player1'}, {11, 'Player2'}, ...}
	self.players = nil
	-- a table of class id and player name (short)
	-- e.g. {11, 'Player13'}
	self.actor = nil
end

function RaidRosterRecord:GetInstanceName()
	return LibEncounter:GetMapName(self.instanceId) or "N/A"
end

function RaidRosterRecord:GetEncounterName()
	local encounter = AddOn.GetEncounterCreatures(self.encounterId)
	if Util.Strings.IsEmpty(encounter) then
		if not Util.Strings.IsEmpty(self.encounterName) then
			encounter = self.encounterName
		else
			encounter = L['N/A']
		end
	end
	return encounter
end

function RaidRosterRecord:GetDifficultyName()
	local name = GetDifficultyInfo(self.encounterDifficultyId)
	return name
end

--- @param encounter Models.Encounter
function RaidRosterRecord.For(encounter)
	local roster = RaidRosterRecord()

	if AddOn.player then
		roster.actor = {AddOn.player:GetClassId(), AddOn.player:GetShortName()}
	end

	if encounter then
		roster.instanceId = encounter.instanceId
		roster.encounterId = encounter.id
		roster.encounterName = encounter.name
		roster.encounterDifficultyId = encounter.difficultyId
		roster.groupSize = encounter.groupSize
		roster.success = encounter:IsSuccess():orElse(nil)
	end

	if IsInRaid() then
		roster.players = {}
		--- @type table<string, Models.Player>
		local players = AddOn:Players(true, false, true)
		for _, player in pairs(players) do
			if Util.Objects.IsSet(player) and not Player.IsUnknown(player) then
				Util.Tables.Push(roster.players, {player:GetClassId(), player:GetShortName()})
			end
		end
	end

	return roster
end

--- @class Models.Audit.RaidAttendanceStatistics
local RaidAttendanceStatistics = AuditPkg:Class('RaidAttendanceStatistics')
function RaidAttendanceStatistics:initialize()
	--- mapping form instance id to dates on which raids occurred
	--- @type table<number, table<string>>
	self.raids = {}
	--- @type table<string, table<number, table<string>>>
	self.players = {}
end

--- @param intervalInDays number number of days in past from which to perform calculation (can be nil)
--- @return table<string, number> table of player name to % of raids attended
function RaidAttendanceStatistics:GetTotals(intervalInDays)
	intervalInDays = tonumber(intervalInDays) or nil

	--- go through the raids and collect the ones and occurrences that are within the requested window
	local cutoff
	if intervalInDays then
		cutoff = Date()
		cutoff:add{day = -intervalInDays}
	end

	--- @type table table<number, table<string>>
	local raids = Util.Tables.Copy(
		self.raids,
		function(dates)
			local filtered = {}
			if cutoff then
				for _, date in pairs(dates) do
					local ts = Audit.ShortDf:parse(date)
					if ts >= cutoff then
						Util.Tables.Push(filtered, date)
					end
				end
			else
				filtered = Util.Tables.Copy(dates)
			end

			return filtered
		end
	)

	--- now go through players and retain raids and attendance that are within the window
	local players = Util.Tables.Copy(
		self.players,
		function(praids)
			local filtered = {}
			for raid, dates in pairs(praids) do
				if Util.Tables.ContainsKey(raids, raid) then
					filtered[raid] = Util.Tables.CopyWhere(dates, false, unpack(raids[raid]))
				end
			end

			return filtered
		end
	)

	local countByRaid = Util.Tables.Map(raids, function(dates) return Util.Tables.Count(dates) end)
	local totalRaids = Util.Tables.Sum(countByRaid)

	local stats = {
		total = totalRaids,
		players = {

		}
	}

	-- e.g.
	--[[
		{
			total = 4,
			players = {
				Avalona = {
					pct = 1,
					count = 4,
					lastRaid = 1665770400
				},
				...
			}
			Avalona = 1,
			Kerridwen = 1,
			Rayne = 0.75, ...
			Iske = 1
		}
	--]]

	for player, praids in pairs(players) do

		local allRaidDates =
			Util.Tables.Map(
				Util.Tables.Flatten(Util.Tables.Values(Util.Tables.Values(self.players[player]))),
				function(d) return Audit.ShortDf:parse(d).time end
			)
		local raidCount = Util.Tables.Count(Util.Tables.Flatten(Util.Tables.Values(praids)))
		local pct = Util.Numbers.Round2(raidCount / totalRaids, 2)
		pct = Util.Objects.Check(tostring(pct) == "-nan", 0, pct)

		stats.players[player] = {
			count = raidCount or 0,
			pct =  pct,
			lastRaid = Util.Tables.Max(allRaidDates),
		}
	end

	return stats
end

--- @param record Models.Audit.RaidRosterRecord
--- @param playerMappingFn  function<string> yields the name of passed player (string) to 'main' as/if needed
function RaidAttendanceStatistics:_AddRaidIfNotPresent(record, playerMappingFn)
	if record then

		playerMappingFn = playerMappingFn or Util.Functions.Id

		local instanceId = record.instanceId
		-- each raid has an instance id, which is key for occurrences
		if Util.Objects.IsNil(self.raids[instanceId])then
			self.raids[instanceId] = {}
		end
		-- consider combination of instance id and date as a raid occurrence
		-- fuzzy as could be in the same raid across a change in day, but close enough
		if not Util.Tables.ContainsValue(self.raids[instanceId], record:FormattedDate()) then
			Util.Tables.Push(self.raids[instanceId], record:FormattedDate())
		end

		for _, player in pairs(record.players) do
			local playerName = playerMappingFn(player[2])

			if Util.Objects.IsNil(self.players[playerName]) then
				self.players[playerName] = {}
			end

			if not Util.Tables.ContainsKey(self.players[playerName], instanceId) then
				self.players[playerName][instanceId] = {}
			end

			if not Util.Tables.ContainsValue(self.players[playerName][instanceId], record:FormattedDate()) then
				Util.Tables.Push(self.players[playerName][instanceId], record:FormattedDate())
			end
		end
	end
end

--- @param dataFn function yields RaidRosterRecord data to be processed via RaidAttendanceStatistics
--- @param playerMappingFn  function<string> yields the name of passed player (string) to 'main' as/if needed
function RaidAttendanceStatistics.For(dataFn, playerMappingFn)
	local stats = RaidAttendanceStatistics()

	for _, data in dataFn() do
		local record = RaidRosterRecord:reconstitute(data)
		stats:_AddRaidIfNotPresent(record, playerMappingFn)
	end

	return stats
end


--- @class Models.Audit.RaidStatistics
local RaidStatistics = AuditPkg:Class('RaidStatistics')
function RaidStatistics:initialize()
	--- mapping form instance id to dates on which raids occurred
	--- @type table<number, table<number, table<boolean, table<number>>>>
	self.raids = {}
	--- extra stuff in case encounter cannot be looked up from id
	--- @type table<number, string>
	self.encountersAppendix = {}
end

--- @param record Models.Audit.RaidRosterRecord
function RaidStatistics:_AddRaidIfNotPresent(record)
	if record then
		local instanceId, encounterId, success, ts =
			record.instanceId, record.encounterId, record.success, record.timestamp
		-- each raid has an instance id, which is key for occurrences
		if Util.Objects.IsNil(self.raids[instanceId])then
			self.raids[instanceId] = {}
		end

		-- each encounter has an encounter id, which is key for attempts
		if not Util.Tables.ContainsKey(self.raids[instanceId], encounterId) then
			self.raids[instanceId][encounterId] = {}
		end

		if not Util.Tables.ContainsKey(self.encountersAppendix, encounterId) then
			self.encountersAppendix[encounterId] = record:GetEncounterName()
		end

		-- nil means it was start of encounter
		if not Util.Objects.IsNil(success) then
			if not Util.Tables.ContainsKey(self.raids[instanceId][encounterId], success) then
				self.raids[instanceId][encounterId][success] = {}
			end

			if not Util.Tables.ContainsValue(self.raids[instanceId][encounterId][success], ts) then
				Util.Tables.Push(self.raids[instanceId][encounterId][success], ts)
			end
		end
	end
end

--- @param intervalInDays number number of days in past from which to perform calculation
--- @return table table of raid stats
function RaidStatistics:GetTotals(intervalInDays)
	intervalInDays = tonumber(intervalInDays) or nil

	--- go through the raids and collect the ones and occurrences that are within the requested window
	local cutoff
	if intervalInDays then
		cutoff = Date()
		cutoff:add{day = -intervalInDays}
	end

	--- @type table table<number, table<number, table<boolean, table<number>>>>
	local raids = Util.Tables.Copy(
		self.raids,
		function(encounters)
			local filtered = {}
			for encounter, results in pairs(encounters) do
				local filteredResults = Util.Tables.Copy(
					results,
					function(dates)
						if cutoff then
							return Util.Tables.CopyFilter(
								dates,
								function(date) return Date(date) >= cutoff end
							)
						else
							return Util.Tables.Copy(dates)
						end
					end
				)

				Util.Tables.Filter(filteredResults, function(dates) return not Util.Tables.IsEmpty(dates) end)

				if Util.Tables.Count(filteredResults) ~= 0 then
					filtered[encounter] = filteredResults
				end
			end

			return filtered
		end
	)

	-- e.g
	--[[
	{
		instances = {
			533 = {
				encounters = {
						1107 = {total = 1, defeats = 0, victories = 1, pct = 1, name = ...},
						1118 = {total = 4, defeats = 4, victories = 0, pct = 0, name = ...},
						1115 = {total = 1, defeats = 0, victories = 1, pct = 1, name = ...},
						1112 = {total = 1, defeats = 0, victories = 1, pct = 1, name = ...},
						1116 = {total = 1, defeats = 0, victories = 1, pct = 1, name = ...},
						1113 = {total = 8, defeats = 8, victories = 0, pct = 0, name = ...},
						1117 = {total = 1, defeats = 0, victories = 1, pct = 1, name = ...},
						1110 = {total = 1, defeats = 0, victories = 1, pct = 1, name = ...},
				},
				total = 18,
				defeats = 12,
				victories = 6,
				pct = 0.33333,
				name = nil,
			},
			615 = {
				encounters = {
					742 = {total = 1, defeats = 0, victories = 1, pct = 1, name = ...}
				},
				total = 1,
				defeats = 0,
				victories = 1
				pct = 1
				name = nil,
			},
			...
		}
	}
	--]]
	local stats = {
		instances = { }

	}

	local function NewStats()
		return {
			total = 0,
			defeats = 0,
			victories = 0,
			pct = 0.0,
			name = nil, -- extra stuff, such as encounter name (not typically needed)
		}
	end

	local function UpdateStats(s, count, result)
		s.total = s.total + count
		if result then
			s.victories = s.victories + count
		else
			s.defeats = s.defeats + count
		end

		s.pct = (s.victories / s.total)
	end


	for instance, encounters in pairs(raids) do
		local instanceStats= NewStats()
		stats.instances[instance] = instanceStats
		stats.instances[instance]['encounters'] = {}

		for encounter, results in pairs(encounters) do
			local encounterStats = NewStats()
			stats.instances[instance].encounters[encounter] = encounterStats
			stats.instances[instance].encounters[encounter].name = self.encountersAppendix[encounter]

			for result, dates in pairs(results) do
				local count = Util.Tables.Count(dates)
				UpdateStats(instanceStats, count, result)
				UpdateStats(encounterStats, count, result)
			end
		end

	end

	return stats

end

function RaidStatistics.For(dataFn)
	local stats = RaidStatistics()

	for _, data in dataFn() do
		local record = RaidRosterRecord:reconstitute(data)
		stats:_AddRaidIfNotPresent(record)
	end

	return stats
end