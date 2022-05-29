
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Hold = require 'maps.pirates.surfaces.hold'
-- local Parrot = require 'maps.pirates.parrot'
local Cabin = require 'maps.pirates.surfaces.cabin'
local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect

-- DEV NOTE: If making boat designs that have rails, make sure the boat is placed at odd co-ordinates before blueprinting.

local Public = {}
local enum = {
		SLOOP = 'Sloop',
		RAFT = 'Raft',
		RAFTLARGE = 'Large Raft',
		MERCHANT = 'Merchant',
}
Public[enum.SLOOP] = require 'maps.pirates.structures.boats.sloop.sloop'
Public[enum.RAFT] = require 'maps.pirates.structures.boats.raft.raft'
Public[enum.RAFTLARGE] = require 'maps.pirates.structures.boats.raft_large.raft_large'
Public[enum.MERCHANT] = require 'maps.pirates.structures.boats.merchant_1.merchant_1'
Public.enum = enum
local enum_state = {
		ATSEA_SAILING = 'at_sea',
		APPROACHING = 'approaching',
		LANDED = 'landed',
		RETREATING = 'retreating',
		LEAVING_DOCK = 'leaving',
		ATSEA_LOADING_MAP = 'waiting_for_load',
		DOCKED = 'docked',
}
Public.enum_state = enum_state

Public.small_distance = 0.1--for generous areas


function Public.get_scope(boat)

	if boat.type then
		if boat.subtype then
			return Public[boat.type][boat.subtype]
		else
			return Public[boat.type]
		end
	else
		return {}
	end
end



function Public.currentdestination_move_boat_natural()
	local memory = Memory.get_crew_memory()
	local boat = memory.boat
    local destination = Common.current_destination()

	if (destination and destination.dynamic_data and destination.dynamic_data.timer) and (not (destination.dynamic_data.timer >= 1)) then return end

	if boat and boat.state == enum_state.LEAVING_DOCK or boat.state == enum_state.APPROACHING then
		local newp = {x = boat.position.x + Common.boat_steps_at_a_time, y = boat.position.y}
		Public.teleport_boat(boat, nil, newp)
	elseif boat and boat.state == enum_state.RETREATING then
		local newp = {x = boat.position.x - Common.boat_steps_at_a_time, y = boat.position.y}
		Public.teleport_boat(boat, nil, newp)
	end
end


function Public.currentdestination_try_move_boat_steered()
	local memory = Memory.get_crew_memory()
	local boat = memory.boat
    local destination = Common.current_destination()

	if (destination and destination.dynamic_data and destination.dynamic_data.timer) and (not (destination.dynamic_data.timer >= 1)) then return end

	if boat and boat.decksteeringchests then
		local leftchest, rightchest = boat.decksteeringchests.left, boat.decksteeringchests.right
		if leftchest and leftchest.valid and rightchest and rightchest.valid then
			local inv_left = leftchest.get_inventory(defines.inventory.chest)
			local inv_right = rightchest.get_inventory(defines.inventory.chest)
			local count_left = inv_left.get_item_count("rail-signal")
			local count_right = inv_right.get_item_count("rail-signal")

			if count_left >= 1 and count_right == 0 then
				inv_left.remove({name = "rail-signal", count = 1})
				local newp = {x = boat.position.x, y = boat.position.y - Common.boat_steps_at_a_time}
				Public.teleport_boat(boat, nil, newp)
				return
			elseif count_right >= 1 and count_left == 0 then
				inv_right.remove({name = "rail-signal", count = 1})
				local newp = {x = boat.position.x, y = boat.position.y + Common.boat_steps_at_a_time}
				Public.teleport_boat(boat, nil, newp)
				return
			end
		end
	end
end




function Public.draw_power_renderings(boat)
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[boat.surface_name]
	local scope = Public.get_scope(boat)

	local p1 = Utils.psum{memory.boat.position, scope.Data.power1_rendering_position}
	local p2 = Utils.psum{memory.boat.position, scope.Data.power2_rendering_position}
	boat.renderings_power = {}
	for i = 1, boat.EEI_stage do
		boat.renderings_power[#boat.renderings_power + 1] = rendering.draw_sprite{
			sprite = "utility/status_working",
			surface = surface,
			x_scale = 2,
			y_scale = 2,
			target = {p1.x + 0.5*i - 0.25*(boat.EEI_stage+1), p1.y},
		}
		boat.renderings_power[#boat.renderings_power + 1] = rendering.draw_sprite{
			sprite = "utility/status_working",
			surface = surface,
			x_scale = 2,
			y_scale = 2,
			target = {p2.x + 0.5*i - 0.25*(boat.EEI_stage+1), p2.y},
		}
	end
end




function Public.destroy_boat(boat, tile_type, flipped)
	flipped = flipped or false
	tile_type = tile_type or 'water'
	if boat.rendering_crewname_text then
		rendering.destroy(boat.rendering_crewname_text)
		boat.rendering_crewname_text = nil
	end
	if boat.renderings_power and #boat.renderings_power > 0 then
		for _, r in pairs(boat.renderings_power) do
			rendering.destroy(r)
		end
	end
	Public.place_boat(boat, tile_type, false, true, flipped)
	-- boat = {} --I guess this doesn't do anything, since it doesn't actually set anything upstream
end





