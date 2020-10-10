local Public = {}

function Public.spawn_player(player)
	if player.character then return end
	local surface = player.surface
	player.create_character()
	local position		
	position = surface.find_non_colliding_position("character", player.force.get_spawn_position(surface), 48, 1)
	if not position then position = player.force.get_spawn_position(surface) end	
	player.teleport(position, surface)
end

function Public.set_mining_speed(cave_miner, force)
	force.manual_mining_speed_modifier = -0.25 + cave_miner.pickaxe_boost_per_level * cave_miner.pickaxe_tier	
	return force.manual_mining_speed_modifier
end

return Public