local simplex_noise = require 'utils.simplex_noise'
local random = math.random

local Public = {}

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math.random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local function secret_shop(pos, surface)
    local secret_market_items = {
        { price = { { 'coin', random(300, 600) } },    offer = { type = 'give-item', item = 'combat-shotgun' } },
        { price = { { 'coin', random(200, 400) } },    offer = { type = 'give-item', item = 'rocket-launcher' } },
        { price = { { 'coin', random(5, 10) } },       offer = { type = 'give-item', item = 'piercing-rounds-magazine' } },
        --{price = {{"coin", random(150,250)}}, offer = {type = 'give-item', item = 'uranium-rounds-magazine'}},
        { price = { { 'coin', random(15, 30) } },      offer = { type = 'give-item', item = 'piercing-shotgun-shell' } },
        { price = { { 'coin', random(10, 20) } },      offer = { type = 'give-item', item = 'rocket' } },
        { price = { { 'coin', random(20, 30) } },      offer = { type = 'give-item', item = 'explosive-rocket' } },
        { price = { { 'coin', random(30, 60) } },      offer = { type = 'give-item', item = 'cluster-grenade' } },
        { price = { { 'coin', random(8, 16) } },       offer = { type = 'give-item', item = 'land-mine' } },
        { price = { { 'coin', random(200, 300) } },    offer = { type = 'give-item', item = 'heavy-armor' } },
        { price = { { 'coin', random(400, 800) } },    offer = { type = 'give-item', item = 'modular-armor' } },
        { price = { { 'coin', random(1000, 2000) } },  offer = { type = 'give-item', item = 'power-armor' } },
        { price = { { 'coin', random(2500, 5000) } },  offer = { type = 'give-item', item = 'fusion-reactor-equipment' } },
        { price = { { 'coin', random(200, 400) } },    offer = { type = 'give-item', item = 'battery-equipment' } },
        { price = { { 'coin', random(150, 250) } },    offer = { type = 'give-item', item = 'belt-immunity-equipment' } },
        { price = { { 'coin', random(100, 200) } },    offer = { type = 'give-item', item = 'night-vision-equipment' } },
        { price = { { 'coin', random(400, 800) } },    offer = { type = 'give-item', item = 'exoskeleton-equipment' } },
        { price = { { 'coin', random(200, 300) } },    offer = { type = 'give-item', item = 'personal-roboport-equipment' } },
        { price = { { 'coin', random(25, 50) } },      offer = { type = 'give-item', item = 'construction-robot' } },
        -- {price = {{"coin", random(10000,20000)}}, offer = {type = 'give-item', item = 'energy-shield-equipment'}},
        -- {price = {{"coin", random(5000,15000)}}, offer = {type = 'give-item', item = 'personal-laser-defense-equipment'}},
        { price = { { 'coin', random(100, 300) } },    offer = { type = 'give-item', item = 'loader' } },
        { price = { { 'coin', random(200, 400) } },    offer = { type = 'give-item', item = 'fast-loader' } },
        { price = { { 'coin', random(300, 500) } },    offer = { type = 'give-item', item = 'express-loader' } },
        { price = { { 'coin', random(150, 300) } },    offer = { type = 'give-item', item = 'locomotive' } },
        { price = { { 'coin', random(100, 200) } },    offer = { type = 'give-item', item = 'cargo-wagon' } },
        { price = { { 'coin', random(5, 15) } },       offer = { type = 'give-item', item = 'grenade' } },
        { price = { { 'coin', random(80, 160) } },     offer = { type = 'give-item', item = 'cliff-explosives' } },
        { price = { { 'coin', random(10, 20) } },      offer = { type = 'give-item', item = 'explosives', count = 50 } },
        { price = { { 'coin', random(4, 8) } },        offer = { type = 'give-item', item = 'rail', count = 4 } },
        { price = { { 'coin', random(20, 30) } },      offer = { type = 'give-item', item = 'train-stop' } },
        { price = { { 'coin', random(4, 12) } },       offer = { type = 'give-item', item = 'small-lamp' } },
        { price = { { 'coin', random(1, 4) } },        offer = { type = 'give-item', item = 'firearm-magazine' } },
        { price = { { 'coin', random(60, 150) } },     offer = { type = 'give-item', item = 'car', count = 1 } },
        { price = { { 'coin', random(75, 150) } },     offer = { type = 'give-item', item = 'gun-turret', count = 1 } },
        { price = { { 'coin', random(500, 750) } },    offer = { type = 'give-item', item = 'laser-turret', count = 1 } },
        { price = { { 'coin', random(1000, 2000) } },  offer = { type = 'give-item', item = 'artillery-turret', count = 1 } },
        { price = { { 'coin', random(100, 200) } },    offer = { type = 'give-item', item = 'artillery-shell', count = 1 } },
        { price = { { 'coin', random(50, 150) } },     offer = { type = 'give-item', item = 'artillery-targeting-remote', count = 1 } },
        { price = { { 'coin', random(5, 15) } },       offer = { type = 'give-item', item = 'shotgun-shell', count = 1 } },
        { price = { { 'coin', random(8000, 16000) } }, offer = { type = 'give-item', item = 'power-armor-mk2', count = 1 } },
        { price = { { 'coin', random(80, 160) } },     offer = { type = 'give-item', item = 'solar-panel-equipment', count = 1 } },
        { price = { { 'coin', random(4, 8) } },        offer = { type = 'give-item', item = 'wood', count = 50 } },
        { price = { { 'coin', random(4, 8) } },        offer = { type = 'give-item', item = 'iron-ore', count = 50 } },
        { price = { { 'coin', random(4, 8) } },        offer = { type = 'give-item', item = 'copper-ore', count = 50 } },
        { price = { { 'coin', random(4, 8) } },        offer = { type = 'give-item', item = 'stone', count = 50 } },
        { price = { { 'coin', random(4, 8) } },        offer = { type = 'give-item', item = 'coal', count = 50 } }
        --{price = {{"coin", random(4,8)}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}}
    }
    secret_market_items = shuffle(secret_market_items)

    local market = surface.create_entity { name = 'market', position = pos }
    market.destructible = false

    for i = 1, math.random(6, 10), 1 do
        market.add_market_item(secret_market_items[i])
    end
