-- forest maze from mewmew
local event = require 'utils.event'
local map_functions = require "tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'.d2
local math_random = math.random

local labyrinth_cell_size = 16 --valid values are 2, 4, 8, 16, 32

local modifiers = {
		{x = 0, y = -1},{x = -1, y = 0},{x = 1, y = 0},{x = 0, y = 1}
	}

local modifiers_diagonal = {
		{diagonal = {x = -1, y = 1}, connection_1 = {x = -1, y = 0}, connection_2 = {x = 0, y = 1}},
		{diagonal = {x = 1, y = -1}, connection_1 = {x = 1, y = 0}, connection_2 = {x = 0, y = -1}},
		{diagonal = {x = 1, y = 1}, connection_1 = {x = 1, y = 0}, connection_2 = {x = 0, y = 1}},
		{diagonal = {x = -1, y = -1}, connection_1 = {x = -1, y = 0}, connection_2 = {x = 0, y = -1}}
	}	

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function get_noise(name, pos)
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	seed = seed + noise_seed_add
	if name == 1 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.001, pos.y * 0.001, seed)
		local noise = noise[1]
		return noise
	end	
end
	
local function labyrinth_wall(surface, cell_pos)
	local noise = get_noise(1, cell_pos)
	local tree = "tree-04"
	if noise > 0 then tree = "tree-01" end
	if noise < -0.75 then tree = "tree-02" end
	if noise > 0.75 then tree = "tree-07" end
	
	for x = 0.5, labyrinth_cell_size, 1 do
		for y = 0.5, labyrinth_cell_size, 1 do
			local pos = {x = cell_pos.x + x, y = cell_pos.y + y}
			if math_random(1,2) == 1 then
				surface.create_entity({name = tree, position = pos})
			end
		end
	end
end
	
local function labyrinth_path(surface, pos)
end

local function get_path_connections_count(cell_pos)
	local connections = 0
	for _, m in pairs(modifiers) do
		if global.labyrinth_cells[tostring(cell_pos.x + m.x) .. "_" .. tostring(cell_pos.y + m.y)] then
			connections = connections + 1
		end
	end
	return connections
end

local function process_labyrinth_cell(pos)
	local cell_position = {x = pos.x / labyrinth_cell_size, y = pos.y / labyrinth_cell_size}
	
	global.labyrinth_cells[tostring(cell_position.x) .. "_" .. tostring(cell_position.y)] = false
	
	for _, modifier in pairs(modifiers_diagonal) do
		if global.labyrinth_cells[tostring(cell_position.x + modifier.diagonal.x) .. "_" .. tostring(cell_position.y + modifier.diagonal.y)] then			
			local connection_1 = global.labyrinth_cells[tostring(cell_position.x + modifier.connection_1.x) .. "_" .. tostring(cell_position.y + modifier.connection_1.y)]
			local connection_2 = global.labyrinth_cells[tostring(cell_position.x + modifier.connection_2.x) .. "_" .. tostring(cell_position.y + modifier.connection_2.y)]
			if not connection_1 and not connection_2 then
				return false
			end												
		end
	end
		
	for _, m in pairs(modifiers) do
		if get_path_connections_count({x = cell_position.x + m.x, y = cell_position.y + m.y}) >= math_random(2, 3) then return false end
	end
		
	if get_path_connections_count(cell_position) >= math_random(2, 3) then return false end
	
	global.labyrinth_cells[tostring(cell_position.x) .. "_" .. tostring(cell_position.y)] = true
	return true
end

