-- spooky forest -- by mewmew --

local shapes = require "maps.tools.shapes"
local event = require 'utils.event'
local map_functions = require "maps.tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2

local math_random = math.random
local insert = table.insert
local uncover_radius = 8

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

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

local biters_in_the_trees = {
		[1] = {"small-biter","small-biter","small-biter","small-biter","small-spitter","small-spitter"},
		[2] = {"small-biter","small-biter","small-biter","small-spitter","small-spitter","medium-biter"},
		[3] = {"small-biter","small-biter","small-biter","small-biter","medium-biter","medium-spitter"},
		[4] = {"small-biter","small-biter","small-biter","medium-biter","medium-biter","medium-spitter"},
		[5] = {"small-biter","small-biter","medium-biter","medium-biter","medium-biter","medium-spitter"},
		[6] = {"small-biter","medium-biter","medium-biter","medium-biter","medium-biter","medium-spitter"},
		[7] = {"medium-biter","medium-biter","medium-biter","medium-biter","big-biter","medium-spitter"},
		[8] = {"medium-biter","medium-biter","medium-biter","medium-biter","big-biter","big-spitter"},
		[9] = {"medium-biter","medium-biter","medium-biter","big-biter","big-biter","big-spitter"},
		[10] = {"medium-biter","medium-biter","medium-biter","big-biter","big-biter","big-spitter"},
		[11] = {"medium-biter","medium-biter","big-biter","big-biter","big-biter","big-spitter"},
		[12] = {"medium-biter","big-biter","big-biter","big-biter","big-biter","big-spitter"},
		[13] = {"big-biter","big-biter","big-biter","big-biter","big-biter","big-spitter"},
		[14] = {"big-biter","big-biter","big-biter","big-biter","behemoth-biter","big-spitter"},
		[15] = {"big-biter","big-biter","big-biter","behemoth-biter","behemoth-biter","big-spitter"},
		[16] = {"big-biter","big-biter","big-biter","behemoth-biter","behemoth-biter","behemoth-spitter"},
		[17] = {"big-biter","big-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"},
		[18] = {"big-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"},
		[19] = {"behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"},
		[20] = {"behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter","behemoth-spitter"}
	}	

