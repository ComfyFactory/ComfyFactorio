-- by mewmew
-- modified by Gerkiz

local Event = require 'utils.event'
local Global = require 'utils.global'

local traps = {}

Global.register(
    traps,
    function(t)
        traps = t
    end
)

local function create_particles(surface, position, amount)
    if not surface.valid then
        return
    end
    local math_random = math.random
    for i = 1, amount, 1 do
        local m = math_random(8, 24)
        local m2 = m * 0.005

        surface.create_particle(
            {
                name = 'stone-particle',
                position = position,
                frame_speed = 0.1,
                vertical_speed = 0.1,
                height = 0.1,
                movement = {m2 - (math_random(0, m) * 0.01), m2 - (math_random(0, m) * 0.01)}
            }
        )
    end
end

local function spawn_worm(surface, position, evolution_index)
    if not surface.valid then
        return
    end
    local worm_raffle_table = {
        [1] = {
            'small-worm-turret',
            'small-worm-turret',
            'small-worm-turret',
            'small-worm-turret',
            'small-worm-turret',
            'small-worm-turret'
        },
        [2] = {
            'small-worm-turret',
            'small-worm-turret',
            'small-worm-turret',
            'small-worm-turret',
            'small-worm-turret',
            'medium-worm-turret'
        },
        [3] = {
            'small-worm-turret',
            'small-worm-turret',
            'small-worm-turret',
            'small-worm-turret',
            'medium-worm-turret',
            'medium-worm-turret'
        },
        [4] = {
            'small-worm-turret',
            'small-worm-turret',
            'small-worm-turret',
            'medium-worm-turret',
            'medium-worm-turret',
            'medium-worm-turret'
        },
        [5] = {
            'small-worm-turret',
            'small-worm-turret',
            'medium-worm-turret',
            'medium-worm-turret',
            'medium-worm-turret',
            'big-worm-turret'
        },
        [6] = {
            'small-worm-turret',
            'medium-worm-turret',
            'medium-worm-turret',
            'medium-worm-turret',
            'medium-worm-turret',
            'big-worm-turret'
        },
        [7] = {
            'medium-worm-turret',
            'medium-worm-turret',
            'medium-worm-turret',
            'medium-worm-turret',
            'big-worm-turret',
            'big-worm-turret'
        },
        [8] = {
            'medium-worm-turret',
            'medium-worm-turret',
            'medium-worm-turret',
            'medium-worm-turret',
            'big-worm-turret',
            'big-worm-turret'
        },
        [9] = {
            'medium-worm-turret',
            'medium-worm-turret',
            'medium-worm-turret',
            'big-worm-turret',
            'big-worm-turret',
            'big-worm-turret'
        },
        [10] = {
            'medium-worm-turret',
            'medium-worm-turret',
            'medium-worm-turret',
            'big-worm-turret',
            'big-worm-turret',
            'big-worm-turret'
        }
    }
    local raffle = worm_raffle_table[evolution_index]
    local worm_name = raffle[math.random(1, #raffle)]
    surface.create_entity({name = worm_name, position = position})
end

local function unearthing_worm(surface, position, relative_evolution)
    if not surface then
        return
    end
    if not surface.valid then
        return
    end
    if not position then
        return
    end
    if not position.x then
        return
    end
    if not position.y then
        return
    end

    local evolution_index = math.ceil(game.forces.enemy.evolution_factor * 10)

    if relative_evolution then
        evolution_index = math.ceil(relative_evolution * 10)
    end
    if evolution_index < 1 then
        evolution_index = 1
    end

    for t = 4, 340, 4 do
        local tick = game.tick - (game.tick % 4) + t
        if not traps[tick] then
            traps[tick] = {}
        end

        traps[tick][#traps[tick] + 1] = {
            callback = 'create_particles',
            params = {surface, {x = position.x, y = position.y}, math.ceil(t * 0.05)}
        }

        if t == 340 then
            traps[tick][#traps[tick] + 1] = {
                callback = 'spawn_worm',
                params = {surface, {x = position.x, y = position.y}, evolution_index}
            }
        end
    end
end

local function on_tick()
    if not traps[game.tick] then
        return
    end
    for _, token in pairs(traps[game.tick]) do
        local callback = token.callback
        local params = token.params
        if callback == 'create_particles' then
            create_particles(params[1], params[2], params[3])
        elseif callback == 'spawn_worm' then
            spawn_worm(params[1], params[2], params[3])
        end
    end
    traps[game.tick] = nil
end

Event.on_nth_tick(4, on_tick)

return unearthing_worm
