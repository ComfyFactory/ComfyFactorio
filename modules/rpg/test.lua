local states = {
    ['attack'] = 'nuclear-smoke',
    ['support'] = 'poison-capsule-smoke'
}

local Task = require 'utils.task'
local Token = require 'utils.token'

local smokes = {
    'artillery-smoke',
    'car-smoke',
    'fire-smoke',
    'fire-smoke-on-adding-fuel',
    'fire-smoke-without-glow',
    'light-smoke',
    'nuclear-smoke',
    'poison-capsule-particle-smoke',
    'poison-capsule-smoke',
    'smoke',
    'smoke-building',
    'smoke-explosion-lower-particle-small',
    'smoke-explosion-particle',
    'smoke-explosion-particle-small',
    'smoke-explosion-particle-stone-small',
    'smoke-explosion-particle-tiny',
    'smoke-fast',
    'smoke-train-stop',
    'soft-fire-smoke',
    'tank-smoke',
    'train-smoke',
    'turbine-smoke'
}

local function get_area(pos, dist)
    local area = {
        left_top = {
            x = pos.x - dist,
            y = pos.y - dist
        },
        right_bottom = {
            x = pos.x + dist,
            y = pos.y + dist
        }
    }
    return area
end

local do_something_token =
    Token.register(
    function(event)
        local cs = event.cs
        local smoke = event.smoke
        local p = event.p
        cs.create_trivial_smoke({name = smoke, position = p})
        game.print(smoke)
    end
)

local function area_of_effect(player, state, radius)
    if not radius then
        return
    end

    local cs = player.surface
    local cp = player.position

    if radius and radius > 256 then
        radius = 256
    end

    local area = get_area(cp, radius)

    if not states[state] then
        return
    end

    for x = area.left_top.x, area.right_bottom.x, 1 do
        for y = area.left_top.y, area.right_bottom.y, 1 do
            local d = math.floor((cp.x - x) ^ 2 + (cp.y - y) ^ 2)
            if d < radius then
                local p = {x = x, y = y}
                local c = 10
                for _, smoke in pairs(smokes) do
                    c = c + 200
                    Task.set_timeout_in_ticks(c, do_something_token, {cs = cs, smoke = smoke, p = p})
                end
            end
        end
    end
end

area_of_effect(game.player, 'attack', 32)
