
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local Math = require 'maps.pirates.math'

local Public = {}

Public.display_names = {'Isle of Buried Treasure'}

Public.terraingen_frame_width = 896
Public.terraingen_frame_height = 896
Public.static_params_default = {
	starting_time_of_day = 0,
	daynightcycletype = 1,
	default_decoratives = true,
	base_starting_treasure = 1000,
	base_starting_rock_material = 800,
	base_starting_wood = 1200,
	base_starting_treasure_maps = 6,
}

function Public.base_ores() 
	return {
		['copper-ore'] = 1.1,
		['iron-ore'] = 5.7,
		['coal'] = 4.4,
		['stone'] = 0.6,
	}
end

local rscale = 250
local hscale = 0.1
Public.noiseparams = {
	radius = {
		type = 'simplex_2d',
		normalised = false,
		params = {
			{wavelength = 0, amplitude = rscale * 1},
			{wavelength = 1.6, amplitude = rscale * 0.3},
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