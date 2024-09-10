-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
-- local Structures = require 'maps.pirates.structures.structures'
local Boats = require 'maps.pirates.structures.boats.boats'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local Hunt = require 'maps.pirates.surfaces.islands.hunt'
local Ores = require 'maps.pirates.ores'
local Quest = require 'maps.pirates.quest'
local _inspect = require 'utils.inspect'.inspect
local Token = require 'utils.token'
local Task = require 'utils.task'
local QuestStructures = require 'maps.pirates.structures.quest_structures.quest_structures'
local IslandEnum = require 'maps.pirates.surfaces.islands.island_enum'

local Public = {}
local enum = IslandEnum.enum

Public[enum.FIRST] = require 'maps.pirates.surfaces.islands.first.first'
Public[enum.STANDARD] = require 'maps.pirates.surfaces.islands.standard.standard'
Public[enum.STANDARD_VARIANT] = require 'maps.pirates.surfaces.islands.standard_variant.standard_variant'
Public[enum.WALKWAYS] = require 'maps.pirates.surfaces.islands.walkways.walkways'
Public[enum.RADIOACTIVE] = require 'maps.pirates.surfaces.islands.radioactive.radioactive'
Public[enum.RED_DESERT] = require 'maps.pirates.surfaces.islands.red_desert.red_desert'
Public[enum.HORSESHOE] = require 'maps.pirates.surfaces.islands.horseshoe.horseshoe'
Public[enum.SWAMP] = require 'maps.pirates.surfaces.islands.swamp.swamp'
Public[enum.MAZE] = require 'maps.pirates.surfaces.islands.maze.maze'
Public[enum.CAVE] = require 'maps.pirates.surfaces.islands.cave.cave'
Public[enum.CAVE_SOURCE] = require 'maps.pirates.surfaces.islands.cave.cave_source'  -- Used as extra layer for cave island
Public['IslandsCommon'] = require 'maps.pirates.surfaces.islands.common'



-- local function render_silo_hp()
-- 	-- local memory = Memory.get_crew_memory()
-- 	local destination = Common.current_destination()
-- 	local surface = game.surfaces[destination.surface_name]
-- 	if not (destination.dynamic_data.rocketsilos and destination.dynamic_data.rocketsilos[1] and destination.dynamic_data.rocketsilos[1].valid) then return end
-- 	destination.dynamic_data.rocketsilohptext = rendering.draw_text{
-- 		text = 'HP: ' .. destination.dynamic_data.rocketsilohp .. ' / ' .. destination.dynamic_data.rocketsilomaxhp,
-- 		surface = surface,
-- 		target = destination.dynamic_data.rocketsilos[1],
-- 		target_offset = {0, 4.5},
-- 		color = {0, 255, 0},
-- 		scale = 1.20,
-- 		font = 'default-game',
-- 		alignment = 'center',
-- 		scale_with_zoom = true
-- 	}
-- end


