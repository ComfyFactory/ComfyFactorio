-- Biter Battles v2 -- by MewMew

require "on_tick_schedule"
require "maps.biter_battles_v2.config"
require "modules.dynamic_landfill"
require "modules.spawners_contain_biters" 
require "modules.mineable_wreckage_yields_scrap"

local event = require 'utils.event'

local function init_surface()	
	local map_gen_settings = {}
	map_gen_settings.water = "0.15"
	map_gen_settings.starting_area = "2.5"
	--map_gen_settings.cliff_settings = {cliff_elevation_interval = 12, cliff_elevation_0 = 32}
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 38, cliff_elevation_0 = 38}	
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "2", size = "1", richness = "1"},
		["stone"] = {frequency = "2", size = "1", richness = "1"},
		["copper-ore"] = {frequency = "2", size = "1", richness = "1"},
		["iron-ore"] = {frequency = "2", size = "1", richness = "1"},
		["uranium-ore"] = {frequency = "2", size = "1", richness = "1"},
		["crude-oil"] = {frequency = "2.5", size = "1", richness = "1.5"},
		["trees"] = {frequency = "1.25", size = "0.6", richness = "0.5"},
		["enemy-base"] = {frequency = "128", size = "1", richness = "1"}	
	}
	game.create_surface("biter_battles", map_gen_settings)
			
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.pollution.enabled = false
	
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.settler_group_min_size = 8
	game.map_settings.enemy_expansion.settler_group_max_size = 16
	game.map_settings.enemy_expansion.min_expansion_cooldown = 54000
	game.map_settings.enemy_expansion.max_expansion_cooldown = 108000
end

local function init_forces()
	local surface = game.surfaces["biter_battles"]
				
	game.create_force("north")
	game.create_force("north_biters")
	game.create_force("south")
	game.create_force("south_biters")	
	game.create_force("spectator")
	
	local f = game.forces["north"]
	f.set_spawn_position({0, -32}, surface)
	f.set_cease_fire('player', true)
	f.set_friend("spectator", true)
	f.set_friend("south_biters", true)
	f.share_chart = true
	
	local f = game.forces["south"]
	f.set_spawn_position({0, 32}, surface)
	f.set_cease_fire('player', true)
	f.set_friend("spectator", true)
	f.set_friend("north_biters", true)
	f.share_chart = true
	
	local f = game.forces["north_biters"]
	f.set_friend("south_biters", true)
	f.set_friend("south", true)
	f.set_friend("player", true)
	--f.set_friend("enemy", true)
	f.set_friend("spectator", true)
	f.share_chart = false
		
	local f = game.forces["south_biters"]
	f.set_friend("north_biters", true)
	f.set_friend("north", true)
	f.set_friend("player", true)
	--f.set_friend("enemy", true)
	f.set_friend("spectator", true)
	f.share_chart = false
	
	--local f = game.forces["enemy"]
	--f.set_friend("spectator", true)
	--f.set_friend("player", true)
	--f.set_friend("north_biters", true)
	--f.set_friend("south_biters", true)
	
	local f = game.forces["spectator"]
	f.set_spawn_position({0,0},surface)
	f.technologies["toolbelt"].researched=true	
	f.set_cease_fire("north_biters", true)
	f.set_cease_fire("south_biters", true)
	f.set_friend("north", true)
	f.set_friend("south", true)
	f.set_cease_fire("player", true)
	f.share_chart = true
	
	local f = game.forces["player"]
	f.set_spawn_position({0,0},surface)
	f.set_cease_fire('spectator', true)
	f.set_cease_fire("north_biters", true)
	f.set_cease_fire("south_biters", true)
	f.set_cease_fire('north', true)
	f.set_cease_fire('south', true)
	f.share_chart = false
	
	if not bb_config.blueprint_library_importing then	
		game.permissions.get_group("Default").set_allows_action(defines.input_action.grab_blueprint_record, false)
	end
	if not bb_config.blueprint_string_importing then	
		game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint_string, false)
		game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint, false)	
	end
	
	local p = game.permissions.create_group("spectator")
	for action_name, _ in pairs(defines.input_action) do
		p.set_allows_action(defines.input_action[action_name], false)
	end
	
	local defs = {
		defines.input_action.write_to_console,
		defines.input_action.gui_click,
		defines.input_action.gui_selection_state_changed,
		defines.input_action.gui_checked_state_changed	,
		defines.input_action.gui_elem_changed,
		defines.input_action.gui_text_changed,
		defines.input_action.gui_value_changed,
		defines.input_action.start_walking,
		defines.input_action.open_kills_gui,
		defines.input_action.open_character_gui,
		defines.input_action.edit_permission_group,
		defines.input_action.toggle_show_entity_info,
		defines.input_action.rotate_entity,
		defines.input_action.start_research
	}	
	for _, d in pairs(defs) do p.set_allows_action(d, true) end
	
	global.rocket_silo = {}
	global.spectator_rejoin_delay = {}
	global.spy_fish_timeout = {}
	global.force_area = {}
	global.active_biters = {}
	global.bb_evolution = {}
	global.bb_evasion = {}
	global.bb_threat_income = {}
	global.bb_threat = {}
	global.chunks_to_mirror = {}
	global.map_pregen_message_counter = {}
	
	for _, force in pairs(game.forces) do
		game.forces[force.name].technologies["artillery"].enabled = false
		game.forces[force.name].technologies["artillery-shell-range-1"].enabled = false					
		game.forces[force.name].technologies["artillery-shell-speed-1"].enabled = false	
		game.forces[force.name].technologies["atomic-bomb"].enabled = false			
		game.forces[force.name].set_ammo_damage_modifier("shotgun-shell", 1)
		game.forces[force.name].research_queue_enabled = true
		global.spy_fish_timeout[force.name] = 0
		global.active_biters[force.name] = {}
		global.bb_evolution[force.name] = 0
		global.bb_evasion[force.name] = false
		global.bb_threat_income[force.name] = 0
		global.bb_threat[force.name] = 0	
	end
	global.game_lobby_active = true
end

local function on_player_joined_game(event)	
	local surface = game.surfaces["biter_battles"]
	local player = game.players[event.player_index]	
	
	if player.gui.left["map_pregen"] then player.gui.left["map_pregen"].destroy() end
	
	if player.online_time == 0 then
		if surface.is_chunk_generated({0,0}) then
			player.teleport(surface.find_non_colliding_position("character", {0,0}, 3, 0.5), surface)
		else
			player.teleport({0,0}, surface)
		end
		player.character.destructible = false
		game.permissions.get_group("spectator").add_player(player)
	end
end

local function on_init(surface)
	if game.surfaces["biter_battles"] then return end
	init_surface()
	init_forces()
	
	global.bb_debug = false
end

event.on_init(on_init)
event.add(defines.events.on_player_joined_game, on_player_joined_game)

require "maps.biter_battles_v2.on_tick"
require "maps.biter_battles_v2.terrain"
require "maps.biter_battles_v2.no_turret_creep"
require "maps.biter_battles_v2.chat"
require "maps.biter_battles_v2.bb_map_intro"
require "modules.custom_death_messages"