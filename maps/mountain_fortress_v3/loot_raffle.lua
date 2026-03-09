--[[
roll(budget, max_slots, blacklist, quality, zone, pos_y)
    returns a table with item-stacks
budget         - total loot value pool
max_slots      - number of item stacks to roll
blacklist      - optional item blacklist
quality        - optional item quality
zone           - optional zone index (int)
]]

local Global = require 'utils.global'
local Public = {}

local this =
{
    zone_loot_bias = {},
    zone_item_names = {}
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local table_insert = table.insert
local math_random = math.random

local item_worths =
{
    ['accumulator'] = 64,
    ['active-provider-chest'] = 256,
    ['advanced-circuit'] = 128,
    ['agricultural-science-pack'] = 2048,
    ['agricultural-tower'] = 128,
    ['arithmetic-combinator'] = 16,
    ['artillery-shell'] = 512,
    ['artillery-turret'] = 9216,
    ['artillery-wagon'] = 16384,
    ['assembling-machine-1'] = 32,
    ['assembling-machine-2'] = 128,
    ['assembling-machine-3'] = 512,
    ['atomic-bomb'] = 8192,
    ['automation-science-pack'] = 4,
    ['barrel'] = 4,
    ['battery'] = 16,
    ['battery-equipment'] = 96,
    ['battery-mk2-equipment'] = 2048,
    ['beacon'] = 1024,
    ['belt-immunity-equipment'] = 128,
    ['big-electric-pole'] = 64,
    ['biochamber'] = 2048,
    ['biolab'] = 9216,
    ['boiler'] = 8,
    ['buffer-chest'] = 512,
    ['bulk-inserter'] = 128,
    ['burner-inserter'] = 2,
    ['burner-mining-drill'] = 8,
    ['calcite'] = 1,
    ['cargo-wagon'] = 256,
    ['cannon-shell'] = 8,
    ['car'] = 128,
    ['centrifuge'] = 2048,
    ['chemical-plant'] = 128,
    ['chemical-science-pack'] = 128,
    ['cliff-explosives'] = 32,
    ['cluster-grenade'] = 64,
    ['coal'] = 1,
    ['combat-shotgun'] = 512,
    ['concrete'] = 1,
    ['constant-combinator'] = 8,
    ['construction-robot'] = 256,
    ['copper-cable'] = 1,
    ['copper-ore'] = 1,
    ['copper-plate'] = 1,
    ['crude-oil-barrel'] = 8,
    ['crusher'] = 128,
    ['cryogenic-plant'] = 2048,
    ['cryogenic-science-pack'] = 2048,
    ['decider-combinator'] = 16,
    ['defender-capsule'] = 48,
    ['depleted-uranium-fuel-cell'] = 8,
    ['destroyer-capsule'] = 1024,
    ['discharge-defense-equipment'] = 2048,
    ['discharge-defense-remote'] = 2048,
    ['display-panel'] = 16,
    ['distractor-capsule'] = 256,
    ['efficiency-module'] = 128,
    ['efficiency-module-2'] = 512,
    ['efficiency-module-3'] = 2048,
    ['electric-engine-unit'] = 64,
    ['electric-furnace'] = 256,
    ['electric-mining-drill'] = 32,
    ['electromagnetic-plant'] = 2048,
    ['electromagnetic-science-pack'] = 1024,
    ['electronic-circuit'] = 4,
    ['energy-shield-equipment'] = 128,
    ['energy-shield-mk2-equipment'] = 2048,
    ['engine-unit'] = 8,
    ['exoskeleton-equipment'] = 1500,
    ['explosive-cannon-shell'] = 16,
    ['explosive-rocket'] = 8,
    ['explosive-uranium-cannon-shell'] = 64,
    ['explosives'] = 3,
    ['express-loader'] = 1024,
    ['express-splitter'] = 256,
    ['express-transport-belt'] = 64,
    ['express-underground-belt'] = 256,
    ['fast-inserter'] = 16,
    ['fast-loader'] = 256,
    ['fast-splitter'] = 64,
    ['fast-transport-belt'] = 16,
    ['fast-underground-belt'] = 64,
    ['fission-reactor-equipment'] = 15000,
    ['firearm-magazine'] = 4,
    ['flamethrower'] = 512,
    ['flamethrower-ammo'] = 32,
    ['flamethrower-turret'] = 2048,
    ['fluid-wagon'] = 256,
    ['flying-robot-frame'] = 128,
    ['foundation'] = 16,
    ['foundry'] = 2048,
    ['fusion-generator'] = 8192,
    ['fusion-power-cell'] = 1024,
    ['fusion-reactor'] = 4096,
    ['fusion-reactor-equipment'] = 15000,
    ['gate'] = 16,
    ['grenade'] = 16,
    ['gun-turret'] = 128,
    ['hazard-concrete'] = 1,
    ['heat-exchanger'] = 256,
    ['heat-pipe'] = 128,
    ['heavy-armor'] = 250,
    ['heavy-oil-barrel'] = 16,
    ['holmium-ore'] = 8,
    ['holmium-plate'] = 32,
    ['ice'] = 1,
    ['ice-platform'] = 32,
    ['inserter'] = 4,
    ['iron-chest'] = 8,
    ['iron-gear-wheel'] = 2,
    ['iron-ore'] = 1,
    ['iron-plate'] = 1,
    ['iron-stick'] = 1,
    ['jellynut'] = 8,
    ['jellynut-seed'] = 2,
    ['lab'] = 64,
    ['land-mine'] = 2,
    ['landfill'] = 20,
    ['laser-turret'] = 1024,
    ['light-armor'] = 50,
    ['light-oil-barrel'] = 16,
    ['lightning-collector'] = 512,
    ['loader'] = 128,
    ['lightning-rod'] = 512,
    ['locomotive'] = 512,
    ['logistic-robot'] = 256,
    ['logistic-science-pack'] = 16,
    ['long-handed-inserter'] = 8,
    ['low-density-structure'] = 64,
    ['lubricant-barrel'] = 16,
    ['mech-armor'] = 9216,
    ['medium-electric-pole'] = 32,
    ['metallurgic-science-pack'] = 512,
    ['military-science-pack'] = 64,
    ['modular-armor'] = 1024,
    ['night-vision-equipment'] = 256,
    ['nuclear-fuel'] = 1024,
    ['nuclear-reactor'] = 8192,
    ['offshore-pump'] = 16,
    ['oil-refinery'] = 512,
    ['passive-provider-chest'] = 256,
    ['personal-laser-defense-equipment'] = 1500,
    ['personal-roboport-equipment'] = 512,
    ['personal-roboport-mk2-equipment'] = 4096,
    ['petroleum-gas-barrel'] = 16,
    ['piercing-rounds-magazine'] = 8,
    ['piercing-shotgun-shell'] = 16,
    ['pipe'] = 1,
    ['pipe-to-ground'] = 8,
    ['pistol'] = 10,
    ['plastic-bar'] = 8,
    ['poison-capsule'] = 32,
    ['power-armor'] = 4096,
    ['power-armor-mk2'] = 32768,
    ['power-switch'] = 16,
    ['processing-unit'] = 512,
    ['production-science-pack'] = 256,
    ['productivity-module'] = 128,
    ['productivity-module-2'] = 512,
    ['productivity-module-3'] = 2048,
    ['programmable-speaker'] = 16,
    ['promethium-science-pack'] = 2048,
    ['pump'] = 32,
    ['pumpjack'] = 64,
    ['quality-module'] = 1024,
    ['quality-module-2'] = 32768,
    ['quality-module-3'] = 65536,
    ['radar'] = 32,
    ['rail'] = 4,
    ['rail-chain-signal'] = 8,
    ['rail-signal'] = 8,
    ['railgun'] = 65536,
    ['railgun-ammo'] = 64,
    ['railgun-turret'] = 2048,
    ['raw-fish'] = 10,
    ['recycler'] = 512,
    ['refined-concrete'] = 2,
    ['refined-hazard-concrete'] = 2,
    ['repair-pack'] = 8,
    ['requester-chest'] = 512,
    ['roboport'] = 2048,
    ['rocket'] = 6,
    ['rocket-fuel'] = 256,
    ['rocket-launcher'] = 128,
    ['rocket-silo'] = 65536,
    ['rocket-turret'] = 4096,
    ['scrap'] = 4,
    ['selector-combinator'] = 16,
    ['shotgun'] = 16,
    ['shotgun-shell'] = 4,
    ['slowdown-capsule'] = 16,
    ['small-electric-pole'] = 2,
    ['small-lamp'] = 4,
    ['solar-panel'] = 64,
    ['solar-panel-equipment'] = 256,
    ['solid-fuel'] = 16,
    ['space-platform-foundation'] = 128,
    ['space-platform-starter-pack'] = 1024,
    ['space-science-pack'] = 2048,
    ['speed-module'] = 128,
    ['speed-module-2'] = 512,
    ['speed-module-3'] = 2048,
    ['spidertron'] = 32768,
    ['splitter'] = 16,
    ['stack-inserter'] = 256,
    ['steam-engine'] = 32,
    ['steam-turbine'] = 256,
    ['steel-chest'] = 32,
    ['steel-furnace'] = 64,
    ['steel-plate'] = 8,
    ['stone'] = 1,
    ['stone-brick'] = 2,
    ['stone-furnace'] = 4,
    ['stone-wall'] = 5,
    ['storage-chest'] = 256,
    ['storage-tank'] = 64,
    ['submachine-gun'] = 32,
    ['substation'] = 256,
    ['sulfur'] = 4,
    ['sulfuric-acid-barrel'] = 16,
    ['supercapacitor'] = 512,
    ['superconductor'] = 1024,
    ['tank'] = 4096,
    ['tesla-ammo'] = 128,
    ['tesla-turret'] = 4096,
    ['teslagun'] = 65536,
    ['thruster'] = 1024,
    ['toolbelt-equipment'] = 256,
    ['train-stop'] = 64,
    ['transport-belt'] = 2,
    ['tree-seed'] = 1,
    ['tungsten-carbide'] = 16,
    ['tungsten-ore'] = 4,
    ['tungsten-plate'] = 16,
    ['turbo-splitter'] = 512,
    ['turbo-transport-belt'] = 256,
    ['turbo-underground-belt'] = 512,
    ['underground-belt'] = 8,
    ['uranium-235'] = 1024,
    ['uranium-238'] = 32,
    ['uranium-cannon-shell'] = 64,
    ['uranium-fuel-cell'] = 128,
    ['uranium-ore'] = 2,
    ['uranium-rounds-magazine'] = 64,
    ['utility-science-pack'] = 256,
    ['water-barrel'] = 4,
    ['wood'] = 1,
    ['wooden-chest'] = 2,
    ['yumako'] = 8,
    ['yumako-mash'] = 16,
    ['yumako-seed'] = 2,
}

local quality_blacklist =
{
    ['active-provider-chest'] = 256,
    ['advanced-circuit'] = 128,
    ['agricultural-tower'] = 128,
    ['arithmetic-combinator'] = 16,
    ['assembling-machine-1'] = 32,
    ['barrel'] = 4,
    ['battery'] = 16,
    ['boiler'] = 8,
    ['buffer-chest'] = 512,
    ['burner-inserter'] = 2,
    ['burner-mining-drill'] = 8,
    ['cannon-shell'] = 8,
    ['cliff-explosives'] = 32,
    ['concrete'] = 1,
    ['constant-combinator'] = 8,
    ['copper-cable'] = 1,
    ['copper-plate'] = 1,
    ['decider-combinator'] = 16,
    ['depleted-uranium-fuel-cell'] = 8,
    ['display-panel'] = 16,
    ['electronic-circuit'] = 4,
    ['engine-unit'] = 8,
    ['explosive-cannon-shell'] = 16,
    ['explosives'] = 3,
    ['express-loader'] = 1024,
    ['express-splitter'] = 256,
    ['express-transport-belt'] = 64,
    ['express-underground-belt'] = 256,
    ['fast-loader'] = 256,
    ['fast-splitter'] = 64,
    ['fast-transport-belt'] = 16,
    ['fast-underground-belt'] = 64,
    ['firearm-magazine'] = 4,
    ['flamethrower'] = 512,
    ['flamethrower-ammo'] = 32,
    ['flamethrower-turret'] = 2048,
    ['fusion-power-cell'] = 1024,
    ['gate'] = 16,
    ['hazard-concrete'] = 1,
    ['heat-pipe'] = 128,
    ['heavy-armor'] = 250,
    ['heavy-oil-barrel'] = 16,
    ['inserter'] = 4,
    ['iron-gear-wheel'] = 2,
    ['iron-plate'] = 1,
    ['iron-stick'] = 1,
    ['light-armor'] = 50,
    ['light-oil-barrel'] = 16,
    ['loader'] = 128,
    ['lubricant-barrel'] = 16,
    ['night-vision-equipment'] = 256,
    ['nuclear-fuel'] = 1024,
    ['offshore-pump'] = 16,
    ['passive-provider-chest'] = 256,
    ['petroleum-gas-barrel'] = 16,
    ['pipe'] = 1,
    ['pipe-to-ground'] = 8,
    ['plastic-bar'] = 8,
    ['power-switch'] = 16,
    ['programmable-speaker'] = 16,
    ['pump'] = 32,
    ['radar'] = 32,
    ['rail'] = 4,
    ['rail-chain-signal'] = 8,
    ['rail-signal'] = 8,
    ['raw-fish'] = 10,
    ['refined-concrete'] = 2,
    ['refined-hazard-concrete'] = 2,
    ['repair-pack'] = 8,
    ['requester-chest'] = 512,
    ['rocket-fuel'] = 256,
    ['selector-combinator'] = 16,
    ['small-lamp'] = 4,
    ['solid-fuel'] = 16,
    ['splitter'] = 16,
    ['steam-engine'] = 32,
    ['steel-plate'] = 8,
    ['stone-brick'] = 2,
    ['stone-furnace'] = 4,
    ['storage-tank'] = 64,
    ['submachine-gun'] = 32,
    ['sulfur'] = 4,
    ['sulfuric-acid-barrel'] = 16,
    ['train-stop'] = 64,
    ['transport-belt'] = 2,
    ['turbo-splitter'] = 512,
    ['turbo-transport-belt'] = 256,
    ['turbo-underground-belt'] = 512,
    ['underground-belt'] = 8,
    ['uranium-235'] = 1024,
    ['uranium-238'] = 32,
    ['uranium-cannon-shell'] = 64,
    ['uranium-fuel-cell'] = 128,
    ['water-barrel'] = 4,
    ['wood'] = 1,
    ['wooden-chest'] = 2,
}

local function get_zone_loot_bias(budget, zone)
    zone = zone and (type(zone) == 'number' and zone) or 1
    if this.zone_loot_bias[zone] then
        return this.zone_loot_bias[zone]
    end

    local zone_factor = math.max(1, zone)
    local min_value = 1 * zone_factor ^ 1.2
    local max_value = budget * zone_factor ^ 1.2

    local data =
    {
        whitelist = {},
        blacklist = {},
        value_multiplier = 1 + (zone_factor * 0.05),
    }

    for name, worth in pairs(item_worths) do
        if prototypes.item[name] then
            if worth >= min_value and worth <= max_value then
                data.whitelist[name] = true
            else
                data.blacklist[name] = true
            end
        end
    end

    this.zone_loot_bias[zone] = data
    return data
end

local function get_zone_items(budget, zone)
    local cached = this.zone_item_names[zone]
    if cached and #cached > 0 then
        return cached
    end

    local bias = get_zone_loot_bias(budget, zone)
    local names = {}
    for name in pairs(bias.whitelist) do
        table_insert(names, name)
    end
    table.sort(names)

    this.zone_item_names[zone] = names
    return names
end

local function shuffle(tbl)
    local size = #tbl
    for i = size, 2, -1 do
        local rand = math_random(i)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

function Public.roll_item_stack(remaining_budget, blacklist, quality, zone)
    if remaining_budget <= 0 then return end
    blacklist = blacklist or {}

    local base = get_zone_items(remaining_budget, zone)
    if not base or #base == 0 then return end

    local items_for_zone = {}
    for i = 1, #base do items_for_zone[i] = base[i] end
    shuffle(items_for_zone)

    local item_name
    local zone_mult = (this.zone_loot_bias[zone] and this.zone_loot_bias[zone].value_multiplier or 1)

    for _, name in ipairs(items_for_zone) do
        local worth = item_worths[name]
        if worth and not blacklist[name] and (worth * zone_mult) <= remaining_budget then
            item_name = name
            break
        end
    end

    if not item_name then return end

    local proto = prototypes.item[item_name]
    local stack_size = (proto and proto.stack_size) or 1
    local item_count = 1
    local unit_price = item_worths[item_name] * zone_mult

    for c = 1, math_random(1, stack_size) do
        if (c * unit_price) <= remaining_budget then
            item_count = c
        else
            break
        end
    end

    if quality_blacklist[item_name] then
        quality = 'normal'
    end

    return { name = item_name, count = item_count, quality = quality }
end

function Public.roll(remaining_budget, max_slots, blacklist, quality, zone)
    zone = zone and (type(zone) == 'number' and zone) or 1
    local item_stack_set, item_stack_set_worth = {}, 0
    local zone_mult = (this.zone_loot_bias[zone] and this.zone_loot_bias[zone].value_multiplier or 1)

    for i = 1, max_slots do
        if remaining_budget <= 0 then break end
        local item_stack = Public.roll_item_stack(remaining_budget, blacklist, quality, zone)
        if not item_stack then break end

        item_stack_set[i] = item_stack

        local base = (item_worths[item_stack.name] or 0)
        local worth = base * zone_mult * item_stack.count
        remaining_budget = remaining_budget - worth
        item_stack_set_worth = item_stack_set_worth + worth
    end

    return item_stack_set, item_stack_set_worth
end

return Public
