-- biters explode --  by mewmew

local event = require 'utils.event'

local biter_values = {
		["medium-biter"] = {"blood-explosion-big", 15, 1},
		["big-biter"] = {"blood-explosion-huge", 30, 1.5},
		["behemoth-biter"] = {"blood-explosion-huge", 45, 2}
	}

local function damage_entities_in_radius(surface, position, radius, damage)
	local entities_to_damage = surface.find_entities_filtered({area = {{position.x - radius, position.y - radius},{position.x + radius, position.y + radius}}})
	for _, entity in pairs(entities_to_damage) do
		if entity.health and entity.name ~= "land-mine" then
			if entity.force.name ~= "enemy" then
				if entity.name == "player" then
					entity.damage(damage, "enemy")
				else
					entity.health = entity.health - damage
					entity.surface.create_entity({name = "blood-explosion-big", position = entity.position})
					if entity.health <= 0 then entity.die("enemy") end
				end
			end
		end
	end
end
	
local function on_entity_died(event)	
	if biter_values[event.entity.name] then
		local entity = event.entity
		entity.surface.create_entity({name = biter_values[entity.name][1], position = entity.position})
		damage_entities_in_radius(entity.surface, entity.position, biter_values[entity.name][3], biter_values[entity.name][2])		
	end
end
	
event.add(defines.events.on_entity_died, on_entity_died)
