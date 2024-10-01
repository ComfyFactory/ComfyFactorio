-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Balance = require('maps.pirates.balance')
-- local Memory = require 'maps.pirates.memory'
local Math = require('maps.pirates.math')
local Raffle = require('maps.pirates.raffle')
local CoreData = require('maps.pirates.coredata')
local _inspect = require('utils.inspect').inspect
local Common = require('maps.pirates.common')
local Utils = require('maps.pirates.utils_local')
local simplex_noise = require('utils.simplex_noise').d2
--

local Public = {}

-- Gives less and less ore with every call, until given amount slowly converges to 2
-- For now used just for Cave island to give players ore when mining rocks
-- NOTE: Also gives some coins
function Public.try_give_ore(player, realp, source_name)
	local destination = Common.current_destination()
	local choices = destination.dynamic_data.hidden_ore_remaining_abstract

	if choices and Utils.length(choices) > 0 then
		local choices_possible = {}
		local choices_to_prioitise = {}
		local total_ore_left = 0

		for k, v in pairs(choices) do
			if v > 0 then
				choices_possible[k] = v
			end

			total_ore_left = total_ore_left + v

			if not destination.dynamic_data.ore_types_spawned[k] then
				choices_to_prioitise[#choices_to_prioitise + 1] = k
			end
		end

		if Utils.length(choices_possible) > 0 then
			local choice
			if Utils.length(choices_to_prioitise) > 0 then
				choice = choices_to_prioitise[Math.random(Utils.length(choices_to_prioitise))]
			else
				choice = Raffle.raffle2(choices_possible)
			end

			if not choice then
				return
			end

			local coin_amount = Math.ceil(0.15 * Balance.coin_amount_from_rock())
			local real_amount = Common.ore_abstract_to_real(choices[choice])

			local given_amount = Math.ceil(real_amount * Math.random_float_in_range(0.004, 0.006))

			if source_name == 'huge-rock' then
				given_amount = given_amount * 2
				coin_amount = coin_amount * 2
			end

			given_amount = Math.max(8 * Balance.game_resources_scale(), given_amount)

			local to_give = {}
			to_give[#to_give + 1] = { name = choice, count = Math.ceil(given_amount) }
			to_give[#to_give + 1] = { name = 'coin', count = Math.ceil(coin_amount) }
			Common.give(player, to_give, realp)

			-- 1 here indicates that ore type should still be given
			choices[choice] = Math.max(1, choices[choice] - Common.ore_real_to_abstract(given_amount))
		end
	end
end

function Public.try_ore_spawn(surface, realp, source_name, density_bonus, from_tree)
	density_bonus = density_bonus or 0
	from_tree = from_tree or false
	-- local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local choices = destination.dynamic_data.hidden_ore_remaining_abstract

	if from_tree then
		choices = destination.static_params.abstract_ore_amounts
	end

	local ret = false

	if choices and Utils.length(choices) > 0 then
		local choices_possible = {}
		local choices_to_prioitise = {}

		for k, v in pairs(choices) do
			if v > 0 then
				choices_possible[k] = v
			end

			if not destination.dynamic_data.ore_types_spawned[k] then
				choices_to_prioitise[#choices_to_prioitise + 1] = k
			end
		end

		if Utils.length(choices_possible) > 0 then
			local choice
			if Utils.length(choices_to_prioitise) > 0 then
				choice = choices_to_prioitise[Math.random(Utils.length(choices_to_prioitise))]
			else
				choice = Raffle.raffle2(choices_possible)
			end

			local placed
			if choice == 'crude-oil' then
				placed = Common.oil_abstract_to_real(
					6 + 0.7 * choices[choice] / (Math.max(1, Math.ceil((choices[choice] / 4) ^ (1 / 2))))
				) * (0.8 + 0.4 * Math.random()) --thesixthroc's magic function, just plot this to see that it makes sense

				placed = Math.min(placed, Common.oil_abstract_to_real(choices[choice]))

				local tile = surface.get_tile(realp)
				if
					not (
						tile
						and tile.name
						and Utils.contains(CoreData.tiles_that_conflict_with_resource_layer_extended, tile.name)
					)
				then
					surface.create_entity({ name = 'crude-oil', amount = placed, position = realp })
				else
					placed = 0
				end

				if placed then
					choices[choice] = Math.max(0, choices[choice] - Common.oil_real_to_abstract(placed))
					if placed > 0 and not destination.dynamic_data.ore_types_spawned[choice] then
						destination.dynamic_data.ore_types_spawned[choice] = true
					end
					ret = true
				end
			else
				if not choice then
					return false
				end

				local real_amount = Common.ore_abstract_to_real(choices[choice])
				if from_tree then
					real_amount = Math.ceil(real_amount * 0.1)
				end
				real_amount = Math.max(Common.minimum_ore_placed_per_tile, real_amount)

				local density = (density_bonus + 17 + 4 * Math.random()) -- not too big, and not too much variation; it makes players have to stay longer

				local radius_squared = (
					destination.static_params and destination.static_params.radius_squared_modifier or 1
				)
					* (12 + 45 * Math.slopefromto(Common.ore_abstract_to_real(choices[choice]), 800, 20000))
					* (0.6 + Math.random()) --tuned

				if source_name == 'huge-rock' then
					radius_squared = radius_squared * 1.5
				end

				placed = Public.draw_noisy_ore_patch(surface, realp, choice, real_amount, radius_squared, density)

				if placed then
					choices[choice] = Math.max(0, choices[choice] - Common.ore_real_to_abstract(placed))
					if placed > 0 and not destination.dynamic_data.ore_types_spawned[choice] then
						destination.dynamic_data.ore_types_spawned[choice] = true
					end
					ret = true
				end
			end
		end
	end

	return ret
end

function Public.draw_noisy_ore_patch(surface, position, name, budget, radius_squared, density, forced, flat)
	flat = flat or false
	budget = budget or 999999999
	forced = forced or false
	local amountplaced = 0
	local radius = Math.sqrt(radius_squared)

	position = { x = Math.ceil(position.x) - 0.5, y = Math.ceil(position.y) - 0.5 }

	if not position then
		return 0
	end
	if not name then
		return 0
	end
	if not surface then
		return 0
	end
	if not radius then
		return 0
	end
	if not density then
		return 0
	end
	local mixed_ore_raffle = {
		'iron-ore',
		'iron-ore',
		'iron-ore',
		'copper-ore',
		'copper-ore',
		'coal',
		'stone',
	}
	local seed = surface.map_gen_settings.seed

	local function try_draw_at_relative_position(x, y, strength)
		local absx = x + position.x
		local absy = y + position.y
		local absp = { x = absx, y = absy }

		local amount_to_place_here = Math.min(density * strength, budget - amountplaced)

		if amount_to_place_here >= Common.minimum_ore_placed_per_tile then
			if name == 'mixed' then
				local noise = simplex_noise(x * 0.005, y * 0.005, seed)
					+ simplex_noise(x * 0.01, y * 0.01, seed) * 0.3
					+ simplex_noise(x * 0.05, y * 0.05, seed) * 0.2
				local i = (Math.floor(noise * 100) % #mixed_ore_raffle) + 1
				name = mixed_ore_raffle[i]
			end
			local entity = { name = name, position = absp, amount = amount_to_place_here }
			-- local area = {{absx - 0.05, absy - 0.05}, {absx + 0.05, absy + 0.05}}
			local area2 = { { absx - 0.1, absy - 0.1 }, { absx + 0.1, absy + 0.1 } }
			local area3 = { { absx - 2, absy - 2 }, { absx + 2, absy + 2 } }
			local preexisting_ores = surface.find_entities_filtered({ area = area2, type = 'resource' })

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
				local silos = surface.find_entities_filtered({ area = area3, name = 'rocket-silo' })
				if
					#silos == 0
					and not (
						tile
						and tile.name
						and Utils.contains(CoreData.tiles_that_conflict_with_resource_layer_extended, tile.name)
					)
				then
					if forced then
						surface.destroy_decoratives({ area = area2 })
						for _, tree in pairs(surface.find_entities_filtered({ area = area2, type = 'tree' })) do
							tree.destroy()
						end
						added = surface.create_entity(entity)
					else
						local pos2 = surface.find_non_colliding_position(name, absp, 10, 1, true)
						pos2 = pos2 or absp
						entity = { name = name, position = pos2, amount = amount_to_place_here }
						surface.destroy_decoratives({ area = area2 })
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

	for _, p in ipairs(Math.points_in_m20t20_squared_sorted_by_distance_to_origin) do
		local x, y = p[1], p[2]
		local distance_to_center = Math.sqrt(x ^ 2 + y ^ 2)
		local noise
		if flat then
			noise = 0.99
				* simplex_noise((position.x + x) * 1 / 3, (position.y + y) * 1 / 3, seed)
				* simplex_noise((position.x + x) * 1 / 9, (position.y + y) * 1 / 9, seed + 100)
		else --put noise on the unit circle
			if distance_to_center > 0 then
				noise = 0.99
					* simplex_noise(
						(position.x + x / distance_to_center) * 1 / 3,
						(position.y + y / distance_to_center) * 1 / 3,
						seed
					)
					* simplex_noise(
						(position.x + x / distance_to_center) * 1 / 9,
						(position.y + y / distance_to_center) * 1 / 9,
						seed + 100
					)
			else
				noise = 0.99
					* simplex_noise(position.x * 1 / 3, position.y * 1 / 3, seed)
					* simplex_noise(position.x * 1 / 9, position.y * 1 / 9, seed + 100)
			end
		end
		local radius_noisy = radius * (1 + noise)
		if distance_to_center < radius_noisy then
			local strength
			if flat then
				-- if noise > -0.5 then strength = 1 else strength = 0 end
				-- its hard to make it both noncircular and flat in per-tile count
				strength = 1
			else
				strength = (3 / 2) * (1 - (distance_to_center / radius_noisy) ^ 2)
			end
			try_draw_at_relative_position(x, y, strength)
		end
		if amountplaced >= budget then
			break
		end
	end

	return amountplaced
end

return Public
