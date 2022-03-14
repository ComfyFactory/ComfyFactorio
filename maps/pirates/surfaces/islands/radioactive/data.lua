
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local Math = require 'maps.pirates.math'

local Public = {}

Public.display_names = {'Abandoned Labs'}

Public.terraingen_frame_width = 700
Public.terraingen_frame_height = 700
Public.static_params_default = {
	starting_time_of_day = 0.45,
	brightness_visual_weights = {0.8, 0.8, 0.8},
	daynightcycletype = 4,
	min_brightness = 0,
	base_starting_treasure = 1000,
	base_starting_rock_material = 1200,
	base_starting_wood = 800,
	base_starting_treasure_maps = 1,
	default_decoratives = false,
}

function Public.base_ores() --here, just for the gui:
	return {
		['copper-ore'] = 1,
		['coal'] = 1,
		['uranium-ore'] = 7,
		['stone'] = 5,
	}
end

local rscale = 200
local hscale = 0.12
Public.noiseparams = {
	radius = {
		type = 'simplex_2d',
		normalised = false,
		params = {
			{wavelength = 0, amplitude = rscale * 1},
			{wavelength = 2.5, amplitude = rscale * 0.12},
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
			{upperscale = 180, amplitude = 1},
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

	ore = {
		type = 'forest1',
		normalised = true,
		params = {
			{upperscale = 40, amplitude = 1, seedfactor = 3},
		},
	},
}



return Public