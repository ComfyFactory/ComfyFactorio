local Price_raffle = require 'maps.expanse.price_raffle'
local Public = {}

local price_modifiers = {
	["unit-spawner"] = -256,
	["unit"] = -16,
	["turret"] = -128,
	["tree"] = -8,
	["simple-entity"] = 2,
	["cliff"] = -128,
	["water"] = -5,
	["water-green"] = -5,
	["deepwater"] = -5,
	["deepwater-green"] = -5,
	["water-mud"] = -6,
	["water-shallow"] = -6,
}

local function get_cell_value(expanse, left_top)
	local square_size = expanse.square_size
	local value = square_size ^ 2
	value = value * 8
	
	local source_surface = game.surfaces[expanse.source_surface]
	local area = {{left_top.x, left_top.y}, {left_top.x + square_size, left_top.y + square_size}}
	local entities = source_surface.find_entities(area)
	local tiles = source_surface.find_tiles_filtered({area = area})
	
	for _, tile in pairs(tiles) do
		if price_modifiers[tile.name] then
			value = value + price_modifiers[tile.name]
		end		
	end	
	for _, entity in pairs(entities) do
		if price_modifiers[entity.type] then
			value = value + price_modifiers[entity.type]
		end
	end
	
	local distance = math.sqrt(left_top.x ^ 2 + left_top.y ^ 2)
	local value = value * (distance * 0.005)	
	local ore_modifier = distance * 0.00025
	if ore_modifier > 0.33 then ore_modifier = 0.33 end
	
	for _, entity in pairs(entities) do		
		if entity.type == "resource" then
			if entity.name == "crude-oil" then
				value = value + (entity.amount * ore_modifier * 0.01)
			else
				value = value + (entity.amount * ore_modifier)
			end
		end
	end
	
	value = math.floor(value)	
	if value < 16 then value = 16 end
	
	return value
end

local function get_left_top(expanse, position)
	local vectors = {{-1, 0}, {1, 0}, {0, 1}, {0, -1}}
	table.shuffle_table(vectors)
	
	local surface = game.surfaces.expanse
	
	local vector = false
	for _, v in pairs(vectors) do
		local tile = surface.get_tile({position.x + v[1], position.y + v[2]})
		if tile.name == "out-of-map" then
			vector = v
			break
		end
	end
	if not vector then return end
	
	local left_top = {x = position.x + vector[1], y = position.y + vector[2]}	
	left_top.x = left_top.x - left_top.x % expanse.square_size
	left_top.y = left_top.y - left_top.y % expanse.square_size
	
	return left_top
end

local function is_container_position_valid(expanse, position)
	if game.tick == 0 then return true end

	local left_top = get_left_top(expanse, position)
	if not left_top then return false end
	
	if game.surfaces.expanse.count_entities_filtered({name = "logistic-chest-requester", force = "neutral", area = {{left_top.x - 1, left_top.y - 1}, {left_top.x + expanse.square_size + 1, left_top.y + expanse.square_size + 1}}}) > 0 then 
		return false 
	end
	
	return true
end

