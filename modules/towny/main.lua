local Town_center = require "modules.towny.town_center"
local Team = require "modules.towny.team"
local Connected_building = require "modules.towny.connected_building"
require "modules.global_chat_toggle"
--local Market = require "modules.towny.market"

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	
	if player.force.index ~= 1 then return end
	
	Team.set_player_to_homeless(player)	
	player.print("Towny is enabled!", {255, 255, 0})
	player.print("Place a stone furnace, to found a new town center. Or join a town by visiting another player's center.", {255, 255, 0})
	player.print("Or join a town by visiting another player's center.", {255, 255, 0})
	
	if player.online_time == 0 then
		Team.give_homeless_items(player)
		return
	end
	
	if not global.towny.requests[player.index] then return end
	if global.towny.requests[player.index] ~= "kill-character" then return end	
	if player.character then
		if player.character.valid then
			player.character.die()
		end
	end
	global.towny.requests[player.index] = nil
end

local function on_player_respawned(event)
	local player = game.players[event.player_index]	
	if player.force.index ~= 1 then return end
	Team.set_player_to_homeless(player)
	Team.give_homeless_items(player)
end

local function on_built_entity(event)
	if Town_center.found(event) then return end
	Connected_building.prevent_isolation(event)
end

local function on_robot_built_entity(event)
	Connected_building.prevent_isolation(event)
end

local function on_entity_died(event)	
	local entity = event.entity
	if entity.name == "market" then
		Team.kill_force(entity.force.name)
	end
end

local function on_entity_damaged(event)	
	local entity = event.entity
	if entity.name == "market" then
		Town_center.set_market_health(entity, event.final_damage_amount)
	end
end

local function on_player_repaired_entity(event)	
	local entity = event.entity
	if entity.name == "market" then
		Town_center.set_market_health(entity, -3)
	end
end

local function on_player_dropped_item(event)
	local player = game.players[event.player_index]
	local entity = event.entity
	if entity.stack.name == "raw-fish" then 
		Team.ally_town(player, entity)
		return
	end
	if entity.stack.name == "coal" then 
		Team.declare_war(player, entity)
		return
	end
end

local function on_init()
	global.towny = {}
	global.towny.requests = {}
	global.towny.town_centers = {}
	global.towny.size_of_town_centers = 0
	game.difficulty_settings.technology_price_multiplier = 0.5 
	
	local p = game.permissions.create_group("Homeless")
	for action_name, _ in pairs(defines.input_action) do
		p.set_allows_action(defines.input_action[action_name], false)
	end
	local defs = {
		defines.input_action.craft,
		defines.input_action.build_item,
		defines.input_action.cursor_split,	
		defines.input_action.cursor_transfer,
		defines.input_action.clean_cursor_stack,
		defines.input_action.drop_item,
		defines.input_action.begin_mining,
		defines.input_action.change_picking_state,
		defines.input_action.edit_permission_group,
		defines.input_action.gui_click,
		defines.input_action.gui_confirmed,
		defines.input_action.gui_elem_changed,
		defines.input_action.gui_location_changed,
		defines.input_action.gui_selected_tab_changed,
		defines.input_action.gui_selection_state_changed,
		defines.input_action.gui_switch_state_changed,
		defines.input_action.gui_text_changed,
		defines.input_action.gui_value_changed,
		defines.input_action.open_character_gui,
		defines.input_action.open_kills_gui,
		defines.input_action.start_walking,
		defines.input_action.toggle_show_entity_info,
		defines.input_action.write_to_console,
	}
	for _, d in pairs(defs) do p.set_allows_action(d, true) end
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
Event.add(defines.events.on_player_dropped_item, on_player_dropped_item)