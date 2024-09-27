-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Math = require("maps.pirates.math")
-- local Memory = require 'maps.pirates.memory'
local Balance = require("maps.pirates.balance")
-- local CoreData = require 'maps.pirates.coredata'
local Common = require("maps.pirates.common")
local _inspect = require("utils.inspect").inspect

local Public = {}

Public.buried_treasure_loot_data_raw = {
    { 100, 0, 1, false, "coin", 1, 600 },
    { 50, 0, 1, false, "steel-plate", 100, 150 },
    { 50, 0, 1, false, "defender-capsule", 5, 18 },
    { 25, 0, 1, false, "distractor-capsule", 5, 18 },
    { 10, 0, 1, false, "destroyer-capsule", 3, 8 },
    -- {20, 0, 1, false, 'flying-robot-frame', 20, 35},
    { 40, 0, 1, false, "construction-robot", 15, 25 },
    -- {100, 0, 1, false, 'electronic-circuit', 150, 250},
    { 70, 0, 1, false, "advanced-circuit", 20, 40 },
    { 150, 0, 1, false, "crude-oil-barrel", 25, 45 },
    { 70, 0, 1, false, "efficiency-module-3", 3, 4 },
    { 70, 0, 1, false, "speed-module-3", 3, 4 },
    { 70, 0, 1, false, "plastic-bar", 40, 70 },
    { 60, 0, 1, false, "chemical-science-pack", 12, 24 },
    { 70, 0, 1, false, "assembling-machine-3", 2, 2 },
    { 65, 0, 1, false, "solar-panel", 7, 8 },
    { 20, 0, 1, false, "radar", 10, 20 },
    { 10, 0, 1, false, "production-science-pack", 12, 24 },
    { 10, 0, 1, false, "utility-science-pack", 4, 4 },
    { 5, 0, 1, false, "modular-armor", 1, 1 },
    { 5, 0, 1, false, "laser-turret", 2, 3 },
    { 5, 0, 1, false, "cannon-shell", 5, 10 },
    { 50, 0, 1, false, "artillery-shell", 4, 8 },
    { 50, 0, 1, false, "express-transport-belt", 8, 20 },
    { 35, 0, 1, false, "express-underground-belt", 4, 4 },
    { 35, 0, 1, false, "express-splitter", 4, 11 },
    { 50, 0, 1, false, "bulk-inserter", 4, 12 },
    { 0.1, 0, 1, false, "atomic-bomb", 1, 1 },
    { 1, 0, 1, false, "nuclear-reactor", 1, 1 },
}

