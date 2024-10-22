local Event = require 'utils.event'

local function on_player_changed_position(event)
    if not storage.vehicle_nanobots_unlocked then
        return
    end
    local player = game.players[event.player_index]
    if not player.character then
        return
    end
    if not player.character.driving then
        return
    end
    if not player.vehicle then
        return
    end
    if not player.vehicle.valid then
        return
    end
    if player.vehicle.health == player.vehicle.max_health then
        return
    end
    player.vehicle.health = player.vehicle.health + player.vehicle.max_health * 0.005
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
