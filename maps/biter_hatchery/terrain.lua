local math_abs = math.abs
local math_random = math.random
local GetNoise = require 'utils.get_noise'
local Public = {}

local hatchery_position = {x = 192, y = 0}

local function get_replacement_tile(surface, position)
    for i = 1, 128, 1 do
        local vectors = {{0, i}, {0, i * -1}, {i, 0}, {i * -1, 0}}
        table.shuffle_table(vectors)
        for k, v in pairs(vectors) do
            local tile = surface.get_tile(position.x + v[1], position.y + v[2])
            if not tile.collides_with('resource-layer') then
                return tile.name
            end
        end
    end
    return 'landfill'
end

local function draw_spawn_ore(surface, position)
    local ores = {'copper-ore', 'iron-ore', 'coal', 'stone'}
    table.shuffle_table(ores)

    local seed = math_random(1, 1000000)
    local r = 25
    local r_square = r ^ 2

    for x = -32, 32, 1 do
        for y = -32, 32, 1 do
            local position = {x = position.x + x + 0.5, y = position.y + y + 0.5}
            if x ^ 2 + y ^ 2 + math_abs(GetNoise('decoratives', position, seed) * 300) < r_square then
                local name = ores[1]
                if y <= 0 and x < 0 then
                    name = ores[2]
                end
                if y >= 0 and x >= 0 then
                    name = ores[3]
                end
                if y >= 0 and x < 0 then
                    name = ores[4]
                end
                for _, e in pairs(surface.find_entities_filtered({position = position})) do
                    e.destroy()
                end
                local tile = surface.get_tile(position)
                if tile.name == 'water' or tile.name == 'deepwater' then
                    surface.set_tiles({{name = get_replacement_tile(surface, position), position = position}}, true)
                end
                surface.create_entity({name = name, position = position, amount = math_random(800, 1000)})
            end
        end
    end
end

function Public.reset_nauvis(hatchery)
    local surface = game.surfaces.nauvis
    local mgs = surface.map_gen_settings
    mgs.seed = math_random(1, 99999999)
    mgs.water = 1
    mgs.starting_area = 1
    mgs.terrain_segmentation = 2
    mgs.cliff_settings = {cliff_elevation_interval = 0, cliff_elevation_0 = 0}
    mgs.autoplace_controls = {
        ['coal'] = {frequency = 8, size = 0.7, richness = 0.5},
        ['stone'] = {frequency = 8, size = 0.7, richness = 0.5},
        ['copper-ore'] = {frequency = 8, size = 0.7, richness = 0.75},
        ['iron-ore'] = {frequency = 8, size = 0.7, richness = 1},
        ['uranium-ore'] = {frequency = 5, size = 0.5, richness = 0.5},
        ['crude-oil'] = {frequency = 5, size = 1, richness = 1},
        ['trees'] = {frequency = math.random(4, 32) * 0.1, size = math.random(4, 16) * 0.1, richness = math.random(1, 10) * 0.1},
        ['enemy-base'] = {frequency = 0, size = 0, richness = 0}
    }
    surface.map_gen_settings = mgs
    surface.clear(false)
    for chunk in surface.get_chunks() do
        surface.delete_chunk({chunk.x, chunk.y})
    end
    hatchery.gamestate = 'prepare_east'
    game.print('preparing east', {150, 150, 150})
    print(hatchery.gamestate)
end

function Public.prepare_east(hatchery)
    if game.tick % 90 ~= 0 then
        return
    end
    local surface = game.surfaces.nauvis
    surface.request_to_generate_chunks({hatchery_position.x, 0}, 7)

    if not surface.is_chunk_generated({13, 0}) then
        return
    end

    local r = 32
    local seed = surface.map_gen_settings.seed
    for x = r * -1, r, 1 do
        for y = r * -1, r, 1 do
            local p = {x = hatchery_position.x + x, y = hatchery_position.y + y}
            if math.sqrt(x ^ 2 + y ^ 2) + math_abs(GetNoise('decoratives', p, seed) * 9) < r then
                local tile = surface.get_tile(p)
                if tile.name == 'water' or tile.name == 'deepwater' then
                    surface.set_tiles({{name = get_replacement_tile(surface, p), position = p}}, true)
                end
            end
        end
    end
    draw_spawn_ore(surface, {x = 240, y = 0})
    hatchery.gamestate = 'clear_west'
    game.print('clearing west chunks', {150, 150, 150})
    print(hatchery.gamestate)
