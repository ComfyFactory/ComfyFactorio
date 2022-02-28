
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
local Structures = require 'maps.pirates.structures.structures'
local Boats = require 'maps.pirates.structures.boats.boats'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local IslandsCommon = require 'maps.pirates.surfaces.islands.common'
local Hunt = require 'maps.pirates.surfaces.islands.hunt'
local Ores = require 'maps.pirates.ores'
local Quest = require 'maps.pirates.quest'
local inspect = require 'utils.inspect'.inspect
local Token = require 'utils.token'
local Task = require 'utils.task'

local Public = {}
local enum = IslandsCommon.enum
Public.enum = enum

Public[enum.FIRST] = require 'maps.pirates.surfaces.islands.first.first'
Public[enum.STANDARD] = require 'maps.pirates.surfaces.islands.standard.standard'
Public[enum.STANDARD_VARIANT] = require 'maps.pirates.surfaces.islands.standard_variant.standard_variant'
Public[enum.WALKWAYS] = require 'maps.pirates.surfaces.islands.walkways.walkways'
Public[enum.RADIOACTIVE] = require 'maps.pirates.surfaces.islands.radioactive.radioactive'
Public[enum.RED_DESERT] = require 'maps.pirates.surfaces.islands.red_desert.red_desert'
Public[enum.HORSESHOE] = require 'maps.pirates.surfaces.islands.horseshoe.horseshoe'
Public[enum.SWAMP] = require 'maps.pirates.surfaces.islands.swamp.swamp'
Public['IslandsCommon'] = require 'maps.pirates.surfaces.islands.common'



local function render_silo_hp()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]
	if not (destination.dynamic_data.rocketsilos and destination.dynamic_data.rocketsilos[1] and destination.dynamic_data.rocketsilos[1].valid) then return end
	destination.dynamic_data.rocketsilohptext = rendering.draw_text{
		text = 'HP: ' .. destination.dynamic_data.rocketsilohp .. ' / ' .. destination.dynamic_data.rocketsilomaxhp,
		surface = surface,
		target = destination.dynamic_data.rocketsilos[1],
		target_offset = {0, 4.5},
		color = {0, 255, 0},
		scale = 1.20,
		font = 'default-game',
		alignment = 'center',
		scale_with_zoom = true
	}
end


function Public.spawn_treasure_maps(destination, points_to_avoid)
	points_to_avoid = points_to_avoid or {}
	local memory = Memory.get_crew_memory()
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
	local memory = Memory.get_crew_memory()
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



