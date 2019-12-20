local Public = {}

local connection_radius = 7

local entity_type_whitelist = {
	["accumulator"] = true,
	["ammo-turret"] = true,
	["arithmetic-combinator"] = true,
	["artillery-turret"] = true,
	["assembling-machine"] = true,
	["boiler"] = true,
	["constant-combinator"] = true,
	["container"] = true,
	["curved-rail"] = true,
	["decider-combinator"] = true,
	["electric-pole"] = true,
	["electric-turret"] = true,
	["fluid-turret"] = true,
	["furnace"] = true,
	["gate"] = true,
	["generator"] = true,
	["heat-interface"] = true,
	["heat-pipe"] = true,
	["infinity-container"] = true,
	["infinity-pipe"] = true,
	["inserter"] = true,
	["lamp"] = true,
	["loader"] = true,
	["logistic-container"] = true,
	["market"] = true,
	["mining-drill"] = true,
	["offshore-pump"] = true,
	["pipe"] = true,
	["pipe-to-ground"] = true,
	["programmable-speaker"] = true,
	["pump"] = true,
	["radar"] = true,
	["rail-chain-signal"] = true,
	["rail-signal"] = true,
	["reactor"] = true,
	["roboport"] = true,
	["rocket-silo"] = true,
	["solar-panel"] = true,
	["splitter"] = true,
	["storage-tank"] = true,
	["straight-rail"] = true,
	["train-stop"] = true,
	["transport-belt"] = true,
	["underground-belt"] = true,
	["wall"] = true,
}

local function is_entity_isolated(surface, entity)
	local position_x = entity.position.x
	local position_y = entity.position.y
	local area = {{position_x - connection_radius, position_y - connection_radius}, {position_x + connection_radius, position_y + connection_radius}}
	local count = 0
	
	for _, e in pairs(surface.find_entities_filtered({area = area, force = entity.force.name})) do
		if entity_type_whitelist[e.type] then
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
	if entity.force.index == 1 then return end
	if not entity_type_whitelist[entity.type] then return end
	local surface = event.created_entity.surface
	
	if is_entity_isolated(surface, entity) then
		refund_entity(event)
		surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "Building is not connected to town!",
			color = {r=0.77, g=0.0, b=0.0}
		})
		entity.destroy()
		return true
	end	
end

local square_min_distance_to_spawn = 96 ^ 2

function Public.protect_spawn(event)
	local entity = event.created_entity
	if not entity.valid then return end
	if entity.force.index == 1 then return end
	if not entity_type_whitelist[entity.type] then return end
	if entity.position.x ^ 2 + entity.position.y ^ 2 > square_min_distance_to_spawn then return end
	refund_entity(event)
	entity.surface.create_entity({
		name = "flying-text",
		position = entity.position,
		text = "Building too close to spawn!",
		color = {r=0.77, g=0.0, b=0.0}
	})
	entity.destroy()
end

return Public