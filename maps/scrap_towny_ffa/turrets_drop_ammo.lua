local Event = require 'utils.event'
local Compat = require 'utils.functions.factorio_compat'

local math_random = math.random
local math_min = math.min

local function on_entity_died(event)
    local entity = event.entity
    local surface = entity.surface
    if entity.type == 'ammo-turret' and entity.force.name == 'enemy' then
        local inv = entity.get_inventory(defines.inventory.turret_ammo)
        if not inv then
            return
        end
        local min = math_min(inv.get_item_count('piercing-rounds-magazine'), 20)
        if min > 0 then
            Compat.spill_item_stack(surface, { position = entity.position, stack = { name = 'piercing-rounds-magazine', count = math_random(1, min) }, enable_looted = true })
        end
    end
end

Event.add(defines.events.on_entity_died, on_entity_died)
