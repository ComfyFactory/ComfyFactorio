-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
-- local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
-- local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect


local SurfacesCommon = require 'maps.pirates.surfaces.common'

local Public = {}
local enum = {
	INITIAL = 'Initial',
	SECONDARY = 'Secondary',
}
Public.enum = enum

Public.Data = {}

-- local enum_boat = Boats.enum
-- Public.enum_boat = enum_boat

Public.Data.width = 92
Public.Data.height = 46
Public.Data.loco_offset = { x = -2, y = 0 }
-- Public.Data.loco_offset = {x = 18, y = 0}
-- Public.Data.display_name = 'Ship\'s Hold'
Public.Data.downstairs_pole_positions = {
	{ x = -1, y = -5 },
	{ x = -1, y = 5 },
}

Public.Data.downstairs_fluid_storage_positions = {
	{ x = -31.5, y = -21.5 },
	{ x = -31.5, y = 21.5 },
}

Public.Data.helper_text_rendering_positions = {
	{ x = -46.5, y = -3.5 },
	{ x = 46.5,  y = -3.5 },
	{ x = -46.5, y = 2.5 },
	{ x = 46.5,  y = 2.5 },
}

Public[enum.INITIAL] = {}
Public[enum.INITIAL].Data = {}
Public[enum.INITIAL].Data.hold_whitebelts_lrtp_order = {
	{ x = -19.5, y = -21.5, direction = defines.direction.north, type = 'output' },
	{ x = -18.5, y = -21.5, direction = defines.direction.north, type = 'output' },
	{ x = -17.5, y = -21.5, direction = defines.direction.north, type = 'output' },
	{ x = -16.5, y = -21.5, direction = defines.direction.north, type = 'output' },

	{ x = 16.5,  y = -21.5, direction = defines.direction.north, type = 'output' },
	{ x = 17.5,  y = -21.5, direction = defines.direction.north, type = 'output' },
	{ x = 18.5,  y = -21.5, direction = defines.direction.north, type = 'output' },
	{ x = 19.5,  y = -21.5, direction = defines.direction.north, type = 'output' },

	{ x = -44.5, y = -3.5,  direction = defines.direction.west,  type = 'output' },
	{ x = 44.5,  y = -3.5,  direction = defines.direction.east,  type = 'output' },
	{ x = -44.5, y = -2.5,  direction = defines.direction.west,  type = 'output' },
	{ x = 44.5,  y = -2.5,  direction = defines.direction.east,  type = 'output' },
	{ x = -44.5, y = 2.5,   direction = defines.direction.west,  type = 'input' },
	{ x = 44.5,  y = 2.5,   direction = defines.direction.east,  type = 'input' },
	{ x = -44.5, y = 3.5,   direction = defines.direction.west,  type = 'input' },
	{ x = 44.5,  y = 3.5,   direction = defines.direction.east,  type = 'input' },

	{ x = -19.5, y = 21.5,  direction = defines.direction.south, type = 'input' },
	{ x = -18.5, y = 21.5,  direction = defines.direction.south, type = 'input' },
	{ x = -17.5, y = 21.5,  direction = defines.direction.south, type = 'input' },
	{ x = -16.5, y = 21.5,  direction = defines.direction.south, type = 'input' },

	{ x = 16.5,  y = 21.5,  direction = defines.direction.south, type = 'input' },
	{ x = 17.5,  y = 21.5,  direction = defines.direction.south, type = 'input' },
	{ x = 18.5,  y = 21.5,  direction = defines.direction.south, type = 'input' },
	{ x = 19.5,  y = 21.5,  direction = defines.direction.south, type = 'input' },
}

Public[enum.SECONDARY] = {}
Public[enum.SECONDARY].Data = {}
Public[enum.SECONDARY].Data.hold_whitebelts_lrtp_order = {
	{ x = -44.5, y = -3.5, direction = defines.direction.west, type = 'output' },
	{ x = 44.5,  y = -3.5, direction = defines.direction.east, type = 'output' },
	{ x = -44.5, y = -2.5, direction = defines.direction.west, type = 'output' },
	{ x = 44.5,  y = -2.5, direction = defines.direction.east, type = 'output' },
	{ x = -44.5, y = 2.5,  direction = defines.direction.west, type = 'input' },
	{ x = 44.5,  y = 2.5,  direction = defines.direction.east, type = 'input' },
	{ x = -44.5, y = 3.5,  direction = defines.direction.west, type = 'input' },
	{ x = 44.5,  y = 3.5,  direction = defines.direction.east, type = 'input' },
}

