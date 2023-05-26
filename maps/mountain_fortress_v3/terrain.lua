local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local Biters = require 'modules.wave_defense.biter_rolls'

local random = math.random
local abs = math.abs
local floor = math.floor
local ceil = math.ceil

local zone_settings = Public.zone_settings
local worm_level_modifier = 0.19
local base_tile = 'grass-1'

local start_ground_tiles = {
    'grass-1',
    'grass-1',
    'grass-2',
    'sand-2',
    'grass-1',
    'grass-4',
    'sand-2',
    'grass-3',
    'grass-4',
    'grass-2',
    'sand-3',
    'grass-4'
}

local wagon_raffle = {
    'cargo-wagon',
    'cargo-wagon',
    'cargo-wagon',
    'locomotive',
    'fluid-wagon'
}

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

local tree_raffle = {
    'dry-tree',
    'tree-01',
    'tree-02-red',
    'tree-04',
    'tree-08-brown'
}
local size_of_tree_raffle = #tree_raffle

local scrap_entities = {
    'medium-ship-wreck',
    'small-ship-wreck',
    'medium-ship-wreck',
    'small-ship-wreck',
    'medium-ship-wreck',
    'small-ship-wreck',
    'medium-ship-wreck',
    'small-ship-wreck'
}

local scrap_entities_index = #scrap_entities

local scrap_entities_friendly = {
    'crash-site-chest-1',
    'crash-site-chest-2',
    'crash-site-chest-1',
    'crash-site-chest-2',
    'crash-site-chest-1',
    'crash-site-chest-2'
}

local scrap_entities_friendly_index = #scrap_entities_friendly

local spawner_raffle = {
    'biter-spawner',
    'biter-spawner',
    'biter-spawner',
    'spitter-spawner'
}

local trees = {
    'dead-tree-desert',
    'dead-dry-hairy-tree',
    'dry-hairy-tree',
    'tree-06',
    'tree-06-brown',
    'dry-tree'
}

local callback = {
    [1] = {callback = Public.refill_turret_callback, data = Public.firearm_magazine_ammo},
    [2] = {callback = Public.refill_turret_callback, data = Public.piercing_rounds_magazine_ammo},
    [3] = {callback = Public.refill_turret_callback, data = Public.uranium_rounds_magazine_ammo},
    [4] = {callback = Public.refill_turret_callback, data = Public.uranium_rounds_magazine_ammo},
    [5] = {callback = Public.refill_liquid_turret_callback, data = Public.light_oil_ammo},
    [6] = {callback = Public.refill_artillery_turret_callback, data = Public.artillery_shell_ammo}
}

local turret_list = {
    [1] = {name = 'gun-turret', callback = callback[1]},
    [2] = {name = 'gun-turret', callback = callback[2]},
    [3] = {name = 'gun-turret', callback = callback[3]},
    [4] = {name = 'gun-turret', callback = callback[4]},
    [5] = {name = 'flamethrower-turret', callback = callback[5]},
    [6] = {name = 'artillery-turret', callback = callback[6]}
}

local function get_scrap_mineable_entities()
    local scrap_mineable_entities = {
        'crash-site-spaceship-wreck-small-1',
        'crash-site-spaceship-wreck-small-1',
        'crash-site-spaceship-wreck-small-2',
        'crash-site-spaceship-wreck-small-2',
        'crash-site-spaceship-wreck-small-3',
        'crash-site-spaceship-wreck-small-3',
        'crash-site-spaceship-wreck-small-4',
        'crash-site-spaceship-wreck-small-4',
        'crash-site-spaceship-wreck-small-5',
        'crash-site-spaceship-wreck-small-5',
        'crash-site-spaceship-wreck-small-6'
    }

    local scrap_mineable_entities_index = #scrap_mineable_entities

    return scrap_mineable_entities, scrap_mineable_entities_index
end

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local function is_position_near(area, table_to_check)
    local status = false
    local function inside(pos)
        local lt = area.left_top
        local rb = area.right_bottom

        return pos.x >= lt.x and pos.y >= lt.y and pos.x <= rb.x and pos.y <= rb.y
    end

    for i = 1, #table_to_check do
        if inside(table_to_check[i]) then
            status = true
        end
    end

    return status
end

