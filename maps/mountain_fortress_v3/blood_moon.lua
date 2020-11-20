local Public = {}

local get_noise = require 'utils.get_noise'
local math_abs = math.abs
local math_round = math.round

function Public.set_daytime(surface, tick, static)
    if static then
        surface.brightness_visual_weights = {
            a = 1,
            b = 1,
            g = 1,
            r = 0.57314002513885498
        }
        surface.daytime = 0.55
        surface.freeze_daytime = true
        return
    end

    local noise = get_noise('n1', {x = tick * 1, y = 0}, surface.map_gen_settings.seed)
    local daytime = math_abs(math_round(noise, 5))

    local brightness_modifier = 1.55 - daytime * 1.5
    if brightness_modifier < 0 then
        brightness_modifier = 0
    end
    if brightness_modifier > 1 then
        brightness_modifier = 1
    end

    if noise > 0 then
        surface.brightness_visual_weights = {1, brightness_modifier, 1}
    else
        surface.brightness_visual_weights = {brightness_modifier, 1, 1}
    end

    if daytime > 0.55 then
        daytime = 0.55
    end
    surface.daytime = daytime
    surface.freeze_daytime = true
end

return Public
