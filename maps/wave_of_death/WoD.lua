-- Mapcodes made by MewMew, Idea and Map-painting by Kyte
-- Coding-Time by MewMew: 24.04.19 from 11am to 5pm = 6+ Hours !!

-- code for reading coordinates ingame: /silent-command game.players[1].print(game.player.selected.position)

require "maps.wave_of_death.intro"
require "modules.biter_evasion_hp_increaser"
local event = require 'utils.event'
local init = require "maps.wave_of_death.init"
local on_chunk_generated = require "maps.wave_of_death.terrain"
local ai = require "maps.wave_of_death.ai"

local function autojoin_lane(player)
	local lowest_player_count = 256
	local lane_number = 1
	for i = 1, 4, 1 do
		if #game.forces[i].connected_players < lowest_player_count then
			lowest_player_count = #game.forces[i].connected_players
			lane_number = i
		end
	end
	player.force = game.forces[lane_number]
	player.teleport(game.forces[player.force.name].get_spawn_position(game.surfaces["wave_of_death"]), game.surfaces["wave_of_death"])
	player.insert({name = "pistol", count = 1})
	player.insert({name = "firearm-magazine", count = 16})
	player.insert({name = "submachine-gun", count = 1})
	player.insert({name = "uranium-rounds-magazine", count = 128})
end

local function on_player_joined_game(event)
	init()
	
	local player = game.players[event.player_index]
	autojoin_lane(player)	
end

local function on_entity_damaged(event)
	ai.prevent_friendly_fire(event)
end

local function on_entity_died(event)
	if not event.entity.valid then return end
	ai.spawn_spread_wave(event)
end

local function on_player_rotated_entity(event)
	ai.trigger_new_wave(event)
end

local function on_tick(event)
	if game.tick % 300 ~= 0 then return end
	
	for i = 1, 4, 1 do
		game.forces[i].chart(game.surfaces["wave_of_death"], {{-320, -384}, {320, 96}})
	end
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_rotated_entity, on_player_rotated_entity)
