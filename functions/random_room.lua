local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local math_random = math.random

local room_spacing = 2

local room_sizes = {}
for a = 3, 15, 2 do
	table_insert(room_sizes, a)
end
local size_of_room_sizes = #room_sizes

local function scan_direction(surface, position, vector, room_radius)
	local valid_tile_count = 0
		
	for d = 1, room_radius * 2 + room_spacing * 2, 1 do
		local p = {position.x + vector[1] * d, position.y + vector[2] * d}
		local tile = surface.get_tile(p)
		if not tile.collides_with("resource-layer") then 
			return false
		end
	end
	
	local a = room_radius + room_spacing * 2 - 1
	local b = room_radius + room_spacing
	
	local room_center_position = {x = position.x + vector[1] * a, y = position.y + vector[2] * a}
	
	local search_area = {
		{x = room_center_position.x - b, y = room_center_position.y - b},
		{x = room_center_position.x + b, y = room_center_position.y + b}
	}
	
	local tiles = surface.find_tiles_filtered({area = search_area})
	for _, tile in pairs(tiles) do
		if not tile.collides_with("resource-layer") then 
			return false
		end
	end
	
	local room = {}
	
	local room_area = {
		left_top = {x = room_center_position.x - room_radius, y = room_center_position.y - room_radius},
		right_bottom = {x = room_center_position.x + room_radius, y = room_center_position.y + room_radius}	
	}
	local left_top = room_area.left_top
	local right_bottom = room_area.right_bottom
	
	room.room_tiles = surface.find_tiles_filtered({area = room_area})
	
	room.path_tiles = {}
	for d = 1, room_spacing, 1 do
		local p = {position.x + vector[1] * d, position.y + vector[2] * d}
		local tile = surface.get_tile(p)
		table_insert(room.path_tiles, tile)
	end

	room.room_border_tiles = {}
	local t = room.room_border_tiles
	for d = 1, room_radius * 2, 1 do
		table_insert(t, surface.get_tile({left_top.x + d, left_top.y}))
		table_insert(t, surface.get_tile({left_top.x, left_top.y + d}))
		table_insert(t, surface.get_tile({right_bottom.x - d, right_bottom.y}))
		table_insert(t, surface.get_tile({right_bottom.x, right_bottom.y - d}))
	end
	table_insert(t, surface.get_tile(left_top))
	table_insert(t, surface.get_tile(right_bottom))
	table_insert(t, surface.get_tile({left_top.x + room_radius * 2, left_top.y + room_radius * 2}))
	table_insert(t, surface.get_tile({right_bottom.x - (room_radius * 2), right_bottom.y - (room_radius * 2)}))

	return room
end

local function get_room_tiles(surface, position, room_radius)
	local vectors = {{0, -1}, {0, 1}, {1, 0}, {-1, 0}}
	table_shuffle_table(vectors)

	for _, v in pairs(vectors) do
		local room = scan_direction(surface, position, v, room_radius)
		if room then 
			return room
		end
	end	
end

local function get_room(surface, position)
	local room_radius = room_sizes[math_random(1, size_of_room_sizes)]

	local room = get_room_tiles(surface, position, room_radius)

	return room
end

function draw_random_room(surface, position)
	local room = get_room(surface, position)
	if not room then return end
	
	for _, tile in pairs(room.room_tiles) do
		surface.set_tiles({{name = "grass-1", position = tile.position}}, true)
	end
	
	for _, tile in pairs(room.path_tiles) do
		surface.set_tiles({{name = "dirt-1", position = tile.position}}, true)
	end
	
	for _, tile in pairs(room.room_border_tiles) do
		surface.set_tiles({{name = "concrete", position = tile.position}}, true)
		if math_random(1, 4) == 1 then
			surface.create_entity({name = "stone-wall", position = tile.position, force = "player"})
		end
	end
end