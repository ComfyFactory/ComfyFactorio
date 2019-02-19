-- rocks heal over time -- by mewmew

local event = require 'utils.event'

local healing_amount = {
		["rock-big"] = 4,
		["sand-rock-big"] = 4,
		["rock-huge"] = 16
	}
	
local function heal_rocks()
	for key, rock in pairs(global.damaged_rocks) do
		if rock.last_damage + 54000 < game.tick then
			if rock.entity then
				if rock.entity.valid then
					rock.entity.health = rock.entity.health + healing_amount[rock.entity.name]
					if rock.entity.prototype.max_health == rock.entity.health then
						global.damaged_rocks[key] = nil
					end
				else
					global.damaged_rocks[key] = nil
				end
			else
				global.damaged_rocks[key] = nil
			end
		end
	end
end

local function on_entity_damaged(event)
	if not event.entity.valid then return end
	if not healing_amount[event.entity.name] then return end
	global.damaged_rocks[tostring(event.entity.position.x) .. tostring(event.entity.position.y)] = {last_damage = game.tick, entity = event.entity}		
end

local function on_player_joined_game(event)
	if not global.damaged_rocks then global.damaged_rocks = {} end	
end

local function on_tick(event)
	if game.tick % 3600 ~= 1 then return end
	heal_rocks()
end
	
event.add(defines.events.on_tick, on_tick)	
event.add(defines.events.on_player_joined_game, on_player_joined_game)	
event.add(defines.events.on_entity_damaged, on_entity_damaged)