function Public.spawn_covered(destination, points_to_avoid)
	points_to_avoid = points_to_avoid or {}
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[destination.surface_name]
	if not surface and surface.valid then return end

	local args = {
		static_params = destination.static_params,
		noise_generator = Utils.noise_generator({}, 0),
	}

	local p
	for i = 1, 1 do
		p = Hunt.mid_farness_position_1(args, points_to_avoid)

		local structureData = Structures.IslandStructures.ROC.covered1.Data
		local special = {
			position = p,
			components = structureData.components,
			width = structureData.width,
			height = structureData.height,
			name = structureData.name,
		}
		if not destination.dynamic_data.structures_waiting_to_be_placed then
			destination.dynamic_data.structures_waiting_to_be_placed = {}
		end
		destination.dynamic_data.structures_waiting_to_be_placed[#destination.dynamic_data.structures_waiting_to_be_placed + 1] = {data = special, tick = game.tick}

		local requirement = destination.dynamic_data.covered1_requirement.price

		local rendering1 = rendering.draw_text{
			surface = surface,
			target = {x = p.x + 4, y = p.y + 6.85},
			color = CoreData.colors.renderingtext_green,
			scale = 1.5,
			font = 'default-game',
			alignment = 'right',
		}
		local rendering2 = rendering.draw_sprite{
			sprite = 'item/' .. requirement.name,
			surface = surface,
			target = {x = p.x + 4.85, y = p.y + 7.5},
			x_scale = 1.5,
			y_scale = 1.5
		}

		destination.dynamic_data.covered_data = {
			position = p,
			state = 'covered',
			requirement = requirement,
			rendering1 = rendering1,
			rendering2 = rendering2,
		}

		log('covered market position: ' .. p.x .. ', ' .. p.y)
	end

	return p
end



function Public.spawn_ores_on_shorehit(destination, points_to_avoid)
	points_to_avoid = points_to_avoid or {}
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[destination.surface_name]
	if not surface and surface.valid then return end

	if not (destination.subtype and (destination.subtype == enum.STANDARD or destination.subtype == enum.STANDARD_VARIANT)) then return end

	local ores = {'iron-ore', 'copper-ore', 'stone', 'coal'}

	local args = {
		static_params = destination.static_params,
		noise_generator = Utils.noise_generator({}, 0),
	}

	for _, ore in pairs(ores) do
		local p = Hunt.close_position_1(args, points_to_avoid)
		if p then points_to_avoid[#points_to_avoid + 1] = {x=p.x, y=p.y, r=8} end

		local amount = Common.ore_abstract_to_real(destination.static_params.abstract_ore_amounts[ore])

		local placed = Ores.draw_noisy_ore_patch(surface, p, ore, amount, 10000, 30, true, true)

		if placed > 0 and not destination.dynamic_data.ore_types_spawned[ore] then
			destination.dynamic_data.ore_types_spawned[ore] = true
		end
	end
end



function Public.spawn_merchant_ship(destination)
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[destination.surface_name]
	if not surface and surface.valid then return end

	local args = {
		static_params = destination.static_params,
		noise_generator = Utils.noise_generator({}, 0),
	}

	local p = Hunt.merchant_ship_position(args)

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
	
		Boats.place_boat(boat, CoreData.static_boat_floor, true, true, true, false)

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

		local memory = Memory.get_crew_memory()
		if memory.game_lost then return end
		local destination = Common.current_destination()
		local force = game.forces[memory.force_name]

		destination.dynamic_data.silo_chart_tag = force.add_chart_tag(surface, {icon = {type = 'item', name = 'rocket-silo'}, position = p_silo})
	end
)
function Public.spawn_silo_setup()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]
	local subtype = destination.subtype
	local force = game.forces[memory.force_name]

	local p_silo = Public[subtype].generate_silo_setup_position()
	-- log(string.format("placing silo at x=%f, y = %f", p_silo.x, p_silo.y))

	local silo_count = Balance.silo_count()
	if not (silo_count and silo_count >= 1) then return end

	if _DEBUG then
		if silo_count >= 2 then game.print('silo count: ' .. silo_count) end
	end

	for i=1,silo_count do
		local silo = surface.create_entity({name = 'rocket-silo', position = {p_silo.x + 9*(i-1), p_silo.y}, force = force, create_build_effect_smoke = false})
		if silo and silo.valid then
			if not destination.dynamic_data.rocketsilos then destination.dynamic_data.rocketsilos = {} end
			destination.dynamic_data.rocketsilos[#destination.dynamic_data.rocketsilos + 1]= silo
			silo.minable = false
			silo.rotatable = false
			silo.operable = false
			if i == 1 then
				silo.auto_launch = true
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

	force.chart(surface, {{p_silo.x - 4, p_silo.y - 4},{p_silo.x + 4, p_silo.y + 4}})
	Task.set_timeout_in_ticks(2, silo_chart_tag, {p_silo = p_silo, surface_name = destination.surface_name})

	render_silo_hp()

	return p_silo
end





function Public.spawn_enemy_boat(type)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]
	local offsets = {50, -50, 63, -63}

	local enemyboats = memory.enemyboats
	if enemyboats then
		local boat = {
			state = Boats.enum_state.APPROACHING,
			type = type,
			speed = 4.5,
			position = {x = - surface.map_gen_settings.width/2 + 17.5, y = (memory.boat.dockedposition or memory.boat.position).y + offsets[Math.random(4)]},
			force_name = memory.enemy_force_name,
			surface_name = surface.name,
			unit_group = nil,
			spawner = nil,
		}
		enemyboats[#enemyboats + 1] = boat

		Boats.place_boat(boat, CoreData.static_boat_floor, true, true)
	
		local e = surface.create_entity({name = 'biter-spawner', force = boat.force_name, position = {boat.position.x + Boats.get_scope(boat).Data.spawn_point.x, boat.position.y + Boats.get_scope(boat).Data.spawn_point.y}})
		boat.spawner = e

		return enemyboats[#enemyboats]
	end
end


return Public