local _, AddOn = ...
local Models = AddOn.ImportPackage('Models')
local Date, DateFormat, SemanticVersion = Models.Date, Models.DateFormat, Models.SemanticVersion

local counter, fullDf, shortDf = 0, DateFormat:new("mm/dd/yyyy HH:MM:SS"), DateFormat("mm/dd/yyyy")

local function counterGetAndIncr()
	local value = counter
	counter = counter + 1
	return value
end

--- @class Models.Audit.Audit
local Audit = AddOn.Package('Models.Audit'):Class('Audit')
function Audit:initialize(instant)
	-- all timestamps will be in UTC/GMT and require use cases to convert to local TZ
	local di = instant and Date(instant) or Date('utc')
	-- for versioning history entries, this is independent of add-on version
	-- not named 'version' because of potential conflict with Versioned
	self.auditVersion = SemanticVersion(1, 0)
	-- unique identifier should multiple instances be created at same instant
	self.id = di.time .. '-' .. counterGetAndIncr()
	self.timestamp = di.time
end

function Audit:TimestampAsDate()
	return Date(self.timestamp)
end

function Audit:afterReconstitute(instance)
	instance.auditVersion = SemanticVersion(instance.auditVersion)
	return instance
end

--- @return string the entry's timestamp formatted in local TZ in format of mm/dd/yyyy HH:MM:SS
function Audit:FormattedTimestamp()
	return fullDf:format(self.timestamp)
end

--- @return string the entry's timestamp formatted in local TZ in format of mm/dd/yyyy
function Audit:FormattedDate()
	return shortDf:format(self.timestamp)
end

function Audit:TimestampAsDate()
	return Date(self.timestamp)
end