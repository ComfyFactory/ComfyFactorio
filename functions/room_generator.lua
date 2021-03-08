local Public = {}
local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random

local room_spacing = 4
local room_spacing2 = room_spacing * 2

local function build_room_rect(surface, position, vector, room_center_position, room_size, offset)
	local room = {}
	
	--local a = room_radius - 1
	local room_area = {
		left_top = {x = room_center_position.x - room_size.x +1, y = room_center_position.y - room_size.y+1},
		right_bottom = {x = room_center_position.x + room_size.x, y = room_center_position.y + room_size.y}	
	}		
	room.room_tiles = surface.find_tiles_filtered({area = room_area})
	
	room.path_tiles = {}
	for d = 1, room_spacing, 1 do
		local p = {position.x + vector[1] * d + offset.x, position.y + vector[2] * d + offset.y}
		local tile = surface.get_tile(p)
		table_insert(room.path_tiles, tile)
	end
	
	room.entrance_tile = surface.get_tile({position.x + offset.x + vector[1] * (room_spacing + 1), position.y + offset.y + vector[2] * (room_spacing + 1)})

	room.room_border_tiles = {}
	local left_top = {x = room_area.left_top.x - 1, y = room_area.left_top.y - 1}
	local right_bottom = {x = room_area.right_bottom.x, y = room_area.right_bottom.y}
	local t = room.room_border_tiles
	for d = 0, room_size.x * 2, 1 do
		table_insert(t, surface.get_tile({left_top.x + d, left_top.y}))
		table_insert(t, surface.get_tile({left_top.x + d, right_bottom.y}))
	end
	
	for d = 1, room_size.y * 2-1, 1 do
		table_insert(t, surface.get_tile({left_top.x 	, left_top.y + d}))
		table_insert(t, surface.get_tile({right_bottom.x, left_top.y + d}))
	end
	
	room.center = room_center_position
	room.radius = math.min(room_size.x,room_size.y)
	room.size = room_size
	
	return room
end


local function scan_area_empty(surface,search_area)
	local tiles = surface.find_tiles_filtered({area = search_area})
	for _, tile in pairs(tiles) do
		if not tile.collides_with("resource-layer") then 
			return false
		end
	end
	return true
end

local function scan_strip_empty(surface, position, vector, length)
	for d = 0, length, 1 do
		local p = {position.x + vector[1] * d, position.y + vector[2] * d}
		local tile = surface.get_tile(p)
		if not tile.collides_with("resource-layer") then 
			return false
		end
	end
	return true
end

--Scans the X and Y independantly for best size
local function scan_direction_full(surface, position, vector, room_max,room_min)
	local best = {x=room_min,y=room_min}
	
	local a = room_min + room_spacing + 1
	local room_center_pos = {x = position.x + vector[1] * a, y = position.y + vector[2] * a}
	
	local search_area = {
		{x = room_center_pos.x - best.x - room_spacing, y = room_center_pos.y - best.y - room_spacing},
		{x = room_center_pos.x + best.x + room_spacing+ 1, y = room_center_pos.y + best.y + room_spacing + 1}
	}
	
	if not scan_area_empty(surface,search_area) then
		return {x=0,y=0}
	end
	
	local x_end = false
	local y_end = false
	
	if vector[1] == 0 then
		local yy = position.y + vector[2]
		repeat
			if not x_end then
				
				if not scan_strip_empty(surface, {x = position.x + best.x + room_spacing + 1, y = yy}, vector, best.y*2 + room_spacing2) or
				not scan_strip_empty(surface, {x = position.x - best.x - room_spacing - 1, y = yy}, vector, best.y*2 + room_spacing2) then
					x_end = true
				else
					best.x = best.x + 1
				end
				if best.x  >= room_max.x then x_end = true end
			end
			if not y_end then
				local xx = position.x - best.x - room_spacing - 1
				if not scan_strip_empty(surface, {x = xx, y = position.y + vector[2] * (best.y*2+room_spacing2+1)}, {1,0}, best.x*2 + room_spacing2) or
				not scan_strip_empty(surface, {x = xx, y = position.y + vector[2] * (best.y*2+room_spacing2+2)}, {1,0}, best.x*2 + room_spacing2) then
					y_end = true
				else
					best.y = best.y + 1
				end
				if best.y  >= room_max.y then y_end = true end
			end
		until(x_end and y_end)
	else
		local xx = position.x + vector[1]
		repeat
			if not y_end then
				if not scan_strip_empty(surface, {x = xx, y = position.y+best.y+room_spacing+1}, vector, best.x*2 + room_spacing2) or
				not scan_strip_empty(surface, {x = xx, y = position.y-best.y-room_spacing-1}, vector, best.x*2 + room_spacing2) then
					y_end = true
				else
					best.y = best.y + 1
				end
				if best.y  >= room_max.y then y_end = true end
			
			end
			if not x_end then
			
				local yy = position.y - best.y - room_spacing - 1
				if not scan_strip_empty(surface, {x = position.x + vector[1] * (best.x*2+room_spacing2+1), y = yy}, {0,1}, best.y*2 + room_spacing2) or
				not scan_strip_empty(surface, {x = position.x + vector[1] * (best.x*2+room_spacing2+2), y = yy}, {0,1}, best.y*2 + room_spacing2) then
					x_end = true
				else
					best.x = best.x + 1
				end
				if best.x  >= room_max.x then x_end = true end
			
			end

		until(x_end and y_end)
	end
	
	return best
