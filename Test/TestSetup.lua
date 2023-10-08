-- params is for passing functions directly to TestSetup in advance of loading files
-- [1] - Boolean indicating if entire AddOn should be loaded
-- [2] - Namespace for establishing global for testing flag
-- [3] - Table of pre-hook functions (for addon loading)
-- [4] - Table of post-hook functions (for addon loading)
local params = {...}
local pl = require('pl.path')
local assert = require("luassert")
local say = require("say")
local addOnTestNs, testNs, loadAddon, logFileName, logFile, caller =
    'Cleo_Testing', nil, nil, nil, nil, pl.abspath(pl.abspath('.') .. '/' .. debug.getinfo(2, "S").source:match("@(.*)$"))

loadAddon = params[1] or false

--local copas = require('copas')
--_G.async = copas.async

-- custom assertions start
--
local function less(state, arguments)
    if not #arguments == 2 then return false end
    return arguments[1] < arguments[2]
end

local function greater(state, arguments)
    if not #arguments == 2 then return false end
    return arguments[1] > arguments[2]
end

local function isa(state, arguments)
    if not #arguments == 2 then return false end
    return type(arguments[1]) == 'table' and getmetatable(arguments[1]).__index == arguments[2]
end

say:set_namespace("en")
say:set("assertion.less.positive", "Expected %s to be smaller than %s")
say:set("assertion.less.negative", "Expected %s to not be smaller than %s")
assert:register("assertion", "less", less, "assertion.less.positive", "assertion.less.negative")

say:set("assertion.greater.positive", "Expected %s to be greater than %s")
say:set("assertion.greater.negative", "Expected %s to not be greater than %s")
assert:register("assertion", "greater", greater, "assertion.greater.positive", "assertion.greater.negative")

say:set("assertion.isa.positive", "Expected object: %s to be of type %s")
say:set("assertion.isa.negative", "Expected object: %s to not be of type %s")
assert:register("assertion", "is_a", isa, "assertion.isa.positive", "assertion.isa.negative")
--
-- custom assertions end
--

function Before()
    local path = pl.dirname(caller)
    local name = pl.basename(caller):match("(.*).lua$")
    testNs = (params[2] or name) .. '_Testing'
    _G[testNs] = true
    logFileName = pl.abspath(path) .. '/' .. name .. '.log'
    logFile = io.open(logFileName, 'w')
    _G[addOnTestNs .. '_GetLogFile'] = function() return logFile end
    _G[addOnTestNs] = true
    _G.print_orig = _G.print
    _G.print = function(...)
        logFile:write(name .. ': ')
        logFile:write(...)
        logFile:write('\n')
        logFile:flush()
    end

    print(testNs .. ' -> true')
    print(addOnTestNs .. ' -> true')
    print("Caller -> FILE(" .. caller .. ") PATH(" .. path .. ") NAME(" .. name .. ")")
end

function ConfigureLogging()
    local success, result = pcall(
            function()
                local Logging = LibStub('LibLogging-1.0')
                Logging:SetRootThreshold(Logging.Level.Trace)
                Logging:SetWriter(
                        function(msg)
                            _G[addOnTestNs .. '_GetLogFile']():write(msg, '\n')
                            _G[addOnTestNs .. '_GetLogFile']():flush()
                        end
                )
            end
    )
    if not success then
        print('Logging configuration failed, not all logging will be written to log file -> ' .. tostring(result))
    else
        print('Logging configured -> ' .. tostring(logFileName))
    end
end

function ResetLogging()
    pcall(
            function()
                local Logging, _ = LibStub('LibLogging-1.0')
                Logging:ResetWriter()
            end
    )
end

local default_eh = function(msg) print(format("ERROR : %s", dump(msg))) end
local eh = default_eh

function seterrorhandler(fn)
    eh = fn
end

function geterrorhandler()
    return eh
end

