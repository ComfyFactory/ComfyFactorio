--18x10

local event = require 'utils.event' 
local playfield_left_top = {x = -5, y = -26}
local playfield_width = 10
local playfield_height = 18

local playfield_area = {
	["left_top"] = {x = playfield_left_top.x, y = playfield_left_top.y},
	["right_bottom"] = {x = playfield_left_top.x + playfield_width, y = playfield_left_top.y + playfield_height}
}
local playfield_width = math.abs(playfield_area.left_top.x - playfield_area.right_bottom.x)
local playfield_height = math.abs(playfield_area.left_top.y - playfield_area.right_bottom.y)

local bricks = {
	[1] = {
		entity_name = "pipe",
		vectors = {
			[1] = {{0, 1},{0, 0},{0, -1},{0, -2}},	--oooo
			[2] = {{1, 0},{0, 0},{-1, 0},{-2, 0}},			
			[3] = {{0, -1},{0, 0},{0, 1},{0, 2}},
			[4] = {{-1, 0},{0, 0},{1, 0},{2, 0}},
		 }
	},
	[2] = {
		entity_name = "pipe",
		vectors = {
			[1] = {{0, 0},{1, 0},{0, -1},{1, -1}},	--oo
			[2] = {{0, 0},{1, 0},{0, -1},{1, -1}},	--oo
			[3] = {{0, 0},{1, 0},{0, -1},{1, -1}},
			[4] = {{0, 0},{1, 0},{0, -1},{1, -1}},
		 }
	},
	[3] = {
		entity_name = "pipe",
		vectors = {
			[1] = {{0, -1},{0, 0},{1, -1},{-1, 0}},	--  oo
			[2] = {{0, 0},{1, 0},{1, 1},{0, -1}},		--oo
			[3] = {{0, -1},{0, 0},{1, -1},{-1, 0}},
			[4] = {{0, 0},{1, 0},{1, 1},{0, -1}},
		 }
	},
	[4] = {
		entity_name = "pipe",
		vectors = {
			[1] = {{0, -1},{0, 0},{-1, -1},{1, 0}},	--oo
			[2] = {{0, 0},{0, 1},{1, 0},{1, -1}},		--  oo
			[3] = {{0, -1},{0, 0},{-1, -1},{1, 0}},
			[4] = {{0, 0},{0, 1},{1, 0},{1, -1}},
		 }
	},
	[5] = {
		entity_name = "stone-wall",
		vectors = {
			[1] = {{-1, 0},{0, 0},{-1, 1},{1, 0}},	--ooo
			[2] = {{0, 1},{0, 0},{0, -1},{-1, -1}},		--o  
			[3] = {{-1, 0},{0, 0},{1, 0},{1, -1}},
			[4] = {{0, -1},{0, 0},{1, 1},{0, 1}},
		 }
	},
	[6] = {
		entity_name = "stone-wall",
		vectors = {
			[1] = {{-1, 0},{0, 0},{1, 1},{1, 0}},		--ooo
			[2] = {{0, 1},{0, 0},{0, -1},{-1, 1}},	--o  
			[3] = {{-1, 0},{0, 0},{1, 0},{-1, -1}},
			[4] = {{0, -1},{0, 0},{1, -1},{0, 1}},
		 }
	},
}

local move_translations = {
	["iron-plate"] = {-1, 0},
	["copper-plate"] = {1, 0}
}

local function coord_string(x, y)
	str = tostring(x) .. "_"
	str = str .. tostring(y)
	return str
end

local function is_position_inside_playfield(position)
	if position.x > playfield_area.right_bottom.x then return false end
	if position.y > playfield_area.right_bottom.y then return false end
	if position.x <= playfield_area.left_top.x then return false end
	if position.y < playfield_area.left_top.y then return false end
	return true
end

local function has_position_free_space(surface, position)
	--local entities = surface.find_entities_filtered({area = {{position.x + 0.1, position.y + 0.1},{position.x + 0.9, position.y + 0.9}}})
	local entities = surface.find_entities_filtered({position = {position.x + 0.5, position.y + 0.5}})
	if not entities then game.print(1) return true end
	if not global.active_brick.entities then game.print(2) return true end
	for _, e in pairs(global.active_brick.entities) do
		if e == entities[1] then game.print(3) return true end
	end
	return false
end