Public.chest_loot_data_raw = {
    { 80, 0, 1, false, "coin", 400, 700 },
    { 10, 0, 1, false, "rail-signal", 50, 50 },
    { 1, 0.2, 1, false, "electric-engine-unit", 1, 2 },
    { 3, 0, 1, false, "small-lamp", 4, 16 },
    { 10, 0, 1, false, "coal", 60, 100 },
    { 12, 0, 1, false, "artillery-shell", 1, 1 },
    { 4, 0, 0.8, false, "pistol", 1, 3 },
    { 3, 0, 0.2, false, "storage-tank", 2, 4 },
    { 2, 0.1, 1, false, "explosives", 5, 9 },
    { 2, 0.2, 1, false, "cliff-explosives", 2, 4 },
    { 0.25, 0, 0.5, false, "uranium-238", 5, 8 },

    { 8, 0, 1.2, true, "steel-chest", 4, 12 },
    { 2, 0, 0.8, false, "barrel", 1, 10 },

    { 5, -0.2, 0.8, true, "iron-gear-wheel", 20, 80 },
    { 5, -0.2, 0.8, true, "copper-cable", 30, 100 },
    -- {5, -0.2, 0.8, true, 'electronic-circuit', 15, 60},
    { 2, 0.3, 1, true, "rocket-fuel", 1, 5 },
    { 1, 0.2, 1.2, true, "battery", 10, 30 },
    { 4, 0.2, 1.4, true, "advanced-circuit", 10, 40 },

    { 8, -0.3, 0.3, true, "small-electric-pole", 16, 30 },
    { 20, 0, 1, false, "medium-electric-pole", 2, 10 },
    { 3, 0.2, 1.4, true, "big-electric-pole", 4, 8 },
    { 1, 0.2, 1.8, true, "substation", 1, 3 },
    { 5, 0, 1.2, true, "accumulator", 1, 4 },
    { 10, 0, 1, false, "solar-panel", 2, 3 },

    { 15, -0.6, 0.6, true, "transport-belt", 20, 60 },
    { 10, 0, 1, false, "fast-transport-belt", 8, 40 },
    { 3, 0.2, 1.8, true, "express-transport-belt", 5, 12 },
    { 12, -1, 0.5, true, "splitter", 4, 10 },
    { 8, 0, 1, false, "fast-splitter", 2, 5 },
    { 5, 0, 2, true, "express-splitter", 1, 3 },
    { 5, -1, 0.5, true, "underground-belt", 6, 6 },
    { 2, 0, 1, false, "fast-underground-belt", 6, 6 },
    { 3, 0, 2, true, "express-underground-belt", 4, 4 },

    { 0.5, 0, 1, false, "loader", 1, 1 },
    { 0.5, 0.2, 1, false, "fast-loader", 1, 1 },
    { 0.5, 0.7, 1, false, "express-loader", 1, 1 },

    { 4, -0.3, 0.3, true, "inserter", 8, 20 },
    { 4, 0, 1, true, "fast-inserter", 2, 12 },
    { 3, 0, 1, false, "long-handed-inserter", 4, 16 },
    { 3, 0, 0.5, false, "bulk-inserter", 1, 4 },
    { 3, 0.5, 1, false, "bulk-inserter", 5, 8 },

    { 40, -0.5, 0.5, true, "firearm-magazine", 10, 32 },
    { 60, -1, 1, true, "piercing-rounds-magazine", 8, 16 },
    { 10, 0, 1, false, "uranium-rounds-magazine", 3, 7 },

    { 2, -0.3, 0.5, true, "assembling-machine-1", 2, 4 },
    { 10, 0, 0.9, false, "assembling-machine-2", 1, 3 },
    { 2, 0, 1, false, "electric-mining-drill", 2, 4 },
    { 3, 0.25, 1.75, true, "assembling-machine-3", 2, 4 },
    { 5, 0, 1, true, "steel-furnace", 4, 8 },
    { 4, 0, 2, true, "electric-furnace", 1, 3 },
    { 3, 0.2, 1, true, "chemical-plant", 1, 3 },
    { 0.2, 0.3, 1, false, "heat-exchanger", 1, 3 },
    { 0.1, 0.3, 1, false, "nuclear-reactor", 1, 1 },
    { 0.2, 0.2, 2, true, "concrete", 10, 40 },

    { 15, -1, 1, true, "speed-module", 1, 3 },
    { 5, 0, 1.5, true, "speed-module-2", 1, 2 },
    { 2, 0, 2, true, "speed-module-3", 1, 1 },
    { 5, -1, 1, true, "efficiency-module", 1, 3 },
    { 3, 0, 1, true, "efficiency-module-2", 1, 3 },
    { 1, 0, 2, true, "efficiency-module-3", 1, 1 },

    { 0.2, 0.2, 2, true, "car", 1, 1 },
    { 0.01, 0.2, 2, true, "tank", 1, 1 },
    { 4, 0, 0.1, false, "light-armor", 1, 1 },
    { 2, 0, 0.5, true, "heavy-armor", 1, 1 },
    { 2, 0, 0.1, false, "submachine-gun", 1, 1 },
    { 1, 0, 1, false, "gun-turret", 2, 4 },
    { 6, 0, 1, false, "grenade", 2, 12 },
    { 4, 0, 1, false, "stone-wall", 12, 50 },
    { 2, 0, 2, true, "rocket-launcher", 1, 1 },
    { 4, 0, 2, true, "rocket", 4, 10 },
    { 5, 0.2, 1.8, true, "explosive-rocket", 2, 8 },
    { 0.2, 0, 1, false, "poison-capsule", 2, 5 },
    { 0.2, 0, 1, false, "slowdown-capsule", 2, 5 },
    { 0.2, 0, 1, false, "defender-capsule", 2, 4 },
    { 0.15, 0, 1, false, "distractor-capsule", 2, 4 },
    { 0.1, 0, 1, false, "destroyer-capsule", 2, 2 },
    { 10, 0.2, 1.2, true, "piercing-shotgun-shell", 6, 9 },
    { 2, 0.3, 1.2, true, "combat-shotgun", 1, 1 },
    { 5, 0.2, 1.8, true, "cluster-grenade", 8, 16 },
    { 5, 0, 1.2, true, "land-mine", 8, 32 },

    { 0.04, 0.1, 1.9, true, "modular-armor", 1, 1 },
    { 0.01, 0.4, 1.6, true, "power-armor", 1, 1 },
    { 0.001, 0.6, 1.4, true, "power-armor-mk2", 1, 1 },
    { 0.6, 0.05, 2, true, "solar-panel-equipment", 1, 2 },
    { 0.4, 0.05, 2, true, "battery-equipment", 1, 1 },
    { 0.32, 0.05, 2, true, "energy-shield-equipment", 1, 2 },
    { 0.16, 0.05, 1.5, true, "night-vision-equipment", 1, 1 },
    { 0.12, 0.01, 1.8, true, "personal-laser-defense-equipment", 1, 1 },
    { 0.12, 0.01, 1.8, true, "exoskeleton-equipment", 1, 1 },

    { 8, -0.5, 0.5, true, "automation-science-pack", 4, 24 },
    { 8, -0.6, 0.6, true, "logistic-science-pack", 4, 24 },
    { 6, -0.1, 1, true, "military-science-pack", 8, 20 },
    { 6, -0.5, 1.5, true, "chemical-science-pack", 8, 16 },
    { 6, 0, 1.5, true, "production-science-pack", 8, 16 },
    { 6, 0, 2, true, "utility-science-pack", 3, 3 },

    { 0.5, 0.2, 1.4, true, "construction-robot", 5, 15 },
    { 2, 0.5, 1.5, true, "roboport", 1, 1 },
    { 2, 0.5, 1.5, false, "passive-provider-chest", 2, 2 },
    { 2, 0.5, 1.5, false, "logistic-robot", 5, 15 },

    { 4, 0.2, 1.2, true, "lubricant-barrel", 1, 4 },

    -- copying over most of those i made for chronotrain:
    --always there (or normally always there):
    -- {4, 0, 1, false, 'gate', 14, 32}, --can beat biters with them
    -- {1, 0, 1, false, 'radar', 1, 2}, --disabled to reduce 'avalanche of crap' effect
    -- {0.25, 0, 1, false, 'rail', 50, 100},
    -- {0.25, 0, 1, false, 'uranium-rounds-magazine', 1, 4},
    -- {1, 0.15, 1, false, 'pump', 1, 2}, --disabled to reduce 'avalanche of crap' effect
    -- {2, 0.15, 1, false, 'pumpjack', 1, 3}, --disabled to reduce 'avalanche of crap' effect
    -- {0.02, 0.15, 1, false, 'oil-refinery', 1, 2}, --disabled to reduce 'avalanche of crap' effect
    --shotgun meta:
    -- {10, -0.2, 0.4, true, 'shotgun-shell', 12, 24}, --disabled to reduce 'avalanche of crap' effect
    -- {5, 0, 0.4, true, 'shotgun', 1, 1}, --disabled to reduce 'avalanche of crap' effect
    --modular armor meta:
    -- {0.5, -1,3, true, "power-armor-mk2", 1, 1},
    --loader meta:
    --science meta:
    -- {4, 0.4, 1.5, true, 'utility-science-pack', 16, 32},
    -- {10, 0.5, 1.5, true, 'space-science-pack', 16, 32},

    --early-game:
    --{3, -0.1, 0.2, false, "railgun-dart", 2, 4},
    -- {3, -0.1, 0.1, true, 'wooden-chest', 8, 40},
    -- {5, -0.1, 0.1, true, 'burner-inserter', 8, 20}, --disabled to reduce 'avalanche of crap' effect
    -- {1, -0.2, 0.2, true, 'offshore-pump', 1, 3}, --disabled to reduce 'avalanche of crap' effect
    -- {3, -0.2, 0.2, true, 'boiler', 3, 6}, --disabled to reduce 'avalanche of crap' effect
    -- {3, 0, 0.1, true, 'lab', 1, 3}, --disabled to reduce 'avalanche of crap' effect
    -- {3, -0.2, 0.2, true, 'steam-engine', 2, 4}, --disabled to reduce 'avalanche of crap' effect
    -- {3, -0.2, 0.2, true, 'burner-mining-drill', 2, 4},
    -- {3, 0, 0.3, true, 'iron-chest', 8, 40}, --disabled to reduce 'avalanche of crap' effect
    -- {6, -0.4, 0.4, true, 'stone-furnace', 8, 16}, --disabled to reduce 'avalanche of crap' effect
    --mid-game:
    --{6, 0.2, 0.5, false, "railgun-dart", 4, 8},
    -- {5, -0.2, 0.7, true, 'pipe', 30, 50}, --disabled to reduce 'avalanche of crap' effect
    -- {1, -0.2, 0.7, true, 'pipe-to-ground', 4, 8}, --disabled to reduce 'avalanche of crap' effect
    -- {3, 0, 0.7, true, 'steel-plate', 15, 80},
    -- {8, 0, 0.9, true, 'piercing-rounds-magazine', 10, 64},
    -- {4, 0.2, 0.6, true, 'engine-unit', 8, 16},
    --late-game:
    --{9, 0.5, 0.8, false, "railgun-dart", 8, 16},
    -- {5, 0.4, 0.7, true, 'cannon-shell', 16, 32},
    -- {5, 0.4, 0.8, true, 'explosive-cannon-shell', 16, 32},
    -- {2, 0.25, 1.75, true, 'logistic-robot', 5, 25},
    -- {1, 0.25, 1.75, true, 'laser-turret', 1, 1},
    -- {4, 0.4, 1.6, true, 'processing-unit', 30, 200},
    -- super late-game:
    --{9, 0.8, 1.2, false, "railgun-dart", 12, 20},
    -- {1, 0.9, 1.1, true, 'power-armor-mk2', 1, 1},
    -- {1, 0.8, 1.2, true, 'fusion-reactor-equipment', 1, 1}

    --{2, 0, 1, , "computer", 1, 1},
    --{1, 0.2, 1, , "railgun", 1, 1},
    --{1, 0.9, 1, , "personal-roboport-mk2-equipment", 1, 1},
}

