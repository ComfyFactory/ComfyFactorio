local Public = {}

function Public.fish(event)
	if event.item.name ~= "raw-fish" then return end
	local player = game.players[event.player_index]
	player.character.health = player.character.health - 80
end

return Public