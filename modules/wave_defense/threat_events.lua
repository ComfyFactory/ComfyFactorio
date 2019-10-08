local threat_values = require "modules.wave_defense.threat_values"
local math_random = math.random

local function get_circle_vectors(radius)
	local vectors = {}
	for x = radius * -1, radius, 1 do
		for y = radius * -1, radius, 1 do
			if math.sqrt(x^2 + y^2) <= radius then
				vectors[#vectors + 1] = {x, y}
			end
		end
	end
	return vectors
end

local acid_nova_entities = {
	["small-biter"] = {projectile = "acid-stream-worm-small", vectors = get_circle_vectors(3), amount = 8, threat_cost = 32},
	["medium-biter"] = {projectile = "acid-stream-worm-medium", vectors = get_circle_vectors(4), amount = 8, threat_cost = 64},
	["big-biter"] = {projectile = "acid-stream-worm-big", vectors = get_circle_vectors(5), amount = 8, threat_cost = 96},
	["behemoth-biter"] = {projectile = "acid-stream-worm-behemoth", vectors = get_circle_vectors(6), amount = 8, threat_cost = 128},
}

local function acid_nova(entity)
	if not acid_nova_entities[entity.name] then return end
	if global.wave_defense.threat < 10000 then return end
	if math_random(1, 32) ~= 1 then return end	
	for _ = 1, acid_nova_entities[entity.name].amount, 1 do
		local i = math.random(1, #acid_nova_entities[entity.name].vectors)		
		entity.surface.create_entity({	
			name = acid_nova_entities[entity.name].projectile,
			position = entity.position,
			force = entity.force.name,
			source = entity.position,
			target = {x = entity.position.x + acid_nova_entities[entity.name].vectors[i][1], y = entity.position.y + acid_nova_entities[entity.name].vectors[i][2]},
			max_range = radius, 
			speed = 0.001
		})
	end	
	global.wave_defense.threat = global.wave_defense.threat - acid_nova_entities[entity.name].threat_cost	
	return true
end

local function on_entity_died(event)
	if not event.entity.valid then	return end
	if event.entity.type ~= "unit" then return end
	if not global.wave_defense.active_biters[event.entity.unit_number] then return end
	global.wave_defense.active_biters[event.entity.unit_number] = nil
	global.wave_defense.active_biter_count = global.wave_defense.active_biter_count - 1

	if acid_nova(event.entity) then return end
end

local event = require 'utils.event'
event.add(defines.events.on_entity_died, on_entity_died)