--- @type AddOn
local _, AddOn = ...
---@type LibUtil
local Util = AddOn:GetLibrary("Util")

--- @class Models.Encounter
--- @field id Models.Encounter
--- @field name Models.Encounter
--- @field difficultyId Models.Encounter
--- @field groupSize Models.Encounter
--- @field success Models.Encounter
local Encounter = AddOn.Package('Models'):Class('Encounter')
--- @class Models.EncounterStart
local EncounterStart = AddOn.Package('Models'):Class('EncounterStart', Encounter)
--- @class Models.EncounterEnd
local EncounterEnd = AddOn.Package('Models'):Class('EncounterEnd', Encounter)

-- https://wow.gamepedia.com/ENCOUNTER_START
--      ENCOUNTER_START: encounterID, "encounterName", difficultyID, groupSize
-- https://wow.gamepedia.com/ENCOUNTER_END
--       ENCOUNTER_END: encounterID, "encounterName", difficultyID, groupSize, success
--
-- These are in the order expected from arguments to the events listed above
local EncounterFields = {'id', 'name', 'difficultyId', 'groupSize', 'success'}

function Encounter:initialize(...)
    local t = Util.Tables.Temp(...)
    for index, field in pairs(EncounterFields) do
        self[field] = t[index]
    end
    Util.Tables.ReleaseTemp(t)

    --
    -- https://wow.gamepedia.com/API_GetInstanceInfo
    --      name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic,
    --      instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
    --
    -- only set the instance id if there is an encounter id
    if self.id then
        local _, _, _, _, _, _, _, instanceId = GetInstanceInfo()
        self.instanceId = tonumber(instanceId)
    end
end

--- @return LibUtil.Optional<boolean>
function Encounter:IsSuccess()  error("IsSuccess() not implemented") end

Encounter.None = Encounter(0, _G.UNKNOWN, nil, nil)

function EncounterStart:initialize(...)
    Encounter.initialize(self, ...)
end

--- @return LibUtil.Optional<boolean>
function EncounterStart:IsSuccess()
    return Util.Optional.empty()
end

--- @return Models.EncounterStart
function Encounter.Start(...)
    return EncounterStart(...)
end

function EncounterEnd:initialize(...)
    Encounter.initialize(self, ...)
    -- the WOW API is either poorly documented or has schizophrenic behavior
    -- it says success should be 0 on failure and 1 on success
    -- however, clear evidence to show it can be nil on failure as well
    -- fix it up here
    if Util.Objects.IsNil(self.success) then
        self.success = 0
    else
        self.success = tonumber(self.success)
    end
end

--- @return LibUtil.Optional<boolean>
function EncounterEnd:IsSuccess()
    return Util.Optional.of(self.success == 1)
end

--- @param start Models.EncounterStart the start encounter for which an end should be created
--- @return Models.EncounterEnd
function Encounter.End(start, ...)
    -- ENCOUNTER_END doesn't seem to reliably provide the correct encounter id
    -- take it from the start and remainder from varargs
    if Util.Objects.IsInstanceOf(start, EncounterStart) then
        return EncounterEnd(start.id, unpack({...}, 2))
    -- if an end event was generated without a start
    -- take the raw event data
    elseif Util.Objects.IsInstanceOf(start, EncounterEnd) or Util.Objects.IsNil(start) then
        return EncounterEnd(...)
    -- if the start event was not an Encounter instance or nil, take it all
    else
        return EncounterEnd(start, ...)
    end
end

