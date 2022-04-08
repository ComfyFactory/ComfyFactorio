local simplex_noise = require 'utils.simplex_noise'.d2

--add or use noise templates from here
local noises = {
    ['bb_biterland'] = {
        {modifier = 0.001, weight = 1},
        {modifier = 0.01, weight = 0.35},
        {modifier = 0.1, weight = 0.015}
    },
    ['bb_ore'] = {{modifier = 0.0042, weight = 1}, {modifier = 0.031, weight = 0.08}, {modifier = 0.1, weight = 0.025}},
    ['cave_ponds'] = {{modifier = 0.01, weight = 0.75}, {modifier = 0.15, weight = 0.08}},
    ['smol_areas'] = {{modifier = 0.005, weight = 0.85}, {modifier = 0.15, weight = 0.025}, {modifier = 0.15, weight = 0.035}},
    ['cave_worms'] = {{modifier = 0.001, weight = 1}, {modifier = 0.1, weight = 0.06}},
    ['cave_rivers'] = {
        {modifier = 0.007, weight = 0.75},
        {modifier = 0.0090, weight = 0.30},
        {modifier = 0.075, weight = 0.03}
    },
    ['cave_rivers_2'] = {
        {modifier = 0.003, weight = 1},
        {modifier = 0.01, weight = 0.21},
        {modifier = 0.05, weight = 0.01}
    },
    ['cave_rivers_3'] = {
        {modifier = 0.002, weight = 1},
        {modifier = 0.01, weight = 0.15},
        {modifier = 0.05, weight = 0.01}
    },
    ['cave_rivers_4'] = {
        {modifier = 0.001, weight = 1},
        {modifier = 0.01, weight = 0.11},
        {modifier = 0.05, weight = 0.01}
    },
    ['decoratives'] = {{modifier = 0.03, weight = 1}, {modifier = 0.05, weight = 0.25}, {modifier = 0.1, weight = 0.05}},
    ['dungeons'] = {{modifier = 0.003, weight = 1}, {modifier = 0.006, weight = 0.25}},
    ['dungeon_sewer'] = {
        {modifier = 0.0005, weight = 1},
        {modifier = 0.005, weight = 0.015},
        {modifier = 0.025, weight = 0.0015}
    },
    ['large_caves'] = {
        {modifier = 0.0033, weight = 1},
        {modifier = 0.01, weight = 0.22},
        {modifier = 0.05, weight = 0.05},
        {modifier = 0.1, weight = 0.04}
    },
    ['n1'] = {{modifier = 0.0001, weight = 1}},
    ['n2'] = {{modifier = 0.001, weight = 1}},
    ['n3'] = {{modifier = 0.01, weight = 1}},
    ['n4'] = {{modifier = 0.1, weight = 1}},
    ['n5'] = {{modifier = 0.07, weight = 1}},
    ['watery_world'] = {
        {modifier = 0.0007, weight = 1},
        {modifier = 0.01, weight = 0.02},
        {modifier = 0.1, weight = 0.005}
    },
    ['no_rocks'] = {
        {modifier = 0.0045, weight = 0.95},
        {modifier = 0.017, weight = 0.25},
        {modifier = 0.045, weight = 0.045},
        {modifier = 0.088, weight = 0.035}
    },
    ['no_rocks_2'] = {{modifier = 0.016, weight = 1.15}, {modifier = 0.13, weight = 0.095}},
    ['oasis'] = {
        {modifier = 0.0015, weight = 1},
        {modifier = 0.0025, weight = 0.5},
        {modifier = 0.01, weight = 0.15},
        {modifier = 0.1, weight = 0.017}
    },
    ['scrapyard'] = {
        {modifier = 0.005, weight = 1},
        {modifier = 0.01, weight = 0.35},
        {modifier = 0.05, weight = 0.23},
        {modifier = 0.1, weight = 0.11}
    },
    ['scrapyard_modified'] = {
        {modifier = 0.006, weight = 1},
        {modifier = 0.04, weight = 0.15},
        {modifier = 0.22, weight = 0.05},
        {modifier = 0.05, weight = 0.32}
    },
    ['big_cave'] = {
        {modifier = 0.003, weight = 1},
        {modifier = 0.02, weight = 0.05},
        {modifier = 0.15, weight = 0.02}
    },
    ['small_caves'] = {
        {modifier = 0.006, weight = 1},
        {modifier = 0.04, weight = 0.15},
        {modifier = 0.22, weight = 0.05}
    },
    ['small_caves_2'] = {
        {modifier = 0.009, weight = 1},
        {modifier = 0.05, weight = 0.25},
        {modifier = 0.25, weight = 0.05}
    },
    ['forest_location'] = {
        {modifier = 0.006, weight = 1},
        {modifier = 0.01, weight = 0.25},
        {modifier = 0.05, weight = 0.15},
        {modifier = 0.1, weight = 0.05}
    },
    ['forest_density'] = {
        {modifier = 0.01, weight = 1},
        {modifier = 0.05, weight = 0.5},
        {modifier = 0.1, weight = 0.025}
    },
    ['cave_miner_01'] = {
        {modifier = 0.002, weight = 1},
        {modifier = 0.003, weight = 0.5},
        {modifier = 0.01, weight = 0.01},
        {modifier = 0.1, weight = 0.015}
    },
    ['cave_miner_02'] = {
        {modifier = 0.006, weight = 1},
        {modifier = 0.02, weight = 0.15},
        {modifier = 0.25, weight = 0.025}
    },
    ['cm_ponds'] = {{modifier = 0.025, weight = 1}, {modifier = 0.05, weight = 0.25}, {modifier = 0.1, weight = 0.05}},
    ['cm_ocean'] = {
        {modifier = 0.002, weight = 1},
        {modifier = 0.004, weight = 1},
        {modifier = 0.02, weight = 0.05}
    }
}

--returns a float number between -1 and 1
local function get_noise(name, pos, seed)
    local noise = 0
    local d = 0
    for i = 1, #noises[name] do
        local mod = noises[name]
        noise = noise + simplex_noise(pos.x * mod[i].modifier, pos.y * mod[i].modifier, seed, 0xF) * mod[i].weight
        d = d + mod[i].weight
        seed = seed + seed / seed
    end
    noise = noise / d
    return noise
end

return get_noise
