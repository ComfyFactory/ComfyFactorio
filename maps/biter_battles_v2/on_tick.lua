local event = require 'utils.event'

local gui = require "maps.biter_battles_v2.gui"
local ai = require "maps.biter_battles_v2.ai"

local function on_tick(event)
	if game.tick % 60 ~= 0 then return end
	gui()
end

event.add(defines.events.on_tick, on_tick)
