--luacheck: ignore function_table
--luacheck: ignore function_nth_tick_table
--luacheck: globals script
--- This Module allows for registering multiple handlers to the same event, overcoming the limitation of script.register.
--
-- ** Event.add(event_name, handler) **
--
-- Handlers added with Event.add must be added at the control stage or in Event.on_init or Event.on_load.
-- Remember that for each player, on_init or on_load is run, never both. So if you can't add the handler in the
-- control stage add the handler in both on_init and on_load.
-- Handlers added with Event.add cannot be removed.
-- For handlers that need to be removed or added at runtime use Event.add_removable.
-- @usage
-- local Event = require 'utils.event'
-- Event.add(
--     defines.events.on_built_entity,
--     function(event)
--         game.print(serpent.block(event)) -- prints the content of the event table to console.
--     end
-- )
--
-- ** Event.add_removable(event_name, token) **
--
-- For conditional event handlers. Event.add_removable can be safely called at runtime without desync risk.
-- Only use this if you need to add the handler at runtime or need to remove the handler, otherwise use Event.add
--
-- Event.add_removable can be safely used at the control stage or in Event.on_init. If used in on_init you don't
-- need to also add in on_load (unlike Event.add).
-- Event.add_removable cannot be called in on_load, doing so will crash the game on loading.
-- Token is used because it's a desync risk to store closures inside the global table.
--
-- @usage
-- local Token = require 'utils.token'
-- local Event = require 'utils.event'
--
-- Token.register must not be called inside an event handler.
-- local handler =
--     Token.register(
--     function(event)
--         game.print(serpent.block(event)) -- prints the content of the event table to console.
--     end
-- )
--
-- The below code would typically be inside another event or a custom command.
-- Event.add_removable(defines.events.on_built_entity, handler)
--
-- When you no longer need the handler.
-- Event.remove_removable(defines.events.on_built_entity, handler)
--
-- It's not an error to register the same token multiple times to the same event, however when
-- removing only the first occurrence is removed.
--
-- ** Event.add_removable_function(event_name, func) **
--
-- Only use this function if you can't use Event.add_removable. i.e you are registering the handler at the console.
-- The same restrictions that apply to Event.add_removable also apply to Event.add_removable_function.
-- func cannot be a closure in this case, as there is no safe way to store closures in the global table.
-- A closure is a function that uses a local variable not defined in the function.
--
-- @usage
-- local Event = require 'utils.event'
--
-- If you want to remove the handler you will need to keep a reference to it.
-- global.handler = function(event)
--     game.print(serpent.block(event)) -- prints the content of the event table to console.
-- end
--
-- The below code would typically be used at the command console.
-- Event.add_removable_function(defines.events.on_built_entity, global.handler)
--
-- When you no longer need the handler.
-- Event.remove_removable_function(defines.events.on_built_entity, global.handler)
--
-- ** Other Events **
--
-- Use Event.on_init(handler) for script.on_init(handler)
-- Use Event.on_load(handler) for script.on_load(handler)
--
-- Use Event.on_nth_tick(tick, handler) for script.on_nth_tick(tick, handler)
-- Favour this event over Event.add(defines.events.on_tick, handler)
-- There are also Event.add_removable_nth_tick(tick, token) and Event.add_removable_nth_tick_function(tick, func)
-- That work the same as above.
--
-- ** Custom Scenario Events **
--
-- local Event = require 'utils.event'
--
-- local event_id = script.generate_event_name()
--
-- Event.add(
--     event_id,
--     function(event)
--         game.print(serpent.block(event)) -- prints the content of the event table to console.
--     end
-- )
--
-- The table contains extra information that you want to pass to the handler.
-- script.raise_event(event_id, {extra = 'data'})
local EventCore = require 'utils.event_core'
local Global = require 'utils.global'
local Token = require 'utils.token'
local Debug = require 'utils.debug'

local table_remove = table.remove
local core_add = EventCore.add
local core_on_init = EventCore.on_init
local core_on_load = EventCore.on_load
local core_on_nth_tick = EventCore.on_nth_tick
local core_on_configuration_changed = EventCore.on_configuration_changed
local stage_load = _STAGE.load
local script_on_event = script.on_event
local script_on_nth_tick = script.on_nth_tick
local generate_event_name = script.generate_event_name

