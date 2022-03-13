
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
local CustomEvents = require 'maps.pirates.custom_events'


local Public = {}

Public.Data = {}
Public.Data.display_names = {'Dock'}
Public.Data.discord_emoji = CoreData.comfy_emojis.smolfish
Public.Data.width = 296
Public.Data.height = 98

Public.Data.static_boat_bottom = 34
Public.Data.player_boat_top = -29
Public.Data.playerboat_starting_xcoord = 10
Public.Data.markets_position = {x = 6.5, y = -46.5}
Public.Data.rightmostgate_stopping_xposition = 16

Public.Data.static_params_default = {
	starting_time_of_day = 0,
	daynightcycletype = 1,
	width = Public.Data.width,
	height = Public.Data.height,
}

Public.PurchaseableBoats = {
	[Boats.enum.SLOOP] = {
		type = Boats.enum.SLOOP,
		position = Utils.snap_coordinates_for_rails({x = -23 - Boats[Boats.enum.SLOOP].Data.leftmost_gate_position, y = Public.Data.static_boat_bottom - Boats[Boats.enum.SLOOP].Data.height/2}),
	},
	-- [Boats.enum.CUTTER] = {
	-- 	type = Boats.enum.CUTTER,
	-- 	position = Utils.snap_coordinates_for_rails({x = 24 - Boats[Boats.enum.CUTTER].Data.leftmost_gate_position, y = Public.Data.static_boat_bottom + Boats[Boats.enum.CUTTER].Data.height/2}),
	-- 	cannonscount = 4
	-- },
	-- [Boats.enum.CUTTER_WITH_HOLD] = {
	-- 	type = Boats.enum.CUTTER_WITH_HOLD,
	-- 	position = Utils.snap_coordinates_for_rails({x = 24 - Boats[Boats.enum.CUTTER_WITH_HOLD].Data.leftmost_gate_position, y = Public.Data.static_boat_bottom + Boats[Boats.enum.CUTTER_WITH_HOLD].Data.height/2}),
	-- 	cannonscount = 4
	-- },
	-- [Boats.enum.SLOOP_WITH_HOLD] = {
	-- 	type = Boats.enum.SLOOP_WITH_HOLD,
	-- 	position = Utils.snap_coordinates_for_rails({x = 24 - Boats[Boats.enum.SLOOP_WITH_HOLD].Data.leftmost_gate_position, y = Public.Data.static_boat_bottom + Boats[Boats.enum.SLOOP_WITH_HOLD].Data.height/2}),
	-- 	cannonscount = 2
	-- },
}


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

	script.raise_event(CustomEvents.enum['update_crew_fuel_gui'], {})
end


function Public.place_dock_jetty_and_boats()
	local memory = Memory.get_crew_memory()
	local boat = memory.boat
	local destination = Common.current_destination()
	if not (boat and boat.surface_name) then return end
	local surface = game.surfaces[boat.surface_name]

	local tiles = {}

	Common.add_tiles_from_blueprint(tiles, Public.Data.ground_bp_1, 'grass-4', Public.Data.ground_bp_1_offset)
	Common.add_tiles_from_blueprint(tiles, Public.Data.jetty_bp, CoreData.walkway_tile, Public.Data.jetty_offset)
	Common.add_tiles_from_blueprint(tiles, Public.Data.stone_bp_1, 'stone-path', Public.Data.stone_bp_1_offset)
		
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

		-- Boats.deck_place_random_obstacle_boxes(boat2, 6, {}, 2)

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

Public.Data.jetty_offset = {x = -20, y = -38}
Public.Data.jetty_bp = [[0eNqVmcFO4zAYhN/F5yBl5ncSJ6+y4lAgQpFKWrUBgVDenZZw4LC76nesNHVGHs/nxP5MD/vX8Xia5iUNn+k87453y+Hu+TQ9XX+/pyFylT7SkNu1StPjYT6n4c9FOD3Pu/1VsnwcxzSkaRlfUpXm3cv110X3eBqXMV3/ND+Nl3G03ldpmfbjNsDxcJ6W6TD/PKXeHhLr34b4lzojdXObWsiJkBMhJ0ZOjJwYOQnkJJCTQE4ycpKRk4ycNMhJg5w0yEmLnLTISYucdMhJh5x0yElBTgpyUpCTHjnpkZOekY1BVoyygpiFnIWgZaQVQ60Ya8VgK0ZbMdyK8VYMuGLEFUOuGHPFoCtGXTHsinFXDLxi5BVDrxh7xeArRl8x/IrxVwzAYgQ2I7AZgc0IbEZgMwIbvuvCl134tssIbEZgMwKbEdiMwGYENiOwGYHNCGxGYDMCmxHYjMDeGNkidYfUBakDynskzzWTB5NnJr81o4IyKiijgjIqLKPCMiosI7Zfm+3XZvu1tx21RmohtZE6kDojNZuTFqk7pC5sTqC8Z3PIws8s/czizzB/tgBuPoCrSSt+1EJqI3UgdUZqNictUndIXdicQHnP5pCFn1n6mcWfYf5sAdzcCqFWCLVCqBVCrRBqhVArhFoh1AqhVoi1QqwVYq0Qa4VYK9indLBP6WCf0mG0AoxWgNEKMFsBZivAbAWwE4ZgJwwBL9QCZRQoo0AZBcsoWEbBMoIXjfCm8X8HL/fVdoU9/LoQr9LbeDp/D+Ci3PXuGjWKtl7XLyUP5fs=]]

