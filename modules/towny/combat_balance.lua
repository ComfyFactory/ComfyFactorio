local Public = {}

function Public.fish(event)
	if event.item.name ~= "raw-fish" then return end
	local player = game.players[event.player_index]
	--local player_max_health = player.character.prototype.max_health + player.character_health_bonus + player.force.character_health_bonus	
	--if player.character.health >= player_max_health then return end	
	player.character.health = player.character.health - 70
end

return Public