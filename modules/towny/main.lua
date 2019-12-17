local found_town_center = require "modules.towny.found_town_center"

local function on_player_joined_game(event)
	local player = game.players[event.player_index]	
	if player.online_time == 0 then
		player.insert({name = "pistol", count = 1})
		player.insert({name = "firearm-magazine", count = 16})
		player.insert({name = "stone-furnace", count = 1})
	end	
end

local function on_built_entity(event)
	found_town_center(event)
end

local function on_init()
	global.towny = {}
	global.towny.town_centers = {}
	global.towny.size_of_town_centers = 0
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_built_entity, on_built_entity)