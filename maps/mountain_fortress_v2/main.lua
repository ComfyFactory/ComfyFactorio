-- Mountain digger fortress, protect the locomotive! -- by MewMew

require "modules.biter_evasion_hp_increaser"
require "modules.wave_defense"
--require "modules.dense_rocks"
require "modules.biters_yield_coins"
require "modules.rocks_broken_paint_tiles"
require "modules.rocks_heal_over_time"
require "modules.rocks_yield_ore_veins"
require "modules.rocks_yield_ore"
require "modules.spawners_contain_biters"
require "modules.map_info"
require "modules.rpg"

global.map_info = {}
global.map_info.main_caption = "Mountain Fortress"
global.map_info.sub_caption =  "    ..diggy diggy choo.."
global.map_info.text = [[
	The biters have catched the scent of fish in the cargo wagon.
	Guide the choo into the mountain and protect it as long as possible!
	This however will not be an easy task,
	since their strength and resistance increases constantly over time.
	
	As you dig, you will encounter black bedrock that is just too solid for your pickaxe.
	Some explosives could even break through the impassable dark rock.
	All they need is a container and a well aimed shot.
]]

require "maps.mountain_fortress_v2.market"
require "maps.mountain_fortress_v2.treasure"
require "maps.mountain_fortress_v2.terrain"
require "maps.mountain_fortress_v2.locomotive"
require "maps.mountain_fortress_v2.explosives"

local function init_surface()	
	local map = {
		["seed"] = math.random(1, 1000000),
		["water"] = 0,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 8, cliff_elevation_0 = 8},
		["default_enable_all_autoplace_controls"] = true,
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = true},
			["decorative"] = {treat_missing_as_default = true},
		},
	}
	game.create_surface("mountain_fortress", map)
end

local function on_entity_died(event)
	if not event.entity.valid then	return end
	if event.entity == global.locomotive_cargo then
		for _, player in pairs(game.connected_players) do
			player.play_sound{path="utility/game_lost", volume_modifier=0.75}
		end
		game.print("The cargo was destroyed!")
		--global.wave_defense.game_lost = true 
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
		player.insert({name = 'wood', count = 16})
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
	game.map_settings.enemy_expansion.max_expansion_cooldown = 1800
	game.map_settings.enemy_expansion.min_expansion_cooldown = 1800
	game.map_settings.enemy_expansion.settler_group_max_size = 16
	game.map_settings.enemy_expansion.settler_group_min_size = 32
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