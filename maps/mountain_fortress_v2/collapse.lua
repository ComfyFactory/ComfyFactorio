local Public = {}
local simplex_noise = require "utils.simplex_noise".d2
local math_random = math.random
local math_abs = math.abs
local math_sqrt = math.sqrt
local math_floor = math.floor
local table_remove = table.remove
local table_insert = table.insert

local function get_collapse_vectors(radius)
	local vectors = {}
	local i = 1
	local m = 1 / (radius * 2)
	local seed = math_random(1, 9999999)
	for x = radius * -1, radius, 1 do
		for y = radius * -1, radius, 1 do
			local noise = math_abs(simplex_noise(x * m, y * m, seed) * radius * 1.5)
			local d = math_sqrt(x ^ 2 + y ^ 2)
			if d + noise < radius then
				vectors[i] = {x, y}
				i = i + 1
			end
		end
	end
	return vectors
end

local function get_position()
	local position = {x = 0, y = 64}
	return position
end

local function sort_list_by_distance(center_position, list)
	local sorted_list = {}
	for _, item in pairs(list) do
		local d = math_floor(math_sqrt((item.position.x - center_position.x)^2 + (item.position.y - center_position.y)^2)) + 1	
		if not sorted_list[d] then sorted_list[d] = {} end
		sorted_list[d][#sorted_list[d] + 1] = item		
	end
	local final_list = {}
	for _, row in pairs(sorted_list) do
		table.shuffle_table(row)
		for _, tile in pairs(row) do
			table_insert(final_list, tile)
		end
	end
	return final_list
end

local function set_collapse_tiles(surface, position, vectors)
	local tiles = {}
	local i = 1
	for _, vector in pairs(vectors) do
		local position = {x = position.x + vector[1], y = position.y + vector[2]}
		local tile = surface.get_tile(position)
		if tile then
			tiles[i] = tile
			i = i + 1
		end
	end
	local sorted_tiles = sort_list_by_distance(position, tiles)
	table_insert(global.map_collapse.processing, sorted_tiles)
end

function Public.process()
	if not global.map_collapse then return end
	local processing = global.map_collapse.processing
	if #processing == 0 then return end
	local surface = game.surfaces[global.active_surface_index]
	for k1, tile_set in pairs(processing) do	
		for k2, tile in pairs(tile_set) do
			surface.set_tiles({{name = "out-of-map", position = tile.position}}, true)
			table_remove(tile_set, k2)
			break
		end
		if #tile_set == 0 then table_remove(processing, k1) end
		break
	end
end

function collapse_map()
	local surface = game.surfaces[global.active_surface_index]
	local vectors = get_collapse_vectors(20)
	set_collapse_tiles(surface, get_position(), vectors)	
end

function Public.init()
	global.map_collapse = {}
	global.map_collapse.last_position = "mew"
	global.map_collapse.processing = {}
end

local event = require 'utils.event'
event.on_init(Public.init())

return Public