local room = {}

room.empty = function(surface, cell_left_top, direction)
	
end

room.worms = function(surface, cell_left_top, direction)	
	local amount = math.ceil(get_biter_amount() * 0.1)
	local tile_positions = {}
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 0.5, grid_size - 0.5, 1 do
		for y = 0.5, grid_size - 0.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			tile_positions[#tile_positions + 1] = pos
		end
	end
	
	table.shuffle_table(tile_positions)
	
	for _, pos in pairs(tile_positions) do
		local worm = get_worm()
		if surface.can_place_entity({name = worm, position = pos}) and math.random(1,4) == 1 then
			surface.create_entity({name = worm, position = pos, force = "enemy"})
			amount = amount - 1
		end	
		if amount < 1 then break end
	end
end

room.nests = function(surface, cell_left_top, direction)	
	local amount = math.ceil(get_biter_amount() * 0.1)
	local tile_positions = {}
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 0.5, grid_size - 0.5, 1 do
		for y = 0.5, grid_size - 0.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			tile_positions[#tile_positions + 1] = pos
		end
	end
	
	table.shuffle_table(tile_positions)
	
	for _, pos in pairs(tile_positions) do
		if surface.can_place_entity({name = "spitter-spawner", position = pos}) then
			if math.random(1,4) == 1 then
				surface.create_entity({name = "spitter-spawner", position = pos, force = "enemy"})
			else
				surface.create_entity({name = "biter-spawner", position = pos, force = "enemy"})			
			end
			amount = amount - 1
		end		
		if amount < 1 then break end
	end
end

room.biters = function(surface, cell_left_top, direction)
	local amount = get_biter_amount()
	local tile_positions = {}
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 0.5, grid_size - 0.5, 1 do
		for y = 0.5, grid_size - 0.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			tile_positions[#tile_positions + 1] = pos
		end
	end
	
	table.shuffle_table(tile_positions)
	
	for _, pos in pairs(tile_positions) do
		local enemy = get_biter()
		if surface.can_place_entity({name = enemy, position = pos}) then
			surface.create_entity({name = enemy, position = pos, force = "enemy"})
			amount = amount - 1
		end
		if amount < 1 then break end
	end		
end

room.spitters = function(surface, cell_left_top, direction)
	local amount = get_biter_amount()
	local tile_positions = {}
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 0.5, grid_size - 0.5, 1 do
		for y = 0.5, grid_size - 0.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			tile_positions[#tile_positions + 1] = pos
		end
	end
	
	table.shuffle_table(tile_positions)
	
	for _, pos in pairs(tile_positions) do
		local enemy = get_spitter()
		if surface.can_place_entity({name = enemy, position = pos}) then
			surface.create_entity({name = enemy, position = pos, force = "enemy"})
			amount = amount - 1
		end
		if amount < 1 then break end
	end		
end

room.spitters_and_biters = function(surface, cell_left_top, direction)
	local amount = get_biter_amount()
	local tile_positions = {}
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 0.5, grid_size - 0.5, 1 do
		for y = 0.5, grid_size - 0.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			tile_positions[#tile_positions + 1] = pos
		end
	end
	
	table.shuffle_table(tile_positions)
	
	for _, pos in pairs(tile_positions) do
		local enemy = get_biter()
		if math.random(1,3) == 1 then enemy = get_spitter() end
		if surface.can_place_entity({name = enemy, position = pos, force = "enemy"}) then
			surface.create_entity({name = enemy, position = pos, force = "enemy"})
			amount = amount - 1
		end	
		if amount < 1 then break end
	end		
end

room.checkerboard_ore = function(surface, cell_left_top, direction)
	local ores = {"coal", "iron-ore", "copper-ore", "stone"}
	table.shuffle_table(ores)
	
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 1, grid_size - 2, 1 do
		for y = 1, grid_size - 2, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			if x % 2 == y % 2 then
				surface.create_entity({name = ores[1], position = pos, force = "neutral", amount = 256 + global.maze_depth * 4})
			else
				surface.create_entity({name = ores[2], position = pos, force = "neutral", amount = 256 + global.maze_depth * 4})
			end
			surface.set_tiles({{name = "grass-2", position = pos}}, true)
		end
	end
end

room.single_oil = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	surface.create_entity({name = "crude-oil", position = {left_top.x + grid_size * 0.5, left_top.y + grid_size * 0.5}, amount = 100000 + global.maze_depth * 4000})
	room.spitters(surface, cell_left_top, direction)
	room.biters(surface, cell_left_top, direction)
end

room.tree_ring = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	local tree = tree_raffle[math.random(1, #tree_raffle)]
	map_functions.draw_noise_tile_circle({x = left_top.x + grid_size * 0.5, y = left_top.y + grid_size * 0.5}, "grass-2", surface, grid_size * 0.35)
	map_functions.draw_noise_entity_ring(surface, {x = left_top.x + grid_size * 0.5, y = left_top.y + grid_size * 0.5}, tree, "neutral", grid_size * 0.25, grid_size * 0.33)
	surface.spill_item_stack({x = left_top.x + grid_size * 0.5, y = left_top.y + grid_size * 0.5}, get_loot_item_stack(), true, nil, true)
	room.spitters(surface, cell_left_top, direction)
end

room.tons_of_trees = function(surface, cell_left_top, direction)
	local tree = tree_raffle[math.random(1, #tree_raffle)]
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 0.5, grid_size - 0.5, 1 do
		for y = 0.5, grid_size - 0.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			if math.random(1,4) == 1 then
				surface.create_entity({name = tree, position = pos, force = "neutral"})
			end
		end
	end
end

room.loot_crate = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	map_functions.draw_noise_tile_circle({x = left_top.x + grid_size * 0.5, y = left_top.y + grid_size * 0.5}, "stone-path", surface, grid_size * 0.2)
	local chest = surface.create_entity({name = "wooden-chest", position = {left_top.x + grid_size * 0.5, left_top.y + grid_size * 0.5}, force = "neutral"})
	chest.destructible = false
	chest.insert(get_loot_item_stack())
	if math.random(1,2) == 1 then chest.insert(get_loot_item_stack()) end
	room.spitters_and_biters(surface, cell_left_top, direction)
end

room.single_rock = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = {left_top.x + grid_size * 0.5, left_top.y + grid_size * 0.5}, force = "neutral"})
	room.biters(surface, cell_left_top, direction)
end

room.three_rocks = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = {left_top.x + grid_size * 0.2, left_top.y + grid_size * 0.8}, force = "neutral"})
	surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = {left_top.x + grid_size * 0.8, left_top.y + grid_size * 0.8}, force = "neutral"})
	surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = {left_top.x + grid_size * 0.5, left_top.y + grid_size * 0.2}, force = "neutral"})
	room.biters(surface, cell_left_top, direction)
end

room.quad_rocks = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = {left_top.x + grid_size * 0.15, left_top.y + grid_size * 0.15}, force = "neutral"})
	surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = {left_top.x + grid_size * 0.15, left_top.y + grid_size * 0.85}, force = "neutral"})
	surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = {left_top.x + grid_size * 0.85, left_top.y + grid_size * 0.15}, force = "neutral"})
	surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = {left_top.x + grid_size * 0.85, left_top.y + grid_size * 0.85}, force = "neutral"})
	room.spitters_and_biters(surface, cell_left_top, direction)