end

--get room tiles and build a room with best fit and add a chance for offset
local function get_room_tiles_wiggle(surface, position, size, shape)
	local vectors = {{0, -1}, {0, 1}, {1, 0}, {-1, 0}}
	table_shuffle_table(vectors)

	local room_max = {x = size,y= size}
	
	if shape == "wide" then
		room_max.x = room_max.x +4
	elseif shape == "tall" then
		room_max.y = room_max.y +4
	elseif shape == "big" then
		room_max.x = room_max.x +3
		room_max.y = room_max.y +3
	end
	
	for _, v in pairs(vectors) do
		local full = scan_direction_full(surface, position, v, room_max,3)
		
		if full.x > 0 then

			local new_pos = position
			
			local offset = {x=0,y=0}
			
			if v[1] == 0 then
				if full.x > 6 then
					local max_roll = math.abs(full.x*0.5)
					if shape == "square" then max_roll = math.min(max_roll, math.abs(full.y*0.5)) end
					local roll = math_random(1 - max_roll,max_roll - 1)
					new_pos.x = new_pos.x + roll
					offset.x = -roll
					full.x = full.x - (1 + math.abs(roll * 0.5))
					
				end
			else
				if full.y > 6 then
					local max_roll = math.abs(full.y*0.5)
					if shape == "square" then max_roll = math.min(max_roll, math.abs(full.x*0.5)) end
					local roll = math_random(1 - max_roll,max_roll - 1)
					new_pos.y = new_pos.y + roll
					offset.y = -roll
					full.y = full.y - (1 + math.abs(roll * 0.5))
				end
			end

			if shape == "square" then
				--game.print("forcing square")
				if full.x > full.y then
					full.x = full.y
				else
					full.y = full.x
				end
			end
			
			local room_center_position = {x = new_pos.x + v[1] * (full.x + room_spacing + 1), y = new_pos.y + v[2] * (full.y + room_spacing + 1)}
			return build_room_rect(surface, new_pos, v, room_center_position, full, offset)

		end
	end

end

