local Lib = LibStub("LibRx-1.1", true)
local Observable = Lib.rx.Observable

--- Returns a new Observable that only produces the first result of the original.
-- @returns {Observable}
function Observable:first()
  return self:take(1)
end
