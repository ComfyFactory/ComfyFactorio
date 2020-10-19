local Public = {}

local GetNoise = require "utils.get_noise"
local Functions = require 'maps.cave_miner_v2.functions'

local math_abs = math.abs
local math_random = math.random

local rock_raffle = {"sand-rock-big","sand-rock-big", "rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local size_of_rock_raffle = #rock_raffle

local loot_blacklist = {
	["landfill"] = true,	
}

function Public.roll_source_surface()
	local map_gen_settings = {
		["water"] = 0,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["default_enable_all_autoplace_controls"] = false,
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = false},
			["decorative"] = {treat_missing_as_default = false},
		},
		autoplace_controls = {
			["coal"] = {frequency = 0, size = 0, richness = 0},
			["stone"] = {frequency = 0, size = 0, richness = 0},
			["copper-ore"] = {frequency = 0, size = 0, richness = 0},
			["iron-ore"] = {frequency = 0, size = 0, richness = 0},
			["uranium-ore"] = {frequency = 0, size = 0, richness = 0},
			["crude-oil"] = {frequency = 0, size = 0, richness = 0},
			["trees"] = {frequency = 0, size = 0, richness = 0},
			["enemy-base"] = {frequency = 0, size = 0, richness = 0}
		},
	}
	local surface = game.create_surface("cave_miner_source", map_gen_settings)
	surface.request_to_generate_chunks({x = 0, y = 0}, 1)
	surface.force_generate_chunk_requests()
end

function Public.out_of_map(event)
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	local tiles = {}
	local i = 0
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			i = i + 1
			tiles[i] = {name = "out-of-map", position = {left_top_x + x, left_top_y + y}}
		end
	end
	event.surface.set_tiles(tiles, false)
end

--lab-dark-1 > position has been copied
--lab-dark-2 > position has been visited

function Public.reveal(cave_miner, surface, source_surface, position, brushsize)
	local tile = source_surface.get_tile(position)
	if tile.name == "lab-dark-2" then return end
	local tiles = {}
	local copied_tiles = {}
	local i = 0
	local brushsize_square = brushsize ^ 2
	for _, tile in pairs(source_surface.find_tiles_filtered({area = {{position.x - brushsize, position.y - brushsize}, {position.x + brushsize, position.y + brushsize}}})) do
		local tile_position = tile.position
		if tile.name ~= "lab-dark-2" and tile.name ~= "lab-dark-1" and (position.x - tile_position.x) ^ 2 + (position.y - tile_position.y) ^ 2 < brushsize_square then
			i = i + 1
			copied_tiles[i] = {name = "lab-dark-1", position = tile.position}
			tiles[i] = {name = tile.name, position = tile.position}
		end
	end
	surface.set_tiles(tiles, true, false, false, false)
	source_surface.set_tiles(copied_tiles, false, false, false, false)
	
	for _, entity in pairs(source_surface.find_entities_filtered({area = {{position.x - brushsize, position.y - brushsize}, {position.x + brushsize, position.y + brushsize}}})) do
		local entity_position = entity.position
		if (position.x - entity_position.x) ^ 2 + (position.y - entity_position.y) ^ 2 < brushsize_square then
			entity.clone({position = entity_position, surface = surface})
			if entity.force.index == 2 then
				table.insert(cave_miner.reveal_queue, {entity.type, entity.position.x, entity.position.y})
			end
			entity.destroy()
		end
	end
	
	source_surface.set_tiles({{name = "lab-dark-2", position = position}}, false)
	source_surface.request_to_generate_chunks(position, 3)
end

local biomes = {}

function biomes.oasis(surface, seed, position, square_distance, noise)
	if noise < 0.79 then
		surface.set_tiles({{name = "deepwater", position = position}}, true) 
		if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = position}) end
		return
	end
	local noise_decoratives = GetNoise("decoratives", position, seed + 50000)
	surface.set_tiles({{name = "grass-1", position = position}}, true)
	if math_random(1, 48) == 1 and math_abs(noise_decoratives) > 0.07 then surface.create_entity({name = "tree-04", position = position}) end
	if math_random(1, 48) == 1 then Functions.place_crude_oil(surface, position, 1) end
	return