local function expand_path_tiles_width(surface, room)
	if not room then return end
	
	local max_expansion_count = 1
	if math_random(1, 4) == 1 then max_expansion_count = 2 end
	if math_random(1, 16) == 1 then max_expansion_count = 3 end
	--if max_expansion_count == 0 then return end
	
	local path_tiles = room.path_tiles
	local vectors = {{0, -1}, {0, 1}, {1, 0}, {-1, 0}}
	
	local entrance_tile
	local exit_tile
	
	local position = path_tiles[1].position
	local expansion_vectors = {}
	for _, v in pairs(vectors) do
		local tile = surface.get_tile({position.x + v[1], position.y + v[2]})
		if not tile.collides_with("resource-layer") then		
			entrance_tile = tile
			exit_tile = surface.get_tile({path_tiles[#path_tiles].position.x + v[1] * -1, path_tiles[#path_tiles].position.y + v[2] * -1})
			if v[1] == 0 then
				expansion_vectors = {{1, 0}, {-1, 0}}
			else
				expansion_vectors = {{0, 1}, {0, -1}}
			end
			break
		end
	end
	
	if not entrance_tile then return end
	local position = entrance_tile.position
	for k, v in pairs(expansion_vectors) do
		local tile = surface.get_tile({position.x + v[1], position.y + v[2]})
		if tile.collides_with("resource-layer") then		
			table_remove(expansion_vectors, k)
		end
	end
	if #expansion_vectors == 0 then return end
	
	if not exit_tile.collides_with("resource-layer") then
		local position = exit_tile.position
		for k, v in pairs(expansion_vectors) do
			local tile = surface.get_tile({position.x + v[1], position.y + v[2]})
			if tile.collides_with("resource-layer") then		
				table_remove(expansion_vectors, k)
			end
		end
	end	
	if #expansion_vectors == 0 then return end
	if #expansion_vectors > 1 then table_shuffle_table(expansion_vectors) end
	
	local tiles = {}
	for k, v in pairs(expansion_vectors) do
		if k > max_expansion_count then break end
		for k2, path_tile in pairs(path_tiles) do
			local tile = surface.get_tile({path_tile.position.x + v[1], path_tile.position.y + v[2]})
			if tile.collides_with("resource-layer") then		
				table_insert(tiles, tile)
			end
		end		
	end

	for k, tile in pairs(tiles) do table_insert(path_tiles, tile) end
end

local function is_bridge_valid(surface, vector, room)
	local bridge_tiles = room.path_tiles
	local scan_vector
	if vector[1] == 0 then
		scan_vector = {1, 0}
	else
		scan_vector = {0, 1}
	end
	
	for _, tile in pairs(bridge_tiles) do
		for d = -5, 5, 1 do
			local p = {tile.position.x + scan_vector[1] * d, tile.position.y + scan_vector[2] * d}
			local tile = surface.get_tile(p)
			if not tile.collides_with("resource-layer") then		
				return
			end
		end
	end
	
	return true
end

local function build_bridge(surface, position)
	if math_random(1, 8) == 1 then return end
	
	local vectors = {{0, -1}, {0, 1}, {1, 0}, {-1, 0}}
	table_shuffle_table(vectors)

	local room = {}
	room.path_tiles = {}
	room.room_border_tiles = {}
	room.room_tiles = {}
	
	local a = room_spacing * 4

	for _, v in pairs(vectors) do		
		for d = 1, a, 1 do
			local p = {position.x + v[1] * d, position.y + v[2] * d}
			local tile = surface.get_tile(p)
			if not tile.collides_with("resource-layer") then 
				break
			end			
			table_insert(room.path_tiles, tile)
			if d == a then room.path_tiles = {} end
		end
		if room.path_tiles[1] then
			if is_bridge_valid(surface, v, room) then
				return room
			else
				room.path_tiles = {}
			end
		end
	end

end

function Public.get_room(surface, position, shape)
	if not shape then
		shape = "square"
	end

	local room_max = math_random(3,14)
	local room = get_room_tiles_wiggle(surface, position, room_max, shape)
			
	if room then 
		expand_path_tiles_width(surface, room)
		return room 			
	end

	local room = build_bridge(surface, position)
	if room then
		expand_path_tiles_width(surface, room)
		return room 
	end
end

function Public.draw_random_room(surface, position,shape)
	if not shape then
		shape = "square"
	end

	local room = Public.get_room(surface, position,shape)
	if not room then return end
	
	for _, tile in pairs(room.path_tiles) do
		surface.set_tiles({{name = "dirt-3", position = tile.position}}, true)
	end
	
	for _, tile in pairs(room.room_border_tiles) do
		surface.set_tiles({{name = "dirt-7", position = tile.position}}, true)
		if math_random(1, 2) == 1 then
			surface.create_entity({name = "rock-big", position = tile.position})
		end
	end
	
	for _, tile in pairs(room.room_tiles) do
		surface.set_tiles({{name = "dirt-5", position = tile.position}}, true)
	end
end

return Public
