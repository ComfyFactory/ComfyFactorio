-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
-- local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
-- local CoreData = require 'maps.pirates.coredata'
-- local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect
-- local Token = require 'utils.token'
-- local Task = require 'utils.task'
-- local Kraken = require 'maps.pirates.surfaces.sea.kraken'
local SurfacesCommon = require 'maps.pirates.surfaces.common'

local Public = {}
local enum = {
	DEFAULT = 'Default',
}
Public.enum = enum

Public.Data = {}
Public.Data.width = 384
Public.Data.height = 384

function Public.ensure_sea_surface()
	local memory = Memory.get_crew_memory()

	local seaname = SurfacesCommon.encode_surface_name(memory.id, 0, SurfacesCommon.enum.SEA, enum.DEFAULT)

	if not game.surfaces[seaname] then
		local width = Public.Data.width
		local height = Public.Data.height
		local map_gen_settings = Common.default_map_gen_settings(width, height)

		map_gen_settings.autoplace_settings.decorative.treat_missing_as_default = false

		local surface = game.create_surface(seaname, map_gen_settings)
		surface.freeze_daytime = true
		surface.daytime = 0
		surface.show_clouds = false

		memory.sea_name = seaname
	end
end

function Public.terrain(args)
	args.tiles[#args.tiles + 1] = {name = 'deepwater', position = args.p}
	if Math.random(110) == 1 then
		args.entities[#args.entities + 1] = {name = 'fish', position = args.p}
	end
	return nil
end

function Public.chunk_structures()
	return nil
end


return Public

