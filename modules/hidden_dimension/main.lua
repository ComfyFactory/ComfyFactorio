local Event = require 'utils.event'
local HDT = require 'modules.hidden_dimension.table'

local Public = {}
Public.events = {
    reset_game = Event.generate_event_name('reset_game'),
    init_surfaces = Event.generate_event_name('init_surfaces')
}

--- If true then surface will be picked to nauvis.
Public.enable_auto_init = true

local deepcopy = table.deepcopy
local transport_table = HDT.transport_table
local levels_table = HDT.levels_table
local math_max = math.max
local table_insert = table.insert

local function get_table(t)
    local key
    local value
    for k, v in pairs(t) do
        key = k
        value = v
    end
    return key, value
end

local function teleport(entity, pos, surface)
    local sane_pos = surface.find_non_colliding_position(entity.name, pos, 0, 1, 1)
    if entity.type == 'character' then
        for k, v in pairs(game.players) do
            if v.character == entity then
                v.teleport(sane_pos, surface)
            end
        end
    end
end

local function clear_surroundings(surface, pos)
    local entity = surface.find_entities(pos)
    for i, _ in ipairs(entity) do
        if entity[i].type ~= 'character' then
            entity[i].destroy()
        else
            teleport(entity[i], {0, 0}, entity[i].surface)
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
            local count = container.remove_fluid({name = 'steam', amount = 1, temperature = temp})
            if count ~= 0 then
                temperature = temp
            else
                return
            end
            container.insert_fluid({name = 'steam', amount = count, temperature = temp})
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
        if
            ((not name1 and not name2) or (name1 and name2 and name1 ~= name2) or (amount1 < 1 and amount2 < 1) or
                (amount1 == amount2))
         then
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
            container1.insert_fluid({name = name1, amount = v, temperature = temp})
            container2.insert_fluid({name = name2, amount = v, temperature = temp})
        else
            container1.clear_fluid_inside()
            container2.clear_fluid_inside()
            container1.insert_fluid({name = name1, amount = v})
            container2.insert_fluid({name = name2, amount = v})
        end
    end

    local function divide_contents()
        local chest1 = container1.get_inventory(defines.inventory.chest)
        local chest2 = container2.get_inventory(defines.inventory.chest)
        for k, v in pairs(chest1.get_contents()) do
            local t = {name = k, count = v}
            local c = chest2.insert(t)
            if (c > 0) then
                chest1.remove({name = k, count = c})
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
                table_insert(tiles, {name = floor_type, position = {i + pos.x, j + pos.y}})
            end
        end

        surface.set_tiles(tiles)
    end
    tile_generation('tutorial-grid', {x = 0, y = 0}, {x = -size / 2, y = -size / 2}, {x = size - 1, y = size})
    tile_generation('black-refined-concrete', {x = 0, y = 0}, {x = -size / 2, y = -size / 2}, {x = size - 1, y = size})
    tile_generation('hazard-concrete-left', {x = 0, y = 0}, {x = -3, y = -7}, {x = 6, y = 3})

    if going_down then
        tile_generation('hazard-concrete-left', {x = 0, y = 0}, {x = -3, y = 3}, {x = 6, y = 3})
        tile_generation('hazard-concrete-left', {x = 0, y = 0}, {x = -2, y = -2}, {x = 4, y = 3})
    else
        tile_generation(
            'black-refined-concrete',
            {x = 0, y = 0},
            {x = -size / 2, y = -size / 2},
            {x = size - 1, y = size}
        )
    end
end

local function create_main_surface(rebuild)
    local hidden_dimension = HDT.get('hidden_dimension')
    local name = hidden_dimension.hd_surface
    local position = hidden_dimension.position

    if not game.surfaces[name] then
        return
    end

    if not game.surfaces[name].valid then
        return
    end

    local surface = game.surfaces[name]

    if rebuild then
        hidden_dimension.main_surface.reference =
            surface.create_entity {
            name = 'car',
            position = position,
            force = game.forces.enemy,
            create_build_effect_smoke = false
        }
        hidden_dimension.main_surface.reference.minable = false
        hidden_dimension.main_surface.reference.destructible = false
        hidden_dimension.main_surface.reference.operable = false
        hidden_dimension.main_surface.reference.get_inventory(defines.inventory.fuel).insert(
            {name = 'coal', count = 100}
        )
        return
    end
    if not hidden_dimension.main_surface.reference or not hidden_dimension.main_surface.reference.valid then
        hidden_dimension.main_surface.reference =
            surface.create_entity {
            name = 'car',
            position = {position.x, position.y - 23},
            force = game.forces.enemy,
            create_build_effect_smoke = false
        }
        hidden_dimension.main_surface.reference.minable = false
        hidden_dimension.main_surface.reference.destructible = false
        hidden_dimension.main_surface.reference.operable = false
        hidden_dimension.main_surface.reference.get_inventory(defines.inventory.fuel).insert(
            {name = 'coal', count = 100}
        )
        if hidden_dimension.logistic_research_level == 0 then
            return
        end
        Public.create_chests(hidden_dimension.main_surface, hidden_dimension.logistic_research_level, 'in_and_out')
    end
