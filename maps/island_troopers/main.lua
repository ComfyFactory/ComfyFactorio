require "functions.noise_vector_path"
require "modules.shopping_chests"
require "maps.island_troopers.enemies"
require "maps.island_troopers.terrain"

local function create_stage_gui(player)
	if player.gui.top.stage_gui then return end
	local element = player.gui.top.add({type = "frame", name = "stage_gui", caption = " "})
	local style = element.style
	style.minimal_height = 38
	style.maximal_height = 38
	style.minimal_width = 140
	style.top_padding = 2
	style.left_padding = 4
	style.right_padding = 4
	style.bottom_padding = 2
	style.font_color = {r = 155, g = 85, b = 25}
	style.font = "default-large-bold"	
end

local function update_gui()
	local caption = "Level: " .. global.current_level
	caption = caption .. " | Stage: "
	caption = caption .. global.current_stage
	for _, player in pairs(game.connected_players) do
		if player.gui.top.stage_gui then
			player.gui.top.stage_gui.caption = caption
		end
	end
end

local function set_next_level()	
	global.alive_enemies = 0
	global.alive_boss_enemy_count = 0
	global.current_stage = 1
	global.current_level = global.current_level + 1
	
	global.path_tiles = nil
	
	local island_size = 16 + math.random(global.current_level * 2, global.current_level * 5)
	if island_size > 256 then island_size = 256 end
	
	global.stages = {}
	global.stages[1] = {
			path_length = 16 + island_size * 2,
			size = island_size,
		}
		
	local stages_amount = global.current_level + 1
	if stages_amount > 16 then stages_amount = 16 end
	for i = 1, stages_amount, 1 do
		global.stages[#global.stages + 1] = {
			path_length = 16 + island_size * 2,
			size = island_size,
		}
	end
	global.stages[#global.stages + 1] = {
		path_length = 128 + global.current_level * 5,
		size = false,
	}
	
	game.print("Level " .. global.current_level)
	update_gui()
	
	global.gamestate = 2
end

local function earn_credits(amount)
	game.print(amount .. " credits have been transfered to the factory!", {r = 255, g = 215, b = 0})
	global.credits = global.credits + amount
end

local function slowmo()
	if not global.slowmo then global.slowmo = 0.10 end
	game.speed = global.slowmo
	global.slowmo = global.slowmo + 0.01		
	if game.speed < 1 then return end
	for _, p in pairs(game.connected_players) do
		if p.gui.left["slowmo_cam"] then p.gui.left["slowmo_cam"].destroy() end
	end
	global.slowmo = nil
	global.gamestate = 4 
end

local function wait_until_stage_is_beaten()
	if global.alive_enemies > 0 then return end
	if global.stages[global.current_stage].size then
		earn_credits(global.current_stage * global.current_level * 100)
		global.current_stage = global.current_stage + 1
		global.gamestate = 2
		update_gui()
		return 
	end
	earn_credits(global.current_stage * global.current_level * 100 * 2)
	game.print("Level " .. global.current_level .. " complete!!")
	global.gamestate = 5
	update_gui()
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	create_stage_gui(player)
	if player.gui.left["slowmo_cam"] then player.gui.left["slowmo_cam"].destroy() end
	player.insert({name = "pistol", count = 1})
	player.insert({name = "uranium-rounds-magazine", count = 128})
	player.insert({name = "firearm-magazine", count = 32})
end

local function on_init()
	local surface = game.surfaces[1]
	surface.request_to_generate_chunks({x = 0, y = 0}, 8)
	surface.force_generate_chunk_requests()
	
	--global.level_tiles = {}
	global.level_vectors = {}
	global.alive_boss_enemy_entities = {}
	global.current_level = 0	
	global.gamestate = 1
	
	game.forces.player.set_spawn_position({0, 2}, surface)
end

local msg = {
	"We got the brainbug!",
	"Good job troopers!",
	"This will pay off well!",
}

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	
	if entity.force.name ~= "enemy" then return end
	global.alive_enemies = global.alive_enemies - 1
	
	if entity.type ~= "unit" then return end
	if not global.alive_boss_enemy_entities[entity.unit_number] then return end
	global.alive_boss_enemy_entities[entity.unit_number] = nil
	global.alive_boss_enemy_count = global.alive_boss_enemy_count - 1
	if global.alive_boss_enemy_count == 0 then
		for _, p in pairs(game.connected_players) do
			if p.gui.left["slowmo_cam"] then p.gui.left["slowmo_cam"].destroy() end
			local frame = p.gui.left.add({type = "frame", name = "slowmo_cam", caption = msg[math.random(1, #msg)]})
			local camera = frame.add({type = "camera", name = "mini_cam_element", position = entity.position, zoom = 1.5, surface_index = 1})
			camera.style.minimal_width = 400
			camera.style.minimal_height = 400		
		end
		global.gamestate = 8 	
	end
end

local gamestate_functions = {
	[1] = set_next_level,
	[2] = draw_path_to_next_stage,
	[3] = draw_the_island,
	[4] = wait_until_stage_is_beaten,
	[5] = kill_the_level,
	[8] = slowmo,
}

local function on_tick()	
	gamestate_functions[global.gamestate]()	
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)

require "functions.boss_unit"