--- @type AddOn
local _, AddOn = ...
AddOn.Libs, AddOn.LibsMinor = {}, {}

function AddOn:AddLibrary(name, major, minor)
    if not name then error("Library name was not specified") end
    if not major then error("Library version was not specified") end
    -- minor is entirely optional and either (a) the minor version or (b) boolean for silent loading

    -- in this case: `major` is the lib table and `minor` is the minor version
    if type(major) == 'table' and type(minor) == 'number' then
        self.Libs[name], self.LibsMinor[name] = major, minor
    else -- in this case: `major` is the lib name and `minor` is the silent switch
        self.Libs[name], self.LibsMinor[name] = LibStub(major, minor)
    end
end

function AddOn:GetLibrary(name)
    if not name then error("Library name was not specified") end
    if not self.Libs[name] then
        error(format("Library '%s' not found - was it loaded via AddLibrary?", name))
    end
    return self.Libs[name], self.LibsMinor[name]
end

if AddOn._IsTestContext('Library') then
    function AddOn:DiscardLibraries()
        AddOn.Libs, AddOn.LibsMinor = {}, {}
    end
end