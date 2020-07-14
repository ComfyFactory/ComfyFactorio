local simplex_noise = require 'utils.simplex_noise'.d2
-- local map_data = require 'maps.fish_defender_v2.fish_defender_layout'
local map_data = require 'maps.fish_defender_v2.cat_defender_layout_v2'

local random = math.random
local abs = math.abs
local floor = math.floor
local scale = 1

local Public = {}

local tile_map = {
    [1] = false,
    [2] = true,
    [3] = 'concrete',
    [4] = 'deepwater-green',
    [5] = 'deepwater',
    [6] = 'dirt-1',
    [7] = 'dirt-2',
    [8] = 'dirt-3',
    [9] = 'dirt-4',
    [10] = 'dirt-5',
    [11] = 'dirt-6',
    [12] = 'dirt-7',
    [13] = 'dry-dirt',
    [14] = 'grass-1',
    [15] = 'grass-2',
    [16] = 'grass-3',
    [17] = 'grass-4',
    [18] = 'hazard-concrete-left',
    [19] = 'hazard-concrete-right',
    [20] = 'lab-dark-1',
    [21] = 'lab-dark-2',
    [22] = 'lab-white',
    [23] = 'out-of-map',
    [24] = 'red-desert-0',
    [25] = 'red-desert-1',
    [26] = 'red-desert-2',
    [27] = 'red-desert-3',
    [28] = 'sand-1',
    [29] = 'sand-2',
    [30] = 'sand-3',
    [31] = 'stone-path',
    [32] = 'water-green',
    [33] = 'water'
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
    'rock-huge'
}

local function decompress()
    local decompressed = {}
    local data = map_data.data
    local height = map_data.height
    local width = map_data.width

    for y = 1, height do
        local row = data[y]
        local u_row = {}
        decompressed[y] = u_row
        local x = 1
        for index = 1, #row, 2 do
            local pixel = row[index]
            local count = row[index + 1]

            for _ = 1, count do
                u_row[x] = pixel
                x = x + 1
            end
        end
    end

    return decompressed, width, height
end
local tile_data, width, height = decompress()

local function get_pos(x, y)
    -- the plus one is because lua tables are one based.
    local half_width = floor(width / 2) + 1
    local half_height = floor(height / 2) + 1
    x = x / scale
    y = y / scale
    x = floor(x)
    y = floor(y)
    local x2 = x + half_width
    local y2 = y + half_height

    if y2 > 0 and y2 <= height and x2 > 0 and x2 <= width then
        return tile_map[tile_data[y2][x2]]
    end
end

local ores = {'coal', 'iron-ore', 'copper-ore', 'stone'}

local function plankton_territory(position, seed, ent)
    local noise = simplex_noise(position.x * 0.009, position.y * 0.009, seed)
    local d = 196

    if get_pos(position.x, position.y) then
        return
    end

    if
        position.x + position.y > (d * -1) - (abs(noise) * d * 3) and
            position.x > position.y - (d + (abs(noise) * d * 3))
     then
        return 'out-of-map'
    end

    local noise_2 = simplex_noise(position.x * 0.0075, position.y * 0.0075, seed + 10000)
    --if noise_2 > 0.87 then surface.set_tiles({{name = "deepwater-green", position = position}}, true) return true end
    if noise_2 > 0.87 then
        return 'deepwater-green'
    end
    if noise_2 > 0.75 then
        local i = floor(noise * 6) % 4 + 1
        --surface.set_tiles({{name = "grass-" .. i, position = position}}, true)
        ent[#ent + 1] = {name = ores[i], position = position, amount = 1 + 2500 * abs(noise_2 * 3)}
        return ('grass-' .. i)
    end
    if noise_2 < -0.76 then
        local i = floor(noise * 6) % 4 + 1
        --surface.set_tiles({{name = "grass-" .. i, position = position}}, true)
        if noise_2 < -0.86 then
            ent[#ent + 1] = {name = 'uranium-ore', position = position, amount = 1 + 1000 * abs(noise_2 * 2)}

            return ('grass-' .. i)
        end
        if random(1, 3) ~= 1 then
            ent[#ent + 1] = {name = rock_raffle[random(1, #rock_raffle)], position = position}
        end
        return ('grass-' .. i)
    end

    if noise < 0.12 and noise > -0.12 then
        local i = floor(noise * 32) % 4 + 1
        --surface.set_tiles({{name = "grass-" .. i, position = position}}, true)
        if random(1, 5) == 1 then
            ent[#ent + 1] = {name = rock_raffle[random(1, #rock_raffle)], position = position}
        end
        return ('grass-' .. i)
    end

    --surface.set_tiles({{name = "water", position = position}}, true)
    if random(1, 128) == 1 then
        ent[#ent + 1] = {name = 'fish', position = position}
    end

    return 'water'
end

local function get_random_ore(position)
    local noise = (position.x * 0.009)
    local i = floor(noise * 6) % 4 + 1
    local ore = ores[i]

    return ore
end

function Public.make_chunk(event)
    local map_name = 'fish_defender'

    if string.sub(event.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local surface = event.surface

    local x1 = event.area.left_top.x
    local y1 = event.area.left_top.y
    local x2 = event.area.right_bottom.x
    local y2 = event.area.right_bottom.y

    local seed = game.surfaces[1].map_gen_settings.seed

    local noise = {}
    local tiles = {}
    local ent = {}

    for x = x1, x2 do
        for y = y1, y2 do
            local pos = {x = x, y = y}
            local new = get_pos(x, y)
            local ore = get_random_ore(pos)

            if new and type(new) == 'string' then
                if new == 'lab-dark-2' then
                    ent[#ent + 1] = {name = ore, position = pos, amount = 2500}
                else
                    tiles[#tiles + 1] = {name = new, position = pos}
                end
            else
                local tile_to_set = plankton_territory(pos, seed, ent)
                if tile_to_set then
                    noise[#noise + 1] = {name = tile_to_set, position = pos}
                end
            end
        end
    end

    surface.set_tiles(tiles, true)
    surface.set_tiles(noise, true)
    for i = 1, #ent do
        if ent[i].amount then
            surface.create_entity({name = ent[i].name, position = ent[i].position, amount = ent[i].amount})
        else
            surface.create_entity({name = ent[i].name, position = ent[i].position})
        end
    end
end

return Public
