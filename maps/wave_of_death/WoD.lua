-- Mapcodes made by MewMew, Idea and Map-painting by Kyte
-- Coding-Time by MewMew: 24.04.19 from 11am to 5pm = 6+ Hours !!

-- code for reading coordinates ingame: /silent-command game.players[1].print(game.player.selected.position)

require "maps.wave_of_death.intro"
local event = require 'utils.event'
local init = require "maps.wave_of_death.init"
local on_chunk_generated = require "maps.wave_of_death.terrain"
local ai = require "maps.wave_of_death.ai"

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	player.teleport({x = -32, y = 0}, player.surface)
	--local radius = 256
	--game.forces.player.chart(player.surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})
	
	
	init()
end

local function on_entity_died(event)
	if not event.entity.valid then return end
	ai.spawn_spread_wave(event)
end

local function on_player_rotated_entity(event)
	ai.trigger_new_wave(event)
end

local function on_tick(event)
	--if game.tick % 15 ~= 0 then return end
	
	--ai.send_wave_command()
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_rotated_entity, on_player_rotated_entity)