function Public.expand(expanse, left_top)
	local source_surface = game.surfaces[expanse.source_surface]
	if not source_surface then return end
	source_surface.request_to_generate_chunks(left_top, 3)
	source_surface.force_generate_chunk_requests()
	
	local square_size = expanse.square_size
	local area = {{left_top.x, left_top.y}, {left_top.x + square_size, left_top.y + square_size}}
	local surface = game.surfaces.expanse
	
	source_surface.clone_area({
		source_area = area,
		destination_area = area,
		destination_surface = surface,
		clone_tiles = true,
		clone_entities = true,
		clone_decoratives = true,
		clear_destination_entities = false,
		clear_destination_decoratives = true,
		expand_map = true,
	})

	for _, e in pairs(source_surface.find_entities(area)) do e.destroy() end
	
	local positions = {
		{x = left_top.x + math.random(1, square_size - 2), y = left_top.y},
		{x = left_top.x, y = left_top.y + math.random(1, square_size - 2)},
		{x = left_top.x + math.random(1, square_size - 2), y = left_top.y + (square_size - 1)},
		{x = left_top.x + (square_size - 1), y = left_top.y + math.random(1, square_size - 2)},	
	}
	
	for _, position in pairs(positions) do
		if is_container_position_valid(expanse, position) then
			local e = surface.create_entity({name = "logistic-chest-requester", position = position, force = "neutral"})
			e.destructible = false
			e.minable = false
		end
	end
	
	if game.tick == 0 then
		local a = math.floor(expanse.square_size * 0.5)
		for x = 1, 3, 1 do
			for y = 1, 3, 1 do
				surface.set_tiles({{name = "water", position = {a + x, a + y - 2}}}, true)
			end
		end
		surface.create_entity({name = "crude-oil", position = {a - 3, a}, amount = 1500000})
		surface.create_entity({name = "rock-big", position = {a, a}})		
		surface.create_entity({name = "tree-0" .. math.random(1,9), position = {a, a - 1}})
		surface.spill_item_stack({a, a + 2}, {name = "small-plane", count = 1}, false, nil, false)
		surface.spill_item_stack({a + 0.5, a + 2.5}, {name = "small-plane", count = 1}, false, nil, false)
		surface.spill_item_stack({a - 0.5, a + 2.5}, {name = "small-plane", count = 1}, false, nil, false)
	end
end

local function init_container(expanse, entity)
	local left_top = get_left_top(expanse, entity.position)
	if not left_top then return end

	local cell_value = get_cell_value(expanse, left_top)

	local item_stacks = {}
	local roll_count = 2
	for _ = 1, roll_count, 1 do
		for _, stack in pairs(Price_raffle.roll(math.floor(cell_value / roll_count), 2)) do
			if not item_stacks[stack.name] then
				item_stacks[stack.name] = stack.count
			else
				item_stacks[stack.name] = item_stacks[stack.name] + stack.count
			end		
		end
	end
	
	local price = {}
	for k, v in pairs(item_stacks) do table.insert(price, {name = k, count = v}) end

	local containers = expanse.containers
	containers[entity.unit_number] = {entity = entity, left_top = left_top, price = price}	
end

function Public.set_container(expanse, entity)
	if entity.name ~= "logistic-chest-requester" then return end
	if not expanse.containers[entity.unit_number] then init_container(expanse, entity) end
	
	local container = expanse.containers[entity.unit_number]
	
	local inventory = container.entity.get_inventory(defines.inventory.chest)
	
	if not inventory.is_empty() then
		local contents = inventory.get_contents()
		if contents["small-plane"] then
			local count_removed = inventory.remove({name = "small-plane", count = 1})
			if count_removed > 0 then
				init_container(expanse, entity)
			end
		end
	end
	
	for key, item_stack in pairs(container.price) do
		local count_removed = inventory.remove(item_stack)
		container.price[key].count = container.price[key].count - count_removed
		if container.price[key].count <= 0 then
			table.remove(container.price, key)
		end
	end

	if #container.price == 0 then
		Public.expand(expanse, container.left_top)
		expanse.containers[entity.unit_number] = nil		
		if not inventory.is_empty() then
			for name, count in pairs(inventory.get_contents()) do
				entity.surface.spill_item_stack(entity.position, {name = name, count = count}, true, nil, false)
			end
		end
		if math.random(1, 4) == 1 then
			entity.surface.spill_item_stack(entity.position, {name = "small-plane", count = 1}, true, nil, false)
		end
		entity.destructible = true
		entity.die()		
		return
	end

	for slot = 1, 30, 1 do
		entity.clear_request_slot(slot)
	end

	for slot, item_stack in pairs(container.price) do
		container.entity.set_request_slot(item_stack, slot)
	end	
end

return Public