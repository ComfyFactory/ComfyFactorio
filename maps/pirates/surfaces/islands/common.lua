-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
-- local Balance = require 'maps.pirates.balance'
local Structures = require 'maps.pirates.structures.structures'
local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
-- local Ores = require 'maps.pirates.ores'
local _inspect = require 'utils.inspect'.inspect

local Public = {}

local enum = {
	STANDARD = '1',
	FIRST = '2',
	WALKWAYS = '3',
	RED_DESERT = '4',
	RADIOACTIVE = '5',
	STANDARD_VARIANT = '6',
	HORSESHOE = '7',
	SWAMP = '8',
	MAZE = '9',
}
Public.enum = enum

function Public.place_water_tile(args)

	if args.static_params and args.static_params.deepwater_terraingenframe_xposition and args.p.x <= args.static_params.deepwater_terraingenframe_xposition - 0.5
	then
		args.tiles[#args.tiles + 1] = {name = 'deepwater', position = args.p}

		local fishrng = Math.random(350)
		if fishrng == 350 then
			args.entities[#args.entities + 1] = {name = 'fish', position = args.p}
		end
		return true
	end

	if not args.noise_generator['height'] then return end

	local height_noise = args.noise_generator['height'](args.p)
	if height_noise < 0 then
		args.tiles[#args.tiles + 1] = {name = 'water', position = args.p}

		local fishrng = Math.random(350)
		if fishrng == 350 then
			args.entities[#args.entities + 1] = {name = 'fish', position = args.p}
		end
		return true
	end

	return false
end


function Public.island_height_1(args)
	local noise_name = 'height'

	if not args.noise_generator[noise_name] then
		args.noise_generator:addNoise(noise_name,
		function(p)
			local r2 = (p.x)^2 + (p.y)^2
			local r = Math.sqrt(r2)

			-- 'noise testing suite':
			-- local height_noise
			-- if args.noise_generator.forest then
			-- 	height_noise = args.noise_generator.forest(p)
			-- else return 0 end
			-- local height_noise = args.noise_generator.height_background(p)
			-- local height_noise = (
			-- 	1 - r/(args.noise_generator.radius{x = p.x/r, y = p.y/r})
			-- )
			local height_noise = (
				1 - r/(args.noise_generator.radius{x = p.x/r, y = p.y/r})
			) + args.noise_generator.height_background(p)

			return height_noise
		end)
	end
	return args.noise_generator[noise_name]
end


function Public.island_height_mostly_circular(args)
	local noise_name = 'height'

	if not args.noise_generator[noise_name] then
		args.noise_generator:addNoise(noise_name,
		function(p)
			local r2 = (p.x)^2 + (p.y)^2
			local r = Math.sqrt(r2)

			-- 'noise testing suite':
			-- local height_noise
			-- if args.noise_generator.forest then
			-- 	height_noise = args.noise_generator.forest(p)
			-- else return 0 end
			-- local height_noise = args.noise_generator.height_background(p)
			-- local height_noise = (
			-- 	1 - r/(args.noise_generator.radius{x = p.x/r, y = p.y/r})
			-- )
			local height_noise = (
				1 - r/(args.noise_generator.radius{x = p.x/r, y = p.y/r})
			)

			return height_noise
		end)
	end
	return args.noise_generator[noise_name]
end



function Public.island_height_horseshoe(args)
	local noise_name = 'height'

	if not args.noise_generator[noise_name] then
		args.noise_generator:addNoise(noise_name,
		function(p)
			local r12 = (p.x)^2 + (p.y)^2
			local r1 = Math.sqrt(r12)

			local offsetp = {x = p.x + 80, y = p.y}
			local r22 = (offsetp.x)^2 + (offsetp.y)^2
			local r2 = Math.sqrt(r22)

			-- 'noise testing suite':
			-- local height_noise
			-- if args.noise_generator.forest then
			-- 	height_noise = args.noise_generator.forest(p)
			-- else return 0 end
			-- local height_noise = args.noise_generator.height_background(p)
			-- local height_noise = (
			-- 	1 - r/(args.noise_generator.radius{x = p.x/r, y = p.y/r})
			-- )
			local height_noise = (
				1 - r1/(args.noise_generator.radius1{x = p.x/r1, y = p.y/r1})
			) - Math.max(0,
				1 - r2/(args.noise_generator.radius2{x = offsetp.x/r2, y = offsetp.y/r2})
			) + args.noise_generator.height_background(p)

			return height_noise
		end)
	end
	return args.noise_generator[noise_name]
end


function Public.island_farness_1(args)
	--on a scale from 0 to 1, how 'far' the point is from the boat dropoff point
	if not args.static_params.width and args.static_params.islandcenter_position and args.static_params.terraingen_coordinates_offset then return end -- can only call after detailed static_params are generated

	local noise_name = 'farness' --might as well remember as a noise just to memoize
	if not args.noise_generator[noise_name] then
		args.noise_generator:addNoise(noise_name,
		function(p)
			local island_width = args.static_params.width - 2*Math.abs(args.static_params.islandcenter_position.x)

			local nexus_of_boredom = {x = args.static_params.terraingen_coordinates_offset.x + args.static_params.islandcenter_position.x - 2/5*island_width, y = args.static_params.terraingen_coordinates_offset.y + args.static_params.islandcenter_position.y}

			local relativeradius2 = Math.distance(p, nexus_of_boredom)
			local farness = Math.slopefromto(relativeradius2, island_width/12, island_width)

			if p.x < nexus_of_boredom.x then
				local num = Math.abs(nexus_of_boredom.y - p.y)
				local denom = Math.abs(nexus_of_boredom.x - p.x)
				if denom < 1 then denom = 1 end
				farness = farness * Math.slopefromto(num/denom, 1, 5)
			end

			return farness
		end)
	end

	return args.noise_generator[noise_name]
end


function Public.island_farness_horseshoe(args)
	--on a scale from 0 to 1, how 'far' the point is from the boat dropoff point
	--compared to first farness function this one is much more simply just distance from boat
	if not args.static_params.width and args.static_params.islandcenter_position and args.static_params.terraingen_coordinates_offset then return end -- can only call after detailed static_params are generated

	local noise_name = 'farness' --might as well remember as a noise just to memoize
	if not args.noise_generator[noise_name] then
		args.noise_generator:addNoise(noise_name,
		function(p)
			local island_width = args.static_params.width - 2*Math.abs(args.static_params.islandcenter_position.x)

			local nexus_of_boredom = {x = args.static_params.terraingen_coordinates_offset.x + args.static_params.islandcenter_position.x - 1/6*island_width, y = args.static_params.terraingen_coordinates_offset.y + args.static_params.islandcenter_position.y}

			local relativeradius2 = Math.distance(p, nexus_of_boredom)
			local farness = Math.slopefromto(relativeradius2, island_width/12, 62/100*island_width)

			return farness
		end)
	end

	return args.noise_generator[noise_name]
end



function Public.enemies_1(args, spec, no_worms, worm_evo_bonus)
	worm_evo_bonus = worm_evo_bonus or 0

	for x = args.left_top.x, args.left_top.x + 31 do
		for y = args.left_top.y, args.left_top.y + 31 do
			local p = {x = x, y = y}
			local spec2 = spec(p)
			if spec2.placeable and Math.random() < spec2.density_perchunk/(32*32) then
				local memory = Memory.get_crew_memory()
				local enemy_force_name = memory.enemy_force_name

				local rng = Math.random(10)
				if rng >= 4 then
					args.entities[#args.entities + 1] = {name = 'biter-spawner', position = p, force = enemy_force_name, indestructible = spec2.spawners_indestructible or false}
				elseif rng >= 3 then
					args.entities[#args.entities + 1] = {name = 'spitter-spawner', position = p, force = enemy_force_name, indestructible = spec2.spawners_indestructible or false}
				elseif not no_worms then
					local evolution = memory.evolution_factor + worm_evo_bonus

					args.entities[#args.entities + 1] = {name = Common.get_random_worm_type(evolution + 0.05), position = p, force = enemy_force_name}
				end
			end
		end
	end
end


function Public.enemies_specworms_separate(args, spec)

	for x = args.left_top.x, args.left_top.x + 31 do
		for y = args.left_top.y, args.left_top.y + 31 do
			local p = {x = x, y = y}
			local spec2 = spec(p)
			if spec2.placeable and Math.random() < spec2.spawners_density_perchunk/(32*32) then
				local memory = Memory.get_crew_memory()
				local enemy_force_name = memory.enemy_force_name

				local rng = Math.random(10)
				if rng >=8 then
					args.entities[#args.entities + 1] = {name = 'spitter-spawner', position = p, force = enemy_force_name, indestructible = spec2.spawners_indestructible or false}
				else
					args.entities[#args.entities + 1] = {name = 'biter-spawner', position = p, force = enemy_force_name, indestructible = spec2.spawners_indestructible or false}
				end
			elseif spec2.placeable and Math.random() < spec2.worms_density_perchunk/(32*32) then
				local memory = Memory.get_crew_memory()
				local enemy_force_name = memory.enemy_force_name

				local evolution = game.forces[enemy_force_name].evolution_factor

				args.entities[#args.entities + 1] = {name = Common.get_random_worm_type(evolution + 0.05), position = p, force = enemy_force_name}
			end
		end
	end
end

function Public.assorted_structures_1(args, spec)
	local memory = Memory.get_crew_memory()
	local overworldx = memory.overworldx or 0

	local rng = Math.random()
	local left_top = args.left_top

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
			x = avgleft_top.x - 16,
			y = avgleft_top.y - 16,
		}

		local spec2 = spec{x = avgleft_top.x + 16, y = avgleft_top.y + 16}

		if rng < spec2.chanceper4chunks then

			local rng2 = Math.random()
			local struct

			if overworldx <= 120 then
				if rng2 < 20/100 then
					struct = Structures.IslandStructures.ROC.lonely_storage_tank
				elseif rng2 < 40/100 then
					struct = Structures.IslandStructures.MATTISSO.small_crashed_ship
				elseif rng2 < 50/100 then
					struct = Structures.IslandStructures.MATTISSO.small_oilrig_base
				elseif rng2 < 60/100 then
					struct = Structures.IslandStructures.MATTISSO.small_abandoned_refinery
				elseif rng2 < 70/100 then
					struct = Structures.IslandStructures.MATTISSO.small_mining_base
				else
					struct = Structures.IslandStructures.MATTISSO.small_primitive_mining_base
				end
			elseif overworldx <= 240 then
				if rng2 < 30/100 then
					struct = Structures.IslandStructures.ROC.lonely_storage_tank
				elseif rng2 < 40/100 then
					struct = Structures.IslandStructures.MATTISSO.small_crashed_ship
				elseif rng2 < 50/100 then
					struct = Structures.IslandStructures.MATTISSO.small_oilrig_base
				elseif rng2 < 70/100 then
					struct = Structures.IslandStructures.MATTISSO.small_abandoned_refinery
				elseif rng2 < 80/100 then
					struct = Structures.IslandStructures.MATTISSO.small_mining_base
				else
					struct = Structures.IslandStructures.MATTISSO.small_solar_base
				end
			else
				if rng2 < 10/100 then
					struct = Structures.IslandStructures.ROC.lonely_storage_tank
				elseif rng2 < 20/100 then
					struct = Structures.IslandStructures.MATTISSO.small_crashed_ship
				elseif rng2 < 40/100 then
					struct = Structures.IslandStructures.MATTISSO.small_oilrig_base
				elseif rng2 < 50/100 then
					struct = Structures.IslandStructures.MATTISSO.small_abandoned_refinery
				elseif rng2 < 60/100 then
					struct = Structures.IslandStructures.MATTISSO.small_mining_base
				elseif rng2 < 80/100 then
					struct = Structures.IslandStructures.MATTISSO.small_solar_base
				else
					struct = Structures.IslandStructures.MATTISSO.small_roboport_base
				end
			end

			if struct then
				Structures.try_place(struct, args.specials, leftmost_topmost, 64, 64, function(p) return spec(p).placeable end)
			end
		end
	end
end



function Public.random_rock_1(p)
	local rock_raffle = {'sand-rock-big','sand-rock-big','rock-big','rock-big','rock-big','rock-big','rock-huge','rock-huge'}
	local s_rock_raffle = #rock_raffle

	return {name = rock_raffle[Math.random(1, s_rock_raffle)], position = p}
end

function Public.random_tree_1(p)
	local tree_raffle = {
		'tree-01',
		'tree-02',
		'tree-02-red',
		'tree-03',
		'tree-04',
		'tree-05',
		'tree-06',
		'tree-06-brown',
		'tree-07',
		'tree-08',
		'tree-08-brown',
		'tree-08-red',
		'tree-09',
		'tree-09-brown',
		'tree-09-red'
	}
	local s_tree_raffle = #tree_raffle

	return {name = tree_raffle[Math.random(1, s_tree_raffle)], position = p}
end

return Public