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

local function create_projectile(surface, pos, projectile)
    surface.create_entity(
        {
            name = projectile,
            position = pos,
            force = 'enemy',
            target = pos,
            speed = 1
        }
    )
end

local function omegakaboom(surface, center_pos, projectile, radius, density)
    local positions = {}
    for x = radius * -1, radius, 1 do
        for y = radius * -1, radius, 1 do
            local pos = {x = center_pos.x + x, y = center_pos.y + y}
            local distance_to_center = math.ceil(math.sqrt((pos.x - center_pos.x) ^ 2 + (pos.y - center_pos.y) ^ 2))
            if distance_to_center < radius and math.random(1, 100) < density then
                if not positions[distance_to_center] then
                    positions[distance_to_center] = {}
                end
                positions[distance_to_center][#positions[distance_to_center] + 1] = pos
            end
        end
    end
    if #positions == 0 then
        return
    end
    local t = 1
    for _, pos_list in pairs(positions) do
        for _, pos in pairs(pos_list) do
            if not traps[game.tick + t] then
                traps[game.tick + t] = {}
            end
            traps[game.tick + t][#traps[game.tick + t] + 1] = {
                callback = 'create_projectile',
                params = {surface, pos, projectile}
            }
        end
        t = t + 4
    end
end

local function on_tick()
    if not traps[game.tick] then
        return
    end
    for _, token in pairs(traps[game.tick]) do
        local callback = token.callback
        local params = token.params
        if callback == 'create_projectile' then
            create_projectile(params[1], params[2], params[3])
        end
    end
    traps[game.tick] = nil
end

Event.add(defines.events.on_tick, on_tick)

return omegakaboom
