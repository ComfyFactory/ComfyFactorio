local room = {}

room.empty = function(surface, cell_left_top, direction)
	
end

room.stone_block = function(surface, cell_left_top, direction)	
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 3.5, grid_size * 3 - 3.5, 1 do
		for y = 3.5, grid_size * 3 - 3.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}			
			if math.random(1,5) ~= 1 then surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = pos, force = "neutral"}) end
		end
	end
end

room.nine_nests = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	
	local tree = tree_raffle[math.random(1, #tree_raffle)]
	
	for x = 0, grid_size * 3 - 1, 1 do
		for y = 0, grid_size * 3 - 1, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			if x <= 1 or x >= grid_size * 3 - 2 or y <= 1 or y >= grid_size * 3 - 2 then
				surface.create_entity({name = tree, position = pos, force = "neutral"})			
			end
		end
	end
	
	if global.maze_depth < 50 then
		surface.create_entity({name = "biter-spawner", position = {left_top.x + grid_size * 3 * 0.5, left_top.y + grid_size * 3 * 0.5}, force = "enemy"})
		return 
	end
	surface.create_entity({name = "biter-spawner", position = {left_top.x + grid_size * 3 * 0.25, left_top.y + grid_size * 3 * 0.25}, force = "enemy"})
	surface.create_entity({name = "biter-spawner", position = {left_top.x + grid_size * 3 * 0.5, left_top.y + grid_size * 3 * 0.25}, force = "enemy"})
	surface.create_entity({name = "biter-spawner", position = {left_top.x + grid_size * 3 * 0.75, left_top.y + grid_size * 3 * 0.25}, force = "enemy"})
	surface.create_entity({name = "biter-spawner", position = {left_top.x + grid_size * 3 * 0.25, left_top.y + grid_size * 3 * 0.5}, force = "enemy"})
	surface.create_entity({name = "spitter-spawner", position = {left_top.x + grid_size * 3 * 0.5, left_top.y + grid_size * 3 * 0.5}, force = "enemy"})
	surface.create_entity({name = "biter-spawner", position = {left_top.x + grid_size * 3 * 0.75, left_top.y + grid_size * 3 * 0.5}, force = "enemy"})
	surface.create_entity({name = "biter-spawner", position = {left_top.x + grid_size * 3 * 0.25, left_top.y + grid_size * 3 * 0.75}, force = "enemy"})
	surface.create_entity({name = "biter-spawner", position = {left_top.x + grid_size * 3 * 0.5, left_top.y + grid_size * 3 * 0.75}, force = "enemy"})
	surface.create_entity({name = "biter-spawner", position = {left_top.x + grid_size * 3 * 0.75, left_top.y + grid_size * 3 * 0.75}, force = "enemy"})
end

local room_weights = {
	{func = room.stone_block, weight = 25},
	{func = room.nine_nests, weight = 15},
	{func = room.empty, weight = 1}
}

local room_shuffle = {}
for _, r in pairs(room_weights) do
	for c = 1, r.weight, 1 do
		room_shuffle[#room_shuffle + 1] = r.func
	end
end

return room_shuffle