local function place_wagon(data, adjusted_zones)
    local x_min = (-zone_settings.zone_width / 2) + 10
    local x_max = (zone_settings.zone_width / 2) - 10

    if data.x < x_min then
        return
    end
    if data.x > x_max then
        return
    end

    local placed_trains_in_zone = Public.get('placed_trains_in_zone')
    if not placed_trains_in_zone.randomized then
        placed_trains_in_zone.limit = random(1, 2)
        placed_trains_in_zone.randomized = true
        placed_trains_in_zone = Public.get('placed_trains_in_zone')
    end

    if not data.new_zone then
        data.new_zone = 1
    end

    if data.new_zone == adjusted_zones.size then
        data.new_zone = 1
    end

    if data.current_zone == adjusted_zones.size then
        local new_zone = placed_trains_in_zone.zones[data.new_zone]
        if new_zone then
            new_zone.placed = 0
            new_zone.positions = {}
            data.new_zone = data.new_zone + 1
        end
    end

    local zone = placed_trains_in_zone.zones[data.current_zone]
    if not zone then
        placed_trains_in_zone.zones[data.current_zone] = {
            placed = 0,
            positions = {}
        }
        zone = placed_trains_in_zone.zones[data.current_zone]
    end

    if zone.placed >= placed_trains_in_zone.limit then
        return
    end

    local surface = data.surface
    local tiles = data.hidden_tiles
    local entities = data.entities
    local top_y = data.top_y
    local position = {x = data.x, y = top_y + random(4, 12) * 2}
    local wagon_mineable = {
        callback = Public.disable_minable_and_ICW_callback
    }

    local rail_mineable = {
        callback = Public.disable_destructible_callback
    }

    local radius = 300
    local area = {
        left_top = {x = position.x - radius, y = position.y - radius},
        right_bottom = {x = position.x + radius, y = position.y + radius}
    }

    if is_position_near(area, zone.positions) then
        return
    end

    local location
    local direction

    local r1 = random(2, 4) * 2
    local r2 = random(2, 4) * 2

    if random(1, 2) == 1 then
        location = surface.find_tiles_filtered({area = {{position.x, position.y - r1}, {position.x + 2, position.y + r2}}})
        direction = 0
    else
        location = surface.find_tiles_filtered({area = {{position.x - r1, position.y}, {position.x + r2, position.y + 2}}})
        direction = 2
    end

    for _, tile in pairs(location) do
        tiles[#tiles + 1] = {name = base_tile, position = tile.position}
        if tile.position.y % 1 == 0 and tile.position.x % 1 == 0 then
            entities[#entities + 1] = {
                name = 'straight-rail',
                position = tile.position,
                force = 'player',
                direction = direction,
                callback = rail_mineable
            }
        end
    end
    entities[#entities + 1] = {
        name = wagon_raffle[random(1, #wagon_raffle)],
        position = position,
        force = 'player',
        callback = wagon_mineable
    }

    zone.placed = zone.placed + 1
    zone.positions[#zone.positions + 1] = position

    return true
end

local function get_oil_amount(p)
    return (abs(p.y) * 200 + 10000) * random(75, 125) * 0.01
end

local function spawn_turret(entities, p, probability)
    entities[#entities + 1] = {
        name = turret_list[probability].name,
        position = p,
        force = 'enemy',
        callback = turret_list[probability].callback,
        direction = 4,
        collision = true,
        note = true
    }
end

local function wall(p, data)
    local tiles = data.tiles
    local entities = data.entities
    local surface = data.surface
    local treasure = data.treasure
    local stone_wall = {callback = Public.disable_minable_callback}
    local enable_arties = Public.get('enable_arties')
    local alert_zone_1 = Public.get('alert_zone_1')

    local seed = data.seed
    local y = data.yv

    local small_caves = Public.get_noise('small_caves', p, seed + seed)
    local cave_ponds = Public.get_noise('cave_rivers', p, seed + seed)
    if y > 9 + cave_ponds * 6 and y < 23 + small_caves * 6 then
        if small_caves > 0.02 or cave_ponds > 0.02 then
            if small_caves > 0.005 then
                tiles[#tiles + 1] = {name = 'water', position = p}
            else
                tiles[#tiles + 1] = {name = 'water-shallow', position = p}
                if random(1, 26) == 1 then
                    entities[#entities + 1] = {
                        name = 'land-mine',
                        position = p,
                        force = 'enemy'
                    }
                end
            end
            if random(1, 48) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
        else
            tiles[#tiles + 1] = {name = base_tile, position = p}

            if random(1, 5) ~= 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, #rock_raffle)], position = p}
                if random(1, 26) == 1 then
                    entities[#entities + 1] = {
                        name = 'land-mine',
                        position = p,
                        force = 'enemy'
                    }
                end
            end
        end
    else
        tiles[#tiles + 1] = {name = base_tile, position = p}

        if
            surface.can_place_entity(
                {
                    name = 'stone-wall',
                    position = p,
                    force = 'enemy'
                }
            )
         then
            if random(1, 512) == 1 and y > 3 and y < 28 then
                if random(1, 2) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
                else
                    treasure[#treasure + 1] = {position = p, chest = 'steel-chest'}
                end
            end
            if y < 4 or y > 25 then
                if y <= 23 then
                    if random(1, y + 1) == 1 then
                        entities[#entities + 1] = {
                            name = 'stone-wall',
                            position = p,
                            force = 'neutral',
                            callback = stone_wall
                        }
                        if not alert_zone_1 and data.y >= -zone_settings.zone_depth then
                            local x_min = -zone_settings.zone_width / 2
                            local x_max = zone_settings.zone_width / 2
                            Public.set('zone1_beam1', surface.create_entity({name = 'electric-beam', position = {x_min, p.y}, source = {x_min, p.y}, target = {x_max, p.y}}))
                            Public.set('zone1_beam2', surface.create_entity({name = 'electric-beam', position = {x_min, p.y}, source = {x_min, p.y}, target = {x_max, p.y}}))
                            Public.set('alert_zone_1', true)
                            Public.set(
                                'zone1_text1',
                                rendering.draw_text {
                                    text = ({'breached_wall.warning'}),
                                    surface = surface,
                                    target = {0, p.y + 35},
                                    color = {r = 255, g = 106, b = 0},
                                    scale = 10,
                                    font = 'heading-1',
                                    alignment = 'center',
                                    scale_with_zoom = false
                                }
                            )
                            Public.set(
                                'zone1_text2',
                                rendering.draw_text {
                                    text = ({'breached_wall.warning'}),
                                    surface = surface,
                                    target = {-180, p.y + 35},
                                    color = {r = 255, g = 106, b = 0},
                                    scale = 10,
                                    font = 'heading-1',
                                    alignment = 'center',
                                    scale_with_zoom = false
                                }
                            )
                            Public.set(
                                'zone1_text3',
                                rendering.draw_text {
                                    text = ({'breached_wall.warning'}),
                                    surface = surface,
                                    target = {180, p.y + 35},
                                    color = {r = 255, g = 106, b = 0},
                                    scale = 10,
                                    font = 'heading-1',
                                    alignment = 'center',
                                    scale_with_zoom = false
                                }
                            )
                        end
                    end
                else
                    if random(1, 32 - y) == 1 then
                        entities[#entities + 1] = {
                            name = 'stone-wall',
                            position = p,
                            force = 'neutral',
                            callback = stone_wall
                        }
                    end
                end
            end
        end

        if random(1, 40) == 1 then
            if
                surface.can_place_entity(
                    {
                        name = 'medium-worm-turret',
                        position = p,
                        force = 'enemy'
                    }
                )
             then
                Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                entities[#entities + 1] = {
                    name = Biters.wave_defense_roll_worm_name(),
                    position = p,
                    force = 'enemy',
                    note = true
                }
            end
        end

        if random(1, 25) == 1 then
            if abs(p.y) < zone_settings.zone_depth * 1.5 then
                if random(1, 16) == 1 then
                    spawn_turret(entities, p, 1)
                else
                    spawn_turret(entities, p, 2)
                end
            elseif abs(p.y) < zone_settings.zone_depth * 2.5 then
                if random(1, 8) == 1 then
                    spawn_turret(entities, p, 3)
                end
            elseif abs(p.y) < zone_settings.zone_depth * 3.5 then
                if random(1, 4) == 1 then
                    spawn_turret(entities, p, 4)
                else
                    spawn_turret(entities, p, 3)
                end
            elseif abs(p.y) < zone_settings.zone_depth * 4.5 then
                if random(1, 4) == 1 then
                    spawn_turret(entities, p, 4)
                else
                    spawn_turret(entities, p, 5)
                end
            elseif abs(p.y) < zone_settings.zone_depth * 5.5 then
                if random(1, 4) == 1 then
                    spawn_turret(entities, p, 4)
                elseif random(1, 2) == 1 then
                    spawn_turret(entities, p, 5)
                end
            end
        elseif abs(p.y) > zone_settings.zone_depth * 5.5 then
            if random(1, 15) == 1 then
                spawn_turret(entities, p, random(3, enable_arties))
            end
        end
    end
end

local function zone_14(x, y, data, _, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local treasure = data.treasure
    data.forest_zone = true

    local small_caves = Public.get_noise('small_caves', p, seed)
    local noise_cave_ponds = Public.get_noise('cave_ponds', p, seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)

    --Resource Spots
    if smol_areas < -0.71 then
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
    end

    if small_caves > -0.21 and small_caves < 0.21 then
        tiles[#tiles + 1] = {name = 'grass-3', position = p}
        if random(1, 768) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        if random(1, 2) == 1 then
            entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = p}
        end
        return
    end

    if small_caves < -0.34 or small_caves > 0.34 then
        tiles[#tiles + 1] = {name = 'water', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end
        if random(1, 256) == 1 then
            spawn_turret(entities, p, 4)
        end
        return
    end

    if small_caves > -0.41 and small_caves < 0.41 then
        if noise_cave_ponds > 0.35 then
            local success = place_wagon(data, adjusted_zones)
            if success then
                return
            end
            tiles[#tiles + 1] = {name = 'grass-' .. random(1, 4), position = p}
            if random(1, 256) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            if random(1, 256) == 1 then
                entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
            end
            return
        end
        if noise_cave_ponds > 0.23 then
            tiles[#tiles + 1] = {name = 'grass-4', position = p}
            if random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = p}
            end
            return
        end
    end

    tiles[#tiles + 1] = {name = 'water-shallow', position = p}
end

local function zone_13(x, y, data, _, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local treasure = data.treasure

    local small_caves = Public.get_noise('small_caves', p, seed)
    local noise_cave_ponds = Public.get_noise('cave_ponds', p, seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)

    --Resource Spots
    if smol_areas < -0.72 then
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
    end

    if small_caves > -0.22 and small_caves < 0.22 then
        tiles[#tiles + 1] = {name = 'dirt-3', position = p}
        if random(1, 768) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        if random(1, 2) == 1 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        return
    end

    if small_caves < -0.35 or small_caves > 0.35 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end
        if random(1, 256) == 1 then
            spawn_turret(entities, p, 4)
        end
        return
    end

    if small_caves > -0.40 and small_caves < 0.40 then
        if noise_cave_ponds > 0.35 then
            local success = place_wagon(data, adjusted_zones)
            if success then
                return
            end
            tiles[#tiles + 1] = {name = 'dirt-' .. random(1, 4), position = p}
            if random(1, 256) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            if random(1, 256) == 1 then
                entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
            end
            return
        end
        if noise_cave_ponds > 0.25 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            if random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
            return
        end
    end

    tiles[#tiles + 1] = {name = 'water-shallow', position = p}
end

local function zone_12(x, y, data, void_or_lab, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local markets = data.markets
    local treasure = data.treasure

    local noise_1 = Public.get_noise('small_caves', p, seed)
    local noise_2 = Public.get_noise('no_rocks_2', p, seed + seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)

    --Resource Spots
    if smol_areas < -0.72 then
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
    end

    if noise_1 > 0.65 then
        if random(1, 100) > 88 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        else
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
        end
        if random(1, 48) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    if noise_1 < -0.72 then
        local success = place_wagon(data, adjusted_zones)
        if success then
            return
        end
        tiles[#tiles + 1] = {name = void_or_lab, position = p}
        if random(1, 100) > 88 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        end
        return
    end

    if noise_1 > -0.30 and noise_1 < 0.30 then
        if noise_1 > -0.14 and noise_1 < 0.14 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
            if random(1, 256) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
        else
            tiles[#tiles + 1] = {name = 'water-shallow', position = p}
        end
        return
    end

    if random(1, 64) == 1 and noise_2 > 0.65 then
        if random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'stone', position = p, amount = abs(p.y) + 1}
        elseif random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'iron-ore', position = p, amount = abs(p.y) + 1}
        elseif random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'copper-ore', position = p, amount = abs(p.y) + 1}
        elseif random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'coal', position = p, amount = abs(p.y) + 1}
        end
    end
    if random(1, 8192) == 1 then
        markets[#markets + 1] = p
    end
    if random(1, 1024) == 1 then
        entities[#entities + 1] = {
            name = 'crash-site-chest-' .. random(1, 2),
            position = p,
            force = 'neutral'
        }
    end

    tiles[#tiles + 1] = {name = 'tutorial-grid', position = p}
end

local function zone_11(x, y, data, _, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local markets = data.markets
    local treasure = data.treasure

    local noise_1 = Public.get_noise('small_caves', p, seed)
    local noise_2 = Public.get_noise('no_rocks_2', p, seed + seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)

    if noise_1 > 0.7 then
        tiles[#tiles + 1] = {name = 'water', position = p}
        if random(1, 48) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    --Resource Spots
    if smol_areas < -0.72 then
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
    end

    if noise_1 < -0.72 then
        tiles[#tiles + 1] = {name = 'lab-dark-1', position = p}
        entities[#entities + 1] = {name = 'uranium-ore', position = p, amount = abs(p.y) + 1 * 3}
        return
    end

    if noise_1 > -0.30 and noise_1 < 0.30 then
        if noise_1 > -0.14 and noise_1 < 0.14 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
            if random(1, 256) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
        else
            tiles[#tiles + 1] = {name = 'water-shallow', position = p}
        end
        return
    end

    if random(1, 64) == 1 and noise_2 > 0.65 then
        entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
    end
    if random(1, 8192) == 1 then
        markets[#markets + 1] = p
    end
    if random(1, 1024) == 1 then
        entities[#entities + 1] = {
            name = 'crash-site-chest-' .. random(1, 2),
            position = p,
            force = 'neutral'
        }
    end

    local success = place_wagon(data, adjusted_zones)
    if success then
        return
    end

    local noise_forest_location = Public.get_noise('forest_location', p, seed)
    if noise_forest_location > 0.095 then
        if noise_forest_location > 0.6 then
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = 'red-refined-concrete', position = p}
            end
        else
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = 'green-refined-concrete', position = p}
            end
        end
        return
    end

    if noise_forest_location < -0.095 then
        if noise_forest_location < -0.6 then
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = 'blue-refined-concrete', position = p}
            end
        else
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = 'red-refined-concrete', position = p}
            end
        end
        return
    end
end

local function zone_10(x, y, data, _, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local treasure = data.treasure
    data.forest_zone = true

    local scrapyard = Public.get_noise('scrapyard', p, seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)

    if scrapyard < -0.70 or scrapyard > 0.70 then
        tiles[#tiles + 1] = {name = 'grass-3', position = p}
        if random(1, 40) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    if scrapyard < -0.65 or scrapyard > 0.65 then
        tiles[#tiles + 1] = {name = 'water-green', position = p}
        return
    end
    --Resource Spots
    if smol_areas < -0.72 then
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
    end

    if abs(scrapyard) > 0.40 and abs(scrapyard) < 0.65 then
        if random(1, 64) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end
        tiles[#tiles + 1] = {name = 'water-mud', position = p}
        return
    end
    if abs(scrapyard) > 0.25 and abs(scrapyard) < 0.40 then
        local success = place_wagon(data, adjusted_zones)
        if success then
            return
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end
        if random(1, 256) == 1 then
            spawn_turret(entities, p, 4)
        end
        tiles[#tiles + 1] = {name = 'water-shallow', position = p}
        return
    end
    local noise_forest_location = Public.get_noise('forest_location', p, seed)
    if scrapyard > -0.15 and scrapyard < 0.15 then
        if noise_forest_location > 0.095 then
            if random(1, 256) == 1 then
                Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                entities[#entities + 1] = {
                    name = Biters.wave_defense_roll_worm_name(),
                    position = p,
                    force = 'enemy',
                    note = true
                }
            end
            if noise_forest_location > 0.6 then
                if random(1, 100) > 42 then
                    entities[#entities + 1] = {name = 'tree-03', position = p}
                end
            else
                if random(1, 100) > 42 then
                    entities[#entities + 1] = {name = 'tree-01', position = p}
                end
            end
            return
        end

        if noise_forest_location < -0.095 then
            if random(1, 256) == 1 then
                Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                entities[#entities + 1] = {
                    name = Biters.wave_defense_roll_worm_name(),
                    position = p,
                    force = 'enemy',
                    note = true
                }
            end
            if noise_forest_location < -0.6 then
                if random(1, 100) > 42 then
                    entities[#entities + 1] = {name = 'dry-tree', position = p}
                end
            else
                if random(1, 100) > 42 then
                    entities[#entities + 1] = {name = 'tree-02-red', position = p}
                end
            end
            return
        end
        tiles[#tiles + 1] = {name = 'dirt-6', position = p}
        return
    end
    tiles[#tiles + 1] = {name = 'grass-2', position = p}
end

local function zone_9(x, y, data, _, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local markets = data.markets
    local treasure = data.treasure

    local maze_p = {x = floor(p.x - p.x % 10), y = floor(p.y - p.y % 10)}
    local maze_noise = Public.get_noise('no_rocks_2', maze_p, seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)

    if maze_noise > -0.35 and maze_noise < 0.35 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        local no_rocks_2 = Public.get_noise('no_rocks_2', p, seed)
        if random(1, 2) == 1 and no_rocks_2 > -0.5 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        if random(1, 1024) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        if random(1, 256) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end
        return
    end

    if maze_noise > 0 and maze_noise < 0.45 then
        local success = place_wagon(data, adjusted_zones)
        if success then
            return
        end
        if random(1, 512) == 1 then
            markets[#markets + 1] = p
        end
        if random(1, 256) == 1 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end
        if random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        end
        return
    end

    --Resource Spots
    if smol_areas < -0.72 then
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
    end

    if maze_noise < -0.5 or maze_noise > 0.5 then
        tiles[#tiles + 1] = {name = 'deepwater', position = p}
        if random(1, 96) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    tiles[#tiles + 1] = {name = 'water', position = p}
    if random(1, 96) == 1 then
        entities[#entities + 1] = {name = 'fish', position = p}
    end
end

--SCRAPYARD
local function zone_scrap_2(x, y, data, void_or_lab, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local treasure = data.treasure
    data.scrap_zone = true

    local scrapyard_modified = Public.get_noise('scrapyard_modified', p, seed)
    local cave_rivers = Public.get_noise('cave_rivers', p, seed + seed)

    --Chasms
    local noise_cave_ponds = Public.get_noise('cave_ponds', p, seed)
    local small_caves = Public.get_noise('small_caves', p, seed)
    if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
        if small_caves > 0.35 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end

        if small_caves < -0.35 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
    end

    if scrapyard_modified < -0.25 or scrapyard_modified > 0.25 then
        if random(1, 256) == 1 then
            if random(1, 8) == 1 then
                spawn_turret(entities, p, 3)
            else
                spawn_turret(entities, p, 4)
            end
            if random(1, 2048) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
        end
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if scrapyard_modified < -0.55 or scrapyard_modified > 0.55 then
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
            return
        end
        if scrapyard_modified < -0.28 or scrapyard_modified > 0.28 then
            local success = place_wagon(data, adjusted_zones)
            if success then
                return
            end
            if random(1, 128) == 1 then
                Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                entities[#entities + 1] = {
                    name = Biters.wave_defense_roll_worm_name(),
                    position = p,
                    force = 'enemy',
                    note = true
                }
            end
            if random(1, 96) == 1 then
                entities[#entities + 1] = {
                    name = scrap_entities[random(1, scrap_entities_index)],
                    position = p,
                    force = 'enemy'
                }
            end
            if random(1, 96) == 1 then
                entities[#entities + 1] = {
                    name = scrap_entities_friendly[random(1, scrap_entities_friendly_index)],
                    position = p,
                    force = 'neutral'
                }
            end

            local scrap_mineable_entities, scrap_mineable_entities_index = get_scrap_mineable_entities()

            if random(1, 5) > 1 then
                entities[#entities + 1] = {name = scrap_mineable_entities[random(1, scrap_mineable_entities_index)], position = p, force = 'neutral'}
            end

            if random(1, 256) == 1 then
                entities[#entities + 1] = {name = 'land-mine', position = p, force = 'enemy'}
            end
            return
        end
        return
    end

    local cave_ponds = Public.get_noise('cave_ponds', p, seed)
    if cave_ponds < -0.6 and scrapyard_modified > -0.2 and scrapyard_modified < 0.2 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    --Resource Spots
    if cave_rivers < -0.72 then
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
    end

    local large_caves = Public.get_noise('large_caves', p, seed)
    if scrapyard_modified > -0.15 and scrapyard_modified < 0.15 then
        if floor(large_caves * 10) % 4 < 3 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
            if random(1, 2048) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            return
        end
    end

    if random(1, 64) == 1 and cave_ponds > 0.6 then
        entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
    end

    tiles[#tiles + 1] = {name = base_tile, position = p}
    if random(1, 256) == 1 then
        entities[#entities + 1] = {name = 'land-mine', position = p, force = 'enemy'}
    end
end

--SCRAPYARD
local function zone_scrap_1(x, y, data, void_or_lab, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local treasure = data.treasure
    data.scrap_zone = true

    local scrapyard = Public.get_noise('scrapyard', p, seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)

    --Chasms
    local noise_cave_ponds = Public.get_noise('cave_ponds', p, seed)
    local small_caves = Public.get_noise('small_caves', p, seed)
    if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
        if small_caves > 0.35 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end

        if small_caves < -0.35 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
    end

    if scrapyard < -0.25 or scrapyard > 0.25 then
        if random(1, 256) == 1 then
            if random(1, 8) == 1 then
                spawn_turret(entities, p, 3)
            else
                spawn_turret(entities, p, 4)
            end
            if random(1, 2048) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
        end
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if scrapyard < -0.55 or scrapyard > 0.55 then
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
            return
        end
        if scrapyard < -0.28 or scrapyard > 0.28 then
            local success = place_wagon(data, adjusted_zones)
            if success then
                return
            end
            if random(1, 128) == 1 then
                Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                entities[#entities + 1] = {
                    name = Biters.wave_defense_roll_worm_name(),
                    position = p,
                    force = 'enemy',
                    note = true
                }
            end
            if random(1, 96) == 1 then
                entities[#entities + 1] = {
                    name = scrap_entities[random(1, scrap_entities_index)],
                    position = p,
                    force = 'enemy'
                }
            end
            if random(1, 96) == 1 then
                entities[#entities + 1] = {
                    name = scrap_entities_friendly[random(1, scrap_entities_friendly_index)],
                    position = p,
                    force = 'neutral'
                }
            end

            local scrap_mineable_entities, scrap_mineable_entities_index = get_scrap_mineable_entities()

            if random(1, 5) > 1 then
                entities[#entities + 1] = {name = scrap_mineable_entities[random(1, scrap_mineable_entities_index)], position = p, force = 'neutral'}
            end

            if random(1, 256) == 1 then
                entities[#entities + 1] = {name = 'land-mine', position = p, force = 'enemy'}
            end
            return
        end
        return
    end

    local cave_ponds = Public.get_noise('cave_ponds', p, seed)
    if cave_ponds < -0.6 and scrapyard > -0.2 and scrapyard < 0.2 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    --Resource Spots
    if smol_areas < -0.72 then
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
    end

    local large_caves = Public.get_noise('large_caves', p, seed)
    if scrapyard > -0.15 and scrapyard < 0.15 then
        if floor(large_caves * 10) % 4 < 3 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
            if random(1, 2048) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            return
        end
    end

    if random(1, 64) == 1 and cave_ponds > 0.6 then
        entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
    end

    tiles[#tiles + 1] = {name = 'stone-path', position = p}
    if random(1, 256) == 1 then
        entities[#entities + 1] = {name = 'land-mine', position = p, force = 'enemy'}
    end
end

local function zone_7(x, y, data, void_or_lab, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local markets = data.markets
    local treasure = data.treasure

    local cave_rivers_3 = Public.get_noise('cave_rivers_3', p, seed)
    local cave_rivers_4 = Public.get_noise('cave_rivers_4', p, seed + seed)
    local no_rocks_2 = Public.get_noise('no_rocks_2', p, seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)

    if cave_rivers_3 > -0.025 and cave_rivers_3 < 0.025 and no_rocks_2 > -0.6 then
        tiles[#tiles + 1] = {name = 'water', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    if cave_rivers_4 > -0.025 and cave_rivers_4 < 0.025 and no_rocks_2 > -0.6 then
        tiles[#tiles + 1] = {name = 'water', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    local noise_ores = Public.get_noise('no_rocks_2', p, seed + seed)

    if cave_rivers_3 > -0.20 and cave_rivers_3 < 0.20 then
        tiles[#tiles + 1] = {name = 'grass-' .. floor(cave_rivers_3 * 32) % 3 + 1, position = p}
        if cave_rivers_3 > -0.10 and cave_rivers_3 < 0.10 then
            if random(1, 8) == 1 and no_rocks_2 > -0.25 then
                entities[#entities + 1] = {name = 'tree-01', position = p}
            end
            if random(1, 2048) == 1 then
                markets[#markets + 1] = p
            end
            if noise_ores < -0.5 and no_rocks_2 > -0.6 then
                if cave_rivers_3 > 0 and cave_rivers_3 < 0.07 then
                    entities[#entities + 1] = {name = 'iron-ore', position = p, amount = abs(p.y) + 1}
                end
            end
        end
        if random(1, 64) == 1 and no_rocks_2 > 0.7 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end

        if random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    if cave_rivers_4 > -0.20 and cave_rivers_4 < 0.20 then
        tiles[#tiles + 1] = {name = 'grass-' .. floor(cave_rivers_4 * 32) % 3 + 1, position = p}
        if cave_rivers_4 > -0.10 and cave_rivers_4 < 0.10 then
            local success = place_wagon(data, adjusted_zones)
            if success then
                return
            end
            if random(1, 8) == 1 and no_rocks_2 > -0.25 then
                entities[#entities + 1] = {name = 'tree-02', position = p}
            end
            if random(1, 2048) == 1 then
                markets[#markets + 1] = p
            end
            if noise_ores < -0.5 and no_rocks_2 > -0.6 then
                if cave_rivers_4 > 0 and cave_rivers_4 < 0.07 then
                    entities[#entities + 1] = {name = 'copper-ore', position = p, amount = abs(p.y) + 1}
                end
            end
        end
        if random(1, 64) == 1 and no_rocks_2 > 0.7 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end
        if random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    --Chasms
    local noise_cave_ponds = Public.get_noise('cave_ponds', p, seed)
    local small_caves = Public.get_noise('small_caves', p, seed)
    if noise_cave_ponds < 0.25 and noise_cave_ponds > -0.25 then
        if small_caves > 0.55 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end

        if small_caves < -0.55 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}

            return
        end
    end

    --Resource Spots
    if smol_areas < -0.72 then
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
    end

    tiles[#tiles + 1] = {name = 'dirt-7', position = p}
    if random(1, 100) > 15 then
        entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
    end
    if random(1, 256) == 1 then
        treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
    end
end

local function zone_forest_2(x, y, data, void_or_lab, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local markets = data.markets
    local treasure = data.treasure
    data.forest_zone = true

    local large_caves = Public.get_noise('large_caves', p, seed)
    local cave_rivers = Public.get_noise('cave_rivers', p, seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)

    --Chasms
    local noise_cave_ponds = Public.get_noise('cave_ponds', p, seed)
    local small_caves = Public.get_noise('small_caves', p, seed)
    if noise_cave_ponds < 0.45 and noise_cave_ponds > -0.45 then
        if small_caves > 0.45 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end

        if small_caves < -0.45 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
    end

    if large_caves > -0.03 and large_caves < 0.03 and cave_rivers < 0.25 then
        tiles[#tiles + 1] = {name = 'water-green', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    --Resource Spots
    if smol_areas < 0.055 and smol_areas > -0.025 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end

        return
    end
    local noise_forest_location = Public.get_noise('forest_location', p, seed)
    if cave_rivers > -0.1 and cave_rivers < 0.1 then
        local success = place_wagon(data, adjusted_zones)
        if success then
            return
        end
        if random(1, 36) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end
        if random(1, 256) == 1 then
            spawn_turret(entities, p, 4)
        end
    else
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if random(1, 100) > 15 then
            if noise_forest_location > 0.095 then
                if random(1, 256) == 1 then
                    Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy',
                        note = true
                    }
                end
                if noise_forest_location > 0.6 then
                    if random(1, 100) > 42 then
                        entities[#entities + 1] = {name = 'tree-08-brown', position = p}
                    end
                else
                    if random(1, 100) > 42 then
                        entities[#entities + 1] = {name = 'tree-01', position = p}
                    end
                end
                return
            end

            if noise_forest_location < -0.095 then
                if random(1, 256) == 1 then
                    Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy',
                        note = true
                    }
                end
                if noise_forest_location < -0.6 then
                    if random(1, 100) > 42 then
                        entities[#entities + 1] = {name = 'tree-04', position = p}
                    end
                else
                    if random(1, 100) > 42 then
                        entities[#entities + 1] = {name = 'tree-02-red', position = p}
                    end
                end

                return
            end
        end
        if random(1, 512) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        if random(1, 4096) == 1 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end
        if random(1, 8096) == 1 then
            markets[#markets + 1] = p
        end
    end
end

local function zone_5(x, y, data, void_or_lab, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local treasure = data.treasure

    local small_caves = Public.get_noise('small_caves', p, seed)
    local noise_cave_ponds = Public.get_noise('cave_ponds', p, seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)

    if small_caves > -0.24 and small_caves < 0.24 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if random(1, 768) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        if random(1, 2) == 1 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        return
    end

    if small_caves < -0.50 or small_caves > 0.50 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end
        if random(1, 256) == 1 then
            spawn_turret(entities, p, 4)
        end
        return
    end

    --Resource Spots
    if smol_areas < 0.055 and smol_areas > -0.025 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end

        return
    end

    if small_caves > -0.40 and small_caves < 0.40 then
        if noise_cave_ponds > 0.35 then
            local success = place_wagon(data, adjusted_zones)
            if success then
                return
            end
            tiles[#tiles + 1] = {name = 'dirt-' .. random(1, 4), position = p}
            if random(1, 256) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            if random(1, 256) == 1 then
                entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
            end
            return
        end
        if noise_cave_ponds > 0.25 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            if random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end

            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
        end
    end

    tiles[#tiles + 1] = {name = void_or_lab, position = p}
end

local function zone_4(x, y, data, void_or_lab, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local markets = data.markets
    local treasure = data.treasure

    local noise_large_caves = Public.get_noise('large_caves', p, seed)
    local noise_cave_ponds = Public.get_noise('cave_ponds', p, seed)
    local small_caves = Public.get_noise('dungeons', p, seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)

    if abs(noise_large_caves) > 0.7 then
        tiles[#tiles + 1] = {name = 'water', position = p}
        if random(1, 16) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end
    if abs(noise_large_caves) > 0.6 then
        if random(1, 16) == 1 then
            entities[#entities + 1] = {name = 'tree-02', position = p}
        end
        if random(1, 32) == 1 then
            markets[#markets + 1] = p
        end
    end
    if abs(noise_large_caves) > 0.5 then
        tiles[#tiles + 1] = {name = 'grass-2', position = p}
        if random(1, 620) == 1 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end
        if random(1, 384) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end
        local success = place_wagon(data, adjusted_zones)
        if success then
            return
        end
        if random(1, 1024) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end
    if abs(noise_large_caves) > 0.475 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if random(1, 2) == 1 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        if random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    --Chasms
    if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
        if small_caves > 0.75 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end

        if small_caves < -0.75 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
    end

    if small_caves > -0.15 and small_caves < 0.15 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if random(1, 2) == 1 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        if random(1, 1024) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    --Resource Spots
    if smol_areas < 0.055 and smol_areas > -0.025 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end

        return
    end

    if noise_large_caves > -0.2 and noise_large_caves < 0.2 then
        --Main Rock Terrain
        local no_rocks_2 = Public.get_noise('no_rocks_2', p, seed + seed)
        if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
            tiles[#tiles + 1] = {name = 'dirt-' .. floor(no_rocks_2 * 8) % 2 + 5, position = p}
            if random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            return
        end

        if random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end

        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if random(1, 100) > 30 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        return
    end

    tiles[#tiles + 1] = {name = void_or_lab, position = p}
end

local function zone_3(x, y, data, void_or_lab, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local markets = data.markets
    local treasure = data.treasure

    local small_caves = Public.get_noise('dungeons', p, seed + seed)
    local small_caves_2 = Public.get_noise('small_caves_2', p, seed + seed)
    local noise_large_caves = Public.get_noise('large_caves', p, seed + seed)
    local noise_cave_ponds = Public.get_noise('cave_ponds', p, seed)
    local cave_miner = Public.get_noise('cave_miner_01', p, seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)

    --Resource Spots
    if smol_areas < 0.055 and smol_areas > -0.025 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end
        return
    end

    --Market Spots
    if noise_cave_ponds < -0.77 then
        if noise_cave_ponds > -0.79 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        else
            tiles[#tiles + 1] = {name = 'grass-' .. floor(noise_cave_ponds * 32) % 3 + 1, position = p}
            if random(1, 32) == 1 then
                markets[#markets + 1] = p
            end
            if random(1, 16) == 1 then
                entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
            end
        end
        return
    end

    if noise_large_caves > -0.15 and noise_large_caves < 0.15 or small_caves_2 > 0 then
        --Green Water Ponds
        if noise_cave_ponds > 0.80 then
            tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
            if random(1, 16) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
            return
        end

        --Chasms
        if noise_cave_ponds < 0.12 and noise_cave_ponds > -0.12 then
            if small_caves > 0.85 then
                tiles[#tiles + 1] = {name = void_or_lab, position = p}

                return
            end

            if small_caves < -0.85 then
                tiles[#tiles + 1] = {name = void_or_lab, position = p}

                return
            end
        end

        --Rivers
        local cave_rivers = Public.get_noise('cave_rivers', p, seed + seed)
        if cave_rivers < 0.024 and cave_rivers > -0.024 then
            if noise_cave_ponds > 0.2 then
                tiles[#tiles + 1] = {name = 'water-shallow', position = p}
                if random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'fish', position = p}
                end
                return
            end
        end
        local cave_rivers_2 = Public.get_noise('cave_rivers_2', p, seed)
        if cave_rivers_2 < 0.024 and cave_rivers_2 > -0.024 then
            if noise_cave_ponds < 0.4 then
                tiles[#tiles + 1] = {name = 'water-shallow', position = p}
                if random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'fish', position = p}
                end
                return
            end
        end

        if noise_cave_ponds > 0.725 then
            tiles[#tiles + 1] = {name = 'dirt-' .. random(4, 6), position = p}
            return
        end

        local no_rocks = Public.get_noise('no_rocks', p, seed + seed)
        --Worm oil Zones
        if no_rocks < 0.20 and no_rocks > -0.20 then
            if small_caves > 0.35 then
                tiles[#tiles + 1] = {name = 'dirt-' .. floor(noise_cave_ponds * 32) % 7 + 1, position = p}
                if random(1, 320) == 1 then
                    entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
                end
                if random(1, 50) == 1 then
                    Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy',
                        note = true
                    }
                end

                if random(1, 256) == 1 then
                    spawn_turret(entities, p, 3)
                end
                if random(1, 512) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
                end
                if random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'dead-tree-desert', position = p}
                end
                return
            end
        end

        --Main Rock Terrain
        local no_rocks_2 = Public.get_noise('no_rocks_2', p, seed + seed)
        if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
            local success = place_wagon(data, adjusted_zones)
            if success then
                return
            end
            tiles[#tiles + 1] = {name = 'dirt-' .. floor(no_rocks_2 * 8) % 2 + 5, position = p}
            if random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end

            return
        end

        if random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if random(1, 100) > 30 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        return
    end

    if cave_miner < 0.32 and cave_miner > -0.32 then
        tiles[#tiles + 1] = {name = void_or_lab, position = p}
    else
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
    end
end

local function zone_2(x, y, data, void_or_lab, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local buildings = data.buildings
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local small_caves = Public.get_noise('dungeons', p, seed)
    local noise_large_caves = Public.get_noise('large_caves', p, seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)

    --Resource Spots
    if smol_areas < 0.055 and smol_areas > -0.025 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end
        return
    end

    if noise_large_caves > -0.75 and noise_large_caves < 0.75 then
        local noise_cave_ponds = Public.get_noise('cave_ponds', p, seed)

        --Chasms
        if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
            if small_caves > 0.32 then
                tiles[#tiles + 1] = {name = void_or_lab, position = p}

                return
            end
            if small_caves < -0.32 then
                tiles[#tiles + 1] = {name = void_or_lab, position = p}
                return
            end
        end

        --Green Water Ponds
        if noise_cave_ponds > 0.80 then
            tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
            if random(1, 16) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
            return
        end

        --Rivers
        local cave_rivers = Public.get_noise('cave_rivers', p, seed + seed)
        if cave_rivers < 0.037 and cave_rivers > -0.037 then
            if noise_cave_ponds < 0.1 then
                tiles[#tiles + 1] = {name = 'water-shallow', position = p}
                if random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'fish', position = p}
                end
                return
            end
        end

        if noise_cave_ponds > 0.66 then
            tiles[#tiles + 1] = {name = 'dirt-' .. random(4, 6), position = p}
            return
        end

        --Market Spots
        if noise_cave_ponds < -0.80 then
            tiles[#tiles + 1] = {name = 'grass-' .. floor(noise_cave_ponds * 32) % 3 + 1, position = p}
            if random(1, 32) == 1 then
                markets[#markets + 1] = p
            end
            if random(1, 16) == 1 then
                entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
            end
            return
        end

        local no_rocks = Public.get_noise('no_rocks', p, seed + seed)
        --Worm oil Zones
        if no_rocks < 0.20 and no_rocks > -0.20 then
            if small_caves > 0.30 then
                tiles[#tiles + 1] = {name = 'dirt-' .. floor(noise_cave_ponds * 32) % 7 + 1, position = p}
                if random(1, 450) == 1 then
                    entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
                end
                if random(1, 64) == 1 then
                    Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy',
                        note = true
                    }
                end

                if random(1, 256) == 1 then
                    spawn_turret(entities, p, 2)
                end
                if random(1, 1024) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
                end
                if random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'dead-tree-desert', position = p}
                end
                return
            end
        end

        --Main Rock Terrain
        local no_rocks_2 = Public.get_noise('no_rocks_2', p, seed + seed)
        if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
            local success = place_wagon(data, adjusted_zones)
            if success then
                return
            end
            tiles[#tiles + 1] = {name = 'grass-' .. random(1, 4), position = p}
            if random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end

            return
        end

        if random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        tiles[#tiles + 1] = {name = 'grass-' .. random(1, 4), position = p}
        if random(1, 100) > 25 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        return
    end

    tiles[#tiles + 1] = {name = void_or_lab, position = p}
end

local function zone_forest_1(x, y, data, void_or_lab, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local buildings = data.buildings
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure
    data.forest_zone = true

    local small_caves = Public.get_noise('dungeons', p, seed + seed)
    local noise_cave_ponds = Public.get_noise('cave_ponds', p, seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)

    --Resource Spots
    if smol_areas < 0.055 and smol_areas > -0.025 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end
        return
    end

    --Chasms
    if noise_cave_ponds < 0.101 and noise_cave_ponds > -0.102 then
        if small_caves > 0.52 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
        if small_caves < -0.52 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
    end

    --Water Ponds
    if noise_cave_ponds > 0.670 then
        if noise_cave_ponds > 0.750 then
            tiles[#tiles + 1] = {name = 'landfill', position = p}
            if random(1, 4) == 1 then
                markets[#markets + 1] = p
            end
            if random(1, 4) == 1 then
                entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = p}
            end
            return
        end
        tiles[#tiles + 1] = {name = 'deepwater', position = p}
        if random(1, 16) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    --Rivers
    local cave_rivers = Public.get_noise('cave_rivers', p, seed + seed)
    if cave_rivers < 0.041 and cave_rivers > -0.042 then
        if noise_cave_ponds > 0 then
            tiles[#tiles + 1] = {name = 'water-shallow', position = p}
            if random(1, 64) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
            return
        end
    end

    if noise_cave_ponds > 0.74 then
        tiles[#tiles + 1] = {name = 'landfill', position = p}
        if cave_rivers < -0.502 then
            tiles[#tiles + 1] = {name = 'refined-hazard-concrete-right', position = p}
        end
        if random(1, 64) == 1 then
            entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = p}
        end
        return
    end

    local no_rocks = Public.get_noise('no_rocks', p, seed + seed)
    --Worm oil Zones
    if p.y < -64 + noise_cave_ponds * 10 then
        if no_rocks < 0.11 and no_rocks > -0.11 then
            if small_caves > 0.31 then
                tiles[#tiles + 1] = {name = 'brown-refined-concrete', position = p}
                if random(1, 450) == 1 then
                    entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
                end
                if random(1, 96) == 1 then
                    Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy',
                        note = true
                    }
                end

                if random(1, 1024) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
                end
                if random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
                end
                return
            end
        end
    end

    --Main Rock Terrain
    local no_rocks_2 = Public.get_noise('no_rocks_2', p, seed + seed)
    if no_rocks_2 > 0.64 or no_rocks_2 < -0.64 then
        local success = place_wagon(data, adjusted_zones)
        if success then
            return
        end
        tiles[#tiles + 1] = {name = base_tile, position = p}
        if random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        end

        if random(1, 512) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
        end
        return
    end

    if random(1, 2048) == 1 then
        treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
    end
    tiles[#tiles + 1] = {name = 'landfill', position = p}
    local noise_forest_location = Public.get_noise('forest_location', p, seed)
    if noise_forest_location > 0.095 then
        if random(1, 256) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end
        if noise_forest_location > 0.6 then
            if random(1, 100) > 42 then
                entities[#entities + 1] = {name = 'tree-08-brown', position = p}
            end
        else
            if random(1, 100) > 42 then
                entities[#entities + 1] = {name = 'tree-01', position = p}
            end
        end
        return
    end

    if noise_forest_location < -0.095 then
        if random(1, 256) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end
        if noise_forest_location < -0.6 then
            if random(1, 100) > 42 then
                entities[#entities + 1] = {name = 'tree-04', position = p}
            end
        else
            if random(1, 100) > 42 then
                entities[#entities + 1] = {name = 'tree-02-red', position = p}
            end
        end
        return
    end
end

local function zone_1(x, y, data, void_or_lab, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local buildings = data.buildings
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local small_caves = Public.get_noise('dungeons', p, seed)
    local noise_cave_ponds = Public.get_noise('cave_ponds', p, seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed)

    if smol_areas < 0.055 and smol_areas > -0.025 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
        if random(1, 32) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy',
                note = true
            }
        end
        return
    end

    --Chasms
    if noise_cave_ponds < 0.110 and noise_cave_ponds > -0.112 then
        if small_caves > 0.5 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
        if small_caves < -0.5 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
    end

    --Water Ponds
    if noise_cave_ponds > 0.670 then
        if noise_cave_ponds > 0.750 then
            tiles[#tiles + 1] = {name = 'grass-' .. floor(noise_cave_ponds * 32) % 3 + 1, position = p}
            if random(1, 4) == 1 then
                markets[#markets + 1] = p
            end
            if random(1, 4) == 1 then
                entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = p}
            end
            return
        end
        tiles[#tiles + 1] = {name = 'deepwater', position = p}
        if random(1, 16) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    --Rivers
    local cave_rivers = Public.get_noise('cave_rivers', p, seed + seed)
    if cave_rivers < 0.042 and cave_rivers > -0.042 then
        if noise_cave_ponds > 0 then
            tiles[#tiles + 1] = {name = 'water-shallow', position = p}
            if random(1, 64) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
            return
        end
    end

    if noise_cave_ponds > 0.74 then
        tiles[#tiles + 1] = {name = 'acid-refined-concrete', position = p}
        if cave_rivers < -0.502 then
            tiles[#tiles + 1] = {name = 'refined-hazard-concrete-right', position = p}
        end
        if random(1, 64) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        end
        return
    end

    local no_rocks = Public.get_noise('no_rocks', p, seed + seed)
    --Worm oil Zones
    if p.y < -64 + noise_cave_ponds * 10 then
        if no_rocks < 0.12 and no_rocks > -0.12 then
            if small_caves > 0.30 then
                tiles[#tiles + 1] = {name = 'brown-refined-concrete', position = p}
                if random(1, 450) == 1 then
                    entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
                end
                if random(1, 96) == 1 then
                    Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy',
                        note = true
                    }
                end

                if random(1, 1024) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
                end
                if random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
                end
                return
            end
        end
    end

    --Main Rock Terrain
    local no_rocks_2 = Public.get_noise('no_rocks_2', p, seed + seed)
    if no_rocks_2 > 0.66 or no_rocks_2 < -0.66 then
        local success = place_wagon(data, adjusted_zones)
        if success then
            return
        end
        tiles[#tiles + 1] = {name = base_tile, position = p}
        if random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        end

        if random(1, 512) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
        end
        return
    end

    if random(1, 2048) == 1 then
        treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
    end
    local random_tiles = Public.get_noise('forest_location', p, seed)
    if random_tiles > 0.095 then
        if random_tiles > 0.6 then
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = base_tile, position = p}
            end
        else
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = 'sand-2', position = p}
            end
        end
    end

    if random_tiles < -0.095 then
        if random_tiles < -0.6 then
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = base_tile, position = p}
            end
        else
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = 'lab-dark-1', position = p}
            end
        end
    end
    if random(1, 100) > 25 then
        entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
    end
end

local function starting_zone(x, y, data, void_or_lab, adjusted_zones)
    local p = {x = x, y = y}
    local seed = data.seed
    local buildings = data.buildings
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local small_caves = Public.get_noise('dungeons', p, seed + seed)
    local noise_cave_ponds = Public.get_noise('cave_ponds', p, seed + seed)
    local smol_areas = Public.get_noise('smol_areas', p, seed + seed)
    local no_rocks_2 = Public.get_noise('no_rocks_2', p, seed + seed)
    local cave_rivers = Public.get_noise('cave_rivers', p, seed)
    local no_rocks = Public.get_noise('no_rocks', p, seed)

    if smol_areas < 0.055 and smol_areas > -0.025 then
        entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        if random(1, 32) == 1 then
            Public.spawn_random_buildings(buildings, p, zone_settings.zone_depth)
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy'
            }
        end
        return
    end

    --Chasms
    if noise_cave_ponds < 0.105 and noise_cave_ponds > -0.112 then
        if small_caves > 0.52 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
        if small_caves < -0.52 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
    end

    --Water Ponds
    if noise_cave_ponds > 0.64 then
        if noise_cave_ponds > 0.74 then
            tiles[#tiles + 1] = {name = 'acid-refined-concrete', position = p}
            if random(1, 4) == 1 then
                markets[#markets + 1] = p
            end
            if random(1, 4) == 1 then
                entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = p}
            end
            return
        end
        tiles[#tiles + 1] = {name = 'deepwater', position = p}
        if random(1, 16) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    --Rivers
    if cave_rivers < 0.042 and cave_rivers > -0.062 then
        if noise_cave_ponds > 0.1 then
            tiles[#tiles + 1] = {name = 'water-shallow', position = p}
            if random(1, 64) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
            return
        end
    end

    if noise_cave_ponds > 0.622 then
        if noise_cave_ponds > 0.542 then
            if cave_rivers > -0.302 then
                tiles[#tiles + 1] = {name = 'refined-hazard-concrete-right', position = p}
            end
        end
        if random(1, 64) == 1 then
            entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = p}
        end
        return
    end

    --Worm oil Zones
    if no_rocks < 0.035 and no_rocks > -0.145 then
        if small_caves > 0.081 then
            tiles[#tiles + 1] = {name = 'brown-refined-concrete', position = p}
            if random(1, 250) == 1 then
                entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
            end
            if random(1, 96) == 1 then
                Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                entities[#entities + 1] = {
                    name = Biters.wave_defense_roll_worm_name(),
                    position = p,
                    force = 'enemy'
                }
            end

            if random(1, 1024) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
            end
            if random(1, 64) == 1 then
                entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
            end
            return
        end
    end

    --Main Rock Terrain
    if no_rocks_2 > 0.334 and no_rocks_2 < 0.544 then
        local success = place_wagon(data, adjusted_zones)
        if success then
            return
        end
        tiles[#tiles + 1] = {name = base_tile, position = p}
        if random(1, 18) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        end

        if random(1, 512) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
        end
        return
    end

    if random(1, 2048) == 1 then
        treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
    end
    tiles[#tiles + 1] = {name = base_tile, position = p}
    if random(1, 100) > 25 then
        entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
    end
end

local zones = {
    ['zone_1'] = zone_1,
    ['zone_2'] = zone_2,
    ['zone_3'] = zone_3,
    ['zone_4'] = zone_4,
    ['zone_5'] = zone_5,
    ['zone_forest_1'] = zone_forest_1,
    ['zone_forest_2'] = zone_forest_2,
    ['zone_scrap_1'] = zone_scrap_1,
    ['zone_scrap_2'] = zone_scrap_2,
    ['zone_7'] = zone_7,
    ['zone_9'] = zone_9,
    ['zone_10'] = zone_10,
    ['zone_11'] = zone_11,
    ['zone_12'] = zone_12,
    ['zone_13'] = zone_13,
    ['zone_14'] = zone_14
}

local function shuffle_terrains(adjusted_zones, new_zone)
    if not adjusted_zones.shuffled_terrains then
        shuffle(adjusted_zones.shuffled_zones)
        adjusted_zones.shuffled_terrains = new_zone
    end

    -- if adjusted_zones.shuffled_terrains and adjusted_zones.shuffled_terrains ~= new_zone then
    --     table.shuffle_table(zones)
    --     adjusted_zones.shuffled_terrains = new_zone
    -- end
end

local function is_out_of_map(p)
    if p.x < 480 and p.x >= -480 then
        return
    end
    return true
end

local function init_terrain(adjusted_zones)
    if adjusted_zones.init_terrain then
        return
    end

    local count = 1
    local shuffled_zones = {}

    for zone_name, _ in pairs(zones) do
        shuffled_zones[count] = zone_name
        count = count + 1
    end

    count = count - 1

    local shuffle_again = {}

    local size = 132

    for inc = 1, size do
        local map = shuffled_zones[random(1, count)]
        if map then
            shuffle_again[inc] = map
        end
    end
    shuffle_again = shuffle(shuffle_again)

    adjusted_zones.size = size
    adjusted_zones.shuffled_zones = shuffle_again
    adjusted_zones.init_terrain = true
end

local function process_bits(p, data, adjusted_zones)
    local left_top_y = data.area.left_top.y

    local index = floor((abs(left_top_y / zone_settings.zone_depth)) % adjusted_zones.size) + 1

    shuffle_terrains(adjusted_zones, index)

    local generate_zone
    if left_top_y >= -zone_settings.zone_depth then
        generate_zone = starting_zone
    else
        generate_zone = zones[adjusted_zones.shuffled_zones[index]]
        if not generate_zone then
            generate_zone = zones[adjusted_zones.shuffled_zones[adjusted_zones.size]]
        end
    end

    data.current_zone = index

    if data.forest_zone and not adjusted_zones.forest[index] then
        adjusted_zones.forest[index] = true
    end

    if data.scrap_zone and not adjusted_zones.scrap[index] then
        adjusted_zones.scrap[index] = true
    end

    local void_or_tile = Public.get('void_or_tile')

    local x = p.x
    local y = p.y

    generate_zone(x, y, data, void_or_tile, adjusted_zones)
end

local function border_chunk(p, data)
    local entities = data.entities
    local decoratives = data.decoratives
    local tiles = data.tiles

    local pos = p

    if random(1, ceil(pos.y + pos.y) + 64) == 1 then
        entities[#entities + 1] = {name = trees[random(1, #trees)], position = pos}
    end

    local noise = Public.get_noise('dungeon_sewer', pos, data.seed)
    local index = floor(noise * 32) % 11 + 1
    tiles[#tiles + 1] = {name = start_ground_tiles[index], position = pos}

    local scrap_mineable_entities, scrap_mineable_entities_index = get_scrap_mineable_entities()

    if not is_out_of_map(pos) then
        if random(1, ceil(pos.y + pos.y) + 32) == 1 then
            entities[#entities + 1] = {name = scrap_mineable_entities[random(1, scrap_mineable_entities_index)], position = pos, force = 'neutral'}
        end

        if random(1, pos.y + 2) == 1 then
            decoratives[#decoratives + 1] = {
                name = 'rock-small',
                position = pos,
                amount = random(1, 32)
            }
        end
        if random(1, pos.y + 2) == 1 then
            decoratives[#decoratives + 1] = {
                name = 'rock-tiny',
                position = pos,
                amount = random(1, 32)
            }
        end
    end
end

local function biter_chunk(p, data)
    local surface = data.surface
    local entities = data.entities
    local tile_positions = {}

    tile_positions[#tile_positions + 1] = p

    local disable_spawners = {
        callback = Public.deactivate_callback
    }
    local disable_worms = {
        callback = Public.active_not_destructible_callback
    }

    if random(1, 128) == 1 then
        local position = surface.find_non_colliding_position('biter-spawner', tile_positions[random(1, #tile_positions)], 16, 2)
        if position then
            entities[#entities + 1] = {
                name = spawner_raffle[random(1, #spawner_raffle)],
                position = position,
                force = 'enemy',
                callback = disable_spawners
            }
        end
    end

    if random(1, 128) == 1 then
        local position = surface.find_non_colliding_position('big-worm-turret', tile_positions[random(1, #tile_positions)], 16, 2)
        if position then
            entities[#entities + 1] = {
                name = 'big-worm-turret',
                position = position,
                force = 'enemy',
                callback = disable_worms
            }
        end
    end
end

local function out_of_map(p, data)
    local tiles = data.tiles
    tiles[#tiles + 1] = {name = 'out-of-map', position = p}
end

function Public.heavy_functions(data)
    local top_y = data.top_y
    local surface = data.surface
    local p = data.position
    local get_tile = surface.get_tile(p)

    local adjusted_zones = Public.get('adjusted_zones')
    init_terrain(adjusted_zones)

    local map_name = 'mtn_v3'

    if string.sub(surface.name, 0, #map_name) ~= map_name then
        return
    end

    if not data.seed then
        data.seed = Public.get('random_seed')
    end

    if get_tile.valid and get_tile.name == 'out-of-map' then
        return
    end

    if top_y % zone_settings.zone_depth == 0 and top_y < 0 then
        Public.set('left_top', data.left_top)
        return wall(p, data)
    end

    if top_y < 0 then
        return process_bits(p, data, adjusted_zones)
    end

    if top_y > 120 then
        return out_of_map(p, data)
    end

    if top_y > 75 then
        return biter_chunk(p, data)
    end

    if top_y >= 0 then
        return border_chunk(p, data)
    end
end

Event.add(
    defines.events.on_chunk_generated,
    function(e)
        local surface = e.surface
        local map_name = 'mtn_v3'

        if string.sub(surface.name, 0, #map_name) ~= map_name then
            return
        end

        local area = e.area
        local left_top = area.left_top
        if not surface then
            return
        end
        if not surface.valid then
            return
        end

        local winter_mode = Public.get('winter_mode')
        if winter_mode then
            rendering.draw_sprite(
                {
                    sprite = 'tile/lab-white',
                    x_scale = 32,
                    y_scale = 32,
                    target = left_top,
                    surface = surface,
                    tint = {r = 0.6, g = 0.6, b = 0.6, a = 0.6},
                    render_layer = 'ground'
                }
            )
        end

        if left_top.y == -128 and left_top.x == -128 then
            local locomotive = Public.get('locomotive')
            if locomotive and locomotive.valid then
                local position = locomotive.position
                for _, entity in pairs(surface.find_entities_filtered({area = {{position.x - 5, position.y - 6}, {position.x + 5, position.y + 10}}, type = 'simple-entity'})) do
                    entity.destroy()
                end
            end
        end

        if left_top.y > 32 then
            game.forces.player.chart(surface, {{left_top.x, left_top.y}, {left_top.x + 31, left_top.y + 31}})
        end
    end
)

return Public
