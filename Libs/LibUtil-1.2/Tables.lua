local MAJOR_VERSION = "LibUtil-1.2"
local MINOR_VERSION = 40400

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Tables) or (minor or 0) > MINOR_VERSION then return end

local Util = lib
--- @class LibUtil.Tables
local Self = Util.Tables

-- GET/SET

-- Get a value from a table
---@return any
function Self.Get(t, ...)
    local n, path = select("#", ...), ...

    if n == 1 and type(path) == "string" and path:find("%.") then
        path = Self.Tmp(("."):split((...)))
    elseif type(path) ~= "table" then
        path = Self.Tmp(...)
    end

    for _,k in Util.IEach(path) do
        if k == nil then
            break
        elseif t ~= nil then
            t = t[k]
        end
    end

    return t
end

-- Set a value on a table
---@vararg any
---@return table
---@return any
function Self.Set(t, ...)
    -- number of parameters and the parameters
    local n, path = select("#", ...), ...
    local val = select(n, ...)

    if n == 2 and type(path) == "string" and path:find("%.") then
        -- if a compound path, such as 'group_param1.args.compound.select'
        -- split it into an array of parts
        -- e.g. => {group_param1, args, compound, select}
        path = Self.Tmp(("."):split((...)))
    elseif type(path) ~= "table" then
        path = Self.Tmp(...)
        tremove(path)
    end

    local u, j = t
    for _,k in Util.IEach(path) do
        if k == nil then
            break
        elseif j then
            if u[j] == nil then
                u[j] = Self.New()
            end
            u = u[j]
        end
        j = k
    end

    u[j] = val

    return t, val
end

function Self.Replace(t, keyFn, value, ...)
    keyFn = Util.Functions.New(keyFn)

    for k, v in pairs(t) do
        if Util.Functions.Call(keyFn, v, k, true, false, ...) then
            t[k] = value
        end
    end

    return t
end

-- Get a random key from the table
function Self.RandomKey(t)
    if not t or not next(t) then
        return
    else
        local n = random(Self.Count(t))
        for i,v in pairs(t) do
            n = n - 1
            if n == 0 then return i end
        end
    end
end

-- Get a random entry from the table
---@param t table
---@return any
function Self.Random(t)
    local key = Self.RandomKey(t)
    return key and t[key]
end

function Self.Shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

-- Get table keys
---@param t table
---@return table
function Self.Keys(t)
    local u = Self.New()
    for i,_ in pairs(t) do tinsert(u, i) end
    return u
end

-- Get table values as continuously indexed list
---@param t table
---@return table
function Self.Values(t)
    local u = Self.New()
    for _,v in pairs(t) do tinsert(u, v) end
    return u
end

--[[
function Self.FirstValue(t)
    return Self.NthValue(t, 1)
end

function Self.NthValue(t, n)
    if Self.IsList(t) then
        return t[n]
    else
        local index, count = 1, Self.Count(t)
        if index <= count then
            for _, value in pairs(t) do
                if index == n then
                    return value
                end
                index = index + 1
            end
        end
    end

    return nil
end
--]]

-- Turn a table into a continuously indexed list (in-place)
---@param t table
---@return table
function Self.List(t)
    local n = Self.Count(t)
    for k=1, n do
        if not t[k] then
            local l
            for i,v in pairs(t) do
                if type(i) == "number" then
                    l = math.min(l or i, i)
                else
                    l = i
                    break
                end
            end
            t[k], t[l] = t[l], nil
        end
    end
    return t
end

-- Check if the table is a continuously indexed list
function Self.IsList(t)
    return #t == Self.Count(t)
end

-- SUB

---@param t table
---@param s number
---@param e number
function Self.Sub(t, s, e)
    return {unpack(t, s or 1, e)}
end

function Self.Head(t, n)
    return Self.Sub(t, 1, n or 1)
end

