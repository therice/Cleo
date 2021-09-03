loadfile('Test/WowXmlParser.lua')()

local Addon = {
    toc = nil,
    attrs = {},
    files = {},
}
Addon.__index = Addon

setmetatable(Addon, {
    __call = function (cls, ...)
        return cls:new(...)
    end,
})

function Addon:new(toc)
    return setmetatable({
        toc = toc,
        attrs = {},
        files = {},
    }, Addon)
end

function Addon:GetProperty(k)
    return self.attrs[k]
end

function Addon:SetProperty(k, v)
    self.attrs[k] = v
end

function Addon:AddFile(f)
    table.insert(self.files, f)
end

function Addon:ResolveFiles(from, files, resolutions)
    from = from or absolutepath(self.toc)
    files = files or self.files
    resolutions = resolutions or {}
    
    -- print('Performing resolution from ' .. from)

    for _, file in pairs(files) do
        local resolvedFile =  filename(from, file)
        print('Resolved ' .. file .. ' @ ' .. resolvedFile)
        -- LUA extension, straight include
        if endswith(resolvedFile, '.lua') then
            table.insert(resolutions, resolvedFile)
        -- XML extension, resole again
        elseif endswith(resolvedFile, '.xml') then
            local rootPath = absolutepath(resolvedFile)
            -- print('New root for resolution is ' .. rootPath)
            -- print('Parsing ' .. resolvedFile)
            local parsed = ParseXml(resolvedFile)
            self:ResolveFiles(rootPath, parsed, resolutions)
        else
            error(format("Unable to handle %s", resolvedFile))
        end
    end

    return resolutions
end

-- https://wow.gamepedia.com/TOC_format
function ParseTOC(toc)
    local file = assert(io.open(toc, "r"))
    local addon = Addon(toc)
    print('Parsing Addon TOC @ ' .. addon.toc)
    while true do
        local line = file:read()
        if line == nil then break end
        -- remove leading and trailing spaces
        line = line:match("^%s*(.-)%s*$")
        -- metadata
        if line:sub(1, 2) == '##' then
            local TagValue = line:match("##[ ]?(.*)")
            local Tag, Value = string.match(TagValue, "([^:]*):[ ]?(.*)")
            if Tag and Value then
                addon:SetProperty(Tag, Value)
            end
        -- comment or empty line
        elseif line:sub(1, 1) == '#' or line:len() == 0 then
            -- no-op
        else
            addon:AddFile(line)
        end
    end

    file:close()
    return addon
end

function TestSetup(toc, preload_functions, postload_functions)
    -- The loading of addon source may redefine print function, capture it before starting
    preload_functions = preload_functions or {}
    postload_functions = postload_functions or {}
    local addon = ParseTOC(toc)
    local load = addon:ResolveFiles()
    local addOnName  = addon:GetProperty("X-AddonName")
    local addOnNamespace = {}
    -- print("Parsed Addon '" .. addOnName .."'")

    if #preload_functions > 0 then
        -- print('Invoking Preload Functions (' .. #preload_functions .. ')')
        for _, f in pairs(preload_functions) do f(addOnName, addOnNamespace) end
    end
    
    -- from WowXmlParser.lua
    Load(load, addOnName, addOnNamespace)

    if #postload_functions > 0 then
        -- print('Invoking Preload Functions (' .. #preload_functions .. ')')
        for _, f in pairs(postload_functions) do f(addOnName, addOnNamespace) end
    end

    -- not generic, specific to this addon
    -- addOnNamespace.defaults.profile.logThreshold = addOnNamespace.Libs.Logging.Level.Trace
    ConfigureLogging()
    return addOnName, addOnNamespace
end

