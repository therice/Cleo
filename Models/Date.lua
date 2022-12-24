-- adapted from https://github.com/lunarmodules/Penlight/blob/master/lua/pl/Date.lua
-- to utilize LibClass
-- probably way too much stuff in here for what is actually used

local _, AddOn = ...
local Util = AddOn:GetLibrary("Util")
local os_time, os_date = time, date

--- @class Models.Date
local Date = AddOn.Package('Models'):Class('Date')
--- @class Models.DateInterval
local DateInterval = AddOn.Package('Models'):Class('DateInterval', Date)
--- @class Models.DateFormat
local DateFormat = AddOn.Package('Models'):Class('DateFormat')

function Date:initialize(t, ...)
    local time
    local nargs = select('#', ...)
    if nargs > 2 then
        local extra = { ... }
        local year = t
        t = {
            year  = year,
            month = extra[1],
            day   = extra[2],
            hour  = extra[3],
            min   = extra[4],
            sec   = extra[5]
        }
    end
    
    if nargs == 1 then
        self.utc = select(1, ...) == true
    end
    
    if Util.Objects.IsNil(t) or t == 'utc' then
        time = os_time()
        self.utc = (t == 'utc')
    elseif Util.Objects.IsNumber(t) then
        time = t
        if self.utc == nil then self.utc = true end
    elseif Util.Objects.IsTable(t) then
        -- copy ctor
        if Date.isInstanceOf(t, Date) then
            time = t.time
            self.utc = t.utc
        else
            if not (t.year and t.month) then
                local lt = os_date('*t')
                if not t.year and not t.month and not t.day then
                    t.year = lt.year
                    t.month = lt.month
                    t.day = lt.day
                else
                    t.year = t.year or lt.year
                    t.month = t.month or (t.day and lt.month or 1)
                    t.day = t.day or 1
                end
            end
            t.day = t.day or 1
            time = os_time(t)
        end
    else
        error("Bad type for Date constructor: " .. type(t), 2)
    end
    
    self:set(time)
end

function Date:set(t)
    self.time = t
    if self.utc then
        self.tab = os_date('!*t', t)
    else
        self.tab = os_date('*t', t)
    end
end

function Date:toUTC()
    local ndate = Date(self)
    if not self.utc then
        ndate.utc = true
        ndate:set(ndate.time)
    end
    return ndate
end

function Date:toLocal()
    local ndate = Date(self)
    if self.utc then
        ndate.utc = false
        ndate:set(ndate.time)
    end
    return ndate
end

function Date.tzone(ts)
    if ts == nil then
        ts = os_time()
    elseif Util.Objects.IsTable(ts) then
        if Date.isInstanceOf(ts, Date) then
            ts = ts.time
        else
            ts = Date(ts).time
        end
    end
    local utc = os_date('!*t', ts)
    local lcl = os_date('*t', ts)
    lcl.isdst = false
    return difftime(os_time(lcl), os_time(utc))
end

for _, c in ipairs { 'year', 'month', 'day', 'hour', 'min', 'sec', 'yday', 'wday' } do
    Date[c] = function(self, val)
        if val then
	        --print(c .. '(' .. tostring(val).. ')')
            assert(Util.Objects.IsNumber(val))
            self.tab[c] = val
            self:set(os_time(self.tab))
            return self
        else
            return self.tab[c]
        end
    end
end

function Date:clear_time()
	return self:hour(0):min(0):sec(0)
end

function Date:end_of_day()
	return self:hour(23):min(59):sec(59)
end

--- name of day of week.
-- @bool full abbreviated if true, full otherwise.
-- @ret string name
function Date:weekday_name(full)
    return os_date(full and '%A' or '%a', self.time)
end

--- name of month.
-- @int full abbreviated if true, full otherwise.
-- @ret string name
function Date:month_name(full)
    return os_date(full and '%B' or '%b', self.time)
end

--- is this day on a weekend?.
function Date:is_weekend()
    return self.tab.wday == 1 or self.tab.wday == 7
end

