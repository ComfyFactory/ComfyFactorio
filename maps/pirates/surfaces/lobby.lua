
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
local Boats = require 'maps.pirates.structures.boats.boats'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local inspect = require 'utils.inspect'.inspect


local Public = {}

Public.StartingBoats = {
	{
		type = Boats.enum.SLOOP,
		position = {x = Boats[Boats.enum.SLOOP].Data.width - 65, y = -1 - (23 + Boats[Boats.enum.SLOOP].Data.height/2)},
		surface_name = CoreData.lobby_surface_name,
		force_name = 'crew-001',
	},
	{
		type = Boats.enum.SLOOP,
		position = {x = Boats[Boats.enum.SLOOP].Data.width - 65, y = -1},
		surface_name = CoreData.lobby_surface_name,
		force_name = 'crew-002',
	},
	{
		type = Boats.enum.SLOOP,
		position = {x = Boats[Boats.enum.SLOOP].Data.width - 65, y = -1 + (23 + Boats[Boats.enum.SLOOP].Data.height/2)},
		surface_name = CoreData.lobby_surface_name,
		force_name = 'crew-003',
	},
	-- {
	-- 	type = Boats.enum.CUTTER,
	-- 	position = {x = Boats[Boats.enum.CUTTER].Data.width - 56, y = (70.5 + Boats[Boats.enum.CUTTER].Data.height/2)},
	-- 	surface_name = CoreData.lobby_surface_name,
	-- 	force_name = 'environment',
	-- 	speedticker1 = 0,
	-- 	speedticker2 = 1/3 * Common.boat_steps_at_a_time,
	-- 	speedticker3 = 2/3 * Common.boat_steps_at_a_time,
	-- },
}


Public.Data = {}
Public.Data.display_name = 'Starting Dock'
Public.Data.width = 224
Public.Data.height = 128
-- Public.Data.noiseparams = {
-- 	land = {
-- 		type = 'simplex_2d',
-- 		normalised = false,
-- 		params = {
-- 			{wavelength = 128, amplitude = 10/100},
-- 			{wavelength = 64, amplitude = 10/100},
-- 			{wavelength = 32, amplitude = 5/100},
-- 			{wavelength = 12, amplitude = 5/100},
-- 		},
-- 	}
-- }

Public.Data.iconized_map_width = 4
Public.Data.iconized_map_height = 20



