
-- local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'

local Public = {}

Public.display_names = {{'pirates.location_displayname_walkways_1'}}

Public.terraingen_frame_width = 896
Public.terraingen_frame_height = 896
Public.static_params_default = {
	starting_time_of_day = 0,
	daynightcycletype = 4,
	min_brightness = 0.05,
	brightness_visual_weights = {1, 1, 1}, --almost pitch black
	default_decoratives = false,
	base_starting_rock_material = 800,
}

function Public.base_ores()
	return {
		['copper-ore'] = 2.6,
		['iron-ore'] = 2.8,
		['coal'] = 4,
		['crude-oil'] = 120,
	}
end

local rscale = 135
local hscale = 1/100
Public.noiseparams = {
	radius = {
		type = 'simplex_2d',
		normalised = false,
		params = {
			{wavelength = 0, amplitude = rscale * 1.0},
			{wavelength = 2.5, amplitude = rscale * 0.23},
		},
	},

	height_background = {
		type = 'simplex_2d',
		normalised = false,
		params = {
			-- shape:
			{wavelength = 1600, amplitude = hscale * 22},
			{wavelength = 800, amplitude = hscale * 18},
			{wavelength = 400, amplitude = hscale * 15},
			{wavelength = 300, amplitude = hscale * 11},
			{wavelength = 200, amplitude = hscale * 8},
			{wavelength = 140, amplitude = hscale * 6},
			{wavelength = 100, amplitude = hscale * 4},
			-- edges:
			{wavelength = 60, amplitude = hscale * 2.5},
			{wavelength = 30, amplitude = hscale * 1.5},
			{wavelength = 9, amplitude = hscale * 0.5}
		},
	},

	walkways = {
		type = 'simplex_2d',
		normalised = false,
		params = {
			{wavelength = 300, amplitude = 15/100},
			{wavelength = 65, amplitude = 90/100},
			{wavelength = 7, amplitude = 5/100},
		},
	},

	rock = {
		type = 'simplex_2d',
		normalised = true,
		params = {
			{wavelength = 100, amplitude = 80},
			{wavelength = 50, amplitude = 20},
			{wavelength = 6, amplitude = 20},
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