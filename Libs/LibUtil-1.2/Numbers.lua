local MAJOR_VERSION = "LibUtil-1.2"
local MINOR_VERSION = 40400

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Numbers) or (minor or 0) > MINOR_VERSION then return end

local Util = lib
--- @class LibUtil.Numbers
local Self = Util.Numbers
--- @type LibClass
local Class = LibStub("LibClass-1.1")

function Self.Round(num, p)
    p = math.pow(10, p or 0)
    return math.floor(num * p + .5) / p
end

function Self.Round2(num, p)
    if type(num) ~= "number" then return nil end
    return tonumber(string.format("%." .. (p or 0) .. "f", num))
end

function Self.Between(num, a, b)
    return num > a and num < b
end

function Self.In(num, a, b)
    return num >= a and num <= b
end

function Self.ToHex(num, minLength)
    return ("%." .. (minLength or 1) .. "x"):format(num)
end

function Self.BinaryRepr(n)
    local t = {}
    for i=7,0,-1 do
        t[#t+1] = math.floor(n / 2^i)
        n = n % 2^i
    end
    return table.concat(t)
end

---
--- it's not really atomic,  but has similar semantics
---
--- @class LibUtil.Numbers.AtomicNumber
local AtomicNumber = Class('AtomicNumber')
Self.AtomicNumber = AtomicNumber

function AtomicNumber:initialize(initialValue)
    self.value = initialValue
end

function AtomicNumber:GetAndIncrement()
    local value = self.value
    self.value = self.value + 1
    return value
end