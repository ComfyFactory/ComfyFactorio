local Public = {}

local SA = script.active_mods['space-age']

Public.mission_unlocks = {
    [4] = 'rocket-silo',
    [5] = SA and 'space-platform-thruster' or 'rocket-silo',
    [6] = SA and 'calcite-processing' or nil,
    [7] = SA and 'recycling' or nil,
    [8] = SA and 'jellynut' or nil,
    [9] = SA and 'lithium-processing' or nil,
    [10] = SA and 'promethium-science-pack' or nil
}

Public.locked_techs = {
    [1] = SA and 'planet-discovery-vulcanus' or nil,
    [2] = SA and 'planet-discovery-fulgora' or nil,
    [3] = SA and 'planet-discovery-gleba' or nil,
    [4] = SA and 'planet-discovery-aquilo' or nil,
}

Public.costs = {
    [4] = {
        [1] = {
            ['space-platform-starter-pack|normal'] = 1
        },
        [2] = {
            ['space-platform-foundation|normal'] = 100,
            ['asteroid-collector|normal'] = 8,
            ['crusher|normal'] = 4,
            ['cargo-bay|normal'] = 4,
            ['solar-panel|normal'] = 10,
            ['electric-furnace|normal'] = 5,
            ['assembling-machine-3|normal'] = 5,
            ['fast-inserter|normal'] = 25,
            ['fast-transport-belt|normal'] = 25,

        },
        [3] = {
            ['space-platform-foundation|normal'] = 100,
            ['solar-panel|normal'] = 10,
            ['efficiency-module|normal'] = 16,
            ['speed-module|normal'] = 16,
            ['electric-furnace|normal'] = 5,
            ['crusher|normal'] = 4,
            ['asteroid-collector|normal'] = 8,

        },
        [4] = {
            ['space-platform-foundation|normal'] = 200,
            ['solar-panel|normal'] = 10,
            ['efficiency-module|normal'] = 16,
            ['speed-module|normal'] = 16,
            ['electric-furnace|normal'] = 5,
            ['asteroid-collector|normal'] = 8,
            ['fast-inserter|normal'] = 25,
            ['fast-transport-belt|normal'] = 100,
            ['fast-underground-belt|normal'] = 20,
            ['fast-splitter|normal'] = 10,

        },
        [5] = {
            ['space-platform-foundation|normal'] = 200,
            ['asteroid-collector|normal'] = 8,
            ['fast-transport-belt|normal'] = 200,
            ['fast-underground-belt|normal'] = 20,
            ['solar-panel|normal'] = 40,
            ['cargo-bay|uncommon'] = 4,
            ['foundry|normal'] = 5,
            ['electromagnetic-plant|normal'] = 5,
            ['stack-inserter|normal'] = 50,
        },
        [6] = {
            ['space-platform-foundation|normal'] = 200,
            ['asteroid-collector|rare'] = 8,
            ['transport-belt|normal'] = 100,
            ['underground-belt|normal'] = 20,
            ['fast-inserter|normal'] = 25,
            ['electric-furnace|rare'] = 5,
            ['speed-module-3|normal'] = 20,
            ['productivity-module-3|normal'] = 20,
            ['efficiency-module-3|normal'] = 20,
        },
        [7] = {
            ['space-platform-foundation|normal'] = 400,
            ['asteroid-collector|rare'] = 8,
            ['fast-transport-belt|normal'] = 200,
            ['fast-underground-belt|normal'] = 50,
            ['solar-panel|rare'] = 20,
            ['cryogenic-plant|normal'] = 5,
            ['cargo-bay|uncommon'] = 4,
        },
        [8] = {
            ['rocket-part|legendary'] = 1
        }
    },
    [5] = {
        [1] = {
            ['space-platform-starter-pack|normal'] = 1
        },
        [2] = {
            ['space-platform-foundation|normal'] = 100,
            ['asteroid-collector|normal'] = 8,
            ['crusher|normal'] = 6,
            ['cargo-bay|normal'] = 4,
            ['solar-panel|normal'] = 20,
            ['electric-furnace|normal'] = 10,
            ['assembling-machine-3|normal'] = 8,
            ['fast-inserter|normal'] = 50,
            ['inserter|normal'] = 50,
            ['transport-belt|normal'] = 100,
            ['gun-turret|normal'] = 40,
            ['piercing-rounds-magazine|normal'] = 100,
            ['underground-belt|normal'] = 50,
            ['splitter|normal'] = 20,
            ['chemical-plant|normal'] = 6,
            ['thruster|normal'] = 4,
            ['stone-wall|normal'] = 40,
            ['pipe|normal'] = 30,
            ['pipe-to-ground|normal'] = 20
        },
        [3] = {
            ['repair-pack|normal'] = 200,
            ['gun-turret|normal'] = 100,
            ['piercing-rounds-magazine|normal'] = 200,
            ['space-platform-foundation|normal'] = 100,
            ['stone-wall|normal'] = 100,
            ['storage-tank|normal'] = 4,
        },
        [4] = {
            ['cargo-landing-pad|normal'] = 1,
            ['solar-panel|normal'] = 50,
            ['electric-furnace|normal'] = 50,
            ['medium-electric-pole|normal'] = 50,
            ['steam-turbine|normal'] = 20,
            ['accumulator|normal'] = 50,
            ['electric-mining-drill|normal'] = 50,
            ['assembling-machine-2|normal'] = 50,
            ['oil-refinery|normal'] = 5,
            ['chemical-plant|normal'] = 20,
            ['fast-inserter|normal'] = 50,
            ['roboport|normal'] = 20,
            ['logistic-robot|normal'] = 100,
            ['construction-robot|normal'] = 100,
        },
        [5] = {
            ['repair-pack|normal'] = 200,
            ['gun-turret|normal'] = 100,
            ['piercing-rounds-magazine|normal'] = 200,
            ['space-platform-foundation|normal'] = 100,
            ['stone-wall|normal'] = 100,
        },
        [6] = {
            ['cargo-landing-pad|normal'] = 1,
            ['solar-panel|normal'] = 50,
            ['electric-furnace|normal'] = 50,
            ['medium-electric-pole|normal'] = 50,
            ['accumulator|normal'] = 500,
            ['electric-mining-drill|normal'] = 50,
            ['chemical-plant|normal'] = 20,
            ['fast-inserter|normal'] = 50,
            ['roboport|normal'] = 20,
            ['logistic-robot|normal'] = 100,
            ['construction-robot|normal'] = 100,
            ['assembling-machine-2|normal'] = 50,
        },
        [7] = {
            ['repair-pack|normal'] = 200,
            ['gun-turret|normal'] = 100,
            ['piercing-rounds-magazine|normal'] = 200,
            ['space-platform-foundation|normal'] = 100,
            ['stone-wall|normal'] = 100,
        },
        [8] = {
            ['cargo-landing-pad|normal'] = 1,
            ['nuclear-reactor|normal'] = 2,
            ['heat-exchanger|normal'] = 20,
            ['solar-panel|normal'] = 50,
            ['electric-furnace|normal'] = 50,
            ['medium-electric-pole|normal'] = 50,
            ['laser-turret|normal'] = 100,
            ['roboport|normal'] = 20,
            ['logistic-robot|normal'] = 100,
            ['construction-robot|normal'] = 100,
            ['assembling-machine-2|normal'] = 20,
        },
        [9] = {
            ['tank|normal'] = 4,
            ['piercing-rounds-magazine|normal'] = 200,
            ['rocket|normal'] = 200,
            ['power-armor-mk2|normal'] = 4,
            ['personal-laser-defense-equipment|normal'] = 16,
            ['energy-shield-equipment|normal'] = 16,
            ['battery-mk2-equipment|normal'] = 8,
            ['exoskeleton-equipment|normal'] = 4,
            ['solar-panel-equipment|normal'] = 24,
        },
        [10] = {
            ['space-platform-foundation|normal'] = 100,
            ['piercing-rounds-magazine|normal'] = 200,
            ['solar-panel|uncommon'] = 20,
            ['gun-turret|uncommon'] = 20,
            ['laser-turret|normal'] = 20,
            ['accumulator|normal'] = 20

        },
        [11] = {
            ['space-platform-foundation|normal'] = 400,
            ['repair-pack|normal'] = 200,
            ['gun-turret|uncommon'] = 20,
            ['piercing-rounds-magazine|normal'] = 200,
            ['rocket-turret|normal'] = 8,
            ['rocket|normal'] = 200,
            ['fast-transport-belt|normal'] = 200,
            ['fast-underground-belt|normal'] = 50,
            ['nuclear-reactor|normal'] = 1,
            ['steam-turbine|normal'] = 8,
            ['heat-exchanger|normal'] = 4,
            ['uranium-fuel-cell|normal'] = 50,
            ['pipe-to-ground|normal'] = 50,
            ['storage-tank|normal'] = 5,
            ['stack-inserter|normal'] = 50,
            ['cargo-bay|rare'] = 8
        },
        [12] = {
            ['cargo-landing-pad|normal'] = 1,
            ['concrete|normal'] = 2000,
            ['nuclear-reactor|normal'] = 4,
            ['uranium-fuel-cell|normal'] = 100,
            ['heat-pipe|normal'] = 400,
            ['heat-exchanger|normal'] = 20,
            ['steam-turbine|normal'] = 20,
            ['roboport|normal'] = 20,
            ['construction-robot|normal'] = 200,
            ['logistic-robot|normal'] = 200,
            ['heating-tower|normal'] = 20,
            ['pumpjack|normal'] = 20,
            ['fast-transport-belt|normal'] = 200,
            ['fast-underground-belt|normal'] = 50,
            ['fast-splitter|normal'] = 50,
            ['chemical-plant|normal'] = 20,
            ['electric-furnace|normal'] = 20,
            ['assembling-machine-3|normal'] = 40,
            ['steel-plate|normal'] = 1600,
            ['processing-unit|normal'] = 900,
            ['electric-engine-unit|normal'] = 200,
            ['low-density-structure|normal'] = 600,
        },
        [13] = {
            ['space-platform-foundation|normal'] = 400,
            ['railgun-turret|normal'] = 8,
            ['railgun-ammo|normal'] = 100,
            ['fusion-reactor|normal'] = 1,
            ['fusion-generator|normal'] = 2,
            ['fluoroketone-cold-barrel|normal'] = 100,
            ['fusion-power-cell|normal'] = 100,
        },
        [14] = {
            ['rocket-part|legendary'] = 1
        }
    },
    [6] = { --vulcanus production
        [1] = {
            ['space-platform-starter-pack|normal'] = 1
        },
        [2] = {
            ['space-platform-foundation|normal'] = 100,
            ['asteroid-collector|normal'] = 8,
            ['crusher|normal'] = 4,
            ['cargo-bay|normal'] = 4,
            ['solar-panel|normal'] = 10,
            ['electric-furnace|normal'] = 5,
            ['assembling-machine-3|normal'] = 5,
            ['fast-inserter|normal'] = 50,
            ['inserter|normal'] = 50,
            ['transport-belt|normal'] = 100,
            ['gun-turret|normal'] = 40,
            ['piercing-rounds-magazine|normal'] = 200,
            ['underground-belt|normal'] = 50,
            ['fast-transport-belt|normal'] = 300,
            ['chemical-plant|normal'] = 6,
            ['thruster|normal'] = 4,
            ['stone-wall|normal'] = 40,
            ['pipe|normal'] = 30,
            ['pipe-to-ground|normal'] = 20
        },
        [3] = {
            ['foundry|normal'] = 10,
            ['assembling-machine-3|normal'] = 20,
            ['roboport|normal'] = 20,
            ['construction-robot|normal'] = 200,
            ['logistic-robot|normal'] = 200,
            ['gun-turret|normal'] = 50,
            ['steam-turbine|normal'] = 40,
            ['oil-refinery|normal'] = 10,
            ['pumpjack|normal'] = 20,
            ['solar-panel|normal'] = 50,
        },
        [4] = {
            ['tank|normal'] = 2,
            ['energy-shield-equipment|normal'] = 16,
            ['battery-mk2-equipment|normal'] = 8,
            ['uranium-238|normal'] = 100,
            ['piercing-rounds-magazine|normal'] = 200,
        },
        [5] = {
            ['foundry|normal'] = 10,
            ['uranium-238|normal'] = 100,
            ['roboport|normal'] = 20,
            ['assembling-machine-3|normal'] = 20,
            ['requester-chest|normal'] = 25,
            ['passive-provider-chest|normal'] = 25,
        },
        [6] = {
            ['foundry|normal'] = 10,
            ['uranium-238|normal'] = 100,
            ['fast-inserter|normal'] = 50,
            ['recycler|normal'] = 10,
            ['beacon|normal'] = 20,
            ['speed-module-2|normal'] = 50,
            ['piercing-rounds-magazine|normal'] = 200,
        },
        [7] = {
            ['assembling-machine-3|normal'] = 20,
            ['electromagnetic-plant|normal'] = 10,
            ['quality-module-2|normal'] = 50,
            ['chemical-plant|normal'] = 40,
        },
        [8] ={
            ['foundry|uncommon'] = 10,
            ['roboport|normal'] = 20,
            ['stack-inserter|normal'] = 50,
            ['big-mining-drill|normal'] = 20,
            ['piercing-rounds-magazine|normal'] = 200,
        },
        [9] = {
            ['railgun|normal'] = 4,
            ['railgun-ammo|normal'] = 20,
            ['mech-armor|normal'] = 2,
            ['assembling-machine-3|normal'] = 20,
            ['electromagnetic-plant|normal'] = 10,
        },
        [10] = {
            ['cryogenic-plant|normal'] = 10,
            ['foundry|rare'] = 10,
            ['railgun-ammo|normal'] = 20,
            ['steam-turbine|normal'] = 40,
            ['spidertron|normal'] = 1,
            ['piercing-rounds-magazine|normal'] = 200,
        },
        [11] = {
            ['rocket-part|legendary'] = 1
        }
    },
    [7] = { --fulgora production
        [1] = {
            ['space-platform-starter-pack|normal'] = 1
        },
        [2] = {
            ['space-platform-foundation|normal'] = 100,
            ['asteroid-collector|normal'] = 8,
            ['crusher|normal'] = 4,
            ['cargo-bay|normal'] = 4,
            ['solar-panel|normal'] = 10,
            ['electric-furnace|normal'] = 5,
            ['assembling-machine-3|normal'] = 5,
            ['fast-inserter|normal'] = 50,
            ['inserter|normal'] = 50,
            ['transport-belt|normal'] = 100,
            ['gun-turret|normal'] = 40,
            ['piercing-rounds-magazine|normal'] = 200,
            ['underground-belt|normal'] = 50,
            ['fast-transport-belt|normal'] = 300,
            ['chemical-plant|normal'] = 6,
            ['thruster|normal'] = 4,
            ['stone-wall|normal'] = 40,
            ['pipe|normal'] = 30,
            ['pipe-to-ground|normal'] = 20
        },
        [3] = {
            ['roboport|normal'] = 20,
            ['construction-robot|normal'] = 200,
            ['logistic-robot|normal'] = 200,
            ['recycler|normal'] = 20,
            ['assembling-machine-3|normal'] = 20,
            ['lightning-rod|normal'] = 20,
            ['accumulator|normal'] = 50,
        },
        [4] = {
            ['space-platform-foundation|normal'] = 100,
            ['chemical-plant|normal'] = 30,
            ['beacon|normal'] = 20,
            ['speed-module-2|normal'] = 50,
            ['lightning-rod|normal'] = 20,
            ['accumulator|normal'] = 50,
            ['rail-support|normal'] = 20,
        },
        [5] = {
            ['roboport|normal'] = 20,
            ['construction-robot|normal'] = 200,
            ['logistic-robot|normal'] = 200,
            ['assembling-machine-3|normal'] = 20,
            ['lightning-rod|normal'] = 20,
            ['accumulator|normal'] = 50,
            ['rail-support|normal'] = 20,
            ['electromagnetic-plant|normal'] = 10,
        },
        [6] = {
            ['space-platform-foundation|normal'] = 100,
            ['recycler|normal'] = 20,
            ['big-mining-drill|normal'] = 10,
            ['lightning-collector|normal'] = 20,
            ['accumulator|normal'] = 50,
            ['ice|normal'] = 1000,
            ['stack-inserter|normal'] = 100,
        },
        [7] = {
            ['roboport|normal'] = 20,
            ['construction-robot|normal'] = 200,
            ['logistic-robot|normal'] = 200,
            ['beacon|normal'] = 20,
            ['speed-module-2|normal'] = 50,
            ['lightning-collector|uncommon'] = 20,
            ['accumulator|uncommon'] = 50,
        },
        [8] = {
            ['space-platform-foundation|normal'] = 100,
            ['assembling-machine-3|normal'] = 20,
            ['lightning-collector|uncommon'] = 20,
            ['accumulator|uncommon'] = 50,
            ['electromagnetic-plant|rare'] = 10,
        },
        [9] = {
            ['roboport|normal'] = 20,
            ['construction-robot|normal'] = 200,
            ['logistic-robot|normal'] = 200,
            ['lightning-collector|rare'] = 20,
            ['accumulator|rare'] = 50,
        },
        [10] = {
            ['space-platform-foundation|normal'] = 100,
            ['lightning-collector|rare'] = 20,
            ['accumulator|rare'] = 50,
            ['electromagnetic-plant|epic'] = 10,
        },
        [11] = {
            ['rocket-part|legendary'] = 1
        }
    },
    [8] = { --gleba production
        [1] = {
            ['space-platform-starter-pack|normal'] = 1
        },
        [2] = {
            ['space-platform-foundation|normal'] = 100,
            ['asteroid-collector|normal'] = 8,
            ['crusher|normal'] = 4,
            ['cargo-bay|normal'] = 4,
            ['solar-panel|normal'] = 10,
            ['electric-furnace|normal'] = 5,
            ['assembling-machine-3|normal'] = 5,
            ['fast-inserter|normal'] = 50,
            ['inserter|normal'] = 50,
            ['transport-belt|normal'] = 100,
            ['gun-turret|normal'] = 40,
            ['piercing-rounds-magazine|normal'] = 200,
            ['underground-belt|normal'] = 50,
            ['fast-transport-belt|normal'] = 300,
            ['chemical-plant|normal'] = 6,
            ['thruster|normal'] = 4,
            ['stone-wall|normal'] = 40,
            ['pipe|normal'] = 30,
            ['pipe-to-ground|normal'] = 20
        },
        [3] = {
            ['roboport|normal'] = 20,
            ['construction-robot|normal'] = 200,
            ['logistic-robot|normal'] = 200,
            ['biochamber|normal'] = 10,
            ['nuclear-reactor|normal'] = 4,
            ['heat-exchanger|normal'] = 50,
            ['steam-turbine|normal'] = 80,
            ['storage-tank|normal'] = 20,
            ['uranium-fuel-cell|normal'] = 100,
            ['efficiency-module-2|normal'] = 50,
        },
        [4] = {
            ['rocket|normal'] = 200,
            ['laser-turret|normal'] = 100,
            ['accumulator|normal'] = 200,
            ['electromagnetic-plant|normal'] = 10,
            ['efficiency-module-2|normal'] = 50,
            ['agricultural-tower|normal'] = 20,
            ['electric-furnace|normal'] = 50,
        },
        [5] = {
            ['roboport|normal'] = 20,
            ['construction-robot|normal'] = 200,
            ['logistic-robot|normal'] = 200,
            ['tesla-turret|normal'] = 10,
            ['rocket|normal'] = 200,
            ['laser-turret|normal'] = 100,
            ['heating-tower|normal'] = 20,
        },
        [6] = {
            ['biochamber|normal'] = 10,
            ['spidertron|normal'] = 2,
            ['tesla-turret|normal'] = 10,
            ['rocket|normal'] = 200,
            ['efficiency-module-2|normal'] = 50,
            ['laser-turret|normal'] = 100,
            ['destroyer-capsule|normal'] = 100,
        },
        [7] = {
            ['roboport|normal'] = 20,
            ['construction-robot|normal'] = 200,
            ['logistic-robot|normal'] = 200,
            ['tesla-turret|uncommon'] = 10,
            ['rocket|normal'] = 200,
            ['destroyer-capsule|normal'] = 100,
        },
        [8] = {
            ['biochamber|rare'] = 10,
            ['tesla-turret|rare'] = 10,
            ['artillery-turret|normal'] = 5,
            ['rocket|normal'] = 200,
            ['efficiency-module-2|normal'] = 50,
            ['destroyer-capsule|normal'] = 100,
        },
        [9] = {
            ['roboport|normal'] = 20,
            ['construction-robot|normal'] = 200,
            ['logistic-robot|normal'] = 200,
            ['tesla-turret|rare'] = 10,
            ['railgun|normal'] = 2,
            ['mech-armor|normal'] = 2,
        },
        [10] = {
            ['biochamber|epic'] = 10,
            ['tesla-turret|epic'] = 10,
            ['efficiency-module-2|normal'] = 50,
            ['fusion-reactor|normal'] = 1,
            ['fusion-generator|normal'] = 2,
            ['fluoroketone-cold-barrel|normal'] = 100,
            ['fusion-power-cell|normal'] = 100,
        },
        [11] = {
            ['rocket-part|legendary'] = 1
        }
    },
    [9] = { --aquilo production
        [1] = {
            ['space-platform-starter-pack|normal'] = 1
        },
        [2] = {
            ['space-platform-foundation|normal'] = 100,
            ['asteroid-collector|normal'] = 8,
            ['crusher|normal'] = 4,
            ['cargo-bay|normal'] = 4,
            ['solar-panel|normal'] = 10,
            ['electric-furnace|normal'] = 5,
            ['assembling-machine-3|normal'] = 5,
            ['fast-inserter|normal'] = 50,
            ['inserter|normal'] = 50,
            ['transport-belt|normal'] = 100,
            ['gun-turret|normal'] = 40,
            ['piercing-rounds-magazine|normal'] = 200,
            ['underground-belt|normal'] = 50,
            ['fast-transport-belt|normal'] = 300,
            ['chemical-plant|normal'] = 6,
            ['thruster|normal'] = 4,
            ['stone-wall|normal'] = 40,
            ['pipe|normal'] = 30,
            ['pipe-to-ground|normal'] = 20
        },
        [3] = {
            ['chemical-plant|normal'] = 30,
            ['concrete|normal'] = 1000,
            ['nuclear-reactor|normal'] = 4,
            ['heat-exchanger|normal'] = 50,
            ['heat-pipe|normal'] = 100,
            ['steam-turbine|normal'] = 80,
            ['storage-tank|normal'] = 20,
            ['uranium-fuel-cell|normal'] = 100,
            ['processing-unit|normal'] = 300,
            ['low-density-structure|normal'] = 200,
            ['rocket-fuel|normal'] = 100,
            ['heating-tower|normal'] = 20,
            ['solar-panel|uncommon'] = 50,
        },
        [4] = {
            ['roboport|normal'] = 20,
            ['construction-robot|normal'] = 200,
            ['logistic-robot|normal'] = 200,
            ['concrete|normal'] = 1000,
            ['heat-pipe|normal'] = 100,
            ['processing-unit|normal'] = 300,
            ['low-density-structure|normal'] = 200,
            ['carbon-fiber|normal'] = 1000,
            ['superconductor|normal'] = 1000,
            ['tungsten-carbide|normal'] = 1000,
            ['refined-concrete|normal'] = 1000,

        },
        [5] = {
            ['concrete|normal'] = 1000,
            ['heat-pipe|normal'] = 100,
            ['processing-unit|normal'] = 300,
            ['low-density-structure|normal'] = 200,
            ['holmium-plate|normal'] = 1000,
            ['refined-concrete|normal'] = 1000,
            ['heating-tower|normal'] = 20,
            ['speed-module-3|normal'] = 50,
            ['productivity-module-3|normal'] = 50,
        },
        [6] = {
            ['roboport|normal'] = 20,
            ['construction-robot|normal'] = 200,
            ['logistic-robot|normal'] = 200,
            ['concrete|normal'] = 1000,
            ['heat-pipe|normal'] = 100,
            ['processing-unit|normal'] = 300,
            ['low-density-structure|normal'] = 200,
            ['holmium-plate|normal'] = 1000,
            ['speed-module-3|normal'] = 50,
            ['productivity-module-3|normal'] = 50,
        },
        [7] = {
            ['concrete|normal'] = 1000,
            ['heat-pipe|normal'] = 100,
            ['processing-unit|normal'] = 300,
            ['low-density-structure|normal'] = 200,
            ['carbon-fiber|normal'] = 1000,
            ['superconductor|normal'] = 1000,
            ['tungsten-carbide|normal'] = 1000,
            ['tungsten-plate|normal'] = 1000,
            ['heating-tower|normal'] = 20,
        },
        [8] = {
            ['roboport|normal'] = 20,
            ['construction-robot|normal'] = 200,
            ['logistic-robot|normal'] = 200,
            ['concrete|normal'] = 1000,
            ['processing-unit|normal'] = 300,
            ['low-density-structure|normal'] = 200,
            ['holmium-plate|normal'] = 1000,
            ['tungsten-plate|normal'] = 1000,
            ['refined-concrete|normal'] = 1000,
            ['speed-module-3|rare'] = 50,
            ['productivity-module-3|rare'] = 50,
        },
        [9] = {
            ['heat-pipe|normal'] = 100,
            ['processing-unit|normal'] = 300,
            ['low-density-structure|normal'] = 200,
            ['carbon-fiber|normal'] = 1000,
            ['superconductor|normal'] = 1000,
            ['tungsten-carbide|normal'] = 1000,
            ['tungsten-plate|normal'] = 1000,
            ['heating-tower|normal'] = 20,
            ['fusion-reactor|normal'] = 1,
            ['fusion-generator|normal'] = 2,
            ['fluoroketone-cold-barrel|normal'] = 100,
            ['fusion-power-cell|normal'] = 100,
        },
        [10] = {
            ['roboport|normal'] = 20,
            ['construction-robot|normal'] = 200,
            ['logistic-robot|normal'] = 200,
            ['concrete|normal'] = 1000,
            ['heat-pipe|normal'] = 100,
            ['processing-unit|normal'] = 300,
            ['low-density-structure|normal'] = 200,
            ['heating-tower|normal'] = 20,
        },
        [11] = {
            ['rocket-part|legendary'] = 1
        }
    },
    [10] = {
        [1] = {
            ['space-platform-starter-pack|normal'] = 1
        },
        [2] = {
            ['space-platform-foundation|normal'] = 10000,
            ['asteroid-collector|normal'] = 32,
            ['crusher|normal'] = 20,
            ['cargo-bay|rare'] = 10,
            ['solar-panel|rare'] = 100,
            ['electric-furnace|rare'] = 50,
            ['assembling-machine-3|rare'] = 20,
            ['fast-inserter|normal'] = 300,
            ['inserter|normal'] = 200,
            ['transport-belt|normal'] = 1000,
            ['gun-turret|normal'] = 400,
            ['piercing-rounds-magazine|normal'] = 500,
            ['underground-belt|normal'] = 200,
            ['fast-transport-belt|normal'] = 800,
            ['chemical-plant|normal'] = 30,
            ['thruster|normal'] = 16,
            ['stone-wall|normal'] = 400,
            ['pipe|normal'] = 300,
            ['pipe-to-ground|normal'] = 200,
            ['nuclear-reactor|normal'] = 2,
            ['heat-exchanger|normal'] = 12,
            ['steam-turbine|normal'] = 20,
            ['rocket-turret|normal'] = 20,
            ['rocket|normal'] = 200,
            ['railgun-turret|normal'] = 5,
            ['railgun-ammo|normal'] = 50,
        },
        [3] = {
            ['storage-tank|normal'] = 10,
            ['space-platform-foundation|normal'] = 1000,
            ['asteroid-collector|uncommon'] = 10,
            ['crusher|uncommon'] = 6,
            ['piercing-rounds-magazine|normal'] = 200,
            ['railgun-turret|normal'] = 5,
            ['stack-inserter|normal'] = 50,
        },
        [4] = {
            ['turbo-underground-belt|normal'] = 100,
            ['piercing-rounds-magazine|normal'] = 200,
            ['railgun-turret|normal'] = 5,
            ['rocket-turret|normal'] = 20,
            ['rocket|normal'] = 200,
            ['fusion-reactor|normal'] = 1,
            ['fusion-generator|normal'] = 2,
            ['fluoroketone-cold-barrel|normal'] = 100,
            ['fusion-power-cell|normal'] = 100,
        },
        [5] = {
            ['space-platform-foundation|normal'] = 500,
            ['speed-module-3|rare'] = 50,
            ['efficiency-module-3|rare'] = 50,
            ['railgun-turret|normal'] = 5,
            ['railgun-ammo|normal'] = 100,
            ['cargo-bay|epic'] = 10,
        },
        [6] = {
            ['turbo-underground-belt|normal'] = 100,
            ['crusher|rare'] = 6,
            ['asteroid-collector|rare'] = 10,
            ['cargo-bay|epic'] = 10,
            ['foundry|rare'] = 10,
            ['electromagnetic-plant|rare'] = 10,

        },
        [7] = {
            ['space-platform-foundation|normal'] = 500,
            ['fusion-reactor|rare'] = 1,
            ['fusion-generator|rare'] = 2,
            ['fluoroketone-cold-barrel|normal'] = 100,
            ['fusion-power-cell|normal'] = 100,
            ['railgun-turret|normal'] = 5,
            ['railgun-ammo|normal'] = 100,
            ['cargo-bay|legendary'] = 10,
        },
        [8] = {
            ['space-platform-foundation|normal'] = 500,
            ['cargo-bay|legendary'] = 10,
            ['foundry|epic'] = 10,
            ['electromagnetic-plant|epic'] = 10,
            ['cryogenic-plant|epic'] = 8,
            ['chemical-plant|epic'] = 20,
            ['speed-module-3|epic'] = 50,
            ['efficiency-module-3|epic'] = 50,
            ['productivity-module-3|epic'] = 50,
            ['gun-turret|epic'] = 50,
            ['rocket-turret|epic'] = 20,
            ['rocket|normal'] = 200,
        },
        [9] = {
            ['space-platform-foundation|normal'] = 500,
            ['railgun-turret|rare'] = 5,
            ['railgun-ammo|normal'] = 100,
            ['cargo-bay|legendary'] = 10,
            ['foundry|legendary'] = 10,
            ['electromagnetic-plant|legendary'] = 10,
            ['beacon|epic'] = 20,
            ['quantum-processor|normal'] = 600
        },
        [10] = {
            ['fusion-reactor|legendary'] = 1,
            ['fusion-generator|legendary'] = 2,
            ['fluoroketone-cold-barrel|normal'] = 100,
            ['fusion-power-cell|normal'] = 100,
            ['railgun-turret|legendary'] = 5,
            ['railgun-ammo|normal'] = 100,
        },
        [11] = {

        },
        [12] = {
            ['rocket-part|legendary'] = 1
        }
    }

}

