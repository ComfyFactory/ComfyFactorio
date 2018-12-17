--tank battles (royale)-- mewmew made this --

local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random
local map_functions = require "maps.tools.map_functions"
local arena_size = 128

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function create_tank_battle_score_gui()
	for _, player in pairs (game.connected_players) do
		if player.gui.left["tank_battle_score"] then player.gui.left["tank_battle_score"].destroy() end
		local frame = player.gui.left.add({type = "frame", name = "tank_battle_score", direction = "vertical"})
				
		local l = frame.add({type = "label", caption = "Won rounds"})
		l.style.font_color = {r=0.98, g=0.66, b=0.22}
		l.style.font = "default-listbox"
		
		local t = frame.add({type = "table", column_count = 2})
		
		local scores = {}
		for _, player in pairs(game.connected_players) do
			if global.tank_battles_score[player.index] then
				table_insert(scores, {name = player.name, score = global.tank_battles_score[player.index]})
			end
		end
		
		for x = 1, #scores, 1 do
			for y = 1, #scores, 1 do			
				if not scores[y + 1] then break end
				if scores[y]["score"] < scores[y + 1]["score"] then
					local key = scores[y]
					scores[y] = scores[y + 1]
					scores[y + 1] = key
				end
			end		
		end
				
		for i = 1, 8, 1 do
			if scores[i] then
				local l = t.add({type = "label", caption = scores[i].name})
				local color = game.players[scores[i].name].color
				color = {r = color.r * 0.6 + 0.4, g = color.g * 0.6 + 0.4, b = color.b * 0.6 + 0.4, a = 1}
				l.style.font_color = color
				l.style.font = "default-bold"
				t.add({type = "label", caption = scores[i].score})			
			end
		end
	end
end

local loot = {
	{{name = "submachine-gun", count = 1}, weight = 2},
	{{name = "combat-shotgun", count = 1}, weight = 2},
	{{name = "flamethrower", count = 1}, weight = 2},
	{{name = "rocket-launcher", count = 1}, weight = 2},
	{{name = "railgun", count = 1}, weight = 2},
	
	{{name = "flamethrower-ammo", count = 16}, weight = 2},
	{{name = "piercing-shotgun-shell", count = 16}, weight = 2},
	{{name = "piercing-rounds-magazine", count = 16}, weight = 2},
	{{name = "uranium-rounds-magazine", count = 8}, weight = 1},
	{{name = "explosive-rocket", count = 8}, weight = 2},
	{{name = "rocket", count = 8}, weight = 2},
	{{name = "railgun-dart", count = 8}, weight = 2},
	
	{{name = "grenade", count = 16}, weight = 3},
	{{name = "cluster-grenade", count = 8}, weight = 2},
	{{name = "poison-capsule", count = 4}, weight = 2},		 
	{{name = "defender-capsule", count = 8}, weight = 2},
	{{name = "distractor-capsule", count = 8}, weight = 2},
	{{name = "destroyer-capsule", count = 8}, weight = 2},
			
	{{name = "cannon-shell", count = 16}, weight = 16},
	{{name = "explosive-cannon-shell", count = 16}, weight = 16},
	{{name = "uranium-cannon-shell", count = 16}, weight = 5},
	{{name = "explosive-uranium-cannon-shell", count = 16}, weight = 5},				
	
	{{name = "light-armor", count = 1}, weight = 5},
	{{name = "heavy-armor", count = 1}, weight = 4},
	{{name = "modular-armor", count = 1}, weight = 3},
	{{name = "power-armor", count = 1}, weight = 2},
	{{name = "power-armor-mk2", count = 1}, weight = 1},
	
	{{name = "battery-mk2-equipment", count = 1}, weight = 2},
	{{name = "energy-shield-equipment", count = 1}, weight = 2},
	{{name = "exoskeleton-equipment", count = 1}, weight = 2},
	{{name = "fusion-reactor-equipment", count = 1}, weight = 2},
			
	{{name = "raw-wood", count = 100}, weight = 8},
	{{name = "coal", count = 32}, weight = 6},
	{{name = "solid-fuel", count = 16}, weight = 4},
	{{name = "nuclear-fuel", count = 1}, weight = 1},
	
	{{name = "gate", count = 8}, weight = 2},
	{{name = "stone-wall", count = 16}, weight = 2}
}
local loot_raffle = {}
for _, item in pairs(loot) do
	for x = 1, item.weight, 1 do			
		table.insert(loot_raffle, item[1])			
	end			
end

