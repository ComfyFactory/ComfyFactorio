
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
		position = Utils.snap_coordinates_for_rails({x = 24 - Boats[Boats.enum.SLOOP].Data.leftmost_gate_position, y = Public.Data.top_boat_bottom - Boats[Boats.enum.SLOOP].Data.height/2}),
	},
	-- [Boats.enum.CUTTER] = {
	-- 	type = Boats.enum.CUTTER,
	-- 	position = Utils.snap_coordinates_for_rails({x = 24 - Boats[Boats.enum.CUTTER].Data.leftmost_gate_position, y = Public.Data.top_boat_bottom + Boats[Boats.enum.CUTTER].Data.height/2}),
	-- 	cannonscount = 4
	-- },
	-- [Boats.enum.CUTTER_WITH_HOLD] = {
	-- 	type = Boats.enum.CUTTER_WITH_HOLD,
	-- 	position = Utils.snap_coordinates_for_rails({x = 24 - Boats[Boats.enum.CUTTER_WITH_HOLD].Data.leftmost_gate_position, y = Public.Data.top_boat_bottom + Boats[Boats.enum.CUTTER_WITH_HOLD].Data.height/2}),
	-- 	cannonscount = 4
	-- },
	-- [Boats.enum.SLOOP_WITH_HOLD] = {
	-- 	type = Boats.enum.SLOOP_WITH_HOLD,
	-- 	position = Utils.snap_coordinates_for_rails({x = 24 - Boats[Boats.enum.SLOOP_WITH_HOLD].Data.leftmost_gate_position, y = Public.Data.top_boat_bottom + Boats[Boats.enum.SLOOP_WITH_HOLD].Data.height/2}),
	-- 	cannonscount = 2
	-- },
}

Public.Data.market_position = {x = -6.5, y = -13.5}
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

Public.Data.jetty_offset = {x = -39, y = -49}

Public.Data.jetty_bp = [[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]]

return Public