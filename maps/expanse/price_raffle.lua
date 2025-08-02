--[[
roll(budget, max_slots, blacklist) returns a table with item-stacks
budget		-	the total value of the item stacks combined
max_slots	-	the maximum amount of item stacks to return
blacklist		-	optional list of item names that can not be rolled. example: {["substation"] = true, ["roboport"] = true,}
]]
local Public = {}

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local math_random = math.random
local math_floor = math.floor

local function get_item_worths(level, specific_only)
    local SA = script.active_mods['space-age']
    local item_worths = {
        [1] = {
            --basic stuff
            ['iron-plate'] = 1,
            ['copper-plate'] = 1,
            ['wood'] = 2,
            ['iron-gear-wheel'] = 2, -- 2x 1
            ['wooden-chest'] = 4, -- 2x 2
            ['iron-chest'] = 8, -- 8x 1
            ['transport-belt'] = 2, -- 1x1 + 1x2 / 2
            ['burner-inserter'] = 3, -- 1x1 + 1x2
            ['stone-brick'] = 2,
            ['stone-furnace'] = 4,
            ['burner-mining-drill'] = 14, -- 3x1 + 3x2 + 1x4            
            ['firearm-magazine'] = 4, -- 4x1
            ['light-armor'] = 40, -- 40x1
            ['copper-cable'] = 1, -- 1x1 / 2
            ['small-electric-pole'] = 4, -- 1x2 + 2x1
            ['electronic-circuit'] = 4, -- 1x1 + 3x1
            ['lab'] = 70, -- 10x2 + 10x4 + 4x2
            ['inserter'] = 8, -- 1x1 + 1x2 + 1x4
            ['pipe'] = 1, -- 1x1
            ['pipe-to-ground'] = 15, -- 5x1 + 10x1
            ['offshore-pump'] = 8, -- 2x2 + 3x1
            ['boiler'] = 8, -- 4x1 + 1x4
            ['steam-engine'] = 32, --10x1 + 8x2 + 5x1

            --red science tier
            ['automation-science-pack'] = 4, -- 1x1 + 1x2
            ['assembling-machine-1'] = 32, -- 9x1 + 5x2 + 3x4
            ['long-handed-inserter'] = 12, -- 1x8 + 1x1 + 1x2
            ['gun-turret'] = 52, -- 20x1 + 10x1 + 10x2
            ['small-lamp'] = 10, -- 1x1 + 3x1 + 1x4
            ['shotgun-shell'] = 4, -- 2x1 + 2x1
            ['submachine-gun'] = 36, -- 10x1 + 5x1 + 10x2
            ['shotgun'] = 48, -- 5x2 + 15x1 + 10x1 + 5x2
            ['stone-wall'] = 10, -- 5x2
            ['underground-belt'] = 20, --10x1 + 5x2
            ['splitter'] = 35, --5x1 + 5x4 + 4x2
            ['radar'] = 40, --10x1 + 5x2 + 5x4
            ['electric-mining-drill'] = 32, --10x1 + 5x2 + 3x4
            ['repair-pack'] = 12, -- 2x2 + 2x4
            ['fast-inserter'] = 20, --1x8 + 2x1 + 2x4
            ['steel-plate'] = 6, --5x1 + 1
            ['steel-chest'] = 50, --8x6
            ['heavy-armor'] = 400, --100x1 + 50x6
        },
        [2] = {
            --green science tier
            ['logistic-science-pack'] = 10, --1x8 + 1x2
            ['piercing-rounds-magazine'] = 8, -- 2x1 + 1x6 + 2x4 / 2
            ['grenade'] = 16,
            ['assembling-machine-2'] = 70, --1x32 +2x6 + 5x2 +3x4
            ['landfill'] = 25,
            ['steel-furnace'] = 60, --6x6 +10x2
            ['engine-unit'] = 10, --1x6 + 1x2 + 2x1
            ['storage-tank'] = 52, --20x1 +5x6
            ['pump'] = 18, -- 1x6 +1x10 +1x1
            ['barrel'] = 6, --1x6
            ['water-barrel'] = 8,
            ['iron-stick'] = 1,
            ['display-panel'] = 6, --1x1 + 1x4
            ['programmable-speaker'] = 30, --3x1 +4x1 +5x1 +4x4
            ['power-switch'] = 20, --5x1 +5x1 +2x4
            ['arithmetic-combinator'] = 26, --5x1 + 5x4
            ['decider-combinator'] = 26, --5x1 + 5x4
            ['constant-combinator'] = 15, --5x1 +2x4
            ['gate'] = 30, --2x6 +2x4 + 1x10
            ['pumpjack'] = 84, -- 5x6 + 10x2 + 5x4 + 10x1
            ['crude-oil-barrel'] = 10,
            ['oil-refinery'] = 200, -- 15x6 + 10x2 + 10x4 + 10x1 + 10x2
            ['chemical-plant'] = 70, -- 5x6 + 5x2 + 5x4 + 5x1
            ['solid-fuel'] = 16,
            ['petroleum-gas-barrel'] = 16,
            ['medium-electric-pole'] = 20, -- 2x6 + 4x1 + 2x1
            ['big-electric-pole'] = 45, -- 5x6 + 8x1 + 4x1
            ['sulfur'] = 4,
            ['sulfuric-acid-barrel'] = 16,
            ['explosives'] = 4,
            ['battery'] = 14,
            ['accumulator'] = 75, -- 5x14 + 2x1
            ['cliff-explosives'] = not SA and 70 or nil, --10x4 + 1x6 + 1x16
            ['fast-transport-belt'] = 14, --5x2 + 1x2
            ['fast-underground-belt'] = 64, --40x2 + 2x20 / 2
            ['fast-splitter'] = 100, -- 10x2 + 10x4 + 1x35
            ['rail'] = 8,
            ['locomotive'] = 440, --30x6 + 10x4 + 20x10
            ['cargo-wagon'] = 180, --20x1 + 20x6 + 10x2
            ['fluid-wagon'] = 190, -- 16x6 + 10x2 + 1x52 + 8x1
            ['car'] = 140, -- 20x1 + 5x6 + 8x10
            ['train-stop'] = 54, -- 6x1 + 3x6 + 6x1 + 5x4
            ['rail-signal'] = 10, --5x1 + 1x4
            ['rail-chain-signal'] = 10, --5x1 + 1x4
            ['plastic-bar'] = 8,
            ['concrete'] = 4,
            ['hazard-concrete'] = 4,
            ['refined-concrete'] = 10, --1x6 + 8x1 + 20x4 + water / 10
            ['refined-hazard-concrete'] = 10,
            ['solar-panel'] = 100, -- 5x1 + 5x6 + 15x4
            ['advanced-circuit'] = 30, --2x8 + 4x1 + 2x4
            ['modular-armor'] = 1250, --30x30 + 50x6
            ['solar-panel-equipment'] = 200, --1x100 + 2x30 + 5x6
            ['battery-equipment'] = 140, --10x6 + 5x14
            ['belt-immunity-equipment'] = 220, --10x6 + 5x30
            ['night-vision-equipment'] = 220, -- 10x6 + 5x30
            ['bulk-inserter'] = 90, --15x2 + 1x30 + 1x20
            ['efficiency-module'] = 180, -- 5x4 + 5x30
            ['productivity-module'] = 180,
            ['speed-module'] = 180,
        },
        [3] = {
            --military science tier
            ['military-science-pack'] = 24, -- 1x8 + 1x16 + 2x10 /2
            ['flamethrower'] = 60, --5x6 + 10x2
            ['flamethrower-ammo'] = 40,
            ['flamethrower-turret'] = 300, -- 30x6 + 15x2 + 5x10 + 10x1
            ['defender-capsule'] = 48, -- 3x2 + 3x4 + 3x8
            ['land-mine'] = 4, --1x6 + 2x4 / 4
            ['rocket-launcher'] = 40, --5x1 + 5x2 + 5x4
            ['rocket'] = 8,
            ['energy-shield-equipment'] = 225, --10x6 + 5x30

            --chemical science tier
            ['chemical-science-pack'] = 64, -- 3x30 + 1x4 + 2x10 / 2
            ['selector-combinator'] = 220, -- 2x30 + 5x26
            ['heavy-oil-barrel'] = 16,
            ['light-oil-barrel'] = 16,
            ['lubricant-barrel'] = 16,
            ['electric-engine-unit'] = 30, -- 2x4 + 1x10
            ['flying-robot-frame'] = 90, --1x6 + 2x14 + 3x4 + 1x30
            ['construction-robot'] = 120, --1x90 + 2x4
            ['roboport'] = 1900, --45x6 + 45x2 + 45x30
            ['passive-provider-chest'] = 100, --3x2 + 1x30 + 1x50
            ['storage-chest'] = 100,
            ['logistic-robot'] = 180, --1x90 + 2x30
            ['personal-roboport-equipment'] = 1250, --20x6 + 45x14 + 40x2 + 10x30
            ['substation'] = 240, --5x30 + 6x1 +10x6
            ['electric-furnace'] = 260, --10x6 + 5x30 + 10x2
            ['low-density-structure'] = 80, --20x1 + 2x6 + 5x8
            ['processing-unit'] = 160, --20x4 + 2x30 
            ['rocket-fuel'] = 180,
            ['power-armor'] = 7500, --40x160 + 40x6 + 20x30
            ['exoskeleton-equipment'] = 2800, --20x6 + 10x160 + 30x30
            ['combat-shotgun'] = 150, --10x2 + 10x1 + 15x6 + 5x2
            ['poison-capsule'] = 50, --3x4 + 3x6 + 10
            ['slowdown-capsule'] = 25, --2x6 + 2x4 + 5
            ['explosive-rocket'] = 16, --2x4 + 8
            ['tank'] = 1200, --50x6 + 15x2 + 10x30 + 32x10
            ['cannon-shell'] = 35, --2x6 + 2x8 + 1x4
            ['explosive-cannon-shell'] = 40, --2x6 + 2x8 + 2x4
            ['laser-turret'] = 400, --20x6 + 12x14 + 20x4
            ['distractor-capsule'] = 320, --3x30 + 4x48
            ['discharge-defense-equipment'] = 5500, --20x6 + 5x160 + 10x400
            ['personal-laser-defense-equipment'] = 6000, --20x160 + 5x80 + 5x400
            ['centrifuge'] = 4200, --50x6 + 100x2 + 100x30 + 100x4
            ['nuclear-reactor'] = 22000, --500x1 + 500x6 + 500x30 + 500x4
            ['heat-pipe'] = 100, --20x1 +10x6
            ['heat-exchanger'] = 200, --100x1 +10x6 +10x1
            ['steam-turbine'] = 200, --50x1 + 50x2 + 20x1
            ['uranium-235'] = 1000,
            ['uranium-238'] = 30,
            ['uranium-fuel-cell'] = 160, --1x1000 +19x30+10x1 /10
            ['energy-shield-mk2-equipment'] = not SA and 3600 or nil, --10x225 + 5x160 + 5x80
            ['battery-mk2-equipment'] = not SA and 4400 or nil, --15x160 + 5x80 + 10x140
            ['speed-module-2'] = not SA and 1800 or nil, --5x30 + 5x160 + 4x180
            ['efficiency-module-2'] = not SA and 1800 or nil,
            ['productivity-module-2'] = not SA and 1800 or nil,
        },
        [4] = {
            --production science tier
            ['production-science-pack'] = 240, -- 30x8 + 1x260 + 1x180 / 3
            ['beacon'] = 800, --10x6 + 10x1 + 20x4 + 20x30
            ['express-transport-belt'] = 45, --10x2 + 1x14 + 
            ['express-splitter'] = 460, --10x2 + 10x30 + 1x100 
            ['express-underground-belt'] = 160, --80x2 + 2x64  / 2
            ['assembling-machine-3'] = 950,--2x70 + 4x180
            ['speed-module-3'] = not SA and 9000 or nil, --5x30 + 5x160 + 4x1800
            ['efficiency-module-3'] = not SA and 9000 or nil,
            ['productivity-module-3'] = not SA and 9000 or nil,
            ['nuclear-fuel'] = not SA and 1250 or nil,

            --utility science tier
            ['utility-science-pack'] = 240, --2x160 + 3x80 +1x90 /3
            ['piercing-shotgun-shell'] = 28, --5x1 + 2x6 + 2x4
            ['cluster-grenade'] = 180, --5x6 + 5x4 + 7x16
            ['fission-reactor-equipment'] = 38000, --200x160 +50x80 +4x160
            ['destroyer-capsule'] = 1600, --1x180 + 4x320
            ['power-armor-mk2'] = 110000, --60x160 + 40x30 + 30x80 + 25x1800 + 25x1800
            ['uranium-rounds-magazine'] = 42,
            ['uranium-cannon-shell'] = 70,
            ['explosive-uranium-cannon-shell'] = 75,
            ['active-provider-chest'] = not SA and 100 or nil, --3x4 + 1x30 + 1x50
            ['buffer-chest'] = not SA and 100 or nil,
            ['requester-chest'] = not SA and 100 or nil,
            ['personal-roboport-mk2-equipment'] = not SA and 25000 or nil, -- 100x160 + 20x80 + 5x1250
        },
        [5] = {
            --space science tier
            --['rocket-silo'] = not SA and 52000 or nil, --1000x6 + 200x160 + 200x30 +100x1 + 1000x4
            ['space-science-pack'] = not SA and 450 or 8, -- 1000x160 + 1000x80 + 1000x180 /1000
            ['satellite'] = not SA and 55000 or nil, --100x160 + 100x80 + 50x180 + 100x100 + 100x75 + 5x40
            --['cargo-landing-pad'] = not SA and 2700 or nil, --25x6 + 10x160 + 200x4
            --['atomic-bomb'] = 34000, --not enabled as it destroys chests in SA --10x4 + 10x160 + 30x1000
            ['spidertron'] = not SA and 128000 or nil, --16x160 + 150x80 + 2x9000 + 4x40 + 2x38000 + 4x2800 + 2x40
            ['artillery-wagon'] = not SA and 1800 or nil, --40x6 + 10x2 + 20x30 + 64x10 +16x1
            ['artillery-shell'] = not SA and 250 or nil, --8x4 + 4x40 + 1x40
            ['artillery-turret'] = not SA and 1500 or nil, --60x6 + 40x2 + 20x30 + 60x4
        },
        [6] = {},
        [7] = {},
        [8] = {},
        [9] = {},
        [10] = {}
    }
    if script.active_mods['space-age'] then
        local sa_worths = {
            [2] = {
                --green science tier
                ['quality-module'] = 180,
            },
            [4] = {
                --production science tier
                ['rail-support'] = 300, --10x6 + 20x10
                ['rail-ramp'] = 1200, --10x6 + 8x8 + 100x10

                --utility science tier
                ['battery-mk2-equipment'] = 4400, --15x160 + 5x80 + 10x140
            },
            [5] = {
                --space science tier
                ['space-platform-foundation'] = 64,
                ['space-platform-starter-pack'] = 512,
                ['asteroid-collector'] = 2800, --5x160 + 8x30 + 20x80
                ['crusher'] = 2100, --10x6 + 10x30 + 20x80
                ['cargo-bay'] = 2700, --20x6 + 5x160 + 20x80
                ['ice'] = 2,
                ['carbon'] = 2,
                ['speed-module-2'] = 1800, --5x30 + 5x160 + 4x180
                ['efficiency-module-2'] = 1800,
                ['productivity-module-2'] = 1800,
                ['quality-module-2'] = 1800,
                ['active-provider-chest'] = 100, --3x4 + 1x30 + 1x50
                ['buffer-chest'] = 100,
                ['requester-chest'] = 100,
                ['thruster'] = 1000, --10x6 + 10x160 + 5x30
                ['nuclear-fuel'] = 1250,
            },
            [6] = {
                --vulcanus
                ['calcite'] = 2,
                ['tungsten-carbide'] = 8,
                ['foundry'] = 1250, --50x6 + 30x4 + 50x8 + 20x10
                ['big-mining-drill'] = 1000, --10x30 + 10x30 + 20x8 + 1x32 + 20x1
                ['tungsten-plate'] = 8,
                ['metallurgic-science-pack'] = 75, -- 3x8 + 2x8 + 20x1
                ['cliff-explosives'] = 90, --10x4 + 1x6 + 1x16 + 10x2
                ['speed-module-3'] = 9000, --5x30 + 5x160 + 4x1800 + 1x8
                ['turbo-transport-belt'] = 100, --5x8 + 1x45
                ['turbo-underground-belt'] = 360, --40x8 + 2x160 / 2
                ['turbo-splitter'] = 1000, --2x160 + 15x8 + 1x460
                ['artillery-wagon'] = 3600, --40x2 + 10x160 + 60x10 + 60x8 + 60x10
                ['artillery-shell'] = 120, --8x4 + 4x8 + 1x40 +1x2
                ['artillery-turret'] = 2900, --40x2 + 10x160 + 60x8 + 60x10

            },
            [7] = {
                --fulgora
                ['lightning-rod'] = 75, --8x6 + 12x1 + 4x2
                ['recycler'] = 1400, --20x6 + 40x2 + 6x160 + 20x4
                ['holmium-plate'] = 8,
                ['electromagnetic-plant'] = 11000, --50x6 + 50x160 + 150x8 + 50x10
                ['superconductor'] = 12, --1x1 + 1x8 + 1x8 + 5 /2
                ['supercapacitor'] = 75, --1x14 + 4x4 + 2x8 + 2x12
                ['electromagnetic-science-pack'] = 200, --1x75 + 1x75 + 
                ['lightning-collector'] = 800, --8x75 + 1x75 + 1x75 + 80
                ['quality-module-3'] = 9000,
                ['battery-mk3-equipment'] = 23500, --10x75 + 5x4400
                ['personal-roboport-mk2-equipment'] = 16000, --50x160 + 50x12 + 5x1250
                ['energy-shield-mk2-equipment'] = 3600,
                ['teslagun'] = 550, --30x8 + 10x8 + 10x12 + 100
                ['tesla-turret'] = 4200, --10x160 + 50x12 + 10x75 + 1x550 + 500
                ['tesla-ammo'] = 100, --1x8 +1x75 + 10
                ['mech-armor'] = 135000, --100x160 + 200x8 + 50x12 + 50x75 + 1x110000
            },
            [8] = {
                --gleba
                ['spoilage'] = 1,
                ['nutrients'] = 2,
                ['agricultural-tower'] = 140, --10x6 + 3x4 + 1x25 +20x1
                ['heating-tower'] = 620, --20x4 + 2x8 + 5x100
                ['jelly'] = 3,
                ['jellynut'] = 3,
                ['jellynut-seed'] = 200,
                ['iron-bacteria'] = 20,
                ['yumako'] = 3,
                ['yumako-mash'] = 3,
                ['yumako-seed'] = 200,
                ['copper-bacteria'] = 20,
                ['artificial-yumako-soil'] = 700,
                ['artificial-jellynut-soil'] = 700,
                ['pentapod-egg'] = 50,
                ['biochamber'] = 150, --20x1 + 5x4 + 5x2 + 1x50 +1x25
                ['bioflux'] = 25,
                ['agricultural-science-pack'] = 100,
                ['carbon-fiber'] = 40,
                ['efficiency-module-3'] = 9000,
                ['toolbelt-equipment'] = 550, --3x30 + 10x40
                ['capture-robot-rocket'] = 1000, --2x6 + 2x160 + 1x90 + 20x25
                ['biter-egg'] = 50,
                ['productivity-module-3'] = 9000,
                ['rocket-turret'] = 1900, --20x6 + 20x2 + 4x160 + 20x40 + 4x40
                ['tree-seed'] = 5,
                ['raw-fish'] = 50,
                ['stack-inserter'] = 400, --1x160 + 10x3 + 2x40 + 1x90
                ['overgrowth-yumako-soil'] = 3500, --5x200 + 50x1 + 10x50 + 2x700 + 100
                ['overgrowth-jellynut-soil'] = 3500,
                ['biolab'] = 6000, --3x1000 + 10x50 + 25x10 + 1x70 + 2x1000
                ['spidertron'] = 95000, --1x50 + 2x38000 + 4x2800 + 2x40 + 1x1900
            },
            [9] = {
                --aquilo
                ['ice-platform'] = 250,
                ['lithium'] = 15,
                ['lithium-plate'] = 16,
                ['cryogenic-plant'] = 4500, --20x160 + 20x12 + 20x16 +40x10
                ['fluoroketone-hot-barrel'] = 50,
                ['fluoroketone-cold-barrel'] = 50,
                ['cryogenic-science-pack'] = 25, --3x2 + 1x16 + 6
                ['quantum-processor'] = 300, --1x160 + 1x8 + 1x12 + 1x40 +2x16 +10
                ['railgun'] = 7000, --10x8 + 10x12 + 20x300 + 10
                ['railgun-turret'] = 34000, --30x8 + 50x12 + 20x40 + 100x300 + 100
                ['railgun-ammo'] = 60, --5x6 + 2x4 + 10x1
                ['foundation'] = 350, --20 + 4x8 + 4x40 + 4x16 + 20
                ['fusion-reactor'] = 85000, --200x8 + 200x12 + 250x300
                ['fusion-generator'] = 18000, -- 100x8 + 100x12 + 50x300
                ['fusion-power-cell'] = 50,
                ['fusion-reactor-equipment'] = 125000, --250x8 + 25x75 + 100x40 + 250x300 + 10x50 + 1x38000
                ['captive-biter-spawner'] = 18000,
            },
            [10] = {
                ['promethium-science-pack'] = 1000
            }
        }
        for tier, list in pairs(sa_worths) do
            for key, value in pairs(list) do
                item_worths[tier][key] = value
            end
        end
    end
    if specific_only and level then
        return item_worths[level]
    else
        local final_list = {}
        for i = 1, level or #item_worths, 1 do
            for key, value in pairs(item_worths[i]) do
                final_list[key] = value
            end
        end
        return final_list
    end
