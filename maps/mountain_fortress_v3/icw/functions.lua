local Public = {}

local ICW = require 'maps.mountain_fortress_v3.icw.table'
local WPT = require 'maps.mountain_fortress_v3.table'
local Task = require 'utils.task_token'
local Gui = require 'utils.gui'
local SpamProtection = require 'utils.spam_protection'
local Core = require 'utils.core'
local LinkedChests = require 'maps.mountain_fortress_v3.icw.linked_chests'

local deepcopy = table.deepcopy
local random = math.random
local sqrt = math.sqrt

local fallout_width = 64
local fallout_debris = {}

for x = fallout_width * -1 - 42, fallout_width + 42, 1 do
    if x < -42 or x > 42 then
        for y = fallout_width * -1 - 42, fallout_width + 42, 1 do
            local position = {x = x, y = y}
            local fallout = sqrt(position.x ^ 2 + position.y ^ 2)
            if fallout > fallout_width then
                fallout_debris[#fallout_debris + 1] = {position.x, position.y}
            end
        end
    end
end
local size_of_debris = #fallout_debris

local add_chests_to_wagon_token =
    Task.register(
    function(data)
        local wagon = data.wagon
        local surface = data.surface
        local wagon_areas = ICW.get('wagon_areas')
        local cargo_wagon = wagon_areas['cargo-wagon']
        local position1 = {cargo_wagon.left_top.x + 4, cargo_wagon.left_top.y + 1}
        local position2 = {cargo_wagon.right_bottom.x - 5, cargo_wagon.left_top.y + 1}
        local position3 = {cargo_wagon.left_top.x + 4, cargo_wagon.right_bottom.y - 2}
        local position4 = {cargo_wagon.right_bottom.x - 5, cargo_wagon.right_bottom.y - 2}

        local left_1 = LinkedChests.add(surface, position1, 'player', 'wagon_' .. wagon.entity.unit_number .. '_1')
        if not left_1 then
            return error('Surface was invalid, please check this out!')
        end
        left_1.destructible = false
        left_1.minable = false

        local left_2 = LinkedChests.add(surface, {position1[1] - 1, position1[2]}, 'player', 'wagon_' .. wagon.entity.unit_number .. '_2')
        left_2.destructible = false
        left_2.minable = false

        local left_3 = LinkedChests.add(surface, {position1[1] - 2, position1[2]}, 'player', 'wagon_' .. wagon.entity.unit_number .. '_3')
        left_3.destructible = false
        left_3.minable = false

        local left_4 = LinkedChests.add(surface, {position1[1] - 3, position1[2]}, 'player', 'wagon_' .. wagon.entity.unit_number .. '_4')
        left_4.destructible = false
        left_4.minable = false

        local right_1 = LinkedChests.add(surface, position2, 'player', 'wagon_' .. wagon.entity.unit_number .. '_5')
        right_1.destructible = false
        right_1.minable = false

        local right_2 = LinkedChests.add(surface, {position2[1] + 1, position2[2]}, 'player', 'wagon_' .. wagon.entity.unit_number .. '_6')
        right_2.destructible = false
        right_2.minable = false

        local right_3 = LinkedChests.add(surface, {position2[1] + 2, position2[2]}, 'player', 'wagon_' .. wagon.entity.unit_number .. '_7')
        right_3.destructible = false
        right_3.minable = false

        local right_4 = LinkedChests.add(surface, {position2[1] + 3, position2[2]}, 'player', 'wagon_' .. wagon.entity.unit_number .. '_8')
        right_4.destructible = false
        right_4.minable = false

        local bottom_left_1 = LinkedChests.add(surface, position3, 'player', 'wagon_' .. wagon.entity.unit_number .. '_9')
        bottom_left_1.destructible = false
        bottom_left_1.minable = false

        local bottom_left_2 = LinkedChests.add(surface, {position3[1] - 1, position3[2]}, 'player', 'wagon_' .. wagon.entity.unit_number .. '_10')
        bottom_left_2.destructible = false
        bottom_left_2.minable = false

        local bottom_left_3 = LinkedChests.add(surface, {position3[1] - 2, position3[2]}, 'player', 'wagon_' .. wagon.entity.unit_number .. '_11')
        bottom_left_3.destructible = false
        bottom_left_3.minable = false

        local bottom_left_4 = LinkedChests.add(surface, {position3[1] - 3, position3[2]}, 'player', 'wagon_' .. wagon.entity.unit_number .. '_12')
        bottom_left_4.destructible = false
        bottom_left_4.minable = false

        local bottom_right_1 = LinkedChests.add(surface, position4, 'player', 'wagon_' .. wagon.entity.unit_number .. '_13')
        bottom_right_1.destructible = false
        bottom_right_1.minable = false

        local bottom_right_2 = LinkedChests.add(surface, {position4[1] + 1, position4[2]}, 'player', 'wagon_' .. wagon.entity.unit_number .. '_14')
        bottom_right_2.destructible = false
        bottom_right_2.minable = false

        local bottom_right_3 = LinkedChests.add(surface, {position4[1] + 2, position4[2]}, 'player', 'wagon_' .. wagon.entity.unit_number .. '_15')
        bottom_right_3.destructible = false
        bottom_right_3.minable = false

        local bottom_right_4 = LinkedChests.add(surface, {position4[1] + 3, position4[2]}, 'player', 'wagon_' .. wagon.entity.unit_number .. '_16')
        bottom_right_4.destructible = false
        bottom_right_4.minable = false
    end
)

local reconstruct_all_trains =
    Task.register(
    function(data)
        local icw = data.icw
        Public.reconstruct_all_trains(icw)
    end
)

local remove_non_migrated_doors_token =
    Task.register(
    function(data)
        local icw = data.icw
        for _, unit_data in pairs(icw.wagons) do
            if not unit_data.migrated then
                for _, door in pairs(unit_data.doors) do
                    if door and door.valid then
                        door.destroy()
                    end
                end
            end
        end
    end
)

local function get_tile_name()
    -- local main_tile_name = 'tutorial-grid'
    -- local main_tile_name = 'stone-path'
    local main_tile_name = 'black-refined-concrete'

    return main_tile_name
end

function Public.request_reconstruction(icw)
    Task.set_timeout_in_ticks(60, reconstruct_all_trains, {icw = icw})
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

local function delete_empty_surfaces(icw)
    for k, surface in pairs(icw.surfaces) do
        if not icw.trains[tonumber(surface.name)] then
            game.delete_surface(surface)
            icw.surfaces[k] = nil
        end
    end
end

local function kick_players_from_surface(wagon)
    if not validate_entity(wagon.surface) then
        return print('Surface was not valid.')
    end
    if not wagon.entity or not wagon.entity.valid then
        local main_surface = wagon.surface
        if validate_entity(main_surface) then
            for _, e in pairs(wagon.surface.find_entities_filtered({area = wagon.area})) do
                if validate_entity(e) and e.name == 'character' and e.player then
                    e.player.teleport(main_surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(main_surface), 3, 0, 5), main_surface)
                end
            end
        end
        return print('Wagon entity was not valid.')
    end

    for _, e in pairs(wagon.surface.find_entities_filtered({area = wagon.area})) do
        if validate_entity(e) and e.name == 'character' and e.player then
            local p = wagon.entity.surface.find_non_colliding_position('character', wagon.entity.position, 128, 0.5)
            if p then
                e.player.teleport(p, wagon.entity.surface)
            else
                e.player.teleport(wagon.entity.position, wagon.entity.surface)
            end
        end
    end
