local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local Math = require 'utils.math.math'

local tick_tacks = { '*tick*', '*tick*', '*tack*', '*tak*', '*tik*', '*tok*', '*run*' }

local kaboom_weights =
{
    { name = 'grenade', chance = 7 },
    { name = 'cluster-grenade', chance = 1 },
    { name = 'destroyer-capsule', chance = 1 },
    { name = 'defender-capsule', chance = 4 },
    { name = 'distractor-capsule', chance = 2 },
    { name = 'poison-capsule', chance = 2 },
    { name = 'coin', chance = 2 },
    { name = 'explosive-uranium-cannon-projectile', chance = 3 },
    { name = 'explosive-cannon-projectile', chance = 5 }
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
        local rng = Math.random(1, 512)
        local chest = 'crash-site-chest-' .. Math.random(1, 2)

        local container = entity.surface.create_entity({ name = chest, position = entity.position, force = 'neutral' })
        if container and container.health then
            container.insert({ name = 'coin', count = rng })
            container.health = Math.random(1, container.health)
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

local death_blast_profiles =
{
    small = { radius = 4, damage = 220, structure_damage = 100 },
    medium = { radius = 5, damage = 400, structure_damage = 120 },
    big = { radius = 6.5, damage = 700, structure_damage = 140 },
    behemoth = { radius = 8, damage = 1000, structure_damage = 160 }
}

local function death_blast_warning(params)
    if not params.surface.valid then return end
    for _, player in pairs(game.connected_players) do
        if player.surface == params.surface then
            player.create_local_flying_text(
                {
                    position = params.position,
                    text = tick_tacks[Math.random(1, #tick_tacks)],
                    color = { r = 0.75, g = 0.75, b = 0.75 }
                }
            )
        end
    end
    params.surface.play_sound({ path = 'utility/armor_insert', position = params.position, volume_modifier = 0.75 })
end

local function create_death_blast_ring(params)
    if not params.surface.valid then return end
    for index = 1, params.count do
        local angle = params.angle + index * Math.pi * 2 / params.count
        params.surface.create_entity(
            {
                name = 'explosion',
                position =
                {
                    x = params.position.x + Math.cos(angle) * params.radius,
                    y = params.position.y + Math.sin(angle) * params.radius
                }
            }
        )
    end
end

local function create_death_blast(params)
    local surface = params.surface
    local force = params.force
    if not surface.valid or not force.valid then return end

    local radius = params.radius or 3
    local damage = params.damage or 100
    local structure_damage = params.structure_damage or Math.min(damage, 160)
    surface.create_entity({ name = 'big-explosion', position = params.position })
    local traps = Public.get('traps')
    for ring = 1, 2 do
        local tick = game.tick + ring * 4
        traps[tick] = traps[tick] or {}
        traps[tick][#traps[tick] + 1] =
        {
            callback = 'create_death_blast_ring',
            params =
            {
                surface = surface,
                position = params.position,
                radius = radius * ring / 2,
                count = 4 + ring * 2,
                angle = Math.random(0, 359) * Math.pi / 180
            }
        }
    end
    for _, target in pairs(surface.find_entities_filtered({ position = params.position, radius = radius })) do
        if target.valid and target.health then
            local target_force = target.force
            if target_force ~= force and not Public.valid_enemy_forces[target_force.name]
                and not force.get_friend(target_force) and not target_force.get_friend(force)
                and not force.get_cease_fire(target_force) and not target_force.get_cease_fire(force) then
                local dx = target.position.x - params.position.x
                local dy = target.position.y - params.position.y
                local distance = Math.sqrt(dx * dx + dy * dy)
                if distance <= radius then
                    local falloff = 0.25 + 0.75 * (1 - distance / radius) ^ 2
                    local peak = target.type == 'character' and damage or structure_damage
                    target.damage(Math.max(1, Math.floor(peak * falloff)), force, 'explosion')
                end
            end
        end
    end
end

function Public.tick_tack_trap(entity, death_blast)
    if not entity or not entity.valid then return end

    local traps = Public.get('traps')
    if death_blast then
        local name = entity.name
        local tier = name:find('behemoth', 1, true) and 'behemoth'
            or name:find('big', 1, true) and 'big'
            or name:find('medium', 1, true) and 'medium' or 'small'
        local profile = death_blast_profiles[tier]
        local delay = Math.random(150, 210)
        local params =
        {
            surface = entity.surface,
            position = { x = entity.position.x, y = entity.position.y },
            force = entity.force,
            radius = profile.radius + Math.random(-2, 2) * 0.25,
            damage = Math.floor(profile.damage * Math.random(90, 110) / 100),
            structure_damage = profile.structure_damage
        }
        death_blast_warning(params)
        rendering.draw_circle(
            {
                color = { r = 1, g = 0.35, b = 0.1, a = 0.8 },
                radius = params.radius,
                width = 2,
                filled = false,
                target = params.position,
                surface = params.surface,
                time_to_live = delay,
                draw_on_ground = true
            }
        )
        for elapsed = 60, delay - 1, 60 do
            local tick = game.tick + elapsed
            traps[tick] = traps[tick] or {}
            traps[tick][#traps[tick] + 1] = { callback = 'death_blast_warning', params = params }
        end
        local tick = game.tick + delay
        traps[tick] = traps[tick] or {}
        traps[tick][#traps[tick] + 1] = { callback = 'create_death_blast', params = params }
        return
    end
    local tick_tack_count = Math.random(5, 9)
    for t = 60, tick_tack_count * 60, 60 do
        if not traps[game.tick + t] then
            traps[game.tick + t] = {}
        end

        if t < tick_tack_count * 60 then
            traps[game.tick + t][#traps[game.tick + t] + 1] =
            {
                callback = 'create_flying_text',
                params = { entity = entity, message = tick_tacks[Math.random(1, #tick_tacks)] }
            }
        else
            if Math.random(1, 10) == 1 then
                traps[game.tick + t][#traps[game.tick + t] + 1] =
                {
                    callback = 'create_flying_text',
                    params = { entity = entity, message = '( ͡° ͜ʖ ͡°)' }
                }
            else
                traps[game.tick + t][#traps[game.tick + t] + 1] =
                {
                    callback = 'create_kaboom',
                    params = { entity = entity, explosion = kabooms[Math.random(1, #kabooms)] }
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
        if callback == 'create_death_blast' then
            create_death_blast(params)
        elseif callback == 'create_death_blast_ring' then
            create_death_blast_ring(params)
        elseif callback == 'death_blast_warning' then
            death_blast_warning(params)
        elseif callback == 'create_kaboom' then
            create_kaboom(params.entity, params.explosion)
        elseif callback == 'create_flying_text' then
            create_flying_text(params.entity, params.message)
        end
    end
    traps[game.tick] = nil
end

Event.add(defines.events.on_tick, on_tick)

return Public