end

room.tons_of_rocks = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 0.5, grid_size - 0.5, 1 do
		for y = 0.5, grid_size - 0.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			if math.random(1,4) ~= 1 then
				surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = pos, force = "neutral"})
			end
		end
	end
end

room.lots_of_rocks = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 0.5, grid_size - 0.5, 1 do
		for y = 0.5, grid_size - 0.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			if math.random(1,2) ~= 1 then
				surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = pos, force = "neutral"})
			end
		end
	end
end

room.some_scrap = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = math.floor(grid_size * 0.15), math.floor(grid_size * 0.85) - 1, 1 do
		for y = math.floor(grid_size * 0.15), math.floor(grid_size * 0.85) - 1, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			if math.random(1,16) == 1 then
				surface.create_entity({name = "mineable-wreckage", position = pos, force = "neutral"})
			end
		end
	end
	room.worms(surface, cell_left_top, direction)	
end

room.lots_of_scrap = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 0.5, grid_size - 0.5, 1 do
		for y = 0.5, grid_size - 0.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			if math.random(1,8) == 1 then
				surface.create_entity({name = "mineable-wreckage", position = pos, force = "neutral"})
			end
		end
	end
end

room.tons_of_scrap = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 0.5, grid_size - 0.5, 1 do
		for y = 0.5, grid_size - 0.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			if math.random(1,2) == 1 then
				surface.create_entity({name = "mineable-wreckage", position = pos, force = "neutral"})
			end
		end
	end
end

room.pond = function(surface, cell_left_top, direction)
	local tree = tree_raffle[math.random(1, #tree_raffle)]
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	map_functions.draw_noise_tile_circle({x = left_top.x + grid_size * 0.5, y = left_top.y + grid_size * 0.5}, "water", surface, grid_size * 0.3)
	for x = 0.5, grid_size - 0.5, 1 do
		for y = 0.5, grid_size - 0.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			if math.random(1,16) == 1 then
				if surface.can_place_entity({name = "fish", position = pos, force = "neutral"}) then
					surface.create_entity({name = "fish", position = pos, force = "neutral"})
				end
			end
			if math.random(1,40) == 1 then
				if surface.can_place_entity({name = tree, position = pos, force = "neutral"}) then
					surface.create_entity({name = tree, position = pos, force = "neutral"})
				end
			end
		end
	end
end

local room_weights = {		
	{func = room.worms, weight = 15},
	{func = room.nests, weight = 8},
	
	{func = room.tons_of_trees, weight = 15},	
	
	{func = room.lots_of_rocks, weight = 15},
	{func = room.tons_of_rocks, weight = 15},	
	{func = room.quad_rocks, weight = 10},
	{func = room.three_rocks, weight = 3},
	{func = room.single_rock, weight = 10},
	
	{func = room.checkerboard_ore, weight = 7},
	{func = room.single_oil, weight = 5},
	--{func = room.some_scrap, weight = 10},
	{func = room.lots_of_scrap, weight = 5},
	--{func = room.tons_of_scrap, weight = 2},
	--{func = room.empty, weight = 1},
	
	{func = room.pond, weight = 8},
	
	{func = room.loot_crate, weight = 10},
	{func = room.tree_ring, weight = 10}
	
}

local room_shuffle = {}
for _, r in pairs(room_weights) do
	for c = 1, r.weight, 1 do
		room_shuffle[#room_shuffle + 1] = r.func
	end
end

return room_shuffle