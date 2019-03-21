local event = require 'utils.event' 

local function set_chunk_coords(radius)
	global.chunk_gen_coords = {}
	for r = radius, 1, -1 do
		for x = r * -1, r - 1, 1 do
			local pos = {x = x, y = r * -1}
			if math.sqrt(pos.x ^ 2 + pos.y ^ 2) <= radius then table.insert(global.chunk_gen_coords, pos) end			
		end
		for y = r * -1, r - 1, 1 do
			local pos = {x = r, y = y}
			if math.sqrt(pos.x ^ 2 + pos.y ^ 2) <= radius then table.insert(global.chunk_gen_coords, pos) end
		end	
		for x = r, r * -1 + 1, -1 do
			local pos = {x = x, y = r}
			if math.sqrt(pos.x ^ 2 + pos.y ^ 2) <= radius then table.insert(global.chunk_gen_coords, pos) end
		end	
		for y = r, r * -1 + 1, -1 do
			local pos = {x = r * -1, y = y}
			if math.sqrt(pos.x ^ 2 + pos.y ^ 2) <= radius then table.insert(global.chunk_gen_coords, pos) end
		end	
	end
end

local function draw_gui()
	for _, player in pairs(game.connected_players) do		
		if global.map_generation_complete then
			if player.gui.left["map_pregen"] then player.gui.left["map_pregen"].destroy() end
		else
			local caption = "Map is generating... " ..  #global.chunk_gen_coords .. " chunks left. Please get comfy."
			if player.gui.left["map_pregen"] then
				player.gui.left["map_pregen"].caption = caption
			else
				local frame = player.gui.left.add({
					type = "frame",
					caption = caption,
					name = "map_pregen"
				})
				frame.style.font_color = {r = 150, g = 100, b = 255}
				frame.style.font = "heading-1"
				frame.style.maximal_height = 36
			end
		end
	end
end

local function process_chunk(surface)	
	if global.map_generation_complete then return end
	if game.tick < 300 then return end
	if not global.chunk_gen_coords then set_chunk_coords(32) end
	if #global.chunk_gen_coords == 0 then
		global.map_generation_complete = true
		draw_gui()
		for _, player in pairs(game.connected_players) do
			player.play_sound{path="utility/new_objective", volume_modifier=0.75}
		end
		return
	end
	
	if not game then return end
	local surface = game.surfaces["biter_battles"]
	if not surface then return end
	
	for i = #global.chunk_gen_coords, 1, -1 do
		if surface.is_chunk_generated(global.chunk_gen_coords[i]) then
			global.chunk_gen_coords[i] = nil
		else
			surface.request_to_generate_chunks({x = (global.chunk_gen_coords[i].x * 32) - 16, y = (global.chunk_gen_coords[i].y * 32) - 16}, 1)
			surface.force_generate_chunk_requests()
			global.chunk_gen_coords[i] = nil
			break
		end		
	end
	draw_gui()
end

return process_chunk