end

function Public.clear_west(hatchery)
    if game.tick % 90 ~= 0 then
        return
    end
    local surface = game.surfaces.nauvis
    for chunk in surface.get_chunks() do
        if chunk.x < 0 then
            surface.delete_chunk({chunk.x, chunk.y})
        end
    end
    hatchery.mirror_queue = {}
    hatchery.gamestate = 'prepare_west'
    game.print('preparing west chunks', {150, 150, 150})
    print(hatchery.gamestate)
end

function Public.prepare_west(hatchery)
    if game.tick % 90 ~= 0 then
        return
    end
    local surface = game.surfaces.nauvis
    surface.request_to_generate_chunks({hatchery_position.x * -1, 0}, 7)
    surface.force_generate_chunk_requests()
    if hatchery.mirror_queue[1] then
        return
    end
    hatchery.gamestate = 'draw_team_nests'
    print(hatchery.gamestate)
end

function Public.draw_team_nests(hatchery)
    if game.tick % 90 ~= 0 then
        return
    end
    game.print('placing nests', {150, 150, 150})
    local surface = game.surfaces.nauvis
    local x = hatchery_position.x

    local e = surface.create_entity({name = 'biter-spawner', position = {x * -1, 0}, force = 'west'})
    for _, p in pairs({{x * -1 + 6, 0}, {x * -1 + 3, 6}, {x * -1 + 3, -5}}) do
        surface.create_entity({name = 'small-worm-turret', position = p, force = 'west'})
        surface.create_decoratives {check_collision = false, decoratives = {{name = 'enemy-decal', position = p, amount = 1}}}
    end
    e.active = false
    global.map_forces.west.hatchery = e
    global.map_forces.east.target = e
    surface.create_decoratives {check_collision = false, decoratives = {{name = 'enemy-decal', position = e.position, amount = 3}}}

    local e = surface.create_entity({name = 'biter-spawner', position = {x, 0}, force = 'east'})
    for _, p in pairs({{x - 6, 0}, {x - 3, 6}, {x - 3, -5}}) do
        surface.create_entity({name = 'small-worm-turret', position = p, force = 'east'})
        surface.create_decoratives {check_collision = false, decoratives = {{name = 'enemy-decal', position = p, amount = 1}}}
    end

    e.active = false
    global.map_forces.east.hatchery = e
    global.map_forces.west.target = e
    surface.create_decoratives {check_collision = false, decoratives = {{name = 'enemy-decal', position = e.position, amount = 3}}}

    hatchery.gamestate = 'draw_border_beams'
    print(hatchery.gamestate)
end

function Public.draw_border_beams(hatchery)
    if game.tick % 90 ~= 0 then
        return
    end
    local surface = game.surfaces.nauvis
    surface.create_entity({name = 'electric-beam', position = {4, -96}, source = {4, -96}, target = {4, 96}})
    surface.create_entity({name = 'electric-beam', position = {-4, -96}, source = {-4, -96}, target = {-4, 96}})
    hatchery.gamestate = 'spawn_players'
    print(hatchery.gamestate)
end

function Public.combat_area(event)
    local surface = event.surface
    local left_top = event.area.left_top
    local seed = surface.map_gen_settings.seed

    if left_top.x >= 256 or left_top.y < -192 or left_top.y > 192 then
        return
    end
    for _, tile in pairs(surface.find_tiles_filtered({area = event.area, name = {'water', 'deepwater'}})) do
        if tile.position.x + math_abs(GetNoise('cave_rivers', {x = 0, y = tile.position.y}, seed) * 64) < 224 then
            if math_abs(GetNoise('n5', tile.position, seed)) < 0.25 then
                surface.set_tiles({{name = get_replacement_tile(surface, tile.position), position = tile.position}}, true)
            end
        end
    end

    if left_top.x ~= 0 then
        return
    end
    if left_top.y >= 96 then
        return
    end
    if left_top.y < -96 then
        return
    end

    for _, tile in pairs(surface.find_tiles_filtered({area = event.area})) do
        if tile.position.x < 4 then
            surface.set_tiles({{name = 'water-shallow', position = tile.position}}, true)
        end
    end
