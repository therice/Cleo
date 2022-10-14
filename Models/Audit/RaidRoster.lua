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