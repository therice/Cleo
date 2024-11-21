local Lib = LibStub("LibRx-1.1", true)
local Util = LibStub("LibUtil-1.2", true)

if not Lib or Lib:_ClassDefined('rx', 'Subscription') then return end

--- @class rx.Subscription
local Subscription = Lib:_DefineClass('rx', 'Subscription')
Subscription.__index = Subscription

--- Creates a new Subscription.
-- @arg {function=} action - The action to run when the subscription is unsubscribed. It will only
--                           be run once.
-- @returns {Subscription}
function Subscription.create(action)
  local self = {
    action = action or Util.Functions.Noop,
    unsubscribed = false
  }

  return setmetatable(self, Subscription)
end

--- Unsubscribes the subscription, performing any necessary cleanup work.
function Subscription:unsubscribe()
  if self.unsubscribed then return end
  self.action(self)
  self.unsubscribed = true
end
