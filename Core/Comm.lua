--- @type AddOn
local _, AddOn = ...
local C = AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type LibRx
local Rx = AddOn:GetLibrary("Rx")
--- @type rx.Subject
local Subject = Rx.rx.Subject
--- @type LibUtil.Compression
local Compression = Util.Compression
--- @type LibUtil.Compression.Compressor
local Compressor = Compression.GetCompressors(Compression.CompressorType.LibDeflate)[1]
--- @type Models.Metrics
local Metrics = AddOn.Package('Models').Metrics
--- @type Models.Player
local Player = AddOn.Package('Models').Player

--- scrubs passed value for transmission over the wire
-- specifically, entries that are modeled as classes via LibClass
-- need to have their functions removed as not serializable
-- when they are received, they will be reconstituted into the appropriate class
local function ScrubValue(value)
    if Util.Objects.IsTable(value) and not value.clazz then
        local t = {}
        for k, v in pairs(value) do
            local k1 = ScrubValue(k)
            local v1 = ScrubValue(v)
            t[k1] = v1
        end
        return t
    elseif Util.Objects.IsTable(value) and value.clazz then
        return value:toTable()
    elseif Util.Objects.IsFunction(value) then
        return nil
    else
        return value
    end
end

--- goes through passed arguments, scrubbing them for transmission over the wire
local function ScrubData(...)
    local scrubbed = Util.Tables.Temp()
    for i=1, select('#', ...) do
        local v = select(i, ...)
        Util.Tables.Push(scrubbed, ScrubValue(v))
    end
    return scrubbed
end

-- private stuff only for use within this scope
--- @class Core.Comms
--- @field public subjects Core.Comms
--- @field public registered Core.Comms
--- @field public AceComm Core.Comms
local Comms = AddOn.Package('Core'):Class('Comms')
function Comms:initialize()
    self.subjects = {}
    self.registered = {}
    -- tracks the metrics for received commands (by prefix)
    -- these metrics include decompress and fire timings
    self.metricsRecv = Metrics("CommReceived")
    -- tracks the metrics for fired commands (by prefix and command)
    -- these metrics only include fire (processing) timings
    self.metricsFired = Metrics("CommFired")
    -- tracks the metrics for sent commands (by prefix and command)
    -- these metrics include compression and sending timings
    self.metricsSend = Metrics("CommSent")
    self.AceComm = {}
    self.MessagePack = AddOn:GetLibrary('MessagePack')
end

function Comms:Serialize(...)
    local temp = Util.Tables.Temp(...)
    local packed = self.MessagePack.pack(temp)
    Util.Tables.ReleaseTemp(temp)
    return packed
end

function Comms:Deserialize(s)
    local success, raw = pcall(function() return self.MessagePack.unpack(s) end)
    if success then
        return success, unpack(raw)
    else
        -- raw will be the error
        return success, raw
    end
end

function Comms:Subject(prefix, command)
    local name = prefix .. (command or "")
    if not self.subjects[name] then
        self.subjects[name] = Subject.create()
    end
    return self.subjects[name]
end

function Comms:GroupChannel()
    if IsInRaid() then
        return AddOn:IsInNonInstance() and C.Channels.Instance or C.Channels.Raid, nil
    elseif IsInGroup() then
        return AddOn:IsInNonInstance() and C.Channels.Instance or C.Channels.Party, nil
    else
        return C.Channels.Whisper, AddOn.player.name
    end
end

