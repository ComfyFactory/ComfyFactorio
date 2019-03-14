local event = require 'utils.event' 
local ai = {}

ai.send_near_biter_to_silo = function()
	if not global.rocket_silo then return end
	game.surfaces["surface"].set_multi_command({
		command={
			type=defines.command.attack,
			target=global.rocket_silo["north"],
			distraction=defines.distraction.none
			},
		unit_count = 8,
		force = "enemy",
		unit_search_distance=64
		})
		
	game.surfaces["surface"].set_multi_command({
		command={
			type=defines.command.attack,
			target=global.rocket_silo["south"],
			distraction=defines.distraction.none
			},
		unit_count = 8,
		force = "enemy",
		unit_search_distance=64
		})
end

return ai