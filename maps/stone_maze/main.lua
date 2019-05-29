--optionals
require "modules.satellite_score"
require "modules.dynamic_landfill"
require "modules.dangerous_goods"

--essentials
require "modules.biters_yield_coins"
require "modules.rocks_yield_ore"
require "modules.mineable_wreckage_yields_scrap"
require 'utils.table'

local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random

local rooms_1x1 = require 'maps.stone_maze.1x1_rooms' 
local multirooms = {}
multirooms["2x2"] = require 'maps.stone_maze.2x2_rooms'

map_functions = require "tools.map_functions"
grid_size = 8
rock_raffle = {"rock-huge", "rock-big", "rock-big", "rock-big"}
tree_raffle = {"tree-01", "tree-02", "tree-03", "tree-04", "tree-05", "tree-06", "tree-07", "tree-08", "tree-09", "tree-02-red", "tree-06-brown", "tree-08-brown", "tree-08-red","tree-09-brown","tree-09-red","dead-dry-hairy-tree","dry-hairy-tree","dry-tree","dead-tree-desert","dead-grey-trunk"}


local visited_tile_translation = {
	["dirt-3"] = "dirt-7",
	["dirt-5"] = "dirt-7",
	["grass-2"] = "grass-1"
}

local function draw_depth_gui()
	for _, player in pairs(game.connected_players) do
		if player.gui.top.evolution_gui then player.gui.top.evolution_gui.destroy() end
		local element = player.gui.top.add({type = "sprite-button", name = "evolution_gui", caption = "Depth: " .. global.maze_depth, tooltip = "Delve deep and face increased dangers."})
		local style = element.style
		style.minimal_height = 38
		style.maximal_height = 38
		style.minimal_width = 146
		style.top_padding = 2
		style.left_padding = 4
		style.right_padding = 4
		style.bottom_padding = 2
		style.font_color = {r = 125, g = 75, b = 25}
		style.font = "default-large-bold"
	end
end

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

local function set_visted_cell_tiles(surface, cell_position)
	local left_top = {x = cell_position.x * grid_size, y = cell_position.y * grid_size}
	for x = 0, grid_size - 1, 1 do
		for y = 0, grid_size - 1, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			local tile_name = surface.get_tile(pos).name
			if visited_tile_translation[tile_name] then
				surface.set_tiles({{name = visited_tile_translation[tile_name], position = pos}}, true)
			end
		end
	end
end

local function can_multicell_expand(cell_position, direction, cell_type)	
	local left_top_index = {}
	for i = 1, #cells[cell_type][coord_to_string(direction)], 1 do
		left_top_index[#left_top_index + 1] = i
	end
	table.shuffle_table(left_top_index)

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

local multi_cell_chances = {
	{"2x2"},
}

local function set_cell(surface, cell_position, direction)
	
	local multi_cell_type = "2x2"
	
	if math_random(1,3) == 1 then
		local cell_left_top = can_multicell_expand(cell_position, direction, multi_cell_type)	
		if cell_left_top then
			if cells_to_open == 0 then return end
			cells_to_open = cells_to_open - 1		
			
			for x = 0, cells[multi_cell_type].size_x - 1, 1 do
				for y = 0, cells[multi_cell_type].size_y - 1, 1 do
					local p = {x = cell_left_top.x + x, y = cell_left_top.y + y}
					set_cell_tiles(surface, p, "dirt-3")
					
					init_cell(p)
					global.maze_cells[coord_to_string(p)].occupied = true
					
					global.maze_depth = global.maze_depth + 1
					draw_depth_gui()
				end
			end							
			
			multirooms[multi_cell_type][math_random(1,#multirooms[multi_cell_type])](surface, cell_left_top, direction)
			
			return
		end
	end
	
	if can_1x1_expand(cell_position, direction) then
		if cells_to_open == 0 then return end
		cells_to_open = cells_to_open - 1		
		
		set_cell_tiles(surface, cell_position, "dirt-3")
		rooms_1x1[math_random(1,#rooms_1x1)](surface, cell_position, direction)
		
		init_cell(cell_position)
		global.maze_cells[coord_to_string(cell_position)].occupied = true
		
		global.maze_depth = global.maze_depth + 1
		draw_depth_gui()
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
	set_visted_cell_tiles(surface, cell_position)
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
	global.maze_depth = 0
	game.forces["player"].set_spawn_position({x = grid_size * 0.5, y = grid_size * 0.5}, game.surfaces.nauvis)
end

event.on_init(on_init)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_chunk_generated, on_chunk_generated)