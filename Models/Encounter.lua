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
    -- name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic,
    --  instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
    --
    -- only set the instance id if there is an encounter id
    if self.id then
        local _, _, _, _, _, _, _, instanceId = GetInstanceInfo()
        self.instanceId = tonumber(instanceId)
    end
end

--- @return boolean
function Encounter:IsSuccess()
    return self.success and (self.success == 1) or false
end

Encounter.None = Encounter(0, _G.UNKNOWN, nil, nil)