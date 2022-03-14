
local ores = require "maps.pirates.ores"

local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local CoreData = require 'maps.pirates.coredata'
local Balance = require 'maps.pirates.balance'
local Structures = require 'maps.pirates.structures.structures'
local Common = require 'maps.pirates.common'
local Effects = require 'maps.pirates.effects'
local Utils = require 'maps.pirates.utils_local'
local inspect = require 'utils.inspect'.inspect
local Ores = require 'maps.pirates.ores'
local IslandsCommon = require 'maps.pirates.surfaces.islands.common'
local Hunt = require 'maps.pirates.surfaces.islands.hunt'

local Public = {}
Public.Data = require 'maps.pirates.surfaces.islands.radioactive.data'


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
	
	if noises.height(p) < 0.05 then
		args.tiles[#args.tiles + 1] = {name = 'sand-1', position = args.p}
		if (not args.iconized_generation) and noises.farness(p) > 0.02 and noises.farness(p) < 0.6 and Math.random(500) == 1 then
			args.specials[#args.specials + 1] = {name = 'buried-treasure', position = args.p}
		end
	else
		if Math.random() < Math.min(0.4,noises.height(p)) then
			args.decoratives[#args.decoratives + 1] = {name = 'white-desert-bush', position = p, amount = 1}
		elseif Math.random() > Math.max(0.8,1.2-noises.height(p)) then
			args.decoratives[#args.decoratives + 1] = {name = 'green-bush-mini', position = p, amount = 1}
		end
		if noises.height(p) < 0.33 then
			args.tiles[#args.tiles + 1] = {name = 'sand-2', position = args.p}
		elseif noises.height(p) < 0.35 then
			args.tiles[#args.tiles + 1] = {name = 'dirt-5', position = args.p}
		else
			if noises.height_background(p) > 0.4 then
				args.tiles[#args.tiles + 1] = {name = 'nuclear-ground', position = args.p}
			else
				args.tiles[#args.tiles + 1] = {name = 'dirt-4', position = args.p}
			end
		end
	end

	if noises.forest_abs_suppressed(p) > 1 then
		local treedensity = 0.02 * Math.slopefromto(noises.forest_abs_suppressed(p), 1, 1.1)
		if noises.forest(p) > 1.4 then
			if Math.random(1,100) < treedensity*100 then args.entities[#args.entities + 1] = {name = 'dead-grey-trunk', position = args.p, visible_on_overworld = true} end
		elseif noises.forest(p) < -0.95 then
			if Math.random(1,100) < treedensity*100 then args.entities[#args.entities + 1] = {name = 'dry-tree', position = args.p, visible_on_overworld = true} end
		end
	end
	
	if noises.forest_abs_suppressed(p) < 0.65 then
		if noises.height(p) > 0.12 then
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

	if noises.forest_abs_suppressed(p) < 0.8 and noises.height(p) > 0.35 then
		if noises.ore(p) > 1 then
			args.entities[#args.entities + 1] = {name = 'uranium-ore', position = args.p, amount = 2000}
		end
	end

	if noises.forest_abs_suppressed(p) < 0.8 and noises.height(p) < 0.35 and noises.height(p) > 0.05 then
		if noises.ore(p) < -1.5 then
			args.entities[#args.entities + 1] = {name = 'stone', position = args.p, amount = 1000}
		elseif noises.ore(p) < 0.005 and noises.ore(p) > -0.005 then
			if noises.ore(p) > 0 then
				args.entities[#args.entities + 1] = {name = 'coal', position = args.p, amount = 10}
			else
				args.entities[#args.entities + 1] = {name = 'copper-ore', position = args.p, amount = 100}
			end
		end
	end
end




function Public.chunk_structures(args)

	local spec = function(p)
		local noises = Public.noises{p = p, noise_generator = args.noise_generator, static_params = args.static_params, seed = args.seed}

		return {
			placeable = noises.farness(p) > 0.3,
			-- we need some indestructible spawners, because otherwise you can clear, stay here forever, make infinite resources...
			spawners_indestructible = noises.farness(p) > 0.63,
			-- spawners_indestructible = false,
			density_perchunk = 25 * Math.slopefromto(noises.farness(p), 0.3, 1)^2 * args.biter_base_density_scale,
		}
	end

	IslandsCommon.enemies_1(args, spec, true)

end


function Public.spawn_structures()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]
	local subtype = destination.subtype
	local force = memory.force
	local ancient_force = string.format('ancient-friendly-%03d', memory.id)

	local ps = Public.structure_positions()

	if not destination.dynamic_data.structures_waiting_to_be_placed then
		destination.dynamic_data.structures_waiting_to_be_placed = {}
	end

	for i = 1, #ps do
		local p = ps[i]

		local structureData
		if i == 1 then
			structureData = Structures.IslandStructures.MATTISSO.small_radioactive_reactor.Data
		elseif i==2 then
			structureData = Structures.IslandStructures.MATTISSO.uranium_miners.Data
		elseif i>2 and i<7 then
			structureData = Structures.IslandStructures.MATTISSO.small_radioactive_centrifuge.Data
		else
			structureData = Structures.IslandStructures.MATTISSO.small_radioactive_lab.Data
		end

		local special = {
			position = p,
			components = structureData.components,
			width = structureData.width,
			height = structureData.height,
			name = structureData.name,
		}
		destination.dynamic_data.structures_waiting_to_be_placed[#destination.dynamic_data.structures_waiting_to_be_placed + 1] = {data = special, tick = game.tick}
	end
end








function Public.structure_positions()

	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]

	local island_center = destination.static_params.islandcenter_position
    local width = destination.static_params.width
    local height = destination.static_params.height

	local tries = 0
	local ret = {{x = 0, y = 0}}

	local max_exclusion_distance = 45
	local maxtries = 2400

	local args = {
		static_params = destination.static_params,
		noise_generator = Utils.noise_generator({}, 0),
	}

	while #ret < 8 and tries < maxtries do

		local p2
		if #ret == 1 then
			p2 = {x = island_center.x + Math.random(-35, 10), y = island_center.y + Math.random(-40, 40)}
		else
			p2 = {x = island_center.x + Math.random(Math.ceil(-width/2), Math.ceil(width/2)), y = island_center.y + Math.random(Math.ceil(-height/2), Math.ceil(height/2))}
		end

        Common.ensure_chunks_at(surface, p2, 0.01)

		local tile = surface.get_tile(p2)
        if tile and tile.valid and tile.name then
            if tile.name ~= 'sand-1' and tile.name ~= 'water' and tile.name ~= 'deepwater' then

				local okay = true

                local p3 = {x = p2.x + args.static_params.terraingen_coordinates_offset.x, y = p2.y + args.static_params.terraingen_coordinates_offset.y}
				local farness = IslandsCommon.island_farness_1(args)(p3)
				if (not okay) or (not (farness > 0.05 and farness < 0.55)) then
					okay = false
				end

				local exclusion_distance = max_exclusion_distance * (maxtries - tries) / maxtries
				if #ret == 1 then exclusion_distance = 15 * (maxtries - tries) / maxtries end
				for _, p in pairs(ret) do
					if (not okay) or Math.distance(p, p2) < exclusion_distance then
						okay = false
					end
				end

				if okay then
					ret[#ret + 1] = p2
				end
            end
        end

		tries = tries + 1
	end

	if _DEBUG then
		log('radioactive world locations took ' .. tries .. ' tries.')
	end

	if #ret < 8 then log('couldn\'t find four positions after 2400 tries') end

    return ret
end




function Public.break_rock(surface, p, entity_name)
	-- return Ores.try_ore_spawn(surface, p, entity_name)
end


local function radioactive_tick()
	for _, id in pairs(Memory.get_global_memory().crew_active_ids) do
		Memory.set_working_id(id)
		local memory = Memory.get_crew_memory()
		local destination = Common.current_destination()

		local tickinterval = 60
		
		if destination.subtype == IslandsCommon.enum.RADIOACTIVE then
			-- faster evo (doesn't need difficulty scaling as higher difficulties have higher base evo):
			local extra_evo = 0.22 * tickinterval/60 / Balance.expected_time_on_island()
			Common.increment_evo(extra_evo)
			if (not destination.dynamic_data.evolution_accrued_time) then
				destination.dynamic_data.evolution_accrued_time = 0
			end
			destination.dynamic_data.evolution_accrued_time = destination.dynamic_data.evolution_accrued_time + extra_evo

			if not memory.floating_pollution then memory.floating_pollution = 0 end

			-- faster pollute:
			local pollution = 0
			local timer = destination.dynamic_data.timer
			if timer and timer > 15 then
				pollution = 4.7 * (6 * Common.difficulty()^(1.1) * (memory.overworldx/40)^(14/10) * (Balance.crew_scale())^(0.6)) / 3600 * tickinterval * (1 + (Common.difficulty()-1)*0.2 + 0.001 * timer)
			end

			if pollution > 0 then
				memory.floating_pollution = memory.floating_pollution + pollution
			
				game.pollution_statistics.on_flow('uranium-ore', pollution)
			end

			local surface = game.surfaces[destination.surface_name]
			if surface and surface.valid and (not surface.freeze_daytime) and destination.dynamic_data.timer and destination.dynamic_data.timer >= CoreData.daynightcycle_types[Public.Data.static_params_default.daynightcycletype].ticksperday/60/2 then --once daytime, never go back to night
				surface.freeze_daytime = true
			end
		end
	end
end


local event = require 'utils.event'
event.on_nth_tick(60, radioactive_tick)




return Public