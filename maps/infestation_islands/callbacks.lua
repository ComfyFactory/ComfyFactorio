local Public = require 'maps.infestation_islands.table'
local Scheduler = require 'utils.scheduler'
local simplex_noise = require 'utils.math.simplex_noise'.d2
local Core = require 'utils.core'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local MapFunctions = require 'utils.tools.map_functions'
local Server = require 'utils.server'

local step_size_param = 3.0
local snake_param = 1.15
local steps_per_tick_param = 10
local random = math.random
local sqrt = math.sqrt
local floor = math.floor
local min = math.min
local pow = math.pow

local draw_path_tile_whitelist = Public.draw_path_tile_whitelist
local decoratives = Public.decoratives


local function merge_arrays(a, b)
    for i = 1, #b do
        a[#a + 1] = b[i]
    end
    return a
end

local function get_brush(size, circular)
    local vectors = {}
    for x = -size, size do
        for y = -size, size do
            if not circular or (x * x + y * y <= size * size) then
                vectors[#vectors + 1] = { x = x, y = y }
            end
        end
    end
    return vectors
end

local cached_brushes = {}
for size = 1, 100 do
    if not cached_brushes[size] then
        cached_brushes[size] = get_brush(size, true)
    end
end

Public.find_items_on_ground_token =
    Scheduler.register_function(
        'find_items_on_ground_token',
        function (event)
            local surface = event.surface
            local position = event.position
            local radius = event.radius
            local area = { { x = (position.x + -radius), y = (position.y + -radius) }, { x = (position.x + radius), y = (position.y + radius) } }

            local ents = {}

            local this = Public.get()

            for _, entity in pairs(surface.find_entities_filtered { type = "item-entity", name = "item-on-ground", area = area }) do
                if entity.valid then
                    ents[#ents + 1] = entity
                end
            end

            this.clear_items_on_ground = this.clear_items_on_ground or {}

            if #ents > 2000 then
                this.clear_items_on_ground = merge_arrays(this.clear_items_on_ground, ents)
            end
        end
    )

Public.do_place_tiles_slowly =
    Scheduler.register_function(
        'do_place_tiles_slowly',
        function (event)
            local positions = event.positions
            if not positions or #positions == 0 then
                return
            end
            local surface = event.surface
            local pos = event.positions[1]
            if pos then
                game.forces.player.chart(surface, { { pos.position.x - 40, pos.position.y - 40 }, { pos.position.x + 40, pos.position.y + 40 } })
            end
            surface.set_tiles(positions, true)

            if random(1, 8) == 1 then
                local position = surface.find_non_colliding_position('behemoth-worm-turret', pos.position, 32, 32)
                if position then
                    Public.buried_worm(surface, position, Public.qualities[random(1, #Public.qualities)])
                end
            end
            for _, position in pairs(positions) do
                surface.set_hidden_tile(position.position, 'foundation')
            end
        end
    )


Public.do_place_decorative_token =
    Scheduler.register_function(
        'do_place_decorative_token',
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

Public.calculate_bridge_token =
    Scheduler.register_function(
        'calculate_bridge_token',
        ---@param event table
        ---@param task Task
        function (event, task)
            local this = Public.get()
            local seed_1, seed_2, m = event.seed_1, event.seed_2, event.m
            local vector = event.vector
            local minimal_move = event.minimal_movement
            local surface = event.surface
            local tile_name = event.tile_name
            local tick_index = event.tick_index
            local step_size = event.step_size or 1.0
            local noise_scale = event.noise_scale or 0.30
            local brush_size = event.brush_size or 10
            local pos = this.bridge_position
            local brush_vectors = cached_brushes[brush_size]


            local positions, dec = {}, {}

            for _, b in pairs(brush_vectors) do
                local p = { x = pos.x + b.x, y = pos.y + b.y }
                local tile = surface.get_tile(p)
                if tile.valid and draw_path_tile_whitelist[tile.name] then
                    positions[#positions + 1] = { name = tile_name, position = p }
                    if random(1, 15) == 1 then
                        dec[#dec + 1] = { name = decoratives[random(1, #decoratives)], position = p, amount = 1 }
                    end
                end
            end

            task:new_child(tick_index, Public.do_place_tiles_slowly)
                :set_data({ positions = positions, surface = surface })
                :new_child(10, Public.do_place_decorative_token)
                :set_data({ pos_tbl = dec, count = #dec, surface = surface })

            local target = this.next_island_position
            if this.reverse_start_position then
                target = this.position
            end
            if not target then return end

            local dx, dy = target.x - pos.x, target.y - pos.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist <= math.max(brush_size, step_size * 2) then
                this.bridge_position = { x = target.x, y = target.y }
                return
            end

            local dirx, diry = dx / dist, dy / dist
            local t = math.min(1, dist / (brush_size * 6))
            local ns = noise_scale * (t * t)
            local n1 = simplex_noise(pos.x * m, pos.y * m, seed_1)
            local n2 = simplex_noise(pos.x * m, pos.y * m, seed_2)

            local vx = dirx * step_size + n1 * ns
            local vy = diry * step_size + n2 * ns

            if math.abs(vx) < minimal_move and math.abs(vy) < minimal_move then
                if random(1, 2) == 1 then
                    vx = (vx < 0) and -minimal_move or minimal_move
                else
                    vy = (vy < 0) and -minimal_move or minimal_move
                end
            end

            local vlen = math.sqrt(vx * vx + vy * vy)
            if vlen > dist then vx, vy = dx, dy end

            vector[1], vector[2] = vx, vy
            this.bridge_position = { x = pos.x + vx, y = pos.y + vy }
        end)


local function route_distance(route, start)
    local p = start
    local total = 0
    for _, q in ipairs(route) do
        local dx, dy = q.x - p.x, q.y - p.y
        total = total + math.sqrt(dx * dx + dy * dy)
        p = q
    end
    return total
end

Public.noise_vector_tiles_path_token =
    Scheduler.register_function(
        'noise_vector_tiles_path_token',
        ---@param event table
        ---@param task Task
        function (event, task)
            local this = Public.get()
            local surface = event.surface
            local tbl_tiles = event.tbl_tiles
            local brush_size = event.brush_size
            local seed_1, seed_2, m = event.seed_1, event.seed_2, event.m

            this.vector = {}
            local tile_name = tbl_tiles[random(1, #tbl_tiles)]
            local route
            local start

            if this.reverse_start_position then
                route = { this.position }
                start = this.next_island_position
            else
                route = { this.next_island_position }
                start = this.position
            end

            local l = math.ceil((route_distance(route, start) / step_size_param) * snake_param)
            local total_batches = math.ceil(l / steps_per_tick_param)

            for batch = 1, total_batches do
                for i = 1, steps_per_tick_param do
                    local g = (batch - 1) * steps_per_tick_param + i
                    if g > l then break end
                    task:new_child(1, Public.calculate_bridge_token)
                        :set_data(
                            {
                                seed_1 = seed_1,
                                seed_2 = seed_2,
                                m = m,
                                vector = this.vector,
                                minimal_movement = not this.reverse_start_position and 1.40 or 0.80,
                                surface = surface,
                                tile_name = tile_name,
                                tick_index = batch,
                                step_size = step_size_param,
                                noise_scale = not this.reverse_start_position and 2.20 or 1.40,
                                brush_size = brush_size,
                            })
                end
            end
        end
    )

Public.chart_area_for_player_force_token =
    Scheduler.register_function(
        'chart_area_for_player_force_token',
        function (event)
            local next_island_position = Public.get('next_island_position')
            local surface = event.surface
            local position = event.position or next_island_position
            if not position then
                return
            end

            local islands_data = Public.get('islands_data')
            local current_level = Public.get('current_level')
            local island_data = islands_data[current_level]
            if not island_data then
                error('No island data found for level ' .. current_level)
                return
            end


            local radius = island_data.radius + 50
            Core.log('VERBOSE: Charting island ' .. current_level .. ' at ' .. position.x .. ',' .. position.y .. ' with radius ' .. radius)
            game.forces.player.chart(surface, { { position.x - radius, position.y - radius }, { position.x + radius, position.y + radius } })
            event.completed = true
        end
    )

Public.do_place_corpses_token =
    Scheduler.register_function(
        'do_place_corpses_token',
        function (event)
            local this = Public.get()
            local count = event.count
            local pos_tbl = event.pos_tbl
            local surface = event.surface
            local seed = event.seed

            local tree = this.tree_raffle[random(1, #this.tree_raffle)]

            for i = 1, count do
                local position = pos_tbl[i] and pos_tbl[i].position or nil
                if position then
                    if random(1, 16) == 1 then
                        local noise = simplex_noise(position.x * 0.02, position.y * 0.02, seed)
                        if noise > 0.75 or noise < -0.75 then
                            surface.create_entity({ name = Public.rock_raffle[random(1, #Public.rock_raffle)], position = position })
                        end
                    end

                    if surface.can_place_entity({ name = 'wooden-chest', position = position }) then
                        if random(1, 32) == 1 then
                            if simplex_noise(position.x * 0.02, position.y * 0.02, seed) > 0.25 then
                                surface.create_entity({ name = tree, position = position, tick_grown = 9999 })
                            end
                        end
                    end

                    if random(1, 128) == 1 then
                        if simplex_noise(position.x * 0.02, position.y * 0.02, seed) > 0.25 then
                            surface.create_entity({ name = Public.gleba_trees[random(1, #Public.gleba_trees)], position = position, tick_grown = random(1, 999) })
                        end
                    end

                    if surface.can_place_entity({ name = 'wooden-chest', position = position }) then
                        if random(1, 64) == 1 then
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


Public.do_place_tiles_token =
    Scheduler.register_function(
        'do_place_tiles_token',
        ---@param event table
        function (event, task)
            local this = Public.get()
            local positions = event.positions
            local position = event.position
            local radius = event.radius
            local count = event.count
            local surface = event.surface

            local tiles = {}
            local corpse_tiles = {}
            for i = 1, count do
                local x = positions[i].x
                local y = positions[i].y
                local p = { x = x + position.x, y = y + position.y }
                local tile_data = surface.get_tile(p)
                if tile_data and tile_data.valid and (tile_data.name == 'water' or tile_data.name == 'deepwater' or tile_data.name == 'brash-ice' or tile_data.name == 'lava-hot') then
                    local distance = sqrt(x ^ 2 + y ^ 2)
                    local tile
                    local watery_tile
                    local noise_radius = Public.get_radius(p, radius)
                    local market_radius = Public.get_radius(p, radius - 10, 22)
                    local main_tile = game.surfaces['island'].get_tile(x, y)
                    if distance > market_radius - (radius + 4) * 0.135 and distance < market_radius - (radius - 4) * 0.135 then
                        if main_tile and main_tile.valid and distance < radius then
                            tile = { name = main_tile.name, position = p }
                        end

                        this.market_positions[#this.market_positions + 1] = p
                        Public.print_grid_value(noise_radius, surface, p, 2, 0)
                    end
                    if distance < noise_radius - radius * 0.15 then
                        if main_tile and main_tile.valid then
                            tile = { name = main_tile.name, position = p }
                        end
                    elseif distance < noise_radius - 5 then
                        local tile_name = Public.get_tile_name_by_level(this.current_level)
                        watery_tile = { name = tile_name, position = p }
                    end

                    if tile then
                        tiles[#tiles + 1] = tile
                        corpse_tiles[#corpse_tiles + 1] = tile
                    end
                    if watery_tile then
                        tiles[#tiles + 1] = watery_tile
                    end
                end
            end
            game.forces.player.chart(surface, { { position.x - 124, position.y - 124 }, { position.x + 124, position.y + 124 } })

            surface.set_tiles(tiles, true)

            local seed = random(1, 1000000)

            task:new_child(1, Public.do_place_corpses_token)
                :set_data({ pos_tbl = corpse_tiles, count = #corpse_tiles, surface = surface, seed = seed })
        end
    )

Public.place_decoratives_token =
    Scheduler.register_function(
        'place_decoratives_token',
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

Public.do_place_fish_token =
    Scheduler.register_function(
        'do_place_fish_token',
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


Public.create_rocket_silo_token =
    Scheduler.register_function(
        'create_rocket_silo_token',
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
            this.initial_rocket_silo_created = true
        end
    )

Public.do_place_enemies_token =
    Scheduler.register_function(
        'do_place_enemies_token',
        function (event)
            local this = Public.get()
            local surface = event.surface
            local position = event.position
            local raw_level = this.current_level or 1
            this.alive_enemies = 0

            local difficulty_value = Difficulty.get('value') or 1
            local final_battle = this.final_battle
            local max_level = this.last_level

            local normalized_level = min(raw_level / max_level, 1.0)
            local scale = pow(normalized_level, 0.8) * (1 + difficulty_value * 0.4) + 0.5

            local base_enemy_count = floor((40 + raw_level * 8) * scale)
            local spawner_count = floor((4 + raw_level * 0.5) * scale)
            local spider_count = floor((10 + raw_level * 2) * scale)
            local worm_count = floor((10 + raw_level * 1.2) * scale)

            spawner_count = min(spawner_count, 128)
            spider_count = min(spider_count, 256)
            worm_count = min(worm_count, 256)
            base_enemy_count = min(base_enemy_count, 1500)

            if raw_level == 1 then
                spawner_count = 0
                worm_count = 0
                base_enemy_count = 4
            end

            if final_battle then
                spawner_count = 64
                worm_count = 128
                base_enemy_count = 1100
            end

            local tier = Public.get_enemy_tier_by_units(raw_level)

            local biter_types = tier.biter_types
            local spitter_types = tier.spitter_types
            local worm_types = tier.worm_types
            local spider_types = tier.spider_types
            local spawner_types = tier.spawner_types
            local spawn_qualities = tier.spawn_qualities

            for _ = 1, spawner_count do
                local p = surface.find_non_colliding_position('gun-turret', Public.get_random_position(position, 100), 128, 5)
                if p then
                    surface.create_entity(
                        {
                            name = spawner_types[random(1, #spawner_types)],
                            position = p,
                            quality = spawn_qualities[random(1, #spawn_qualities)]
                        })
                end
            end

            if spider_types and #spider_types > 0 then
                for _ = 1, spider_count do
                    local p = surface.find_non_colliding_position('gun-turret', Public.get_random_position(position, 80), 128, 5)
                    if p then
                        surface.create_entity(
                            {
                                name = spider_types[random(1, #spider_types)],
                                position = p,
                                quality = spawn_qualities[random(1, #spawn_qualities)]
                            })
                    end
                end
            end

            if worm_types and #worm_types > 0 then
                for _ = 1, worm_count do
                    local p = surface.find_non_colliding_position('gun-turret', Public.get_random_position(position, 80), 128, 5)
                    if p then
                        surface.create_entity(
                            {
                                name = worm_types[random(1, #worm_types)],
                                position = p,
                                quality = spawn_qualities[random(1, #spawn_qualities)]
                            })
                    end
                end
            end

            for _ = 1, base_enemy_count do
                local enemy_type
                if random(1, 2) == 1 then
                    enemy_type = biter_types[random(1, #biter_types)]
                else
                    enemy_type = spitter_types[random(1, #spitter_types)]
                end

                local p = surface.find_non_colliding_position('wooden-chest', Public.get_random_position(position, 40), 128, 4)
                if p then
                    local e = surface.create_entity(
                        {
                            name = enemy_type,
                            position = p,
                            quality = spawn_qualities[random(1, #spawn_qualities)]
                        })
                    if e and e.valid then
                        e.ai_settings.allow_try_return_to_spawner = false
                        e.ai_settings.allow_destroy_when_commands_fail = false
                    end
                end
            end

            if final_battle then
                for _ = 1, 128 do
                    local p = surface.find_non_colliding_position('gun-turret', Public.get_random_position(position, 20), 128, 10)
                    if p then
                        local e = surface.create_entity(
                            {
                                name = 'gun-turret',
                                position = p,
                                force = 'enemy',
                                quality = spawn_qualities[random(1, #spawn_qualities)]
                            })
                        if e and e.valid then
                            e.insert(
                                {
                                    name = 'uranium-rounds-magazine',
                                    count = 200,
                                    quality = spawn_qualities[random(1, #spawn_qualities)]
                                })
                        end
                    end
                end
            end

            if difficulty_value >= 2 then
                local demolisher_type
                local demolisher_count = 0

                if raw_level >= 6 and raw_level <= 10 then
                    demolisher_type = 'small-demolisher'
                    demolisher_count = 4
                elseif raw_level >= 11 and raw_level <= 20 then
                    demolisher_type = 'medium-demolisher'
                    demolisher_count = 6
                elseif raw_level > 20 or final_battle then
                    demolisher_type = 'big-demolisher'
                    demolisher_count = 8
                end

                for _ = 1, demolisher_count do
                    local p = surface.find_non_colliding_position('gun-turret', Public.get_random_position(position, 30), 128, 10)
                    if p then
                        surface.create_entity(
                            {
                                name = demolisher_type,
                                position = p,
                                force = 'enemy',
                                quality = spawn_qualities[random(1, #spawn_qualities)]
                            })
                    end
                end
            end

            local islands_data = Public.get('islands_data')
            local current_level = Public.get('current_level')
            local island_data = islands_data[current_level]
            if not island_data then
                error('No island data found for level ' .. current_level)
                return
            end

            this.cooldown_complete_level = game.tick

            island_data.ready = true
        end)


Public.do_place_market_token =
    Scheduler.register_function(
        'do_place_market_token',
        function (event)
            local this = Public.get()
            local surface = event.surface
            local random_pos = Public.shuffle(this.market_positions)

            local position = random_pos[#random_pos]
            if not position then
                error('No market position found!')
            end

            local new_tile = Public.find_dirt_tile(surface, position)
            local new_pos = surface.find_non_colliding_position('rocket-silo', new_tile, 0, 4)

            this.market_positions = {}

            if new_pos then
                local p = new_pos
                local market = surface.create_entity({ name = 'market', position = p, force = 'player', quality = Public.qualities[random(1, #Public.qualities)] })
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
                    if this.current_level > 1 then
                        market.destructible = false
                    end

                    this.market_target = market

                    local render_checkpoint_text = rendering.draw_text
                        {
                            text = 'Checkpoint ' .. this.current_level,
                            surface = surface,
                            target = { market.position.x, market.position.y - 3.5 },
                            color = { r = 0.98, g = 0.77, b = 0.22 },
                            scale = 2,
                            font = 'heading-1',
                            alignment = 'center',
                            scale_with_zoom = false
                        }

                    local island_data = this.islands_data[this.current_level]
                    if not island_data then
                        error('No island data found for level ' .. this.current_level)
                        return
                    end

                    if this.nearest_island_level and this.nearest_island_level.to and this.nearest_island_level.to == this.current_level then
                        local parent_island = this.islands_data[this.nearest_island_level.from]
                        if not parent_island then
                            error('No parent island found for level ' .. this.nearest_island_level.from)
                            return
                        end

                        island_data.parent_island = parent_island
                        this.nearest_island_level = nil
                    end

                    island_data.market = market
                    island_data.market_position = p
                    island_data.current_level = island_data.level
                    island_data.render_protect_text = render_protect_text
                    island_data.render_checkpoint_text = render_checkpoint_text
                    island_data.captured = false
                    -- self reference to the island data for easier access
                    this.islands_data[market.unit_number] = island_data

                    Public.add_market_slot(market)
                end
                MapFunctions.draw_noise_tile_circle(p, 'blue-refined-concrete', surface, 12)
            end
        end
    )

Public.do_revive_market_token =
    Scheduler.register_function(
        'do_revive_market_token',
        function (event)
            local this = Public.get()
            local surface = event.surface
            local position = event.position
            local level = event.level

            if position then
                local market = surface.create_entity({ name = 'market', position = position, force = 'player', quality = Public.qualities[random(1, #Public.qualities)] })
                if market and market.valid then
                    market.minable = false
                    market.destructible = false
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

                    local render_checkpoint_text = rendering.draw_text
                        {
                            text = 'Checkpoint ' .. level,
                            surface = surface,
                            target = { market.position.x, market.position.y - 3.5 },
                            color = { r = 0.98, g = 0.77, b = 0.22 },
                            scale = 2,
                            font = 'heading-1',
                            alignment = 'center',
                            scale_with_zoom = false
                        }

                    local island_data = this.islands_data[level]
                    if not island_data then
                        error('No island data found for level ' .. level)
                        return
                    end

                    island_data.market = market
                    island_data.market_position = position
                    island_data.render_protect_text = render_protect_text
                    island_data.render_checkpoint_text = render_checkpoint_text
                    island_data.captured = false

                    -- self reference to the island data for easier access
                    this.islands_data[market.unit_number] = island_data

                    Public.add_market_revive_slot(market, level, position)
                end
                MapFunctions.draw_noise_tile_circle(position, 'blue-refined-concrete', surface, 12)
            end
        end
    )

Public.do_place_entities_token =
    Scheduler.register_function(
        'do_place_entities_token',
        ---@param event table
        ---@param task Task
        function (event, task)
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
                Public.shuffle(chest_pos)

                local chest_raff =
                {
                    'crash-site-chest-1',
                    'crash-site-chest-1',
                    'crash-site-chest-2',
                    'crash-site-chest-2'
                }

                this.ammo_chest = surface.create_entity({ name = chest_raff[random(1, #chest_raff)], position = { chest_pos[1].x, chest_pos[1].y }, force = 'neutral' })
                this.ammo_chest.operable = false
                this.ammo_chest.destructible = false
                this.ammo_chest.minable = false
                this.render_ammo_text = rendering.draw_text
                    {
                        text = 'Free ammo',
                        surface = surface,
                        target = this.ammo_chest,
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
                Public.shuffle(ore_positions)

                Public.resource_placement(surface, ore_positions[1], 'copper-ore', 150000, 550, 1)
                Public.resource_placement(surface, ore_positions[2], 'iron-ore', 150000, 550, 1)
                Public.resource_placement(surface, ore_positions[3], 'coal', 130000, 550, 1)
                Public.resource_placement(surface, ore_positions[4], 'stone', 130000, 550, 1)
                Public.resource_placement(surface, ore_positions[5], 'uranium-ore', 130000, 550, 1)
                MapFunctions.draw_oil_circle(ore_positions[6], 'crude-oil', surface, 8, 200000)
            end

            local callback_data = { surface = surface, position = position, radius = radius }

            if not this.final_battle then
                task:new_child(1, Public.do_place_market_token)
                    :set_data(callback_data)

                    :new_child(10, Public.do_place_enemies_token)
                    :set_data(callback_data)

                Public.update_evolution(this)
            else
                task:new_child(1, Public.do_place_enemies_token)
                    :set_data(callback_data)
                Public.update_evolution(this)
            end
        end
    )

Public.do_island_creation_token =
    Scheduler.register_function(
        'do_island_creation_token',
        ---@param event table
        ---@param task Task
        function (event, task)
            local position = event.position or Public.get('next_island_position')
            local current_level = event.current_level or Public.get('current_level')
            local stages = event.stages or Public.get('stages')
            local radius = event.radius or stages[current_level].size
            local last_level = event.last_level or Public.get('last_level')
            local surface = event.surface
            local main_island = Public.get('current_level') == 1


            if last_level < 11 and current_level == last_level then
                radius = Public.max_island_radius_param
                Public.set('final_battle', true)
                game.forces.enemy.set_evolution_factor(1, game.surfaces[1])
                Public.delayed_message(1, Public.island_keeper .. 'The final island has been discovered! The battle has begun!')
                Server.to_discord_embed('** The final island has been discovered! The battle has begun! **')
            end

            local r = 100
            game.surfaces['island'].request_to_generate_chunks({ position.x, position.y }, 2)
            game.surfaces['island'].force_generate_chunk_requests()
            local mirror_decorative = game.surfaces['island'].find_decoratives_filtered({ area = { { position.x - r, position.y - r }, { position.x + r, position.y + r } } })

            local max_count = 256
            if current_level == 1 then
                max_count = 1024
            end
            local count = 1
            local c = 1
            local positions = {}
            local last_tile_task

            for y = radius * -1, radius, 1 do
                for x = radius * -1, radius, 1 do
                    positions[count] = { x = x, y = y }
                    count = count + 1

                    if count == max_count + 1 then
                        c = c + 1
                        last_tile_task = task:new_child(1, Public.do_place_tiles_token)
                            :set_data(
                                {
                                    positions = positions,
                                    position = position,
                                    radius = radius,
                                    count = max_count,
                                    surface = surface
                                })

                        count = 1
                        positions = {}
                    end
                end
            end

            if last_tile_task then
                last_tile_task:new_child(50, Public.place_decoratives_token)
                    :set_data({ surface = surface, mirror_decorative = mirror_decorative })

                    :new_child(50, Public.do_place_fish_token)
                    :set_data(
                        {
                            surface = surface,
                            area =
                            {
                                { position.x - 100, position.y - 100 },
                                { position.x + 100, position.y + 100 }
                            }
                        })
                    :new_child(50, Public.do_place_entities_token)
                    :set_data(
                        {
                            surface = surface,
                            position = position,
                            radius = radius,
                            main_island = main_island
                        })
            end
        end
    )

Public.init_next_island_token =
    Scheduler.register_function(
        'init_next_island_token',
        function (event)
            local this = Public.get()
            local surface = event.surface
            local seed_1 = random(1, 10000000)
            local seed_2 = random(1, 10000000)
            local m = random(1, 100) * 0.001

            Public.delayed_message(1, Public.island_keeper .. Public.messages[random(1, #Public.messages)])
            Public.prepare_next_island(this)
            local new_island = Public.set_islands_data()
            new_island.bridge_generated = true

            local root = Scheduler.new(1, Public.chart_area_for_player_force_token):set_data({ surface = surface })
            root:new_child(500, Public.do_island_creation_token):set_data({ surface = surface })
            root:new_child(1, Public.noise_vector_tiles_path_token):set_data(
                {
                    surface = surface,
                    tbl_tiles = Public.path_tile_names,
                    brush_size = (this.final_battle and (18 + this.current_level) or (10 + this.current_level)),
                    seed_1 = seed_1,
                    seed_2 = seed_2,
                    m = m
                })
            root:new_child(1, Public.do_misc_token):set_data({ surface = surface })
        end
    )

Public.init_next_island_without_bridge_token =
    Scheduler.register_function(
        'init_next_island_without_bridge_token',
        function (event)
            local this = Public.get()
            local surface = event.surface

            local island_data = this.islands_data[this.current_level]
            if not island_data then
                error('No island data found for level ' .. this.current_level)
                return
            end

            this.position = island_data.market_position

            local market = island_data.market
            if not market or not market.valid then
                error('No market found for level ' .. this.current_level)
                return
            end

            local offers = market.get_market_items()
            if offers then
                for offer_index, offer_data in pairs(offers) do
                    if offer_data and offer_data.offer and offer_data.offer.effect_description and string.find(offer_data.offer.effect_description, 'onwards') then
                        market.remove_market_item(offer_index)
                    end
                end
            end

            if this.current_level == 4 then
                Scheduler.new(1, Public.create_rocket_silo_token)
                    :set_data({ surface = surface, center_position = this.islands_data[4] })
            end

            this.current_level = this.current_level + 1

            island_data.voting = nil

            Public.delayed_message(1, Public.island_keeper .. Public.messages[random(1, #Public.messages)])
            Public.prepare_next_island(this)
            local new_island = Public.set_islands_data()
            new_island.parent_level = this.current_level - 1
            new_island.auto_generated_bridge = false
            new_island.island_generated = true

            local offer =
            {
                price = {},
                offer = { type = 'nothing', effect_description = 'Generate bridge to the next island!' }
            }
            market.add_market_item(offer)

            local root = Scheduler.new(1, Public.chart_area_for_player_force_token):set_data({ surface = surface })
            root:new_child(500, Public.do_island_creation_token):set_data({ surface = surface })
            root:new_child(1, Public.do_misc_token):set_data({ surface = surface })

            this.attack_grace_period = game.tick + 54000
            this.cooldown_complete_level = game.tick + (60 * 60)
        end
    )

Public.do_generate_bridge_token =
    Scheduler.register_function(
        'do_generate_bridge_token',
        function (event)
            local this = Public.get()
            local surface = event.surface
            local seed_1 = random(1, 10000000)
            local seed_2 = random(1, 10000000)
            local m = random(1, 100) * 0.001
            local reroll_enabled = event.reroll_enabled or false

            local island_data = this.islands_data[this.current_level]
            if not island_data then
                error('No island data found for level ' .. this.current_level)
                return
            end

            local parent_island = island_data.parent_island
            if not parent_island then
                error('No parent island found for level ' .. this.current_level)
                return
            end

            this.position = parent_island.market_position
            this.next_island_position = island_data.market_position

            local market = parent_island.market
            if not market or not market.valid then
                error('No market found for level ' .. this.current_level)
                return
            end

            local offers = market.get_market_items()
            if offers then
                for offer_index, offer_data in pairs(offers) do
                    if offer_data and offer_data.offer and offer_data.offer.effect_description and string.find(offer_data.offer.effect_description, 'bridge') then
                        market.remove_market_item(offer_index)
                    end
                end
            end

            if not market.get_market_items() then
                market.operable = false
            end

            if not reroll_enabled then
                island_data.no_rerolls = true
            end

            island_data.bridge_generated = true

            island_data.voting = nil

            Scheduler.new(1, Public.noise_vector_tiles_path_token):set_data(
                {
                    surface = surface,
                    tbl_tiles = Public.path_tile_names,
                    brush_size = (this.final_battle and (18 + this.current_level) or (10 + this.current_level)),
                    seed_1 = seed_1,
                    seed_2 = seed_2,
                    m = m
                })
        end
    )

Public.do_misc_token = Scheduler.register_function(
    'do_misc_token',
    function (event)
        local this = Public.get()
        local surface = event.surface

        local island_data = this.islands_data[this.current_level]
        if not island_data then
            error('No island data found for level ' .. this.current_level)
            return
        end

        if this.auto_create_islands then
            if this.current_level == this.last_level then
                game.tick_paused = true
                return
            end
            this.current_level = this.current_level + 1
            this.attack_grace_period = game.tick + 54000
            this.cooldown_complete_level = game.tick + (60 * 60)
            if this.market_target then
                this.position = this.market_target.position
            else
                this.position = { x = 0, y = 0 }
            end
            Public.reward_level(surface, this.islands_data[this.current_level - 1])
            Scheduler.new(1, Public.init_next_island_token)
                :set_data({ surface = surface })
            return
        end

        local parent_island = this.islands_data[this.current_level - 1]
        if not parent_island then
            error('No parent island found for level ' .. this.current_level)
            return
        end

        if not parent_island.auto_generated_island then
            Public.reward_level(surface, this.islands_data[this.current_level - 1])
        end
    end
)

return Public
