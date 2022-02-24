local Event = require 'utils.event'
local Public = require 'maps.fish_defender_v2.table'
local gain_multiplier = 4

local function on_research_finished(event)
    local research = event.research
    local force_name = research.force.name
    local shotgun_shell_damage_modifier_old = Public.get('shotgun_shell_damage_modifier_old')

    if not shotgun_shell_damage_modifier_old[force_name] then
        shotgun_shell_damage_modifier_old[force_name] = game.forces[force_name].get_ammo_damage_modifier('shotgun-shell') - 0.1
    end

    if string.sub(research.name, 0, 26) == 'physical-projectile-damage' then
        local current_damage = game.forces[force_name].get_ammo_damage_modifier('shotgun-shell')
        local vanilla_gain = current_damage - shotgun_shell_damage_modifier_old[force_name]
        local additional_gain = vanilla_gain * (gain_multiplier - 1)
        game.forces[force_name].set_ammo_damage_modifier('shotgun-shell', current_damage + additional_gain)
    end

    shotgun_shell_damage_modifier_old[force_name] = game.forces[force_name].get_ammo_damage_modifier('shotgun-shell')
end

local function on_init()
    game.forces.player.set_ammo_damage_modifier('shotgun-shell', 1)
end

Event.on_init(on_init)
Event.add(defines.events.on_research_finished, on_research_finished)

return Public
