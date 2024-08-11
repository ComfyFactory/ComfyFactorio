-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio.


-- local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'

local Public = {}

Public.display_names = {{'pirates.location_displayname_horseshoe_1'}, {'pirates.location_displayname_horseshoe_2'}, {'pirates.location_displayname_horseshoe_3'}}

Public.terraingen_frame_width = 896
Public.terraingen_frame_height = 896
Public.static_params_default = {
	starting_time_of_day = 0,
	daynightcycletype = 1,
	default_decoratives = true,
	base_starting_treasure = 1000,
	base_starting_rock_material = 800,
	base_starting_wood = 1200,
	base_starting_treasure_maps = 0,
}

function Public.base_ores()
	return {
		['copper-ore'] = 1.6,
		['iron-ore'] = 4.7,
		['coal'] = 2.8,
		['stone'] = 0.8,
	}
end

local rscale1 = 240
local rscale2 = 210
local hscale = 0.1
Public.noiseparams = {
	radius1 = {
		type = 'simplex_2d',
		normalised = false,
		params = {
			{wavelength = 0, amplitude = rscale1 * 1},
			{wavelength = 1.6, amplitude = rscale1 * 0.2},
		},
	},
	radius2 = {
		type = 'simplex_2d',
		normalised = false,
		params = {
			{wavelength = 0, amplitude = rscale2 * 1},
			{wavelength = 1.6, amplitude = rscale2 * 0.2},
		},
	},

	height_background = {
		type = 'island1',
		normalised = false,
		params = {
			-- {upperscale = 1000, amplitude = hscale * 200},
			{upperscale = 1600, amplitude = hscale * 1},
			{upperscale = 80, amplitude = hscale * 0.1},
		},
	},

	forest = {
		type = 'forest1',
		normalised = true,
		params = {
			{upperscale = 90, amplitude = 1},
			-- {upperscale = 0, amplitude = 0.15},
		},
	},

	rock = {
		type = 'forest1',
		normalised = true,
		params = {
			{upperscale = 110, amplitude = 1, seedfactor = 2},
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
}




return Public