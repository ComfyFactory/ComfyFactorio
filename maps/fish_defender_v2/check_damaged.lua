local Event = require 'utils.event'
local Public = require 'maps.fish_defender_v2.table'

local function protect_market(entity, cause, final_damage_amount)
    if entity.name ~= 'market' then
        return
    end
    if cause then
        if cause.force.name == 'enemy' then
            return
        end
    end
    entity.health = entity.health + final_damage_amount
    return true
end

Event.add(
    defines.events.on_entity_damaged,
    function(event)
        local entity = event.entity
        local cause = event.cause
        local final_damage_amount = event.final_damage_amount

        if not entity then
            return
        end
        if not entity.valid then
            return
        end

        if protect_market(entity, cause, final_damage_amount) then
            return
        end

        if not cause then
            return
        end
        local explosive_bullets_unlocked = Public.get('explosive_bullets_unlocked')
        local bouncy_shells_unlocked = Public.get('bouncy_shells_unlocked')

        if cause.name ~= 'character' then
            return
        end

        if explosive_bullets_unlocked then
            if Public.explosive_bullets(event) then
                return
            end
        end
        if bouncy_shells_unlocked then
            if Public.bouncy_shells(event) then
                return
            end
        end
    end
)

return Public