local function_table = function_table
local function_nth_tick_table = function_nth_tick_table

local Event = {}

local handlers_added = false -- set to true after the removeable event handlers have been added.

local event_handlers = EventCore.get_event_handlers()
local on_nth_tick_event_handlers = EventCore.get_on_nth_tick_event_handlers()

local token_handlers = {}
local token_nth_tick_handlers = {}
local function_handlers = {}
local function_nth_tick_handlers = {}

Global.register(
    {
        token_handlers = token_handlers,
        token_nth_tick_handlers = token_nth_tick_handlers,
        function_handlers = function_handlers,
        function_nth_tick_handlers = function_nth_tick_handlers
    },
    function(tbl)
        token_handlers = tbl.token_handlers
        token_nth_tick_handlers = tbl.token_nth_tick_handlers
        function_handlers = tbl.function_handlers
        function_nth_tick_handlers = tbl.function_nth_tick_handlers
    end
)

local function remove(tbl, handler)
    if tbl == nil then
        return
    end

    -- the handler we are looking for is more likly to be at the back of the array.
    for i = #tbl, 1, -1 do
        if tbl[i] == handler then
            table_remove(tbl, i)
            break
        end
    end
end

--- Register a handler for the event_name event.
-- This function must be called in the control stage or in Event.on_init or Event.on_load.
-- See documentation at top of file for details on using events.
-- @param event_name<number>
-- @param handler<function>
function Event.add(event_name, handler)
    if _LIFECYCLE == 8 then
        error('Calling Event.add after on_init() or on_load() has run is a desync risk.', 2)
    end

    core_add(event_name, handler)
end

--- Register a handler for the script.on_init event.
-- This function must be called in the control stage or in Event.on_init or Event.on_load
-- See documentation at top of file for details on using events.
-- @param handler<function>
function Event.on_init(handler)
    if _LIFECYCLE == 8 then
        error('Calling Event.on_init after on_init() or on_load() has run is a desync risk.', 2)
    end

    core_on_init(handler)
end

--- Register a handler for the script.on_load event.
-- This function must be called in the control stage or in Event.on_init or Event.on_load
-- See documentation at top of file for details on using events.
-- @param handler<function>
function Event.on_load(handler)
    if _LIFECYCLE == 8 then
        error('Calling Event.on_load after on_init() or on_load() has run is a desync risk.', 2)
    end

    core_on_load(handler)
end

--- Register a handler for the script.on_configuration_changed event.
-- @param handler<function>
function Event.on_configuration_changed(handler)
    if _LIFECYCLE == 8 then
        error('Calling Event.on_configuration_changed after on_init() or on_load() has run is a desync risk.', 2)
    end

    core_on_configuration_changed(handler)
end

--- Register a handler for the nth_tick event.
-- This function must be called in the control stage or in Event.on_init or Event.on_load.
-- See documentation at top of file for details on using events.
-- @param tick<number> The handler will be called every nth tick
-- @param handler<function>
function Event.on_nth_tick(tick, handler)
    if _LIFECYCLE == 8 then
        error('Calling Event.on_nth_tick after on_init() or on_load() has run is a desync risk.', 2)
    end

    core_on_nth_tick(tick, handler)
end

