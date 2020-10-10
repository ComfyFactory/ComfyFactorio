local Constants = require 'maps.cave_miner_v2.constants'

local Public = {}

function Public.spawn_player(player)
	if not player.character then
		player.create_character()
	end
	
	local surface = player.surface	
	local position		
	position = surface.find_non_colliding_position("character", player.force.get_spawn_position(surface), 48, 1)
	if not position then position = player.force.get_spawn_position(surface) end	
	player.teleport(position, surface)
	
	for name, count in pairs(Constants.starting_items) do
		player.insert({name = name, count = count})
	end
end

function Public.set_mining_speed(cave_miner, force)
	force.manual_mining_speed_modifier = cave_miner.pickaxe_tier * 0.25
	return force.manual_mining_speed_modifier
end

return Public