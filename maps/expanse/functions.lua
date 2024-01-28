local Price_raffle = require 'maps.expanse.price_raffle'
local BiterRaffle = require 'utils.functions.biter_raffle'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Public = {}

local ores = {'copper-ore', 'iron-ore', 'stone', 'coal'}
local price_modifiers = {
    ['unit-spawner'] = -256,
    ['unit'] = -16,
    ['turret'] = -128,
    ['tree'] = -8,
    ['simple-entity'] = 2,
    ['cliff'] = -128,
    ['water'] = -5,
    ['water-green'] = -5,
    ['deepwater'] = -5,
    ['deepwater-green'] = -5,
    ['water-mud'] = -6,
    ['water-shallow'] = -6
}

--- Some mods like to destroy the infini tree.
--- So we solve it by delaying the creation.
local delay_infini_tree_token =
    Token.register(
    function(event)
        local surface = event.surface
        local position = event.position

        surface.create_entity({name = 'tree-0' .. math.random(1, 9), position = position})
    end
)

local function reward_tokens(expanse, entity)
    local chance = expanse.token_chance % 1
    local count = math.floor(expanse.token_chance)

    if chance > 0 then
        chance = math.floor(chance * 1000)
        if math.random(1, 1000) <= chance then
            entity.surface.spill_item_stack(entity.position, {name = 'coin', count = 1}, true, nil, false)
        end
    end
    if count > 0 then
        for _ = 1, count, 1 do
            entity.surface.spill_item_stack(entity.position, {name = 'coin', count = 1}, true, nil, false)
        end
    end
end

local function get_cell_value(expanse, left_top)
    local square_size = expanse.square_size
    local value = square_size ^ 2
    value = value * 8

    local source_surface = game.surfaces[expanse.source_surface]
    local area = {{left_top.x, left_top.y}, {left_top.x + square_size, left_top.y + square_size}}
    local entities = source_surface.find_entities(area)
    local tiles = source_surface.find_tiles_filtered({area = area})

    for _, tile in pairs(tiles) do
        if price_modifiers[tile.name] then
            value = value + price_modifiers[tile.name]
        end
    end
    for _, entity in pairs(entities) do
        if price_modifiers[entity.type] then
            value = value + price_modifiers[entity.type]
        end
    end

    local distance = math.sqrt(left_top.x ^ 2 + left_top.y ^ 2)
    value = value * ((distance ^ 1.1) * expanse.price_distance_modifier)
    local ore_modifier = distance * (expanse.price_distance_modifier / 20)
    if ore_modifier > expanse.max_ore_price_modifier then
        ore_modifier = expanse.max_ore_price_modifier
    end

    for _, entity in pairs(entities) do
        if entity.type == 'resource' then
            if entity.prototype.resource_category == 'basic-fluid' then
                value = value + (entity.amount * ore_modifier * 0.01)
            else
                value = value + (entity.amount * ore_modifier)
            end
        end
    end

    value = math.floor(value)
    if value < 16 then
        value = 16
    end

    return value
end

local function get_left_top(expanse, position)
    local vectors = {{-1, 0}, {1, 0}, {0, 1}, {0, -1}}
    table.shuffle_table(vectors)

    local surface = game.surfaces.expanse

    for _, v in pairs(vectors) do
        local tile = surface.get_tile({position.x + v[1], position.y + v[2]})
        if tile.name == 'out-of-map' then
            local left_top = tile.position
            left_top.x = left_top.x - left_top.x % expanse.square_size
            left_top.y = left_top.y - left_top.y % expanse.square_size
            if not expanse.grid[tostring(left_top.x .. '_' .. left_top.y)] then
                return left_top
            end
        end
    end

    return false
end

local function is_container_position_valid(expanse, position)
    if game.tick == 0 then
        return true
    end

    local left_top = get_left_top(expanse, position)
    if not left_top then
        return false
    end

    if
        game.surfaces.expanse.count_entities_filtered(
            {
                name = 'logistic-chest-requester',
                force = 'neutral',
                area = {{left_top.x - 1, left_top.y - 1}, {left_top.x + expanse.square_size + 1, left_top.y + expanse.square_size + 1}}
            }
        ) > 0
     then
        return false
    end

    return true
end

