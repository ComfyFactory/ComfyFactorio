require "modules.satellite_score"

local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random

local grid_size = 16

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

local directions = {{-1, 0}, {1, 0}, {0, 1}, {0, -1}}

local cells_1x1 = {
	["0_-1"] = {core = {{0, 0}}, border = {{-1, 0}, {1, 0}, {-1, -1}, {1, -1}, {0, -1}}},
	["0_1"] = {core = {{0, 0}}, border = {{-1, 0}, {1, 0}, {1, 1}, {-1, 1}, {0, 1}}},
	["-1_0"] = {core = {{0, 0}}, border = {{-1, 0}, {-1, -1}, {-1, 1}, {0, -1}, {0, 1}}},
	["1_0"] = {core = {{0, 0}}, border = {{1, 0}, {1, 1}, {1, -1}, {0, -1}, {0, 1}}}
}

local cells_2x2 = {
	["0_-1"] = {core = {{0, 0}, {-1, 0}, {-1, -1}, {0, -1}}, border = {{-1, 0}, {1, 0}, {-1, -1}, {1, -1}, {0, -1}}},
	["0_1"] = {core = {{0, 0}}, border = {{-1, 0}, {1, 0}, {1, 1}, {-1, 1}, {0, 1}}},
	["-1_0"] = {core = {{0, 0}}, border = {{-1, 0}, {-1, -1}, {-1, 1}, {0, -1}, {0, 1}}},
	["1_0"] = {core = {{0, 0}}, border = {{1, 0}, {1, 1}, {1, -1}, {0, -1}, {0, 1}}}
}

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
		return
	end
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do	
			local p = {x = left_top.x + x, y = left_top.y + y}
			surface.set_tiles({{name = "out-of-map", position = p}}, true)	
		end
	end
end



local function can_1x1_expand(cell_position, direction)
	for _, v in pairs(cells_1x1[coord_to_string(direction)].core) do
		local p = {x = cell_position.x + v[1], y = cell_position.y + v[2]}		
		if global.maze_cells[coord_to_string(p)] then return false end
	end
	for _, v in pairs(cells_1x1[coord_to_string(direction)].border) do
		local p = {x = cell_position.x + v[1], y = cell_position.y + v[2]}		
		if global.maze_cells[coord_to_string(p)] then return false end
	end
	return true
end

local function set_cell(surface, cell_position, direction)	
	if can_1x1_expand(cell_position, direction) then
		local left_top = {x = cell_position.x * grid_size, y = cell_position.y * grid_size}
		for x = 0, grid_size - 1, 1 do
			for y = 0, grid_size - 1, 1 do
				local pos = {left_top.x + x, left_top.y + y}
				surface.set_tiles({{name = "dirt-7", position = pos}}, true)
			end
		end
		global.maze_cells[coord_to_string(cell_position)] = true
	end
end

local function set_cells(surface, cell_position)
	for _, d in pairs(directions) do
		local p = {x = cell_position.x + d[1], y = cell_position.y + d[2]}
		if not global.maze_cells[coord_to_string(p)] then set_cell(surface, p, d) end
	end
end

local function on_player_changed_position(event)
	local position = game.players[event.player_index].position
	local surface = game.players[event.player_index].surface
	
	local cell_x = math.floor(position.x / grid_size)
	local cell_y = math.floor(position.y / grid_size)
	
	--game.print(position.x / grid_size - cell_x)
	
	if position.x / grid_size - cell_x < 0.05 then return end
	if position.x / grid_size - cell_x > 0.95 then return end
	if position.y / grid_size - cell_y < 0.05 then return end
	if position.y / grid_size - cell_y > 0.95 then return end
	
	local cell_position = {x = cell_x, y = cell_y}
	set_cells(surface, cell_position)
end

local function on_init(event)
	global.maze_cells = {}
	game.forces["player"].set_spawn_position({x = grid_size * 0.5, y = grid_size * 0.5}, game.surfaces.nauvis)
end

event.on_init(on_init)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_chunk_generated, on_chunk_generated)