Public.Data.boxes_bp =
[[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]]
Public.Data.boxes_bp_offset = { x = 0, y = 0 }

Public.Data.surfacename_rendering_pos = { x = Public.Data.loco_offset.x, y = -Public.Data.height / 2 - 5 }

function Public.get_hold_surface_name(nth)
	nth = nth or 1
	local memory = Memory.get_crew_memory()
	local subtype = (nth == 1) and enum.INITIAL or enum.SECONDARY
	return SurfacesCommon.encode_surface_name(memory.id, nth, SurfacesCommon.enum.HOLD, subtype)
end

function Public.get_hold_surface(nth)
	nth = nth or 1
	local name = Public.get_hold_surface_name(nth)
	if name and game.surfaces[name] and game.surfaces[name].valid then return game.surfaces[name] end
end

function Public.create_hold_surface(nth)
	local memory = Memory.get_crew_memory()
	local boat = memory.boat


	local width = Public.Data.width
	local height = Public.Data.height
	local map_gen_settings = Common.default_map_gen_settings(width, height)

	map_gen_settings.autoplace_settings.decorative.treat_missing_as_default = false

	local holdname = Public.get_hold_surface_name(nth)

	if not holdname then log(_inspect { 'holdname is nil? here some stuff:', memory.id, nth, SurfacesCommon.enum.HOLD }) end

	local surface = game.create_surface(holdname, map_gen_settings)
	surface.freeze_daytime = true
	surface.daytime = 0.25
	surface.show_clouds = false
	surface.solar_power_multiplier = 0

	-- more here

	Common.ensure_chunks_at(surface, { x = 0, y = 0 }, 5)


	local subtype = nth == 1 and enum.INITIAL or enum.SECONDARY

	local whitebelts_table, whitebelts_data

	if (not boat.hold_whitebelts) then boat.hold_whitebelts = {} end
	boat.hold_whitebelts[nth] = {}
	whitebelts_table = boat.hold_whitebelts[nth]

	if subtype == enum.INITIAL then
		whitebelts_data = Public[enum.INITIAL].Data.hold_whitebelts_lrtp_order
	elseif subtype == enum.SECONDARY then
		whitebelts_data = Public[enum.SECONDARY].Data.hold_whitebelts_lrtp_order
	end

	for _, b in ipairs(whitebelts_data) do
		local p = { x = b.x, y = b.y }
		local e = surface.create_entity({ name = 'linked-belt', position = p, force = boat.force_name, create_build_effect_smoke = false, direction = b.direction })
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = false
			e.operable = false
			local type = b.type
			if nth % 2 == 0 then
				if type == 'input' then type = 'output' else type = 'input' end
			end
			e.linked_belt_type = type
			whitebelts_table[#whitebelts_table + 1] = e
		end
	end

	if (not boat.hold_helper_renderings) then boat.hold_helper_renderings = {} end
	boat.hold_helper_renderings[nth] = {}
	for i, p in ipairs(Public.Data.helper_text_rendering_positions) do
		local alignment = i % 2 == 0 and 'left' or 'right'
		boat.hold_helper_renderings[nth][i] = rendering.draw_text {
			surface = surface,
			target = p,
			color = CoreData.colors.renderingtext_green,
			scale = 1,
			font = 'default-game',
			alignment = alignment,
			text = { 'pirates.hold_connections_label_inactive' },
		}
	end

	Common.build_small_loco(surface, Public.Data.loco_offset, memory.force, { 255, 106, 52 })

	if not boat.downstairs_poles then boat.downstairs_poles = {} end
	boat.downstairs_poles[nth] = {}
	for i = 1, #Public.Data.downstairs_pole_positions do
		local e = surface.create_entity({ name = 'substation', position = Public.Data.downstairs_pole_positions[i], force = boat.force_name, create_build_effect_smoke = false })
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = false
			boat.downstairs_poles[nth][i] = e
		end
	end
	if nth >= 2 then
		Common.force_connect_poles(boat.downstairs_poles[nth][1], boat.downstairs_poles[nth - 1][2])
	end

	if not boat.downstairs_fluid_storages then boat.downstairs_fluid_storages = {} end
	boat.downstairs_fluid_storages[nth] = {}
	for i = 1, #Public.Data.downstairs_fluid_storage_positions do
		local e = surface.create_entity({ name = 'storage-tank', position = Public.Data.downstairs_fluid_storage_positions[i], force = boat.force_name, create_build_effect_smoke = false })
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = true
			boat.downstairs_fluid_storages[nth][i] = e
		end
	end

	-- We place obstacle boxes before the other static boxes, so that they are potentially one tile closer to the edge than they would be otherwise:
	local items = subtype == enum.INITIAL and Balance.starting_items_crew_downstairs() or {}
	Common.surface_place_random_obstacle_boxes(Public.get_hold_surface(nth), { x = 0, y = 0 }, Public.Data.width, Public.Data.height, 'rocket-silo', { [1] = 0, [2] = 6, [3] = 5, [4] = 2 }, items)
	-- Public.hold_place_random_obstacle_boxes(nth, {[1] = 0, [2] = 9, [3] = 3, [4] = 1}, items)

	local boxes = Common.build_from_blueprint(Public.Data.boxes_bp, surface, Public.Data.boxes_bp_offset, boat.force_name)
	for _, e in pairs(boxes) do
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = false
		end
	end

	if subtype == enum.SECONDARY then
		local difficulty_name = CoreData.get_difficulty_option_informal_name_from_value(memory.difficulty)
		if difficulty_name == 'nightmare' then
			Public.upgrade_chests(nth, 'steel-chest')
		elseif difficulty_name ~= 'easy' then
			Public.upgrade_chests(nth, 'iron-chest')
		end

		Public.nth_hold_connect_linked_belts(nth)
	end

	if nth == 1 then
		memory.shiphold_rendering_1 = rendering.draw_text {
			text = { 'pirates.surface_label_hold' },
			surface = surface,
			target = Public.Data.surfacename_rendering_pos,
			color = CoreData.colors.renderingtext_yellow,
			scale = 6,
			font = 'default-game',
			alignment = 'center'
		}
	else
		if nth == 2 then
			if memory.shiphold_rendering_1 then
				memory.shiphold_rendering_1.text = { 'pirates.surface_label_hold_nth', 1 }
			end
		end
		rendering.draw_text {
			text = { 'pirates.surface_label_hold_nth', nth },
			surface = surface,
			target = Public.Data.surfacename_rendering_pos,
			color = CoreData.colors.renderingtext_yellow,
			scale = 6,
			font = 'default-game',
			alignment = 'center'
		}
	end
end

function Public.add_another_hold_surface()
	local memory = Memory.get_crew_memory()

	memory.hold_surface_count = memory.hold_surface_count + 1

	Public.create_hold_surface(memory.hold_surface_count)

	return memory.hold_surface_count
end

function Public.upgrade_chests(nth, new_chest)
	local memory = Memory.get_crew_memory()
	local boat = memory.boat
	local surface = Public.get_hold_surface(nth)

	local ps = Common.entity_positions_from_blueprint(Public.Data.boxes_bp, { x = -Public.Data.width / 2, y = -Public.Data.height / 2 })

	for _, p in pairs(ps) do
		local es = surface.find_entities_filtered { name = 'wooden-chest', position = p, radius = 0.05 }
		if es and #es == 1 then
			es[1].minable = true
			es[1].destructible = true
			es[1].rotatable = true
		end
		local e2 = surface.create_entity { name = new_chest, position = p, fast_replace = true, spill = false, force = boat.force_name }
		e2.minable = false
		e2.destructible = false
		e2.rotatable = false
	end
end

function Public.connect_up_linked_belts_to_deck() --assumes both are in standard lrtd order
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if boat and boat.deck_whitebelts and #boat.deck_whitebelts > 0 and boat.hold_whitebelts and boat.hold_whitebelts[1] and #boat.hold_whitebelts[1] > 0 then
		local connections = {
			{ 1,  1 },
			{ 2,  2 },
			{ 3,  3 },
			{ 4,  4 },
			{ 5,  5 },
			{ 6,  6 },
			{ 7,  7 },
			{ 8,  8 },
			{ 17, 17 },
			{ 18, 18 },
			{ 19, 19 },
			{ 20, 20 },
			{ 21, 21 },
			{ 22, 22 },
			{ 23, 23 },
			{ 24, 24 },
		}

		for _, c in pairs(connections) do
			local b1 = boat.hold_whitebelts[1][c[1]]
			local b2 = boat.deck_whitebelts[c[2]]
			-- log(string.format("Connecting hold belt %d to deck belt %d", c[1], c[2]))
			b1.connect_linked_belts(b2)
		end
	end
end

function Public.nth_hold_connect_linked_belts(nth) --assumes both are in standard lrtd order
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if boat.hold_whitebelts and boat.hold_whitebelts[nth - 1] and #boat.hold_whitebelts[nth - 1] > 0 and boat.hold_whitebelts[nth] and #boat.hold_whitebelts[nth] > 0 then
		local connections
		if nth % 2 == 0 then
			if nth == 2 then
				connections = {
					{ 5, 13 },
					{ 6, 14 },
					{ 7, 15 },
					{ 8, 16 },
				}
				for i, c in pairs(connections) do
					local b1 = boat.hold_whitebelts[nth][c[1]]
					local b2 = boat.hold_whitebelts[nth - 1][c[2]]
					b1.connect_linked_belts(b2)
				end

				boat.hold_helper_renderings[nth][3].text = { 'pirates.hold_connections_label_from', nth - 1 }
				boat.hold_helper_renderings[nth - 1][3].text = { 'pirates.hold_connections_label_to', nth }
				boat.hold_helper_renderings[nth][4].text = { 'pirates.hold_connections_label_from', nth - 1 }
				boat.hold_helper_renderings[nth - 1][4].text = { 'pirates.hold_connections_label_to', nth }
			else
				connections = {
					{ 5, 5 },
					{ 6, 6 },
					{ 7, 7 },
					{ 8, 8 },
				}
				for _, c in pairs(connections) do
					local b1 = boat.hold_whitebelts[nth][c[1]]
					local b2 = boat.hold_whitebelts[nth - 1][c[2]]
					b1.connect_linked_belts(b2)
				end

				boat.hold_helper_renderings[nth][3].text = { 'pirates.hold_connections_label_from', nth - 1 }
				boat.hold_helper_renderings[nth - 1][3].text = { 'pirates.hold_connections_label_to', nth }
				boat.hold_helper_renderings[nth][4].text = { 'pirates.hold_connections_label_from', nth - 1 }
				boat.hold_helper_renderings[nth - 1][4].text = { 'pirates.hold_connections_label_to', nth }
			end
			connections = {
				{ 1, 9 },
				{ 2, 10 },
				{ 3, 11 },
				{ 4, 12 },
			}
			for _, c in pairs(connections) do
				local b1 = boat.hold_whitebelts[nth][c[1]]
				local b2 = boat.hold_whitebelts[1][c[2]]
				b1.connect_linked_belts(b2)
			end

			boat.hold_helper_renderings[nth][1].text = { 'pirates.hold_connections_label_to', 1 }
			boat.hold_helper_renderings[1][1].text = { 'pirates.hold_connections_label_from', nth }
			boat.hold_helper_renderings[nth][2].text = { 'pirates.hold_connections_label_to', 1 }
			boat.hold_helper_renderings[1][2].text = { 'pirates.hold_connections_label_from', nth }
		else
			connections = {
				{ 1, 1 },
				{ 2, 2 },
				{ 3, 3 },
				{ 4, 4 },
			}
			for _, c in pairs(connections) do
				local b1 = boat.hold_whitebelts[nth][c[1]]
				local b2 = boat.hold_whitebelts[nth - 1][c[2]]
				b1.connect_linked_belts(b2)
			end

			boat.hold_helper_renderings[nth][1].text = { 'pirates.hold_connections_label_from', nth - 1 }
			boat.hold_helper_renderings[nth - 1][1].text = { 'pirates.hold_connections_label_to', nth }
			boat.hold_helper_renderings[nth][2].text = { 'pirates.hold_connections_label_from', nth - 1 }
			boat.hold_helper_renderings[nth - 1][2].text = { 'pirates.hold_connections_label_to', nth }

			connections = {
				{ 5, 9 },
				{ 6, 10 },
				{ 7, 11 },
				{ 8, 12 },
			}
			for _, c in pairs(connections) do
				local b1 = boat.hold_whitebelts[nth][c[1]]
				local b2 = boat.hold_whitebelts[1][c[2]]
				b1.connect_linked_belts(b2)
			end

			boat.hold_helper_renderings[nth][3].text = { 'pirates.hold_connections_label_to', 1 }
			boat.hold_helper_renderings[1][1].text = { 'pirates.hold_connections_label_from', nth }
			boat.hold_helper_renderings[nth][4].text = { 'pirates.hold_connections_label_to', 1 }
			boat.hold_helper_renderings[1][2].text = { 'pirates.hold_connections_label_from', nth }
		end
	end
end

function Public.terrain(args)
	if args.p.x < Public.Data.width / 2 - 5 and args.p.x > Public.Data.width / 2 - 10 and args.p.y > Public.Data.height / 2 - 2 then
		args.tiles[#args.tiles + 1] = { name = 'water', position = args.p }
	else
		args.tiles[#args.tiles + 1] = { name = CoreData.static_boat_floor, position = args.p }
	end
	return nil
end

function Public.chunk_structures()
	return nil
end

return Public
