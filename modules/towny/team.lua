local Public = {}

function Public.add_new_force(force_name)
	game.create_force(force_name)
	
	game.forces.player.set_cease_fire(force_name, true)
	game.forces[force_name].set_cease_fire('player', true)
end

function Public.kill_force(force_name)
	local force = game.forces[force_name]
	local market = global.towny.town_centers[force_name].market	
	local surface = market.surface
	
	surface.create_entity({name = "big-artillery-explosion", position = market.position})
	
	for _, player in pairs(force.players) do
		if player.character then player.character.die() end
		player.force = game.forces.player
	end

	for _, e in pairs(surface.find_entities_filtered({force = force_name})) do e.active = false end

	game.merge_forces(force_name, "neutral")
	
	global.towny.town_centers[force_name] = nil
	global.towny.size_of_town_centers = global.towny.size_of_town_centers - 1
	
	game.print(">> " .. force_name .. "'s town has fallen!", {255, 255, 0})	
end

return Public