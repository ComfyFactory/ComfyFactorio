-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


-- local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'

local Public = {}

Public.display_names = { { 'pirates.location_displayname_maze_1' } }

Public.terraingen_frame_width = 896
Public.terraingen_frame_height = 896
Public.static_params_default = {
	starting_time_of_day = 0,
	daynightcycletype = 1,
	default_decoratives = true,
	base_starting_treasure = 1000,
	base_starting_rock_material = 800,
	base_starting_wood = 1200,
	base_starting_treasure_maps = 3,
}

function Public.base_ores()
	return {
		['copper-ore'] = 3.5,
		['iron-ore'] = 6.5,
		['coal'] = 4,
		['stone'] = 2.0,
		['crude-oil'] = 30,
	}
end

local rscale = 240
-- local hscale = 0.1
Public.noiseparams = {
	radius = {
		type = 'simplex_2d',
		normalised = false,
		params = {
			{ wavelength = 0,   amplitude = rscale * 1 },
			{ wavelength = 1.6, amplitude = rscale * 0.15 },
		},
	},

	maze = {
		type = 'simplex_2d',
		normalised = true,
		params = {
			{ wavelength = 250, amplitude = 70 },
			{ wavelength = 50,  amplitude = 20 },
		},
	},
}




return Public
