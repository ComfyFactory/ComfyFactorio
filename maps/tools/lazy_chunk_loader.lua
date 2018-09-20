--this tool should provide you with smoother gameplay in heavily modified custom maps--
--tiles will be generated first, entities will be placed, when there are no more tiles left to process--
--by mewmew

local event = require 'utils.event'

--cut chunks into 8x8 pieces and fill them into global.chunk_pieces
local function on_chunk_generated(event)	
	if not global.chunk_pieces then global.chunk_pieces = {} end
	if not global.chunk_pieces_tile_index then global.chunk_pieces_tile_index = 1 end
	if not global.chunk_pieces_entity_index then global.chunk_pieces_entity_index = 1 end
	local a
	for pos_y = 0, 24, 8 do
		for pos_x = 0, 24, 8 do
			a = {
				left_top = {x = event.area.left_top.x + pos_x, y = event.area.left_top.y + pos_y},
				right_bottom = {x = event.area.left_top.x + pos_x + 8, y = event.area.left_top.y + pos_y + 8}
			}			
			table.insert(global.chunk_pieces, {area = a, surface = event.surface})
		end
	end	 
end

--process the pieces lazy, calling generate_chunk_tiles() and generate_chunk_entities()
local function on_tick()
	if not generate_chunk_tiles then game.print("no function > generate_chunk_tiles") return end
	if not generate_chunk_entities then game.print("no function > generate_chunk_entities") return end
	
	if global.chunk_pieces[global.chunk_pieces_tile_index] then		
		if global.chunk_pieces_tile_index < 4096 then   --4096 for a fast spawn generation
			for x = 1, 16, 1 do
				if global.chunk_pieces[global.chunk_pieces_tile_index] then 
					generate_chunk_tiles(global.chunk_pieces[global.chunk_pieces_tile_index])
					global.chunk_pieces_tile_index = global.chunk_pieces_tile_index + 1
				end
			end
		else
			generate_chunk_tiles(global.chunk_pieces[global.chunk_pieces_tile_index])
			global.chunk_pieces_tile_index = global.chunk_pieces_tile_index + 1
		end
	else
		if global.chunk_pieces[global.chunk_pieces_entity_index] then
			if global.chunk_pieces_entity_index < 4096 then   --4096 for a fast spawn generation
				for x = 1, 16, 1 do
					if global.chunk_pieces[global.chunk_pieces_entity_index] then 
						generate_chunk_entities(global.chunk_pieces[global.chunk_pieces_entity_index])
						global.chunk_pieces_entity_index = global.chunk_pieces_entity_index + 1
					end
				end
			else
				generate_chunk_entities(global.chunk_pieces[global.chunk_pieces_entity_index])
				global.chunk_pieces_entity_index = global.chunk_pieces_entity_index + 1
			end
		end
	end	
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_chunk_generated, on_chunk_generated)