Public.rewards = {
    [4] = { --space science production and basic nauvis-orbit resources
        [1] = {
            ['research'] = {
                ['space-platform'] = 1
            },
            ['script'] = {
                ['new-ship'] = 'Atlas'
            }
        },
        [2] = {
            ['research'] = {
                ['space-science-pack'] = 1
            },
            ['production'] = {
                ['metallic-asteroid-chunk|normal'] = 1,
                ['carbonic-asteroid-chunk|normal'] = 1,
                ['oxide-asteroid-chunk|normal'] = 1,
            },
            ['once'] = {
                ['space-science-pack|normal'] = 200,
            }
        },
        [3] = {
            ['production'] = {
                ['metallic-asteroid-chunk|normal'] = 1,
                ['carbonic-asteroid-chunk|normal'] = 1,
                ['oxide-asteroid-chunk|normal'] = 1,
            }
        },
        [4] = {
            ['production'] = {
                ['metallic-asteroid-chunk|normal'] = 2,
                ['carbonic-asteroid-chunk|normal'] = 2,
                ['oxide-asteroid-chunk|normal'] = 2,
            }
        },
        [5] = {
            ['production'] = {
                ['metallic-asteroid-chunk|normal'] = 2,
                ['carbonic-asteroid-chunk|normal'] = 2,
                ['oxide-asteroid-chunk|normal'] = 2,
            }
        },
        [6] = {
            ['production'] = {
                ['metallic-asteroid-chunk|normal'] = 3,
                ['carbonic-asteroid-chunk|normal'] = 3,
                ['oxide-asteroid-chunk|normal'] = 3,
            }
        },
        [7] = {
            ['production'] = {
                ['metallic-asteroid-chunk|normal'] = 6,
                ['carbonic-asteroid-chunk|normal'] = 6,
                ['oxide-asteroid-chunk|normal'] = 6,
            }
        },
        [8] = {
            ['script'] = {
                ['all-done'] = true
            }
        },

    },
    [5] = {
        [1] = {
            ['script'] = {
                ['new-ship'] = 'Odysseus'
            }
        },
        [2] = {
            ['research'] = {
                ['planet-discovery-vulcanus'] = 0.05
            }
        },
        [3] = {
            ['research'] = {
                ['planet-discovery-vulcanus'] = 0.95,
                ['planet-discovery-gleba'] = 0.1,
                ['planet-discovery-fulgora'] = 0.1,
            }
        },
        [4] = {
            ['research'] = {
                ['calcite-processing'] = 1,
                ['tungsten-carbide'] = 1
            },
            ['production'] = {
                ['tungsten-ore|normal'] = 5,
                ['calcite|normal'] = 5
            },
            ['once'] = {
                ['tungsten-ore|normal'] = 50,
                ['calcite|normal'] = 50
            }
        },
        [5] = {
            ['research'] = {
                ['planet-discovery-fulgora'] = 0.9,
            }
        },
        [6] = {
            ['research'] = {
                ['recycling'] = 1
            },
            ['production'] = {
                ['scrap|normal'] = 100
            },
            ['once'] = {
                ['scrap|normal'] = 2000,
                ['holmium-ore|normal'] = 50,
            }
        },
        [7] = {
            ['research'] = {
                ['planet-discovery-gleba'] = 0.9,
            }
        },
        [8] = {
            ['research'] = {
                ['agriculture'] = 1,
            },
            ['production'] = {
                ['spoilage|normal'] = 100
            },
            ['once'] = {
                ['spoilage|normal'] = 1000
            }

        },
        [9] = {
            ['research'] = {
                ['jellynut'] = 1,
                ['yumako'] = 1
            },
            ['production'] = {
                ['yumako|normal'] = 4,
                ['jellynut|normal'] = 4,
                ['pentapod-egg|normal'] = 1,
            }
        },
        [10] = {
            ['research'] = {
                ['planet-discovery-aquilo'] = 0.1
            }
        },
        [11] = {
            ['research'] = {
                ['planet-discovery-aquilo'] = 0.9
            }
        },
        [12] = {
            ['research'] = {
                ['lithium-processing'] = 1,
            },
            ['production'] = {
                ['lithium|normal'] = 5
            },
            ['once'] = {
                ['fluoroketone-hot-barrel|normal'] = 200
            }
        },
        [13] = {
            ['production'] = {
                ['promethium-asteroid-chunk|normal'] = 5
            },
            ['once'] = {
                ['promethium-asteroid-chunk|normal'] = 500
            }
        },
        [14] = {
            ['script'] = {
                ['all-done'] = true
            }
        }
    },
    [6] = {
        [1] = {
            ['script'] = {
                ['new-ship'] = 'Hephaestus'
            }
        },
        [2] = {
            ['production'] = {
                ['calcite|normal'] = 10,
                ['tungsten-ore|normal'] = 20,

            }
        },
        [3] = {
            ['production'] = {
                ['calcite|normal'] = 10,
                ['tungsten-ore|normal'] = 20,
                ['coal|normal'] = 20,
                ['sulfur|normal'] = 20,
            }
        },
        [4] = {
            ['production'] = {
                ['calcite|normal'] = 10,
                ['tungsten-ore|normal'] = 20,

            },
            ['once'] = {
                ['tungsten-ore|normal'] = 2500,
            }
        },
        [5] = {
            ['production'] = {
                ['calcite|normal'] = 10,
                ['tungsten-ore|normal'] = 20,

            }
        },
        [6] = {
            ['production'] = {
                ['calcite|normal'] = 10,
                ['tungsten-ore|normal'] = 20,

            }
        },
        [7] = {
            ['production'] = {
                ['calcite|normal'] = 10,
                ['tungsten-ore|normal'] = 20,

            }
        },
        [8] = {
            ['production'] = {
                ['calcite|normal'] = 10,
                ['tungsten-ore|normal'] = 20,

            }
        },
        [9] = {
            ['production'] = {
                ['calcite|normal'] = 10,
                ['tungsten-ore|normal'] = 20,

            }
        },
        [10] = {
            ['production'] = {
                ['calcite|normal'] = 10,
                ['tungsten-ore|normal'] = 20,

            }
        },
        [11] = {
            ['script'] = {
                ['all-done'] = true
            }
        }
    },
    [7] = {
        [1] = {
            ['script'] = {
                ['new-ship'] = 'Zeus'
            }
        },
        [2] = {
            ['production'] = {
                ['scrap|normal'] = 50,
            }
        },
        [3] = {
            ['production'] = {
                ['scrap|normal'] = 50,
            }
        },
        [4] = {
            ['production'] = {
                ['scrap|normal'] = 75,
            }
        },
        [5] = {
            ['production'] = {
                ['scrap|normal'] = 75,
            }
        },
        [6] = {
            ['production'] = {
                ['scrap|normal'] = 100,
            }
        },
        [7] = {
            ['production'] = {
                ['scrap|normal'] = 100,
            }
        },
        [8] = {
            ['production'] = {
                ['scrap|normal'] = 100,
            }
        },
        [9] = {
            ['production'] = {
                ['scrap|normal'] = 100,
            }
        },
        [10] = {
            ['production'] = {
                ['scrap|normal'] = 100,
            }
        },
        [11] = {
            ['script'] = {
                ['all-done'] = true
            }
        }
    },
    [8] = {
        [1] = {
            ['script'] = {
                ['new-ship'] = 'Gaia'
            }
        },
        [2] = {
            ['production'] = {
                ['spoilage|normal'] = 100,
                ['yumako|normal'] = 2,
                ['jellynut|normal'] = 2,
                ['pentapod-egg|normal'] = 1,
            }
        },
        [3] = {
            ['production'] = {
                ['spoilage|normal'] = 100,
                ['yumako|normal'] = 2,
                ['jellynut|normal'] = 2,
                ['pentapod-egg|normal'] = 1,
            }
        },
        [4] = {
            ['production'] = {
                ['spoilage|normal'] = 100,
                ['yumako|normal'] = 2,
                ['jellynut|normal'] = 2,
                ['pentapod-egg|normal'] = 1,
            }
        },
        [5] = {
            ['production'] = {
                ['spoilage|normal'] = 100,
                ['yumako|normal'] = 2,
                ['jellynut|normal'] = 2,
                ['pentapod-egg|normal'] = 1,
            }
        },
        [6] = {
            ['production'] = {
                ['spoilage|normal'] = 100,
                ['yumako|normal'] = 2,
                ['jellynut|normal'] = 2,
                ['pentapod-egg|normal'] = 1,
            }
        },
        [7] = {
            ['production'] = {
                ['spoilage|normal'] = 100,
                ['yumako|normal'] = 2,
                ['jellynut|normal'] = 2,
                ['pentapod-egg|normal'] = 1,
            }
        },
        [8] = {
            ['production'] = {
                ['spoilage|normal'] = 100,
                ['yumako|normal'] = 2,
                ['jellynut|normal'] = 2,
                ['pentapod-egg|normal'] = 1,
            }
        },
        [9] = {
            ['production'] = {
                ['spoilage|normal'] = 100,
                ['yumako|normal'] = 2,
                ['jellynut|normal'] = 2,
                ['pentapod-egg|normal'] = 1,
            }
        },
        [10] = {
            ['production'] = {
                ['spoilage|normal'] = 100,
                ['yumako|normal'] = 2,
                ['jellynut|normal'] = 2,
                ['pentapod-egg|normal'] = 1,
            }
        },
        [11] = {
            ['script'] = {
                ['all-done'] = true
            }
        }
    },
    [9] = {
        [1] = {
            ['script'] = {
                ['new-ship'] = 'Chione'
            }
        },
        [2] = {
            ['production'] = {
                ['lithium|normal'] = 5,
                ['fluoroketone-hot-barrel|normal'] = 1
            }
        },
        [3] = {
            ['production'] = {
                ['lithium|normal'] = 5,
                ['fluoroketone-hot-barrel|normal'] = 1
            }
        },
        [4] = {
            ['production'] = {
                ['lithium|normal'] = 5,
                ['fluoroketone-hot-barrel|normal'] = 1
            }
        },
        [5] = {
            ['production'] = {
                ['lithium|normal'] = 5,
                ['fluoroketone-hot-barrel|normal'] = 1
            }
        },
        [6] = {
            ['production'] = {
                ['lithium|normal'] = 5,
                ['fluoroketone-hot-barrel|normal'] = 1
            }
        },
        [7] = {
            ['production'] = {
                ['lithium|normal'] = 5,
                ['fluoroketone-hot-barrel|normal'] = 1
            }
        },
        [8] = {
            ['production'] = {
                ['lithium|normal'] = 5,
                ['fluoroketone-hot-barrel|normal'] = 1
            }
        },
        [9] = {
            ['production'] = {
                ['lithium|normal'] = 5,
                ['fluoroketone-hot-barrel|normal'] = 1
            }
        },
        [10] = {
            ['production'] = {
                ['lithium|normal'] = 5,
                ['fluoroketone-hot-barrel|normal'] = 1
            }
        },
        [11] = {
            ['script'] = {
                ['all-done'] = true
            }
        }
    },
    [10] = {
        [1] = {
            ['script'] = {
                ['new-ship'] = 'Galactica'
            }
        },
        [2] = {
            ['production'] = {
                ['promethium-asteroid-chunk|normal'] = 25
            }
        },
        [3] = {
            ['production'] = {
                ['promethium-asteroid-chunk|normal'] = 25
            }
        },
        [4] = {
            ['production'] = {
                ['promethium-asteroid-chunk|normal'] = 25
            }
        },
        [5] = {
            ['production'] = {
                ['promethium-asteroid-chunk|normal'] = 25
            }
        },
        [6] = {
            ['production'] = {
                ['promethium-asteroid-chunk|normal'] = 25
            }
        },
        [7] = {
            ['production'] = {
                ['promethium-asteroid-chunk|normal'] = 25
            }
        },
        [8] = {
            ['production'] = {
                ['promethium-asteroid-chunk|normal'] = 25
            }
        },
        [9] = {
            ['production'] = {
                ['promethium-asteroid-chunk|normal'] = 25
            }
        },
        [10] = {
            ['production'] = {
                ['promethium-asteroid-chunk|normal'] = 25
            }
        },
        [11] = {
            ['script'] = {
                ['victory'] = true
            }
        },
        [12] = {
            ['script'] = {
                ['all-done'] = true
            }
        }
    },
}

