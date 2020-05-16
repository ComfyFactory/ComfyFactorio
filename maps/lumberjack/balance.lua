local Event = require 'utils.event'
local Difficulty = require 'modules.difficulty_vote'
local Public = {}

function Public.init_enemy_weapon_damage()
    local data = {
        ['artillery-shell'] = 0,
        ['biological'] = 0.1,
        ['bullet'] = 2,
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

    local e, s, sd = game.forces.enemy, game.forces.defenders, game.forces.lumber_defense

    for k, v in pairs(data) do
        e.set_ammo_damage_modifier(k, v)
        s.set_ammo_damage_modifier(k, v)
        sd.set_ammo_damage_modifier(k, v)
    end
end

local function enemy_weapon_damage()
    Difficulty.get()
    if game.tick < 100 then
        goto rtn
    end
    local e, s, sd = game.forces.enemy, game.forces.defenders, game.forces.lumber_defense

    local data = {
        ['artillery-shell'] = 0.1,
        ['biological'] = 0.1,
        ['bullet'] = 0.1,
        ['capsule'] = 0.1,
        ['combat-robot-beam'] = 0.1,
        ['combat-robot-laser'] = 0.1,
        ['electric'] = 0.1,
        ['flamethrower'] = 0.1,
        --['grenade'] = 0.1,
        --['landmine'] = 0.1,
        ['laser-turret'] = 0.1,
        ['melee'] = 0.1
        --['railgun'] = 0.1,
        --['rocket'] = 0.1,
        --['shotgun-shell'] = 0.1
    }

    for k, v in pairs(data) do
        local new = Diff.difficulty_vote_value * v

        local e_old = e.get_ammo_damage_modifier(k)
        local s_old = s.get_ammo_damage_modifier(k)
        local sd_old = sd.get_ammo_damage_modifier(k)

        e.set_ammo_damage_modifier(k, new + e_old)
        s.set_ammo_damage_modifier(k, new + s_old)
        sd.set_ammo_damage_modifier(k, new + sd_old)
    end

    ::rtn::
end

Event.on_nth_tick(54000, enemy_weapon_damage)

return Public