local function create_costs_render(entity, name, offset)
    local id =
        rendering.draw_sprite {
        sprite = 'virtual-signal/signal-grey',
        surface = entity.surface,
        target = entity,
        x_scale = 1.1,
        y_scale = 1.1,
        render_layer = '190',
        target_offset = {offset, -1.5},
        only_in_alt_mode = true
    }
    local id2 =
        rendering.draw_sprite {
        sprite = 'item/' .. name,
        surface = entity.surface,
        target = entity,
        x_scale = 0.75,
        y_scale = 0.75,
        render_layer = '191',
        target_offset = {offset, -1.5},
        only_in_alt_mode = true
    }
    return {id, id2}
end

local function remove_one_render(container, key)
    if rendering.is_valid(container.price[key].render[1]) then
        rendering.destroy(container.price[key].render[1])
    end
    if rendering.is_valid(container.price[key].render[2]) then
        rendering.destroy(container.price[key].render[2])
    end
end

local function remove_old_renders(container)
    for key, _ in pairs(container.price) do
        remove_one_render(container, key)
    end
end

function Public.spawn_units(spawner)
    local evolution = game.forces.enemy.evolution_factor
    local position = spawner.position
    for i = 1, 4 + math.floor(8 * evolution), 1 do
        local biter_roll = BiterRaffle.roll('mixed', evolution)
        local free_pos = spawner.surface.find_non_colliding_position(biter_roll, {x = position.x + math.random(-8, 8), y = position.y + math.random(-8, 8)}, 12, 0.05)
        spawner.surface.create_entity({name = biter_roll, position = free_pos or position, force = 'enemy'})
    end
end

function Public.get_item_tooltip(name)
    return {'expanse.stats_item_tooltip', game.item_prototypes[name].localised_name, Price_raffle.get_item_worth(name)}
end

function Public.invasion_numbers()
    local evo = game.forces.enemy.evolution_factor
    return {candidates = 3 + math.floor(evo * 10), groups = 1 + math.floor(evo * 4)}
end

function Public.invasion_warn(event)
    local seconds = (120 * 60 - event.delay) / 60
    game.print({'expanse.biters_invasion_warning', seconds, event.size}, {r = 0.88, g = 0.22, b = 0.22})
end

function Public.invasion_detonate(event)
    local surface = event.surface
    local position = event.position
    local entities_close = surface.find_entities_filtered {position = position, radius = 8}
    for _, entity in pairs(entities_close) do
        if entity.valid then
            entity.die('enemy')
        end
    end
    local entities_nearby = surface.find_entities_filtered {position = position, radius = 16}
    for _, entity in pairs(entities_nearby) do
        if entity.valid and entity.is_entity_with_health then
            entity.damage(entity.prototype.max_health * 0.75, 'enemy')
        end
    end
    surface.create_entity({name = 'nuke-explosion', position = position})
end