function Date:add(t)
    local old_dst = self.tab.isdst
    local key, val = next(t)
    self.tab[key] = self.tab[key] + val
    self:set(os_time(self.tab))
    if old_dst ~= self.tab.isdst then
        self.tab.hour = self.tab.hour - (old_dst and 1 or -1)
        self:set(os_time(self.tab))
    end
    return self
end

function Date:last_day()
    local d = 28
    local m = self.tab.month
    while self.tab.month == m do
        d = d + 1
        self:add { day = 1 }
    end
    self:add { day = -1 }
    return self
end

function Date:diff(other)
    local dt = self.time - other.time
    if dt < 0 then error("date difference is negative!", 2) end
    return DateInterval(dt)
end

function Date:__tostring()
    local fmt = '%Y-%m-%dT%H:%M:%S'
    if self.utc then
        fmt = "!" .. fmt
    end
    
    local t = os_date(fmt, self.time)
    if self.utc then
        return t .. 'Z'
    else
        local offs = self:tzone()
        if offs == 0 then
            return t .. 'Z'
        end
        local sign = offs > 0 and '+' or '-'
        local h = math.ceil(offs / 3600)
        local m = (offs % 3600) / 60
        return t .. ('%s%02d:%02d'):format(sign, math.abs(h), m)
    end
end

function Date:__eq(other)
    return self.time == other.time
end

function Date:__lt(other)
    return self.time < other.time
end

function Date:__eq(other)
    return self.time == other.time
end

Date.__sub = Date.diff

function Date:__add(other)
    local nd = Date(self)
    if DateInterval.isInstanceOf(other, DateInterval) then
        other = { sec = other.time }
    end
    
    nd:add(other)
    return nd
end

function DateInterval:initialize(t)
    self:set(t)
end

function DateInterval:set(t)
    self.time = t
    self.tab = os_date('!*t', self.time)
end

local function ess(n)
    if n > 1 then return 's '
    else return ' '
    end
end

function DateInterval:Duration()
    local t = self.tab
    return t.year - 1970, t.month - 1, t.day - 1, t.hour, t.min, t.sec
end

function DateInterval:__tostring()
    local t, res = self.tab, ''
    local y, m, d = t.year - 1970, t.month - 1, t.day - 1
    if y > 0 then res = res .. y .. ' year' .. ess(y) end
    if m > 0 then res = res .. m .. ' month' .. ess(m) end
    if d > 0 then res = res .. d .. ' day' .. ess(d) end
    local h = t.hour
    if h > 0 then res = res .. h .. ' hour' .. ess(h) end
    if t.min > 0 then res = res .. t.min .. ' min ' end
    if t.sec > 0 then res = res .. t.sec .. ' sec ' end
    if res == '' then res = 'zero' end
    return res
end

local formats = {
    d = { 'day', { true, true } },
    y = { 'year', { false, true, false, true } },
    m = { 'month', { true, true } },
    H = { 'hour', { true, true } },
    M = { 'min', { true, true } },
    S = { 'sec', { true, true } },
}

function DateFormat:initialize(fmt)
    if not fmt then
        self.fmt = '%Y-%m-%d %H:%M:%S'
        self.outf = self.fmt
        self.plain = true
        return
    end
    local append = table.insert
    local D, PLUS, OPENP, CLOSEP = '\001', '\002', '\003', '\004'
    local vars, used = {}, {}
    local patt, outf = {}, {}
    local i = 1
    while i < #fmt do
        local ch = fmt:sub(i, i)
        local df = formats[ch]
        if df then
            if used[ch] then error("field appeared twice: " .. ch, 4) end
            used[ch] = true
            -- this field may be repeated
            local _, inext = fmt:find(ch .. '+', i + 1)
            local cnt = not _ and 1 or inext - i + 1
            if not df[2][cnt] then error("wrong number of fields: " .. ch, 4) end
            -- single chars mean 'accept more than one digit'
            local p = cnt == 1 and (D .. PLUS) or (D):rep(cnt)
            append(patt, OPENP .. p .. CLOSEP)
            append(vars, ch)
            if ch == 'y' then
                append(outf, cnt == 2 and '%y' or '%Y')
            else
                append(outf, '%' .. ch)
            end
            i = i + cnt
        else
            append(patt, ch)
            append(outf, ch)
            i = i + 1
        end
    end
    -- escape any magic characters
    fmt = Util.Strings.Escape(table.concat(patt))
    -- fmt = table.concat(patt):gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1')
    -- replace markers with their magic equivalents
    fmt = fmt:gsub(D, '%%d'):gsub(PLUS, '+'):gsub(OPENP, '('):gsub(CLOSEP, ')')
    self.fmt = fmt
    self.outf = table.concat(outf)
    self.vars = vars
