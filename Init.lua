local AceAddon, AceAddonMinor = LibStub('AceAddon-3.0')
local AddOnName, AddOn = ...

--- @class AddOn
AddOn = AceAddon:NewAddon(AddOn, AddOnName, 'AceConsole-3.0', 'AceEvent-3.0', "AceSerializer-3.0", "AceHook-3.0", "AceTimer-3.0", "AceBucket-3.0")
AddOn:SetDefaultModuleState(false)
_G[AddOnName] = AddOn

-- just capture version here, it will be turned into semantic version later
-- as we don't have access to that model yet here
AddOn.version = GetAddOnMetadata(AddOnName, "Version")
AddOn.author = GetAddOnMetadata(AddOnName, "Author")
--@debug@
-- if local development and not substituted, then use a dummy version
if AddOn.version == '@project-version@' then
    AddOn.version = '2021.1.0-dev'
end
--@end-debug@

AddOn.Timer = C_Timer
AddOn.Timer.Schedule = function(scheduler)
    assert(scheduler and type(scheduler) == 'function')
    AddOn.Timer.After(0, scheduler)
end

do
    AddOn:AddLibrary('CallbackHandler', 'CallbackHandler-1.0')
    AddOn:AddLibrary('Class', 'LibClass-1.0')
    AddOn:AddLibrary('Logging', 'LibLogging-1.0')
    AddOn:AddLibrary('SHA', 'LibSHA-1.0')
    AddOn:AddLibrary('Util', 'LibUtil-1.1')
    AddOn:AddLibrary('Deflate', 'LibDeflate')
    AddOn:AddLibrary('Base64', 'LibBase64-1.0')
    AddOn:AddLibrary('Rx', 'LibRx-1.0')
    AddOn:AddLibrary('MessagePack', 'LibMessagePack-1.0')
    AddOn:AddLibrary('AceAddon', AceAddon, AceAddonMinor)
    AddOn:AddLibrary('AceEvent', 'AceEvent-3.0')
    AddOn:AddLibrary('AceTimer', 'AceTimer-3.0')
    AddOn:AddLibrary('AceHook', 'AceHook-3.0')
    AddOn:AddLibrary('AceLocale', 'AceLocale-3.0')
    AddOn:AddLibrary('AceConsole', 'AceConsole-3.0')
    AddOn:AddLibrary('AceComm', 'AceComm-3.0')
    AddOn:AddLibrary('AceSerializer', 'AceSerializer-3.0')
    AddOn:AddLibrary('AceGUI', 'AceGUI-3.0')
    AddOn:AddLibrary('AceDB', 'AceDB-3.0')
    AddOn:AddLibrary('AceBucket', 'AceBucket-3.0')
    AddOn:AddLibrary('AceConfig', 'AceConfig-3.0')
    AddOn:AddLibrary('AceConfigCmd', 'AceConfigCmd-3.0')
    AddOn:AddLibrary('AceConfigDialog', 'AceConfigDialog-3.0')
    AddOn:AddLibrary('AceConfigRegistry', 'AceConfigRegistry-3.0')
    AddOn:AddLibrary('ItemUtil', 'LibItemUtil-1.1')
    AddOn:AddLibrary('Window', 'LibWindow-1.1')
    AddOn:AddLibrary('ScrollingTable', 'ScrollingTable')
    AddOn:AddLibrary('Dialog', 'LibDialog-1.0')
    AddOn:AddLibrary('DataBroker', 'LibDataBroker-1.1')
    AddOn:AddLibrary('DbIcon', 'LibDBIcon-1.0')
    AddOn:AddLibrary('GuildStorage', 'LibGuildStorage-1.3')
    AddOn:AddLibrary('Encounter', 'LibEncounter-1.0')
    AddOn:AddLibrary('JSON', 'LibJSON-1.0')
end

AddOn.Locale = AddOn:GetLibrary("AceLocale"):GetLocale(AddOn.Constants.name)

--- @type Logging
local Logging = AddOn:GetLibrary("Logging")
---@type LibUtil
local Util = AddOn:GetLibrary("Util")


--@debug@
Logging:SetRootThreshold(AddOn._IsTestContext() and Logging.Level.Trace or Logging.Level.Debug)
--@end-debug@

-- Augment constants with some stuff that requires initial bootstrapping to be completed first
do
    for i, v in pairs(Util.Tables.ASort(AddOn.Constants.EquipmentLocations, function(a, b) return a[2] < b[2] end)) do
        AddOn.Constants.EquipmentLocationsSort[i] = v[1]
    end
end


