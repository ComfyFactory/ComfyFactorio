--spiral troopers-- mewmew wrote this -- inspired from kyte

local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local event = require 'utils.event'
require "maps.tools.map_pregen"
require "maps.tools.map_functions"

local function on_player_joined_game(event)
	local player = game.players[event.player_index]	
	if not global.map_init_done then			
		local map_gen_settings = {}
		map_gen_settings.water = "none"	
		game.create_surface("spiral_troopers", map_gen_settings)		
		game.forces["player"].set_spawn_position({0,0},game.surfaces["spiral_troopers"])
		game.forces["player"].technologies["artillery-shell-range-1"].enabled = false			
		game.forces["player"].technologies["artillery-shell-speed-1"].enabled = false
		game.forces["player"].technologies["artillery"].enabled = false
		global.map_init_done = true						
	end	
	local surface = game.surfaces["spiral_troopers"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("player", {0,0}, 2, 1), "spiral_troopers")
	else
		if player.online_time < 5 then
			player.teleport({0,0}, "spiral_troopers")
		end
	end	
	if player.online_time < 10 then				
		player.insert {name = 'iron-axe', count = 1}
	end
end

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise = {}
	local noise_seed_add = 25000
	if name == "water" then		
		noise[1] = simplex_noise(pos.x * 0.002, pos.y * 0.002, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		local noise = noise[1] + noise[2] * 0.2
		return noise
	end
	seed = seed + noise_seed_add
	if name == "assembly" then		
		noise[1] = simplex_noise(pos.x * 0.004, pos.y * 0.004, seed)
		seed = seed + noise_seed_add
		local noise = noise[1]
		return noise
	end
end

local spiral_cords = {
	{x = 0, y = -1},
	{x = -1, y = 0},
	{x = 0, y = 1},
	{x = 1, y = 0}
	}

function level_finished()
	local surface = game.surfaces["spiral_troopers"]
	if not global.spiral_troopers_beaten_level then global.spiral_troopers_beaten_level = 1 end
	if not global.current_beaten_chunk then global.current_beaten_chunk = {x = 0, y = -1} end
	local current_growth_direction = global.spiral_troopers_beaten_level % 4
	if current_growth_direction == 0 then current_growth_direction = 4 end	
	for levelsize = 1, global.spiral_troopers_beaten_level, 1 do
		global.current_beaten_chunk = {
			x = global.current_beaten_chunk.x + spiral_cords[current_growth_direction].x,
			y = global.current_beaten_chunk.y + spiral_cords[current_growth_direction].y
			}
		local tiles = {}
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				local pos = {x = global.current_beaten_chunk.x * 32 + x, y = global.current_beaten_chunk.y * 32 + y}
				table.insert(tiles,{name = "water", position = pos})
				--- ADD FISSH
			end
		end
		surface.set_tiles(tiles, true)		
	end	
	for _, player in pairs(game.connected_players) do
		player.play_sound{path="utility/new_objective", volume_modifier=0.6}
	end
	game.print("Level " .. global.spiral_troopers_beaten_level .. " finished. Area Unlocked!")
	global.spiral_troopers_beaten_level = global.spiral_troopers_beaten_level + 1
end
	
function grow_level()
	local surface = game.surfaces["spiral_troopers"]
	if not global.spiral_troopers_level then global.spiral_troopers_level = 1 end
	if not global.current_chunk then global.current_chunk = {x = 0, y = -1} end
	local current_growth_direction = global.spiral_troopers_level % 4
	if current_growth_direction == 0 then current_growth_direction = 4 end
		
	for levelsize = 1, global.spiral_troopers_level, 1 do
		global.current_chunk = {
			x = global.current_chunk.x + spiral_cords[current_growth_direction].x,
			y = global.current_chunk.y + spiral_cords[current_growth_direction].y
			}
		
		if levelsize == global.spiral_troopers_level then
			local tiles = {}
			local checkpoint_chunk = {
			x = global.current_chunk.x + spiral_cords[current_growth_direction].x,
			y = global.current_chunk.y + spiral_cords[current_growth_direction].y
			}
			for x = 0, 31, 1 do
				for y = 0, 31, 1 do
					local pos = {x = checkpoint_chunk.x * 32 + x, y = checkpoint_chunk.y * 32 + y}
					table.insert(tiles,{name = "water-green", position = pos})
				end
			end
			
			local reward_chunk_offset = (global.spiral_troopers_level - 1) % 4
			if reward_chunk_offset == 0 then reward_chunk_offset = 4 end
			local reward_chunk = {
			x = checkpoint_chunk.x + spiral_cords[reward_chunk_offset].x,
			y = checkpoint_chunk.y + spiral_cords[reward_chunk_offset].y
			}
			for x = 0, 31, 1 do
				for y = 0, 31, 1 do
					local pos = {x = reward_chunk.x * 32 + x, y = reward_chunk.y * 32 + y}
					table.insert(tiles,{name = "water", position = pos})
				end
			end
			surface.set_tiles(tiles, true)			
		end
		
		local tiles = {}
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				local pos = {x = global.current_chunk.x * 32 + x, y = global.current_chunk.y * 32 + y}
				table.insert(tiles,{name = "out-of-map", position = pos})
			end
		end
		surface.set_tiles(tiles, true)		
	end
	global.spiral_troopers_level = global.spiral_troopers_level + 1
end

local function on_chunk_generated(event)
	local surface = game.surfaces["spiral_troopers"]
	if event.surface.name ~= surface.name then return end	
	local entities = {}
	local tiles = {}
	local math_random = math.random
	local chunk_position_x = event.area.left_top.x / 32
	local chunk_position_y = event.area.left_top.y / 32
	local tile_to_insert
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = event.area.left_top.x + x, y = event.area.left_top.y + y}	
			
		end
	end	
end

local function on_player_rotated_entity(event)
	local area = {
			left_top = {x = global.current_chunk.x * 32, y = global.current_chunk.y * 32},
			right_bottom = {x = global.current_chunk.x * 32 + 31, y = global.current_chunk.y * 32 + 31}
			}
end

local disabled_entities = {"gun-turret", "laser-turret", "flamethrower-turret"}
local function on_built_entity(event)
	for _, e in pairs(disabled_entities) do
		if e == event.created_entity.name then
			event.created_entity.die("enemy")
			if event.player_index then
				--local player = game.players[event.player_index]
				--player.print("Turrets outside of conquered zones are disabled.", { r=0.75, g=0.0, b=0.0})
			end
		end
	end
end

local function on_robot_built_entity(event)
	on_built_entity(event)
end

event.add(defines.events.on_player_rotated_entity, on_player_rotated_entity)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)