local Biters = require 'modules.wave_defense.biter_rolls'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local Event = require 'utils.event'
local WPT = require 'maps.mountain_fortress_v3.table'
local Loot = require 'maps.mountain_fortress_v3.loot'
local get_noise = require 'utils.get_noise'

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

local size_of_rock_raffle = #rock_raffle

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

local spawner_raffle = {'biter-spawner', 'biter-spawner', 'biter-spawner', 'spitter-spawner'}
local trees = {'dead-grey-trunk', 'dead-grey-trunk', 'dry-tree'}

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
        for _, e in pairs(surface.find_entities_filtered({position = tile.position, force = {'neutral', 'enemy'}})) do
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

local function get_oil_amount(p)
    return (math_abs(p.y) * 200 + 10000) * math_random(75, 125) * 0.01
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
                            force = 'enemy',
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
                                            force = 'enemy',
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
                                            force = 'enemy',
                                            destructible = true
                                        }
                                    )
                                    e.minable = false
                                end
                            end
                        end
                    end
                end

                if math_random(1, 16) == 1 then
                    if
                        surface.can_place_entity(
                            {
                                name = 'small-worm-turret',
                                position = p,
                                force = 'enemy',
                                destructible = true
                            }
                        )
                     then
                        Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
                        surface.create_entity(
                            {
                                name = Biters.wave_defense_roll_worm_name(),
                                position = p,
                                force = 'enemy',
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
                                force = 'enemy',
                                destructible = true
                            }
                        )
                     then
                        local e =
                            surface.create_entity(
                            {
                                name = 'gun-turret',
                                position = p,
                                force = 'enemy',
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

local function process_level_11_position(data)
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local noise_1 = get_noise('small_caves', p, seed)
    local noise_2 = get_noise('no_rocks_2', p, seed + 10000)

    if noise_1 > 0.7 then
        tiles[#tiles + 1] = {name = 'water', position = p}
        if math_random(1, 48) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    if noise_1 < -0.72 then
        tiles[#tiles + 1] = {name = 'lab-dark-1', position = p}
        entities[#entities + 1] = {name = 'uranium-ore', position = p, amount = math_abs(p.y) + 1 * 3}
        return
    end

    if noise_1 > -0.30 and noise_1 < 0.30 then
        if noise_1 > -0.14 and noise_1 < 0.14 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            if math_random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
            end
            if math_random(1, 256) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
        else
            tiles[#tiles + 1] = {name = 'out-of-map', position = p}
        end
        return
    end

    if math_random(1, 64) == 1 and noise_2 > 0.65 then
        entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
    end
    if math_random(1, 8192) == 1 then
        markets[#markets + 1] = p
    end
    if math_random(1, 1024) == 1 then
        entities[#entities + 1] = {name = 'crash-site-chest-' .. math_random(1, 2), position = p, force = 'neutral'}
    end

    tiles[#tiles + 1] = {name = 'tutorial-grid', position = p}
end

local function process_level_10_position(data)
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local treasure = data.treasure

    local scrapyard = get_noise('scrapyard', p, seed)

    if scrapyard < -0.70 or scrapyard > 0.70 then
        tiles[#tiles + 1] = {name = 'grass-3', position = p}
        if math_random(1, 40) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    if scrapyard < -0.65 or scrapyard > 0.65 then
        tiles[#tiles + 1] = {name = 'water-green', position = p}
        return
    end
    if math_abs(scrapyard) > 0.40 and math_abs(scrapyard) < 0.65 then
        if math_random(1, 64) == 1 then
            Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
        end
        tiles[#tiles + 1] = {name = 'water-mud', position = p}
        return
    end
    if math_abs(scrapyard) > 0.25 and math_abs(scrapyard) < 0.40 then
        if math_random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
        end
        tiles[#tiles + 1] = {name = 'water-shallow', position = p}
        return
    end
    if scrapyard > -0.15 and scrapyard < 0.15 then
        if math_random(1, 100) > 88 then
            entities[#entities + 1] = {name = 'tree-0' .. math_random(1, 9), position = p}
        else
            if math_random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
            end
        end
        tiles[#tiles + 1] = {name = 'dirt-6', position = p}
        return
    end
    tiles[#tiles + 1] = {name = 'grass-2', position = p}
end

local function process_level_9_position(data)
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
            entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
        end
        if math_random(1, 1024) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        if math_random(1, 256) == 1 then
            Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
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

--SCRAPYARD
local function process_level_8_position(data)
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
            entities[#entities + 1] = {name = 'gun-turret', position = p, force = 'enemy'}
        end
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if scrapyard < -0.55 or scrapyard > 0.55 then
            if math_random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
            end
            return
        end
        if scrapyard < -0.28 or scrapyard > 0.28 then
            if math_random(1, 128) == 1 then
                Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
                entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
            end
            if math_random(1, 96) == 1 then
                entities[#entities + 1] = {
                    name = scrap_entities[math_random(1, scrap_entities_index)],
                    position = p,
                    force = 'enemy'
                }
            end
            if math_random(1, 5) > 1 then
                entities[#entities + 1] = {name = 'mineable-wreckage', position = p}
            end
            if math_random(1, 256) == 1 then
                entities[#entities + 1] = {name = 'land-mine', position = p, force = 'enemy'}
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
            if math_random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
            end
            return
        end
    end

    if math_random(1, 64) == 1 and cave_ponds > 0.6 then
        entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
    end

    tiles[#tiles + 1] = {name = 'stone-path', position = p}
    if math_random(1, 256) == 1 then
        entities[#entities + 1] = {name = 'land-mine', position = p, force = 'enemy'}
    end
end

local function process_level_7_position(data)
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

    tiles[#tiles + 1] = {name = 'dirt-7', position = p}
    if math_random(1, 100) > 15 then
        entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
    end
    if math_random(1, 256) == 1 then
        treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
    end
end

local function process_level_6_position(data)
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local large_caves = get_noise('large_caves', p, seed)
    local cave_rivers = get_noise('cave_rivers', p, seed)

    --Chasms
    local noise_cave_ponds = get_noise('cave_ponds', p, seed)
    local small_caves = get_noise('small_caves', p, seed)
    if noise_cave_ponds < 0.45 and noise_cave_ponds > -0.45 then
        if small_caves > 0.45 then
            tiles[#tiles + 1] = {name = 'out-of-map', position = p}
            return
        end
        if small_caves < -0.45 then
            tiles[#tiles + 1] = {name = 'out-of-map', position = p}
            return
        end
    end

    if large_caves > -0.03 and large_caves < 0.03 and cave_rivers < 0.25 then
        tiles[#tiles + 1] = {name = 'water-green', position = p}
        if math_random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    if cave_rivers > -0.1 and cave_rivers < 0.1 then
        if math_random(1, 36) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. math_random(1, 9), position = p}
        end
        if math_random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
        end
    else
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if math_random(1, 100) > 15 then
            entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
        end
        if math_random(1, 512) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        if math_random(1, 4096) == 1 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end
        if math_random(1, 8096) == 1 then
            markets[#markets + 1] = p
        end
    end
end

local function process_level_5_position(data)
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local treasure = data.treasure

    local small_caves = get_noise('small_caves', p, seed)
    local noise_cave_ponds = get_noise('cave_ponds', p, seed)

    if small_caves > -0.24 and small_caves < 0.24 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if math_random(1, 768) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        if math_random(1, 2) == 1 then
            entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
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
            entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
        end
        return
    end

    if small_caves > -0.40 and small_caves < 0.40 then
        if noise_cave_ponds > 0.35 then
            tiles[#tiles + 1] = {name = 'dirt-' .. math_random(1, 4), position = p}
            if math_random(1, 256) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            if math_random(1, 256) == 1 then
                entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
            end
            return
        end
        if noise_cave_ponds > 0.25 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            if math_random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            if math_random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
            end
            return
        end
    end

    tiles[#tiles + 1] = {name = 'out-of-map', position = p}
end

local function process_level_4_position(data)
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
        tiles[#tiles + 1] = {name = 'water', position = p}
        if math_random(1, 16) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end
    if math_abs(noise_large_caves) > 0.6 then
        if math_random(1, 16) == 1 then
            entities[#entities + 1] = {name = 'tree-02', position = p}
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
            Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
        end
        if math_random(1, 1024) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end
    if math_abs(noise_large_caves) > 0.475 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if math_random(1, 2) == 1 then
            entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
        end
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
        if math_random(1, 2) == 1 then
            entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
        end
        if math_random(1, 1024) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    if noise_large_caves > -0.2 and noise_large_caves < 0.2 then
        --Main Rock Terrain
        local no_rocks_2 = get_noise('no_rocks_2', p, seed + 75000)
        if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
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
        if math_random(1, 100) > 30 then
            entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
        end
        return
    end

    tiles[#tiles + 1] = {name = 'out-of-map', position = p}
end

local function process_level_3_position(data)
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
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
        else
            tiles[#tiles + 1] = {name = 'grass-' .. math_floor(noise_cave_ponds * 32) % 3 + 1, position = p}
            if math_random(1, 32) == 1 then
                markets[#markets + 1] = p
            end
            if math_random(1, 16) == 1 then
                entities[#entities + 1] = {name = 'tree-0' .. math_random(1, 9), position = p}
            end
        end
        return
    end

    if noise_large_caves > -0.15 and noise_large_caves < 0.15 or small_caves_2 > 0 then
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
        if cave_rivers < 0.024 and cave_rivers > -0.024 then
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
            if noise_cave_ponds < 0.4 then
                tiles[#tiles + 1] = {name = 'water-shallow', position = p}
                if math_random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'fish', position = p}
                end
                return
            end
        end

        if noise_cave_ponds > 0.725 then
            tiles[#tiles + 1] = {name = 'dirt-' .. math_random(4, 6), position = p}
            return
        end

        local no_rocks = get_noise('no_rocks', p, seed + 25000)
        --Worm oil Zones
        if no_rocks < 0.20 and no_rocks > -0.20 then
            if small_caves > 0.35 then
                tiles[#tiles + 1] = {name = 'dirt-' .. math_floor(noise_cave_ponds * 32) % 7 + 1, position = p}
                if math_random(1, 320) == 1 then
                    entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
                end
                if math_random(1, 50) == 1 then
                    Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy'
                    }
                end
                if math_random(1, 512) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
                end
                if math_random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'dead-tree-desert', position = p}
                end
                return
            end
        end

        --Main Rock Terrain
        local no_rocks_2 = get_noise('no_rocks_2', p, seed + 75000)
        if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
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
        if math_random(1, 100) > 30 then
            entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
        end
        return
    end

    tiles[#tiles + 1] = {name = 'out-of-map', position = p}
end

local function process_level_2_position(data)
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
        if cave_rivers < 0.037 and cave_rivers > -0.037 then
            if noise_cave_ponds < 0.1 then
                tiles[#tiles + 1] = {name = 'water-shallow', position = p}
                if math_random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'fish', position = p}
                end
                return
            end
        end

        if noise_cave_ponds > 0.66 then
            tiles[#tiles + 1] = {name = 'dirt-' .. math_random(4, 6), position = p}
            return
        end

        --Market Spots
        if noise_cave_ponds < -0.80 then
            tiles[#tiles + 1] = {name = 'grass-' .. math_floor(noise_cave_ponds * 32) % 3 + 1, position = p}
            if math_random(1, 32) == 1 then
                markets[#markets + 1] = p
            end
            if math_random(1, 16) == 1 then
                entities[#entities + 1] = {name = 'tree-0' .. math_random(1, 9), position = p}
            end
            return
        end

        local no_rocks = get_noise('no_rocks', p, seed + 25000)
        --Worm oil Zones
        if no_rocks < 0.20 and no_rocks > -0.20 then
            if small_caves > 0.30 then
                tiles[#tiles + 1] = {name = 'dirt-' .. math_floor(noise_cave_ponds * 32) % 7 + 1, position = p}
                if math_random(1, 450) == 1 then
                    entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
                end
                if math_random(1, 64) == 1 then
                    Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy'
                    }
                end
                if math_random(1, 1024) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
                end
                if math_random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'dead-tree-desert', position = p}
                end
                return
            end
        end

        --Main Rock Terrain
        local no_rocks_2 = get_noise('no_rocks_2', p, seed + 75000)
        if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
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
        if math_random(1, 100) > 25 then
            entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
        end
        return
    end

    tiles[#tiles + 1] = {name = 'out-of-map', position = p}
end

local function process_level_1_position(data)
    local p = {x = data.x, y = data.y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local small_caves = get_noise('small_caves', p, seed)

    local noise_cave_ponds = get_noise('cave_ponds', p, seed)

    --Chasms
    if noise_cave_ponds < 0.12 and noise_cave_ponds > -0.12 then
        if small_caves > 0.55 then
            tiles[#tiles + 1] = {name = 'out-of-map', position = p}
            return
        end
        if small_caves < -0.55 then
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
    if cave_rivers < 0.044 and cave_rivers > -0.044 then
        if noise_cave_ponds > 0 then
            tiles[#tiles + 1] = {name = 'water-shallow', position = p}
            if math_random(1, 64) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
            return
        end
    end

    if noise_cave_ponds > 0.76 then
        tiles[#tiles + 1] = {name = 'dirt-' .. math_random(4, 6), position = p}
        return
    end

    --Market Spots
    if noise_cave_ponds < -0.75 then
        tiles[#tiles + 1] = {name = 'grass-' .. math_floor(noise_cave_ponds * 32) % 3 + 1, position = p}
        if math_random(1, 32) == 1 then
            markets[#markets + 1] = p
        end
        if math_random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. math_random(1, 9), position = p}
        end
        return
    end

    local no_rocks = get_noise('no_rocks', p, seed + 25000)
    --Worm oil Zones
    if p.y < -64 + noise_cave_ponds * 10 then
        if no_rocks < 0.12 and no_rocks > -0.12 then
            if small_caves > 0.30 then
                tiles[#tiles + 1] = {name = 'dirt-' .. math_floor(noise_cave_ponds * 32) % 7 + 1, position = p}
                if math_random(1, 450) == 1 then
                    entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
                end
                if math_random(1, 96) == 1 then
                    Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy'
                    }
                end
                if math_random(1, 1024) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
                end
                if math_random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'dead-tree-desert', position = p}
                end
                return
            end
        end
    end

    --Main Rock Terrain
    local no_rocks_2 = get_noise('no_rocks_2', p, seed + 75000)
    if no_rocks_2 > 0.65 or no_rocks_2 < -0.65 then
        tiles[#tiles + 1] = {name = 'dirt-' .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
        if math_random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'dead-tree-desert', position = p}
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
    if math_random(1, 100) > 25 then
        entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
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
    process_level_9_position,
    process_level_10_position,
    process_level_11_position
}

local function is_out_of_map(p)
    if p.x < 480 and p.x >= -480 then
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
        for y = 0, 31, 1 do
            local pos = {x = left_top.x + x, y = left_top.y + y}
            local p = {x = left_top.x + x, y = left_top.y + y}
            if math_random(1, math.ceil(p.y + p.y) + 64) == 1 then
                surface.create_entity({name = trees[math_random(1, #trees)], position = p})
            end
            if not is_out_of_map(pos) then
                if math_random(1, math.ceil(pos.y + pos.y) + 32) == 1 then
                    surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = pos})
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

local function on_chunk_generated(event)
    local map_name = 'mountain_fortress_v3'

    if string.sub(event.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local surface = event.surface
    local seed = surface.map_gen_settings.seed
    local position = WPT.get_table().locomotive.position
    local left_top = event.area.left_top

    local data = {
        surface = surface,
        seed = seed,
        position = position,
        left_top = left_top
    }

    if left_top.x >= Public.level_depth * 0.5 then
        return
    end
    if left_top.x < Public.level_depth * -0.5 then
        return
    end

    if left_top.y % Public.level_depth == 0 and left_top.y < 0 then
        WPT.get_table().left_top = data.left_top
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

    if left_top.y == -128 and left_top.x == -128 then
        local p = WPT.get_table().locomotive.position
        for _, entity in pairs(
            surface.find_entities_filtered({area = {{p.x - 3, p.y - 4}, {p.x + 3, p.y + 10}}, type = 'simple-entity'})
        ) do
            entity.destroy()
        end
    end

    if left_top.y < -256 then
        if math_random(1, chance_for_wagon_spawn) == 1 then
            place_wagon(data)
        end
    end

    --out_of_map_area(data)
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)

return Public
