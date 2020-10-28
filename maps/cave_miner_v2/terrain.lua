local Public = {}

local GetNoise = require "utils.get_noise"
local Functions = require 'maps.cave_miner_v2.functions'
local Market = require 'maps.cave_miner_v2.market'

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

local biomes = {}

function biomes.oasis(surface, seed, position, square_distance, noise)
	if noise > 0.83 then
		surface.set_tiles({{name = "deepwater", position = position}}, true) 
		if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = position}) end
		return
	end
	local noise_decoratives = GetNoise("decoratives", position, seed + 50000)
	surface.set_tiles({{name = "grass-1", position = position}}, true)
	if math_random(1, 16) == 1 and math_abs(noise_decoratives) > 0.17 then surface.create_entity({name = "tree-04", position = position}) end
	if math_random(1, 128) == 1 then Functions.place_crude_oil(surface, position, 1) end
	
	if noise < 0.73 then
		local a = (-49 + math_random(0, 98)) * 0.01
		local b = (-49 + math_random(0, 98)) * 0.01
		surface.create_entity({name = rock_raffle[math_random(1, size_of_rock_raffle)], position = {position.x + a, position.y + b}})
	end
end

function biomes.void(surface, seed, position)
	surface.set_tiles({{name = "out-of-map", position = position}}, false, false, false, false)
end

function biomes.pond_cave(surface, seed, position, square_distance, noise)
	local noise_2 = GetNoise("cm_ponds", position, seed)
	
	if math_abs(noise_2) > 0.60 then
		surface.set_tiles({{name = "water", position = position}}, true, false, false, false)
		if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = position}) end
		return
	end
	
	if math_abs(noise_2) > 0.25 and math_random(1, 2) > 1 then
		local a = (-49 + math_random(0, 98)) * 0.01
		local b = (-49 + math_random(0, 98)) * 0.01
		surface.create_entity({name = rock_raffle[math_random(1, size_of_rock_raffle)], position = {position.x + a, position.y + b}})
		return
	end
	
	if noise > -0.53 then
		local a = (-49 + math_random(0, 98)) * 0.01
		local b = (-49 + math_random(0, 98)) * 0.01
		surface.create_entity({name = rock_raffle[math_random(1, size_of_rock_raffle)], position = {position.x + a, position.y + b}})
	else
		if math_random(1, 128) == 1 then			
			Market.spawn_random_cave_market(surface, position)
		end
	end
end

function biomes.spawn(surface, seed, position, square_distance)
	if square_distance < 32 then return end
	local noise = GetNoise("decoratives", position, seed)
	
	if math_abs(noise) > 0.60 and square_distance < 1250 then
		surface.set_tiles({{name = "water", position = position}}, true, false, false, false)
		if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = position}) end
		return
	end
	
	if math_abs(noise) > 0.25 and math_random(1, 2) > 1 then
		local a = (-49 + math_random(0, 98)) * 0.01
		local b = (-49 + math_random(0, 98)) * 0.01
		surface.create_entity({name = rock_raffle[math_random(1, size_of_rock_raffle)], position = {position.x + a, position.y + b}})
		return
	end
	
	if square_distance > 1750 then
		local a = (-49 + math_random(0, 98)) * 0.01
		local b = (-49 + math_random(0, 98)) * 0.01
		surface.create_entity({name = rock_raffle[math_random(1, size_of_rock_raffle)], position = {position.x + a, position.y + b}})
	end
end

function biomes.ocean(surface, seed, position, square_distance, noise)
	if noise > 0.68 then
		surface.set_tiles({{name = "deepwater", position = position}}, true, false, false, false) 
		if math_random(1, 32) == 1 then surface.create_entity({name = "fish", position = position}) end
		return 
	end
	if noise > 0.63 then
		surface.set_tiles({{name = "water", position = position}}, true, false, false, false) 
		if math_random(1, 32) == 1 then surface.create_entity({name = "fish", position = position}) end
		return 
	end
	if math_random(1, 3) > 1 then 
		local a = (-49 + math_random(0, 98)) * 0.01
		local b = (-49 + math_random(0, 98)) * 0.01
		surface.create_entity({name = rock_raffle[math_random(1, size_of_rock_raffle)], position = {position.x + a, position.y + b}})
	end
end

function biomes.cave(surface, seed, position, square_distance, noise)
	local noise_cave_rivers1 = GetNoise("cave_rivers_2", position, seed + 100000)
	if math_abs(noise_cave_rivers1) < 0.025 then
		local noise_cave_rivers2 = GetNoise("cave_rivers_3", position, seed + 200000)
		if noise_cave_rivers2 > 0 then
			surface.set_tiles({{name = "water-shallow", position = position}}, true, false, false, false) 
			if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = position}) end
			return 
		end
	end

	if GetNoise("no_rocks_2", position, seed) > 0.7 then return end

	local noise_rock = GetNoise("small_caves", position, seed)	

	if noise_rock < 0.5 then
		if math_random(1, 3) > 1 then 
			local a = (-49 + math_random(0, 98)) * 0.01
			local b = (-49 + math_random(0, 98)) * 0.01
			surface.create_entity({name = rock_raffle[math_random(1, size_of_rock_raffle)], position = {position.x + a, position.y + b}})
		end
		if math_random(1, 2048) == 1 then Functions.loot_crate(surface, position, "wooden-chest") return end
		if math_random(1, 4096) == 1 then Functions.loot_crate(surface, position, "iron-chest") return end
		return
	end

	if square_distance < 4096 then return end
	if math_random(1, 4096) == 1 then Market.spawn_random_cave_market(surface, position) return end
	if math_random(1, 64) == 1 then surface.create_entity({name = "biter-spawner", position = position, force = "enemy"}) return end
	if math_random(1, 64) == 1 then Functions.place_worm(surface, position, 1) return end
end

local function get_biome(surface, seed, position)
	local d = position.x ^ 2 + position.y ^ 2
	if d < 2048 then return biomes.spawn, d end

	local noise = GetNoise("cave_miner_01", position, seed)
	local abs_noise = math_abs(noise)
	if abs_noise < 0.088 then return biomes.cave, d, noise end
	
	if abs_noise > 0.25 then	
		local noise = GetNoise("cave_rivers", position, seed)
		if noise > 0.72 then return biomes.oasis, d, noise end	
		if noise < -0.5 then return biomes.pond_cave, d, noise end	
	end
	
	local noise = GetNoise("cm_ocean", position, seed + 100000)
	if noise > 0.6 then return biomes.ocean, d, noise end
	
	local noise = GetNoise("cave_miner_02", position, seed)
	if math_abs(noise) < 0.1 then return biomes.cave, d, noise end
	
	return biomes.void
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
			biome(surface, seed, position, square_distance, noise)
		end
	end
end

return Public