local Biters = require 'modules.wave_defense.biter_rolls'
local ICW = require 'maps.lumberjack.icw.main'
local Event = require 'utils.event'
local Market = require 'functions.basic_markets'
local create_entity_chain = require 'functions.create_entity_chain'
local create_tile_chain = require 'functions.create_tile_chain'
local map_functions = require 'tools.map_functions'
local WPT = require 'maps.lumberjack.table'
local Loot = require 'maps.lumberjack.loot'
local get_noise = require 'utils.get_noise'
local simplex_noise = require 'utils.simplex_noise'.d2

local Public = {}

local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs
Public.level_depth = 960
local worm_level_modifier = 0.18
local average_number_of_wagons_per_level = 2
local chunks_per_level = ((Public.level_depth - 32) / 32) ^ 2
local chance_for_wagon_spawn = math_floor(chunks_per_level / average_number_of_wagons_per_level)

local wagon_raffle = {'cargo-wagon', 'cargo-wagon', 'cargo-wagon', 'locomotive', 'fluid-wagon'}
local rock_raffle = {
    'sand-rock-big',
    'sand-rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-huge'
}

local remnants = {
    '1x2-remnants',
    'accumulator-remnants',
    'active-provider-chest-remnants',
    'arithmetic-combinator-remnants',
    'artillery-turret-remnants',
    'artillery-wagon-remnants',
    'big-electric-pole-remnants',
    'big-remnants',
    'boiler-remnants',
    'buffer-chest-remnants',
    'burner-inserter-remnants',
    'burner-mining-drill-remnants',
    'car-remnants',
    'cargo-wagon-remnants',
    'centrifuge-remnants',
    'chemical-plant-remnants',
    'constant-combinator-remnants',
    'construction-robot-remnants',
    'decider-combinator-remnants',
    'defender-remnants',
    'destroyer-remnants',
    'distractor-remnants',
    'electric-furnace-remnants',
    'express-splitter-remnants',
    'express-transport-belt-remnants',
    'express-underground-belt-remnants',
    'fast-inserter-remnants',
    'fast-splitter-remnants',
    'fast-transport-belt-remnants',
    'fast-underground-belt-remnants',
    'filter-inserter-remnants',
    'flamethrower-turret-remnants',
    'fluid-wagon-remnants',
    'gate-remnants',
    'gun-turret-remnants',
    'heat-exchanger-remnants',
    'heat-pipe-remnants',
    'inserter-remnants',
    'iron-chest-remnants',
    'lab-remnants',
    'lamp-remnants',
    'laser-turret-remnants',
    'locomotive-remnants',
    'logistic-robot-remnants',
    'long-handed-inserter-remnants',
    'medium-electric-pole-remnants',
    'medium-remnants',
    'medium-small-remnants',
    'nuclear-reactor-remnants',
    'offshore-pump-remnants',
    'oil-refinery-remnants',
    'passive-provider-chest-remnants',
    'pipe-remnants',
    'pipe-to-ground-remnants',
    'programmable-speaker-remnants',
    'pump-remnants',
    'pumpjack-remnants',
    'radar-remnants',
    'rail-chain-signal-remnants',
    'rail-ending-remnants',
    'rail-signal-remnants',
    'requester-chest-remnants',
    'roboport-remnants',
    --'rocket-silo-remnants',
    'small-electric-pole-remnants',
    'small-remnants',
    'solar-panel-remnants',
    'splitter-remnants',
    'stack-filter-inserter-remnants',
    'stack-inserter-remnants',
    'steam-engine-remnants',
    'steam-turbine-remnants',
    'steel-chest-remnants',
    'steel-furnace-remnants',
    'stone-furnace-remnants',
    'storage-chest-remnants',
    'storage-tank-remnants',
    'substation-remnants',
    'tank-remnants',
    'train-stop-remnants',
    'transport-belt-remnants',
    'underground-belt-remnants',
    'wall-remnants',
    'wooden-chest-remnants'
}

local remnants_index = #remnants

local scrap_entities = {
    'crash-site-assembling-machine-1-broken',
    'crash-site-assembling-machine-2-broken',
    'crash-site-assembling-machine-1-broken',
    'crash-site-assembling-machine-2-broken',
    'crash-site-lab-broken',
    'medium-ship-wreck',
    'small-ship-wreck',
    'medium-ship-wreck',
    'small-ship-wreck',
    'medium-ship-wreck',
    'small-ship-wreck',
    'medium-ship-wreck',
    'small-ship-wreck',
    'crash-site-chest-1',
    'crash-site-chest-2',
    'crash-site-chest-1',
    'crash-site-chest-2',
    'crash-site-chest-1',
    'crash-site-chest-2'
}
local scrap_entities_index = #scrap_entities

local scrap_buildings = {
    'nuclear-reactor',
    'centrifuge',
    'beacon',
    'chemical-plant',
    'assembling-machine-1',
    'assembling-machine-2',
    'assembling-machine-3',
    'oil-refinery',
    'arithmetic-combinator',
    'constant-combinator',
    'decider-combinator',
    'programmable-speaker',
    'steam-turbine',
    'steam-engine',
    'chemical-plant',
    'assembling-machine-1',
    'assembling-machine-2',
    'assembling-machine-3',
    'oil-refinery',
    'arithmetic-combinator',
    'constant-combinator',
    'decider-combinator',
    'programmable-speaker',
    'steam-turbine',
    'steam-engine'
}
local decos_inside_forest = {'brown-asterisk', 'brown-asterisk', 'brown-carpet-grass', 'brown-hairy-grass'}
local spawner_raffle = {'biter-spawner', 'biter-spawner', 'biter-spawner', 'spitter-spawner'}
local trees = {'dead-grey-trunk', 'dead-grey-trunk', 'dry-tree'}

