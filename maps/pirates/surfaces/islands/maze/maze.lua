-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


-- local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Raffle = require 'maps.pirates.raffle'
-- local Balance = require 'maps.pirates.balance'
local Structures = require 'maps.pirates.structures.structures'
-- local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect
-- local Ores = require 'maps.pirates.ores'
local IslandsCommon = require 'maps.pirates.surfaces.islands.common'
local Hunt = require 'maps.pirates.surfaces.islands.hunt'

local Public = {}
Public.Data = require 'maps.pirates.surfaces.islands.maze.data'


function Public.noises(args)
	local ret = {}

	ret.height = IslandsCommon.island_height_mostly_circular(args)
	ret.maze = args.noise_generator.maze
	ret.farness = IslandsCommon.island_farness_1(args) --isn't available on the iconized pass, only on actual generation; check args.iconized_generation before you use this
	return ret
end

local function maze_wall(args)
	args.tiles[#args.tiles + 1] = { name = 'grass-2', position = args.p }
	if Math.random(1, 2) == 1 then
		args.entities[#args.entities + 1] = IslandsCommon.random_rock_1(args.p)
	else
		local e = IslandsCommon.random_tree_1(args.p)
		e.visible_on_overworld = true
		args.entities[#args.entities + 1] = e
	end
end

local maze_scale = 24

local steps_orthogonal = {
	{ x = 0,           y = -maze_scale },
	{ x = -maze_scale, y = 0 },
	{ x = maze_scale,  y = 0 },
	{ x = 0,           y = maze_scale }
}
local steps_diagonal = {
	{ diagonal = { x = -maze_scale, y = maze_scale }, connection_1 = { x = -maze_scale, y = 0 }, connection_2 = { x = 0, y = maze_scale } },
	{ diagonal = { x = maze_scale, y = -maze_scale }, connection_1 = { x = maze_scale, y = 0 }, connection_2 = { x = 0, y = -maze_scale } },
	{ diagonal = { x = maze_scale, y = maze_scale }, connection_1 = { x = maze_scale, y = 0 }, connection_2 = { x = 0, y = maze_scale } },
	{ diagonal = { x = -maze_scale, y = -maze_scale }, connection_1 = { x = -maze_scale, y = 0 }, connection_2 = { x = 0, y = -maze_scale } }
}

local function get_path_connections_count(lab_cells, p)
	local connections = 0
	for _, m in pairs(steps_orthogonal) do
		if lab_cells[tostring(p.x + m.x) .. '_' .. tostring(p.y + m.y)] then
			connections = connections + 1
		end
	end
	return connections
end

local function labyrinth_determine_walkable_cell(args)
	-- local noises = Public.noises(args)
	-- local mazenoise = noises.maze()
	local reduced_p = { x = args.true_p.x - (args.true_p.x % maze_scale), y = args.true_p.y - (args.true_p.y % maze_scale) }

	if not args.other_map_generation_data.labyrinth_cells then
		args.other_map_generation_data.labyrinth_cells = {}
	end
	local lab_cells = args.other_map_generation_data.labyrinth_cells

	if lab_cells[tostring(reduced_p.x) .. '_' .. tostring(reduced_p.y)] == true then
		return true
	elseif lab_cells[tostring(reduced_p.x) .. '_' .. tostring(reduced_p.y)] == false then
		return false
	else
		-- presumptive
		lab_cells[tostring(reduced_p.x) .. '_' .. tostring(reduced_p.y)] = false

		for _, modifier in pairs(steps_diagonal) do
			if lab_cells[tostring(reduced_p.x + modifier.diagonal.x) .. '_' .. tostring(reduced_p.y + modifier.diagonal.y)] then
				local connection_1 = lab_cells[tostring(reduced_p.x + modifier.connection_1.x) .. '_' .. tostring(reduced_p.y + modifier.connection_1.y)]
				local connection_2 = lab_cells[tostring(reduced_p.x + modifier.connection_2.x) .. '_' .. tostring(reduced_p.y + modifier.connection_2.y)]
				if not connection_1 and not connection_2 then
					return false --sensible corners
				end
			end
		end

		local max_connections = 2
		if Math.random(4) == 1 then max_connections = 3 end

		for _, m in pairs(steps_orthogonal) do
			if get_path_connections_count(lab_cells, { x = reduced_p.x + m.x, y = reduced_p.y + m.y }) >= max_connections then
				return false
			end
		end

		if get_path_connections_count(lab_cells, reduced_p) >= max_connections then
			return false
		end

		-- for _, m in pairs(steps_orthogonal) do
		--     if get_path_connections_count(lab_cells, {x = reduced_p.x + m.x, y = reduced_p.y + m.y}) >= Math.random(2, 3) then
		--         return false
		--     end
		-- end

		-- if get_path_connections_count(lab_cells, reduced_p) >= Math.random(2, 3) then
		--     return false
		-- end

		-- if Math.random(80) == 1 then --dead ends and such
		-- 	log(reduced_p.x .. '_' .. reduced_p.y .. ' is dead end')
		-- 	return false
		-- end

		lab_cells[tostring(reduced_p.x) .. '_' .. tostring(reduced_p.y)] = true
		return true
	end
end

-- local function terrain_entity_at_relative_position(args, entity)
-- 	local relative_p = {x = args.true_p.x % maze_scale, y = args.true_p.y % maze_scale}

-- 	if relative_p.x >= entity.rel_p.x and relative_p.x < entity.rel_p.x+1 and relative_p.y >= entity.rel_p.y and relative_p.y < entity.rel_p.y+1 then
-- 		entity.rel_p = nil
-- 		entity.position = args.p
-- 		args.entities[#args.entities + 1] = entity
-- 	end
-- end

local free_labyrinth_cell_raffle = {
	empty = 16.5,
	maze_labs = 0.6,
	maze_defended_camp = 0.85,
	maze_undefended_camp = 0.25,
	maze_worms = 0.8,
	small_abandoned_refinery = 0.05,
	small_roboport_base = 0.05,
	maze_belts_1 = 0.28,
	maze_belts_2 = 0.28,
	maze_belts_3 = 0.28,
	maze_belts_4 = 0.28,
	maze_mines = 0.1,
	maze_treasure = 0.92,
	-- maze_treasure = 0.74,
}

local function free_labyrinth_cell_type(args)
	local reduced_p = { x = args.true_p.x - (args.true_p.x % maze_scale), y = args.true_p.y - (args.true_p.y % maze_scale) }

	if not args.other_map_generation_data.free_labyrinth_cell_types then
		args.other_map_generation_data.free_labyrinth_cell_types = {}
	end
	local cell_types = args.other_map_generation_data.free_labyrinth_cell_types

	local type
	if cell_types[tostring(reduced_p.x) .. '_' .. tostring(reduced_p.y)] then
		type = cell_types[tostring(reduced_p.x) .. '_' .. tostring(reduced_p.y)]
	end

	if not type then
		type = Raffle.raffle2(free_labyrinth_cell_raffle)
		cell_types[tostring(reduced_p.x) .. '_' .. tostring(reduced_p.y)] = type
	end

	return type
end

local function free_labyrinth_cell_contents(args)
	-- local memory = Memory.get_crew_memory()

	-- local noises = Public.noises(args)
	-- local mazenoise = noises.maze()
	local relative_p = { x = args.true_p.x % maze_scale, y = args.true_p.y % maze_scale }
	-- local reduced_p = {x = args.true_p.x - relative_p.x, y = args.true_p.y - relative_p.y}

	local type = free_labyrinth_cell_type(args)

	if relative_p.x >= maze_scale / 2 - 0.5 and relative_p.x < maze_scale / 2 + 0.5 and relative_p.y >= maze_scale / 2 - 0.5 and relative_p.y < maze_scale / 2 + 0.5 then --should fire just once, and only if the center is included
		-- terrain_entity_at_relative_position(args, {name = 'lab', rel_p = {x = 15, y = 15}, force = memory.ancient_friendly_force})
		if type == 'empty' then
			return nil
		else
			Structures.tryAddStructureByName(args.specials, type, args.p)
		end
	end
end





function Public.terrain(args)
	local noises = Public.noises(args)
	local p = args.p

	if IslandsCommon.place_water_tile(args) then return end

	if noises.height(p) < 0 then
		args.tiles[#args.tiles + 1] = { name = 'water', position = args.p }
		return
	end

	if args.iconized_generation then
		maze_wall(args)
	else
		if noises.height(p) < 0 + Math.max(0, 0.3 - 2 * noises.farness(p)) then
			if args.true_p.x < 0 and Math.abs(args.true_p.y) < 3 then
				args.tiles[#args.tiles + 1] = { name = 'stone-path', position = args.p }
			else
				args.tiles[#args.tiles + 1] = { name = 'sand-1', position = args.p }
			end
			if Math.random(500) == 1 then
				args.specials[#args.specials + 1] = { name = 'buried-treasure', position = args.p }
			end
		elseif noises.height(p) < 0.1 + Math.max(0, 0.3 - 2 * noises.farness(p) / 2) then
			if args.true_p.x < 0 and Math.abs(args.true_p.y) < 3 then
				args.tiles[#args.tiles + 1] = { name = 'stone-path', position = args.p }
			else
				maze_wall(args)
			end
		else -- maze itself
			args.tiles[#args.tiles + 1] = { name = 'grass-1', position = args.p }

			if labyrinth_determine_walkable_cell(args) then
				free_labyrinth_cell_contents(args)
			else
				maze_wall(args)
			end
		end
	end
end

function Public.chunk_structures(args)
	local spec = function (p)
		local noises = Public.noises { p = p, noise_generator = args.noise_generator, static_params = args.static_params, seed = args.seed }

		return {
			placeable = noises.farness(p) > 0.66,
			-- spawners_indestructible = noises.farness(p) > 0.7,
			spawners_indestructible = false,
			density_perchunk = 150 * Math.slopefromto(noises.farness(p), 0.3, 0.9) ^ 2 * args.biter_base_density_scale,
		}
	end

	IslandsCommon.enemies_1(args, spec)
end

-- function Public.break_rock(surface, p, entity_name)
-- 	-- return Ores.try_ore_spawn(surface, p, entity_name)
-- end


function Public.generate_silo_setup_position(points_to_avoid)
	return Hunt.silo_setup_position(points_to_avoid)
end

return Public
