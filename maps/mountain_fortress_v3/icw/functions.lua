local Public = {}

local Event = require 'utils.event'
local ICW = require 'maps.mountain_fortress_v3.icw.table'
local WPT = require 'maps.mountain_fortress_v3.table'
local Task = require 'utils.task_token'
local Gui = require 'utils.gui'
local SpamProtection = require 'utils.spam_protection'
local Core = require 'utils.core'
local LinkedChests = require 'maps.mountain_fortress_v3.icw.linked_chests'

local deep_copy = table.deep_copy
local random = math.random
local sqrt = math.sqrt
local move_room_to_train

local out_of_map_tile = 'out-of-map'

local fallout_width = 64
local fallout_debris = {}
local chunk_reveal_token
local reconstruct_all_trains

local construct_train_token =
    Task.register(
        function (event)
            local icw = event.icw
            local carriage = event.carriage
            if not carriage or not carriage.valid then
                return error('Carriage was invalid, please check this out!')
            end

            local train = event.train
            local chunk_position = event.chunk_position
            local saved_carriages = event.saved_carriages

            local carriage_wagon = icw.wagons[carriage.unit_number]

            move_room_to_train(icw, train, carriage_wagon, saved_carriages)
            carriage_wagon.chunk_position.x = chunk_position.x
        end
    )

