local _, AddOn = ...
local Util = AddOn:GetLibrary("Util")
--- @type LibClass
local Class = LibStub("LibClass-1.0")
--- @type Models.SemanticVersion
local SemanticVersion = AddOn.Package('Models').SemanticVersion
--- @type Models.Date
local Date = AddOn.Package('Models').Date
--- @type Models.DateFormat
local DateFormat = AddOn.Package('Models').DateFormat
---- @type Models.SemanticVersion
local DefaultVersion = SemanticVersion(1, 0)

-- dumb, doing this for a workaround to get native LibClass toTable() functionality
local B = Class("B")
--- @class Models.Versioned
local Versioned = AddOn.Package('Models'):Class('Versioned', B)
function Versioned:initialize(version, ...)
	B.initialize(self)
	--- @type Models.SemanticVersion
	self.version = version and SemanticVersion(version) or DefaultVersion
	--- @type number
	self.revision = 0
	--- @type table<string>
	self.triggers = {}
	for _, trigger in Util.Objects.Each(...) do
		Util.Tables.Push(self.triggers, trigger)
	end
	self:NewRevision()
end

--- we only want to serialize the player's stripped guid which is enough
function Versioned:toTable()
	local t = Versioned.super.toTable(self)
	Util.Tables.Remove(t, 'triggers')
	return t
end

function Versioned:afterReconstitute(instance)
	instance.version = SemanticVersion(instance.version)
	return instance
end

function Versioned:NewRevision()
	self.revision = Date(GetServerTime(), true).time
end

function Versioned:TriggersNewRevision(attr)
	return Util.Tables.ContainsValue(self.triggers, attr)
end

function Versioned:RevisionAsDate()
	return Date(self.timestamp, true)
end

function Versioned:__tostring()
	return format('%s (%d)', tostring(self.version), self.revision)
end