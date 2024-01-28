--[[
roll(budget, max_slots, blacklist) returns a table with item-stacks
budget		-	the total value of the item stacks combined
max_slots	-	the maximum amount of item stacks to return
blacklist		-	optional list of item names that can not be rolled. example: {["substation"] = true, ["roboport"] = true,}
]]
local Public = {}

local table_insert = table.insert
local math_random = math.random
local math_floor = math.floor

local item_worths = {
    ['wooden-chest'] = 2,
    ['iron-chest'] = 8,
    ['steel-chest'] = 32,
    ['storage-tank'] = 64,
    ['transport-belt'] = 2,
    ['fast-transport-belt'] = 16,
    ['express-transport-belt'] = 64,
    ['underground-belt'] = 8,
    ['fast-underground-belt'] = 64,
    ['express-underground-belt'] = 256,
    ['splitter'] = 16,
    ['fast-splitter'] = 64,
    ['express-splitter'] = 256,
    ['loader'] = 128,
    ['fast-loader'] = 256,
    ['express-loader'] = 1024,
    ['burner-inserter'] = 2,
    ['inserter'] = 4,
    ['long-handed-inserter'] = 8,
    ['fast-inserter'] = 16,
    ['filter-inserter'] = 32,
    ['stack-inserter'] = 128,
    ['stack-filter-inserter'] = 160,
    ['small-electric-pole'] = 2,
    ['medium-electric-pole'] = 32,
    ['big-electric-pole'] = 64,
    ['substation'] = 256,
    ['pipe'] = 1,
    ['pipe-to-ground'] = 8,
    ['pump'] = 32,
    ['rail'] = 4,
    ['train-stop'] = 64,
    ['rail-signal'] = 8,
    ['rail-chain-signal'] = 8,
    ['locomotive'] = 512,
    ['cargo-wagon'] = 256,
    ['fluid-wagon'] = 256,
    ['artillery-wagon'] = 16384,
    ['car'] = 128,
    ['tank'] = 4096,
    ['logistic-robot'] = 256,
    ['construction-robot'] = 256,
    ['logistic-chest-active-provider'] = 256,
    ['logistic-chest-passive-provider'] = 256,
    ['logistic-chest-storage'] = 256,
    ['logistic-chest-buffer'] = 512,
    ['logistic-chest-requester'] = 512,
    ['roboport'] = 2048,
    ['small-lamp'] = 4,
    ['red-wire'] = 4,
    ['green-wire'] = 4,
    ['arithmetic-combinator'] = 16,
    ['decider-combinator'] = 16,
    ['constant-combinator'] = 8,
    ['power-switch'] = 16,
    ['programmable-speaker'] = 16,
    ['stone-brick'] = 2,
    ['concrete'] = 1,
    ['hazard-concrete'] = 1,
    ['refined-concrete'] = 2,
    ['refined-hazard-concrete'] = 2,
    ['cliff-explosives'] = 32,
    ['repair-pack'] = 8,
    ['boiler'] = 8,
    ['steam-engine'] = 32,
    ['solar-panel'] = 64,
    ['accumulator'] = 64,
    ['nuclear-reactor'] = 8192,
    ['heat-pipe'] = 128,
    ['heat-exchanger'] = 256,
    ['steam-turbine'] = 256,
    ['burner-mining-drill'] = 8,
    ['electric-mining-drill'] = 32,
    ['offshore-pump'] = 16,
    ['pumpjack'] = 64,
    ['stone-furnace'] = 4,
    ['steel-furnace'] = 64,
    ['electric-furnace'] = 256,
    ['assembling-machine-1'] = 32,
    ['assembling-machine-2'] = 128,
    ['assembling-machine-3'] = 512,
    ['oil-refinery'] = 256,
    ['chemical-plant'] = 128,
    ['centrifuge'] = 2048,
    ['lab'] = 64,
    ['beacon'] = 512,
    ['speed-module'] = 128,
    ['speed-module-2'] = 512,
    ['speed-module-3'] = 2048,
    ['effectivity-module'] = 128,
    ['effectivity-module-2'] = 512,
    ['effectivity-module-3'] = 2048,
    ['productivity-module'] = 128,
    ['productivity-module-2'] = 512,
    ['productivity-module-3'] = 2048,
    ['wood'] = 1,
    ['raw-fish'] = 10,
    ['iron-plate'] = 1,
    ['copper-plate'] = 1,
    ['solid-fuel'] = 16,
    ['steel-plate'] = 8,
    ['plastic-bar'] = 8,
    ['sulfur'] = 4,
    ['battery'] = 16,
    ['explosives'] = 3,
    ['crude-oil-barrel'] = 8,
    ['heavy-oil-barrel'] = 16,
    ['light-oil-barrel'] = 16,
    ['lubricant-barrel'] = 16,
    ['petroleum-gas-barrel'] = 16,
    ['sulfuric-acid-barrel'] = 16,
    ['water-barrel'] = 4,
    ['copper-cable'] = 1,
    ['iron-stick'] = 1,
    ['iron-gear-wheel'] = 2,
    ['empty-barrel'] = 4,
    ['electronic-circuit'] = 4,
    ['advanced-circuit'] = 16,
    ['processing-unit'] = 128,
    ['engine-unit'] = 8,
    ['electric-engine-unit'] = 64,
    ['flying-robot-frame'] = 128,
    ['satellite'] = 32768,
    ['rocket-control-unit'] = 256,
    ['low-density-structure'] = 64,
    ['rocket-fuel'] = 256,
    ['nuclear-fuel'] = 1024,
    ['uranium-235'] = 1024,
    ['uranium-238'] = 32,
    ['uranium-fuel-cell'] = 128,
    ['used-up-uranium-fuel-cell'] = 8,
    ['automation-science-pack'] = 4,
    ['logistic-science-pack'] = 16,
    ['military-science-pack'] = 64,
    ['chemical-science-pack'] = 128,
    ['production-science-pack'] = 256,
    ['utility-science-pack'] = 256,
    ['space-science-pack'] = 512,
    ['pistol'] = 10,
    ['submachine-gun'] = 32,
    ['shotgun'] = 16,
    ['combat-shotgun'] = 256,
    ['rocket-launcher'] = 128,
    ['flamethrower'] = 512,
    ['land-mine'] = 2,
    ['landfill'] = 20,
    ['firearm-magazine'] = 4,
    ['piercing-rounds-magazine'] = 8,
    ['uranium-rounds-magazine'] = 64,
    ['shotgun-shell'] = 4,
    ['piercing-shotgun-shell'] = 16,
    ['cannon-shell'] = 8,
    ['explosive-cannon-shell'] = 16,
    ['uranium-cannon-shell'] = 64,
    ['explosive-uranium-cannon-shell'] = 64,
    ['artillery-shell'] = 512,
    ['rocket'] = 6,
    ['explosive-rocket'] = 8,
    ['atomic-bomb'] = 8192,
    ['flamethrower-ammo'] = 32,
    ['grenade'] = 16,
    ['cluster-grenade'] = 64,
    ['poison-capsule'] = 32,
    ['slowdown-capsule'] = 16,
    ['defender-capsule'] = 48,
    ['distractor-capsule'] = 256,
    ['destroyer-capsule'] = 1024,
    ['light-armor'] = 50,
    ['heavy-armor'] = 250,
    ['modular-armor'] = 512,
    ['power-armor'] = 2048,
    ['power-armor-mk2'] = 32768,
    ['solar-panel-equipment'] = 256,
    ['fusion-reactor-equipment'] = 15000,
    ['energy-shield-equipment'] = 128,
    ['energy-shield-mk2-equipment'] = 2048,
    ['battery-equipment'] = 96,
    ['battery-mk2-equipment'] = 2048,
    ['personal-laser-defense-equipment'] = 1500,
    ['discharge-defense-equipment'] = 2048,
    ['discharge-defense-remote'] = 32,
    ['belt-immunity-equipment'] = 128,
    ['exoskeleton-equipment'] = 1500,
    ['personal-roboport-equipment'] = 512,
    ['personal-roboport-mk2-equipment'] = 4096,
    ['night-vision-equipment'] = 256,
    ['stone-wall'] = 5,
    ['gate'] = 16,
    ['gun-turret'] = 64,
    ['laser-turret'] = 1024,
    ['flamethrower-turret'] = 2048,
    ['artillery-turret'] = 9216,
    ['radar'] = 32,
    ['rocket-silo'] = 65536
}

