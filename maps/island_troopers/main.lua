require "functions.noise_vector_path"
require "functions.boss_unit"
require "maps.island_troopers.terrain"

local function set_next_level()	
	global.alive_enemies = 0
	global.current_stage = 1
	global.current_level = global.current_level + 1
	
	global.path_tiles = nil
	global.stages = {}
	global.stages[1] = {
			path_length = 32 + global.current_level * 5,
			size = math.random(global.current_level * 2, global.current_level * 5),
		}	
	for i = 1, global.current_level, 1 do
		global.stages[#global.stages + 1] = {
			path_length = 24 + global.current_level * 5,
			size = math.random(global.current_level * 2, global.current_level * 5),
		}
	end
	global.stages[#global.stages + 1] = {
		path_length = 128 + global.current_level * 5,
		size = false,
	}
	
	game.print("Level " .. global.current_level .. " has begun!")
	
	global.gamestate = 2
end

local function wait_until_stage_is_beaten()
	if global.alive_enemies > 0 then return end
	if global.stages[global.current_stage].size then
		global.current_stage = global.current_stage + 1
		global.gamestate = 2 
		return 
	end
	
	game.print("Level " .. global.current_level .. " complete!!")
	global.gamestate = 5
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
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
	global.current_level = 0	
	global.gamestate = 1
	
	game.forces.player.set_spawn_position({0, 2}, surface)
end

local function on_entity_died(event)
	if not event.entity.valid then return end
	if event.entity.force.name == "enemy" then global.alive_enemies = global.alive_enemies - 1 end
end

local gamestate_functions = {
	[1] = set_next_level,
	[2] = draw_path_to_next_stage,
	[3] = draw_the_island,
	[4] = wait_until_stage_is_beaten,
	[5] = kill_the_level,
}

local function on_tick()
	if game.tick % 2 == 0 then
		gamestate_functions[global.gamestate]()
	end
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)