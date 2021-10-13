
local Balance = require 'maps.pirates.balance'
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local CoreData = require 'maps.pirates.coredata'
local inspect = require 'utils.inspect'.inspect
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local simplex_noise = require 'utils.simplex_noise'.d2
local Public = {}






function Public.try_ore_spawn(surface, realp, source_name, density_bonus)
	density_bonus = density_bonus or 0
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local choices = destination.dynamic_data.hidden_ore_remaining_abstract

	if choices and Utils.length(choices) > 0 then
		local choices_possible = {}
		local choices_to_prioitise = {}

		for k, v in pairs(choices) do
			if v>0 then choices_possible[k] = v end

			if (not destination.dynamic_data.ore_types_spawned[k]) then
				choices_to_prioitise[#choices_to_prioitise + 1] = k
			end
		end

		if Utils.length(choices_possible) > 0 then
			local choice
			if Utils.length(choices_to_prioitise) > 0 then
				choice = choices_to_prioitise[Math.random(Utils.length(choices_to_prioitise))]
			else
				choice = Math.raffle2(choices_possible)
			end

			local placed
			if choice == 'crude-oil' then

				placed = (3000 * (1 + 9 * Math.slopefromto(choices[choice], 1, 8))) * (0.6 + Math.random()) --3000 is 1%

				placed = Math.min(placed, Common.oil_abstract_to_real(choices[choice]))

				local tile = surface.get_tile(realp)
				if (not (tile and tile.name and Utils.contains(CoreData.tiles_that_conflict_with_resource_layer_extended, tile.name))) then
					surface.create_entity{name = 'crude-oil', amount = placed, position = realp}
				else
					placed = 0
				end

			else
				local real_amount = Math.max(Common.minimum_ore_placed_per_tile, Common.ore_abstract_to_real(choices[choice]))

				local density = (density_bonus + 23 + 4 * Math.random()) -- not too big, and not too much variation; it makes players have to stay longer
				
				local radius_squared = (destination.static_params and destination.static_params.radius_squared_modifier or 1) * (9 + 39 * Math.slopefromto(Common.ore_abstract_to_real(choices[choice]), 800, 20000)) * (0.6 + Math.random())
	
				if source_name == 'rock-huge' then
					radius_squared = radius_squared * 1.5
				end
			
				placed = Public.draw_noisy_ore_patch(surface, realp, choice, real_amount, radius_squared, density)
			end

			if placed then
				choices[choice] = Math.max(0, choices[choice] - Common.ore_real_to_abstract(placed))
				if placed > 0 and not destination.dynamic_data.ore_types_spawned[choice] then
					destination.dynamic_data.ore_types_spawned[choice] = true
				end
				return true
			end
		end
	end

	return false
end




function Public.draw_noisy_ore_patch(surface, position, name, budget, radius_squared, density, forced, flat)
	flat = flat or true
	budget = budget or 999999999
	forced = forced or false
	local amountplaced = 0
	local radius = Math.sqrt(radius_squared)

	position = {x = Math.ceil(position.x) - 0.5, y = Math.ceil(position.y) - 0.5}

	if not position then return 0 end
	if not name then return 0 end
	if not surface then return 0 end
	if not radius then return 0 end
	if not density then return 0 end
	local mixed_ore_raffle = {
		'iron-ore', 'iron-ore', 'iron-ore', 'copper-ore', 'copper-ore', 'coal', 'stone'
	}
	local seed = surface.map_gen_settings.seed

	local function try_draw_at_relative_position(x, y, strength)
		local absx = x + position.x
		local absy = y + position.y
		local absp = {x = absx, y = absy}
		
		local amount_to_place_here = Math.min(density * strength, budget - amountplaced)

		if amount_to_place_here >= Common.minimum_ore_placed_per_tile then

			if name == 'mixed' then
				local noise = simplex_noise(x * 0.005, y * 0.005, seed) + simplex_noise(x * 0.01, y * 0.01, seed) * 0.3 + simplex_noise(x * 0.05, y * 0.05, seed) * 0.2
				local i = (Math.floor(noise * 100) % #mixed_ore_raffle) + 1
				name = mixed_ore_raffle[i]
			end
			local entity = {name = name, position = absp, amount = amount_to_place_here}
			-- local area = {{absx - 0.05, absy - 0.05}, {absx + 0.05, absy + 0.05}}
			local area2 = {{absx - 0.1, absy - 0.1}, {absx + 0.1, absy + 0.1}}
			local area3 = {{absx - 2, absy - 2}, {absx + 2, absy + 2}}
			local preexisting_ores = surface.find_entities_filtered{area = area2, type = 'resource'}

			local added
			if #preexisting_ores >= 1 then
				local addedbool = false
				for _, ore in pairs(preexisting_ores) do
					if ore.name == name then
						ore.amount = ore.amount + amount_to_place_here
						amountplaced = amountplaced + amount_to_place_here
						addedbool = true
						break
					end
				end
				if not addedbool then
					added = surface.create_entity(entity)
				end
			else
				local tile = surface.get_tile(absp)
				local silos = surface.find_entities_filtered{area=area3, name='rocket-silo'}
				if #silos == 0 and (not (tile and tile.name and Utils.contains(CoreData.tiles_that_conflict_with_resource_layer_extended, tile.name))) then
					if forced then
						surface.destroy_decoratives{area = area2}
						for _, tree in pairs(surface.find_entities_filtered{area=area2, type='tree'}) do
							tree.destroy()
						end
						added = surface.create_entity(entity)
					else
						local pos2 = surface.find_non_colliding_position(name, absp, 10, 1, true)
						pos2 = pos2 or absp
						entity = {name = name, position = pos2, amount = amount_to_place_here}
						surface.destroy_decoratives{area = area2}
						if pos2 and surface.can_place_entity(entity) then
							added = surface.create_entity(entity)
						end
					end
				end
			end
			if added and added.valid then
				amountplaced = amountplaced + amount_to_place_here
			end
		end
	end

	local spiral_layer = 0
	local outwards_spiral_x = 0
	local outwards_spiral_y = 0

	local whilesafety = 0
	while whilesafety < 10000 and spiral_layer < radius * 2 do
		whilesafety = whilesafety + 1

		local distance_to_center = Math.sqrt(outwards_spiral_x^2 + outwards_spiral_y^2)
		local noise
		if distance_to_center > 0 then
			noise = 0.99 * simplex_noise((position.x + outwards_spiral_x/distance_to_center) * 1/3, (position.y + outwards_spiral_y/distance_to_center) * 1/3, seed) * simplex_noise((position.x + outwards_spiral_x/distance_to_center) * 1/9, (position.y + outwards_spiral_y/distance_to_center) * 1/9, seed+100)
		else
			noise = 0.99 * simplex_noise((position.x) * 1/3, (position.y) * 1/3, seed) * simplex_noise((position.x) * 1/9, (position.y) * 1/9, seed+100)
		end
		local radius_noisy = radius * (1 + noise)
		if distance_to_center < radius_noisy then
			local strength
			if flat then
				strength = 1
			else
				strength = (3/2) * (1 - (distance_to_center/radius_noisy)^2)
			end
			try_draw_at_relative_position(outwards_spiral_x, outwards_spiral_y, strength)
		end

		if outwards_spiral_x == 0 and outwards_spiral_y >= spiral_layer then
			outwards_spiral_x = outwards_spiral_x + 1
			spiral_layer = spiral_layer + 1
		elseif outwards_spiral_x > 0 and outwards_spiral_y > 0 then
			outwards_spiral_x = outwards_spiral_x + 1
			outwards_spiral_y = outwards_spiral_y - 1
		elseif outwards_spiral_x > 0 and outwards_spiral_y <= 0 then
			outwards_spiral_x = outwards_spiral_x - 1
			outwards_spiral_y = outwards_spiral_y - 1
		elseif outwards_spiral_x <= 0 and outwards_spiral_y < 0 then
			outwards_spiral_x = outwards_spiral_x - 1
			outwards_spiral_y = outwards_spiral_y + 1
		elseif outwards_spiral_x < 0 and outwards_spiral_y >= 0 then
			outwards_spiral_x = outwards_spiral_x + 1
			outwards_spiral_y = outwards_spiral_y + 1
		end
	end

	return amountplaced
end


return Public