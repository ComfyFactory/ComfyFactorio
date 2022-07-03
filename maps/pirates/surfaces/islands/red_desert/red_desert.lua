-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
local Structures = require 'maps.pirates.structures.structures'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Effects = require 'maps.pirates.effects'
local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect
-- local Ores = require 'maps.pirates.ores'
local IslandsCommon = require 'maps.pirates.surfaces.islands.common'
local Hunt = require 'maps.pirates.surfaces.islands.hunt'

local Public = {}
Public.Data = require 'maps.pirates.surfaces.islands.red_desert.data'


function Public.noises(args)
	local ret = {}

	ret.height = IslandsCommon.island_height_1(args)
	ret.height_background = args.noise_generator.height_background
	ret.forest = args.noise_generator.forest
	ret.forest_abs = function (p) return Math.abs(ret.forest(p)) end
	ret.forest_abs_suppressed = function (p) return ret.forest_abs(p) - 1 * Math.slopefromto(ret.height(p), 0.17, 0.11) end
	ret.rock = args.noise_generator.rock
	ret.ore = args.noise_generator.ore
	ret.rock_abs = function (p) return Math.abs(ret.rock(p)) end
	ret.mood = args.noise_generator.mood
	ret.farness = IslandsCommon.island_farness_1(args) --isn't available on the iconized pass, only on actual generation; check args.iconized_generation before you use this
	return ret
end


