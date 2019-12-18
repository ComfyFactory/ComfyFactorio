local Combat_balance = require "modules.towny.combat_balance"
local Connected_building = require "modules.towny.connected_building"
local Market = require "modules.towny.market"
local Team = require "modules.towny.team"
local Town_center = require "modules.towny.town_center"
require "modules.global_chat_toggle"
require "modules.custom_death_messages"

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	Team.set_player_color(player)
	
	if player.force.index ~= 1 then return end
	
	Team.set_player_to_homeless(player)	
	player.print("Towny is enabled! To found your town, place down a stone furnace.", {255, 255, 0})
	player.print("To ally or settle with another player, drop a fish on their market or character. Coal yields the opposite result.", {255, 255, 0})
	
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

local function on_init()
	global.towny = {}
	global.towny.requests = {}
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
Event.add(defines.events.on_console_command, on_console_command)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
Event.add(defines.events.on_player_dropped_item, on_player_dropped_item)
Event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
Event.add(defines.events.on_gui_opened, on_gui_opened)