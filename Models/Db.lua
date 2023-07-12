---@type AddOn
local _, AddOn = ...
local C = AddOn.Constants
---@type LibUtil
local Util = AddOn:GetLibrary("Util")
---@type LibLogging
local Logging = AddOn:GetLibrary("Logging")
---@type LibBase64
local Base64 = AddOn:GetLibrary("Base64")
---@type LibUtil.Compression.Compressor
local Compressor = Util.Compression.GetCompressors(Util.Compression.CompressorType.LibDeflate)[1]

-- This is only for testing during development, cannot change it at runtime
-- 'A' = AceSerializer, 'M' = LibMessagePack
local SerializerType = 'M'
local Serializer, Serialize, Deserialize
if SerializerType == 'A' then
    Serializer = AddOn:GetLibrary('AceSerializer')
    Serialize = function(d) return Serializer:Serialize(d) end
    Deserialize = function(s) return Serializer:Deserialize(s) end
elseif SerializerType == 'M' then
    --- @type LibMessagePack
    Serializer = AddOn:GetLibrary('MessagePack')
    Serialize = function(d) return Serializer.pack(d) end
    Deserialize = function(s) return pcall(function() return Serializer.unpack(s) end) end
end

local function compress(data)
    if data == nil then return nil end
    local serialized = Serialize(data)
    local compressed = Compressor:compress(serialized)
    local encoded = Base64:Encode(compressed)
    return encoded
end

local function decompress(data)
    if data == nil then return nil end
    local decoded = Base64:Decode(data)
    local decompressed, message = Compressor:decompress(decoded)
    if not decompressed then
        error('Could not de-compress decoded data : ' .. message)
        return
    end
    local success, raw = Deserialize(decompressed)
    if not success then
        error('Could not de-serialize de-compressed data : ' .. tostring(raw))
    end
    return raw
end

-- be warned, everything under the namespace for DB passed to this constructor
-- needs to be compressed, there is no mixing and matching
-- exception to this is top-level table keys
--
-- also, this class isn't meant to be designed for every possible use case
-- it was designed with a very narrow use case in mind - specifically recording very large numbers
-- of table like entries for a realm or realm/character combination
-- such as loot history
--
-- CompressionSettingsKey not used currently, but reserved for future need
local CompressionSettingsKey = '__CompressionSettings'
--- @class Models.CompressedDb
local CompressedDb = AddOn.Package('Models'):Class('CompressedDb')
function CompressedDb:initialize(db)
    self.db = db
end

function CompressedDb:decompress(data)
    return decompress(data)
end

function CompressedDb:compress(data)
    return compress(data)
end

function CompressedDb:clear()
    wipe(self.db)
end

function CompressedDb:get(key)
    return self:decompress(self.db[key])
end

function CompressedDb:put(key, value)
    self.db[key] = self:compress(value)
end

function CompressedDb:del(key, index)
    if Util.Objects.IsEmpty(index) then
        Util.Tables.Remove(self.db, key)
    else
        local v = self:get(key)
        if not Util.Objects.IsTable(v) then
            error("Attempt to delete from a non-table value : " .. type(v))
        end
        tremove(v, index)
        self:put(key, v)
    end
end

function CompressedDb:insert(value, key)
    if Util.Objects.IsEmpty(key) then
        Util.Tables.Push(self.db, self:compress(value))
    else
        local v = self:get(key)
        if not Util.Objects.IsTable(v) then
            error("Attempt to insert into a non-table value : " .. type(v))
        end
        Util.Tables.Push(v, value)
        self:put(key, v)
    end
    
end

function CompressedDb:__len()
    return #self.db
end