function Public.wooden_chest_loot()
    local num = 1

    -- return Public.chest_loot(
    -- 	num,
    -- 	Math.clamp(0, 1, Math.sloped(Common.difficulty_scale(),1/2) * Common.game_completion_progress())
    -- )

    return Public.chest_loot(num, Math.clamp(0, 1, Common.game_completion_progress()))
end

function Public.iron_chest_loot()
    local num = 2

    -- local loot = Public.chest_loot(
    -- 	num,
    -- 	Math.clamp(0, 1, Math.sloped(Common.difficulty_scale(),1/2) * (5/100 + Common.game_completion_progress()))
    -- ) --reward higher difficulties with better loot

    local loot = Public.chest_loot(num, Math.clamp(0, 1, 5 / 100 + Common.game_completion_progress()))

    loot[#loot + 1] = {
        name = "coin",
        count = Math.ceil(1000 * Balance.game_resources_scale() * Math.random_float_in_range(0.8, 1.2)),
    }

    return loot
end

function Public.quest_structure_coin_loot()
    return Math.ceil(2000 * Balance.game_resources_scale() * Math.random_float_in_range(0.8, 1.2))
end

function Public.covered_wooden_chest_loot()
    local num = 2

    local loot = Public.chest_loot(
        num,
        Math.clamp(0, 1, Math.sloped(Common.difficulty_scale(), 1 / 2) * (18 / 100 + Common.game_completion_progress()))
    ) --reward higher difficulties with better loot

    return loot
