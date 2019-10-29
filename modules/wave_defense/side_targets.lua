local WD = require "modules.wave_defense.table"
local Public = {}
local side_target_types = {
	["assembling-machine"] = true,
	["accumulator"] = true,
	["boiler"] = true,
	["furnace"] = true,
	["lab"] = true,
	["mining-drill"] = true,
	["radar"] = true,
	["reactor"] = true,
	["roboport"] = true,
	["rocket-silo"] = true,
	["solar-panel"] = true,
}

local function get_random_target(wave_defense_table)	
	local r = math.random(1, #wave_defense_table.side_targets)
	if not wave_defense_table.side_targets[r] then table.remove(wave_defense_table.side_targets, r) return end
	if not wave_defense_table.side_targets[r].valid then table.remove(wave_defense_table.side_targets, r) return end
	return wave_defense_table.side_targets[r]	
end

function Public.get_side_target()
	local wave_defense_table = WD.get_table()
	for _ = 1, 1024, 1 do
		if #wave_defense_table.side_targets == 0 then return false end
		local target = get_random_target(wave_defense_table)
		if target then return target end
	end
end

local function add_entity(entity)
	local wave_defense_table = WD.get_table()
	table.insert(wave_defense_table.side_targets, entity)
end

local function on_built_entity(event)
	if not side_target_types[event.created_entity.type] then return end
	add_entity(event.created_entity)
end

local function on_robot_built_entity(event)
	if not side_target_types[event.created_entity.type] then return end
	add_entity(event.created_entity)
end

local event = require 'utils.event'
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)

return Public