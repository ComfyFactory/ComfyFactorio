--Mining or breaking a rock paints the tiles underneath
local event = require 'utils.event'
local math_random = math.random
local insert = table.insert

local valid_entities = {
	["rock-big"] = true,
	["rock-huge"] = true,
	["sand-rock-big"] = true	
}

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

local coords = {{x = 0, y = 0},{x = -1, y = -1},{x = 1, y = -1},{x = 0, y = -1},{x = -1, y = 0},{x = -1, y = 1},{x = 0, y = 1},{x = 1, y = 1},{x = 1, y = 0}}
local function on_player_mined_entity(event)
	local entity = event.entity
	if valid_entities[entity.name] then
		local tiles = {}
		for _, p in pairs(coords) do
			local pos = {x = entity.position.x + p.x, y = entity.position.y + p.y}
			local tile = entity.surface.get_tile(pos)
			if not tile.collides_with("player-layer") then
				insert(tiles, {name = "dirt-3", position = pos})
			end			
		end
		if #tiles == 0 then return end		
		entity.surface.set_tiles(tiles, true)
		if math_random(1,4) == 1 then regenerate_decoratives(entity.surface, entity.position) end
	end
end

local function on_entity_died(event)	
	if not event.entity.valid then return end
	on_player_mined_entity(event)
end

event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)