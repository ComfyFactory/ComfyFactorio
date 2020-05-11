local LootRaffle = require 'functions.loot_raffle'

local Public = {}
local math_random = math.random
local math_abs = math.abs
local math_floor = math.floor

local blacklist = {
    ['cargo-wagon'] = true,
    ['locomotive'] = true,
    ['artillery-wagon'] = true,
    ['fluid-wagon'] = true
}

function Public.add(surface, position, container_name)
    local budget = 48 + math_abs(position.y) * 1.75
    budget = budget * math_random(25, 175) * 0.01

    if math_random(1, 128) == 1 then
        budget = budget * 4
        container_name = 'crash-site-chest-' .. math_random(1, 2)
    end
    if math_random(1, 256) == 1 then
        budget = budget * 4
        container_name = 'crash-site-chest-' .. math_random(1, 2)
    end

    budget = math_floor(budget) + 1

    local item_stacks = LootRaffle.roll(budget, 8, blacklist)
    local container = surface.create_entity({name = container_name, position = position, force = 'defenders'})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.minable = false

    for _ = 1, 3, 1 do
        if math_random(1, 8) == 1 then
            container.insert({name = 'explosives', count = math_random(25, 50)})
        else
            break
        end
    end
end

function Public.add_rare(surface, position, chest, magic)
    if magic > 150 then
        magic = math.random(1, 150)
    end
    local chest_raffle = {}
    local chest_loot = {
        {{name = 'submachine-gun', count = magic}, weight = 3, d_min = 0.0, d_max = 0.1},
        {{name = 'slowdown-capsule', count = magic}, weight = 1, d_min = 0.3, d_max = 0.7},
        {{name = 'poison-capsule', count = magic}, weight = 3, d_min = 0.3, d_max = 1},
        {{name = 'uranium-cannon-shell', count = magic}, weight = 5, d_min = 0.6, d_max = 1},
        {{name = 'cannon-shell', count = magic}, weight = 5, d_min = 0.4, d_max = 0.7},
        {{name = 'explosive-uranium-cannon-shell', count = magic}, weight = 5, d_min = 0.6, d_max = 1},
        {{name = 'explosive-cannon-shell', count = magic}, weight = 5, d_min = 0.4, d_max = 0.8},
        {{name = 'shotgun', count = 1}, weight = 2, d_min = 0.0, d_max = 0.2},
        {{name = 'shotgun-shell', count = magic}, weight = 5, d_min = 0.0, d_max = 0.2},
        {{name = 'combat-shotgun', count = 1}, weight = 3, d_min = 0.3, d_max = 0.8},
        {{name = 'piercing-shotgun-shell', count = magic}, weight = 10, d_min = 0.2, d_max = 1},
        {{name = 'flamethrower', count = 1}, weight = 3, d_min = 0.3, d_max = 0.6},
        {{name = 'flamethrower-ammo', count = magic}, weight = 5, d_min = 0.3, d_max = 1},
        {{name = 'rocket-launcher', count = 1}, weight = 3, d_min = 0.2, d_max = 0.6},
        {{name = 'rocket', count = magic}, weight = 5, d_min = 0.2, d_max = 0.7},
        {{name = 'explosive-rocket', count = magic}, weight = 5, d_min = 0.3, d_max = 1},
        {{name = 'grenade', count = magic}, weight = 5, d_min = 0.0, d_max = 0.5},
        {{name = 'cluster-grenade', count = magic}, weight = 5, d_min = 0.4, d_max = 1},
        {{name = 'firearm-magazine', count = magic}, weight = 6, d_min = 0, d_max = 0.3},
        {{name = 'piercing-rounds-magazine', count = magic}, weight = 5, d_min = 0.1, d_max = 0.8},
        {{name = 'uranium-rounds-magazine', count = magic}, weight = 4, d_min = 0.5, d_max = 1},
        {{name = 'railgun', count = 1}, weight = 1, d_min = 0.2, d_max = 1},
        {{name = 'railgun-dart', count = magic}, weight = 3, d_min = 0.2, d_max = 0.7},
        {{name = 'defender-capsule', count = magic}, weight = 2, d_min = 0.0, d_max = 0.7},
        {{name = 'distractor-capsule', count = magic}, weight = 2, d_min = 0.2, d_max = 1},
        {{name = 'destroyer-capsule', count = magic}, weight = 2, d_min = 0.3, d_max = 1},
        {{name = 'atomic-bomb', count = 1}, weight = 1, d_min = 0.8, d_max = 1},
        {{name = 'land-mine', count = magic}, weight = 5, d_min = 0.2, d_max = 0.7},
        {{name = 'light-armor', count = 1}, weight = 3, d_min = 0, d_max = 0.1},
        {{name = 'heavy-armor', count = 1}, weight = 3, d_min = 0.1, d_max = 0.3},
        {{name = 'modular-armor', count = 1}, weight = 2, d_min = 0.2, d_max = 0.6},
        {{name = 'power-armor', count = 1}, weight = 1, d_min = 0.4, d_max = 1},
        {{name = 'battery-equipment', count = 1}, weight = 2, d_min = 0.3, d_max = 0.7},
        {{name = 'belt-immunity-equipment', count = 1}, weight = 1, d_min = 0.5, d_max = 1},
        {{name = 'solar-panel-equipment', count = magic}, weight = 5, d_min = 0.4, d_max = 0.8},
        {{name = 'discharge-defense-equipment', count = 1}, weight = 1, d_min = 0.5, d_max = 1},
        {{name = 'energy-shield-equipment', count = magic}, weight = 2, d_min = 0.3, d_max = 0.8},
        {{name = 'exoskeleton-equipment', count = 1}, weight = 1, d_min = 0.3, d_max = 1},
        {{name = 'night-vision-equipment', count = 1}, weight = 1, d_min = 0.3, d_max = 0.8},
        {{name = 'personal-laser-defense-equipment', count = 1}, weight = 1, d_min = 0.7, d_max = 1},
        {{name = 'personal-roboport-equipment', count = magic}, weight = 3, d_min = 0.4, d_max = 1},
        {{name = 'logistic-robot', count = magic}, weight = 2, d_min = 0.5, d_max = 1},
        {{name = 'construction-robot', count = magic}, weight = 5, d_min = 0.4, d_max = 1},
        {{name = 'iron-gear-wheel', count = magic}, weight = 3, d_min = 0.0, d_max = 0.3},
        {{name = 'copper-cable', count = magic}, weight = 3, d_min = 0.0, d_max = 0.3},
        {{name = 'engine-unit', count = magic}, weight = 2, d_min = 0.1, d_max = 0.5},
        {{name = 'electric-engine-unit', count = magic}, weight = 2, d_min = 0.4, d_max = 0.8},
        {{name = 'battery', count = magic}, weight = 2, d_min = 0.3, d_max = 0.8},
        {{name = 'advanced-circuit', count = magic}, weight = 3, d_min = 0.3, d_max = 1},
        {{name = 'electronic-circuit', count = magic}, weight = 4, d_min = 0.0, d_max = 0.4},
        {{name = 'processing-unit', count = magic}, weight = 3, d_min = 0.7, d_max = 1},
        {{name = 'explosives', count = magic}, weight = 10, d_min = 0.0, d_max = 1},
        {{name = 'lubricant-barrel', count = magic}, weight = 1, d_min = 0.3, d_max = 0.5},
        {{name = 'rocket-fuel', count = magic}, weight = 2, d_min = 0.3, d_max = 0.7},
        {{name = 'effectivity-module', count = magic}, weight = 2, d_min = 0.1, d_max = 1},
        {{name = 'productivity-module', count = magic}, weight = 2, d_min = 0.1, d_max = 1},
        {{name = 'speed-module', count = magic}, weight = 2, d_min = 0.1, d_max = 1},
        {{name = 'automation-science-pack', count = magic}, weight = 3, d_min = 0.0, d_max = 0.2},
        {{name = 'logistic-science-pack', count = magic}, weight = 3, d_min = 0.1, d_max = 0.5},
        {{name = 'military-science-pack', count = magic}, weight = 3, d_min = 0.2, d_max = 1},
        {{name = 'chemical-science-pack', count = magic}, weight = 3, d_min = 0.3, d_max = 1},
        {{name = 'production-science-pack', count = magic}, weight = 3, d_min = 0.4, d_max = 1},
        {{name = 'utility-science-pack', count = magic}, weight = 3, d_min = 0.5, d_max = 1},
        {{name = 'space-science-pack', count = magic}, weight = 3, d_min = 0.9, d_max = 1},
        {{name = 'steel-plate', count = magic}, weight = 2, d_min = 0.1, d_max = 0.3},
        {{name = 'nuclear-fuel', count = 1}, weight = 2, d_min = 0.7, d_max = 1},
        {{name = 'burner-inserter', count = magic}, weight = 3, d_min = 0.0, d_max = 0.1},
        {{name = 'inserter', count = magic}, weight = 3, d_min = 0.0, d_max = 0.4},
        {{name = 'long-handed-inserter', count = magic}, weight = 3, d_min = 0.0, d_max = 0.4},
        {{name = 'fast-inserter', count = magic}, weight = 3, d_min = 0.1, d_max = 1},
        {{name = 'filter-inserter', count = magic}, weight = 1, d_min = 0.2, d_max = 1},
        {{name = 'stack-filter-inserter', count = magic}, weight = 1, d_min = 0.4, d_max = 1},
        {{name = 'stack-inserter', count = magic}, weight = 3, d_min = 0.3, d_max = 1},
        {{name = 'small-electric-pole', count = magic}, weight = 3, d_min = 0.0, d_max = 0.3},
        {{name = 'medium-electric-pole', count = magic}, weight = 3, d_min = 0.2, d_max = 1},
        {{name = 'big-electric-pole', count = magic}, weight = 3, d_min = 0.3, d_max = 1},
        {{name = 'substation', count = magic}, weight = 3, d_min = 0.5, d_max = 1},
        {{name = 'wooden-chest', count = magic}, weight = 3, d_min = 0.0, d_max = 0.2},
        {{name = 'iron-chest', count = magic}, weight = 3, d_min = 0.1, d_max = 0.4},
        {{name = 'steel-chest', count = magic}, weight = 3, d_min = 0.3, d_max = 1},
        {{name = 'small-lamp', count = magic}, weight = 3, d_min = 0.1, d_max = 0.3},
        {{name = 'rail', count = magic}, weight = 3, d_min = 0.1, d_max = 0.6},
        {{name = 'assembling-machine-1', count = magic}, weight = 3, d_min = 0.0, d_max = 0.3},
        {{name = 'assembling-machine-2', count = magic}, weight = 3, d_min = 0.2, d_max = 0.8},
        {{name = 'assembling-machine-3', count = magic}, weight = 3, d_min = 0.5, d_max = 1},
        {{name = 'accumulator', count = magic}, weight = 3, d_min = 0.4, d_max = 1},
        {{name = 'offshore-pump', count = magic}, weight = 2, d_min = 0.0, d_max = 0.2},
        {{name = 'beacon', count = 1}, weight = 2, d_min = 0.7, d_max = 1},
        {{name = 'boiler', count = magic}, weight = 3, d_min = 0.0, d_max = 0.3},
        {{name = 'steam-engine', count = magic}, weight = 3, d_min = 0.0, d_max = 0.5},
        {{name = 'steam-turbine', count = magic}, weight = 2, d_min = 0.6, d_max = 1},
        {{name = 'nuclear-reactor', count = 1}, weight = 1, d_min = 0.7, d_max = 1},
        {{name = 'centrifuge', count = 1}, weight = 1, d_min = 0.6, d_max = 1},
        {{name = 'heat-pipe', count = magic}, weight = 2, d_min = 0.5, d_max = 1},
        {{name = 'heat-exchanger', count = magic}, weight = 2, d_min = 0.5, d_max = 1},
        {{name = 'arithmetic-combinator', count = magic}, weight = 2, d_min = 0.1, d_max = 1},
        {{name = 'constant-combinator', count = magic}, weight = 2, d_min = 0.1, d_max = 1},
        {{name = 'decider-combinator', count = magic}, weight = 2, d_min = 0.1, d_max = 1},
        {{name = 'power-switch', count = 1}, weight = 2, d_min = 0.1, d_max = 1},
        {{name = 'programmable-speaker', count = magic}, weight = 1, d_min = 0.1, d_max = 1},
        {{name = 'green-wire', count = magic}, weight = 4, d_min = 0.1, d_max = 1},
        {{name = 'red-wire', count = magic}, weight = 4, d_min = 0.1, d_max = 1},
        {{name = 'chemical-plant', count = magic}, weight = 3, d_min = 0.3, d_max = 1},
        {{name = 'burner-mining-drill', count = magic}, weight = 3, d_min = 0.0, d_max = 0.2},
        {{name = 'electric-mining-drill', count = magic}, weight = 3, d_min = 0.2, d_max = 1},
        {{name = 'express-transport-belt', count = magic}, weight = 3, d_min = 0.5, d_max = 1},
        {{name = 'express-underground-belt', count = magic}, weight = 3, d_min = 0.5, d_max = 1},
        {{name = 'express-splitter', count = magic}, weight = 3, d_min = 0.5, d_max = 1},
        {{name = 'fast-transport-belt', count = magic}, weight = 3, d_min = 0.2, d_max = 0.7},
        {{name = 'fast-underground-belt', count = magic}, weight = 3, d_min = 0.2, d_max = 0.7},
        {{name = 'fast-splitter', count = magic}, weight = 3, d_min = 0.2, d_max = 0.3},
        {{name = 'transport-belt', count = magic}, weight = 3, d_min = 0, d_max = 0.3},
        {{name = 'underground-belt', count = magic}, weight = 3, d_min = 0, d_max = 0.3},
        {{name = 'splitter', count = magic}, weight = 3, d_min = 0, d_max = 0.3},
        {{name = 'pipe', count = magic}, weight = 3, d_min = 0.0, d_max = 0.3},
        {{name = 'pipe-to-ground', count = magic}, weight = 1, d_min = 0.2, d_max = 0.5},
        {{name = 'pumpjack', count = magic}, weight = 1, d_min = 0.3, d_max = 0.8},
        {{name = 'pump', count = magic}, weight = 1, d_min = 0.3, d_max = 0.8},
        {{name = 'solar-panel', count = magic}, weight = 3, d_min = 0.4, d_max = 0.9},
        {{name = 'electric-furnace', count = magic}, weight = 3, d_min = 0.5, d_max = 1},
        {{name = 'steel-furnace', count = magic}, weight = 3, d_min = 0.2, d_max = 0.7},
        {{name = 'stone-furnace', count = magic}, weight = 3, d_min = 0.0, d_max = 0.2},
        {{name = 'radar', count = magic}, weight = 1, d_min = 0.1, d_max = 0.4},
        {{name = 'rail-signal', count = magic}, weight = 2, d_min = 0.2, d_max = 0.8},
        {{name = 'rail-chain-signal', count = magic}, weight = 2, d_min = 0.2, d_max = 0.8},
        {{name = 'stone-wall', count = magic}, weight = 3, d_min = 0.0, d_max = 0.7},
        {{name = 'gate', count = magic}, weight = 3, d_min = 0.0, d_max = 0.7},
        {{name = 'storage-tank', count = magic}, weight = 3, d_min = 0.3, d_max = 0.6},
        {{name = 'train-stop', count = magic}, weight = 1, d_min = 0.2, d_max = 0.7},
        {{name = 'express-loader', count = magic}, weight = 1, d_min = 0.5, d_max = 1},
        {{name = 'fast-loader', count = magic}, weight = 1, d_min = 0.2, d_max = 0.7},
        {{name = 'loader', count = magic}, weight = 1, d_min = 0.0, d_max = 0.5},
        {{name = 'lab', count = magic}, weight = 2, d_min = 0.0, d_max = 0.3},
        {{name = 'roboport', count = 1}, weight = 2, d_min = 0.8, d_max = 1},
        {{name = 'flamethrower-turret', count = 1}, weight = 3, d_min = 0.5, d_max = 1},
        {{name = 'laser-turret', count = magic}, weight = 3, d_min = 0.5, d_max = 1},
        {{name = 'gun-turret', count = magic}, weight = 3, d_min = 0.2, d_max = 0.9}
    }

    local distance_to_center = (math.abs(position.y) + 1) * 0.0002
    if distance_to_center > 1 then
        distance_to_center = 1
    end

    for _, t in pairs(chest_loot) do
        for x = 1, t.weight, 1 do
            if t.d_min <= distance_to_center and t.d_max >= distance_to_center then
                table.insert(chest_raffle, t[1])
            end
        end
    end

    local e = surface.create_entity({name = chest, position = position, force = 'defenders'})
    e.minable = false
    local i = e.get_inventory(defines.inventory.chest)
    for x = 1, math_random(5, 8), 1 do
        local loot = chest_raffle[math_random(1, #chest_raffle)]
        i.insert(loot)
    end
end

return Public
