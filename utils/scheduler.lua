local Event = require 'utils.event'
local Public = {}
local loaded = {}
local count = 1
local limit = 30

function Public.set(var)
    if game then
        return
    end

    count = count + 1
    loaded[count] = var

    return count
end

function Public.get_handlers()
    local handlers = global.tick_handler

    if not handlers then
        global.tick_handler = {}
        handlers = global.tick_handler
    end

    return handlers
end

function Public.search(id)
    local handlers = global.tick_handler

    for _, data in pairs(handlers) do
        if data and (data.parent_id == id or (data.custom_name and data.custom_name == id)) then
            return true
        end
    end
    return false
end

function Public.get(id)
    return loaded[id]
end

function Public.return_callback(callback)
    if not callback then
        return
    end

    local data = {
        iterator_index = 1,
        tick_index = 1,
        point_index = 1,
        pos_tbl = {},
        total_calls = 256,
        table_index = 1
    }

    if not data then
        return callback()
    else
        return callback(data)
    end
end

function Public.timeout(tick, id, data, custom_name)
    if not id then
        return
    end
    if not tick then
        return
    end

    tick = game.tick + tick

    local handlers = global.tick_handler
    if not handlers then
        handlers = Public.get_handlers()
    end

    ::retry::

    if handlers[tick] then
        tick = tick + 1
        if handlers[tick] then
            goto retry
        end

        handlers[tick] = {
            id = id,
            parent_id = id,
            data = data,
            execute_tick = tick,
            custom_name = custom_name or nil
        }
    else
        handlers[tick] = {
            id = id,
            parent_id = id,
            data = data,
            execute_tick = tick,
            custom_name = custom_name or nil
        }
    end
end

local function increment_handler(tick, handler)
    local handlers = global.tick_handler

    ::retry::
    tick = tick + 1
    if handlers[tick] then
        tick = tick + 1
        goto retry
    else
        local old_tick = handler.execute_tick
        handler.execute_tick = tick
        handlers[tick] = handler
        handlers[old_tick] = nil
    end
end

local function on_tick()
    local tick = game.tick
    local handlers = global.tick_handler

    if not handlers then
        handlers = Public.get_handlers()
    end

    local handler = handlers[tick]
    if not handler then
        return
    end

    local data = handler.data or {}

    local callback = Public.get(handler.id)
    if not callback then
        if data.sleep then
            if data.sleep > tick then
                increment_handler(tick, handler)
                return
            else
                handlers[tick] = nil
                return
            end
        end

        return
    end

    if data.ttl then
        if data.ttl > limit then
            handlers[tick] = nil
            return
        else
            increment_handler(tick, handler)
        end
    end

    if data.child_id then
        if type(data.child_id) == 'table' then
            for i = 1, #data.child_id do
                local child_id = Public.search(data.child_id[i])
                if child_id then
                    increment_handler(tick, handler)
                    return
                end
            end
        else
            local child_id = Public.search(data.child_id)
            if child_id then
                increment_handler(tick, handler)
                return
            end
        end
    end

    callback(handler.data)

    if data.sleep then
        handler.id = nil
        increment_handler(tick, handler)
    end

    handlers[tick] = nil
end

Event.add(defines.events.on_tick, on_tick)

Public.timer = Public.timeout

return Public
