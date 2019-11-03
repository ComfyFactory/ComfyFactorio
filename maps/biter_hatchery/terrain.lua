local function get_replacement_tile(surface, position)
	for i = 1, 128, 1 do
		local vectors = {{0, i}, {0, i * -1}, {i, 0}, {i * -1, 0}}
		table.shuffle_table(vectors)
		for k, v in pairs(vectors) do
			local tile = surface.get_tile(position.x + v[1], position.y + v[2])
			if not tile.collides_with("resource-layer") then return tile.name end
		end
	end
	return "grass-1"
end

local function combat_area(event)
	local surface = event.surface
	for _, tile in pairs(surface.find_tiles_filtered({area = event.area})) do
		if tile.name == "water" or tile.name == "deepwater" then
			surface.set_tiles({{name = get_replacement_tile(surface, tile.position), position = tile.position}}, true)
		end
		if tile.position.x >= -4 and tile.position.x <= 4 then
			surface.set_tiles({{name = "water-shallow", position = tile.position}}, true)
		end
	end
	for _, entity in pairs(surface.find_entities_filtered({type = {"resource", "cliff"}, area = event.area})) do
		entity.destroy()
	end	
end

local function on_chunk_generated(event)
	local left_top = event.area.left_top
	if left_top.y >= 96 then return end
	if left_top.y < -96 then return end
	
	if left_top.x >= -160 and left_top.x < 160 then combat_area(event) end

	if left_top.x > 512 then return end
	if left_top.x < -512 then return end
	if left_top.y > 512 then return end
	if left_top.y < -512 then return end
	
	game.forces.west.chart(event.surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}})
	game.forces.east.chart(event.surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}})
end

local event = require 'utils.event'
event.add(defines.events.on_chunk_generated, on_chunk_generated)