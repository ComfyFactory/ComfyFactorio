local Public = require 'maps.mountain_fortress_v3.table'
local simplex_noise = require 'utils.simplex_noise'.d2

--add or use noise templates from here
local noises = {
    ['bb_biterland'] = {
        {modifier = 0.0015, weight = 1.1},
        {modifier = 0.009, weight = 0.34},
        {modifier = 0.095, weight = 0.016}
    },
    ['bb_ore'] = {{modifier = 0.0046, weight = 0.95}, {modifier = 0.03, weight = 0.077}, {modifier = 0.09, weight = 0.023}},
    ['cave_ponds'] = {{modifier = 0.011, weight = 0.74}, {modifier = 0.14, weight = 0.079}},
    ['smol_areas'] = {{modifier = 0.0042, weight = 0.81}, {modifier = 0.129, weight = 0.021}, {modifier = 0.119, weight = 0.03}},
    ['cave_worms'] = {{modifier = 0.0011, weight = 0.99}, {modifier = 0.09, weight = 0.059}},
    ['cave_rivers'] = {
        {modifier = 0.0077, weight = 0.74},
        {modifier = 0.0089, weight = 0.29},
        {modifier = 0.072, weight = 0.028}
    },
    ['cave_rivers_2'] = {
        {modifier = 0.0033, weight = 0.99},
        {modifier = 0.0099, weight = 0.2},
        {modifier = 0.049, weight = 0.009}
    },
    ['cave_rivers_3'] = {
        {modifier = 0.0022, weight = 0.99},
        {modifier = 0.0099, weight = 0.14},
        {modifier = 0.049, weight = 0.009}
    },
    ['cave_rivers_4'] = {
        {modifier = 0.0009, weight = 0.99},
        {modifier = 0.0099, weight = 0.1},
        {modifier = 0.049, weight = 0.009}
    },
    ['decoratives'] = {{modifier = 0.031, weight = 1.05}, {modifier = 0.055, weight = 0.24}, {modifier = 0.11, weight = 0.055}},
    ['dungeons'] = {{modifier = 0.0033, weight = 1.05}, {modifier = 0.0066, weight = 0.24}},
    ['dungeon_sewer'] = {
        {modifier = 0.00055, weight = 1.05},
        {modifier = 0.0055, weight = 0.014},
        {modifier = 0.0275, weight = 0.00135}
    },
    ['large_caves'] = {
        {modifier = 0.00363, weight = 1.05},
        {modifier = 0.01, weight = 0.23},
        {modifier = 0.055, weight = 0.045},
        {modifier = 0.11, weight = 0.042}
    },
    ['n1'] = {{modifier = 0.00011, weight = 1.1}},
    ['n2'] = {{modifier = 0.0011, weight = 1.1}},
    ['n3'] = {{modifier = 0.011, weight = 1.1}},
    ['n4'] = {{modifier = 0.11, weight = 1.1}},
    ['n5'] = {{modifier = 0.077, weight = 1.1}},
    ['watery_world'] = {
        {modifier = 0.00077, weight = 1.1},
        {modifier = 0.011, weight = 0.022},
        {modifier = 0.11, weight = 0.0055}
    },
    ['no_rocks'] = {
        {modifier = 0.00495, weight = 0.945},
        {modifier = 0.01665, weight = 0.2475},
        {modifier = 0.0435, weight = 0.0435},
        {modifier = 0.07968, weight = 0.0315}
    },
    ['no_rocks_2'] = {{modifier = 0.0184, weight = 1.265}, {modifier = 0.143, weight = 0.1045}},
    ['oasis'] = {
        {modifier = 0.00165, weight = 1.1},
        {modifier = 0.00275, weight = 0.55},
        {modifier = 0.011, weight = 0.165},
        {modifier = 0.11, weight = 0.0187}
    },
    ['scrapyard'] = {
        {modifier = 0.0055, weight = 1.1},
        {modifier = 0.011, weight = 0.385},
        {modifier = 0.055, weight = 0.253},
        {modifier = 0.11, weight = 0.121}
    },
    ['scrapyard_modified'] = {
        {modifier = 0.0066, weight = 1.1},
        {modifier = 0.044, weight = 0.165},
        {modifier = 0.242, weight = 0.055},
        {modifier = 0.055, weight = 0.352}
    },
    ['big_cave'] = {
        {modifier = 0.0033, weight = 1.1},
        {modifier = 0.022, weight = 0.055},
        {modifier = 0.165, weight = 0.022}
    },
    ['small_caves'] = {
        {modifier = 0.0066, weight = 1.1},
        {modifier = 0.044, weight = 0.165},
        {modifier = 0.242, weight = 0.055}
    },
    ['small_caves_2'] = {
        {modifier = 0.0099, weight = 1.1},
        {modifier = 0.055, weight = 0.275},
        {modifier = 0.275, weight = 0.055}
    },
    ['forest_location'] = {
        {modifier = 0.0066, weight = 1.1},
        {modifier = 0.011, weight = 0.275},
        {modifier = 0.055, weight = 0.165},
        {modifier = 0.11, weight = 0.0825}
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
function Public.get_noise(name, pos, seed)
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

return Public
