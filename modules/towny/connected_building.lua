local Public = {}

local connection_radius = 3

local function is_entity_isolated(surface, entity)
	local position_x = entity.position.x
	local position_y = entity.position.y
	local area = {{position_x - connection_radius, position_y - connection_radius}, {position_x + connection_radius, position_y + connection_radius}}
	local count = 0
	
	for _, e in pairs(surface.find_entities_filtered({area = area, force = entity.force.name})) do
		if game.entity_prototypes[e.name] and game.recipe_prototypes[e.name] or e.name == "market" then
			count = count + 1
			if count > 1 then return end
		end
	end
	
	return true
end

local function refund_entity(event)
	local entity_name = event.created_entity.name 

	if event.player_index then 
		game.players[event.player_index].insert({name = entity_name, count = 1})
		return 
	end	
	
	if event.robot then
		local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
		inventory.insert({name = entity_name, count = 1})
		return
	end
end

function Public.prevent_isolation(event)
	local entity = event.created_entity
	if not entity.valid then return end
	local surface = event.created_entity.surface
	
	if is_entity_isolated(surface, entity) then
		refund_entity(event)
		surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "Building is not connected to the town!",
			color = {r=0.77, g=0.0, b=0.0}
		})
		entity.destroy()
	end	
end

return Public