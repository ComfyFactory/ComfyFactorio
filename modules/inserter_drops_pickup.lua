local Event = require 'utils.event'
local controllers_with_inventory = {
	[defines.controllers.character] = true,
	[defines.controllers.god] = true,
	[defines.controllers.editor] = true,
}

Event.add(defines.events.on_player_mined_entity, function(event)
	local inserter = event.entity
	if (not inserter.valid) or (inserter.type ~= "inserter") or inserter.drop_target then return end

	local item_entity = inserter.surface.find_entity("item-on-ground", inserter.drop_position)
	if item_entity then
		local player = game.get_player(event.player_index)
		if controllers_with_inventory[player.controller_type] then
			player.mine_entity(item_entity)
		end
	end
end)
