local Public = require 'modules.wave_defense.table'
local Task = require 'utils.task_token'
local round = math.round

function Public.wave_defense_roll_biter_name()
    local biter_raffle = Public.get('biter_raffle') --[[@as table]]
    local max_chance = 0
    for _, v in pairs(biter_raffle) do
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
    local spitter_raffle = Public.get('spitter_raffle') --[[@as table]]
    local max_chance = 0
    for _, v in pairs(spitter_raffle) do
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
    local unit_settings = Public.get('unit_settings') --[[@as table]]
    if unit_settings.custom_unit_raffle then
        local callback = Task.get(unit_settings.custom_unit_raffle)
        callback({ level = level })
    else
        Public.set(
            'biter_raffle',
            {
                ['small-biter'] = round(1000 - level * 1.75, 6),
                ['medium-biter'] = round(level, 6),
                ['big-biter'] = 0,
                ['behemoth-biter'] = 0
            }
        )

        Public.set(
            'spitter_raffle',
            {
                ['small-spitter'] = round(1000 - level * 1.75, 6),
                ['medium-spitter'] = round(level, 6),
                ['big-spitter'] = 0,
                ['behemoth-spitter'] = 0
            }
        )

        local biter_raffle = Public.get('biter_raffle') --[[@as table]]
        local spitter_raffle = Public.get('spitter_raffle') --[[@as table]]
        if level > 500 then
            biter_raffle['medium-biter'] = round(500 - (level - 500), 6)
            spitter_raffle['medium-spitter'] = round(500 - (level - 500), 6)
            biter_raffle['big-biter'] = round((level - 500) * 2, 6)
            spitter_raffle['big-spitter'] = round((level - 500) * 2, 6)
        end
        if level > 800 then
            biter_raffle['behemoth-biter'] = round((level - 800) * 2.75, 6)
            spitter_raffle['behemoth-spitter'] = round((level - 800) * 2.75, 6)
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
end

function Public.wave_defense_roll_worm_name(exclude)
    local worm_raffle = Public.get('worm_raffle') --[[@as table]]

    if exclude then
        local copied_raffle = {}
        for k, v in pairs(worm_raffle) do
            if not string.find(k, exclude, 1, true) then
                copied_raffle[k] = v
            end
        end
        if next(copied_raffle) then
            worm_raffle = copied_raffle
        end
    end


    local max_chance = 0
    for _, v in pairs(worm_raffle) do
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
    local unit_settings = Public.get('unit_settings') --[[@as table]]
    if unit_settings.custom_worm_raffle then
        local callback = Task.get(unit_settings.custom_worm_raffle)
        callback({ level = level })
    else
        Public.set(
            'worm_raffle',
            {
                ['small-worm-turret'] = round(1000 - level * 1.75, 6),
                ['medium-worm-turret'] = round(level, 6),
                ['big-worm-turret'] = 0,
                ['behemoth-worm-turret'] = 0
            }
        )
        local worm_raffle = Public.get('worm_raffle') --[[@as table]]

        if level > 500 then
            worm_raffle['medium-worm-turret'] = round(500 - (level - 500), 6)
            worm_raffle['big-worm-turret'] = round((level - 500) * 2, 6)
        end
        if level > 800 then
            worm_raffle['behemoth-worm-turret'] = round((level - 800) * 3, 6)
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
