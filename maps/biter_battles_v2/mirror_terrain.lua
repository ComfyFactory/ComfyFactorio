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
	["east-to-none"] =  "west-to-none",
	["east-to-north"] =  "west-to-south",
	["east-to-south"] =  "west-to-north",
	["east-to-west"] =  "west-to-east",	
	["north-to-east"] =  "south-to-west",
	["north-to-none"] =  "south-to-none",
	["north-to-south"] =  "south-to-north",
	["north-to-west"] =  "south-to-east",
	["south-to-east"] =  "north-to-west",
	["south-to-none"] =  "north-to-none",
	["south-to-north"] =  "north-to-south",
	["south-to-west"] =  "north-to-east",	
	["west-to-east"] =  "east-to-west",
	["west-to-none"] =  "east-to-none",
	["west-to-north"] =  "east-to-south",
	["west-to-south"] =  "east-to-north",
	["none-to-east"] =  "none-to-west",
	["none-to-north"] =  "none-to-south",
	["none-to-south"] =  "none-to-north",
	["none-to-west"] =  "none-to-east"
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
	--local new_pos = {x = entity.position.x * -1, y = (entity.position.y * -1) - 1}
	local new_pos = {x = entity.position.x * -1, y = entity.position.y * -1}
	if entity.type == "tree" then
		local e = surface.create_entity({name = entity.name, position = new_pos, graphics_variation = entity.graphics_variation})
		e.graphics_variation = entity.graphics_variation
		--e.tree_color_index = entity.tree_color_index
		return
	end
	if entity.type == "simple-entity" then
		local e = surface.create_entity({name = entity.name, position = new_pos, direction = direction_translation[entity.direction]})
		e.graphics_variation = entity.graphics_variation
		return
	end
	if entity.type == "cliff" then	
		surface.create_entity({name = entity.name, position = new_pos, cliff_orientation = cliff_orientation_translation[entity.cliff_orientation]})
		return
	end
	if entity.type == "resource" then
		surface.create_entity({name = entity.name, position = new_pos, amount = entity.amount})
		return
	end	
	if entity.type == "unit-spawner" or entity.type == "unit" or entity.type == "turret" then
		surface.create_entity({name = entity.name, position = new_pos, direction = direction_translation[entity.direction], force = "south_biters"})
		return
	end
	if entity.name == "rocket-silo" then
		global.rocket_silo["south"] = surface.create_entity({name = entity.name, position = new_pos, direction = direction_translation[entity.direction], force = "south"})
		global.rocket_silo["south"].minable = false		
		return
	end
	if entity.name == "player" then
		return
	end
	surface.create_entity({name = entity.name, position = new_pos, direction = direction_translation[entity.direction], force = entity.force.name})
end

local function mirror_chunk(surface, chunk)		
	local chunk_area = {left_top = {x = chunk.x * 32, y = chunk.y * 32}, right_bottom = {x = chunk.x * 32 + 32, y = chunk.y * 32 + 32}}	
	if not surface.is_chunk_generated(chunk) then
		surface.request_to_generate_chunks({x = chunk_area.left_top.x - 16, y = chunk_area.left_top.y - 16}, 1)
		surface.force_generate_chunk_requests()
	end	
	for _, tile in pairs(surface.find_tiles_filtered({area = chunk_area})) do
		surface.set_tiles({{name = tile.name, position = {x = tile.position.x * -1, y = (tile.position.y * -1) - 1}}}, true)
	end	
	for _, entity in pairs(surface.find_entities_filtered({area = chunk_area})) do
		process_entity(surface, entity)
	end	
	for _, decorative in pairs(surface.find_decoratives_filtered{area=chunk_area}) do
		surface.create_decoratives{
			check_collision=false,
			decoratives={{name = decorative.decorative.name, position = {x = decorative.position.x * -1, y = (decorative.position.y * -1) - 1}, amount = decorative.amount}}
		}
	end
end

local function clear_chunk(surface, event)
	if event.area.left_top.y > 32 or event.area.left_top.x > 32 or event.area.left_top.x < -32 then 
		for _, e in pairs(surface.find_entities_filtered({area = event.area})) do
			if e.valid then
				e.destroy()
			end
		end
	else
		for _, e in pairs(surface.find_entities_filtered({area = event.area})) do
			if e.valid then
				if e.name ~= "player" then
					e.destroy()
				end
			end
		end
	end	
	surface.destroy_decoratives{area=event.area}
end

local function on_chunk_generated(event)
	if event.area.left_top.y < 0 then return end
	if event.surface.name ~= "biter_battles" then return end
	
	clear_chunk(event.surface, event)
		
	local x = ((event.area.left_top.x + 16) * -1) - 16
	local y = ((event.area.left_top.y + 16) * -1) - 16	
	local chunk = get_chunk_position({x = x, y = y})

	local delay = 30
	if not global.chunks_to_mirror[game.tick + delay] then global.chunks_to_mirror[game.tick + delay] = {} end
	global.chunks_to_mirror[game.tick + delay][#global.chunks_to_mirror[game.tick + delay] + 1] = {x = chunk.x, y = chunk.y}
	
	--mirror_chunk(game.surfaces["biter_battles"], chunk)
	--local delay = 60
	--if not global.on_tick_schedule[game.tick + delay] then global.on_tick_schedule[game.tick + delay] = {} end	
	--global.on_tick_schedule[game.tick + delay][#global.on_tick_schedule[game.tick + delay] + 1] = {
	--	func = mirror_chunk,
	--	args = {surface, {x = chunk.x, y = chunk.y}}
	--}									
end

local function mirror_map()
	for i, c in pairs(global.chunks_to_mirror) do
		if i < game.tick then
			for _, chunk in pairs(global.chunks_to_mirror[i]) do
				mirror_chunk(game.surfaces["biter_battles"], chunk)
			end
			global.chunks_to_mirror[i] = nil
		end
	end
end

event.add(defines.events.on_chunk_generated, on_chunk_generated)

return mirror_map
