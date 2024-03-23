local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local Global = require 'utils.global'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local WD = require 'modules.wave_defense.table'

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

local s_random_particles = #random_particles

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
    if not (surface and surface.valid) then
        return false
    end
    local position = data.position
    local h = floor(abs(position.y))

    local max_biters = Public.get('biters')

    if max_biters.amount >= max_biters.limit then
        return false
    end

    if not position then
        position = surface.find_non_colliding_position('small-biter', position, 10, 1)
        if not position then
            return false
        end
    end

    local unit_to_create
    WD.wave_defense_set_unit_raffle(h * 0.20)

    if random(1, 3) == 1 then
        unit_to_create = WD.wave_defense_roll_spitter_name()
    else
        unit_to_create = WD.wave_defense_roll_biter_name()
    end

    if not unit_to_create then
        print('buried_enemies - unit_to_create was nil?')
        return
    end

    local modified_unit_health = WD.get('modified_unit_health')
    local modified_boss_unit_health = WD.get('modified_boss_unit_health')

    local unit_settings = WD.get('unit_settings')

    local unit = surface.create_entity({name = unit_to_create, position = position})
    max_biters.amount = max_biters.amount + 1

    if random(1, 30) == 1 then
        BiterHealthBooster.add_boss_unit(unit, modified_boss_unit_health.current_value, 0.38)
    else
        local final_health = round(modified_unit_health.current_value * unit_settings.scale_units_by_health[unit.name], 3)
        if final_health < 1 then
            final_health = 1
        end
        BiterHealthBooster.add_unit(unit, final_health)
    end
    return true
end

local function spawn_worms(data)
    local modified_unit_health = WD.get('modified_unit_health')
    local modified_boss_unit_health = WD.get('modified_boss_unit_health')
    local max_biters = Public.get('biters')

    if max_biters.amount >= max_biters.limit then
        return
    end

    local unit_to_create = WD.wave_defense_roll_worm_name()
    if not unit_to_create then
        return
    end

    local surface = data.surface
    if not (surface and surface.valid) then
        return
    end
    local position = data.position

    WD.wave_defense_set_worm_raffle(sqrt(position.x ^ 2 + position.y ^ 2) * 0.20)

    local unit = surface.create_entity({name = unit_to_create, position = position})
    max_biters.amount = max_biters.amount + 1

    local worm_unit_settings = WD.get('worm_unit_settings')

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

function Public.buried_biter(surface, position, count)
    if not (surface and surface.valid) then
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

    if not count then
        count = 1
    end

    for t = 1, 60, 1 do
        if not this[game.tick + t] then
            this[game.tick + t] = {}
        end

        this[game.tick + t][#this[game.tick + t] + 1] = {
            callback = 'create_particles',
            data = {surface = surface, position = {x = position.x, y = position.y}, amount = math.ceil(t * 0.05)}
        }

        if t == 60 then
            if count == 1 then
                this[game.tick + t][#this[game.tick + t] + 1] = {
                    callback = 'spawn_biters',
                    data = {surface = surface, position = {x = position.x, y = position.y}, count = count or 1}
                }
            else
                local tick = 2
                for _ = 1, count do
                    this[game.tick + t][#this[game.tick + t] + 1 + tick] = {
                        callback = 'spawn_biters',
                        data = {surface = surface, position = {x = position.x, y = position.y}, count = count or 1}
                    }
                    tick = tick + 2
                end
            end
        end
    end
end

function Public.buried_worm(surface, position)
    if not (surface and surface.valid) then
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

    for t = 1, 60, 1 do
        if not this[game.tick + t] then
            this[game.tick + t] = {}
        end

        this[game.tick + t][#this[game.tick + t] + 1] = {
            callback = 'create_particles',
            data = {surface = surface, position = {x = position.x, y = position.y}, amount = math.ceil(t * 0.05)}
        }

        if t == 60 then
            this[game.tick + t][#this[game.tick + t] + 1] = {
                callback = 'spawn_worms',
                data = {surface = surface, position = {x = position.x, y = position.y}}
            }
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

function Public.reset_buried_biters()
    for k, _ in pairs(this) do
        this[k] = nil
    end
end

Event.add(defines.events.on_tick, on_tick)

return Public
