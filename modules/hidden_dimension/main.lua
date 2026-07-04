local Event = require 'utils.event'
local HDT = require 'modules.hidden_dimension.table'
local SessionData = require 'utils.datastore.session_data'

local Public = {}

local deepcopy = table.deepcopy
local transport_table = HDT.transport_table
local levels_table = HDT.levels_table
local math_max = math.max
local table_insert = table.insert

local level_1_size = 64
local level_2_size = 128
local level_3_size = 160

local teleporter_type = 'steel-furnace'

local function get_table(t)
    local key
    local value
    for k, v in pairs(t) do
        key = k
        value = v
    end
    return key, value
end

local function exists(name)
    local hidden_dimension = HDT.get('hidden_dimension')
    if not hidden_dimension then
        return false
    end
    local multiplayer_enabled = HDT.get('multiplayer_enabled')
    if not multiplayer_enabled then
        return false
    end

    if not hidden_dimension.players[name] then
        return false
    end

    return true
end

local function get_or_set_player(player, position)
    local hidden_dimension = HDT.get('hidden_dimension')
    if not hidden_dimension then
        return
    end

    local multiplayer_enabled = HDT.get('multiplayer_enabled')
    if not multiplayer_enabled then
        return hidden_dimension
    end
    if not hidden_dimension.players[player.name] then
        hidden_dimension.players[player.name] =
        {
            logistic_research_level = 0,
            energy = {},
            energy_connected = {},
            surface = nil,
            size = nil,
            going_up = deepcopy(transport_table),
            going_down = deepcopy(transport_table),
            upgrade_level = 0,
            name = player.name,
            index = player.index,
            level_1 = deepcopy(levels_table),
            level_2 = deepcopy(levels_table),
            main_surface = deepcopy(transport_table),
            hd_surface = player.surface.name,
            position = position or nil,
            reset_counter = 1
        }

        if SessionData.allowed(player, 'instant_hd_unlock') then
            hidden_dimension.players[player.name].instant_unlocked_available = true
        end
    end

    return hidden_dimension.players[player.name]
end

local function get_player_by_force(force, callback)
    local hidden_dimension = HDT.get('hidden_dimension')
    if not hidden_dimension then
        return
    end
    local multiplayer_enabled = HDT.get('multiplayer_enabled')
    if not multiplayer_enabled then
        return hidden_dimension
    end

    local players = force.players
    for i = 1, #players do
        local player = players[i]
        if exists(player.name) then
            local tbl = get_or_set_player(player)
            callback(tbl, player)
        end
    end
end

local function player_callback(callback)
    local hidden_dimension = HDT.get('hidden_dimension')
    if not hidden_dimension then
        return
    end
    local multiplayer_enabled = HDT.get('multiplayer_enabled')
    if not multiplayer_enabled then
        return callback(nil, hidden_dimension)
    end
    local players = hidden_dimension.players
    for name, hd in pairs(players) do
        callback(name, hd)
    end
end

--- Resets the table to default
local function reset_player(player)
    local hidden_dimension = HDT.get('hidden_dimension')
    if not hidden_dimension then
        return
    end
    local multiplayer_enabled = HDT.get('multiplayer_enabled')
    if not multiplayer_enabled then
        return hidden_dimension
    end

    if hidden_dimension.players[player.name] then
        local tbl = get_or_set_player(player)
        if not tbl then
            return
        end
        if tbl.main_surface.reference_text then
            tbl.main_surface.reference_text.destroy()
        end

        if next(tbl.main_surface.entities) then
            for _, ent in pairs(tbl.main_surface.entities) do
                if ent and ent.valid then
                    ent.destroy()
                end
            end
        end
        if next(tbl.energy) then
            for _, ent in pairs(tbl.energy) do
                if ent and ent.valid then
                    ent.destroy()
                end
            end
        end
        if tbl.main_surface.reference and tbl.main_surface.reference.valid then
            local main_surf = tbl.main_surface.reference.surface
            local position = main_surf.find_non_colliding_position('character', { 0, 0 }, 32, 0.5)
            player.teleport(position, main_surf)
            tbl.main_surface.reference.destroy()
        end

        game.delete_surface(player.name .. '_level_1_' .. tostring(tbl.reset_counter))
        game.delete_surface(player.name .. '_level_2_' .. tostring(tbl.reset_counter))
        hidden_dimension.players[player.name] = nil
    end
end

local function unstuck_player(index, surface, ent_pos)
    if not ent_pos then
        return
    end
    local player = game.get_player(index)
    local position = surface.find_non_colliding_position('character', ent_pos, 32, 0.5)
    if not position then
        return
    end
    player.teleport(position, surface)
end

