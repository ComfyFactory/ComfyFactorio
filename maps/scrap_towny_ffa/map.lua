local Public = {}

function Public.disable_world_map(player)
	player.map_view_settings = {
		["show-player-names"] = false,
	}
	player.show_on_map = false
	player.game_view_settings.show_minimap = false
end

function Public.enable_world_map(player)
	player.map_view_settings = {
		["show-player-names"] = true,
	}
	player.show_on_map = true
	player.game_view_settings.show_minimap = true
end

return Public