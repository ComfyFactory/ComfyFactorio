local Event = require 'utils.event'
local map_functions = require 'utils.tools.map_functions'
local simplex_noise = require 'utils.simplex_noise'.d2
local Public = require 'maps.fish_defender_v2.table'
local Task = require 'utils.task'
local Token = require 'utils.token'

local random = math.random
local abs = math.abs
local sqrt = math.sqrt

--rock spawning code for stone pile
local rock_raffle = {
    'sand-rock-big',
    'sand-rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-huge'
}

local size_of_rock_raffle = #rock_raffle

local function place_rock(surface, position)
    local a = (random(-250, 250)) * 0.05
    local b = (random(-250, 250)) * 0.05
    surface.create_entity({name = rock_raffle[random(1, size_of_rock_raffle)], position = {position.x + a, position.y + b}})
end

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

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
                    if (math.random() > 0.9) and (abs(a) < w_max) and (abs(b) < h_max) then
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
    for _, _ in pairs(biases) do
        for _, bias in pairs(_) do
            total_bias = total_bias + bias
        end
    end

    for x, _ in pairs(biases) do
        for y, bias in pairs(_) do
            surface.create_entity {
                name = name,
                amount = amount * (bias / total_bias),
                force = 'neutral',
                position = {position.x + x, position.y + y}
            }
        end
    end
end

function Public.get_replacement_tile(surface, position)
    for i = 1, 128, 1 do
        local vectors = {{0, i}, {0, i * -1}, {i, 0}, {i * -1, 0}}
        shuffle(vectors)
        for k, v in pairs(vectors) do
            local tile = surface.get_tile(position.x + v[1], position.y + v[2])
            if tile and tile.valid and not tile.collides_with('resource-layer') then
                return tile.name
            end
        end
    end
    return 'grass-1'
end

local function is_enemy_territory(p)
    if p.x - 64 < abs(p.y) then
        return false
    end
    --if p.x - 64 < p.y then return false end
    if p.x < 256 then
        return false
    end
    if p.x > 1024 then
        return false
    end
    if p.y > 512 then
        return false
    end
    if p.y < -512 then
        return false
    end
    return true
end

local function place_fish_market(surface, position)
    local market = surface.create_entity({name = 'market', position = position, force = 'player'})
    market.minable = false

    return market
end

local enemy_territory_token =
    Token.register(
    function(data)
        local surface_index = data.surface_index
        local left_top = data.left_top
        local surface = game.get_surface(surface_index)
        if left_top.x < 256 then
            return
        end
        if left_top.x > 750 then
            return
        end
        if left_top.y > 766 then
            return
        end
        if left_top.y < -256 then
            return
        end

        local area = {{left_top.x, left_top.y}, {left_top.x + 32, left_top.y + 32}}

        if left_top.x > 300 then
            for x = 0, 31, 1 do
                for y = 0, 31, 1 do
                    local pos = {x = left_top.x + x, y = left_top.y + y}
                    if is_enemy_territory(pos) then
                        if random(1, 512) == 1 then
                            if surface.can_place_entity({name = 'biter-spawner', force = 'decoratives', position = pos}) then
                                local entity
                                if random(1, 4) == 1 then
                                    entity = surface.create_entity({name = 'spitter-spawner', force = 'decoratives', position = pos})
                                else
                                    entity = surface.create_entity({name = 'biter-spawner', force = 'decoratives', position = pos})
                                end
                                entity.active = false
                                entity.destructible = false
                            end
                        end
                    end
                end
            end
        end
        for _, entity in pairs(surface.find_entities_filtered({area = area, type = {'tree', 'cliff'}})) do
            if is_enemy_territory(entity.position) then
                entity.destroy()
            end
        end
        for _, entity in pairs(surface.find_entities_filtered({area = area, type = 'resource'})) do
            if is_enemy_territory(entity.position) then
                surface.create_entity({name = 'uranium-ore', position = entity.position, amount = random(200, 8000)})
                entity.destroy()
            end
        end
        for _, tile in pairs(surface.find_tiles_filtered({name = {'water', 'deepwater'}, area = area})) do
            if is_enemy_territory(tile.position) then
                surface.set_tiles({{name = Public.get_replacement_tile(surface, tile.position), position = {tile.position.x, tile.position.y}}}, true)
            end
        end
    end
)

local fish_mouth_token =
    Token.register(
    function(data)
        local surface_index = data.surface_index
        local left_top = data.left_top
        local surface = game.get_surface(surface_index)
        if left_top.x > -1800 then
            return
        end
        if left_top.y > 64 then
            return
        end
        if left_top.y < -64 then
            return
        end
        if left_top.x < -2200 then
            return
        end

        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                local pos = {x = left_top.x + x, y = left_top.y + y}
                local noise = simplex_noise(pos.x * 0.006, 0, game.surfaces[1].map_gen_settings.seed) * 20
                if pos.y <= 12 + noise and pos.y >= -12 + noise then
                    surface.set_tiles({{name = 'water', position = pos}})
                end
            end
        end
    end
)

