local event = require 'utils.event' 

----------share chat with player and spectator force-------------------
local function on_console_chat(event)
	if not event.message then return end	
	if not event.player_index then return end	
	local player = game.players[event.player_index] 
	
	local color = {}
	color = player.color
	color.r = color.r * 0.6 + 0.35
	color.g = color.g * 0.6 + 0.35
	color.b = color.b * 0.6 + 0.35
	color.a = 1	
	
	if player.force.name == "north" then
		game.forces.spectator.print(player.name .. " (north): ".. event.message, color)
		game.forces.player.print(player.name .. " (north): ".. event.message, color)			
	end
	if player.force.name == "south" then
		game.forces.spectator.print(player.name .. " (south): ".. event.message, color)
		game.forces.player.print(player.name .. " (south): ".. event.message, color)
	end
	
	if global.tournament_mode then return end
	
	if player.force.name == "player" then
		game.forces.north.print(player.name .. " (spawn): ".. event.message, color)
		game.forces.south.print(player.name .. " (spawn): ".. event.message, color)
		game.forces.spectator.print(player.name .. " (spawn): ".. event.message, color)
	end
	if player.force.name == "spectator" then
		game.forces.north.print(player.name .. " (spectator): ".. event.message, color)
		game.forces.south.print(player.name .. " (spectator): ".. event.message, color)
		game.forces.player.print(player.name .. " (spectator): ".. event.message, color)
	end
end

event.add(defines.events.on_console_chat, on_console_chat)
