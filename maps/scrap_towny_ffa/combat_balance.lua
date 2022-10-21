local Event = require 'utils.event'
local Public = {}

local player_ammo_damage_starting_modifiers = {
    ['bullet'] = 0,
    ['cannon-shell'] = -0.5,
    ['capsule'] = 0,
    ['beam'] = -0.5,
    ['laser'] = -0.5,
    ['electric'] = -0.5,
    ['flamethrower'] = 0,
    ['grenade'] = -0.5,
    ['landmine'] = -0.75,
    ['shotgun-shell'] = 0
}
local player_ammo_damage_modifiers = {
    ['bullet'] = 0,
    ['cannon-shell'] = -0.5,
    ['capsule'] = 0,
    ['beam'] = -0.5,
    ['laser'] = -0.5,
    ['electric'] = -0.5,
    ['flamethrower'] = 0,
    ['grenade'] = -0.5,
    ['landmine'] = -0.5,
    ['shotgun-shell'] = 0
}
local player_gun_speed_modifiers = {
    ['bullet'] = 0,
    ['cannon-shell'] = -0.5,
    ['capsule'] = -0.5,
    ['beam'] = -0.5,
    ['laser'] = 0,
    ['electric'] = -0.5,
    ['flamethrower'] = 0,
    ['grenade'] = -0.5,
    ['landmine'] = 0,
    ['shotgun-shell'] = 0
}

function Public.init_player_weapon_damage(force)
    for k, v in pairs(player_ammo_damage_starting_modifiers) do
        force.set_ammo_damage_modifier(k, v)
    end

    for k, v in pairs(player_gun_speed_modifiers) do
        force.set_gun_speed_modifier(k, v)
    end

    force.set_turret_attack_modifier('laser-turret', 3)
end

-- After a research is finished and the game applied the modifier, we reduce modifiers to achieve the reduction
local function research_finished(event)
    local r = event.research
    local p_force = r.force

    for _, e in ipairs(r.effects) do
        local t = e.type

        if t == 'ammo-damage' then
            local category = e.ammo_category
            local factor = player_ammo_damage_modifiers[category]

            if factor then
                local current_m = p_force.get_ammo_damage_modifier(category)
                p_force.set_ammo_damage_modifier(category, current_m + factor * e.modifier)
            end
        elseif t == 'gun-speed' then
            local category = e.ammo_category
            local factor = player_gun_speed_modifiers[category]

            if factor then
                local current_m = p_force.get_gun_speed_modifier(category)
                p_force.set_gun_speed_modifier(category, current_m + factor * e.modifier)
            end
        end
    end
end

Event.add(defines.events.on_research_finished, research_finished)
return Public
