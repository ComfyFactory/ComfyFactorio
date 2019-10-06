local function process_position(surface, p)
	local distance_to_center = math.sqrt(p.x^2 + p.y^2)	
	local index = math.floor((distance_to_center / 16) % 18) + 1
	--if index == 7 then surface.create_entity({name = "rock-big", position = p}) return end
	if index % 2 == 1 then
		if math.random(1, 3) == 1 then
			surface.create_entity({name = "rock-big", position = p})
		else
			surface.create_entity({name = "tree-0" .. math.ceil(index * 0.5), position = p})
		end
		return		
	end
end

local function on_chunk_generated(event)
	local left_top = event.area.left_top
	local surface = event.surface
	
	for x = 0.5, 31.5, 1 do
		for y = 0.5, 31.5, 1 do
			p = {x = left_top.x + x, y = left_top.y + y}
			--process_position(surface, p)
					
		end
	end
end

local event = require 'utils.event'
event.add(defines.events.on_chunk_generated, on_chunk_generated)