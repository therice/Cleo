--- @type AddOn
local _, AddOn = ...
local L, C, Logging, Util, AceConfig, ACD =
    AddOn.Locale, AddOn.Constants, AddOn:GetLibrary('Logging'), AddOn:GetLibrary('Util'),
    AddOn:GetLibrary('AceConfig'), AddOn:GetLibrary('AceConfigDialog')
local AceUI = AddOn.Require('UI.Ace')

ACD:SetDefaultSize(AddOn.Constants.name, 850, 750)

local function BuildConfigOptions()
    local ConfigOptions = Util.Tables.Copy(AddOn.BaseConfigOptions)
    local ConfigBuilder = AceUI.ConfigBuilder(ConfigOptions)

    -- base configuration options
    ConfigBuilder:args()
        :header('header', L["version"] .. format(": |cff99ff33%s|r", tostring(AddOn.version)))
            :order(0):set('width', 'full')
        :group('general', _G.GENERAL)
            :args()
                :group('generalOptions', L["general_options"]):order(0):set('inline', true)
                    :args()
                        :toggle('enable', L["active"]):desc(L["active_desc"]):order(1)
                            :set('set',
                                 function()
                                     AddOn.enabled = not AddOn.enabled
                                     -- being disabled and currently master looter
                                     if not AddOn.enabled and AddOn:IsMasterLooter() then
                                        AddOn.masterLooter = nil
                                        -- AddOn:MasterLooterModule():Disable()
                                     else
                                        AddOn:NewMasterLooterCheck()
                                     end
                                 end
                            )
                            :set('get', function() return AddOn.enabled end)
                        :toggle('minimizeInCombat', L["minimize_in_combat"]):desc(L["minimize_in_combat_desc"]):order(2)
                        :header('spacer', ""):order(3)
                        --[[
                        :execute('test', L["Test"]):desc(L["test_desc"]):order(4)
                            :set('func',
                                    function ()

                                    end
                            )
                        :execute('verCheck', L["version_check"]):desc(L["version_check_desc"]):order(5)
                            :set('func', function () end)
                        :execute('sync', L["sync"]):desc(L["sync_desc"]):order(6)
                            :set('func', function () end)
                        --]]
                        :execute('clearPCache', L["clear_player_cache"]):desc(L["clear_player_cache_desc"]):order(7)
                            :set('func',
                                    function ()
                                        AddOn.Package('Models').Player.ClearCache()
                                        AddOn:Print("Player cache cleared")
                                    end
                            )
                        :execute('clearICache', L["clear_item_cache"]):desc(L["clear_item_cache_desc"]):order(8)
                            :set('func',
                                 function ()
                                     --AddOn.Package('Models.Item').Item.ClearCache()
                                     --AddOn:Print("Item cache cleared")
                                 end
                            )

    -- set point to location where to add subsequent options
    ConfigBuilder:SetPath('args')

    -- per module configuration options
    local options, embedEnableDisable = nil, false
    for name, module in AddOn:IterateModules() do
        Logging:Trace("BuildConfigOptions() : examining Module '%s'", name)

        if module['BuildConfigOptions'] then
            Logging:Trace("BuildConfigOptions(%s) : invoking 'BuildConfigOptions' on module to generate options", name)
            options, embedEnableDisable = module:BuildConfigOptions()
        else
            Logging:Trace("BuildConfigOptions(%s) : no configuration options for module", name)
            options, embedEnableDisable = nil, false
        end

        if options then
            if options.args and embedEnableDisable then
                for n, option in pairs(options.args) do
                    Logging:Trace("BuildConfigOptions() : modifying 'disabled' property for option argument %s in %s", n, name)
                    if option.disabled then
                        local oldDisabled = option.disabled
                        option.disabled = function(i)
                            return Util.Objects.IsFunction(oldDisabled) and oldDisabled(i) or module:IsDisabled()
                        end
                    else
                        option.disabled = "IsDisabled"
                    end
                end

                Logging:Trace("BuildConfigOptions() : adding 'enable' option argument for %s", tostring(name))
                options.args['enabled'] = {
                    order = 0,
                    type = "toggle",
                    width = "full",
                    name = _G.ENABLE,
                    get = "IsEnabled",
                    set = "SetEnabled",
                }
            end

            Logging:Trace("BuildConfigOptions() : registering options for module %s", name)
            -- these are added without order, meaning they will be displayed alphabetically based upon top level group names
            -- if you want a specific order, will need to establish either in individual modules (prone to conflicts)
            -- or establish it above and index by module name
            ConfigBuilder
                :group(name, options.name):desc(options.desc) --:order(order)
                    :set('handler', module)
                    :set('childGroups', options.childGroups and options.childGroups or 'tree')
                    :set('args', options.args)
                    :set('set', 'SetDbValue')
                    :set('get', 'GetDbValue')
        end
    end

    return ConfigBuilder:build()
end

local ConfigOptions = Util.Memoize.Memoize(BuildConfigOptions)
function AddOn:RegisterConfig()
    AceConfig:RegisterOptionsTable(
            AddOn.Constants.name,
            function (uiType, uiName, appName)
                Logging:Trace("RegisterConfig() : Building configuration for '%s', '%s', '%s'", tostring(uiType), tostring(uiName), tostring(appName))
                return ConfigOptions()
            end
    )
end

-- this is hooked primarily through the Module Prototype (SetDbValue) in Init.lua
-- but can be invoked directly as needed (for instance if you don't use the standard set definition
-- for an option)
function AddOn:ConfigChanged(moduleName, val)
    Logging:Debug("ConfigChanged(%s) : %s", moduleName, Util.Objects.ToString(val))
    -- need to serialize the values, as AceBucket (if used on other end) only groups by a single value
    self:SendMessage(C.Messages.ConfigTableChanged, AddOn:Serialize(moduleName, val))
end

local function ConfigFrame()
    local f = ACD.OpenFrames[AddOn.Constants.name]
    return not Util.Objects.IsNil(f), f
end

function AddOn.ToggleConfig()
    if ConfigFrame() then AddOn.HideConfig() else AddOn.ShowConfig() end
end

function AddOn.ShowConfig()
    ACD:Open(AddOn.Constants.name)
end

function AddOn.HideConfig()
    local _, f = ConfigFrame()
    if f then
        -- todo
        -- local gpm = AddOn:GearPointsCustomModule()
        -- if gpm.addItemFrame then gpm.addItemFrame:Hide() end
        ACD:Close(AddOn.Constants.name)
        return true
    end

    return false
end

if AddOn._IsTestContext('Core_Config') then
    AddOn.BuildConfigOptions = BuildConfigOptions
    AddOn.ConfigOptions = ConfigOptions
end