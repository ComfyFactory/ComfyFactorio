-- trees multiply --  mewmew

local event = require 'utils.event'
local math_random = math.random

local vectors = {}
local r = 8
for x = r * -1, r, 0.25 do
	for y = r * -1, r, 0.25 do
		local d = math.sqrt(x ^ 2 + y ^ 2)
		if d <= r and d > 2 then
			vectors[#vectors + 1] = {x, y}
		end
	end
end
local vectors_max_index = #vectors

local immune_tiles = {
	["concrete"] = true,
	["hazard-concrete-left"] = true,
	["hazard-concrete-right"] = true,
	["refined-concrete"] = true,
	["refined-hazard-concrete-left"] = true,
	["refined-hazard-concrete-right"] = true,
	["stone-path"] = true
}

local blacklist = {
	["dead-grey-trunk"] = true
}

local function coord_string(x, y)
	str = tostring(x) .. "_"
	str = str .. tostring(y)
	return str
end

local function is_tree_valid(surface, tree)
	if not tree then return false end
	if not tree.valid then return false end
	if tree.surface.index ~= surface.index then return false end
	return true
end

local function shrink_table()
	print("Shrinking the tree table..")
	print("Old index count was " .. #global.trees_grow.raffle)
	global.trees_grow.raffle = {}
	for k, e in pairs(global.trees_grow.entities) do
		if e.valid then
			global.trees_grow.raffle[#global.trees_grow.raffle + 1] = k
		else
			global.trees_grow.entities[k] = nil
		end
	end
	print("New index count is " .. #global.trees_grow.raffle)
end

local function get_random_tree(surface)
	for a = 1, 32, 1 do
		if #global.trees_grow.raffle == 0 then return false end
		local r = math_random(1, #global.trees_grow.raffle)
		local tree_coord = global.trees_grow.raffle[r]
		if tree_coord then
			local tree = global.trees_grow.entities[tree_coord]		
			if is_tree_valid(surface, tree) then	
				return tree
			else
				global.trees_grow.raffle[r] = nil
				global.trees_grow.entities[tree_coord] = nil
			end
		end
	end
	shrink_table()
	return false
end

local function add_tree_entry(entity)
	local str = coord_string(entity.position.x, entity.position.y)
	global.trees_grow.entities[str] = entity
	global.trees_grow.raffle[#global.trees_grow.raffle + 1] = str
end

local function grow_tree(surface)
	local tree = get_random_tree(surface)
	if not tree then return false end
	
	local vector = vectors[math_random(1, vectors_max_index)]
	
	local p = surface.find_non_colliding_position("beacon", {tree.position.x + vector[1], tree.position.y + vector[2]}, 8, 8)
	if not p then return false end
	
	local tile = surface.get_tile(p)
	if immune_tiles[tile.name] then
		if math_random(1, 4) == 1 then
			surface.set_tiles({{name = tile.hidden_tile, position = p}})
			add_tree_entry(surface.create_entity({name = tree.name, position = p, force = tree.force.name}))	
		end
	else
		add_tree_entry(surface.create_entity({name = tree.name, position = p, force = tree.force.name}))
	end
		
	return true
end

local function on_chunk_generated(event)
	local surface = event.surface
	for _, e in pairs(surface.find_entities_filtered({area = event.area, type = "tree"})) do
		if not blacklist[e.name] then
			add_tree_entry(e)	
		end
	end
end

local function tick(event)
	local surface = game.players[1].surface
	for a = 1, 32, 1 do
		if grow_tree(surface) then break end
	end
end

local function on_init(event)
	global.trees_grow = {}
	global.trees_grow.entities = {}
	global.trees_grow.raffle = {}
end

event.on_init(on_init)
event.on_nth_tick(1, tick)
event.add(defines.events.on_chunk_generated, on_chunk_generated)