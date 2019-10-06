-- Cave Defender, protect the locomotive! -- by MewMew

require "modules.wave_defense"

require "maps.mountain_fortress.terrain"
require "maps.mountain_fortress.locomotive"

local function init_surface()	
	local map = {
		["seed"] = math.random(1, 1000000),
		["water"] = 0,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = false},
			["decorative"] = {treat_missing_as_default = false},
		},
		["default_enable_all_autoplace_controls"] = false,
	}
	game.create_surface("mountain_fortress", map)
end

local function on_player_joined_game(event)	
	local surface = game.surfaces["mountain_fortress"]
	local player = game.players[event.player_index]	
	
	if player.online_time == 0 then
		player.teleport(surface.find_non_colliding_position("character", {0,0}, 3, 0.5), surface)
	end
end

local function on_init(surface)
	init_surface()
	
	local surface = game.surfaces["mountain_fortress"]
	surface.request_to_generate_chunks({0,0}, 6)
	surface.force_generate_chunk_requests()
	
	global.wave_defense.surface = surface
	
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0	
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.max_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.min_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.settler_group_max_size = 32
	game.map_settings.enemy_expansion.settler_group_min_size = 16
	game.map_settings.pollution.enabled = false
	
	locomotive_spawn(surface, {x = 0, y = -10})
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_player_joined_game, on_player_joined_game)