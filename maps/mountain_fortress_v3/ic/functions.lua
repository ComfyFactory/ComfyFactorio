local Utils = require 'utils.core'
local Color = require 'utils.color_presets'
local Task = require 'utils.task'
local Token = require 'utils.token'

local Public = {}

function Public.request_reconstruction(ic)
    ic.rebuild_tick = game.tick + 30
end

local function validate_entity(entity)
    if not entity then
        return false
    end
    if not entity.valid then
        return false
    end
    return true
end

local function upperCase(str)
    return (str:gsub('^%l', string.upper))
end

local function kill_doors(ic, car)
    if not validate_entity(car.entity) then
        return
    end
    for k, e in pairs(car.doors) do
        ic.doors[e.unit_number] = nil
        e.destroy()
        car.doors[k] = nil
    end
end

local function get_owner_car_object(cars, player)
    for k, car in pairs(cars) do
        if car.owner == player.index then
            return k
        end
    end
    return false
end

local function get_owner_car_name(ic, player)
    local cars = ic.cars
    local saved_surfaces = ic.saved_surfaces
    local index = saved_surfaces[player.index]
    for k, car in pairs(cars) do
        if not index then
            return false
        end
        if car.owner == player.index then
            return car.name
        end
    end
    return false
end

local function get_saved_entity(cars, entity, index)
    for k, car in pairs(cars) do
        if index and index.name ~= entity.name then
            local msg =
                'The built entity is not the same as the saved one. ' ..
                upperCase(car.name) .. ' is not equal to ' .. upperCase(entity.name) .. '.'
            return false, msg
        end
        if car.entity == false then
            t[unit_number] = car
            t[unit_number].entity = entity
            t[unit_number].transfer_entities = car.transfer_entities
            t[k] = nil
        end
    end
    return true
end

local function replace_doors(t, saved, entity)
    for k, door in pairs(t) do
        local unit_number = entity.unit_number
        if saved == door then
            t[k] = unit_number
        end
    end
end

local function replace_surface(surfaces, entity, index)
    if not validate_entity(entity) then
        return
    end
    for k, surface in pairs(surfaces) do
        local unit_number = entity.unit_number
        if tostring(index.saved_entity) == surface.name then
            if validate_entity(surface) then
                surface.name = unit_number
                surfaces[unit_number] = surface
                surfaces[k] = nil
            end
        end
    end
end

local function replace_surface_entity(cars, entity, index)
    if not validate_entity(entity) then
        return
    end
    for _, car in pairs(cars) do
        local unit_number = entity.unit_number
        if index and index.saved_entity == car.saved_entity then
            if validate_entity(car.surface) then
                car.surface.name = unit_number
            end
        end
    end
end

local function remove_logistics(car)
    local chests = car.transfer_entities
    for k, chest in pairs(chests) do
        car.transfer_entities[k] = nil
        chest.destroy()
    end
end

local function set_new_area(ic, car)
    local new_area = ic.car_areas
    local name = car.name
    local apply_area = new_area[name]
    car.area = apply_area
end

local function upgrade_surface(ic, player, entity)
    local ce = entity
    local saved_surfaces = ic.saved_surfaces
    local cars = ic.cars
    local door = ic.doors
    local surfaces = ic.surfaces
    local index = saved_surfaces[player.index]
    if not index then
        return
    end

    if saved_surfaces[player.index] then
        local c = get_owner_car_object(cars, player)
        local car = ic.cars[c]
        car.name = 'tank'
        set_new_area(ic, car)
        remove_logistics(car)
        replace_entity(cars, ce, index)
        replace_doors(door, ce, index)
        replace_surface(surfaces, ce, index)
        replace_surface_entity(cars, ce, index)
        kill_doors(ic, car)
        Public.create_car_room(ic, car)
        saved_surfaces[player.index] = nil
        return true
    end
    return false
end

local function save_surface(ic, entity, player)
    local car = ic.cars[entity.unit_number]

    car.entity = false

    ic.saved_surfaces[player.index] = entity.unit_number