local function labyrinth(event)
	local positions = {}
	for x = 0, 32 - labyrinth_cell_size, labyrinth_cell_size do
		for y = 0, 32 - labyrinth_cell_size, labyrinth_cell_size do
			positions[#positions + 1] = {x = event.area.left_top.x + x, y = event.area.left_top.y + y}					
		end
	end
	positions = shuffle(positions)
	
	for _, pos in pairs(positions) do				
		if process_labyrinth_cell(pos) then
			labyrinth_path(event.surface, pos)
		else
			labyrinth_wall(event.surface, pos)
		end
	end	
end

local function on_chunk_generated(event)
	local surface = game.surfaces["forest_maze"]
	if event.surface.name ~= surface.name then return end	 
	local left_top = event.area.left_top
	local area = {
			left_top = {x = left_top.x, y = left_top.y},
			right_bottom = {x = left_top.x + 31, y = left_top.y + 31}
			}							
	surface.destroy_decoratives({area = area})
	
	local entities = surface.find_entities(area)
	for _, e in pairs(entities) do
		if e.valid then
			if e.name ~= "player" then
				e.destroy()				
			end
		end
	end
		
	local tiles = {}
	for x = 0.5, 31.5, 1 do
		for y = 0.5, 31.5, 1 do			
			local pos = {x = left_top.x + x, y = left_top.y + y}				
			table.insert(tiles, {name = "grass-1", position = pos}) 
		end
	end
	surface.set_tiles(tiles,true)
	
	labyrinth(event)
	
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
			decorative_names[#decorative_names+1] = k
		end
	end										
	surface.regenerate_decorative(decorative_names, {{x = left_top.x / 32, y = left_top.y / 32}})
end

local ore_chance_weights = {
	{"iron-ore", 25},
	{"copper-ore",18},
	{"coal",14},
	{"stone",10},
	{"crude-oil",5},
	{"uranium-ore",3}
}
local ore_raffle = {}				
for _, t in pairs (ore_chance_weights) do
	for x = 1, t[2], 1 do
		table.insert(ore_raffle, t[1])
	end			
end

local function draw_ores(surface, position)
	local ore = ore_raffle[math_random(1, #ore_raffle)]
	for x = 0, labyrinth_cell_size - 1, 1 do
		for y = 0, labyrinth_cell_size - 1, 1 do
			local pos = {x = position.x + x, y = position.y + y}
			local amount = 500 + math.sqrt(pos.x^2 + pos.x^2) * 2
			if ore == "crude-oil" then
				if math_random(1, 32) == 1 and surface.can_place_entity({name = ore, position = pos, amount = amount * 100}) then surface.create_entity({name = ore, position = pos, amount = amount * 100}) end
			else
				surface.create_entity({name = ore, position = pos, amount = amount})
			end
		end
	end
end

local function draw_water(surface, position)
	map_functions.draw_noise_tile_circle({x = position.x + labyrinth_cell_size * 0.5, y = position.y + labyrinth_cell_size * 0.5}, "water", surface, math.floor(labyrinth_cell_size * 0.3))
end

local enemy_chances = {
	{"biter-spawner", 20},
	{"spitter-spawner",8},
	{"small-worm-turret",5},
	{"medium-worm-turret",4},
	{"big-worm-turret",3},
	{"behemoth-worm-turret",1},
}
local enemy_raffle = {}				
for _, t in pairs (enemy_chances) do
	for x = 1, t[2], 1 do
		table.insert(enemy_raffle, t[1])
	end			
end

local function draw_enemies(surface, position)
	local positions = {}
	for x = 0, labyrinth_cell_size - 1, 1 do
		for y = 0, labyrinth_cell_size - 1, 1 do
			positions[#positions + 1] = {x = position.x + x, y = position.y + y}					
		end
	end
	positions = shuffle(positions)
	
	for i = 1, labyrinth_cell_size, 1 do
		local enemy = enemy_raffle[math_random(1, #enemy_raffle)]
		if surface.can_place_entity({name = enemy, position = positions[i]}) then
			surface.create_entity({name = enemy, position = positions[i], force = "enemy"})
		end
	end
end

local function process_chunk_charted_cell(surface, pos)
	local cell_position = {x = pos.x / labyrinth_cell_size, y = pos.y / labyrinth_cell_size}
	if not global.labyrinth_cells[tostring(cell_position.x) .. "_" .. tostring(cell_position.y)] then return end
			
	local connection_count = get_path_connections_count(cell_position)
	if connection_count == 1 then
		if math_random(1, 2) == 1 then
			draw_ores(surface, pos)
		else
			local distance_to_center = math.sqrt(pos.x^2 + pos.x^2)
			if distance_to_center > 160 then
				if math_random(1, 4) == 1 then
					draw_water(surface, pos)
				else
					--draw_enemies(surface, pos)
				end
			else
				if math_random(1, 3) == 1 then draw_water(surface, pos) end
			end					
		end
	end
end

local function on_chunk_charted(event)
	local surface = game.surfaces[event.surface_index]
	
	if game.tick < 300 then return end
	
	if not global.chunks_charted then
		game.forces.player.clear_chart(surface)
		global.chunks_charted = {}
	end
	
	local left_top = {x = event.position.x * 32, y = event.position.y * 32}
	
	if global.chunks_charted[tostring(left_top.x) .. "_" .. tostring(left_top.y)] then return end
	global.chunks_charted[tostring(left_top.x) .. "_" .. tostring(left_top.y)] = true
	
	for x = 0, 32 - labyrinth_cell_size, labyrinth_cell_size do
		for y = 0, 32 - labyrinth_cell_size, labyrinth_cell_size do	
			local pos = {x = left_top.x + x, y = left_top.y + y}
			process_chunk_charted_cell(surface, pos)
		end
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.map_init_done then			
		local map_gen_settings = {}
		map_gen_settings.water = "none"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 20, cliff_elevation_0 = 20}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "none", size = "none", richness = "none"},
			["stone"] = {frequency = "none", size = "none", richness = "none"},
			["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
			["uranium-ore"] = {frequency = "none", size = "none", richness = "none"},
			["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
			["crude-oil"] = {frequency = "none", size = "none", richness = "none"},
			["trees"] = {frequency = "none", size = "none", richness = "none"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"}
		}
		game.map_settings.pollution.pollution_restored_per_tree_damage = 0
		game.create_surface("forest_maze", map_gen_settings)		
		game.forces["player"].set_spawn_position({0,0},game.surfaces["forest_maze"])
		local surface = game.surfaces["forest_maze"]
		
		surface.daytime = 1
		surface.freeze_daytime = 1
		--local radius = 512
		--game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})	
		global.map_init_done = true						
	end	
	local surface = game.surfaces["forest_maze"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("player", {0,0}, 2, 1), "forest_maze")
	else
		if player.online_time < 5 then
			player.teleport({0,0}, "forest_maze")
		end
	end	
	if player.online_time < 10 then				
		player.insert {name = 'raw-fish', count = 3}
		player.insert {name = 'light-armor', count = 1}
	end	
end



local function on_init()
	global.labyrinth_cells = {}
end

event.on_init(on_init)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_chunk_charted, on_chunk_charted)
event.add(defines.events.on_player_joined_game, on_player_joined_game)