local tech_tier_list = {
    'iron-gear-wheel',
    'iron-plate',
    'iron-stick',
    'stone-brick',
    'copper-cable',
    'copper-plate',
    'pipe',
    'pipe-to-ground',
    'automation-science-pack',
    'boiler',
    'burner-inserter',
    'burner-mining-drill',
    'electronic-circuit',
    'firearm-magazine',
    'inserter',
    'iron-chest',
    'lab',
    'light-armor',
    'offshore-pump',
    'electric-mining-drill',
    'pistol',
    'radar',
    'repair-pack',
    'small-electric-pole',
    'steam-engine',
    'stone-furnace',
    'transport-belt',
    'wooden-chest',
    'assembling-machine-1',
    'long-handed-inserter',
    'fast-inserter',
    'filter-inserter',
    'underground-belt',
    'splitter',
    'loader',
    'small-lamp',
    'gun-turret',
    'stone-wall',
    'logistic-science-pack',
    'steel-plate',
    'steel-chest',
    'submachine-gun',
    'shotgun',
    'shotgun-shell',
    'heavy-armor',
    'assembling-machine-2',
    'explosives',
    'advanced-circuit',
    'red-wire',
    'green-wire',
    'arithmetic-combinator',
    'decider-combinator',
    'constant-combinator',
    'power-switch',
    'programmable-speaker',
    'landfill',
    'fast-transport-belt',
    'fast-underground-belt',
    'fast-splitter',
    'fast-loader',
    'solar-panel',
    'gate',
    'engine-unit',
    'battery',
    'chemical-science-pack',
    'military-science-pack',
    'steel-furnace',
    'concrete',
    'hazard-concrete',
    'accumulator',
    'medium-electric-pole',
    'big-electric-pole',
    'rail',
    'locomotive',
    'cargo-wagon',
    'fluid-wagon',
    'train-stop',
    'rail-signal',
    'rail-chain-signal',
    'stack-inserter',
    'stack-filter-inserter',
    'pumpjack',
    'oil-refinery',
    'chemical-plant',
    'solid-fuel',
    'storage-tank',
    'pump',
    'empty-barrel',
    'water-barrel',
    'crude-oil-barrel',
    'land-mine',
    'rocket-launcher',
    'rocket',
    'sulfur',
    'plastic-bar',
    'piercing-rounds-magazine',
    'grenade',
    'defender-capsule',
    'car',
    'refined-concrete',
    'refined-hazard-concrete',
    'modular-armor',
    'night-vision-equipment',
    'belt-immunity-equipment',
    'heavy-oil-barrel',
    'light-oil-barrel',
    'lubricant-barrel',
    'petroleum-gas-barrel',
    'sulfuric-acid-barrel',
    'battery-equipment',
    'solar-panel-equipment',
    'speed-module',
    'productivity-module',
    'effectivity-module',
    'cliff-explosives',
    'processing-unit',
    'electric-engine-unit',
    'production-science-pack',
    'utility-science-pack',
    'electric-furnace',
    'substation',
    'flying-robot-frame',
    'roboport',
    'logistic-chest-passive-provider',
    'logistic-chest-storage',
    'construction-robot',
    'roboport',
    'logistic-chest-passive-provider',
    'logistic-chest-storage',
    'logistic-robot',
    'personal-roboport-equipment',
    'flamethrower',
    'flamethrower-ammo',
    'flamethrower-turret',
    'piercing-shotgun-shell',
    'cluster-grenade',
    'destroyer-capsule',
    'poison-capsule',
    'slowdown-capsule',
    'combat-shotgun',
    'tank',
    'cannon-shell',
    'explosive-cannon-shell',
    'explosive-rocket',
    'distractor-capsule',
    'nuclear-reactor',
    'heat-exchanger',
    'heat-pipe',
    'steam-turbine',
    'centrifuge',
    'uranium-fuel-cell',
    'used-up-uranium-fuel-cell',
    'uranium-235',
    'uranium-238',
    'power-armor',
    'energy-shield-equipment',
    'exoskeleton-equipment',
    'battery-mk2-equipment',
    'speed-module-2',
    'productivity-module-2',
    'effectivity-module-2',
    'low-density-structure',
    'rocket-fuel',
    'assembling-machine-3',
    'express-transport-belt',
    'express-underground-belt',
    'express-splitter',
    'express-loader',
    'laser-turret',
    'logistic-chest-active-provider',
    'logistic-chest-requester',
    'logistic-chest-buffer',
    'personal-roboport-mk2-equipment',
    'nuclear-fuel',
    'energy-shield-mk2-equipment',
    'personal-laser-defense-equipment',
    'discharge-defense-equipment',
    'discharge-defense-remote',
    'speed-module-3',
    'productivity-module-3',
    'effectivity-module-3',
    'space-science-pack',
    'beacon',
    'rocket-control-unit',
    'fusion-reactor-equipment',
    'artillery-wagon',
    'artillery-turret',
    'artillery-shell',
    'artillery-targeting-remote',
    'uranium-rounds-magazine',
    'uranium-cannon-shell',
    'explosive-uranium-cannon-shell',
    'atomic-bomb',
    'power-armor-mk2',
    'satellite',
    'rocket-silo'
}

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math_random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local item_names = {}
for k, _ in pairs(item_worths) do
    table_insert(item_names, k)
