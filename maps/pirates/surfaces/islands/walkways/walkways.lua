-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio.


local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
-- local Structures = require 'maps.pirates.structures.structures'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
-- local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect
-- local Data = require 'maps.pirates.surfaces.islands.walkways.data'
local Ores = require 'maps.pirates.ores'
local IslandsCommon = require 'maps.pirates.surfaces.islands.common'
local IslandEnum = require 'maps.pirates.surfaces.islands.island_enum'
local Hunt = require 'maps.pirates.surfaces.islands.hunt'

local Public = {}
Public.Data = require 'maps.pirates.surfaces.islands.walkways.data'


function Public.noises(args)
	local ret = {}

	ret.height = IslandsCommon.island_height_1(args)
	ret.walkways = function (p) return Math.abs(args.noise_generator.walkways(p)) end
	ret.rock = args.noise_generator.rock
	ret.rock_abs = function (p) return Math.abs(ret.rock(p)) end
	ret.mood = args.noise_generator.mood
	ret.farness = IslandsCommon.island_farness_1(args) --isn't available on the iconized pass, only on actual generation; check args.iconized_generation before you use this
	return ret
end

function Public.terrain(args)
	local memory = Memory.get_crew_memory()
	local noises = Public.noises(args)
	local p = args.p

	if IslandsCommon.place_water_tile(args) then return end

	if noises.height(p) < 0.05 then
		args.tiles[#args.tiles + 1] = {name = 'water-mud', position = p}

	elseif noises.height(p) < 0.1 then
		args.tiles[#args.tiles + 1] = {name = 'landfill', position = p}
		if Math.random() < 1/50 then
			args.decoratives[#args.decoratives + 1] = {name = 'brown-asterisk', position = p, amount = 1}
		end
	else
		if noises.walkways(p) < 0.34 then
			args.tiles[#args.tiles + 1] = {name = 'landfill', position = p}


			if noises.walkways(p) <= 0.01 then
				if Math.random(40) == 1 then
					args.entities[#args.entities + 1] = {name = 'big-scorchmark-tintable', position = p}
				end
			elseif noises.walkways(p) <= 0.02 then
				if Math.random(40) == 1 then
					args.entities[#args.entities + 1] = {name = 'medium-scorchmark-tintable', position = p}
				end
			end

			if Math.abs(noises.rock(p)) < 0.3 then
				if Math.random() < 1/20 then
					args.decoratives[#args.decoratives + 1] = {name = 'red-pita', position = p, amount = 1}
				end
			end

			if noises.rock(p) > 0.2 then
				if Math.random() < (0.25 - noises.walkways(p))/8 then
					args.entities[#args.entities + 1] = IslandsCommon.random_rock_1(p)
				end
			elseif Math.random() < -(noises.rock(p) + 0.3)/2 then
				args.decoratives[#args.decoratives + 1] = {name = 'red-croton', position = p, amount = 1}
			end

			if noises.height(p) > 0.12 and noises.walkways(p) < 0.1 and noises.rock_abs(p) < 0.07 then
				local amount = Math.ceil(180 * Math.min(noises.height(p), 0.2) * Balance.island_richness_avg_multiplier(args.overworldx) * Math.random_float_in_range(0.8, 1.2))
				args.entities[#args.entities + 1] = {name = 'coal', position = args.p, amount = amount}
			end

		else
			args.tiles[#args.tiles + 1] = {name = 'water-shallow', position = p}

			if math.random(1, 512) == 1 then
				local name = Common.get_random_worm_type(memory.evolution_factor)
				local force = memory.enemy_force_name
				args.entities[#args.entities + 1] = {name = name, position = p, force = force}
			elseif math.random(1, 256) == 1 then
				args.entities[#args.entities + 1] = {name = 'fish', position = p}
			end
		end
	end
end

function Public.chunk_structures(args)

	local spec = function(p)
		local noises = Public.noises{p = p, noise_generator = args.noise_generator, static_params = args.static_params, seed = args.seed}

		return {
			placeable = noises.walkways(p) < 0.30,
			density_perchunk = 15 * (noises.farness(p) - 0.1)^3 * args.biter_base_density_scale,
			spawners_indestructible = true,
		}
	end
	IslandsCommon.enemies_1(args, spec)

	-- local spec2 = function(p)
	-- 	local noises = Public.noises{p = p, noise_generator = args.noise_generator, static_params = args.static_params, seed = args.seed}

	-- 	return {
	-- 		-- placeable = noises.height(p) > 0.1 and noises.walkways(p) < 0.3,
	-- 		placeable_strict = noises.height(p) > 0.1 and noises.walkways(p) < 0.3,
	-- 		placeable_optional = true,
	-- 		chanceper4chunks = 1/2,
	-- 	}
	-- end
	-- IslandsCommon.assorted_structures_1(args, spec2)
end


function Public.generate_silo_setup_position(points_to_avoid)
	-- local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]

	local first_silo_pos = Hunt.silo_setup_position(points_to_avoid, 0.2)

	local silo_count = Balance.silo_count()
	if first_silo_pos then
		for i = 1, silo_count do
			local tiles = {}
			local silo_pos = {x = first_silo_pos.x + 9 * (i-1), y = first_silo_pos.y}
			for x = -7.5, 7.5, 1 do
				for y = -7.5, 7.5, 1 do
					tiles[#tiles + 1] = {name = CoreData.world_concrete_tile, position = {x = silo_pos.x + x, y = silo_pos.y + y}}
				end
			end
			Common.ensure_chunks_at(surface, first_silo_pos, 1)
			surface.set_tiles(tiles, true)
		end

		return first_silo_pos
	end
end


function Public.break_rock(surface, p, entity_name)
	return Ores.try_ore_spawn(surface, p, entity_name)
end


local function walkways_tick()
	for _, id in pairs(Memory.get_global_memory().crew_active_ids) do
		Memory.set_working_id(id)
		local memory = Memory.get_crew_memory()
		local destination = Common.current_destination()

		if destination.subtype == IslandEnum.enum.WALKWAYS then
			for _, player in pairs(game.connected_players) do
				if player.force.name == memory.force_name and player.surface == game.surfaces[destination.surface_name] and player.character and player.character.valid and game.surfaces[destination.surface_name].get_tile(player.position).name == 'water-shallow' then
					player.character.damage(Balance.walkways_frozen_pool_damage, game.forces['environment'], 'fire')
					if not (player.character and player.character.valid) then
						Common.notify_force(player.force, {'pirates.death_froze',player.name})
					end
				end
			end
		end
	end
end

local event = require 'utils.event'
event.on_nth_tick(20, walkways_tick)


return Public