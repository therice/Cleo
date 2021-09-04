--- @type AddOn
local _, AddOn = ...
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type LibRx
local Rx = AddOn:GetLibrary("Rx")
--- @type rx.Subject
local Subject = Rx.rx.Subject
--- @type Models.Metrics
local Metrics = AddOn.Package('Models').Metrics

-- private stuff only for use within this scope
--- @class Core.Events
--- @field public registered Core.Events
--- @field public subjects Core.Events
--- @field public AceEvent Core.Events
local Events = AddOn.Package('Core'):Class('Events')
function Events:initialize()
    self.registered = {}
    self.subjects = {}
    -- tracks the stats for received events
    self.metricsRcv = Metrics("EventsReceived")
    self.AceEvent = {}
end

--- @return rx.Subject
function Events:Subject(event)
    local name = event
    if not self.subjects[name] then self.subjects[name] = Subject.create() end
    return self.subjects[name]
end

function Events:HandleEvent(event, ...)
    Logging:Debug("HandleEvent(%s) : %s", event, Util.Objects.ToString({...}))
    self:Subject(event):next(event, ...)
end

function Events:RegisterEvent(event)
    Logging:Trace("RegisterEvent(%s)", event)

    if not self.registered[event] then
        Logging:Trace("RegisterEvent(%s) : registering 'self' with AceEvent", event)
        self.registered[event] = true
        self.AceEvent:RegisterEvent(
                event,
                self.metricsRcv:Timer(event):Timed(function(event, ...) return self:HandleEvent(event, ...) end)
        )
    end
end

-- anything attached to 'Event' will be available via the instance
--- @class Core.Event
local Event = AddOn.Instance(
        'Core.Event',
        function()
            return {
                private = Events()
            }
        end
)

AddOn:GetLibrary('AceEvent'):Embed(Event.private.AceEvent)

function Event:GetMetrics()
    return {self.private.metricsRcv}
end

--- @return rx.Subscription
function Event:Subscribe(event, func)
    assert(Util.Strings.IsSet(event), "'event' was not provided")
    assert(Util.Objects.IsFunction(func), "'func' was not provided")
    Logging:Trace("Subscribe(%s) : %s", tostring(event), Util.Objects.ToString(func))
    self.private:RegisterEvent(event)
    return self.private:Subject(event):subscribe(func)
end

--- @return table<number, rx.Subscription>
function Event:BulkSubscribe(funcs)
    assert(
            funcs and Util.Objects.IsTable(funcs) and
                    Util.Tables.CountFn(
                            funcs,
                            function(v, k)
                                if Util.Objects.IsString(k) and Util.Objects.IsFunction(v) then return 1 end
                                return 0
                            end,
                            true, false
                    ) == Util.Tables.Count(funcs),
            "each 'func' table entry must be an event(string) to function mapping"
    )

    Logging:Trace("BulkSubscribe(%d)", Util.Tables.Count(funcs))

    local subs, idx = {}, 1
    for event, func in pairs(funcs) do
        subs[idx] = self:Subscribe(event, func)
        idx = idx + 1
    end
    return subs
end

