
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
local Structures = require 'maps.pirates.structures.structures'
local Boats = require 'maps.pirates.structures.boats.boats'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local inspect = require 'utils.inspect'.inspect


local Public = {}
Public.Data = require 'maps.pirates.surfaces.channel.data'

Public.info = {
	display_name = 'Channel'
}

function Public.terrain(args)

	if (args.p.y>30 or args.p.y<-20) and args.p.x>-80 and args.p.x<80 then
		args.tiles[#args.tiles + 1] = {name = 'sand-1', position = args.p}
	else
		args.tiles[#args.tiles + 1] = {name = 'deepwater', position = args.p}
	end

end

function Public.chunk_structures(args)
	return
end

return Public