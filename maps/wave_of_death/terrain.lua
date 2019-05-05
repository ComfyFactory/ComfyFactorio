local function init(surface, left_top)
	if left_top.x ~= 96 then return end
	if left_top.y ~= 96 then return end
	
	surface.request_to_generate_chunks({x = 0, y = 0}, 9)
	surface.force_generate_chunk_requests()
	
	global.loaders = {}
	for i = 1, 4, 1 do
		global.loaders[i] = surface.create_entity({name = "loader", position = {x = -240 + 192*(i - 1), y = 0}, force = i})
		global.loaders[i].minable = false
	end
	
	rendering.draw_sprite({sprite = "file/maps/wave_of_death/WoD.png", target = {32, 0}, surface = game.surfaces.nauvis, orientation = 0, x_scale = 2, y_scale = 2, render_layer = "ground-tile"})
end

local function draw_lanes(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}
			surface.set_tiles({{name = "grass-2", position = position}})
		end
	end
end

local function draw_void(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}
			surface.set_tiles({{name = "out-of-map", position = position}})
		end
	end
end

local function clear_chunk(surface, area)
	surface.destroy_decoratives{area = area}
	for _, e in pairs(surface.find_entities_filtered({area = area})) do
		if e.name ~= "character" then
			e.destroy()
		end
	end
end

local function on_chunk_generated(event)
	local surface = game.surfaces["nauvis"]
	if event.surface.index ~= surface.index then return end
	local left_top = event.area.left_top
	if left_top.x % 192 < 96 or left_top.x > 256 or left_top.x < - 256 then
		draw_void(surface, left_top)
	else
		clear_chunk(surface, event.area)
		draw_lanes(surface, left_top)
	end	
	init(surface, left_top)
end

return on_chunk_generated

