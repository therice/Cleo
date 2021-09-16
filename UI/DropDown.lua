local _, AddOn = ...
local Util = AddOn:GetLibrary('Util')
local Attributes, Builder = AddOn.Package('UI.Util').Attributes, AddOn.Package('UI.Util').Builder

local Entry = AddOn.Class('Entry', Attributes)
function Entry:initialize() Attributes.initialize(self, {}) end
function Entry:text(text) return self:set('text', text) end
function Entry:checkable(val) return self:set('notCheckable', not val) end
function Entry:arrow(val) return self:set('hasArrow',val) end
function Entry:value(val) return self:set('value',val) end
function Entry:disabled(val) return self:set('disabled', val) end
function Entry:fn(fn) return self:set('func', fn)  end
function Entry:hidden(val) return self:set('hidden', val) end

--- @class UI.AceConfig.EntryBuilder
local EntryBuilder = AddOn.Package('UI.DropDown'):Class('EntryBuilder', Builder)
function EntryBuilder:initialize(entries)
    Builder.initialize(self, entries or {})
    self.level = 0
    tinsert(self.embeds, 'nextlevel')
    tinsert(self.embeds, 'add')
end

function EntryBuilder:_InsertPending()
    -- no attributes on current entry being added
    if Util.Tables.Count(self.pending.attrs) == 0 then
        error(format('no attributes were added to pending entry at level %d index %d', self.level, #self.entries[self.level] + 1))
    end
    tinsert(self.entries[self.level], self.pending.attrs)
end

--- @return UI.AceConfig.EntryBuilder
function EntryBuilder:nextlevel()
    self:_CheckPending()
    self.level = self.level + 1
    self.entries[self.level] = {}
    return self
end

--- @return UI.AceConfig.EntryBuilder
function EntryBuilder:add()
    return self:entry(Entry)
end

function EntryBuilder:build()
    if self.level == 0 then error("must call 'nextlevel' at least once before adding entries or building") end
    local built = Builder.build(self)
    for level, _ in pairs(built) do
        if #built[level] == 0 then
            error(format("no entries were added to level %d", level))
        end
    end
    return built
end

--- @class UI.DropDown
local DropDown = AddOn.Instance(
        'UI.DropDown',
        function()
            return {

            }
        end
)

--- @return UI.AceConfig.EntryBuilder
function DropDown.EntryBuilder()
    return EntryBuilder()
end


function DropDown.ToggleMenu(level, menu, cellFrame)
    MSA_ToggleDropDownMenu(level, nil, menu, cellFrame, 0, 0)
end

function DropDown.RightClickMenu(predicate, entries, callback)
    return function(menu, level)
        if not predicate() then return end
        if not menu or not level then return end

        local name, el, module = menu.name, menu.entry, menu.module
        local value = _G.MSA_DROPDOWNMENU_MENU_VALUE
        local levelEntries = entries[level]
        if not levelEntries then return end

        local info
        for _, entry in ipairs(levelEntries) do
            info = MSA_DropDownMenu_CreateInfo()
            if not entry.special then
                if not entry.onValue or entry.onValue == value or (Util.Objects.IsFunction(entry.onValue) and entry.onValue(name, el)) then
                    if (entry.hidden and Util.Objects.IsFunction(entry.hidden) and not entry.hidden(name, el)) or not entry.hidden then
                        for name, val in pairs(entry) do
                            -- custom attributes with support for callbacks
                            -- the parameters are attributes on the menu itself, which must be manually specified
                            -- typically done in the OnClick event, see Standings.lua for example
                            if name == "func" then
                                info[name] = function() return val(name, el, module) end
                            elseif Util.Objects.IsFunction(val) then
                                info[name] = val(name, el, module)
                            else
                                info[name] = val
                            end
                        end
                        MSA_DropDownMenu_AddButton(info, level)
                    end
                end
            else
                if callback then callback(info, menu, level, entry, value) end
            end
        end
    end
end