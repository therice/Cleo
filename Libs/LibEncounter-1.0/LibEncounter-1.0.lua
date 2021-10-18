local MAJOR_VERSION = "LibEncounter-1.0"
local MINOR_VERSION = 20502

--- @class LibEncounter
local lib, _ = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

local LibBoss = LibStub("LibBabble-Boss-3.0")
local LibSubZone = LibStub("LibBabble-SubZone-3.0")
local Util = LibStub("LibUtil-1.1")

-- Boss localization
local LB = LibBoss:GetLookupTable()
local LBR = LibBoss:GetReverseLookupTable()
-- Zone localization (e.g. raids)
local LZ = LibSubZone:GetLookupTable()
local LZR = LibSubZone:GetReverseLookupTable()

-- collection of maps (for encounters)
lib.Maps = {

}

-- collection of creatures (for encounters)
lib.Creatures = {

}

-- collection of encounters
lib.Encounters = {

}

function lib:GetCreatureMapId(creatureId)
    local encounters = Util(lib.Encounters)
        :CopyFilter(
            function(v)
                for _, id in pairs(v.creature_id) do
                    if id == creatureId then
                        return true
                    end
                end
                
                return false
            end
    )()

    if Util.Tables.Count(encounters) == 0 then
        error(("No encounters found for creature id=%s"):format(creatureId))
    end

    if Util.Tables.Count(encounters) > 1 then
        error(("Multiple encounters found for creature id=%s"):format(creatureId))
    end

    return Util.Tables.First(encounters).map_id
end

function lib:GetCreatureName(creatureId)
    local creatureName
    --  map id to the creature, then look up from localization
    local creature = lib.Creatures[creatureId]
    if creature then creatureName = LB[creature.name] end
    return creatureName
end

function lib:GetCreatureId(creatureName)
    -- reverse lookup based upon localized name into english
    local creatureName, creatureId = LBR[creatureName], nil
    if creatureName then
        creatureId, _ = Util.Tables.FindFn(
            lib.Creatures,
            function(creature)
                return Util.Strings.Equal(creatureName, creature.name)
            end,
            true
        )
    end

    return creatureId
end

function lib:GetMapName(mapId)
    local mapName
    --  map id to the map's name key, then look up from localization
    local map = lib.Maps[mapId]
    if map then mapName = LZ[map.name] end
    return mapName
end

function lib:GetMapId(mapName)
    local mapId
    -- Maps are in English, so map localized map name to english variation for lookup
    local mapName = LZR[mapName]
    if mapName then
        mapId = Util.Tables.FindFn(
            lib.Maps,
            function(value) return value.name == mapName end
        )
    end
    
    return mapId
end

function lib:GetEncounterId(creatureId)
    return Util.Tables.FindFn(
            lib.Encounters,
            function(e)
                return Util.Tables.ContainsValue(e.creature_id, creatureId)
            end
    )
end

function lib:GetCreatureDetail(creatureId)
    local map_id = self:GetCreatureMapId(creatureId)
    return self:GetCreatureName(creatureId), self:GetMapName(map_id)
end

-- the returned value will be a table, as encounters can have more than one creature
function lib:GetEncounterCreatureId(encounterId)
    local encounter = lib.Encounters[encounterId]
    return encounter and encounter.creature_id or nil
end

function lib:GetEncounterMapId(encounterId)
    local encounter = lib.Encounters[encounterId]
    return encounter and encounter.map_id or nil
end
