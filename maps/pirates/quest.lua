
local Memory = require 'maps.pirates.memory'
local Roles = require 'maps.pirates.roles.roles'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local Math = require 'maps.pirates.math'
local Loot = require 'maps.pirates.loot'
local inspect = require 'utils.inspect'.inspect


local Public = {}

local enum = {
	TIME = 'Time',
	FIND = 'Find',
	NODAMAGE = 'No_Damage',
	RESOURCEFLOW = 'Resource_Flow',
	RESOURCECOUNT = 'Resource_Count',
	WORMS = 'Worms',
} 
Public.enum = enum

Public.quest_icons = {
	[enum.TIME] = '[img=utility.time_editor_icon]',
	[enum.NODAMAGE] = '[item=stone-wall]',
	[enum.WORMS] = '[entity=small-worm-turret]',
	[enum.FIND] = '[img=utility.ghost_time_to_live_modifier_icon]',
	[enum.RESOURCEFLOW] = '',
	[enum.RESOURCECOUNT] = '',
}



function Public.quest_reward()
	local ret
	local multiplier = Balance.quest_reward_multiplier()
	local rng = Math.random()

	if rng <= 0.3 then
		ret = {name = 'iron-plate', count = Math.ceil(2000 * multiplier), display_sprite = '[item=iron-plate]', display_amount = string.format('%.0fk', 2 * multiplier)}
	elseif rng <= 0.5 then
		ret = {name = 'copper-plate', count = Math.ceil(2000 * multiplier), display_sprite = '[item=copper-plate]', display_amount = string.format('%.0fk', 2 * multiplier)}
	elseif rng <= 0.7 then
		ret = {name = 'solid-fuel', count = Math.ceil(450 * multiplier), display_sprite = '[item=solid-fuel]', display_amount = string.format('%.0f', Math.ceil(450 * multiplier))}
	elseif rng <= 0.9 then
		ret = {name = 'coin', count = Math.ceil(6000 * (multiplier^(1/2))), display_sprite = '[item=coin]', display_amount = string.format('%.0fk', Math.ceil(6 * (multiplier^(1/2))))}
	else
		ret = {name = 'piercing-rounds-magazine', count = Math.ceil(250 * multiplier), display_sprite = '[item=piercing-rounds-magazine]', display_amount = string.format('%.0f', Math.ceil(250 * multiplier))}
	end

	return ret
end




function Public.initialise_random_quest()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	destination.dynamic_data.quest_complete = false

	if destination.destination_index == 2 then return end

	local rng = Math.random(10)
	if rng == 1 then
		Public.initialise_nodamage_quest()
	elseif rng <= 3 then
		Public.initialise_worms_quest()
	elseif rng <= 5 then
		Public.initialise_time_quest()
	elseif rng <= 7 then
		Public.initialise_find_quest()
	elseif rng <= 10 then
		Public.initialise_resourcecount_quest()
		-- Public.initialise_resourceflow_quest()
	end

	-- Public.initialise_time_quest()
end






function Public.initialise_time_quest()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	destination.dynamic_data.quest_type = enum.TIME
	destination.dynamic_data.quest_reward = Public.quest_reward()
	destination.dynamic_data.quest_progress = Balance.time_quest_seconds()
	destination.dynamic_data.quest_progressneeded = 9999999
	
	return true
end

function Public.initialise_find_quest()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	-- @FIXME: Magic numbers
	if destination.subtype and destination.subtype == '1' or destination.subtype == '5' or destination.subtype == '6' then

		destination.dynamic_data.quest_type = enum.FIND
		destination.dynamic_data.quest_reward = Public.quest_reward()
		destination.dynamic_data.quest_progress = 0
		if #Common.crew_get_crew_members() > 15 then
			destination.dynamic_data.quest_progressneeded = 2
		else
			destination.dynamic_data.quest_progressneeded = 1
		end
		return true
	else
		Public.initialise_random_quest() --@FIXME: mild danger of loop
		return false
	end
end


function Public.initialise_nodamage_quest()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	if not destination and destination.dynamic_data and destination.dynamic_data.rocketsilomaxhp then return end

	destination.dynamic_data.quest_type = enum.NODAMAGE
	destination.dynamic_data.quest_reward = Public.quest_reward()
	destination.dynamic_data.quest_progress = 0
	destination.dynamic_data.quest_progressneeded = destination.dynamic_data.rocketsilomaxhp
	
	return true
end