--- Register a token handler that can be safely added and removed at runtime.
-- Do NOT call this method during on_load.
-- See documentation at top of file for details on using events.
-- @param  event_name<number>
-- @param  token<number>
function Event.add_removable(event_name, token)
    if type(token) ~= 'number' then
        error('token must be a number', 2)
    end
    if _LIFECYCLE == stage_load then
        error('cannot call during on_load', 2)
    end

    local tokens = token_handlers[event_name]
    if not tokens then
        token_handlers[event_name] = {token}
    else
        tokens[#tokens + 1] = token
    end

    if handlers_added then
        local handler = Token.get(token)
        core_add(event_name, handler)
    end
end

--- Removes a token handler for the given event_name.
-- Do NOT call this method during on_load.
-- See documentation at top of file for details on using events.
-- @param  event_name<number>
-- @param  token<number>
function Event.remove_removable(event_name, token)
    if _LIFECYCLE == stage_load then
        error('cannot call during on_load', 2)
    end
    local tokens = token_handlers[event_name]

    if not tokens then
        return
    end

    local handler = Token.get(token)
    local handlers = event_handlers[event_name]

    remove(tokens, token)
    remove(handlers, handler)

    if #handlers == 0 then
        script_on_event(event_name, nil)
    end
end

--- Register a handler that can be safely added and removed at runtime.
-- The handler must not be a closure, as that is a desync risk.
-- Do NOT call this method during on_load.
-- See documentation at top of file for details on using events.
-- @param  event_name<number>
-- @param  func<function>
-- @param  name<string>
function Event.add_removable_function(event_name, func, name)
    if _LIFECYCLE == stage_load then
        error('cannot call during on_load', 2)
    end

    if not event_name or not func or not name then
        return
    end

    local f = assert(load('return ' .. func))()

    if type(f) ~= 'function' then
        error('func must be a function', 2)
    end

    if Debug.is_closure(f) then
        error('func cannot be a closure as that is a desync risk. Consider using Event.add_removable(event, token) instead.', 2)
    end

    local funcs = function_handlers[name]
    if not funcs then
        function_handlers[name] = {}
        funcs = function_handlers[name]
    end

    funcs[#funcs + 1] = {event_name = event_name, handler = func}

    local func_table = function_table[name]
    if not func_table then
        function_table[name] = {}
        func_table = function_table[name]
    end

    func_table[#func_table + 1] = {event_name = event_name, handler = f}

    if handlers_added then
        core_add(event_name, f)
    end
end

--- Removes a handler for the given event_name.
-- Do NOT call this method during on_load.
-- See documentation at top of file for details on using events.
-- @param  event_name<number>
-- @param  name<string>
function Event.remove_removable_function(event_name, name)
    if _LIFECYCLE == stage_load then
        error('cannot call during on_load', 2)
    end

    if not event_name or not name then
        return
    end

    local funcs = function_handlers[name]

    if not funcs then
        return
    end

    local handlers = event_handlers[event_name]

    for k, v in pairs(function_table[name]) do
        local n = v.event_name
        if n == event_name then
            local f = v.handler
            function_handlers[name][k] = nil
            remove(handlers, f)
        end
    end

    if #handlers == 0 then
        script_on_event(event_name, nil)
    end

    if #function_handlers[name] == 0 then
        function_handlers[name] = nil
    end
end

--- Register a token handler for the nth tick that can be safely added and removed at runtime.
-- Do NOT call this method during on_load.
-- See documentation at top of file for details on using events.
-- @param  tick<number>
-- @param  token<number>
function Event.add_removable_nth_tick(tick, token)
    if _LIFECYCLE == stage_load then
        error('cannot call during on_load', 2)
    end
    if type(token) ~= 'number' then
        error('token must be a number', 2)
    end

    local tokens = token_nth_tick_handlers[tick]
    if not tokens then
        token_nth_tick_handlers[tick] = {token}
    else
        tokens[#tokens + 1] = token
    end

    if handlers_added then
        local handler = Token.get(token)
        core_on_nth_tick(tick, handler)
    end
end

--- Removes a token handler for the nth tick.
-- Do NOT call this method during on_load.
-- See documentation at top of file for details on using events.
-- @param  tick<number>
-- @param  token<number>
function Event.remove_removable_nth_tick(tick, token)
    if _LIFECYCLE == stage_load then
        error('cannot call during on_load', 2)
    end
    local tokens = token_nth_tick_handlers[tick]

    if not tokens then
        return
    end

    local handler = Token.get(token)
    local handlers = on_nth_tick_event_handlers[tick]

    remove(tokens, token)
    remove(handlers, handler)

    if #handlers == 0 then
        script_on_nth_tick(tick, nil)
    end
end

--- Register a handler for the nth tick that can be safely added and removed at runtime.
-- The handler must not be a closure, as that is a desync risk.
-- Do NOT call this method during on_load.
-- See documentation at top of file for details on using events.
-- @param  tick<number>
-- @param  func<function>
function Event.add_removable_nth_tick_function(tick, func, name)
    if _LIFECYCLE == stage_load then
        error('cannot call during on_load', 2)
    end

    if not tick or not func or not name then
        return
    end

    local f = assert(load('return ' .. func))()

    if type(f) ~= 'function' then
        error('func must be a function', 2)
    end

    if Debug.is_closure(f) then
        error('func cannot be a closure as that is a desync risk. Consider using Event.add_removable_nth_tick(tick, token) instead.', 2)
    end

    local funcs = function_nth_tick_handlers[name]
    if not funcs then
        function_nth_tick_handlers[name] = {}
        funcs = function_nth_tick_handlers[name]
    end

    funcs[#funcs + 1] = {tick = tick, handler = func}

    local func_table = function_nth_tick_table[name]
    if not func_table then
        function_nth_tick_table[name] = {}
        func_table = function_nth_tick_table[name]
    end

    func_table[#func_table + 1] = {tick = tick, handler = f}

    if handlers_added then
        core_on_nth_tick(tick, f)
    end
end

--- Removes a handler for the nth tick.
-- Do NOT call this method during on_load.
-- See documentation at top of file for details on using events.
-- @param  tick<number>
-- @param  func<function>
function Event.remove_removable_nth_tick_function(tick, name)
    if _LIFECYCLE == stage_load then
        error('cannot call during on_load', 2)
    end

    if not tick or not name then
        return
    end

    local funcs = function_nth_tick_handlers[name]

    if not funcs then
        return
    end

    local handlers = on_nth_tick_event_handlers[tick]
    local f = function_nth_tick_table[name]

    for k, v in pairs(function_nth_tick_table[name]) do
        local t = v.tick
        if t == tick then
            f = v.handler
        end
    end

    remove(handlers, f)

    for k, v in pairs(function_nth_tick_handlers[name]) do
        local t = v.tick
        if t == tick then
            function_nth_tick_handlers[name][k] = nil
        end
    end

    if #function_nth_tick_handlers[name] == 0 then
        function_nth_tick_handlers[name] = nil
    end

    if #handlers == 0 then
        script_on_nth_tick(tick, nil)
    end
end

--- Generate a new, unique event ID.
-- @param <string> name of the event/variable that is exposed
function Event.generate_event_name(name)
    local event_id = generate_event_name()

    -- If we're in debug, add the event ID into defines.events for the debuggertron's event module
    if _DEBUG then
        defines.events[name] = event_id -- luacheck: ignore 122
    end

    return event_id
end

function Event.add_event_filter(event, filter)
    local current_filters = script.get_event_filter(event)

    if not current_filters then
        current_filters = {filter}
    else
        table.insert(current_filters, filter)
    end

    script.set_event_filter(event, current_filters)
end

local function add_handlers()
    if not function_table then
        function_table = {}
    end
    if not function_nth_tick_table then
        function_nth_tick_table = {}
    end

    for event_name, tokens in pairs(token_handlers) do
        for i = 1, #tokens do
            local handler = Token.get(tokens[i])
            core_add(event_name, handler)
        end
    end

    for name, funcs in pairs(function_handlers) do
        for i = 1, #funcs do
            local e_name = funcs[i].event_name
            local func = funcs[i].handler
            local handler = assert(load('return ' .. func))()
            local func_handler = function_table[name]
            if not func_handler then
                function_table[name] = {}
                func_handler = function_table[name]
            end

            func_handler[#func_handler + 1] = {event_name = e_name, handler = handler}
            core_add(e_name, handler)
        end
    end

    for tick, tokens in pairs(token_nth_tick_handlers) do
        for i = 1, #tokens do
            local handler = Token.get(tokens[i])
            core_on_nth_tick(tick, handler)
        end
    end

    for name, funcs in pairs(function_nth_tick_handlers) do
        for i = 1, #funcs do
            local tick = funcs[i].tick
            local func = funcs[i].handler
            local handler = assert(load('return ' .. func))()
            local func_handler = function_nth_tick_table[name]
            if not func_handler then
                function_nth_tick_table[name] = {}
                func_handler = function_nth_tick_table[name]
            end

            func_handler[#func_handler + 1] = {tick = tick, handler = handler}
            core_on_nth_tick(tick, handler)
        end
    end

    handlers_added = true
end

core_on_init(add_handlers)
core_on_load(add_handlers)
core_on_configuration_changed(add_handlers)
function_table = {}
function_nth_tick_table = {}

return Event
