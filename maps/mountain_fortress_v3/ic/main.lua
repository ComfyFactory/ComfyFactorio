local Event = require 'utils.event'
local Functions = require 'maps.mountain_fortress_v3.ic.functions'
local IC = require 'maps.mountain_fortress_v3.ic.table'
local Public = {}

Public.reset = IC.reset
Public.get_table = IC.get

local function on_entity_died(event)
    local entity = event.entity
    if not entity and not entity.valid then
        return
    end
    local entity_type = IC.get('entity_type')

    if not entity_type[entity.type] then
        return
    end
    local ic = IC.get()
    Functions.kill_car(ic, entity)
end

local function on_player_mined_entity(event)
    local entity = event.entity
    if not entity and not entity.valid then
        return
    end
    local ic = IC.get()
    Functions.kill_car(ic, entity)
end

local function on_robot_mined_entity(event)
    local entity = event.entity
    if not entity and not entity.valid then
        return
    end
    local ic = IC.get()
    Functions.kill_car(ic, entity)
end

local function on_built_entity(event)
    local ic = IC.get()
    local created_entity = event.created_entity
    Functions.create_car(ic, created_entity)
end

local function on_robot_built_entity(event)
    local ic = IC.get()
    local created_entity = event.created_entity
    Functions.create_car(ic, created_entity)
end

local function on_player_driving_changed_state(event)
    local ic = IC.get()
    local player = game.players[event.player_index]
    Functions.use_door_with_entity(ic, player, event.entity)
end

local function on_player_created(event)
    local player = game.players[event.player_index]
    player.insert({name = 'car', count = 5})
end

local function on_tick()
    local ic = IC.get()
    local tick = game.tick

    if tick % 60 == 0 then
        Functions.teleport_players_around(ic)
        Functions.item_transfer(ic)
    end

    if not ic.rebuild_tick then
        return
    end
    if ic.rebuild_tick ~= tick then
        return
    end
    Functions.reconstruct_all_cars(ic)
    ic.rebuild_tick = nil
end

local function on_init()
    Public.reset()
end

Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_player_created, on_player_created)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_robot_mined_entity, on_robot_mined_entity)

return Public
