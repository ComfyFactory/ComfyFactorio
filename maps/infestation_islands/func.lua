--created by Gerkiz
local Event = require 'utils.event'
local simplex_noise = require 'utils.math.simplex_noise'.d2
local MapFunctions = require 'utils.tools.map_functions'
local Scheduler = require 'utils.scheduler'
local Public = require 'maps.infestation_islands.table'
local Commands = require 'utils.commands'
local BuriedBiter = require 'maps.infestation_islands.buried_biters'
local Loot = require 'maps.infestation_islands.loot'
local ParticleEffects = require 'modules.particle_effects'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Server = require 'utils.server'
local MGS = require 'maps.infestation_islands.island_settings'
local Discord = require 'utils.discord_handler'
local Poll = require 'utils.gui.poll'
local Color = require 'utils.color_presets'

local island_keeper = '[color=blue]Island Keeper: [/color]'
local CommandColor = { r = 0.98, g = 0.66, b = 0.22 }
local island_radius = 6
local max_island_radius = 256
local random = math.random
local sqrt = math.sqrt
local abs = math.abs
local ceil = math.ceil
local floor = math.floor
local min = math.min

local quality_per_level = {}
for i = 0, 50 do
    local n = i / 50
    local w_normal, w_uncommon, w_rare, w_epic, w_legendary = 100, 0, 0, 0, 0

    if n > 0.2 then
        w_normal, w_uncommon = 70, 30
    end
    if n > 0.4 then
        w_normal, w_uncommon, w_rare = 65, 25, 10
    end
    if n > 0.6 then
        w_normal, w_uncommon, w_rare, w_epic = 50, 30, 15, 5
    end
    if n > 0.8 then
        w_normal, w_uncommon, w_rare, w_epic, w_legendary = 40, 30, 20, 8, 2
    end

    local total = w_normal + w_uncommon + w_rare + w_epic + w_legendary
    quality_per_level[i] =
    {
        thresholds =
        {
            w_normal / total,
            (w_normal + w_uncommon) / total,
            (w_normal + w_uncommon + w_rare) / total,
            (w_normal + w_uncommon + w_rare + w_epic) / total,
        }
    }
end

local valid_enemy_types =
{
    ['unit'] = true,
    ['turret'] = true,
    ['unit-spawner'] = true
}

local rock_raffle =
{
    'big-sand-rock',
    'big-sand-rock',
    'big-rock',
    'big-rock',
    'big-rock',
    'big-rock',
    'big-rock',
    'huge-rock',
    'huge-rock'
}

local plantable_soil =
{
    'natural-jellynut-soil',
    'artificial-jellynut-soil',
    'natural-yumako-soil',
    'artificial-yumako-soil',
    'wetland-yumako',
    'wetland-jellynut',
}

local qualities =
{
    'normal',
    'uncommon',
    'rare',
    'epic',
    'legendary'
}

local mining_chances_ores =
{
    { name = 'coal', chance = 26 },
    { name = 'copper-ore', chance = 21 },
    { name = 'iron-ore', chance = 20 },
    { name = 'stone', chance = 15 },
    { name = 'uranium-ore', chance = 10 },
    { name = 'spoilage', chance = 10 },
    { name = 'tungsten-ore', chance = 5 },
    { name = 'holmium-ore', chance = 5 },
    { name = 'calcite', chance = 5 },
    { name = 'lithium', chance = 5 },
    { name = 'jellynut', chance = 5 },
    { name = 'yumako', chance = 5 },
    { name = 'carbon', chance = 5 },
    { name = 'scrap', chance = 5 },
    { name = 'ice', chance = 5 },
}

