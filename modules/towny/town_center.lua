local Team = require "modules.towny.team"
local Public = {}

local math_random = math.random
local table_insert = table.insert

local min_distance_to_spawn = 1
local square_min_distance_to_spawn = min_distance_to_spawn ^ 2
local town_radius = 32
local radius_between_towns = town_radius * 4

local colors = {}
local c1 = 250
local c2 = 150
local c3 = -25
for v = c1, c2, c3 do
	table.insert(colors, {0, 0, v})
end
for v = c1, c2, c3 do
	table.insert(colors, {0, v, 0})
end
for v = c1, c2, c3 do
	table.insert(colors, {v, 0, 0})
end
for v = c1, c2, c3 do
	table.insert(colors, {0, v, v})
end
for v = c1, c2, c3 do
	table.insert(colors, {v, v, 0})
end
for v = c1, c2, c3 do
	table.insert(colors, {v, 0, v})
end

local town_wall_vectors = {}
for x = town_radius * -1, town_radius, 1 do
	table_insert(town_wall_vectors, {x, town_radius})
	table_insert(town_wall_vectors, {x, town_radius * -1})
end
for y = (town_radius - 1) * -1, town_radius - 1, 1 do
	table_insert(town_wall_vectors, {town_radius, y})
	table_insert(town_wall_vectors, {town_radius * -1, y})
end

local gate_vectors_horizontal = {}
for x = -1, 1, 1 do
	table_insert(gate_vectors_horizontal, {x, town_radius})
	table_insert(gate_vectors_horizontal, {x, town_radius * -1})
end
local gate_vectors_vertical = {}
for y = -1, 1, 1 do
	table_insert(gate_vectors_vertical, {town_radius, y})
	table_insert(gate_vectors_vertical, {town_radius * -1, y})
end

local turret_vectors = {}
local turret_d = 5
table_insert(turret_vectors, {turret_d * -1, turret_d * -1})
table_insert(turret_vectors, {turret_d * 1, turret_d * 1})
table_insert(turret_vectors, {turret_d * -1, turret_d * 1})
table_insert(turret_vectors, {turret_d * 1, turret_d * -1})

local resource_vectors = {}
resource_vectors[1] = {}
for x = 7, 25, 1 do
	for y = 7, 25, 1 do	
		table_insert(resource_vectors[1], {x, y})
	end
end
resource_vectors[2] = {}
for _, vector in pairs(resource_vectors[1]) do table_insert(resource_vectors[2], {vector[1] * -1, vector[2]}) end
resource_vectors[3] = {}
for _, vector in pairs(resource_vectors[1]) do table_insert(resource_vectors[3], {vector[1] * -1, vector[2] * -1}) end
resource_vectors[4] = {}
for _, vector in pairs(resource_vectors[1]) do table_insert(resource_vectors[4], {vector[1], vector[2] * -1}) end

local market_collide_vectors = {{-1, 1},{0, 1},{1, 1},{1, 0},{1, -1}}

local clear_blacklist_types = {
	["simple-entity"] = true,
	["cliff"] = true,
}

local starter_supplies = {
	{name = "grenade", count = 3},
	{name = "stone", count = 32},
	{name = "submachine-gun", count = 1},
	{name = "land-mine", count = 4},
	{name = "iron-gear-wheel", count = 16},
	{name = "iron-plate", count = 32},
	{name = "copper-plate", count = 16},
	{name = "shotgun", count = 1},
	{name = "shotgun-shell", count = 8},
	{name = "firearm-magazine", count = 16},
}

local function draw_town_spawn(player_name)
	local market = global.towny.town_centers[player_name].market
	local position = market.position
	local surface = market.surface

	local area = {{position.x - town_radius, position.y - town_radius}, {position.x + town_radius, position.y + town_radius}}
	
	for _, e in pairs(surface.find_entities_filtered({area = area, force = "neutral"})) do
		if not clear_blacklist_types[e.type] then
			--e.destroy()
		end
	end
	
	for _, vector in pairs(gate_vectors_horizontal) do
		local p = {position.x + vector[1], position.y + vector[2]}	
		if surface.can_place_entity({name = "gate", position = p, force = player_name}) then
			surface.create_entity({name = "gate", position = p, force = player_name, direction = 2})
		end
	end
	for _, vector in pairs(gate_vectors_vertical) do
		local p = {position.x + vector[1], position.y + vector[2]}	
		if surface.can_place_entity({name = "gate", position = p, force = player_name}) then
			surface.create_entity({name = "gate", position = p, force = player_name, direction = 0})
		end
	end

	for _, vector in pairs(town_wall_vectors) do
		local p = {position.x + vector[1], position.y + vector[2]}	
		if surface.can_place_entity({name = "stone-wall", position = p, force = player_name}) then
			surface.create_entity({name = "stone-wall", position = p, force = player_name})
		end
	end
	
	for _, vector in pairs(turret_vectors) do
		local p = {position.x + vector[1], position.y + vector[2]}
		if surface.can_place_entity({name = "gun-turret", position = p, force = player_name}) then
			local turret = surface.create_entity({name = "gun-turret", position = p, force = player_name})
			turret.insert({name = "firearm-magazine", count = 16})
		end
	end
	
	local ores = {"iron-ore", "copper-ore", "stone", "coal"}
	table.shuffle_table(ores)
	
	for i = 1, 4, 1 do
		for _, vector in pairs(resource_vectors[i]) do
			local p = {position.x + vector[1], position.y + vector[2]} 
			if not surface.get_tile(p).collides_with("resource-layer") then
				surface.create_entity({name = ores[i], position = p, amount = 1500})
			end
		end
	end
	
	for _, item_stack in pairs(starter_supplies) do
		local m1 = -8 + math_random(0, 16)
		local m2 = -8 + math_random(0, 16)		
		local p = {position.x + m1, position.y + m2}
		p = surface.find_non_colliding_position("wooden-chest", p, 32, 1)
		if p then 
			local e = surface.create_entity({name = "wooden-chest", position = p, force = player_name})
			local inventory = e.get_inventory(defines.inventory.chest)
			inventory.insert(item_stack)
		end
	end