end

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not player.character then
        return false
    end
    if not player.connected then
        return false
    end
    if not game.players[player.name] then
        return false
    end
    return true
end

local function delete_empty_surfaces(ic)
    for k, surface in pairs(ic.surfaces) do
        if not ic.cars[tonumber(surface.name)] or ic.cars.entity == false then
            game.delete_surface(surface)
            ic.surfaces[k] = nil
        end
    end
end

local function kick_players_out_of_vehicles(car)
    for _, player in pairs(game.connected_players) do
        local character = player.character
        if character and character.valid and character.driving then
            if car.surface == player.surface then
                character.driving = false
            end
        end
    end
end

local function kick_player_from_surface(car)
    for _, e in pairs(car.surface.find_entities_filtered({area = car.area})) do
        if e and e.valid and e.name == 'character' and e.player then
            local p = car.entity.surface.find_non_colliding_position('character', car.entity.position, 128, 0.5)
            if p then
                e.player.teleport(p, car.entity.surface)
            else
                e.player.teleport(car.entity.position, car.entity.surface)
            end
        end
    end
end

local function input_filtered(car_inv, chest, chest_inv, free_slots)
    local request_stacks = {}
    local prototypes = game.item_prototypes
    for slot_index = 1, 30, 1 do
        local stack = chest.get_request_slot(slot_index)
        if stack then
            request_stacks[stack.name] = 10 * prototypes[stack.name].stack_size
        end
    end
    for i = 1, #car_inv - 1, 1 do
        if free_slots <= 0 then
            return
        end
        local stack = car_inv[i]
        if stack.valid_for_read then
            local request_stack = request_stacks[stack.name]
            if request_stack and request_stack > chest_inv.get_item_count(stack.name) then
                chest_inv.insert(stack)
                stack.clear()
                free_slots = free_slots - 1
            end
        end
    end
end

local function input_cargo(car, chest)
    if not chest.request_from_buffers then
        return
    end

    local car_entity = car.entity
    if not validate_entity(car_entity) then
        return
    end

    local car_inventory = car_entity.get_inventory(defines.inventory.car_trunk)
    if car_inventory.is_empty() then
        return
    end

    local chest_inventory = chest.get_inventory(defines.inventory.chest)
    local free_slots = 0
    for i = 1, chest_inventory.get_bar() - 1, 1 do
        if not chest_inventory[i].valid_for_read then
            free_slots = free_slots + 1
        end
    end

    if chest.get_request_slot(1) then
        input_filtered(car_inventory, chest, chest_inventory, free_slots)
        return
    end

    for i = 1, #car_inventory - 1, 1 do
        if free_slots <= 0 then
            return
        end
        if car_inventory[i].valid_for_read then
            chest_inventory.insert(car_inventory[i])
            car_inventory[i].clear()
            free_slots = free_slots - 1
        end
    end
end

local function output_cargo(car, passive_chest)
    if not validate_entity(car.entity) then
        return
    end

    if not passive_chest.valid then
        return
    end
    local chest1 = passive_chest.get_inventory(defines.inventory.chest)
    local chest2 = car.entity.get_inventory(defines.inventory.car_trunk)
    for k, v in pairs(chest1.get_contents()) do
        local t = {name = k, count = v}
        local c = chest2.insert(t)
        if (c > 0) then
            chest1.remove({name = k, count = c})
        end
    end
end

local transfer_functions = {
    ['logistic-chest-requester'] = input_cargo,
    ['logistic-chest-passive-provider'] = output_cargo
}

