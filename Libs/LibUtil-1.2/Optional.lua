local MAJOR_VERSION = "LibUtil-1.2"
local MINOR_VERSION = 40400

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Optional) or (minor or 0) > MINOR_VERSION then return end

---- @type LibUtil
local Util = lib
--- @class LibUtil.Optional
local Self = Util.Optional
--- @type LibClass
local Class = LibStub("LibClass-1.1")

--- @class LibUtil.Optional.Optional
--- @field public value any  the optional value
local Optional = Class("Optional")
function Optional:initialize(value)
	self.value = value
end

function Optional:rawGet()
	return self.value
end

function Optional:isEmpty()
	return self.value == nil
end

function Optional:isPresent()
	if self.value ~= nil then
		return true
	else
		return false
	end
end

function Optional:ifPresent(fn)
	if self.value ~= nil then
		return fn(self.value)
	else
		return false
	end
end

function Optional:orElse(other)
	if self.value ~= nil then
		return self.value
	else
		return other
	end
end

function Optional:orElseGet(other)
	if self.value ~= nil then
		return self.value
	else
		return other:get()
	end
end

function Optional:orElseThrow(err)
	if self.value ~= nil then
		return self.value
	else
		error(err)
	end
end

function Optional:get()
	if self.value ~= nil then
		return self.value
	else
		error("Optional : NoSuchElementException")
	end
end

function Optional:filter(fn)
	if self.value ~= nil then
		if fn(self.value) then
			return Self.of(self.value)
		end
	end
	return Self.empty()
end

--- @return LibUtil.Optional.Optional result of applying function to value if present, otherwise empty
function Optional:map(fn)
	if not self:isPresent() then
		return Self.empty()
	else
		return Self.ofNillable(fn(self.value))
	end
end

---
--- Similar to map, but the mapping function is one whose result is already an Optional
---
--- @see LibUtil.Optional.Optional.map
--- @return LibUtil.Optional.Optional  result of applying function to value if present, otherwise empty
function Optional:flatMap(fn)
	if not self:isPresent() then
		return Self.empty()
	else
		local result = fn(self.value)
		assert(result, "result of flatMap was not set")
		assert(Util.Objects.IsInstanceOf(result, Optional), "result of flatMap was not an Optional")
		return result
	end
end

function Optional:either(other)
	if self.value ~= nil then
		return Self.of(self.value)
	end
	return other
end

function Optional:__tostring()
	return format("Optional(%s)", Util.Objects.ToString(self.value))
end

--- @return LibUtil.Optional.Optional
function Self.of(value)
	if value ~= nil then
		return Optional(value)
	else
		error("Optional - Value was nil in 'of' function")
	end
end

--- @return LibUtil.Optional.Optional
function Self.empty()
	return Optional(nil)
end

--- @return LibUtil.Optional.Optional
function Self.ofNillable(value)
	return Optional(value)
end