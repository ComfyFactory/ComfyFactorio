
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
local Structures = require 'maps.pirates.structures.structures'
local Boats = require 'maps.pirates.structures.boats.boats'
local Common = require 'maps.pirates.common'
local Hold = require 'maps.pirates.surfaces.hold'
local Cabin = require 'maps.pirates.surfaces.cabin'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local inspect = require 'utils.inspect'.inspect


local Public = {}

Public.Data = {}
Public.Data.display_names = {'Dock'}
Public.Data.discord_emoji = CoreData.comfy_emojis.smolfish
Public.Data.width = 296
Public.Data.height = 98
Public.Data.top_boat_bottom = -7
Public.Data.bottom_boat_top = 5
Public.Data.playerboat_starting_xcoord = 41

Public.Data.static_params_default = {
	starting_time_of_day = 0,
	daynightcycletype = 1,
	width = Public.Data.width,
	height = Public.Data.height,
}

Public.PurchaseableBoats = {
	[Boats.enum.SLOOP] = {
		type = Boats.enum.SLOOP,
		position = Utils.snap_coordinates_for_rails({x = 24 - Boats[Boats.enum.SLOOP].Data.leftmost_gate_position, y = Public.Data.bottom_boat_top + Boats[Boats.enum.SLOOP].Data.height/2}),
	},
	-- [Boats.enum.CUTTER] = {
	-- 	type = Boats.enum.CUTTER,
	-- 	position = Utils.snap_coordinates_for_rails({x = 24 - Boats[Boats.enum.CUTTER].Data.leftmost_gate_position, y = Public.Data.bottom_boat_top + Boats[Boats.enum.CUTTER].Data.height/2}),
	-- 	cannonscount = 4
	-- },
	-- [Boats.enum.CUTTER_WITH_HOLD] = {
	-- 	type = Boats.enum.CUTTER_WITH_HOLD,
	-- 	position = Utils.snap_coordinates_for_rails({x = 24 - Boats[Boats.enum.CUTTER_WITH_HOLD].Data.leftmost_gate_position, y = Public.Data.bottom_boat_top + Boats[Boats.enum.CUTTER_WITH_HOLD].Data.height/2}),
	-- 	cannonscount = 4
	-- },
	-- [Boats.enum.SLOOP_WITH_HOLD] = {
	-- 	type = Boats.enum.SLOOP_WITH_HOLD,
	-- 	position = Utils.snap_coordinates_for_rails({x = 24 - Boats[Boats.enum.SLOOP_WITH_HOLD].Data.leftmost_gate_position, y = Public.Data.bottom_boat_top + Boats[Boats.enum.SLOOP_WITH_HOLD].Data.height/2}),
	-- 	cannonscount = 2
	-- },
}

Public.Data.market_position = {x = -7.5, y = 13.5}
-- FIXME:
Public.Data.rightmostgate_stopping_xposition = 49 -- not sure if this is right for all boat types

Public.Data.iconized_map_width = 4
Public.Data.iconized_map_height = 20

function Public.execute_boat_purchase()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	memory.boat = destination.dynamic_data.boat_for_sale
	destination.dynamic_data.boat_for_sale = nil

	Hold.connect_up_linked_belts_to_deck()
	Cabin.connect_up_linked_belts_to_deck()

	memory.mainshop_availability_bools.new_boat_cutter_with_hold = false
	memory.mainshop_availability_bools.new_boat_sloop_with_hold = false
	memory.mainshop_availability_bools.new_boat_cutter = false
	
end


function Public.place_dock_jetty_and_boats()
	local memory = Memory.get_crew_memory()
	local boat = memory.boat
	local destination = Common.current_destination()
	if not (boat and boat.surface_name) then return end
	local surface = game.surfaces[boat.surface_name]

	local offset = Public.Data.jetty_offset

	local tiles = {}
	for _, p in pairs(Common.tile_positions_from_blueprint(Public.Data.jetty_bp, offset)) do
		tiles[#tiles + 1] = {name = CoreData.walkway_tile, position = p}
	end
		
	surface.set_tiles(tiles, true)

	local boat_for_sale_type = destination.static_params.boat_for_sale_type
	if boat_for_sale_type then
		local boat2 = Utils.deepcopy(Public.PurchaseableBoats[boat_for_sale_type])

		-- not needed whilst we're not buying boats:
		-- boat2.dockedposition = boat2.position
		-- boat2.state = Boats.enum_state.DOCKED
		-- boat2.speed = 0
		-- boat2.decksteeringchests = {}
		-- boat2.questrewardchest = nil
		-- boat2.hold_input_belts = boat.hold_input_belts
		-- boat2.hold_output_belts = boat.hold_output_belts

		-- boat2.crowsneststeeringchests = boat.crowsneststeeringchests
		-- boat2.cannons = {}
		-- boat2.speedticker1 = 0
		-- boat2.speedticker2 = 1/3 * Common.boat_steps_at_a_time
		-- boat2.speedticker3 = 2/3 * Common.boat_steps_at_a_time

		boat2.force_name = boat.force_name
		boat2.surface_name = boat.surface_name
		Boats.place_boat(boat2, CoreData.static_boat_floor, true, true)

		Boats.place_random_obstacle_boxes(boat2, 10, {}, 2)

		destination.dynamic_data.boat_for_sale = boat2
	end
	


	-- for y = -3.5, 3.5 do
	-- 	local e = surface.create_entity{name = 'stone-wall', position = {x = -68.5, y = y}, force = 'environment'}
		-- e.destructible = false
		-- e.minable = false
		-- e.rotatable = false
		-- e.operable = false
	-- end
end

function Public.terrain(args)

	local x, y = args.p.x, args.p.y

	args.tiles[#args.tiles + 1] = {name = 'water', position = args.p}
	local fishrng = Math.random(200)
	if fishrng == 1 then
		args.entities[#args.entities + 1] = {name = 'fish', position = args.p}
	end
end

function Public.chunk_structures(args)
	return nil
end

Public.Data.jetty_offset = {x = -40, y = -6}

Public.Data.jetty_bp = [[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]]

return Public