end

function DateFormat:format(d)
    if not Date.isInstanceOf(d, Date) then d = Date(d) end
    return date(self.outf, d.time)
end

local parse_date

--- parse a string into a Date object.
-- @string str a date string
-- @return date object
function DateFormat:parse(str)
    assert(Util.Objects.IsString(str))
    if self.plain then
        return parse_date(str, self.us)
    end
    local res = { str:match(self.fmt) }
    if #res == 0 then return nil, 'cannot parse ' .. str end
    local tab = {}
    for i, v in ipairs(self.vars) do
        local name = formats[v][1] -- e.g. 'y' becomes 'year'
        tab[name] = tonumber(res[i])
    end
    -- os.date() requires these fields; if not present, we assume
    -- that the time set is for the current day.
    if not (tab.year and tab.month and tab.day) then
        local today = Date()
        tab.year = tab.year or today:year()
        tab.month = tab.month or today:month()
        tab.day = tab.day or today:day()
    end
    local Y = tab.year
    if Y < 100 then
        -- classic Y2K pivot
        tab.year = Y + (Y < 35 and 2000 or 1999)
    elseif not Y then
        tab.year = 1970
    end
    return Date(tab)
end

function DateFormat:tostring(d)
    local tm
    local fmt = self.outf
    if type(d) == 'number' then
        tm = d
    else
        tm = d.time
        if d.utc then
            fmt = '!' .. fmt
        end
    end
    return os_date(fmt, tm)
end

function DateFormat:US_order(yesno)
    self.us = yesno
end

local months
local parse_date_unsafe
local function create_months()
    local ld, day1 = parse_date_unsafe '2000-12-31', { day = 1 }
    months = {}
    for i = 1, 12 do
        ld = ld:last_day()
        ld:add(day1)
        local mon = ld:month_name():lower()
        months[mon] = i
    end
end

--[[
Allowed patterns:
- [day] [monthname] [year] [time]
- [day]/[month][/year] [time]
]]

local function looks_like_a_month(w)
    return w:match '^%a+,*$' ~= nil
end

local is_number = Util.Strings.IsNumber
local function tonum(s, l1, l2, kind)
    kind = kind or ''
    local n = tonumber(s)
    if not n then error(("% is not a number: '%s'"):format(kind, s)) end
    if n < l1 or n > l2 then
        error(("%s out of range: %s is not between %d and %d"):format(kind, s, l1, l2))
    end
    return n
end

