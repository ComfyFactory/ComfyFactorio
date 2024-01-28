local LootRaffle = require 'utils.functions.loot_raffle'
local Public = require 'maps.mountain_fortress_v3.table'
local random = math.random
local abs = math.abs
local floor = math.floor
local sqrt = math.sqrt

local blacklist = {
    ['atomic-bomb'] = true,
    ['cargo-wagon'] = true,
    ['car'] = true,
    ['tank'] = true,
    ['spidertron'] = true,
    ['locomotive'] = true,
    ['artillery-wagon'] = true,
    ['artillery-turret'] = true,
    ['landfill'] = true,
    ['discharge-defense-equipment'] = true,
    ['discharge-defense-remote'] = true,
    ['fluid-wagon'] = true,
    ['pistol'] = true
}

function Public.get_distance(position)
    local difficulty = sqrt(position.x ^ 2 + position.y ^ 2) * 0.0001
    return difficulty
end

function Public.add_loot(surface, position, chest)
    local loot_stats = Public.get('loot_stats') -- loot_stats.normal == 48
    local budget = loot_stats.normal + abs(position.y) * 1.75
    budget = budget * random(25, 175) * 0.01

    if random(1, 128) == 1 then
        budget = budget * 4
        chest = 'crash-site-chest-' .. random(1, 2)
    end
    if random(1, 256) == 1 then
        budget = budget * 4
        chest = 'crash-site-chest-' .. random(1, 2)
    end

    budget = floor(budget) + 1

    local amount = random(1, 5)
    local base_amount = 12 * amount
    local distance_mod = Public.get_distance(position)

    local result = base_amount + budget + distance_mod

    local c = game.entity_prototypes[chest]
    local slots = c.get_inventory_size(defines.inventory.chest)

    local item_stacks = LootRaffle.roll(result, slots, blacklist)
    local container = surface.create_entity({name = chest, position = position, force = 'neutral', create_build_effect_smoke = false})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.minable = false

    if random(1, 8) == 1 then
        container.insert({name = 'coin', count = random(1, 32)})
    elseif random(1, 32) == 1 then
        container.insert({name = 'coin', count = random(1, 128)})
    elseif random(1, 128) == 1 then
        container.insert({name = 'coin', count = random(1, 256)})
    elseif random(1, 256) == 1 then
        container.insert({name = 'coin', count = random(1, 512)})
    elseif random(1, 512) == 1 then
        container.insert({name = 'coin', count = random(1, 1024)})
    end

    for _ = 1, 3, 1 do
        if random(1, 16) == 1 then
            container.insert({name = 'explosives', count = random(25, 50)})
        else
            break
        end
    end
end

function Public.add_loot_rare(surface, position, chest, magic)
    local loot_stats = Public.get('loot_stats') -- loot_stats.rare == 48
    local budget = (magic * loot_stats.rare) + abs(position.y) * 1.75
    budget = budget * random(25, 175) * 0.01

    if random(1, 128) == 1 then
        budget = budget * 6
        chest = 'crash-site-chest-' .. random(1, 2)
    end
    if random(1, 128) == 1 then
        budget = budget * 6
        chest = 'crash-site-chest-' .. random(1, 2)
    end

    local amount = random(1, 5)
    local base_amount = 12 * amount
    local distance_mod = Public.get_distance(position)

    budget = floor(budget) + 1

    local result = base_amount + budget + distance_mod

    local c = game.entity_prototypes[chest]
    local slots = c.get_inventory_size(defines.inventory.chest)

    local item_stacks = LootRaffle.roll(result, slots, blacklist)
    local container = surface.create_entity({name = chest, position = position, force = 'neutral', create_build_effect_smoke = false})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.minable = false

    if random(1, 8) == 1 then
        container.insert({name = 'coin', count = random(1, 32)})
    elseif random(1, 32) == 1 then
        container.insert({name = 'coin', count = random(1, 128)})
    elseif random(1, 128) == 1 then
        container.insert({name = 'coin', count = random(1, 256)})
    elseif random(1, 256) == 1 then
        container.insert({name = 'coin', count = random(1, 512)})
    elseif random(1, 512) == 1 then
        container.insert({name = 'coin', count = random(1, 2048)})
    end

    for _ = 1, 3, 1 do
        if random(1, 16) == 1 then
            container.insert({name = 'explosives', count = random(25, 50)})
        else
            break
        end
    end
end

return Public
