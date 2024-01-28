local Event = require 'utils.event'
local Builder = require 'maps.crab_defender.b'
local map_functions = require 'utils.tools.map_functions'
local simplex_noise = require 'utils.simplex_noise'.d2
local FDT = require 'maps.crab_defender.table'
local math_random = math.random
local math_abs = math.abs

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

local function is_enemy_territory(surface, p)
    local get_tile = surface.get_tile(p)
    if get_tile.valid and get_tile.name == 'tutorial-grid' then
        return true
    end

    return false
end

local function place_crab_market(surface, position)
    local market = surface.create_entity({name = 'market', position = position, force = 'player'})
    market.minable = false
    return market
end

local function enemy_territory(surface, left_top)
    if left_top.x > 778 then
        return
    end
    if left_top.x < -607 then
        return
    end
    if left_top.y < -590 then
        return
    end
    if left_top.y > -150 then
        return
    end

    local area = {{left_top.x, left_top.y}, {left_top.x + 32, left_top.y + 32}}
    local find_entities_filtered = surface.find_entities_filtered

    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local pos = {x = left_top.x + x, y = left_top.y + y}
            local get_tile = surface.get_tile(pos)

            if is_enemy_territory(surface, pos) then
                if get_tile.valid and get_tile.name == 'tutorial-grid' then
                    if math_random(1, 1024) == 1 then
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

    for _, entity in pairs(find_entities_filtered({area = area, type = 'resource'})) do
        if is_enemy_territory(surface, entity.position) then
            surface.create_entity({name = 'uranium-ore', position = entity.position, amount = math_random(200, 8000)})
            entity.destroy()
        end
    end
end

local function render_market_hp()
    local this = FDT.get()
    local surface = game.surfaces[this.active_surface_index]
    if not surface or not surface.valid then
        return
    end

    this.caption =
        rendering.draw_text {
        text = 'Crab Market',
        surface = surface,
        target = this.market,
        target_offset = {0, -3.4},
        color = {0, 255, 0},
        scale = 1.80,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false
    }
end

local function generate_spawn_area(this, surface)
    if this.spawn_area_generated then
        return
    end
    local find_entities_filtered = surface.find_entities_filtered

    surface.request_to_generate_chunks({x = 0, y = 0}, 1)
    surface.request_to_generate_chunks({x = 32, y = 118}, 1)

    if not surface.is_chunk_generated({-7, 0}) then
        return
    end
    if not surface.is_chunk_generated({5, 0}) then
        return
    end

    local spawn_position_x = 32
    local spawn_position_y = 120

    surface.create_entity({name = 'electric-beam', position = {-532, -10}, source = {-532, -10}, target = {-471, -124}})
    surface.create_entity({name = 'electric-beam', position = {665, -10}, source = {665, -10}, target = {601, -127}})

    for _, tile in pairs(surface.find_tiles_filtered({name = {'water', 'deepwater'}, area = {{-145, -133}, {32, 59}}})) do
        local noise = math_abs(simplex_noise(tile.position.x * 0.02, tile.position.y * 0.02, game.surfaces[1].map_gen_settings.seed) * 16)
        if tile.position.x > -160 + noise then
            surface.set_tiles({{name = get_replacement_tile(surface, tile.position), position = {tile.position.x, tile.position.y}}}, true)
        end
    end

    for _, entity in pairs(
        find_entities_filtered(
            {
                type = {'resource', 'cliff'},
                area = {
                    {spawn_position_x - 128, spawn_position_y - 132},
                    {spawn_position_x + 64, spawn_position_y + 32}
                }
            }
        )
    ) do
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

    local ore_positions = {
        {x = spawn_position_x - 80, y = spawn_position_y + 50},
        {x = spawn_position_x - 40, y = spawn_position_y + 50},
        {x = spawn_position_x, y = spawn_position_y + 50},
        {x = spawn_position_x + 40, y = spawn_position_y + 50},
        {x = spawn_position_x + 80, y = spawn_position_y + 50}
    }
    shuffle(ore_positions)
    map_functions.draw_smoothed_out_ore_circle(ore_positions[1], 'copper-ore', surface, 15, 2500)
    map_functions.draw_smoothed_out_ore_circle(ore_positions[2], 'iron-ore', surface, 15, 2500)
    map_functions.draw_smoothed_out_ore_circle(ore_positions[3], 'coal', surface, 15, 1500)
    map_functions.draw_smoothed_out_ore_circle(ore_positions[4], 'stone', surface, 15, 1500)
    map_functions.draw_noise_tile_circle({x = spawn_position_x, y = spawn_position_y + 25}, 'water', surface, 16)
    map_functions.draw_oil_circle(ore_positions[5], 'crude-oil', surface, 8, 200000)

    local pos = surface.find_non_colliding_position('market', {spawn_position_x, spawn_position_y}, 50, 1)
    this.market = place_crab_market(surface, pos)

    render_market_hp()

    local r = 32
    for _, entity in pairs(
        find_entities_filtered(
            {
                area = {
                    {this.market.position.x - r, this.market.position.y - r},
                    {this.market.position.x + r, this.market.position.y + r}
                },
                type = 'tree'
            }
        )
    ) do
        entity.destroy()
    end

    local turret_pos = surface.find_non_colliding_position('gun-turret', {spawn_position_x, spawn_position_y - 5}, 50, 1)
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

    local character_pos = surface.find_non_colliding_position('character', {spawn_position_x + 1, spawn_position_y}, 50, 1)
    game.forces['player'].set_spawn_position(character_pos, surface)
    for _, player in pairs(game.connected_players) do
        local spawn_pos = surface.find_non_colliding_position('character', {spawn_position_x + 1, spawn_position_y}, 50, 1)
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
    local find_entities_filtered = surface.find_entities_filtered

    generate_spawn_area(this, surface, left_top)
    enemy_territory(surface, left_top)

    for _, entity in pairs(
        find_entities_filtered(
            {
                area = {{left_top.x - 32, left_top.y - 32}, {left_top.x + 32, left_top.y + 32}},
                type = {'tree', 'simple-entity', 'cliff'}
            }
        )
    ) do
        if is_enemy_territory(surface, entity.position) then
            entity.destroy()
        end
    end

    game.forces.player.chart(surface, {{left_top.x, left_top.y}, {left_top.x + 31, left_top.y + 31}})
    if this.market and this.market.valid then
        this.game_reset = false
    end
end

local function on_chunk_generated(event)
    local map_name = 'crab_defender'

    if string.sub(event.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local left_top = event.area.left_top
    Builder.make_chunk(event)

    process_chunk(left_top)
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)
