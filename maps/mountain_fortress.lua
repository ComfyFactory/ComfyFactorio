-- mountain digger fortress -- by mewmew --

require "maps.modules.satellite_score"
require "maps.modules.dynamic_landfill"
require "maps.modules.dynamic_player_spawn"
require "maps.modules.rocks_yield_ore"
require "maps.modules.fluids_are_explosive"
require "maps.modules.explosives_are_explosive"
require "maps.modules.explosive_biters"
require "maps.modules.spawners_contain_biters"
require "maps.modules.splice"
global.splice_modifier = 2

local event = require 'utils.event'
local math_random = math.random
local insert = table.insert
local map_functions = require "maps.tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'
local simplex_noise = simplex_noise.d2

local worm_raffle_table = {
		[1] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret"},
		[2] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret"},
		[3] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret"},
		[4] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret"},
		[5] = {"small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"},
		[6] = {"small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"},
		[7] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"},
		[8] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"},
		[9] = {"medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"},
		[10] = {"medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"}
	}
local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local nest_raffle = {"biter-spawner", "biter-spawner", "biter-spawner", "spitter-spawner"}

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]

	if not global.surface_init_done then	
		local map_gen_settings = {}
		map_gen_settings.water = "small"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 22, cliff_elevation_0 = 22}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "none", size = "none", richness = "none"},
			["stone"] = {frequency = "none", size = "none", richness = "none"},
			["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
			["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
			["uranium-ore"] = {frequency = "none", size = "none", richness = "none"},
			["crude-oil"] = {frequency = "none", size = "none", richness = "none"},
			["trees"] = {frequency = "normal", size = "normal", richness = "normal"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"},
			["grass"] = {frequency = "none", size = "none", richness = "none"},
			["sand"] = {frequency = "none", size = "none", richness = "none"},
			["desert"] = {frequency = "none", size = "none", richness = "none"},
			["dirt"] = {frequency = "normal", size = "normal", richness = "normal"}
		}		
		game.create_surface("mountain_fortress", map_gen_settings)							
		local surface = game.surfaces["mountain_fortress"]
		
		local radius = 256
		game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})
		
		--game.map_settings.enemy_expansion.enabled = true
		--game.map_settings.enemy_evolution.destroy_factor = 0
		--game.map_settings.enemy_evolution.time_factor = 0
		--game.map_settings.enemy_evolution.pollution_factor = 0					
		--game.map_settings.pollution.enabled = true			
		
		surface.ticks_per_day = surface.ticks_per_day * 2
		game.forces.player.manual_mining_speed_modifier = 2
		
		global.surface_init_done = true
	end
	
	if player.online_time < 1 then
		player.insert({name = "pistol", count = 1})
		player.insert({name = "iron-axe", count = 1})
		player.insert({name = "raw-fish", count = 3})
		player.insert({name = "firearm-magazine", count = 16})
		player.insert({name = "iron-plate", count = 32})
		if global.show_floating_killscore then global.show_floating_killscore[player.name] = false end
	end
	
	local surface = game.surfaces["mountain_fortress"]
	if player.online_time < 2 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("player", {-75, 4}, 50, 1), "mountain_fortress")
	else
		if player.online_time < 2 then
			player.teleport({-50, 0}, "mountain_fortress")
		end
	end		