end

local function kick_players_out_of_vehicles(wagon)
    for _, player in pairs(game.connected_players) do
        local character = player.character
        if character and character.valid and character.driving then
            if wagon.surface == player.surface then
                character.driving = false
            end
        end
    end
end

local function teleport_char(position, destination_area, wagon)
    for _, e in pairs(wagon.surface.find_entities_filtered({name = 'character', area = wagon.area})) do
        local player = e.player
        if player then
            position[player.index] = {
                player.position.x,
                player.position.y + (destination_area.left_top.y - wagon.area.left_top.y)
            }
            player.teleport({0, 0}, game.surfaces.nauvis)
        end
    end
end

local function connect_power_pole(entity, wagon_area_left_top_y)
    local surface = entity.surface
    local max_wire_distance = entity.prototype.max_wire_distance
    local area = {
        {entity.position.x - max_wire_distance, entity.position.y - max_wire_distance},
        {entity.position.x + max_wire_distance, entity.position.y - 1}
    }
    for _, pole in pairs(surface.find_entities_filtered({area = area, name = entity.name})) do
        if pole.position.y < wagon_area_left_top_y then
            entity.connect_neighbour(pole)
            return
        end
    end
end

local function equal_fluid(source_tank, target_tank)
    if not source_tank.valid then
        return
    end
    if not target_tank.valid then
        return
    end

    local source_fluid = source_tank.fluidbox[1]
    if not source_fluid then
        return
    end

    local target_fluid = target_tank.fluidbox[1]
    local source_fluid_amount = source_fluid.amount

    local amount
    if target_fluid then
        amount = source_fluid_amount - ((target_fluid.amount + source_fluid_amount) * 0.5)
    else
        amount = source_fluid.amount * 0.5
    end

    if amount <= 0 then
        return
    end

    local inserted_amount = target_tank.insert_fluid({name = source_fluid.name, amount = amount, temperature = source_fluid.temperature})
    if inserted_amount > 0 then
        source_tank.remove_fluid({name = source_fluid.name, amount = inserted_amount})
    end
