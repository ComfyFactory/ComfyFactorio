-- changes placed landfill tiles, adapting the new tile to adjecant tiles -- by mewmew

local regenerate_decoratives = true

local event = require 'utils.event'
local math_random = math.random
local table_insert = table.insert
local water_tile_whitelist = {
		["water"] = true,
		["deepwater"] = true,
		["water-green"] = true
	}
	
local water_tiles = {
	"water",
	"deepwater",
	"water-green"
}

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function get_chunk_position(position)
	local chunk_position = {}
	position.x = math.floor(position.x, 0)
	position.y = math.floor(position.y, 0)
	for x = 0, 31, 1 do
		if (position.x - x) % 32 == 0 then chunk_position.x = (position.x - x)  / 32 end
	end
	for y = 0, 31, 1 do
		if (position.y - y) % 32 == 0 then chunk_position.y = (position.y - y)  / 32 end
	end	
	return chunk_position
end

local function regenerate_decoratives(surface, position)
	local chunk = get_chunk_position(position)
	surface.destroy_decoratives({{chunk.x * 32, chunk.y * 32}, {chunk.x * 32 + 32, chunk.y * 32 + 32}})
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
			decorative_names[#decorative_names+1] = k
		end
	end
	surface.regenerate_decorative(decorative_names, {chunk})
end

local function is_this_a_valid_source_tile(pos, tiles)
	for _, tile in pairs(tiles) do
		if tile.position.x == pos.x and tile.position.y == pos.y then
			return false
		end
	end
	return true
end

local function place_fitting_tile(position, surface, tiles_placed)
	local tiles = {}	
	for i = 1, 64, 0.5 do
		local area = {{position.x - i, position.y - i}, {position.x + i, position.y + i}}	
		for _, found_tile in pairs(surface.find_tiles_filtered({area = area, collision_mask = "ground-tile"})) do
		
			local valid_source_tile = is_this_a_valid_source_tile(found_tile.position, tiles_placed)			
			if found_tile.name == "out-of-map" then valid_source_tile = false end
			
			if valid_source_tile then
				if found_tile.hidden_tile then
					table_insert(tiles, found_tile.hidden_tile)			
				else
					table_insert(tiles, found_tile.name)				
				end			
			end	
		end
		if #tiles > 0 then break end		
	end
	if #tiles == 0 then return false end
	tiles = shuffle(tiles)
	surface.set_tiles({{name = tiles[1], position = position}}, true)
end	
	
local function on_player_built_tile(event)
	if event.item.name ~= "landfill" then return end
	local surface = game.surfaces[event.surface_index]
	
	for _, placed_tile in pairs(event.tiles) do
		if water_tile_whitelist[placed_tile.old_tile.name] then
			place_fitting_tile(placed_tile.position, surface, event.tiles)
			if regenerate_decoratives then
				if math_random(1, 4) == 1 then
					regenerate_decoratives(surface, placed_tile.position)
				end
			end
		end
	end		
end

event.add(defines.events.on_player_built_tile, on_player_built_tile)