function Public.terrain(args)
	local noises = Public.noises(args)
	local p = args.p


	if IslandsCommon.place_water_tile(args) then return end

	if noises.height(p) < 0 then
		args.tiles[#args.tiles + 1] = {name = 'water', position = args.p}
		return
	end

	if noises.height(p) < 0.19 then
		args.tiles[#args.tiles + 1] = {name = 'sand-1', position = args.p}
	elseif noises.height(p) < 0.22 then
		args.tiles[#args.tiles + 1] = {name = 'red-desert-3', position = args.p}
	else
		if noises.height_background(p) > 0.4 then
			args.tiles[#args.tiles + 1] = {name = 'red-desert-2', position = args.p}
		elseif noises.height_background(p) > -0.15 then
			args.tiles[#args.tiles + 1] = {name = 'red-desert-1', position = args.p}
		else
			args.tiles[#args.tiles + 1] = {name = 'red-desert-0', position = args.p}
		end
	end

	if noises.height(p) > 0.32 then
		if noises.rock_abs(p) > 0.25 then

			if noises.mood(p) < -0.5 then
				local density = 0.003 * Math.slopefromto(noises.rock_abs(p), 0.25, 0.4)
				local rng = Math.random()
				if rng < density then
					args.decoratives[#args.decoratives + 1] = {name = 'worms-decal', position = args.p}
				end
			end

			if noises.mood(p) < 0.1 then
				local rng = Math.random()
				if rng < 0.0004 then
					args.entities[#args.entities + 1] = {name = 'medium-remnants', position = args.p}
				elseif rng < 0.0007 then
					args.entities[#args.entities + 1] = {name = 'spidertron-remnants', position = args.p}
				elseif rng < 0.001 then
					args.entities[#args.entities + 1] = {name = 'medium-ship-wreck', position = args.p}
				elseif rng < 0.0013 then
					args.entities[#args.entities + 1] = {name = 'big-ship-wreck-2', position = args.p}
				elseif rng < 0.0014 then
					args.entities[#args.entities + 1] = {name = 'big-ship-wreck-1', position = args.p}
				end
			end
		end
	end

	if noises.forest_abs_suppressed(p) > 0.85 then
		local treedensity = 0.3 * Math.slopefromto(noises.forest_abs_suppressed(p), 0.85, 0.9)
		if noises.forest(p) > 1.6 then
			if Math.random(1,100) < treedensity*100 then args.entities[#args.entities + 1] = {name = 'dry-hairy-tree', position = args.p, visible_on_overworld = true} end
		elseif noises.forest(p) < -0.95 then
			if Math.random(1,100) < treedensity*100 then args.entities[#args.entities + 1] = {name = 'dead-tree-desert', position = args.p, visible_on_overworld = true} end
		end
	end

	if noises.forest_abs_suppressed(p) < 0.65 then
		if noises.height(p) > 0.15 then
			if noises.rock_abs(p) > 0.25 then
				local rockdensity = 1/200 * Math.slopefromto(noises.rock_abs(p), 0.25, 0.6)
				local rockrng = Math.random()
				if rockrng < rockdensity then
					args.entities[#args.entities + 1] = IslandsCommon.random_rock_1(args.p)
				elseif rockrng < rockdensity * 1.5 then
					args.decoratives[#args.decoratives + 1] = {name = 'rock-medium', position = args.p}
				elseif rockrng < rockdensity * 2 then
					args.decoratives[#args.decoratives + 1] = {name = 'rock-small', position = args.p}
				elseif rockrng < rockdensity * 2.5 then
					args.decoratives[#args.decoratives + 1] = {name = 'rock-tiny', position = args.p}
				end
			end
		end
	end

	if noises.forest_abs_suppressed(p) < 0.8 and noises.mood(p) > -0.3 then
		if noises.height(p) > 0.27 then
			if noises.ore(p) > 1.5 then
				local name = 'iron-ore'
				if (args.p.x + args.p.y) % 2 < 1 then
					name = 'copper-ore'
				end
				args.entities[#args.entities + 1] = {name = name, position = args.p, amount = 20}
			elseif noises.ore(p) < -1.6 then
				args.entities[#args.entities + 1] = {name = 'coal', position = args.p, amount = 20}
			elseif noises.ore(p) < 0.041 and noises.ore(p) > -0.041 then
				args.entities[#args.entities + 1] = {name = 'stone', position = args.p, amount = 10}
			end
		elseif noises.height(p) < 0.19 then
			if noises.ore(p) > 2.1 then
				args.entities[#args.entities + 1] = {name = 'copper-ore', position = args.p, amount = 10}
			elseif noises.ore(p) < -2.1 then
				args.entities[#args.entities + 1] = {name = 'iron-ore', position = args.p, amount = 10}
			-- elseif noises.ore(p) < 0.010 and noises.ore(p) > -0.010 then
			-- 	args.entities[#args.entities + 1] = {name = 'coal', position = args.p, amount = 5}
			end
		end
	end
end




function Public.chunk_structures(args)
	local rng = Math.random()
	local left_top = args.left_top

	local spec = function(p)
		local noises = Public.noises{p = p, noise_generator = args.noise_generator, static_params = args.static_params, seed = args.seed}

		return {
			placeable = noises.height(p) > 0.05 and noises.mood(p) > -0.6 and noises.farness(p) > 0.1,
			chanceper4chunks = 0.05,
		}
	end

	-- initial attempt, to avoid placing two structures too close to each other, is to divide up the map into 2x2 chonks, and spawn once in each
	local bool1, bool2 = left_top.x % 64 < 32, left_top.y % 64 < 32
	local all_four_chunks = {
		{x = left_top.x, y = left_top.y},
		{x = left_top.x + (bool1 and 32 or -32), y = left_top.y},
		{x = left_top.x, y = left_top.y + (bool2 and 32 or -32)},
		{x = left_top.x + (bool1 and 32 or -32), y = left_top.y + (bool2 and 32 or -32)},
	}

	if not args.other_map_generation_data.chunks_loaded then args.other_map_generation_data.chunks_loaded = {} end
	local chunks_loaded = args.other_map_generation_data.chunks_loaded

	if not chunks_loaded[args.left_top.x] then chunks_loaded[args.left_top.x] = {} end
	chunks_loaded[args.left_top.x][args.left_top.y] = true

	local nearby_chunks_generated_count = 0
	for i=1,4 do
		if chunks_loaded[all_four_chunks[i].x] and chunks_loaded[all_four_chunks[i].x][all_four_chunks[i].y] then
			nearby_chunks_generated_count = nearby_chunks_generated_count + 1
		end
	end

	if nearby_chunks_generated_count == 4 then --should trigger only once per 4 chunks
		local avgleft_top = {
			x = (all_four_chunks[1].x + all_four_chunks[4].x)/2,
			y = (all_four_chunks[1].y + all_four_chunks[4].y)/2,
		}
		local leftmost_topmost = {
			x = avgleft_top.x - 32,
			y = avgleft_top.y - 32,
		}

		local spec2 = spec{x = avgleft_top.x + 16, y = avgleft_top.y + 16}

		if rng < spec2.chanceper4chunks then

			local rng2 = Math.random()
			local struct

			if rng2 < 28/100 then
				struct = Structures.IslandStructures.ROC.shelter2
			else
				struct = Structures.IslandStructures.ROC.shelter1
			end
			if struct then
				Structures.try_place(struct, args.specials, leftmost_topmost, 64, 64, function(p) return spec(p).placeable end)
			end
		end
	end
end



-- function Public.break_rock(surface, p, entity_name)
-- 	-- return Ores.try_ore_spawn(surface, p, entity_name)
-- end


function Public.generate_silo_setup_position(points_to_avoid)
	return Hunt.silo_setup_position(points_to_avoid)
end

local function red_desert_tick()
	for _, id in pairs(Memory.get_global_memory().crew_active_ids) do
		Memory.set_working_id(id)
		local memory = Memory.get_crew_memory()
		local destination = Common.current_destination()

		if destination.subtype == IslandsCommon.enum.RED_DESERT then
			if memory.boat and memory.boat.surface_name and memory.boat.surface_name == destination.surface_name then

				Public.underground_worms_ai()

				if game.tick % 360 == 0 and destination.dynamic_data.timer and destination.dynamic_data.timer > 60 then
					Public.custom_biter_ai()
				end
			end
		end
	end
end


local event = require 'utils.event'
event.on_nth_tick(30, red_desert_tick)



function Public.underground_worms_ai()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]
	local player_force = memory.force
	local enemy_force_name = memory.enemy_force_name
	local evolution = memory.evolution_factor

	if not destination.dynamic_data.worms_table then destination.dynamic_data.worms_table = {} end

	local worms = destination.dynamic_data.worms_table

	local indices_to_remove = {}

	for i = #worms, 1, -1 do
		local w = worms[i]

		w.age = w.age + 1
		-- despawn
		if w.age > w.max_age then
			indices_to_remove[#indices_to_remove + 1] = i
		else
			-- move
			w.position = {x = w.position.x + Balance.sandworm_speed() * 30/60 * w.direction.x, y = w.position.y + Balance.sandworm_speed() * 30/60 * w.direction.y}

			if w.chart_tag then w.chart_tag.destroy() end

			local tile = surface.get_tile(w.position.x, w.position.y)
			local on_land = tile and tile.valid and (not Utils.contains(CoreData.tiles_that_conflict_with_resource_layer, tile.name)) and (not Utils.contains(CoreData.noworm_tile_names, tile.name))

			if on_land then
				local solid_ground = (tile and tile.valid and Utils.contains(CoreData.worm_solid_tile_names, tile.name))

				-- stomp
				local big_bool = (w.age % 4 == 0)
				Effects.worm_movement_effect(surface, w.position, solid_ground, big_bool)

				w.chart_tag = player_force.add_chart_tag(surface, {icon = {type = 'virtual', name = 'signal-red'}, position = w.position})

				if not solid_ground then
					local nearby_characters = surface.find_entities_filtered{position = w.position, radius = 7, name = 'character'}

					local character_outside = false
					for j = 1, #nearby_characters do
						local c = nearby_characters[j]

						local t = surface.get_tile(c.position.x, c.position.y)
						if not (t and t.valid and Utils.contains(CoreData.worm_solid_tile_names, t.name))
						then
							character_outside = true
							break
						end
					end

					if character_outside then
						local type = Common.get_random_worm_type(evolution)

						local emerge_position = surface.find_non_colliding_position(type, w.position, 3, 0.5)

						if emerge_position then
							local emerge_position_tile = surface.get_tile(emerge_position.x, emerge_position.y)

							local can_emerge = (not solid_ground) and (not (tile and tile.valid and Utils.contains(CoreData.worm_solid_tile_names, emerge_position_tile.name)))

							if can_emerge then
								surface.create_entity{name = type, position = emerge_position, force = enemy_force_name}
								Effects.worm_emerge_effect(surface, emerge_position)
								indices_to_remove[#indices_to_remove + 1] = i
								if w.chart_tag then w.chart_tag.destroy() end

								local extra_evo = Balance.sandworm_evo_increase_per_spawn()
								Common.increment_evo(extra_evo)

								if destination.dynamic_data then
									destination.dynamic_data.evolution_accrued_sandwurms = destination.dynamic_data.evolution_accrued_sandwurms + extra_evo
								end
							end
						end

					end
				end
			end
		end
	end

	for i = 1, #indices_to_remove do
		local index = indices_to_remove[i]

		for j = index, #worms-1 do
			worms[j] = worms[j+1]
		end
		worms[#worms] = nil
	end

	local max_worms = Math.ceil(45 * Math.sloped(Common.difficulty_scale(), 1/2))

	-- spawn worms
	if game.tick % 90 == 0 then
		if #worms < max_worms then
			local island_center = destination.static_params.islandcenter_position
			local r = Math.max(destination.static_params.width, destination.static_params.height)/2

			local theta = Math.random()*5.75 - Math.pi/2+0.25
			local p = {x = island_center.x + r*Math.sin(theta), y = island_center.y + r*Math.cos(theta)}

			local theta2 = Math.random()*1.4-0.7
			local d = {x = -Math.sin(theta+theta2), y = -Math.cos(theta+theta2)}

			worms[#worms + 1] = {position = p, direction = d, age = 0, max_age = 2*r/(Balance.sandworm_speed() * 30/60) * Math.cos(theta2/2)}
		end
	end
end



function Public.custom_biter_ai()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	local surface = game.surfaces[destination.surface_name]
	-- local difficulty = memory.difficulty
	local enemy_force_name = memory.enemy_force_name
	local evolution = memory.evolution_factor

	local fraction_of_floating_pollution = 1/2
	local minimum_avg_units = 30
	local maximum_units = 256

	local pollution_available = memory.floating_pollution
	local budget = fraction_of_floating_pollution * pollution_available

	if budget >= minimum_avg_units * Common.averageUnitPollutionCost(evolution) then
		local initialbudget = budget

		local position = Hunt.position_away_from_players_1({static_params = destination.static_params}, 50)

		local units_created_count = 0
		local units_created = {}

		local name = Common.get_random_unit_type(evolution)
		local unittype_pollutioncost = CoreData.biterPollutionValues[name] * 1.1 * Balance.scripted_biters_pollution_cost_multiplier()

		local function spawn(name2)
			units_created_count = units_created_count + 1

			local p = surface.find_non_colliding_position(name2, position, 50, 2)
			if not p then return end

			local biter = surface.create_entity({name = name2, force = enemy_force_name, position = p})

			units_created[#units_created + 1] = biter
			memory.scripted_biters[biter.unit_number] = {entity = biter, created_at = game.tick}

			return biter.unit_number
		end

		local whilesafety = 1000
		while units_created_count < maximum_units and budget >= unittype_pollutioncost and #memory.scripted_biters < CoreData.total_max_biters and whilesafety > 0 do
			whilesafety = whilesafety - 1
			pollution_available = pollution_available - unittype_pollutioncost
			budget = budget - unittype_pollutioncost
			spawn(name)
		end

		game.pollution_statistics.on_flow(name, budget - initialbudget)
		memory.floating_pollution = pollution_available

		if (not units_created) or (not #units_created) or (#units_created == 0) then return end

		Effects.biters_emerge(surface, position)

		local position2 = surface.find_non_colliding_position('rocket-silo', position, 256, 2) or position

		local unit_group = surface.create_unit_group({position = position2, force = enemy_force_name})
		for _, unit in pairs(units_created) do
			unit_group.add_member(unit)
		end
		memory.scripted_unit_groups[unit_group.group_number] = {ref = unit_group, script_type = 'burrowed'}

		local target = {valid = true, position = {x = memory.boat.position.x - 60, y = memory.boat.position.y} or nil, name = 'boatarea'}

		unit_group.set_command{
			type = defines.command.attack_area,
			destination = target.position,
			radius = 30,
			distraction = defines.distraction.by_anything
		}
	end
end

return Public