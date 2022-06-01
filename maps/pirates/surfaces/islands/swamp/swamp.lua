-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
-- local Balance = require 'maps.pirates.balance'
local Structures = require 'maps.pirates.structures.structures'
local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect
local Ores = require 'maps.pirates.ores'
local IslandsCommon = require 'maps.pirates.surfaces.islands.common'
local Hunt = require 'maps.pirates.surfaces.islands.hunt'

local Public = {}
Public.Data = require 'maps.pirates.surfaces.islands.swamp.data'


function Public.noises(args)
	local ret = {}

	ret.height = IslandsCommon.island_height_1(args)
	ret.forest = args.noise_generator.forest
	ret.forest_abs = function (p) return Math.abs(ret.forest(p)) end
	ret.forest_abs_suppressed = function (p) return ret.forest_abs(p) - 1 * Math.slopefromto(ret.height(p), 0.35, 0.1) end
	ret.terrain = args.noise_generator.terrain
	ret.terrain_abs = function (p) return Math.abs(ret.terrain(p)) end
	ret.rock = args.noise_generator.rock
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

	local land = true

	if noises.height(p) < 0.03 then
		args.tiles[#args.tiles + 1] = {name = 'water-shallow', position = args.p}
		land = false
	-- elseif noises.height(p) < 0.07 then
	-- 	args.tiles[#args.tiles + 1] = {name = 'grass-4', position = args.p}
	else
		if noises.terrain(p) < 0.44 then
			args.tiles[#args.tiles + 1] = {name = 'grass-1', position = args.p}
		elseif noises.terrain(p) < 0.59 then
			args.tiles[#args.tiles + 1] = {name = 'grass-2', position = args.p}
		else
			args.tiles[#args.tiles + 1] = {name = 'water-mud', position = args.p}
			land = false
		end
	end

	if land then
		if (not args.iconized_generation) and Math.random(2500) == 1 then
			args.specials[#args.specials + 1] = {name = 'chest', position = args.p}
		else
			if noises.forest_abs(p) > 0.15 then
				local treedensity = 0.08 * Math.slopefromto(noises.forest_abs_suppressed(p), 0.3, 0.6) + 0.3 * Math.slopefromto(noises.forest_abs_suppressed(p), 0.65, 1.0)
				if noises.forest(p) > 1.3 then
					if Math.random(1,100) < treedensity*100 then args.entities[#args.entities + 1] = {name = 'tree-09-brown', position = args.p} end
				else
					if Math.random(1,100) < treedensity*100 then args.entities[#args.entities + 1] = {name = 'tree-08', position = args.p, visible_on_overworld = true} end
				end

				if noises.forest_abs_suppressed(p) < 0.7 then

					if noises.height(p) > 0.12 then
						if noises.rock_abs(p) > -0.15 then
							local rockdensity = 1/600 * Math.slopefromto(noises.rock_abs(p), 0.22, 0.6) + 1/5 * Math.slopefromto(noises.rock_abs(p), 1.6, 1.8)
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
			end


			if noises.mood(p) > 0.3 then
				local density = 0.001 * Math.slopefromto(noises.rock_abs(p), 0.25, 0.4)
				local rng = Math.random()
				if rng < density then
					args.decoratives[#args.decoratives + 1] = {name = 'shroom-decal', position = args.p}
				end
			end

			if noises.mood(p) < -0.3 then
				local rng = Math.random()
				if rng < 0.0015 then
					args.decoratives[#args.decoratives + 1] = {name = 'lichen-decal', position = args.p}
				end
			end

			local rng = Math.random()
			if rng < 0.004 then
				args.decoratives[#args.decoratives + 1] = {name = 'green-asterisk', position = args.p}
			end
		end
	end
end


function Public.chunk_structures(args)

	local spec = function(p)
		local noises = Public.noises{p = p, noise_generator = args.noise_generator, static_params = args.static_params, seed = args.seed}

		return {
			placeable = noises.farness(p) > 0.3,
			-- spawners_indestructible = noises.farness(p) > 0.75,
			spawners_indestructible = false,
			spawners_density_perchunk = 100 * Math.slopefromto(noises.mood(p), 0.7, 0.5) * Math.slopefromto(noises.farness(p), 0.35, 1)^2 * args.biter_base_density_scale,
			worms_density_perchunk = 60 * Math.slopefromto(noises.mood(p), 0.7, 0.5) * Math.slopefromto(noises.farness(p), 0.25, 1)^2 * args.biter_base_density_scale,
		}
	end

	IslandsCommon.enemies_specworms_separate(args, spec)

	local spec2 = function(p)
		local noises = Public.noises{p = p, noise_generator = args.noise_generator, static_params = args.static_params, seed = args.seed}

		return {
			placeable = noises.height(p) > 0.05,
			chanceperchunk = 0.25 * Math.slopefromto(noises.farness(p), 0.05, 0.15),
		}
	end
	Public.swamp_structures(args, spec2)
end


function Public.swamp_structures(args, spec)
	-- local memory = Memory.get_crew_memory()
	-- local overworldx = memory.overworldx or 0

	local rng = Math.random()
	local left_top = args.left_top

	local spec2 = spec{x = left_top.x + 16, y = left_top.y + 16}

	if rng < spec2.chanceperchunk then

		local struct
		struct = Structures.IslandStructures.ROC.swamp_lonely_storage_tank

		if struct then
			Structures.try_place(struct, args.specials, left_top, 64, 64, function(p) return spec(p).placeable end)
		end
	end
end



function Public.break_rock(surface, p, entity_name)
	return Ores.try_ore_spawn(surface, p, entity_name)
end


function Public.generate_silo_setup_position()
	return Hunt.silo_setup_position()
end


local function swamp_tick()
	for _, id in pairs(Memory.get_global_memory().crew_active_ids) do
		Memory.set_working_id(id)
		local memory = Memory.get_crew_memory()
		local destination = Common.current_destination()

		if destination.subtype and destination.subtype == IslandsCommon.enum.SWAMP then
			if memory.boat and memory.boat.surface_name and memory.boat.surface_name == destination.surface_name then
				local surface = game.surfaces[destination.surface_name]
				if not (surface and surface.valid) then return end

				local island_center = destination.static_params.islandcenter_position
				local width = destination.static_params.width
				local height = destination.static_params.height

				local area = width*height

				local period = 5 * Math.ceil(7 / (area/(330*330)))

				if game.tick % period == 0 then
					local random_x = Math.random(island_center.x - width/2, island_center.x + width/2)
					local random_y = Math.random(island_center.y - height/2, island_center.y + height/2)
					local random_p = {x = random_x, y = random_y}

					local tile = surface.get_tile(random_x, random_y)
					if not (tile and tile.valid) then return end

					if tile.name == 'water-mud' then
						local nearby_characters = surface.find_entities_filtered{position = random_p, radius = 66, name = 'character'}
						local nearby_characters_count = #nearby_characters
						if nearby_characters_count >= 1 then
							Common.create_poison_clouds(surface, random_p)
							if Math.random(1, 3) == 1 then
								local random_angles = {Math.rad(Math.random(359))}
								Common.create_poison_clouds(surface, {x = random_x + 24 * Math.cos(random_angles[1]), y = random_y + 24 * Math.sin(random_angles[1])})
							end
						end
					end
				end
			end
		end
	end
end



local event = require 'utils.event'
event.on_nth_tick(5, swamp_tick)


return Public