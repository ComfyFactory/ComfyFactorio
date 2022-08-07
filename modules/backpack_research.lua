-- backpack research -- researching mining efficiency increases your backpack capacity (inventory slots)

local Event = require 'utils.event'

local function on_research_finished(event)
    local force = event.research.force
    local toolbelt_bonus = (force.technologies['toolbelt'].researched and 10) or 0
    local prod_bonus = force.mining_drill_productivity_bonus * 100
    force.character_inventory_slots_bonus = prod_bonus + toolbelt_bonus
end

Event.add(defines.events.on_research_finished, on_research_finished)
