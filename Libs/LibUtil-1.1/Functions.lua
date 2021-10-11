local MAJOR_VERSION = "LibUtil-1.1"
local MINOR_VERSION = 20502

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Functions) or (minor or 0) > MINOR_VERSION then return end

local Util = lib
--- @class LibUtil.Functions
local Self = Util.Functions

function Self.New(fn, obj) return type(fn) == "string" and (obj and obj[fn] or _G[fn]) or fn end
function Self.Id(...) return ... end
function Self.True() return true end
function Self.False() return false end
function Self.Zero() return 0 end
function Self.Noop() end

function Self.CompareMultitype(op1, op2)
    -- Inspired by http://lua-users.org/wiki/SortedIteration
    local type1, type2 = type(op1), type(op2)
    local num1,  num2  = tonumber(op1), tonumber(op2)

    -- Number or numeric string
    if (num1 ~= nil) and (num2 ~= nil) then
        -- Numeric compare
        return  num1 < num2
        -- Different types
    elseif type1 ~= type2 then
        -- String compare of type name
        return type1 < type2
    -- From here on, types are known to match (need only single compare)
    -- Non-numeric string
    elseif type1 == "string"  then
        -- Default compare
        return op1 < op2
    elseif type1 == "boolean" then
        -- No compare needed!
        return op1
    -- Handled above: number, string, boolean
    -- What's left: function, table, thread, userdata
    else
        -- String representation
        return tostring(op1) < tostring(op2)
    end
end

-- index and notVal = function(index, ...)
-- index = function(value, index, ...)
-- notVal = function(...)

---@param index boolean
---@param notVal boolean
---@return any
function Self.Call(fn, v, i, index, notVal, ...)
    if index and notVal then
        return fn(i, ...)
    elseif index then
        return fn(v, i, ...)
    elseif notVal then
        return fn(...)
    else
        return fn(v, ...)
    end
end

-- Get a value directly or as return value of a function
---@param fn function
function Self.Val(fn, ...)
    return (type(fn) == "function" and Util.Push(fn(...)) or Util.Push(fn)).Pop()
end

-- Some math
---@param i number
function Self.Inc(i)
    return i+1
end

---@param i number
function Self.Dec(i)
    return i-1
end

---@param a number
---@param b number
function Self.Add(a, b)
    return a+b
end

---@param a number
---@param b number
function Self.Sub(a, b)
    return a-b
end

---@param a number
---@param b number
function Self.Mul(a, b)
    return a*b
end

---@param a number
---@param b number
function Self.Div(a, b)
    return a/b
end

function Self.Dispatch(...)
    local funcs = {...}
    return function (...)
        for _, f in ipairs(funcs) do
            local r = { f(...) }
            if #r > 0 then return unpack(r) end
        end
    end
end

function Self.Filter(predicate_func, f, s, v)
    return function(s, v)
        local tmp = { f(s, v) }
        while tmp[1] ~= nil and not predicate_func(unpack(tmp)) do
            v = tmp[1]
            tmp = { f(s, v) }
        end
        return unpack(tmp)
    end, s, v
end


-- MODIFY

-- Throttle a function, so it is executed at most every n seconds
---@param fn function
---@param n number
---@param leading boolean
function Self.Throttle(fn, n, leading)
    local Timer = LibStub("AceTimer-3.0")
    local Fn, handle, called
    Fn = function (...)
        if not handle then
            if leading then fn(...) end
            handle = Timer:ScheduleTimer(function (...)
                handle = nil
                if not leading then fn(...) end
                if called then
                    called = nil
                    Fn(...)
                end
            end, n, ...)
        else
            called = true
        end
    end
    return Fn
end

-- Debounce a function, so it is executed only n seconds after the last call
function Self.Debounce(fn, n, leading)
    local Timer = LibStub("AceTimer-3.0")
    local handle, called
    return function (...)
        if not handle then
            if leading then fn(...) end
            handle = Timer:ScheduleTimer(function (...)
                handle = nil
                if not leading or called then
                    called = nil
                    fn(...)
                end
            end, n, ...)
        else
            called = true
            Timer:CancelTimer(handle)
            handle = Timer:ScheduleTimer(handle.func, n, unpack(handle, 1, handle.argsCount))
        end
    end
end

local traceback = (debug and debug.traceback) and debug.traceback or _G.debugstack

function Self.try(tryBlock)
    local status, err = true, nil
    if Util.Objects.IsFunction(tryBlock) then
        status, err = xpcall(tryBlock, traceback)
    end

    local finally = function(finallyBlock, hasCatchBlock)
        if Util.Objects.IsFunction(finallyBlock) then
            finallyBlock()
        end

        if not hasCatchBlock and not status then
            error(err)
        end
    end

    local catch = function(catchBlock)
        local hasCatchBlock = Util.Objects.IsFunction(catchBlock)

        if not status and hasCatchBlock then
            local ex = err or "unknown error occurred"
            catchBlock(ex)
        end

        return {
            finally = function(finallyBlock)  finally(finallyBlock, hasCatchBlock) end
        }
    end

    return {
        catch = catch,
        finally = function(finallyBlock) finally(finallyBlock, false) end
    }
end