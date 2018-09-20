--this tool should provide you with smoother gameplay in heavily modified custom maps--
--tiles will be generated first, entities will be placed, when there are no more tiles left to process--
--by mewmew

local event = require 'utils.event'
if not global.generate_chunk_tiles_functions then global.generate_chunk_tiles_functions = {} end
if not global.generate_chunk_entities_functions then global.generate_chunk_entities_functions = {} end

--cut chunks into 8x8 pieces and fill them into global.chunk_pieces
local function on_chunk_generated(event)		
	if not global.generate_chunk_tiles_functions[1] then game.print("No functions found in table: global.generate_chunk_tiles_functions") return end
	if not global.generate_chunk_entities_functions[1] then game.print("No functions found in table: global.generate_chunk_entities_functions") return end
	if not global.chunk_pieces then global.chunk_pieces = {} end
	if not global.chunk_pieces_tile_index then global.chunk_pieces_tile_index = 1 end
	if not global.chunk_pieces_entity_index then global.chunk_pieces_entity_index = 1 end
	if not global.chunk_pieces_load_speed then global.chunk_pieces_load_speed = 1 end -- max chunk loading speed in 8x8 tile pieces / tick	
	for pos_y = 0, 24, 8 do
		for pos_x = 0, 24, 8 do
			local a = {
				left_top = {x = event.area.left_top.x + pos_x, y = event.area.left_top.y + pos_y},
				right_bottom = {x = event.area.left_top.x + pos_x + 8, y = event.area.left_top.y + pos_y + 8}
			}			
			table.insert(global.chunk_pieces, {area = a, surface = event.surface})
		end
	end	 
end

--process the pieces lazy, calling generate_chunk_tiles_functions() and generate_chunk_entities_functions()
local function on_tick()	
	if global.chunk_pieces[global.chunk_pieces_tile_index] then		
		if global.chunk_pieces_tile_index < 4096 then   --4096 for a fast spawn generation
			for x = 1, 128, 1 do
				if global.chunk_pieces[global.chunk_pieces_tile_index] then 
					for _, f in pairs(global.generate_chunk_tiles_functions) do
						f(global.chunk_pieces[global.chunk_pieces_tile_index])
					end
					global.chunk_pieces_tile_index = global.chunk_pieces_tile_index + 1
				end
			end			
		else
			for x = 1, global.chunk_pieces_load_speed, 1 do
				if global.chunk_pieces[global.chunk_pieces_tile_index] then
					for _, f in pairs(global.generate_chunk_tiles_functions) do
						f(global.chunk_pieces[global.chunk_pieces_tile_index])
					end
					global.chunk_pieces_tile_index = global.chunk_pieces_tile_index + 1
				end
			end			
		end
	else
		if global.chunk_pieces[global.chunk_pieces_entity_index] then
			if global.chunk_pieces_entity_index < 4096 then   --4096 for a fast spawn generation
				for x = 1, 128, 1 do
					if global.chunk_pieces[global.chunk_pieces_entity_index] then
						for _, f in pairs(global.generate_chunk_entities_functions) do
							f(global.chunk_pieces[global.chunk_pieces_entity_index])
						end
						global.chunk_pieces_entity_index = global.chunk_pieces_entity_index + 1
					end
				end				
			else
				if not global.chunk_fast_spawn_generation_done then global.chunk_fast_spawn_generation_done = true game.print("Spawn generation done!", { r=0.22, g=0.99, b=0.99}) end
				for x = 1, global.chunk_pieces_load_speed, 1 do
					if global.chunk_pieces[global.chunk_pieces_entity_index] then 
						for _, f in pairs(global.generate_chunk_entities_functions) do
							f(global.chunk_pieces[global.chunk_pieces_entity_index])
						end
						global.chunk_pieces_entity_index = global.chunk_pieces_entity_index + 1
					end
				end				
			end
		end
	end	
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_chunk_generated, on_chunk_generated)