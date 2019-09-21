--map by mewmew and kyte

require "maps.island_troopers.map_intro"
require "functions.noise_vector_path"
require "modules.shopping_chests"
require "modules.no_turrets"
require "modules.dangerous_goods"
require "modules.difficulty_vote"
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

function update_stage_gui()
	local caption = "Level: " .. global.current_level
	caption = caption .. "  |  Stage: "
	local stage = global.current_stage
	if stage > #global.stages - 1 then stage = #global.stages - 1 end
	caption = caption .. stage
	caption = caption .. "/"
	caption = caption .. #global.stages - 1
	caption = caption .. "  |  Bugs remaining: "
	caption = caption .. global.alive_enemies
	
	for _, player in pairs(game.connected_players) do
		if player.gui.top.stage_gui then
			player.gui.top.stage_gui.caption = caption
		end
	end
end

local function bring_players()
	local surface = game.surfaces[1]
	for _, player in pairs(game.connected_players) do
		if player.position.y < -1 then
			if player.character then
				if player.character.valid then
					local p = surface.find_non_colliding_position("character", {0, 2}, 8, 0.5)
					if not p then player.teleport({0, 2}, surface) end
					player.teleport(p, surface)
				end
			end
		end
	end
end

local function drift_corpses_toward_beach()
	local surface = game.surfaces[1]
	for _, corpse in pairs(surface.find_entities_filtered({name = "character-corpse"})) do
		if corpse.position.y < 0 then			
			if surface.get_tile(corpse.position).collides_with("resource-layer") then
				corpse.clone{position={corpse.position.x, corpse.position.y + 1}, surface=surface, force=corpse.force.name}
				corpse.destroy()
			end 
		end
	end
end

local function set_next_level()	
	global.alive_enemies = 0
	global.alive_boss_enemy_count = 0
	global.current_stage = 1
	global.current_level = global.current_level + 1
	
	if global.current_level > 1 then bring_players() end
	
	global.path_tiles = nil
	
	local island_size = math.random(global.current_level, global.current_level * 2) + 7
	if island_size > 128 then island_size = 128 end
	
	global.stages = {}
	global.stages[1] = {
			path_length = 24 + island_size * 2,
			size = island_size,
		}
		
	local stages_amount = (global.current_level * 0.5) + 1
	if stages_amount > 16 then stages_amount = 16 end
	for i = 1, stages_amount, 1 do
		global.stages[#global.stages + 1] = {
			path_length = 16 + island_size * 2,
			size = island_size,
		}
	end
	global.stages[#global.stages + 1] = {
		path_length = 64 + island_size * 5,
		size = false,
	}
	
	--game.print("Level " .. global.current_level)
	update_stage_gui()
	
	global.gamestate = 2
end

local function earn_credits(amount)
	for _, player in pairs(game.connected_players) do
		player.play_sound{path="utility/new_objective", volume_modifier=0.4}
	end
	game.print(amount .. " credits have been transfered to the factory.", {r = 255, g = 215, b = 0})
	global.credits = global.credits + amount
end

local function slowmo()
	if not global.slowmo then global.slowmo = 0.15 end
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
	local reward_amount = false
	local gamestate = 2
	
	if global.stages[global.current_stage].size then
		if global.current_stage < #global.stages -1 then
			reward_amount = global.current_stage * global.current_level * 75
		else
			reward_amount = global.current_stage * global.current_level * 150
		end
	else
		game.print("Final Stage complete!")
		game.print("Level is collapsing !!", {r = 255, g = 0, b = 0})
		gamestate = 5
	end		
	
	if reward_amount then
		earn_credits(reward_amount) 
		update_stage_gui()
	end
	global.current_stage = global.current_stage + 1
	global.gamestate = gamestate
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	create_stage_gui(player)
	if player.gui.left["slowmo_cam"] then player.gui.left["slowmo_cam"].destroy() end
	player.insert({name = "pistol", count = 1})
	player.insert({name = "firearm-magazine", count = 32})
end

local function on_init()
	local surface = game.surfaces[1]
	surface.request_to_generate_chunks({x = 0, y = 0}, 16)
	surface.force_generate_chunk_requests()
	
	tree_raffle = {}
	for _, e in pairs(game.entity_prototypes) do
		if e.type == "tree" then
			table.insert(tree_raffle, e.name)
		end			
	end
	
	global.difficulty_poll_closing_timeout = 3600 * 5
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
	"I'm doing my part!",
}

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	
	if entity.force.name ~= "enemy" then return end
	global.alive_enemies = global.alive_enemies - 1
	update_stage_gui()
	
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
	if game.tick % 300 == 0 then drift_corpses_toward_beach() end
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)

require "functions.boss_unit"