function CompressedDb.static.pairs(cdb, filter)
    -- an optional filter which allows restrictions on what is returned
    filter = Util.Objects.IsFunction(filter) and filter or Util.Functions.True

    local function stateless_iter(tbl, k)
        local v
        k, v = next(tbl, k)
        if k == CompressionSettingsKey then k, v = next(tbl, k) end

        if v ~= nil then
            local vd = cdb:decompress(v)
            while vd and not filter(k, vd) do
                k, v = next(tbl, k)
                vd = v and cdb:decompress(v) or nil
            end

            if k and vd then
                return k, vd
            end
        end
    end
    
    return stateless_iter, cdb.db, nil
end

function CompressedDb.static.ipairs(cdb)
    local function stateless_iter(tbl, i)
        i = i + 1
        local v = tbl[i]
        if v ~= nil then
            return i, cdb:decompress(v)
        end
    end
    
    return stateless_iter, cdb.db, 0
end


if AddOn._IsTestContext('Models_Db') then
    function CompressedDb.static:compress(data) return compress(data) end
    function CompressedDb.static:decompress(data) return decompress(data) end
end

--- @class Models.MasterLooterDb
local MasterLooterDb = AddOn.Package('Models'):Class('MasterLooterDb')
function MasterLooterDb:initialize()
    self.db = {}
end

function MasterLooterDb:IsInitialized()
    return self.db and Util.Tables.Count(self.db) > 0
end

function MasterLooterDb:ForTransmit()
    return self:toTable()
end

local _build = function(self, ml)
    Logging:Trace("MasterLooterDb:_build(BEFORE) : %d", Util.Tables.Count(self.db))

    local mlSettings, mlDefaults =
        ml.db and ml.db.profile or {},
        ml.defaults and ml.defaults.profile or {}

    -- do not support custom buttons and responses currently, only the default
    -- so don't send them unnecessarily
    local numButtons =
            Util.Tables.Get(mlSettings, 'buttons.numButtons') or
            Util.Tables.Get(mlDefaults, 'buttons.numButtons') or
            0

    self.db = {
        outOfRaid         = mlSettings.outOfRaid,
        timeout           = mlSettings.timeout and Util.Tables.Copy(mlSettings.timeout) or nil,
        showLootResponses = mlSettings.showLootResponses,
        buttons           = { numButtons = numButtons }
    }

    Logging:Trace("MasterLooterDb:_build(AFTER) : %d", Util.Tables.Count(self.db))
end

-- Singleton of MasterLooterDb through which all operations should be performed, it will manged the actual
-- instance and required operations
---@class MasterLooterDb
local MasterLooterDbSingleton = AddOn.Instance(
        'MasterLooterDb',
        function()
            return {
                instance = MasterLooterDb()
            }
        end
)

local _settings = function()
    local ML = AddOn:MasterLooterModule()
    if not ML or not ML.db or not ML.db.profile then
        error("MasterLooter module DB is not available")
    end
    return ML
end

---@return table
function MasterLooterDbSingleton:Get(rebuild)
    rebuild = Util.Objects.Default(rebuild, false)
    Logging:Trace("MasterLooterDbSingleton:Get(%s)", tostring(rebuild))

    if rebuild or not self.instance:IsInitialized() then
        _build(self.instance, _settings())
    end

    -- return the underlying table, not any other metadata
    return self.instance.db
end

---@param data table
function MasterLooterDbSingleton:Set(data)
    Logging:Trace("MasterLooterDbSingleton:Set(%s)", Util.Objects.ToString(data, 2))
    if not data or not Util.Objects.IsTable(data) then
        error("MasterLooter data is nil or not table")
    end
    self.instance = MasterLooterDb:reconstitute(data)
end

---@type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
function MasterLooterDbSingleton:Send(target)
    -- make sure the DB has been built, if already built it won't be rebuilt
    self:Get()
    Comm():Send {
        target = target,
        command = C.Commands.MasterLooterDb,
        data = {self.instance:ForTransmit()}
    }
end

if AddOn._IsTestContext('Models_Db') then
    function MasterLooterDb:Build(ml)
        _build(self, ml)
    end
end