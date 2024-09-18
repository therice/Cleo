--- @type AddOn
local _, AddOn = ...
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type AceEvent
local AceEvent = AddOn:GetLibrary('AceEvent')
--- @type LibRx
local Rx = AddOn:GetLibrary("Rx")
--- @type rx.Subject
local Subject = Rx.rx.Subject
--- @type Models.Metrics
local Metrics = AddOn.Package('Models').Metrics

--- @class Core.Messages
local Messages = AddOn.Package('Core'):Class('Messages')
function Messages:initialize()
	self.subjects = {}
	self.registered = {}
	-- tracks the stats for received messages
	self.metricsRcv = Metrics("MessagesReceived")
	-- tracks the stats for sent messages
	self.metricsSend = Metrics("MessagesSent")
	self.AceEvent = {}

	AceEvent:Embed(self.AceEvent)
end

function Messages:Subject(message)
	if not self.subjects[message] then
		self.subjects[message] = Subject.create()
	end
	return self.subjects[message]
end

function Messages:HandleMessage(message, ...)
	self:Subject(message):next(message, ...)
end

function Messages:RegisterMessage(message)
	Logging:Trace("RegisterMessage(%s)", message)
	if not self.registered[message] then
		Logging:Trace("RegisterMessage(%s) : registering 'self' with AceEvent", message)
		self.registered[message] = true
		self.AceEvent:RegisterMessage(
			message,
			self.metricsRcv:Timer(message):Timed(
				function(m, ...)
					return self:HandleMessage(m, ...)
				end
			)
		)
	end
end

function Messages:SendMessage(message, ...)
	Logging:Trace("SendMessage(%s) : args(%d)", message, #{...})
	local args = {...}
	self.metricsSend:Timer(message):Time(
		function(m, ...)
			self.AceEvent:SendMessage(m, ...)
		end,
		message, unpack(args)
	)
end

-- anything attached to 'Message' will be available via the instance
--- @class Core.Message
local Message = AddOn.Instance(
	'Core.Message',
	function()
		return {
			--- @type Core.Messages
			private = Messages()
		}
	end
)

function Message:GetMetrics()
	return {self.private.metricsRcv, self.private.metricsSend}
end

--- @return rx.Subscription
function Message:Subscribe(message, func)
	assert(Util.Strings.IsSet(message), "'message' was not provided")
	assert(Util.Objects.IsCallable(func), "'func' was not provided")
	Logging:Trace("Subscribe(%s) : %s", tostring(message), Util.Objects.ToString(func))
	self.private:RegisterMessage(message)
	return self.private:Subject(message):subscribe(func)
end

--- @return table<number, rx.Subscription>
function Message:BulkSubscribe(funcs)
	assert(
		funcs and Util.Objects.IsTable(funcs) and
			Util.Tables.CountFn(
				funcs,
				function(v, k)
					if Util.Objects.IsString(k) and Util.Objects.IsCallable(v) then return 1 end
					return 0
				end,
				true, false
			) == Util.Tables.Count(funcs),
		"each 'func' table entry must be an message(string) to function mapping"
	)

	Logging:Trace("BulkSubscribe(%d)", Util.Tables.Count(funcs))

	local subs, idx = {}, 1
	for event, func in pairs(funcs) do
		subs[idx] = self:Subscribe(event, func)
		idx = idx + 1
	end
	return subs
end

function Message:Send(message, ...)
	assert(Util.Strings.IsSet(message), "'message' was not provided")
	Logging:Trace("Send(%s)", tostring(message))
	self.private:SendMessage(message, ...)
end