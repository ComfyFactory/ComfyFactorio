local Event = require 'utils.event'

local function on_research_finished(event)
    local research = event.research
    if string.sub(research.name, 0, 26) ~= 'physical-projectile-damage' then
        return
    end
    local multiplier = 4
    if storage.shotgun_shell_damage_research_multiplier then
        multiplier = storage.shotgun_shell_damage_research_multiplier
    end

    local modifier = game.forces[research.force.name].get_ammo_damage_modifier('shotgun-shell')

    local proto = prototypes.technology[research.name]

    modifier = modifier - proto.effects[3].modifier
    modifier = modifier + proto.effects[3].modifier * multiplier

    game.forces[research.force.name].set_ammo_damage_modifier('shotgun-shell', modifier)
end

Event.add(defines.events.on_research_finished, on_research_finished)
