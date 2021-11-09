local Event = require 'utils.event'

Event.add(defines.events.on_player_mined_entity, function(event)
	local inserter = event.entity
	if (not inserter.valid) or (inserter.type ~= "inserter") or inserter.drop_target then return end

	local item_entity = inserter.surface.find_entity("item-on-ground", inserter.drop_position)
	if item_entity then
		game.get_player(event.player_index).mine_entity(item_entity)
	end
end)
