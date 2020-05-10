local Event = require 'utils.event'
local Public = {}

function Public.init_enemy_weapon_damage()
    local data = {
        ['artillery-shell'] = 0,
        ['biological'] = 0.1,
        ['bullet'] = 2.5,
        ['cannon-shell'] = 0,
        ['capsule'] = 0,
        ['combat-robot-beam'] = 0,
        ['combat-robot-laser'] = 0,
        ['electric'] = 0,
        ['flamethrower'] = 0,
        ['grenade'] = 0,
        ['landmine'] = 0,
        ['laser-turret'] = 0,
        ['melee'] = 0.5,
        ['railgun'] = 0,
        ['rocket'] = 0,
        ['shotgun-shell'] = 0
    }

    local e, s, sd = game.forces.enemy, game.forces.scrap, game.forces.scrap_defense

    for k, v in pairs(data) do
        e.set_ammo_damage_modifier(k, v)
        s.set_ammo_damage_modifier(k, v)
        sd.set_ammo_damage_modifier(k, v)
    end
end

local function enemy_weapon_damage()
    if game.tick < 100 then
        goto rtn
    end
    local e, s, sd = game.forces.enemy, game.forces.scrap, game.forces.scrap_defense

    local data = {
        ['artillery-shell'] = 0.5,
        ['biological'] = 0.5,
        ['bullet'] = 0.5,
        ['capsule'] = 0.5,
        ['combat-robot-beam'] = 0.5,
        ['combat-robot-laser'] = 0.5,
        ['electric'] = 0.5,
        ['flamethrower'] = 0.5,
        --['grenade'] = 0.5,
        --['landmine'] = 0.5,
        ['laser-turret'] = 0.5,
        ['melee'] = 0.5
        --['railgun'] = 0.5,
        --['rocket'] = 0.5,
        --['shotgun-shell'] = 0.5
    }

    for k, v in pairs(data) do
        local new = global.difficulty_vote_value * v

        e.set_ammo_damage_modifier(k, new)
        s.set_ammo_damage_modifier(k, new)
        sd.set_ammo_damage_modifier(k, new)
    end

    ::rtn::
end

Event.on_nth_tick(18000, enemy_weapon_damage)

return Public
