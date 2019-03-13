-- Mirrored Terrain for Biter Battles -- by MewMew
local event = require 'utils.event' 

local direction_translation = {
	[0] = 4,
	[1] = 5,
	[2] = 6,
	[3] = 7,
	[4] = 0,
	[5] = 1,
	[6] = 2,
	[7] = 3
}

local cliff_orientation_translation = {
	["west_to_east"] =  "east_to_west",
	["north_to_south"] =  "south_to_north",
	["east_to_west"] =  "west_to_east",
	["south_to_north"] =  "north_to_south",
	["west_to_north"] =  "east_to_south",
	["north_to_east"] =  "south_to_west",
	["east_to_south"] =  "west_to_north",
	["south_to_west"] =  "north_to_east",	
	["west_to_south"] =  "east_to_north",
	["north_to_west"] =  "south_to_east",
	["east_to_north"] =  "west_to_south",
	["south_to_east"] =  "north_to_west",
	["west_to_none"] =  "none_to_east",
	["none_to_east"] =  "west_to_none",
	["north_to_none"] =  "none_to_south",
	["none_to_south"] =  "north_to_none",
	["east_to_none"] =  "none_to_west",
	["none_to_west"] =  "east_to_none",
	["south_to_none"] =  "none_to_north",
	["none_to_north"] =  "south_to_none"
}

local function get_chunk_position(position)
	local chunk_position = {}
	position.x = math.floor(position.x)
	position.y = math.floor(position.y)
	for x = 0, 31, 1 do
		if (position.x - x) % 32 == 0 then chunk_position.x = (position.x - x)  / 32 end
	end
	for y = 0, 31, 1 do
		if (position.y - y) % 32 == 0 then chunk_position.y = (position.y - y)  / 32 end
	end	
	return chunk_position
end

local function process_entity(surface, entity)
	local new_pos = {x = entity.position.x * -1, y = entity.position.y * -1}
	if entity.type == "cliff" then
		surface.create_entity({name = entity.name, position = new_pos, cliff_orientation = cliff_orientation_translation[entity.cliff_orientation]})
		return
	end
	if entity.type == "resource" then
		surface.create_entity({name = entity.name, position = new_pos, amount = entity.amount})
		return
	end
	if entity.name == "player" then
		return
	end
	surface.create_entity({name = entity.name, position = new_pos, direction = direction_translation[entity.direction], force = entity.force.name})
end

local function mirror_chunk(surface, chunk_area, chunk_position)
	if not surface then return end
	if not chunk_area then return end
	if not chunk_position then return end
	if not surface.is_chunk_generated(chunk_position) then
		surface.request_to_generate_chunks({x = chunk_area.left_top.x - 16, y = chunk_area.left_top.y - 16}, 1)
		surface.force_generate_chunk_requests()
	end
	for _, tile in pairs(surface.find_tiles_filtered({area = chunk_area})) do
		surface.set_tiles({{name = tile.name, position = {x = tile.position.x * -1, y = tile.position.y * -1}}}, true)
	end	
	for _, entity in pairs(surface.find_entities_filtered({area = chunk_area})) do
		process_entity(surface, entity)
	end
end

local function on_chunk_generated(event)
	if event.area.left_top.y < 0 then return end
	local surface = event.surface
	
	if event.area.left_top.y > 32 or event.area.left_top.x > 32 or event.area.left_top.x < -32 then 
		for _, e in pairs(surface.find_entities_filtered({area = event.area})) do
			e.destroy()
		end
	else
		for _, e in pairs(surface.find_entities_filtered({area = event.area})) do
			if e.name ~= "player" then
				e.destroy()
			end
		end
	end
		
	local x = ((event.area.left_top.x + 16) * -1) - 16
	local y = ((event.area.left_top.y + 16) * -1) - 16	
	local mirror_chunk_area = {left_top = {x = x, y = y}, right_bottom = {x = x + 32, y = y + 32}}
		
	if not global.on_tick_schedule[game.tick + 1] then global.on_tick_schedule[game.tick + 1] = {} end	
	global.on_tick_schedule[game.tick + 1][#global.on_tick_schedule[game.tick + 1] + 1] = {
		func = mirror_chunk,
		args = {surface, mirror_chunk_area, get_chunk_position({x = x, y = y})}
	}										
end

event.add(defines.events.on_chunk_generated, on_chunk_generated)
