local Biters = require "modules.towny.biters"
local Combat_balance = require "modules.towny.combat_balance"
local Connected_building = require "modules.towny.connected_building"
local Info = require "modules.towny.info"
local Market = require "modules.towny.market"
local Team = require "modules.towny.team"
local Town_center = require "modules.towny.town_center"
require "modules.global_chat_toggle"
require "modules.custom_death_messages"

local function on_player_joined_game(event)
	local player = game.players[event.player_index]	
	Info.show(player)
	
	Team.set_player_color(player)
	
	if player.force.index ~= 1 then return end
	
	Team.set_player_to_homeless(player)	
	
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

local function on_player_used_capsule(event)
	Combat_balance.fish(event)
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
		Town_center.set_market_health(entity, -4)
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

local function on_console_command(event)
	Team.set_town_color(event)
end

local function on_market_item_purchased(event)
	Market.offer_purchased(event)
	Market.refresh_offers(event)
end

local function on_gui_opened(event)
	Market.refresh_offers(event)
end

local function on_gui_click(event)
	Info.close(event)
end

local function on_research_finished(event)
	local town_center = global.towny.town_centers[event.research.force.name]
	if not town_center then return end
	town_center.research_counter = town_center.research_counter + 1
end

local function on_player_died(event)
	local player = game.players[event.player_index]
	if not player.character then return end
	if not player.character.valid then return end
	Team.reveal_entity_to_all(player.character)
end

local minute_actions = {
	[60 * 5] = Team.update_town_chart_tags,
	[60 * 10] = Team.set_all_player_colors,
	[60 * 15] = Biters.swarm,
	[60 * 20] = Biters.set_evolution,
}

local function on_nth_tick(event)
	local tick = game.tick % 3600	
	if not minute_actions[tick] then return end 
	minute_actions[tick]()
end

local function on_init()
	global.towny = {}
	global.towny.requests = {}
	global.towny.request_cooldowns = {}
	global.towny.town_centers = {}
	global.towny.cooldowns = {}
	global.towny.size_of_town_centers = 0
	game.difficulty_settings.technology_price_multiplier = 0.25 
	
	local p = game.permissions.create_group("Homeless")
	for action_name, _ in pairs(defines.input_action) do
		p.set_allows_action(defines.input_action[action_name], true)
	end
	local defs = {
		defines.input_action.craft,
		defines.input_action.deconstruct,
		defines.input_action.start_research,
		defines.input_action.open_technology_gui,
	}
	for _, d in pairs(defs) do p.set_allows_action(d, false) end
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.on_nth_tick(60, on_nth_tick)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_console_command, on_console_command)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_player_dropped_item, on_player_dropped_item)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)