end

local function create_underground_surfaces()
    local function create_underground(floor_table, name, going_down)
        --local underground_level
        floor_table.surface = game.create_surface(name, {width = 14, height = 16})
        floor_table.surface.always_day = true
        floor_table.surface.daytime = 0.5
        floor_table.surface.request_to_generate_chunks({0, 0}, 10)
        floor_table.surface.force_generate_chunk_requests()
        local clear_ent = floor_table.surface.find_entities()
        for i, _ in ipairs(clear_ent) do
            clear_ent[i].destroy()
        end
        floor_table.name = name
        floor_table.size = 16

        floor_table.surface.destroy_decoratives(
            {area = {{-floor_table.size, -floor_table.size}, {floor_table.size, floor_table.size}}}
        )

        create_underground_floor(floor_table.surface, floor_table.size, going_down)

        floor_table.going_up.reference =
            floor_table.surface.create_entity {
            name = 'car',
            position = {0, -6},
            force = game.forces.enemy,
            create_build_effect_smoke = false
        }
        rendering.draw_light(
            {
                sprite = 'utility/light_medium',
                scale = 5.5,
                intensity = 1,
                minimum_darkness = 0,
                oriented = true,
                color = {255, 255, 255},
                target = floor_table.going_up.reference,
                surface = floor_table.surface,
                visible = true,
                only_in_alt_mode = false
            }
        )
        floor_table.going_up.reference.minable = false
        floor_table.going_up.reference.destructible = false
        floor_table.going_up.reference.operable = false
        floor_table.going_up.reference.get_inventory(defines.inventory.fuel).insert({name = 'coal', count = 100})

        if going_down then
            floor_table.going_down.reference =
                floor_table.surface.create_entity {
                name = 'car',
                position = {0, 4},
                force = game.forces.enemy,
                create_build_effect_smoke = false
            }
            floor_table.going_down.reference.minable = false
            floor_table.going_down.reference.destructible = false
            floor_table.going_down.reference.operable = false
            floor_table.going_down.reference.get_inventory(defines.inventory.fuel).insert({name = 'coal', count = 100})

            rendering.draw_light(
                {
                    sprite = 'utility/light_medium',
                    scale = 5.5,
                    intensity = 1,
                    minimum_darkness = 0,
                    oriented = true,
                    color = {255, 255, 255},
                    target = floor_table.going_down.reference,
                    surface = floor_table.surface,
                    visible = true,
                    only_in_alt_mode = false
                }
            )
        end
    end
    local hidden_dimension = HDT.get('hidden_dimension')
    if not hidden_dimension.reset_counter then
        hidden_dimension.reset_counter = 1
    else
        hidden_dimension.reset_counter = hidden_dimension.reset_counter + 1
    end

    create_underground(hidden_dimension.level_1, 'level_1_' .. tostring(hidden_dimension.reset_counter), true)
    create_underground(hidden_dimension.level_2, 'level_2_' .. tostring(hidden_dimension.reset_counter), false)
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

local function logistic_update()
    local hidden_dimension = HDT.get('hidden_dimension')
    local name = hidden_dimension.hd_surface

    if not game.surfaces[name] then
        return
    end

    if not game.surfaces[name].valid then
        return
    end

    local function energy_update(t)
        local g = 0
        local c = 0
        for k, v in pairs(t) do
            if (v.valid) then
                g = g + v.energy
                c = c + v.electric_buffer_size
            end
        end
        for k, v in pairs(t) do
            if (v.valid) then
                local r = (v.electric_buffer_size / c)
                v.energy = g * r
            end
        end
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

    transport_resources(
        hidden_dimension.level_1.going_down.reference,
        hidden_dimension.level_1.going_up.reference,
        'average'
    )

    energy_update(hidden_dimension.energy)
end

