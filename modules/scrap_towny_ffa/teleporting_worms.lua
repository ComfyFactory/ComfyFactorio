-- worms will teleport to where they shoot -- by mewmew
local math_random = math.random

local function on_entity_damaged(event)
	local entity = event.entity
	if not entity or not entity.valid then
		return
	end
	if entity.type ~= 'turret' then
		return
	end
	local surface = entity.surface
	local damager = event.cause
	if not damager or not damager.valid then
		return
	end
	if damager.name ~= 'character' and damager.name ~= 'tank' and damager.name ~= 'car' then
		return
	end
	if math_random(1, 5) ~= 1 then
		return
	end
	local delta = {
		x = (entity.position.x - damager.position.x) * 0.5,
		y = (entity.position.y - damager.position.y) * 0.5
	}
	if delta.x ^ 2 + delta.y ^ 2 < 25 then
		return
	end
	local target = {
		x = (entity.position.x - delta.x),
		y = (entity.position.y - delta.y)
	}

	local position = surface.find_non_colliding_position(entity.prototype.name, target, 48, 0.5)
	if position then
		local worm = surface.create_entity({name = entity.name, force = entity.force, position = position})
		entity.surface.create_entity({name = 'blood-explosion-big', position = target})
		entity.surface.create_entity({name = 'blood-explosion-big', position = entity.position})
		worm.health = entity.health
		entity.destroy()
	end
end

local Event = require 'utils.event'

Event.add(defines.events.on_entity_damaged, on_entity_damaged)