end

local function mirror_tiles(east_left_top)
    local surface = game.surfaces.nauvis
    surface.request_to_generate_chunks({x = east_left_top.x + 16, y = east_left_top.y + 16}, 0)
    surface.force_generate_chunk_requests()
    local mirror_area = {{east_left_top.x, east_left_top.y}, {east_left_top.x + 32, east_left_top.y + 32}}
    for _, tile in pairs(surface.find_tiles_filtered({area = mirror_area})) do
        surface.set_tiles({{name = tile.name, position = {x = tile.position.x * -1 - 1, y = tile.position.y}}}, true)
    end
end

local function mirror_entities(east_left_top)
    local surface = game.surfaces.nauvis
    local mirror_area = {{east_left_top.x, east_left_top.y}, {east_left_top.x + 32, east_left_top.y + 32}}
    for _, entity in pairs(surface.find_entities_filtered({area = mirror_area})) do
        if surface.can_place_entity({name = entity.name, position = {x = entity.position.x * -1, y = entity.position.y}}) then
            entity.clone({position = {x = entity.position.x * -1, y = entity.position.y}, surface = surface, force = 'neutral'})
        end
    end
end

local function mirror_decoratives(east_left_top)
    local surface = game.surfaces.nauvis
    local mirror_area = {{east_left_top.x, east_left_top.y}, {east_left_top.x + 32, east_left_top.y + 32}}
    for _, decorative in pairs(surface.find_decoratives_filtered {area = mirror_area}) do
        surface.create_decoratives {
            check_collision = false,
            decoratives = {{name = decorative.decorative.name, position = {x = decorative.position.x * -1 - 1, y = decorative.position.y}, amount = decorative.amount}}
        }
    end
end

local mirror_functions = {
    [1] = mirror_tiles,
    [2] = mirror_entities,
    [3] = mirror_decoratives
}

function Public.mirror_queue(hatchery)
    local mirror_queue = hatchery.mirror_queue
    local chunk = mirror_queue[1]
    if not chunk then
        return
    end
    mirror_functions[chunk[2]]({x = chunk[1][1] * -1 - 32, y = chunk[1][2]})
    mirror_queue[1][2] = mirror_queue[1][2] + 1
    if not mirror_functions[mirror_queue[1][2]] then
        table.remove(hatchery.mirror_queue, 1)
    end
end

local function is_out_of_map(p)
    if p.y < 96 and p.y >= -96 then
        return
    end
    if p.x * 0.5 >= math_abs(p.y) then
        return
    end
    if p.x * -0.5 > math_abs(p.y) then
        return
    end
    return true
end

function Public.is_out_of_map_chunk(p)
    if p.y < 96 and p.y >= -96 then
        return
    end
    if p.x * 0.5 + 32 >= math_abs(p.y) then
        return
    end
    if p.x * -0.5 + 32 > math_abs(p.y) then
        return
    end
    return true
end

function Public.out_of_map_area(surface, left_top)
    local tiles = {}
    local i = 1
    for x = -1, 32, 1 do
        for y = -1, 32, 1 do
            local p = {x = left_top.x + x, y = left_top.y + y}
            if is_out_of_map(p) then
                tiles[i] = {name = 'out-of-map', position = {x = left_top.x + x, y = left_top.y + y}}
                i = i + 1
            end
        end
    end
    surface.set_tiles(tiles, true)
end

function Public.out_of_map(surface, left_top)
    local tiles = {}
    local i = 1
    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            tiles[i] = {name = 'out-of-map', position = {x = left_top.x + x, y = left_top.y + y}}
            i = i + 1
        end
    end
    surface.set_tiles(tiles, true)
end

return Public