local noises = {
    ['forest_location'] = {
        {modifier = 0.003, weight = 1},
        {modifier = 0.01, weight = 0.25},
        {modifier = 0.05, weight = 0.15},
        {modifier = 0.1, weight = 0.05}
    },
    ['forest_density'] = {
        {modifier = 0.01, weight = 1},
        {modifier = 0.05, weight = 0.5},
        {modifier = 0.1, weight = 0.025}
    }
}
local function get_forest_noise(name, p, seed)
    local noise = 0
    for _, n in pairs(noises[name]) do
        noise = noise + simplex_noise(p.x * n.modifier, p.y * n.modifier, seed) * n.weight
        seed = seed + 10000
    end
    return noise
end

local function place_wagon(data)
    local surface = data.surface
    local left_top = data.left_top

    local position = {x = left_top.x + math_random(4, 12) * 2, y = left_top.y + math_random(4, 12) * 2}

    local direction
    local tiles
    local r1 = math_random(2, 4) * 2
    local r2 = math_random(2, 4) * 2

    if math_random(1, 2) == 1 then
        tiles = surface.find_tiles_filtered({area = {{position.x, position.y - r1}, {position.x + 2, position.y + r2}}})
        direction = 0
    else
        tiles = surface.find_tiles_filtered({area = {{position.x - r1, position.y}, {position.x + r2, position.y + 2}}})
        direction = 2
    end

    for k, tile in pairs(tiles) do
        if tile.collides_with('resource-layer') then
            surface.set_tiles({{name = 'landfill', position = tile.position}}, true)
        end
        for _, e in pairs(
            surface.find_entities_filtered(
                {position = tile.position, force = {'neutral', 'enemy', 'lumber_defense', 'defenders'}}
            )
        ) do
            e.destroy()
        end
        if tile.position.y % 2 == 0 and tile.position.x % 2 == 0 then
            surface.create_entity(
                {name = 'straight-rail', position = tile.position, force = 'player', direction = direction}
            )
        end
    end

    local entity =
        surface.create_entity(
        {name = wagon_raffle[math_random(1, #wagon_raffle)], position = position, force = 'player'}
    )
    entity.minable = false

    local wagon = ICW.register_wagon(entity, true)
    wagon.entity_count = 999
end

local function place_random_scrap_entity(surface, position)
    local r = math_random(1, 100)
    if r < 15 then
        local e =
            surface.create_entity(
            {name = scrap_buildings[math_random(1, #scrap_buildings)], position = position, force = 'defenders'}
        )
        if e.name == 'nuclear-reactor' then
            create_entity_chain(
                surface,
                {name = 'heat-pipe', position = position, force = 'player'},
                math_random(16, 32),
                25
            )
        end
        if
            e.name == 'chemical-plant' or e.name == 'steam-turbine' or e.name == 'steam-engine' or
                e.name == 'oil-refinery'
         then
            create_entity_chain(surface, {name = 'pipe', position = position, force = 'player'}, math_random(8, 16), 25)
        end
        e.active = false
        return
    end
    if r < 75 then
        local e =
            surface.create_entity(
            {
                name = 'gun-turret',
                position = position,
                force = 'lumber_defense',
                destructible = true
            }
        )
        if math_abs(position.y) < Public.level_depth * 2.5 then
            e.insert({name = 'piercing-rounds-magazine', count = math_random(64, 128)})
        else
            e.insert({name = 'uranium-rounds-magazine', count = math_random(64, 128)})
        end
        return
    end

    local e =
        surface.create_entity(
        {name = 'storage-tank', position = position, force = 'defenders', direction = math_random(0, 3)}
    )
    local fluids = {'crude-oil', 'lubricant', 'heavy-oil', 'light-oil', 'petroleum-gas', 'sulfuric-acid', 'water'}
    e.fluidbox[1] = {name = fluids[math_random(1, #fluids)], amount = math_random(15000, 25000)}
    create_entity_chain(surface, {name = 'pipe', position = position, force = 'player'}, math_random(6, 8), 1)
    create_entity_chain(surface, {name = 'pipe', position = position, force = 'player'}, math_random(6, 8), 1)
    create_entity_chain(surface, {name = 'pipe', position = position, force = 'player'}, math_random(15, 30), 80)
end

local function create_inner_content(surface, pos, noise)
    if math_random(1, 90000) == 1 then
        if noise < 0.3 or noise > -0.3 then
            map_functions.draw_noise_entity_ring(surface, pos, 'laser-turret', 'lumber_defense', 0, 2)
            map_functions.draw_noise_entity_ring(surface, pos, 'accumulator', 'lumber_defense', 2, 3)
            map_functions.draw_noise_entity_ring(surface, pos, 'substation', 'lumber_defense', 3, 4)
            map_functions.draw_noise_entity_ring(surface, pos, 'solar-panel', 'lumber_defense', 4, 6)
            map_functions.draw_noise_entity_ring(surface, pos, 'stone-wall', 'lumber_defense', 6, 7)

            create_tile_chain(surface, {name = 'concrete', position = pos}, math_random(16, 32), 50)
            create_tile_chain(surface, {name = 'concrete', position = pos}, math_random(16, 32), 50)
            create_tile_chain(surface, {name = 'stone-path', position = pos}, math_random(16, 32), 50)
            create_tile_chain(surface, {name = 'stone-path', position = pos}, math_random(16, 32), 50)
        end
        return
    end
end

local function get_oil_amount(p)
    return (math_abs(p.y) * 200 + 10000) * math_random(75, 125) * 0.01
end

local function forest_look(data, rock)
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local surface = data.surface
    local entities = data.entities
    local noise_forest_location = get_forest_noise('forest_location', p, seed)

    if noise_forest_location > 0.095 then
        if noise_forest_location > 0.6 then
            if math_random(1, 100) > 42 then
                if rock then
                    entities[#entities + 1] = {name = 'rock-big', position = p}
                else
                    entities[#entities + 1] = {name = 'tree-08-brown', position = p}
                end
            end
        else
            if math_random(1, 100) > 42 then
                if rock then
                    entities[#entities + 1] = {name = 'rock-huge', position = p}
                else
                    entities[#entities + 1] = {name = 'tree-01', position = p}
                end
            end
        end
        surface.create_decoratives(
            {
                check_collision = false,
                decoratives = {
                    {
                        name = decos_inside_forest[math_random(1, #decos_inside_forest)],
                        position = p,
                        amount = math_random(1, 2)
                    }
                }
            }
        )
        return
    end

    if noise_forest_location < -0.095 then
        if noise_forest_location < -0.6 then
            if math_random(1, 100) > 42 then
                if rock then
                    entities[#entities + 1] = {name = 'sand-rock-big', position = p}
                else
                    entities[#entities + 1] = {name = 'tree-04', position = p}
                end
            end
        else
            if math_random(1, 100) > 42 then
                if rock then
                    entities[#entities + 1] = {name = 'rock-big', position = p}
                else
                    entities[#entities + 1] = {name = 'tree-02-red', position = p}
                end
            end
        end
        surface.create_decoratives(
            {
                check_collision = false,
                decoratives = {
                    {
                        name = decos_inside_forest[math_random(1, #decos_inside_forest)],
                        position = p,
                        amount = math_random(1, 2)
                    }
                }
            }
        )
        return
    end
end

local function wall(data)
    local surface = data.surface
    local left_top = data.left_top
    local seed = data.seed

    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local p = {x = left_top.x + x, y = left_top.y + y}
            local small_caves = get_noise('small_caves', p, seed)
            local cave_ponds = get_noise('cave_rivers', p, seed + 100000)
            if y > 9 + cave_ponds * 6 and y < 23 + small_caves * 6 then
                if small_caves > 0.05 or cave_ponds > 0.05 then
                    surface.set_tiles({{name = 'deepwater-green', position = p}})
                    if math_random(1, 48) == 1 then
                        surface.create_entity({name = 'fish', position = p})
                    end
                else
                    surface.set_tiles({{name = 'dirt-7', position = p}})
                    if math_random(1, 5) ~= 1 then
                        surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = p})
                    end
                end
            else
                surface.set_tiles({{name = 'dirt-7', position = p}})

                if
                    surface.can_place_entity(
                        {
                            name = 'stone-wall',
                            position = p,
                            force = 'lumber_defense',
                            destructible = true
                        }
                    )
                 then
                    if math_random(1, 512) == 1 and y > 3 and y < 28 then
                        if math_random(1, 2) == 1 then
                            Loot.add(surface, p, 'wooden-chest')
                        else
                            Loot.add(surface, p, 'steel-chest')
                        end
                    else
                        if y < 5 or y > 26 then
                            if y <= 15 then
                                if math_random(1, y + 1) == 1 then
                                    local e =
                                        surface.create_entity(
                                        {
                                            name = 'stone-wall',
                                            position = p,
                                            force = 'lumber_defense',
                                            destructible = true
                                        }
                                    )
                                    e.minable = false
                                end
                            else
                                if math_random(1, 32 - y) == 1 then
                                    local e =
                                        surface.create_entity(
                                        {
                                            name = 'stone-wall',
                                            position = p,
                                            force = 'lumber_defense',
                                            destructible = true
                                        }
                                    )
                                    e.minable = false
                                end
                            end
                        end
                    end
                end

                if math_random(1, 512) == 1 then
                    place_random_scrap_entity(surface, p)
                end

                if math_random(1, 16) == 1 then
                    if
                        surface.can_place_entity(
                            {
                                name = 'small-worm-turret',
                                position = p,
                                force = 'lumber_defense',
                                destructible = true
                            }
                        )
                     then
                        Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
                        surface.create_entity(
                            {
                                name = Biters.wave_defense_roll_worm_name(),
                                position = p,
                                force = 'lumber_defense',
                                destructible = true
                            }
                        )
                    end
                end

                if math_random(1, 32) == 1 then
                    if
                        surface.can_place_entity(
                            {
                                name = 'gun-turret',
                                position = p,
                                force = 'lumber_defense',
                                destructible = true
                            }
                        )
                     then
                        local e =
                            surface.create_entity(
                            {
                                name = 'gun-turret',
                                position = p,
                                force = 'lumber_defense',
                                destructible = true
                            }
                        )
                        if math_abs(p.y) < Public.level_depth * 2.5 then
                            e.insert({name = 'piercing-rounds-magazine', count = math_random(64, 128)})
                        else
                            e.insert({name = 'uranium-rounds-magazine', count = math_random(64, 128)})
                        end
                    end
                end
            end
        end
    end
end

local function process_level_9_position(data)
    local surface = data.surface
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local maze_p = {x = math_floor(p.x - p.x % 10), y = math_floor(p.y - p.y % 10)}
    local maze_noise = get_noise('no_rocks_2', maze_p, seed)

    if maze_noise > -0.35 and maze_noise < 0.35 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        local no_rocks_2 = get_noise('no_rocks_2', p, seed)
        if math_random(1, 2) == 1 and no_rocks_2 > -0.5 then
            if math_random(1, 2048) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end

            tiles[#tiles + 1] = {name = 'dirt-7', position = p}

            if math_random(1, 4028) == 1 then
                place_random_scrap_entity(surface, p)
            end

            forest_look(data)
        end
        if math_random(1, 1024) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        if math_random(1, 256) == 1 then
            Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
            create_inner_content(surface, p, maze_noise)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'lumber_defense',
                destructible = true
            }
        end
        return
    end

    if maze_noise > 0 and maze_noise < 0.45 then
        if math_random(1, 512) == 1 then
            markets[#markets + 1] = p
        end
        if math_random(1, 256) == 1 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end
        if math_random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. math_random(1, 9), position = p}
        end
        return
    end

    if maze_noise < -0.5 or maze_noise > 0.5 then
        tiles[#tiles + 1] = {name = 'deepwater', position = p}
        if math_random(1, 96) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    tiles[#tiles + 1] = {name = 'water', position = p}
    if math_random(1, 96) == 1 then
        entities[#entities + 1] = {name = 'fish', position = p}
    end
end

local function process_level_8_position(data)
    local surface = data.surface
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities

    local scrapyard = get_noise('scrapyard', p, seed)

    --Chasms
    local noise_cave_ponds = get_noise('cave_ponds', p, seed)
    local small_caves = get_noise('small_caves', p, seed)
    if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
        if small_caves > 0.35 then
            tiles[#tiles + 1] = {name = 'out-of-map', position = p}
            return
        end
        if small_caves < -0.35 then
            tiles[#tiles + 1] = {name = 'out-of-map', position = p}
            return
        end
    end

    if scrapyard < -0.25 or scrapyard > 0.25 then
        if math_random(1, 256) == 1 then
            entities[#entities + 1] = {
                name = 'gun-turret',
                position = p,
                force = 'lumber_defense',
                destructible = true
            }
        end
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if scrapyard < -0.55 or scrapyard > 0.55 then
            forest_look(data)
            return
        end
        if scrapyard < -0.28 or scrapyard > 0.28 then
            if math_random(1, 128) == 1 then
                Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
                create_inner_content(surface, p, scrapyard)
                entities[#entities + 1] = {
                    name = Biters.wave_defense_roll_worm_name(),
                    position = p,
                    force = 'lumber_defense',
                    destructible = true
                }
            end
            if math_random(1, 96) == 1 then
                entities[#entities + 1] = {
                    name = scrap_entities[math_random(1, scrap_entities_index)],
                    position = p,
                    force = 'lumber_defense',
                    destructible = true
                }
            end
            if math_random(1, 5) > 1 then
                forest_look(data)
            end
            if math_random(1, 256) == 1 then
                create_inner_content(surface, p, scrapyard)

                entities[#entities + 1] = {
                    name = 'land-mine',
                    position = p,
                    force = 'lumber_defense',
                    destructible = true
                }
            end
            return
        end
        return
    end

    local cave_ponds = get_noise('cave_ponds', p, seed)
    if cave_ponds < -0.6 and scrapyard > -0.2 and scrapyard < 0.2 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if math_random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    local large_caves = get_noise('large_caves', p, seed)
    if scrapyard > -0.15 and scrapyard < 0.15 then
        if math_floor(large_caves * 10) % 4 < 3 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}

            if math_random(1, 4028) == 1 then
                place_random_scrap_entity(surface, p)
            end

            forest_look(data)

            return
        end
    end

    if math_random(1, 64) == 1 and cave_ponds > 0.6 then
        entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
    end

    tiles[#tiles + 1] = {name = 'stone-path', position = p}
    if math_random(1, 256) == 1 then
        entities[#entities + 1] = {
            name = 'land-mine',
            position = p,
            force = 'lumber_defense',
            destructible = true
        }
    end
end

local function process_level_7_position(data)
    local surface = data.surface
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local cave_rivers_3 = get_noise('cave_rivers_3', p, seed)
    local cave_rivers_4 = get_noise('cave_rivers_4', p, seed + 50000)
    local no_rocks_2 = get_noise('no_rocks_2', p, seed)

    if cave_rivers_3 > -0.025 and cave_rivers_3 < 0.025 and no_rocks_2 > -0.6 then
        tiles[#tiles + 1] = {name = 'water', position = p}
        if math_random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    if cave_rivers_4 > -0.025 and cave_rivers_4 < 0.025 and no_rocks_2 > -0.6 then
        tiles[#tiles + 1] = {name = 'water', position = p}
        if math_random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    local noise_ores = get_noise('no_rocks_2', p, seed + 25000)

    if cave_rivers_3 > -0.20 and cave_rivers_3 < 0.20 then
        tiles[#tiles + 1] = {name = 'grass-' .. math_floor(cave_rivers_3 * 32) % 3 + 1, position = p}
        if cave_rivers_3 > -0.10 and cave_rivers_3 < 0.10 then
            if math_random(1, 8) == 1 and no_rocks_2 > -0.25 then
                entities[#entities + 1] = {name = 'tree-01', position = p}
            end
            if math_random(1, 2048) == 1 then
                create_inner_content(surface, p, cave_rivers_3)
                markets[#markets + 1] = p
            end
            if noise_ores < -0.5 and no_rocks_2 > -0.6 then
                if cave_rivers_3 > 0 and cave_rivers_3 < 0.07 then
                    entities[#entities + 1] = {name = 'iron-ore', position = p, amount = math_abs(p.y) + 1}
                end
            end
        end
        if math_random(1, 64) == 1 and no_rocks_2 > 0.7 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end
        if math_random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    if cave_rivers_4 > -0.20 and cave_rivers_4 < 0.20 then
        tiles[#tiles + 1] = {name = 'grass-' .. math_floor(cave_rivers_4 * 32) % 3 + 1, position = p}
        if cave_rivers_4 > -0.10 and cave_rivers_4 < 0.10 then
            if math_random(1, 8) == 1 and no_rocks_2 > -0.25 then
                entities[#entities + 1] = {name = 'tree-02', position = p}
            end
            if math_random(1, 2048) == 1 then
                markets[#markets + 1] = p
            end
            if noise_ores < -0.5 and no_rocks_2 > -0.6 then
                if cave_rivers_4 > 0 and cave_rivers_4 < 0.07 then
                    create_inner_content(surface, p, noise_ores)
                    entities[#entities + 1] = {name = 'copper-ore', position = p, amount = math_abs(p.y) + 1}
                end
            end
        end
        if math_random(1, 64) == 1 and no_rocks_2 > 0.7 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end
        if math_random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    --Chasms
    local noise_cave_ponds = get_noise('cave_ponds', p, seed)
    local small_caves = get_noise('small_caves', p, seed)
    if noise_cave_ponds < 0.25 and noise_cave_ponds > -0.25 then
        if small_caves > 0.55 then
            tiles[#tiles + 1] = {name = 'out-of-map', position = p}
            return
        end
        if small_caves < -0.55 then
            tiles[#tiles + 1] = {name = 'out-of-map', position = p}
            return
        end
    end

    if math_random(1, 2048) == 1 then
        treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
    end

    tiles[#tiles + 1] = {name = 'dirt-7', position = p}

    if math_random(1, 4028) == 1 then
        place_random_scrap_entity(surface, p)
    end

    forest_look(data)
end

local function process_level_6_position(data)
    local surface = data.surface
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local treasure = data.treasure

    local large_caves = get_noise('large_caves', p, seed)
    local noise_cave_ponds = get_noise('cave_ponds', p, seed)

    if large_caves > -0.14 and large_caves < 0.14 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        --tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
        if math_random(1, 768) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    if large_caves < -0.47 or large_caves > 0.47 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if math_random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        if math_random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
            create_inner_content(surface, p, noise_cave_ponds)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'lumber_defense',
                destructible = true
            }
        end
        return
    end

    if large_caves > -0.30 and large_caves < 0.30 then
        if noise_cave_ponds > 0.35 then
            tiles[#tiles + 1] = {name = 'dirt-' .. math_random(1, 4), position = p}
            --tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
            if math_random(1, 256) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            if math_random(1, 256) == 1 then
                entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
            end
            return
        end
        if noise_cave_ponds > 0.25 then
            if math_random(1, 2048) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end

            tiles[#tiles + 1] = {name = 'dirt-7', position = p}

            if math_random(1, 4028) == 1 then
                place_random_scrap_entity(surface, p)
            end

            if math_random(1, 100) > 25 then
                if math_random(1, 4) == 1 then
                    forest_look(data, true)
                else
                    forest_look(data)
                end
            end
        end
    end
end

local function process_level_5_position(data)
    local surface = data.surface
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local treasure = data.treasure

    local small_caves = get_noise('small_caves', p, seed)
    local noise_cave_ponds = get_noise('cave_ponds', p, seed)

    if small_caves > -0.14 and small_caves < 0.14 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        --tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
        if math_random(1, 768) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    if small_caves < -0.50 or small_caves > 0.50 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if math_random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        if math_random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
            create_inner_content(surface, p, noise_cave_ponds)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'lumber_defense',
                destructible = true
            }
        end
        return
    end

    if small_caves > -0.30 and small_caves < 0.30 then
        if noise_cave_ponds > 0.35 then
            tiles[#tiles + 1] = {name = 'dirt-' .. math_random(1, 4), position = p}
            --tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
            if math_random(1, 256) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            if math_random(1, 256) == 1 then
                entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
            end
            return
        end
        if noise_cave_ponds > 0.25 then
            if math_random(1, 2048) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end

            tiles[#tiles + 1] = {name = 'dirt-7', position = p}

            if math_random(1, 4028) == 1 then
                place_random_scrap_entity(surface, p)
            end

            if math_random(1, 100) > 25 then
                if math_random(1, 8) == 1 then
                    forest_look(data, true)
                else
                    forest_look(data)
                end
            end
        end
    end
    tiles[#tiles + 1] = {name = 'out-of-map', position = p}
end

local function process_level_4_position(data)
    local surface = data.surface
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local noise_large_caves = get_noise('large_caves', p, seed)
    local noise_cave_ponds = get_noise('cave_ponds', p, seed)
    local small_caves = get_noise('small_caves', p, seed)

    if math_abs(noise_large_caves) > 0.7 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if math_random(1, 16) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end
    if math_abs(noise_large_caves) > 0.6 then
        if math_random(1, 16) == 1 then
            entities[#entities + 1] = {name = trees[math_random(1, #trees)], position = p}
        end
        if math_random(1, 32) == 1 then
            markets[#markets + 1] = p
        end
    end
    if math_abs(noise_large_caves) > 0.5 then
        tiles[#tiles + 1] = {name = 'grass-2', position = p}
        if math_random(1, 620) == 1 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end
        if math_random(1, 384) == 1 then
            create_inner_content(surface, p, noise_cave_ponds)
            Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'lumber_defense',
                destructible = true
            }
        end
        if math_random(1, 1024) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end
    if math_abs(noise_large_caves) > 0.475 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        --tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
        if math_random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    --Chasms
    if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
        if small_caves > 0.75 then
            tiles[#tiles + 1] = {name = 'out-of-map', position = p}
            return
        end
        if small_caves < -0.75 then
            tiles[#tiles + 1] = {name = 'out-of-map', position = p}
            return
        end
    end

    if small_caves > -0.15 and small_caves < 0.15 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        --tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
        if math_random(1, 1024) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    if noise_large_caves > -0.1 and noise_large_caves < 0.1 then
        --Main Terrain
        local no_rocks_2 = get_noise('no_rocks_2', p, seed + 75000)
        if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
            --tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
            tiles[#tiles + 1] = {name = 'dirt-' .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
            if math_random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            return
        end

        if math_random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end

        tiles[#tiles + 1] = {name = 'dirt-7', position = p}

        if math_random(1, 4028) == 1 then
            place_random_scrap_entity(surface, p)
        end

        if math_random(1, 100) > 25 then
            if math_random(1, 8) == 1 then
                forest_look(data, true)
            else
                forest_look(data)
            end
        end
    end
    tiles[#tiles + 1] = {name = 'out-of-map', position = p}
end

local function process_level_3_position(data)
    local surface = data.surface
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local small_caves = get_noise('small_caves', p, seed + 50000)
    local small_caves_2 = get_noise('small_caves_2', p, seed + 70000)
    local noise_large_caves = get_noise('large_caves', p, seed + 60000)
    local noise_cave_ponds = get_noise('cave_ponds', p, seed)

    --Market Spots
    if noise_cave_ponds < -0.77 then
        if noise_cave_ponds > -0.79 then
            --tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        else
            tiles[#tiles + 1] = {name = 'grass-' .. math_floor(noise_cave_ponds * 32) % 3 + 1, position = p}
            if math_random(1, 32) == 1 then
                markets[#markets + 1] = p
            end
            if math_random(1, 16) == 1 then
                entities[#entities + 1] = {name = trees[math_random(1, #trees)], position = p}
            end
        end
        return
    end

    if noise_large_caves > -0.2 and noise_large_caves < 0.2 or small_caves_2 > 0 then
        --Green Water Ponds
        if noise_cave_ponds > 0.80 then
            tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
            if math_random(1, 16) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
            return
        end

        --Chasms
        if noise_cave_ponds < 0.12 and noise_cave_ponds > -0.12 then
            if small_caves > 0.85 then
                tiles[#tiles + 1] = {name = 'out-of-map', position = p}
                return
            end
            if small_caves < -0.85 then
                tiles[#tiles + 1] = {name = 'out-of-map', position = p}
                return
            end
        end

        --Rivers
        local cave_rivers = get_noise('cave_rivers', p, seed + 100000)
        if cave_rivers < 0.014 and cave_rivers > -0.014 then
            if noise_cave_ponds > 0.2 then
                tiles[#tiles + 1] = {name = 'water-shallow', position = p}
                if math_random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'fish', position = p}
                end
                return
            end
        end
        local cave_rivers_2 = get_noise('cave_rivers_2', p, seed)
        if cave_rivers_2 < 0.024 and cave_rivers_2 > -0.024 then
            if noise_cave_ponds < 0.5 then
                tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
                if math_random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'fish', position = p}
                end
                return
            end
        end

        if noise_cave_ponds > 0.775 then
            tiles[#tiles + 1] = {name = 'dirt-' .. math_random(4, 6), position = p}
            --tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
            return
        end

        local no_rocks = get_noise('no_rocks', p, seed + 25000)
        --Worm oil Zones
        if no_rocks < 0.15 and no_rocks > -0.15 then
            if small_caves > 0.35 then
                --tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
                tiles[#tiles + 1] = {name = 'dirt-' .. math_floor(noise_cave_ponds * 32) % 7 + 1, position = p}
                if math_random(1, 320) == 1 then
                    entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
                end
                if math_random(1, 50) == 1 then
                    Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
                    create_inner_content(surface, p, noise_cave_ponds)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'lumber_defense',
                        destructible = true
                    }
                end
                if math_random(1, 512) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
                end
                if math_random(1, 64) == 1 then
                    entities[#entities + 1] = {name = trees[math_random(1, #trees)], position = p}
                end
                return
            end
        end

        --Main Terrain
        local no_rocks_2 = get_noise('no_rocks_2', p, seed + 75000)
        if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
            tiles[#tiles + 1] = {name = 'dirt-' .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
            --tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
            if math_random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            return
        end

        if math_random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end

        tiles[#tiles + 1] = {name = 'dirt-7', position = p}

        if math_random(1, 4028) == 1 then
            place_random_scrap_entity(surface, p)
        end

        if math_random(1, 100) > 25 then
            if math_random(1, 8) == 1 then
                forest_look(data, true)
            else
                forest_look(data)
            end
        end
    end
    tiles[#tiles + 1] = {name = 'out-of-map', position = p}
end

local function process_level_2_position(data)
    local surface = data.surface
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local small_caves = get_noise('small_caves', p, seed)
    local noise_large_caves = get_noise('large_caves', p, seed)

    if noise_large_caves > -0.75 and noise_large_caves < 0.75 then
        local noise_cave_ponds = get_noise('cave_ponds', p, seed)

        --Chasms
        if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
            if small_caves > 0.32 then
                tiles[#tiles + 1] = {name = 'out-of-map', position = p}
                return
            end
            if small_caves < -0.32 then
                tiles[#tiles + 1] = {name = 'out-of-map', position = p}
                return
            end
        end

        --Green Water Ponds
        if noise_cave_ponds > 0.80 then
            tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
            if math_random(1, 16) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
            return
        end

        --Rivers
        local cave_rivers = get_noise('cave_rivers', p, seed + 100000)
        if cave_rivers < 0.027 and cave_rivers > -0.027 then
            if noise_cave_ponds < 0.1 then
                tiles[#tiles + 1] = {name = 'water-shallow', position = p}
                if math_random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'fish', position = p}
                end
                return
            end
        end

        if noise_cave_ponds > 0.76 then
            tiles[#tiles + 1] = {name = 'dirt-' .. math_random(4, 6), position = p}
            --tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
            return
        end

        --Market Spots
        if noise_cave_ponds < -0.80 then
            create_inner_content(surface, p, noise_cave_ponds)
            tiles[#tiles + 1] = {name = 'grass-' .. math_floor(noise_cave_ponds * 32) % 3 + 1, position = p}
            if math_random(1, 32) == 1 then
                markets[#markets + 1] = p
            end
            if math_random(1, 16) == 1 then
                forest_look(data, true)
            end
            return
        end

        local no_rocks = get_noise('no_rocks', p, seed + 25000)
        --Worm oil Zones
        if no_rocks < 0.15 and no_rocks > -0.15 then
            if small_caves > 0.35 then
                tiles[#tiles + 1] = {name = 'dirt-' .. math_floor(noise_cave_ponds * 32) % 7 + 1, position = p}
                --tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
                if math_random(1, 450) == 1 then
                    entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
                end
                if math_random(1, 64) == 1 then
                    Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'lumber_defense',
                        destructible = true
                    }
                end
                if math_random(1, 64) == 1 then
                    entities[#entities + 1] = {name = trees[math_random(1, #trees)], position = p}
                end
                return
            end
        end

        --Main Terrain
        local no_rocks_2 = get_noise('no_rocks_2', p, seed + 75000)
        if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
            tiles[#tiles + 1] = {name = 'dirt-' .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
            --tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
            if math_random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            return
        end

        if math_random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end

        tiles[#tiles + 1] = {name = 'dirt-7', position = p}

        if math_random(1, 4028) == 1 then
            place_random_scrap_entity(surface, p)
        end

        if math_random(1, 100) > 25 then
            if math_random(1, 8) == 1 then
                forest_look(data, true)
            else
                forest_look(data)
            end
        end
    end
end

local function process_level_1_position(data)
    local surface = data.surface
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local small_caves = get_noise('small_caves', p, seed)

    local noise_cave_ponds = get_noise('cave_ponds', p, seed)

    local cave_worms = get_noise('cave_worms', p, seed)

    if cave_worms < 0.12 and cave_worms > -0.12 then
        if small_caves > 0.55 then
            tiles[#tiles + 1] = {name = 'water-shallow', position = p}
            return
        end
        if small_caves < -0.55 then
            tiles[#tiles + 1] = {name = 'water-shallow', position = p}
            return
        end
    end
    --Green Water Ponds
    if noise_cave_ponds > 0.80 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if math_random(1, 16) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end
    --Rivers
    local cave_rivers = get_noise('cave_rivers', p, seed + 100000)
    if cave_rivers < 0.024 and cave_rivers > -0.024 then
        if noise_cave_ponds > 0 then
            tiles[#tiles + 1] = {name = 'water-shallow', position = p}
            if math_random(1, 64) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
            return
        end
    end

    if noise_cave_ponds > 0.76 then
        --tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
        --tiles[#tiles + 1] = {name = 'dirt-' .. math_random(4, 6), position = p}
        tiles[#tiles + 1] = {name = 'stone-path', position = p}

        return
    end

    --Market Spots
    if noise_cave_ponds < -0.75 then
        tiles[#tiles + 1] = {name = 'grass-' .. math_floor(noise_cave_ponds * 32) % 3 + 1, position = p}
        if math_random(1, 32) == 1 then
            markets[#markets + 1] = p
        end
        if math_random(1, 32) == 1 then
            entities[#entities + 1] = {name = trees[math_random(1, #trees)], position = p}
        end
        create_inner_content(surface, p, noise_cave_ponds)
        return
    end

    local no_rocks = get_noise('no_rocks', p, seed + 25000)
    --Worm oil Zones
    if p.y < -64 + noise_cave_ponds * 10 then
        if no_rocks < 0.08 and no_rocks > -0.08 then
            if small_caves > 0.35 then
                --tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
                tiles[#tiles + 1] = {name = 'dirt-' .. math_floor(noise_cave_ponds * 32) % 7 + 1, position = p}
                if math_random(1, 450) == 1 then
                    entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
                end
                if math_random(1, 96) == 1 then
                    Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'lumber_defense',
                        destructible = true
                    }
                end
                if math_random(1, 1024) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
                end
                if math_random(1, 64) == 1 then
                    entities[#entities + 1] = {name = trees[math_random(1, #trees)], position = p}
                end
                return
            end
        end
    end

    --Main Terrain
    local no_rocks_2 = get_noise('no_rocks_2', p, seed + 75000)

    if no_rocks_2 > 0.70 or no_rocks_2 < -0.70 then
        --tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
        tiles[#tiles + 1] = {name = 'dirt-' .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
        if math_random(1, 32) == 1 then
            entities[#entities + 1] = {name = trees[math_random(1, #trees)], position = p}
        end
        if math_random(1, 512) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    if math_random(1, 2048) == 1 then
        treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
    end

    tiles[#tiles + 1] = {name = 'dirt-7', position = p}

    if math_random(1, 4028) == 1 then
        place_random_scrap_entity(surface, p)
    end

    if math_random(1, 100) > 25 then
        if math_random(1, 8) == 1 then
            forest_look(data, true)
        else
            forest_look(data)
        end
    end
end

Public.levels = {
    process_level_1_position,
    process_level_2_position,
    process_level_3_position,
    process_level_4_position,
    process_level_5_position,
    process_level_6_position,
    process_level_7_position,
    process_level_8_position,
    process_level_9_position
}

local function is_out_of_map(p)
    if p.x < 196 and p.x >= -196 then
        return
    end
    if p.y * 0.5 >= math_abs(p.x) then
        return
    end
    if p.y * -0.5 > math_abs(p.x) then
        return
    end
    return true
end

local function process_bits(_, _, data)
    local left_top_y = data.area.left_top.y
    local index = math_floor((math_abs(left_top_y / Public.level_depth)) % 11) + 1
    local process_level = Public.levels[index]
    if not process_level then
        process_level = Public.levels[#Public.levels]
    end

    if not is_out_of_map({x = data.x, y = data.y}) then
        process_level(data)
    end
end

local function border_chunk(data)
    local surface = data.surface
    local left_top = data.left_top

    for x = 0, 31, 1 do
        for y = 5, 31, 1 do
            local pos = {x = left_top.x + x, y = left_top.y + y}
            if math_random(1, math.ceil(pos.y + pos.y) + 64) == 1 then
                surface.create_entity({name = trees[math_random(1, #trees)], position = pos})
            end
        end
    end

    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local pos = {x = left_top.x + x, y = left_top.y + y}
            if not is_out_of_map(pos) then
                if math_random(1, math.ceil(pos.y + pos.y) + 32) == 1 then
                    surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = pos})
                end
                if math_random(1, pos.y + 23) == 1 then
                    surface.create_entity {
                        name = remnants[math_random(1, remnants_index)],
                        position = pos,
                        amount = 1
                    }
                end
                if math_random(1, pos.y + 2) == 1 then
                    surface.create_decoratives {
                        check_collision = false,
                        decoratives = {
                            {name = 'rock-small', position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))}
                        }
                    }
                end
                if math_random(1, pos.y + 2) == 1 then
                    surface.create_decoratives {
                        check_collision = false,
                        decoratives = {
                            {name = 'rock-tiny', position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))}
                        }
                    }
                end
            end
        end
    end

    for _, e in pairs(
        surface.find_entities_filtered(
            {area = {{left_top.x, left_top.y}, {left_top.x + 32, left_top.y + 32}}, type = 'cliff'}
        )
    ) do
        e.destroy()
    end
end

local function replace_water(data)
    local surface = data.surface
    local left_top = data.left_top

    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local p = {x = left_top.x + x, y = left_top.y + y}
            if surface.get_tile(p).collides_with('resource-layer') then
                surface.set_tiles({{name = 'dirt-' .. math_random(1, 5), position = p}}, true)
            end
        end
    end
end

local function out_of_map_area(data)
    local surface = data.surface
    local left_top = data.left_top

    for x = -1, 32, 1 do
        for y = -1, 32, 1 do
            local p = {x = left_top.x + x, y = left_top.y + y}
            if is_out_of_map(p) then
                surface.set_tiles({{name = 'out-of-map', position = p}}, true)
            end
        end
    end
end

local function biter_chunk(data)
    local surface = data.surface
    local left_top = data.left_top

    local tile_positions = {}
    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local p = {x = left_top.x + x, y = left_top.y + y}
            tile_positions[#tile_positions + 1] = p
        end
    end

    for i = 1, 1, 1 do
        local position =
            surface.find_non_colliding_position('biter-spawner', tile_positions[math_random(1, #tile_positions)], 16, 2)
        if position then
            local e =
                surface.create_entity(
                {name = spawner_raffle[math_random(1, #spawner_raffle)], position = position, force = 'enemy'}
            )
            e.destructible = false
            e.active = false
        end
    end

    for i = 1, 3, 1 do
        local position =
            surface.find_non_colliding_position(
            'big-worm-turret',
            tile_positions[math_random(1, #tile_positions)],
            16,
            2
        )
        if position then
            local e = surface.create_entity({name = 'big-worm-turret', position = position, force = 'enemy'})
            e.destructible = false
        end
    end
end

local function out_of_map(data)
    local surface = data.surface
    local left_top = data.left_top
    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            surface.set_tiles({{name = 'out-of-map', position = {x = left_top.x + x, y = left_top.y + y}}})
        end
    end
end

local function on_chunk_generated(event)
    local this = WPT.get_table()
    local map_name = 'lumberjack'

    if string.sub(event.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local surface = event.surface
    local seed = surface.map_gen_settings.seed
    local position = this.locomotive.position
    local left_top = event.area.left_top

    local data = {
        surface = surface,
        seed = seed,
        position = position,
        reveal = 23,
        left_top = left_top
    }

    if left_top.x >= Public.level_depth * 0.5 then
        out_of_map(data)
        return
    end
    if left_top.x < Public.level_depth * -0.5 then
        out_of_map(data)
        return
    end

    if left_top.y % Public.level_depth == 0 and left_top.y < 0 then
        this.left_top = data.left_top
        wall(data)
        return
    end

    if left_top.y > 150 then
        out_of_map(data)
        return
    end

    if left_top.y > 75 then
        biter_chunk(data)
    end
    if left_top.y > 32 then
        game.forces.player.chart(surface, {{left_top.x, left_top.y}, {left_top.x + 31, left_top.y + 31}})
    end

    if left_top.y >= 0 then
        replace_water(data)
    end

    if left_top.y >= 0 then
        border_chunk(data)
    end

    if left_top.y < -50 then
        if math_random(1, chance_for_wagon_spawn) == 1 then
            place_wagon(data)
        end
    end

    out_of_map_area(data)
end

function Public.heavy_functions(x, y, data)
    local area = data.area
    local top_y = area.left_top.y

    data.seed = data.surface.map_gen_settings.seed

    if top_y % Public.level_depth == 0 and top_y < 0 then
        return
    end

    if top_y < 0 then
        process_bits(x, y, data)
    end
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)

return Public
