local Public = {}

local GetNoise = require "utils.get_noise"
local math_abs = math.abs
local math_random = math.random

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
	surface.request_to_generate_chunks({x = 0, y = 0}, 2)
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

function Public.reveal(surface, source_surface, position, brushsize)
	local tile = source_surface.get_tile(position)
	if tile.name == "lab-dark-1" then return end
	local tiles = {}
	local i = 0
	local brushsize_square = brushsize ^ 2
	for _, tile in pairs(source_surface.find_tiles_filtered({area = {{position.x - brushsize, position.y - brushsize}, {position.x + brushsize, position.y + brushsize}}})) do
		local tile_position = tile.position
		if tile.name ~= "lab-dark-1" and surface.get_tile(tile_position).name ~= tile.name and (position.x - tile_position.x) ^ 2 + (position.y - tile_position.y) ^ 2 < brushsize_square then
			i = i + 1
			tiles[i] = {name = tile.name, position = tile.position}
		end
	end
	surface.set_tiles(tiles, true)
	
	for _, entity in pairs(source_surface.find_entities_filtered({area = {{position.x - brushsize, position.y - brushsize}, {position.x + brushsize, position.y + brushsize}}})) do
		local entity_position = entity.position
		if (position.x - entity_position.x) ^ 2 + (position.y - entity_position.y) ^ 2 < brushsize_square then
			entity.clone({position = entity_position, surface = surface})
			entity.destroy()
		end
	end
	
	source_surface.set_tiles({{name = "lab-dark-1", position = position}}, true)
	source_surface.request_to_generate_chunks(position, 2)
end

local function get_biome(surface, seed, position)
	local d = position.x ^ 2 + position.y ^ 2	
	if d < 128 then return "spawn" end
	if d < 1024 then return "cave" end

	local noise = GetNoise("smol_areas", position, seed)
	if noise > 0.75 then return "worms" end
	if noise < -0.75 then return "nests" end
	
	local noise = GetNoise("cave_rivers", position, seed)
	if noise > 0.72 then return "green", noise end
	if noise < -0.5 then return "void", noise end
	
	return "cave"
end

local biomes = {}
function biomes.worms(surface, seed, position)	
	if math_random(1, 16) == 1 then surface.create_entity({name = "small-worm-turret", position = position, force = "enemy"}) end	
end

function biomes.nests(surface, seed, position)	
	if math_random(1, 32) == 1 then surface.create_entity({name = "biter-spawner", position = position, force = "enemy"}) end	
end

function biomes.green(surface, seed, position, noise)		
	local noise_decoratives = GetNoise("decoratives", position, seed + 50000)
	surface.set_tiles({{name = "grass-1", position = position}}, true)
	if math_random(1, 32) == 1 and math_abs(noise_decoratives) > 0.07 then surface.create_entity({name = "tree-04", position = position}) end
	return
end

function biomes.void(surface, seed, position, noise)
	surface.set_tiles({{name = "out-of-map", position = position}}, true)
end

function biomes.spawn(surface, seed, position)

end

function biomes.cave(surface, seed, position)
	local noise_cave_rivers1 = GetNoise("cave_rivers_2", position, seed)
	local noise_cave_rivers2 = GetNoise("cave_rivers_3", position, seed + 100000)
	
	if math_abs(noise_cave_rivers2) < 0.05 then surface.set_tiles({{name = "out-of-map", position = position}}, true) return end
	if math_abs(noise_cave_rivers1) < 0.035 then
		surface.set_tiles({{name = "water", position = position}}, true) 
		if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = position}) end
		return 
	end
	
	local noise_rock = GetNoise("decoratives", position, seed)	
	if noise_rock > 0 then	
		if math_random(1, 3) > 1 then surface.create_entity({name = "rock-big", position = position}) end
	else
		local noise_rock_2 = GetNoise("decoratives", position, seed + 50000)
		if math_random(1, 3) > 1 and math_abs(noise_rock_2) > 0.15 then surface.create_entity({name = "rock-big", position = position}) end
	end
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
			tiles[i] = {name = "nuclear-ground", position = {left_top_x + x, left_top_y + y}}
		end
	end
	surface.set_tiles(tiles, true)	
	
	for x = 0.5, 31.5, 1 do
		for y = 0.5, 31.5, 1 do
			local position = {x = left_top_x + x, y = left_top_y + y}
			local biome, noise = get_biome(surface, seed, position)
			biomes[biome](surface, seed, position, noise)
		end
	end
end

return Public