local Event = require 'utils.event'
local Builder = require 'maps.fish_defender_v2.b'
local map_functions = require 'tools.map_functions'
local simplex_noise = require 'utils.simplex_noise'.d2
local FDT = require 'maps.fish_defender_v2.table'
local math_random = math.random
local math_abs = math.abs
local math_sqrt = math.sqrt

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math.random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local function get_replacement_tile(surface, position)
    for i = 1, 128, 1 do
        local vectors = {{0, i}, {0, i * -1}, {i, 0}, {i * -1, 0}}
        shuffle(vectors)
        for k, v in pairs(vectors) do
            local tile = surface.get_tile(position.x + v[1], position.y + v[2])
            if not tile.collides_with('resource-layer') then
                return tile.name
            end
        end
    end
    return 'grass-1'
end

local function is_enemy_territory(p)
    if p.x - 64 < math_abs(p.y) then
        return false
    end
    --if p.x - 64 < p.y then return false end
    if p.x < 160 then
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

local function enemy_territory(surface, left_top)
    if left_top.x < 160 then
        return
    end
    if left_top.x > 750 then
        return
    end
    if left_top.y > 766 then
        return
    end
    if left_top.y < -160 then
        return
    end

    local area = {{left_top.x, left_top.y}, {left_top.x + 32, left_top.y + 32}}

    if left_top.x > 256 then
        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                local pos = {x = left_top.x + x, y = left_top.y + y}
                if is_enemy_territory(pos) then
                    if math_random(1, 512) == 1 then
                        if surface.can_place_entity({name = 'biter-spawner', force = 'decoratives', position = pos}) then
                            local entity
                            if math_random(1, 4) == 1 then
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
            surface.create_entity({name = 'uranium-ore', position = entity.position, amount = math_random(200, 8000)})
            entity.destroy()
        end
    end
    for _, tile in pairs(surface.find_tiles_filtered({name = {'water', 'deepwater'}, area = area})) do
        if is_enemy_territory(tile.position) then
            surface.set_tiles({{name = get_replacement_tile(surface, tile.position), position = {tile.position.x, tile.position.y}}}, true)
        end
    end
end

local function fish_mouth(surface, left_top)
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

local function generate_spawn_area(this, surface)
    if this.spawn_area_generated then
        return
    end

    surface.request_to_generate_chunks({x = 0, y = 0}, 7)
    surface.request_to_generate_chunks({x = 160, y = 0}, 4)

    if not surface.is_chunk_generated({-7, 0}) then
        return
    end
    if not surface.is_chunk_generated({5, 0}) then
        return
    end

    local spawn_position_x = -128

    surface.create_entity({name = 'electric-beam', position = {160, -132}, source = {160, -132}, target = {160, 179}}) -- fish
    --surface.create_entity({name = 'electric-beam', position = {160, -101}, source = {160, -101}, target = {160, 248}}) -- fish
    --surface.create_entity({name = 'electric-beam', position = {160, -88}, source = {160, -88}, target = {160, 185}})

    for _, tile in pairs(surface.find_tiles_filtered({name = {'water', 'deepwater'}, area = {{-160, -160}, {160, 160}}})) do
        local noise = math_abs(simplex_noise(tile.position.x * 0.02, tile.position.y * 0.02, game.surfaces[1].map_gen_settings.seed) * 16)
        if tile.position.x > -160 + noise then
            surface.set_tiles({{name = get_replacement_tile(surface, tile.position), position = {tile.position.x, tile.position.y}}}, true)
        end
    end

    for _, entity in pairs(
        surface.find_entities_filtered({type = {'resource', 'cliff'}, area = {{spawn_position_x - 32, -256}, {160, 256}}})
    ) do
        if
            entity.position.x >
                spawn_position_x - 32 +
                    math_abs(simplex_noise(entity.position.x * 0.02, entity.position.y * 0.02, game.surfaces[1].map_gen_settings.seed) * 16)
         then
            entity.destroy()
        end
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
    map_functions.draw_smoothed_out_ore_circle(ore_positions[1], 'copper-ore', surface, 15, 2500)
    map_functions.draw_smoothed_out_ore_circle(ore_positions[2], 'iron-ore', surface, 15, 2500)
    map_functions.draw_smoothed_out_ore_circle(ore_positions[3], 'coal', surface, 15, 1500)
    map_functions.draw_smoothed_out_ore_circle(ore_positions[4], 'stone', surface, 15, 1500)
    map_functions.draw_noise_tile_circle({x = spawn_position_x - 20, y = 0}, 'water', surface, 16)
    map_functions.draw_oil_circle(ore_positions[5], 'crude-oil', surface, 8, 200000)

    local pos = surface.find_non_colliding_position('market', {spawn_position_x, 0}, 50, 1)
    this.market = place_fish_market(surface, pos)

    local r = 16
    for _, entity in pairs(
        surface.find_entities_filtered(
            {
                area = {
                    {this.market.position.x - r, this.market.position.y - r},
                    {this.market.position.x + r, this.market.position.y + r}
                },
                type = 'tree'
            }
        )
    ) do
        local distance_to_center =
            math_sqrt((entity.position.x - this.market.position.x) ^ 2 + (entity.position.y - this.market.position.y) ^ 2)
        if distance_to_center < r then
            if math_random(1, r) > distance_to_center then
                entity.destroy()
            end
        end
    end

    local turret_pos = surface.find_non_colliding_position('gun-turret', {spawn_position_x + 5, 1}, 50, 1)
    local turret = surface.create_entity({name = 'gun-turret', position = turret_pos, force = 'player'})
    turret.insert({name = 'firearm-magazine', count = 32})

    for x = -20, 20, 1 do
        for y = -20, 20, 1 do
            local market_pos = {x = this.market.position.x + x, y = this.market.position.y + y}
            local distance_to_center = x ^ 2 + y ^ 2
            if distance_to_center > 64 and distance_to_center < 225 then
                if math_random(1, 3) == 1 and surface.can_place_entity({name = 'wooden-chest', position = market_pos, force = 'player'}) then
                    surface.create_entity({name = 'wooden-chest', position = market_pos, force = 'player'})
                end
            end
        end
    end

    local area = {{x = -160, y = -96}, {x = 160, y = 96}}
    for _, tile in pairs(surface.find_tiles_filtered({name = 'water', area = area})) do
        if math_random(1, 32) == 1 then
            surface.create_entity({name = 'fish', position = tile.position})
        end
    end

    local character_pos = surface.find_non_colliding_position('character', {spawn_position_x + 1, 4}, 50, 1)
    game.forces['player'].set_spawn_position(character_pos, surface)
    for _, player in pairs(game.connected_players) do
        local spawn_pos = surface.find_non_colliding_position('character', {spawn_position_x + 1, 4}, 50, 1)
        player.teleport(spawn_pos, surface)
    end
    this.spawn_area_generated = true
end

local function process_chunk(left_top)
    local this = FDT.get()
    local surface = game.surfaces[this.active_surface_index]
    if not surface or not surface.valid then
        return
    end

    generate_spawn_area(this, surface, left_top)
    enemy_territory(surface, left_top)
    fish_mouth(surface, left_top)

    game.forces.player.chart(surface, {{left_top.x, left_top.y}, {left_top.x + 31, left_top.y + 31}})
    if this.market and this.market.valid then
        this.game_reset = false
    end
end

local function on_chunk_generated(event)
    local map_name = 'fish_defender'

    if string.sub(event.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local left_top = event.area.left_top
    Builder.make_chunk(event)

    process_chunk(left_top)
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)
