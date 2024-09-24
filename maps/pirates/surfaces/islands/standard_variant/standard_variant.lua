-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


-- local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
-- local Balance = require 'maps.pirates.balance'
-- local Structures = require 'maps.pirates.structures.structures'
-- local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect
-- local Ores = require 'maps.pirates.ores'
local IslandsCommon = require 'maps.pirates.surfaces.islands.common'
local Hunt = require 'maps.pirates.surfaces.islands.hunt'

local Public = {}
Public.Data = require 'maps.pirates.surfaces.islands.standard_variant.data'


function Public.noises(args)
	local ret = {}

	ret.height = IslandsCommon.island_height_1(args)
	ret.forest = args.noise_generator.forest
	ret.forest_abs = function (p) return Math.abs(ret.forest(p)) end
	ret.forest_abs_suppressed = function (p) return ret.forest_abs(p) - 1 * Math.slopefromto(ret.height(p), 0.17, 0.11) end
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
		args.tiles[#args.tiles + 1] = { name = 'water', position = args.p }
		return
	end

	if noises.height(p) < 0.04 then
		args.tiles[#args.tiles + 1] = { name = 'sand-1', position = args.p }
		if (not args.iconized_generation) and noises.farness(p) > 0.02 and noises.farness(p) < 0.6 and Math.random(500) == 1 then
			args.specials[#args.specials + 1] = { name = 'buried-treasure', position = args.p }
		end
	elseif noises.height(p) < 0.05 then
		args.tiles[#args.tiles + 1] = { name = 'sand-2', position = args.p }
	elseif noises.height(p) < 0.11 then
		args.tiles[#args.tiles + 1] = { name = 'dry-dirt', position = args.p }
	elseif noises.height(p) < 0.12 then
		args.tiles[#args.tiles + 1] = { name = 'grass-4', position = args.p }
	else
		if noises.forest_abs_suppressed(p) > 0.3 and noises.rock(p) < 0.3 then
			args.tiles[#args.tiles + 1] = { name = 'dirt-7', position = args.p }
		elseif noises.forest_abs_suppressed(p) > 0.15 and noises.rock(p) < 0.3 then
			args.tiles[#args.tiles + 1] = { name = 'grass-4', position = args.p }
		else
			args.tiles[#args.tiles + 1] = { name = 'grass-3', position = args.p }
		end
	end

	if noises.height(p) > 0.11 then
		if noises.forest_abs_suppressed(p) > 0.7 then
			if (not args.iconized_generation) and noises.forest_abs_suppressed(p) < 1 and Math.random(700) == 1 then -- high amounts of this
				args.specials[#args.specials + 1] = { name = 'chest', position = args.p }
			else
				local forest_noise = noises.forest(p)
				local treedensity = 0.7 * Math.slopefromto(noises.forest_abs_suppressed(p), 0.61, 0.76)
				if forest_noise > 0 then
					if noises.rock(p) > 0.05 then
						if Math.random(1, 100) < treedensity * 100 then args.entities[#args.entities + 1] = { name = 'tree-08-red', position = args.p, visible_on_overworld = true } end
					elseif noises.rock(p) < -0.05 then
						if Math.random(1, 100) < treedensity * 100 then args.entities[#args.entities + 1] = { name = 'tree-09-brown', position = args.p } end
					end
				elseif forest_noise < -1.2 then
					if Math.random(1, 100) < treedensity * 100 then args.entities[#args.entities + 1] = { name = 'tree-09', position = args.p, visible_on_overworld = true } end
				else
					if Math.random(1, 100) < treedensity * 100 then args.entities[#args.entities + 1] = { name = 'tree-02-red', position = args.p } end
				end
			end
		end
	end

	if noises.forest_abs_suppressed(p) < 0.45 then
		if noises.height(p) > 0.12 then
			if noises.rock_abs(p) > 0.25 then
				local rockdensity = 1 / 600 * Math.slopefromto(noises.rock_abs(p), 0.25, 0.6) + 1 / 5 * Math.slopefromto(noises.rock_abs(p), 2.4, 2.6)
				local rockrng = Math.random()
				if rockrng < rockdensity then
					args.entities[#args.entities + 1] = IslandsCommon.random_rock_1(args.p)
				elseif rockrng < rockdensity * 1.5 then
					args.decoratives[#args.decoratives + 1] = { name = 'rock-medium', position = args.p }
				elseif rockrng < rockdensity * 2 then
					args.decoratives[#args.decoratives + 1] = { name = 'rock-small', position = args.p }
				elseif rockrng < rockdensity * 2.5 then
					args.decoratives[#args.decoratives + 1] = { name = 'rock-tiny', position = args.p }
				end
			end
		end
	end

	if noises.height(p) > 0.18 and noises.mood(p) > 0.3 then
		if noises.forest_abs(p) < 0.2 and noises.rock_abs(p) > 1.5 then
			args.entities[#args.entities + 1] = { name = 'coal', position = args.p, amount = 7 }
		end
	end
end

function Public.chunk_structures(args)
	local spec = function (p)
		local noises = Public.noises { p = p, noise_generator = args.noise_generator, static_params = args.static_params, seed = args.seed }

		return {
			placeable = noises.farness(p) > 0.3,
			-- spawners_indestructible = false,
			spawners_indestructible = noises.farness(p) > 0.7,
			density_perchunk = 25 * Math.slopefromto(noises.mood(p), 0.16, -0.1) * Math.slopefromto(noises.farness(p), 0.3, 1) ^ 2 * args.biter_base_density_scale,
		}
	end

	IslandsCommon.enemies_1(args, spec)

	local spec2 = function (p)
		local noises = Public.noises { p = p, noise_generator = args.noise_generator, static_params = args.static_params, seed = args.seed }

		return {
			-- placeable = noises.height(p) >= 0 and noises.forest_abs_suppressed(p) < 0.3 + Math.max(0, 0.2 - noises.height(p)),
			placeable_strict = noises.height(p) >= 0.05,
			placeable_optional = noises.forest_abs_suppressed(p) < 0.3 + Math.max(0, 0.2 - noises.height(p)),
			chanceper4chunks = 0.1 * Math.slopefromto(noises.farness(p), 0.1, 0.4) * Math.slopefromto(noises.mood(p), 0, 0.25),
		}
	end
	IslandsCommon.assorted_structures_1(args, spec2)
end

-- function Public.break_rock(surface, p, entity_name)
-- 	-- return Ores.try_ore_spawn(surface, p, entity_name)
-- end


function Public.generate_silo_setup_position(points_to_avoid)
	return Hunt.silo_setup_position(points_to_avoid)
end

return Public
