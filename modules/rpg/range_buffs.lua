local Public = require 'modules.rpg.table'
local Event = require 'utils.event'

local function on_entity_damaged(event)
    local enable_range_buffs = Public.get_range_buffs()
    if not enable_range_buffs then
        return
    end

    local cause = event.cause
    if not cause then
        return
    end
    if not cause.valid then
        return
    end
    if cause.name ~= 'character' then
        return
    end
    local damage_type = event.damage_type
    if damage_type.name ~= 'physical' then
        return
    end

    local player = cause
    if player.shooting_state.state == defines.shooting.not_shooting then
        return
    end
    local weapon = player.get_inventory(defines.inventory.character_guns)[player.selected_gun_index]
    local ammo = player.get_inventory(defines.inventory.character_ammo)[player.selected_gun_index]
    if not weapon.valid_for_read or not ammo.valid_for_read then
        return
    end
    local p = cause.player
    if not (p and p.valid) then
        return
    end
    local modifier = Public.get_range_modifier(p)
    if ammo.name ~= 'firearm-magazine' and ammo.name ~= 'piercing-rounds-magazine' and ammo.name ~= 'uranium-rounds-magazine' then
        return
    end
    local entity = event.entity
    if not entity.valid then
        return
    end

    local final_damage_amount = event.final_damage_amount
    entity.damage(final_damage_amount * modifier, player.force, 'impact', player)
end

Event.add(defines.events.on_entity_damaged, on_entity_damaged)

return Public
