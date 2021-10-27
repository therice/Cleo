--- @type AddOn
local _, AddOn = ...
local C, Logging, Util = AddOn.Constants, AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util")

-- these will be applied to the generic 'configuration' layout
function AddOn:GetConfigSupplement(module)
    if module['ConfigSupplement'] then
        local cname, fn = module:ConfigSupplement()
        if Util.Strings.IsSet(cname) and Util.Objects.IsFunction(fn) then
            Logging:Trace("GetConfigSupplement() : module '%s' has a configuration supplement named '%s'", module:GetName(), cname)
            return cname, fn
        end
    end

    Logging:Trace("GetConfigSupplement() : module '%s' has no associated configuration supplement", module:GetName())
    return nil, nil
end

-- these will be applied as a new section in the layout
function AddOn:GeLaunchpadSupplement(module)
    if module['LaunchpadSupplement'] then
        local mname, fn, enableDisableSupport = module:LaunchpadSupplement()
        if Util.Strings.IsSet(mname) and Util.Objects.IsFunction(fn) then
            Logging:Trace("GeLaunchpadSupplement() : module '%s' has a launchpad supplement named '%s'", module:GetName(), mname)
            return mname, {module, fn, enableDisableSupport}
        end
    end

    Logging:Trace("GetConfigSupplement() : module '%s' has no associated launchpad supplement", module:GetName())
    return nil, nil
end

-- this is hooked primarily through the Module Prototype (SetDbValue) in Init.lua
-- but can be invoked directly as needed (for instance if you don't use the standard set definition
-- for an option)
function AddOn:ConfigChanged(moduleName, val)
    Logging:Trace("ConfigChanged(%s) : %s", moduleName, Util.Objects.ToString(val))
    -- need to serialize the values, as AceBucket (if used on other end) only groups by a single value
    self:SendMessage(C.Messages.ConfigTableChanged, AddOn:Serialize(moduleName, val))
end