-- It seems Wow doesn't follow the 5.1 spec for xpcall (no additional arguments),
-- but instead the one from 5.2 where that's allowed.
-- Try to recreate that here.
local xpcall_orig = _G.xpcall
function xpcall_patch()
    --there's an issue on lua5.1 with xpcall accepting function aruments, so patch it
    --_G.xpcall = function(fn, err, ...)  return Dispatchers[select("#", ...)](fn, ...) end
    --_G.xpcall = function(f, err, ...)
    --    return xpcall_orig(function() return f(...) end, err)
    --end

    _G.xpcall = function(f, err, ...)
        local status, code = pcall(f, ...)
        if not status then
            --...sers/tedri/opt/r2d2/R2D2X/Models/History/Traffic.lua:30: The specified data was not of the correct type : table
            --
            --stack traceback:
            --        ...sers/tedri/opt/r2d2/R2D2X/Models/History/Traffic.lua:30: in function 'initialize'
            --        ...ri/opt/r2d2/R2D2X/Libs/LibClass-1.0/LibClass-1.0.lua:159: in function <...ri/opt/r2d2/R2D2X/Libs/LibClass-1.0/LibClass-1.0.lua:156>
            --        (tail call): ?
            --        ./Models/History/Test/TrafficTest.lua:28: in function <./Models/History/Test/TrafficTest.lua:27>
            --
            -- print(code)
            -- print(debug.traceback(1))
            -- print('here')
            geterrorhandler()(code)
            return err(code)
        else
            return status, code
        end
    end
end


local LoadedAddOns = {}

_G.IsAddOnLoaded = function(name)
    --print('IsAddOnLoaded -> ' .. name)
    return LoadedAddOns[name] or false
end

function AddOnLoaded(name, enable)
    WoWAPI_FireEvent("ADDON_LOADED", name)
    LoadedAddOns[name] = true

    if enable then
        _G.IsLoggedIn = function() return true end
        WoWAPI_FireEvent("PLAYER_LOGIN")
    end
end

function PlayerEnteredWorld()
    -- print('PlayerEnteredWorld')
    _G.IsLoggedIn = function() return true end
    WoWAPI_FireEvent("PLAYER_ENTERING_WORLD", true, false)
end

function GuildRosterUpdate()
    --print('GuildRosterUpdate')
    WoWAPI_FireEvent("GUILD_ROSTER_UPDATE", false)
    WoWAPI_FireUpdate()
end

local _async = false
_G.IsAsync = function()
    return _async
end

local copas = require("copas")
function Async(thunk)
    _async = true
    return function()
        copas.loop(
            function()
                thunk(copas)
                _async = false
            end
        )
    end
end

function After()
    if logFile then
        logFile:close()
        logFile = nil
    end
    _G[testNs] = nil
    _G[addOnTestNs] = nil
    _G[addOnTestNs .. '_GetLogFile'] = nil
    _G.print = _G.print_orig
    ResetLogging()
end

function NewAceDb(defaults)
    local AceDB = LibStub('AceDB-3.0')
    -- need to add random # to end or it will have the same data
    return AceDB:New('TestDB' .. random(100000), defaults or {})
end

function GetSize(tbl, includeIndices, includeKeys)
    local size = 0;

    includeIndices = (includeIndices == nil and true) or includeIndices
    includeKeys = (includeKeys == nil and true) or includeKeys

    if (includeIndices and includeKeys) then
        for _, _ in pairs(tbl) do
            size = size + 1
        end

    elseif (includeIndices and not includeKeys) then
        for _, _ in ipairs(tbl) do
            size = size + 1
        end
    elseif (not includeIndices and includeKeys) then
        for key, _ in pairs(tbl) do
            if (type(key) == "string") then
                size = size + 1
            end
        end
    end

    return size;
end


Before()
xpcall_patch()

local thisDir = pl.abspath(debug.getinfo(1).source:match("@(.*)/.*.lua$"))
local wowApi = thisDir .. '/WowApi.lua'
print('Loading WowApi @ ' .. wowApi)
loadfile(wowApi)()

SetTime()

local True = function(...) return true end
local name, addon

if loadAddon then
    local toc = pl.abspath(thisDir .. '/../Cleo.toc')
    print('Loading TOC @ ' .. toc)
    loadfile('Test/WowAddonParser.lua')()
    local preload_fns = params[3] or {}
    tinsert(preload_fns, function(_, addon) addon._IsTestContext = True end)
    name, addon = TestSetup(toc, preload_fns, params[4] or {})
else
    loadfile('Libs/LibStub/LibStub.lua')()
    name, addon = "AddOnName", {}
    addon._IsTestContext = True
end


return name, addon