local function on_research_finished(event)
    local hidden_dimension = HDT.get('hidden_dimension')

    if
        event.research.name == 'automation' or event.research.name == 'automation-2' or
            event.research.name == 'automation-3'
     then
        if event.research.name == 'automation' then
            hidden_dimension.level_1.size = 32
            hidden_dimension.level_2.size = 32
            create_underground_floor(hidden_dimension.level_1.surface, hidden_dimension.level_1.size, true)
            create_underground_floor(hidden_dimension.level_2.surface, hidden_dimension.level_1.size, false)
        elseif event.research.name == 'automation-2' then
            hidden_dimension.level_1.size = 64
            create_underground_floor(hidden_dimension.level_1.surface, hidden_dimension.level_1.size, true)
        elseif event.research.name == 'automation-3' then
            hidden_dimension.level_2.size = 64
            create_underground_floor(hidden_dimension.level_2.surface, hidden_dimension.level_1.size, false)
        end
    elseif event.research.name == 'logistics' then
        hidden_dimension.logistic_research_level = 1
        Public.create_chests_logistics(1)
    elseif event.research.name == 'logistics-2' then
        hidden_dimension.logistic_research_level = 2
        Public.upgrade_transport_buildings(2)
    elseif event.research.name == 'logistics-3' then
        hidden_dimension.logistic_research_level = 3
        Public.upgrade_transport_buildings(3)
    elseif event.research.name == 'electric-energy-accumulators' then
    -- fix power
    end
end

local function through_teleporter_update()
    local hidden_dimension = HDT.get('hidden_dimension')
    local function teleport_players_around(source, destination)
        if source == nil or source.valid ~= true then
            return
        end
        if destination == nil or (not destination.valid) then
            return
        end

        local function surface_play_sound(sound_path, surface, pos)
            for k, v in pairs(game.connected_players) do
                if v.surface.name == surface then
                    v.play_sound {path = sound_path, position = pos}
                end
            end
        end

        local to_teleport_out_entity_list =
            source.surface.find_entities_filtered {
            area = {
                {source.position.x - 1.1, source.position.y - 1.1},
                {source.position.x + 1.1, source.position.y + 1.1}
            },
            type = 'character'
        }
        for i, v in ipairs(to_teleport_out_entity_list) do
            if v.type == 'character' then
                local pos = {x = destination.position.x, y = destination.position.y}
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

    if
        hidden_dimension.level_1 and hidden_dimension.level_1.going_down and
            hidden_dimension.level_1.going_down.reference
     then
        teleport_players_around(
            hidden_dimension.level_1.going_down.reference,
            hidden_dimension.level_2.going_up.reference
        )
    end
    if hidden_dimension.level_2 and hidden_dimension.level_2.going_up and hidden_dimension.level_2.going_up.reference then
        teleport_players_around(
            hidden_dimension.level_2.going_up.reference,
            hidden_dimension.level_1.going_down.reference
        )
    end
end

local function on_entity_cloned(event)
    local hidden_dimension = HDT.get('hidden_dimension')
    for k, v in pairs(hidden_dimension.main_surface.entities) do
        if event.source == v then
            event.destination.destroy()
        end
    end
    hidden_dimension.main_surface.reference.destroy()
end

local function on_player_joined_game(event)
    if event.player_index == 1 then
        create_underground_surfaces()

        create_main_surface(true)
    end
end

local function on_tick(e)
    if e.tick % 5 then
        logistic_update()
        if e.tick % 30 then
            create_main_surface()
            through_teleporter_update()
        end
    end
end

local function on_init()
    local hidden_dimension = HDT.get('hidden_dimension')
    hidden_dimension.level_1 = deepcopy(levels_table)
    hidden_dimension.level_2 = deepcopy(levels_table)
    hidden_dimension.main_surface = deepcopy(transport_table)
end

--- If a different surface is wanted then this should be called
-- with:
-- local HD = require 'modules.hidden_dimension.main'
-- HD.init({hd_surface = some_surface})
function Public.init(args)
    local hidden_dimension = HDT.get('hidden_dimension')
    if args then
        hidden_dimension.position = args.position or {x = 0, y = 3}
        hidden_dimension.hd_surface = args.hd_surface or 'nauvis'
    else
        hidden_dimension.hd_surface = 'nauvis'
        hidden_dimension.position = {x = 0, y = 3}
    end
end

