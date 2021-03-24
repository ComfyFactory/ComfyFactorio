local Functions = require 'maps.cave_miner_v2.functions'

local max_spill = 60
local math_random = math.random
local math_floor = math.floor
local math_sqrt = math.sqrt

local rock_yield = {
    ['rock-big'] = 1,
    ['rock-huge'] = 2,
    ['sand-rock-big'] = 1
}

local particles = {
    ['iron-ore'] = 'iron-ore-particle',
    ['copper-ore'] = 'copper-ore-particle',
    ['uranium-ore'] = 'coal-particle',
    ['coal'] = 'coal-particle',
    ['stone'] = 'stone-particle',
    ['angels-ore1'] = 'iron-ore-particle',
    ['angels-ore2'] = 'copper-ore-particle',
    ['angels-ore3'] = 'coal-particle',
    ['angels-ore4'] = 'iron-ore-particle',
    ['angels-ore5'] = 'iron-ore-particle',
    ['angels-ore6'] = 'iron-ore-particle'
}

local function get_ore_name(position)
    local surface = game.surfaces.cave_miner_source
    local seed = surface.map_gen_settings.seed
    local tile_name = Functions.get_base_ground_tile(position, seed)
    if tile_name == 'dirt-7' then
        if math_random(1, 2) == 1 then
            return 'iron-ore'
        else
            return 'copper-ore'
        end
    end
    if math_random(1, 16) == 1 then
        return 'uranium-ore'
    else
        return 'coal'
    end
end

local function create_particles(surface, name, position, amount, cause_position)
    local direction_mod = (-100 + math_random(0, 200)) * 0.0004
    local direction_mod_2 = (-100 + math_random(0, 200)) * 0.0004

    if cause_position then
        direction_mod = (cause_position.x - position.x) * 0.025
        direction_mod_2 = (cause_position.y - position.y) * 0.025
    end

    for i = 1, amount, 1 do
        local m = math_random(4, 10)
        local m2 = m * 0.005

        surface.create_particle(
            {
                name = name,
                position = position,
                frame_speed = 1,
                vertical_speed = 0.130,
                height = 0,
                movement = {
                    (m2 - (math_random(0, m) * 0.01)) + direction_mod,
                    (m2 - (math_random(0, m) * 0.01)) + direction_mod_2
                }
            }
        )
    end
end

local function get_amount(entity)
    local distance_to_center = math_floor(math_sqrt(entity.position.x ^ 2 + entity.position.y ^ 2))

    local amount = global.rocks_yield_ore_base_amount + (distance_to_center * global.rocks_yield_ore_distance_modifier)
    if amount > global.rocks_yield_ore_maximum_amount then
        amount = global.rocks_yield_ore_maximum_amount
    end

    local m = (70 + math_random(0, 60)) * 0.01

    amount = math_floor(amount * rock_yield[entity.name] * m)
    if amount < 1 then
        amount = 1
    end

    return amount
end

local function on_player_mined_entity(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if not rock_yield[entity.name] then
        return
    end

    event.buffer.clear()

    local ore = get_ore_name(entity.position)
    local player = game.players[event.player_index]

    local count = get_amount(entity)
    count = math_floor(count * (1 + player.force.mining_drill_productivity_bonus))

    global.rocks_yield_ore['ores_mined'] = global.rocks_yield_ore['ores_mined'] + count
    global.rocks_yield_ore['rocks_broken'] = global.rocks_yield_ore['rocks_broken'] + 1

    local position = {x = entity.position.x, y = entity.position.y}

    local stone_m = math_random(10, 30) * 0.01
    local ore_amount = math_floor(count * (1 - stone_m)) + 1
    local stone_amount = math_floor(count * stone_m) + 1

    player.surface.create_entity(
        {
            name = 'flying-text',
            position = position,
            text = '+' .. ore_amount .. ' [img=item/' .. ore .. ']  +' .. stone_amount .. ' [img=item/stone]',
            color = {r = 200, g = 160, b = 30}
        }
    )
    create_particles(player.surface, particles[ore], position, 64, {x = player.position.x, y = player.position.y})

    entity.destroy()

    if ore_amount > max_spill then
        player.surface.spill_item_stack(position, {name = ore, count = max_spill}, true)
        ore_amount = ore_amount - max_spill
        local inserted_count = player.insert({name = ore, count = ore_amount})
        ore_amount = ore_amount - inserted_count
        if ore_amount > 0 then
            player.surface.spill_item_stack(position, {name = ore, count = ore_amount}, true)
        end
    else
        player.surface.spill_item_stack(position, {name = ore, count = ore_amount}, true)
    end

    if stone_amount > max_spill then
        player.surface.spill_item_stack(position, {name = 'stone', count = max_spill}, true)
        stone_amount = stone_amount - max_spill
        local inserted_count = player.insert({name = 'stone', count = stone_amount})
        stone_amount = stone_amount - inserted_count
        if stone_amount > 0 then
            player.surface.spill_item_stack(position, {name = 'stone', count = stone_amount}, true)
        end
    else
        player.surface.spill_item_stack(position, {name = 'stone', count = stone_amount}, true)
    end
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if not rock_yield[entity.name] then
        return
    end

    local surface = entity.surface
    local ore = get_ore_name(entity.position)
    local pos = {entity.position.x, entity.position.y}
    create_particles(surface, particles[ore], pos, 16, false)

    if event.cause then
        if event.cause.valid then
            if event.cause.force.index == 2 or event.cause.force.index == 3 then
                entity.destroy()
                return
            end
        end
    end

    entity.destroy()

    local count = math_random(7, 15)
    global.rocks_yield_ore['ores_mined'] = global.rocks_yield_ore['ores_mined'] + count
    surface.spill_item_stack(pos, {name = ore, count = count}, true)

    local count = math_random(2, 8)
    global.rocks_yield_ore['ores_mined'] = global.rocks_yield_ore['ores_mined'] + count
    surface.spill_item_stack(pos, {name = 'stone', count = math_random(1, 3)}, true)

    global.rocks_yield_ore['rocks_broken'] = global.rocks_yield_ore['rocks_broken'] + 1
end

local function on_init()
    global.rocks_yield_ore = {}
    global.rocks_yield_ore['rocks_broken'] = 0
    global.rocks_yield_ore['ores_mined'] = 0

    if not global.rocks_yield_ore_distance_modifier then
        global.rocks_yield_ore_distance_modifier = 0.25
    end
    if not global.rocks_yield_ore_base_amount then
        global.rocks_yield_ore_base_amount = 35
    end
    if not global.rocks_yield_ore_maximum_amount then
        global.rocks_yield_ore_maximum_amount = 150
    end
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