function Public.spawn_treasure_maps(destination, points_to_avoid)
	points_to_avoid = points_to_avoid or {}
	-- local memory = Memory.get_crew_memory()
	local surface = game.surfaces[destination.surface_name]
	if not surface and surface.valid then return end

	local num = destination.static_params.starting_treasure_maps
	if not destination.dynamic_data.treasure_maps then destination.dynamic_data.treasure_maps = {} end

	local args = {
		static_params = destination.static_params,
		noise_generator = Utils.noise_generator({}, 0),
	}

	for i = 1, num do
		local map = {}

		local p = Hunt.mid_farness_position_1(args, points_to_avoid)

		-- game.print(p)

		map.position = p
		map.mapobject_rendering = rendering.draw_sprite{
			surface = surface,
			target = p,
			sprite = 'utility/gps_map_icon',
			render_layer = '125',
			x_scale = 2.4,
			y_scale = 2.4,
		}
		map.state = 'on_ground'
		map.x_renderings = nil
		map.buried_treasure_position = nil

		destination.dynamic_data.treasure_maps[#destination.dynamic_data.treasure_maps + 1] = map
	end
end



function Public.spawn_ghosts(destination, points_to_avoid)
	points_to_avoid = points_to_avoid or {}
	-- local memory = Memory.get_crew_memory()
	local surface = game.surfaces[destination.surface_name]
	if not surface and surface.valid then return end

	if not (destination.dynamic_data and destination.dynamic_data.quest_type and destination.dynamic_data.quest_type == Quest.enum.FIND) then return end

	local num = destination.dynamic_data.quest_progressneeded
	if not destination.dynamic_data.ghosts then destination.dynamic_data.ghosts = {} end

	local args = {
		static_params = destination.static_params,
		noise_generator = Utils.noise_generator({}, 0),
	}

	for i = 1, num do
		local ghost = {}

		local p = Hunt.mid_farness_position_1(args, points_to_avoid)

		ghost.position = p
		ghost.ghostobject_rendering = rendering.draw_sprite{
			surface = surface,
			target = p,
			sprite = 'utility/ghost_time_to_live_modifier_icon',
			render_layer = '125',
			x_scale = 1,
			y_scale = 1,
		}
		ghost.state = 'on_ground'

		destination.dynamic_data.ghosts[#destination.dynamic_data.ghosts + 1] = ghost
	end
end



function Public.spawn_quest_structure(destination, points_to_avoid)
	points_to_avoid = points_to_avoid or {}
	-- local memory = Memory.get_crew_memory()
	local surface = game.surfaces[destination.surface_name]
	if not surface and surface.valid then return end

	local args = {
		static_params = destination.static_params,
		noise_generator = Utils.noise_generator({}, 0),
	}

	local p = Hunt.mid_farness_position_1(args, points_to_avoid)

	if p then
		QuestStructures.initialise_cached_quest_structure(p, QuestStructures.choose_quest_structure_type())
	end

	return p
end



function Public.spawn_ores_on_arrival(destination, points_to_avoid)
	points_to_avoid = points_to_avoid or {}
	-- local memory = Memory.get_crew_memory()
	local surface = game.surfaces[destination.surface_name]
	if not surface and surface.valid then return end

	if destination.subtype == enum.STANDARD or destination.subtype == enum.STANDARD_VARIANT or destination.subtype == enum.MAZE then
		local ores = {'iron-ore', 'copper-ore', 'stone', 'coal', 'crude-oil'}

		local args = {
			static_params = destination.static_params,
			noise_generator = Utils.noise_generator({}, 0),
		}

		local farness_low, farness_high = 0.06, 0.25
		if destination.subtype == enum.MAZE then
			farness_low = 0.14
			farness_high = 0.44
		end

		for _, ore in pairs(ores) do
			if destination.static_params.abstract_ore_amounts[ore] then
				local p = Hunt.close_position_try_avoiding_entities(args, points_to_avoid, farness_low, farness_high)
				if p then
					points_to_avoid[#points_to_avoid + 1] = {x=p.x, y=p.y, r=11}

					if ore == 'crude-oil' then

						local count = Math.max(1, Math.ceil((destination.static_params.abstract_ore_amounts[ore]/3)^(1/2)))
						local amount = Common.oil_abstract_to_real(destination.static_params.abstract_ore_amounts[ore]) / count

						for i = 1, count do
							local p2 = {p.x + Math.random(-7, 7), p.y + Math.random(-7, 7)}
							local whilesafety = 0
							while (not surface.can_place_entity{name = 'crude-oil', position = p2}) and whilesafety < 30 do
								p2 = {p.x + Math.random(-7, 7), p.y + Math.random(-7, 7)}
								whilesafety = whilesafety + 1
							end

							surface.create_entity{name = 'crude-oil', position = p2, amount = amount}
						end

						destination.dynamic_data.ore_types_spawned[ore] = true
					else
						local amount = Common.ore_abstract_to_real(destination.static_params.abstract_ore_amounts[ore])

						local placed = Ores.draw_noisy_ore_patch(surface, p, ore, amount, 10000, 30, true, true)

						if placed > 0 then
							destination.dynamic_data.ore_types_spawned[ore] = true
						end
					end
				end
			end
		end
	end
end



function Public.spawn_merchant_ship(destination)
	-- local memory = Memory.get_crew_memory()
	local surface = game.surfaces[destination.surface_name]
	if not surface and surface.valid then return end

	-- local args = {
	-- 	static_params = destination.static_params,
	-- 	noise_generator = Utils.noise_generator({}, 0),
	-- }
	-- local p = Hunt.merchant_ship_position(args)
	local p = Hunt.merchant_ship_position()

	if p then
		local boat = {
			state = Boats.enum_state.LANDED,
			type = Boats.enum.MERCHANT,
			position = p,
			force_name = 'environment',
			surface_name = surface.name,
			market = nil,
		}

		Boats.place_landingtrack(boat, CoreData.landing_tile, true)

		Boats.place_boat(boat, CoreData.static_boat_floor, true, true, true)

		destination.dynamic_data.merchant_market = boat.market

		return boat.market
	end
end



local silo_chart_tag = Token.register(
	function(data)
		local p_silo = data.p_silo
		local surface_name = data.surface_name

		local surface = game.surfaces[surface_name]
		if not surface and surface.valid then return end


		Memory.set_working_id(data.crew_id)
		local memory = Memory.get_crew_memory()

		if memory.game_lost then return end
		local destination = Common.current_destination()
		local force = memory.force

		destination.dynamic_data.silo_chart_tag = force.add_chart_tag(surface, {icon = {type = 'item', name = 'rocket-silo'}, position = p_silo})
	end
)
function Public.spawn_silo_setup(points_to_avoid)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]
	local subtype = destination.subtype
	local force = memory.force

	if not Public[subtype].generate_silo_setup_position then return end

	local p_silo = Public[subtype].generate_silo_setup_position(points_to_avoid)
	if not p_silo then return end
	-- log(string.format("placing silo at x=%f, y = %f", p_silo.x, p_silo.y))

	local silo_count = Balance.silo_count()
	if not (silo_count and silo_count >= 1) then return end

	if _DEBUG then
		if silo_count >= 2 then game.print('debug - silo count: ' .. silo_count) end
	end

	for i = 1, silo_count do
		local pos = {x = p_silo.x + 9*(i-1), y = p_silo.y}

		Common.delete_entities(surface, pos, 11, 11)
		Common.replace_unwalkable_tiles(surface, pos, 11, 11)

		local silo = surface.create_entity({name = 'rocket-silo', position = pos, force = force, create_build_effect_smoke = false})
		if silo and silo.valid then
			if not destination.dynamic_data.rocketsilos then destination.dynamic_data.rocketsilos = {} end
			destination.dynamic_data.rocketsilos[#destination.dynamic_data.rocketsilos + 1]= silo
			silo.minable = false
			silo.rotatable = false
			silo.operable = false
			if i == 1 then
				silo.auto_launch = true
				Common.new_healthbar(true, silo, Balance.silo_max_hp, nil, Balance.silo_max_hp, 0.6, -2, destination.dynamic_data)
			else
				silo.destructible = false
			end
			local modulesinv = silo.get_module_inventory()
			modulesinv.insert{name = 'productivity-module-3', count = 4}
		end
	end

	-- local substation = surface.create_entity({name = 'substation', position = {x = p_silo.x - 8.5, y = p_silo.y - 0.5}, force = force, create_build_effect_smoke = false})
	-- if substation and substation.valid then
	-- 	substation.destructible = false
	-- 	substation.minable = false
	-- 	substation.rotatable = false
	-- end

	-- local eei = surface.create_entity({name = 'electric-energy-interface', position = {x = p_silo.x - 8.5, y = p_silo.y + 1.5}, force = force, create_build_effect_smoke = false})
	-- if eei and eei.valid then
	-- 	memory.islandeei = eei
	-- 	eei.destructible = false
	-- 	eei.minable = false
	-- 	eei.rotatable = false
	-- 	eei.operable = false
	-- 	eei.electric_buffer_size = memory.islandeeijoulesperrocket / 100
	-- 	eei.power_production = 0
	-- 	eei.power_usage = 0
	-- end

	if CoreData.rocket_silo_death_causes_loss or (destination.static_params and destination.static_params.base_cost_to_undock and destination.static_params.base_cost_to_undock['launch_rocket'] == true) then
		-- we need to know where it is
		force.chart(surface, {{p_silo.x - 4, p_silo.y - 4},{p_silo.x + 4, p_silo.y + 4}})
		Task.set_timeout_in_ticks(2, silo_chart_tag, {p_silo = p_silo, surface_name = destination.surface_name, crew_id = memory.id})
	end

	-- render_silo_hp()

	return p_silo
end




-- NOTE: Currently the boats can trigger landing early if 2 boats spawn in same lane in short interval. Too lazy to fix.
-- NOTE: As well as biter boats can miss the island on smaller ones when boat is steered
function Public.spawn_enemy_boat(type)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]
	local offsets = {50, -50, 63, -63, 76, -76, 89, -89}

	local enemyboats = destination.dynamic_data.enemyboats
	if enemyboats then
		local boat = {
			state = Boats.enum_state.APPROACHING,
			type = type,
			speed = 4,
			position = {x = - surface.map_gen_settings.width/2 + 23.5, y = (memory.boat.dockedposition or memory.boat.position).y + offsets[Math.random(#offsets)]},
			force_name = memory.enemy_force_name,
			surface_name = surface.name,
			unit_group = nil,
			spawner = nil,
		}
		enemyboats[#enemyboats + 1] = boat

		Boats.place_boat(boat, CoreData.static_boat_floor, true, true)

		local e = surface.create_entity({name = 'biter-spawner', force = boat.force_name, position = {boat.position.x + Boats.get_scope(boat).Data.spawn_point.x, boat.position.y + Boats.get_scope(boat).Data.spawn_point.y}})

		if e and e.valid then
			-- e.destructible = false
			boat.spawner = e

			local max_health = Balance.biter_boat_health()
			Common.new_healthbar(true, e, max_health, nil, max_health, 0.5, nil)
		end

		return enemyboats[#enemyboats]
	end
end


return Public