function Public.invasion_trigger(event)
    local surface = event.surface
    local position = event.position
    local round = event.round
    local evolution = game.forces.enemy.evolution_factor
    local biters = {}
    for i = 1, 5 + math.floor(30 * evolution) + round * 5, 1 do
        local biter_roll = BiterRaffle.roll('mixed', evolution)
        local free_pos = surface.find_non_colliding_position(biter_roll, {x = position.x + math.random(-8, 8), y = position.y + math.random(-8, 8)}, 12, 0.05)
        biters[#biters + 1] = surface.create_entity({name = biter_roll, position = free_pos or position, force = 'enemy'})
    end
    local group = surface.create_unit_group {position = position, force = 'enemy'}
    for _, biter in pairs(biters) do
        group.add_member(biter)
    end
    group.set_command({type = defines.command.attack_area, destination = position, radius = 80, distraction = defines.distraction.by_anything})
    group.start_moving()
    local worm_roll = BiterRaffle.roll('worm', evolution)
    for i = 1, 3 + math.floor(7 * evolution), 1 do
        local worm_pos = surface.find_non_colliding_position(worm_roll, {x = position.x + math.random(-12, 12), y = position.y + math.random(-12, 12)}, 12, 0.1)
        if worm_pos then
            surface.create_entity({name = worm_roll, position = worm_pos, force = 'enemy'})
        end
    end
    local nest = {'biter-spawner', 'biter-spawner', 'biter-spawner', 'spitter-spawner'}
    local nest_roll = nest[math.random(1, 4)]
    local nest_pos = surface.find_non_colliding_position(nest_roll, position, 12, 0.1)
    if nest_pos then
        surface.create_entity({name = nest_roll, position = nest_pos, force = 'enemy'})
    end
end

local function schedule_detonation(expanse, surface, position)
    table.insert(expanse.schedule, {tick = game.tick + 120 * 60, event = 'invasion_detonate', parameters = {surface = surface, position = position}})
end

local function schedule_warning(expanse, size, delay)
    table.insert(expanse.schedule, {tick = game.tick + 2 * 60 + delay, event = 'invasion_warn', parameters = {size = size, delay = delay}})
end

local function schedule_biters(expanse, surface, position, delay, round)
    table.insert(expanse.schedule, {tick = game.tick + delay + 120 * 60, event = 'invasion_trigger', parameters = {surface = surface, position = position, round = round}})
end

local function plan_invasion(expanse, invasion_numbers)
    local candidates = expanse.invasion_candidates
    table.shuffle_table(candidates)
    schedule_warning(expanse, invasion_numbers.groups, 0)
    schedule_warning(expanse, invasion_numbers.groups, 60 * 60)
    schedule_warning(expanse, invasion_numbers.groups, 90 * 60)
    local rounds = 4 + math.random(1, 8)
    for i = 1, invasion_numbers.groups, 1 do
        local surface = candidates[i].surface
        local position = candidates[i].position
        schedule_detonation(expanse, surface, position)
        for ii = 1, rounds, 1 do
            schedule_biters(expanse, surface, position, 120 + (ii - 1) * 300, ii)
        end
        rendering.set_time_to_live(candidates[i].render, 122 * 60 + rounds * 300)
    end
    for j = invasion_numbers.groups + 1, #candidates, 1 do
        rendering.set_time_to_live(candidates[j].render, 122 * 60)
    end
    expanse.invasion_candidates = {}
end

function Public.check_invasion(expanse)
    local invasion_numbers = Public.invasion_numbers()
    if #expanse.invasion_candidates >= invasion_numbers.candidates then
        plan_invasion(expanse, invasion_numbers)
    end
end

function Public.expand(expanse, left_top)
    expanse.grid[tostring(left_top.x .. '_' .. left_top.y)] = true

    local source_surface = game.surfaces[expanse.source_surface]
    if not source_surface then
        return
    end
    source_surface.request_to_generate_chunks(left_top, 3)
    source_surface.force_generate_chunk_requests()

    local square_size = expanse.square_size
    local area = {{left_top.x, left_top.y}, {left_top.x + square_size, left_top.y + square_size}}
    local surface = game.surfaces.expanse

    source_surface.clone_area(
        {
            source_area = area,
            destination_area = area,
            destination_surface = surface,
            clone_tiles = true,
            clone_entities = true,
            clone_decoratives = true,
            clear_destination_entities = false,
            clear_destination_decoratives = true,
            expand_map = true
        }
    )

    local positions = {
        {x = left_top.x + math.random(1, square_size - 2), y = left_top.y},
        {x = left_top.x, y = left_top.y + math.random(1, square_size - 2)},
        {x = left_top.x + math.random(1, square_size - 2), y = left_top.y + (square_size - 1)},
        {x = left_top.x + (square_size - 1), y = left_top.y + math.random(1, square_size - 2)}
    }

    for _, position in pairs(positions) do
        if is_container_position_valid(expanse, position) then
            local e = surface.create_entity({name = 'logistic-chest-requester', position = position, force = 'neutral'})
            e.destructible = false
            e.minable = false
        end
    end

    if game.tick == 0 then
        local a = math.floor(expanse.square_size * 0.5)
        for x = 1, 3, 1 do
            for y = 1, 3, 1 do
                surface.set_tiles({{name = 'water', position = {a + x + 2, a + y + 2}}}, true)
            end
        end
        surface.create_entity({name = 'crude-oil', position = {a - 4, a - 4}, amount = 1500000})
        Task.set_timeout_in_ticks(30, delay_infini_tree_token, {surface = surface, position = {a - 4, a + 4}})
        surface.create_entity({name = 'rock-big', position = {a + 4, a - 4}})
        surface.spill_item_stack({a, a + 2}, {name = 'coin', count = 1}, false, nil, false)
        surface.spill_item_stack({a + 0.5, a + 2.5}, {name = 'coin', count = 1}, false, nil, false)
        surface.spill_item_stack({a - 0.5, a + 2.5}, {name = 'coin', count = 1}, false, nil, false)

        for x = 0, square_size, 1 do
            for y = 0, square_size, 1 do
                if surface.can_place_entity({name = 'wooden-chest', position = {x, y}}) and surface.can_place_entity({name = 'coal', position = {x, y}, amount = 1}) then
                    surface.create_entity({name = ores[(x + y) % 4 + 1], position = {x, y}, amount = 1500})
                end
            end
        end
    end
end

local function init_container(expanse, entity, budget)
    local left_top = get_left_top(expanse, entity.position)
    if not left_top then
        return
    end
    local cell_value = budget or get_cell_value(expanse, left_top)
    local item_stacks = {}
    local roll_count = 3
    for _ = 1, roll_count, 1 do
        for _, stack in pairs(Price_raffle.roll(math.floor(cell_value / roll_count), 3, nil, math.max(4, cell_value / (roll_count * 6)))) do
            if not item_stacks[stack.name] then
                item_stacks[stack.name] = stack.count
            else
                item_stacks[stack.name] = item_stacks[stack.name] + stack.count
            end
        end
    end

    local price = {}
    local offset = -3
    for k, v in pairs(item_stacks) do
        table.insert(price, {name = k, count = v, render = create_costs_render(entity, k, offset)})
        offset = offset + 1
    end

    local containers = expanse.containers
    containers[entity.unit_number] = {entity = entity, left_top = left_top, price = price}
end

local function get_remaining_budget(container)
    local budget = 0
    for _, item_stack in pairs(container.price) do
        budget = budget + (item_stack.count * Price_raffle.get_item_worth(item_stack.name))
    end
    return budget
end

function Public.set_container(expanse, entity)
    if entity.name ~= 'logistic-chest-requester' then
        return
    end
    if not expanse.containers[entity.unit_number] then
        init_container(expanse, entity)
    end

    local container = expanse.containers[entity.unit_number]
    if not container or not container.entity or not container.entity.valid then
        expanse.containers[entity.unit_number] = nil
        return
    end

    local inventory = container.entity.get_inventory(defines.inventory.chest)

    if not inventory.is_empty() then
        local contents = inventory.get_contents()
        if contents['coin'] then
            local count_removed = inventory.remove({name = 'coin', count = 1})
            if count_removed > 0 then
                expanse.cost_stats['coin'] = (expanse.cost_stats['coin'] or 0) + count_removed
                script.raise_event(expanse.events.gui_update, {item = 'coin'})
                remove_old_renders(container)
                init_container(expanse, entity, get_remaining_budget(container))
                container = expanse.containers[entity.unit_number]
                game.print({'expanse.chest_reset', {'expanse.gps', math.floor(entity.position.x), math.floor(entity.position.y), 'expanse'}})
            end
        end
        if contents['infinity-chest'] then
            remove_old_renders(container)
            container.price = {}
        end
    end

    for key, item_stack in pairs(container.price) do
        local name = item_stack.name
        local count_removed = inventory.remove({name = name, count = item_stack.count})
        container.price[key].count = container.price[key].count - count_removed
        expanse.cost_stats[name] = (expanse.cost_stats[name] or 0) + count_removed
        script.raise_event(expanse.events.gui_update, {item = name})
        if container.price[key].count <= 0 then
            remove_one_render(container, key)
            table.remove(container.price, key)
        end
    end

    if #container.price == 0 then
        Public.expand(expanse, container.left_top)
        local a = math.floor(expanse.square_size * 0.5)
        local expansion_position = {x = expanse.containers[entity.unit_number].left_top.x + a, y = expanse.containers[entity.unit_number].left_top.y + a}
        expanse.containers[entity.unit_number] = nil
        if not inventory.is_empty() then
            for name, count in pairs(inventory.get_contents()) do
                entity.surface.spill_item_stack(entity.position, {name = name, count = count}, true, nil, false)
            end
        end
        reward_tokens(expanse, entity)
        entity.destructible = true
        entity.die()
        return expansion_position
    end

    for slot = 1, 30, 1 do
        entity.clear_request_slot(slot)
    end

    for slot, item_stack in pairs(container.price) do
        container.entity.set_request_slot(item_stack, slot)
    end
end

return Public
