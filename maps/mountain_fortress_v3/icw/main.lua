local Event = require 'utils.event'
local Functions = require 'maps.mountain_fortress_v3.icw.functions'
local ICW = require 'maps.mountain_fortress_v3.icw.table'
local Public = {}

Public.reset = ICW.reset
Public.get_table = ICW.get

local function on_entity_died(event)
    local entity = event.entity
    if not entity and not entity.valid then
        return
    end
    local wagon_types = ICW.get('wagon_types')

    if entity and entity.valid and not wagon_types[entity.type] then
        return
    end
    local icw = ICW.get()
    Functions.kill_wagon(icw, entity)
end

local function on_player_driving_changed_state(event)
    local icw = ICW.get()
    local player = game.players[event.player_index]
    Functions.use_cargo_wagon_door_with_entity(icw, player, event.entity)
end

local function on_player_changed_surface(event)
    local player = game.players[event.player_index]
    Functions.kill_minimap(player)
end

local function on_gui_closed(event)
    local entity = event.entity
    if not entity then
        return
    end
    if not entity.valid then
        return
    end
    if not entity.unit_number then
        return
    end
    local icw = ICW.get()
    if not icw.wagons[entity.unit_number] then
        return
    end
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    Functions.kill_minimap(player)
end

local function on_gui_opened(event)
    local entity = event.entity
    if not entity then
        return
    end
    if not entity.valid then
        return
    end
    if not entity.unit_number then
        return
    end
    local icw = ICW.get()
    local wagon = icw.wagons[entity.unit_number]
    if not wagon then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    Functions.draw_minimap(
        icw,
        player,
        wagon.surface,
        {
            wagon.area.left_top.x + (wagon.area.right_bottom.x - wagon.area.left_top.x) * 0.5,
            wagon.area.left_top.y + (wagon.area.right_bottom.y - wagon.area.left_top.y) * 0.5
        }
    )
end

local function on_player_died(event)
    local player = game.get_player(event.player_index)
    Functions.kill_minimap(player)
end

local function on_train_created()
    local icw = ICW.get()
    Functions.request_reconstruction(icw)
end

local function on_gui_click(event)
    local icw = ICW.get()
    Functions.toggle_minimap(icw, event)
end

local function nth_5_tick()
    Functions.item_transfer()
end

local function nth_20_tick()
    Functions.hazardous_debris()
end

local function nth_240_tick()
    Functions.update_minimap()
end

local function on_init()
    Public.reset()
end

local function on_gui_switch_state_changed(event)
    local element = event.element
    local player = game.players[event.player_index]
    if not (player and player.valid) then
        return
    end

    if not element.valid then
        return
    end

    if element.name == 'icw_auto_switch' then
        local icw = ICW.get()
        Functions.toggle_auto(icw, player)
    end
end

local function on_entity_cloned(event)
    local source = event.source
    local destination = event.destination
    Functions.on_entity_cloned(source, destination)
end

function Public.register_wagon(wagon_entity)
    local icw = ICW.get()
    return Functions.create_wagon(icw, wagon_entity)
end

function Public.migrate_wagon(source, target)
    local icw = ICW.get()
    return Functions.migrate_wagon(icw, source, target)
end

local on_player_or_robot_built_tile = Functions.on_player_or_robot_built_tile

Event.on_init(on_init)
Event.on_nth_tick(5, nth_5_tick)
Event.on_nth_tick(20, nth_20_tick)
Event.on_nth_tick(240, nth_240_tick)
Event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_train_created, on_train_created)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_gui_closed, on_gui_closed)
Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_player_built_tile, on_player_or_robot_built_tile)
Event.add(defines.events.on_robot_built_tile, on_player_or_robot_built_tile)
Event.add(defines.events.on_gui_switch_state_changed, on_gui_switch_state_changed)
Event.add(defines.events.on_entity_cloned, on_entity_cloned)
Event.add(
    defines.events.on_built_entity,
    function(event)
        local icw = ICW.get()
        return Functions.create_wagon(icw, event.created_entity)
    end
)

return Public
