--lost-- mewmew made this --

local Rooms = require "functions.random_room"
local table_insert = table.insert
local math_random = math.random

local disabled_for_deconstruction = {
		["fish"] = true,
		["rock-huge"] = true,
		["rock-big"] = true,
		["sand-rock-big"] = true,
		["mineable-wreckage"] = true
	}

local function on_chunk_generated(event)
	local left_top = event.area.left_top
	
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	local surface = game.surfaces["dungeons"]
	if player.online_time == 0 then
		player.teleport(surface.find_non_colliding_position("character", {0, 0}, 50, 0.5), surface)
	end	
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	local surface = entity.surface
	
	Rooms.draw_random_room(surface, entity.position)
end

local function on_marked_for_deconstruction(event)	
	if disabled_for_deconstruction[event.entity.name] then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

local function on_init()
	local map_gen_settings = {}	
	map_gen_settings.height = 3
	map_gen_settings.width = 3
	local surface = game.create_surface("dungeons", map_gen_settings)
	
	surface.request_to_generate_chunks({0,0}, 2)
	surface.force_generate_chunk_requests()
	surface.create_entity({name = "rock-big", position = {0, -1}})
	
	local surface = game.surfaces[1]
	local map_gen_settings = surface.map_gen_settings
	map_gen_settings.height = 3
	map_gen_settings.width = 3
	surface.map_gen_settings = map_gen_settings
	for chunk in surface.get_chunks() do		
		surface.delete_chunk({chunk.x, chunk.y})		
	end
	
	game.forces.player.manual_mining_speed_modifier = 10
end

local Event = require 'utils.event' 
Event.on_init(on_init)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)