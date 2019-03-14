local event = require 'utils.event'

local gui = require "maps.biter_battles_v2.gui"
local ai = require "maps.biter_battles_v2.ai"
local pregenerate_chunks = require "maps.biter_battles_v2.pregenerate_chunks"

local function on_tick(event)
	if game.tick % 5 ~= 0 then return end
	pregenerate_chunks()
	if game.tick % 60 ~= 0 then return end		
end

event.add(defines.events.on_tick, on_tick)
