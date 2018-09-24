--lost desert-- mewmew made this --
local chunk_loader = require "maps.tools.lazy_chunk_loader"
local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local event = require 'utils.event' 

local function shipwreck(position, surface)
	local wrecks = {"big-ship-wreck-1", "big-ship-wreck-2", "big-ship-wreck-3"}
	local wreck = wrecks[math.random(1,#wrecks)]
	local p = game.surfaces[1].find_non_colliding_position(wreck,position, 2,0.5)
	if not p then return end
	
	local wreck_raffle_table = {}
	local wreck_loot_weights = {}
	table.insert(wreck_loot_weights, {{name = 'iron-gear-wheel', count = math.random(16,48)},5})		
	table.insert(wreck_loot_weights, {{name = 'burner-inserter', count = math.random(16,32)},2})
	table.insert(wreck_loot_weights, {{name = 'engine-unit', count = math.random(1,16)},3})		
	table.insert(wreck_loot_weights, {{name = 'rocket-fuel', count = math.random(1,5)},3})
	table.insert(wreck_loot_weights, {{name = 'lubricant-barrel', count = math.random(1,10)},3})
	table.insert(wreck_loot_weights, {{name = 'crude-oil-barrel', count = math.random(1,10)},3})
	table.insert(wreck_loot_weights, {{name = "firearm-magazine", count = math.random(64,128)},8})
	table.insert(wreck_loot_weights, {{name = 'grenade', count = math.random(16,32)},5})
	table.insert(wreck_loot_weights, {{name = 'land-mine', count = math.random(16,32)},5})
	table.insert(wreck_loot_weights, {{name = 'light-armor', count = 1},1})
	table.insert(wreck_loot_weights, {{name = 'heavy-armor', count = 1},2})		
	table.insert(wreck_loot_weights, {{name = 'pipe', count = math.random(10,100)},3})		
	table.insert(wreck_loot_weights, {{name = 'rail', count = math.random(32,100)},4})	
	table.insert(wreck_loot_weights, {{name = 'assembling-machine-1', count = math.random(1,4)},2})
	table.insert(wreck_loot_weights, {{name = 'assembling-machine-2', count = math.random(1,3)},2})
	table.insert(wreck_loot_weights, {{name = 'assembling-machine-3', count = math.random(1,2)},1})
	table.insert(wreck_loot_weights, {{name = 'combat-shotgun', count = 1},4})
	table.insert(wreck_loot_weights, {{name = 'piercing-shotgun-shell', count = math.random(16,48)},5})
	table.insert(wreck_loot_weights, {{name = 'flamethrower', count = 1},4})
	table.insert(wreck_loot_weights, {{name = 'rocket-launcher', count = 1},4})
	table.insert(wreck_loot_weights, {{name = 'flamethrower-ammo', count = math.random(16,48)},5})		
	table.insert(wreck_loot_weights, {{name = 'rocket', count = math.random(16,48)},5})
	table.insert(wreck_loot_weights, {{name = 'explosive-rocket', count = math.random(16,48)},5})
	table.insert(wreck_loot_weights, {{name = 'modular-armor', count = 1},3})
	table.insert(wreck_loot_weights, {{name = 'power-armor', count = 1},1})
	table.insert(wreck_loot_weights, {{name = 'uranium-rounds-magazine', count = math.random(16,32)},3})	
	table.insert(wreck_loot_weights, {{name = 'piercing-rounds-magazine', count = math.random(64,128)},5})	
	table.insert(wreck_loot_weights, {{name = 'railgun', count = 1},3})
	table.insert(wreck_loot_weights, {{name = 'railgun-dart', count = math.random(16,48)},4})
	table.insert(wreck_loot_weights, {{name = 'exoskeleton-equipment', count = 1},1})
	table.insert(wreck_loot_weights, {{name = 'defender-capsule', count = math.random(8,16)},5})
	table.insert(wreck_loot_weights, {{name = 'distractor-capsule', count = math.random(4,8)},4})
	table.insert(wreck_loot_weights, {{name = 'destroyer-capsule', count = math.random(4,8)},3})
	table.insert(wreck_loot_weights, {{name = 'atomic-bomb', count = 1},1})		
	for _, t in pairs (wreck_loot_weights) do
		for x = 1, t[2], 1 do
			table.insert(wreck_raffle_table, t[1])
		end			
	end	
	local e = surface.create_entity {name=wreck, position=p, force="player"}
	e.minable = false
	local i = e.get_inventory(defines.inventory.chest)
	for x = 1, math.random(2,3), 1 do
		local loot = wreck_raffle_table[math.random(1,#wreck_raffle_table)]
		i.insert(loot)
	end		
end

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function create_cluster(name, pos, size, surface, spread, resource_amount)		
	local p = {x = pos.x, y = pos.y}
	local math_random = math.random
	for z = 1, size, 1 do											
		for x = 1, 8, 1 do
			local y = 1
			if spread then y = math_random(1, spread) end
			local modifier_raffle = {{0,y*-1},{y*-1,0},{y,0},{0,y},{y*-1,y*-1},{y,y},{y,y*-1},{y*-1,y}}
			modifier_raffle = shuffle(modifier_raffle)
			local m = modifier_raffle[x]
			local pos = {x = p.x + m[1], y = p.y + m[2]}
			if resource_amount then				
				surface.create_entity {name=name, position=pos, amount=resource_amount}				
				p = {x = pos.x, y = pos.y}
				break
			else
				if surface.can_place_entity({name=name, position=pos}) then
					surface.create_entity {name=name, position=pos}
					p = {x = pos.x, y = pos.y}	
					break
				end
			end
		end		
	end
end

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise = {}
	local noise_seed_add = 25000
	seed = seed + noise_seed_add
	if name == 1 then		
		noise[1] = simplex_noise(pos.x * 0.001, pos.y * 0.001, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		noise[3] = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)
		seed = seed + noise_seed_add
		noise[4] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.15 + noise[3] * 0.02 + noise[4] * 0.001
		return noise
	end
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	if name == "rocks_1" then
		noise[1] = simplex_noise(pos.x * 0.005, pos.y * 0.005, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		noise[3] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.005 + noise[3] * 0.0002
		return noise
	end
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	if name == "deco_1" then
		noise[1] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)				
		local noise = noise[1]
		return noise
	end
	seed = seed + noise_seed_add
	if name == "deco_2" then
		noise[1] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)				
		local noise = noise[1]
		return noise
	end
	seed = seed + noise_seed_add
	if name == "dead_trees" then
		noise[1] = simplex_noise(pos.x * 0.005, pos.y * 0.005, seed)				
		local noise = noise[1]
		return noise
	end
	seed = seed + noise_seed_add
end

local worm_raffle = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"}
local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local ore_spawn_raffle = {"iron-ore","iron-ore","iron-ore","copper-ore","copper-ore","copper-ore","coal","coal","stone","stone","uranium-ore","crude-oil"}

chunk_loader.add(function(chunk_piece)
	local surface = game.surfaces["lost_desert"] 
	if chunk_piece[2] ~= surface.index then return end
	local chunk_piece_position = chunk_piece[1]
	local chunk_pos_x = chunk_piece_position.x
	local chunk_pos_y = chunk_piece_position.y
	local area = {
			left_top = {x = chunk_piece_position.x, y = chunk_piece_position.y},
			right_bottom = {x = chunk_piece_position.x + 8, y = chunk_piece_position.y + 8}
			}							
	local tiles = {}
	local entities_to_place = {
		rocks = {},
		worms = {},
		enemy_buildings = {},
		trees = {},
		fish = {},		
		shipwrecks = {}		
	}	
	local decoratives = {}
	local math_random = math.random
	local entities = surface.find_entities(area)
	for _, e in pairs(entities) do
		if e.type == "tree" or e.force.name == "enemy" then
			--e.destroy()				
		end
	end	
	local sands = {"sand-1", "sand-2", "sand-3"}
	local tile_to_insert = false	
	for x = 0, 7, 1 do
		for y = 0, 7, 1 do			
			local pos_x = chunk_pos_x + x
			local pos_y = chunk_pos_y + y
			local pos = {x = pos_x, y = pos_y}
			local tile_distance_to_center = pos_x^2 + pos_y^2
			tile_to_insert = false							
			local noise_1 = get_noise(1, pos)									
			if tile_distance_to_center > 10000 then
				if noise_1 <= -0.9 then
					if math_random(1,250) == 1 then table.insert(entities_to_place.shipwrecks, pos) end
				end
				if noise_1 <= -0.85 then
					if math_random(1,16) == 1 then table.insert(entities_to_place.worms, pos) end
					if math_random(1,16) == 1 then table.insert(entities_to_place.enemy_buildings, pos) end
				end
			end
			if noise_1 <= -0.4 then tile_to_insert = "sand-2" end
			if noise_1 > -0.4 then tile_to_insert = "sand-1" end
			if noise_1 > 0.4 then tile_to_insert = "sand-3" end
			if noise_1 > 0.72 and noise_1 < 0.8 then if math_random(1,3) == 1 then table.insert(decoratives, {name = "garballo", position = pos, amount = math_random(1,3)}) end end
			if noise_1 > 0.75 then if math_random(1,5) == 1 then table.insert(entities_to_place.trees, {"tree-05", pos}) end end			
			if noise_1 > 0.8 then
				tile_to_insert = "water"
				if math_random(1,32) == 1 then table.insert(entities_to_place.fish, pos) end
			end			
			if noise_1 > 0.9 then tile_to_insert = "deepwater" end

			if tile_to_insert ~= "deepwater" and tile_to_insert ~= "water" and noise_1 < 0.7 then	
				if math_random(1,20000) == 1 and noise_1 < 0.65 then
					local spread = 1
					local amount = math_random(400,600)
					local size = math.ceil(math.sqrt(tile_distance_to_center),0)
					local ore = ore_spawn_raffle[math_random(1,#ore_spawn_raffle)]
					if ore == "crude-oil" then
						spread = 10
						amount = 100000 + math_random(tile_distance_to_center,tile_distance_to_center*2)
						size = math_random(4,16)
					end					
					create_cluster(ore, pos, size, surface, spread, amount)
				end
				local noise_dead_trees = get_noise("dead_trees", pos)			
				local noise_rocks_1 = get_noise("rocks_1", pos)
				local noise_deco_1 = get_noise("deco_1", pos)
				local noise_deco_2 = get_noise("deco_2", pos)				
				while true do
					if noise_dead_trees > 0.5 then
						if math_random(1,55) == 1 then table.insert(entities_to_place.trees, {"tree-06", pos}) end
						break
					end
					if noise_rocks_1 > 0.5 and noise_dead_trees < -0.4 then
						if noise_rocks_1 > 0.55 then
							if math_random(1,6) == 1 then table.insert(entities_to_place.rocks, pos) end					
						end
						tile_to_insert = "dirt-1"
					end
					if noise_deco_1 > 0.75 then
						if math_random(1,7) == 1 then table.insert(decoratives, {name = "brown-fluff-dry", position = pos, amount = math_random(1,3)}) end
						break
					end
					if noise_deco_1 < -0.75 then
						if math_random(1,7) == 1 then table.insert(decoratives, {name = "red-desert-bush", position = pos, amount = math_random(1,3)}) end
						break
					end
					if noise_deco_2 > 0.75 then
						if math_random(1,7) == 1 then table.insert(decoratives, {name = "white-desert-bush", position = pos, amount = math_random(1,3)}) end
						break
					end
					if noise_deco_2 < -0.75 then 
						if math_random(1,7) == 1 then table.insert(decoratives, {name = "brown-asterisk", position = pos, amount = math_random(1,3)}) end
						break
					end
					if tile_to_insert == "sand-1" then
						if math_random(1,50) == 1 then table.insert(decoratives, {name = "sand-dune-decal", position = pos, amount = 1}) end						
					end					
					break
				end
			end
			if tile_to_insert == false then
				--table.insert(tiles, {name = "sand-4", position = {pos_x,pos_y}})   tree-06
			else
				table.insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}}) 
			end					
		end							
	end		
	surface.set_tiles(tiles,true)
	surface.create_decoratives{check_collision=false, decoratives=decoratives}	
	
	for _, p in pairs(entities_to_place.shipwrecks) do			 
		shipwreck(p, surface)		
	end
	for _, p in pairs(entities_to_place.enemy_buildings) do						
		if math_random(1,3) == 1 then
			if surface.can_place_entity({name="spitter-spawner", position=p}) then surface.create_entity {name="spitter-spawner", position=p} end	
		else
			if surface.can_place_entity({name="biter-spawner", position=p}) then surface.create_entity {name="biter-spawner", position=p} end	
		end							
	end
	for _, p in pairs(entities_to_place.worms) do				
		local e = worm_raffle[math.random(1,#worm_raffle)]
		if surface.can_place_entity({name=e, position=p}) then surface.create_entity {name=e, position=p} end					
	end	
	for _, p in pairs(entities_to_place.rocks) do			
		local e = rock_raffle[math.random(1,#rock_raffle)]
		surface.create_entity {name=e, position=p} 				
	end
	for _, p in pairs(entities_to_place.trees) do			 
		if surface.can_place_entity({name=p[1], position=p[2]}) then surface.create_entity {name=p[1], position=p[2]} end				
	end									
	for _, p in pairs(entities_to_place.fish) do					
		surface.create_entity {name="fish",position=p}				
	end
	return true
end
)

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.map_init_done then			
		local map_gen_settings = {}
		map_gen_settings.water = "none"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 20, cliff_elevation_0 = 20}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "very-low", size = "normal", richness = "normal"},
			["stone"] = {frequency = "very-low", size = "normal", richness = "normal"},
			["copper-ore"] = {frequency = "very-low", size = "normal", richness = "normal"},
			["iron-ore"] = {frequency = "very-low", size = "normal", richness = "normal"},
			["crude-oil"] = {frequency = "very-low", size = "normal", richness = "normal"},
			["trees"] = {frequency = "none", size = "none", richness = "none"},
			["enemy-base"] = {frequency = "very-low", size = "small", richness = "none"},
			["grass"] = {frequency = "none", size = "none", richness = "none"},
			["sand"] = {frequency = "none", size = "none", richness = "none"},
			["desert"] = {frequency = "none", size = "none", richness = "none"},
			["dirt"] = {frequency = "none", size = "none", richness = "none"}
		}
		game.map_settings.pollution.pollution_restored_per_tree_damage = 0
		game.create_surface("lost_desert", map_gen_settings)		
		game.forces["player"].set_spawn_position({0,0},game.surfaces["lost_desert"])
		local surface = game.surfaces["lost_desert"]
		create_cluster("stone", {x=-30,y=30}, 1500, surface, 1, math.random(400,600))
		create_cluster("copper-ore", {x=30,y=30}, 1500, surface, 1, math.random(400,600))		
		create_cluster("coal", {x=30,y=-30}, 1500, surface, 1, math.random(400,600))
		create_cluster("iron-ore", {x=-30,y=-30}, 1500, surface, 1, math.random(400,600))
		create_cluster("crude-oil", {x=0,y=0}, 5, surface, 10, math.random(300000,400000))
		global.map_init_done = true						
	end	
	local surface = game.surfaces["lost_desert"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("player", {0,0}, 2, 1), "lost_desert")
	else
		if player.online_time < 5 then
			player.teleport({0,0}, "lost_desert")
		end
	end	
	if player.online_time < 10 then				
		player.insert {name = 'raw-fish', count = 3}
		player.insert {name = 'iron-axe', count = 1}
		player.insert {name = 'light-armor', count = 1}
	end	
end
	
function cheat_mode()
	local cheat_mode_enabed = false
	if cheat_mode_enabed == true then
		local surface = game.surfaces["lost_desert"]
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
		local chart = 300
		local surface = game.surfaces["lost_desert"]	
		game.forces["player"].chart(surface, {lefttop = {x = chart*-1, y = chart*-1}, rightbottom = {x = chart, y = chart}})		
	end
end

event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_joined_game, on_player_joined_game)