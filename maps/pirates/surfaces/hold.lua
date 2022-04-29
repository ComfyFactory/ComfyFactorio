
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
Public.Data.loco_offset = {x = -2, y = 0}
-- Public.Data.loco_offset = {x = 18, y = 0}
-- Public.Data.display_name = 'Ship\'s Hold'
Public.Data.downstairs_pole_positions = {
	{x = -1, y = -5},
	{x = -1, y = 5},
}

Public[enum.INITIAL] = {}
Public[enum.INITIAL].Data = {}
Public[enum.INITIAL].Data.hold_whitebelts_lrtp_order = {
	{x = -19.5, y = -21.5, direction = defines.direction.north, type = 'output'},
	{x = -18.5, y = -21.5, direction = defines.direction.north, type = 'output'},
	{x = -17.5, y = -21.5, direction = defines.direction.north, type = 'output'},
	{x = -16.5, y = -21.5, direction = defines.direction.north, type = 'output'},

	{x = 16.5, y = -21.5, direction = defines.direction.north, type = 'output'},
	{x = 17.5, y = -21.5, direction = defines.direction.north, type = 'output'},
	{x = 18.5, y = -21.5, direction = defines.direction.north, type = 'output'},
	{x = 19.5, y = -21.5, direction = defines.direction.north, type = 'output'},

	{x = -44.5, y = -3.5, direction = defines.direction.west, type = 'output'},
	{x = 44.5, y = -3.5, direction = defines.direction.east, type = 'output'},
	{x = -44.5, y = -2.5, direction = defines.direction.west, type = 'output'},
	{x = 44.5, y = -2.5, direction = defines.direction.east, type = 'output'},
	{x = -44.5, y = 2.5, direction = defines.direction.west, type = 'input'},
	{x = 44.5, y = 2.5, direction = defines.direction.east, type = 'input'},
	{x = -44.5, y = 3.5, direction = defines.direction.west, type = 'input'},
	{x = 44.5, y = 3.5, direction = defines.direction.east, type = 'input'},

	{x = -19.5, y = 21.5, direction = defines.direction.south, type = 'input'},
	{x = -18.5, y = 21.5, direction = defines.direction.south, type = 'input'},
	{x = -17.5, y = 21.5, direction = defines.direction.south, type = 'input'},
	{x = -16.5, y = 21.5, direction = defines.direction.south, type = 'input'},

	{x = 16.5, y = 21.5, direction = defines.direction.south, type = 'input'},
	{x = 17.5, y = 21.5, direction = defines.direction.south, type = 'input'},
	{x = 18.5, y = 21.5, direction = defines.direction.south, type = 'input'},
	{x = 19.5, y = 21.5, direction = defines.direction.south, type = 'input'},
}

Public[enum.SECONDARY] = {}
Public[enum.SECONDARY].Data = {}
Public[enum.SECONDARY].Data.hold_whitebelts_lrtp_order = {
	{x = -44.5, y = -3.5, direction = defines.direction.west, type = 'output'},
	{x = 44.5, y = -3.5, direction = defines.direction.east, type = 'output'},
	{x = -44.5, y = -2.5, direction = defines.direction.west, type = 'output'},
	{x = 44.5, y = -2.5, direction = defines.direction.east, type = 'output'},
	{x = -44.5, y = 2.5, direction = defines.direction.west, type = 'input'},
	{x = 44.5, y = 2.5, direction = defines.direction.east, type = 'input'},
	{x = -44.5, y = 3.5, direction = defines.direction.west, type = 'input'},
	{x = 44.5, y = 3.5, direction = defines.direction.east, type = 'input'},
}

Public.Data.boxes_bp = [[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]]
Public.Data.boxes_bp_offset = {x = 0, y = 0}

