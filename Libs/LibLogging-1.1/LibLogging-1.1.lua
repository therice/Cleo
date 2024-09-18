local MAJOR_VERSION = "LibLogging-1.1"
local MINOR_VERSION = 40400

---@class LibLogging
local lib, _ = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

-- Basic constants for use with library, with a mapping to hierarchy key
lib.Level = {
    Trace       = "Trace",
    Debug       = "Debug",
    Info        = "Info",
    Warn        = "Warn",
    Error       = "Error",
    Fatal       = "Fatal",
    Disabled    = "Disabled",
}
-- local reference for ease of use
local Level = lib.Level

-- Establish hierarchy of levels
local LevelHierarchy = {"Disabled", "Fatal", "Error", "Warn", "Info", "Debug", "Trace"}
local MaxLevels = #LevelHierarchy
for i=1,MaxLevels do
    LevelHierarchy[LevelHierarchy[i]] = i
end

local LevelColorsRgb = {
    {},
    {0.54510, 0.00000, 0.00000},
    {1.00000, 0.00000, 0.00000},
    {1.00000, 0.98039, 0.31373},
    {0.50196, 0.50196, 0.00000},
    {0.12649, 0.69804, 0.66667},
    {0.56471, 0.93333, 0.56471},
}


local function Colored(c, text)
    return "|cFF" ..
            string.format("%02X%02X%02X", math.floor(255*c[1]), math.floor(255*c[2]), math.floor(255*c[3])) ..
           text .. ":|r"
end

local LevelColors = {
    "",
    --"|cFF8B0000FATAL:|r",
    Colored(LevelColorsRgb[2], "FATAL"),
    --"|cFFFF0000ERROR:|r",
    Colored(LevelColorsRgb[3], "ERROR"),
    --"|cFFFFA500WARN:|r",
    Colored(LevelColorsRgb[4], "WARN"),
    --"|cFF808000INFO:|r",
    Colored(LevelColorsRgb[5], "INFO"),
    --"|cFF20B2AADEBUG:|r",
    Colored(LevelColorsRgb[6], "DEBUG"),
    --"|cFF90EE90TRACE:|r",
    Colored(LevelColorsRgb[7], "TRACE"),
}

-- validates specified level is of correct type and within valid range
-- returns passed level if valid
local function AssertLevel(value)
    assert(type(value) == 'number', format("undefined level `%s'", tostring(level)))
    assert(value, format("undefined level '%s'", tostring(level)))
    assert(value >= LevelHierarchy[LevelHierarchy[1]] and value <= LevelHierarchy[LevelHierarchy[#LevelHierarchy]],
            format("undefined level `%s'", tostring(value)))
    return value
end

-- returns mapping from level to numeric value
-- supports strings or numbers as input
local function GetThreshold(level)
    local value

    if type(level) == "string" then
        value = LevelHierarchy[level]
    elseif type(level) == "number" then
        value = math.floor(tonumber(level))
    end

    return AssertLevel(value)
end

-- expose some internal functionality for purposes of tests
if _G.LibLogging_Testing then
    function lib:GetMinThreshold()
        return LevelHierarchy[LevelHierarchy[1]]
    end

    function lib:GetMaxThreshold()
        return LevelHierarchy[LevelHierarchy[#LevelHierarchy]]
    end
end

-- a numeric value mapping on to level
local RootThreshold = GetThreshold(Level.Disabled)

function lib:GetLevelRGBColor(level)
    return LevelColorsRgb[self:GetThreshold(level)]
end

function lib:GetThreshold(level)
    return GetThreshold(level)
end

function lib:GetRootThreshold()
    return RootThreshold
end

function lib:SetRootThreshold(level)
    RootThreshold = GetThreshold(level)
end

function lib:Enable()
    self:SetRootThreshold(Level.Debug)
end

function lib:Disable()
    self:SetRootThreshold(Level.Disabled)
end

-- @return boolean indicating if messages logged at the specified level would be written to logging output based upon
-- logger threshold
function lib:IsEnabledFor(level)
    -- print(tostring(level) .. ' (' .. GetThreshold(level)  .. ') == '  .. LevelHierarchy[RootThreshold] .. '(' .. RootThreshold .. ')')
    return GetThreshold(level) <= RootThreshold
end

local Writer

function lib:SetWriter(writer)
    Writer = writer
end

function lib:ResetWriter()
    Writer = function(msg) print(msg) end
end

-- set it default to start
lib:ResetWriter()

local function GetDateTime()
    return date("%m/%d/%y %H:%M:%S", time())
end

local function GetCaller()
    local trace = debugstack(4, 1, 0)
    -- E.G.
    -- [12:16:42 PM] [string "@Interface\AddOns\R2D2X\Libs\LibGearPoints-1.2\LibGearPoints-1.2.lua"]:266: in function `GetValue'
    -- the 'gsub' should not be needed if I could write a better regex
    return trace:match("([^\\/]-): in [function|method]"):gsub('"]', '') or trace
end

local function Log(writer, level, fmt, ...)
    -- don't log if specified level is filtered by our root threshold
    local levelThreshold = GetThreshold(level)
    if levelThreshold > RootThreshold then return end

    -- wrap in pcall to prevent logging errors from bombing caller
    -- instead capture and report error as needed
    local success, result = pcall(
        function(f, ...)
                local args = {}
                for i,v in pairs({ ... }) do
                    args[i] = type(v) == 'function' and v() or v
                end

                writer(format(f, unpack(args)))
            end,
            "%s [%s] (%s): " .. fmt,
            LevelColors[levelThreshold],
            "|cFFFFFACD" .. GetDateTime() .. "|r",
            "|cFFB0E0E6" .. GetCaller() .. "|r",
            ...
    )

    if not success then
        print('LibLogging(ERROR) ' .. GetCaller() .. ' : ' .. result)
    end
end

function lib:Log(level, fmt, ...)
    Log(Writer, level, fmt, ...)
end

function lib:Trace(fmt, ...)
    Log(Writer, Level.Trace, fmt, ...)
end

function lib:Info(fmt, ...)
    Log(Writer, Level.Info, fmt, ...)
end

function lib:Debug(fmt, ...)
    Log(Writer, Level.Debug, fmt, ...)
end

function lib:Warn(fmt, ...)
    Log(Writer, Level.Warn, fmt, ...)
end

function lib:Error(fmt, ...)
    Log(Writer, Level.Error, fmt, ...)
end

function lib:Fatal(fmt, ...)
    Log(Writer, Level.Fatal, fmt, ...)
end




