local MAJOR_VERSION = "LibUtil-1.1"
local MINOR_VERSION = 20502

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Objects) or (minor or 0) > MINOR_VERSION then return end

local Util = lib
--- @class LibUtil.Objects
local Self = Util.Objects

function Self.IsEmpty(obj)
    if Self.IsNil(obj) then return true end
    if Self.IsString(obj) then return Util.Strings.IsEmpty(obj) end
    if Self.IsTable(obj) then return Util.Tables.IsEmpty(obj) end
    return false
end

function Self.IsSet(val)
    return not Self.IsEmpty(val)
end

function Self.IsString(obj)
    return type(obj) == 'string'
end

function Self.IsTable(obj)
    return type(obj) == 'table'
end

function Self.IsCallable(obj)
    return (Self.IsFunction(obj) or ((Self.IsTable(obj) and getmetatable(obj) and getmetatable(obj).__call ~= nil) or false))
end

function Self.IsFunction(obj)
    return type(obj) == 'function'
end

function Self.IsNil(obj)
    return obj==nil
end

function Self.IsNumber(obj)
    return type(obj) == 'number'
end

function Self.IsBoolean(obj)
    return type(obj) == 'boolean'
end

function Self.IsInstanceOf(obj, clazz)
    return obj and Self.IsTable(obj) and (obj.clazz and obj.isInstanceOf) and obj:isInstanceOf(clazz)
end

-- Check if two values are equal
function Self.Equals(a, b)
    return a == b
end

-- Compare two values, returns -1 for a < b, 0 for a == b and 1 for a > b
---@generic T
---@param a T
---@param b T
function Self.Compare(a, b)
    return a == b and 0
            or a == nil and 1
            or b == nil and -1
            or a > b and 1 or -1
end

-- Create an iterator
---@param from number
---@param to number
---@param step number
---@return function(steps: number, reset: boolean): number
function Self.Iter(from, to, step)
    local i = from or 0
    return function (steps, reset)
        i = (reset and (from or 0) or i) + (step or 1) * (steps or 1)
        return (not to or i <= to) and i or nil
    end
end

-- Return val if it's not nil, default otherwise
---@generic T
---@param val T
---@param default T
---@return T
function Self.Default(val, default)
    if val ~= nil then return val else return default end
end

-- Return a when cond is true, b otherwise
---@generic T
---@param cond any
---@param a T
---@param b T
---@return T
function Self.Check(cond, a, b)
    if cond then return a else return b end
end

-- Iterate tables or parameter lists
---@generic T, I
---@param t T[]
---@param i I
---@return I, T
local Fn = function (t, i)
    i = (i or 0) + 1
    if i > #t then
        Util.Tables.ReleaseTmp(t)
    else
        local v = t[i]
        return i, Self.Check(v == Util.Tables.NIL, nil, v)
    end
end
---@generic T, I
---@return function(t: T[], i: I): I, T
---@return T
---@return I
function Self.Each(...)
    if ... and type(...) == "table" then
        return next, ...
    elseif select("#", ...) == 0 then
        return Util.Functions.Noop
    else
        return Fn, Util.Tables.Tmp(...)
    end
end
---@generic T, I
---@return function(t: T[], i: I): I, T
---@return T
---@return I
function Self.IEach(...)
    if ... and type(...) == "table" then
        return Fn, ...
    else
        return Self.Each(...)
    end
end

-- Shortcut for val == x or val == y or ...
---@param val any
---@return boolean
function Self.In(val, ...)
    for i,v in Self.Each(...) do
        if v == val then return true end
    end
    return false
end

-- Shortcut for val == a and b or val == c and d or ...
---@param val any
---@return any
function Self.Select(val, ...)
    local n = select("#", ...)

    for i=1, n - n % 2, 2 do
        local a, b = select(i, ...)
        if val == a then return b end
    end

    if n % 2 == 1 then
        return select(n, ...)
    end
end

-------------------------------------------------------
--                       Stack                       --
-------------------------------------------------------

-- Useful for ternary conditionals, e.g. val = (cond1 and Push(false) or cond2 and Push(true) or Push(nil)).Pop()

Self.stack = {}

---@param val any
function Self.Push(val)
    tinsert(Self.stack, val == nil and Util.Tables.NIL or val)
    return Self
end

---@return any
function Self.Pop()
    local val = tremove(Self.stack)
    return Self.Check(val == Util.Tables.NIL, nil, val)
end

-- Get string representation of various object types
function Self.ToString(val, depth)
    depth = depth or 3
    local t = type(val)

    if t == "nil" then
        return "nil"
    elseif t == "table" then
        local _, fn = pcall(
            function() return val.ToString or val.toString or val.tostring end
        )

        if depth == 0 then
            return "{...}"
        elseif type(fn) == "function" and fn ~= Self.ToString then
            return fn(val, depth)
        else
            local j = 1
            return Util.Tables.FoldL(
                    val,
                    function (s, v, i)
                        if s ~= "{" then s = s .. ", " end
                        if i ~= j then
                            if type(i) == 'table' then
                                s = s .. Self.ToString(i, depth - 1) .. " = "
                            else
                                s = s .. i .. " = "
                            end
                        end
                        j = j + 1

                        return s .. Self.ToString(v, depth-1)
                    end,
                    "{", true
            ) .. "}"
        end
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "function" then
        return "(fn)"
    elseif t == "string" then
        return val
    elseif t == "userdata" then
        return "(userdata)"
    else
        return val
    end
end

-------------------------------------------------------
--                       Other                       --
-------------------------------------------------------

-- Safecall
local xpcall = xpcall

local function errorhandler(err)
    return geterrorhandler()(err)
end

local function CreateDispatcher(argCount)
    local code = [[
		local xpcall, eh = ...
		local method, ARGS
		local function call() return method(ARGS) end

		local function dispatch(func, ...)
			method = func
			if not method then return end
			ARGS = ...
			return xpcall(call, eh)
		end

		return dispatch
	]]

    local ARGS = {}
    for i = 1, argCount do ARGS[i] = "arg"..i end
    code = code:gsub("ARGS", table.concat(ARGS, ", "))
    return assert(loadstring(code, "safecall Dispatcher["..argCount.."]"))(xpcall, errorhandler)
end

local Dispatchers = setmetatable({}, {__index=function(self, argCount)
    local dispatcher = CreateDispatcher(argCount)
    rawset(self, argCount, dispatcher)
    return dispatcher
end})

Dispatchers[0] = function(func) return xpcall(func, errorhandler) end

---@param func function
function Self.Safecall(func, ...)
    return Dispatchers[select("#", ...)](func, ...)
end

-- Dump all given values
function Self.Dump(...)
    for i=1,select("#", ...) do
        print(Util.Str.ToString((select(i, ...))))
    end
end