local function GetDbValue(self, db, i, ...)
    local path = Util.Objects.IsTable(i) and tostring(i[#i]) or Util.Strings.Join('.', i, ...)
    Logging:Trace("GetDbValue(%s, %s, %s)", self:GetName(), tostring(db), path)
    return Util.Tables.Get(db, path)
end

local function SetDbValue(self, db, i, v)
    local path = Util.Objects.IsTable(i) and tostring(i[#i]) or i
    Logging:Trace("SetDbValue(%s, %s, %s, %s)", self:GetName(), tostring(db), tostring(path), Util.Objects.ToString(v))
    Util.Tables.Set(db, path, v)
    if self['GenerateConfigChangedEvents'] and self:GenerateConfigChangedEvents() then
        AddOn:ConfigChanged(self:GetName(), path)
    end
end

AddOn.GetDbValue = GetDbValue
AddOn.SetDbValue = SetDbValue

local ModulePrototype = {
    IsDisabled = function (self, _)
        Logging:Trace("Module:IsDisabled(%s) : %s", self:GetName(), tostring(not self:IsEnabled()))
        return not self:IsEnabled()
    end,
    SetEnabled = function (self, _, v)
        if v then
            Logging:Trace("Module:SetEnabled(%s) : Enabling module", self:GetName())
            self:Enable()
        else
            Logging:Trace("Module:SetEnabled(%s) : Disabling module ", self:GetName())
            self:Disable()
        end
        self.db.profile.enabled = v
        Logging:Trace("Module:SetEnabled(%s) : %s", self:GetName(), tostring(self.db.profile.enabled))
    end,
    GetDbValue = function(self, db, ...)
        if not Util.Objects.IsTable(db) then
            return GetDbValue(self, self.db.profile, db, ...)
        else
            return GetDbValue(self, db, ...)
        end
    end,
    SetDbValue = function(self, db, ...)
        if not Util.Objects.IsTable(db) then
            SetDbValue(self, self.db.profile, db, ...)
        else
            SetDbValue(self, db, ...)
        end
    end,
    GenerateConfigChangedEvents = function(self)
        return false
    end,
    -- will provide the default value used for bootstrapping a module's db
    -- will only return a value if the module has a 'Defaults' attribute
    GetDefaultDbValue = function(self, ...)
        if self.defaults then
            return Util.Tables.Get(self.defaults, Util.Strings.Join('.', ...))
        end
        return nil
    end,
    -- specifies if module should be enabled on startup
    EnableOnStartup = function (self)
        local enable = (self.db and ((self.db.profile and self.db.profile.enabled) or self.db.enabled)) or false
        Logging:Debug("EnableOnStartup(%s) : %s", self:GetName(), tostring(enable))
        return enable
    end,
    -- a function which is invoked for determining configuration supplements, which will be added to generic configuration layout
    -- must return a tuple
    --  1, a string which is the configuration group name (all settings will be bucketed here)
    --  2, a function which is invoked and takes a container for adding configuration settings
    ConfigSupplement = function(self)
        return nil, nil
    end,
    -- a function which is invoked for determining launchpad supplements, which will be added as a new layout
    -- must return a tuple
    --  1, a string which is the launchpad module display name
    --  2, a function which is invoked and takes a container for adding a launchpad module
    --  3, a boolean indicating if enable/disable support should be setup
    LaunchpadSupplement = function(self)
        return nil, nil, false
    end,
    -- implement to provide data import functionality for a module
    ImportData = function(self, data, into)
        Logging:Debug("ImportData(%s)", self:GetName())

        into = into or (self.db and self.db.profile or nil)
        if not into then return end

        local count = 0

        for k, v in pairs(data) do
            Logging:Trace("ImportData(%s) : importing key %s", self:GetName(), tostring(k))
            into[k] = v
            count = count + 1
        end

        Logging:Debug("ImportData(%s) : imported %d entries", self:GetName(), count)
        -- fire message that the configuration table has changed (this is handled on per module basis, as necessary)
        AddOn:ConfigChanged(self:GetName())
        -- notify config registry of change as well, this updates configuration UI if displayed
        AddOn:GetLibrary('AceConfigRegistry'):NotifyChange(AddOnName)
        AddOn:Print(format(AddOn.Locale['import_successful'], AddOn.GetDateTime(), self:GetName()))
    end,
    ModuleSettings = function(self)
        return AddOn:ModuleSettings(self:GetName())
    end
}

AddOn:SetDefaultModulePrototype(ModulePrototype)

-- stuff below here is strictly for use during tests of addon
-- not to be confused with addon test mode
--@debug@
local function _testNs(name) return  Util.Strings.Join('_', name, 'Testing')  end
local AddOnTestNs = _testNs(AddOnName)
function AddOn._IsTestContext(name)
    if _G[AddOnTestNs] then
        return true
    end
    if Util.Strings.IsSet(name) then
        if _G[_testNs(name)] then
            return true
        end
    end

    return false
end
--@end-debug@