
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local Math = require 'maps.pirates.math'

local Public = {}

Public.display_names = {'Sandworm Caldera'}

Public.discord_emoji = CoreData.comfy_emojis.mjau

Public.terraingen_frame_width = 700
Public.terraingen_frame_height = 700
Public.static_params_default = {
	starting_time_of_day = 0,
	daynightcycletype = 1,
	solar_power_multiplier = 1,
	default_decoratives = true,
	base_starting_treasure = 0,
	base_starting_rock_material = 8600,
	base_starting_wood = 600,
}

function Public.base_ores() --here, just for the gui:
	return {
		['copper-ore'] = 7,
		['iron-ore'] = 7,
		['stone'] = 9,
	}
end

local rscale = 180
local hscale = 0.16
Public.noiseparams = {
	radius = {
		type = 'simplex_2d',
		normalised = false,
		params = {
			{wavelength = 0, amplitude = rscale * 1},
		},
	},

	height_background = {
		type = 'island1',
		normalised = false,
		params = {
			-- {upperscale = 1000, amplitude = hscale * 200},
			{upperscale = 1600, amplitude = hscale * 1},
			{upperscale = 60, amplitude = hscale * 0.15},
		},
	},

	forest = {
		type = 'forest1',
		normalised = true,
		params = {
			{upperscale = 100, amplitude = 1},
		},
	},

	ore = {
		type = 'forest1',
		normalised = true,
		params = {
			{upperscale = 40, amplitude = 1, seedfactor = 2},
		},
	},

	rock = {
		type = 'forest1',
		normalised = true,
		params = {
			{upperscale = 120, amplitude = 1, seedfactor = 3},
		},
	},

	mood = {
		type = 'simplex_2d',
		normalised = true,
		params = {
			{wavelength = 200, amplitude = 70},
		},
	},
}




return Public