end

local function is_valid_location(surface, entity)

	for _, vector in pairs(market_collide_vectors) do
		local p = {entity.position.x + vector[1], entity.position.y + vector[2]} 
		if not surface.can_place_entity({name = "iron-chest", position = p}) then
			surface.create_entity({
				name = "flying-text",
				position = entity.position,
				text = "Position is obstructed!",
				color = {r=0.77, g=0.0, b=0.0}
			})
			return 
		end
	end

	if global.towny.size_of_town_centers > 48 then
		surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "Too many town centers on the map!",
			color = {r=0.77, g=0.0, b=0.0}
		})
		return 
	end

	if entity.position.x ^ 2 + entity.position.y ^ 2 < square_min_distance_to_spawn then
		surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "Town location is too close to spawn!",
			color = {r=0.77, g=0.0, b=0.0}
		})
		return 
	end
	
	local area = {{entity.position.x - radius_between_towns, entity.position.y - radius_between_towns}, {entity.position.x + radius_between_towns, entity.position.y + radius_between_towns}}	
	if surface.count_entities_filtered({area = area, name = "market"}) > 0 then
		surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "Town location is too close to another town center!",
			color = {r=0.77, g=0.0, b=0.0}
		})
		return
	end
		
	local area = {{entity.position.x - town_radius, entity.position.y - town_radius}, {entity.position.x + town_radius, entity.position.y + town_radius}}
	local count = 0
	for _, e in pairs(surface.find_entities_filtered({area = area})) do
		if e.force.index ~= 3 then
			if e.name == "market" then
				surface.create_entity({
					name = "flying-text",
					position = entity.position,
					text = "Town location is too close to another town center!",
					color = {r=0.77, g=0.0, b=0.0}
				})
				return
			end
			count = count + 1
		end
	end

	if count > 3 then 
		surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "Area has too many non-neutral entities!",
			color = {r=0.77, g=0.0, b=0.0}
		})
		return 
	end
	
	return true
end

function Public.set_market_health(entity, final_damage_amount)
	local town_center = global.towny.town_centers[entity.force.name]
	town_center.health = town_center.health - final_damage_amount
	local m = town_center.health / town_center.max_health
	entity.health = 150 * m
	rendering.set_text(town_center.health_text, "HP: " .. town_center.health .. " / " .. town_center.max_health)
	
end

function Public.found(event)
	local entity = event.created_entity
	if entity.force.index ~= 1 then return end
	if entity.name ~= "stone-furnace" then return end	
	
	local player = game.players[event.player_index]
	local player_name = tostring(player.name)
	
	if game.forces[player_name] then return end
	
	local surface = entity.surface
	
	if not is_valid_location(surface, entity) then
		player.insert({name = "stone-furnace", count = 1})
		entity.destroy()
		return
	end
	
	Team.add_new_force(player_name)
	
	global.towny.town_centers[player_name] = {}
	local town_center = global.towny.town_centers[player_name]
	town_center.market = surface.create_entity({name = "market", position = entity.position, force = player_name})
	town_center.max_health = 5000
	town_center.health = town_center.max_health
	town_center.color = colors[math_random(1, #colors)]
	
	town_center.health_text = rendering.draw_text{
		text = "HP: " .. town_center.health .. " / " .. town_center.max_health,
		surface = surface,
		target = town_center.market,
		target_offset = {0, -2.5},
		color = {200, 200, 200},
		scale = 1.00,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	
	town_center.town_caption = rendering.draw_text{
		text = player.name .. "'s town",
		surface = surface,
		target = town_center.market,
		target_offset = {0, -3.25},
		color = town_center.color,
		scale = 1.30,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	
	global.towny.size_of_town_centers = global.towny.size_of_town_centers + 1
	
	entity.destroy()
	
	draw_town_spawn(player_name)
	
	Team.add_player_to_town(player, town_center)
	
	player.force.set_spawn_position({x = town_center.market.position.x, y = town_center.market.position.y + 4}, surface)
	
	game.print(">> " .. player.name .. " has founded a new town!", {255, 255, 0})	
	return true
end

return Public