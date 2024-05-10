local _, AddOn = ...
local Util = AddOn:GetLibrary("Util")
--- @type LibClass
local Class = LibStub("LibClass-1.1")
--- @type Models.SemanticVersion
local SemanticVersion = AddOn.Package('Models').SemanticVersion
--- @type Models.Date
local Date = AddOn.Package('Models').Date
---- @type Models.SemanticVersion
local DefaultVersion = SemanticVersion(1, 0)

local Triggerable = {
	static = {
		triggers = {},
		AddTriggers = function(self, ...)
			local triggers = self.triggers
			for _, attr in Util.Objects.Each(...) do
				if not Util.Tables.ContainsValue(triggers, attr) then
					Util.Tables.Push(triggers, attr)
				end
			end
		end
	},
	included = function(_, clazz)
		clazz.isTriggerable = true
	end,
	TriggersNewRevision = function(self, attr)
		return Util.Tables.ContainsValue(self.clazz.static.triggers, attr)
	end
}
-- dumb, doing this for a workaround to get native LibClass toTable() functionality
local B = Class("B")
--- @class Models.Versioned
local Versioned = AddOn.Package('Models'):Class('Versioned', B):include(Triggerable)

function Versioned:initialize(version)
	B.initialize(self)
	--- @type Models.SemanticVersion
	self.version = version and SemanticVersion(version) or DefaultVersion
	--- @type number
	self.revision = 0
	self:NewRevision()
end

-- version is for compatibility across definitions
-- revision says nothing about whether 'content' is the same, just tracks the iteration of the instance
function Versioned.ExcludeAttrsInHash(clazz)
	if clazz.static.isHashable then
		clazz.static:ExcludeAttrsInHash('version', 'revision')
	end
end

function Versioned.IncludeAttrsInRef(clazz)
	if clazz.static.isReferenceable then
		clazz.static:IncludeAttrsInRef('revision', 'version')
	end
end

--- we only want to serialize the player's stripped guid which is enough
function Versioned:toTable()
	local t = Versioned.super.toTable(self)
	return t
end

function Versioned:afterReconstitute(instance)
	instance.version = SemanticVersion(instance.version)
	return instance
end

function Versioned:NewRevision(revision)
	revision = Util.Objects.Default(revision, GetServerTime())
	if not Util.Objects.IsNumber(revision) then error('revision must be a number') end
	-- before/after is for same instant, primarily for testing stuff (which could be conditionalized here)
	local before = self.revision
	self.revision = Date(revision, true).time
	if before == self.revision then
		self.revision = self.revision + 1
	end
end

function Versioned:RevisionAsDate()
	return Date(self.revision, true)
end

function Versioned:__tostring()
	return format('%s (%d)', tostring(self.version), self.revision)
end