local function get_valid_random_spawn_position(surface)
	local chunks = {}	
	for chunk in surface.get_chunks() do
		table_insert(chunks, {x = chunk.x, y = chunk.y})
	end
	chunks = shuffle(chunks)
	
	for _, chunk in pairs(chunks) do
		if chunk.x * 32 < arena_size and chunk.y * 32 < arena_size and chunk.x * 32 >= arena_size * -1 and chunk.y * 32 >= arena_size * -1 then
			local area = {{chunk.x * 32 - 64, chunk.y * 32 - 64}, {chunk.x * 32 + 64, chunk.y * 32 + 64}}			
			if surface.count_entities_filtered({name = "tank", area = area}) == 0 then
				local pos = surface.find_non_colliding_position("tank", {chunk.x * 32 + 16, chunk.y * 32 + 16}, 16, 8)
				return pos
			end
		end
	end
	
	local pos = surface.find_non_colliding_position("tank", {0, 0}, 32, 4)
	if pos then return pos end
	
	return {0, 0}
end

local function put_players_into_arena()
	for _, player in pairs(game.connected_players) do	
		local permissions_group = game.permissions.get_group("Default")	
		permissions_group.add_player(player.name)
		
		if not player.character then
			player.create_character()
		end
		
		player.insert({name = "pistol", count = 1})
		player.insert({name = "firearm-magazine", count = 512})
		
		local surface = game.surfaces["tank_battles"]
		local pos = get_valid_random_spawn_position(surface)
		
		player.teleport(pos, surface)
		local tank = surface.create_entity({name = "tank", force = game.forces[player.index], position = pos})
		tank.insert({name = "coal", count = 50})
		tank.insert({name = "cannon-shell", count = 64})		
		tank.set_driver(player)
	end
end