end

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise = {}
	local noise_seed_add = 25000
	if name == "rocks" then		
		noise[1] = simplex_noise(pos.x * 0.002, pos.y * 0.002, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		local noise = noise[1] + noise[2] * 0.2
		return noise
	end	
end

local function generate_north_chunk(event, surface)
	local left_top = event.area.left_top
	local tile_positions = {}
	
	for _, e in pairs(surface.find_entities_filtered({area = event.area, type = "tree"})) do
		e.destroy()
	end
	
	if left_top.y < -512 then
		local tiles_to_set = {}
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do	
				insert(tiles_to_set, {name = "out-of-map", position = {x = left_top.x + x, y = left_top.y + y}})
			end
		end
		surface.set_tiles(tiles_to_set, true)
		return
	end
	
	local tiles_to_set = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}			
			tile_positions[#tile_positions + 1] = pos			
			insert(tiles_to_set, {name = "dirt-7", position = pos})
		end
	end
	surface.set_tiles(tiles_to_set, true)
	if #tile_positions == 0 then return end
	
	local rock_amount = math.ceil(#tile_positions * 0.75)
	tile_positions = shuffle(tile_positions)
	for _, pos in pairs(tile_positions) do					
		surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = pos})	
		rock_amount = rock_amount - 1
		if rock_amount < 1 then break end
	end	
	
	if math_random(1,7) == 1 then
		map_functions.draw_noise_tile_circle(tile_positions[math_random(1, #tile_positions)], "deepwater-green", surface, math_random(2, 6))
	end
	
	if math_random(1,20) == 1 then
		map_functions.draw_oil_circle(tile_positions[math_random(1, #tile_positions)], "crude-oil", surface, math_random(1, 3), math_random(100000, 500000))
	end
	
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
		  decorative_names[#decorative_names+1] = k
		end
	 end
	surface.regenerate_decorative(decorative_names, {{x=math.floor(left_top.x/32),y=math.floor(left_top.y/32)}})	
end

local function generate_south_chunk(event, surface)	
	for _, e in pairs(surface.find_entities_filtered({area = event.area})) do
		e.destroy()
	end

	local left_top = event.area.left_top
	local current_depth = math.abs(left_top.y) - 32
	
	local i = math.ceil(current_depth / 32)
	if i > 10 then i = 10 end
	if i < 1 then i = 1 end
	local worm_raffle = worm_raffle_table[i]
	
	local worm_amount = math.ceil(current_depth / 32)		
	local nests_amount = math.ceil(current_depth / 8)		
	
	local tile_positions = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if not surface.get_tile(pos).collides_with("player-layer") then
				tile_positions[#tile_positions + 1] = pos
			end
		end
	end			
	if #tile_positions == 0 then return end
	
	tile_positions = shuffle(tile_positions)
	for _, pos in pairs(tile_positions) do
		if surface.can_place_entity({name = "biter-spawner", position = pos, force = "enemy"}) then
			surface.create_entity({name = nest_raffle[math_random(1, #nest_raffle)], position = pos, force = "enemy"})
			nests_amount = nests_amount - 1
			if nests_amount < 1 then break end
		end
	end	
	
	tile_positions = shuffle(tile_positions)			
	for _, pos in pairs(tile_positions) do		
		if surface.can_place_entity({name = "big-worm-turret", position = pos, force = "enemy"}) then
			surface.create_entity({name = worm_raffle[math_random(1, #worm_raffle)], position = pos, force = "enemy"})
			worm_amount = worm_amount - 1
			if worm_amount < 1 then break end
		end
	end
end

local function replace_spawn_water(surface)
	if global.spawn_water_replaced then return end
	if not surface.is_chunk_generated({5,5}) then return end
	local tilename = "grass-1"
	for x = -160, 160, 1 do
		for y = -96, 90, 1 do
			local tile = surface.get_tile(x, y)
			if tile.name ~= "water" and tile.name ~= "deepwater" then
				tilename = tile.name
			end
		end
	end
	local tiles = {}
	for x = -128, 128, 1 do
		for y = -128, 128, 1 do
			local tile = surface.get_tile(x, y)
			if tile.name == "water" or tile.name == "deepwater" then
				insert(tiles, {name = tilename, position = {x = tile.position.x, y = tile.position.y}})
			end
		end
	end
	surface.set_tiles(tiles, true)
	global.spawn_water_replaced = true
end

local function on_chunk_generated(event)
	local surface = game.surfaces["mountain_fortress"]
	if event.surface.name ~= surface.name then return end
	local left_top = event.area.left_top					
	
	replace_spawn_water(surface)		
	
	if left_top.y < -32 then
		generate_north_chunk(event, surface)
	end
	if left_top.y > 0 then
		generate_south_chunk(event, surface)
	end
end

local disabled_for_deconstruction = {
		["fish"] = true,
		["rock-huge"] = true,
		["rock-big"] = true,
		["sand-rock-big"] = true,		
	}
	
local function on_marked_for_deconstruction(event)	
	if disabled_for_deconstruction[event.entity.name] then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)