function Public.terrain(args)

	local x, y = args.p.x, args.p.y
	
	if Math.distance(args.p, {x = -316, y = 0}) < 230 then
		args.tiles[#args.tiles + 1] = {name = 'dirt-3', position = args.p}
	elseif Math.distance(args.p, {x = -264, y = 0}) < 180 then
			args.tiles[#args.tiles + 1] = {name = 'water-shallow', position = args.p}
	elseif Math.abs(Common.lobby_spawnpoint.x - x) < 3 and Math.abs(Common.lobby_spawnpoint.y - y) < 3 then
		args.tiles[#args.tiles + 1] = {name = CoreData.walkway_tile, position = args.p}
	else
		args.tiles[#args.tiles + 1] = {name = 'water', position = args.p}
	end
end

function Public.chunk_structures(args)
	return nil
end

function Public.create_starting_dock_surface()
	local memory = Memory.get_crew_memory()

	local starting_dock_name = CoreData.lobby_surface_name

	local width = Public.Data.width
	local height = Public.Data.height
	local map_gen_settings = Common.default_map_gen_settings(width, height)

	local surface = game.create_surface(starting_dock_name, map_gen_settings)
	surface.freeze_daytime = true
	surface.daytime = 0
end

function Public.place_starting_dock_showboat(id)
	local global_memory = Memory.get_global_memory()

	Memory.set_working_id(id)
	
	local boat = Utils.deepcopy(Public.StartingBoats[id])

	global_memory.lobby_boats[id] = boat

	Boats.place_boat(boat, CoreData.static_boat_floor, true, true, false, true)
end

function Public.place_lobby_jetty_and_boats()

	local surface = game.surfaces[CoreData.lobby_surface_name]

	for id, _ in pairs(Public.StartingBoats) do
		Public.place_starting_dock_showboat(id)
	end

	local offset = {x = -85, y = -23}

	local tiles = {}
	for _, p in pairs(Common.tile_positions_from_blueprint(Public.Data.jetty_bp, offset)) do
		tiles[#tiles + 1] = {name = CoreData.walkway_tile, position = p, force = 'environment'}
	end
		
	surface.set_tiles(tiles, true)

	-- for y = -3.5, 3.5 do
	-- 	local e = surface.create_entity{name = 'stone-wall', position = {x = -68.5, y = y}, force = 'environment'}
	-- 	e.destructible = false
	-- 	e.minable = false
	-- 	e.rotatable = false
	-- 	e.operable = false
	-- end
end

Public.Data.jetty_bp = [[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TC21ioU0stImFNrHQJhaaxEKTWGgSC01ioUksNImFJrHQJBaaxEKbWGgTC21ioU0stImFNrHQJhbaxEKbWGgSC01ioUksNImFJrHQJBaaxEKTWGgSC21ioU0stImFNrHQJhbaxEKbWGgTC21ioUksNImFJrHQJBaaxEKTWGgSC01ioUkstImFNrHQJhbaxEKbWGgTC21ioU0stImFJrHQJBaaxEKTWGgSC01ioUksNImFJrHQJhbaxEKbWGgTC21ioU0stImFNrHQJhaaxEKTWGgSC01ioUksNImFJrHQJBaaxEKbWGgTC21ioU0stImFNrHQJhbaxEKbWGgSC01ioUksNImFJrHQJBaaxEKTWGgSC21ioU0stImFNrHQJhbaxEKbWGgTC21ioUksNImFJrHQJBaaxEKTWGgSC01ioUkstImFNrHQJhbaxEKbWGgTC21ioU0stImFJrHQJBaaxEKTWGgSC01ioUksNImFJrHQJhbaxEKbWGgTC21ioU0stImFNrHQJhaaxEKTWGgSC01ioUksNImFJrHQJBaaxEKbWGgTC21ioU0stImFNrHQJhbaxEKbWBgSC0NiYUgsDImFIbEwJBaGxMKQWBgSC2NiYUwsjImFMbEwJhbGxMKYWBgTC2NiYUgsDImFIbEwJBaGxMKQWBgSC0NiYUgsjImFMbEwJhbGxMKYWBgTC2NiYUwsjImFIbEwJBaGxMKQWBgSC0NiYUgsDImFIbEwJhbGxMKYWBgTC2NiYUwsjImFMbEwJhaGxMKQWBgSC0NiYUgsDImFIbEwJBaGxMKYWBgTC2NiYUwsjImFMbEwJhbGxMKYWBgSC0NiYUgsDImFIbEwJBaGxMKQWBgSC2NiYUwsjImFMbEwJhbGxMKYWBgTC2NiYUgsDImFIbEwJBaGxMKQWBgSC0NiYUgsjImFMbEwJhbGxMKYWBgTC2NiYUwsjImFIbEwJBaGxMKQWBgSC0NiYUgsDImFIbEwJhbGxMKYWBgTC2NiYUwsjImFMbEwJhaGxMKQWBgSC0NiYUgsDImFIbEwJBaGxMKYWBgTC2NiYUwsjImFMbEwJhbGxMKYWBgSC0NiYUgsDImFIbEwJBaGxMKQWBgSC2NiYUwsjImFMbEwJhbGxMKYWBgTC2NiYUgsDImFIbEwJBaGxMKQWBgSC0NiYUgsjImFMbEwJhbGxMKYWBgTC2NiYUwsjImFJbGwJBaWxMKSWFgSC0tiYUksLImFJbGwJhbWxMKaWFgTC2tiYU0srImFNbGwJhaWxMKSWFgSC0tiYUksLImFJbGwJBaWxMKaWFgTC2tiYU0srImFNbGwJhbWxMKaWFgSC0tiYUksLImFJbGwJBaWxMKSWFgSC2tiYU0srImFNbGwJhbWxMKaWFgTC2tiYUksLImFJbGwJBaWxMKSWFgSC0tiYUksrImFNbGwJhbWxMKaWFgTC2tiYU0srImFJbGwJBaWxMKSWFgSC0tiYUksLImFJbGwJhbWxMKaWFgTC2tiYU0srImFNbGwJhaWxMKSWFgSC0tiYUksLImFJbGwJBaWxMKaWFgTC2tiYU0srImFNbGwJhbWxMKaWFgSC0tiYUksLImFJbGwJBaWxMKSWFgSC2tiYU0srImFNbGwJhbWxMKaWFgTC2tiYUksLImFJbGwJBaWxMKSWFgSC0tiYUksrImFNbGwJhbWxMKaWFgTC2tiYU0srImFJbGwJBaWxMKSWFgSC0tiYUksLImFJbGwJhbWxMKaWFgTC2tiYU0srImFNbGwJhaWxMKSWFgSC0tiYUksLImFJbGwJBaWxMKaWFgTC2tiYU0srImFNbGwJhbWxMKaWDgSC0di4UgsHImFI7FwJBaOxMKRWDgSC2di4UwsnImFM7FwJhbOxMKZWDgTC2di4UgsHImFI7FwJBaOxMKRWDgSC0di4UgsnImFM7FwJhbOxMKZWDgTC2di4UwsnImFI7FwJBaOxMKRWDgSC0di4UgsHImFI7FwJhbOxMKZWDgTC2di4UwsnImFM7FwJhaOxMKRWDgSC0di4UgsHImFI7FwJBaOxMKZWDgTC2di4UwsnImFM7FwJhbOxMKZWDgSC0di4UgsHImFI7FwJBaOxMKRWDgSC2di4UwsnImFM7FwJhbOxMKZWDgTC2di4UgsHImFI7FwJBaOxMKRWDgSC0di4UgsnImFM7FwJhbOxMKZWDgTC2di4Uws3P8nFv787uXty+vPv/3eX376x+unz28fv7y8e/nP18+//vED8n30PXmdVe9nv379b+px6g8=]]



return Public