function Public.update_EEIs(boat)
	local EEI_stage = boat.EEI_stage or 1

	local multiplier
	if EEI_stage > #Balance.EEI_stages then --sensible out of bounds behaviour:
		multiplier = Balance.EEI_stages[#Balance.EEI_stages] + 5 * (EEI_stage - #Balance.EEI_stages)
	else
		multiplier = Balance.EEI_stages[EEI_stage]
	end

	boat.EEIpower_production = Balance.starting_boatEEIpower_production_MW() * 1000000 / 60 * multiplier
	boat.EEIelectric_buffer_size = Balance.starting_boatEEIelectric_buffer_size_MJ() * 1000000 * multiplier

	for _, e in pairs(boat.EEIs) do
		if e and e.valid then
			e.power_production = boat.EEIpower_production
			e.electric_buffer_size = boat.EEIelectric_buffer_size
		end
	end

	if boat.renderings_power and #boat.renderings_power > 0 then
		for _, r in pairs(boat.renderings_power) do
			rendering.destroy(r)
		end
	end
	Public.draw_power_renderings(boat)
end


function Public.upgrade_chests(boat, new_chest)
	local scope = Public.get_scope(boat)
	local surface = game.surfaces[boat.surface_name]

	local ps = Common.entity_positions_from_blueprint(scope.Data.upgrade_chests.bp_str, Math.vector_sum(boat.position, scope.Data.upgrade_chests.pos))

	for _, p in pairs(ps) do
		local es = surface.find_entities_filtered{name = 'wooden-chest', position = p, radius = 0.05}
		if es and #es == 1 then
			es[1].minable = true
			es[1].destructible = true
			es[1].rotatable = true
		end
		local e2 = surface.create_entity{name = new_chest, position = p, fast_replace = true, spill = false, force = boat.force_name}
		e2.minable = false
		e2.destructible = false
		e2.rotatable = false
	end
end



--!! you must place boats at odd-valued co-ordinates...
-- function Public.place_boat(boat, floor_tile, place_entities_bool, correct_tiles, flipped)

function Public.place_boat(boat, floor_tile, place_entities_bool, correct_tiles, flipped)
-- function Public.place_boat(boat, floor_tile, place_entities_bool, correct_tiles, flipped, comfy_logo)
	flipped = flipped or false
	local flipped_sign = flipped and -1 or 1
	correct_tiles = correct_tiles or true
	place_entities_bool = place_entities_bool or false
	local scope = Public.get_scope(boat)

	local surface = game.surfaces[boat.surface_name]


	local tiles = {}
	for _, area in pairs(scope.Data.tile_areas) do
		Common.tiles_from_area(tiles, area, boat.position, floor_tile)
	end

	if flipped then
		tiles = Common.tiles_horizontally_flipped(tiles, boat.position.x)
		Common.ensure_chunks_at(surface, {boat.position.x + scope.Data.width/2, boat.position.y}, 3)
	else
		Common.ensure_chunks_at(surface, {boat.position.x - scope.Data.width/2, boat.position.y}, 3)
	end

	surface.set_tiles(tiles, correct_tiles)

	boat.speedticker1 = 0
	boat.speedticker2 = 1/3 * Common.boat_steps_at_a_time
	boat.speedticker3 = 2/3 * Common.boat_steps_at_a_time


	if place_entities_bool then
		for etype, entitydata in pairs(scope.Data.entities) do
			local entities_pos
			if entitydata.pos then
				entities_pos = {x = boat.position.x + flipped_sign * entitydata.pos.x, y = boat.position.y + entitydata.pos.y}
			else
				entities_pos = {x = boat.position.x, y = boat.position.y}
			end
			local entities = Common.build_from_blueprint(entitydata.bp_str, surface, entities_pos, boat.force_name, flipped)
			for _, e in pairs(entities) do
				if e and e.valid then
					if etype == 'static_inoperable' then
						e.destructible = false
						e.minable = false
						e.rotatable = false
						e.operable = false
					elseif etype == 'static' then
						e.destructible = false
						e.minable = false
						e.rotatable = false
					elseif etype == 'inaccessible' then
						e.destructible = false
						e.minable = false
						e.rotatable = false
						e.operable = false
						e.force = 'environment'
					end
					if e.name and e.name == 'locomotive' then
						e.color = {148, 106, 52}
					end
				end
			end
		end

		if scope.Data.EEIs then
			if not boat.EEIs then boat.EEIs = {} end
			for _, p in pairs(scope.Data.EEIs) do
				local p2 = {x = boat.position.x + p.x, y = boat.position.y + p.y}
				local e = surface.create_entity({name = 'electric-energy-interface', position = p2, force = boat.force_name, create_build_effect_smoke = false})
				if e and e.valid then
					e.destructible = false
					e.minable = false
					e.rotatable = false
					e.operable = false
					e.electric_buffer_size = boat.EEIelectric_buffer_size or Balance.starting_boatEEIelectric_buffer_size_MJ() * 1000000
					e.power_production = boat.EEIpower_production or Balance.starting_boatEEIpower_production_MW() * 1000000 / 60
					e.power_usage = 0
					boat.EEIs[#boat.EEIs + 1] = e
				end
			end
		end

		if scope.Data.upstairs_poles then
			for i = 1, 2 do
				local p = scope.Data.upstairs_poles[i]
				local p2 = {x = boat.position.x + p.x, y = boat.position.y + p.y}
				local e = surface.create_entity({name = 'substation', position = p2, force = boat.force_name, create_build_effect_smoke = false})
				if e and e.valid then
					e.destructible = false
					e.minable = false
					e.rotatable = false
					if i == 1 then
						boat.upstairs_pole = e
						Public.try_connect_upstairs_and_downstairs_poles(boat)
					end
				end
			end
		end

		if scope.Data.cannons then
			for _, p in pairs(scope.Data.cannons) do
				local p2 = {x = boat.position.x + p.x, y = boat.position.y + p.y}
				local e = surface.create_entity({name = 'artillery-turret', position = p2, force = boat.force_name, create_build_effect_smoke = false})
				if e and e.valid then
					e.minable = false
					if p.y > 0 then e.direction = defines.direction.south end
					if not boat.cannons_temporary_reference then boat.cannons_temporary_reference = {} end
					boat.cannons_temporary_reference[#boat.cannons_temporary_reference + 1] = e
				end
				local wall1,wall2,wall3 = surface.create_entity({name = 'stone-wall', position = {x = p2.x+1, y = p2.y}, force = boat.force_name, create_build_effect_smoke = false}),surface.create_entity({name = 'stone-wall', position = {x = p2.x, y = p2.y}, force = boat.force_name, create_build_effect_smoke = false}),surface.create_entity({name = 'stone-wall', position = {x = p2.x-1, y = p2.y}, force = boat.force_name, create_build_effect_smoke = false})
				if wall1 and wall2 and wall3 and wall1.valid and wall2.valid and wall3.valid then
					wall1.destructible = false
					wall1.minable = false
					wall2.destructible = false
					wall2.minable = false
					wall3.destructible = false
					wall3.minable = false
				end
			end
		end

		if scope.Data.entercrowsnest_cars then
			for _, p in pairs(scope.Data.entercrowsnest_cars) do
				local car_pos = {x = boat.position.x + p.x, y = boat.position.y + p.y}
				local e = surface.create_entity({name = 'car', position = car_pos, force = boat.force_name, create_build_effect_smoke = false})
				if e and e.valid then
					e.get_inventory(defines.inventory.fuel).insert({name = 'wood', count = 16})
					e.color = {148, 106, 52}
					e.destructible = false
					e.minable = false
					e.rotatable = false
					e.operable = false
				end
			end
		end

		if scope.Data.cabin_car then
			local car_pos = {x = boat.position.x + scope.Data.cabin_car.x, y = boat.position.y + scope.Data.cabin_car.y}
			local e = surface.create_entity({name = 'car', position = car_pos, force = boat.force_name, create_build_effect_smoke = false})
			if e and e.valid then
				e.get_inventory(defines.inventory.fuel).insert({name = 'wood', count = 16})
				e.color = {148, 106, 52}
				e.destructible = false
				e.minable = false
				e.rotatable = false
				e.operable = false
			end
		end

		if scope.Data.steering_boxes then
			if not boat.decksteeringchests then boat.decksteeringchests = {} end
			for _, p in pairs(scope.Data.steering_boxes or {}) do
				local box_pos = {x = boat.position.x + p.x, y = boat.position.y + p.y}
				local ee = surface.create_entity({name = 'blue-chest', position = box_pos, force = boat.force_name, create_build_effect_smoke = false})
				if ee and ee.valid then
					ee.destructible = false
					ee.minable = false
					ee.rotatable = false
					if p.y < 0 then
						boat.decksteeringchests.left = ee
						-- --attach parrot to this:
						-- if scope.Data.parrot_resting_position then
						-- 	boat.parrot = {}
						-- 	boat.parrot.frame = 1
						-- 	boat.parrot.state = Parrot.enum.FLY
						-- 	boat.parrot.resting_position_relative_to_boat = scope.Data.parrot_resting_position
						-- 	boat.parrot.position_relative_to_boat = scope.Data.parrot_resting_position
						-- 	boat.parrot.sprite_extra_offset = {x = -p.x, y = -p.y}
						-- 	boat.parrot.text_extra_offset = {x = -p.x, y = -p.y - 1.5}
						-- 	boat.parrot.render = rendering.draw_sprite{
						-- 		sprite = "file/parrot/parrot_idle_fly_1.png",
						-- 		surface = surface,
						-- 		target = ee,
						-- 		target_offset = Utils.psum{boat.parrot.position_relative_to_boat, boat.parrot.sprite_extra_offset},
						-- 		x_scale = 2.8,
						-- 		y_scale = 2.8,
						-- 		visible = false,
						-- 	}
						-- 	boat.parrot.render_name = rendering.draw_text{
						-- 		text = 'Parrot',
						-- 		color = CoreData.colors.parrot,
						-- 		surface = surface,
						-- 		target = ee,
						-- 		target_offset = Utils.psum{boat.parrot.position_relative_to_boat, boat.parrot.text_extra_offset},
						-- 		visible = false,
						-- 		alignment = 'center',
						-- 	}
						-- end
					else
						boat.decksteeringchests.right = ee
					end
				end
			end
		end
		-- if boat.decksteeringchests and boat.decksteeringchests.left then
		-- 	local box_pos = {x = boat.position.x - 0.5, y = boat.position.y + 0.5}
		-- 	local e = surface.create_entity({name = 'blue-chest', position = box_pos, force = boat.force_name, create_build_effect_smoke = false})
		-- 	if e and e.valid then
		-- 		e.destructible = false
		-- 		e.operable = false
		-- 		e.minable = false
		-- 		e.rotatable = false
		-- 		boat.questrewardchest = e
		-- 	end
		-- end

		if scope.Data.loco_pos then
			Common.build_small_loco(surface, {x = boat.position.x + scope.Data.loco_pos.x, y = boat.position.y + scope.Data.loco_pos.y}, boat.force_name, {255, 106, 52})
		end

		if scope.Data.deck_whitebelts_lrtp_order then
			if not boat.deck_whitebelts then boat.deck_whitebelts = {} end
			for _, b in ipairs(scope.Data.deck_whitebelts_lrtp_order or {}) do
				local p = {x = boat.position.x + b.x, y = boat.position.y + b.y}
				local e = surface.create_entity({name = 'linked-belt', position = p, force = boat.force_name, create_build_effect_smoke = false, direction = b.direction})
				if e and e.valid then
					e.destructible = false
					e.minable = false
					e.rotatable = false
					e.operable = false
					e.linked_belt_type = b.type
					boat.deck_whitebelts[#boat.deck_whitebelts + 1] = e
				end
			end

			Hold.connect_up_linked_belts_to_deck()
			Cabin.connect_up_linked_belts_to_deck()
		end
	end

	-- if comfy_logo then
	-- 	local p = Utils.psum{boat.position, scope.Data.comfy_rendering_position}
	-- 	boat.rendering_comfy = rendering.draw_sprite{
	-- 		sprite = "file/comfy2.png",
	-- 		render_layer = '125',
	-- 		surface = surface,
	-- 		target = p,
	-- 	}
	-- end

	if scope.Data.market_pos then
		local p = {x = boat.position.x + flipped_sign * scope.Data.market_pos.x, y = boat.position.y + flipped_sign * scope.Data.market_pos.y}
		local e = surface.create_entity({name = 'market', position = p, force = boat.force_name, create_build_effect_smoke = false})
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = false
			boat.market = e
		end
	end
end



function Public.put_deck_whitebelts_in_standard_order(boat)

	if boat and boat.deck_whitebelts and #boat.deck_whitebelts > 0 then

		local i1 = {}
		for i = 1, #boat.deck_whitebelts do
			i1[i] = i
		end

		table.sort(i1, function(a,b) return boat.deck_whitebelts[a].position.y < boat.deck_whitebelts[b].position.y or (boat.deck_whitebelts[a].position.y == boat.deck_whitebelts[b].position.y and boat.deck_whitebelts[a].position.x < boat.deck_whitebelts[b].position.x) end) --true if a should be to the left of b

		local replacementlist = {}
		for i = 1, #boat.deck_whitebelts do
			replacementlist[i] = boat.deck_whitebelts[i1[i]]
		end
		boat.deck_whitebelts = nil
		boat.deck_whitebelts = replacementlist
	end
end



function Public.place_landingtrack(boat, floor_tile, flipped)
	flipped = flipped or false
	local flipped_bool = flipped and -1 or 1
	local surface = game.surfaces[boat.surface_name]

	Common.ensure_chunks_at(surface, boat.position, 3)

	local data = Public[boat.type].Data.landingtrack

	local tilesp = Common.tile_positions_from_blueprint(data.bp, data.offset)
	local tiles = {}
	for _, p in pairs(tilesp) do
		local p2 = {x = boat.position.x + flipped_bool * p.x, y = boat.position.y + p.y}
		tiles[#tiles + 1] = {name = floor_tile, position = p2}
		surface.destroy_decoratives{position = p2}
	end

	surface.set_tiles(tiles, true)
end


function Public.get_players_on_gate_tiles(boat, boatposition_override)
	local surface = game.surfaces[boat.surface_name]
	local scope = Public.get_scope(boat)

	local position = boatposition_override or boat.position

	local players_on_gate_tiles = {}
	for _, relative_area in pairs(scope.Data.right_gate_tile_areas) do
		local area = {{position.x + relative_area[1][1] - Public.small_distance, position.y + relative_area[1][2] - Public.small_distance}, {position.x + relative_area[2][1] + Public.small_distance, position.y + relative_area[2][2] + Public.small_distance}}
		local entities = surface.find_entities_filtered{area = area, name = 'character'}
		for _, e in pairs(entities) do
			if e and e.valid then
				players_on_gate_tiles[#players_on_gate_tiles + 1] = e
			end
		end
	end
	for _, relative_area in pairs(scope.Data.left_gate_tile_areas) do
		local area = {{position.x + relative_area[1][1] - Public.small_distance, position.y + relative_area[1][2] - Public.small_distance}, {position.x + relative_area[2][1] + Public.small_distance, position.y + relative_area[2][2] + Public.small_distance}}
		local entities = surface.find_entities_filtered{area = area, name = 'character'}
		for _, e in pairs(entities) do
			if e and e.valid then
				players_on_gate_tiles[#players_on_gate_tiles + 1] = e
			end
		end
	end
	return players_on_gate_tiles
end


function Public.get_players_just_offside(boat, boatposition_override)
	local players_just_offside = {}
	local surface = game.surfaces[boat.surface_name]

	local position = boatposition_override or boat.position

	for _, relative_area in pairs(Public[boat.type].Data.areas_offleft) do
		local area = {{position.x + relative_area[1][1] - Public.small_distance, position.y + relative_area[1][2] - Public.small_distance}, {position.x + relative_area[2][1] + Public.small_distance, position.y + relative_area[2][2] + Public.small_distance}}
		local entities = surface.find_entities_filtered{area = area, name = 'character'}
		for _, e in pairs(entities) do
			if e and e.valid then
				players_just_offside[#players_just_offside + 1] = e
			end
		end
	end
	for _, relative_area in pairs(Public[boat.type].Data.areas_offright) do
		local area = {{position.x + relative_area[1][1] - Public.small_distance, position.y + relative_area[1][2] - Public.small_distance}, {position.x + relative_area[2][1] + Public.small_distance, position.y + relative_area[2][2] + Public.small_distance}}
		local entities = surface.find_entities_filtered{area = area, name = 'character'}
		for _, e in pairs(entities) do
			if e and e.valid then
				players_just_offside[#players_just_offside + 1] = e
			end
		end
	end
	for _, relative_area in pairs(Public[boat.type].Data.areas_infront) do
		local area = {{position.x + relative_area[1][1] - Public.small_distance, position.y + relative_area[1][2] - Public.small_distance}, {position.x + relative_area[2][1] + Public.small_distance, position.y + relative_area[2][2] + Public.small_distance}}
		local entities = surface.find_entities_filtered{area = area, name = 'character'}
		for _, e in pairs(entities) do
			if e and e.valid then
				players_just_offside[#players_just_offside + 1] = e
			end
		end
	end
	for _, relative_area in pairs(Public[boat.type].Data.areas_behind) do
		local area = {{position.x + relative_area[1][1] - Public.small_distance, position.y + relative_area[1][2] - Public.small_distance}, {position.x + relative_area[2][1] + Public.small_distance, position.y + relative_area[2][2] + Public.small_distance}}
		local entities = surface.find_entities_filtered{area = area, name = 'character'}
		for _, e in pairs(entities) do
			if e and e.valid then
				players_just_offside[#players_just_offside + 1] = e
			end
		end
	end

	return Utils.exclude(players_just_offside, Public.get_players_on_gate_tiles(boat, boatposition_override))
end


function Public.collision_infront(boat)
	local surface = game.surfaces[boat.surface_name]
	if surface and surface.valid then
		for _, relative_area in pairs(Public[boat.type].Data.areas_infront) do
			for _, p in pairs(Common.central_positions_within_area(relative_area, boat.position)) do
				local tile = surface.get_tile(p)
				if tile and tile.valid and not tile.collides_with('resource-layer') then
					return true
				end
			end
		end
	end
	return false
end


function Public.on_boat(boat, pos)
	for _, relative_area in pairs(Public[boat.type].Data.tile_areas) do
		local area = {{boat.position.x + relative_area[1][1], boat.position.y + relative_area[1][2]}, {boat.position.x + relative_area[2][1], boat.position.y + relative_area[2][2]}}
		if pos.x >= area[1][1] and pos.x <= area[2][1] and pos.y >= area[1][2] and pos.y <= area[2][2] then
			return true
		end
	end
	return false
end


function Public.players_on_boat_count(boat)
	local count = 0
	for _, player in pairs(game.connected_players) do
		if player.surface and player.surface.valid and boat.surface_name and player.surface.name == boat.surface_name and Public.on_boat(boat, player.position) then
			count = count + 1
		end
	end
	return count
end




-- function Public.deck_place_random_obstacle_boxes(boat, smallcount, contents, largecount)
-- 	contents = contents or {}
-- 	largecount = largecount or 0

-- 	local scope = Public.get_scope(boat)

-- 	local memory = Memory.get_crew_memory()
-- 	local surface = game.surfaces[boat.surface_name]
-- 	if not surface then return end

-- 	local boatwidth, boatheight = scope.Data.width, scope.Data.height
-- 	local smallpositions = {}

-- 	local function boxposition()
-- 		local p1 = {x = boat.position.x - boatwidth*1 + Math.random(boatwidth)*0.85, y = boat.position.y - boatheight/2*0.8 + Math.random(boatheight)*0.8}

-- 		local whilesafety = 50
-- 		local p2
--         while whilesafety>0 and ((not p2) or Utils.contains(smallpositions, p2)) do
-- 			whilesafety = whilesafety - 1
--             p2 = surface.find_non_colliding_position('electric-furnace', p1, 6, 0.5, true)
--         end
-- 		if _DEBUG and (not p2) then game.print('obstacle box placement fail. placing at ' .. p1.x .. ', ' .. p1.y) end

-- 		local res = p2 or p1

-- 		return {x = res.x, y = res.y}
-- 	end

-- 	for i = 1, smallcount do
-- 		smallpositions[i] = boxposition()
-- 	end


-- 	-- for i = 1, largecount do
-- 	-- 	local p = boxposition()
-- 	-- 	for j=1,4 do
-- 	-- 		local p2 = surface.find_non_colliding_position('assembling-machine-1', p, 2, 0.1, true)
-- 	-- 		local e = surface.create_entity{name = 'wooden-chest', position = p2, force = memory.force_name, create_build_effect_smoke = false}
-- 	-- 		e.destructible = false
-- 	-- 		e.minable = false
-- 	-- 		e.rotatable = false
-- 	-- 	end
-- 	-- end


-- 	for i = 1, smallcount do
-- 		local p = smallpositions[i]
-- 		if p then
-- 			local e = surface.create_entity{name = 'wooden-chest', position = p, force = memory.force_name, create_build_effect_smoke = false}
-- 			e.destructible = false
-- 			e.minable = false
-- 			e.rotatable = false
-- 			if contents[i] then
-- 				local inventory = e.get_inventory(defines.inventory.chest)
-- 				for name, count in pairs(contents[i]) do
-- 					inventory.insert{name = name, count = count}
-- 				end
-- 			end
-- 		end
-- 	end
-- end


function Public.try_connect_upstairs_and_downstairs_poles(boat)
	-- local memory = Memory.get_crew_memory()

	if not (boat and boat.upstairs_pole and boat.upstairs_pole.valid and boat.downstairs_poles and boat.downstairs_poles[1] and boat.downstairs_poles[1][1] and boat.downstairs_poles[1][1].valid) then return end

	boat.upstairs_pole.connect_neighbour(boat.downstairs_poles[1][1])
end



local function process_entity_on_boat_unteleportable(memory, boat, newsurface, vector, players_just_offside, oldsurface_name, newsurface_name, e, name)

	local un = e.unit_number
	local p = e.position
	local p2 = {x = p.x + vector.x, y = p.y + vector.y}

	-- if e.type and e.type == 'underground-belt' then
	-- 	local n = e.neighbours
	-- 	if n and n.valid and n.position then
	-- 		local np = n.position
	-- 		if not underground_belt_neighbours_matrix[np.x] then
	-- 			underground_belt_neighbours_matrix[np.x] = {}
	-- 		end
	-- 		underground_belt_neighbours_matrix[np.x][np.y] = {name = e.name, pos = p}
	-- 	end
	-- end

	local ee = e.clone{position = p2, surface = newsurface, force = e.force, create_build_effect_smoke = false}

	if ee and ee.valid then
		e.destroy()
	else
		local f = e.force
		local eee = e.clone{position = {x = p.x % 1, y = p.y % 1}, surface = game.surfaces['nauvis'], force = f, create_build_effect_smoke = false}
		if eee and eee.valid then
			e.destroy()
			ee = eee.clone{position = {p.x + vector.x, p.y + vector.y}, surface = newsurface, force = f, create_build_effect_smoke = false}
			eee.destroy()
		end
	end

	if ee and ee.valid then

		if un and boat.healthbars and boat.healthbars[un] then
			Common.transfer_healthbar(un, ee, boat) --for some reason I don't understand, if the old healthbars is contained within memory rather than boat, sometimes this function can't find them (observed during the initial ship launch)
		end

		if name == 'artillery-turret' then
			-- if friendlyboat_bool then
			-- 	if memory.enemyboatcannons then memory.enemyboatcannons[#memory.enemyboatcannons + 1] = ee end
			-- else
			-- 	if boat.cannons then boat.cannons[#boat.cannons + 1] = ee end
			-- end
			if oldsurface_name == newsurface_name then -- push players
				local area1 = {{ee.position.x - 1.5, ee.position.y - 1.5}, {ee.position.x + 1.5, ee.position.y + 1.5}}
				local area2 = {{ee.position.x - vector.x - 1.5, ee.position.y - vector.y - 1.5}, {ee.position.x - vector.x + 1.5, ee.position.y - vector.y + 1.5}}
				if ee.position.y > boat.position.y then
					area1 = {{ee.position.x - 2.5, ee.position.y}, {ee.position.x + 2.5, ee.position.y + 1.5}}
					area2 = {{ee.position.x - 2.5, ee.position.y}, {ee.position.x + 2.5, ee.position.y + 1.5}}
				elseif ee.position.y < boat.position.y then
					area1 = {{ee.position.x - 2.5, ee.position.y - 1.5}, {ee.position.x + 2.5, ee.position.y}}
					area2 = {{ee.position.x - 2.5, ee.position.y - 1.5}, {ee.position.x + 2.5, ee.position.y}}
				end

				local intersectingcharacters = newsurface.find_entities_filtered{area = area1, name = 'character'}
				local intersectingcharacters2 = newsurface.find_entities_filtered{area = area2, name = 'character'}
				local teleportedbool = false
				for _, char in pairs(intersectingcharacters) do
					if Utils.contains(intersectingcharacters2, char) then
						char.teleport(vector.x, vector.y)
						teleportedbool = true
					end
				end
				for _, char in pairs(players_just_offside) do
					if Utils.contains(intersectingcharacters, char) or Utils.contains(intersectingcharacters2, char) then
						char.teleport(vector.x, vector.y)
						teleportedbool = true
					end
					if teleportedbool and char and char.valid then --did I push you into water?
						local nearbytiles = {newsurface.get_tile(char.position.x-1, char.position.y-1), newsurface.get_tile(char.position.x-1, char.position.y), newsurface.get_tile(char.position.x-1, char.position.y+1), newsurface.get_tile(char.position.x, char.position.y-1), newsurface.get_tile(char.position.x, char.position.y), newsurface.get_tile(char.position.x, char.position.y+1), newsurface.get_tile(char.position.x+1, char.position.y-1), newsurface.get_tile(char.position.x+1, char.position.y), newsurface.get_tile(char.position.x+1, char.position.y+1)}
						local watercount = 0
						for _, t in pairs(nearbytiles) do
							if Utils.contains(CoreData.water_tile_names, t.name) then watercount = watercount + 1 end
						end
						if watercount > 5 then
							local name2 = char.player and char.player.name or 'unknown-character'
							char.die(char.force)

							local force = memory.force
							if not (force and force.valid) then return end
							Common.notify_force(force,{'pirates.death_pushed_into_water_by_cannon', name2}, {r = 0.98, g = 0.66, b = 0.22})
						end
					end
				end
			end

		-- elseif ee.type and ee.type == 'underground-belt' then
		-- 	local n = underground_belt_neighbours_matrix[p.x] and underground_belt_neighbours_matrix[p.x][p.y] or nil
		-- 	if n then
		-- 		log(_inspect(n))
		-- 		local p3 = {x = n.pos.x + vector.x, y = n.pos.y + vector.y}
		-- 		local e3s = newsurface.find_entities_filtered{
		-- 			name = n.name,
		-- 			position = p3,
		-- 			radius = 0.01,
		-- 		}
		-- 		if e3s and #e3s>0 then
		-- 			local e3 = e3s[1]
		-- 			if e3 and e3.valid then
		-- 				ee.connect_neighbour(e3)
		-- 			end
		-- 		end
		-- 	end

		elseif name == 'electric-energy-interface' then
			boat.EEIs[#boat.EEIs + 1] = ee

		elseif name == 'linked-belt' then
			-- if ee.linked_belt_type == 'output' then
			-- 	boat.deck_output_belts[#boat.deck_output_belts + 1] = ee
			-- else
			-- 	boat.deck_input_belts[#boat.deck_input_belts + 1] = ee
			-- end
			boat.deck_whitebelts[#boat.deck_whitebelts + 1] = ee
		end
	end
end


local function process_entity_on_boat_teleportable(memory, boat, newsurface, newposition, vector, oldsurface_name, newsurface_name, electric_pole_neighbours_matrix, circuit_neighbours_matrix, e)

	if oldsurface_name == newsurface_name then
		e.teleport(vector.x, vector.y)
		e.update_connections()
	else
		local p = Utils.deepcopy(e.position)
		local p2 = {x = p.x + vector.x, y = p.y + vector.y}

		if e.type and e.type == 'electric-pole' then
			for k, v in pairs(e.neighbours or {}) do
				if k == 'copper' then --red and green cases handled by circuit_neighbours_matrix
					if not electric_pole_neighbours_matrix[k] then electric_pole_neighbours_matrix[k] = {} end
					for _, v2 in pairs(v) do
						if v2 and v2.valid and v2.position then
							local v2p = v2.position
							if not electric_pole_neighbours_matrix[k][v2p.x] then
								electric_pole_neighbours_matrix[k][v2p.x] = {}
							end
							if not electric_pole_neighbours_matrix[k][v2p.x][v2p.y] then
								electric_pole_neighbours_matrix[k][v2p.x][v2p.y] = {}
							end
							electric_pole_neighbours_matrix[k][v2p.x][v2p.y][#electric_pole_neighbours_matrix[k][v2p.x][v2p.y] + 1] = {name = e.name, pos = p}
						end
					end
				end
			end
		end

		for _, v in pairs(e.circuit_connection_definitions or {}) do
			local e2 = v.target_entity
			local wire = v.wire
			local source_circuit_id = v.source_circuit_id
			local target_circuit_id = v.target_circuit_id
			if e2 and e2.valid and e2.position and (wire == defines.wire_type.red or wire == defines.wire_type.green) then --observed an error "Expected source_wire_id for entities with more than one wire connection" in the .connect_neighbour() function called later, so putting the red/green wire check in to try and catch it
				local e2p = e2.position
				if not circuit_neighbours_matrix[e2p.x] then
					circuit_neighbours_matrix[e2p.x] = {}
				end
				if not circuit_neighbours_matrix[e2p.x][e2p.y] then
					circuit_neighbours_matrix[e2p.x][e2p.y] = {}
				end
				circuit_neighbours_matrix[e2p.x][e2p.y][#circuit_neighbours_matrix[e2p.x][e2p.y] + 1] = {name = e.name, pos = p, wire = wire, source_circuit_id = target_circuit_id, target_circuit_id = source_circuit_id} --flip since we will read these backwards
			end
		end

		local ee = e.clone{position = p2, surface = newsurface, create_build_effect_smoke = false}

		if boat.upstairs_pole and e == boat.upstairs_pole then
			boat.upstairs_pole = ee
			Public.try_connect_upstairs_and_downstairs_poles(boat)
		end

		e.destroy()

		-- Right now in the game we don't expect any non-player characters, so let's kill them to make a point:
		if ee and ee.valid and ee.name and ee.name == 'character' and (not ee.player) then
			ee.die()
		end

		if ee and ee.valid and ee.name then
			if ee.name == 'blue-chest' then
				if p2.y < newposition.y then
					memory.boat.decksteeringchests.left = ee
					-- --attach parrot to this:
					-- if boat.parrot then
					-- 	local r = rendering.draw_sprite{
					-- 		sprite = "file/parrot/parrot_idle_fly_1.png",
					-- 		surface = newsurface,
					-- 		target = ee,
					-- 		target_offset = Utils.psum{boat.parrot.position_relative_to_boat, boat.parrot.sprite_extra_offset},
					-- 		x_scale = 2.8,
					-- 		y_scale = 2.8,
					-- 	}
					-- 	local r2 = rendering.draw_text{
					-- 		text = 'Parrot',
					-- 		color = CoreData.colors.parrot,
					-- 		surface = newsurface,
					-- 		target = ee,
					-- 		target_offset = Utils.psum{boat.parrot.position_relative_to_boat, boat.parrot.text_extra_offset},
					-- 		alignment = 'center',
					-- 	}
					-- 	rendering.destroy(boat.parrot.render)
					-- 	rendering.destroy(boat.parrot.render_name)
					-- 	boat.parrot.frame = 1
					-- 	boat.parrot.state = Parrot.enum.FLY
					-- 	boat.parrot.render = r
					-- 	boat.parrot.render_name = r2
					-- end
				elseif p2.y > newposition.y then
					memory.boat.decksteeringchests.right = ee
				end
			end

			if circuit_neighbours_matrix[p.x] and circuit_neighbours_matrix[p.x][p.y] then
				for _, v2 in pairs(circuit_neighbours_matrix[p.x][p.y]) do
					local p3 = {x = v2.pos.x + vector.x, y = v2.pos.y + vector.y}
					local e3s = newsurface.find_entities_filtered{
						name = v2.name,
						position = p3,
						radius = 0.01,
					}
					if e3s and #e3s>0 then
						local e3 = e3s[1]
						if e3 and e3.valid then
							ee.connect_neighbour{wire = v2.wire, target_entity = e3, source_circuit_id = v2.source_circuit_id, target_circuit_id = v2.target_circuit_id}
						end
					end
				end
			end

			if ee.type and ee.type == 'electric-pole' then
				for k, v in pairs(electric_pole_neighbours_matrix or {}) do
					if v[p.x] and v[p.x][p.y] then
						for _, v2 in pairs(v[p.x][p.y]) do
							local p3 = {x = v2.pos.x + vector.x, y = v2.pos.y + vector.y}
							local e3s = newsurface.find_entities_filtered{
								name = v2.name,
								position = p3,
								radius = 0.01,
							}
							if e3s and #e3s>0 then
								local e3 = e3s[1]
								if e3 and e3.valid then
									if k == 'copper' then
										ee.connect_neighbour(e3)
									-- elseif k == 'red' then
									-- 	ee.connect_neighbour{wire = defines.wire_type.red, target_entity = e3}
									-- elseif k == 'green' then
									-- 	ee.connect_neighbour{wire = defines.wire_type.green, target_entity = e3}
									end
								end
							end
						end
					end
				end
			end
		end
	end
end


local function process_entity_on_boat(memory, boat, newsurface, newposition, vector, players_just_offside, oldsurface_name, newsurface_name, unique_entities_list, electric_pole_neighbours_matrix, circuit_neighbours_matrix, e)

	if e and e.valid and (not Utils.contains(unique_entities_list, e)) then
		unique_entities_list[#unique_entities_list + 1] = e
		local name = e.name

		if name and name == 'item-on-ground' then
			Common.give_items_to_crew{{name = e.stack.name, count = e.stack.count}}
			e.destroy()
		else
			if name == 'character' and e.player then -- characters with associated players treated as special case
				if oldsurface_name == newsurface_name then
					e.teleport(vector.x, vector.y)
				else
					local p = {e.position.x + vector.x, e.position.y + vector.y}
					if e.player then --e.player being nil caused a bug once!
						e.player.teleport(newsurface.find_non_colliding_position('character', p, 1.2, 0.2) or p, newsurface)
					end
				end

			elseif Utils.contains(CoreData.unteleportable_names, name) or (name == 'entity-ghost' and Utils.contains(CoreData.unteleportable_names, e.ghost_name)) then
				process_entity_on_boat_unteleportable(memory, boat, newsurface, vector, players_just_offside, oldsurface_name, newsurface_name, e, name)
			else
				process_entity_on_boat_teleportable(memory, boat, newsurface, newposition, vector, oldsurface_name, newsurface_name, electric_pole_neighbours_matrix, circuit_neighbours_matrix, e)
			end
		end
	end
end


local function teleport_handle_wake_tiles(boat, dummyboat, newsurface_name, oldsurface_name, oldsurface, newposition, vector, scope, vectordirection, vectorlength, old_water_tile, friendlyboat_bool)

	local static_params = Common.current_destination().static_params

	--handle wake tiles:
	if oldsurface_name == newsurface_name then
		local newtiles = {}

		local wakeareas = {}
		if vector.x < 0 then
			wakeareas = scope.Data.areas_infront
		elseif vector.x > 0 then
			wakeareas = scope.Data.areas_behind
		elseif vector.y > 0 then
			wakeareas = scope.Data.areas_offleft
		elseif vector.y < 0 then
			wakeareas = scope.Data.areas_offright
		end

		for i=1,vectorlength,1 do
			local adjustednewposition = {x = newposition.x - (i-1)*vectordirection.x, y = newposition.y - (i-1)*vectordirection.y}
			for _, area in pairs(wakeareas) do
				for _, p in pairs(Common.central_positions_within_area(area, adjustednewposition)) do
					local t = old_water_tile
					if static_params and static_params.deepwater_xposition and (p.x <= static_params.deepwater_xposition - 0.5) then t = 'deepwater' end
					if friendlyboat_bool and boat.state == enum_state.RETREATING and vector.x < 0 then --in this case we need to place some landing tiles, as the cannon juts out
						if (p.x >= boat.dockedposition.x + scope.Data.leftmost_gate_position) and (p.y <= scope.Data.upmost_gate_position or p.y >= scope.Data.downmost_gate_position) then t = CoreData.landing_tile end
					end
					newtiles[#newtiles + 1] = {name = t, position = {x = p.x, y = p.y}}
				end
			end
		end

		oldsurface.set_tiles(newtiles, true, true, true)

	else

		local p = dummyboat.position

		Public.destroy_boat(dummyboat, old_water_tile)

		local deepwaterfixuptiles = {}
		for x = p.x, p.x - scope.Data.width, -1 do
			if static_params and static_params.deepwater_xposition and x < static_params.deepwater_xposition then
				for y = p.y - scope.Data.height/2, p.y + scope.Data.height/2, 1 do
					deepwaterfixuptiles[#deepwaterfixuptiles + 1] = {name = 'deepwater', position = {x = x, y = y}}
				end
			end
		end

		oldsurface.set_tiles(deepwaterfixuptiles, true)

	end
end


local function teleport_handle_renderings(boat, oldsurface_name, newsurface_name, vector, scope, memory, newsurface)

	if boat.renderings_power and #boat.renderings_power > 0 then

		if oldsurface_name == newsurface_name then
			for _, r in pairs(boat.renderings_power) do
				if rendering.is_valid(r) then
					local p = rendering.get_target(r).position
					rendering.set_target(r, {x = p.x + vector.x, y = p.y + vector.y})
				end
			end
		else
			for _, r in pairs(boat.renderings_power) do
				if rendering.is_valid(r) then
					rendering.destroy(r)
				end
			end
			Public.draw_power_renderings(boat)
		end
	end

	if boat.rendering_crewname_text then
		local p = Utils.psum{boat.position, scope.Data.crewname_rendering_position}

		if oldsurface_name == newsurface_name then
			rendering.set_target(boat.rendering_crewname_text, p)
		else
			rendering.destroy(boat.rendering_crewname_text)
			boat.rendering_crewname_text = rendering.draw_text{
				text = memory.name,
				-- render_layer = '125', --does nothing
				surface = newsurface,
				target = p,
				color = CoreData.colors.renderingtext_yellow,
				scale = 8,
				font = 'default-game',
				alignment = 'left'
			}
		end
	end

	-- if boat.rendering_comfy then
	-- 	local p = Utils.psum{boat.position, scope.Data.comfy_rendering_position}

	-- 	if oldsurface_name == newsurface_name then
	-- 		rendering.set_target(boat.rendering_comfy, p)
	-- 	else
	-- 		rendering.destroy(boat.rendering_comfy)
	-- 		boat.rendering_comfy = rendering.draw_sprite{
	-- 			sprite = "file/comfy2.png",
	-- 			render_layer = '125',
	-- 			surface = newsurface,
	-- 			target = p,
	-- 		}
	-- 	end
	-- end
end


local function teleport_prepare_new_tiles(boat, new_floor_tile, oldposition, oldsurface_name, newsurface_name, vector, scope, vectorlength, vectordirection)

	if oldsurface_name == newsurface_name then
		local areas = {}
		if vector.x > 0 then
			areas = scope.Data.areas_infront
		elseif vector.x < 0 then
			areas = scope.Data.areas_behind
		elseif vector.y > 0 then
			areas = scope.Data.areas_offright
		elseif vector.y < 0 then
			areas = scope.Data.areas_offleft
		end

		local newtiles = {}
		for i=1,vectorlength,1 do
			local adjustedoldposition = {x = oldposition.x + (i-1)*vectordirection.x, y = oldposition.y + (i-1)*vectordirection.y}
			for _, area in pairs(areas) do
				Common.tiles_from_area(newtiles, area, adjustedoldposition, new_floor_tile)
				Common.destroy_decoratives_in_area(game.surfaces[newsurface_name], area, adjustedoldposition)
			end
		end
		game.surfaces[newsurface_name].set_tiles(newtiles, true, true, true)
	else
		Public.place_boat(boat, new_floor_tile, false, true)
	end
end



--if you're teleporting to the same surface, only do this in an orthogonal direction
function Public.teleport_boat(boat, newsurface_name, newposition, new_floor_tile, old_water_tile)
	new_floor_tile = new_floor_tile or CoreData.moving_boat_floor
	old_water_tile = old_water_tile or 'water'
	local oldsurface_name = boat.surface_name
	newsurface_name = newsurface_name or oldsurface_name
	local oldposition = boat.position
	newposition = newposition or oldposition

	local scope = Public.get_scope(boat)

	local memory = Memory.get_crew_memory()
	local friendlyboat_bool = (memory.force_name == boat.force_name)
	local oldsurface, newsurface = game.surfaces[oldsurface_name], game.surfaces[newsurface_name]

	local dummyboat
	if oldsurface_name ~= newsurface_name then
		-- we will place this with water:
		dummyboat = Utils.deepcopy(boat)
	end

	game.surfaces['nauvis'].request_to_generate_chunks({0,0}, 1)
	game.surfaces['nauvis'].force_generate_chunk_requests() --WARNING: THIS DOES NOT PLAY NICELY WITH DELAYED TASKS. log(_inspect{global_memory.working_id}) was observed to vary before and after this function.

	-- reset these:
	boat.deck_whitebelts = {}
	boat.EEIs = {}

	-- only relevant for teleporting to the same surface, i.e. moving:
	local vector = {x = newposition.x - oldposition.x, y = newposition.y - oldposition.y}
	local vectordirection = {x = 0, y = 0};
	local vectorlength = 0;
	if oldsurface_name == newsurface_name then
		if vector.x > 0 then
			vectorlength = vector.x
			vectordirection = {x = 1, y = 0}
		elseif vector.x < 0 then
			vectorlength = - vector.x
			vectordirection = {x = -1, y = 0}
		elseif vector.y > 0 then
			vectorlength = vector.y
			vectordirection = {x = 0, y = 1}
		elseif vector.y < 0 then
			vectorlength = - vector.y
			vectordirection = {x = 0, y = -1}
		end
	end


	boat.position = newposition
	boat.surface_name = newsurface_name

	if friendlyboat_bool then
		if oldsurface_name == newsurface_name then
			if oldsurface_name ~= CoreData.lobby_surface_name then
				local oldspawn = memory.spawnpoint
				memory.spawnpoint = {x = oldspawn.x + vector.x, y = oldspawn.y + vector.y}
			end
		else
			memory.spawnpoint = {x = scope.Data.spawn_point.x + boat.position.x, y = scope.Data.spawn_point.y + boat.position.y}
		end
		game.forces[boat.force_name].set_spawn_position(memory.spawnpoint, game.surfaces[newsurface_name])
	end

	local sorting_f
	if oldsurface_name == newsurface_name then
		sorting_f = function(a,b)
			if (a.name == 'straight-rail' or a.name == 'curved-rail') and (not (b.name == 'straight-rail' or b.name == 'curved-rail')) then return true end
			if (b.name == 'straight-rail' or b.name == 'curved-rail') and (not (a.name == 'straight-rail' or a.name == 'curved-rail')) then return false end
			if vector.x > 0 then
				return ((a.position.x > b.position.x) or ((a.position.x == b.position.x) and (a.position.y > b.position.y)))
			elseif vector.x < 0 then
				return ((a.position.x < b.position.x) or ((a.position.x == b.position.x) and (a.position.y > b.position.y)))
			end
			if vector.y > 0 then
				return ((a.position.y > b.position.y) or ((a.position.y == b.position.y) and (a.position.x > b.position.x)))
			elseif vector.y < 0 then
				return ((a.position.y < b.position.y) or ((a.position.y == b.position.y) and (a.position.x > b.position.x)))
			end
			return false
		end
	else
		 --move walls before artillery
		sorting_f = function(a,b)
			return (a.name and a.name == 'stone-wall') and (not (b.name and b.name == 'stone-wall'))
		end
	end


	local chunkloadradius = 1
	if boat.type == enum.SLOOP then
		chunkloadradius = 2
	elseif boat.type == enum.CUTTER then
		chunkloadradius = 3
	end
	Common.ensure_chunks_at(game.surfaces[newsurface_name], {x = newposition.x - scope.Data.width, y = newposition.y}, chunkloadradius)

	teleport_prepare_new_tiles(boat, new_floor_tile, oldposition, oldsurface_name, newsurface_name, vector, scope, vectorlength, vectordirection)


	local entities_on_boat = {}
	for _, relative_area in pairs(scope.Data.tile_areas) do
		local area = {{oldposition.x + relative_area[1][1], oldposition.y + relative_area[1][2]}, {oldposition.x + relative_area[2][1], oldposition.y + relative_area[2][2]}}
		local entities = oldsurface.find_entities(area)
		for _, e in pairs(entities) do
			if e and e.valid then
				entities_on_boat[#entities_on_boat + 1] = e
			end
		end
	end

	local players_just_offside = {}

	if friendlyboat_bool then
		players_just_offside = Public.get_players_just_offside(boat, oldposition)
		entities_on_boat = Utils.exclude(entities_on_boat, players_just_offside)
		table.sort(entities_on_boat, sorting_f)
	end


	local unique_entities_list = {}

	-- copy away rails:
	local saved_rails = {}
	local first_rail_found_p = nil
	for i = 1, #entities_on_boat do
		local e = entities_on_boat[i]
		if e and e.valid and (e.name == 'straight-rail' or e.name == 'curved-rail' or (e.name == 'entity-ghost' and (e.ghost_name == 'straight-rail' or e.ghost_name == 'curved-rail'))) and (not Utils.contains(unique_entities_list, e)) then
			unique_entities_list[#unique_entities_list + 1] = e
			local p, f = e.position, e.force
			if not first_rail_found_p then
				first_rail_found_p = {x = p.x, y = p.y}
			end
			local ee = e.clone{position = {x = p.x - first_rail_found_p.x, y = p.y - first_rail_found_p.y}, surface = game.surfaces['piratedev1'], force = f, create_build_effect_smoke = false}
			if ee and ee.valid then
				saved_rails[#saved_rails + 1] = ee
			end
		end
	end

	-- copy away wagons:
	local saved_wagons = {}
	for i = 1, #entities_on_boat do
		local e = entities_on_boat[i]
		if e and e.valid and (e.name == 'cargo-wagon' or e.name == 'locomotive' or (e.name == 'entity-ghost' and (e.ghost_name == 'cargo-wagon' or e.ghost_name == 'locomotive'))) and (not Utils.contains(unique_entities_list, e)) then
			unique_entities_list[#unique_entities_list + 1] = e
			local p, f = e.position, e.force
			local ee = e.clone{position = {x = p.x - first_rail_found_p.x, y = p.y - first_rail_found_p.y}, surface = game.surfaces['piratedev1'], force = f, create_build_effect_smoke = false}
			if ee and ee.valid then
				saved_wagons[#saved_wagons + 1] = ee
			end
		end
	end


	-- destroy rail/wagons:
	for i = 1, #entities_on_boat do
		local e = entities_on_boat[i]
		if e and e.valid and (e.name == 'cargo-wagon' or e.name == 'locomotive' or (e.name == 'entity-ghost' and (e.ghost_name == 'cargo-wagon' or e.name == 'locomotive'))) then
			e.destroy()
		end
	end
	for i = 1, #entities_on_boat do
		local e = entities_on_boat[i]
		if e and e.valid and (e.name == 'straight-rail' or e.name == 'curved-rail' or (e.name == 'entity-ghost' and (e.ghost_name == 'straight-rail' or e.ghost_name == 'curved-rail'))) then
			e.destroy()
		end
	end



	local electric_pole_neighbours_matrix = {}
	local circuit_neighbours_matrix = {}
	-- local underground_belt_neighbours_matrix = {}

	for i = 1, #entities_on_boat do
		local e = entities_on_boat[i]
		process_entity_on_boat(memory, boat, newsurface, newposition, vector, players_just_offside, oldsurface_name, newsurface_name, unique_entities_list, electric_pole_neighbours_matrix, circuit_neighbours_matrix, e)
	end


	-- copy back rails:
	for _, ee in ipairs(saved_rails) do
		if ee and ee.valid then
			local p, f = ee.position, ee.force
			ee.clone{position = {p.x + first_rail_found_p.x + vector.x, p.y + first_rail_found_p.y + vector.y}, surface = newsurface, force = f, create_build_effect_smoke = false}
		end
	end

	-- copy back wagons:
	for _, ee in ipairs(saved_wagons) do
		if ee and ee.valid then
			local p, f = ee.position, ee.force
			ee.clone{position = {p.x + first_rail_found_p.x + vector.x, p.y + first_rail_found_p.y + vector.y}, surface = newsurface, force = f, create_build_effect_smoke = false}
		end
	end

	-- destroy copies of rail/wagons:
	for _, e in ipairs(saved_wagons) do
		if e and e.valid then
			e.destroy()
		end
	end
	for _, e in ipairs(saved_rails) do
		if e and e.valid then
			e.destroy()
		end
	end


	Public.put_deck_whitebelts_in_standard_order(boat)
	Hold.connect_up_linked_belts_to_deck()
	Cabin.connect_up_linked_belts_to_deck()

	teleport_handle_wake_tiles(boat, dummyboat, newsurface_name, oldsurface_name, oldsurface, newposition, vector, scope, vectordirection, vectorlength, old_water_tile, friendlyboat_bool)

	teleport_handle_renderings(boat, oldsurface_name, newsurface_name, vector, scope, memory, newsurface)

end

return Public