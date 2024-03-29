local Event = require 'utils.event'
local Public = require 'maps.fish_defender_v2.table'

local radius = 20

local whitelist = {
    ['defender'] = 'explosive-cannon-projectile',
    ['distractor'] = 'explosive-uranium-cannon-projectile',
    ['destroyer'] = 'explosive-uranium-cannon-projectile'
}

local function on_entity_died(event)
    local trapped_capsules_unlocked = Public.get('trapped_capsules_unlocked')
    if not trapped_capsules_unlocked then
        return
    end

    local entity = event.entity
    if not entity.valid then
        return
    end

    if not whitelist[entity.name] then
        return
    end

    local valid_targets = {}
    local position = entity.position

    for _, e in pairs(
        entity.surface.find_entities_filtered(
            {
                area = {{position.x - radius, position.y - radius}, {position.x + radius, position.y + radius}},
                force = 'enemy'
            }
        )
    ) do
        if e.health then
            local distance_from_center = math.sqrt((e.position.x - position.x) ^ 2 + (e.position.y - position.y) ^ 2)
            if distance_from_center <= radius then
                valid_targets[#valid_targets + 1] = e
            end
        end
    end

    if not valid_targets[1] then
        return
    end

    entity.surface.create_entity(
        {
            name = whitelist[entity.name],
            position = position,
            force = 'player',
            source = position,
            target = valid_targets[math.random(1, #valid_targets)].position,
            max_range = 20,
            speed = 0.1
        }
    )
end

Event.add(defines.events.on_entity_died, on_entity_died)

return Public