Public.Data.stone_bp_1_offset = {x = -5, y = -49}
Public.Data.stone_bp_1 = [[0eNqd2cFq4zAURuF30dqB/FeWZPtVShdpKjqiqW1st7QUv/skbRZDoYNPloEb2ToEog99uofTax6n0i+u+3Rzfxh3y7B7msrj5fO768xX7sN1aa1cOQ797Lq781x56g+ny8TyMWbXubLkF1e5/vBy+TQvQ593D1M5PrvL9/rHfF5J633llnLK32uMw1yWMvTX5+y/HrNffywyHpY/5zV+GRcbNzbut46LvbvYu4u9u25593rruLGtGtuqsa0a26rdstWwddyzMp6V8ayMZ2U8K+NvKRO3jtcsZM1C1ixkzULWLGTNQtYsZGAhAwsZWMjAQoafIc//PccpL/n34cDW3pwxsoyRZYwsY2QZI/s9RhYyspCJhUwsZGIhEwuZWMjEQiYWsmEhGxayYSEbFrJhIRsWsmEhWxayZSFbFrJlIVsWsmUhWxZS8PgueH4XPMCLnuD3rOZ1PsD57T0pKagpKCqoKiArrvMBzm/vCd0iCBdBuQjSRdAugni5zm/vCbUjyB1B7wiCR1A8guQRNI8gegTVI8geQfcIwkdQPoL0EbSPIH4E9SPIHwXYExJI0ECCCBJUkCCDBB0kCCFBCQlSSNBCghgS1JAghwQ9JAgiQREJkkjQRIIoElSRIIsEXSQII0EZCdJI0EaCOBLUkSCPBH1k0EcGfWTQRwZ9ZNBHBn1k0DsGvWPQOwa9Y/Qahd6j0IsUepPyX4/cV98XfN0/t4WVe8vT/LWCNapTaykoyMf9uv4FIKIUeQ==]]


Public.Data.ground_bp_1_offset = {x = -122, y = -49}
Public.Data.ground_bp_1 = [[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WNca6xljXGOsaY11j7GqMXY2xqzF2NcauxtjVGLsaY1dj7GqMXR1jUcdY1DEWdYxFHWNRx1jUMRZ1jEUdY1HHYNExWHQMFh2DRcdg0TFYdAwWHYNFx2DRMfpzjP4coz/H6M8x+nOM/hyjP8fozzH6cwznHMM5x3DOMZxzDOccwznHcM4xnHMMuBwDLseAyzHgcgy4HAMux4DLMeByDIkcQyLHkMgxJHIMiRxDIseQyDEkcgxaHIMWx6DFMWhxDFocgxbHoMUxTnCMExzjBMc4wTFOcIwTHOMEx57mx57mx57mx57mx57mx57mx57mx17Dx17Dx17Dx17Dx17Dx17Dx17D1x6g1x6g1x6g1x6g1x6g1x6g1x6g156I156I156I156I156I156I156I1x5x1x5x1x5x1x5x1x5x1x5x1x5x155Z155Z155Z155Z155Z155Z1x5C1x5C1x5C1x5C1x5C1x5C154q154q154q154q154q154q1x4T1x4T1x4T1x4T1x4T1x4T114H114H114H114H114H1+7v1+7v1+7v1+7v1+7v127Y127Y127Yl27Y8Ykute/xZeNh448/+7LPvuyzL/vsYR8m7MOEfZi0D5P2Ycp+9bbx/+enxx+/+fjy9fPff/3P/vzdPz7/+NOX779+fPPxn59/+vnfv0CcVXNjevXK/emXX/4bcpQOIA==]]

return Public