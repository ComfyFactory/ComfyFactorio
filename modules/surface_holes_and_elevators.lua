-- switch surfaces through out-of-map holes and white tile elevators -- by mewmew
--- WIP

local event = require 'utils.event' 
local position_modifiers = {{0, -0.1}, {0, 0.1}, {0.1, 0}, {-0.1, 0}}

local function go_down()
	game.print("down")
end

local function go_up()
	game.print("up")
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	if player.character.driving == true then return end
	
	local surface = player.surface
	
	if surface.get_tile(player.position).name == "lab-white" then
		go_up()
		return
	end
	
	for _, m in pairs(position_modifiers) do
		if surface.get_tile({player.position.x + m[1], player.position.y + m[2]}).name == "out-of-map" then
			go_down()
			return
		end
	end	
end

event.add(defines.events.on_player_changed_position, on_player_changed_position)
