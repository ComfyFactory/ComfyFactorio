local Public = {}

local get_noise = require "utils.get_noise"
local math_abs = math.abs

function Public.set_daytime(surface, tick)
	local seed = surface.map_gen_settings.seed
	local noise = get_noise("n1", {x = tick, y = 0}, seed)	
	local daytime = math_abs(noise)
	
	local brightness_modifier = 1.55 - daytime * 1.5
	if brightness_modifier < 0 then brightness_modifier = 0 end
	if brightness_modifier > 1 then brightness_modifier = 1 end
	
	if noise > 0 then
		surface.brightness_visual_weights = {1, brightness_modifier, 1}
	else
		surface.brightness_visual_weights = {brightness_modifier, 1, 1}
	end
		
	if daytime > 0.55 then daytime = 0.55 end

	surface.daytime = daytime
	
	--game.print(math.round(noise, 3))
end

return Public