local function construct_doors(ic, car)
    local area = car.area
    local surface = car.surface

    local main_tile_name = 'black-refined-concrete'

    for _, x in pairs({area.left_top.x - 1, area.right_bottom.x + 0.5}) do
        local p
        if car.name == 'car' then
            p = {x, area.left_top.y + 10}
        else
            p = {x, area.left_top.y + 20}
        end
        surface.set_tiles({{name = main_tile_name, position = p}}, true)
        local e =
            surface.create_entity(
            {
                name = 'player-port',
                position = {x, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5)},
                force = 'neutral',
                create_build_effect_smoke = false
            }
        )
        e.destructible = false
        e.minable = false
        e.operable = false
        ic.doors[e.unit_number] = car.entity.unit_number
        car.doors[#car.doors + 1] = e
    end
end

local function get_player_data(ic, player)
    local player_data = ic.players[player.index]
    if ic.players[player.index] then
        return player_data
    end

    ic.players[player.index] = {
        surface = 1,
        fallback_surface = 1
    }
    return ic.players[player.index]
end

local remove_car =
    Token.register(
    function(data)
        local player = data.player
        local car = data.car
        player.remove_item({name = car.name, count = 9999})
    end
)

function Public.save_car(ic, event)
    local entity = event.entity
    if not validate_entity(entity) then
        return
    end

    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end

    local entity_type = ic.entity_type

    if not entity_type[entity.name] then
        return
    end
    local car = ic.cars[entity.unit_number]

    if not car then
        return
    end

    kick_players_out_of_vehicles(car)
    kick_player_from_surface(car)

    if car.owner == player.index then
        save_surface(ic, entity, player)
    else
        local p = game.players[car.owner]
        if not p then
            return
        end

        log_err(ic, 'Owner of this vehicle is: ' .. p.name)
        save_surface(ic, entity, p)
        Utils.action_warning('{Car}', player.name .. ' has looted ' .. p.name .. '´s car.')
        player.print('This car was not yours to keep.', Color.warning)
        player.remove_item({name = car.name, count = 9999})
        local params = {
            player = player,
            car = car
        }
        Task.set_timeout_in_ticks(10, remove_car, params)
        if ic.restore_on_theft then
            local e =
                player.surface.create_entity(
                {name = car.name, position = position, force = player.force, create_build_effect_smoke = false}
            )
            e.health = health
            restore_surface(ic, p, e)
        else
            p.insert({name = car.name, count = 1, health = health})
            p.print('Your car was stolen from you - the gods foresaw this and granted you a new one.', Color.info)
        end
    end
end

function Public.kill_car(ic, entity)
    if not validate_entity(entity) then
        return
    end

    local entity_type = ic.entity_type

    if not entity_type[entity.name] then
        return
    end
    local car = ic.cars[entity.unit_number]
    local surface = car.surface
    kick_players_out_of_vehicles(car)
    kill_doors(ic, car)
    kick_player_from_surface(car)
    for _, tile in pairs(surface.find_tiles_filtered({area = car.area})) do
        surface.set_tiles({{name = 'out-of-map', position = tile.position}}, true)
    end
    car.entity.force.chart(surface, car.area)
    ic.cars[entity.unit_number] = nil
    Public.request_reconstruction(ic)
end

function Public.create_room_surface(ic, unit_number)
    if game.surfaces[tostring(unit_number)] then
        return game.surfaces[tostring(unit_number)]
    end

    local map_gen_settings = {
        ['width'] = 2,
        ['height'] = 2,
        ['water'] = 0,
        ['starting_area'] = 1,
        ['cliff_settings'] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
        ['default_enable_all_autoplace_controls'] = true,
        ['autoplace_settings'] = {
            ['entity'] = {treat_missing_as_default = false},
            ['tile'] = {treat_missing_as_default = true},
            ['decorative'] = {treat_missing_as_default = false}
        }
    }
    local surface = game.create_surface(tostring(unit_number), map_gen_settings)
    surface.freeze_daytime = true
    surface.daytime = 0.1
    surface.request_to_generate_chunks({16, 16}, 1)
    surface.force_generate_chunk_requests()
    for _, tile in pairs(surface.find_tiles_filtered({area = {{-2, -2}, {2, 2}}})) do
        surface.set_tiles({{name = 'out-of-map', position = tile.position}}, true)
    end
    ic.surfaces[#ic.surfaces + 1] = surface
    return surface
end

function Public.create_car_room(ic, car)
    local surface = car.surface
    local car_areas = ic.car_areas
    local entity_name = car.name
    local area = car_areas[entity_name]

    local main_tile_name = 'black-refined-concrete'

    local tiles = {}

    for x = area.left_top.x, area.right_bottom.x - 1, 1 do
        for y = area.left_top.y + 2, area.right_bottom.y - 3, 1 do
            tiles[#tiles + 1] = {name = main_tile_name, position = {x, y}}
        end
    end
    for x = -3, 2, 1 do
        for y = area.right_bottom.y - 4, area.right_bottom.y - 2, 1 do
            tiles[#tiles + 1] = {name = main_tile_name, position = {x, y}}
        end
    end

    local fishes = {}

    for x = area.left_top.x, area.right_bottom.x - 1, 1 do
        for y = -0, 1, 1 do
            tiles[#tiles + 1] = {name = 'water', position = {x, y}}
            fishes[#fishes + 1] = {name = 'fish', position = {x, y}}
        end
    end

    surface.set_tiles(tiles, true)
    for _, fish in pairs(fishes) do
        surface.create_entity(fish)
    end

    construct_doors(ic, car)

    local lx, ly, rx, ry
    if car.name == 'car' then
        lx, ly, rx, ry = 4, 1, 5, 1
    else
        lx, ly, rx, ry = 4, 1, 5, 1
    end
    local position1 = {area.left_top.x + lx, area.left_top.y + ly}
    local position2 = {area.right_bottom.x - rx, area.left_top.y + ry}

    local e1 =
        surface.create_entity(
        {
            name = 'logistic-chest-requester',
            position = position1,
            force = 'neutral',
            create_build_effect_smoke = false
        }
    )
    e1.destructible = false
    e1.minable = false

    local e2 =
        surface.create_entity(
        {
            name = 'logistic-chest-passive-provider',
            position = position2,
            force = 'neutral',
            create_build_effect_smoke = false
        }
    )
    e2.destructible = false
    e2.minable = false
    car.transfer_entities = {e1, e2}
    return
end

function Public.create_car(ic, event)
    local created_entity = event.created_entity
    if not validate_entity(created_entity) then
        return
    end
    local player = game.get_player(event.player_index)
    if not validate_player(player) then
        return
    end

    local saved_surfaces = ic.saved_surfaces
    local cars = ic.cars
    local door = ic.doors

    local entity_type = ic.entity_type
    local car_areas = ic.car_areas

    if not created_entity.unit_number then
        return
    end
    if not entity_type[created_entity.name] then
        return
    end

    if string.sub(ce.surface.name, 0, #map_name) ~= map_name then
        return player.print('Multi-surface is not supported at the moment.', Color.warning)
    end

    if get_owner_car_name(ic, player) == 'car' and ce.name == 'tank' then
        upgrade_surface(ic, player, ce)
        player.print('Your car-surface has been upgraded!', Color.success)
        return
    end

    local saved_surface = restore_surface(ic, player, ce)
    if saved_surface then
        return
    end

    for _, c in pairs(cars) do
        if c.owner == player.index then
            created_entity.destroy()
            return player.print('You already have a portable vehicle.', Color.fail)
        end
    end

    local car_area = car_areas[created_entity.name]

    ic.cars[created_entity.unit_number] = {
        entity = created_entity,
        area = {
            left_top = {x = car_area.left_top.x, y = car_area.left_top.y},
            right_bottom = {x = car_area.right_bottom.x, y = car_area.right_bottom.y}
        },
        doors = {},
        owner = player.index,
        name = created_entity.name
    }

    local car = ic.cars[created_entity.unit_number]

    car.surface = Public.create_room_surface(ic, un)
    Public.create_car_room(ic, car)

    Public.request_reconstruction(ic)
    return car
end

function Public.remove_invalid_cars(ic)
    for k, car in pairs(ic.cars) do
        if type(car.entity) == 'boolean' then
            return
        end
        if not validate_entity(car.entity) then
            ic.cars[k] = nil
            for key, value in pairs(ic.doors) do
                if k == value then
                    ic.doors[key] = nil
                end
            end
        end
    end
    for k, surface in pairs(ic.surfaces) do
        if not ic.cars[tonumber(surface.name)] then
            game.delete_surface(surface)
            ic.surfaces[k] = nil
        end
    end
end

function Public.teleport_players_around(ic)
    for _, player in pairs(game.connected_players) do
        if not validate_player(player) then
            return
        end

        if player.surface.find_entity('player-port', player.position) then
            local door = player.surface.find_entity('player-port', player.position)
            if door and door.valid then
                local doors = ic.doors
                local cars = ic.cars

                local car = false
                if doors[door.unit_number] then
                    car = cars[doors[door.unit_number]]
                end
                if cars[door.unit_number] then
                    car = cars[door.unit_number]
                end
                if not car then
                    return
                end

                local player_data = get_player_data(ic, player)
                if player_data.state then
                    player_data.state = player_data.state - 1
                    if player_data.state == 0 then
                        player_data.state = nil
                    end
                    return
                end

                if car.entity.surface.name ~= player.surface.name then
                    if validate_entity(car.entity) and car.owner == player.index then
                        car.entity.minable = true
                    end
                    local surface = car.entity.surface
                    local x_vector = (door.position.x / math.abs(door.position.x)) * 2
                    local position = {car.entity.position.x + x_vector, car.entity.position.y}
                    local surface_position = surface.find_non_colliding_position('character', position, 128, 0.5)
                    if car.entity.type == 'car' then
                        player.teleport(surface_position, surface)
                        player_data.state = 2
                        player.driving = true
                    else
                        player.teleport(surface_position, surface)
                    end
                    player_data.surface = surface.index
                elseif car.entity.type == 'car' and player.driving then
                    player.driving = false
                else
                    local surface = car.surface
                    local area = car.area
                    local x_vector = door.position.x - player.position.x
                    local position
                    if x_vector > 0 then
                        position = {
                            area.left_top.x + 0.5,
                            area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5)
                        }
                    else
                        position = {
                            area.right_bottom.x - 0.5,
                            area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5)
                        }
                    end
                    local p = surface.find_non_colliding_position('character', position, 128, 0.5)
                    if p then
                        player.teleport(p, surface)
                    else
                        player.teleport(position, surface)
                    end
                    player_data.surface = surface.index
                end
            end
        end
    end
end

function Public.use_door_with_entity(ic, player, door)
    local player_data = get_player_data(ic, player)
    if player_data.state then
        player_data.state = player_data.state - 1
        if player_data.state == 0 then
            player_data.state = nil
        end
        return
    end

    if not door then
        return
    end
    if not door.valid then
        return
    end
    local doors = ic.doors
    local cars = ic.cars

    local car = false
    if doors[door.unit_number] then
        car = cars[doors[door.unit_number]]
    end
    if cars[door.unit_number] then
        car = cars[door.unit_number]
    end
    if not car then
        return
    end

    player_data.fallback_surface = car.entity.surface.index
    player_data.fallback_position = {car.entity.position.x, car.entity.position.y}

    local surface = car.surface
    if validate_entity(car.entity) and car.owner == player.index then
        car.entity.minable = false
    end
end

function Public.reconstruct_all_cars(ic)
    for unit_number, car in pairs(ic.cars) do
        if not validate_entity(car.entity) then
            ic.cars[unit_number] = nil
            Public.request_reconstruction(ic)
            return
        end

        if not car.surface then
            car.surface = Public.create_room_surface(ic, unit_number)
            Public.create_car_room(ic, car)
        end
    end
    delete_empty_surfaces(ic)
end

function Public.item_transfer(ic)
    for _, car in pairs(ic.cars) do
        if validate_entity(car.entity) then
            if car.transfer_entities then
                for k, e in pairs(car.transfer_entities) do
                    if validate_entity(e) then
                        transfer_functions[e.name](car, e)
                    end
                end
            end
        end
    end
end

return Public
