--deep jungle-- mewmew made this --

local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random
local map_functions = require "maps.tools.map_functions"

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	seed = seed + noise_seed_add
	if name == "islands_1" then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.1
		return noise
	end	
end

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	if not global.map_init_done then			
		local map_gen_settings = {}
		map_gen_settings.water = "none"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 4, cliff_elevation_0 = 0.1}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "none", size = "none", richness = "none"},
			["stone"] = {frequency = "none", size = "none", richness = "none"},
			["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
			["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
			["crude-oil"] = {frequency = "none", size = "none", richness = "none"},
			["trees"] = {frequency = "none", size = "none", richness = "none"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"},
			["grass"] = {frequency = "none", size = "none", richness = "none"},
			["sand"] = {frequency = "none", size = "none", richness = "none"},
			["desert"] = {frequency = "none", size = "none", richness = "none"},
			["dirt"] = {frequency = "none", size = "none", richness = "none"}
		}
		game.map_settings.pollution.pollution_restored_per_tree_damage = 0
		game.create_surface("atoll", map_gen_settings)		
		game.forces["player"].set_spawn_position({0,0},game.surfaces["atoll"])								
		global.map_init_done = true						
	end	
	local surface = game.surfaces["atoll"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("player", {0,0}, 2, 1), "atoll")
	else
		if player.online_time < 5 then
			player.teleport({0,0}, "atoll")
		end
	end
	
	if player.online_time < 4 then		
		player.insert {name = 'iron-axe', count = 1}
	end	
end

local function on_marked_for_deconstruction(event)
	if event.entity.name == "fish" then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

local function on_chunk_generated(event)
	if event.surface.name ~= "atoll" then return end
	local surface = event.surface
	local left_top = event.area.left_top
	local tiles = {}
	local valid_resource_spots = {}
	local entities = {}
	
	if not global.spawn_generated and left_top.x <= -160 then
		map_functions.draw_noise_tile_circle({x = 0, y = 0}, "grass-1", surface, 20)
		map_functions.draw_smoothed_out_ore_circle({x = -32, y = -32}, "copper-ore", surface, 15, 2500)
		map_functions.draw_smoothed_out_ore_circle({x = -32, y = 32}, "iron-ore", surface, 15, 2500)
		map_functions.draw_smoothed_out_ore_circle({x = 32, y = 32}, "coal", surface, 15, 2500)
		map_functions.draw_smoothed_out_ore_circle({x = 32, y = -32}, "stone", surface, 15, 2500)							
		map_functions.draw_oil_circle({x = 0, y = 0}, "crude-oil", surface, 5, 200000)
		global.spawn_generated = true
	end
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			local islands_1_noise = get_noise("islands_1", pos)
			if islands_1_noise > 0.5 then
				table_insert(tiles, {name = "grass-2", position = pos})
			end
		end
	end
	surface.set_tiles(tiles, true)
	
end

event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_chunk_generated, on_chunk_generated)