local function draw_active_bricks(surface)
	if not global.active_brick then return end
	if not global.active_brick.entities then global.active_brick.entities = {} end
	for k, e in pairs(global.active_brick.entities) do	
		e.destroy()
		global.active_brick.entities[k] = nil
	end
	for _, p in pairs(global.active_brick.positions) do
		global.active_brick.entities[#global.active_brick.entities + 1] = surface.create_entity({name = global.active_brick.entity_name, position = p})
	end
end

local function rotate_brick(surface)
	if not global.active_brick then return end	
	local center_pos = global.active_brick.positions[2]
	local vectors = bricks[global.active_brick.type].vectors
	local new_direction = global.active_brick.direction + 1
	if new_direction > 4 then new_direction = 1 end
	local new_vectors = vectors[new_direction]	
	for k, p in pairs(global.active_brick.positions) do
		if not global.tetris_grid[coord_string(math.floor(center_pos.x + new_vectors[k][1]), math.floor(center_pos.y + new_vectors[k][2]))] then return end
	end
	for k, p in pairs(global.active_brick.positions) do
		global.active_brick.positions[k] = {x = center_pos.x + new_vectors[k][1], y = center_pos.y + new_vectors[k][2]}
	end
	global.active_brick.direction = new_direction
end

local function new_brick(surface)

	if global.active_brick then return end	
	if game.tick < 60 then return end
	global.active_brick = {}
	
	local spawn_position = {x = playfield_area.left_top.x + playfield_width * 0.5, y = playfield_area.left_top.y + 3}
	local r = math.random(1, #bricks)
	--local r = 6
	local brick = bricks[r]
	global.active_brick.direction = 1
	global.active_brick.type = r
	global.active_brick.positions = {}
	global.active_brick.entity_name = brick.entity_name
	
	for k, v in pairs(brick.vectors[1]) do
		global.active_brick.positions[k] = {x = spawn_position.x + v[1], y = spawn_position.y + v[2]}
	end
	
end

local function set_hotbar()
	for _, player in pairs(game.connected_players) do
		player.set_quick_bar_slot(1, "iron-plate")
		player.set_quick_bar_slot(2, "copper-plate")
		player.set_quick_bar_slot(8, "iron-gear-wheel")
	end
end

local function set_inventory()
	for _, player in pairs(game.connected_players) do
		
		for _, item in pairs({"iron-plate", "copper-plate", "iron-gear-wheel"}) do
			
			if player.get_main_inventory().get_item_count(item) == 0 then
				player.insert({name = item, count = 1})
			end
		end
	end
end

local function move(surface, item)
	if not global.active_brick then return end
	if item == "iron-gear-wheel" then
		rotate_brick(surface)
		return
	end
	if not move_translations[item] then return end
	for k, p in pairs(global.active_brick.positions) do
		if not global.tetris_grid[coord_string(math.floor(global.active_brick.positions[k].x + move_translations[item][1]), math.floor(global.active_brick.positions[k].y + move_translations[item][2]))] then return end
	end
	for k, p in pairs(global.active_brick.positions) do
		global.active_brick.positions[k] = {x = global.active_brick.positions[k].x + move_translations[item][1], y = global.active_brick.positions[k].y + move_translations[item][2]}
	end
end

local function move_down(surface)
	if not global.active_brick then return end
	for k, p in pairs(global.active_brick.positions) do
		if not global.tetris_grid[coord_string(math.floor(global.active_brick.positions[k].x), math.floor(global.active_brick.positions[k].y + 1))] then
			for k, p in pairs(global.active_brick.positions) do
				global.tetris_grid[coord_string(math.floor(p.x), math.floor(p.y))] = false
			end
			global.active_brick = nil
			return 
		end
	end	
	for k, p in pairs(global.active_brick.positions) do
		global.active_brick.positions[k] = {x = global.active_brick.positions[k].x, y = global.active_brick.positions[k].y + 1}
	end
end

local function draw_playfield(surface)
	for x = 1, playfield_width, 1 do
		for y = 1, playfield_height, 1 do
			local position = {x = playfield_area.left_top.x + x, y = playfield_area.left_top.y + y}
			surface.set_tiles({{name = "tutorial-grid", position = position}})
			global.tetris_grid[coord_string(math.floor(position.x), math.floor(position.y))] = true
		end
	end
end

local function on_player_cursor_stack_changed(event)
	local player = game.players[event.player_index]
	--game.print(game.tick)
--	game.print(player.cursor_stack)
	if not player.cursor_stack then return end	
	if not player.cursor_stack.valid_for_read then return end
	if not player.cursor_stack.name then return end
	local item = player.cursor_stack.name
	move(player.surface, item)
	player.cursor_stack.clear()
	player.surface.spill_item_stack(player.position,{name = item, count = 1}, true)
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	set_hotbar()
	set_inventory()
end

local function on_chunk_generated(event)
	local surface = event.surface
	for _, e in pairs(surface.find_entities_filtered({area = event.area, force = {"neutral", "enemy"}})) do
		e.destroy()
	end
	for _, t in pairs(surface.find_tiles_filtered({area = event.area})) do
		--surface.set_tiles({{name = "tutorial-grid", position = t.position}})
		if t.position.y < 4 and t.position.y > -4 then
			surface.set_tiles({{name = "sand-1", position = t.position}})
		else
			surface.set_tiles({{name = "out-of-map", position = t.position}})
		end
	end
	surface.destroy_decoratives{area=event.area}
	if event.area.left_top.x == 128 and event.area.left_top.y == 128 then
		draw_playfield(surface)
	end
end

local function on_init(event)
	global.tetris_grid = {}
end

local function tick()
	--set_inventory()
	local surface = game.surfaces[1]
	if game.tick % 30 == 0 then		
		new_brick(surface)
	end
	if game.tick % 30 == 0 then
		move_down(surface)	
	end	
	if game.tick % 8 == 0 then	
		draw_active_bricks(surface)
	end
end

event.on_nth_tick(2, tick)
event.on_init(on_init)
event.add(defines.events.on_player_cursor_stack_changed, on_player_cursor_stack_changed)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_chunk_generated, on_chunk_generated)