local Blood_moon = require "maps.pitch_black.blood_moon"

local function on_tick()
	local tick = game.tick
	if tick % 3 ~= 0 then return end
	local surface = game.surfaces[1]
	Blood_moon.set_daytime(surface, tick)
end

local function on_init()
	local surface = game.surfaces[1]
	
	surface.freeze_daytime = true
	surface.min_brightness = 0	
end

local Event = require 'utils.event'
Event.add(defines.events.on_tick, on_tick)
Event.on_init(on_init)