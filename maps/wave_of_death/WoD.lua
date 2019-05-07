-- Map by Kyte & MewMew

require "maps.wave_of_death.intro"
require "modules.biter_evasion_hp_increaser"
local event = require 'utils.event'
local init = require "maps.wave_of_death.init"
local on_chunk_generated = require "maps.wave_of_death.terrain"
local ai = require "maps.wave_of_death.ai"
local game_status = require "maps.wave_of_death.game_status"

function soft_teleport(player, destination)
	local surface = game.surfaces["wave_of_death"]
	local pos = surface.find_non_colliding_position("character", destination, 8, 0.5)
	if not pos then player.teleport(destination, surface) end
	player.teleport(pos, surface)
end

local function autojoin_lane(player)
	local lowest_player_count = 256
	local lane_number = 1
	for i = 1, 4, 1 do
		if #game.forces[i].connected_players < lowest_player_count and global.wod_lane[i].game_lost == false then
			lowest_player_count = #game.forces[i].connected_players
			lane_number = i
		end
	end
	player.force = game.forces[lane_number]
	soft_teleport(player, game.forces[player.force.name].get_spawn_position(game.surfaces["wave_of_death"]))
	player.insert({name = "pistol", count = 1})
	player.insert({name = "firearm-magazine", count = 16})
	player.insert({name = "iron-plate", count = 128})
	player.insert({name = "iron-gear-wheel", count = 32})
end

local function on_player_joined_game(event)
	init()
	
	local player = game.players[event.player_index]
	if player.online_time == 0 then autojoin_lane(player) return end
	
	if global.wod_lane[tonumber(player.force.name)].game_lost == true then
		player.character.die()
	end
end

local function on_entity_damaged(event)
	ai.prevent_friendly_fire(event)
end

local function on_entity_died(event)
	if not event.entity.valid then return end
	ai.spawn_spread_wave(event)
	game_status.has_lane_lost(event)
end

local function on_player_rotated_entity(event)
	ai.trigger_new_wave(event)
end

local function on_tick(event)
	if game.tick % 300 ~= 0 then return end
	
	for i = 1, 4, 1 do
		game.forces[i].chart(game.surfaces["wave_of_death"], {{-288, -420}, {352, 32}})
	end
	
	game_status.restart_server()
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_rotated_entity, on_player_rotated_entity)
