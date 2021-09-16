-- adapted from https://github.com/kikito/semver.lua/blob/master/spec/semver_spec.lua
-- into being LibClass compatible

local _, AddOn = ...
local Util, Logging = AddOn:GetLibrary("Util"), AddOn:GetLibrary("Logging")
--- @class Models.SemanticVersion
local SemanticVersion = AddOn.Package('Models'):Class('SemanticVersion')

local function checkPositiveInteger(number, name)
    assert(number >= 0, name .. ' must be a valid positive number')
    assert(math.floor(number) == number, name .. ' must be an integer')
end

local function parsePrereleaseAndBuildWithSign(str)
    local prereleaseWithSign, buildWithSign = str:match("^(-[^+]+)(+.+)$")
    if not (prereleaseWithSign and buildWithSign) then
        prereleaseWithSign = str:match("^(-.+)$")
        buildWithSign      = str:match("^(+.+)$")
    end
    assert(prereleaseWithSign or buildWithSign, ("The parameter %q must begin with + or - to denote a prerelease or a build"):format(str))
    return prereleaseWithSign, buildWithSign
end

local function parsePrerelease(prereleaseWithSign)
    if prereleaseWithSign then
        local prerelease = prereleaseWithSign:match("^-(%w[%.%w-]*)$")
        assert(prerelease, ("The prerelease %q is not a slash followed by alphanumerics, dots and slashes"):format(prereleaseWithSign))
        return prerelease
    end
end

local function parseBuild(buildWithSign)
    if buildWithSign then
        local build = buildWithSign:match("^%+(%w[%.%w-]*)$")
        assert(build, ("The build %q is not a + sign followed by alphanumerics, dots and slashes"):format(buildWithSign))
        return build
    end
end

local function parsePrereleaseAndBuild(str)
    if not Util.Strings.IsSet(str) then return nil, nil end
    
    local prereleaseWithSign, buildWithSign = parsePrereleaseAndBuildWithSign(str)
    
    local prerelease = parsePrerelease(prereleaseWithSign)
    local build = parseBuild(buildWithSign)
    
    return prerelease, build
end


local function parseVersion(str)
    return str:match("^(%d+)%.?(%d*)%.?(%d*)(.-)$")
end

local function isVersion(str)
    local major = parseVersion(str)
    return Util.Objects.IsString(major)
end

local function parseVersionAndValidate(str)
    local sMajor, sMinor, sPatch, sPrereleaseAndBuild = parseVersion(str)
    assert(Util.Objects.IsString(sMajor), ("Could not extract version number(s) from %q"):format(str))
    local major, minor, patch = tonumber(sMajor), tonumber(sMinor), tonumber(sPatch)
    local prerelease, build = parsePrereleaseAndBuild(sPrereleaseAndBuild)
    return major, minor, patch, prerelease, build
end

local function compare(a,b)
    return a == b and 0 or a < b and -1 or 1
end

local function compareIds(myId, otherId)
    if myId == otherId then return  0
    elseif not myId    then return -1
    elseif not otherId then return  1
    end
    
    local selfNumber, otherNumber = tonumber(myId), tonumber(otherId)
    
    if selfNumber and otherNumber then -- numerical comparison
        return compare(selfNumber, otherNumber)
    -- numericals are always smaller than alphanums
    elseif selfNumber then
        return -1
    elseif otherNumber then
        return 1
    else
        return compare(myId, otherId) -- alphanumerical comparison
    end
end

local function smallerIdList(myIds, otherIds)
    local myLength = #myIds
    local comparison
    
    for i=1, myLength do
        comparison = compareIds(myIds[i], otherIds[i])
        if comparison ~= 0 then
            return comparison == -1
        end
        -- if comparison == 0, continue loop
    end
    
    return myLength < #otherIds
end

local function smallerPrerelease(mine, other)
    if mine == other or not mine
        then return false
    elseif not other
        then return true
    end
    
    return smallerIdList(Util.Strings.Split(mine, '.'), Util.Strings.Split(other, '.'))
end

--- @field public major Models.SemanticVersion
--- @field public minor Models.SemanticVersion
--- @field public patch Models.SemanticVersion
--- @field public prerelease Models.SemanticVersion
--- @field public build Models.SemanticVersion
function SemanticVersion:initialize(major, minor, patch, prerelease, build)
    assert(major, "At least one parameter is needed")
    
    if Util.Objects.IsString(major) then
        major,minor,patch,prerelease,build = parseVersionAndValidate(major)
    elseif Util.Objects.IsTable(major) then
        major,minor,patch,prerelease,build = major.major, major.minor, major.patch, major.prerelease, major.build
    end

    patch = patch or 0
    minor = minor or 0
    
    checkPositiveInteger(major, "major")
    checkPositiveInteger(minor, "minor")
    checkPositiveInteger(patch, "patch")
    
    self.major = major
    self.minor = minor
    self.patch = patch
    self.prerelease = prerelease
    self.build = build
end

-- simple wrapper around SemanticVersion creation to allow for handling of
-- invalid inputs
function SemanticVersion.Create(major, minor, patch, prerelease, build)
    return pcall(function ()
        return SemanticVersion(major, minor, patch, prerelease, build)
    end)
end

function SemanticVersion.Is(value)
   return isVersion(value)
end

function SemanticVersion:nextMajor()
    return SemanticVersion:new(self.major + 1, 0, 0)
end

function SemanticVersion:nextMinor()
    return SemanticVersion:new(self.major, self.minor + 1, 0)
end

function SemanticVersion:nextPatch()
    return SemanticVersion:new(self.major, self.minor, self.patch + 1)
end

function SemanticVersion:__tostring()
    local buffer = { ("%d.%d.%d"):format(self.major, self.minor, self.patch) }
    if self.prerelease then table.insert(buffer, "-" .. self.prerelease) end
    if self.build      then table.insert(buffer, "+" .. self.build) end
    return table.concat(buffer)
end

function SemanticVersion:__eq(other)
    return self.major == other.major and
            self.minor == other.minor and
            self.patch == other.patch and
            self.prerelease == other.prerelease
end

function SemanticVersion:__lt(other)
    if self.major ~= other.major then return self.major < other.major end
    if self.minor ~= other.minor then return self.minor < other.minor end
    if self.patch ~= other.patch then return self.patch < other.patch end
    return smallerPrerelease(self.prerelease, other.prerelease)
end

function SemanticVersion:__pow(other)
    if self.major == 0 then
        return self == other
    end
    return self.major == other.major and
            self.minor <= other.minor
end