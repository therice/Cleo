local MAJOR_VERSION = "LibUtil-1.1"
local MINOR_VERSION = 20502

--- @class LibUtil
--- @field public Tables LibUtil.Tables
--- @field public Strings LibUtil.Strings
--- @field public Numbers LibUtil.Numbers
--- @field public Functions LibUtil.Functions
--- @field public Objects LibUtil.Objects
--- @field public Compression LibUtil.Compression
--- @field public Memoize LibUtil.Memoize
--- @field public Utf8 LibUtil.Utf8
--- @field public Optional LibUtil.Optional
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

-- Modules
-- type() to module
local Modules = {
    table = "Tables",
    string = "Strings",
    number = "Numbers",
    ["function"] = "Functions",
    "Objects",
    "Compression",
    "Memoize",
    "UUID",
    "Bitfield",
    "Lists",
    "Patch",
    "Utf8",
    "Optional"
}

local Module = {
    __call = function (self, ...)
        return self.New(...)
    end
}

for _, mod in pairs(Modules) do
    lib[mod] = setmetatable({}, Module)
end

-- Chaining
local Resolve = function (self, ...)
    local obj, mod = rawget(self, "obj"), rawget(self, "mod")
    local key, val = rawget(self, "key"), rawget(self, "val")

    mod = mod or Modules[type(val)]
    obj = mod and obj[mod] or obj

    self.val = obj[key](val, ...)
    self.key, self.mod = nil, nil

    return self
end


local Chain = {
    __index = function (self, key)
        if rawget(self.obj, key) then
            self.mod = key
            return self
        else
            self.key = key
            return Resolve
        end
    end,
    __call = function (self, key)
        local val = rawget(self, "val")
        if key ~= nil then
            val = val[key]
        end
        self.obj.Tables.Release(self)
        return val
    end
}

-- Metatable
local Meta = {
    __index = lib.Objects,
    __call = function (self, val)
        local chain = setmetatable(self.Tables.New(), Chain)
        chain.obj, chain.key, chain.val = self, nil, val
        return chain
    end
}

setmetatable(lib, Meta)
lib.__index = lib
lib.__call = Meta.__call