Public.Data.surfacename_rendering_pos = {x = Public.Data.loco_offset.x, y = -Public.Data.height/2 - 5}

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

	if not holdname then log(_inspect{'holdname is nil? here some stuff:', memory.id, nth, SurfacesCommon.enum.HOLD}) end

	local surface = game.create_surface(holdname, map_gen_settings)
	surface.freeze_daytime = true
	surface.daytime = 0
	surface.show_clouds = false
	surface.solar_power_multiplier = 0

	-- more here

	Common.ensure_chunks_at(surface, {x = 0, y = 0}, 5)


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
		local p = {x = b.x, y = b.y}
		local e = surface.create_entity({name = 'linked-belt', position = p, force = boat.force_name, create_build_effect_smoke = false, direction = b.direction})
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

	Common.build_small_loco(surface, Public.Data.loco_offset, memory.force, {255, 106, 52})

	-- We place obstacle boxes before the other static boxes, so that they are potentially one tile closer to the edge than they would be otherwise:
	local items = subtype == enum.INITIAL and Balance.starting_items_crew_downstairs() or {}
	Common.surface_place_random_obstacle_boxes(Public.get_hold_surface(nth), {x=0,y=0}, Public.Data.width, Public.Data.height, 'rocket-silo', {[1] = 0, [2] = 5, [3] = 5, [4] = 2}, items)
	-- Public.hold_place_random_obstacle_boxes(nth, {[1] = 0, [2] = 9, [3] = 3, [4] = 1}, items)

	local boxes = Common.build_from_blueprint(Public.Data.boxes_bp, surface, Public.Data.boxes_bp_offset, boat.force_name)
	for _, e in pairs(boxes) do
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = false
		end
	end

	if not boat.downstairs_poles then boat.downstairs_poles = {} end
	boat.downstairs_poles[nth] = {}
	for i = 1, 2 do
		local e = surface.create_entity({name = 'substation', position = Public.Data.downstairs_pole_positions[i], force = boat.force_name, create_build_effect_smoke = false})
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = false
			boat.downstairs_poles[nth][i] = e
		end
	end
	if nth >= 2 then
		if boat.downstairs_poles[nth][1] and boat.downstairs_poles[nth][1].valid and boat.downstairs_poles[nth-1][2] and boat.downstairs_poles[nth-1][2].valid then
			boat.downstairs_poles[nth][1].connect_neighbour(boat.downstairs_poles[nth-1][2])
		end
	end

	if subtype == enum.SECONDARY then
		local difficulty_name = CoreData.get_difficulty_name_from_value(Common.difficulty())
		if difficulty_name == CoreData.difficulty_options[#CoreData.difficulty_options].text then
			Public.upgrade_chests(nth, 'steel-chest')
		elseif difficulty_name ~= CoreData.difficulty_options[1].text then
			Public.upgrade_chests(nth, 'iron-chest')
		end

		Public.nth_hold_connect_linked_belts(nth)
	end

	if nth==1 then
		memory.shiphold_rendering_1 = rendering.draw_text{
			text = 'Ship\'s Hold',
			surface = surface,
			target = Public.Data.surfacename_rendering_pos,
			color = CoreData.colors.renderingtext_yellow,
			scale = 6,
			font = 'default-game',
			alignment = 'center'
		}
	else
		if nth==2 then
			if memory.shiphold_rendering_1 then
				rendering.set_text(memory.shiphold_rendering_1, 'Ship\'s Hold: -1')
			end
		end
		rendering.draw_text{
			text = 'Ship\'s Hold: -' .. nth,
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

	local ps = Common.entity_positions_from_blueprint(Public.Data.boxes_bp, {x = -Public.Data.width/2 ,y = -Public.Data.height/2})

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


function Public.connect_up_linked_belts_to_deck() --assumes both are in standard lrtd order
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if boat and boat.deck_whitebelts and #boat.deck_whitebelts > 0 and boat.hold_whitebelts and boat.hold_whitebelts[1] and #boat.hold_whitebelts[1] > 0 then

		local connections = {
			{1,1},
			{2,2},
			{3,3},
			{4,4},
			{5,5},
			{6,6},
			{7,7},
			{8,8},
			{17,17},
			{18,18},
			{19,19},
			{20,20},
			{21,21},
			{22,22},
			{23,23},
			{24,24},
		}

		for _, c in pairs(connections) do
			local b1 = boat.hold_whitebelts[1][c[1]]
			local b2 = boat.deck_whitebelts[c[2]]
			b1.connect_linked_belts(b2)
		end
	end
end


function Public.nth_hold_connect_linked_belts(nth) --assumes both are in standard lrtd order
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if boat.hold_whitebelts and boat.hold_whitebelts[nth-1] and #boat.hold_whitebelts[nth-1] > 0 and boat.hold_whitebelts[nth] and #boat.hold_whitebelts[nth] > 0 then

		local connections
		if nth % 2 == 0 then
			if nth == 2 then
				connections = {
					{5,13},
					{6,14},
					{7,15},
					{8,16},
				}
				for _, c in pairs(connections) do
					local b1 = boat.hold_whitebelts[nth][c[1]]
					local b2 = boat.hold_whitebelts[nth-1][c[2]]
					b1.connect_linked_belts(b2)
				end
			else
				connections = {
					{5,5},
					{6,6},
					{7,7},
					{8,8},
				}
				for _, c in pairs(connections) do
					local b1 = boat.hold_whitebelts[nth][c[1]]
					local b2 = boat.hold_whitebelts[nth-1][c[2]]
					b1.connect_linked_belts(b2)
				end
			end
			connections = {
				{1,9},
				{2,10},
				{3,11},
				{4,12},
			}
			for _, c in pairs(connections) do
				local b1 = boat.hold_whitebelts[nth][c[1]]
				local b2 = boat.hold_whitebelts[1][c[2]]
				b1.connect_linked_belts(b2)
			end
		else
			connections = {
				{1,1},
				{2,2},
				{3,3},
				{4,4},
			}
			for _, c in pairs(connections) do
				local b1 = boat.hold_whitebelts[nth][c[1]]
				local b2 = boat.hold_whitebelts[nth-1][c[2]]
				b1.connect_linked_belts(b2)
			end
			connections = {
				{5,9},
				{6,10},
				{7,11},
				{8,12},
			}
			for _, c in pairs(connections) do
				local b1 = boat.hold_whitebelts[nth][c[1]]
				local b2 = boat.hold_whitebelts[1][c[2]]
				b1.connect_linked_belts(b2)
			end
		end
	end
end


function Public.terrain(args)
	if args.p.x < Public.Data.width/2-5 and args.p.x > Public.Data.width/2-10 and args.p.y > Public.Data.height/2 - 2 then
		args.tiles[#args.tiles + 1] = {name = 'water', position = args.p}
	else
		args.tiles[#args.tiles + 1] = {name = CoreData.static_boat_floor, position = args.p}
	end
	return nil
end

function Public.chunk_structures()
	return nil
end

return Public