local function teleport(entity, pos, surface)
    local sane_pos = surface.find_non_colliding_position(entity.name, pos, 0, 1)
    if entity.type == 'character' then
        for _, v in pairs(game.players) do
            if v.character == entity then
                v.teleport(sane_pos, surface)
            end
        end
    end
end

local function add_container(name, pos, direction, type, logistic_building)
    local container_entity
    container_entity = logistic_building.surface.find_entity(name,
        { logistic_building.position.x + pos.x, logistic_building.position.y + pos.y })
    if container_entity == nil then
        local pos2 = { logistic_building.position.x + pos.x, logistic_building.position.y + pos.y }
        if name == 'loader' or name == 'fast-loader' or name == 'express-loader' then
            container_entity =
                logistic_building.surface.create_entity
                {
                    name = name,
                    position = pos2,
                    force = game.forces.player,
                    type = type
                }
            container_entity.direction = direction
        elseif name == 'pipe-to-ground' then
            container_entity = logistic_building.surface.create_entity { name = name, position = pos2, force = game.forces.player }
            container_entity.direction = direction
        elseif name == 'substation' then
            container_entity = logistic_building.surface.create_entity { name = name, position = pos2, force = game.forces.player }
            container_entity.minable_flag = false
            container_entity.destructible = false
            container_entity.operable = false
        else
            container_entity = logistic_building.surface.create_entity { name = name, position = pos2, force = game.forces.player }
        end
    end
    container_entity.minable_flag = false
    container_entity.destructible = false
    return container_entity
end

local function clear_surroundings(index, surface, pos)
    local area = { { pos.x - 5, pos.y - 5 }, { pos.x + 5, pos.y + 5 } }
    local entity = surface.find_entities(area)
    local position = entity.position
    for i, _ in ipairs(entity) do
        if entity[i].type == 'character' then
            unstuck_player(index, surface, position)
        else
            entity[i].destroy()
        end
    end
end

local function connect_neighbour(hidden_dimension)
    local energy = hidden_dimension.energy
    hidden_dimension.energy_connected = hidden_dimension.energy_connected or {}
    local energy_connected = hidden_dimension.energy_connected
    for _, data in pairs(energy) do
        if data and data.entity and data.entity.valid then
            for i = 2, #energy do
                local next = energy[i]
                if next and next.entity and next.entity.valid and data.entity.type == 'electric-pole' then
                    local wire = data.entity.get_wire_connector(5)
                    local next_wire = next.entity.get_wire_connector(5)
                    if wire and next_wire then
                        wire.connect_to(next_wire, false, defines.wire_origin.script)
                    end
                    energy_connected[data.entity.unit_number] = next.entity.unit_number
                end
            end
        end
    end
end

local function disconnect_neighbour(hidden_dimension)
    local energy = hidden_dimension.energy
    hidden_dimension.energy_connected = hidden_dimension.energy_connected or {}
    local energy_connected = hidden_dimension.energy_connected

    for _, data in pairs(energy) do
        if data and data.entity and data.entity.valid then
            for i = 2, #energy do
                local next = energy[i]
                if next and next.entity and next.entity.valid and data.entity.type == 'electric-pole' then
                    local wire = data.entity.get_wire_connector(5)
                    local next_wire = next.entity.get_wire_connector(5)
                    if wire and next_wire then
                        wire.disconnect_from(next_wire, defines.wire_origin.script)
                    end
                    if energy_connected[data.entity.unit_number] == next.entity.unit_number then
                        energy_connected[data.entity.unit_number] = nil
                    end
                end
            end
        end
    end
end

local function conf_changed(hidden_dimension)
    if hidden_dimension.energy_changed then
        return
    end
    local energy = hidden_dimension.energy
    for id, data in pairs(energy) do
        if data and data.valid and data.name == 'electric-energy-interface' then
            energy[id] = { reference = data.surface.index, entity = data }
        end
    end

    for id, data in pairs(energy) do
        if data and data.entity and data.entity.valid and data.entity.name == 'electric-energy-interface' then
            local entity = data.entity
            local position = entity.position
            local furnace =
                data.entity.surface.find_entities_filtered
                {
                    position = position,
                    name = teleporter_type
                }
            if furnace and furnace[1] then
                entity.destroy()
                energy[id] =
                {
                    reference = furnace,
                    entity = add_container('substation', { x = 0, y = 0 }, nil, nil,
                        furnace[1])
                }
            end
        end
    end

    disconnect_neighbour(hidden_dimension)
    connect_neighbour(hidden_dimension)
    hidden_dimension.energy_changed = true
end