end

local function treasure_chest(position)
    if not game.surfaces['deep_jungle'].can_place_entity({ name = 'steel-chest', position = position, force = 'player' }) then
        return
    end
    local treasure_chest_raffle_table = {}
    local treasure_chest_loot_weights = {}
    table.insert(treasure_chest_loot_weights, { { name = 'landfill', count = random(8, 16) }, 16 })
    table.insert(treasure_chest_loot_weights, { { name = 'iron-gear-wheel', count = random(16, 48) }, 8 })
    table.insert(treasure_chest_loot_weights, { { name = 'coal', count = random(16, 48) }, 2 })
    table.insert(treasure_chest_loot_weights, { { name = 'copper-cable', count = random(64, 128) }, 8 })
    table.insert(treasure_chest_loot_weights, { { name = 'inserter', count = random(4, 8) }, 4 })
    table.insert(treasure_chest_loot_weights, { { name = 'fast-inserter', count = random(4, 8) }, 3 })
    table.insert(treasure_chest_loot_weights, { { name = 'burner-inserter', count = random(4, 8) }, 6 })
    table.insert(treasure_chest_loot_weights, { { name = 'rocket-fuel', count = random(1, 5) }, 3 })
    table.insert(treasure_chest_loot_weights, { { name = 'small-electric-pole', count = random(4, 8) }, 7 })
    table.insert(treasure_chest_loot_weights, { { name = 'firearm-magazine', count = random(16, 48) }, 8 })
    table.insert(treasure_chest_loot_weights, { { name = 'submachine-gun', count = 1 }, 4 })
    table.insert(treasure_chest_loot_weights, { { name = 'grenade', count = random(6, 12) }, 5 })
    table.insert(treasure_chest_loot_weights, { { name = 'land-mine', count = random(8, 16) }, 5 })
    table.insert(treasure_chest_loot_weights, { { name = 'light-armor', count = 1 }, 1 })
    table.insert(treasure_chest_loot_weights, { { name = 'heavy-armor', count = 1 }, 2 })
    table.insert(treasure_chest_loot_weights, { { name = 'pipe', count = random(10, 100) }, 6 })
    table.insert(treasure_chest_loot_weights, { { name = 'explosives', count = random(40, 50) }, 6 })
    table.insert(treasure_chest_loot_weights, { { name = 'shotgun', count = 1 }, 3 })
    table.insert(treasure_chest_loot_weights, { { name = 'shotgun-shell', count = random(8, 16) }, 3 })
    table.insert(treasure_chest_loot_weights, { { name = 'stone-brick', count = random(80, 100) }, 4 })
    table.insert(treasure_chest_loot_weights, { { name = 'small-lamp', count = random(2, 4) }, 2 })
    table.insert(treasure_chest_loot_weights, { { name = 'rail', count = random(16, 48) }, 3 })
    table.insert(treasure_chest_loot_weights, { { name = 'coin', count = random(32, 320) }, 1 })
    table.insert(treasure_chest_loot_weights, { { name = 'assembling-machine-1', count = random(1, 3) }, 3 })
    table.insert(treasure_chest_loot_weights, { { name = 'assembling-machine-2', count = random(1, 3) }, 2 })
    table.insert(treasure_chest_loot_weights, { { name = 'assembling-machine-3', count = random(1, 2) }, 1 })
    for _, t in pairs(treasure_chest_loot_weights) do
        for _ = 1, t[2], 1 do
            table.insert(treasure_chest_raffle_table, t[1])
        end
    end

    local e = game.surfaces['deep_jungle'].create_entity { name = 'wooden-chest', position = position, force = 'player' }
    e.minable = false
    local i = e.get_inventory(defines.inventory.chest)
    for _ = 1, random(3, 7), 1 do
        local loot = treasure_chest_raffle_table[random(1, #treasure_chest_raffle_table)]
        i.insert(loot)
    end
end

local function rare_treasure_chest(position)
    if not game.surfaces['deep_jungle'].can_place_entity({ name = 'steel-chest', position = position, force = 'player' }) then
        return
    end
    local rare_treasure_chest_raffle_table = {}
    local rare_treasure_chest_loot_weights = {}
    table.insert(rare_treasure_chest_loot_weights, { { name = 'combat-shotgun', count = 1 }, 5 })
    table.insert(rare_treasure_chest_loot_weights, { { name = 'piercing-shotgun-shell', count = random(8, 16) }, 5 })
    table.insert(rare_treasure_chest_loot_weights, { { name = 'rocket-launcher', count = 1 }, 5 })
    table.insert(rare_treasure_chest_loot_weights, { { name = 'rocket', count = random(4, 8) }, 5 })
    table.insert(rare_treasure_chest_loot_weights, { { name = 'explosive-rocket', count = random(4, 8) }, 5 })
    table.insert(rare_treasure_chest_loot_weights, { { name = 'modular-armor', count = 1 }, 3 })
    table.insert(rare_treasure_chest_loot_weights, { { name = 'piercing-rounds-magazine', count = random(32, 64) }, 3 })
    table.insert(rare_treasure_chest_loot_weights, { { name = 'defender-capsule', count = random(4, 8) }, 5 })
    table.insert(rare_treasure_chest_loot_weights, { { name = 'distractor-capsule', count = random(3, 5) }, 4 })
    table.insert(rare_treasure_chest_loot_weights, { { name = 'destroyer-capsule', count = random(2, 3) }, 3 })
    for _, t in pairs(rare_treasure_chest_loot_weights) do
        for _ = 1, t[2], 1 do
            table.insert(rare_treasure_chest_raffle_table, t[1])
        end
    end

    local e = game.surfaces['deep_jungle'].create_entity { name = 'steel-chest', position = position, force = 'player' }
    e.minable = false
    local i = e.get_inventory(defines.inventory.chest)
    for _ = 1, random(2, 3), 1 do
        local loot = rare_treasure_chest_raffle_table[random(1, #rare_treasure_chest_raffle_table)]
        i.insert(loot)
    end
end

local function get_noise(name, pos)
    local seed = game.surfaces[1].map_gen_settings.seed
    local d2 = simplex_noise.d2
    local noise_seed_add = 25000
    if name == 1 then
        local noise = {}
        noise[1] = d2(pos.x * 0.001, pos.y * 0.001, seed)
        seed = seed + noise_seed_add
        noise[2] = d2(pos.x * 0.01, pos.y * 0.01, seed + noise_seed_add)
        noise = noise[1] + noise[2] * 0.1
        return noise
    end
    if name == 2 then
        local noise = {}
        noise[1] = d2(pos.x * 0.015, pos.y * 0.015, seed)
        seed = seed + noise_seed_add
        noise[2] = d2(pos.x * 0.15, pos.y * 0.15, seed + noise_seed_add)
        noise = noise[1] + noise[2] * 0.2
        return noise
    end
    if name == 3 then
        local noise = {}
        noise[1] = d2(pos.x * 0.025, pos.y * 0.025, seed)
        seed = seed + noise_seed_add
        noise[2] = d2(pos.x * 0.2, pos.y * 0.2, seed + noise_seed_add)
        noise = noise[1] + noise[2] * 0.2
        return noise
    end
    if name == 'greenwater' then
        local noise = {}
        noise[1] = d2(pos.x * 0.003, pos.y * 0.003, seed)
        seed = seed + noise_seed_add
        noise[2] = d2(pos.x * 0.03, pos.y * 0.03, seed + noise_seed_add)
        noise = noise[1] + noise[2] * 0.1
        return noise
    end
end

local rock_raffle = { 'big-sand-rock', 'big-sand-rock', 'big-rock', 'big-rock', 'big-rock', 'big-rock', 'huge-rock' }
local tree_raffle = { 'tree-04', 'tree-07', 'tree-09', 'tree-06', 'tree-04', 'tree-07', 'tree-09', 'tree-04' }

local function process_tile(pos)
    local noise_1 = get_noise(1, pos)
    if noise_1 > -0.03 and noise_1 < 0.03 then
        return 'deepwater'
    end
    if noise_1 > -0.05 and noise_1 < 0.05 then
        return 'water'
    end
    local noise_greenwater = get_noise('greenwater', pos)
    if noise_greenwater > -0.035 and noise_greenwater < 0.035 then
        return 'water-green'
    end
    if noise_1 > -0.08 and noise_1 < 0.08 then
        return false
    end

    local noise_2 = get_noise(2, pos)
    if noise_2 > 0.37 or noise_2 < -0.37 then
        if random(1, 4) == 1 then
            return false, tree_raffle[math.ceil(math.abs(noise_1 * 8))]
        end
    end
    local noise_3 = get_noise(3, pos)
    if noise_3 > 0.5 then
        if random(1, 3) == 1 then
            return false, rock_raffle[random(1, #rock_raffle)]
        end
    end

    return false
end

local function process_bits(data)
    local pos = data.position
    local tiles = data.tiles
    local entities = data.entities

    local surface = game.surfaces['deep_jungle']

    local treasure_chests = {}
    local rare_treasure_chests = {}
    local secret_shops = {}

    local tile_to_insert, entity_to_place = process_tile(pos)
    if entity_to_place then
        entities[#entities + 1] = { name = entity_to_place, position = pos, force = 'player' }
    end

    if tile_to_insert then
        tiles[#tiles + 1] = { name = tile_to_insert, position = pos }
        if random(1, 40) == 1 and tile_to_insert == 'deepwater' then
            entities[#entities + 1] = { name = 'fish', position = pos }
        end
    end

    if random(1, 1500) == 1 then
        table.insert(treasure_chests, pos)
    end
    if random(1, 16000) == 1 then
        table.insert(rare_treasure_chests, pos)
    end
    if random(1, 8000) == 1 then
        table.insert(secret_shops, pos)
    end

    for _, v in pairs(treasure_chests) do
        treasure_chest(v)
    end
    for _, v in pairs(rare_treasure_chests) do
        rare_treasure_chest(v)
    end
    for _, v in pairs(secret_shops) do
        if not surface.get_tile(v).collides_with('player') then
            local area = { { v.x - 128, v.y - 128 }, { v.x + 128, v.y + 128 } }
            if surface.count_entities_filtered({ name = 'market', area = area }) == 0 then
                secret_shop(v, surface)
            end
        end
    end
end

function Public.heavy_functions(data)
    local surface = data.surface
    local map_name = 'deep_jungle'

    if string.sub(surface.name, 0, #map_name) ~= map_name then
        return
    end

    if not data.seed then
        data.seed = surface.map_gen_settings.seed
    end

    process_bits(data)
end

return Public