local clear_old_surfaces_token =
    Task.register(
        function ()
            local icw = ICW.get()
            local surfaces_in_use = {}

            for _, wagon in pairs(icw.wagons) do
                if wagon.surface and wagon.surface.valid then
                    surfaces_in_use[wagon.surface.index] = true
                end
            end

            for _, train in pairs(icw.trains) do
                if train.surface and train.surface.valid then
                    surfaces_in_use[train.surface.index] = true
                end
            end

            local new_surfaces = {}
            for _, surface in pairs(icw.surfaces) do
                if surface and surface.valid then
                    local is_in_use = surfaces_in_use[surface.index]
                    local is_default = icw.default_surface and surface.name == WPT.get_planet()

                    if not is_in_use and not is_default then
                        game.delete_surface(surface)
                    else
                        new_surfaces[#new_surfaces + 1] = surface
                    end
                end
            end
            icw.surfaces = new_surfaces
        end
    )

chunk_reveal_token =
    Task.register(
        function (event)
            local surface_index = event.surface_index
            local surface = game.get_surface(surface_index)
            local wagons = ICW.get('wagons')
            for _, wagon in pairs(wagons) do
                local area = wagon.area
                local new_area =
                {
                    left_top =
                    {
                        x = area.left_top.x - 80,
                        y = area.left_top.y - 80
                    },
                    right_bottom =
                    {
                        x = area.right_bottom.x + 80,
                        y = area.right_bottom.y + 80
                    }
                }
                game.forces.player.chart(surface.name, new_area)
            end
        end
    )

for x = fallout_width * -1 - 80, fallout_width + 80, 1 do
    if x < -80 or x > 80 then
        for y = fallout_width * -1 - 80, fallout_width + 80, 1 do
            local position = { x = x, y = y }
            local fallout = sqrt(position.x ^ 2 + position.y ^ 2)
            if fallout > fallout_width then
                fallout_debris[#fallout_debris + 1] = { position.x, position.y }
            end
        end
    end
end
local size_of_debris = #fallout_debris

local function get_offset(icw, surface, offset)
    if not icw.default_surface then
        return { x = 0, y = 0 }
    end
    local position =
    {
        x = 2030 + offset,
        y = 0
    }

    Task.set_timeout_in_ticks(10, chunk_reveal_token, { surface_index = surface.index })

    for _, tile in pairs(surface.find_tiles_filtered({ area = { { position.x - 2, -2 }, { position.x + 2, 2 } } })) do
        surface.set_tiles({ { name = out_of_map_tile, position = tile.position } }, true)
    end

    return position
end

local add_chests_to_wagon_token =
    Task.register(
        function (data)
            local wagon = data.wagon
            local surface = data.surface
            local position1 = { wagon.area.left_top.x + 4, wagon.area.left_top.y + 1 }
            local position2 = { wagon.area.right_bottom.x - 5, wagon.area.left_top.y + 1 }
            local position3 = { wagon.area.left_top.x + 4, wagon.area.right_bottom.y - 2 }
            local position4 = { wagon.area.right_bottom.x - 5, wagon.area.right_bottom.y - 2 }

            if not wagon.entity or not wagon.entity.valid then
                return error('Entity was invalid, please check this out!')
            end

            local positions =
            {
                { position1, 0, '_1' },
                { position1, -1, '_2' },
                { position1, -2, '_3' },
                { position1, -3, '_4' },
                { position2, 0, '_5' },
                { position2, 1, '_6' },
                { position2, 2, '_7' },
                { position2, 3, '_8' },
                { position3, 0, '_9' },
                { position3, -1, '_10' },
                { position3, -2, '_11' },
                { position3, -3, '_12' },
                { position4, 0, '_13' },
                { position4, 1, '_14' },
                { position4, 2, '_15' },
                { position4, 3, '_16' }
            }

            for _, pos_data in ipairs(positions) do
                local base_pos, offset, suffix = table.unpack(pos_data)
                local chest = LinkedChests.add(surface, { base_pos[1] + offset, base_pos[2] }, 'player', 'wagon_' .. wagon.entity.unit_number .. suffix, true)
                chest.destructible = false
                chest.minable_flag = false
            end
        end
    )

reconstruct_all_trains =
    Task.register(
        function ()
            local icw = ICW.get()
            icw.reconstruction_pending = false
            Public.reconstruct_all_trains()
        end
    )

-- local ICW = require 'maps.mountain_fortress_v3.icw.functions'
-- local icw_table = require 'maps.mountain_fortress_v3.icw.table'.get()
-- ICW.reconstruct_all_trains()

local remove_non_migrated_doors_token =
    Task.register(
        function (data)
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
    -- local starting_planet = WPT.get_planet()
    -- if starting_planet == 'nauvis' or starting_planet == 'fortress' then
    --     return 'black-refined-concrete'
    -- elseif starting_planet == 'fulgora' then
    --     return 'black-refined-concrete'
    -- end

    return 'refined-concrete'
end

local function has_wagon_id(carriages, id)
    for _, wagon in pairs(carriages) do
        if wagon.unit_number == id then
            return true
        end
    end
    return false
end

local function carriages_not_saved(icw, carriages)
    if not icw.carriages or #icw.carriages == 0 then
        return true
    end

    for index, saved_train in pairs(icw.carriages) do
        if has_wagon_id(carriages, saved_train.id) then
            local saved_wagons = saved_train.carriages

            if #saved_wagons ~= #carriages then
                return true, index
            end

            for i, wagon in ipairs(carriages) do
                if not saved_wagons[i] or saved_wagons[i].unit_number ~= wagon.unit_number then
                    return true, index
                end
            end

            return false
        end
    end

    return true
end

local function clear_saved_carriages(icw, unit_number)
    if not icw.carriages or #icw.carriages == 0 then
        return
    end

    for index, data in pairs(icw.carriages) do
        if unit_number == data.id then -- Match by parent Id
            table.remove(icw.carriages, index)
        end
        for _, wagon in pairs(data.carriages) do
            if wagon.unit_number == unit_number then
                table.remove(icw.carriages, index)
            end
        end
    end

    Public.request_reconstruction()
end

local function get_saved_carriages(icw, carriages)
    if not icw.carriages or #icw.carriages == 0 then
        return
    end

    for _, data in pairs(icw.carriages) do
        if has_wagon_id(carriages, data.id) then
            return data
        end
    end
end

function Public.request_reconstruction()
    local icw = ICW.get()
    if icw.reconstruction_pending then
        return
    end
    icw.reconstruction_pending = true
    Task.set_timeout_in_ticks(5, reconstruct_all_trains, {})
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

local function kick_players_from_surface(wagon)
    if not validate_entity(wagon.surface) then
        return print('Surface was not valid.')
    end
    if not wagon.entity or not wagon.entity.valid then
        local main_surface = wagon.surface
        if validate_entity(main_surface) then
            for _, e in pairs(wagon.surface.find_entities_filtered({ area = wagon.area })) do
                if validate_entity(e) and e.name == 'character' and e.player then
                    e.player.teleport(main_surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(main_surface), 3, 0, 5), main_surface)
                end
            end
        end
        return print('Wagon entity was not valid.')
    end

    for _, e in pairs(wagon.surface.find_entities_filtered({ area = wagon.area })) do
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

-- This function broke whenever a player tried to connect a wagon - sent them straight to the void and instantly killed them.
--[[
local function kick_players_out_of_vehicles(wagon)
    for _, player in pairs(game.connected_players) do
        local character = player.character
        if character and character.valid and character.driving then
            if wagon.surface == player.physical_surface then
                character.driving = false
            end
        end
    end
end
]]
local function teleport_char(position, destination_area, wagon)
    if not wagon.surface or not wagon.surface.valid then
        return
    end
    for _, e in pairs(wagon.surface.find_entities_filtered({ name = 'character', area = wagon.area })) do
        local player = e.player
        if player then
            position[player.index] =
            {
                player.physical_position.x,
                player.physical_position.y + (destination_area.left_top.y - wagon.area.left_top.y)
            }
            player.teleport({ 0, 0 }, game.surfaces.fortress)
        end
    end
end

local function connect_power_pole(entity, wagon_area_left_top_y)
    local surface = entity.surface
    local max_wire_distance = prototypes.entity[entity.name].get_max_wire_distance()
    local area =
    {
        { entity.position.x - max_wire_distance, entity.position.y - max_wire_distance },
        { entity.position.x + max_wire_distance, entity.position.y - 1 }
    }
    for _, pole in pairs(surface.find_entities_filtered({ area = area, name = entity.name })) do
        if pole.position.y < wagon_area_left_top_y then
            local source_wire = entity.get_wire_connector(5)
            local target_wire = pole.get_wire_connector(5)
            if source_wire and target_wire then
                source_wire.connect_to(target_wire, false)
            end
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

    local source_fluid = source_tank.get_fluid(1) ~= nil and source_tank.get_fluid(1)
    if not source_fluid then
        return
    end

    local target_fluid = target_tank.get_fluid(1)
    local source_fluid_amount = source_fluid.amount

    local amount
    if target_fluid then
        amount = source_fluid_amount - ((target_fluid.amount + source_fluid_amount) * 0.5)
    else
        amount = source_fluid.amount * 0.5
    end

    if amount <= 1 then
        return
    end

    if amount > 0 then
        local inserted_amount = target_tank.insert_fluid({ name = source_fluid.name, amount = amount, temperature = source_fluid.temperature })
        if inserted_amount > 0 then
            source_tank.remove_fluid({ name = source_fluid.name, amount = inserted_amount })
        end
    end
end

local function exclude_surface(surface)
    for _, force in pairs(game.forces) do
        force.set_surface_hidden(surface, true)
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
        function (player)
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
    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end
    local icw = ICW.get()
    local wagon = icw.wagons[locomotive.unit_number]
    if not wagon then
        return
    end

    local surface = wagon.surface
    local speed = icw.speed
    local final_battle = icw.final_battle

    local hazardous_debris = icw.hazardous_debris
    if not hazardous_debris then
        return
    end

    local create = surface.create_entity

    if final_battle then
        for _ = 1, 16 * speed, 1 do
            local position = deep_copy(fallout_debris[random(1, size_of_debris)])
            position[1] = position[1] + wagon.chunk_position.x
            local p = { x = position[1], y = position[2] }
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == out_of_map_tile then
                create({ name = 'slowdown-capsule', position = position, force = 'neutral', target = { position[1], position[2] + fallout_width * 2 }, speed = speed })
            end
        end

        for _ = 1, 6 * speed, 1 do
            local position = deep_copy(fallout_debris[random(1, size_of_debris)])
            position[1] = position[1] + wagon.chunk_position.x
            local p = { x = position[1], y = position[2] }
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == out_of_map_tile then
                create({ name = 'slowdown-capsule', position = position, force = 'neutral', target = { position[1], position[2] + fallout_width * 2 }, speed = speed })
            end
        end

        for _ = 1, 4 * speed, 1 do
            local position = deep_copy(fallout_debris[random(1, size_of_debris)])
            position[1] = position[1] + wagon.chunk_position.x
            local p = { x = position[1], y = position[2] }
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == out_of_map_tile then
                create(
                    {
                        name = 'atomic-bomb-wave-spawns-nuke-shockwave-explosion',
                        position = position,
                        force = 'neutral',
                        target = { position[1], position[2] + fallout_width * 2 },
                        speed = speed
                    }
                )
            end
        end

        for _ = 1, 6 * speed, 1 do
            local position = deep_copy(fallout_debris[random(1, size_of_debris)])
            position[1] = position[1] + wagon.chunk_position.x
            local p = { x = position[1], y = position[2] }
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == out_of_map_tile then
                create(
                    {
                        name = 'slowdown-capsule',
                        position = position,
                        force = 'neutral',
                        target = { position[1], position[2] + fallout_width * 2 },
                        speed = speed
                    }
                )
            end
        end
    else
        for _ = 1, 16 * speed, 1 do
            local position = deep_copy(fallout_debris[random(1, size_of_debris)])
            position[1] = position[1] + wagon.chunk_position.x
            local p = { x = position[1], y = position[2] }
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == out_of_map_tile then
                create({ name = 'shotgun-pellet', position = position, force = 'neutral', target = { position[1], position[2] + fallout_width * 2 }, speed = speed })
            end
        end

        for _ = 1, 6 * speed, 1 do
            local position = deep_copy(fallout_debris[random(1, size_of_debris)])
            position[1] = position[1] + wagon.chunk_position.x
            local p = { x = position[1], y = position[2] }
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == out_of_map_tile then
                create({ name = 'cannon-projectile', position = position, force = 'neutral', target = { position[1], position[2] + fallout_width * 2 }, speed = speed })
            end
        end

        for _ = 1, 4 * speed, 1 do
            local position = deep_copy(fallout_debris[random(1, size_of_debris)])
            position[1] = position[1] + wagon.chunk_position.x
            local p = { x = position[1], y = position[2] }
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == out_of_map_tile then
                create(
                    {
                        name = 'atomic-bomb-wave-spawns-nuke-shockwave-explosion',
                        position = position,
                        force = 'neutral',
                        target = { position[1], position[2] + fallout_width * 2 },
                        speed = speed
                    }
                )
            end
        end

        for _ = 1, 6 * speed, 1 do
            local position = deep_copy(fallout_debris[random(1, size_of_debris)])
            position[1] = position[1] + wagon.chunk_position.x
            local p = { x = position[1], y = position[2] }
            local get_tile = surface.get_tile(p)
            if get_tile.valid and get_tile.name == out_of_map_tile then
                create(
                    {
                        name = 'uranium-cannon-projectile',
                        position = position,
                        force = 'neutral',
                        target = { position[1], position[2] + fallout_width * 2 },
                        speed = speed
                    }
                )
            end
        end
    end
end

local transfer_functions =
{
    ['storage-tank'] = divide_fluid
}

local function position_in_wagon_area(position, wagon)
    local area = wagon and wagon.area
    if not area then
        return false
    end
    local left_top = area.left_top
    local right_bottom = area.right_bottom
    return position.x >= left_top.x and position.y >= left_top.y and position.x <= right_bottom.x and position.y <= right_bottom.y
end

local function get_wagon_for_entity(icw, entity)
    if not validate_entity(entity) then
        return
    end

    local position = entity.position
    for _, wagon in pairs(icw.wagons) do
        if wagon and position_in_wagon_area(position, wagon) then
            return wagon
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
            local surface = e.surface
            local position = e.position
            local unit_number = e.unit_number
            local get_tile = surface.get_tile(position)
            if get_tile.valid then
                surface.set_tiles({ { name = out_of_map_tile, position = position } }, true)
            end
            icw.doors[unit_number] = nil
            e.destroy()
            wagon.doors[k] = nil
        end
    end
end

local function construct_wagon_doors(icw, wagon)
    local area = wagon.area
    local surface = wagon.surface
    local main_tile_name = get_tile_name()

    for _, x in pairs({ area.left_top.x - 1.5, area.right_bottom.x + 1.5 }) do
        local p = { x = x, y = area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5) }
        if (p.x - area.left_top.x) < 0 then
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x + 1, y = p.y } } }, true)
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x + 1, y = p.y - 1 } } }, true)
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x, y = p.y - 1 } } }, true)
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x, y = p.y } } }, true)
        else
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x - 1, y = p.y - 1 } } }, true)
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x - 1, y = p.y } } }, true)
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x, y = p.y - 1 } } }, true)
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x, y = p.y } } }, true)
        end
        local e
        if (x - area.left_top.x) < 0 then
            e =
                surface.create_entity(
                    {
                        name = 'warp',
                        position = { x - 0.5, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5) },
                        force = 'neutral',
                        create_build_effect_smoke = false,
                        direction = defines.direction.west
                    }
                )
        else
            e =
                surface.create_entity(
                    {
                        name = 'warp',
                        position = { x, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5) },
                        force = 'neutral',
                        create_build_effect_smoke = false,
                        direction = defines.direction.east
                    }
                )
        end
        e.destructible = false
        e.minable_flag = false
        e.operable = false
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

    icw.players[player.index] =
    {
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
        if player.physical_surface ~= surface then
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

    if wagon.light and wagon.light.valid then
        wagon.light.destroy()
    end

    clear_saved_carriages(icw, entity.unit_number)

    local surface = wagon.surface
    kick_players_from_surface(wagon)
    -- kick_players_out_of_vehicles(wagon)
    kill_wagon_doors(icw, wagon)
    for _, tile in pairs(surface.find_tiles_filtered({ area = wagon.area })) do
        surface.set_tiles({ { name = out_of_map_tile, position = tile.position } }, true)
    end
    for _, x in pairs({ wagon.area.left_top.x - 1.5, wagon.area.right_bottom.x + 1.5 }) do
        local p = { x = x, y = wagon.area.left_top.y + ((wagon.area.right_bottom.y - wagon.area.left_top.y) * 0.5) }
        surface.set_tiles({ { name = out_of_map_tile, position = { x = p.x + 0.5, y = p.y } } }, true)
        surface.set_tiles({ { name = out_of_map_tile, position = { x = p.x - 1, y = p.y } } }, true)
    end
    local chart_area = deep_copy(wagon.area)
    chart_area.left_top.x = chart_area.left_top.x - 5
    chart_area.right_bottom.x = chart_area.right_bottom.x + 5
    game.forces.player.chart(surface, chart_area)
    icw.wagons[entity.unit_number] = nil
    Public.request_reconstruction()
end

function Public.create_room_surface(icw, unit_number)
    local current_planet = WPT.get_planet()
    if game.surfaces[current_planet] and icw.default_surface then
        return game.surfaces[current_planet]
    end

    if game.surfaces[tostring(unit_number)] then
        return game.surfaces[tostring(unit_number)]
    end
    local map_gen_settings =
    {
        ['width'] = 2,
        ['height'] = 2,
        ['water'] = 0,
        ['starting_area'] = 1,
        ['cliff_settings'] = { cliff_elevation_interval = 0, cliff_elevation_0 = 0 },
        ['default_enable_all_autoplace_controls'] = true,
        ['autoplace_settings'] =
        {
            ['entity'] = { treat_missing_as_default = false },
            ['tile'] = { treat_missing_as_default = true },
            ['decorative'] = { treat_missing_as_default = false }
        }
    }
    local surface = game.create_surface(tostring(unit_number), map_gen_settings)
    surface.no_enemies_mode = true
    surface.freeze_daytime = true
    surface.daytime = 0.1
    surface.request_to_generate_chunks({ 16, 16 }, 1)
    surface.force_generate_chunk_requests()

    if ServerCommands.is_dev_server() then
        surface.ignore_surface_conditions = true
    end

    exclude_surface(surface)
    for _, tile in pairs(surface.find_tiles_filtered({ area = { { -2, -2 }, { 2, 2 } } })) do
        surface.set_tiles({ { name = out_of_map_tile, position = tile.position } }, true)
    end
    icw.surfaces[#icw.surfaces + 1] = surface
    return surface
end

function Public.set_wagon_tiles(wagon)
    local area = wagon.area
    local main_tile_name = get_tile_name()

    local tiles = {}
    for x = wagon.chunk_position.x - 3, wagon.chunk_position.x + 2, 1 do
        tiles[#tiles + 1] = { name = 'hazard-concrete-right', position = { x, area.left_top.y } }
        tiles[#tiles + 1] = { name = 'hazard-concrete-right', position = { x, area.right_bottom.y - 1 } }
    end
    for x = area.left_top.x, area.right_bottom.x - 1, 1 do
        for y = area.left_top.y + 2, area.right_bottom.y - 3, 1 do
            tiles[#tiles + 1] = { name = main_tile_name, position = { x, y } }
        end
    end
    for x = wagon.chunk_position.x - 3, wagon.chunk_position.x + 2, 1 do
        for y = 1, 3, 1 do
            tiles[#tiles + 1] = { name = main_tile_name, position = { x, y } }
        end
        for y = area.right_bottom.y - 4, area.right_bottom.y - 2, 1 do
            tiles[#tiles + 1] = { name = main_tile_name, position = { x, y } }
        end
    end

    local fishes = {}

    local water_tile = 'water'

    if wagon.entity.type == 'locomotive' then
        for x = wagon.chunk_position.x - 6, wagon.chunk_position.x + 5, 1 do
            for y = 10, 12, 1 do
                tiles[#tiles + 1] = { name = water_tile, position = { x, y } }
                fishes[#fishes + 1] = { name = 'fish', position = { x, y } }
            end
        end
    end

    wagon.surface.set_tiles(tiles, true)
end

function Public.create_wagon_room(icw, wagon)
    local surface = wagon.surface
    local area = wagon.area
    local main_tile_name = get_tile_name()

    local tiles = {}
    for x = wagon.chunk_position.x - 3, wagon.chunk_position.x + 2, 1 do
        tiles[#tiles + 1] = { name = 'hazard-concrete-right', position = { x, area.left_top.y } }
        tiles[#tiles + 1] = { name = 'hazard-concrete-right', position = { x, area.right_bottom.y - 1 } }
    end
    for x = area.left_top.x, area.right_bottom.x - 1, 1 do
        for y = area.left_top.y + 2, area.right_bottom.y - 3, 1 do
            tiles[#tiles + 1] = { name = main_tile_name, position = { x, y } }
        end
    end
    for x = wagon.chunk_position.x - 3, wagon.chunk_position.x + 2, 1 do
        for y = 1, 3, 1 do
            tiles[#tiles + 1] = { name = main_tile_name, position = { x, y } }
        end
        for y = area.right_bottom.y - 4, area.right_bottom.y - 2, 1 do
            tiles[#tiles + 1] = { name = main_tile_name, position = { x, y } }
        end
    end

    local fishes = {}

    local water_tile = 'water'

    if wagon.entity.type == 'locomotive' then
        for x = wagon.chunk_position.x - 6, wagon.chunk_position.x + 5, 1 do
            for y = 10, 12, 1 do
                tiles[#tiles + 1] = { name = water_tile, position = { x, y } }
                fishes[#fishes + 1] = { name = 'fish', position = { x, y } }
            end
        end
    end

    surface.set_tiles(tiles, true)

    for _, fish in pairs(fishes) do
        surface.create_entity(fish)
    end

    construct_wagon_doors(icw, wagon)
    if not icw.default_surface then
        local mgs = surface.map_gen_settings
        mgs.width = area.right_bottom.x * 2
        mgs.height = area.right_bottom.y * 2
        surface.map_gen_settings = mgs
    end

    if wagon.entity.type == 'fluid-wagon' then
        local height = area.right_bottom.y - area.left_top.y
        local positions =
        {
            { area.right_bottom.x, area.left_top.y + height * 0.25 },
            { area.right_bottom.x, area.left_top.y + height * 0.75 },
            { area.left_top.x - 1, area.left_top.y + height * 0.25 },
            { area.left_top.x - 1, area.left_top.y + height * 0.75 }
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
        e.minable_flag = false
        wagon.transfer_entities = { e }
        return
    end

    local center_position =
    {
        x = wagon.area.left_top.x + (wagon.area.right_bottom.x - wagon.area.left_top.x) * 0.5,
        y = wagon.area.left_top.y + (wagon.area.right_bottom.y - wagon.area.left_top.y) * 0.5
    }

    wagon.light =
        rendering.draw_light(
            {
                sprite = 'utility/light_medium',
                scale = 55.5,
                intensity = 1,
                minimum_darkness = 0,
                oriented = true,
                color = { 255, 255, 255 },
                target = center_position,
                surface = surface,
                visible = true,
                only_in_alt_mode = false
            }
        )

    if wagon.entity.type == 'cargo-wagon' then
        local task = Task.get(add_chests_to_wagon_token)
        task({ wagon = wagon, surface = surface })
    end
end

function Public.create_wagon(icw, created_entity, quality_areas)
    if not validate_entity(created_entity) then
        return
    end

    if not icw.wagon_types[created_entity.type] then
        return
    end

    local wagon_types = ICW.get('wagon_types')
    local wagon_areas = ICW.get('wagon_areas')

    if quality_areas then
        wagon_areas = quality_areas
    end

    local position = get_offset(icw, created_entity.surface, icw.offsets)

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

    icw.wagons[created_entity.unit_number] =
    {
        entity = created_entity,
        chunk_position = position,
        offset = icw.offsets,
        unit_number = created_entity.unit_number,
        unit_type = created_entity.type,
        area =
        {
            left_top = { x = wagon_area.left_top.x + position.x, y = wagon_area.left_top.y },
            right_bottom = { x = wagon_area.right_bottom.x + position.x, y = wagon_area.right_bottom.y }
        },
        doors = {}
    }
    local wagon = icw.wagons[created_entity.unit_number]
    icw.offsets = icw.offsets + icw.offset_increment

    wagon.surface = Public.create_room_surface(icw, created_entity.unit_number)
    Public.create_wagon_room(icw, icw.wagons[created_entity.unit_number])

    Public.request_reconstruction()
    return wagon
end

function Public.migrate_wagon(icw, source, target)
    if not validate_entity(target) then
        return
    end

    target.minable_flag = false

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
            icw.wagons[target_wagon] = deep_copy(unit_data)
        end
    end

    Task.set_timeout_in_ticks(100, remove_non_migrated_doors_token, { icw = icw })
end

function Public.use_cargo_wagon_door_with_entity(icw, player, door)
    local player_data = get_player_data(icw, player)

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

    if player and player.valid and player.character == nil then
        return
    end

    player_data.fallback_surface = wagon.entity.surface.index
    player_data.fallback_position = { wagon.entity.position.x, wagon.entity.position.y }

    Event.raise(ICW.events.on_player_used_door, { player_index = player.index, surface_index = player.physical_surface.index })

    if player.driving and door.type == 'locomotive' then
        player_data.pos = player.physical_position.x
        return
    end

    if icw.default_surface then
        if player.physical_position.x < 800 then
            local surface = wagon.surface
            if not (surface and surface.valid) then
                return
            end

            local area = wagon.area

            local pos = player_data and player_data.pos or player.physical_position.x

            local x_vector = door.position.x - pos
            local position
            if x_vector > 0 then
                position = { area.left_top.x + 0.5, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5) }
            else
                position = { area.right_bottom.x - 0.5, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5) }
            end
            local p = surface.find_non_colliding_position('character', position, 128, 0.5)
            player.character.driving = false
            if p then
                player.teleport(p)
            else
                player.teleport(position)
            end
            player_data.surface = surface.index
            player_data.pos = nil
        else
            local surface = wagon.entity.surface
            if not (surface and surface.valid) then
                return
            end

            local door_position = door.position.x - wagon.chunk_position.x
            local teleport_position = door_position < 0 and -2 or 2

            local position = { wagon.entity.position.x + teleport_position, wagon.entity.position.y }
            local surface_position = surface.find_non_colliding_position('character', position, 128, 0.5)
            if not position then
                return
            end
            if not surface_position then
                surface.request_to_generate_chunks({ -20, 22 }, 1)
                if player.character and player.character.valid and player.character.driving then
                    if wagon.surface == player.physical_surface then
                        player.character.driving = false
                    end
                end
                return
            end
            player.character.driving = false
            player.teleport(surface_position, surface)
            Public.kill_minimap(player)
            player_data.surface = surface.index
        end
    else
        if wagon.entity.surface.name ~= player.physical_surface.name then
            local surface = wagon.entity.surface
            if not (surface and surface.valid) then
                return
            end
            local x_vector = (door.position.x / math.abs(door.position.x)) * 2
            local position = { wagon.entity.position.x + x_vector, wagon.entity.position.y }
            local surface_position = surface.find_non_colliding_position('character', position, 128, 0.5)
            if not position then
                return
            end
            if not surface_position then
                surface.request_to_generate_chunks({ -20, 22 }, 1)
                if player.character and player.character.valid and player.character.driving then
                    if wagon.surface == player.physical_surface then
                        player.character.driving = false
                    end
                end
                return
            end
            if wagon.entity.type == 'locomotive' then
                player.teleport(surface_position, surface)
                player_data.state = 2
                player.driving = false
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
            local x_vector = door.position.x - player.physical_position.x
            local position
            if x_vector > 0 then
                position = { area.left_top.x + 0.5, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5) }
            else
                position = { area.right_bottom.x - 0.5, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5) }
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

move_room_to_train = function (icw, train, wagon, carriages)
    if not wagon then
        return
    end

    if not train.surface or not train.surface.valid then
        error('Train surface is invalid, please check this out!')
        return
    end

    train.wagons[#train.wagons + 1] = wagon.entity.unit_number

    local ltx = carriages and carriages.new_area and carriages.new_area.left_top.x or wagon.area.left_top.x
    local rbx = carriages and carriages.new_area and carriages.new_area.right_bottom.x or wagon.area.right_bottom.x

    local destination_area =
    {
        left_top = { x = ltx, y = train.top_y },
        right_bottom =
        {
            x = rbx,
            y = train.top_y + (wagon.area.right_bottom.y - wagon.area.left_top.y)
        }
    }

    train.top_y = destination_area.right_bottom.y

    if carriages and (carriages.top_y == nil or carriages.top_y < train.top_y) then
        carriages.top_y = train.top_y
    end

    if not wagon.surface or not wagon.surface.valid then
        return
    end

    if destination_area.left_top.x == wagon.area.left_top.x and destination_area.left_top.y == wagon.area.left_top.y and wagon.surface.name == train.surface.name then
        return
    end

    local old_area = deep_copy(wagon.area)
    local old_surface = wagon.surface

    kick_players_from_surface(wagon)
    -- kick_players_out_of_vehicles(wagon)
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
            expand_map = false
        }
    )

    if icw.default_surface then
        local entities = train.surface.find_entities_filtered { area = wagon.area, name = { 'logistic-robot', 'construction-robot' } }
        for _, entity in pairs(entities) do
            entity.destroy()
        end
    end

    for player_index, position in pairs(player_positions) do
        local player = game.players[player_index]
        player.teleport(position, train.surface)
    end

    wagon.surface = train.surface
    wagon.area = destination_area
    wagon.transfer_entities = {}

    if old_surface and old_surface.valid and old_area then
        local clear_area = deep_copy(old_area)
        clear_area.left_top.x = clear_area.left_top.x - 10.5
        clear_area.right_bottom.x = clear_area.right_bottom.x + 10.5
        for _, tile in pairs(old_surface.find_tiles_filtered({ area = clear_area })) do
            old_surface.set_tiles({ { name = out_of_map_tile, position = tile.position } }, true)
        end
        game.forces.player.chart(old_surface, clear_area)
    end

    if icw.default_surface then
        wagon.entity.force.chart(wagon.surface, destination_area)
    else
        wagon.entity.force.chart(wagon.surface, wagon.area)
    end

    construct_wagon_doors(icw, wagon)

    local left_top_y = wagon.area.left_top.y
    for _, e in pairs(wagon.surface.find_entities_filtered({ type = 'electric-pole', area = wagon.area })) do
        connect_power_pole(e, left_top_y)
    end

    for _, e in pairs(wagon.surface.find_entities_filtered({ area = wagon.area, force = 'neutral' })) do
        if transfer_functions[e.name] then
            wagon.transfer_entities[#wagon.transfer_entities + 1] = e
        end
    end

    if icw.default_surface then
        if wagon.light and wagon.light.valid then
            wagon.light.destroy()
        end

        local center_position =
        {
            x = wagon.area.left_top.x + (wagon.area.right_bottom.x - wagon.area.left_top.x) * 0.5,
            y = wagon.area.left_top.y + (wagon.area.right_bottom.y - wagon.area.left_top.y) * 0.5
        }

        wagon.light =
            rendering.draw_light(
                {
                    sprite = 'utility/light_medium',
                    scale = 55.5,
                    intensity = 1,
                    minimum_darkness = 0,
                    oriented = true,
                    color = { 255, 255, 255 },
                    target = center_position,
                    surface = wagon.surface,
                    visible = true,
                    only_in_alt_mode = false
                }
            )
    end
end

function Public.construct_train(icw, carriages)
    local old_carriages = carriages
    local unit_number = carriages[1].unit_number

    if icw.trains[unit_number] then
        return
    end

    local train = { surface = Public.create_room_surface(icw, unit_number), wagons = {}, top_y = 0 }
    icw.trains[unit_number] = train

    if not icw.train_locomotives then
        icw.train_locomotives = {}
    end

    if not icw.train_locomotives[unit_number] then
        for _, carriage in ipairs(carriages) do
            if carriage and carriage.valid and carriage.type == 'locomotive' then
                icw.train_locomotives[unit_number] = carriage.unit_number
                break
            end
        end
    end

    local saved_carriages

    local wagon = icw.wagons[unit_number]
    if wagon and wagon.new_chunk_position then
        saved_carriages = get_saved_carriages(icw, old_carriages)
        wagon.chunk_position = wagon.new_chunk_position
        wagon.new_chunk_position = nil
        if not icw.default_surface then
            move_room_to_train(icw, train, wagon, saved_carriages)
        end
    end

    local timeout = 5
    for _, carriage in ipairs(carriages) do
        Task.set_timeout_in_ticks(timeout, construct_train_token, { icw = icw, carriage = carriage, train = train, chunk_position = wagon.chunk_position, saved_carriages = saved_carriages })
        timeout = timeout + 5
    end
end

function Public.clear_old_area(wagon)
    local area = wagon.area
    if not area then
        return
    end

    local old_area = deep_copy(area)
    old_area.left_top.x = old_area.left_top.x - 10.5
    old_area.right_bottom.x = old_area.right_bottom.x + 10.5

    for _, tile in pairs(wagon.surface.find_tiles_filtered({ area = old_area })) do
        wagon.surface.set_tiles({ { name = out_of_map_tile, position = tile.position } }, true)
    end
    game.forces.player.chart(wagon.surface, old_area)
end

function Public.reconstruct_all_trains(reset_carriages)
    local final_battle = WPT.get('final_battle')
    if final_battle then
        return false
    end

    local icw = ICW.get()
    local areas = icw.wagon_areas

    if reset_carriages then
        icw.carriages = {}
    end

    icw.trains = {}
    for unit_number, wagon in pairs(icw.wagons) do
        if not validate_entity(wagon.entity) then
            icw.wagons[unit_number] = nil
            return false
        end

        local carriages = wagon.entity.train.carriages
        local locomotive = WPT.get('locomotive')

        if (locomotive and locomotive.valid) then
            local should_reverse = false
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
                        should_reverse = true
                    end
                    break
                end
            end

            if should_reverse then
                local n = 1
                local m = #carriages
                while (n < m) do
                    carriages[n], carriages[m] = carriages[m], carriages[n]
                    n = n + 1
                    m = m - 1
                end
            end
        elseif #carriages > 1 then
            local oldest_locomotive = nil
            local lowest_unit_number = nil

            for _, carriage in pairs(carriages) do
                if carriage and carriage.valid and carriage.type == 'locomotive' then
                    if not lowest_unit_number or carriage.unit_number < lowest_unit_number then
                        oldest_locomotive = carriage
                        lowest_unit_number = carriage.unit_number
                    end
                end
            end

            if oldest_locomotive then
                local loco_index = nil
                for i, carriage in ipairs(carriages) do
                    if carriage.unit_number == oldest_locomotive.unit_number then
                        loco_index = i
                        break
                    end
                end

                if loco_index then
                    local connected_wagon = nil

                    if loco_index > 1 then
                        connected_wagon = carriages[loco_index - 1]
                    elseif loco_index < #carriages then
                        connected_wagon = carriages[loco_index + 1]
                    end

                    local should_reverse = false
                    if connected_wagon and connected_wagon.valid and oldest_locomotive.valid then
                        if oldest_locomotive.position.y > connected_wagon.position.y then
                            if loco_index == 1 then
                                should_reverse = true
                            end
                        else
                            if loco_index > 1 then
                                should_reverse = true
                            end
                        end
                    end

                    if should_reverse then
                        local reversed = {}
                        for i = #carriages, 1, -1 do
                            reversed[#reversed + 1] = carriages[i]
                        end
                        carriages = reversed
                    end
                end
            end
        end

        local to_construct_ids = {}

        if #carriages > 1 then
            if icw.default_surface then
                local new_wagon = icw.wagons[carriages[1].unit_number]
                if not new_wagon then
                    error('Wagon not found while creating wagon snake: ' .. carriages[1].unit_number)
                    break
                end
                local not_carriage, carriage_index = carriages_not_saved(icw, carriages)
                if not_carriage then
                    local entity_area = areas[new_wagon.entity.type]
                    if not entity_area then
                        goto continue
                    end

                    local cr = {}
                    local c = 1
                    for _, carriage in pairs(carriages) do
                        cr[c] = { unit_number = carriage.unit_number }
                        c = c + 1
                    end

                    local new_position = get_offset(icw, new_wagon.surface, icw.offsets)

                    local destination_area =
                    {
                        left_top = { x = entity_area.left_top.x + new_position.x, y = new_wagon.area.left_top.y },
                        right_bottom = { x = entity_area.right_bottom.x + new_position.x, y = new_wagon.area.right_bottom.y }
                    }

                    if carriage_index then
                        icw.carriages[carriage_index] = { id = carriages[1].unit_number, carriages = cr, new_area = destination_area, position = new_position }
                    else
                        icw.carriages[#icw.carriages + 1] = { id = carriages[1].unit_number, carriages = cr, new_area = destination_area, position = new_position }
                    end

                    new_wagon.new_chunk_position = new_position
                    icw.offsets = icw.offsets + icw.offset_increment
                    to_construct_ids[carriages[1].unit_number] = true
                    ::continue::
                end
            end

            if not wagon.surface then
                wagon.surface = Public.create_room_surface(icw, unit_number)
                Public.create_wagon_room(icw, wagon)
            end

            for _, carriage in pairs(carriages) do
                if not icw.wagons[carriage.unit_number] then
                    Public.create_wagon(icw, carriage)
                end
            end

            if next(to_construct_ids) or not icw.default_surface then
                Public.construct_train(icw, carriages)
            end
        end
    end
    Task.set_timeout_in_ticks(25, clear_old_surfaces_token)
    return true
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
        frame = player.gui.left.add({ type = 'frame', direction = 'vertical', name = 'icw_main_frame', caption = 'Minimap' })
    end
    local element = frame['icw_sub_frame']
    -- if not frame.icw_auto_switch then
    --     frame.add({ type = 'switch', name = 'icw_auto_switch', allow_none_state = false, left_label_caption = { 'gui.map_on' }, right_label_caption = { 'gui.map_off' } })
    -- end
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
    if player.controller_type == defines.controllers.remote then
        return
    end

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
    local starting_planet = WPT.get_planet()
    if string.sub(surface.name, 0, #starting_planet) == starting_planet then
        return
    end

    local tiles = event.tiles
    if not tiles then
        return
    end

    for _, v in pairs(tiles) do
        local old_tile = v.old_tile
        if old_tile.name == 'water' then
            surface.set_tiles({ { name = 'water', position = v.position } }, true)
        end
    end
end

function Public.on_entity_cloned(source, destination)
    LinkedChests.migrate(source, destination)
end

Public.get_player_data = get_player_data

return Public
