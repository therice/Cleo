local MAJOR_VERSION = "LibUtil-1.1"
local MINOR_VERSION = 20502

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Strings) or (minor or 0) > MINOR_VERSION then return end

local Util = lib
--- @class LibUtil.Strings
local Self = Util.Strings

function Self.IsSet(str)
    return type(str) == "string" and str:trim() ~= "" or false
end

function Self.IsEmpty(str)
    return not Self.IsSet(str)
end

function Self.StartsWith(str, str2)
    return  type(str) == "string" and
            type(str2) == "string" and
            str:sub(1, str2:len()) == str2
end

function Self.EndsWith(str, str2)
    return  type(str) == "string" and
            type(str2) == "string" and
            str:sub(-str2:len()) == str2
end

function Self.Equal(str1, str2)
    if str1 == nil or str2 == nil then return str1 == str2 end
    if Self.IsEmpty(str1) then return Self.IsEmpty(str2) end
    return str1 == str2
end

function Self.Wrap(str, before, after)
    if Self.IsEmpty(str) then return "" end
    return (before or " ") .. str .. (after or before or " ")
end

function Self.Prefix(str, prefix)
    return Self.Wrap(str, prefix, "")
end

function Self.Postfix(str, postfix)
    return Self.Wrap(str, "", postfix)
end

-- Split string on delimiter
function Self.Split(str, del)
    local t = Util.Tables.New()
    for v in (str .. del):gmatch("(.-)" .. del:gsub(".", "%%%1")) do
        tinsert(t, v)
    end
    return t
end

function Self.Join2(del, fn, ...)
    local s = ""
    for _,v in Util.Each(...) do
        -- dubious check for \n'
        if fn(v) then
            s = s .. (s == "" and "" or del or " ") .. v
        end
    end
    return s
end

function Self.Join(del, ...)
    return Self.Join2(
            del,
            function(v) return not Self.IsEmpty(v) end,
            ...
    )
end

function Self.UcFirst(str)
    return str:sub(1, 1):upper() .. str:sub(2)
end

function Self.LcFirst(str)
    return str:sub(1, 1):lower() .. str:sub(2)
end


function Self.Lower(str)
    return string.lower(str or "")
end

function Self.IsLower(s)
    return (s == Self.Lower(s))
end

function Self.Upper(str)
    return string.upper(str or "")
end

function Self.IsUpper(s)
    return (s == Self.Upper(s))
end

function Self.IsNumber(str)
    return type(str) == 'string' and tonumber(str) ~= nil
end

function Self.Abbr(str, length)
    return str:len() <= length and str or str:sub(1, length) .. "..."
end

function Self.Color(r, g, b, a)
    return ("%.2x%.2x%.2x%.2x"):format((a or 1) * 255, (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
end

-- this replaces 'len' characters starting at 'from' in a string with 'sub
-- it does not replace an occurrence of a string in another
-- use string:gsub(replace, replace_with) for that
function Self.Replace(str, from, len, sub)
    from, len, sub = from or 1, len or str:len(), sub or ""
    local to = from < 0 and str:len() + from + len + 1 or from + len
    return str:sub(1, from - 1) .. sub .. str:sub(to)
end

---@param str string
---@param del string
function Self.ToCamelCase(str, del)
    local s = ""
    for v in str:gmatch("[^" .. (del or "%p%s") .. "]+") do
        s = s .. Self.UcFirst(v:lower())
    end
    return Self.LcFirst(s)
end

---@param str string
---@param del string
function Self.FromCamelCase(str, del, case)
    local s = str:gsub("%u", (del or " ") .. "%1")
    return case == true and s:upper() or case == false and s:lower() or s
end

function Self.ToString(val, depth)
    return Util.Objects.ToString(val, depth)
end

function Self.Escape(s)
    return (s:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1'))
end

function Self.RPad(s, l, c)
    return s .. string.rep(c or ' ', l - #s)
end