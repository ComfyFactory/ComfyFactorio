--destroying and mining rocks yields ore -- load as last module
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

local function get_chances()
    local chances = {}

    if prototypes.entity['angels-ore1'] then
        for i = 1, 6, 1 do
            table.insert(chances, { 'angels-ore' .. i, 1 })
        end
        table.insert(chances, { 'coal', 2 })
        return chances
    end

    table.insert(chances, { 'iron-ore', 25 })
    table.insert(chances, { 'copper-ore', 17 })
    table.insert(chances, { 'coal', 13 })
    table.insert(chances, { 'uranium-ore', 2 })

    return chances
end

local function set_raffle()
    storage.rocks_yield_ore['raffle'] = {}
    for _, t in pairs(get_chances()) do
        for _ = 1, t[2], 1 do
            table.insert(storage.rocks_yield_ore['raffle'], t[1])
        end
    end
    storage.rocks_yield_ore['size_of_raffle'] = #storage.rocks_yield_ore['raffle']
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

    local amount = storage.rocks_yield_ore_base_amount + (distance_to_center * storage.rocks_yield_ore_distance_modifier)
    if amount > storage.rocks_yield_ore_maximum_amount then
        amount = storage.rocks_yield_ore_maximum_amount
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

    local ore = storage.rocks_yield_ore['raffle'][math_random(1, storage.rocks_yield_ore['size_of_raffle'])]
    local player = game.players[event.player_index]

    local count = get_amount(entity)
    count = math_floor(count * (1 + player.force.mining_drill_productivity_bonus))

    storage.rocks_yield_ore['ores_mined'] = storage.rocks_yield_ore['ores_mined'] + count
    storage.rocks_yield_ore['rocks_broken'] = storage.rocks_yield_ore['rocks_broken'] + 1

    local position = { x = entity.position.x, y = entity.position.y }

    local ore_amount = math_floor(count * 0.85) + 1
    local stone_amount = math_floor(count * 0.15) + 1

    player.surface.create_entity({ name = 'flying-text', position = position, text = '+' .. ore_amount .. ' [img=item/' .. ore .. ']', color = { r = 200, g = 160, b = 30 } })
    create_particles(player.surface, particles[ore], position, 64, { x = player.position.x, y = player.position.y })

    entity.destroy()

    if ore_amount > max_spill then
        player.surface.spill_item_stack(position, { name = ore, count = max_spill }, true)
        ore_amount = ore_amount - max_spill
        local inserted_count = player.insert({ name = ore, count = ore_amount })
        ore_amount = ore_amount - inserted_count
        if ore_amount > 0 then
            player.surface.spill_item_stack(position, { name = ore, count = ore_amount }, true)
        end
    else
        player.surface.spill_item_stack(position, { name = ore, count = ore_amount }, true)
    end

    if stone_amount > max_spill then
        player.surface.spill_item_stack(position, { name = 'stone', count = max_spill }, true)
        stone_amount = stone_amount - max_spill
        local inserted_count = player.insert({ name = 'stone', count = stone_amount })
        stone_amount = stone_amount - inserted_count
        if stone_amount > 0 then
            player.surface.spill_item_stack(position, { name = 'stone', count = stone_amount }, true)
        end
    else
        player.surface.spill_item_stack(position, { name = 'stone', count = stone_amount }, true)
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
    local ore = storage.rocks_yield_ore['raffle'][math_random(1, storage.rocks_yield_ore['size_of_raffle'])]
    local pos = { entity.position.x, entity.position.y }
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

    local count = math_random(6, 9)
    storage.rocks_yield_ore['ores_mined'] = storage.rocks_yield_ore['ores_mined'] + count
    surface.spill_item_stack(pos, { name = ore, count = count }, true)

    count = math_random(1, 3)
    storage.rocks_yield_ore['ores_mined'] = storage.rocks_yield_ore['ores_mined'] + count
    surface.spill_item_stack(pos, { name = 'stone', count = math_random(1, 3) }, true)

    storage.rocks_yield_ore['rocks_broken'] = storage.rocks_yield_ore['rocks_broken'] + 1
end

local function on_init()
    storage.rocks_yield_ore = {}
    storage.rocks_yield_ore['rocks_broken'] = 0
    storage.rocks_yield_ore['ores_mined'] = 0
    set_raffle()

    if not storage.rocks_yield_ore_distance_modifier then
        storage.rocks_yield_ore_distance_modifier = 0.25
    end
    if not storage.rocks_yield_ore_base_amount then
        storage.rocks_yield_ore_base_amount = 35
    end
    if not storage.rocks_yield_ore_maximum_amount then
        storage.rocks_yield_ore_maximum_amount = 150
    end
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
