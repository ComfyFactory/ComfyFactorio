local WPT = require 'maps.lumberjack.table'

local Public = {}

local max_spill = 60
local math_random = math.random
local math_floor = math.floor
local math_sqrt = math.sqrt

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

local function mining_chances_ores()
    local data = {
        {name = 'tree', chance = 500},
        {name = 'iron-ore', chance = 570},
        {name = 'copper-ore', chance = 570},
        {name = 'stone', chance = 550},
        {name = 'coal', chance = 545},
        {name = 'uranium-ore', chance = 1}
    }
    return data
end

local function ore_yield_amounts()
    local data = {
        ['iron-ore'] = 28,
        ['copper-ore'] = 28,
        ['stone'] = 20,
        ['coal'] = 28,
        ['uranium-ore'] = 1,
        ['tree-01'] = 1,
        ['tree-02'] = 1,
        ['tree-02-red'] = 1,
        ['tree-03'] = 1,
        ['tree-04'] = 1,
        ['tree-05'] = 1,
        ['tree-06'] = 1,
        ['tree-07'] = 1,
        ['tree-08'] = 1,
        ['tree-08-red'] = 1,
        ['tree-09'] = 1,
        ['tree-09-brown'] = 1,
        ['tree-09-red'] = 1
    }
    return data
end

local tree_raffle_ores = {}
for _, t in pairs(mining_chances_ores()) do
    for _ = 1, t.chance, 1 do
        table.insert(tree_raffle_ores, t.name)
    end
end

local size_of_ore_raffle = #tree_raffle_ores

local function get_amount(data)
    local entity = data.entity
    local this = data.this
    local distance_to_center = math_floor(math_sqrt(entity.position.x ^ 2 + entity.position.y ^ 2))

    local distance_modifier = 0.25
    local base_amount = 35
    local maximum_amount = 100
    if this.rocks_yield_ore_distance_modifier then
        distance_modifier = this.rocks_yield_ore_distance_modifier
    end
    if this.rocks_yield_ore_base_amount then
        base_amount = this.rocks_yield_ore_base_amount
    end
    if this.rocks_yield_ore_maximum_amount then
        maximum_amount = this.rocks_yield_ore_maximum_amount
    end

    local amount = base_amount + (distance_to_center * distance_modifier)
    if amount > maximum_amount then
        amount = maximum_amount
    end

    local m = (70 + math_random(0, 60)) * 0.01

    amount = math_floor(amount * ore_yield_amounts()[entity.name] * m)
    if amount < 1 then
        amount = 1
    end

    return amount
end

local function tree_randomness(data)
    local entity = data.entity
    local player = data.player
    local tree
    local tree_amount

    if not ore_yield_amounts()[entity.name] then
        tree = 'wood'
        data.tree = tree
        tree_amount = 2

        goto continue
    end

    tree = tree_raffle_ores[math.random(1, size_of_ore_raffle)]

    data.tree = tree

    tree_amount = get_amount(data)
    ::continue::

    local position = {x = entity.position.x, y = entity.position.y}

    if tree_amount > max_spill then
        if tree == 'tree' then
            tree = 'wood'
        end

        player.surface.spill_item_stack(position, {name = tree, count = max_spill}, true)
        tree_amount = tree_amount - max_spill
        local inserted_count = player.insert({name = tree, count = tree_amount})
        tree_amount = tree_amount - inserted_count
        if tree_amount > 0 then
            player.surface.spill_item_stack(position, {name = tree, count = tree_amount}, true)
        end
    else
        if tree == 'tree' then
            tree = 'wood'
        end
        player.surface.spill_item_stack(position, {name = tree, count = tree_amount}, true)
    end

    if tree_amount <= 0 then
        tree_amount = math_random(1, 10)
    end

    player.surface.create_entity(
        {
            name = 'flying-text',
            position = position,
            text = '+' .. tree_amount .. ' [img=item/' .. tree .. ']',
            color = {r = 200, g = 160, b = 30}
        }
    )

    create_particles(player.surface, 'shell-particle', position, 64, {x = player.position.x, y = player.position.y})
end

function Public.on_player_mined_entity(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if entity.type ~= 'tree' then
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

    tree_randomness(data)
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
