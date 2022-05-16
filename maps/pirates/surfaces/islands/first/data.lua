
-- local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'

local Public = {}

Public.display_names = {'Fledgling Vale'}

Public.terraingen_frame_width = 325
Public.terraingen_frame_height = 325
Public.static_params_default = {
	starting_time_of_day = 0,
	daynightcycletype = 1,
	boat_extra_distance_from_shore = 0,
	-- boat_extra_distance_from_shore = 0.1 * Common.boat_default_starting_distance_from_shore,
	default_decoratives = true,
	base_starting_treasure = 2000,
	base_starting_rock_material = 800,
	base_starting_wood = 2400,
}

function Public.base_ores()
	return {
		['copper-ore'] = 1.9,
		['iron-ore'] = 4.2,
		['coal'] = 3.1,
		['stone'] = 0.4,
	}
end

local rscale = 125
Public.noiseparams = {
	radius = {
		type = 'simplex_2d',
		normalised = false,
		params = {
			{wavelength = 0, amplitude = rscale * 1},
			-- {wavelength = 2.5, amplitude = rscale * 0.1},
		},
	},

	height_background = {
		type = 'island1',
		normalised = false,
		params = {
			-- {upperscale = 1000, amplitude = hscale * 200},
			{upperscale = 600, amplitude = 0.15},
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
}



return Public