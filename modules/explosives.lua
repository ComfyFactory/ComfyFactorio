--Explosives by MewMew
--/c cell_birth(game.player.surface.index, {x = -5, y = -5}, game.tick, {x = -5, y = -5}, 100000)

local damage_decay = 8
local speed = 4
local density = 1

local destructible_tiles = {


}

local function pos_to_key(position)
	return tostring(position.x .. "_" .. position.y)
end

local function get_explosion_name(health)
	if health < 2500 then return "explosion" end
	if health < 25000 then return "big-explosion" end
	return "big-artillery-explosion"
end

function cell_birth(surface_index, origin_position, origin_tick, position, health)
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
	local radius = math.floor((game.tick - cell.origin_tick) / 18) + 3
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
	
	local new_cell_health = math.round(cell.health / #positions, 2) - damage_decay
	
	if new_cell_health > 0 then
		global.explosion_cells_damage_dealt = global.explosion_cells_damage_dealt + damage_decay * #positions
	else
		global.explosion_cells_damage_dealt = global.explosion_cells_damage_dealt + (new_cell_health + damage_decay) * #positions
	end

	if new_cell_health <= 0 then return end
	
	for _, p in pairs(positions) do
		cell_birth(cell.surface_index, cell.origin_position, cell.origin_tick, p, new_cell_health)			
	end
end

local function damage_area(cell)
	local surface = game.surfaces[cell.surface_index]
	if not surface then return end
	if not surface.valid then return end
	surface.create_entity({name = get_explosion_name(cell.health), position = cell.position})
	
	for _, e in pairs(surface.find_entities_filtered({area = {{cell.position.x - density, cell.position.y - density},{cell.position.x + density, cell.position.y + density}}})) do
		if e.valid then
			if e.health then
				if e.destructible then
					if cell.health > e.health then
					
						global.explosion_cells_damage_dealt = global.explosion_cells_damage_dealt + e.health
						
						cell.health = cell.health - e.health				
						e.die()
					else
					
						global.explosion_cells_damage_dealt = global.explosion_cells_damage_dealt + cell.health
						
						e.health = e.health - cell.health
						return
					end
				end
			end
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

local function on_init(surface)
	global.explosion_cells = {}
	global.explosion_cells_vectors = {{density, 0}, {density * -1, 0}, {0, density}, {0, density * -1}}
	global.explosion_cells_damage_dealt = 0
end

local event = require 'utils.event'
event.on_init(on_init)
event.on_nth_tick(speed, tick)
