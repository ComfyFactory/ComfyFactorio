local Public = {}

function Public.spawn_player(player)
	if player.character then return end	
	player.create_character()
	player.teleport({0,0}, player.surface)
end
	
return Public