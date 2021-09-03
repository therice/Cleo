-- Functionality below is intended to provide package/class like semantics to Lua
-- Extremely rudimentary, but provides easy and consistent mechanism to namespace and define classes
-- Both package and class support based upon LibClass library
--- @type AddOn
local _, AddOn = ...
local Class = LibStub("LibClass-1.0")

local pkgs = {}

-- for defining a package that can be later imported
-- classes can the be attached to packages for namespacing
--- @class Package
local Package = Class('Package')
function Package:initialize(name)
    self.name = name
    self.classes = {}
end

-- create a class associated with this package
function Package:Class(name, super)
    if self.classes[name] then error(format("Class '%s' already defined in Package '%s'", name, self.name)) end
    local class = AddOn.Class(name, super)
    self.classes[name] = class
    return class
end

-- easy access to class via Package.Class
function Package:__index(name)
    -- print(format('__index(%s)', tostring(name)))
    local c = self.classes[name]
    if not c then error(format("Class '%s' does not exist in Package '%s'", name, self.name)) end
    return c
end

-- define a new class which isn't associated with a package
-- useful for scoping classes to only where needed
function AddOn.Class(name, super)
    -- class names must always be string
    assert(name and type(name) == 'string', 'Class name was not provided')
    if super then assert(type(super) == 'table', format("Superclass was of incorrect type '%s'", type(super))) end
    return Class(name, super)
end

-- get existing or define new package
--- @return Package
function AddOn.Package(name)
    assert(type(name) == 'string')
    local pkg = pkgs[name]
    if not pkg then
        pkg = Package(name)
        pkgs[name] = pkg
    end
    return pkg
end

-- get an existing package, fails if not defined
--- @return Package
function AddOn.ImportPackage(name)
    assert(type(name) == "string")
    local pkg = pkgs[name]
    if not pkg then error(format("Package '%s' does not exist", name)) end
    return pkg
end

if AddOn._IsTestContext('Package') then
    function Package:DiscardClasses()
        self.classes = {}
    end

    function AddOn.DiscardPackages()
        for _, p in pairs(pkgs) do
            p:DiscardClasses()
        end
        pkgs = {}
    end

end