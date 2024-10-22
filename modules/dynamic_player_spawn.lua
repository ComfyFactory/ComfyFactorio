-- this automatically sets player's force spawn point to where a lot of buildings are

local Event = require 'utils.event'

local valid_types = {'boiler', 'furnace', 'generator', 'offshore-pump', 'lab', 'assembling-machine'}

local function on_built_entity(event)
    if not event.entity.valid then
        return
    end
    local player = game.players[event.player_index]
    local area = {{event.entity.position.x - 12, event.entity.position.y - 12}, {event.entity.position.x + 12, event.entity.position.y + 12}}
    if player.surface.count_entities_filtered({area = area, force = player.force, type = valid_types}) > 12 then
        player.force.set_spawn_position(player.position, player.surface)
    end
end

Event.add(defines.events.on_built_entity, on_built_entity)
