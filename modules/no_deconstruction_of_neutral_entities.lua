local event = require 'utils.event' 

local function on_marked_for_deconstruction(event)	
	if event.entity.force.name ~= "neutral" then return end
	if event.entity.name == "item-on-ground" then return end
	event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
end
	
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)