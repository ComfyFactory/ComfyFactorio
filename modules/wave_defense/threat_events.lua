local threat_values = require "modules.wave_defense.threat_values"
local math_random = math.random

local function remove_unit(entity)
	if not global.wave_defense.active_biters[entity.unit_number] then return end
	global.wave_defense.active_biter_threat = global.wave_defense.active_biter_threat - math.round(threat_values[entity.name] * global.biter_health_boost, 2)
	global.wave_defense.active_biter_count = global.wave_defense.active_biter_count - 1
	global.wave_defense.active_biters[entity.unit_number] = nil
end

function build_nest()
	if global.wave_defense.threat < 1000 then return end
	if math_random(1, global.wave_defense.nest_building_chance) ~= 1 then return end
	if #global.wave_defense.unit_groups == 0 then return end
	local group = global.wave_defense.unit_groups[math_random(1, #global.wave_defense.unit_groups)]
	if not group then return end
	if not group.valid then return end
	if not group.members then return end
	if not group.members[1] then return end
	local unit = group.members[math_random(1, #group.members)]
	if not unit.valid then return end	
	local position = unit.surface.find_non_colliding_position("biter-spawner", unit.position, 16, 1)
	if not position then return end
	local r = global.wave_defense.nest_building_density	
	if unit.surface.count_entities_filtered({type = "unit-spawner", area = {{position.x - r, position.y - r},{position.x + r, position.y + r}}}) > 0 then return end
	unit.surface.create_entity({name = "biter-spawner", position = position, force = unit.force})
	unit.surface.create_entity({name = "blood-explosion-huge", position = position})
	unit.surface.create_entity({name = "blood-explosion-huge", position = unit.position})
	remove_unit(unit)
	unit.destroy()
	global.wave_defense.threat = global.wave_defense.threat - 500
end

function build_worm()
	if global.wave_defense.threat < 1000 then return end
	if math_random(1, global.wave_defense.worm_building_chance) ~= 1 then return end
	if #global.wave_defense.unit_groups == 0 then return end
	local group = global.wave_defense.unit_groups[math_random(1, #global.wave_defense.unit_groups)]
	if not group then return end
	if not group.valid then return end
	if not group.members then return end
	if not group.members[1] then return end
	local unit = group.members[math_random(1, #group.members)]
	if not unit.valid then return end
	wave_defense_set_worm_raffle(global.wave_defense.wave_number)
	local worm = wave_defense_roll_worm_name()
	local position = unit.surface.find_non_colliding_position("assembling-machine-1", unit.position, 8, 1)
	if not position then return end
	local r = global.wave_defense.worm_building_density
	if unit.surface.count_entities_filtered({type = "turret", area = {{position.x - r, position.y - r},{position.x + r, position.y + r}}}) > 0 then return end
	unit.surface.create_entity({name = worm, position = position, force = unit.force})
	unit.surface.create_entity({name = "blood-explosion-huge", position = position})
	unit.surface.create_entity({name = "blood-explosion-huge", position = unit.position})
	remove_unit(unit)
	unit.destroy()
	global.wave_defense.threat = global.wave_defense.threat - threat_values[worm]
end

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
	if global.wave_defense.threat < 100000 then return end
	if math_random(1, 16) ~= 1 then return end	
	for _ = 1, acid_nova_entities[entity.name].amount, 1 do
		local i = math_random(1, #acid_nova_entities[entity.name].vectors)		
		entity.surface.create_entity({	
			name = acid_nova_entities[entity.name].projectile,
			position = entity.position,
			force = entity.force.name,
			source = entity.position,
			target = {x = entity.position.x + acid_nova_entities[entity.name].vectors[i][1], y = entity.position.y + acid_nova_entities[entity.name].vectors[i][2]},
			max_range = 10, 
			speed = 0.001
		})
	end	
	global.wave_defense.threat = global.wave_defense.threat - acid_nova_entities[entity.name].threat_cost	
	return true
end

local function shred_simple_entities(entity)
	if global.wave_defense.threat < 25000 then return end
	local simple_entities = entity.surface.find_entities_filtered({type = "simple-entity", area = {{entity.position.x - 3, entity.position.y - 3},{entity.position.x + 3, entity.position.y + 3}}})
	if #simple_entities == 0 then return end
	if #simple_entities > 1 then table.shuffle_table(simple_entities) end	
	local r = math.floor(global.wave_defense.threat * 0.00004)
	if r < 1 then r = 1 end
	local count = math.random(1, r)
	--local count = 1
	local damage_dealt = 0
	for i = 1, count, 1 do
		if not simple_entities[i] then break end
		if simple_entities[i].valid then
			if simple_entities[i].health then
				damage_dealt = damage_dealt + simple_entities[i].health
				simple_entities[i].die("neutral", simple_entities[i])
			end
		end
	end
	if damage_dealt == 0 then return end
	local threat_cost = math.floor(damage_dealt * global.wave_defense.simple_entity_shredding_cost_modifier)
	if threat_cost < 1 then threat_cost = 1 end
	global.wave_defense.threat = global.wave_defense.threat - threat_cost
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then	return end
	
	if entity.type == "unit" then
		global.wave_defense.threat = math.round(global.wave_defense.threat - threat_values[entity.name] * global.biter_health_boost, 2)
		remove_unit(entity)
		acid_nova(entity)
	else
		if entity.force.index == 2 then	
			if entity.health then
				if threat_values[entity.name] then
					global.wave_defense.threat = global.wave_defense.threat - threat_values[entity.name]
				end
			end
		end
	end

	if entity.force.index == 3 then
		if event.cause then
			if event.cause.valid then
				if event.cause.force.index == 2 then
					shred_simple_entities(entity)
				end
			end
		end
	end
end

local event = require 'utils.event'
event.add(defines.events.on_entity_died, on_entity_died)