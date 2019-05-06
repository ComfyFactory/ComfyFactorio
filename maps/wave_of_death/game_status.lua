local game_status = {}

local function create_victory_gui(winning_lane)
	for _, player in pairs(game.connected_players) do
		local frame = player.gui.left.add {type = "frame", name = "victory_gui", direction = "vertical", caption = "Lane " .. winning_lane .. " has won the game!! ^_^" }
		frame.style.font = "heading-1"
		frame.style.font_color = {r = 0, g = 220, b = 220}
	end	
end

game_status.restart_server = function()
	if not global.server_restart_timer then return end
	global.server_restart_timer = global.server_restart_timer - 5
	if global.server_restart_timer == 120 then return end
	if global.server_restart_timer == 0 then
		game.print("Map is restarting!", {r=0.22, g=0.88, b=0.22})
		local message = 'Map is restarting! '
		server_commands.to_discord_bold(table.concat{'*** ', message, ' ***'})
		server_commands.start_scenario('wave_of_death')
		global.server_restart_timer = nil
		return
	end
	if global.server_restart_timer % 30 == 0 then
		game.print("Map will restart in " .. global.server_restart_timer .. " seconds!", {r=0.22, g=0.88, b=0.22})		
	end
end

game_status.has_lane_lost = function(event)
	if event.entity.name ~= "loader" then return end
	local lane_number = tonumber(event.entity.force.name)
	global.wod_lane[lane_number].game_lost = true
	game.forces[lane_number].set_spawn_position({x = 32, y = 0}, event.entity.surface)
	
	event.entity.surface.create_entity({
		name = "atomic-rocket",	
		position = event.entity.position,
		force = "enemy",
		source = event.entity.position,
		target = event.entity.position,
		max_range = 1, 
		speed = 1
	})
	
	for _, player in pairs(game.forces[lane_number].connected_players) do
		if player.character then
			player.character.die()
		end
	end
	game.print(">> Lane " .. lane_number .. " has been defeated!", {r = 120, g = 60, b = 0})
	
	--determine winner and restart the server
	local lanes_alive = 0
	for i = 1, 4, 1 do
		if global.wod_lane[i].game_lost == false then
			lanes_alive = lanes_alive + 1
		end
	end
	if lanes_alive ~= 1 then return end
	for i = 1, 4, 1 do
		if global.wod_lane[i].game_lost == true then
			game.print(">> Lane " .. i .. " has won the game!!", {r = 0, g = 220, b = 220})
			global.server_restart_timer = 120
		end
	end	 
end

return game_status
