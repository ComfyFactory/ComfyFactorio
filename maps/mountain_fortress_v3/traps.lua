local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'

local random = math.random

local tick_tacks = { '*tick*', '*tick*', '*tack*', '*tak*', '*tik*', '*tok*', '*run*' }

local kaboom_weights = {
    { name = 'grenade',                             chance = 7 },
    { name = 'cluster-grenade',                     chance = 1 },
    { name = 'destroyer-capsule',                   chance = 1 },
    { name = 'defender-capsule',                    chance = 4 },
    { name = 'distractor-capsule',                  chance = 2 },
    { name = 'poison-capsule',                      chance = 2 },
    { name = 'coin',                                chance = 2 },
    { name = 'explosive-uranium-cannon-projectile', chance = 3 },
    { name = 'explosive-cannon-projectile',         chance = 5 }
}

local kabooms = {}
for _, t in pairs(kaboom_weights) do
    for _ = 1, t.chance, 1 do
        kabooms[#kabooms + 1] = t.name
    end
end

local function create_flying_text(entity, text)
    if not entity or not entity.valid then return end
    if not entity.surface.valid then
        return
    end
    entity.surface.create_entity(
        {
            name = 'compi-speech-bubble',
            position = entity.position,
            text = text,
            source = entity,
            lifetime = 30
        }
    )

    entity.surface.play_sound({ path = 'utility/armor_insert', position = entity.position, volume_modifier = 0.75 })
end

local function create_kaboom(entity, name)
    if not entity or not entity.valid then return end

    local target = entity.position
    local speed = 0.5
    if name == 'coin' then
        local rng = random(1, 512)
        local chest = 'crash-site-chest-' .. random(1, 2)

        local container = entity.surface.create_entity({ name = chest, position = entity.position, force = 'neutral' })
        if container and container.health then
            container.insert({ name = 'coin', count = rng })
            container.health = random(1, container.health)
        end
        return
    end

    if name == 'defender-capsule' or name == 'destroyer-capsule' or name == 'distractor-capsule' then
        entity.surface.create_entity(
            {
                name = 'compi-speech-bubble',
                position = entity.position,
                text = '(((Sentries Engaging Target)))',
                source = entity,
                lifetime = 30
            }
        )
        local nearest_player_unit = entity.surface.find_nearest_enemy({ position = entity.position, max_distance = 128, force = 'enemy' })
        if nearest_player_unit then
            target = nearest_player_unit.position
        end
        speed = 0.001
    end
    entity.surface.create_entity(
        {
            name = name,
            position = entity.position,
            force = 'enemy',
            target = target,
            speed = speed
        }
    )
end

function Public.tick_tack_trap(entity)
    if not entity or not entity.valid then return end

    local traps = Public.get('traps')
    local tick_tack_count = random(5, 9)
    for t = 60, tick_tack_count * 60, 60 do
        if not traps[game.tick + t] then
            traps[game.tick + t] = {}
        end

        if t < tick_tack_count * 60 then
            traps[game.tick + t][#traps[game.tick + t] + 1] = {
                callback = 'create_flying_text',
                params = { entity = entity, message = tick_tacks[random(1, #tick_tacks)] }
            }
        else
            if random(1, 10) == 1 then
                traps[game.tick + t][#traps[game.tick + t] + 1] = {
                    callback = 'create_flying_text',
                    params = { entity = entity, message = '( ͡° ͜ʖ ͡°)' }
                }
            else
                traps[game.tick + t][#traps[game.tick + t] + 1] = {
                    callback = 'create_kaboom',
                    params = { entity = entity, explosion = kabooms[random(1, #kabooms)] }
                }
            end
        end
    end
end

local function on_tick()
    local traps = Public.get('traps')
    if not traps[game.tick] then
        return
    end
    for _, token in pairs(traps[game.tick]) do
        local callback = token.callback
        local params = token.params
        if callback == 'create_kaboom' then
            create_kaboom(params.entity, params.explosion)
        elseif callback == 'create_flying_text' then
            create_flying_text(params.entity, params.message)
        end
    end
    traps[game.tick] = nil
end

Event.add(defines.events.on_tick, on_tick)

return Public
