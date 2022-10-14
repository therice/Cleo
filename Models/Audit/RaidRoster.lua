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

--- @class Models.Audit.RaidRosterRecord
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

--- @param intervalInDays number number of days in past from which to perform calculation
--- @return table<string, number> table of player name to % of raids attended
function RaidAttendanceStatistics:GetTotals(intervalInDays)
	intervalInDays = tonumber(intervalInDays) or 30

	--- go through the raids and collect the ones and occurrences that are within the requested window
	--- @type table table<number, table<string>>
	local cutoff = Date()
	cutoff:add{day = -intervalInDays}

	local raids = Util.Tables.Copy(
		self.raids,
		function(dates)
			local filtered = {}
			for _, date in pairs(dates) do
				local ts = Audit.ShortDf:parse(date)
				if ts >= cutoff then
					Util.Tables.Push(filtered, date)
				end
			end
			return filtered
		end
	)
	--print(Util.Objects.ToString(raids))

	--- no go through players and retain raids and attendance that are within the window
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
	--print(Util.Objects.ToString(players))

	local countByRaid = Util.Tables.Map(raids, function(dates) return Util.Tables.Count(dates) end)
	--print(Util.Objects.ToString(countByRaid))
	local totalRaids = Util.Tables.Sum(countByRaid)
	--print(totalRaids)

	local countByPlayer = Util.Tables.Map(players, function(praids) return Util.Tables.Map(praids, function(dates) return Util.Tables.Count(dates) end) end)
	--print(Util.Objects.ToString(countByPlayer))
	local totalByPlayer = Util.Tables.Map(countByPlayer,function(praids) return Util.Tables.Sum(praids) end)
	--print(Util.Objects.ToString(totalByPlayer))

	return Util.Tables.Map(
		totalByPlayer,
		function(count)
			local v = Util.Numbers.Round2(count / totalRaids, 2)
			return Util.Objects.Check(tostring(v) == "-nan", 0, v)
		end
	)
end

--- @param self Models.Audit.RaidAttendanceStatistics
--- @param record Models.Audit.RaidRosterRecord
local function AddRaidIfNotPresent(self, record)
	if record then
		local instanceId = record.instanceId
		-- each raid has an instance id, which is key for occurrences
		if not self.raids[instanceId] then
			self.raids[instanceId] = {}
		end
		-- consider combination of instance id and date as a raid occurrence
		-- fuzzy as could be in the same raid across a change in day, but close enough
		if not Util.Tables.ContainsValue(self.raids[instanceId], record:FormattedDate()) then
			Util.Tables.Push(self.raids[instanceId], record:FormattedDate())
		end

		for _, player in pairs(record.players) do
			local playerName = player[2]

			if not self.players[playerName] then
				self.players[playerName] = {}
			end

			if not Util.Tables.ContainsValue(self.players[playerName], instanceId) then
				self.players[playerName][instanceId] = {}
			end

			if not Util.Tables.ContainsValue(self.players[playerName][instanceId], record:FormattedDate()) then
				Util.Tables.Push(self.players[playerName][instanceId], record:FormattedDate())
			end
		end
	end
end

function RaidAttendanceStatistics.For(dataFn)
	local stats = RaidAttendanceStatistics()

	for _, data in dataFn() do
		local record = RaidRosterRecord:reconstitute(data)
		AddRaidIfNotPresent(stats, record)
	end

	return stats
end