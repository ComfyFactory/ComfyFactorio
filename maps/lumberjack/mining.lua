local WPT = require 'maps.lumberjack.table'

local Public = {}

local max_spill = 60
local math_random = math.random
local math_floor = math.floor
local math_sqrt = math.sqrt

local valid_types = {
    ['tree'] = true,
    ['simple-entity'] = true
}

local function create_particles(surface, name, position, amount, cause_position)
    local d1 = (-100 + math_random(0, 200)) * 0.0004
    local d2 = (-100 + math_random(0, 200)) * 0.0004

    if cause_position then
        d1 = (cause_position.x - position.x) * 0.025
        d2 = (cause_position.y - position.y) * 0.025
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
                    (m2 - (math_random(0, m) * 0.01)) + d1,
                    (m2 - (math_random(0, m) * 0.01)) + d2
                }
            }
        )
    end
end

local function mining_chances_ores()
    local data = {
        {name = 'iron-ore', chance = 545},
        {name = 'copper-ore', chance = 545},
        {name = 'coal', chance = 545},
        {name = 'stone', chance = 545},
        {name = 'uranium-ore', chance = 200}
    }
    return data
end

local harvest_raffle_ores = {}
for _, t in pairs(mining_chances_ores()) do
    for _ = 1, t.chance, 1 do
        table.insert(harvest_raffle_ores, t.name)
    end
end

local size_of_ore_raffle = #harvest_raffle_ores

local function get_amount(data)
    local entity = data.entity
    local this = data.this
    local distance_to_center = math_floor(math_sqrt(entity.position.x ^ 2 + entity.position.y ^ 2))
    local type_modifier
    local amount
    local second_amount

    local distance_modifier = 0.25
    local base_amount = 25
    local second_base_amount = 10
    local maximum_amount = 100
    if this.type_modifier then
        type_modifier = this.type_modifier
    end
    if this.rocks_yield_ore_distance_modifier then
        distance_modifier = this.rocks_yield_ore_distance_modifier
    end

    if this.rocks_yield_ore_base_amount then
        base_amount = this.rocks_yield_ore_base_amount
    end
    if this.rocks_yield_ore_maximum_amount then
        maximum_amount = this.rocks_yield_ore_maximum_amount
    end

    amount = base_amount + (distance_to_center * distance_modifier)
    second_amount = math_floor((second_base_amount + (distance_to_center * distance_modifier)) / 3)
    if amount > maximum_amount then
        amount = maximum_amount
    end
    if second_amount > maximum_amount then
        second_amount = maximum_amount
    end

    local m = (70 + math_random(0, 60)) * 0.01

    amount = math_floor(amount * type_modifier * m * 0.7)

    return amount, second_amount
end

local function randomness(data)
    local entity = data.entity
    local player = data.player
    local harvest
    local second_harvest
    local harvest_amount
    local second_harvest_amount

    if entity.type == 'simple-entity' then
        harvest = harvest_raffle_ores[math.random(1, size_of_ore_raffle)]
        second_harvest = 'stone'
        harvest_amount, second_harvest_amount = get_amount(data)
    else
        harvest = harvest_raffle_ores[math.random(1, size_of_ore_raffle)]
        second_harvest = 'wood'
        harvest_amount, second_harvest_amount = get_amount(data)
    end

    local position = {x = entity.position.x, y = entity.position.y}

    if second_harvest then
        player.surface.create_entity(
            {
                name = 'flying-text',
                position = position,
                text = '+' ..
                    harvest_amount ..
                        ' [img=item/' ..
                            harvest .. ']\n+' .. second_harvest_amount .. ' [img=item/' .. second_harvest .. ']',
                color = {r = math_random(1, 200), g = 160, b = 30}
            }
        )
        player.insert({name = second_harvest, count = second_harvest_amount})
    else
        player.surface.create_entity(
            {
                name = 'flying-text',
                position = position,
                text = '+' .. harvest_amount .. ' [img=item/' .. harvest .. ']',
                color = {r = math_random(1, 200), g = 160, b = 30}
            }
        )
    end

    if harvest_amount > max_spill then
        player.surface.spill_item_stack(position, {name = harvest, count = max_spill}, true)
        harvest_amount = harvest_amount - max_spill
        local inserted_count = player.insert({name = harvest, count = harvest_amount})
        harvest_amount = harvest_amount - inserted_count
        if harvest_amount > 0 then
            player.surface.spill_item_stack(position, {name = harvest, count = harvest_amount}, true)
        end
    else
        player.surface.spill_item_stack(position, {name = harvest, count = harvest_amount}, true)
    end

    create_particles(player.surface, 'shell-particle', position, 64, {x = player.position.x, y = player.position.y})
end

function Public.on_player_mined_entity(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if not valid_types[entity.type] then
        return
    end

    local player = game.players[event.player_index]
    local this = WPT.get_table()
    if not player then
        return
    end

    event.buffer.clear()

    local data = {
        this = this,
        entity = entity,
        player = player
    }

    randomness(data)
end

function Public.on_entity_died(event)
    if not event.entity.valid then
        return
    end
    if event.entity.type == 'tree' then
        for _, entity in pairs(
            event.entity.surface.find_entities_filtered(
                {
                    area = {
                        {event.entity.position.x - 4, event.entity.position.y - 4},
                        {event.entity.position.x + 4, event.entity.position.y + 4}
                    },
                    name = 'fire-flame-on-tree'
                }
            )
        ) do
            if entity.valid then
                entity.destroy()
            end
        end
    end
end

return Public
