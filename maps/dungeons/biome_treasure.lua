local Functions = require 'maps.dungeons.functions'

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local math_random = math.random

local rainbow_tiles = {
    'cyan-refined-concrete',
    'purple-refined-concrete'
}

-- balanced the same as end-game rocks from functions.lua:rocky_loot
local ores = {
    'copper-ore',
    'copper-ore',
    'copper-ore',
    'iron-ore',
    'iron-ore',
    'iron-ore',
    'iron-ore',
    'coal',
    'coal',
    'stone'
}

local function treasure(surface, room)
    local tiles = {}
    for _, tile in pairs(room.path_tiles) do
        table_insert(tiles, tile)
    end
    for _, tile in pairs(room.room_border_tiles) do
        table_insert(tiles, tile)
    end
    for _, tile in pairs(room.room_tiles) do
        table_insert(tiles, tile)
    end

    local scale_factor = 5

    if room.room_tiles[1] then
	-- room.room_tiles[1] is set only if this is a real room not a walkway
	-- Small rooms are 9x9, big ones are 29x29, so 100-1000 tiles
	-- middle size about 400 tiles, but test at that showed treasure rooms over-buffed.
	-- test#2 at 200.
	scale_factor = 10 * 10000 / #tiles  --珍宝室的矿物含量  基础系数
    end
    for _, tile in pairs(tiles) do
        surface.set_tiles({{name = rainbow_tiles[math_random(1, 2)], position = tile.position}}, true)

        if math_random(1, 3) == 1 then
            surface.create_entity({name = ores[math_random(1, #ores)], position = tile.position, amount = Functions.get_common_resource_amount(surface.index) * scale_factor})
        end
    end

    if not room.room_border_tiles[1] then
        return
    end

    table_shuffle_table(room.room_tiles)
    for key, tile in pairs(room.room_tiles) do
        if math_random(1, 256) == 1 or key == 1 then
            Functions.epic_loot_crate(surface, tile.position, true)
        else
            if math_random(1, 128) == 1 then
                Functions.rare_loot_crate(surface, tile.position, true)
            end
        end
    end

    table_shuffle_table(room.room_border_tiles)
    for key, tile in pairs(room.room_border_tiles) do
        if key % 8 == 1 then
            Functions.place_border_rock(surface, tile.position)
        end
    end
end

return treasure
