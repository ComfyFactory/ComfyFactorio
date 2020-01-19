--biters may revive depending of global.biter_reanimator["biter force index"]
--0 = no extra life
--0.25 = 25% chance for another life
--1.5 = 1 extra life + 50% chance of another life
--3 = 3 extra lifes

local math_random = math.random
local math_floor = math.floor
local math_sqrt = math.sqrt

local function reanimate(entity)
	local extra_lifes = global.biter_reanimator.units[entity.unit_number]
	
	if extra_lifes <= 0 then
		global.biter_reanimator.units[entity.unit_number] = nil
		return 
	end
	
	if extra_lifes < 1 then
		if math_random(1, 10000) > extra_lifes * 10000 then			
			global.biter_reanimator.units[entity.unit_number] = nil
			return		
		end
	end

	local revived_entity = entity.clone({position = entity.position, surface = entity.surface, force = entity.force})
	local unit_group = entity.unit_group
	if unit_group then unit_group.add_member(revived_entity) end
	
	global.biter_reanimator.units[revived_entity.unit_number] = extra_lifes - 1
	global.biter_reanimator.units[entity.unit_number] = nil
end

local function on_entity_died(event)	
	local entity = event.entity
	if not entity.valid then return end
	if entity.type ~= "unit" then return end
	
	if not global.biter_reanimator.units[entity.unit_number] then
		local extra_lifes = global.biter_reanimator.forces[entity.force.index]
		if not extra_lifes then return end
		if extra_lifes <= 0 then return end		
		global.biter_reanimator.units[entity.unit_number] = extra_lifes
	end
		
	reanimate(entity)
end

local function on_init()
	global.biter_reanimator = {}
	global.biter_reanimator.forces = {}
	global.biter_reanimator.units = {}
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_entity_died, on_entity_died)