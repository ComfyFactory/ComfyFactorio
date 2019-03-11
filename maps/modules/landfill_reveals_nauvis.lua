-- placing landfill in another surface will reveal nauvis -- by mewmew

local regenerate_decoratives = true

local event = require 'utils.event'
local math_random = math.random
local table_insert = table.insert
local water_tile_whitelist = {
		["water"] = true,
		["deepwater"] = true,
		["water-green"] = true,
		["deepwater-green"] = true
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
	if not chunk then return end
	surface.destroy_decoratives({area = {{chunk.x * 32, chunk.y * 32}, {chunk.x * 32 + 32, chunk.y * 32 + 32}}})
	--surface.destroy_decoratives({{chunk.x * 32, chunk.y * 32}, {chunk.x * 32 + 32, chunk.y * 32 + 32}})
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
			decorative_names[#decorative_names+1] = k
		end
	end
	surface.regenerate_decorative(decorative_names, {chunk})
end

local function place_entity(surface, e)
	if e.type == "resource" then surface.create_entity({name = e.name, position = e.position, amount = e.amount}) return end	
	if e.type == "cliff" then surface.create_entity({name = e.name, position = e.position, force = e.force, cliff_orientation = e.cliff_orientation}) return end	
	if e.direction then surface.create_entity({name = e.name, position = e.position, force = e.force, direction = e.direction}) return end
	surface.create_entity({name = e.name, position = e.position, force = e.force})
end

local function generate_chunks(position)
	local nauvis = game.surfaces.nauvis
	local chunk = get_chunk_position(position)
	if nauvis.is_chunk_generated(chunk) then return end
	nauvis.request_to_generate_chunks(position, 1)
	nauvis.force_generate_chunk_requests()
end

local function process_tile(surface, position, old_tile, player)	
	local nauvis = game.surfaces.nauvis
	generate_chunks(position)
	local new_tile = nauvis.get_tile(position)	
	surface.set_tiles({new_tile})
	if new_tile.name == old_tile.name then
		player.insert({name = "landfill", count = 1})
		return
	end
	for _, e in pairs(nauvis.find_entities_filtered({area = {{position.x - 0, position.y - 0}, {position.x + 0.999, position.y + 0.999}}})) do
		place_entity(surface, e)				
	end
end
	
local function on_player_built_tile(event)
	if event.item.name ~= "landfill" then return end
	local surface = game.surfaces[event.surface_index]
	local player = game.players[event.player_index]
	for _, placed_tile in pairs(event.tiles) do
		if water_tile_whitelist[placed_tile.old_tile.name] then
			process_tile(surface, placed_tile.position, placed_tile.old_tile, player)			
			if regenerate_decoratives then
				if math_random(1, 4) == 1 then
					regenerate_decoratives(surface, placed_tile.position)
				end
			end
		end
	end		
end

event.add(defines.events.on_player_built_tile, on_player_built_tile)