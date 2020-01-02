-- Biter Battles v2 -- by MewMew

local Ai = require "maps.biter_battles_v2.ai"
local BiterHealthBooster = require "modules.biter_health_booster"
local Biters_landfill = require "maps.biter_battles_v2.biters_landfill"
local Chat = require "maps.biter_battles_v2.chat"
local Combat_balance = require "maps.biter_battles_v2.combat_balance"
local Game_over = require "maps.biter_battles_v2.game_over"
local Gui = require "maps.biter_battles_v2.gui"
local Init = require "maps.biter_battles_v2.init"
local Map_info = require "maps.biter_battles_v2.map_info"
local Mirror_terrain = require "maps.biter_battles_v2.mirror_terrain"
local No_turret_creep = require "maps.biter_battles_v2.no_turret_creep"
local Team_manager = require "maps.biter_battles_v2.team_manager"

require "on_tick_schedule"
require "maps.biter_battles_v2.map_settings_tab"
require "modules.spawners_contain_biters"
require "modules.mineable_wreckage_yields_scrap"

local function on_player_joined_game(event)
	local surface = game.surfaces["biter_battles"]
	local player = game.players[event.player_index]	

	if player.online_time == 0 then
		player.spectator = true
		player.force = game.forces.spectator
		if surface.is_chunk_generated({0,0}) then
			player.teleport(surface.find_non_colliding_position("character", {0,0}, 3, 0.5), surface)
		else
			player.teleport({0,0}, surface)
		end
		player.character.destructible = false
		game.permissions.get_group("spectator").add_player(player)
	end
	
	Map_info.player_joined_game(player)
	Team_manager.draw_top_toggle_button(player)
end

local function on_gui_click(event)
	local player = game.players[event.player_index]
	local element = event.element
	if not element then return end
	if not element.valid then return end
	
	if Map_info.gui_click(player, element) then return end
	Team_manager.gui_click(event)	
end

local function on_research_finished(event)
	Combat_balance.research_finished(event)
end

local function on_console_chat(event)
	Chat.share(event)
end

local function on_built_entity(event)
	No_turret_creep.deny_building(event)
end

local function on_robot_built_entity(event)
	No_turret_creep.deny_building(event)
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end	
	if Biters_landfill.entity_died(entity) then return end
	Game_over.silo_death(event)
end

local tick_minute_functions = {
	[300 * 1] = Ai.raise_evo,
	[300 * 2] = Ai.destroy_inactive_biters,
	[300 * 3] = Ai.main_attack,
	[300 * 4] = Ai.send_near_biters_to_silo,
	[300 * 5] = Ai.destroy_old_age_biters,
	[300 * 6] = Ai.wake_up_sleepy_groups,
	[300 * 7] = Game_over.restart_idle_map,
}

local function on_tick(event)
	Mirror_terrain()
	
	local tick = game.tick

	if tick % 60 ~= 0 then return end
	global.bb_threat["north_biters"] = global.bb_threat["north_biters"] + global.bb_threat_income["north_biters"]
	global.bb_threat["south_biters"] = global.bb_threat["south_biters"] + global.bb_threat_income["south_biters"]

	if tick % 180 == 0 then Gui.refresh() end

	if tick % 300 ~= 0 then return end
	Gui.spy_fish()
	if global.bb_game_won_by_team then
		Game_over.reveal_map()
		Game_over.server_restart()
		return
	end
	
	local key = tick % 3600
	if tick_minute_functions[key] then tick_minute_functions[key]() end
end

local function on_init()
	Init.settings()
	Init.surface()
	Init.forces()
	Team_manager.init()
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_console_chat, on_console_chat)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_tick, on_tick)

require "maps.biter_battles_v2.spec_spy"
require "maps.biter_battles_v2.terrain"
require "maps.biter_battles_v2.difficulty_vote"
require "modules.custom_death_messages"