local harvest_raffle_ores = {}
for _, data in pairs(mining_chances_ores) do
    for _ = 1, data.chance, 1 do
        harvest_raffle_ores[#harvest_raffle_ores + 1] = data.name
    end
end
local size_of_ore_raffle = #harvest_raffle_ores

local raw_ores =
{
    'copper-ore',
    'iron-ore',
    'coal',
    'stone',
    'uranium-ore',
    'calcite',
    'tungsten-ore',
    'scrap',
}

local oil_raffle =
{
    'sulfuric-acid-geyser',
    'lithium-brine',
    'fluorine-vent',
    'crude-oil',
}

local draw_path_tile_whitelist =
{
    ['water'] = true,
    ['deepwater'] = true,
    ['brash-ice'] = true,
    ['lava-hot'] = true,
    ['wetland-yumako'] = true,
    ['wetland-jellynut'] = true,
}

local path_tile_names =
{
    'highland-yellow-rock',
    'highland-yellow-rock',
    'highland-dark-rock-2',
    'highland-dark-rock-2',
    'highland-dark-rock',
    'highland-dark-rock',
    'midland-cracked-lichen-dull',
    'midland-cracked-lichen-dull',
    'midland-cracked-lichen-dark',
    'midland-cracked-lichen-dark',
    'midland-turquoise-bark-2',
    'midland-turquoise-bark-2',
    'midland-turquoise-bark',
    'midland-turquoise-bark',
    'lowland-dead-skin',
    'lowland-dead-skin',
    'lowland-dead-skin-2',
    'lowland-dead-skin-2',
    'lowland-red-vein-dead',
    'lowland-red-vein-dead',
}

local function get_brush_unfiltered(size)
    local vectors = {}
    for x = size, size * -1, -1 do
        for y = size * -1, size, 1 do
            vectors[#vectors + 1] = { x = x, y = y }
        end
    end
    return vectors
end

local function get_vector(position)
    if position.x < 0 and position.y < 0 then
        if random(1, 2) == 1 then
            return { -1, -1 }
        else
            return { 1, -1 }
        end
    end
    if position.x > 0 and position.y > 0 then
        if random(1, 2) == 1 then
            return { 1, 1 }
        else
            return { -1, 1 }
        end
    end
    if position.x > 0 and position.y < 0 then
        if random(1, 2) == 1 then
            return { 1, -1 }
        else
            return { -1, -1 }
        end
    end
    if position.x < 0 and position.y > 0 then
        if random(1, 2) == 1 then
            return { -1, 1 }
        else
            return { 1, 1 }
        end
    end
end

local find_items_on_ground_token =
    Scheduler.set(
        function (event)
            local surface = event.surface
            local position = event.position
            local radius = event.radius
            local area = { { x = (position.x + -radius), y = (position.y + -radius) }, { x = (position.x + radius), y = (position.y + radius) } }

            local ents = {}

            for _, entity in pairs(surface.find_entities_filtered { type = "item-entity", name = "item-on-ground", area = area }) do
                if entity.valid then
                    ents[#ents + 1] = entity
                end
            end

            if #ents > 2000 then
                Public.set('clear_items_on_ground', ents)
            end
        end
    )

local slowly_place_brige_tiles_token =
    Scheduler.set(
        function (event)
            local positions = event.positions
            local surface = event.surface
            surface.set_tiles(positions, true)
        end
    )


local do_place_decorative_token =
    Scheduler.set(
        function (event)
            local count = event.count
            local pos_tbl = event.pos_tbl
            local surface = event.surface

            for i = 1, count do
                local decorative = pos_tbl[i]
                if decorative then
                    local position = decorative.position
                    local name = decorative.name
                    local amount = decorative.amount
                    surface.create_decoratives
                    {
                        check_collision = true,
                        decoratives = { { name = name, position = position, amount = amount } }
                    }
                end
            end
        end
    )

local decoratives =
{
    'red-croton',
    'brown-hairy-grass',
    'muddy-stump',
    'green-bush-mini',
    'nuclear-ground-patch',
}

local calculate_bridge_token =
    Scheduler.set(
        function (event)
            local this = Public.get()
            local seed_1 = event.seed_1
            local seed_2 = event.seed_2
            local m = event.m
            local vector = event.vector
            local base_vector = event.base_vector
            local minimal_movement = event.minimal_movement
            local position = this.position
            local surface = event.surface
            local whitelist = event.whitelist
            local tile_name = event.tile_name
            local brush_vectors = event.brush_vectors
            local tick_index = event.tick_index
            local positions = {}
            local dec = {}

            for _, brush in pairs(brush_vectors) do
                local p = { x = position.x + brush.x, y = position.y + brush.y }
                if whitelist then
                    local tile = surface.get_tile(p)
                    if tile.valid then
                        if whitelist[tile.name] then
                            this.path_tiles[#this.path_tiles + 1] = { name = tile_name, position = p }
                            positions[#positions + 1] = { name = tile_name, position = p }
                            if random(1, 10) == 1 then
                                dec[#dec + 1] = { name = decoratives[random(1, #decoratives)], position = p, amount = 1 }
                            end
                        end
                    end
                end
            end

            Scheduler.timeout(tick_index, slowly_place_brige_tiles_token, { positions = positions, surface = surface })

            local data = { pos_tbl = dec }

            Scheduler.timeout(tick_index, do_place_decorative_token, { pos_tbl = data.pos_tbl, count = #dec, surface = surface })

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

            this.position = { x = position.x + vector[1], y = position.y + vector[2] }


            event.positions = positions

            return event
        end
    )


local noise_vector_tiles_path_token =
    Scheduler.set(
        function (event)
            local this = Public.get()
            local surface = event.surface
            local tbl_tiles = event.tbl_tiles
            local position = this.position
            local length = event.length
            local brush_size = event.brush_size
            local whitelist = event.whitelist
            local seed_1 = event.seed_1
            local seed_2 = event.seed_2
            local m = event.m

            this.vector = {}
            local minimal_movement = 0.40
            local brush_vectors = get_brush_unfiltered(brush_size)
            local tile_name = tbl_tiles[random(1, #tbl_tiles)]

            local base_vector = get_vector(position)

            local callback = Scheduler.get(calculate_bridge_token)

            Scheduler.return_callback(
                function (data)
                    for _ = 1, length, 1 do
                        callback(
                            {
                                seed_1 = seed_1,
                                seed_2 = seed_2,
                                m = m,
                                vector = this.vector,
                                base_vector = base_vector,
                                minimal_movement = minimal_movement,
                                position = position,
                                positions = {},
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

local set_centered_points_token =
    Scheduler.set(
        function ()
            local this = Public.get()
            local position = this.path_tiles[#this.path_tiles].position

            local radius = this.stages[this.current_stage].size

            if this.current_stage == this.last_level then
                radius = max_island_radius
            end

            local level_data =
            {
                position = position,
                level = this.current_level,
                radius = radius
            }

            if not next(level_data.position) then
                error('No position found for level ' .. this.current_level)
            end

            this.centered_points[this.current_level] = level_data
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
        function (event)
            local this = Public.get()
            local size = event.size
            local surface = event.surface
            local position = event.position or this.path_tiles[#this.path_tiles].position
            surface.request_to_generate_chunks(position, size)
            game.surfaces['island'].request_to_generate_chunks(position, size)
        end
    )

local function resource_placement(surface, position, name, amount, tiles)
    local w_max = 256
    local h_max = 256

    local biases = { [0] = { [0] = 1 } }
    local ti = 1

    local function grow(grid, t)
        local old = {}
        local new_count = 0
        for x, _ in pairs(grid) do
            for y, _ in pairs(_) do
                table.insert(old, { x, y })
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
            surface.create_entity
            {
                name = name,
                amount = c,
                force = 'neutral',
                position = { position.x + x, position.y + y }
            }
        end
    end
end

local function tile_placement(surface, position, name, tiles)
    local w_max = 256
    local h_max = 256

    local biases = { [0] = { [0] = 1 } }
    local ti = 1

    local function grow(grid, t)
        local old = {}
        local new_count = 0
        for x, _ in pairs(grid) do
            for y, _ in pairs(_) do
                table.insert(old, { x, y })
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
        for y, _ in pairs(_) do
            surface.set_tiles({ { name = name, position = { position.x + x, position.y + y } } }, true)
        end
    end
end

local function reward_level(surface, level)
    local radius = level.radius
    local ore = raw_ores[random(1, #raw_ores)]
    local oil = oil_raffle[random(1, #oil_raffle)]
    local offset_oil_position = { x = level.position.x - random(1, 20), y = level.position.y - random(1, 20) }
    MapFunctions.draw_oil_circle(offset_oil_position, oil, surface, 8, 50000)
    resource_placement(surface, level.position, ore, random(75000, 75000 * 3), radius * 3)

    if level.level > 1 then
        local position = { x = level.position.x + random(1, 20), y = level.position.y + random(1, 20) }
        tile_placement(surface, position, plantable_soil[random(1, #plantable_soil)], radius * 2)
    end
end

local function island_noise(p, divided_by)
    local this = Public.get()
    local seeds = this.seeds
    local noise_1 = simplex_noise(p.x * seeds.seed_m1, p.y * seeds.seed_m1, seeds.seed_1)
    local noise_2 = simplex_noise(p.x * seeds.seed_m2, p.y * seeds.seed_m2, seeds.seed_2)
    local noise_3 = simplex_noise(p.x * seeds.seed_m3, p.y * seeds.seed_m3, seeds.seed_3)
    local noise = abs(noise_1 + noise_2 + noise_3)
    divided_by = divided_by or 2.3
    noise = noise / divided_by
    return noise
end

local function connected_ground_size(surface, start, max_radius, max_count)
    local start_x, start_y = math.floor(start.x), math.floor(start.y)
    local queue, head = { { x = start_x, y = start_y } }, 1
    local visited = {}
    local count = 0
    local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

    local function key(x, y) return x .. "," .. y end

    while head <= #queue and count < max_count do
        local p = queue[head]; head = head + 1
        local k = key(p.x, p.y)
        if not visited[k] then
            visited[k] = true
            local t = surface.get_tile(p)
            if t and t.valid and not t.collides_with("water_tile") then
                count = count + 1
                for i = 1, 4 do
                    local nx, ny = p.x + dirs[i][1], p.y + dirs[i][2]
                    if math.abs(nx - start_x) <= max_radius and math.abs(ny - start_y) <= max_radius then
                        table.insert(queue, { x = nx, y = ny })
                    end
                end
            end
        end
    end
    return count
end

local function find_dirt_tile(surface, position)
    local this = Public.get()
    local min_island_tiles = 1500
    local check_radius = 64

    for r = 1, 64 do
        local vectors = { { r, 0 }, { -r, 0 }, { 0, r }, { 0, -r } }
        if this.current_stage == 1 then vectors = shuffle(vectors) end

        for _, v in ipairs(vectors) do
            local pos = { x = position.x + v[1], y = position.y + v[2] }
            local tile = surface.get_tile(pos)
            if tile and tile.valid and not tile.collides_with("water_tile") then
                if connected_ground_size(surface, pos, check_radius, min_island_tiles) >= min_island_tiles then
                    return tile.position
                end
            end
        end
    end
end

local function get_quality_for_stage(current_level, last_level)
    local level = current_level or 1
    local normalized = min(level / last_level, 1.0)
    local tier = floor(normalized * 50 + 0.5)
    local t = quality_per_level[tier].thresholds

    local r = random()
    if r < t[1] then
        return "normal"
    elseif r < t[2] then
        return "uncommon"
    elseif r < t[3] then
        return "rare"
    elseif r < t[4] then
        return "epic"
    else
        return "legendary"
    end
end



local function do_buried_biters()
    local current_level = Public.get('current_level')
    local centered_points = Public.get('centered_points')
    local center_position = centered_points[current_level]
    if not center_position then
        return
    end
    if current_level > 2 then
        local count = random(4, 10)
        local position = { x = center_position.position.x + random(1, 15), y = center_position.position.y + random(1, 30) }
        if random(1, 10) == 1 then
            BuriedBiter.buried_biter(game.surfaces[1], position, count, 'enemy', qualities[random(1, #qualities)])
        elseif random(1, 15) == 1 then
            BuriedBiter.buried_worm(game.surfaces[1], position, qualities[random(1, #qualities)])
        elseif random(1, 60) == 1 then
            BuriedBiter.buried_spawner(game.surfaces[1], position, 1, 'enemy')
        end
    end
end

local function check_alive_enemies()
    local this = Public.get()
    if this.alive_enemies <= 0 then
        return
    end

    if this.alive_enemies == 999 then
        return
    end

    local current_level = Public.get('current_level')
    local center_position = Public.get('centered_points')[current_level]
    if not center_position then
        center_position =
        {
            position = { x = 0, y = 0 }
        }
    end

    local count = game.surfaces[1].count_entities_filtered({ force = 'enemy', type = { 'unit', 'turret', 'unit-spawner', 'spider-unit' }, area = { { center_position.position.x - 256, center_position.position.y - 256 }, { center_position.position.x + 256, center_position.position.y + 256 } } })

    if this.alive_enemies == 0 then
        Public.complete_level()
        return
    end
    this.alive_enemies = count
    Public.complete_level()
end

local function update_evolution_static()
    local evolution_factor = Public.get('evolution_factor')
    if not evolution_factor then return end
    if evolution_factor <= 0 then
        return
    end

    local force = game.forces.enemy
    force.set_evolution_factor(evolution_factor, game.surfaces[1])
end

local function update_evolution(this)
    local surface = game.surfaces[1]
    local force = game.forces.enemy

    local normalized = math.min(this.current_level / this.last_level, 1)
    local curve = math.pow(normalized, 1.3)

    local evolution_factor = math.max(0.05, math.min(curve, 1.0))

    this.evolution_factor = evolution_factor

    force.set_evolution_factor(evolution_factor, surface)
    Server.output_script_data(string.format("[Evo] Island level %d -> evolution %.2f", this.current_level, evolution_factor))
end

local function get_radius(position, size, divided_by)
    local noise = island_noise(position, divided_by)
    local rr = size
    return rr * 0.5 + noise * rr * 0.5
end

local function print_grid_value(value, surface, position, scale, offset)
    local this = Public.get()
    if not this.debug_island_values then
        return
    end

    local is_string = type(value) == 'string'
    local color = { r = 1, g = 1, b = 1 }
    local text = value

    if not is_string then
        scale = scale or 1
        offset = offset or 0
        position = { x = position.x + offset, y = position.y + offset }
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

        color = { r = r, g = g, b = b }

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

    surface.create_entity
    {
        name = 'flying-text',
        color = color,
        text = text,
        position = position
    }.active = false
end

local function get_tile_name_by_level(level)
    local tile_names =
    {
        'deepwater',
        'brash-ice',
        'lava-hot',
        'wetland-yumako',
        'wetland-jellynut',
    }
    return tile_names[(level - 1) % #tile_names + 1]
end

local place_tiles_token =
    Scheduler.set(
        function (event)
            local this = Public.get()
            local positions = event.positions
            local position = event.position
            local radius = event.radius
            local count = event.count
            local surface = event.surface

            local tiles = {}
            for i = 1, count do
                local x = positions[i].x
                local y = positions[i].y
                local p = { x = x + position.x, y = y + position.y }
                local tile_data = surface.get_tile(p)
                if tile_data and tile_data.valid and (tile_data.name == 'water' or tile_data.name == 'deepwater' or tile_data.name == 'brash-ice' or tile_data.name == 'lava-hot') then
                    local distance = sqrt(x ^ 2 + y ^ 2)
                    local tile
                    local watery_tile
                    local noise_radius = get_radius(p, radius)
                    local market_radius = get_radius(p, radius - 10, 22)
                    local main_tile = game.surfaces['island'].get_tile(x, y)
                    if distance > market_radius - (radius + 4) * 0.135 and distance < market_radius - (radius - 4) * 0.135 then
                        if main_tile and main_tile.valid and distance < radius then
                            tile = { name = main_tile.name, position = p }
                        end

                        this.market_positions[#this.market_positions + 1] = p
                        print_grid_value(noise_radius, surface, p, 2, 0)
                    end
                    if distance < noise_radius - radius * 0.15 then
                        if main_tile and main_tile.valid then
                            tile = { name = main_tile.name, position = p }
                        end
                    elseif distance < noise_radius - 5 then
                        local tile_name = get_tile_name_by_level(this.current_level)
                        watery_tile = { name = tile_name, position = p }
                    end

                    if tile then
                        tiles[#tiles + 1] = tile
                        this.tiles[#this.tiles + 1] = tile
                    end
                    if watery_tile then
                        tiles[#tiles + 1] = watery_tile
                    end
                end
            end
            game.forces.player.chart(surface, { { position.x - 124, position.y - 124 }, { position.x + 124, position.y + 124 } })

            surface.set_tiles(tiles, true)
        end
    )

local place_decoratives_token =
    Scheduler.set(
        function (event)
            local surface = event.surface
            local mirror_decorative = event.mirror_decorative
            for i = 1, #mirror_decorative do
                local decorative = mirror_decorative[i]
                local tile = surface.get_tile(decorative.position)
                if decorative and decorative.decorative and decorative.decorative.name and tile.valid and draw_path_tile_whitelist[tile.name] then
                    surface.create_decoratives
                    {
                        check_collision = true,
                        decoratives = { { name = decorative.decorative.name, position = decorative.position, amount = decorative.amount } }
                    }
                end
            end
        end
    )

local do_place_fish_token =
    Scheduler.set(
        function (event)
            local surface = event.surface
            local area = event.area
            for _, tile in pairs(surface.find_tiles_filtered({ name = 'water', area = area })) do
                if random(1, 32) == 1 then
                    surface.create_entity({ name = 'fish', position = tile.position })
                end
            end
        end
    )

local function disable_tech()
    local force = game.forces['player']
    -- force.technologies['landfill'].enabled = false
    force.technologies['night-vision-equipment'].enabled = false
    force.technologies['artillery-shell-range-1'].enabled = false
    force.technologies['artillery-shell-speed-1'].enabled = false
    force.technologies['artillery'].enabled = false
    force.technologies['atomic-bomb'].enabled = false
    force.technologies['planet-discovery-fulgora'].researched = true
    force.technologies['planet-discovery-gleba'].researched = true
    force.technologies['planet-discovery-vulcanus'].researched = true
    force.technologies['planet-discovery-aquilo'].researched = true
    force.technologies['recycling'].researched = true
    force.technologies['lithium-processing'].researched = true
    force.technologies['holmium-processing'].researched = true
    force.technologies['calcite-processing'].researched = true
    force.technologies['agriculture'].researched = true
    force.technologies['heating-tower'].researched = true
    force.technologies['tungsten-carbide'].researched = true
    force.technologies['quality-module'].researched = true
    force.recipes['rocket-silo'].enabled = false
    force.recipes['mech-armor'].enabled = false
    force.recipes['railgun-turret'].enabled = false
    force.recipes['artillery-turret'].enabled = false

    force.set_surface_hidden(game.surfaces['island'], true)
end

local gleba_trees =
{
    'jellystem',
    'yumako-tree'
}

local do_place_simple_entities_token =
    Scheduler.set(
        function (event)
            local this = Public.get()
            local count = event.count
            local pos_tbl = event.pos_tbl
            local surface = event.surface
            local seed = event.seed

            local tree = this.tree_raffle[random(1, #this.tree_raffle)]

            for i = 1, count do
                local position = pos_tbl[i]
                if position then
                    if random(1, 32) == 1 then
                        local noise = simplex_noise(position.x * 0.02, position.y * 0.02, seed)
                        if noise > 0.75 or noise < -0.75 then
                            surface.create_entity({ name = rock_raffle[random(1, #rock_raffle)], position = position })
                        end
                    end

                    if surface.can_place_entity({ name = 'wooden-chest', position = position }) then
                        if random(1, 64) == 1 then
                            if simplex_noise(position.x * 0.02, position.y * 0.02, seed) > 0.25 then
                                surface.create_entity({ name = tree, position = position, tick_grown = 9999 })
                            end
                        end
                    end

                    if random(1, 128) == 1 then
                        if simplex_noise(position.x * 0.02, position.y * 0.02, seed) > 0.25 then
                            surface.create_entity({ name = gleba_trees[random(1, #gleba_trees)], position = position, tick_grown = random(1, 999) })
                        end
                    end

                    if surface.can_place_entity({ name = 'wooden-chest', position = position }) then
                        if random(1, 128) == 1 then
                            if simplex_noise(position.x * 0.02, position.y * 0.02, seed) > 0.25 then
                                local corpse = this.corpses_raffle[random(1, #this.corpses_raffle)]

                                local c = surface.create_entity({ name = corpse, position = position })
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
        function (event)
            if game.surfaces['island'] then
                return
            end

            local radius = event.radius

            local map_gen_settings = MGS
            map_gen_settings.height = radius
            map_gen_settings.width = radius
            map_gen_settings.seed = random(1, 999999999)

            if not game.surfaces['island'] then
                game.create_surface('island', map_gen_settings)
                local surface = game.surfaces['island']
                surface.ignore_surface_conditions = true
                ---@diagnostic disable-next-line: param-type-mismatch
                surface.request_to_generate_chunks({ 0, 0 }, ceil(max_island_radius / 32))
            end
        end
    )

local clear_globals_token =
    Scheduler.set(
        function ()
            local this = Public.get()
            this.tiles = {}
            this.market_positions = {}
        end
    )

local create_rocket_silo_token =
    Scheduler.set(
        function (event)
            local surface = event.surface
            local this = Public.get()
            local center_position = event.center_position
            local rand_position =
            {
                x = center_position.position.x + random(-25, 25),
                y = center_position.position.y + random(-25, 25)
            }
            local new_position = surface.find_non_colliding_position('rocket-silo', rand_position, 128, 10)
            for x = new_position.x - 1, new_position.x + 1 do
                for y = new_position.y - 1, new_position.y + 1 do
                    local tile = surface.get_tile(x, y)
                    if not tile.collides_with('resource') then
                        new_position = tile.position
                        break
                    end
                end
            end


            local e = surface.create_entity({ name = 'rocket-silo', position = new_position, force = 'player' })
            if e and e.valid then
                this.rocket_silo = e
                game.forces.player.technologies['space-science-pack'].researched = true
                e.minable = false
                e.destructible = false
            end
        end
    )

local function roll_biter(level)
    local choices
    if not level or level <= 1 then
        choices = { 'small-biter', 'small-spitter' }
    elseif level <= 2 then
        choices = { 'small-biter', 'medium-biter', 'small-wriggler-pentapod', 'small-spitter', 'medium-spitter' }
    elseif level <= 5 then
        choices = { 'small-wriggler-pentapod', 'medium-biter', 'medium-wriggler-pentapod', 'small-spitter', 'medium-spitter' }
    elseif level <= 6 then
        choices = { 'medium-biter', 'big-biter', 'medium-wriggler-pentapod', 'small-strafer-pentapod', 'medium-spitter', 'big-spitter' }
    elseif level < 8 then
        choices = { 'big-biter', 'small-wriggler-pentapod', 'medium-wriggler-pentapod', 'big-biter', 'big-wriggler-pentapod', 'small-strafer-pentapod', 'medium-strafer-pentapod', 'big-spitter' }
    else
        choices = { 'big-biter', 'big-wriggler-pentapod', 'behemoth-biter', 'medium-wriggler-pentapod', 'big-strafer-pentapod', 'big-strafer-pentapod', 'medium-spitter', 'big-spitter', 'behemoth-spitter' }
    end
    return choices[random(1, #choices)]
end

local function create_units_and_command(unit_count, market, surface, center_position, current_level)
    local commands = {}
    commands[#commands + 1] =
    {
        type = defines.command.attack_area,
        destination = { x = market.position.x, y = market.position.y },
        radius = 125,
        distraction = defines.distraction.by_anything
    }

    local unit_group = surface.create_unit_group({ position = center_position.position, force = 'enemy' }) --[[@as LuaCommandable]]

    for _ = 1, unit_count do
        local p = surface.find_non_colliding_position('wooden-chest', center_position.position, 128, 4)
        if p then
            local biter = surface.create_entity({ name = roll_biter(current_level), position = p, force = 'enemy' })
            if biter and biter.valid then
                if unit_group and unit_group.valid then
                    unit_group.add_member(biter)
                end
            end
        end
    end

    if not unit_group or not unit_group.valid then
        return
    end

    unit_group.set_command(
        {
            type = defines.command.compound,
            structure_type = defines.compound_command.return_last,
            commands = commands
        }
    )
end

local function run_clear_items_on_ground()
    local this = Public.get()
    if not this.centered_points or not next(this.centered_points) then
        return
    end

    if not this.checked_island then
        this.checked_island = {}
    end


    for island_level, data in pairs(this.centered_points) do
        this.checked_island[island_level] = this.checked_island[island_level] or { next_check = 0 }
        if this.checked_island[island_level] and game.tick < this.checked_island[island_level].next_check then
            goto continue
        end

        if data and data.position then
            local radius = (data.radius or 0) + 100

            Scheduler.timeout(20, find_items_on_ground_token,
                {
                    surface = game.surfaces[1],
                    position = data.position,
                    radius = radius
                })

            this.checked_island[island_level] = { next_check = game.tick + 6000 }
            break
        end
        ::continue::
    end
end

local function do_clear_items_on_ground_slowly()
    local clear_items_on_ground = Public.get('clear_items_on_ground')
    if not clear_items_on_ground or not next(clear_items_on_ground) then
        return
    end

    for _ = 1, 250 do
        local entity = table.remove(clear_items_on_ground, #clear_items_on_ground)
        if entity and entity.valid then
            entity.destroy()
        end
    end
end

local function set_multi_command()
    local current_level = Public.get('current_level')
    local spawned_markets = Public.get('spawned_markets')

    local disable_multi_command_attack = Public.get('disable_multi_command_attack')
    if disable_multi_command_attack then
        return
    end

    local alive_enemies = Public.get('alive_enemies')
    if alive_enemies == 0 or alive_enemies == 999 then
        return
    end

    local attack_grace_period = Public.get('attack_grace_period')
    if attack_grace_period and attack_grace_period > game.tick then
        return
    else
        local notified_enemies_to_attack = Public.get('notified_enemies_to_attack')
        if not notified_enemies_to_attack[current_level] then
            game.print(island_keeper .. 'The bugs have smelled the market at island level ' .. current_level - 1 .. ' and are swarming toward it!')
            notified_enemies_to_attack[current_level] = true
        end
    end

    local last_attack_tick = Public.get('last_attack_tick')
    if last_attack_tick and last_attack_tick > game.tick then
        return
    end

    local check_surface_daytime_for_attacks = Public.get('check_surface_daytime_for_attacks')

    local surface = game.surfaces[1]
    if check_surface_daytime_for_attacks then
        if surface.daytime < 0.35 then
            return
        end
        if surface.daytime > 0.65 then
            return
        end
    end

    Public.set('last_attack_tick', game.tick + 2000)

    if current_level == 1 then
        return -- we don't attack during the first level
    end

    local market = spawned_markets[current_level - 1] and spawned_markets[current_level - 1].market
    if not market or not market.valid then
        return
    end

    local center_position = Public.get('centered_points')[current_level]
    if not center_position then
        center_position =
        {
            position = { x = 0, y = 0 }
        }
    end

    local difficulty_index = Difficulty.get('index')
    local base_min, base_max
    if difficulty_index == 1 then
        base_min, base_max = 16, 32
    elseif difficulty_index == 2 then
        base_min, base_max = 32, 64
    else
        base_min, base_max = 64, 128
    end

    local scale = math.max(1, current_level * 0.1)
    local unit_count = random(base_min * scale, base_max * scale)
    unit_count = math.floor(unit_count)

    create_units_and_command(unit_count, market, surface, center_position, current_level)

    if random(1, 10) == 1 then
        local limit = 1
        if current_level > 5 then
            limit = 2
        elseif current_level > 8 then
            limit = 4
        end

        local p = center_position.position
        local enemies = surface.find_entities_filtered({ type = 'spider-unit', force = 'enemy', area = { { p.x - 125, p.y - 125 }, { p.x + 125, p.y + 125 } }, limit = limit })
        if enemies and enemies[1] then
            for _, enemy in pairs(enemies) do
                if enemy and enemy.valid then
                    enemy.commandable.set_command(
                        {
                            type = defines.command.attack_area,
                            destination = market.position,
                            radius = 125,
                            distraction = defines.distraction.by_anything
                        }
                    )
                end
            end
        end
    end
end

local function add_market_slot(market)
    local this = Public.get()
    local current_level = Public.get('current_level')
    this.market_prices[market.unit_number] = {}
    local offers =
    {
        {
            price = {},
            offer = { type = 'nothing', effect_description = 'Progress onwards to the next island!' }
        }
    }
    if random(1, 4) == 1 then
        offers[#offers + 1] =
        {
            price = {},
            offer = { type = 'nothing', effect_description = 'Generate more ammo in the infinity chest!\nPrice: ' .. 500 * current_level .. ' coins' }
        }
        this.market_prices[market.unit_number]['ammo'] = 500 * current_level
    end
    if not this.piercing_ammo_grants and (current_level >= 1 and current_level <= 3) and not this.piercing_ammo_grants_added then
        if random(1, 6) == 1 then
            offers[#offers + 1] =
            {
                price = {},
                offer = { type = 'nothing', effect_description = 'Generate piercing rounds ammo in the infinity chest!\nPrice: ' .. 1000 * current_level .. ' coins' }
            }
            this.piercing_ammo_grants_added = true
            this.market_prices[market.unit_number]['piercing'] = 1000 * current_level
        end
    end
    if not this.uranium_ammo_grants and (current_level >= 7 and current_level <= this.last_level) and not this.uranium_ammo_grants_added then
        if random(1, 12) == 1 then
            offers[#offers + 1] =
            {
                price = {},
                offer = { type = 'nothing', effect_description = 'Generate uranium rounds ammo in the infinity chest!\nPrice: ' .. 1000 * current_level .. ' coins' }
            }
            this.market_prices[market.unit_number]['uranium'] = 1000 * current_level
            this.uranium_ammo_grants_added = true
        end
    end
    for _, offer in pairs(offers) do
        market.add_market_item(offer)
    end
end

local create_biters_token =
    Scheduler.set(
        function (event)
            local this = Public.get()
            local surface = event.surface
            local position = event.position
            local level = this.current_level or 1
            this.alive_enemies = 0
            local base_enemy_count

            local biter_types
            local spitter_types
            local worm_types
            local spawner_types

            local spawn_qualities
            local difficulty_index = Difficulty.get('index')
            local raw_level = level
            level = level * (difficulty_index + 10)

            if raw_level <= 2 then
                biter_types = { 'small-biter', 'small-wriggler-pentapod' }
                spitter_types = { 'small-spitter' }
                worm_types = { 'small-worm-turret' }
                spawner_types = { 'biter-spawner', 'spitter-spawner', 'gleba-spawner-small', 'gleba-spawner-small' }
                spawn_qualities = { 'normal', 'normal' }
                base_enemy_count = 30 + (level * 10)
            elseif raw_level <= 3 then
                biter_types = { 'small-biter', 'small-wriggler-pentapod', 'small-strafer-pentapod', 'medium-biter', 'medium-wriggler-pentapod' }
                spitter_types = { 'small-spitter' }
                worm_types = { 'small-worm-turret' }
                spawner_types = { 'biter-spawner', 'spitter-spawner', 'gleba-spawner-small', 'gleba-spawner-small' }
                spawn_qualities = { 'normal', 'normal' }
                base_enemy_count = 30 + (level * 8)
            elseif raw_level <= 6 then
                biter_types = { 'small-biter', 'small-wriggler-pentapod', 'medium-biter', 'medium-wriggler-pentapod', 'small-strafer-pentapod', 'medium-strafer-pentapod' }
                spitter_types = { 'small-spitter', 'medium-spitter' }
                worm_types = { 'small-worm-turret', 'medium-worm-turret' }
                spawner_types = { 'biter-spawner', 'spitter-spawner', 'gleba-spawner', 'gleba-spawner', 'gleba-spawner-small', 'gleba-spawner-small' }
                spawn_qualities = { 'uncommon', 'uncommon', 'rare' }
                base_enemy_count = 30 + (level * 6)
            elseif raw_level < 8 then
                biter_types = { 'small-biter', 'small-wriggler-pentapod', 'medium-biter', 'medium-wriggler-pentapod', 'big-biter', 'big-wriggler-pentapod', 'small-strafer-pentapod', 'medium-strafer-pentapod' }
                spitter_types = { 'small-spitter', 'medium-spitter', 'big-spitter' }
                worm_types = { 'small-worm-turret', 'medium-worm-turret', 'big-worm-turret' }
                spawner_types = { 'biter-spawner', 'spitter-spawner', 'gleba-spawner', 'gleba-spawner' }
                spawn_qualities = { 'rare', 'rare', 'uncommon', 'rare' }
                if difficulty_index == 1 then
                    spitter_types[#spitter_types + 1] = 'small-stomper-pentapod'
                elseif difficulty_index == 2 then
                    spitter_types[#spitter_types + 1] = 'medium-stomper-pentapod'
                elseif difficulty_index == 3 then
                    spitter_types[#spitter_types + 1] = 'big-stomper-pentapod'
                end
                base_enemy_count = 30 + (level * 4)
            else
                biter_types = { 'big-biter', 'big-wriggler-pentapod', 'behemoth-biter', 'medium-wriggler-pentapod', 'big-strafer-pentapod', 'big-strafer-pentapod' }
                spitter_types = { 'big-spitter', 'behemoth-spitter', 'behemoth-spitter' }
                worm_types = { 'big-worm-turret', 'behemoth-worm-turret', 'behemoth-worm-turret' }
                spawner_types = { 'biter-spawner', 'spitter-spawner', 'gleba-spawner', 'gleba-spawner' }
                spawn_qualities = { 'epic', 'epic', 'legendary', 'legendary' }
                if difficulty_index == 1 then
                    spitter_types[#spitter_types + 1] = 'medium-stomper-pentapod'
                elseif difficulty_index == 2 then
                    spitter_types[#spitter_types + 1] = 'big-stomper-pentapod'
                elseif difficulty_index == 3 then
                    spitter_types[#spitter_types + 1] = 'big-stomper-pentapod'
                end
                base_enemy_count = 30 + (level * 5)
            end



            local final_battle = this.final_battle

            local random_positions =
            {
                { x = position.x + 10, y = position.y + 10 },
                { x = position.x - 10, y = position.y + 10 },
                { x = position.x + 10, y = position.y - 10 },
                { x = position.x - 10, y = position.y - 10 },
                { x = position.x + 15, y = position.y + 10 },
                { x = position.x - 15, y = position.y - 10 },
                { x = position.x + 10, y = position.y - 15 },
                { x = position.x - 10, y = position.y + 15 }
            }

            shuffle(random_positions)

            position = random_positions[random(1, #random_positions)]

            local spawner_count = math.min(random(1, 2) + math.floor(level / 3), level / 2)
            if final_battle then
                spawner_count = 64
            end
            if this.current_level == 1 then
                spawner_count = 0
            end
            for _ = 1, spawner_count do
                local spawner_type = spawner_types[random(1, #spawner_types)]
                local p = surface.find_non_colliding_position('rocket-silo', position, 128, 10)
                if p then
                    local spawner = surface.create_entity({ name = spawner_type, position = p, quality = spawn_qualities[random(1, #spawn_qualities)] })
                    if spawner and spawner.valid then
                        this.alive_enemies = this.alive_enemies + 1
                    end
                end
            end

            shuffle(random_positions)
            position = random_positions[random(1, #random_positions)]

            local worm_count = random(12, 64)
            if this.current_level == 1 then
                worm_count = 0
            end
            if final_battle then
                worm_count = 128
            end
            for _ = 1, worm_count do
                local worm_type = worm_types[random(1, #worm_types)]
                local p = surface.find_non_colliding_position('rocket-silo', position, 128, 10)
                if p then
                    local e = surface.create_entity({ name = worm_type, position = p, quality = spawn_qualities[random(1, #spawn_qualities)] })
                    if e and e.valid then
                        this.alive_enemies = this.alive_enemies + 1
                    end
                end
            end

            shuffle(random_positions)
            position = random_positions[random(1, #random_positions)]

            local enemy_count = random(base_enemy_count, base_enemy_count + 30)
            if this.current_level == 1 then
                enemy_count = 4
            end
            if final_battle then
                enemy_count = 1100
            end
            for _ = 1, enemy_count do
                local enemy_type
                if random(1, 2) == 1 then
                    enemy_type = biter_types[random(1, #biter_types)]
                else
                    enemy_type = spitter_types[random(1, #spitter_types)]
                end

                local p = surface.find_non_colliding_position('wooden-chest', position, 128, 4)
                if p then
                    local e = surface.create_entity({ name = enemy_type, position = p, quality = spawn_qualities[random(1, #spawn_qualities)] })
                    if e and e.valid then
                        e.ai_settings.allow_try_return_to_spawner = false
                        e.ai_settings.allow_destroy_when_commands_fail = false
                        this.alive_enemies = this.alive_enemies + 1
                    end
                end
            end

            shuffle(random_positions)
            position = random_positions[random(1, #random_positions)]

            if final_battle then
                for _ = 1, 128 do
                    local p = surface.find_non_colliding_position('gun-turret', position, 128, 10)
                    if p then
                        local e = surface.create_entity({ name = 'gun-turret', position = p, force = 'enemy', quality = spawn_qualities[random(1, #spawn_qualities)] })
                        if e and e.valid then
                            e.insert({ name = 'uranium-rounds-magazine', count = 200, quality = spawn_qualities[random(1, #spawn_qualities)] })
                            this.alive_enemies = this.alive_enemies + 1
                        end
                    end
                end
            end

            game.forces.player.chart(surface, { { position.x - 124, position.y - 124 }, { position.x + 124, position.y + 124 } })
        end
    )

local create_market_token =
    Scheduler.set(
        function (event)
            local this = Public.get()
            local surface = event.surface

            local random_pos = shuffle(this.market_positions)
            local pos = random_pos[#random_pos]
            if not pos then
                error('No market position found!')
            end
            local new_tile = find_dirt_tile(surface, pos)
            local new_pos = surface.find_non_colliding_position('rocket-silo', new_tile, 0, 4)

            if new_pos then
                local p = new_pos
                local market = surface.create_entity({ name = 'market', position = p, force = 'player', quality = qualities[random(1, #qualities)] })
                game.forces.player.chart(surface, { { p.x - 30, p.y - 30 }, { p.x + 30, p.y + 30 } })
                if market and market.valid then
                    market.minable = false
                    local render_protect_text = rendering.draw_text
                        {
                            text = 'Protect this market at all costs!',
                            surface = surface,
                            target = { market.position.x, market.position.y - 4.5 },
                            color = { r = 0.98, g = 0.77, b = 0.22 },
                            scale = 2,
                            font = 'heading-1',
                            alignment = 'center',
                            scale_with_zoom = false
                        }
                    if this.current_stage > 1 then
                        market.destructible = false
                    end

                    local render_checkpoint_text = rendering.draw_text
                        {
                            text = 'Checkpoint ' .. this.current_stage,
                            surface = surface,
                            target = { market.position.x, market.position.y - 3.5 },
                            color = { r = 0.98, g = 0.77, b = 0.22 },
                            scale = 2,
                            font = 'heading-1',
                            alignment = 'center',
                            scale_with_zoom = false
                        }
                    this.spawned_markets[this.current_stage] = { market = market, render_protect_text = render_protect_text, render_checkpoint_text = render_checkpoint_text }

                    add_market_slot(market)
                    Scheduler.timeout(10, request_to_generate_chunks_token, { size = 8, surface = surface, position = market.position, sleep = game.tick + 500 })
                end
                MapFunctions.draw_noise_tile_circle(p, 'blue-refined-concrete', surface, 12)
            end
        end
    )

local do_place_entities_token =
    Scheduler.set(
        function (event)
            local this = Public.get()
            local surface = event.surface
            local position = event.position
            local radius = event.radius
            local main_island = event.main_island

            if main_island then
                MapFunctions.draw_noise_tile_circle(position, 'concrete', surface, 12)

                local chest_pos =
                {
                    { x = position.x + 1, y = position.y + 5 * 0.5 },
                    { x = position.x - 1, y = position.y + 6 },
                    { x = position.x + 1, y = position.y - 5 * -0.5 },
                    { x = position.x - 1, y = position.y + 10 * -1 }
                }
                shuffle(chest_pos)

                local chest_raff =
                {
                    'crash-site-chest-1',
                    'crash-site-chest-1',
                    'crash-site-chest-2',
                    'crash-site-chest-2'
                }

                this.infini_chest = surface.create_entity({ name = chest_raff[random(1, #chest_raff)], position = { chest_pos[1].x, chest_pos[1].y }, force = 'neutral' })
                this.infini_chest.operable = false
                this.infini_chest.destructible = false
                this.infini_chest.minable = false
                this.render_ammo_text = rendering.draw_text
                    {
                        text = 'Free ammo',
                        surface = surface,
                        target = this.infini_chest,
                        color = { r = 0.98, g = 0.77, b = 0.22 },
                        scale = 1.25,
                        font = 'heading-1',
                        alignment = 'center',
                        scale_with_zoom = false
                    }

                local _y = 55
                local ore_positions =
                {
                    { x = position.x + 19, y = _y },
                    { x = position.x - 52, y = _y * 0.5 },
                    { x = position.x + 33, y = 0 },
                    { x = position.x - 52, y = _y * -0.5 },
                    { x = position.x + 25, y = _y * -1 },
                    { x = position.x - 25, y = _y * -1 }
                }
                shuffle(ore_positions)

                resource_placement(surface, ore_positions[1], 'copper-ore', 150000, 550)
                resource_placement(surface, ore_positions[2], 'iron-ore', 150000, 550)
                resource_placement(surface, ore_positions[3], 'coal', 130000, 550)
                resource_placement(surface, ore_positions[4], 'stone', 130000, 550)
                resource_placement(surface, ore_positions[5], 'uranium-ore', 130000, 550)
                MapFunctions.draw_oil_circle(ore_positions[6], 'crude-oil', surface, 8, 200000)
            end

            local seed = random(1, 1000000)

            Scheduler.return_callback(
                function (data)
                    for _, t in pairs(this.tiles) do
                        local start_index = (data.table_index - 1) * data.total_calls + 1
                        local end_index = start_index + data.total_calls - 1

                        data.pos_tbl[data.point_index] = t.position

                        if data.iterator_index == end_index or data.iterator_index > #this.tiles then
                            data.table_index = data.table_index + 1
                            data.tick_index = data.tick_index + 1
                            Scheduler.timeout(data.tick_index, do_place_simple_entities_token, { pos_tbl = data.pos_tbl, count = data.total_calls, surface = surface, seed = seed })
                            data.pos_tbl = {}
                            data.point_index = 1
                            if data.table_index > #this.tiles then
                                break
                            end
                        end
                        data.iterator_index = data.iterator_index + 1
                        data.point_index = data.point_index + 1
                    end
                end
            )

            if not this.final_battle then
                Scheduler.timeout(5, create_market_token, { child_id = do_place_simple_entities_token, surface = surface, position = position, radius = radius })
                update_evolution(this)
            end
            Scheduler.timeout(10, create_biters_token, { child_id = create_market_token, surface = surface, position = position, radius = radius })
            Scheduler.timeout(15, clear_globals_token, { child_id = create_biters_token })
            this.gamestate = 33
        end
    )

local draw_island_inner_task_token =
    Scheduler.set(
        function (event)
            local surface = event.surface
            local position = event.position
            local radius = event.radius
            local main_island = event.main_island or false

            local r = 100
            game.surfaces['island'].request_to_generate_chunks({ position.x, position.y }, 2)
            game.surfaces['island'].force_generate_chunk_requests()
            local mirror_decorative = game.surfaces['island'].find_decoratives_filtered({ area = { { position.x - r, position.y - r }, { position.x + r, position.y + r } } })

            local max_count = 400

            local count = 1
            local c = 1
            local positions = {}
            for y = radius * -1, radius, 1 do
                for x = radius * -1, radius, 1 do
                    positions[count] = { x = x, y = y }
                    count = count + 1
                    if count == max_count + 1 then
                        c = c + 1
                        Scheduler.timeout(c, place_tiles_token, { positions = positions, position = position, radius = radius, count = max_count, surface = surface })

                        count = 1
                        positions = {}
                    end
                end
            end

            Scheduler.timeout(25, place_decoratives_token, { surface = surface, mirror_decorative = mirror_decorative })
            Scheduler.timeout(30, do_place_fish_token, { surface = surface, area = { { position.x - 300, position.y - 300 }, { position.x + 300, position.y + 300 } } })
            Scheduler.timeout(50, do_place_entities_token, { surface = surface, position = position, positions = positions, radius = radius, child_id = place_tiles_token, main_island = main_island })
        end
    )

local set_new_island_token =
    Scheduler.set(
        function ()
            local this = Public.get()
            local position = this.path_tiles[#this.path_tiles].position
            local radius = this.stages[this.current_stage].size

            if this.current_stage == this.last_level then
                radius = max_island_radius
                this.final_battle = true
                game.forces.enemy.set_evolution_factor(1, game.surfaces[1])
                game.print(island_keeper .. 'The final island has been discovered! The battle has begun!')
                Server.to_discord_embed('** The final island has been discovered! The battle has begun! **')
            end
            this.path_tiles = nil
            Public.draw_main_island(position, radius)
        end
    )

local draw_bridge_token =
    Scheduler.set(
        function (event)
            local this = Public.get()
            local position = event.position
            local surface = event.surface
            local seed_1 = random(1, 10000000)
            local seed_2 = random(1, 10000000)
            local m = random(1, 100) * 0.001

            this.path_tiles = {}

            Scheduler.timeout(
                1,
                noise_vector_tiles_path_token,
                {
                    surface = surface,
                    tbl_tiles = path_tile_names,
                    position = position,
                    length = 300,
                    brush_size = this.final_battle and 10 or 5,
                    whitelist = draw_path_tile_whitelist,
                    seed_1 = seed_1,
                    seed_2 = seed_2,
                    m = m
                },
                'noise_vector_tiles_path_1'
            )

            Scheduler.timeout(5, set_centered_points_token, { child_id = noise_vector_tiles_path_token })

            Scheduler.timeout(10, request_to_generate_chunks_token, { size = 8, surface = surface })
            this.current_stage = this.current_stage + 1
            Scheduler.timeout(50, set_new_island_token, { child_id = request_to_generate_chunks_token, sleep = game.tick + 50 })
        end
    )

local function draw_main_island(position, radius, main_island)
    local this = Public.get()
    local surface = game.surfaces[1]

    position = position or { x = 0, y = 0 }
    radius = radius or 200

    if (position.x == 0 and position.y == 0) then
        main_island = true
    end

    if not this.seeds then
        this.seeds =
        {
            seed_1 = random(1, 9999999),
            seed_2 = random(1, 9999999),
            seed_3 = random(1, 9999999),
            seed_m1 = (random(8, 16) * 0.1) / radius,
            seed_m2 = (random(12, 24) * 0.1) / radius,
            seed_m3 = (random(50, 100) * 0.1) / radius
        }
    end

    Scheduler.timeout(5, create_new_surface_token, { sleep = game.tick + 10 })
    Scheduler.timeout(10, draw_island_inner_task_token, { child_id = create_new_surface_token, surface = surface, radius = radius, position = position, main_island = main_island })
    this.gamestate = 33
end

local function on_chunk_generated(event)
    if event.surface.index ~= 1 then
        return
    end
    local left_top = event.area.left_top
    local surface = event.surface

    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local position = { x = left_top.x + x, y = left_top.y + y }
            if not is_inside_island(position.x, position.y) then
                surface.set_tiles { { name = 'water', position = position } }
            else
                surface.set_tiles({ { name = 'black-refined-concrete', position = position } }, true)
            end
        end
    end
end

local function complete_level()
    local this = Public.get()
    if not this.cooldown_complete_level then
        this.cooldown_complete_level = game.tick + (60 * 60)
    end

    if this.alive_enemies == 0 and not this.completed_levels[this.current_level] and game.tick > this.cooldown_complete_level then
        this.cooldown_complete_level = game.tick + (60 * 60)
        this.completed_levels[this.current_level] = true
        for _, player in pairs(game.connected_players) do
            player.play_sound { path = 'utility/game_won', volume_modifier = 1 }
        end
        if this.current_level == this.last_level then
            game.print(island_keeper .. 'All the bugs have been vanquished from the islands! GG!')
            Server.to_discord_embed('** All the bugs have been vanquished from the islands! GG! **')
            this.game_won = true
            this.game_reset_tick = 54000
        else
            game.print(island_keeper .. 'Level ' .. this.current_level .. ' has been completed!')
            Server.to_discord_embed('** Level ' .. this.current_level .. ' has been completed! **')
        end
    end
end

local function get_ore_count(level)
    return random(level, level + 1)
end

local function reward_items(loot, entity)
    local amount = loot.count
    local surface = entity.surface
    local position = entity.position
    if amount > 0 then
        if amount >= 50 then
            for _ = 1, math.floor(amount / 50), 1 do
                local e = surface.create_entity { name = 'item-on-ground', position = position, stack = { name = loot.name, quality = loot.quality, count = 50 } }
                if e and e.valid then
                    e.to_be_looted = true
                end
                amount = amount - 50
            end
        end
        if amount > 0 then
            local e = surface.create_entity { name = 'item-on-ground', position = position, stack = { name = loot.name, quality = loot.quality, count = amount } }
            if e and e.valid then
                e.to_be_looted = true
            end
        end
    end
end

local function on_entity_died(event)
    local entity = event.entity
    local this = Public.get()
    if entity.name == 'market' then
        if this.render_ammo_text then
            this.render_ammo_text.destroy()
            this.render_ammo_text = nil
        end
        if this.infini_chest and this.infini_chest.valid then
            this.infini_chest.destroy()
            this.infini_chest = nil
        end

        for stage, market_data in pairs(this.spawned_markets) do
            if market_data and market_data.market and market_data.market.valid then
                if market_data.render_protect_text then
                    market_data.render_protect_text.destroy()
                    market_data.render_protect_text = nil
                end
                if market_data.render_checkpoint_text then
                    market_data.render_checkpoint_text.destroy()
                    market_data.render_checkpoint_text = nil
                end
                if entity == market_data.market then
                    this.nomed_marked = stage
                end
                market_data.market.destroy()
            end
        end
        for _, player in pairs(game.connected_players) do
            player.play_sound { path = 'utility/game_lost', volume_modifier = 1 }
        end
        this.game_reset_tick = 5400
        this.game_lost = true
        game.print(island_keeper .. 'The market was overrun by hungry biters!')
        Server.to_discord_embed('** The market was overrun by hungry biters! **')
        return
    end
    if entity and entity.valid and entity.force.name == 'enemy' and entity.type == 'unit' then
        this.alive_enemies = this.alive_enemies - 1
        local ore_drop_1 = harvest_raffle_ores[random(1, size_of_ore_raffle)]
        local ore_drop_2 = harvest_raffle_ores[random(1, size_of_ore_raffle)]
        local quality_1 = get_quality_for_stage(this.current_level, this.last_level)
        local quality_2 = get_quality_for_stage(this.current_level, this.last_level)
        if ore_drop_1 == "calcite" then quality_1 = "normal" end
        if ore_drop_2 == "calcite" then quality_2 = "normal" end

        reward_items({ name = 'coin', count = random(1, 2), quality = 'normal'}, entity)
        reward_items({ name = ore_drop_1, count = get_ore_count(this.current_level), quality = quality_1 }, entity)
        reward_items({ name = ore_drop_2, count = get_ore_count(this.current_level), quality = quality_2 }, entity)
        if this.alive_enemies < 0 then this.alive_enemies = 0 end
        complete_level()
    end
end

local function on_entity_spawned(event)
    local entity = event.entity
    if entity and entity.valid and entity.force.name == 'enemy' and valid_enemy_types[entity.type] then
        local this = Public.get()
        this.alive_enemies = this.alive_enemies + 1
    end
end

local function on_market_item_purchased(event)
    local entity = event.market
    if not entity or not entity.valid then
        return
    end

    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end
    local this = Public.get()


    local offer_index = event.offer_index
    local offers = entity.get_market_items()
    local bought_offer = offers[offer_index].offer
    if bought_offer.type ~= 'nothing' then
        return
    end

    local market_prices = this.market_prices[entity.unit_number]
    if not market_prices then
        return
    end


    if string.find(bought_offer.effect_description, 'onwards') then
        if this.alive_enemies > 0 then
            player.print('You must kill all enemies before you can buy this offer')
            return
        end
        if not Difficulty.has_votes_ended() then
            return player.print('The difficulty vote has not ended yet!', { color = Color.warning })
        end
        if this.game_won then
            return
        end
        if this.voting_to_progress_enabled then
            local can_progress = false
            if this.islands_voting[this.current_level] and this.islands_voting[this.current_level].id and Poll.poll_complete(this.islands_voting[this.current_level].id) then
                local _, winning_answer = Poll.poll_result(this.islands_voting[this.current_level].id)
                if winning_answer and winning_answer.text == 'Progress!' then
                    can_progress = true
                end

                if not can_progress and not this.islands_voting[this.current_level].timeout_until_next_vote then
                    this.islands_voting[this.current_level].timeout_until_next_vote = game.tick + 18000
                end
                if not this.islands_voting[this.current_level].completed then
                    this.islands_voting[this.current_level].completed = true
                end
            end

            if this.islands_voting[this.current_level] and not this.islands_voting[this.current_level].completed then
                return player.print('There is already a poll ongoing regarding the islands advancement!', { color = Color.warning })
            end

            if not this.islands_voting[this.current_level] or (this.islands_voting[this.current_level] and this.islands_voting[this.current_level].timeout_until_next_vote and game.tick >= this.islands_voting[this.current_level].timeout_until_next_vote) then
                this.islands_voting[this.current_level] = { id = nil, completed = false, timeout_until_next_vote = nil }

                local _, id = Poll.poll(
                    {
                        question = player.name .. ' wants to advance to island ' .. this.current_level + 1,
                        answers = { 'Progress!', 'No, we are not ready!' },
                        duration = 300,
                    })
                this.islands_voting[this.current_level].id = id
                return
            end

            if not can_progress and game.tick < this.islands_voting[this.current_level].timeout_until_next_vote then
                player.print('The team has decided to not progress yet to the next island!', { color = Color.warning })
                player.print('The next vote will be available in ' .. math.floor((this.islands_voting[this.current_level].timeout_until_next_vote - game.tick) / 60) .. ' seconds!', { color = Color.warning })
                return
            end
        end

        entity.remove_market_item(offer_index)
        this.position = entity.position

        local surface = entity.surface


        reward_level(entity.surface, this.centered_points[this.current_level])

        local market = this.spawned_markets[this.current_stage] and this.spawned_markets[this.current_stage].market
        if market and market.valid then
            market.destructible = true
        end

        if this.current_level == 4 then
            Scheduler.timeout(20, create_rocket_silo_token, { child_id = clear_globals_token, surface = surface, center_position = this.centered_points[4] })
            this.initial_rocket_silo_created = true
        end

        this.current_level = this.current_level + 1

        game.print(island_keeper .. player.name .. ' has advanced to level ' .. this.current_level)
        if not this.notified_market_safe then
            this.notified_market_safe = true
            game.print(island_keeper .. 'The market doesn\'t feel as safe as before.')
        end
        Server.to_discord_embed('** ' .. player.name .. ' has advanced to level ' .. this.current_level .. ' **')

        this.alive_enemies = 0
        this.alive_boss_enemy_count = 0


        local loot_found = 0
        for _ = 1, random(1, 3), 1 do
            local treasure_position = surface.find_non_colliding_position('stone-furnace', market.position, 32, 1)

            if treasure_position then
                if random(1, 2) == 1 then
                    loot_found = loot_found + 1
                    Loot.add_loot(surface, treasure_position, 'iron-chest', true)
                    ParticleEffects.particle_effects(surface, treasure_position, 80)
                elseif random(1, 20) == 1 then
                    loot_found = loot_found + 1
                    Loot.add_loot(surface, treasure_position, 'steel-chest', true)
                    ParticleEffects.particle_effects(surface, treasure_position, 80)
                elseif random(1, 40) == 1 then
                    loot_found = loot_found + 1
                    Loot.add_loot_rare(surface, treasure_position, 'crash-site-chest-1', random(1, 1024))
                    ParticleEffects.particle_effects(surface, treasure_position, 120)
                end
            end
        end

        if loot_found == 1 then
            game.print(island_keeper .. 'A magical chest has appeared near the market!')
        elseif loot_found > 1 then
            game.print(island_keeper .. 'Magical chests have appeared near the market!')
        end



        this.attack_grace_period = game.tick + 54000

        this.alive_enemies = 999

        Scheduler.timeout(1, draw_bridge_token, { surface = entity.surface, position = this.position, child_id = request_to_generate_chunks_token })
    elseif string.find(bought_offer.effect_description, 'more ammo') then
        local price = market_prices['ammo'] or 500
        local inventory = player.get_main_inventory()
        if not inventory then
            return
        end
        local count = inventory.get_item_count({ name = 'coin' })
        if count and count < price then
            player.print('You do not have enough coins to purchase this offer!', { color = Color.warning })
            return
        elseif not count then
            return
        end
        inventory.remove({ name = 'coin', count = price })
        this.infinite_ammo_grants = this.infinite_ammo_grants + 1
        game.print(island_keeper .. 'Infinite ammo now grants more ammo thanks to ' .. player.name .. '!')
        Server.to_discord_embed('** Infinite ammo now grants more ammo thanks to ' .. player.name .. '! **')
        entity.remove_market_item(offer_index)
    elseif string.find(bought_offer.effect_description, 'piercing') then
        local price = market_prices['piercing'] or 1000
        if this.piercing_ammo_grants then
            entity.remove_market_item(offer_index)
            return player.print('You already have piercing rounds ammo!', { color = Color.warning })
        end
        local inventory = player.get_main_inventory()
        if not inventory then
            return
        end
        local count = inventory.get_item_count({ name = 'coin' })
        if count and count < price then
            player.print('You do not have enough coins to purchase this offer!', { color = Color.warning })
            return
        elseif not count then
            return
        end
        inventory.remove({ name = 'coin', count = price })
        this.piercing_ammo_grants = true
        game.print(island_keeper .. 'Infinite ammo now grants piercing rounds ammo thanks to ' .. player.name .. '!')
        Server.to_discord_embed('** Infinite ammo now grants piercing rounds ammo thanks to ' .. player.name .. '! **')
        entity.remove_market_item(offer_index)
    elseif string.find(bought_offer.effect_description, 'uranium') then
        local price = market_prices['uranium'] or 1000
        if this.uranium_ammo_grants then
            entity.remove_market_item(offer_index)
            return player.print('You already have uranium rounds ammo!', { color = Color.warning })
        end
        local inventory = player.get_main_inventory()
        if not inventory then
            return
        end
        local count = inventory.get_item_count({ name = 'coin' })
        if count and count < price then
            player.print('You do not have enough coins to purchase this offer!', { color = Color.warning })
            return
        elseif not count then
            return
        end
        inventory.remove({ name = 'coin', count = price })
        this.uranium_ammo_grants = true
        game.print(island_keeper .. 'Infinite ammo now grants uranium rounds ammo thanks to ' .. player.name .. '!')
        Server.to_discord_embed('** Infinite ammo now grants uranium rounds ammo thanks to ' .. player.name .. '! **')
        entity.remove_market_item(offer_index)
    end

    if not entity.get_market_items() then
        Public.island_market(entity, (this.current_level * random(1, 3)) * 10)
        game.print(island_keeper .. 'The market at level ' .. this.current_level - 1 .. ' has been refilled by ' .. player.name .. '!')
        Server.to_discord_embed('** The market at level ' .. this.current_level - 1 .. ' has been refilled by ' .. player.name .. '! **')
    end
end

local on_player_or_robot_built_tile = function (event)
    local surface = game.surfaces[event.surface_index]

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

Commands.new('show_centered_gps', 'Shows the centered points of the map.')
    :require_admin()
    :callback(
        function (player)
            local this = Public.get()
            for level, point in pairs(this.centered_points) do
                player.print('Level ' .. level .. ':')
                player.print('[gps=' .. point.position.x .. ',' .. point.position.y .. ',' .. player.surface.name .. ']')
            end
        end
    )

Commands.new('reset_island', 'Resets the island.')
    :require_admin()
    :callback(
        function (player)
            local this = Public.get()
            this.game_reset_tick = 0
            this.game_lost = true
            player.print('The island has been reset!', { color = Color.warning })
            Server.to_discord_embed('** The island has been reset! **')
        end
    )

Commands.new('set_biter_count', 'Sets the biter count.')
    :require_admin()
    :add_parameter('count', true, 'number')
    :callback(
        function (player, count)
            local this = Public.get()
            this.max_biters_per_island = count
            player.print('The biter count has been set to ' .. count .. '!', { color = Color.warning })
        end
    )

Commands.new('set_final_battle', 'Sets the final battle.')
    :require_admin()
    :callback(
        function (player)
            local this = Public.get()
            this.current_level = this.last_level - 1
            this.current_stage = this.last_level - 1
            player.print('The final battle has been set!', { color = Color.warning })
            return true
        end
    )

Commands.new('send_enemies', 'Sends enemies to the market.')
    :require_admin()
    :callback(
        function (player)
            set_multi_command()
            player.print('Enemies have been sent to the market!', { color = Color.warning })
            return true
        end
    )

Commands.new('toggle_drift_corpses_toward_beach', 'Toggles the drift corpses toward beach.')
    :require_admin()
    :add_parameter('state', true, 'boolean')
    :callback(
        function (player, state)
            Public.set('drift_corpses_toward_beach_enabled', state)
            player.print('The drift corpses toward beach has been ' .. (state and 'enabled' or 'disabled') .. '!', { color = Color.warning })
        end
    )

Commands.new('set_infinite_ammo_tick', 'Sets the infinite ammo tick.')
    :require_admin()
    :add_parameter('tick', true, 'number')
    :callback(
        function (player, tick)
            if tick < 10 then
                return player.print('The infinite ammo tick must be at least 10 ticks!', { color = Color.warning })
            end
            if tick > 100 then
                return player.print('The infinite ammo tick must be less than 100 ticks!', { color = Color.warning })
            end
            Public.set('infinite_ammo_tick', tick)
            player.print('The infinite ammo tick has been set to ' .. tick .. '!', { color = Color.warning })
        end
    )

Commands.new('skip_difficulty_vote', 'Skips the difficulty vote.')
    :require_admin()
    :callback(
        function ()
            Difficulty.set_poll_closing_timeout(game.tick)
        end
    )

Commands.new('toggle_voting_to_progress', 'Toggles the voting to progress.')
    :require_admin()
    :add_parameter('state', true, 'boolean')
    :callback(
        function (player, state)
            Public.set('voting_to_progress_enabled', state)
            player.print('The voting to progress has been ' .. (state and 'enabled' or 'disabled') .. '!', { color = Color.warning })
        end
    )

Commands.new('reward_level', 'Rewards the level.')
    :require_admin()
    :callback(
        function (player)
            local level = Public.get('current_level')
            local center_position = Public.get('centered_points')[level]
            if not center_position then
                center_position =
                {
                    position = { x = 0, y = 0 }
                }
            end
            reward_level(game.surfaces[1], center_position)
            player.print('Level ' .. level .. ' has been rewarded!', { color = Color.warning })
        end
    )

Commands.new('set_clear_items_on_ground', 'Sets the clear items on ground state.')
    :require_admin()
    :add_parameter('state', true, 'boolean')
    :callback(
        function (player, state)
            Public.set('clear_items_on_ground_state', state)
            player.print('Clear items on ground has been ' .. (state and 'enabled' or 'disabled') .. '!', { color = Color.warning })
        end
    )

Commands.new('toggle_check_surface_daytime', 'Checks the surface daytime if an attack towards the market should be sent.')
    :require_admin()
    :add_parameter('state', true, 'boolean')
    :callback(
        function (player, state)
            Public.set('check_surface_daytime_for_attacks', state)
            player.print('The check surface daytime has been ' .. (state and 'enabled' or 'disabled') .. '!', { color = Color.warning })
        end
    )

Commands.new('toggle_disable_multi_command_attack', 'Disables waves of enemies from being sent to the market.')
    :require_admin()
    :add_parameter('state', true, 'boolean')
    :callback(
        function (player, state)
            Public.set('disable_multi_command_attack', state)
            player.print('The disable multi command attack has been ' .. (state and 'enabled' or 'disabled') .. '!', { color = Color.warning })
        end
    )

Commands.new('scenario', 'Usable only for admins - controls the scenario!')
    :require_admin()
    :require_validation()
    :add_parameter('restart/shutdown/reset/restartnow', false, 'string')
    :callback(
        function (player, action)
            local this = Public.get()

            if action == 'restart' or action == 'shutdown' or action == 'reset' or action == 'restartnow' then
                goto continue
            else
                player.print('Invalid action.')
                return false
            end

            ::continue::

            if action == 'restart' then
                if this.restart then
                    this.reset_are_you_sure = nil
                    this.restart = false
                    this.soft_reset = true
                    Discord.send_notification(
                        {
                            title = "Soft-reset enabled",
                            description = player.name .. ' has enabled soft-reset!',
                            color = "info",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                    player.print('Soft-reset is enabled.')
                else
                    this.reset_are_you_sure = nil
                    this.restart = true
                    this.soft_reset = false
                    if this.shutdown then
                        this.shutdown = false
                    end
                    Discord.send_notification(
                        {
                            title = "Soft-reset disabled",
                            description = player.name .. ' has disabled soft-reset! Restart will happen from scenario.',
                            color = "warning",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                    player.print('Soft-reset is disabled! Server will restart from scenario to load new changes.')
                end
            elseif action == 'restartnow' then
                this.reset_are_you_sure = nil
                Server.start_scenario('Mountain_Fortress_v3')
                Discord.send_notification(
                    {
                        title = "Scenario restarted",
                        description = player.name .. ' restarted the scenario.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                player.print('Restarted the scenario.')
            elseif action == 'shutdown' then
                if this.shutdown then
                    this.reset_are_you_sure = nil
                    this.shutdown = false
                    this.soft_reset = true
                    Discord.send_notification(
                        {
                            title = "Soft-reset enabled",
                            description = player.name .. ' has enabled soft-reset. Server will NOT shutdown!',
                            color = "success",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })

                    player.print('Soft-reset is enabled.')
                else
                    this.reset_are_you_sure = nil
                    this.shutdown = true
                    this.soft_reset = false
                    if this.restart then
                        this.restart = false
                    end

                    Discord.send_notification(
                        {
                            title = "Soft-reset disabled",
                            description = player.name .. ' has disabled soft-reset. Server will shutdown!',
                            color = "warning",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                    player.print('Soft-reset is disabled! Server will shutdown.')
                end
            elseif action == 'reset' then
                this.reset_are_you_sure = nil
                if player and player.valid then
                    game.print(island_keeper .. player.name .. ', has reset the game!',
                        { color = CommandColor })
                    Discord.send_notification(
                        {
                            title = "Game reset",
                            description = player.name .. ' has reset the game!',
                            color = "success",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                else
                    game.print(island_keeper .. 'server, has reset the game!', { color = CommandColor })
                    Discord.send_notification(
                        {
                            title = "Game reset",
                            description = 'Server has reset the game!',
                            color = "success",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                end
                this.game_lost = true
                this.game_reset_tick = 1
                player.print('Game has been reset!')
            end
        end
    )

local function is_rocket_silo_alive()
    local this = Public.get()
    if not this.initial_rocket_silo_created then
        return false
    end
    if this.current_level < 4 then return end
    if this.rocket_silo and this.rocket_silo.valid then
        return true
    end

    local task = Scheduler.get(create_rocket_silo_token)
    if task then
        task({ surface = game.surfaces[1], center_position = this.centered_points[4] })
        return true
    end
    return false
end

local function on_research_finished()
    disable_tech()
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_entity_spawned, on_entity_spawned)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_player_built_tile, on_player_or_robot_built_tile)
Event.add(defines.events.on_robot_built_tile, on_player_or_robot_built_tile)

Public.draw_main_island = draw_main_island
Public.on_chunk_generated = on_chunk_generated
Public.on_entity_died = on_entity_died
Public.on_market_item_purchased = on_market_item_purchased
Public.do_buried_biters = do_buried_biters
Public.buried_biter = BuriedBiter.buried_biter
Public.buried_tech = BuriedBiter.buried_tech
Public.buried_worm = BuriedBiter.buried_worm
Public.buried_spawner = BuriedBiter.buried_spawner
Public.reset_buried_biters = BuriedBiter.reset_buried_biters
Public.check_alive_enemies = check_alive_enemies
Public.complete_level = complete_level
Public.set_multi_command = set_multi_command
Public.disable_tech = disable_tech
Public.is_rocket_silo_alive = is_rocket_silo_alive
Public.run_clear_items_on_ground = run_clear_items_on_ground
Public.do_clear_items_on_ground_slowly = do_clear_items_on_ground_slowly
Public.update_evolution_static = update_evolution_static

return Public