end

local item_names = {{},{},{},{},{},{},{},{},{},{}}
for i = 1, 5, 1 do
    for k, _ in pairs(get_item_worths(i)) do
        table_insert(item_names[i], k)
    end
end
if script.active_mods['space-age'] then
    for j = 6, 9, 1 do
        --item_names[j] = item_names[5]
        for k, _ in pairs(get_item_worths(j, true)) do
            table_insert(item_names[j], k)
        end
    end
    for k, _ in pairs(get_item_worths(10)) do
        table_insert(item_names[10], k)
    end
end
local size_of_item_names = {
    #item_names[1],
    #item_names[2],
    #item_names[3],
    #item_names[4],
    #item_names[5],
    #item_names[6],
    #item_names[7],
    #item_names[8],
    #item_names[9],
    #item_names[10]
}

function Public.get_item_worth(name, quality_level)
    return math.ceil((get_item_worths()[name] or 0) * (1 + quality_level / 5))
end

function roll_quality(tier, remaining_budget)
    if not script.active_mods['quality'] then
        return 'normal', 0
    end
    local levels = {
        [1] = 0,
        [2] = 0,
        [3] = 1,
        [4] = 1,
        [5] = 2,
        [6] = 3,
        [7] = 3,
        [8] = 3,
        [9] = 3,
        [10] = 5
    }
    local thresholds = {
        { threshold = 9000, level = 5, quality = 'legendary' },
        { threshold = 8000, level = 3, quality = 'epic' },
        { threshold = 7000, level = 2, quality = 'rare' },
        { threshold = 6000, level = 1, quality = 'uncommon' }
    }
    local roll = math.random(1,10000 + math.ceil(math.min(0, remaining_budget/100)))

    local tier_level = levels[tier] or 0

    for _, t in ipairs(thresholds) do
        if roll > t.threshold and tier_level >= t.level then
            return t.quality, t.level
        end
    end
    return 'normal', 0
