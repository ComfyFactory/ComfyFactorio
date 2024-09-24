--Flamethrower Turret Nerf
local function on_research_finished(event)
    local research = event.research
    local force_name = research.force.name
    if research.name == 'military' then
        if not storage.flamethrower_damage then
            storage.flamethrower_damage = {}
        end
        storage.flamethrower_damage[force_name] = -0.50
        game.forces[force_name].set_turret_attack_modifier('flamethrower-turret', storage.flamethrower_damage[force_name])
        game.forces[force_name].set_ammo_damage_modifier('flamethrower', storage.flamethrower_damage[force_name])
    end

    if string.sub(research.name, 0, 18) == 'refined-flammables' then
        storage.flamethrower_damage[force_name] = storage.flamethrower_damage[force_name] + 0.10
        game.forces[force_name].set_turret_attack_modifier('flamethrower-turret', storage.flamethrower_damage[force_name])
        game.forces[force_name].set_ammo_damage_modifier('flamethrower', storage.flamethrower_damage[force_name])
    end
end

local event = require 'utils.event'
event.add(defines.events.on_research_finished, on_research_finished)
