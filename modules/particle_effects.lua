local Event = require 'utils.event'
local Public = {}
local Global = require 'utils.global'

local this = {}

Global.register(
    this,
    function (t)
        this = t
    end
)
local random = math.random

local random_particles =
{
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
                movement = { m2 - (random(0, m) * 0.01), m2 - (random(0, m) * 0.01) }
            }
        )
    end
end

function Public.particle_effects(surface, position, count)
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
        count = 60
    end

    for t = 1, count, 1 do
        if not this[game.tick + t] then
            this[game.tick + t] = {}
        end

        this[game.tick + t][#this[game.tick + t] + 1] =
        {
            callback = 'create_particles',
            data = { surface = surface, position = { x = position.x, y = position.y }, amount = math.ceil(t * 0.05) }
        }
    end
end

local callbacks =
{
    ['create_particles'] = create_particles,
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
