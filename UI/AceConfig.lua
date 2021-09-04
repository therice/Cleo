local _, AddOn = ...
local Logging, Util = AddOn:GetLibrary('Logging'), AddOn:GetLibrary('Util')
local Attributes, Builder = AddOn.Package('UI.Util').Attributes, AddOn.Package('UI.Util').Builder

local Option = AddOn.Class('Option', Attributes)
function Option:initialize(param, type, name, order)
    Attributes.initialize(
            self, {
                type = type,
                name = name,
                order = order or 0,
            }
    )
    -- param is the key for the configuration table at which option will associated
    self.param = param
end

function Option:named(name) return self:set('name', name) end
function Option:type(type) return self:set('type', type) end
function Option:order(order) return self:set('order', order or 0) end
function Option:fontSize(size) return self:set('fontSize', size) end
function Option:desc(desc) return self:set('desc', desc) end

--- @class UI.AceConfig.ConfigBuilder
local ConfigBuilder = AddOn.Package('UI.AceConfig'):Class('ConfigBuilder', Builder)
function ConfigBuilder:initialize(options, path)
    Builder.initialize(self, options or {})
    self.path = path or nil
    tinsert(self.embeds, 'args')
    tinsert(self.embeds, 'close')
    tinsert(self.embeds, 'header')
    tinsert(self.embeds, 'group')
    tinsert(self.embeds, 'toggle')
    tinsert(self.embeds, 'input')
    tinsert(self.embeds, 'execute')
    tinsert(self.embeds, 'description')
    tinsert(self.embeds, 'select')
    tinsert(self.embeds, 'range')
end

function ConfigBuilder:_ParameterName(param)
    return self.path and (self.path .. '.' .. param) or param
end

function ConfigBuilder:_InsertPending()
    -- Logging:Debug("_InsertPending(#1) : %s, %s", tostring(self.path), tostring(self.pending.param))
    if self.path then
        -- the current path will have been propagated to the parameter name to track full path
        -- at this point we have already established entry at parent path, so remove it for the
        -- paramter name
        local paramName = self.pending.param:gsub(self.path .. '.', "")
        -- Logging:Debug("_InsertPending(#2) : %s, %s", tostring(self.path), tostring(paramName))
        Util.Tables.Get(self.entries, self.path)[paramName] = self.pending.attrs
    else
        Util.Tables.Set(self.entries, self.pending.param, self.pending.attrs)
    end
end

function ConfigBuilder:SetPath(path)
    self:_CheckPending()
    self.path = path
    return self
end

function ConfigBuilder:args()
    local path = self.pending and Util.Strings.Join('.', self.pending.param, 'args') or 'args'
    self:_CheckPending()
    Util.Tables.Set(self.entries, path, { })
    self.path = path
    return self
end

-- this "closes" out the current pending option group and adds it to the builder
-- any invocations after "close" will occur in the context of the parent group
function ConfigBuilder:close()
    -- add any pending option
    self:_CheckPending()
    -- if path is present, walk backwards to relevant parent of 'args'
    if self.path then
        -- must be at args to close
        if not Util.Strings.EndsWith(self.path, 'args') then
            error(format("the current path '%s', does not correspond to arguments, cannot close", self.path))
        end
        local parts = Util.Strings.Split(self.path, '.')
        if #parts == 2 then
            error(format("the current path '%s' represents the top level group, it cannot be closed", self.path))
        end

        -- print(format('(START) %s', self.path))
        for i = #parts, 1, -1 do
            local part = parts[i]
            parts[i] = nil
            if part == 'args' then
                parts[i-1] = nil
                break
            end
        end
        self.path = Util.Strings.Join('.', parts)
        -- print(format('(END) %s', self.path))
    end
    return self
end

function ConfigBuilder:entry(class, param, ...)
    return Builder.entry(self, class, self:_ParameterName(param), ...)
end

function ConfigBuilder:header(param, name)
    return self:entry(Option, param, 'header', name)
end

function ConfigBuilder:group(param, name)
    return self:entry(Option, param, 'group', name)
end

function ConfigBuilder:toggle(param, name)
    return self:entry(Option, param, 'toggle', name)
end

function ConfigBuilder:execute(param, name)
    return self:entry(Option, param, 'execute', name)
end

function ConfigBuilder:description(param, name)
    return self:entry(Option, param, 'description', name):fontSize('medium')
end

function ConfigBuilder:select(param, name)
    return self:entry(Option, param, 'select', name)
end

function ConfigBuilder:input(param, name)
    return self:entry(Option, param, 'input', name)
end

function ConfigBuilder:range(param, name, min, max, step)
    return self:entry(Option, param, 'range', name)
            :set('min', min or 0)
            :set('max', max or 100)
            :set('step', step or 0.5)
end