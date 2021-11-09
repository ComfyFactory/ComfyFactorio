local Event = require 'utils.event'
local Public = {}
local loaded = {}
local count = 1

function Public.set(var)
    if game then
        return
    end

    count = count + 1
    loaded[count] = var

    return count
end

function Public.get_handler()
    local handler = global.tick_handler

    if not handler then
        global.tick_handler = {
            index = game.tick
        }
        handler = global.tick_handler
    end
    return handler
end

function Public.get(id)
    return loaded[id]
end

function Public.timer(tick, id, data)
    if not id then
        return
    end
    if not data then
        return
    end
    if not tick then
        return
    end

    local handler = global.tick_handler
    if not handler then
        handler = Public.get_handler()
    end

    local limit = 30

    handler.index = handler.index + 1
    ::retry::

    if handler[tick] and handler[tick].index >= limit then
        tick = tick + 2
        goto retry
    elseif handler[tick] and handler[tick].index <= limit then
        handler[tick].index = handler[tick].index + 1
        local index = handler[tick].index

        handler[tick][index] = data
    else
        handler[tick] = {
            index = 1,
            id = id,
            [1] = data
        }
    end
end

local function on_tick()
    local tick = game.tick
    local handler = global.tick_handler

    if not handler then
        handler = Public.get_handler()
    end

    if not handler[tick] then
        return
    end

    local id = handler[tick].id
    local data = handler[tick]

    local func = Public.get(id)
    if not func then
        return
    end
    if not data then
        return
    end

    if data and data.id then
        data.id = nil
        data.index = nil
    end

    func(data)
    handler[tick] = nil
end

Event.add(defines.events.on_tick, on_tick)

return Public
