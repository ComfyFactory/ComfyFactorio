local Public = {}

local GetNoise = require "utils.get_noise"

function Public.roll_source_surface()
	local map_gen_settings = {
		["water"] = 0,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["default_enable_all_autoplace_controls"] = false,
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = false},
			["decorative"] = {treat_missing_as_default = false},
		},
		autoplace_controls = {
			["coal"] = {frequency = 0, size = 0, richness = 0},
			["stone"] = {frequency = 0, size = 0, richness = 0},
			["copper-ore"] = {frequency = 0, size = 0, richness = 0},
			["iron-ore"] = {frequency = 0, size = 0, richness = 0},
			["uranium-ore"] = {frequency = 0, size = 0, richness = 0},
			["crude-oil"] = {frequency = 0, size = 0, richness = 0},
			["trees"] = {frequency = 0, size = 0, richness = 0},
			["enemy-base"] = {frequency = 0, size = 0, richness = 0}
		},
	}
	local surface = game.create_surface("cave_miner_source", map_gen_settings)
	surface.request_to_generate_chunks({x = 0, y = 0}, 2)
	surface.force_generate_chunk_requests()
end

function Public.out_of_map(event)
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	local tiles = {}
	local i = 0
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			i = i + 1
			tiles[i] = {name = "out-of-map", position = {left_top_x + x, left_top_y + y}}
		end
	end
	event.surface.set_tiles(tiles, false)
end

function Public.reveal(surface, source_surface, position, brushsize)
	local tile = source_surface.get_tile(position)
	if tile.name == "lab-dark-1" then return end
	local tiles = {}
	local i = 0
	local brushsize_square = brushsize ^ 2
	for _, tile in pairs(source_surface.find_tiles_filtered({area = {{position.x - brushsize, position.y - brushsize}, {position.x + brushsize, position.y + brushsize}}})) do
		local tile_position = tile.position
		if tile.name ~= "lab-dark-1" and surface.get_tile(tile_position).name ~= tile.name and (position.x - tile_position.x) ^ 2 + (position.y - tile_position.y) ^ 2 < brushsize_square then
			i = i + 1
			tiles[i] = {name = tile.name, position = tile.position}
		end
	end
	surface.set_tiles(tiles, true)
	
	for _, entity in pairs(source_surface.find_entities_filtered({area = {{position.x - brushsize, position.y - brushsize}, {position.x + brushsize, position.y + brushsize}}})) do
		local entity_position = entity.position
		if (position.x - entity_position.x) ^ 2 + (position.y - entity_position.y) ^ 2 < brushsize_square then
			entity.clone({position = entity_position, surface = surface})
			entity.destroy()
		end
	end
	
	source_surface.set_tiles({{name = "lab-dark-1", position = position}}, true)
	source_surface.request_to_generate_chunks(position, 2)
end

function Public.generate_cave(event)
	local surface = event.surface
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	local seed = surface.map_gen_settings.seed
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top_x + x, y = left_top_y + y}
			local noise = GetNoise("decoratives", position, seed)
			if math.random(1, 3) > 1 and math.abs(noise) > 0.2 then surface.create_entity({name = "rock-big", position = position}) end
		end
	end
	
	local tiles = {}
	local i = 0
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			i = i + 1
			tiles[i] = {name = "dirt-7", position = {left_top_x + x, left_top_y + y}}
		end
	end
	event.surface.set_tiles(tiles, false)
	
	
end

return Public