function Comms:PrepareForSend(command, ...)
    local scrubbed = ScrubData(...)
    Logging:Trace('PrepareForSend() : %s', Util.Objects.ToString(scrubbed))
    local serialized = self:Serialize(command, scrubbed)
    local data = Compressor:compress(serialized, true)
    Util.Tables.ReleaseTemp(scrubbed)
    Logging:Trace("PrepareForSend(%s) : Compressed length '%d' -> '%d'", command, #serialized, #data)
    return data
end

function Comms:ProcessReceived(msg)
    if not msg then
        Logging:Error("ProcessReceived() : No message was provided")
        return false
    end

    Logging:Trace("ProcessReceived() : len=%d", #msg)

    local decompressed = Compressor:decompress(msg, true)
    if not decompressed then
        Logging:Warn("ProcessReceived() : Message could not be decompressed")
        return false
    end

    local success, command, data = self:Deserialize(decompressed)
    if not success then
        Logging:Error("ProcessReceived() : Message could not deserialized, '%s' - %s", tostring(command), Util.Objects.ToString(decompressed))
    end

    return success, command, data
end

function Comms:FireCommand(prefix, dist, sender, command, data)
    Logging:Debug("FireCommand(%s) : via=%s, sender=%s, command=%s", tostring(prefix), tostring(dist), tostring(sender), tostring(command))
    self:Subject(prefix, command):next(data, sender, command, dist)
end

function Comms:ReceiveComm(prefix, msg, dist, sender)
    Logging:Debug("ReceiveComm()")

    local senderName = AddOn:UnitName(sender)
    Logging:Debug("ReceiveComm(%s) : via=%s, sender=%s/%s", tostring(prefix), tostring(dist), tostring(sender), tostring(senderName))
    local success, command, data = self:ProcessReceived(msg)
    if success then
        self.metricsFired:Timer(Util.Strings.Join(':', prefix, command or "")):Time(
            function(...) self:FireCommand(prefix, dist, senderName, command, data) end
        )
    end
end

function Comms:RegisterComm(prefix)
    Logging:Trace("RegisterComm(%s)", prefix)

    if not C.CommPrefixes[prefix] then
        C.CommPrefixes[prefix] = prefix
    end

    if not self.registered[prefix] then
        Logging:Trace("RegisterComm(%s) : registering 'self' with AceComm", prefix)
        self.registered[prefix] = true
        self.AceComm:RegisterComm(
                prefix,
                self.metricsRecv:Timer(prefix):Timed(
                        function(...)
                            return self:ReceiveComm(...)
                        end
                )
        )
    end
end

function Comms:SendComm(prefix, target, prio, callback, callbackarg, command, ...)
    self.metricsSend:Timer(Util.Strings.Join(':', prefix, command or "")):Time(
        function(...)

            local toSend = self:PrepareForSend(command, ...)
            local isPlayer = Util.Objects.IsInstanceOf(target, Player)

            Logging:Trace("SendComm(%s, %s, %s) : %s (%d)", prefix,
                          isPlayer and target:GetName() or Util.Objects.ToString(target),
                          command, '[omitted]' or Util.Objects.ToString(ScrubData(...)), #toSend
            )

            if target == C.group then
                local channel, player = self:GroupChannel()
                Logging:Trace("SendComm[group](%s, %s, %s)", tostring(prefix), tostring(channel), tostring(player))
                self.AceComm:SendCommMessage(prefix, toSend, channel, player, prio, callback, callbackarg)
            elseif target == C.guild then
                Logging:Trace("SendComm[guild](%s, %s, %s)", tostring(prefix), tostring(C.Channels.Guild), tostring(nil))
                self.AceComm:SendCommMessage(prefix, toSend, C.Channels.Guild, nil, prio, callback, callbackarg)
            else
                target = isPlayer and target:GetName() or target
                Logging:Debug("SendComm[other](%s, %s)", tostring(prefix), tostring(target))
                if AddOn.UnitIsUnit(target, C.player) then
                    Logging:Trace("SendComm[other]() : UnitIsUnit(true), %s", AddOn.player.name)
                    self.AceComm:SendCommMessage(prefix, toSend, C.Channels.Whisper, AddOn.player:GetName(), prio,
                                                 callback, callbackarg)
                else
                    Logging:Trace("SendComm[other]() : UnitIsUnit(false), %s", target)
                    self.AceComm:SendCommMessage(prefix, toSend, C.Channels.Whisper, target, prio, callback,
                                                 callbackarg)
                end
            end
        end,
        ...
    )
end

-- anything attached to 'Comm' will be available via the instance
--- @class Core.Comm
local Comm = AddOn.Instance(
        'Core.Comm',
        function()
            return {
                private = Comms()
            }
        end
)

AddOn:GetLibrary('AceComm'):Embed(Comm.private.AceComm)

function Comm:GetMetrics()
    return {self.private.metricsRecv, self.private.metricsFired, self.private.metricsSend}
end

--- @return rx.Subscription
function Comm:Subscribe(prefix, command, func)
    assert(prefix and type(prefix) == 'string', "subscription prefix was not provided")
    assert(tInvert(C.CommPrefixes)[prefix], format("'%s' is not a registered prefix", tostring(prefix)))
    Logging:Trace("Subscribe(%s) : '%s' -> %s", prefix, Util.Objects.ToString(command), Util.Objects.ToString(func))
    return self.private:Subject(prefix, command):subscribe(func)
end

--- @return table<number, rx.Subscription>
function Comm:BulkSubscribe(prefix, funcs)
    assert(funcs and type(funcs) == 'table', "functions must be a table")
    Logging:Trace("BulkSubscribe(%s) :%s", prefix, Util.Objects.ToString(funcs))
    local subs, idx = {}, 1
    for command, func in pairs(funcs) do
        subs[idx] = self:Subscribe(prefix, command, func)
        idx = idx + 1
    end
    return subs
end

--- @return function
function Comm:GetSender(prefix)
    assert(Util.Strings.IsSet(prefix), "prefix was not provided")
    self.private:RegisterComm(prefix)
    return function(module, target, command, ...)
        -- if the function is attached to a module, the first argument will be implicitly 'self'
        -- so check if that's the case by looking at type and shifting if necessary
        if Util.Objects.IsString(module) then
            self.private:SendComm(prefix, module, 'NORMAL', nil, nil, target, command, ...)
        else
            -- left shift args
            self.private:SendComm(prefix, target, "NORMAL", nil, nil, command, ...)
        end
    end
end

function Comm:Send(args)
    assert(Util.Objects.IsTable(args), "args must be a table")
    assert(Util.Objects.IsSet(args.command), "command was not provided")
    args.data = Util.Objects.IsTable(args.data) and args.data or {args.data}
    self.private:SendComm(
            args.prefix or C.CommPrefixes.Main, args.target or C.group,
            args.prio, args.callback, args.callbackarg, args.command, unpack(args.data)
    )
end

function Comm:RegisterPrefix(prefix)
    assert(Util.Strings.IsSet(prefix), "prefix was not provided")
    self.private:RegisterComm(prefix)
end

Comm.Register = Comm.RegisterPrefix