function Public.initialise_resourceflow_quest()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	if not destination and destination.dynamic_data and destination.dynamic_data.rocketsilomaxhp then return end

	destination.dynamic_data.quest_type = enum.RESOURCEFLOW
	destination.dynamic_data.quest_reward = Public.quest_reward()
	destination.dynamic_data.quest_progress = 0

	local generated_flow_quest = Public.generate_flow_quest()
	destination.dynamic_data.quest_params = {item = generated_flow_quest.item}

	local progressneeded_before_rounding = generated_flow_quest.base_rate * Balance.resource_quest_multiplier()

	destination.dynamic_data.quest_progressneeded = Math.ceil(progressneeded_before_rounding/10)*10
	
	return true
end


function Public.initialise_resourcecount_quest()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	if not destination and destination.dynamic_data and destination.dynamic_data.rocketsilomaxhp then return end

	destination.dynamic_data.quest_type = enum.RESOURCECOUNT
	destination.dynamic_data.quest_reward = Public.quest_reward()
	destination.dynamic_data.quest_progress = 0

	local generated_production_quest = Public.generate_resourcecount_quest()
	destination.dynamic_data.quest_params = {item = generated_production_quest.item}

	local force = memory.force
	if force and force.valid then
		destination.dynamic_data.quest_params.initial_count = force.item_production_statistics.get_flow_count{name = generated_production_quest.item, input = true, precision_index = defines.flow_precision_index.one_thousand_hours, count = true}
	end

	local progressneeded_before_rounding = generated_production_quest.base_rate * Balance.resource_quest_multiplier() * Common.difficulty()

	destination.dynamic_data.quest_progressneeded = Math.ceil(progressneeded_before_rounding/10)*10
	
	return true
end


function Public.initialise_worms_quest()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	if not (destination.surface_name and game.surfaces[destination.surface_name]) then return end

	local surface = game.surfaces[destination.surface_name]

	local worms = surface.find_entities_filtered{type = 'turret'}

	local count = 0
	for i = 1, #worms do
		local w = worms[i]
		if w.destructible then count = count + 1 end
	end

	local needed = Math.ceil(
		1 + 9 * Math.slopefromto(count, 0, 20) + 10 * Math.slopefromto(count, 20, 70)
	)

	if  Common.difficulty() < 1 then needed = Math.max(1, needed - 3) end
	if  Common.difficulty() > 1 then needed = Math.max(1, needed + 2) end

	if needed >= 5 then
		destination.dynamic_data.quest_type = enum.WORMS
		destination.dynamic_data.quest_reward = Public.quest_reward()
		destination.dynamic_data.quest_progress = 0
		destination.dynamic_data.quest_progressneeded = needed
		return true
	else
		Public.initialise_random_quest() --@FIXME: mild danger of loop
		return false
	end
end



function Public.try_resolve_quest()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	if destination.dynamic_data.quest_type and destination.dynamic_data.quest_progress and destination.dynamic_data.quest_progressneeded and destination.dynamic_data.quest_progress >= destination.dynamic_data.quest_progressneeded and (not destination.dynamic_data.quest_complete) then

		local force = memory.force
		if not (force and force.valid) then return end
		Common.notify_force_light(force,'Granted ' .. destination.dynamic_data.quest_reward.display_amount .. ' ' .. destination.dynamic_data.quest_reward.display_sprite)

		local name = destination.dynamic_data.quest_reward.name
		local count = destination.dynamic_data.quest_reward.count

		-- destination.dynamic_data.quest_type = nil
		-- destination.dynamic_data.quest_reward = nil
		-- destination.dynamic_data.quest_progress = nil
		-- destination.dynamic_data.quest_progressneeded = nil
		destination.dynamic_data.quest_complete = true

		local boat = memory.boat
		if not boat then return end
		local surface_name = boat.surface_name
		if not surface_name then return end
		local surface = game.surfaces[surface_name]
		if not (surface and surface.valid) then return end
		local chest = boat.output_chest
		if not chest and chest.valid then return end

		local inventory = chest.get_inventory(defines.inventory.chest)
		local inserted = inventory.insert{name = name, count = count}
		
		if inserted < count then
			Common.notify_force(force,'There wasn\'t space in the cabin for all of your reward.')
		end
	end
end





-- Public.flow_quest_data_raw = {
-- 	{0.2, 0, 1, false, 'submachine-gun', 3 * 12},
-- 	{1, 0, 1, false, 'electronic-circuit', 3 * 120},
-- 	{0.2, 0.1, 1, false, 'big-electric-pole', 1 * 120},
-- 	{0.4, 0.2, 1, false, 'engine-unit', 3 * 6},
-- 	-- {1, 0.5, 1, false, 'advanced-circuit', 1 * 10},
-- 	-- {0.3, 0.8, 1, false, 'electric-engine-unit', 1 * 6},
-- }

