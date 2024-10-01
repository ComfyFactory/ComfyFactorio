-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

-- local Common = require 'maps.pirates.common'
local CoreData = require('maps.pirates.coredata')
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'

local Public = {}

Public.display_names = { { 'pirates.location_displayname_red_desert_1' } }

Public.discord_emoji = CoreData.comfy_emojis.hype

Public.terraingen_frame_width = 700
Public.terraingen_frame_height = 700
Public.static_params_default = {
	starting_time_of_day = 0,
	daynightcycletype = 1,
	decorative_settings = prototypes.space_location.nauvis.map_gen_settings.autoplace_settings.decorative.settings,
	base_starting_treasure = 0,
	base_starting_rock_material = 8600,
	base_starting_wood = 600,
}

function Public.base_ores() --here, just for the visualisation:
	return {
		['copper-ore'] = 5,
		['iron-ore'] = 5,
		['coal'] = 3,
	}
end

local rscale = 175
local hscale = 0.16
Public.noiseparams = {
	radius = {
		type = 'simplex_2d',
		normalised = false,
		params = {
			{ wavelength = 0, amplitude = rscale * 1 },
		},
	},

	height_background = {
		type = 'island1',
		normalised = false,
		params = {
			-- {upperscale = 1000, amplitude = hscale * 200},
			{ upperscale = 1600, amplitude = hscale * 1 },
			{ upperscale = 60, amplitude = hscale * 0.15 },
		},
	},

	forest = {
		type = 'forest1',
		normalised = true,
		params = {
			{ upperscale = 100, amplitude = 1 },
		},
	},

	ore = {
		type = 'forest1',
		normalised = true,
		params = {
			{ upperscale = 40, amplitude = 1, seedfactor = 2 },
		},
	},

	rock = {
		type = 'forest1',
		normalised = true,
		params = {
			{ upperscale = 120, amplitude = 1, seedfactor = 3 },
		},
	},

	mood = {
		type = 'simplex_2d',
		normalised = true,
		params = {
			{ wavelength = 200, amplitude = 70 },
		},
	},
}

return Public