local function parse_iso_end(p, ns, sec)
    -- may be fractional part of seconds
    local _, nfrac, secfrac = p:find('^%.%d+', ns + 1)
    if secfrac then
        sec = sec .. secfrac
        p = p:sub(nfrac + 1)
    else
        p = p:sub(ns + 1)
    end
    -- ISO 8601 dates may end in Z (for UTC) or [+-][isotime]
    -- (we're working with the date as lower case, hence 'z')
    if p:match 'z$' then
        -- we're UTC!
        return sec, { h = 0, m = 0 }
    end
    p = p:gsub(':', '') -- turn 00:30 to 0030
    local _, _, sign, offs = p:find('^([%+%-])(%d+)')
    if not sign then return sec, nil end -- not UTC
    
    if #offs == 2 then offs = offs .. '00' end -- 01 to 0100
    local tz = { h = tonumber(offs:sub(1, 2)), m = tonumber(offs:sub(3, 4)) }
    if sign == '-' then
        tz.h = -tz.h;
        tz.m = -tz.m
    end
    return sec, tz
end

function parse_date_unsafe(s, US)
    s = s:gsub('T', ' ') -- ISO 8601
    local parts = Util.Strings.Split(s:lower(), " ")
    local i, p = 1, parts[1]
    local function nextp()
        i = i + 1;
        p = parts[i]
    end
    local year, min, hour, sec, apm
    local tz
    local _, nxt, day, month = p:find '^(%d+)/(%d+)'
    if day then
        -- swop for US case
        if US then
            day, month = month, day
        end
        _, _, year = p:find('^/(%d+)', nxt + 1)
        nextp()
    else
        -- ISO
        year, month, day = p:match('^(%d+)%-(%d+)%-(%d+)')
        if year then
            nextp()
        end
    end
    if p and not year and is_number(p) then
        -- has to be date
        if #p < 4 then
            day = p
            nextp()
        else
            -- unless it looks like a 24-hour time
            year = true
        end
    end
    if p and looks_like_a_month(p) then
        -- date followed by month
        p = p:sub(1, 3)
        if not months then
            create_months()
        end
        local mon = months[p]
        if mon then
            month = mon
        else error("not a month: " .. p) end
        nextp()
    end
    if p and not year and is_number(p) then
        year = p
        nextp()
    end
    
    if p then
        -- time is hh:mm[:ss], hhmm[ss] or H.M[am|pm]
        _, nxt, hour, min = p:find '^(%d+):(%d+)'
        local ns
        if nxt then
            -- are there seconds?
            _, ns, sec = p:find('^:(%d+)', nxt + 1)
            --if ns then
            sec, tz = parse_iso_end(p, ns or nxt, sec)
            --end
        else
            -- might be h.m
            _, ns, hour, min = p:find '^(%d+)%.(%d+)'
            if ns then
                apm = p:match '[ap]m$'
            else
                -- or hhmm[ss]
                local hourmin
                _, nxt, hourmin = p:find('^(%d+)')
                if nxt then
                    hour = hourmin:sub(1, 2)
                    min = hourmin:sub(3, 4)
                    sec = hourmin:sub(5, 6)
                    if #sec == 0 then sec = nil end
                    sec, tz = parse_iso_end(p, nxt, sec)
                end
            end
        end
    end
    local today
    if year == true then year = nil end
    if not (year and month and day) then
        today = Date()
    end
    day = day and tonum(day, 1, 31, 'day') or (month and 1 or today:day())
    month = month and tonum(month, 1, 12, 'month') or today:month()
    year = year and tonumber(year) or today:year()
    if year < 100 then
        -- two-digit year pivot around year < 2035
        year = year + (year < 35 and 2000 or 1900)
    end
    hour = hour and tonum(hour, 0, apm and 12 or 24, 'hour') or 12
    if apm == 'pm' then
        hour = hour + 12
    end
    min = min and tonum(min, 0, 59) or 0
    sec = sec and tonum(sec, 0, 60) or 0  --60 used to indicate leap second
    local res = Date { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
    if tz then
        -- ISO 8601 UTC time
        local corrected = false
        if tz.h ~= 0 then
            res:add { hour = -tz.h };
            corrected = true
        end
        if tz.m ~= 0 then
            res:add { min = -tz.m };
            corrected = true
        end
        res.utc = true
        -- we're in UTC, so let's go local...
        if corrected then
            res = res:toLocal()
        end-- we're UTC!
    end
    return res
end

function parse_date(s)
    local ok, d = pcall(parse_date_unsafe, s)
    if not ok then
        -- error
        error(format('parse_date(%s) : %s', tostring(s), tostring(d)))
        d = d:gsub('.-:%d+: ', '')
        return nil, d
    else
        return d
    end
end

DateFormat.Short = DateFormat("mm/dd/yyyy")
DateFormat.Full = DateFormat("mm/dd/yyyy HH:MM:SS")