---@param t table
---@param n number
function Self.Tail(t, n)
    return Self.Sub(t, #t - (n or 1))
end

---@param t table
---@param s number
---@param e number
---@param u number
function Self.Splice(t, s, e, u)
    return Self.Merge(Self.Head(t, s), u or {}, Self.Sub(t, e))
end

-- "same" as Splice but handles sparse tables
function Self.Splice2(t, s, e, u)
    local spliced, u, size = {}, u or {}, table.maxn(t)
    for index=1, math.min(s, size) do
        spliced[index] = t[index]
    end

    for index=1, #u do
       spliced[table.maxn(spliced)+ 1] = u[index]
    end

    for index=e, size do
        spliced[index + #u] = t[index]
    end

    return spliced
end

-- ITERATE

-- Good old FoldLeft
---@param t table
---@param u any
function Self.FoldL(t, fn, u, index, ...)
    fn, u = Util.Functions.New(fn), u or Self.New()
    for i,v in pairs(t) do
        if index then
            u = fn(u, v, i, ...)
        else
            u = fn(u, v, ...)
        end
    end
    return u
end

-- Iterate through a table
function Self.Iter(t, fn, ...)
    fn = Util.Functions.New(fn)
    for i,v in pairs(t) do
        fn(v, i, ...)
    end
    return t
end

-- Call a function on every table entry
---@param fn function
---@param index boolean
---@param notVal boolean
function Self.Call(t, fn, index, notVal, ...)
    for i,v in pairs(t) do
        Util.Functions.Call(Util.Functions.New(fn, v), v, i, index, notVal, ...)
    end
    return t
end

-- COUNT, SUM, MULTIPLY, MIN, MAX

---@return number
function Self.Count(t)
    return Self.FoldL(t, Util.Functions.Inc, 0)
end

---@param t table
---@return number
function Self.Sum(t)
    return Self.FoldL(t, Util.Functions.Add, 0)
end

---@param t table
---@return number
function Self.Mul(t)
    return Self.FoldL(t, Util.Functions.Mul, 1)
end

function Self.Incr(t)
    return Self.FoldL(t, Util.Functions.Inc, 1)
end

---@param t table
---@param start number
---@return number
function Self.Min(t, start)
    return Self.FoldL(t, math.min, start or select(2, next(t)))
end

---@param t table
---@param start number
---@return number
function Self.Max(t, start)
    return Self.FoldL(t, math.max, start or select(2, next(t)))
end

-- Count the # of occurrences of given value(s)
---@param t table
function Self.CountOnly(t, ...)
    local n = 0
    for i,v in pairs(t) do
        if Util.In(v, ...) then n = n + 1 end
    end
    return n
end

-- Count the # of occurrences of everything except given value(s)
function Self.CountExcept(t, ...)
    local n = 0
    for i,v in pairs(t) do
        if not Util.In(v, ...) then n = n + 1 end
    end
    return n
end

-- Count the # of tables that have given key/val pairs
---@param t table
function Self.CountWhere(t, ...)
    local n = 0
    for i,u in pairs(t) do
        if Self.Matches(u, ...) then n = n + 1 end
    end
    return n
end

-- Count using a function
---@param index boolean
---@param notVal boolean
function Self.CountFn(t, fn, index, notVal, ...)
    local n, fn = 0, Util.Functions.New(fn)
    for i,v in pairs(t) do
        local val = Util.Functions.Call(fn, v, i, index, notVal, ...)
        n = n + (tonumber(val) or val and 1 or 0)
    end
    return n
end

-- SEARCH

-- Search for something in a table and return the index
---@param t table
---@param fn function(v: any, i: any): boolean
function Self.Search(t, fn, ...)
    fn = Util.Functions.New(fn) or Util.Functions.Id
    for i,v in pairs(t) do
        if fn(v, i, ...) then
            return i
        end
    end
end

-- Check if one table is contained within the other
---@param t table
function Self.Contains(t, u, deep)
    if t == u then
        return true
    elseif (t == nil) ~= (u == nil) then
        return false
    end

    for i,v in pairs(u) do
        if deep and type(t[i]) == "table" and type(v) == "table" then
            if not Self.Contains(t[i], v, true) then
                return false
            end
        elseif t[i] ~= v then
            return false
        end
    end
    return true
end

function Self.ContainsKey(t, k)
    return t[k] ~= nil
end

function Self.ContainsValue(t, v)
    return Self.Find(t, v) and true or false
end

-- Check if two tables are equal
---@param deep boolean
function Self.Equals(a, b, deep)
    return type(a) == "table" and type(b) == "table" and Self.Contains(a, b, deep) and Self.Contains(b, a, deep)
end

--[[
function Self.Compare(a, b)
    local resA, resB = {}, {}

    local function Difference(t1, t2, k, v)
        if t2[k] ~= nil and Util.Objects.IsTable(t1[k]) and Util.Objects.IsTable(t2[k]) then
            return Self.Compare(t1[k], t2[k])
        elseif t2[k] == nil then
            return {}
        elseif t2[k] ~= v then
            return t2[k]
        end
    end

    for k,v in pairs(a) do
        local diff = Difference(a, b, k, v)
        if not resA[k] then
            resA[k] = diff
        else
            tinsert(resA[k], diff)
        end
    end

    for k,v in pairs(b) do
        local diff = Difference(b, a, k, v)
        if not resB[k] then
            resB[k] = diff
        else
            tinsert(resB[k], diff)
        end
    end

    return resA, resB
end

--  https://github.com/martinfelis/luatablediff/blob/master/ltdiff.lua
function Self.Compare(A, B)
    local mod, del = {}, {}

    for k,v in pairs(A) do
        if B[k] ~= nil and type(A[k]) == "table" and type(B[k]) == "table" then
            local a, b = Self.Compare(A[k], B[k])
            mod[k] = a
            del[k] = b
        elseif B[k] == nil then
            del[#del + 1] = k
            --diff.del[#(diff.del) + 1] = k
        elseif B[k] ~= v then
            mod[k] = B[k]
            --diff.mod[k] = B[k]
        end
    end

    for k,v in pairs(B) do
        if mod[k] ~= nil then
            -- skip
        elseif A[k] ~= nil and type(A[k]) == "table" and type(B[k]) == "table" then
            local a, b = Self.Compare(A[k], B[k])
            mod[k] = a
            del[k] = b
        elseif B[k] ~= A[k] then
            mod[k] = v
        end
    end

    --if next(diff.sub) == nil then
    --    diff.sub = nil
    --end
    --
    --if next(diff.mod) == nil then
    --    diff.mod = nil
    --end
    --
    --if next(diff.del) == nil then
    --    diff.del = nil
    --end

    print('Mod -> ' .. Util.Objects.ToString(mod))
    print('Del -> ' .. Util.Objects.ToString(del))
    return mod, del
end
--]]

-- Check if a table matches the given key-value pairs
---@param t table
function Self.Matches(t, ...)
    if type(...) == "table" then
        return Self.Contains(t, ...)
    else
        for i=1, select("#", ...), 2 do
            local key, val = select(i, ...)
            local v = Self.Get(t, key)
            if v == nil or val ~= nil and v ~= val then
                return false
            end
        end

        return true
    end
end

-- Check if a value is a filled table
---@param t table
function Self.IsSet(t)
    return type(t) == "table" and next(t) and true or false
end

-- Check if a value is not a table or empty
---@param t table
function Self.IsEmpty(t)
    return not Self.IsSet(t)
end

-- Find a value in a table
---@param t table
---@param val any
---@return any
---@return any
function Self.Find(t, val)
    for i,v in pairs(t) do
        if v == val then return i, v end
    end
end

-- Find a set of key/value pairs in a table
---@return any
---@return any
function Self.FindWhere(t, ...)
    for i,v in pairs(t) do
        if Self.Matches(v, ...) then return i, v end
    end
end

-- Find the first element matching a fn
---@param index boolean
---@param notVal boolean
---@return any
---@return any
function Self.FindFn(t, fn, index, notVal, ...)
    for i,v in pairs(t) do
        if Util.Functions.Call(Util.Functions.New(fn, v), v, i, index, notVal, ...) then
            return i, v
        end
    end
end

-- Find the first element (optionally matching a fn)
---@return any
function Self.First(t, fn, index, notVal, ...)
    return Self.Nth(t, 2, fn, index, notVal, ...)
end

-- i should be desired index + 1, as the key will be in index 1
function Self.Nth(t, i, fn, index, notVal, ...)
    if not fn then
        return select(i, next(t))
    else
        return select(i, Self.FindFn(t, fn, index, notVal, ...))
    end
end

-- Find the first set of key/value pairs in a table
---@return any
function Self.FirstWhere(t, ...)
    return select(2, Self.FindWhere(t, ...))
end

-- FILTER

-- Filter by a function
---@param t table
---@param index boolean
---@param notVal boolean
---@param k boolean
function Self.Filter(t, fn, index, notVal, k, ...)
    fn = Util.Functions.New(fn) or Util.Functions.Id

    if not k and Self.IsList(t) then
        for i=#t,1,-1 do
            if not Util.Functions.Call(fn, t[i], i, index, notVal, ...) then
                tremove(t, i)
            end
        end
    else
        for i,v in pairs(t) do
            if not Util.Functions.Call(fn, v, i, index, notVal, ...) then
                Self.Remove(t, i, k)
            end
        end
    end

    return t
end

-- Pick specific keys from a table
function Self.Select(t, ...)
    for i in pairs(t) do
        if not Util.In(i, ...) then t[i] = nil end
    end
    return t
end

-- Omit specific keys from a table
---@param t table
function Self.Unselect(t, ...)
    for i,v in Util.Each(...) do t[v] = nil end
    return t
end

-- Filter by a value
---@param k boolean
function Self.Only(t, val, k)
    return Self.Filter(t, Util.Equals, nil, nil, k, val)
end

-- Filter by not being a value
local ExceptFn = function (v, val) return v ~= val end
---@param val any
---@param k boolean
function Self.Except(t, val, k)
    return Self.Filter(t, ExceptFn, nil, nil, k, val)
end

-- Filter by a set of key/value pairs in a table
---@param t table
---@param k boolean
function Self.Where(t, k, ...)
    return Self.Filter(t, Self.Matches, nil, nil, k, ...)
end

-- Filter by not having a set of key/value pairs in a table
local ExceptWhereFn = function (...)
    return not Self.Matches(...)
end
---@param t table
---@param k boolean
function Self.ExceptWhere(t, k, ...)
    return Self.Filter(t, ExceptWhereFn, nil, nil, k, ...)
end

-- COPY

-- if the passed table is sparse, it will return a copy with entries removed which have a nil value
-- if the passed table is NOT sparse, the original table is returned unmodified
function Self.Compact(t)
    if Self.Count(t) ~= table.maxn(t) then
        local compact, append = {}, {}

        local index = 1
        for k, _ in pairs(t) do
            if not Util.Objects.IsNil(k) then
                if Util.Objects.IsNumber(k) and t[k] ~= nil then
                    compact[index] = t[k]
                    index = index + 1
                else
                    append[k] = t[k]
                end
            end
        end
        Self.CopyInto(compact, append)
        return compact, true
    end

    return t, false
end

-- Copy a table and optionally apply a function to every entry
---@param fn function
---@param index boolean
---@param notVal boolean
function Self.Copy(t, fn, index, notVal, ...)
    local fn, u = Util.Functions.New(fn), Self.New()
    for i,v in pairs(t) do
        if fn then
            u[i] = Util.Functions.Call(fn, v, i, index, notVal, ...)
        else
            u[i] = v
        end
    end
    return u
end

-- Copy a table into another table
---@param to table the table in which to copy
---@param from table the table from which to copy
function Self.CopyInto(to, from)
    for k, v in pairs(from) do
        to[k] = v
    end
end

-- Filter by a function
function Self.CopyFilter(t, fn, index, notVal, k, ...)
    fn = Util.Functions.New(fn) or Util.Functions.Id
    local u = Self.New()
    for i,v in pairs(t) do
        if Util.Functions.Call(fn, v, i, index, notVal, ...) then
            Self.Insert(u, k and i, v, k)
        end
    end
    return k and u or Self.List(u)
end

-- Pick specific keys from a table
function Self.CopySelect(t, ...)
    local u = Self.New()
    for _,v in Util.Each(...) do u[v] = t[v] end
    return u
end

-- Omit specific keys from a table
function Self.CopyUnselect(t, ...)
    local u = Self.New()
    for i,v in pairs(t) do
        if not Util.In(i, ...) then
            u[i] = v
        end
    end
    return u
end

-- Filter by a value
---@param t table
---@param k boolean
function Self.CopyOnly(t, val, k)
    local u = Self.New()
    for i,v in pairs(t) do
        if v == val then
            Self.Insert(u, k and i, v, k)
        end
    end
    return u
end

-- Filter by not being a value
---@param val any
---@param k boolean
function Self.CopyExcept(t, val, k)
    local u = Self.New()
    for i,v in pairs(t) do
        if v ~= val then
            Self.Insert(u, k and i, v, k)
        end
    end
    return u
end

-- Filter by a set of key/value pairs in a table
---@param t table
---@param k boolean
function Self.CopyWhere(t, k, ...)
    local u = Self.New()
    for i,v in pairs(t) do
        if Util.In(v, ...) then
            Self.Insert(u, k and i, v, k)
        end
    end
    return u
end

-- Filter by not having a set of key/value pairs in a table
---@param t table
---@param k boolean
function Self.CopyExceptWhere(t, k, ...)
    local u = Self.New()
    for i,v in pairs(t) do
        if not Util.In(v, ...) then
            Self.Insert(u, k and i, v, k)
        end
    end
    return u
end

-- MAP

-- Change table values by applying a function
---@param index boolean
---@param notVal boolean
function Self.Map(t, fn, index, notVal, ...)
    fn = Util.Functions.New(fn)
    for i,v in pairs(t) do
        t[i] = Util.Functions.Call(fn, v, i, index, notVal, ...)
    end
    return t
end

-- Change table keys by applying a function
---@param index boolean
---@param notVal boolean
function Self.MapKeys(t, fn, index, notVal, ...)
    fn = Util.Functions.New(fn)
    local u = Self.New()
    for i,v in pairs(t) do
        u[Util.Functions.Call(fn, v, i, index, notVal, ...)] = v
    end
    return u
end

-- Change table values by extracting a key
---@param t table
function Self.Pluck(t, k)
    for i,v in pairs(t) do
        t[i] = v[k]
    end
    return t
end

-- Flip table keys and values
function Self.Flip(t, val, ...)
    local u = Self.New()
    for i,v in pairs(t) do
        if type(val) == "function" then
            u[v] = val(v, i, ...)
        elseif val ~= nil then
            u[v] = val
        else
            u[v] = i
        end
    end
    return u
end

-- GROUP

-- Group table entries by funciton
---@param t table
---@param fn function(v: any, i: any): any
function Self.Group(t, fn)
    fn = Util.Functions.New(fn) or Util.Functions.Id
    local u = Self.New()
    for i,v in pairs(t) do
        i = fn(v, i)
        u[i] = u[i] or Self.New()
        tinsert(u[i], v)
    end
    return u
end

-- Group table entries by key
---@param t table
function Self.GroupBy(t, k)
    local u = Self.New()
    for i,v in pairs(t) do
        i = v[k]
        u[i] = u[i] or Self.New()
        tinsert(u[i], v)
    end
    return u
end

-- Group the keys with the same values
function Self.GroupKeys(t)
    local u = Self.New()
    for i,v in pairs(t) do
        u[v] = u[v] or Self.New()
        tinsert(u[v], i)
    end
    return u
end

-- SET

-- Make sure all table entries are unique
---@param t table
---@param k boolean
function Self.Unique(t, k)
    local u = Self.New()
    for i,v in pairs(t) do
        if u[v] ~= nil then
            Self.Remove(t, i, k)
        else
            u[v] = true
        end
    end
    Self.Release(u)
    return t
end

-- Subtract the given tables from the table
---@param t table
function Self.Diff(t, ...)
    local k = select(select("#", ...), ...) == true

    for _,v in pairs(t) do
        for i=1, select("#", ...) - (k and 1 or 0) do
            if Util.In(v, (select(i, ...))) then
                Self.Remove(t, i, k)
                break
            end
        end
    end
    return t
end

-- Intersect the table with given tables
---@param t table
function Self.Intersect(t, ...)
    local k = select(select("#", ...), ...) == true

    for _,v in pairs(t) do
        for i=1, select("#", ...) - (k and 1 or 0) do
            if not Util.In(v, (select(i, ...))) then
                Self.Remove(t, i, k)
                break
            end
        end
    end
    return t
end

-- Check if the intersection of the given tables is not empty
---@param t table
function Self.Intersects(t, ...)
    for _,v in pairs(t) do
        local found = true
        for i=1, select("#", ...) do
            if not Util.In(v, (select(i, ...))) then
                found = false
                break
            end
        end

        if found then
            return true
        end
    end
    return false
end

-- CHANGE

---@param i any
---@param v any
---@param k boolean
function Self.Insert(t, i, v, k)
    if k or i and not tonumber(i) then
        t[i] = v
    elseif i then
        tinsert(t, i, v)
    else
        tinsert(t, v)
    end
end

function Self.Remove(t, i, k)
    if k or i and not tonumber(i) then
        t[i] = nil
    elseif i then
        tremove(t, i)
    else
        tremove(t)
    end
end

---@param t table
function Self.Push(t, v)
    tinsert(t, v)
    return t
end

---@param t table
function Self.Pop(t)
    return tremove(t)
end

---@param t table
function Self.Drop(t)
    tremove(t)
    return t
end

---@param t table
function Self.Shift(t)
    return tremove(t, 1)
end

---@param t table
function Self.Unshift(t, v)
    tinsert(t, 1, v)
    return t
end

-- Rotate by l (l>0: left, l<0: right)
---@param t table
---@param l number
function Self.Rotate(t, l)
    l = l or 1
    for i=1, math.abs(l) do
        if l < 0 then
            tinsert(t, 1, tremove(t))
        else
            tinsert(t, tremove(t, 1))
        end
    end
    return t
end

-- Sort a table
local SortFn = function (a, b) return a > b end
function Self.Sort(t, fn)
    fn = fn == true and SortFn or Util.Functions.New(fn) or nil
    table.sort(t, fn)
    return t
end

-- sorts using OrderedPairs (this copies the passed table)
function Self.Sort2(t, flip)
    flip = Util.Objects.Default(flip, false)
    local u = Self.New()
    local p = flip and Util.Tables.Flip(t) or t

    for k, v in Self.OrderedPairs(p) do
        u[k] = v
    end
    return u
end

function Self.SortRecursively(t)
	local u = Self.Sort2(t)

	for i, v in pairs(u) do
		if type(v) == 'table' then
			u[i] = Self.Sort2(v)
		end
	end

	return u
end

local function GenOrderedIndex(t)
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert(orderedIndex, key)
    end
    table.sort(orderedIndex, Util.Functions.CompareMultitype)
    return orderedIndex
end

-- Equivalent of the next function, but returns the keys in the alphabetic
-- order. We use a temporary ordered key table that is stored in the
-- table being iterated.
local function OrderedNext(t, state)
    local key
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = GenOrderedIndex(t)
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1,table.getn(t.__orderedIndex) do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

-- Equivalent of the pairs() function on tables, but allows to iterate in order
function Self.OrderedPairs(t)
    local u = Self.New()
    Self.CopyInto(u, t)
    return OrderedNext, u, nil
end

---
--- return an iterator to a table sorted by its values
---
--- @param t table the table
--- @param fn function optional comparison function  such that (f(x,y) is true if x < y)
function Self.SortedByValue(t, fn)
    fn = fn == true and SortFn or Util.Functions.New(fn) or nil

    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
    end

    table.sort(keys,function(x, y) return fn(t[x], t[y]) end)

    local i = 0
    return function()
        i = i + 1
        return keys[i], t[keys[i]]
    end
end

-- Sort a table which represents an associative array
-- For example
--[[
    t =  {
        ['test'] = {a=1,b='Zed'},
        ['foo'] = {a=2,b='Bar'},
        ['aba'] = {a=100,b='Qre'},
    }

    fn = function (a,b) return a[2].b < b[2].b end

    would yield

    {{'foo', {a = 2, b = 'Bar'}}, {'aba', {a = 100, b = 'Qre'}}, {'test', {a = 1, b = 'Zed'}}}
--]]
function Self.ASort(t, fn)
    local sorted = Self.New()
    for k, v in pairs(t) do table.insert(sorted,{k,v}) end
    Self.Sort(sorted, fn)
    return sorted
end

-- Sort a table of tables by given table keys and default values
local SortByFn = function (a, b) return Util.Compare(b, a) end
function Self.SortBy(t, ...)
    local args = type(...) == "table" and (...) or Self.Tmp(...)
    return Self.Sort(t, function (a, b)
        for i=1, #args, 3 do
            local key, default, fn = args[i], args[i+1], args[i+2]
            fn = fn == true and SortByFn or Util.Functions.New(fn) or Util.Compare

            local cmp = fn(a and a[key] or default, b and b[key] or default)
            if cmp ~= 0 then return cmp == -1 end
        end
    end), Self.ReleaseTmp(args)
end

-- Merge two or more tables
function Self.Merge(t, ...)
    t = t or Self.New()
    local unique = select(select("#", ...), ...) == true

    for i=1,select("#", ...) - (unique and 1 or 0) do
        local tbl, j = (select(i, ...)), 1
        if tbl then
            for k,v in pairs(tbl) do
                if k == j then tinsert(t, v) else t[k] = v end
                j = j + 1
            end
        end
    end

    return unique and Self.Unique(t) or t
end

-- OTHER

-- Convert the table into tuples of n
---@param t table
---@param n number
function Self.Tuple(t, n)
    local u, n, r = Self.New(), n or 2
    for i,v in pairs(t) do
        if not r or #r == n then
            r = Self.New()
            tinsert(u, r)
        end
        tinsert(r, v)
    end
    return u
end

-- Flatten a list of tables by one dimension
local FlattenFn = function (u, v) return Self.Merge(u, v) end
---@param t table
---@return table
function Self.Flatten(t)
    return Self.FoldL(t, FlattenFn, Self.New())
end

-- Wipe multiple tables at once
---@vararg table
function Self.Wipe(...)
    for i=1,select("#", ...) do wipe((select(i, ...))) end
    return ...
end

-- Join a table of strings
function Self.Concat(t, del)
    return Util.Strings.Join(del, t)
end

-- Use Blizzard's inspect tool
function Self.Inspect(t)
    UIParentLoadAddOn("Blizzard_DebugTools")
    DisplayTableInspectorWindow(t)
end

-------------------------------------------------------
--                  Reusable Table                   --
-------------------------------------------------------

-- Store unused tables in a cache to reuse them later

-- A cache for temp tables
Self.tblPool = {}
Self.tblPoolSize = 10

-- For when we need an empty table as noop or special marking
Self.EMPTY = {}

-- For when we need to store nil values in a table
Self.NIL = {}

-- Get a table (newly created or from the cache), and fill it with values
function Self.New(...)
    local t = tremove(Self.tblPool) or {}
    for i=1, select("#", ...) do
        t[i] = select(i, ...)
    end
    return t
end

-- Get a table (newly created or from the cache), and fill it with key/value pairs
function Self.Hash(...)
    local t = tremove(Self.tblPool) or {}
    for i=1, select("#", ...), 2 do
        t[select(i, ...)] = select(i + 1, ...)
    end
    return t
end

-- Add one or more tables to the cache, first parameter can define a recursive depth
---@vararg table|boolean
function Self.Release(...)
    local depth = type(...) ~= "table" and (type(...) == "number" and max(0, (...)) or ... and Self.tblPoolSize) or 0

    for i=1, select("#", ...) do
        local t = select(i, ...)
        if type(t) == "table" and t ~= Self.EMPTY and t ~= Self.NIL then
            if #Self.tblPool < Self.tblPoolSize then
                tinsert(Self.tblPool, t)

                if depth > 0 then
                    for _,v in pairs(t) do
                        if type(v) == "table" then Self.Release(depth - 1, v) end
                    end
                end

                wipe(t)
                setmetatable(t, nil)
            else
                break
            end
        end
    end
end

-- Unpack and release a table
local UnpackFn = function (t, ...) Self.Release(t) return ... end
---@param t table
function Self.Unpack(t)
    return UnpackFn(t, unpack(t))
end

Self.Sparse = {

}

function Self.Sparse.Keys(t)
	local u, index = Self.New(), 1
	for k, _ in Self.Sparse.ipairs(t) do
		tinsert(u, index, k)
		index = index + 1
	end

	return u

end

function Self.Sparse.ipairs(t)
    -- tmpIndex will hold sorted indices, otherwise
    -- this iterator would be no different from pairs iterator
    local tmpIndex = {}
    local index, _ = next(t)
    while index do
        tmpIndex[#tmpIndex+1] = index
        index, _ = next(t, index)
    end
    -- sort table indices
    table.sort(tmpIndex)
    local j = 1

    return function()
        -- get index value
        local i = tmpIndex[j]
        j = j + 1
        if i then
            return i, t[i]
        end
    end
end

-------------------------------------------------------
--                  Temporary Table                  --
-------------------------------------------------------

-- Tables that are automatically released after certain operations (such as loops)

function Self.Temp(...)
    return Self.Tmp(...)
end

function Self.Tmp(...)
    local t = tremove(Self.tblPool) or {}
    for i=1, select("#", ...) do
        local v = select(i, ...)
        t[i] = v == nil and Self.NIL or v
    end
    return setmetatable(t, Self.EMPTY)
end

function Self.HashTmp(...)
    return setmetatable(Self.Hash(...), Self.EMPTY)
end

---@param t table
function Self.IsTmp(t)
    return getmetatable(t) == Self.EMPTY
end

function Self.ReleaseTemp(...)
    Self.ReleaseTmp(...)
end

---@vararg table
function Self.ReleaseTmp(...)
    for i=1, select("#", ...) do
        local t = select(i, ...)
        if type(t) == "table" and Self.IsTmp(t) then Self.Release(t) end
    end
end