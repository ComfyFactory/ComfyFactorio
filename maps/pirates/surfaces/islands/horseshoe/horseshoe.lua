
local ores = require "maps.pirates.ores"

local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
local Structures = require 'maps.pirates.structures.structures'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local inspect = require 'utils.inspect'.inspect
local Ores = require 'maps.pirates.ores'
local IslandsCommon = require 'maps.pirates.surfaces.islands.common'
local Hunt = require 'maps.pirates.surfaces.islands.hunt'

local Public = {}
Public.Data = require 'maps.pirates.surfaces.islands.horseshoe.data'


function Public.noises(args)
	local ret = {}

	ret.height = IslandsCommon.island_height_horseshoe(args)
	ret.forest = args.noise_generator.forest
	ret.forest_abs = function (p) return Math.abs(ret.forest(p)) end
	ret.forest_abs_suppressed = function (p) return ret.forest_abs(p) - 2 * Math.slopefromto(ret.height(p), 0.2, 0.12) end
	ret.rock = args.noise_generator.rock
	ret.rock_abs = function (p) return Math.abs(ret.rock(p)) end
	ret.mood = args.noise_generator.mood
	ret.farness = IslandsCommon.island_farness_horseshoe(args)
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
	
	if noises.height(p) < 0.05 then
		args.tiles[#args.tiles + 1] = {name = 'sand-1', position = args.p}
		if args.specials and noises.farness(p) > 0.02 and noises.farness(p) < 0.6 and Math.random(400) == 1 then
			args.specials[#args.specials + 1] = {name = 'buried-treasure', position = args.p}
		end
	elseif noises.height(p) < 0.12 then
		args.tiles[#args.tiles + 1] = {name = 'sand-2', position = args.p}
	else
		if noises.forest_abs_suppressed(p) > 0.3 and noises.rock(p) < -0.1 then
			args.tiles[#args.tiles + 1] = {name = 'dirt-1', position = args.p}
		else
			if noises.mood(p) > 0.66 then
				args.tiles[#args.tiles + 1] = {name = 'water-shallow', position = args.p}
			else
				args.tiles[#args.tiles + 1] = {name = 'sand-3', position = args.p}
			end
		end
	end

	if args.specials and noises.height(p) > 0 and Math.random(6000) == 1 then --but has lots of chests due to spawning anywhere
		args.specials[#args.specials + 1] = {name = 'chest', position = args.p}
	elseif noises.height(p) > 0.02 then
		if noises.forest_abs_suppressed(p) > 0.58 then
			local forest_noise = noises.forest(p)
			local treedensity
			if forest_noise > 0 then
				treedensity = 0.5 * Math.slopefromto(noises.forest_abs_suppressed(p), 0.58, 0.75)
				if Math.random(1,100) < treedensity*100 then args.entities[#args.entities + 1] = {name = 'tree-06', position = args.p, visible_on_overworld = true} end
			elseif noises.forest_abs_suppressed(p) > 0.68 then
				treedensity = 0.5 * Math.slopefromto(forest_noise, -0.7, -0.75)
				if Math.random(1,100) < treedensity*100 then args.entities[#args.entities + 1] = {name = 'tree-08-brown', position = args.p, visible_on_overworld = true} end
			end
		end
	end


	if noises.forest_abs_suppressed(p) < 0.45 then

		if noises.height(p) > 0.05 then
			if noises.rock_abs(p) > 0.15 then
				local rockdensity = 1/500 * Math.slopefromto(noises.rock_abs(p), 0.15, 0.5)
				if noises.height(p) < 0.12 then rockdensity = rockdensity * 3 end
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

	if noises.height(p) > 0.18 and noises.mood(p) > 0.2 then
		if noises.forest_abs(p) < 0.2 and noises.rock_abs(p) > 1.5 then
			args.entities[#args.entities + 1] = {name = 'coal', position = args.p, amount = 10}
		end
	end
end


function Public.chunk_structures(args)

	local spec = function(p)
		local noises = Public.noises{p = p, noise_generator = args.noise_generator, static_params = args.static_params, seed = args.seed}

		return {
			placeable = noises.farness(p) > 0.35,
			spawners_indestructible = false,
			-- spawners_indestructible = noises.farness(p) > 0.7,
			density_perchunk = 10 * Math.slopefromto(noises.mood(p), 0.12, -0.18) * Math.slopefromto(noises.farness(p), 0.35, 1) * args.biter_base_density_scale,
		}
	end

	IslandsCommon.enemies_1(args, spec)

	-- local spec2 = function(p)
	-- 	local noises = Public.noises{p = p, noise_generator = args.noise_generator, static_params = args.static_params, seed = args.seed}

	-- 	return {
	-- 		placeable = noises.height(p) >= 0 and noises.forest_abs_suppressed(p) < 0.3 + Math.max(0, 0.2 - noises.height(p)),
	-- 		chanceper4chunks = 0.5 * Math.slopefromto(noises.farness(p), 0.1, 0.4) * Math.slopefromto(noises.mood(p), 0, 0.25),
	-- 	}
	-- end
	-- IslandsCommon.assorted_structures_1(args, spec2)
end


function Public.break_rock(surface, p, entity_name)
	return Ores.try_ore_spawn(surface, p, entity_name)
end


function Public.generate_silo_setup_position()
	return Hunt.silo_setup_position(0, 30)
end


return Public