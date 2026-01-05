local LootRaffle = require 'maps.mountain_fortress_v3.loot_raffle'
local Public = require 'maps.mountain_fortress_v3.table'
local random = math.random
local abs = math.abs
local floor = math.floor
local sqrt = math.sqrt

local blacklist =
{
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
    ['pistol'] = true,
    ['railgun'] = true,
    ['teslagun'] = true,
    ['mech-armor'] = true,
    ['thruster'] = true,
    ['artillery-shell'] = 512,
    ['calcite'] = 1,
    ['coal'] = 1,
    ['copper-ore'] = 1,
    ['foundation'] = 16,
    ['holmium-ore'] = 8,
    ['ice'] = 1,
    ['ice-platform'] = 32,
    ['iron-ore'] = 1,
    ['jellynut'] = 8,
    ['jellynut-seed'] = 2,
    ['lightning-collector'] = 512,
    ['lightning-rod'] = 512,
    ['railgun-ammo'] = 64,
    ['railgun-turret'] = 2048,
    ['scrap'] = 4,
    ['space-platform-foundation'] = 128,
    ['space-platform-starter-pack'] = 1024,
    ['stone'] = 1,
    ['tesla-ammo'] = 128,
    ['tree-seed'] = 1,
    ['tungsten-ore'] = 4,
    ['uranium-ore'] = 2,
    ['yumako'] = 8,
    ['yumako-mash'] = 16,
    ['yumako-seed'] = 2,
}

local function check_quality()
    local quality_list = Public.get('quality_list')
    local quality_level = random(1, #quality_list)
    local quality = quality_list[quality_level]

    return quality
end

function Public.get_distance(position)
    local difficulty = sqrt(position.x ^ 2 + position.y ^ 2) * 0.0001
    return difficulty
end

function Public.add_loot(surface, position, chest, collision, zone)
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

    local quality = check_quality()

    budget = floor(budget) + 1

    local amount = random(1, 5)
    local base_amount = 12 * amount
    local distance_mod = Public.get_distance(position)

    local result = base_amount + budget + distance_mod

    local c = prototypes.entity[chest]
    local slots = c.get_inventory_size(defines.inventory.chest)

    local item_stacks = LootRaffle.roll(result, slots, blacklist, quality, zone)
    local new_position = position

    if collision then
        new_position = surface.find_non_colliding_position(chest, position, 32, 1)
        if not new_position then
            new_position = position
        end
    end

    local container = surface.create_entity({ name = chest, position = new_position, force = 'neutral', create_build_effect_smoke = false })

    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.minable_flag = false

    local is_coin_quality_enabled = Public.get('is_coin_quality_enabled')
    if not is_coin_quality_enabled then
        quality = 'normal'
    end

    if random(1, 8) == 1 then
        container.insert({ name = 'coin', count = random(1, 32), quality = 'normal' })
    elseif random(1, 32) == 1 then
        container.insert({ name = 'coin', count = random(1, 128), quality = 'normal' })
    elseif random(1, 128) == 1 then
        container.insert({ name = 'coin', count = random(1, 256), quality = quality })
    elseif random(1, 256) == 1 then
        container.insert({ name = 'coin', count = random(1, 512), quality = quality })
    elseif random(1, 512) == 1 then
        container.insert({ name = 'coin', count = random(1, 1024), quality = quality })
    end

    for _ = 1, 3, 1 do
        if random(1, 16) == 1 then
            container.insert({ name = 'explosives', count = random(25, 50) })
        else
            break
        end
    end
end

function Public.add_loot_rare(surface, position, chest, magic, zone)
    local loot_stats = Public.get('loot_stats') -- loot_stats.rare == 48
    local budget = (magic * loot_stats.rare) + abs(position.y) * 1.75

    if random(1, 128) == 1 then
        budget = budget * 6
        chest = 'crash-site-chest-' .. random(1, 2)
    end
    if random(1, 128) == 1 then
        budget = budget * 6
        chest = 'crash-site-chest-' .. random(1, 2)
    end

    local quality = check_quality()

    local amount = random(1, 5)
    local base_amount = 12 * amount
    local distance_mod = Public.get_distance(position)

    budget = floor(budget) + 1

    local result = base_amount + budget + distance_mod

    local c = prototypes.entity[chest]
    local slots = c.get_inventory_size(defines.inventory.chest)

    local item_stacks = LootRaffle.roll(result, slots, blacklist, quality, zone)
    local container = surface.create_entity({ name = chest, position = position, force = 'neutral', create_build_effect_smoke = false })
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.minable_flag = false

    local is_coin_quality_enabled = Public.get('is_coin_quality_enabled')
    if not is_coin_quality_enabled then
        quality = 'normal'
    end

    if random(1, 8) == 1 then
        container.insert({ name = 'coin', count = random(1, 32), quality = 'normal' })
    elseif random(1, 32) == 1 then
        container.insert({ name = 'coin', count = random(1, 128), quality = 'normal' })
    elseif random(1, 128) == 1 then
        container.insert({ name = 'coin', count = random(1, 256), quality = quality })
    elseif random(1, 256) == 1 then
        container.insert({ name = 'coin', count = random(1, 512), quality = quality })
    elseif random(1, 512) == 1 then
        container.insert({ name = 'coin', count = random(1, 2048), quality = quality })
    end

    for _ = 1, 3, 1 do
        if random(1, 16) == 1 then
            container.insert({ name = 'explosives', count = random(25, 50) })
        else
            break
        end
    end
end

return Public
