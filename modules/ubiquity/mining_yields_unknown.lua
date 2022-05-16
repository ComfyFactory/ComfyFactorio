local math_random = math.random
local unearthing_worm = require 'modules.ubiquity.unearthing_worm'
local unearthing_biters = require 'modules.ubiquity.unearthing_biters'
local tick_tack_trap = require 'modules.ubiquity.tick_tack_trap'
local treasure_chest = require 'modules.ubiquity.treasure_chest'

local rocks = {
	['rock-big'] = true,
	['rock-huge'] = true,
	['sand-rock-big'] = true,
	['underground-rock-rock-big'] = true,
	['underground-rock-rock-huge'] = true,
	['underground-rock-sand-rock-big'] = true,
	['underground-attack-rock'] = true
}

local function unknown(entity, evolution_factor)
	-- check if we are mining a rock
	local surface = entity.surface
	local position = entity.position
	if rocks[entity.name] then
		if math_random(1, 32) == 1 then
			unearthing_biters(surface, position, math_random(2, 8), evolution_factor)
		end
		if math_random(1,32) == 1 then
			treasure_chest(surface, position)
		end
		if math_random(1, 64) == 1 then
			tick_tack_trap(surface, position)
		end
		if math_random(1, 128) == 1 then
			unearthing_worm(surface, position, evolution_factor)
		end
	end
end

local function on_player_mined_entity(event)
	local player = game.players[event.player_index]
	local evolution_factor = player.force.evolution_factor
	local entity = event.entity
	if entity and entity.valid then
		unknown(entity, evolution_factor)
	end
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