local rock_raffle = {"sand-rock-big","sand-rock-big", "rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
	
local function spawn_biter(surface, position)
	local e = math.ceil(game.forces.enemy.evolution_factor*20)
	if e < 1 then e = 1 end
	if e > 20 then e = 20 end		
	local biter = biters_in_the_trees[e][math_random(1, #biters_in_the_trees[e])]
	local p = surface.find_non_colliding_position(biter , position, 16, 0.5)
	if not p then return end
	surface.create_entity{name = biter, position = p}
end	
	
local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise = {}
	local noise_seed_add = 25000
	if name == "water" then		
		noise[1] = simplex_noise(pos.x * 0.02, pos.y * 0.02, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		seed = seed + noise_seed_add
		local noise = noise[1] + noise[2] * 0.2
		return noise
	end
	seed = seed + noise_seed_add
	if name == "grass" then		
		noise[1] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		seed = seed + noise_seed_add
		local noise = noise[1]
		return noise
	end
	seed = seed + noise_seed_add
	if name == "trees" then		
		noise[1] = simplex_noise(pos.x * 0.045, pos.y * 0.045, seed)
		seed = seed + noise_seed_add
		local noise = noise[1]
		return noise
	end
end

local function get_entity(position)
	local noise = get_noise("trees", position)
	local entity_name = false
	if noise > 0 then
		if math_random(1, 3) ~= 1 then
			entity_name = "tree-04"
			if math_random(1,7) == 1 then
				entity_name = "dead-tree-desert"
			end
			if noise > 0.6 then
				entity_name = rock_raffle[math_random(1, #rock_raffle)]
				if math_random(1, 20) == 1 then
					if position.x > 32 or position.x < -32 or position.y > 32 or position.y < -32 then
						local e = math.ceil(game.forces.enemy.evolution_factor*10)
						if e < 1 then e = 1 end								
						entity_name = worm_raffle_table[e][math_random(1, #worm_raffle_table[e])]
					end
				end 
			end
		end	
	else	
		if math_random(1, 96) == 1 then
			entity_name = "biter-spawner"
			if math_random(1,5) == 1 then
				entity_name = "spitter-spawner"
			end			
		end
	end
	return entity_name
end

local function get_noise_tile(position)
	local noise = get_noise("grass", position)
	local tile_name
	--local decorative = false
	if noise > 0 then
		tile_name = "grass-1"
		--decorative = "green-pita"
	else
		tile_name = "grass-2"
		--decorative = "green-hairy-grass"
		--	table.insert(decoratives, {name = "green-croton", position = pos, amount = 3})
		--table.insert(decoratives, {name = "green-asterisk", position = pos, amount = 2})		
	end
	
	local noise = get_noise("water", position)
	if noise > 0.75 then
		tile_name = "water"
		--decorative = false
		if noise > 0.85 then
			tile_name = "deepwater"			
		end			
	end
	
	if noise < -0.85 then
		tile_name = "water-green"
		--decorative = false
	end
	
	return tile_name
end

local function create_decoratives_around_position(surface, position)
	local decoratives = {}
		
	for _, position_modifier in pairs(shapes.circles[uncover_radius - 2]) do
		local pos = {x = position.x + position_modifier.x, y = position.y + position_modifier.y}
		local area = {{pos.x - 0.01, pos.y - 0.01},{pos.x + 0.01, pos.y + 0.01}}
		surface.destroy_decoratives(area)		
		insert(decoratives, {name = "green-pita", position = pos, amount = 1})	
	end
		
	if #decoratives > 0 then
		surface.create_decoratives{check_collision=true, decoratives=decoratives}
	end
end

local function uncover_map(surface, position, radius_min, radius_max)
	local circles = shapes.circles			
	local tiles = {}
	local fishes = {}
	for r = radius_min, radius_max, 1 do
		for _, position_modifier in pairs(circles[r]) do			
			local pos = {x = position.x + position_modifier.x, y = position.y + position_modifier.y} 
			if surface.get_tile(pos).name == "out-of-map" then
				local tile_name = get_noise_tile(pos)
				insert(tiles, {name = tile_name, position = pos})
				if tile_name == "water" or tile_name == "deepwater" or tile_name == "water-green" then
					if math_random(1, 9) == 1 then insert(fishes, pos) end
				else
					local entity = get_entity(pos)
					if entity then
						surface.create_entity({name = entity, position = pos})						
					end
				end								
			end				
		end
	end
	if #tiles > 0 then
		surface.set_tiles(tiles, true)
	end
	for _, fish in pairs(fishes) do
		surface.create_entity({name = "fish", position = fish}) 
	end
end

local function uncover_map_for_player(player)
	local position = player.position
	local surface = player.surface
	local circles = shapes.circles			
	local tiles = {}
	local fishes = {}
	local uncover_map_schedule = {}
	
	for r = uncover_radius - 1, uncover_radius, 1 do
		for _, position_modifier in pairs(circles[r]) do
			local pos = {x = position.x + position_modifier.x, y = position.y + position_modifier.y} 
			if surface.get_tile(pos).name == "out-of-map" then
				local tile_name = get_noise_tile(pos)
				insert(tiles, {name = tile_name, position = pos})				
				if tile_name == "water" or tile_name == "deepwater" or tile_name == "water-green" then
					if math_random(1, 9) == 1 then insert(fishes, pos) end
				else
					local entity = get_entity(pos)
					if entity then
						surface.create_entity({name = entity, position = pos})
						if entity == "biter-spawner" or entity == "spitter-spawner" then
							insert(uncover_map_schedule, {x = pos.x, y = pos.y})
						end
					end
				end								
			end				
		end
	end
	
	if #tiles > 0 then
		surface.set_tiles(tiles, true)
	end		
	
	--create_decoratives_around_position(surface, position)
	
	for _, pos in pairs(uncover_map_schedule) do
		uncover_map(surface, pos, 1, 14)	
	end	
	for _, fish in pairs(fishes) do
		surface.create_entity({name = "fish", position = fish}) 
	end
end

local biter_building_inhabitants = {}
biter_building_inhabitants[1] = {{"small-biter",8,16}}
biter_building_inhabitants[2] = {{"small-biter",12,24}}
biter_building_inhabitants[3] = {{"small-biter",8,16},{"medium-biter",1,2}}
biter_building_inhabitants[4] = {{"small-biter",4,8},{"medium-biter",4,8}}
biter_building_inhabitants[5] = {{"small-biter",3,5},{"medium-biter",8,12}}
biter_building_inhabitants[6] = {{"small-biter",3,5},{"medium-biter",5,7},{"big-biter",1,2}}
biter_building_inhabitants[7] = {{"medium-biter",6,8},{"big-biter",3,5}}
biter_building_inhabitants[8] = {{"medium-biter",2,4},{"big-biter",6,8}}
biter_building_inhabitants[9] = {{"medium-biter",2,3},{"big-biter",7,9}}
biter_building_inhabitants[10] = {{"big-biter",4,8},{"behemoth-biter",3,4}}

local entity_drop_amount = {
    ['small-biter'] = {low = 16, high = 24},
    ['small-spitter'] = {low = 16, high = 24},
	['medium-biter'] = {low = 24, high = 32},
    ['medium-spitter'] = {low = 24, high = 32},
	['big-biter'] = {low = 32, high = 40},
    ['big-spitter'] = {low = 32, high = 40},
    ['behemoth-biter'] = {low = 40, high = 48},
	['behemoth-spitter'] = {low = 40, high = 48},
	['biter-spawner'] = {low = 64, high = 128},
	['spitter-spawner'] = {low = 64, high = 128},
	['small-worm-turret'] = {low = 64, high = 128},
	['medium-worm-turret'] = {low = 128, high = 196},
	['big-worm-turret'] = {low = 196, high = 254}
}
local ore_spill_raffle = {"iron-ore","iron-ore","iron-ore","iron-ore","copper-ore","copper-ore","copper-ore","coal","coal"}
local ore_spawn_raffle = {"iron-ore","iron-ore","iron-ore","iron-ore","copper-ore","copper-ore","copper-ore","coal","coal","stone","iron-ore","iron-ore","iron-ore","iron-ore","copper-ore","copper-ore","copper-ore","coal","coal","stone","uranium-ore","crude-oil"}

local function on_entity_died(event)
	local surface = event.entity.surface
	
	if event.entity.name == "biter-spawner" or event.entity.name == "spitter-spawner" then
		local e = math.ceil(game.forces.enemy.evolution_factor*10)
		if e < 1 then e = 1 end
		for _, t in pairs (biter_building_inhabitants[e]) do		
			for x = 1, math.random(t[2],t[3]), 1 do
				local p = surface.find_non_colliding_position(t[1] , event.entity.position, 6, 1)			
				if p then surface.create_entity {name=t[1], position=p} end
			end
		end
		if math_random(1, 4) == 1 then
			local name = ore_spawn_raffle[math.random(1,#ore_spawn_raffle)]
			local pos = {x = event.entity.position.x, y = event.entity.position.y}						
			local amount_modifier = 1 + game.forces.enemy.evolution_factor * 10
			if name == "crude-oil" then				
				map_functions.draw_oil_circle(pos, name, surface, 5, math.ceil(100000 * amount_modifier))
			else				
				map_functions.draw_smoothed_out_ore_circle(pos, name, surface, 7, math.ceil(600 * amount_modifier))
			end
		end
	end
	
	if entity_drop_amount[event.entity.name] then
		if game.forces.enemy.evolution_factor < 0.5 then
			local amount = math.ceil(math.random(entity_drop_amount[event.entity.name].low, entity_drop_amount[event.entity.name].high))
			surface.spill_item_stack(event.entity.position,{name = ore_spill_raffle[math.random(1,#ore_spill_raffle)], count = amount},true)
		end
		return
	end	
	
	if event.entity.type == "tree" then
		--if math_random(1, 2) == 1 then return end
		spawn_biter(event.entity.surface, event.entity.position)			
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	
	if not global.spooky_forest_init_done then
		local map_gen_settings = {}
		map_gen_settings.water = "small"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 22, cliff_elevation_0 = 22}		
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
		game.create_surface("spooky_forest", map_gen_settings)							
		local surface = game.surfaces["spooky_forest"]
		surface.daytime = 0.5
		surface.freeze_daytime = 1
		game.forces["player"].set_spawn_position({0, 0}, surface)
		
		game.map_settings.enemy_expansion.enabled = true
		game.map_settings.enemy_evolution.destroy_factor = 0.0012
		game.map_settings.enemy_evolution.time_factor = 0
		game.map_settings.enemy_evolution.pollution_factor = 0
							
		global.spooky_forest_init_done = true
	end
			
	if player.online_time < 1 then
		player.insert({name = "submachine-gun", count = 1})
		player.insert({name = "iron-axe", count = 1})
		player.insert({name = "grenade", count = 1})
		player.insert({name = "raw-fish", count = 5})
		player.insert({name = "land-mine", count = 5})
		player.insert({name = "light-armor", count = 1})
		player.insert({name = "firearm-magazine", count = 96})
		if global.show_floating_killscore then global.show_floating_killscore[player.name] = false end
	end
	
	local surface = game.surfaces["spooky_forest"]
	if player.online_time < 2 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("player", {0, 0}, 50, 1), "spooky_forest")
	else
		if player.online_time < 2 then
			player.teleport({0, 0}, "spooky_forest")
		end
	end
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	uncover_map_for_player(player)
end

local function on_chunk_generated(event)
	if not game.surfaces["spooky_forest"] then return end
	local surface = game.surfaces["spooky_forest"]
	if surface.name ~= event.surface.name then return end
	
	local position_left_top = event.area.left_top
	
	local tiles = {}
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local tile_to_insert = "out-of-map"
			local pos = {x = position_left_top.x + x, y = position_left_top.y + y}
			if pos.x > uncover_radius * -1 and pos.x < uncover_radius and pos.y > uncover_radius * -1 and pos.y < uncover_radius then
				tile_to_insert = get_noise_tile(pos)
			end
			insert(tiles, {name = tile_to_insert, position = pos})			
		end
	end 
	surface.set_tiles(tiles, true)
end

local function on_player_mined_entity(event)
	local player = game.players[event.player_index]
	if event.entity.type == "tree" then
		if math_random(1, 96) == 1 then
			player.print("You anger the tree, it hits you with a low branch uppercut.", {r = 0.77, g = 0, b = 0})
			player.character.damage(25, "enemy")
		end
		if math_random(1, 3) ~= 1 then return end
		spawn_biter(event.entity.surface, event.entity.position)				
	end
end

local disabled_for_deconstruction = {
		["fish"] = true,
		["rock-huge"] = true,
		["rock-big"] = true,
		["sand-rock-big"] = true,
		["tree-02"] = true,
		["tree-04"] = true
	}
	
local function on_marked_for_deconstruction(event)	
	if disabled_for_deconstruction[event.entity.name] then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

local function on_research_finished(event)	
	game.forces.player.recipes["flamethrower-turret"].enabled = false
end

event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)	
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)	
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_player_joined_game, on_player_joined_game)