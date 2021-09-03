local xml2lua = require("xml2lua")
local handler = require("xmlhandler.dom")
local pl = require('pl.path')

function findlast(s, pattern, plain)
    local curr = 0
    repeat
        local next = s:find(pattern, curr + 1, plain)
        if (next) then curr = next end
    until (not next)
    if (curr > 0) then
        return curr
    end
end

function endswith(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

-- returns absolute pathname of specified file
function absolutepath(file)
    local normalized = normalize(file)
    local endAt = findlast(normalized, '/', true)
    return normalized:sub(1, endAt - 1)
end

function normalize(file)
    return file:gsub('\\', '/')
end

function filename(dir, file)
    return normalize(dir .. '/' .. file)
end

-- returns absolute pathname of specified file
function absolutepath(file)
    local normalized = normalize(file)
    local endAt = findlast(normalized, '/', true)
    return normalized:sub(1, endAt - 1)
end

-- this doesn't know how to handle includes within an XML file, FYI
-- the addon parser in WowAddonParser.lua does though
function Load(files, addOnName, addOnNamespace)
    addOnName = addOnName or 'TestAddOn'
    addOnNamespace = addOnNamespace or {}

    for _, toload in pairs(files) do
        print('Loading File @ ' .. toload .. format(' (%s => %s)', tostring(addOnName), dump(addOnNamespace)))
        loadfile(toload)(addOnName, addOnNamespace)
    end
end

function ParseXml(file)
    print('Parsing File @ ' .. file)
    local wowXmlHandler = handler:new()
    local wowXmlParser = xml2lua.parser(wowXmlHandler)
    wowXmlParser:parse(xml2lua.loadFile(file))
    -- xml2lua.printable(wowXmlHandler.root)

    local parsed = {}
    for _, child in pairs(wowXmlHandler.root._children) do
        if type(child) == 'table' and child['_type'] ~= 'COMMENT' then
            table.insert(parsed, child["_attr"].file)
        end
    end
    return parsed
end

function ParseXmlAndLoad(file, addOnName, addOnNamespace)
    local rootDir = pl.dirname(pl.abspath(file))
    local parsed = ParseXml(file)
    for i, toload in ipairs(parsed) do
        toload = filename(rootDir, toload)
        parsed[i] = toload
    end

    Load(parsed, addOnName, addOnNamespace)
end