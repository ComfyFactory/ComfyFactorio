-- enemy biters have pseudo double hp -- by mewmew

local Event = require 'utils.event'

local function on_entity_damaged(event)
    if not event.entity.valid then
        return
    end
    if math.random(1, 2) == 1 then
        return
    end
    if event.entity.type ~= 'unit' then
        return
    end
    if event.final_damage_amount > event.entity.max_health then
        return
    end
    event.entity.health = event.entity.health + event.final_damage_amount
end

Event.add(defines.events.on_entity_damaged, on_entity_damaged)
