-- forest maze from mewmew
local event = require 'utils.event'
local map_functions = require "tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'.d2
local math_random = math.random

local labyrinth_cell_size = 16 --valid values are 1, 2, 4, 8, 16, 32

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
	
local function labyrinth_wall(surface, cell_pos)
	for x = 0.5, labyrinth_cell_size + 0.5, 1 do
		for y = 0.5, labyrinth_cell_size + 0.5, 1 do
			local pos = {x = cell_pos.x + x, y = cell_pos.y + y}
			if math_random(1,2) == 1 then
				surface.create_entity({name = "tree-04", position = pos})
			end
		end
	end
end
	
local function labyrinth_path(surface, pos)
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
		
	for _, m1 in pairs(modifiers) do
		local connections = 0
		local r = math_random(2, 3)
		for _, m2 in pairs(modifiers) do
			if global.labyrinth_cells[tostring(cell_position.x + m1.x + m2.x) .. "_" .. tostring(cell_position.y + m1.y + m2.y)] then
				connections = connections + 1
			end
			if connections >= r then return false end
		end
	end
	
	local connections = 0
	for _, m in pairs(modifiers) do
		if global.labyrinth_cells[tostring(cell_position.x + m.x) .. "_" .. tostring(cell_position.y + m.y)] then
			connections = connections + 1
		end
	end		
	if connections > math_random(2, 3) then return false end
	
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
	local chunk_pos_x = event.area.left_top.x
	local chunk_pos_y = event.area.left_top.y
	local area = {
			left_top = {x = chunk_pos_x, y = chunk_pos_y},
			right_bottom = {x = chunk_pos_x + 31, y = chunk_pos_y + 31}
			}							
	surface.destroy_decoratives({area = area})
	local decoratives = {}	
	
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
			local pos = {x = event.area.left_top.x + x, y = event.area.left_top.y + y}				
			table.insert(tiles, {name = "grass-1", position = pos}) 
		end
	end
	surface.set_tiles(tiles,true)

	labyrinth(event)
end

local function on_chunk_charted(event)
	
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