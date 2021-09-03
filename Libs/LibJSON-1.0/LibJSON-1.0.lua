local MAJOR_VERSION = "LibJSON-1.0"
local MINOR_VERSION = 20502

local lib, minor = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib or (minor or 0) > MINOR_VERSION then return end

lib.Engine = nil

local function assertEngine()
    if not lib.Engine then error("JSON engine has not been specified") end
end

function lib:Encode(value, etc, options)
    assertEngine()
    return lib.Engine:encode(value, etc, options)
end


function lib:Decode(text, etc, options)
    assertEngine()
    return lib.Engine:decode(text, etc, options)
end