local request_to_generate_chunks_token =
    Token.register(
    function(data)
        local surface_index = data.surface_index
        local surface = game.get_surface(surface_index)
        local spawn_area_generated = Public.get('spawn_area_generated')
        if spawn_area_generated then
            return
        end

        surface.request_to_generate_chunks({0, 0}, 8)

        local fish_eye_location = Public.get('fish_eye_location')

        surface.request_to_generate_chunks(fish_eye_location, 2)
    end
)

local function initial_cargo_boxes()
    return {
        {name = 'coal', count = random(32, 64)},
        {name = 'coal', count = random(32, 64)},
        {name = 'coal', count = random(32, 64)},
        {name = 'iron-ore', count = random(32, 128)},
        {name = 'iron-ore', count = random(32, 128)},
        {name = 'iron-ore', count = random(32, 128)},
        {name = 'copper-ore', count = random(32, 128)},
        {name = 'copper-ore', count = random(32, 128)},
        {name = 'copper-ore', count = random(32, 128)},
        {name = 'submachine-gun', count = 1},
        {name = 'submachine-gun', count = 1},
        {name = 'submachine-gun', count = 1},
        {name = 'shotgun', count = 1},
        {name = 'shotgun', count = 1},
        {name = 'shotgun', count = 1},
        {name = 'burner-mining-drill', count = 1},
        {name = 'burner-mining-drill', count = 2},
        {name = 'burner-mining-drill', count = 1},
        {name = 'burner-mining-drill', count = 4},
        {name = 'gun-turret', count = 1},
        {name = 'gun-turret', count = 1},
        {name = 'gun-turret', count = 1},
        {name = 'shotgun-shell', count = random(4, 5)},
        {name = 'shotgun-shell', count = random(4, 5)},
        {name = 'shotgun-shell', count = random(4, 5)},
        {name = 'grenade', count = random(2, 7)},
        {name = 'grenade', count = random(2, 8)},
        {name = 'grenade', count = random(2, 7)},
        {name = 'light-armor', count = random(2, 4)},
        {name = 'iron-gear-wheel', count = random(7, 15)},
        {name = 'iron-gear-wheel', count = random(7, 15)},
        {name = 'iron-gear-wheel', count = random(7, 15)},
        {name = 'iron-gear-wheel', count = random(7, 15)},
        {name = 'iron-plate', count = random(15, 23)},
        {name = 'iron-plate', count = random(15, 23)},
        {name = 'iron-plate', count = random(15, 23)},
        {name = 'iron-plate', count = random(15, 23)},
        {name = 'copper-plate', count = random(15, 23)},
        {name = 'copper-plate', count = random(15, 23)},
        {name = 'copper-plate', count = random(15, 23)},
        {name = 'copper-plate', count = random(15, 23)},
        {name = 'firearm-magazine', count = random(10, 15)},
        {name = 'firearm-magazine', count = random(10, 15)},
        {name = 'firearm-magazine', count = random(10, 15)},
        {name = 'firearm-magazine', count = random(10, 15)}
    }
end

