local lib = LibStub("LibItemUtil-1.1", true)
local Logging = LibStub("LibLogging-1.0", true)
local Util = LibStub("LibUtil-1.1", true)

local itemQueue = { }

function OnError(err)
    Logging:Error("%s", err)
end

function lib:GET_ITEM_INFO_RECEIVED(_, item, success)
    Logging:Trace("GET_ITEM_INFO_RECEIVED(%s) : success=%s", tostring(item), tostring(success))
    if success then
        local item_id = tonumber(item)
        local callback_fn = itemQueue[item_id]

        if callback_fn then
            Logging:Trace("GET_ITEM_INFO_RECEIVED(%s) : invoking callback", tostring(item))
            local result = xpcall(callback_fn, OnError)
            Logging:Trace("GET_ITEM_INFO_RECEIVED(%s) : callback result %s", tostring(item), tostring(result))
            itemQueue[item_id] = nil
        end
    end

    Logging:Trace("GET_ITEM_INFO_RECEIVED() - Awaiting %s results", tostring(Util.Tables.Count(itemQueue)))

    if Util.Tables.Count(itemQueue) == 0 then
        Logging:Trace("GetItemInfo : UnregisterEvent GET_ITEM_INFO_RECEIVED")
        lib:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
    end
end

function lib:QueryItemInfo(id, callback)
    if type(id) == 'string' and strmatch(id, 'item:(%d+)')  then
        id = lib:ItemLinkToId(id)
    end

    if type(callback) ~= "function" then
        error("Usage: GetItemInfo(id, callback): 'callback' - function", 2)
    end

    id = tonumber(id)

    itemQueue[id] = callback
    if Util.Tables.Count(itemQueue) > 0 then
        Logging:Trace("GetItemInfo : Registering GET_ITEM_INFO_RECEIVED")
        lib:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    end
end
