local math_random = math.random
local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local spawner_raffle = {"biter-spawner", "biter-spawner", "biter-spawner", "spitter-spawner"}

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

local function rock_chunk(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			surface.set_tiles({{name = "dirt-7", position = {x = left_top.x + x, y = left_top.y + y}}})				
		end
	end
end

local function border_chunk(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			surface.set_tiles({{name = "dirt-3", position = {x = left_top.x + x, y = left_top.y + y}}})				
		end
	end
	
	local trees = {"dead-grey-trunk", "dead-grey-trunk", "dry-tree"}
	for x = 0, 31, 1 do
		for y = 5, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if math_random(1, math.ceil(pos.y + pos.y) + 64) == 1 then
				surface.create_entity({name = trees[math_random(1, #trees)], position = pos})			
			end
		end
	end		
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if math_random(1, pos.y + 2) == 1 then
				surface.create_decoratives{
				check_collision=false,
				decoratives={
						{name = "rock-medium", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))}
					}
				}
			end
			if math_random(1, pos.y + 2) == 1 then
				surface.create_decoratives{
				check_collision=false,
				decoratives={
						{name = "rock-small", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))}
					}
				}
			end
			if math_random(1, pos.y + 2) == 1 then
				surface.create_decoratives{
				check_collision=false,
				decoratives={
						{name = "rock-tiny", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))}
					}
				}
			end									
			if math_random(1, math.ceil(pos.y + pos.y) + 2) == 1 then
				surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = pos})			
			end
		end
	end
end

local function biter_chunk(surface, left_top)
	local tile_positions = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			surface.set_tiles({{name = "sand-3", position = p}})
			tile_positions[#tile_positions + 1] = p
		end
	end
	for i = 1, 4, 1 do
		local position = surface.find_non_colliding_position("biter-spawner", tile_positions[math_random(1, #tile_positions)], 16, 2)
		if position then
			surface.create_entity({name = spawner_raffle[math_random(1, #spawner_raffle)], position = position})
		end		
	end
end

local function out_of_map(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x = left_top.x + x, y = left_top.y + y}}})				
		end
	end
end

local function process_chunk(left_top)
	local surface = game.surfaces["mountain_fortress"]
	if left_top.y == 96 and left_top.x == 96 then
		local p = global.locomotive.position
		for _, entity in pairs(surface.find_entities_filtered({area = {{p.x - 3, p.y - 4},{p.x + 3, p.y + 8}}, force = "neutral"})) do	entity.destroy() end
	end
	if left_top.y < 0 then rock_chunk(surface, left_top) return end
	if left_top.y > 128 then out_of_map(surface, left_top) return end
	if left_top.y > 64 then biter_chunk(surface, left_top) return end
	if left_top.y >= 0 then border_chunk(surface, left_top) return end
end

local function process_chunk_queue()
	for k, left_top in pairs(global.chunk_queue) do
		process_chunk(left_top)
		global.chunk_queue[k] = nil
		return
	end
end

local function on_chunk_generated(event)
	if game.surfaces["mountain_fortress"].index ~= event.surface.index then return end
	local left_top = event.area.left_top
	
	if game.tick == 0 then
		process_chunk(left_top)
	else
		global.chunk_queue[#global.chunk_queue + 1] = {x = left_top.x, y = left_top.y}
	end
end

local event = require 'utils.event'
event.on_nth_tick(60, process_chunk_queue)
event.add(defines.events.on_chunk_generated, on_chunk_generated)