end
local size_of_item_names = #item_names

function Public.TweakItemWorth(updates)
    item_names = {}
    for k, v in pairs(updates) do
        item_worths[k] = v
    end
    item_names = {}
    for k, _ in pairs(item_worths) do
        table_insert(item_names, k)
    end

    size_of_item_names = #item_names
end

local function get_raffle_keys()
    local raffle_keys = {}
    for i = 1, size_of_item_names, 1 do
        raffle_keys[i] = i
    end
    shuffle(raffle_keys)
    return raffle_keys
end

function Public.roll_item_stack(remaining_budget, blacklist)
    if remaining_budget <= 0 then
        return
    end
    local raffle_keys = get_raffle_keys()
    local item_name = false
    local item_worth = 0
    for _, index in pairs(raffle_keys) do
        item_name = item_names[index]
        item_worth = item_worths[item_name]
        if not blacklist[item_name] and item_worth <= remaining_budget then
            break
        end
    end

    local stack_size = game.item_prototypes[item_name].stack_size

    local item_count = 1

    for c = 1, math_random(1, stack_size), 1 do
        local price = c * item_worth
        if price <= remaining_budget then
            item_count = c
        else
            break
        end
    end

    return {name = item_name, count = item_count}
end

local function roll_item_stacks(remaining_budget, max_slots, blacklist)
    local item_stack_set = {}
    local item_stack_set_worth = 0

    for i = 1, max_slots, 1 do
        if remaining_budget <= 0 then
            break
        end
        local item_stack = Public.roll_item_stack(remaining_budget, blacklist)
        item_stack_set[i] = item_stack
        remaining_budget = remaining_budget - item_stack.count * item_worths[item_stack.name]
        item_stack_set_worth = item_stack_set_worth + item_stack.count * item_worths[item_stack.name]
    end

    return item_stack_set, item_stack_set_worth
