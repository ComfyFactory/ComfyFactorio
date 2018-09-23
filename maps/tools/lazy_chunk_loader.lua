--this tool should provide you with smoother gameplay in heavily modified custom maps--
--tiles will be generated first, entities will be placed, when there are no more tiles left to process--
--by mewmew

local event = require 'utils.event'
local lazy_chunk_loader = {}
local chunk_functions = {}

--cut chunks into pieces and fill them into chunk_pieces tables
local function on_chunk_generated(event)		
	if not global.chunk_pieces then global.chunk_pieces = {} end
	if not global.chunk_pieces_entities then global.chunk_pieces_entities = {} end	
	if not global.chunk_pieces_load_amount then global.chunk_pieces_load_amount = 128 end
	if not global.chunk_pieces_load_speed then global.chunk_pieces_load_speed = 2 end -- how many ticks until one operation happens
	if game.tick > 300 then global.chunk_pieces_load_amount = 1 end -- how many pieces are processed per one operation
	local index = event.surface.index	
	for pos_y = 0, 24, 8 do
		for pos_x = 0, 24, 8 do
			table.insert(global.chunk_pieces, {{x = event.area.left_top.x + pos_x, y = event.area.left_top.y + pos_y}, index})
		end
	end 
end

--process the pieces lazy, calling chunk_functions() 
local function on_tick() 
	if global.chunk_pieces[1] then
		if game.tick % global.chunk_pieces_load_speed ~= 0 then return end
		local z = global.chunk_pieces_load_amount
		for x = #global.chunk_pieces, 1, -1 do										
			if not global.chunk_pieces[x] then return end			
			for _, f in pairs(chunk_functions) do				
				f(global.chunk_pieces[x])
			end			
			global.chunk_pieces[x] = nil
			z = z - 1
			if z == 0 then break end
		end						
	end	
end

--[[
--process the pieces lazy, calling chunk_functions() 
local function on_tick() 
	if #global.chunk_pieces > 0 then
		if game.tick % global.chunk_pieces_load_speed ~= 0 then return end				
		for x = 1, global.chunk_pieces_load_amount, 1 do				
			local i, z = next(global.chunk_pieces, nil)			
			if not i then return end			
			for _, f in pairs(chunk_functions) do				
				f(global.chunk_pieces[i])
			end			
			global.chunk_pieces[i] = nil							
		end						
	end	
end
]]--

--add custom terrain functions here
lazy_chunk_loader.add = function(f)
	table.insert(chunk_functions, f)
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_chunk_generated, on_chunk_generated)

return lazy_chunk_loader