local generate_spawn_area_token =
    Token.register(
    function(data)
        local surface_index = data.surface_index
        local surface = game.get_surface(surface_index)
        local spawn_area_generated = Public.get('spawn_area_generated')
        if spawn_area_generated then
            return
        end

        local chunk_load_tick = Public.get('chunk_load_tick')
        if chunk_load_tick > game.tick then
            if game.tick % 100 == 1 then
                game.print('[color=blue][Map Generator][/color] Generating map in progress...')
            end
            return
        end

        local spawn_position_x = -128

        surface.create_entity({name = 'electric-beam', position = {254, -143}, source = {254, -143}, target = {254, 193}}) -- fish
        --surface.create_entity({name = 'electric-beam', position = {160, -101}, source = {160, -101}, target = {160, 248}}) -- fish
        --surface.create_entity({name = 'electric-beam', position = {160, -88}, source = {160, -88}, target = {160, 185}})

        for _, tile in pairs(surface.find_tiles_filtered({name = {'water', 'deepwater'}, area = {{-300, -256}, {300, 300}}})) do
            surface.set_tiles({{name = Public.get_replacement_tile(surface, tile.position), position = {tile.position.x, tile.position.y}}}, true)
        end

        for _, entity in pairs(surface.find_entities_filtered({type = {'resource', 'cliff'}, area = {{-300, -256}, {300, 300}}})) do
            entity.destroy()
        end

        local decorative_names = {}
        for k, v in pairs(game.decorative_prototypes) do
            if v.autoplace_specification then
                decorative_names[#decorative_names + 1] = k
            end
        end
        for x = -4, 4, 1 do
            for y = -3, 3, 1 do
                surface.regenerate_decorative(decorative_names, {{x, y}})
            end
        end

        local _y = 80
        local ore_positions = {
            {x = spawn_position_x - 52, y = _y},
            {x = spawn_position_x - 52, y = _y * 0.5},
            {x = spawn_position_x - 52, y = 0},
            {x = spawn_position_x - 52, y = _y * -0.5},
            {x = spawn_position_x - 52, y = _y * -1}
        }
        shuffle(ore_positions)

        resource_placement(surface, ore_positions[1], 'copper-ore', 1500000, 650)
        resource_placement(surface, ore_positions[2], 'iron-ore', 1500000, 650)
        resource_placement(surface, ore_positions[3], 'coal', 1300000, 650)
        resource_placement(surface, ore_positions[4], 'stone', 1300000, 650)

        for _ = 0, 10, 1 do
            place_rock(surface, ore_positions[4]) --add rocks to stone area
        end

        map_functions.draw_noise_tile_circle({x = spawn_position_x - 20, y = 0}, 'water', surface, 16)
        map_functions.draw_oil_circle(ore_positions[5], 'crude-oil', surface, 8, 200000)

        local pos = surface.find_non_colliding_position('market', {spawn_position_x, 0}, 50, 1)
        local market = Public.set('market', place_fish_market(surface, pos))

        local r = 16
        for _, entity in pairs(
            surface.find_entities_filtered(
                {
                    area = {
                        {market.position.x - r, market.position.y - r},
                        {market.position.x + r, market.position.y + r}
                    },
                    type = 'tree'
                }
            )
        ) do
            local distance_to_center = sqrt((entity.position.x - market.position.x) ^ 2 + (entity.position.y - market.position.y) ^ 2)
            if distance_to_center < r then
                if random(1, r) > distance_to_center then
                    entity.destroy()
                end
            end
        end

        local turret_pos = surface.find_non_colliding_position('gun-turret', {spawn_position_x + 5, 1}, 50, 1)
        local turret = surface.create_entity({name = 'gun-turret', position = turret_pos, force = 'player'})
        turret.insert({name = 'firearm-magazine', count = 32})

        local cargo_boxes = initial_cargo_boxes()

        for x = -20, 20, 1 do
            for y = -20, 20, 1 do
                local market_pos = {x = market.position.x + x, y = market.position.y + y}
                local distance_to_center = x ^ 2 + y ^ 2
                if distance_to_center > 64 and distance_to_center < 225 then
                    if random(1, 3) == 1 and surface.can_place_entity({name = 'wooden-chest', position = market_pos, force = 'player'}) then
                        local e = surface.create_entity({name = 'wooden-chest', position = market_pos, force = 'player', create_build_effect_smoke = false})
                        if random(1, 8) == 1 then
                            local inventory = e.get_inventory(defines.inventory.chest)
                            inventory.insert(cargo_boxes[random(1, #cargo_boxes)])
                        end
                    end
                end
            end
        end

        local area = {{x = -160, y = -96}, {x = 160, y = 96}}
        for _, tile in pairs(surface.find_tiles_filtered({name = 'water', area = area})) do
            if random(1, 32) == 1 then
                surface.create_entity({name = 'fish', position = tile.position})
            end
        end

        local character_pos = surface.find_non_colliding_position('character', {spawn_position_x + 1, 4}, 50, 1)
        game.forces['player'].set_spawn_position(character_pos, surface)

        for _, player in pairs(game.connected_players) do
            local spawn_pos = surface.find_non_colliding_position('character', {spawn_position_x + 1, 4}, 50, 1)
            player.teleport(spawn_pos, surface)
        end

        local rr = 200
        local p = {x = -131, y = 5}
        game.forces.player.chart(
            surface,
            {
                {p.x - rr - 100, p.y - rr},
                {p.x + rr + 400, p.y + rr}
            }
        )

        Public.set('spawn_area_generated', true)
    end
)

local function process_chunk(left_top)
    local active_surface_index = Public.get('active_surface_index')
    local surface = game.get_surface(active_surface_index)
    if not surface or not surface.valid then
        return
    end

    Task.set_timeout_in_ticks(1, request_to_generate_chunks_token, {surface_index = surface.index})
    Task.set_timeout_in_ticks(15, generate_spawn_area_token, {surface_index = surface.index})
    Task.set_timeout_in_ticks(60, enemy_territory_token, {surface_index = surface.index, left_top = left_top})
    Task.set_timeout_in_ticks(90, fish_mouth_token, {surface_index = surface.index, left_top = left_top})

    local market = Public.get('market')

    game.forces.player.chart(surface, {{left_top.x, left_top.y}, {left_top.x + 31, left_top.y + 31}})
    if market and market.valid then
        Public.set('game_reset', false)
    end
end

local function on_chunk_generated(event)
    local map_name = 'fish_defender'
    local surface = event.surface
    local area = event.area
    local left_top = area.left_top

    if string.sub(surface.name, 0, #map_name) ~= map_name then
        return
    end

    if Public.get('stop_generating_map') then
        return
    end

    Public.make_chunk(event)

    process_chunk(left_top)
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)

return Public