end

function Public.roll(budget, max_slots, blacklist)
    if not budget then
        return
    end
    if not max_slots then
        return
    end

    local b
    if not blacklist then
        b = {}
    else
        b = blacklist
    end

    budget = math_floor(budget)
    if budget == 0 then
        return
    end

    local final_stack_set
    local final_stack_set_worth = 0

    for _ = 1, 5, 1 do
        local item_stack_set, item_stack_set_worth = roll_item_stacks(budget, max_slots, b)
        if item_stack_set_worth > final_stack_set_worth or item_stack_set_worth == budget then
            final_stack_set = item_stack_set
            final_stack_set_worth = item_stack_set_worth
        end
    end
    --[[
	for k, item_stack in pairs(final_stack_set) do
		game.print(item_stack.count .. "x " .. item_stack.name)
	end
	game.print(final_stack_set_worth)
	]]
    return final_stack_set
end

--tier = float 0-1; 1 = everything unlocked
function Public.get_tech_blacklist(tier)
    if not tier then
        return
    end

    local blacklist = {}
    local size_of_tech_tier_list = #tech_tier_list
    tier = math.clamp(tier, 0, 1)
    local min_index = math_floor(size_of_tech_tier_list * tier) + 1
    for i = size_of_tech_tier_list, min_index, -1 do
        blacklist[tech_tier_list[i]] = true
    end
    return blacklist
end

function Public.get_item_value(item)
    local value = item_worths[item]
    return value
end

return Public
