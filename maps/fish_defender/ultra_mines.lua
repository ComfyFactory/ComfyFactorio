local event = require 'utils.event'

local function on_entity_died(event)
	if not global.ultra_mines_unlocked then return end
	if not event.entity.valid then return end
	if event.entity.name ~= "land-mine" then return end
	
	event.entity.surface.create_entity({	
		name = "artillery-projectile",
		position = event.entity.position,
		force = "player",
		source = event.entity.position,
		target = event.entity.position,
		max_range = 1, 
		speed = 1
	})
end

event.add(defines.events.on_entity_died, on_entity_died)


