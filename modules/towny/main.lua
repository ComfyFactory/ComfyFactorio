local Town_center = require "modules.towny.town_center"
local Team = require "modules.towny.team"
local Connected_building = require "modules.towny.connected_building"

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	
	if player.force.index == 1 then
		player.print("Towny is enabled on this server!", {255, 255, 0})
		player.print("Place a stone furnace, to found a new town center. Or join a town by visiting another player's center.", {255, 255, 0})
	end
	
	if player.online_time == 0 then	player.insert({name = "stone-furnace", count = 1}) end
end

local function on_player_respawned(event)
	local player = game.players[event.player_index]	
	if player.force.index ~= 1 then return end
	player.insert({name = "stone-furnace", count = 1})	
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

local function on_init()
	global.towny = {}
	global.towny.town_centers = {}
	global.towny.size_of_town_centers = 0
	game.difficulty_settings.technology_price_multiplier = 0.5 
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_entity_died, on_entity_died)