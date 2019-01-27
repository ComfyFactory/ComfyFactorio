-- sushi mode WIP -- this will make full belts without a valid output overflow and spill their items

local event = require 'utils.event'

local valid_types = {
		["underground-belt"] = true,
		["splitter"] = true,
		["transport-belt"] = true,
	}

local function process_belt(entity)
	
end
	
local function on_built_entity(event)
	if not global.sushi then global.sushi = {} end
	if valid_types[event.entity.type] then
		global.sushi[tostring(event.entity.position.x) .. "," .. tostring(event.entity.position.y)] = event.entity
	end
end

local function on_player_mined_entity(event)
	if valid_types[event.entity.type] then
		local area = {{event.entity.position.x - 2, event.entity.position.y - 2},{event.entity.position.x + 2, event.entity.position.y + 2}}
		local entities = event.entity.surface.find_entities_filtered({area = area, type = valid_types})		
		for _, e in pairs(entities) do
			global.sushi[tostring(e.position.x) .. "," .. tostring(e.position.y)] = e
		end
	end
end

local function on_robot_mined_entity(event)	
	on_player_mined_entity(event)
end

local function on_tick(event)	
	if not global.sushi then return end
	for _, sushi in pairs(global.sushi) do
		process_belt(sushi)
	end
end

event.add(defines.events.on_tick, on_tick)	
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_robot_mined_entity, on_robot_mined_entity)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
