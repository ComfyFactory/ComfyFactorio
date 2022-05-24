local Public = {}

local function on_player_driving_changed_state(event)
	local player = game.players[event.player_index]
	if not player or not player.valid then
		return
	end
	local vehicle = player.vehicle
	if vehicle and vehicle.valid then
		-- player entered a vehicle
		if vehicle.name == 'locomotive' or vehicle.name == 'cargo-wagon' or vehicle.name == 'fluid-wagon' then
			vehicle.force = 'neutral'
		else
			-- includes cars, tanks and artillery-wagons
			vehicle.force = player.force.name
		end

	else
		-- player exited a vehicle
		vehicle = event.entity
		vehicle.force = 'neutral'
	end
end


local Event = require 'utils.event'
Event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)

return Public