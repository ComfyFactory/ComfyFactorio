local function set_chunk_coords()
	global.chunk_gen_coords = {}
	for r = 14, 1, -1 do
		for x = r * -1, r - 1, 1 do
			table.insert(global.chunk_gen_coords, {x = x, y = r * -1})
		end
		for y = r * -1, r - 1, 1 do
			table.insert(global.chunk_gen_coords, {x = r, y = y})
		end	
		for x = r, r * -1 + 1, -1 do
			table.insert(global.chunk_gen_coords, {x = x, y = r})
		end	
		for y = r, r * -1 + 1, -1 do
			table.insert(global.chunk_gen_coords, {x = r * -1, y = y})
		end	
	end
end

local function draw_gui()
	for _, player in pairs(game.connected_players) do
		if player.gui.left["map_pregen"] then player.gui.left["map_pregen"].destroy() end
		if not global.map_generation_complete then
			local frame = player.gui.left.add({
				type = "frame",
				caption = "Map is generating... " ..  #global.chunk_gen_coords .. " chunks left.",
				name = "map_pregen"
			})
			frame.style.font_color = {r = 100, g = 100, b = 250}
			frame.style.font = "heading-2"
		end
	end
end

local function process_chunk()
	if global.map_generation_complete then draw_gui() return end
	if not global.chunk_gen_coords then set_chunk_coords() end
	if #global.chunk_gen_coords == 0 then
		global.map_generation_complete = true
		draw_gui()
		return
	end
	local surface = game.surfaces["biter_battles"]
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