local function create_chests(hidden_dimension, surface, level, build_type)
    surface.transport_type = build_type
    local direction1
    local direction2
    local rotation1
    local rotation2
    if build_type == 'in_and_out' then
        direction1 = defines.direction.south
        direction2 = defines.direction.north
        rotation1 = 'input'
        rotation2 = 'output'
    elseif build_type == 'out_and_in' then
        direction1 = defines.direction.north
        direction2 = defines.direction.south
        rotation1 = 'output'
        rotation2 = 'input'
    elseif build_type == 'in_and_in' then
        direction1 = defines.direction.south
        direction2 = defines.direction.south
        rotation1 = 'input'
        rotation2 = 'input'
    else
        direction1 = defines.direction.north
        direction2 = defines.direction.north
        rotation1 = 'output'
        rotation2 = 'output'
    end
    local logistic_building = surface.reference
    local energy = 'substation'
    local loader
    local chest = 'blue-chest'
    if level == 1 then
        loader = 'loader'
    elseif level == 2 then
        loader = 'fast-loader'
    elseif level == 4 then
        loader = 'express-loader'
    end

    surface.entities.loader_1 = add_container(loader, { x = -2, y = 0 }, direction1, rotation1, logistic_building)
    surface.entities.loader_2 = add_container(loader, { x = 1, y = 0 }, direction2, rotation2, logistic_building)
    surface.entities.chest_1 = add_container(chest, { x = -2, y = 1 }, nil, nil, logistic_building)
    surface.entities.chest_2 = add_container(chest, { x = 1, y = 1 }, nil, nil, logistic_building)
    surface.entities.pipe_1 = add_container('pipe-to-ground', { x = -3, y = 1 }, defines.direction.west, nil,
        logistic_building)
    surface.entities.pipe_2 = add_container('pipe-to-ground', { x = 2, y = 1 }, defines.direction.east, nil,
        logistic_building)
    if level > 1 then
        surface.entities.pipe_3 = add_container('pipe-to-ground', { x = -3, y = 0 }, defines.direction.west, nil,
            logistic_building)
        surface.entities.pipe_4 = add_container('pipe-to-ground', { x = 2, y = 0 }, defines.direction.east, nil,
            logistic_building)
        if level > 2 then
            hidden_dimension.energy[#hidden_dimension.energy + 1] =
            {
                reference = logistic_building,
                entity =
                    add_container(energy, { x = 0, y = 0 }, nil, nil, logistic_building)
            }
        end
        if level > 3 then
            surface.entities.pipe_5 = add_container('pipe-to-ground', { x = -3, y = -1 }, defines.direction.west, nil,
                logistic_building)
            surface.entities.pipe_6 = add_container('pipe-to-ground', { x = 2, y = -1 }, defines.direction.east, nil,
                logistic_building)
        end
    end
end

local function transport_resources(container1, container2, transport_type)
    if container1 == nil or container2 == nil then
        return
    end

    if not container1.valid or not container2.valid then
        return
    end

    local function average(c1c, c2c)
        local average_content = (c1c + c2c) / 2
        c1c = average_content
        c2c = average_content
        return c1c, c2c
    end

    local function get_steam_temperature(container)
        local temperature = 0

        local function test_for(temp)
            local fluid = container.get_fluid(1)
            if not fluid or fluid.name ~= 'steam' or fluid.temperature ~= temp then
                return
            end
            local count = container.remove_fluid(1, 1)
            if count ~= 0 then
                temperature = temp
                container.insert_fluid({ name = 'steam', amount = count, temperature = temp })
            end
        end

        test_for(15)
        if temperature == 0 then
            test_for(165)
            if temperature == 0 then
                test_for(500)
                if temperature == 0 then
                    temperature = 165
                end
            end
        end
        return temperature
    end

    local function divide_fluids()
        local af = container1.get_fluid_contents()
        local bf = container2.get_fluid_contents()
        local name1, amount1 = get_table(af)
        local name2, amount2 = get_table(bf)
        amount1 = amount1 or 0
        amount2 = amount2 or 0
        if ((not name1 and not name2) or (name1 and name2 and name1 ~= name2) or (amount1 < 1 and amount2 < 1) or (amount1 == amount2)) then
            return
        end
        if (not name1) then
            name1 = name2
        elseif (not name2) then
            name2 = name1
        end
        local v = (amount1 + amount2) / 2
        if (name1 == 'steam') then
            local temp
            local at = get_steam_temperature(container1)
            local bt = get_steam_temperature(container2)
            temp = math_max(at, bt)
            container1.clear_fluid_inside()
            container2.clear_fluid_inside()
            container1.insert_fluid({ name = name1, amount = v, temperature = temp })
            container2.insert_fluid({ name = name2, amount = v, temperature = temp })
        else
            container1.clear_fluid_inside()
            container2.clear_fluid_inside()
            container1.insert_fluid({ name = name1, amount = v })
            container2.insert_fluid({ name = name2, amount = v })
        end
    end

    local function divide_contents()
        local chest1 = container1.get_inventory(defines.inventory.chest)
        local chest2 = container2.get_inventory(defines.inventory.chest)
        for k, v in pairs(chest1.get_contents()) do
            local t = { name = k, count = v }
            local c = chest2.insert(t)
            if (c > 0) then
                chest1.remove({ name = k, count = c })
            end
        end
    end

    if container1.type == 'container' and container2.type == 'container' then
        if transport_type == 'in-out' then
            divide_contents()
        end
    elseif container1.type == 'pipe-to-ground' and container2.type == 'pipe-to-ground' then
        divide_fluids()
    else
        if transport_type == 'average' then
            if container1.temperature and container2.temperature then
                container1.temperature, container2.temperature = average(container1.temperature, container2.temperature)
            end
        end
    end
end

local function create_underground_floor(surface, size, going_down)
    local function tile_generation(floor_type, offset_pos, floor_pos, floor_area)
        local area = {}
        if type(floor_area) == 'table' then
            area.x = floor_area.x
            area.y = floor_area.y
        else
            area.x = floor_area
            area.y = floor_area
        end

        local pos = {}
        pos.x = floor_pos.x + offset_pos.x
        pos.y = floor_pos.y + offset_pos.y
        local tiles = {}
        for i = 0, area.x - 1 do
            for j = 0, area.y - 1 do
                table_insert(tiles, { name = floor_type, position = { i + pos.x, j + pos.y } })
            end
        end

        surface.set_tiles(tiles)
    end

    local gen = surface.map_gen_settings
    gen.width = size * 1.5
    gen.height = size * 1.5
    surface.map_gen_settings = gen

    tile_generation('tutorial-grid', { x = 0, y = 0 }, { x = -size / 2, y = -size / 2 }, { x = size - 1, y = size })
    tile_generation('tutorial-grid', { x = 0, y = 0 }, { x = -size / 2, y = -size / 2 }, { x = size - 1, y = size })
    tile_generation('hazard-concrete-left', { x = 0, y = 0 }, { x = -3, y = -7 }, { x = 6, y = 3 })

    if going_down then
        tile_generation('hazard-concrete-left', { x = 0, y = 0 }, { x = -3, y = 3 }, { x = 6, y = 3 })
        tile_generation('hazard-concrete-left', { x = 0, y = 0 }, { x = -2, y = -2 }, { x = 4, y = 3 })
    else
        tile_generation('tutorial-grid', { x = 0, y = 0 }, { x = -size / 2, y = -size / 2 }, { x = size - 1, y = size })
    end

    local water_tiles = {}
    for i = 0, 5, 1 do
        table_insert(water_tiles, { name = 'water', position = { -3 + i, 9 } })
        table_insert(water_tiles, { name = 'water', position = { -3 + i, 8 } })
    end

    surface.set_tiles(water_tiles)
end

local function create_main_surface(hidden_dimension, rebuild)
    local name = hidden_dimension.hd_surface
    local position = hidden_dimension.position

    if not name then
        return
    end

    local surface = game.get_surface(name)

    if not surface or not surface.valid then
        return
    end

    if rebuild then
        hidden_dimension.main_surface.reference =
            surface.create_entity
            {
                name = teleporter_type,
                position = position,
                force = game.forces.neutral,
                create_build_effect_smoke = false
            }
        if hidden_dimension.main_surface.reference_text then
            hidden_dimension.main_surface.reference_text.destroy()
        end

        hidden_dimension.main_surface.reference_text =
            rendering.draw_text
            {
                text = 'Underground',
                surface = surface,
                target = hidden_dimension.main_surface.reference,
                color = { r = 0.98, g = 0.66, b = 0.22 },
                scale = 1,
                font = 'heading-1',
                alignment = 'center',
                scale_with_zoom = false
            }
        hidden_dimension.main_surface.reference.minable_flag = false
        hidden_dimension.main_surface.reference.destructible = false
        hidden_dimension.main_surface.reference.operable = false
        hidden_dimension.main_surface.reference.get_inventory(defines.inventory.fuel).insert({ name = 'coal', count = 100 })
        return
    end
    if not hidden_dimension.main_surface.reference or not hidden_dimension.main_surface.reference.valid then
        hidden_dimension.main_surface.reference =
            surface.create_entity
            {
                name = teleporter_type,
                position = { position.x, position.y - 23 },
                force = game.forces.neutral,
                create_build_effect_smoke = false
            }
        if hidden_dimension.main_surface.reference_text then
            hidden_dimension.main_surface.reference_text.destroy()
        end
        hidden_dimension.main_surface.reference_text =
            rendering.draw_text
            {
                text = 'Underground',
                surface = surface,
                target = hidden_dimension.main_surface.reference,
                color = { r = 0.98, g = 0.66, b = 0.22 },
                scale = 1,
                font = 'heading-1',
                alignment = 'center',
                scale_with_zoom = false
            }
        hidden_dimension.main_surface.reference.minable_flag = false
        hidden_dimension.main_surface.reference.destructible = false
        hidden_dimension.main_surface.reference.operable = false
        hidden_dimension.main_surface.reference.get_inventory(defines.inventory.fuel).insert({ name = 'coal', count = 100 })
        if hidden_dimension.logistic_research_level == 0 then
            return
        end
        create_chests(hidden_dimension.main_surface, hidden_dimension.logistic_research_level, 'in_and_out')
    end
end

local function create_underground_surfaces(hidden_dimension)
    local function create_underground(floor_table, name, going_down)
        --local underground_level
        local map_gen_settings =
        {
            width = 14,
            height = 16,
            ['water'] = 0,
            ['starting_area'] = 1,
            ['cliff_settings'] = { cliff_elevation_interval = 0, cliff_elevation_0 = 0 },
            ['autoplace_settings'] =
            {
                ['entity'] = { treat_missing_as_default = false },
                ['decorative'] = { treat_missing_as_default = false }
            },
            autoplace_controls =
            {
                ['coal'] = { frequency = 0, size = 0, richness = 0 },
                ['stone'] = { frequency = 0, size = 0, richness = 0 },
                ['copper-ore'] = { frequency = 0, size = 0, richness = 0 },
                ['iron-ore'] = { frequency = 0, size = 0, richness = 0 },
                ['uranium-ore'] = { frequency = 0, size = 0, richness = 0 },
                ['crude-oil'] = { frequency = 0, size = 0, richness = 0 },
                ['trees'] = { frequency = 0, size = 0, richness = 0 },
                ['enemy-base'] = { frequency = 0, size = 0, richness = 0 }
            }
        }
        floor_table.surface = game.create_surface(name, map_gen_settings)
        floor_table.surface.always_day = true
        floor_table.surface.daytime = 0.5
        floor_table.surface.request_to_generate_chunks({ 0, 0 }, 10)
        floor_table.surface.force_generate_chunk_requests()
        local clear_ent = floor_table.surface.find_entities()
        for i, _ in ipairs(clear_ent) do
            clear_ent[i].destroy()
        end
        floor_table.name = name
        floor_table.size = 16

        floor_table.surface.destroy_decoratives({ area = { { -floor_table.size, -floor_table.size }, { floor_table.size, floor_table.size } } })

        create_underground_floor(floor_table.surface, floor_table.size, going_down)

        floor_table.going_up.reference =
            floor_table.surface.create_entity
            {
                name = teleporter_type,
                position = { 0, -6 },
                force = game.forces.neutral,
                create_build_effect_smoke = false
            }
        rendering.draw_light(
            {
                sprite = 'utility/light_medium',
                scale = 5.5,
                intensity = 1,
                minimum_darkness = 0,
                oriented = true,
                color = { 255, 255, 255 },
                target = floor_table.going_up.reference,
                surface = floor_table.surface,
                visible = true,
                only_in_alt_mode = false
            }
        )
        floor_table.going_up.reference.minable_flag = false
        floor_table.going_up.reference.destructible = false
        floor_table.going_up.reference.operable = false
        floor_table.going_up.reference.get_inventory(defines.inventory.fuel).insert({ name = 'coal', count = 100 })

        if going_down then
            floor_table.going_down.reference =
                floor_table.surface.create_entity
                {
                    name = teleporter_type,
                    position = { 0, 4 },
                    force = game.forces.neutral,
                    create_build_effect_smoke = false
                }
            floor_table.going_down.reference.minable_flag = false
            floor_table.going_down.reference.destructible = false
            floor_table.going_down.reference.operable = false
            floor_table.going_down.reference.get_inventory(defines.inventory.fuel).insert({ name = 'coal', count = 100 })

            rendering.draw_light(
                {
                    sprite = 'utility/light_medium',
                    scale = 5.5,
                    intensity = 1,
                    minimum_darkness = 0,
                    oriented = true,
                    color = { 255, 255, 255 },
                    target = floor_table.going_down.reference,
                    surface = floor_table.surface,
                    visible = true,
                    only_in_alt_mode = false
                }
            )
        end
    end

    hidden_dimension.reset_counter = hidden_dimension.reset_counter + 1

    create_underground(hidden_dimension.level_1,
        hidden_dimension.name .. '_level_1_' .. tostring(hidden_dimension.reset_counter), true)
    create_underground(hidden_dimension.level_2,
        hidden_dimension.name .. '_level_2_' .. tostring(hidden_dimension.reset_counter), false)
end

local function logistic_update(hidden_dimension)
    local name = hidden_dimension.hd_surface
    if not name then
        return
    end

    local surface = game.get_surface(name)

    if not surface or not surface.valid then
        return
    end

    local function entrance_transport_resources(transport1, transport2)
        transport_resources(transport1.reference, transport2.reference, 'average')

        if transport1.transport_type == 'out_and_out' then
            transport_resources(transport2.entities.chest_1, transport1.entities.chest_1, 'in-out')
            transport_resources(transport2.entities.chest_2, transport1.entities.chest_2, 'in-out')
        elseif transport1.transport_type == 'in_and_out' then
            transport_resources(transport1.entities.chest_1, transport2.entities.chest_1, 'in-out')
            transport_resources(transport2.entities.chest_2, transport1.entities.chest_2, 'in-out')
        end

        transport_resources(transport1.entities.pipe_1, transport2.entities.pipe_1, 'in-out')
        transport_resources(transport2.entities.pipe_2, transport1.entities.pipe_2, 'in-out')

        if hidden_dimension.logistic_research_level > 1 then
            transport_resources(transport1.entities.pipe_3, transport2.entities.pipe_3, 'in-out')
            transport_resources(transport2.entities.pipe_4, transport1.entities.pipe_4, 'in-out')

            if hidden_dimension.logistic_research_level > 2 then
                transport_resources(transport1.entities.pipe_5, transport2.entities.pipe_5, 'in-out')
                transport_resources(transport2.entities.pipe_6, transport1.entities.pipe_6, 'in-out')
            end
        end
    end

    entrance_transport_resources(hidden_dimension.main_surface, hidden_dimension.level_1.going_up)

    entrance_transport_resources(hidden_dimension.level_1.going_down, hidden_dimension.level_2.going_up)

    transport_resources(hidden_dimension.level_1.going_down.reference, hidden_dimension.level_1.going_up.reference,
        'average')
end

local function create_chests_logistics(hidden_dimension, level)
    create_chests(hidden_dimension, hidden_dimension.main_surface, level, 'in_and_out')
    create_chests(hidden_dimension, hidden_dimension.level_1.going_up, level, 'out_and_in')
    create_chests(hidden_dimension, hidden_dimension.level_1.going_down, level, 'in_and_out')
    create_chests(hidden_dimension, hidden_dimension.level_2.going_up, level, 'out_and_in')
    disconnect_neighbour(hidden_dimension)
    connect_neighbour(hidden_dimension)
end

local function reset_surface()
    HDT.reset_table()
    local hidden_dimension = HDT.get('hidden_dimension')
    hidden_dimension.logistic_research_level = 0

    hidden_dimension.level_1.going_down.entities = {}
    hidden_dimension.level_1.going_up.entities = {}
    hidden_dimension.level_2.going_down.entities = {}
    hidden_dimension.level_2.going_up.entities = {}
    hidden_dimension.main_surface.entities = {}

    game.delete_surface('level_1_' .. tostring(hidden_dimension.reset_counter))
    game.delete_surface('level_2_' .. tostring(hidden_dimension.reset_counter))
    create_underground_surfaces()
end

local function through_teleporter_update(hidden_dimension)
    local function teleport_players_around(source, destination)
        if source == nil or source.valid ~= true then
            return
        end
        if destination == nil or (not destination.valid) then
            return
        end

        local function surface_play_sound(sound_path, surface, pos)
            for _, v in pairs(game.connected_players) do
                if v.surface.name == surface then
                    v.play_sound { path = sound_path, position = pos }
                end
            end
        end

        local to_teleport_out_entity_list =
            source.surface.find_entities_filtered
            {
                area =
                {
                    { source.position.x - 1.1, source.position.y - 1.1 },
                    { source.position.x + 1.1, source.position.y + 1.1 }
                },
                type = 'character'
            }
        for _, v in ipairs(to_teleport_out_entity_list) do
            if v.type == 'character' then
                local pos = { x = destination.position.x, y = destination.position.y }
                if v.position.y < source.position.y then
                    pos.y = pos.y + 2
                else
                    pos.y = pos.y - 2
                end
                teleport(v, pos, destination.surface)
                local sound = 'utility/wire_connect_pole'
                surface_play_sound(sound, source.surface.name, source.position)
                surface_play_sound(sound, destination.surface.name, destination.position)
            end
        end
    end

    if hidden_dimension.main_surface and hidden_dimension.main_surface.reference then
        teleport_players_around(hidden_dimension.main_surface.reference, hidden_dimension.level_1.going_up.reference)
    end
    if hidden_dimension.level_1 and hidden_dimension.level_1.going_up and hidden_dimension.level_1.going_up.reference then
        teleport_players_around(hidden_dimension.level_1.going_up.reference, hidden_dimension.main_surface.reference)
    end

    if hidden_dimension.level_1 and hidden_dimension.level_1.going_down and hidden_dimension.level_1.going_down.reference then
        teleport_players_around(hidden_dimension.level_1.going_down.reference,
            hidden_dimension.level_2.going_up.reference)
    end
    if hidden_dimension.level_2 and hidden_dimension.level_2.going_up and hidden_dimension.level_2.going_up.reference then
        teleport_players_around(hidden_dimension.level_2.going_up.reference,
            hidden_dimension.level_1.going_down.reference)
    end
end

local function modify_surface_daytime(surface)
    surface.daytime = 0.1
end

local function upgrade_transport_buildings(hidden_dimension, level)
    local function upgrade(transport, building_type)
        local function copy_chest_content(content, chest)
            for k, v in pairs(content) do
                chest.insert({ name = k, count = v })
            end
        end

        if transport.reference == nil or transport.reference.valid ~= true then
            return
        end
        if transport.entities.chest_1 == nil or transport.entities.chest_1.valid ~= true then
            return
        end

        local chest_1_inventory = transport.entities.chest_1.get_inventory(defines.inventory.chest).get_contents()
        local chest_2_inventory = transport.entities.chest_2.get_inventory(defines.inventory.chest).get_contents()

        local pos = transport.reference.position

        local surface = transport.reference.surface

        clear_surroundings(hidden_dimension.name, surface, pos)

        transport.reference = surface.create_entity { name = building_type, position = pos, force = game.forces.enemy }
        transport.reference.minable_flag = false
        transport.reference.destructible = false
        transport.reference.operable = false
        transport.reference.get_inventory(defines.inventory.fuel).insert({ name = 'coal', count = 100 })

        create_chests(hidden_dimension, transport, level, transport.transport_type)

        copy_chest_content(chest_1_inventory, transport.entities.chest_1)
        copy_chest_content(chest_2_inventory, transport.entities.chest_2)
    end

    upgrade(hidden_dimension.level_1.going_up, teleporter_type)
    upgrade(hidden_dimension.level_1.going_down, teleporter_type)
    upgrade(hidden_dimension.level_2.going_up, teleporter_type)
    upgrade(hidden_dimension.main_surface, teleporter_type)
end

local function has_tech_researched(force, hidden_dimension)
    if hidden_dimension.instant_unlocked_available and not hidden_dimension.instant_unlocked then
        hidden_dimension.instant_unlocked = true
        hidden_dimension.level_1.size = level_3_size
        hidden_dimension.level_2.size = level_3_size
        create_underground_floor(hidden_dimension.level_1.surface, hidden_dimension.level_1.size, true)
        create_underground_floor(hidden_dimension.level_2.surface, hidden_dimension.level_2.size, false)
        hidden_dimension.logistic_research_level = 4
        upgrade_transport_buildings(hidden_dimension, 4)
        create_chests_logistics(hidden_dimension, 4)
        modify_surface_daytime(hidden_dimension.level_1.surface)
        modify_surface_daytime(hidden_dimension.level_2.surface)
        return
    end

    if force.technologies['automation'].researched then
        hidden_dimension.level_1.size = level_1_size
        hidden_dimension.level_2.size = level_1_size
        create_underground_floor(hidden_dimension.level_1.surface, hidden_dimension.level_1.size, true)
        create_underground_floor(hidden_dimension.level_2.surface, hidden_dimension.level_2.size, false)
    end
    if force.technologies['automation-2'].researched then
        hidden_dimension.level_1.size = level_2_size
        hidden_dimension.level_2.size = level_2_size
        create_underground_floor(hidden_dimension.level_1.surface, hidden_dimension.level_1.size, true)
        create_underground_floor(hidden_dimension.level_2.surface, hidden_dimension.level_2.size, false)
    end
    if force.technologies['automation-3'].researched then
        hidden_dimension.level_1.size = level_3_size
        hidden_dimension.level_2.size = level_3_size
        create_underground_floor(hidden_dimension.level_1.surface, hidden_dimension.level_1.size, true)
        create_underground_floor(hidden_dimension.level_2.surface, hidden_dimension.level_2.size, false)
    end

    if force.technologies['logistics'].researched then
        hidden_dimension.logistic_research_level = 1
        create_chests_logistics(hidden_dimension, 1)
    end
    if force.technologies['logistics-2'].researched then
        hidden_dimension.logistic_research_level = 2
        upgrade_transport_buildings(hidden_dimension, 2)
    end
    if force.technologies['logistics-3'].researched then
        hidden_dimension.logistic_research_level = 4
        upgrade_transport_buildings(hidden_dimension, 4)
    end
    if force.technologies['electric-energy-accumulators'].researched then
        hidden_dimension.logistic_research_level = 3
        upgrade_transport_buildings(hidden_dimension, 3)

        modify_surface_daytime(hidden_dimension.level_1.surface)
        modify_surface_daytime(hidden_dimension.level_2.surface)
    end
end

local function create(player, position)
    if exists(player.name) then
        print('hidden dimension already exists for ' .. player.name)
        return
    end

    print('creating hidden dimension for ' .. player.name)

    local hidden_dimension = get_or_set_player(player, position)
    local multiplayer_enabled = HDT.get('multiplayer_enabled')
    if multiplayer_enabled then
        print('creating underground surfaces for ' .. player.name)
        create_underground_surfaces(hidden_dimension)
        create_main_surface(hidden_dimension, true)

        has_tech_researched(player.force, hidden_dimension)
    end
end

Event.on_nth_tick(
    20,
    function ()
        if not HDT.get('module_enabled') then
            return
        end
        player_callback(
            function (_, hidden_dimension)
                logistic_update(hidden_dimension)
                through_teleporter_update(hidden_dimension)
                conf_changed(hidden_dimension)
            end
        )
    end
)

Event.add(
    defines.events.on_research_finished,
    function (event)
        if not HDT.get('module_enabled') then
            return
        end
        local research = event.research
        local force = research.force

        get_player_by_force(
            force,
            function (hidden_dimension, player)
                if SessionData.allowed(player, 'instant_hd_unlock') then
                    return
                end

                if research.name == 'automation' or research.name == 'automation-2' or research.name == 'automation-3' then
                    if research.name == 'automation' then
                        hidden_dimension.level_1.size = level_1_size
                        hidden_dimension.level_2.size = level_1_size
                        create_underground_floor(hidden_dimension.level_1.surface, hidden_dimension.level_1.size, true)
                        create_underground_floor(hidden_dimension.level_2.surface, hidden_dimension.level_2.size, false)
                    elseif research.name == 'automation-2' then
                        hidden_dimension.level_1.size = level_2_size
                        hidden_dimension.level_2.size = level_2_size
                        create_underground_floor(hidden_dimension.level_1.surface, hidden_dimension.level_1.size, true)
                        create_underground_floor(hidden_dimension.level_2.surface, hidden_dimension.level_2.size, true)
                    elseif research.name == 'automation-3' then
                        hidden_dimension.level_1.size = level_3_size
                        hidden_dimension.level_2.size = level_3_size
                        create_underground_floor(hidden_dimension.level_1.surface, hidden_dimension.level_1.size, false)
                        create_underground_floor(hidden_dimension.level_2.surface, hidden_dimension.level_2.size, false)
                    end
                elseif research.name == 'logistics' then
                    hidden_dimension.logistic_research_level = 1
                    create_chests_logistics(hidden_dimension, 1)
                elseif research.name == 'logistics-2' then
                    hidden_dimension.logistic_research_level = 2
                    upgrade_transport_buildings(hidden_dimension, 2)
                elseif research.name == 'logistics-3' then
                    hidden_dimension.logistic_research_level = 4
                    upgrade_transport_buildings(hidden_dimension, 4)
                elseif research.name == 'electric-energy-accumulators' then
                    hidden_dimension.logistic_research_level = 3
                    upgrade_transport_buildings(hidden_dimension, 3)
                end
            end
        )
    end
)

--- If a different surface is wanted then this should be called
-- with:
-- local HD = require 'features.modules.hidden_dimension.main'
-- HD.init({hd_surface = some_surface})
function Public.init(args)
    if not HDT.get('module_enabled') then
        return
    end
    local hidden_dimension = HDT.get('hidden_dimension')
    if args then
        hidden_dimension.position = args.position or { x = 0, y = 3 }
        hidden_dimension.hd_surface = args.hd_surface or 'nauvis'
    else
        hidden_dimension.hd_surface = 'nauvis'
        hidden_dimension.position = { x = 0, y = 3 }
    end
end

Event.add(
    defines.events.on_entity_cloned,
    function (event)
        if not HDT.get('module_enabled') then
            return
        end
        player_callback(
            function (_, hidden_dimension)
                for _, v in pairs(hidden_dimension.main_surface.entities) do
                    if event.source == v then
                        event.destination.destroy()
                    end
                end
                hidden_dimension.main_surface.reference.destroy()
            end
        )
    end
)

Event.add(
    defines.events.on_pre_player_removed,
    function (event)
        if not HDT.get('module_enabled') then
            return
        end
        local player = game.get_player(event.player_index)
        reset_player(player)
    end
)

Event.add(ServerCommands.events.reset_game, reset_surface)
Event.add(ServerCommands.events.init_surfaces, create_underground_surfaces)

Public.reset_player = reset_player
Public.create = create

return Public
