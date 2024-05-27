local Event = require 'utils.event'
local simplex_noise = require 'utils.simplex_noise'.d2
local NoiseVectors = require 'utils.functions.noise_vector_path'
local MapFunctions = require 'utils.tools.map_functions'
local Scheduler = require 'utils.scheduler'

local island_radius = 6
local random = math.random
local sqrt = math.sqrt
local abs = math.abs
local ceil = math.ceil
local floor = math.floor

local rock_raffle = {
    'sand-rock-big',
    'sand-rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-huge'
}

local draw_path_tile_whitelist = {
    ['water'] = true,
    ['deepwater'] = true
}

local path_tile_names = {
    'grass-2',
    'grass-3',
    'grass-4',
    'dirt-1',
    'dirt-2',
    'dirt-3',
    'dirt-4',
    'dirt-5',
    'dirt-6',
    'dirt-7'
}

local function get_brush_unfiltered(size)
    local vectors = {}
    for x = size, size * -1, -1 do
        for y = size * -1, size, 1 do
            vectors[#vectors + 1] = {x = x, y = y}
        end
    end
    return vectors
end

local function get_vector(position)
    if position.x < 0 and position.y < 0 then
        return {-1, -1}
    end
    if position.x > 0 and position.y > 0 then
        return {1, 1}
    end
    if position.x > 0 and position.y < 0 then
        return {1, -1}
    end
    if position.x < 0 and position.y > 0 then
        return {-1, 1}
    end
end

local function add_path_decoratives(surface, tiles)
    local d = global.decorative_names[random(1, #global.decorative_names)]
    for _, t in pairs(tiles) do
        local noise = simplex_noise(t.position.x * 0.075, t.position.y * 0.075, game.surfaces[1].map_gen_settings.seed)
        if random(1, 3) == 1 and noise > 0 then
            surface.create_decoratives {check_collision = false, decoratives = {{name = d, position = t.position, amount = floor(abs(noise * 3)) + 1}}}
        end
    end
end

local place_bridge_token =
    Scheduler.set(
    function(event)
        log(serpent.block('place_bridge_token'))
        local surface = event.surface

        -- add_path_decoratives(surface, global.old_path_tiles)

        for _, tile in pairs(global.old_path_tiles) do
            local new_tile = surface.get_tile(tile.position)
            if new_tile and new_tile.valid and new_tile.name == 'water' then
                surface.set_tiles({{name = tile.name, position = tile.position}})
            end
        end
        global.old_path_tiles = nil
    end
)

local slowly_place_brige_tiles_token =
    Scheduler.set(
    function(event)
        local positions = event.positions
        local surface = event.surface
        log(serpent.block('setting tiles'))

        surface.set_tiles(positions, true)
    end
)

local calculate_bridge_token =
    Scheduler.set(
    function(event)
        local seed_1 = event.seed_1
        local seed_2 = event.seed_2
        local m = event.m
        local vector = event.vector
        local base_vector = event.base_vector
        local minimal_movement = event.minimal_movement
        local position = global.position
        local surface = event.surface
        local whitelist = event.whitelist
        local tile_name = event.tile_name
        local brush_vectors = event.brush_vectors
        local tick_index = event.tick_index
        local positions = {}

        for _, brush in pairs(brush_vectors) do
            local p = {x = position.x + brush.x, y = position.y + brush.y}
            if whitelist then
                local tile = surface.get_tile(p)
                if tile.valid then
                    if whitelist[tile.name] then
                        global.path_tiles[#global.path_tiles + 1] = {name = tile_name, position = p}
                        positions[#positions + 1] = {name = tile_name, position = p}
                    end
                end
            end
        end

        Scheduler.timeout(tick_index, slowly_place_brige_tiles_token, {positions = positions, surface = surface})

        -- surface.set_tiles(positions, true)

        global.old_path_tiles = global.path_tiles

        local noise = simplex_noise(position.x * m, position.y * m, seed_1)
        local noise_2 = simplex_noise(position.x * m, position.y * m, seed_2)

        vector[1] = base_vector[1] + noise
        vector[2] = base_vector[2] + noise_2

        if abs(vector[1]) < minimal_movement and abs(vector[2]) < minimal_movement then
            local i = random(1, 2)
            if vector[i] < 0 then
                vector[i] = minimal_movement * -1
            else
                vector[i] = minimal_movement
            end
        end

        global.position = {x = position.x + vector[1], y = position.y + vector[2]}
    end
)

local noise_vector_tiles_path_token =
    Scheduler.set(
    function(event)
        log(serpent.block('noise_vector_tiles_path_token'))
        local surface = event.surface
        local tbl_tiles = event.tbl_tiles
        local position = global.position
        local length = event.length
        local brush_size = event.brush_size
        local whitelist = event.whitelist
        local seed_1 = event.seed_1
        local seed_2 = event.seed_2
        local m = event.m

        global.vector = {}
        local minimal_movement = 0.40
        local brush_vectors = get_brush_unfiltered(brush_size)
        local tile_name = tbl_tiles[random(1, #tbl_tiles)]

        local base_vector = get_vector(position)

        game.print(serpent.block(base_vector))

        if (base_vector[1] == 1 or base_vector[1] == -1) and random(1, 2) == 1 then
            base_vector = {base_vector[1], 1}
        end

        local callback = Scheduler.get(calculate_bridge_token)

        Scheduler.return_callback(
            function(data)
                for _ = 1, length, 1 do
                    data.tick_index = data.tick_index + 10
                    callback(
                        {
                            seed_1 = seed_1,
                            seed_2 = seed_2,
                            m = m,
                            vector = global.vector,
                            base_vector = base_vector,
                            minimal_movement = minimal_movement,
                            position = position,
                            surface = surface,
                            whitelist = whitelist,
                            tile_name = tile_name,
                            brush_vectors = brush_vectors,
                            tick_index = data.tick_index
                        }
                    )
                    data.tick_index = data.tick_index + 1
                end
            end
        )
    end
)

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local function is_inside_island(x, y, radius)
    radius = radius or island_radius
    local distance_to_center = sqrt(x ^ 2 + y ^ 2)
    return distance_to_center < radius
end

local request_to_generate_chunks_token =
    Scheduler.set(
    function(event)
        local size = event.size
        local surface = event.surface
        local position = event.position or global.path_tiles[#global.path_tiles].position
        surface.request_to_generate_chunks(position, size)
        game.surfaces['island'].request_to_generate_chunks(position, size)
        log(serpent.block('generating chunks'))
        log(serpent.block(game.tick))
    end
)

local function resource_placement(surface, position, name, amount, tiles)
    local w_max = 256
    local h_max = 256

    local biases = {[0] = {[0] = 1}}
    local ti = 1

    local function grow(grid, t)
        local old = {}
        local new_count = 0
        for x, _ in pairs(grid) do
            for y, _ in pairs(_) do
                table.insert(old, {x, y})
            end
        end
        for _, pos in pairs(old) do
            local x, y = pos[1], pos[2]
            for dx = -1, 1, 1 do
                for dy = -1, 1, 1 do
                    local a, b = x + dx, y + dy
                    if (random() > 0.9) and (abs(a) < w_max) and (abs(b) < h_max) then
                        grid[a] = grid[a] or {}
                        if not grid[a][b] then
                            grid[a][b] = 1 - (t / tiles)
                            new_count = new_count + 1
                            if (new_count + t) == tiles then
                                return new_count
                            end
                        end
                    end
                end
            end
        end
        return new_count
    end

    repeat
        ti = ti + grow(biases, ti)
    until ti >= tiles

    local total_bias = 0
    for _, d in pairs(biases) do
        for _, bias in pairs(d) do
            total_bias = total_bias + bias
        end
    end

    for x, _ in pairs(biases) do
        for y, bias in pairs(_) do
            local c = amount * (bias / total_bias)
            if c < 1 then
                c = 1
            end
            surface.create_entity {
                name = name,
                amount = c,
                force = 'neutral',
                position = {position.x + x, position.y + y}
            }
        end
    end
end

local function island_noise(p, seed_1, seed_2, seed_3, divided_by)
    local noise_1 = simplex_noise(p.x * seed_m1, p.y * seed_m1, seed_1)
    local noise_2 = simplex_noise(p.x * seed_m2, p.y * seed_m2, seed_2)
    local noise_3 = simplex_noise(p.x * seed_m3, p.y * seed_m3, seed_3)
    local noise = abs(noise_1 + noise_2 + noise_3)
    divided_by = divided_by or 2.3
    noise = noise / divided_by
    return noise
end

local function find_dirt_tiles(surface, positions)
    local tiles = {}
    for i = 1, 8, 1 do
        local vectors = {{1, i}, {-1, i * -1}, {i, 1}, {i * -1, -1}}
        if global.current_stage == 1 then
            vectors = shuffle(vectors)
        end
        for _, v in pairs(vectors) do
            for _, tile_data in pairs(positions) do
                local pos = {x = tile_data.position.x + v[1], y = tile_data.position.y + v[2]}
                local tile = surface.get_tile(pos)
                if tile and tile.valid and tile.name ~= 'water' then
                    tiles[#tiles + 1] = tile.position
                end
            end
        end
    end

    return tiles
end

function find_dirt_tile(surface, position)
    for i = 1, 64, 1 do
        local vectors = {{1, i}, {-1, i * -1}, {i, 1}, {i * -1, -1}}
        if global.current_stage == 1 then
            vectors = shuffle(vectors)
        end
        for _, v in pairs(vectors) do
            local pos = {x = position.x + v[1], y = position.y + v[2]}
            local tile = surface.get_tile(pos)
            if tile and tile.valid and tile.name == 'water' then
                return tile.position
            end
        end
    end
end

local function get_radius(position, size, divided_by)
    local noise = island_noise(position, seed_1, seed_2, seed_3, divided_by)
    local rr = size
    return rr * 0.5 + noise * rr * 0.5
end

local function print_grid_value(value, surface, position, scale, offset)
    if not global.debug_island_values then
        return
    end

    local is_string = type(value) == 'string'
    local color = {r = 1, g = 1, b = 1}
    local text = value

    if not is_string then
        scale = scale or 1
        offset = offset or 0
        position = {x = position.x + offset, y = position.y + offset}
        local r = math.max(1, value) / scale
        local g = 1 - abs(value) / scale
        local b = math.min(1, value) / scale

        if (r > 0) then
            r = 0
        end

        if (b < 0) then
            b = 0
        end

        if (g < 0) then
            g = 0
        end

        r = abs(r)

        color = {r = r, g = g, b = b}

        text = floor(100 * value) * 0.01

        if (0 == text) then
            text = '0.00'
        end
    end

    text = tostring(text)

    local text_entity = surface.find_entity('flying-text', position)

    if text_entity then
        text_entity.text = text
        text_entity.color = color
        return
    end

    surface.create_entity {
            name = 'flying-text',
            color = color,
            text = text,
            position = position
        }.active = false
end

local place_tiles_token =
    Scheduler.set(
    function(event)
        local positions = event.positions
        local position = event.position
        local radius = event.radius
        local count = event.count
        local surface = event.surface

        global.market_positions = global.market_positions or {}
        global.tiles = global.tiles or {}

        local tiles = {}
        for i = 1, count do
            local x = positions[i].x
            local y = positions[i].y
            local p = {x = x + position.x, y = y + position.y}
            local tile_data = surface.get_tile(p)
            if tile_data and tile_data.valid and (tile_data.name == 'water' or tile_data.name == 'deepwater') then
                local distance = sqrt(x ^ 2 + y ^ 2)
                local tile
                local watery_tile
                local noise_radius = get_radius(p, radius)
                local market_radius = get_radius(p, radius - 10, 22)
                local main_tile = game.surfaces['island'].get_tile(x, y)
                if distance > market_radius - (radius + 4) * 0.135 and distance < market_radius - (radius - 4) * 0.135 then
                    if main_tile and main_tile.valid and distance < radius then
                        tile = {name = main_tile.name, position = p}
                    end

                    global.market_positions[#global.market_positions + 1] = p
                    print_grid_value(noise_radius, surface, p, 2, 0)
                end
                if distance < noise_radius - radius * 0.15 then
                    if main_tile and main_tile.valid then
                        tile = {name = main_tile.name, position = p}
                    end
                elseif distance < noise_radius - 10 then
                    watery_tile = {name = 'deepwater', position = p}
                end

                if tile then
                    tiles[#tiles + 1] = tile
                    global.tiles[#global.tiles + 1] = tile
                end
                if watery_tile then
                    tiles[#tiles + 1] = watery_tile
                end
            end
        end
        game.forces.player.chart(surface, {{position.x - 124, position.y - 124}, {position.x + 124, position.y + 124}})

        surface.set_tiles(tiles, true)
    end
)

local do_place_decorative_token =
    Scheduler.set(
    function(event)
        local count = event.count
        local pos_tbl = event.pos_tbl
        local surface = event.surface

        for i = 1, count do
            local decorative = pos_tbl[i]
            if decorative then
                local position = decorative.position
                local name = decorative.name
                local amount = decorative.amount
                surface.create_decoratives {
                    check_collision = true,
                    decoratives = {{name = name, position = position, amount = amount}}
                }
            end
        end
    end
)

local do_place_simple_entities_token =
    Scheduler.set(
    function(event)
        local count = event.count
        local pos_tbl = event.pos_tbl
        local surface = event.surface
        local seed = event.seed

        local tree = global.tree_raffle[random(1, #global.tree_raffle)]

        for i = 1, count do
            local position = pos_tbl[i]
            if position then
                if random(1, 32) == 1 then
                    local noise = simplex_noise(position.x * 0.02, position.y * 0.02, seed)
                    if noise > 0.75 or noise < -0.75 then
                        surface.create_entity({name = rock_raffle[random(1, #rock_raffle)], position = position})
                    end
                end

                if surface.can_place_entity({name = 'wooden-chest', position = position}) then
                    if random(1, 64) == 1 then
                        if simplex_noise(position.x * 0.02, position.y * 0.02, seed) > 0.25 then
                            surface.create_entity({name = tree, position = position})
                        end
                    end
                end

                if surface.can_place_entity({name = 'wooden-chest', position = position}) then
                    if random(1, 128) == 1 then
                        if simplex_noise(position.x * 0.02, position.y * 0.02, seed) > 0.25 then
                            local corpse = global.corpses_raffle[random(1, #global.corpses_raffle)]

                            local c = surface.create_entity({name = corpse, position = position})
                            if c and c.valid then
                                c.corpse_expires = false
                            end
                        end
                    end
                end
            end
        end
    end
)

local create_new_surface_token =
    Scheduler.set(
    function(event)
        if game.surfaces['island'] then
            return
        end

        local radius = event.radius

        local map_gen_settings = {}
        map_gen_settings.height = radius
        map_gen_settings.width = radius
        map_gen_settings.water = 0.001
        map_gen_settings.terrain_segmentation = 8
        map_gen_settings.seed = random(1, 999999999)
        map_gen_settings.cliff_settings = {cliff_elevation_interval = random(2, 16), cliff_elevation_0 = random(2, 16)}
        map_gen_settings.autoplace_controls = {
            ['coal'] = {frequency = 0, size = 0, richness = 0},
            ['stone'] = {frequency = 0, size = 0, richness = 0},
            ['copper-ore'] = {frequency = 0, size = 0, richness = 0},
            ['iron-ore'] = {frequency = 0, size = 0, richness = 0},
            ['uranium-ore'] = {frequency = 0, size = 0, richness = 0},
            ['crude-oil'] = {frequency = 0, size = 0, richness = 0},
            ['trees'] = {frequency = 50, size = 0.1, richness = random(0, 10) * 0.1},
            ['enemy-base'] = {frequency = 'none', size = 'none', richness = 'none'}
        }
        map_gen_settings.autoplace_settings = {
            ['tile'] = {
                settings = {
                    ['deepwater'] = {frequency = 1, size = 0, richness = 1},
                    ['deepwater-green'] = {frequency = 1, size = 0, richness = 1},
                    ['water'] = {frequency = 1, size = 0, richness = 1},
                    ['water-green'] = {frequency = 1, size = 0, richness = 1},
                    ['water-mud'] = {frequency = 1, size = 0, richness = 1},
                    ['water-shallow'] = {frequency = 1, size = 0, richness = 1}
                },
                treat_missing_as_default = true
            }
        }
        map_gen_settings.property_expression_names = {
            ['control-setting:aux:bias'] = '-0.500000',
            ['control-setting:moisture:bias'] = '0.500000',
            ['control-setting:moisture:frequency:multiplier'] = '4.000000',
            ['starting-lake-noise-amplitude'] = 0,
            ['starting-area'] = 0
        }
        if not game.surfaces['island'] then
            game.create_surface('island', map_gen_settings)
            local surface = game.surfaces['island']
            ---@diagnostic disable-next-line: param-type-mismatch
            surface.request_to_generate_chunks({0, 0}, ceil(max_island_radius / 32))
        end
    end
)

local clear_globals_token =
    Scheduler.set(
    function()
        global.tiles = {}
        global.market_positions = {}
    end
)

local function add_market_slot(market)
    market.add_market_item(
        {
            price = {{'coin', 1}},
            offer = {type = 'nothing', effect_description = 'Progress onwards to the next island!'}
        }
    )
end

function test(event)
    local surface = event.surface
    local radius = (event.radius / 2) - 10
    local position = event.position

    local tiles = surface.find_tiles_filtered({name = 'water', area = {{position.x - radius, position.y - radius}, {position.x + radius, position.y + radius}}})
    if global.current_stage == 1 then
        tiles = shuffle(tiles)
    end

    local pos = global.market_positions[#global.market_positions]
    local new_tile = find_dirt_tile(surface, pos)
    local new_pos = surface.find_non_colliding_position('rocket-silo', new_tile, 0, 4)

    if new_pos then
        local p = new_pos
        local market = surface.create_entity({name = 'market', position = p, force = 'player'})
        if market and market.valid then
            market.minable = false
            market.destructible = false
            rendering.draw_text {
                text = 'Checkpoint ' .. global.current_stage,
                surface = surface,
                target = {market.position.x, market.position.y - 3.5},
                color = {r = 0.98, g = 0.77, b = 0.22},
                scale = 2,
                font = 'heading-1',
                alignment = 'center',
                scale_with_zoom = false
            }
            add_market_slot(market)
            Scheduler.timeout(10, request_to_generate_chunks_token, {size = 8, surface = surface, position = market.position, sleep = game.tick + 500})
        end
        MapFunctions.draw_noise_tile_circle(p, 'blue-refined-concrete', surface, 12)
    end
end

local create_market_token =
    Scheduler.set(
    function(event)
        local surface = event.surface
        local radius = (event.radius / 2) - 10
        local position = event.position

        local tiles = surface.find_tiles_filtered({name = 'water', area = {{position.x - radius, position.y - radius}, {position.x + radius, position.y + radius}}})
        if global.current_stage == 1 then
            tiles = shuffle(tiles)
        end

        local pos = global.market_positions[#global.market_positions]
        local new_tile = find_dirt_tile(surface, pos)
        local new_pos = surface.find_non_colliding_position('rocket-silo', new_tile, 0, 4)

        if new_pos then
            local p = new_pos
            local market = surface.create_entity({name = 'market', position = p, force = 'player'})
            if market and market.valid then
                market.minable = false
                market.destructible = false
                rendering.draw_text {
                    text = 'Checkpoint ' .. global.current_stage,
                    surface = surface,
                    target = {market.position.x, market.position.y - 3.5},
                    color = {r = 0.98, g = 0.77, b = 0.22},
                    scale = 2,
                    font = 'heading-1',
                    alignment = 'center',
                    scale_with_zoom = false
                }
                add_market_slot(market)
                Scheduler.timeout(10, request_to_generate_chunks_token, {size = 8, surface = surface, position = market.position, sleep = game.tick + 500})
            end
            MapFunctions.draw_noise_tile_circle(p, 'blue-refined-concrete', surface, 12)
        end
    end
)

local do_place_entities_token =
    Scheduler.set(
    function(event)
        local surface = event.surface
        local position = event.position
        local radius = event.radius
        local main_island = event.main_island

        if main_island then
            MapFunctions.draw_noise_tile_circle(position, 'concrete', surface, 12)

            local chest_pos = {
                {x = position.x + 1, y = position.y + 5 * 0.5},
                {x = position.x - 1, y = position.y + 6},
                {x = position.x + 1, y = position.y - 5 * -0.5},
                {x = position.x - 1, y = position.y + 10 * -1}
            }
            shuffle(chest_pos)

            local chest_raff = {
                'crash-site-chest-1',
                'crash-site-chest-1',
                'crash-site-chest-2',
                'crash-site-chest-2'
            }

            global.infini_chest = surface.create_entity({name = chest_raff[random(1, #chest_raff)], position = {chest_pos[1].x, chest_pos[1].y}, force = 'neutral'})
            global.infini_chest.operable = false
            global.infini_chest.destructible = false
            global.infini_chest.minable = false
            rendering.draw_text {
                text = 'Free ammo',
                surface = surface,
                target = global.infini_chest,
                color = {r = 0.98, g = 0.77, b = 0.22},
                scale = 1.25,
                font = 'heading-1',
                alignment = 'center',
                scale_with_zoom = false
            }

            local _y = 55
            local ore_positions = {
                {x = position.x + 19, y = _y},
                {x = position.x - 52, y = _y * 0.5},
                {x = position.x + 33, y = 0},
                {x = position.x - 52, y = _y * -0.5},
                {x = position.x + 25, y = _y * -1}
            }
            shuffle(ore_positions)

            resource_placement(surface, ore_positions[1], 'copper-ore', 150000, 550)
            resource_placement(surface, ore_positions[2], 'iron-ore', 150000, 550)
            resource_placement(surface, ore_positions[3], 'coal', 130000, 550)
            resource_placement(surface, ore_positions[4], 'stone', 130000, 550)
        end

        local decoratives = game.surfaces['island'].find_decoratives_filtered({area = {{position.x - 100, position.y - 100}, {position.x + 100, position.y + 100}}})
        Scheduler.return_callback(
            function(data)
                for _, decorative in pairs(decoratives) do
                    local start_index = (data.table_index - 1) * data.total_calls + 1
                    local end_index = start_index + data.total_calls - 1

                    data.pos_tbl[data.point_index] = {position = {position.x + decorative.position.x, position.y + decorative.position.y}, name = decorative.decorative.name, amount = decorative.amount}

                    if data.iterator_index == end_index or data.iterator_index > #decoratives then
                        data.table_index = data.table_index + 1
                        data.tick_index = data.tick_index + 1
                        Scheduler.timeout(data.tick_index, do_place_decorative_token, {pos_tbl = data.pos_tbl, count = data.total_calls, surface = surface})
                        data.pos_tbl = {}
                        data.point_index = 1
                        if data.table_index > #decoratives then
                            break
                        end
                    end
                    data.iterator_index = data.iterator_index + 1
                    data.point_index = data.point_index + 1
                end
            end
        )

        local seed = random(1, 1000000)

        Scheduler.return_callback(
            function(data)
                for _, t in pairs(global.tiles) do
                    local start_index = (data.table_index - 1) * data.total_calls + 1
                    local end_index = start_index + data.total_calls - 1

                    data.pos_tbl[data.point_index] = t.position

                    if data.iterator_index == end_index or data.iterator_index > #global.tiles then
                        data.table_index = data.table_index + 1
                        data.tick_index = data.tick_index + 1
                        Scheduler.timeout(data.tick_index, do_place_simple_entities_token, {pos_tbl = data.pos_tbl, count = data.total_calls, surface = surface, seed = seed, child_id = do_place_decorative_token})
                        data.pos_tbl = {}
                        data.point_index = 1
                        if data.table_index > #global.tiles then
                            break
                        end
                    end
                    data.iterator_index = data.iterator_index + 1
                    data.point_index = data.point_index + 1
                end
            end
        )

        Scheduler.timeout(5, create_market_token, {child_id = do_place_simple_entities_token, surface = surface, position = position, radius = radius})
        Scheduler.timeout(15, clear_globals_token, {child_id = create_market_token})

        global.gamestate = 33
    end
)

local draw_island_inner_task_token =
    Scheduler.set(
    function(event)
        local surface = event.surface
        local position = event.position
        local radius = event.radius
        local main_island = event.main_island or false

        game.print('running')
        local count = 1
        local c = 1
        local positions = {}
        for y = radius * -1, radius, 1 do
            for x = radius * -1, radius, 1 do
                positions[count] = {x = x, y = y}
                count = count + 1
                if count == 256 then
                    c = c + 1
                    Scheduler.timeout(c, place_tiles_token, {positions = positions, position = position, radius = radius, count = 255, surface = surface})
                    count = 1
                    positions = {}
                end
            end
        end

        Scheduler.timeout(50, do_place_entities_token, {surface = surface, position = position, radius = radius, child_id = place_tiles_token, main_island = main_island})
    end
)

local set_new_island_token =
    Scheduler.set(
    function()
        local position = global.path_tiles[#global.path_tiles].position
        local radius = global.stages[global.current_stage].size
        global.path_tiles = nil
        draw_main_island(position, radius)
    end
)

local draw_bridge_token =
    Scheduler.set(
    function(event)
        log(serpent.block('drawing bridge'))
        log(serpent.block(game.tick))

        local position = event.position
        local surface = event.surface
        local seed_1 = random(1, 10000000)
        local seed_2 = random(1, 10000000)
        local m = random(1, 100) * 0.001

        global.path_tiles = {}

        Scheduler.timeout(
            1,
            noise_vector_tiles_path_token,
            {
                surface = surface,
                tbl_tiles = path_tile_names,
                position = position,
                length = 200,
                brush_size = 6,
                whitelist = draw_path_tile_whitelist,
                seed_1 = seed_1,
                seed_2 = seed_2,
                m = m
            },
            'noise_vector_tiles_path_1'
        )

        -- local test = global.path_tiles[#global.path_tiles].position
        -- game.print('[gps=' .. test.x .. ',' .. test.y .. ',' .. surface.name .. ']')

        -- Scheduler.timeout(
        --     20,
        --     noise_vector_tiles_path_token,
        --     {
        --         surface = surface,
        --         tbl_tiles = {'deepwater'},
        --         position = position,
        --         length = 200,
        --         brush_size = 10,
        --         whitelist = {['water'] = true},
        --         seed_1 = seed_1,
        --         seed_2 = seed_2,
        --         m = m,
        --         child_id = 'noise_vector_tiles_path_1'
        --     },
        --     'noise_vector_tiles_path_2'
        -- )

        Scheduler.timeout(10, request_to_generate_chunks_token, {size = 8, surface = surface, sleep = game.tick + 500})
        global.current_stage = global.current_stage + 1
        Scheduler.timeout(20, set_new_island_token, {child_id = request_to_generate_chunks_token, sleep = game.tick + 200})

        -- Scheduler.timeout(
        --     30,
        --     place_bridge_token,
        --     {
        --         surface = surface,
        --         child_id = {'noise_vector_tiles_path_2', set_new_island_token, create_new_surface_token, draw_island_inner_task_token}
        --     }
        -- )
    end
)

function draw_main_island(position, radius, main_island)
    local surface = game.surfaces[1]

    position = position or {x = 0, y = 0}
    radius = radius or 200

    if (position.x == 0 and position.y == 0) then
        main_island = true
    end

    if not seed_1 then
        seed_1 = random(1, 9999999)
        seed_2 = random(1, 9999999)
        seed_3 = random(1, 9999999)
        seed_m1 = (random(8, 16) * 0.1) / radius
        seed_m2 = (random(12, 24) * 0.1) / radius
        seed_m3 = (random(50, 100) * 0.1) / radius
    end

    Scheduler.timeout(5, create_new_surface_token, {sleep = game.tick + 10})
    Scheduler.timeout(10, draw_island_inner_task_token, {child_id = create_new_surface_token, surface = surface, radius = radius, position = position, main_island = main_island})

    global.gamestate = 33
end

local function on_chunk_generated(event)
    if event.surface.index ~= 1 then
        return
    end
    local left_top = event.area.left_top
    local surface = event.surface

    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local position = {x = left_top.x + x, y = left_top.y + y}
            if not is_inside_island(position.x, position.y) then
                surface.set_tiles {{name = 'water', position = position}}
            else
                surface.set_tiles({{name = 'black-refined-concrete', position = position}}, true)
            end
        end
    end
end

local function on_market_item_purchased(event)
    local entity = event.market
    if not entity or not entity.valid then
        return
    end

    local offer_index = event.offer_index
    local offers = entity.get_market_items()
    local bought_offer = offers[offer_index].offer
    if bought_offer.type ~= 'nothing' then
        return
    end
    if string.find(bought_offer.effect_description, 'onwards') then
        -- entity.remove_market_item(1)
        -- entity.operable = false
        global.position = entity.position

        game.print('bought offer')

        Scheduler.timeout(1, draw_bridge_token, {surface = entity.surface, position = global.position, child_id = request_to_generate_chunks_token})
    end
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