Public.nonspace_costs = {
    [4] = {
        [1] = {
            ['satellite|normal'] = 1
        },
        [2] = {
            ['satellite|normal'] = 10
        },
        [3] = {
            ['satellite|normal'] = 20
        },
        [4] = {
            ['satellite|normal'] = 30
        },
        [5] = {
            ['satellite|normal'] = 40
        },
        [6] = {
            ['satellite|normal'] = 50
        },
        [7] = {
            ['satellite|normal'] = 60
        },
        [8] = {
            ['satellite|normal'] = 70
        },
        [9] = {
            ['satellite|normal'] = 80
        },
        [10] = {
            ['satellite|normal'] = 90
        },
        [11] = {
            ['satellite|normal'] = 100
        },
        [12] = {
            ['rocket-part|normal'] = 1
        }
    },
    [5] = {
        [1] = {
            ['satellite|normal'] = 1000
        },
        [2] = {
            ['rocket-part|normal'] = 1
        }
    }
}

Public.nonspace_rewards = {
    [4] = {
        [1] = {
            ['research'] = {
                ['space-science-pack'] = 1
            },
            ['once'] = {
                ['space-science-pack|normal'] = 1000
            }
        },
        [2] = {
            ['production'] = {
                ['space-science-pack|normal'] = 20,
                ['iron-ore|normal'] = 10,
                ['copper-ore|normal'] = 10,
                ['coal|normal'] = 5,
                ['stone|normal'] = 5,
                ['uranium-ore|normal'] = 5
            },
            ['once'] = {
                ['space-science-pack|normal'] = 1200
            }
        },
        [3] = {
            ['production'] = {
                ['space-science-pack|normal'] = 20,
                ['iron-ore|normal'] = 10,
                ['copper-ore|normal'] = 10,
                ['coal|normal'] = 5,
                ['stone|normal'] = 5,
                ['uranium-ore|normal'] = 5
            },
            ['once'] = {
                ['space-science-pack|normal'] = 1400
            }
        },
        [4] = {
            ['production'] = {
                ['space-science-pack|normal'] = 20,
                ['iron-ore|normal'] = 10,
                ['copper-ore|normal'] = 10,
                ['coal|normal'] = 5,
                ['stone|normal'] = 5,
                ['uranium-ore|normal'] = 5
            },
            ['once'] = {
                ['space-science-pack|normal'] = 1600
            }
        },
        [5] = {
            ['production'] = {
                ['space-science-pack|normal'] = 20,
                ['iron-ore|normal'] = 10,
                ['copper-ore|normal'] = 10,
                ['coal|normal'] = 5,
                ['stone|normal'] = 5,
                ['uranium-ore|normal'] = 5
            },
            ['once'] = {
                ['space-science-pack|normal'] = 1800
            }
        },
        [6] = {
            ['production'] = {
                ['space-science-pack|normal'] = 20,
                ['iron-ore|normal'] = 10,
                ['copper-ore|normal'] = 10,
                ['coal|normal'] = 5,
                ['stone|normal'] = 5,
                ['uranium-ore|normal'] = 5
            },
            ['once'] = {
                ['space-science-pack|normal'] = 2000
            }
        },
        [7] = {
            ['production'] = {
                ['space-science-pack|normal'] = 20,
                ['iron-ore|normal'] = 10,
                ['copper-ore|normal'] = 10,
                ['coal|normal'] = 5,
                ['stone|normal'] = 5,
                ['uranium-ore|normal'] = 5
            },
            ['once'] = {
                ['space-science-pack|normal'] = 2200
            }
        },
        [8] = {
            ['production'] = {
                ['space-science-pack|normal'] = 20,
                ['iron-ore|normal'] = 10,
                ['copper-ore|normal'] = 10,
                ['coal|normal'] = 5,
                ['stone|normal'] = 5,
                ['uranium-ore|normal'] = 5
            },
            ['once'] = {
                ['space-science-pack|normal'] = 2400
            }
        },
        [9] = {
            ['production'] = {
                ['space-science-pack|normal'] = 20,
                ['iron-ore|normal'] = 10,
                ['copper-ore|normal'] = 10,
                ['coal|normal'] = 5,
                ['stone|normal'] = 5,
                ['uranium-ore|normal'] = 5
            },
            ['once'] = {
                ['space-science-pack|normal'] = 2600
            }
        },
        [10] = {
            ['production'] = {
                ['space-science-pack|normal'] = 20,
                ['iron-ore|normal'] = 10,
                ['copper-ore|normal'] = 10,
                ['coal|normal'] = 5,
                ['stone|normal'] = 5,
                ['uranium-ore|normal'] = 5
            },
            ['once'] = {
                ['space-science-pack|normal'] = 2800
            }
        },
        [11] = {
            ['production'] = {
                ['space-science-pack|normal'] = 20,
                ['iron-ore|normal'] = 10,
                ['copper-ore|normal'] = 10,
                ['coal|normal'] = 5,
                ['stone|normal'] = 5,
                ['uranium-ore|normal'] = 5,
            },
            ['once'] = {
                ['space-science-pack|normal'] = 3000
            }
        },
        [12] = {
            ['script'] = {
                ['all-done'] = true
            }
        }
    },
    [5] = {
        [1] = {
            ['script'] = {
                ['victory'] = true
            }
        },
        [2] = {
            ['script'] = {
                ['all-done'] = true
            }
        }
    }
}

return Public