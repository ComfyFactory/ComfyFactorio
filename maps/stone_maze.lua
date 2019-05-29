require "modules.satellite_score"
require 'utils.table'

local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random

local grid_size = 8

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]	
	if player.online_time == 0 then
		player.insert{name = 'landfill', count = 200}
		player.insert{name = 'iron-plate', count = 32}
		player.insert{name = 'iron-gear-wheel', count = 16}
	end	
end

local function coord_to_string(pos)
	local x = pos[1]
	local y = pos[2]
	if pos.x then x = pos.x end
	if pos.y then y = pos.y end
	return tostring(x .. "_" .. y)
end

local cells = {
	["2x2"] = {
		size_x = 2,
		size_y = 2,
		["0_-1"] = {{-1, -1}, {0, -1}},
		["0_1"] = {{0, 0}, {-1, 0}},
		["-1_0"] = {{-1, -1}, {-1, 0}},
		["1_0"] = {{0, 0}, {0, -1}},
	}
}

local cells_1x1 = {
	--["0_-1"] = {core = {{0, 0}}, border = {{-1, 0}, {1, 0}, {-1, -1}, {1, -1}, {0, -1}}},
	--["0_1"] = {core = {{0, 0}}, border = {{-1, 0}, {1, 0}, {1, 1}, {-1, 1}, {0, 1}}},
	--["-1_0"] = {core = {{0, 0}}, border = {{-1, 0}, {-1, -1}, {-1, 1}, {0, -1}, {0, 1}}},
	--["1_0"] = {core = {{0, 0}}, border = {{1, 0}, {1, 1}, {1, -1}, {0, -1}, {0, 1}}}
	["0_-1"] = {{0, 0}, {-1, 0}, {1, 0}, {-1, -1}, {1, -1}},
	["0_1"] = {{0, 0}, {-1, 0}, {1, 0}, {1, 1}, {-1, 1}},
	["-1_0"] = {{0, 0}, {-1, -1}, {-1, 1}, {0, -1}, {0, 1}},
	["1_0"] = {{0, 0}, {1, 1}, {1, -1}, {0, -1}, {0, 1}}
}

local function init_cell(cell_position)
	if global.maze_cells[coord_to_string(cell_position)] then return end
	if not global.maze_cells[coord_to_string(cell_position)] then global.maze_cells[coord_to_string(cell_position)] = {} end
	global.maze_cells[coord_to_string(cell_position)].visited = false
	global.maze_cells[coord_to_string(cell_position)].occupied = false
end

local function set_cell_tiles(surface, cell_position, tile_name)
	local left_top = {x = cell_position.x * grid_size, y = cell_position.y * grid_size}
	for x = 0, grid_size - 1, 1 do
		for y = 0, grid_size - 1, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			surface.set_tiles({{name = tile_name, position = pos}}, true)
		end
	end
end

local function can_multicell_expand(cell_position, direction, cell_type)
	
	local left_top_index = {}
	for i = 1, #cells[cell_type][coord_to_string(direction)], 1 do
		left_top_index[#left_top_index + 1] = i
	end
	table.shuffle_table(left_top_index)

	game.print(left_top_index[1])

	for i = 1, #left_top_index, 1 do
		
		local left_top = cells[cell_type][coord_to_string(direction)][left_top_index[i]]
		local failures = 0
		local cell_left_top = {x = cell_position.x + left_top[1], y = cell_position.y + left_top[2]}
		
		for x = -1, cells[cell_type].size_x, 1 do
			for y = -1, cells[cell_type].size_y, 1 do
				local p = {x = cell_left_top.x + x, y = cell_left_top.y + y}
				if global.maze_cells[coord_to_string(p)] then
					if global.maze_cells[coord_to_string(p)].occupied then failures = failures + 1 end
				end
			end
		end
		
		if failures < 2 then return cell_left_top end
	end	
	return false
end

local function can_1x1_expand(cell_position, direction)
	for _, v in pairs(cells_1x1[coord_to_string(direction)]) do
		local p = {x = cell_position.x + v[1], y = cell_position.y + v[2]}		
		if global.maze_cells[coord_to_string(p)] then
			if global.maze_cells[coord_to_string(p)].occupied then return false end
		end
	end
	return true
end

local function set_cell(surface, cell_position, direction)
	
	local cell_left_top_2x2 = can_multicell_expand(cell_position, direction, "2x2")
	
	if cell_left_top_2x2 then
		if cells_to_open == 0 then return end
		cells_to_open = cells_to_open - 1		
		
		for x = 0, cells["2x2"].size_x - 1, 1 do
			for y = 0, cells["2x2"].size_y - 1, 1 do
				local p = {x = cell_left_top_2x2.x + x, y = cell_left_top_2x2.y + y}
				set_cell_tiles(surface, p, "dirt-3")
				init_cell(p)
				global.maze_cells[coord_to_string(p)].occupied = true			
			end
		end							
		
		return
	end

	if can_1x1_expand(cell_position, direction) then
		if cells_to_open == 0 then return end
		cells_to_open = cells_to_open - 1		
		
		set_cell_tiles(surface, cell_position, "dirt-3")
			
		init_cell(cell_position)
		global.maze_cells[coord_to_string(cell_position)].occupied = true		
	end	
end

local function set_cells(surface, cell_position)
	local directions = {{-1, 0}, {1, 0}, {0, 1}, {0, -1}}
	table.shuffle_table(directions)
	
	cells_to_open = math.random(1,2)
	
	for _, d in pairs(directions) do
		local p = {x = cell_position.x + d[1], y = cell_position.y + d[2]}		
		set_cell(surface, p, d)
	end
end

local function on_player_changed_position(event)
	local position = game.players[event.player_index].position
	local surface = game.players[event.player_index].surface
	
	local cell_x = math.floor(position.x / grid_size)
	local cell_y = math.floor(position.y / grid_size)	
	
	if position.x / grid_size - cell_x < 0.05 then return end
	if position.x / grid_size - cell_x > 0.95 then return end
	if position.y / grid_size - cell_y < 0.05 then return end
	if position.y / grid_size - cell_y > 0.95 then return end
	
	local cell_position = {x = cell_x, y = cell_y}
	
	init_cell(cell_position)
	
	if global.maze_cells[coord_to_string(cell_position)].visited then return end
	
	set_cells(surface, cell_position)
	
	global.maze_cells[coord_to_string(cell_position)].visited = true
	set_cell_tiles(surface, cell_position, "dirt-7")
end

local function on_chunk_generated(event)
	local surface = event.surface
	local left_top = event.area.left_top
	local tiles = {}
	
	if left_top.x == 0 and left_top.y == 0 then
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				local tile_name = "out-of-map"
				if x < grid_size and y < grid_size then tile_name = "dirt-7" end
				local p = {x = left_top.x + x, y = left_top.y + y}
				surface.set_tiles({{name = tile_name, position = p}}, true)	
			end
		end
		init_cell({0,0})
		global.maze_cells[coord_to_string({0,0})].occupied = true
		return
	end
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do	
			local p = {x = left_top.x + x, y = left_top.y + y}
			surface.set_tiles({{name = "out-of-map", position = p}}, true)	
		end
	end
end

local function on_init(event)
	global.maze_cells = {}
	game.forces["player"].set_spawn_position({x = grid_size * 0.5, y = grid_size * 0.5}, game.surfaces.nauvis)
end

event.on_init(on_init)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_chunk_generated, on_chunk_generated)