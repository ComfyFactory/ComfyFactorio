-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


-- local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
-- local Balance = require 'maps.pirates.balance'
-- local Structures = require 'maps.pirates.structures.structures'
-- local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect
local Ores = require 'maps.pirates.ores'
local IslandsCommon = require 'maps.pirates.surfaces.islands.common'
local Hunt = require 'maps.pirates.surfaces.islands.hunt'

local Public = {}
Public.Data = require 'maps.pirates.surfaces.islands.first.data'


function Public.noises(args)
	local ret = {}

	ret.height = IslandsCommon.island_height_1(args)
	ret.forest = args.noise_generator.forest
	ret.forest_abs = function (p) return Math.abs(ret.forest(p)) end
	ret.forest_abs_suppressed = function (p) return ret.forest_abs(p) - 1 * Math.slopefromto(ret.height(p), 0.35, 0.1) end
	ret.rock = args.noise_generator.rock
	ret.rock_abs = function (p) return Math.abs(ret.rock(p)) end
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

	if noises.height(p) < 0.1 then
		args.tiles[#args.tiles + 1] = { name = 'sand-1', position = args.p }
		-- if args.specials and noises.farness(p) > 0.0001 and noises.farness(p) < 0.6 and Math.random(150) == 1 then
		-- 	args.specials[#args.specials + 1] = {name = 'buried-treasure', position = args.p}
		-- end
	elseif noises.height(p) < 0.16 then
		args.tiles[#args.tiles + 1] = { name = 'grass-4', position = args.p }
	else
		if noises.forest_abs_suppressed(p) > 0.5 and noises.rock(p) < 0.3 then
			args.tiles[#args.tiles + 1] = { name = 'grass-3', position = args.p }
		elseif noises.forest_abs_suppressed(p) > 0.2 and noises.rock(p) < 0.3 then
			args.tiles[#args.tiles + 1] = { name = 'grass-2', position = args.p }
		else
			args.tiles[#args.tiles + 1] = { name = 'grass-1', position = args.p }
		end
	end

	if noises.height(p) > 0.2 then
		if noises.forest_abs(p) > 0.65 then
			if (not args.iconized_generation) and Math.random(1600) == 1 then
				args.specials[#args.specials + 1] = { name = 'chest', position = args.p }
			else
				local treedensity = 0.4 * Math.slopefromto(noises.forest_abs_suppressed(p), 0.6, 0.85)
				if noises.forest(p) > 0.87 then
					if Math.random(1, 100) < treedensity * 100 then args.entities[#args.entities + 1] = { name = 'tree-01', position = args.p, visible_on_overworld = true } end
				elseif noises.forest(p) < -1.4 then
					if Math.random(1, 100) < treedensity * 100 then args.entities[#args.entities + 1] = { name = 'tree-03', position = args.p, visible_on_overworld = true } end
				else
					if Math.random(1, 100) < treedensity * 100 then args.entities[#args.entities + 1] = { name = 'tree-02', position = args.p, visible_on_overworld = true } end
				end
			end
		end
	end

	if noises.forest_abs_suppressed(p) < 0.6 then
		if noises.height(p) > 0.12 then
			local rockdensity = 0.0018 * Math.slopefromto(noises.rock_abs(p), -0.15, 0.3)
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

function Public.chunk_structures(args)
	local spec = function (p)
		local noises = Public.noises { p = p, noise_generator = args.noise_generator, static_params = args.static_params, seed = args.seed }

		return {
			placeable = noises.farness(p) > 0.4,
			density_perchunk = 28 * Math.slopefromto(noises.farness(p), 0.4, 1) ^ 2,
		}
	end

	IslandsCommon.enemies_1(args, spec, false, 0.4)
end

function Public.break_rock(surface, p, entity_name)
	return Ores.try_ore_spawn(surface, p, entity_name, 8)
end

function Public.generate_silo_setup_position(points_to_avoid)
	return Hunt.silo_setup_position(points_to_avoid)
end

return Public
