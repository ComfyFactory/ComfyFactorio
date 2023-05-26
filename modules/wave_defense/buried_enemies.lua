local Public = require 'modules.wave_defense.table'
local Event = require 'utils.event'
local Global = require 'utils.global'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'

local this = {}

Global.register(
    this,
    function(t)
        this = t
    end
)

local round = math.round
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

local size_random_particles = #random_particles

local function create_particles(data)
    local surface = data.surface
    local position = data.position
    local amount = data.amount

    if not surface or not surface.valid then
        return
    end
    for _ = 1, amount, 1 do
        local m = random(6, 12)
        local m2 = m * 0.005

        surface.create_particle(
            {
                name = random_particles[random(1, size_random_particles)],
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
    local entity_name = data.entity_name
    local h = floor(abs(position.y))

    if not position then
        position = surface.find_non_colliding_position('small-biter', position, 10, 1)
        if not position then
            return
        end
    end
    Public.wave_defense_set_unit_raffle(h * 0.20)

    local unit_to_create

    if random(1, 3) == 1 then
        unit_to_create = Public.wave_defense_roll_spitter_name()
    else
        unit_to_create = Public.wave_defense_roll_biter_name()
    end

    if entity_name then
        unit_to_create = entity_name
    end

    local modified_unit_health = Public.get('modified_unit_health')
    local modified_boss_unit_health = Public.get('modified_boss_unit_health')

    local unit_settings = Public.get('unit_settings')

    local unit = surface.create_entity({name = unit_to_create, position = position})

    if random(1, 30) == 1 then
        BiterHealthBooster.add_boss_unit(unit, modified_boss_unit_health.current_value, 0.38)
    else
        local final_health = round(modified_unit_health.current_value * unit_settings.scale_units_by_health[unit.name], 3)
        if final_health < 1 then
            final_health = 1
        end
        BiterHealthBooster.add_unit(unit, final_health)
    end
end

local function spawn_worms(data)
    local modified_unit_health = Public.get('modified_unit_health')
    local modified_boss_unit_health = Public.get('modified_boss_unit_health')

    local surface = data.surface
    local position = data.position
    Public.wave_defense_set_worm_raffle(sqrt(position.x ^ 2 + position.y ^ 2) * 0.20)

    local unit_to_create = Public.wave_defense_roll_worm_name(sqrt(position.x ^ 2 + position.y ^ 2) * 0.20)

    local unit = surface.create_entity({name = unit_to_create, position = position})
    local worm_unit_settings = Public.get('worm_unit_settings')

    if random(1, 30) == 1 then
        BiterHealthBooster.add_boss_unit(unit, modified_boss_unit_health.current_value, 0.38)
    else
        local final_health = round(modified_unit_health.current_value * worm_unit_settings.scale_units_by_health[unit.name], 3)
        if final_health < 1 then
            final_health = 1
        end
        BiterHealthBooster.add_unit(unit, final_health)
    end
end

function Public.buried_biter(surface, position, max, entity_name)
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
        if not this[game.tick + t] then
            this[game.tick + t] = {}
        end

        this[game.tick + t][#this[game.tick + t] + 1] = {
            callback = 'create_particles',
            data = {surface = surface, position = {x = position.x, y = position.y}, amount = 4}
        }

        if t > 90 then
            if t % 30 == 29 then
                a = a + 1
                this[game.tick + t][#this[game.tick + t] + 1] = {
                    callback = 'spawn_biters',
                    data = {surface = surface, position = {x = position.x, y = position.y}, entity_name = entity_name}
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
        if not this[game.tick + t] then
            this[game.tick + t] = {}
        end

        this[game.tick + t][#this[game.tick + t] + 1] = {
            callback = 'create_particles',
            data = {surface = surface, position = {x = position.x, y = position.y}, amount = 4}
        }

        if not a then
            this[game.tick + t][#this[game.tick + t] + 1] = {
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
    if not this[t] then
        return
    end
    for _, token in pairs(this[t]) do
        local callback = token.callback
        local data = token.data
        local cbl = callbacks[callback]
        if callbacks[callback] then
            cbl(data)
        end
    end
    this[t] = nil
end

Event.add(defines.events.on_tick, on_tick)

return Public
