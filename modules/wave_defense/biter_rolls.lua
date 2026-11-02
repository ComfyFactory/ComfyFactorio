local Public = require 'modules.wave_defense.table'
local Task = require 'utils.task_token'
local Math = require 'utils.math.math'

local function roll_weighted_name(raffle)
    local total = 0
    for _, weight in pairs(raffle) do
        if weight > 0 then
            total = total + weight
        end
    end
    if total <= 0 then
        return
    end
    local roll = Math.random() * total
    local cumulative = 0
    for name, weight in pairs(raffle) do
        if weight > 0 then
            cumulative = cumulative + weight
            if roll < cumulative then
                return name
            end
        end
    end
end

function Public.wave_defense_roll_biter_name(raffle)
    return roll_weighted_name(raffle or Public.get('biter_raffle'))
end

function Public.wave_defense_roll_boss_name(raffle)
    return roll_weighted_name(raffle or Public.get('boss_raffle'))
end

function Public.wave_defense_roll_spitter_name(raffle)
    return roll_weighted_name(raffle or Public.get('spitter_raffle'))
end

function Public.wave_defense_set_unit_raffle(level)
    local unit_settings = Public.get('unit_settings') --[[@as table]]
    if unit_settings.custom_unit_raffle then
        local callback = Task.get(unit_settings.custom_unit_raffle)
        callback({ level = level })
    else
        Public.set(
            'biter_raffle',
            {
                ['small-biter'] = Math.round(1000 - level * 1.75, 6),
                ['medium-biter'] = Math.round(level, 6),
                ['big-biter'] = 0,
                ['behemoth-biter'] = 0
            }
        )

        Public.set(
            'spitter_raffle',
            {
                ['small-spitter'] = Math.round(1000 - level * 1.75, 6),
                ['medium-spitter'] = Math.round(level, 6),
                ['big-spitter'] = 0,
                ['behemoth-spitter'] = 0
            }
        )

        Public.set(
            'boss_raffle',
            {
                ['behemoth-biter'] = Math.round(1000 - level * 1.75, 6),
                ['behemoth-spitter'] = Math.round(level, 6),
            }
        )

        local biter_raffle = Public.get('biter_raffle') --[[@as table]]
        local spitter_raffle = Public.get('spitter_raffle') --[[@as table]]
        local boss_raffle = Public.get('boss_raffle') --[[@as table]]
        if level > 500 then
            biter_raffle['medium-biter'] = Math.round(500 - (level - 500), 6)
            spitter_raffle['medium-spitter'] = Math.round(500 - (level - 500), 6)
            biter_raffle['big-biter'] = Math.round((level - 500) * 2, 6)
            spitter_raffle['big-spitter'] = Math.round((level - 500) * 2, 6)
            boss_raffle['behemoth-biter'] = Math.round((level - 500) * 2, 6)
            boss_raffle['behemoth-spitter'] = Math.round((level - 500) * 2, 6)
        end
        if level > 800 then
            biter_raffle['behemoth-biter'] = Math.round((level - 800) * 2.75, 6)
            spitter_raffle['behemoth-spitter'] = Math.round((level - 800) * 2.75, 6)
            boss_raffle['behemoth-biter'] = Math.round((level - 800) * 2.75, 6)
            boss_raffle['behemoth-spitter'] = Math.round((level - 800) * 2.75, 6)
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
        for k, _ in pairs(boss_raffle) do
            if boss_raffle[k] < 0 then
                boss_raffle[k] = 0
            end
        end
    end
end

function Public.wave_defense_roll_worm_name(exclude)
    local worm_raffle = Public.get('worm_raffle') --[[@as table]]

    if exclude then
        local copied_raffle = {}
        if type(exclude) == 'string' then
            for k, v in pairs(worm_raffle) do
                if not string.find(k, exclude, 1, true) then
                    copied_raffle[k] = v
                end
            end
            if next(copied_raffle) then
                worm_raffle = copied_raffle
            end
        elseif type(exclude) == 'table' then
            for k, v in pairs(worm_raffle) do
                local matched = false
                for _, excluded_name in pairs(exclude) do
                    if string.find(k, excluded_name, 1, true) then
                        matched = true
                        break
                    end
                end
                if not matched then
                    copied_raffle[k] = v
                end
            end
            if next(copied_raffle) then
                worm_raffle = copied_raffle
            end
        end
    end


    return roll_weighted_name(worm_raffle)
end

function Public.wave_defense_set_worm_raffle(level)
    local unit_settings = Public.get('unit_settings') --[[@as table]]
    if unit_settings.custom_worm_raffle then
        local callback = Task.get(unit_settings.custom_worm_raffle)
        callback({ level = level })
    else
        Public.set(
            'worm_raffle',
            {
                ['small-worm-turret'] = Math.round(1000 - level * 1.75, 6),
                ['medium-worm-turret'] = Math.round(level, 6),
                ['big-worm-turret'] = 0,
                ['behemoth-worm-turret'] = 0
            }
        )
        local worm_raffle = Public.get('worm_raffle') --[[@as table]]

        if level > 500 then
            worm_raffle['medium-worm-turret'] = Math.round(500 - (level - 500), 6)
            worm_raffle['big-worm-turret'] = Math.round((level - 500) * 2, 6)
        end
        if level > 800 then
            worm_raffle['behemoth-worm-turret'] = Math.round((level - 800) * 3, 6)
        end
        for k, _ in pairs(worm_raffle) do
            if worm_raffle[k] < 0 then
                worm_raffle[k] = 0
            end
        end
    end
end

function Public.wave_defense_print_chances(tbl)
    for k, v in pairs(tbl) do
        game.print(k .. ' chance = ' .. v)
    end
end

return Public
