local Public = require 'maps.mountain_fortress_v3.table'

local random = math.random
local rad = math.rad
local sin = math.sin
local cos = math.cos

local function create_defense_system(position, name, target)
    local active_surface_index = Public.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]

    local random_angles = {
        rad(random(359)),
        rad(random(359)),
        rad(random(359)),
        rad(random(359))
    }

    surface.create_entity(
        {
            name = name,
            position = {x = position.x, y = position.y},
            target = target,
            speed = 1.5,
            force = 'player'
        }
    )
    surface.create_entity(
        {
            name = name,
            position = {
                x = position.x + 12 * cos(random_angles[1]),
                y = position.y + 12 * sin(random_angles[1])
            },
            target = target,
            speed = 1.5,
            force = 'player'
        }
    )
    surface.create_entity(
        {
            name = name,
            position = {
                x = position.x + 12 * cos(random_angles[2]),
                y = position.y + 12 * sin(random_angles[2])
            },
            target = target,
            speed = 1.5,
            force = 'player'
        }
    )
    surface.create_entity(
        {
            name = name,
            position = {
                x = position.x + 12 * cos(random_angles[3]),
                y = position.y + 12 * sin(random_angles[3])
            },
            target = target,
            speed = 1.5,
            force = 'player'
        }
    )
    surface.create_entity(
        {
            name = name,
            position = {
                x = position.x + 12 * cos(random_angles[4]),
                y = position.y + 12 * sin(random_angles[4])
            },
            target = target,
            speed = 1.5,
            force = 'player'
        }
    )
end

function Public.enable_poison_defense(pos)
    local locomotive = Public.get('locomotive')
    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end
    pos = pos or locomotive.position
    create_defense_system({x = pos.x, y = pos.y}, 'poison-cloud', pos)
end

function Public.enable_robotic_defense(pos)
    local locomotive = Public.get('locomotive')
    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end

    pos = pos or locomotive.position
    create_defense_system({x = pos.x, y = pos.y}, 'destroyer-capsule', pos)
end

return Public