-- function Public.flow_quest_data()
-- 	local ret = {}
-- 	local data = Public.flow_quest_data_raw
-- 	for i = 1, #data do
-- 		local datum = data[i]
-- 		ret[#ret + 1] = {
--             weight = datum[1],
--             game_completion_progress_min = datum[2],
--             game_completion_progress_max = datum[3],
--             scaling = datum[4],
--             item = datum[5],
-- 			base_rate = datum[6],
--         }
-- 	end
-- 	return ret
-- end

function Public.generate_flow_quest()
	local memory = Memory.get_crew_memory()
	local game_completion_progress = Common.game_completion_progress_capped()

	local data = Public.flow_quest_data()
    local v, w = {}, {}

    for i = 1, #data, 1 do
        table.insert(v, {item = data[i].item, base_rate = data[i].base_rate})

		local destination = Common.current_destination()
		if not (destination and destination.subtype and data[i].map_subtype and data[i].map_subtype == destination.subtype) then
			if data[i].scaling then -- scale down weights away from the midpoint 'peak' (without changing the mean)
				local midpoint = (data[i].game_completion_progress_max + data[i].game_completion_progress_min) / 2
				local difference = (data[i].game_completion_progress_max - data[i].game_completion_progress_min)
				table.insert(w, data[i].weight * Math.max(0, 1 - (Math.abs(game_completion_progress - midpoint) / (difference / 2))))
			else -- no scaling
				if data[i].game_completion_progress_min <= game_completion_progress and data[i].game_completion_progress_max >= game_completion_progress then
					table.insert(w, data[i].weight)
				else
					table.insert(w, 0)
				end
			end
		end
    end

	return Math.raffle(v, w)
end





Public.resourcecount_quest_data_raw = {
	{0.8, 0, 1, false, 'iron-gear-wheel', 2400},
	{1, 0, 1, false, 'electronic-circuit', 1400},
	{1, 0, 1, false, 'transport-belt', 1600},
	-- {0.1, 0, 1, false, 'red-wire', 500},
	{0.4, 0, 1, false, 'empty-barrel', 600},
	{0.2, 0, 0.2, false, 'underground-belt', 200},
	{0.2, 0, 0.2, false, 'splitter', 150},
	{0.3, 0.2, 1, false, 'fast-splitter', 60},
	{0.3, 0.2, 1, false, 'fast-underground-belt', 75},
	{0.4, 0.3, 1, false, 'big-electric-pole', 160},
	{1, 0.61, 1, false, 'advanced-circuit', 350},
	{3, 0, 1, false, 'shotgun-shell', 600},
	-- {0.3, 0.8, 1, false, 'electric-engine-unit', 1 * 6},
}

function Public.resourcecount_quest_data()
	local ret = {}
	local data = Public.resourcecount_quest_data_raw
	for i = 1, #data do
		local datum = data[i]
		ret[#ret + 1] = {
            weight = datum[1],
            game_completion_progress_min = datum[2],
            game_completion_progress_max = datum[3],
            scaling = datum[4],
            item = datum[5],
			base_rate = datum[6],
        }
	end
	return ret
end

function Public.generate_resourcecount_quest()
	local memory = Memory.get_crew_memory()
	local game_completion_progress = Common.game_completion_progress_capped()

	local data = Public.resourcecount_quest_data()
    local v, w = {}, {}

    for i = 1, #data, 1 do
        table.insert(v, {item = data[i].item, base_rate = data[i].base_rate})

		local destination = Common.current_destination()
		if not (destination and destination.subtype and data[i].map_subtype and data[i].map_subtype == destination.subtype) then
			if data[i].scaling then -- scale down weights away from the midpoint 'peak' (without changing the mean)
				local midpoint = (data[i].game_completion_progress_max + data[i].game_completion_progress_min) / 2
				local difference = (data[i].game_completion_progress_max - data[i].game_completion_progress_min)
				table.insert(w, data[i].weight * Math.max(0, 1 - (Math.abs(game_completion_progress - midpoint) / (difference / 2))))
			else -- no scaling
				if data[i].game_completion_progress_min <= game_completion_progress and data[i].game_completion_progress_max >= game_completion_progress then
					table.insert(w, data[i].weight)
				else
					table.insert(w, 0)
				end
			end
		end
    end

	return Math.raffle(v, w)
end





return Public