end

function biomes.void(surface, seed, position)
	surface.set_tiles({{name = "out-of-map", position = position}}, false, false, false, false)
end

function biomes.spawn(surface, seed, position, square_distance)
	if square_distance < 32 then return end
	local noise = GetNoise("decoratives", position, seed)
	
	if math_abs(noise) > 0.5 then
		surface.set_tiles({{name = "water", position = position}}, true, false, false, false)
		if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = position}) end
		return
	end
	
	if math_abs(noise) > 0.15 and math_random(1, 2) > 1 then
		local a = (-49 + math_random(0, 98)) * 0.01
		local b = (-49 + math_random(0, 98)) * 0.01
		surface.create_entity({name = rock_raffle[math_random(1, size_of_rock_raffle)], position = {position.x + a, position.y + b}})
	end
end

function biomes.cave(surface, seed, position, square_distance, noise)
	local noise_cave_rivers1 = GetNoise("cave_rivers_2", position, seed + 100000)
	local noise_cave_rivers2 = GetNoise("cave_rivers_3", position, seed + 200000)

	if math_abs(noise_cave_rivers1) < 0.025 and noise_cave_rivers2 > -0.35 then
		surface.set_tiles({{name = "water", position = position}}, true) 
		if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = position}) end
		return 
	end
	
	local noise_rock = GetNoise("small_caves", position, seed)	

	if noise_rock < 0.4 then
		if math_random(1, 3) > 1 then 
			local a = (-49 + math_random(0, 98)) * 0.01
			local b = (-49 + math_random(0, 98)) * 0.01
			surface.create_entity({name = rock_raffle[math_random(1, size_of_rock_raffle)], position = {position.x + a, position.y + b}})
		end
		if math_random(1, 512) == 1 then Functions.loot_crate(surface, position, 1, 8, "wooden-chest") return end
		if math_random(1, 2048) == 2 then Functions.loot_crate(surface, position, 2, 8, "iron-chest") return end
		if math_random(1, 4096) == 4 then Functions.loot_crate(surface, position, 3, 8, "steel-chest") return end
	else
		if square_distance < 4096 then return end
		if math_random(1, 48) == 1 then surface.create_entity({name = "biter-spawner", position = position, force = "enemy"}) end
		if math_random(1, 48) == 1 then Functions.place_worm(surface, position, 1) end
	end
end

local function get_biome(surface, seed, position)
	local d = position.x ^ 2 + position.y ^ 2
	if d < 1024 then return "spawn", d end
	
	local noise = GetNoise("cave_rivers", position, seed)
	if noise > 0.72 then return "oasis", d, noise end
	
	local noise = GetNoise("big_cave", position, seed)
	if math_abs(noise) < 0.125 then return "cave", d, noise end
	
	local noise = GetNoise("small_caves", position, seed)
	if math_abs(noise) < 0.1 then return "cave", d, noise end
	
	local noise = GetNoise("small_caves_2", position, seed)
	if math_abs(noise) < 0.1 then return "cave", d, noise end

	return "void"
end

function Public.generate_cave(event)
	local surface = event.surface
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	local seed = surface.map_gen_settings.seed
	
	local tiles = {}
	local i = 0
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			i = i + 1
			tiles[i] = {name = "dirt-7", position = {left_top_x + x, left_top_y + y}}
		end
	end
	surface.set_tiles(tiles, true)	
	
	for x = 0.5, 31.5, 1 do
		for y = 0.5, 31.5, 1 do
			local position = {x = left_top_x + x, y = left_top_y + y}
			local biome, square_distance, noise = get_biome(surface, seed, position)
			biomes[biome](surface, seed, position, square_distance, noise)
		end
	end
end

return Public