local Public = require 'modules.wave_defense.table'

function Public.wave_defense_roll_biter_name()
    local biter_raffle = Public.get('biter_raffle')
    local max_chance = 0
    for k, v in pairs(biter_raffle) do
        max_chance = max_chance + v
    end
    local r = math.random(0, math.floor(max_chance))
    local current_chance = 0
    for k, v in pairs(biter_raffle) do
        current_chance = current_chance + v
        if r <= current_chance then
            return k
        end
    end
end

function Public.wave_defense_roll_spitter_name()
    local spitter_raffle = Public.get('spitter_raffle')
    local max_chance = 0
    for k, v in pairs(spitter_raffle) do
        max_chance = max_chance + v
    end
    local r = math.random(0, math.floor(max_chance))
    local current_chance = 0
    for k, v in pairs(spitter_raffle) do
        current_chance = current_chance + v
        if r <= current_chance then
            return k
        end
    end
end

function Public.wave_defense_set_unit_raffle(level)
    Public.set(
        'biter_raffle',
        {
            ['small-biter'] = 1000 - level * 1.75,
            ['medium-biter'] = level,
            ['big-biter'] = 0,
            ['behemoth-biter'] = 0
        }
    )

    Public.set(
        'spitter_raffle',
        {
            ['small-spitter'] = 1000 - level * 1.75,
            ['medium-spitter'] = level,
            ['big-spitter'] = 0,
            ['behemoth-spitter'] = 0
        }
    )

    local biter_raffle = Public.get('biter_raffle')
    local spitter_raffle = Public.get('spitter_raffle')
    if level > 500 then
        biter_raffle['medium-biter'] = 500 - (level - 500)
        spitter_raffle['medium-spitter'] = 500 - (level - 500)
        biter_raffle['big-biter'] = (level - 500) * 2
        spitter_raffle['big-spitter'] = (level - 500) * 2
    end
    if level > 800 then
        biter_raffle['behemoth-biter'] = (level - 800) * 2.75
        spitter_raffle['behemoth-spitter'] = (level - 800) * 2.75
    end
    for k, _ in pairs(biter_raffle) do
        if biter_raffle[k] < 0 then
            biter_raffle[k] = 0
        end
    end
    for k, _ in pairs(spitter_raffle) do
        if spitter_raffle[k] < 0 then
            spitter_raffle[k] = 0
        end
    end
end

function Public.wave_defense_roll_worm_name()
    local worm_raffle = Public.get('worm_raffle')
    local max_chance = 0
    for k, v in pairs(worm_raffle) do
        max_chance = max_chance + v
    end
    local r = math.random(0, math.floor(max_chance))
    local current_chance = 0
    for k, v in pairs(worm_raffle) do
        current_chance = current_chance + v
        if r <= current_chance then
            return k
        end
    end
end

function Public.wave_defense_set_worm_raffle(level)
    Public.set(
        'worm_raffle',
        {
            ['small-worm-turret'] = 1000 - level * 1.75,
            ['medium-worm-turret'] = level,
            ['big-worm-turret'] = 0,
            ['behemoth-worm-turret'] = 0
        }
    )
    local worm_raffle = Public.get('worm_raffle')

    if level > 500 then
        worm_raffle['medium-worm-turret'] = 500 - (level - 500)
        worm_raffle['big-worm-turret'] = (level - 500) * 2
    end
    if level > 800 then
        worm_raffle['behemoth-worm-turret'] = (level - 800) * 3
    end
    for k, _ in pairs(worm_raffle) do
        if worm_raffle[k] < 0 then
            worm_raffle[k] = 0
        end
    end
end

function Public.wave_defense_print_chances(tbl)
    for k, v in pairs(tbl) do
        game.print(k .. ' chance = ' .. v)
    end
end

return Public
