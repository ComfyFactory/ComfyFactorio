-- trees multiply --  mewmew

local event = require 'utils.event'
local math_random = math.random

local vectors = {}
local r = 8
for x = r * -1, r, 0.25 do
	for y = r * -1, r, 0.25 do
		if math.sqrt(x ^ 2 + y ^ 2) <= r then
			vectors[#vectors + 1] = {x, y}
		end
	end
end

local immune_tiles = {
	["concrete"] = true,
	["hazard-concrete-left"] = true,
	["hazard-concrete-right"] = true,
	["refined-concrete"] = true,
	["refined-hazard-concrete-left"] = true,
	["refined-hazard-concrete-right"] = true,
	["stone-path"] = true
}

local function get_random_chunk_area(surface)
	local p = surface.get_random_chunk()
	if not p then return end
	local area = {{p.x * 32, p.y * 32}, {p.x * 32 + 32, p.y * 32 + 32}}
	return area
end

local function grow_trees(surface)
	local trees = surface.find_entities_filtered({type = "tree", area = get_random_chunk_area(surface)})
	if not trees[1] then return false end
	
	for a = 1, math_random(1, 6), 1 do
		local tree = trees[math_random(1, #trees)]
		local vector = vectors[math_random(1, #vectors)]
		
		local p = surface.find_non_colliding_position("car", {tree.position.x + vector[1], tree.position.y + vector[2]}, 16, 0.5)
		if not p then return false end
		
		local tile = surface.get_tile(p)
		if immune_tiles[tile.name] then
			if math_random(1, 4) == 1 then
				surface.set_tiles({{name = tile.hidden_tile, position = p}})
				surface.create_entity({name = tree.name, position = p, force = tree.force.name})
			end
		else
			surface.create_entity({name = tree.name, position = p, force = tree.force.name})
		end
	end
	
	return true
end

local function tick(event)
	local surface = game.players[1].surface
	
	for a = 1, 16, 1 do
		if grow_trees(surface) then break end
	end
	
end

event.on_nth_tick(3, tick)
event.add(defines.events.on_entity_damaged, on_entity_damaged)