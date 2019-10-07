-- Cave Defender, protect the locomotive! -- by MewMew

require "modules.wave_defense"
--require "modules.dense_rocks"

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

local function on_entity_died(event)
	if not event.entity.valid then	return end
	if event.entity == global.locomotive_cargo then
		game.print("Game Over!")
		global.wave_defense.game_lost = true 
		return 
	end
end

local function on_entity_damaged(event)
	if not event.entity.valid then	return end
	if event.entity.force.index ~= 1 then return end
	if event.entity == global.locomotive or event.entity == global.locomotive_cargo then
		if event.cause then
			if event.cause.force.index == 2 then
				return
			end
		end
		event.entity.health = event.entity.health + event.final_damage_amount
	end
end

local function on_player_joined_game(event)	
	local surface = game.surfaces["mountain_fortress"]
	local player = game.players[event.player_index]	
	
	if player.online_time == 0 then
		player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 3, 0.5), surface)
		player.insert({name = 'pistol', count = 1})
		player.insert({name = 'firearm-magazine', count = 16})
		player.insert({name = 'rail', count = 16})
	end
end

local function on_init(surface)
	global.chunk_queue = {}

	init_surface()
	
	local surface = game.surfaces["mountain_fortress"]
	surface.request_to_generate_chunks({0,0}, 6)
	surface.force_generate_chunk_requests()
	
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0	
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.max_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.min_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.settler_group_max_size = 32
	game.map_settings.enemy_expansion.settler_group_min_size = 16
	game.map_settings.pollution.enabled = false
	
	game.forces.player.technologies["steel-axe"].researched = true
	game.forces.player.technologies["railway"].researched = true
	game.forces.player.set_spawn_position({-2, 16}, surface)
	
	locomotive_spawn(surface, {x = 0, y = 16})
	
	global.wave_defense.surface = surface
	global.wave_defense.target = global.locomotive_cargo
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)