local Functions = require "maps.dungeons.functions"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local math_random = math.random

local rainbow_tiles = {
	"orange-refined-concrete", "purple-refined-concrete",
}

local function laboratory(surface, room)
	local tiles = {}
	for _, tile in pairs(room.path_tiles) do table_insert(tiles, tile) end
	for _, tile in pairs(room.room_border_tiles) do table_insert(tiles, tile) end
	for _, tile in pairs(room.room_tiles) do table_insert(tiles, tile) end

	local seed = game.surfaces[surface.index].map_gen_settings.seed + math_random(1, 1000000)
	for _, tile in pairs(tiles) do
		surface.set_tiles({{name = rainbow_tiles[math_random(1, 2)], position = tile.position}}, true)
	end

	if not room.room_border_tiles[1] then return end

	table_shuffle_table(room.room_tiles)
	for key, tile in pairs(room.room_tiles) do
		if key == 1 then
			Functions.laboratory(surface, tile.position)
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

return laboratory
