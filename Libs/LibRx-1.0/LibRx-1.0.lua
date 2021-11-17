local MAJOR_VERSION = "LibRx-1.0"
local MINOR_VERSION = 20502

--- @class LibRx
local Lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not Lib then return end

local Util = LibStub('LibUtil-1.1')

local classes = {}
local function ClassesIndex(_, name, resolved)
    -- wow, LibItemCache iterates all loaded libraries and has assumptions/expectations
    -- about how indexing works, so short circuit here if name represents that usage
    if Util.Strings.Equal(name, 'IsItemCache') then
        return nil
    end

    local c = Util.Tables.Get(classes, name)
    if not c then error(format("LibRx - package or class '%s' does not exist", resolved and (resolved .. '.' .. name) or name)) end
    if type(c) == 'table' and not rawget(c, 'clazz') then
        c = setmetatable(c, {__index = function(k, v) ClassesIndex(k, v, name) end})
    end
    return c
end

setmetatable(Lib, {__index = ClassesIndex})

local Class_MT = {
    __tostring = function(self) return self.clazz.pkg .. '.' .. self.clazz.name end
}

-- if you're calling this from outside the actual library, you're doing it wrong
-- there should be no need interact with the library other than straight table/member access
--
-- e.g. Lib.rx.Observer or Lib['rx.Observer']
--
function Lib:_DefineClass(pkg, name, super)
    assert(pkg and type(pkg) == 'string', 'LibRx - package name was not provided')
    assert(name and type(name) == 'string', 'LibRx - class name was not provided')
    if super then assert(type(super) == 'table', format("LibRx - superclass was of incorrect type '%s'", type(super))) end

    local p, class, fullName = rawget(classes, pkg) or {}, nil, pkg .. '.' .. name
    class = rawget(p, name) or nil
    if class then error(format("LibRx - class already defined at '%s'", fullName)) end

    class = setmetatable({
        clazz = {
            pkg = pkg,
            name = name,
        }
    }, Class_MT)

    if super then class = setmetatable(class, super) end
    Util.Tables.Set(classes, fullName, class)
    return class
end


function Lib._IsA(object, class)
    return type(object) == 'table' and getmetatable(object).__index == class
end