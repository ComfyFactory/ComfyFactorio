-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio.

local Public = {}

Public.display_names = {{'pirates.location_displayname_cave_1'}}

Public.terraingen_frame_width = 640
Public.terraingen_frame_height = 640
Public.static_params_default = {
	default_decoratives = true,
	base_starting_treasure = 1000,
	base_starting_rock_material = 800,
	base_starting_wood = 1200,
	base_starting_treasure_maps = 0,
	starting_time_of_day = 0.43,
	daynightcycletype = 1,
	brightness_visual_weights = {0.92, 0.92, 0.92},
	min_brightness = 0.08,
}


-- Here we set values somewhat higher, because getting all resources requires work and bit of luck (island needs enough rock)
function Public.base_ores()
	return {
		['copper-ore'] = 3.3,
		['iron-ore'] = 7.7,
		['coal'] = 5.5,
		['stone'] = 3.3,
		['uranium-ore'] = 0.6,
	}
end

function Public.spawn_fish(args)
	if math.random(1, 32) == 1 then
		args.entities[#args.entities + 1] = {name = 'fish', position = args.p}
	end
end

return Public