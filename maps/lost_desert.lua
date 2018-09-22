--endless desert-- mewmew made this --

local simplex_noise = require 'utils.simplex_noise'
local event = require 'utils.event' 
require "maps.tools.lazy_chunk_loader"

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	seed = seed + noise_seed_add
	if name == 1 then
		local noise = {}
		noise[1] = simplex_noise.d2(pos.x * 0.001, pos.y * 0.001, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise.d2(pos.x * 0.01, pos.y * 0.01, seed)
		local noise = noise[1] + noise[2] * 0.1
		return noise
	end
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	if name == 2 then
		local noise = {}
		noise[1] = simplex_noise.d2(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise.d2(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.1
		return noise
	end
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	if name == 3 then
		local noise = {}
		noise[1] = simplex_noise.d2(pos.x * 0.001, pos.y * 0.001, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise.d2(pos.x * 0.01, pos.y * 0.01, seed)
		local noise = noise[1] + noise[2] * 0.1
		return noise
	end
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	if name == 4 then
		local noise = {}
		noise[1] = simplex_noise.d2(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise.d2(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.2
		return noise
	end
end

table.insert(global.generate_chunk_tiles_functions, function(chunk_piece) 
	local area = chunk_piece.area
	local surface = game.surfaces["endless_desert"] 
	if chunk_piece.surface ~= surface then return end
	local tiles = {}		
	local entities = surface.find_entities(area)
	for _, e in pairs(entities) do
		if e.type == "tree" or e.force.name == "enemy" then
			e.destroy()				
		end
	end			
	local tile_to_insert = false	
	for y = 0, 7, 1 do
		for x = 0, 7, 1 do			
			local pos_x = area.left_top.x + x
			local pos_y = area.left_top.y + y
			local pos = {x = pos_x, y = pos_y}
			tile_distance_to_center = pos_x^2 + pos_y^2
			tile_to_insert = false										
			--local noise_3 = get_noise(3, pos)						
			local noise_1 = get_noise(1, pos)
			if noise_1 > 0.3 then 
				tile_to_insert = "sand-1"
			end
			if noise_1 < -0.3 then 
				tile_to_insert = "sand-2"
			end
			
			if tile_to_insert == false then
				table.insert(tiles, {name = "sand-3", position = {pos_x,pos_y}}) 
			else
				table.insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}}) 
			end		
			
		end							
	end
	surface.set_tiles(tiles,true)		
end
)

table.insert(global.generate_chunk_entities_functions, function(chunk_piece)
	local area = chunk_piece.area
	local surface = game.surfaces["endless_desert"] 
	if chunk_piece.surface ~= surface then return end	
	local enemy_building_positions = {}
	local enemy_worm_positions = {}
	local worm_raffle = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"}
	local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
	local rock_positions = {}
	local fish_positions = {}
	local rare_treasure_chest_positions = {}
	local treasure_chest_positions = {}
	local secret_shop_locations = {}	
	local tree_positions = {}
	
	for y = 0, 7, 1 do
		for x = 0, 7, 1 do			
			local pos_x = area.left_top.x + x
			local pos_y = area.left_top.y + y
			local pos = {x = pos_x, y = pos_y}
			tile_distance_to_center = pos_x^2 + pos_y^2
			--if surface.can_place_entity({name="tree-03", position=pos}) then surface.create_entity {name="tree-03", position=pos} end							
			local noise_1 = get_noise(1, pos)			
		end							
	end
end
)

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	if not global.map_init_done then			
		local map_gen_settings = {}
		map_gen_settings.water = "none"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 20, cliff_elevation_0 = 5}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "very-low", size = "normal", richness = "normal"},
			["stone"] = {frequency = "very-low", size = "normal", richness = "normal"},
			["copper-ore"] = {frequency = "very-low", size = "normal", richness = "normal"},
			["iron-ore"] = {frequency = "very-low", size = "normal", richness = "normal"},
			["crude-oil"] = {frequency = "very-low", size = "normal", richness = "good"},
			["trees"] = {frequency = "normal", size = "normal", richness = "normal"},
			["enemy-base"] = {frequency = "normal", size = "normal", richness = "good"}			
		}		
		game.create_surface("endless_desert", map_gen_settings)		
		game.forces["player"].set_spawn_position({0,0},game.surfaces["endless_desert"])								
		global.map_init_done = true						
	end	
	local surface = game.surfaces["endless_desert"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("player", {0,0}, 2, 1), "endless_desert")
	else
		if player.online_time < 5 then
			player.teleport({0,0}, "endless_desert")
		end
	end
	
	if player.online_time < 10 then		
		player.insert {name = 'raw-fish', count = 1}		
		player.insert {name = 'iron-axe', count = 1}			
	end	
end

local function on_marked_for_deconstruction(event)
	if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" or event.entity.name == "fish" or event.entity.type == "tree" then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end
	
function cheat_mode()
	local cheat_mode_enabed = true
	if cheat_mode_enabed == true then
		local surface = game.surfaces["endless_desert"]
		game.player.cheat_mode=true
		game.players[1].insert({name="power-armor-mk2"})
		game.players[1].insert({name="fusion-reactor-equipment", count=4})
		game.players[1].insert({name="personal-laser-defense-equipment", count=8})
		game.players[1].insert({name="rocket-launcher"})		
		game.players[1].insert({name="explosive-rocket", count=200})		
		game.speed = 2
		surface.daytime = 1
		game.player.force.research_all_technologies()
		game.forces["enemy"].evolution_factor = 0.2
		local chart = 400
		local surface = game.surfaces["endless_desert"]	
		game.forces["player"].chart(surface, {lefttop = {x = chart*-1, y = chart*-1}, rightbottom = {x = chart, y = chart}})		
	end
end

event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)	
event.add(defines.events.on_player_joined_game, on_player_joined_game)