local WPT = require 'maps.mountain_fortress_v3.table'
require 'modules.check_fullness'

local Public = {}
local random = math.random
local floor = math.floor
local sqrt = math.sqrt

local max_spill = 60

local valid_rocks = {
    ['sand-rock-big'] = true,
    ['rock-big'] = true,
    ['rock-huge'] = true
}

local valid_trees = {
    ['dry-tree'] = true,
    ['tree-01'] = true,
    ['tree-02-red'] = true,
    ['tree-03'] = true,
    ['tree-04'] = true,
    ['tree-08-brown'] = true
}

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
    ['stone'] = 'stone-particle'
}

local function create_particles(surface, name, position, amount, cause_position)
    local d1 = (-100 + random(0, 200)) * 0.0004
    local d2 = (-100 + random(0, 200)) * 0.0004

    name = name or 'leaf-particle'

    if cause_position then
        d1 = (cause_position.x - position.x) * 0.025
        d2 = (cause_position.y - position.y) * 0.025
    end

    for i = 1, amount, 1 do
        local m = random(4, 10)
        local m2 = m * 0.005

        surface.create_particle(
            {
                name = name,
                position = position,
                frame_speed = 1,
                vertical_speed = 0.130,
                height = 0,
                movement = {
                    (m2 - (random(0, m) * 0.01)) + d1,
                    (m2 - (random(0, m) * 0.01)) + d2
                }
            }
        )
    end
end

local function mining_chances_ores()
    local data = {
        {name = 'iron-ore', chance = 545},
        {name = 'copper-ore', chance = 540},
        {name = 'coal', chance = 545},
        {name = 'stone', chance = 545},
        {name = 'uranium-ore', chance = 45}
    }
    return data
end

local harvest_raffle_ores = {}
for _, t in pairs(mining_chances_ores()) do
    for _ = 1, t.chance, 1 do
        harvest_raffle_ores[#harvest_raffle_ores + 1] = t.name
    end
end

local size_of_ore_raffle = #harvest_raffle_ores

local function get_amount(data)
    local entity = data.entity
    local this = data.this
    local distance_to_center = floor(sqrt(entity.position.x ^ 2 + entity.position.y ^ 2))
    local type_modifier = 1
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

    type_modifier = rock_yield[entity.name] or type_modifier

    amount = base_amount + (distance_to_center * distance_modifier)
    second_amount = floor((second_base_amount + (distance_to_center * distance_modifier)) / 3)
    if amount > maximum_amount then
        amount = maximum_amount
    end
    if second_amount > maximum_amount then
        second_amount = maximum_amount
    end

    local m = (70 + random(0, 60)) * 0.01

    amount = floor(amount * type_modifier * m * 0.7)

    return amount, second_amount
end

function Public.entity_died_randomness(data)
    local entity = data.entity
    local surface = data.surface
    local harvest

    harvest = harvest_raffle_ores[random(1, size_of_ore_raffle)]

    local position = {x = entity.position.x, y = entity.position.y}

    surface.spill_item_stack(position, {name = harvest, count = random(1, 5)}, true)
    local particle = particles[harvest]
    create_particles(surface, particle, position, 64, {x = entity.position.x, y = entity.position.y})
end

local function randomness(data)
    local entity = data.entity
    local player = data.player
    local this = data.this
    local harvest
    local harvest_amount

    local n = entity.name
    if n == 'tree-08-brown' then
        harvest = 'stone'
    elseif n == 'tree-04' then
        harvest = 'coal'
    elseif n == 'tree-02-red' then
        harvest = 'copper-ore'
    elseif n == 'tree-01' then
        harvest = 'iron-ore'
    elseif n == 'tree-03' then
        harvest = 'coal'
    elseif n == 'dry-tree' then
        harvest = 'wood'
    else
        harvest = harvest_raffle_ores[random(1, size_of_ore_raffle)]
    end
    harvest_amount = get_amount(data)

    local position = {x = entity.position.x, y = entity.position.y}

    player.surface.create_entity(
        {
            name = 'flying-text',
            position = position,
            text = '+' .. harvest_amount .. ' [img=item/' .. harvest .. ']',
            color = {r = 0, g = 127, b = 33}
        }
    )

    if harvest_amount > max_spill then
        if this.spill_items_to_surface then
            player.surface.spill_item_stack(position, {name = harvest, count = max_spill}, true)
        else
            player.insert({name = harvest, count = max_spill})
        end
        harvest_amount = harvest_amount - max_spill
        local inserted_count = player.insert({name = harvest, count = harvest_amount})
        harvest_amount = harvest_amount - inserted_count
        if harvest_amount > 0 then
            if this.spill_items_to_surface then
                player.surface.spill_item_stack(position, {name = harvest, count = harvest_amount}, true)
            else
                player.insert({name = harvest, count = harvest_amount})
            end
        end
    else
        if this.spill_items_to_surface then
            player.surface.spill_item_stack(position, {name = harvest, count = harvest_amount}, true)
        else
            player.insert({name = harvest, count = harvest_amount})
        end
    end
    local particle = particles[harvest]
    create_particles(player.surface, particle, position, 64, {x = player.position.x, y = player.position.y})
end

function Public.on_player_mined_entity(event)
    local entity = event.entity
    if not entity.valid then
        return
    end

    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    local this = WPT.get()

    if valid_rocks[entity.name] or valid_trees[entity.name] then
        event.buffer.clear()

        local data = {
            this = this,
            entity = entity,
            player = player
        }

        randomness(data)
    end
end

return Public