end

local function divide_fluid(wagon, storage_tank)
    if not validate_entity(wagon.entity) then
        return
    end

    local fluid_wagon = wagon.entity
    equal_fluid(fluid_wagon, storage_tank)
    equal_fluid(storage_tank, fluid_wagon)
end

function Public.disable_auto_minimap()
    local icw = ICW.get()

    Core.iter_connected_players(
        function(player)
            local data = Public.get_player_data(icw, player)
            if not data then
                return
            end
            Gui.clear_all_active_frames(player)
            data.auto = false
            Public.kill_minimap(player)
        end
    )
end

function Public.hazardous_debris()
    local surface = WPT.get('loco_surface')
    if not surface or not surface.valid then
        return
    end
    local icw = ICW.get()
    local speed = icw.speed
    local final_battle = icw.final_battle

    local hazardous_debris = icw.hazardous_debris
    if not hazardous_debris then
        return
    end

    local create = surface.create_entity

    if final_battle then
        for _ = 1, 16 * speed, 1 do
            local position = fallout_debris[random(1, size_of_debris)]
            local p = {x = position[1], y = position[2]}
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == 'out-of-map' then
                create({name = 'slowdown-capsule', position = position, force = 'neutral', target = {position[1], position[2] + fallout_width * 2}, speed = speed})
            end
        end

        for _ = 1, 6 * speed, 1 do
            local position = fallout_debris[random(1, size_of_debris)]
            local p = {x = position[1], y = position[2]}
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == 'out-of-map' then
                create({name = 'slowdown-capsule', position = position, force = 'neutral', target = {position[1], position[2] + fallout_width * 2}, speed = speed})
            end
        end

        for _ = 1, 4 * speed, 1 do
            local position = fallout_debris[random(1, size_of_debris)]
            local p = {x = position[1], y = position[2]}
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == 'out-of-map' then
                create(
                    {
                        name = 'atomic-bomb-wave-spawns-nuke-shockwave-explosion',
                        position = position,
                        force = 'neutral',
                        target = {position[1], position[2] + fallout_width * 2},
                        speed = speed
                    }
                )
            end
        end

        for _ = 1, 6 * speed, 1 do
            local position = fallout_debris[random(1, size_of_debris)]
            local p = {x = position[1], y = position[2]}
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == 'out-of-map' then
                create(
                    {
                        name = 'slowdown-capsule',
                        position = position,
                        force = 'neutral',
                        target = {position[1], position[2] + fallout_width * 2},
                        speed = speed
                    }
                )
            end
        end
    else
        for _ = 1, 16 * speed, 1 do
            local position = fallout_debris[random(1, size_of_debris)]
            local p = {x = position[1], y = position[2]}
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == 'out-of-map' then
                create({name = 'shotgun-pellet', position = position, force = 'neutral', target = {position[1], position[2] + fallout_width * 2}, speed = speed})
            end
        end

        for _ = 1, 6 * speed, 1 do
            local position = fallout_debris[random(1, size_of_debris)]
            local p = {x = position[1], y = position[2]}
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == 'out-of-map' then
                create({name = 'cannon-projectile', position = position, force = 'neutral', target = {position[1], position[2] + fallout_width * 2}, speed = speed})
            end
        end

        for _ = 1, 4 * speed, 1 do
            local position = fallout_debris[random(1, size_of_debris)]
            local p = {x = position[1], y = position[2]}
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == 'out-of-map' then
                create(
                    {
                        name = 'atomic-bomb-wave-spawns-nuke-shockwave-explosion',
                        position = position,
                        force = 'neutral',
                        target = {position[1], position[2] + fallout_width * 2},
                        speed = speed
                    }
                )
            end
        end

        for _ = 1, 6 * speed, 1 do
            local position = fallout_debris[random(1, size_of_debris)]
            local p = {x = position[1], y = position[2]}
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == 'out-of-map' then
                create(
                    {
                        name = 'uranium-cannon-projectile',
                        position = position,
                        force = 'neutral',
                        target = {position[1], position[2] + fallout_width * 2},
                        speed = speed
                    }
                )
            end
        end
    end
