local WD = require 'modules.wave_defense.table'
local RPG = require 'modules.rpg.main'
local Public = {}

local coins = { 2000, 5000, 10000 }
local xp = { 3000, 6000, 12000 }
local packages =
{
    {
        { 'firearm-magazine', 200 }, { 'repair-pack', 100 }, { 'electronic-circuit', 200 },
        { 'iron-plate', 500 }, { 'copper-plate', 500 }, { 'steel-plate', 100 },
        { 'iron-gear-wheel', 200 }, { 'battery', 50 }, { 'explosives', 50 },
        { 'grenade', 50 }, { 'stone-wall', 100 }, { 'engine-unit', 25 }, { 'solid-fuel', 100 }
    },
    {
        { 'piercing-rounds-magazine', 300 }, { 'repair-pack', 200 }, { 'advanced-circuit', 200 },
        { 'iron-plate', 1000 }, { 'copper-plate', 1000 }, { 'steel-plate', 200 },
        { 'iron-gear-wheel', 400 }, { 'battery', 100 }, { 'explosives', 100 },
        { 'grenade', 100 }, { 'stone-wall', 200 }, { 'engine-unit', 50 }, { 'solid-fuel', 200 }
    },
    {
        { 'uranium-rounds-magazine', 300 }, { 'repair-pack', 400 }, { 'processing-unit', 100 },
        { 'iron-plate', 2000 }, { 'copper-plate', 2000 }, { 'steel-plate', 400 },
        { 'iron-gear-wheel', 800 }, { 'battery', 200 }, { 'explosives', 200 },
        { 'grenade', 200 }, { 'stone-wall', 400 }, { 'engine-unit', 100 }, { 'solid-fuel', 400 }
    }
}

function Public.create(legacy)
    local wave = legacy and 0 or (WD.get_wave() or 0)
    local tier = wave < 500 and 1 or wave < 1000 and 2 or 3
    local available = {}
    for _, item in ipairs(packages[tier]) do
        if prototypes.item[item[1]] then available[#available + 1] = item end
    end
    if #available == 0 then
        for _, item in ipairs(packages[1]) do
            if prototypes.item[item[1]] then available[#available + 1] = item end
        end
    end
    assert(#available > 0, 'Flag rewards require an ammo, repair or circuit item prototype')
    local selected = available[legacy and 1 or math.random(#available)]
    return { tier = tier, wave = wave, coins = coins[tier], xp = xp[tier],
        item = selected[1], count = selected[2] }
end

function Public.describe(reward)
    return reward.coins .. ' coins + ' .. reward.xp .. ' shared XP pool + '
        .. reward.count .. ' [item=' .. reward.item .. ']'
end

local function insert(loco, name, count)
    local remaining = count
    local train = loco.train
    if train and train.valid then
        for _, wagon in pairs(train.cargo_wagons) do
            if wagon.valid and wagon.train == train and wagon.surface.index == loco.surface.index
                and wagon.force.index == loco.force.index then
                local inventory = wagon.get_inventory(defines.inventory.cargo_wagon)
                if inventory and inventory.valid then
                    remaining = remaining - inventory.insert { name = name, count = remaining, quality = 'normal' }
                    if remaining == 0 then return end
                end
            end
        end
    end
    loco.surface.spill_item_stack
    { position = loco.position, stack = { name = name, count = remaining, quality = 'normal' },
        enable_looted = true, force = loco.force, allow_belts = false
    }
end

function Public.deliver(loco, reward)
    insert(loco, 'coin', reward.coins)
    insert(loco, reward.item, reward.count)
    RPG.add_to_global_pool(reward.xp / 0.3, false)
end

return Public
