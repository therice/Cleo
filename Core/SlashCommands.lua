--- @type AddOn
local _, AddOn = ...
local L, C, Logging, Util, Rx = AddOn.Locale, AddOn.Constants, AddOn:GetLibrary('Logging'), AddOn:GetLibrary('Util'), AddOn:GetLibrary('Rx')
local Subject = Rx.rx.Subject

--- @class Core.SlashCommandsInternal
--- @field public subjects Core.SlashCommandsInternal
--- @field public commands Core.SlashCommandsInternal
--- @field public AceConsole Core.SlashCommandsInternal
local SlashCommandsInternal = AddOn.Package('Core'):Class('SlashCommandsInternal')
function SlashCommandsInternal:initialize()
    self.subjects = {}
    self.commands = {}
    self.AceConsole = {}
end

function SlashCommandsInternal:Help()
    print(format(L["chat_version"], tostring(AddOn.version)))
    for _, cmd in pairs(self.commands) do
        if not cmd.hidden or AddOn:DevModeEnabled() then
            print("|cff20a200", cmd.cmd, "|r:", cmd.desc or "")
        end
    end
end

function SlashCommandsInternal:HandleCommand(msg)
    local args = Util.Tables.Temp(self.AceConsole:GetArgs(msg, 10))
    Logging:Debug("HandleCommand() : %s", Util.Objects.ToString(args))
    local cmd = tremove(args, 1)
    if Util.Objects.IsTable(cmd) then cmd = nil else cmd = cmd:trim():lower() end
    if Util.Strings.IsEmpty(cmd) or Util.Strings.Equal(cmd, 'help') then
        self:Help()
    else
        local subject = self.subjects[cmd]
        if subject then
            args = Util.Tables.Filter(
                    args,
                    function(v)
                        -- magic number to designate 'next'
                        if v == 1e9 then return false end
                        -- empty tables are fillers
                        if Util.Objects.IsTable(v) then return false end
                        return true
                    end
            )
            Logging:Trace("HandleCommand(%s) : dispatching %s to subject", cmd, Util.Objects.ToString(args))
            subject:next(unpack(args))
        else
            self:Help()
        end
    end

    Util.Tables.ReleaseTemp(args)
end

function SlashCommandsInternal:RegisterCommand(cmds, desc, hidden)
    for _, cmd in ipairs(cmds) do
        if not self.commands[cmd:lower()] then
            -- Logging:Trace('RegisterCommand() : %s', tostring(cmd))
            self.commands[cmd] = {
                cmd = cmd:lower(),
                desc = desc,
                hidden = hidden,
            }
        end
    end
end

function SlashCommandsInternal:UnregisterAll()
    for cmd, subject in pairs(self.subjects) do
        Logging:Debug("UnregisterAll() : %s, %s", Util.Objects.ToString(cmd), Util.Objects.ToString(subject))
        subject:onCompleted()
    end
    self.commands = {}
    self.subjects = {}
end

function SlashCommandsInternal:Subject(cmds)
   local first = cmds[1]:lower()
    if not self.subjects[first] then
        self.subjects[first] = Subject.create()
        for i = 2, #cmds do
            self.subjects[cmds[i]:lower()] = self.subjects[first]
        end
    end
    return self.subjects[first]
end

--- @class Core.SlashCommands
local SlashCommands = AddOn.Instance(
        'Core.SlashCommands',
        function()
            return {
                private = SlashCommandsInternal(),
                initialized = false,
            }
        end
)

AddOn:GetLibrary('AceConsole'):Embed(SlashCommands.private.AceConsole)

function SlashCommands:Subscribe(cmds, desc, func, hidden)
    assert(
        Util.Objects.IsTable(cmds) and #cmds > 0 and Util.Tables.CountFn(cmds, function(v) return Util.Strings.IsSet(v) and 1 or 0 end) == #cmds,
        "'cmds' must be a table of strings with at least one entry"
    )
    assert(Util.Objects.IsString(desc), "'desc' was not provided")
    assert(Util.Objects.IsFunction(func), "'func' was not provided")
    Logging:Trace("SlashCommands:Subscribe() : %s", Util.Objects.ToString(cmds))
    hidden = Util.Objects.IsEmpty(hidden) and false or hidden
    self.private:RegisterCommand(cmds, desc, hidden)
    return self.private:Subject(cmds):subscribe(func)
end

function SlashCommands:BulkSubscribe(...)
    assert(
            (...) and Util.Tables.CountFn(Util.Tables.New(...), function(v) return Util.Objects.IsTable(v) and 1 or 0 end) == select("#", ...),
            "each 'cmd' parameter must be a table"
    )
    local subs, idx = {}, 1
    for i=1, select("#", ...) do
        local command = select(i, ...)
        subs[idx] = self:Subscribe(unpack(command))
        idx = idx + 1
    end
    return subs
end

function SlashCommands:Register()
    if not self.private.initialized then
        Logging:Debug("SlashCommands:Register()")
        self.private.AceConsole:RegisterChatCommand(
                C.name:lower(),
                function(msg) self.private:HandleCommand(msg) end
        )
        self.private.initialized = true
    end
end

function SlashCommands:Unregister()
    if self.private.initialized then
        Logging:Debug("SlashCommands:Unregister()")
        self.private:UnregisterAll()
        self.private.AceConsole:UnregisterChatCommand(C.name:lower())
        self.private.initialized = false
    end
end