function create_new_arena()			
	local map_gen_settings = {}
	map_gen_settings.seed = math_random(1, 2097152)
	map_gen_settings.water = "none"
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 4, cliff_elevation_0 = 0.1}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "none", size = "none", richness = "none"},
		["stone"] = {frequency = "none", size = "none", richness = "none"},
		["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
		["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
		["crude-oil"] = {frequency = "none", size = "none", richness = "none"},
		--["trees"] = {frequency = "none", size = "none", richness = "none"},
		["enemy-base"] = {frequency = "none", size = "none", richness = "none"}
		--["grass"] = {frequency = "none", size = "none", richness = "none"},
		--["sand"] = {frequency = "none", size = "none", richness = "none"},
		--["desert"] = {frequency = "none", size = "none", richness = "none"},
		--["dirt"] = {frequency = "none", size = "none", richness = "none"}
	}		
	game.create_surface("tank_battles", map_gen_settings)	
	local surface = game.surfaces["tank_battles"]
	surface.request_to_generate_chunks({0,0}, math.ceil(arena_size / 32) + 2)
	surface.force_generate_chunk_requests()
	
	global.current_arena_size = arena_size
	
	put_players_into_arena()
	
	global.game_stage = "ongoing_game"
end

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	if not game.forces[event.player_index] then
		game.create_force(event.player_index)
	end
	
	player.force = game.forces[event.player_index]
	
	if not global.map_init_done then
			
		local spectator_permission_group = game.permissions.create_group("Spectator")
		for action_name, _ in pairs(defines.input_action) do
			spectator_permission_group.set_allows_action(defines.input_action[action_name], false)
		end
		spectator_permission_group.set_allows_action(defines.input_action.write_to_console, true)
		spectator_permission_group.set_allows_action(defines.input_action.gui_click, true)
		spectator_permission_group.set_allows_action(defines.input_action.gui_selection_state_changed, true)
		spectator_permission_group.set_allows_action(defines.input_action.start_walking, true)
		spectator_permission_group.set_allows_action(defines.input_action.open_kills_gui, true)
		--spectator_permission_group.set_allows_action(defines.input_action.open_character_gui, true)
		--spectator_permission_group.set_allows_action(defines.input_action.open_equipment_gui, true)
		spectator_permission_group.set_allows_action(defines.input_action.edit_permission_group, true)	
		spectator_permission_group.set_allows_action(defines.input_action.toggle_show_entity_info, true)				
		
		--game.forces[event.player_index].set_spawn_position({0,0}, surface)								
						
		--local radius = 256
		--player.force.chart(surface,{{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})
		global.tank_battles_score = {}
		global.game_stage = "lobby"
		
		global.map_init_done = true
	end		
		
	if not game.surfaces["tank_battles"] then
		if global.lobby_timer then global.lobby_timer = 1800 end
		return
	end
	
	local permissions_group = game.permissions.get_group("Spectator")	
	permissions_group.add_player(player.name)	
	player.character.destroy()
	player.character = nil
	player.teleport({0, 0}, game.surfaces["tank_battles"])	
end

local function on_marked_for_deconstruction(event)
	event.entity.cancel_deconstruction(game.players[event.player_index].force.name)	
end

function shrink_arena()
	local surface = game.surfaces["tank_battles"]	
	
	if global.current_arena_size < 16 then return end
	
	global.current_arena_size = global.current_arena_size - 1
	
	local tiles = {}	
	for x = arena_size * -1, arena_size, 1 do
		for y = arena_size * -1, arena_size, 1 do
			local pos = {x = x, y = y}
			if surface.get_tile(pos).name ~= "water" and surface.get_tile(pos).name ~= "deepwater" then
				if x > global.current_arena_size or y > global.current_arena_size or x < global.current_arena_size * -1 or y < global.current_arena_size * -1 then				
					if math_random(1, 2) == 1 then
						table_insert(tiles, {name = "water", position = pos})
					end
				end
			end
		end
	end	
		
	surface.set_tiles(tiles, true)
end

local function render_arena_chunk(event)
	if event.surface.name ~= "tank_battles" then return end
	local surface = event.surface
	
	local left_top = event.area.left_top
	
	local tiles = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if pos.x > arena_size or pos.y > arena_size or pos.x < arena_size * -1 or pos.y < arena_size * -1 then
				table_insert(tiles, {name = "water", position = pos})
			else
				if math_random(1, 128) == 1 then
					if surface.can_place_entity({name = "wooden-chest", position = pos, force = "enemy"}) then
						surface.create_entity({name = "wooden-chest", position = pos, force = "enemy"})
					end
				end
			end			
		end
	end
	surface.set_tiles(tiles, true)	
end

local function render_spawn_chunk(event)
	if event.surface.name ~= "nauvis" then return end
	local surface = event.surface
	local left_top = event.area.left_top
	
	for _, entity in pairs(surface.find_entities_filtered({area = event.area})) do
		if entity.name ~= "player" then
			entity.destroy()
		end
	end
	
	local tiles = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			table_insert(tiles, {name = "tutorial-grid", position = pos})
		end
	end
	surface.set_tiles(tiles, true)
end

local function check_for_game_over()
	local surface = game.surfaces["tank_battles"]
	local alive_players = 0
	for _, player in pairs(game.connected_players) do
		if player.character and player.surface.name == "tank_battles" then
			alive_players = alive_players + 1
		end
	end		
	
	if alive_players > 0 then return end
	
	local player
	for _, p in pairs(game.connected_players) do
		if p.character and p.surface.name == "tank_battles" then
			player = p
		end
	end
	
	if alive_players == 1 then
		if not global.tank_battles_score[player.index] then
			global.tank_battles_score[player.index] = 1
		else
			global.tank_battles_score[player.index] = global.tank_battles_score[player.index] + 1
		end
		game.print(player.name .. " has won the battle!", {r = 150, g = 150, b = 0})
	end
	
	global.game_stage = "lobby"
	
	create_tank_battle_score_gui()
end

local function on_chunk_generated(event)
	render_arena_chunk(event)
	render_spawn_chunk(event)	
end

local function on_player_respawned(event)
	local player = game.players[event.player_index]
	
	local permissions_group = game.permissions.get_group("Spectator")	
	permissions_group.add_player(player.name)	
	player.character.destroy()
	player.character = nil
end

local function lobby()	
	if #game.connected_players < 1 then return 	end
	if game.surfaces["tank_battles"] then
		game.delete_surface(game.surfaces["tank_battles"])
		for _, player in pairs(game.connected_players) do
			if player.character then
				player.character.destroy()
				player.character = nil
			end
			if not player.character then
				player.create_character()
			end			
			player.insert({name = "concrete", count = 500})
			player.insert({name = "hazard-concrete", count = 500})
			player.insert({name = "stone-brick", count = 500})
			player.insert({name = "stone-wall", count = 500})
			player.insert({name = "refined-concrete", count = 500})
			player.insert({name = "refined-hazard-concrete", count = 500})
		end
	end
	if not global.lobby_timer then global.lobby_timer = 1800 end
	if global.lobby_timer % 600 == 0 then
		if global.lobby_timer <= 0 then 
			game.print("Round has started!", {r = 0, g = 150, b = 150})
		else
			game.print("Round will begin in " .. global.lobby_timer / 60 .. " seconds.", {r = 0, g = 150, b = 150})
		end
	end
	global.lobby_timer = global.lobby_timer - 300
	if global.lobby_timer >= 0 then return end
	global.lobby_timer = nil
	global.game_stage = "create_arena"
end

local function on_tick(event)
	if game.tick % 300 == 0 then
		--game.print(global.game_stage)
		if global.game_stage == "lobby" then			
			lobby()
		end
		if global.game_stage == "create_arena" then
			create_new_arena()
		end
		if global.game_stage == "ongoing_game" then
			shrink_arena()
			check_for_game_over()
		end		
	end
end

local function on_entity_died(event)
	if event.entity.name == "wooden-chest" then
		event.entity.surface.spill_item_stack(event.entity.position, loot_raffle[math_random(1, #loot_raffle)], true)
	end
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_respawned, on_player_respawned)
event.add(defines.events.on_chunk_generated, on_chunk_generated)