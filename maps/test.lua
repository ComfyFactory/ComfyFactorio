local event = require 'utils.event' 

local function on_player_joined_game(event)	
	
	game.print("Hello")
	
end

event.add(defines.events.on_player_joined_game, on_player_joined_game)