end

local function get_raffle_keys(tier)
    local raffle_keys = {}
    for i = 1, size_of_item_names[tier], 1 do
        raffle_keys[i] = i
    end
    table_shuffle_table(raffle_keys)
    return raffle_keys
end

function Public.roll_item_stack(remaining_budget, tier, blacklist)
    if remaining_budget <= 0 then
        return false
    end
    local raffle_keys = get_raffle_keys(tier)
    local item_name = false
    local item_worth = 0
    local item_quality, quality_level
    local item_worths = get_item_worths(tier)
    for _, index in pairs(raffle_keys) do
        item_name = item_names[tier][index]
        item_quality, quality_level = roll_quality(tier, remaining_budget)
        item_worth = math.ceil(item_worths[item_name] * (1 + quality_level / 5))
        if not blacklist[item_name] and item_worth <= remaining_budget then
            break
        end
    end

    local stack_size = prototypes.item[item_name].stack_size * 32

    local item_count = 1

    for c = 1, math_random(1, stack_size), 1 do
        local price = c * item_worth
        if price <= remaining_budget then
            item_count = c
        else
            break
        end
    end

    return { name = item_name, count = item_count , quality = item_quality, quality_level = quality_level}
end

local function roll_item_stacks(remaining_budget, max_slots,  tier, blacklist)
    local item_stack_set = {}
    local item_stack_set_worth = 0
    local item_worths = get_item_worths(tier)

    for i = 1, max_slots, 1 do
        if remaining_budget <= 0 then
            break
        end
        local item_stack = Public.roll_item_stack(remaining_budget, tier, blacklist)
        if item_stack then
            item_stack_set[i] = item_stack
            remaining_budget = remaining_budget - item_stack.count * item_worths[item_stack.name] * (1 + item_stack.quality_level / 5)
            item_stack_set_worth = item_stack_set_worth + item_stack.count * item_worths[item_stack.name] * (1 + item_stack.quality_level / 5)
        end
    end

    return item_stack_set, item_stack_set_worth
end

function Public.roll(budget, max_slots, tier, blacklist)
    if not budget then
        return {}
    end
    if not max_slots then
        return {}
    end

    local b
    if not blacklist then
        b = {}
    else
        b = blacklist
    end

    budget = math_floor(budget)
    if budget == 0 then
        return {}
    end

    local final_stack_set
    local final_stack_set_worth = 0

    for _ = 1, 5, 1 do
        local item_stack_set, item_stack_set_worth = roll_item_stacks(budget, max_slots, tier, b)
        if item_stack_set_worth > final_stack_set_worth or item_stack_set_worth == budget then
            final_stack_set = item_stack_set
            final_stack_set_worth = item_stack_set_worth
        end
    end
    return final_stack_set
end

return Public
