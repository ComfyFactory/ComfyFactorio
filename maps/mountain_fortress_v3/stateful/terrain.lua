local Public = require 'maps.mountain_fortress_v3.stateful.table'
local map_name = 'boss_room'
local Task = require 'utils.task_token'
local random = math.random
local ceil = math.ceil
local floor = math.floor

local assign_locomotive_token =
    Task.register(
    function(event)
        local entity = event.entity
        if not entity or not entity.valid then
            return
        end

        entity.get_inventory(defines.inventory.fuel).insert({name = 'wood', count = 100})
        for y = -1, 0, 0.05 do
            local scale = random(50, 100) * 0.01
            rendering.draw_sprite(
                {
                    sprite = 'entity/small-biter',
                    orientation = random(0, 100) * 0.01,
                    x_scale = scale,
                    y_scale = scale,
                    tint = {random(60, 255), random(60, 255), random(60, 255)},
                    render_layer = 'selection-box',
                    target = entity,
                    target_offset = {-0.7 + random(0, 140) * 0.01, y},
                    surface = entity.surface
                }
            )
        end
        rendering.draw_light(
            {
                sprite = 'utility/light_medium',
                scale = 5.5,
                intensity = 1,
                minimum_darkness = 0,
                oriented = true,
                color = {255, 255, 255},
                target = entity,
                surface = entity.surface,
                visible = true,
                only_in_alt_mode = false
            }
        )
        entity.color = {random(2, 255), random(60, 255), random(60, 255)}
        Public.set_stateful('stateful_locomotive', entity)
        entity.minable = false
    end
)

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

local mud_tiles = {
    'water-mud',
    'water-shallow',
    'water-mud',
    'water-shallow',
    'water-mud',
    'water-shallow',
    'water-mud',
    'water-shallow',
    'water-mud',
    'water-shallow'
}

local tree_raffle = {
    'dry-tree',
    'tree-01',
    'tree-02-red',
    'tree-04',
    'tree-08-brown'
}
local size_of_tree_raffle = #tree_raffle

local function is_out_of_map(p)
    if p.x < 512 and p.x >= -512 then
        return
    end
    if p.y < 512 and p.y >= -512 then
        return
    end
    return true
end

local function void_tiles(p)
    if p.y > 480 then
        return false
    end
    if p.y < 160 and p.y >= -160 then
        return false
    end
    return true
end

local function enemy_spawn_positions(p)
    if p.x < 230 and p.x >= -242 then
        return false
    end
    return true
end

local function draw_rails(data)
    local entities = data.entities
    local y = data.yv
    -- for y = 0, 30, 2 do
    entities[#entities + 1] = {name = 'straight-rail', position = {0, data.top_y + y}, direction = defines.direction.north, force = 'player'}
    -- end
    if data.top_y == -32 then
        entities[#entities + 1] = {name = 'locomotive', position = {0, -24}, force = 'player', direction = defines.direction.north, callback = assign_locomotive_token}
    end
end

local function border_chunk(p, data)
    local decoratives = data.decoratives
    local tiles = data.tiles
    local entities = data.entities

    local pos = p

    if pos.y == 0 or pos.y > 0 then
        if random(1, ceil(pos.y + pos.y) + 64) == 1 then
            entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = pos, collision = true}
        end
    else
        if random(ceil(pos.y - pos.y) - 64, -1) == -1 then
            entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = pos, collision = true}
        end
    end

    local noise = Public.get_noise('dungeon_sewer', pos, data.seed)
    local index = floor(noise * 32) % 11 + 1
    tiles[#tiles + 1] = {name = start_ground_tiles[index], position = pos}

    if random(1, 128) == 1 then
        local name = 'biter-spawner'
        if random(1, 4) == 1 then
            name = 'spitter-spawner'
        end
        if enemy_spawn_positions(p) then
            entities[#entities + 1] = {name = name, position = pos, force = 'enemy', collision = true, active = false, destructible = false, random_active = true}
        end
    end

    if not is_out_of_map(pos) then
        if pos.y == 0 or pos.y >= 0 then
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
        else
            if random(pos.y - 2, -1) == -1 then
                decoratives[#decoratives + 1] = {
                    name = 'rock-small',
                    position = pos,
                    amount = random(1, 32)
                }
            end
            if random(pos.y - 2, -1) == -1 then
                decoratives[#decoratives + 1] = {
                    name = 'rock-tiny',
                    position = pos,
                    amount = random(1, 32)
                }
            end
        end
    end
end

local function oozy_tiles(p, seed, tiles)
    local noise = Public.get_noise('no_rocks_2', p, seed)
    local index = floor(noise * 32) % 9 + 1
    if noise < -0.3 then
        local noise_cave_ponds = Public.get_noise('cave_ponds', p, seed)
        local small_caves = Public.get_noise('small_caves', p, seed)
        if noise_cave_ponds < 0.45 and noise_cave_ponds > -0.45 then
            if small_caves > 0.45 then
                tiles[#tiles + 1] = {name = 'out-of-map', position = p}
                return
            end

            if small_caves < -0.45 then
                tiles[#tiles + 1] = {name = mud_tiles[index], position = p}
                return
            end
        end
    end
end

function Public.heavy_functions(data)
    local surface = data.surface
    local p = data.position
    local get_tile = surface.get_tile(p)

    if string.sub(surface.name, 0, #map_name) ~= map_name then
        return
    end

    if not data.seed then
        data.seed = surface.map_gen_settings.seed
    end

    if get_tile.valid and get_tile.name == 'out-of-map' then
        return
    end

    if void_tiles(p) then
        data.tiles[#data.tiles + 1] = {name = 'out-of-map', position = p}
        return
    end

    if p.y < 250 then
        border_chunk(p, data)
        oozy_tiles(p, data.seed, data.tiles)
        draw_rails(data)
    end
end

return Public
