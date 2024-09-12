-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


-- local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'

local Public = {}

Public.display_names = {{'pirates.location_displayname_swamp_1'}}

Public.terraingen_frame_width = 480
Public.terraingen_frame_height = 480
Public.static_params_default = {
	starting_time_of_day = 0.26,
	daynightcycletype = 1,
	brightness_visual_weights = {0, 0, 0},
	default_decoratives = true,
	base_starting_treasure = 1000,
	base_starting_rock_material = 800,
	base_starting_wood = 1200,
	base_starting_treasure_maps = 0,
}

function Public.base_ores()
	return {
		['copper-ore'] = 2.9,
		['iron-ore'] = 3.6,
		['coal'] = 5.2,
		['stone'] = 0.5,
		['crude-oil'] = 80,
	}
end

local rscale = 185
Public.noiseparams = {
	radius = {
		type = 'simplex_2d',
		normalised = false,
		params = {
			{wavelength = 0, amplitude = rscale * 1},
			{wavelength = 2, amplitude = rscale * 0.2},
		},
	},

	height_background = {
		type = 'island1',
		normalised = false,
		params = {
			-- {upperscale = 1000, amplitude = hscale * 200},
			{upperscale = 600, amplitude = 0.1},
		},
	},

	forest = {
		type = 'forest1',
		normalised = true,
		params = {
			{upperscale = 70, amplitude = 1},
		},
	},

	rock = {
		type = 'forest1',
		normalised = true,
		params = {
			{upperscale = 120, amplitude = 1, seedfactor = 2},
		},
	},

	mood = {
		type = 'simplex_2d',
		normalised = true,
		params = {
			{wavelength = 250, amplitude = 70},
			{wavelength = 50, amplitude = 20},
		},
	},

	terrain = {
		type = 'simplex_2d',
		normalised = true,
		params = {
			{wavelength = 48, amplitude = 1},
		},
	},
}



return Public