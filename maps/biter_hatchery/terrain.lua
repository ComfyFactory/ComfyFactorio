local function on_chunk_generated(event)
	local left_top = event.area.left_top
	
	if left_top.x > 512 then return end
	if left_top.x < -512 then return end
	if left_top.y > 512 then return end
	if left_top.y < -512 then return end
	
	game.forces.west.chart(event.surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}})
	game.forces.east.chart(event.surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}})
end

local event = require 'utils.event'
event.add(defines.events.on_chunk_generated, on_chunk_generated)