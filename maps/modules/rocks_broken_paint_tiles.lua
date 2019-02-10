--Mining or breaking a rock paints the tiles underneath
local event = require 'utils.event'
local math_random = math.random
local insert = table.insert

local valid_entities = {
	["rock-big"] = true,
	["rock-huge"] = true,
	["sand-rock-big"] = true	
}

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
	end
end

local function on_entity_died(event)	
	if not event.entity.valid then return end
	on_player_mined_entity(event)
end

event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)