local map_functions = require "tools.map_functions"

local function get_vector()
	local v = {}
	v[1] = (-100 + math.random(0, 200)) * 0.01
	v[2] = (-100 + math.random(0, 50)) * 0.01
	return v
end

local function draw_island(surface, position, size)
	map_functions.draw_noise_tile_circle(position, "grass-2", surface, size)
end

local function draw_path(surface, position, length)
	local tiles = noise_vector_tile_path(surface, "grass-1", position, get_vector(), length, math.random(2, 5))
	return tiles
end

function kill_level(surface)
	for _, t in pairs(surface.find_tiles_filtered({area = {{-256, -256}, {256, -32}}, name = {"grass-1", "grass-2"}})) do
		surface.set_tiles({{name = "water", position = t.position}}, true)
	end
end

local function wipe_vision(surface)
	for chunk in surface.get_chunks() do
		if chunk.y < 0 then game.forces.player.unchart_chunk(chunk, surface) end
	end
end

function draw_level(surface)
	kill_level(surface)
	wipe_vision(surface)
	local position = {x = 0, y = -32}
	for a = 1, 3, 1 do
		local size = math.random(20, 48)
		local length = size * 3
		local t = draw_path(surface, position, length)		
		draw_island(surface, t[#t].position, size)
		position = t[#t].position
	end
end

local function on_chunk_generated(event)
	local left_top = event.area.left_top
	local surface = event.surface
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			if left_top.y < -32 then surface.set_tiles({{name = "water", position = p}}, true) end
			if left_top.y > 32 then surface.set_tiles({{name = "water-green", position = p}}, true) end
		end
	end
end

local event = require 'utils.event'
event.add(defines.events.on_chunk_generated, on_chunk_generated)