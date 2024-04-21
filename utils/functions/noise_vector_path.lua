--draws lines modified by noise -- mewmew

local simplex_noise = require 'utils.simplex_noise'.d2
local Public = {}

local function get_brush(size)
    local vectors = {}
    for x = size * -1, size, 1 do
        for y = size * -1, size, 1 do
            if math.sqrt(y ^ 2 + x ^ 2) <= size then
                vectors[#vectors + 1] = {x, y}
            end
        end
    end
    return vectors
end

local function get_brush_unfiltered(size)
    local vectors = {}
    for x = size, size * -1, -1 do
        for y = size * -1, size, 1 do
            vectors[#vectors + 1] = {x = x, y = y}
        end
    end
    return vectors
end

function Public.noise_vector_entity_path(surface, entity_name, position, base_vector, length, collision)
    local seed_1 = math.random(1, 10000000)
    local seed_2 = math.random(1, 10000000)
    local vector = {}
    local entities = {}
    local minimal_movement = 0.5

    for _ = 1, length, 1 do
        if collision then
            if surface.can_place_entity({name = entity_name, position = position}) then
                entities[#entities + 1] = surface.create_entity({name = entity_name, position = position})
            end
        else
            entities[#entities + 1] = surface.create_entity({name = entity_name, position = position})
        end

        local noise = simplex_noise(position.x * 0.01, position.y * 0.01, seed_1)
        local noise_2 = simplex_noise(position.x * 0.01, position.y * 0.01, seed_2)

        vector[1] = base_vector[1] + noise * 0.85
        vector[2] = base_vector[2] + noise_2 * 0.85

        --enforce minimum movement
        if math.abs(vector[1]) < minimal_movement and math.abs(vector[2]) < minimal_movement then
            local i = math.random(1, 2)
            if vector[i] < 0 then
                vector[i] = minimal_movement * -1
            else
                vector[i] = minimal_movement
            end
        end

        position = {x = position.x + vector[1], y = position.y + vector[2]}
    end

    return entities
end

function Public.noise_vector_tile_path(surface, tile_name, position, base_vector, length, brush_size, whitelist)
    local seed_1 = math.random(1, 10000000)
    local seed_2 = math.random(1, 10000000)
    local m = math.random(1, 100) * 0.001
    local vector = {}
    local tiles = {}
    local minimal_movement = 0.65
    local brush_vectors = get_brush(brush_size)

    for _ = 1, length, 1 do
        for _, v in pairs(brush_vectors) do
            local p = {x = position.x + v[1], y = position.y + v[2]}
            if whitelist then
                local tile = surface.get_tile(p)
                if tile.valid then
                    if whitelist[tile.name] then
                        surface.set_tiles({{name = tile_name, position = p}}, true)
                        tiles[#tiles + 1] = {name = tile_name, position = p}
                    end
                end
            else
                surface.set_tiles({{name = tile_name, position = p}}, true)
                tiles[#tiles + 1] = {name = tile_name, position = p}
            end
        end

        local noise = simplex_noise(position.x * m, position.y * m, seed_1)
        local noise_2 = simplex_noise(position.x * m, position.y * m, seed_2)

        vector[1] = base_vector[1] + noise
        vector[2] = base_vector[2] + noise_2

        if math.abs(vector[1]) < minimal_movement and math.abs(vector[2]) < minimal_movement then
            local i = math.random(1, 2)
            if vector[i] < 0 then
                vector[i] = minimal_movement * -1
            else
                vector[i] = minimal_movement
            end
        end

        position = {x = position.x + vector[1], y = position.y + vector[2]}
    end

    return tiles
end

function Public.noise_vector_tiles_path(surface, tbl_tiles, position, base_vector, length, brush_size, whitelist, seed_1, seed_2, m)
    seed_1 = seed_1 or math.random(1, 10000000)
    seed_2 = seed_2 or math.random(1, 10000000)
    m = m or math.random(1, 100) * 0.001
    local vector = {}
    local tiles = {}
    local minimal_movement = 0.40
    local brush_vectors = get_brush_unfiltered(brush_size)

    local tile_name = tbl_tiles[math.random(1, #tbl_tiles)]

    for _ = 1, length, 1 do
        for _, brush in pairs(brush_vectors) do
            local p = {x = position.x + brush.x, y = position.y + brush.y}
            if whitelist then
                local tile = surface.get_tile(p)
                if tile.valid then
                    if whitelist[tile.name] then
                        surface.set_tiles({{name = tile_name, position = p}}, true)
                        tiles[#tiles + 1] = {name = tile_name, position = p}
                    end
                end
            end
        end

        local noise = simplex_noise(position.x * m, position.y * m, seed_1)
        local noise_2 = simplex_noise(position.x * m, position.y * m, seed_2)

        vector[1] = base_vector[1] + noise
        vector[2] = base_vector[2] + noise_2

        if math.abs(vector[1]) < minimal_movement and math.abs(vector[2]) < minimal_movement then
            local i = math.random(1, 2)
            if vector[i] < 0 then
                vector[i] = minimal_movement * -1
            else
                vector[i] = minimal_movement
            end
        end

        position = {x = position.x + vector[1], y = position.y + vector[2]}
    end

    return tiles, seed_1, seed_2, m
end

--/c noise_vector_path(game.player.surface, "tree-04", game.player.position, {0,0})

return Public
