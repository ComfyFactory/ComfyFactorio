--Cellular Automata Explosives by MewMew

--Example: cell_birth(game.player.surface.index, {x = -0, y = -64}, game.tick, {x = -0, y = -64}, 100000) --100000 = damage

--1 steel chest filled with explosives = ~1 million damage

local damage_per_explosive = 500
local damage_decay = 10
local speed = 3
local density = 1
local density_r = density * 0.5
local valid_container_types = {
	["container"] = true,
	["logistic-container"] = true,
	["car"] = true,
	["cargo-wagon"] = true	
}

local function pos_to_key(position)
	return tostring(position.x .. "_" .. position.y)
end

local function get_explosion_name(health)
	if health < 2500 then return "explosion" end
	if health < 25000 then return "big-explosion" end
	return "big-artillery-explosion"
end

local function cell_birth(surface_index, origin_position, origin_tick, position, health)
	local key = pos_to_key(position)

	--Merge cells that are overlapping.
	if global.explosion_cells[key] then
		global.explosion_cells[key].health = global.explosion_cells[key].health + health	
		return
	end

	--Spawn new cell.
	global.explosion_cells[key] = {
		surface_index = surface_index,
		origin_position = origin_position,
		origin_tick = origin_tick,
		position = {x = position.x, y = position.y},
		spawn_tick = game.tick + speed,
		health = health,
	}
end

local function grow_cell(cell)
	table.shuffle_table(global.explosion_cells_vectors)
	local radius = math.floor((game.tick - cell.origin_tick) / 9) + 2
	local positions = {}
	for i = 1, 4, 1 do
		local position = {x = cell.position.x + global.explosion_cells_vectors[i][1], y = cell.position.y + global.explosion_cells_vectors[i][2]}			
		if not global.explosion_cells[pos_to_key(position)] then
			local distance = math.sqrt((cell.origin_position.x - position.x) ^ 2 + (cell.origin_position.y - position.y) ^ 2)
			if distance < radius then
				positions[#positions + 1] = position
			end
		end	
	end
	
	if #positions == 0 then positions[#positions + 1] = {x = cell.position.x + global.explosion_cells_vectors[1][1], y = cell.position.y + global.explosion_cells_vectors[1][2]} end
	
	local new_cell_health = math.round(cell.health / #positions, 3) - damage_decay
	
	--[[
	if new_cell_health > 0 then
		global.explosion_cells_damage_dealt = global.explosion_cells_damage_dealt + damage_decay * #positions
	else
		global.explosion_cells_damage_dealt = global.explosion_cells_damage_dealt + (new_cell_health + damage_decay) * #positions
	end
	]]
	
	if new_cell_health <= 0 then return end
	
	for _, p in pairs(positions) do
		cell_birth(cell.surface_index, cell.origin_position, cell.origin_tick, p, new_cell_health)			
	end
end

local function damage_area(cell)
	local surface = game.surfaces[cell.surface_index]
	if not surface then return end
	if not surface.valid then return end
	
	if math.random(1,6) == 1 then
		surface.create_entity({name = get_explosion_name(cell.health), position = cell.position})
	end
	
	for _, e in pairs(surface.find_entities({{cell.position.x - density_r, cell.position.y - density_r},{cell.position.x + density_r, cell.position.y + density_r}})) do
		if e.valid then
			if e.health then
				if e.destructible and e.minable then
					if cell.health > e.health then				
						--global.explosion_cells_damage_dealt = global.explosion_cells_damage_dealt + e.health					
						cell.health = cell.health - e.health
						e.die()
					else				
						--global.explosion_cells_damage_dealt = global.explosion_cells_damage_dealt + cell.health					
						e.health = e.health - cell.health
						return
					end
				end
			end
		end
	end
	
	local tile = surface.get_tile(cell.position)
	if global.explosion_cells_destructible_tiles[tile.name] then
		local key = pos_to_key(tile.position)
		if not global.explosion_cells_tiles[key] then global.explosion_cells_tiles[key] = global.explosion_cells_destructible_tiles[tile.name] end
		
		if cell.health > global.explosion_cells_tiles[key] then
			--global.explosion_cells_damage_dealt = global.explosion_cells_damage_dealt + global.explosion_cells_tiles[key]
						
			cell.health = cell.health - global.explosion_cells_tiles[key]
			global.explosion_cells_tiles[key] = nil
			surface.set_tiles({{name = "landfill", position = tile.position}}, true)
		else
			--global.explosion_cells_damage_dealt = global.explosion_cells_damage_dealt + cell.health
			
			global.explosion_cells_tiles[key] = global.explosion_cells_tiles[key] - cell.health
			return
		end		
	end
	
	return true
end

local function life_cycle(cell)
	if not damage_area(cell) then return end
	grow_cell(cell)
end

local function tick(event)
	for key, cell in pairs(global.explosion_cells) do
		if cell.spawn_tick < game.tick then
			life_cycle(cell, key)
			global.explosion_cells[key] = nil
		end
	end
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	if not valid_container_types[entity.type] then return end
	
	local inventory = defines.inventory.chest
	if entity.type == "car" then inventory = defines.inventory.car_trunk end
	
	local i = entity.get_inventory(inventory)
	local amount = i.get_item_count("explosives")
	if not amount then return end
	if amount < 1 then return end
	
	cell_birth(entity.surface.index, {x = entity.position.x, y = entity.position.y}, game.tick, {x = entity.position.x, y = entity.position.y}, amount * damage_per_explosive)
end

local function on_init(surface)
	global.explosion_cells = {}
	global.explosion_cells_vectors = {{density, 0}, {density * -1, 0}, {0, density}, {0, density * -1}}
	--global.explosion_cells_damage_dealt = 0
	
	global.explosion_cells_tiles = {}
	global.explosion_cells_destructible_tiles = {
		["water"] = false,
		["deepwater"] = false,
		["out-of-map"] = false,
	}
end

local event = require 'utils.event'
event.on_init(on_init)
event.on_nth_tick(speed, tick)
event.add(defines.events.on_entity_died, on_entity_died)