function Public.create_chests(surface, level, build_type)
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
    local energy = 'electric-energy-interface'
    local loader
    local chest = 'blue-chest'
    if level == 1 then
        loader = 'loader'
    elseif level == 2 then
        loader = 'fast-loader'
    else
        loader = 'express-loader'
    end

    local function add_container(name, pos, direction, type)
        local container_entity
        container_entity =
            logistic_building.surface.find_entity(
            name,
            {logistic_building.position.x + pos.x, logistic_building.position.y + pos.y}
        )
        if container_entity == nil then
            local pos2 = {logistic_building.position.x + pos.x, logistic_building.position.y + pos.y}
            if name == 'loader' or name == 'fast-loader' or name == 'express-loader' then
                container_entity =
                    logistic_building.surface.create_entity {
                    name = name,
                    position = pos2,
                    force = game.forces.player,
                    type = type
                }
                container_entity.direction = direction
            elseif name == 'pipe-to-ground' then
                container_entity =
                    logistic_building.surface.create_entity {name = name, position = pos2, force = game.forces.player}
                container_entity.direction = direction
            elseif name == energy then
                container_entity =
                    logistic_building.surface.create_entity {name = name, position = pos2, force = game.forces.player}
                container_entity.minable = false
                container_entity.destructible = false
                container_entity.operable = false
                container_entity.power_production = 0
                container_entity.electric_buffer_size = 10000000
            else
                container_entity =
                    logistic_building.surface.create_entity {name = name, position = pos2, force = game.forces.player}
            end
        end
        container_entity.minable = false
        container_entity.destructible = false
        return container_entity
    end

    surface.entities.loader_1 = add_container(loader, {x = -2, y = 0}, direction1, rotation1)
    surface.entities.loader_2 = add_container(loader, {x = 1, y = 0}, direction2, rotation2)
    surface.entities.chest_1 = add_container(chest, {x = -2, y = 1})
    surface.entities.chest_2 = add_container(chest, {x = 1, y = 1})
    surface.entities.pipe_1 = add_container('pipe-to-ground', {x = -3, y = 1}, defines.direction.west)
    surface.entities.pipe_2 = add_container('pipe-to-ground', {x = 2, y = 1}, defines.direction.east)
    if level > 1 then
        surface.entities.pipe_3 = add_container('pipe-to-ground', {x = -3, y = 0}, defines.direction.west)
        surface.entities.pipe_4 = add_container('pipe-to-ground', {x = 2, y = 0}, defines.direction.east)
        if level > 2 then
            local hidden_dimension = HDT.get('hidden_dimension')
            hidden_dimension.energy[#hidden_dimension.energy + 1] = add_container(energy, {x = 0, y = 0})
            surface.entities.pipe_5 = add_container('pipe-to-ground', {x = -3, y = -1}, defines.direction.west)
            surface.entities.pipe_6 = add_container('pipe-to-ground', {x = 2, y = -1}, defines.direction.east)
        end
    end
end

function Public.upgrade_transport_buildings(level)
    local function upgrade(transport, building_type)
        local function copy_chest_content(content, chest)
            for k, v in pairs(content) do
                chest.insert({name = k, count = v})
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
        local logistic_bb = {{pos.x - 5, pos.y - 5}, {pos.x + 5, pos.y + 5}}

        local surface = transport.reference.surface

        clear_surroundings(transport.reference.surface, logistic_bb)

        transport.reference = surface.create_entity {name = building_type, position = pos, force = game.forces.enemy}
        transport.reference.minable = false
        transport.reference.destructible = false
        transport.reference.operable = false
        transport.reference.get_inventory(defines.inventory.fuel).insert({name = 'coal', count = 100})

        Public.create_chests(transport, level, transport.transport_type)

        copy_chest_content(chest_1_inventory, transport.entities.chest_1)
        copy_chest_content(chest_2_inventory, transport.entities.chest_2)
    end

    local hidden_dimension = HDT.get('hidden_dimension')

    upgrade(hidden_dimension.level_1.going_up, 'car')
    upgrade(hidden_dimension.level_1.going_down, 'car')
    upgrade(hidden_dimension.level_2.going_up, 'car')
    upgrade(hidden_dimension.main_surface, 'car')
end

function Public.create_chests_logistics(level)
    local hidden_dimension = HDT.get('hidden_dimension')
    Public.create_chests(hidden_dimension.main_surface, level, 'in_and_out')
    Public.create_chests(hidden_dimension.level_1.going_up, level, 'out_and_in')
    Public.create_chests(hidden_dimension.level_1.going_down, level, 'in_and_out')
    Public.create_chests(hidden_dimension.level_2.going_up, level, 'out_and_in')
end

if Public.enable_auto_init then
    Public.init()
end

Event.on_init(on_init)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_entity_cloned, on_entity_cloned)
Event.add(Public.events.reset_game, reset_surface)
Event.add(Public.events.init_surfaces, create_underground_surfaces)

return Public