end

local transfer_functions = {
    ['storage-tank'] = divide_fluid
}

local function get_wagon_for_entity(icw, entity)
    if not validate_entity(entity) then
        return
    end

    local train = icw.trains[tonumber(entity.surface.name)]

    if not train then
        return
    end

    local position = entity.position
    for k, unit_number in pairs(train.wagons) do
        local wagon = icw.wagons[unit_number]
        if wagon then
            local left_top = wagon.area.left_top
            local right_bottom = wagon.area.right_bottom
            if position.x >= left_top.x and position.y >= left_top.y and position.x <= right_bottom.x and position.y <= right_bottom.y then
                return wagon
            end
        end
    end
    return false
end

local function kill_wagon_doors(icw, wagon)
    if not validate_entity(wagon.entity) then
        return
    end
    for k, e in pairs(wagon.doors) do
        if e and e.valid then
            icw.doors[e.unit_number] = nil
            e.destroy()
            wagon.doors[k] = nil
        end
    end
end

local function construct_wagon_doors(icw, wagon)
    local area = wagon.area
    local surface = wagon.surface
    local main_tile_name = get_tile_name()

    for _, x in pairs({area.left_top.x - 1.5, area.right_bottom.x + 1.5}) do
        local p = {x = x, y = area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5)}
        if p.x < 0 then
            surface.set_tiles({{name = main_tile_name, position = {x = p.x + 0.5, y = p.y}}}, true)
        else
            surface.set_tiles({{name = main_tile_name, position = {x = p.x - 1, y = p.y}}}, true)
        end
        local e =
            surface.create_entity(
            {
                name = 'car',
                position = {x, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5)},
                force = 'neutral',
                create_build_effect_smoke = false
            }
        )
        e.destructible = false
        e.minable = false
        e.operable = false
        e.get_inventory(defines.inventory.fuel).insert({name = 'coal', count = 1})
        icw.doors[e.unit_number] = wagon.entity.unit_number
        wagon.doors[#wagon.doors + 1] = e
    end
end

local function get_player_data(icw, player)
    local player_data = icw.players[player.index]
    if icw.players[player.index] then
        return player_data
    end

    local fallback = WPT.get('active_surface_index')
    if not fallback then
        fallback = 1
    end

    icw.players[player.index] = {
        surface = 1,
        fallback_surface = tonumber(fallback),
        zoom = 0.30,
        auto = true,
        map_size = 360
    }
    return icw.players[player.index]
end

function Public.kill_minimap(player)
    local element = player.gui.left.icw_main_frame
    if element then
        element.destroy()
    end
end

function Public.is_minimap_valid(player, surface)
    if validate_entity(player) then
        if player.surface ~= surface then
            Public.kill_minimap(player)
        end
    end
end

function Public.kill_wagon(icw, entity)
    if not validate_entity(entity) then
        return
    end

    local wagon_types = ICW.get('wagon_types')

    if not wagon_types[entity.type] then
        return
    end
    local wagon = icw.wagons[entity.unit_number]
    if not wagon then
        return
    end

    local surface = wagon.surface
    kick_players_from_surface(wagon)
    kick_players_out_of_vehicles(wagon)
    kill_wagon_doors(icw, wagon)
    for _, tile in pairs(surface.find_tiles_filtered({area = wagon.area})) do
        surface.set_tiles({{name = 'out-of-map', position = tile.position}}, true)
    end
    for _, x in pairs({wagon.area.left_top.x - 1.5, wagon.area.right_bottom.x + 1.5}) do
        local p = {x = x, y = wagon.area.left_top.y + ((wagon.area.right_bottom.y - wagon.area.left_top.y) * 0.5)}
        surface.set_tiles({{name = 'out-of-map', position = {x = p.x + 0.5, y = p.y}}}, true)
        surface.set_tiles({{name = 'out-of-map', position = {x = p.x - 1, y = p.y}}}, true)
    end
    wagon.entity.force.chart(surface, wagon.area)
    icw.wagons[entity.unit_number] = nil
    Public.request_reconstruction(icw)
end

function Public.create_room_surface(icw, unit_number)
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
    icw.surfaces[#icw.surfaces + 1] = surface
    return surface
end

function Public.create_wagon_room(icw, wagon)
    local surface = wagon.surface
    local area = wagon.area
    local main_tile_name = get_tile_name()

    local tiles = {}
    for x = -3, 2, 1 do
        tiles[#tiles + 1] = {name = 'hazard-concrete-right', position = {x, area.left_top.y}}
        tiles[#tiles + 1] = {name = 'hazard-concrete-right', position = {x, area.right_bottom.y - 1}}
    end
    for x = area.left_top.x, area.right_bottom.x - 1, 1 do
        for y = area.left_top.y + 2, area.right_bottom.y - 3, 1 do
            tiles[#tiles + 1] = {name = main_tile_name, position = {x, y}}
        end
    end
    for x = -3, 2, 1 do
        for y = 1, 3, 1 do
            tiles[#tiles + 1] = {name = main_tile_name, position = {x, y}}
        end
        for y = area.right_bottom.y - 4, area.right_bottom.y - 2, 1 do
            tiles[#tiles + 1] = {name = main_tile_name, position = {x, y}}
        end
    end

    local fishes = {}

    if wagon.entity.type == 'locomotive' then
        for x = -6, 5, 1 do
            for y = 10, 12, 1 do
                tiles[#tiles + 1] = {name = 'water', position = {x, y}}
                fishes[#fishes + 1] = {name = 'fish', position = {x, y}}
            end
        end
    end

    surface.set_tiles(tiles, true)

    for _, fish in pairs(fishes) do
        surface.create_entity(fish)
    end

    construct_wagon_doors(icw, wagon)
    local mgs = surface.map_gen_settings
    mgs.width = area.right_bottom.x * 2
    mgs.height = area.right_bottom.y * 2
    surface.map_gen_settings = mgs

    if wagon.entity.type == 'fluid-wagon' then
        local height = area.right_bottom.y - area.left_top.y
        local positions = {
            {area.right_bottom.x, area.left_top.y + height * 0.25},
            {area.right_bottom.x, area.left_top.y + height * 0.75},
            {area.left_top.x - 1, area.left_top.y + height * 0.25},
            {area.left_top.x - 1, area.left_top.y + height * 0.75}
        }
        table.shuffle_table(positions)
        local e =
            surface.create_entity(
            {
                name = 'storage-tank',
                position = positions[1],
                force = 'neutral',
                create_build_effect_smoke = false
            }
        )
        e.destructible = false
        e.minable = false
        wagon.transfer_entities = {e}
        return
    end

    if wagon.entity.type == 'cargo-wagon' then
        Task.set_timeout_in_ticks(5, add_chests_to_wagon_token, {wagon = wagon, surface = surface})
    end
end

function Public.create_wagon(icw, created_entity, delay_surface)
    if not validate_entity(created_entity) then
        return
    end

    local wagon_types = ICW.get('wagon_types')
    local wagon_areas = ICW.get('wagon_areas')

    if not created_entity.unit_number then
        return
    end
    if icw.trains[tonumber(created_entity.surface.name)] or icw.wagons[tonumber(created_entity.surface.name)] then
        return
    end
    if not wagon_types[created_entity.type] then
        return
    end
    local wagon_area = wagon_areas[created_entity.type]

    icw.wagons[created_entity.unit_number] = {
        entity = created_entity,
        area = {
            left_top = {x = wagon_area.left_top.x, y = wagon_area.left_top.y},
            right_bottom = {x = wagon_area.right_bottom.x, y = wagon_area.right_bottom.y}
        },
        doors = {}
    }
    local wagon = icw.wagons[created_entity.unit_number]

    if not delay_surface then
        wagon.surface = Public.create_room_surface(icw, created_entity.unit_number)
        Public.create_wagon_room(icw, icw.wagons[created_entity.unit_number])
    end

    Public.request_reconstruction(icw)
    return wagon
end

function Public.migrate_wagon(icw, source, target)
    if not validate_entity(target) then
        return
    end

    target.minable = false

    local target_wagon = target.unit_number
    local source_wagon = source.unit_number

    for door_id, entity_id in pairs(icw.doors) do
        if entity_id == source_wagon then
            icw.doors[door_id] = target_wagon
        end
    end
    for _, surface_data in pairs(icw.surfaces) do
        if surface_data.name == source_wagon then
            surface_data.name = tostring(target_wagon)
        end
    end

    for unit_number, unit_data in pairs(icw.wagons) do
        if unit_number == source_wagon then
            unit_data.surface.name = tostring(target_wagon)
            unit_data.entity = target
            unit_data.migrated = true
            icw.wagons[target_wagon] = deepcopy(unit_data)
        end
    end

    Task.set_timeout_in_ticks(100, remove_non_migrated_doors_token, {icw = icw})
end

function Public.use_cargo_wagon_door_with_entity(icw, player, door)
    local player_data = get_player_data(icw, player)
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
    local doors = icw.doors
    local wagons = icw.wagons

    local wagon = false
    if doors[door.unit_number] then
        wagon = wagons[doors[door.unit_number]]
    end
    if wagons[door.unit_number] then
        wagon = wagons[door.unit_number]
    end
    if not wagon then
        return
    end

    if not wagon.entity or not wagon.entity.valid then
        return
    end

    player_data.fallback_surface = wagon.entity.surface.index
    player_data.fallback_position = {wagon.entity.position.x, wagon.entity.position.y}

    if wagon.entity.surface.name ~= player.surface.name then
        local surface = wagon.entity.surface
        if not (surface and surface.valid) then
            return
        end
        local x_vector = (door.position.x / math.abs(door.position.x)) * 2
        local position = {wagon.entity.position.x + x_vector, wagon.entity.position.y}
        local surface_position = surface.find_non_colliding_position('character', position, 128, 0.5)
        if not position then
            return
        end
        if not surface_position then
            surface.request_to_generate_chunks({-20, 22}, 1)
            if player.character and player.character.valid and player.character.driving then
                if wagon.surface == player.surface then
                    player.character.driving = false
                end
            end
            return
        end
        if wagon.entity.type == 'locomotive' then
            player.teleport(surface_position, surface)
            player_data.state = 2
            player.driving = true
            Public.kill_minimap(player)
        else
            player.teleport(surface_position, surface)
            Public.kill_minimap(player)
        end
        player_data.surface = surface.index
    else
        local surface = wagon.surface
        if not (surface and surface.valid) then
            return
        end
        local area = wagon.area
        local x_vector = door.position.x - player.position.x
        local position
        if x_vector > 0 then
            position = {area.left_top.x + 0.5, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5)}
        else
            position = {area.right_bottom.x - 0.5, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5)}
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

local function move_room_to_train(icw, train, wagon)
    if not wagon then
        return
    end
    train.wagons[#train.wagons + 1] = wagon.entity.unit_number

    local destination_area = {
        left_top = {x = wagon.area.left_top.x, y = train.top_y},
        right_bottom = {
            x = wagon.area.right_bottom.x,
            y = train.top_y + (wagon.area.right_bottom.y - wagon.area.left_top.y)
        }
    }

    train.top_y = destination_area.right_bottom.y

    if destination_area.left_top.x == wagon.area.left_top.x and destination_area.left_top.y == wagon.area.left_top.y and wagon.surface.name == train.surface.name then
        return
    end
    kick_players_from_surface(wagon)
    kick_players_out_of_vehicles(wagon)
    local player_positions = {}
    teleport_char(player_positions, destination_area, wagon)

    kill_wagon_doors(icw, wagon)

    wagon.surface.clone_area(
        {
            source_area = wagon.area,
            destination_area = destination_area,
            destination_surface = train.surface,
            clone_tiles = true,
            clone_entities = true,
            clear_destination_entities = true,
            expand_map = true
        }
    )

    for player_index, position in pairs(player_positions) do
        local player = game.players[player_index]
        player.teleport(position, train.surface)
    end

    for _, tile in pairs(wagon.surface.find_tiles_filtered({area = wagon.area})) do
        wagon.surface.set_tiles({{name = 'out-of-map', position = tile.position}}, true)
    end
    wagon.entity.force.chart(wagon.surface, wagon.area)

    wagon.surface = train.surface
    wagon.area = destination_area
    wagon.transfer_entities = {}
    construct_wagon_doors(icw, wagon)

    local left_top_y = wagon.area.left_top.y
    for _, e in pairs(wagon.surface.find_entities_filtered({type = 'electric-pole', area = wagon.area})) do
        connect_power_pole(e, left_top_y)
    end

    for _, e in pairs(wagon.surface.find_entities_filtered({area = wagon.area, force = 'neutral'})) do
        if transfer_functions[e.name] then
            wagon.transfer_entities[#wagon.transfer_entities + 1] = e
        end
    end
end

function Public.construct_train(icw, locomotive, carriages)
    for i, carriage in pairs(carriages) do
        if carriage == locomotive then
            local adjusted_zones = WPT.get('adjusted_zones')

            local stock
            if adjusted_zones.reversed then
                stock = locomotive.get_connected_rolling_stock(defines.rail_direction.back)
            else
                stock = locomotive.get_connected_rolling_stock(defines.rail_direction.front)
            end
            if stock ~= carriages[i - 1] then
                local n = 1
                local m = #carriages
                while (n < m) do
                    carriages[n], carriages[m] = carriages[m], carriages[n]
                    n = n + 1
                    m = m - 1
                end
                break
            end
        end
    end
    local unit_number = carriages[1].unit_number

    if icw.trains[unit_number] then
        return
    end

    local train = {surface = Public.create_room_surface(icw, unit_number), wagons = {}, top_y = 0}
    icw.trains[unit_number] = train

    for _, carriage in pairs(carriages) do
        move_room_to_train(icw, train, icw.wagons[carriage.unit_number])
    end
end

function Public.reconstruct_all_trains(icw)
    local final_battle = WPT.get('final_battle')
    if final_battle then
        return
    end

    icw.trains = {}
    for unit_number, wagon in pairs(icw.wagons) do
        if not validate_entity(wagon.entity) then
            icw.wagons[unit_number] = nil
            Public.request_reconstruction(icw)
            return
        end

        local locomotive = WPT.get('locomotive')
        if not (locomotive and locomotive.valid) then
            return
        end

        if not wagon.surface then
            wagon.surface = Public.create_room_surface(icw, unit_number)
            Public.create_wagon_room(icw, wagon)
        end
        local carriages = wagon.entity.train.carriages

        Public.construct_train(icw, locomotive, carriages)
    end
    delete_empty_surfaces(icw)
end

function Public.item_transfer()
    local icw = ICW.get()
    local wagon
    icw.current_wagon_index, wagon = next(icw.wagons, icw.current_wagon_index)
    if not wagon then
        return
    end
    if validate_entity(wagon.entity) and wagon.transfer_entities then
        for _, e in pairs(wagon.transfer_entities) do
            if validate_entity(e) then
                transfer_functions[e.name](wagon, e)
            end
        end
    end
end

function Public.toggle_auto(icw, player)
    local player_data = get_player_data(icw, player)
    local switch = player.gui.left.icw_main_frame['icw_auto_switch']
    if switch.switch_state == 'left' then
        player_data.auto = true
    elseif switch.switch_state == 'right' then
        player_data.auto = false
    end
end

function Public.draw_minimap(icw, player, surface, position)
    if not (surface and surface.valid) then
        return
    end
    local player_data = get_player_data(icw, player)
    local frame = player.gui.left.icw_main_frame
    if not frame then
        frame = player.gui.left.add({type = 'frame', direction = 'vertical', name = 'icw_main_frame', caption = 'Minimap'})
    end
    local element = frame['icw_sub_frame']
    if not frame.icw_auto_switch then
        frame.add({type = 'switch', name = 'icw_auto_switch', allow_none_state = false, left_label_caption = {'gui.map_on'}, right_label_caption = {'gui.map_off'}})
    end
    if not element then
        element =
            player.gui.left.icw_main_frame.add(
            {
                type = 'camera',
                position = position,
                name = 'icw_sub_frame',
                surface_index = surface.index,
                zoom = player_data.zoom,
                tooltip = 'LMB: Increase zoom level.\nRMB: Decrease zoom level.\nMMB: Toggle camera size.'
            }
        )
        element.style.margin = 1
        element.style.minimal_height = player_data.map_size
        element.style.minimal_width = player_data.map_size
        return
    end

    element.position = position
end

function Public.update_minimap()
    local icw = ICW.get()
    for _, player in pairs(game.connected_players) do
        if player and player.valid then
            local player_data = get_player_data(icw, player)
            if player.character and player.character.valid then
                local wagon = get_wagon_for_entity(icw, player.character)
                if wagon and player_data.auto then
                    if wagon and wagon.entity and wagon.entity.valid then
                        Public.draw_minimap(icw, player, wagon.entity.surface, wagon.entity.position)
                    end
                end
            end
        end
    end
end

function Public.toggle_minimap(icw, event)
    local element = event.element
    if not element then
        return
    end
    if not element.valid then
        return
    end
    if element.name ~= 'icw_sub_frame' then
        return
    end
    local player = game.players[event.player_index]
    local is_spamming = SpamProtection.is_spamming(player, 5, 'ICW Toggle Minimap')
    if is_spamming then
        return
    end
    local player_data = get_player_data(icw, player)
    if event.button == defines.mouse_button_type.right then
        player_data.zoom = player_data.zoom - 0.07
        if player_data.zoom < 0.07 then
            player_data.zoom = 0.07
        end
        element.zoom = player_data.zoom
        return
    end
    if event.button == defines.mouse_button_type.left then
        player_data.zoom = player_data.zoom + 0.07
        if player_data.zoom > 2 then
            player_data.zoom = 2
        end
        element.zoom = player_data.zoom
        return
    end
    if event.button == defines.mouse_button_type.middle then
        player_data.map_size = player_data.map_size + 50
        if player_data.map_size > 650 then
            player_data.map_size = 250
        end
        element.style.minimal_height = player_data.map_size
        element.style.minimal_width = player_data.map_size
        element.style.maximal_height = player_data.map_size
        element.style.maximal_width = player_data.map_size
        return
    end
end

function Public.on_player_or_robot_built_tile(event)
    local surface = game.surfaces[event.surface_index]

    local map_name = 'mtn_v3'

    if string.sub(surface.name, 0, #map_name) == map_name then
        return
    end

    local tiles = event.tiles
    if not tiles then
        return
    end

    for _, v in pairs(tiles) do
        local old_tile = v.old_tile
        if old_tile.name == 'water' then
            surface.set_tiles({{name = 'water', position = v.position}}, true)
        end
    end
end

function Public.on_entity_cloned(source, destination)
    LinkedChests.migrate(source, destination)
end

Public.get_player_data = get_player_data

return Public
