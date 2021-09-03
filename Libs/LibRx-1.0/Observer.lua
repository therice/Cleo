local Lib = LibStub("LibRx-1.0", true)
local Util = LibStub("LibUtil-1.1", true)

--- @class Observer
local Observer = Lib:_DefineClass('rx', 'Observer')
Observer.__index = Observer

--- Creates a new Observer.
-- @arg {function=} onNext - Called when the Observable produces a value.
-- @arg {function=} onError - Called when the Observable terminates due to an error.
-- @arg {function=} onCompleted - Called when the Observable completes normally.
-- @returns {Observer}
function Observer.create(onNext, onError, onCompleted)
    local self = {
        _onNext = onNext or Util.Functions.Noop,
        _onError = onError or error,
        _onCompleted = onCompleted or Util.Functions.Noop,
        stopped = false
    }

    return setmetatable(self, Observer)
end

--- Pushes zero or more values to the Observer.
-- @arg {*...} values
function Observer:onNext(...)
    if not self.stopped then
        self._onNext(...)
    end
end

--- Notify the Observer that an error has occurred.
-- @arg {string=} message - A string describing what went wrong.
function Observer:onError(message)
    if not self.stopped then
        self.stopped = true
        self._onError(message)
    end
end

--- Notify the Observer that the sequence has completed and will produce no more values.
function Observer:onCompleted()
    if not self.stopped then
        self.stopped = true
        self._onCompleted()
    end
end