end

function Public.covered_wooden_chest_loot_1()
    return {
        { name = "iron-plate", count = Math.ceil(600 * Balance.game_resources_scale()) },
        { name = "copper-plate", count = Math.ceil(200 * Balance.game_resources_scale()) },
    }
end

function Public.covered_wooden_chest_loot_2()
    return Common.raffle_from_processed_loot_data(
        Common.processed_loot_data(Public.chest_loot_data_raw),
        2,
        Math.clamp(0, 1, 0.15 + Common.game_completion_progress())
    )
end

function Public.stone_furnace_loot()
    return {
        { name = "coal", count = 50 },
    }
end

function Public.assembling_machine_loot()
    -- not sure if similar table exists already, but I couldn't find any
    local loot_table = {
        "transport-belt",
        "underground-belt",
        "splitter",
        "inserter",
        "long-handed-inserter",
        "fast-inserter",
        "small-electric-pole",
        "medium-electric-pole",
        "pipe",
        "pipe-to-ground",
        "small-lamp",
        "repair-pack",
        "iron-stick",
        "iron-gear-wheel",
        "stone-wall",
    }

    local index = Math.random(#loot_table)

    -- even though count is bigger than the stack size, it will automatically delete excess items
    return { name = loot_table[index], count = 200 }
end

function Public.storage_tank_fluid_loot(force_type)
    local ret
    local rng = Math.random(10)
    if force_type == "crude-oil" then
        ret = { name = "crude-oil", amount = Math.random(3000, 12500) }
    elseif force_type == "petroleum-gas" then
        ret = { name = "petroleum-gas", amount = Math.random(1500, 7500) }
    elseif rng <= 6 then
        ret = { name = "crude-oil", amount = Math.random(1500, 4500) }
    elseif rng == 7 then
        ret = { name = "light-oil", amount = Math.random(1500, 3500) }
    elseif rng == 8 then
        ret = { name = "heavy-oil", amount = Math.random(1500, 3500) }
        -- elseif rng == 9 then
        -- 	ret = {name = 'lubricant', amount = Math.random(1000, 2000)}
    else
        ret = { name = "petroleum-gas", amount = Math.random(1500, 2000) }
    end
    return ret
end

function Public.swamp_storage_tank_fluid_loot()
    local ret
    -- ret = {name = 'sulfuric-acid', amount = 100*Math.ceil(Math.random(5^2, 40^2)^(1/2))} -- don't know why this formula made best amount most common, but lowest amount least common (was this intentional?).
    ret = {
        name = "sulfuric-acid",
        amount = Math.ceil(2000 * Math.random_float_in_range(0.8, 1.2) * Balance.game_resources_scale()),
    }
    return ret
end

function Public.roboport_bots_loot()
    return {
        { name = "logistic-robot", count = Math.ceil((15 + Math.random(5)) * Balance.game_resources_scale()) },
        { name = "construction-robot", count = Math.ceil((10 + Math.random(5)) * Balance.game_resources_scale()) },
    }
end

function Public.random_plates(multiplier)
    multiplier = multiplier or 1
    multiplier = multiplier * Balance.game_resources_scale()
    multiplier = multiplier * Math.random_float_in_range(0.9, 1.1)

    local platesrng = Math.random(5)

    if platesrng <= 2 then
        return { name = "iron-plate", count = Math.ceil(80 * multiplier) }
    elseif platesrng <= 4 then
        return { name = "copper-plate", count = Math.ceil(80 * multiplier) }
    else
        return { name = "steel-plate", count = Math.ceil(12 * multiplier) }
    end
end

function Public.chest_loot(number_of_items, game_completion_progress)
    local ret = Common.raffle_from_processed_loot_data(
        Common.processed_loot_data(Public.chest_loot_data_raw),
        number_of_items,
        game_completion_progress
    )

    ret[#ret + 1] = ret[1]
    ret[1] = Public.random_plates()

    return ret
end

function Public.buried_treasure_loot()
    local ret = Common.raffle_from_processed_loot_data(
        Common.processed_loot_data(Public.buried_treasure_loot_data_raw),
        1,
        Math.clamp(0, 1, Math.sloped(Common.difficulty_scale(), 1 / 2) * Common.game_completion_progress_capped())
    )

    if ret and ret[1] then
        return ret[1]
    end
end

function Public.maze_camp_loot()
    if Math.random(10) <= 7 then
        return { Public.random_plates() }
    else
        return Common.raffle_from_processed_loot_data(
            Common.processed_loot_data(Public.chest_loot_data_raw),
            1,
            Math.clamp(
                0,
                1,
                Math.sloped(Common.difficulty_scale(), 1 / 2) * (15 / 100 + Common.game_completion_progress())
            )
        )
    end
end

Public.lab_loot_data_raw = {
    { 8, -0.5, 0.5, true, "automation-science-pack", 5, 20 },
    { 8, -0.6, 0.6, true, "logistic-science-pack", 5, 20 },
    { 6, -0.1, 1, true, "military-science-pack", 5, 18 },
    { 6, -0.5, 1.5, true, "chemical-science-pack", 4, 12 },
    { 6, 0, 1.5, true, "production-science-pack", 3, 11 },
    { 2, 0, 2, true, "utility-science-pack", 2, 3 },
    -- {4, 0.4, 1.5, true, 'utility-science-pack', 16, 32},
    -- {10, 0.5, 1.5, true, 'space-science-pack', 16, 32},
}

function Public.lab_loot()
    return Common.raffle_from_processed_loot_data(
        Common.processed_loot_data(Public.lab_loot_data_raw),
        1,
        Math.clamp(0, 1, Math.sloped(Common.difficulty_scale(), 1 / 2) * (Common.game_completion_progress()))
    )
end

Public.maze_treasure_data_raw = {
    { 2, -1, 1, true, "rocket", 18, 24 },
    { 2, -0.8, 0.8, false, "bulk-inserter", 8, 10 },
    { 2, 0, 1, false, "poison-capsule", 22, 22 },
    { 2, 0, 1, false, "destroyer-capsule", 8, 8 },
    { 2, 0, 1, false, "slowdown-capsule", 14, 14 },

    { 2, 0, 1, false, "uranium-rounds-magazine", 15, 25 },
    { 2, 0, 1, false, "artillery-shell", 5, 7 },
    { 2, 0, 1, false, "rail-signal", 250, 250 },
    { 2, 0, 1, false, "electric-engine-unit", 3, 4 },
    { 2, 0, 1, false, "cluster-grenade", 8, 12 },

    { 0.5, 0, 1, false, "nuclear-fuel", 1, 1 },

    { 1, 0, 0.8, false, "speed-module-3", 2, 2 },
    { 1, 0, 0.8, false, "efficiency-module-3", 3, 3 },

    { 2, 0, 1.5, true, "production-science-pack", 20, 25 },
    { 2, 0, 2, true, "utility-science-pack", 7, 8 },
    -- {2, 0, 1.5, true, 'coin', 4000, 6500},
    { 3, 0, 0.9, false, "beacon", 1, 1 },

    { 1, 0, 1, false, "construction-robot", 30, 40 },
    { 3, 0, 1, false, "passive-provider-chest", 2, 2 },

    { 1, 0.2, 1.8, true, "explosive-rocket", 6, 8 },

    { 1, 0, 0.9, false, "express-transport-belt", 20, 60 },
    { 0.5, 0, 0.9, false, "express-underground-belt", 6, 6 },
    { 0.5, 0, 0.9, false, "express-splitter", 10, 10 },
    { 1, 0, 0.9, false, "express-loader", 2, 2 },
    { 0.5, 0, 0.5, false, "substation", 2, 2 },
    { 0.5, 0, 0.8, false, "assembling-machine-3", 3, 3 },
    { 1, 0, 0.7, false, "electric-furnace", 4, 6 },

    { 1, 0, 0.8, false, "modular-armor", 1, 1 },
    { 1, 0, 2, true, "power-armor", 1, 1 },
    { 0.1, 0, 2, true, "power-armor-mk2", 1, 1 },

    { 4, -1, 1, true, "solar-panel-equipment", 3, 4 },
    { 4, -1, 1, true, "battery-equipment", 1, 1 },
    { 2, 0, 2, true, "battery-mk2-equipment", 1, 1 },
    { 4, -1, 1, true, "energy-shield-equipment", 1, 2 },
    { 2, 0, 2, true, "energy-shield-mk2-equipment", 1, 1 },
    { 2, -1, 1, true, "personal-roboport-equipment", 1, 1 },
    { 1, 0, 2, true, "personal-roboport-mk2-equipment", 1, 1 },
    { 1, 0, 0.8, false, "night-vision-equipment", 1, 1 },
    { 2, 0, 1, false, "personal-laser-defense-equipment", 1, 1 },
    { 1, 0, 1, false, "fusion-reactor-equipment", 1, 1 },
    { 4, 0, 1, false, "exoskeleton-equipment", 1, 1 },

    { 2, -0.7, 1.3, true, "advanced-circuit", 40, 90 },

    { 2, 0, 0.5, false, "laser-turret", 1, 2 },
    { 2, 0.6, 1, false, "laser-turret", 4, 5 },
    { 1, 0, 0.5, false, "roboport", 1, 1 },

    { 1, 0, 1, false, "atomic-bomb", 1, 1 },
}

function Public.maze_treasure_loot()
    if Math.random(5) == 1 then
        return { Public.random_plates(8) }
    else
        return Common.raffle_from_processed_loot_data(
            Common.processed_loot_data(Public.maze_treasure_data_raw),
            1,
            Math.clamp(0, 1, Math.sloped(Common.difficulty_scale(), 1 / 2) * (Common.game_completion_progress()))
        )
    end
end

Public.dredger_loot_raw = {
    { 8, 0, 1, false, "iron-plate", 5, 80 },
    { 8, 0, 1, false, "copper-plate", 5, 80 },
    { 8, 0, 1, false, "coal", 5, 50 },
    { 10, 0, 1, false, "coin", 10, 100 },

    { 2, 0, 1, false, "small-electric-pole", 2, 10 },
    { 1, 0, 1, false, "medium-electric-pole", 1, 5 },
    { 0.1, 0, 1, false, "big-electric-pole", 1, 3 },

    { 0.2, 0, 1, false, "poison-capsule", 1, 4 },
    { 0.2, 0, 1, false, "slowdown-capsule", 1, 4 },
    { 0.1, 0, 1, false, "destroyer-capsule", 1, 3 },
    { 0.2, 0, 1, false, "defender-capsule", 1, 4 },
    { 0.2, 0, 1, false, "distractor-capsule", 1, 3 },

    { 0.05, 0, 1, false, "speed-module-3", 1, 2 },
    { 0.05, 0, 1, false, "efficiency-module-3", 1, 2 },

    { 0.1, 0, 1, false, "rocket", 1, 3 },
    { 0.01, 0, 1, false, "explosive-rocket", 1, 2 },

    { 4, 0, 1, false, "automation-science-pack", 4, 15 },
    { 4, 0, 1, false, "logistic-science-pack", 4, 15 },
    { 2, 0, 1, false, "military-science-pack", 2, 10 },
    { 1, 0, 1, false, "chemical-science-pack", 2, 8 },
    { 1, 0, 1, false, "production-science-pack", 1, 5 },
    { 0.5, 0, 1, false, "utility-science-pack", 1, 4 },

    { 0.012, 0, 0.8, false, "night-vision-equipment", 1, 1 },
    { 0.01, 0, 1, false, "exoskeleton-equipment", 1, 1 },
    { 0.01, -1, 1, true, "energy-shield-equipment", 1, 1 },
    { 0.01, -1, 1, true, "solar-panel-equipment", 1, 1 },
    { 0.01, -1, 1, true, "battery-equipment", 1, 1 },
    { 0.008, 0, 2, true, "battery-mk2-equipment", 1, 1 },
    { 0.008, 0, 1, false, "personal-laser-defense-equipment", 1, 1 },
    { 0.008, 0, 2, true, "energy-shield-mk2-equipment", 1, 1 },
    { 0.008, -1, 1, true, "personal-roboport-equipment", 1, 1 },
    { 0.004, 0, 1, false, "fusion-reactor-equipment", 1, 1 },
    { 0.004, 0, 2, true, "personal-roboport-mk2-equipment", 1, 1 },
}

function Public.dredger_loot()
    return Common.raffle_from_processed_loot_data(
        Common.processed_loot_data(Public.dredger_loot_raw),
        1,
        Math.clamp(0, 1, Common.game_completion_progress())
    )
end

return Public
