---- WIP!

local event = require 'utils.event'

local healing_amount = {
		["rock-big"] = 4,
		["sand-rock-big"] = 4,
		["rock-huge"] = 16
	}
	
local function heal_rocks()
	for key, rock in pairs(global.damaged_rocks) do
		if rock.last_damage + 300 < game.tick then
			if rock.entity.valid then
				rock.entity.health = rock.entity.health + healing_amount[rock.entity.name]
				if rock.entity.prototype.max_health == rock.entity.health then global.damaged_rocks[key] = nil end
			else
				global.damaged_rocks[key] = nil
			end
		end
	end
end

local function on_entity_damaged(event)	
	if not event.entity.valid then return end
	if event.entity.type == "simple-entity" then
		
	end
end

event.add(defines.events.on_entity_damaged, on_entity_damaged)