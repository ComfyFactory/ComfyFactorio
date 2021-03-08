local Event = require 'utils.event'
local Global = require 'utils.global'
local BiterRolls = require 'modules.wave_defense.biter_rolls'
local BiterHealthBooster = require 'modules.biter_health_booster'
local WD = require 'modules.wave_defense.table'
local Diff = require 'modules.difficulty_vote_by_amount'

local traps = {}

Global.register(
    traps,
    function(t)
        traps = t
    end
)

local Public = {}
local floor = math.floor
local random = math.random
local abs = math.abs
local sqrt = math.sqrt

local spawn_amount_rolls = {}
for a = 48, 1, -1 do
    spawn_amount_rolls[#spawn_amount_rolls + 1] = floor(a ^ 5)
end

local random_particles = {
    'dirt-2-stone-particle-medium',
    'dirt-4-dust-particle',
    'coal-particle'
}

local s_random_particles = #random_particles

local function create_particles(data)
    local surface = data.surface
    local position = data.position
    local amount = data.amount

    if not surface or not surface.valid then
        return
    end
    for i = 1, amount, 1 do
        local m = random(6, 12)
        local m2 = m * 0.005

        surface.create_particle(
            {
                name = random_particles[random(1, s_random_particles)],
                position = position,
                frame_speed = 0.1,
                vertical_speed = 0.1,
                height = 0.1,
                movement = {m2 - (random(0, m) * 0.01), m2 - (random(0, m) * 0.01)}
            }
        )
    end
end

local function spawn_biters(data)
    local surface = data.surface
    local position = data.position
    local h = floor(abs(position.y))
    local wave_number = WD.get('wave_number')
    local d = Diff.get()

    if not position then
        position = surface.find_non_colliding_position('small-biter', position, 10, 1)
        if not position then
            return
        end
    end

    local m = 0.0015
    if d.difficulty_vote_index then
        if not d.strength_modifier then
            m = m * 1.05
        else
            m = m * d.strength_modifier
        end
    end

    local boosted_health = 1 + (wave_number * (m * 2))

    if wave_number >= 100 then
        boosted_health = boosted_health * 2
    end

    BiterRolls.wave_defense_set_unit_raffle(h * 0.20)

    local unit
    if random(1, 3) == 1 then
        unit = surface.create_entity({name = BiterRolls.wave_defense_roll_spitter_name(), position = position})
    else
        unit = surface.create_entity({name = BiterRolls.wave_defense_roll_biter_name(), position = position})
    end

    if random(1, 64) == 1 then
        BiterHealthBooster.add_boss_unit(unit, boosted_health, 0.38)
    end
end

local function spawn_worms(data)
    local surface = data.surface
    local position = data.position
    BiterRolls.wave_defense_set_worm_raffle(sqrt(position.x ^ 2 + position.y ^ 2) * 0.20)
    surface.create_entity({name = BiterRolls.wave_defense_roll_worm_name(), position = position})
end

function Public.buried_biter(surface, position, max)
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

    local amount = 8
    local a = 0
    max = max or random(4, 6)

    local ticks = amount * 30
    ticks = ticks + 90
    for t = 1, ticks, 1 do
        if not traps[game.tick + t] then
            traps[game.tick + t] = {}
        end

        traps[game.tick + t][#traps[game.tick + t] + 1] = {
            callback = 'create_particles',
            data = {surface = surface, position = {x = position.x, y = position.y}, amount = 4}
        }

        if t > 90 then
            if t % 30 == 29 then
                a = a + 1
                traps[game.tick + t][#traps[game.tick + t] + 1] = {
                    callback = 'spawn_biters',
                    data = {surface = surface, position = {x = position.x, y = position.y}}
                }
                if a >= max then
                    break
                end
            end
        end
    end
end

function Public.buried_worm(surface, position)
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

    local amount = 8

    local ticks = amount * 30
    ticks = ticks + 90
    local a = false
    for t = 1, ticks, 1 do
        if not traps[game.tick + t] then
            traps[game.tick + t] = {}
        end

        traps[game.tick + t][#traps[game.tick + t] + 1] = {
            callback = 'create_particles',
            data = {surface = surface, position = {x = position.x, y = position.y}, amount = 4}
        }

        if not a then
            traps[game.tick + t][#traps[game.tick + t] + 1] = {
                callback = 'spawn_worms',
                data = {surface = surface, position = {x = position.x, y = position.y}}
            }
            a = true
        end
    end
end

local callbacks = {
    ['create_particles'] = create_particles,
    ['spawn_biters'] = spawn_biters,
    ['spawn_worms'] = spawn_worms
}

local function on_tick()
    local t = game.tick
    if not traps[t] then
        return
    end
    for _, token in pairs(traps[t]) do
        local callback = token.callback
        local data = token.data
        local cbl = callbacks[callback]
        if callbacks[callback] then
            cbl(data)
        end
    end
    traps[t] = nil
end

Event.add(defines.events.on_tick, on_tick)

return Public
