local Public = {}
local simplex_noise = require "utils.simplex_noise".d2
local math_random = math.random
local math_abs = math.abs
local math_sqrt = math.sqrt
local level_depth = require "maps.mountain_fortress_v2.terrain"
local math_floor = math.floor
local table_remove = table.remove
local table_insert = table.insert
local chart_radius = 30
local tile_conversion = {
	["concrete"] = "stone-path",
	["hazard-concrete-left"] = "stone-path",
	["hazard-concrete-right"] = "stone-path",
	["refined-concrete"] = "concrete",
	["refined-hazard-concrete-left"] = "hazard-concrete-left",
	["refined-hazard-concrete-right"] = "hazard-concrete-right",
	["stone-path"] = "landfill",
}

local function get_collapse_vectors(radius)
	local vectors = {}
	local i = 1
	local m = 1 / (radius * 2)
	local seed = math_random(1, 9999999)
	for x = radius * -1, radius, 1 do
		for y = radius * -1, radius, 1 do
			local noise = math_abs(simplex_noise(x * m, y * m, seed) * radius * 1.3)
			local d = math_sqrt(x ^ 2 + y ^ 2)
			if d + noise < radius then
				vectors[i] = {x, y}
				i = i + 1
			end
		end
	end
	return vectors
end

local function set_x_positions()
	local x_positions = global.map_collapse.x_positions	
	for x = level_depth * -1, level_depth - 1, 1 do
		table_insert(x_positions, x)
	end
	table.shuffle_table(x_positions)
end

local function get_position(surface)
	local x_positions = global.map_collapse.x_positions
	if #x_positions == 0 then set_x_positions() end
	local x = x_positions[1]
	local position = false
	for y = 160, -100000, -1 do
		y = y + math_random(1, 16)
		local tile = surface.get_tile({x, y})
		if tile.valid then
			if tile.name ~= "out-of-map" then
				position = {x = x, y = y}
				break
			else
				y = y + math_random(8, 32)
			end
		else
			y = y + 96 
		end		
	end
	table_remove(x_positions, 1)
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
		if tile.valid then
			tiles[i] = tile
			i = i + 1
		end
	end
	local sorted_tiles = sort_list_by_distance(position, tiles)
	table_insert(global.map_collapse.processing, sorted_tiles)
end

local function collapse_map()
	local surface = game.surfaces[global.active_surface_index]
	local vectors = get_collapse_vectors(math_random(8, 24))
	local position = get_position(surface)
	if not position then return end	
	
	local last_position = global.map_collapse.last_position
	game.forces.player.chart(surface, {{last_position.x - chart_radius, last_position.y - chart_radius},{last_position.x + chart_radius, last_position.y + chart_radius}})
	global.map_collapse.last_position = {x = position.x, y = position.y}
	
	game.forces.player.chart(surface, {{position.x - chart_radius, position.y - chart_radius},{position.x + chart_radius, position.y + chart_radius}})
	
	set_collapse_tiles(surface, position, vectors)	
end

function Public.delete_out_of_map_chunks(surface)
	local count = 0
	for chunk in surface.get_chunks() do
		if surface.count_tiles_filtered({name = "out-of-map", area = chunk.area}) == 1024 then
			surface.delete_chunk({chunk.x, chunk.y})
			count = count + 1
		end
	end
end

function Public.process()
	local processing = global.map_collapse.processing
	if #processing == 0 then collapse_map() return end
	local surface = game.surfaces[global.active_surface_index]
	for k1, tile_set in pairs(processing) do	
		for k2, tile in pairs(tile_set) do
			local conversion_tile = tile_conversion[tile.name]
			if conversion_tile then
				surface.set_tiles({{name = conversion_tile, position = tile.position}}, true)
				surface.create_trivial_smoke({name="train-smoke", position = tile.position})	
			else
				surface.set_tiles({{name = "out-of-map", position = tile.position}}, true)
			end			
			table_remove(tile_set, k2)
			break
		end
		if #tile_set == 0 then table_remove(processing, k1) end
	end
end

function Public.init()
	global.map_collapse = {}
	global.map_collapse.x_positions = {}
	global.map_collapse.processing = {}
	global.map_collapse.last_position = {x = 0, y = 0}
end

local event = require 'utils.event'
event.on_init(Public.init())

return Public