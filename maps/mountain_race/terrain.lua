local Public = {}

local function draw_border(surface, left_x, height)
	local tiles = {}
	local i = 1
	for x = left_x, left_x + 31, 1 do
		for y = height * -1, height - 1, 1 do
			tiles[i] = {name = "out-of-map", position = {x = x, y = y}}
			i = i + 1
		end
	end
	surface.set_tiles(tiles, true) 
end

function Public.clone_south_to_north(mountain_race)
	if game.tick < 60 then return end
	local surface = game.surfaces.nauvis
	if not surface.is_chunk_generated({mountain_race.clone_x + 2, 0}) then return end
	
	local area = {{mountain_race.clone_x * 32, 0}, {mountain_race.clone_x * 32 + 32, mountain_race.playfield_height}}
	local offset = mountain_race.playfield_height + mountain_race.border_half_width

	draw_border(surface, mountain_race.clone_x * 32, mountain_race.border_half_width)

	surface.clone_area({
		source_area = area,
		destination_area = {{area[1][1], area[1][2] - offset}, {area[2][1], area[2][2] - offset}},
		destination_surface = surface,
		--destination_force = …,
		clone_tiles = true,
		clone_entities = true,
		clone_decoratives = true,
		clear_destination_entities = true,
		clear_destination_decoratives = true,
		expand_map = true,
	})
	
	mountain_race.clone_x = mountain_race.clone_x + 1
end

function Public.draw_out_of_map_chunk(surface, left_top)
	local tiles = {}
	local i = 1
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			tiles[i] = {name = "out-of-map", position = {x = left_top.x + x, y = left_top.y + y}}
			i = i + 1
		end
	end
	surface.set_tiles(tiles, true) 
end

return Public