local Team = require "modules.towny.team"
local Public = {}

local table_insert = table.insert

local min_distance_to_spawn = 1
local square_min_distance_to_spawn = min_distance_to_spawn ^ 2
local town_radius = 32

local town_wall_vectors = {}
for x = -32, 32, 1 do
	table_insert(town_wall_vectors, {x, 32})
	table_insert(town_wall_vectors, {x, -32})
end
for y = -31, 31, 1 do
	table_insert(town_wall_vectors, {32, y})
	table_insert(town_wall_vectors, {-32, y})
end

local clear_blacklist_types = {
	["simple-entity"] = true,
	["tree"] = true,
	["cliff"] = true,
}

local function draw_town_spawn(player_name)
	local market = global.towny.town_centers[player_name]
	local position = market.position
	local surface = market.surface

	local area = {{position.x - town_radius, position.y - town_radius}, {position.x + town_radius, position.y + town_radius}}
	
	for _, e in pairs(surface.find_entities_filtered({area = area, force = "neutral"})) do
		if not clear_blacklist_types[e.type] then
			e.destroy()
		end
	end

	for _, vector in pairs(town_wall_vectors) do
		local p = {position.x + vector[1], position.y + vector[2]}
		if surface.can_place_entity({name = "stone-wall", position = p, force = player_name}) then
			surface.create_entity({name = "stone-wall", position = p, force = player_name})
		end
	end
end

local function is_valid_location(surface, entity)
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

function Public.found(event)
	local entity = event.created_entity
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
	
	global.towny.town_centers[player_name] = surface.create_entity({name = "market", position = entity.position, force = player_name})
	global.towny.size_of_town_centers = global.towny.size_of_town_centers + 1
	
	entity.destroy()
	
	draw_town_spawn(player_name)
	
	player.force = game.forces[player_name]
	game.print(">> " .. player.name .. " has founded a new town!", {255, 255, 0})
	
	return true
end

return Public