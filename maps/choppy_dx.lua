--luacheck: ignore
--choppy-- mewmew made this --
--neko barons attempt to mix up map gen--

require 'modules.satellite_score'
require 'modules.spawners_contain_biters'
require 'utils.functions.create_entity_chain'
require 'utils.functions.create_tile_chain'
require 'utils.tools.map_functions'

require 'modules.surrounded_by_worms'
require 'modules.biter_noms_you'

local Map = require 'modules.map_info'
local unearthing_worm = require 'utils.functions.unearthing_worm'
local unearthing_biters = require 'utils.functions.unearthing_biters'
local tick_tack_trap = require 'utils.functions.tick_tack_trap'

local simplex_noise = require 'utils.simplex_noise'.d2
local Event = require 'utils.event'
local math_random = math.random

--global.choppy_nightmare = true

local disabled_for_deconstruction = {
    ['fish'] = true,
    ['rock-huge'] = true,
    ['rock-big'] = true,
    ['sand-rock-big'] = true,
    ['mineable-wreckage'] = true
}

local tile_replacements = {
    ['dirt-1'] = 'grass-1',
    ['dirt-2'] = 'grass-2',
    ['dirt-3'] = 'grass-3',
    ['dirt-4'] = 'grass-4',
    ['dirt-5'] = 'grass-1',
    ['sand-1'] = 'grass-1',
    ['sand-2'] = 'grass-2',
    ['sand-3'] = 'grass-3',
    ['dry-dirt'] = 'grass-2',
    ['red-desert-0'] = 'grass-1',
    ['red-desert-1'] = 'grass-2',
    ['red-desert-2'] = 'grass-3',
    ['red-desert-3'] = 'grass-4'
}

local rocks = {'rock-big', 'rock-big', 'rock-huge'}
local decos = {
    'green-hairy-grass',
    'green-hairy-grass',
    'green-hairy-grass',
    'green-hairy-grass',
    'green-hairy-grass',
    'green-hairy-grass',
    'green-carpet-grass',
    'green-carpet-grass',
    'green-pita'
}
-- local decos_inside_forest = {"brown-asterisk","brown-asterisk", "brown-carpet-grass","brown-hairy-grass"} // unused?

local noises = {
    --["forest_location"] = {{modifier = 0.006, weight = 1}, {modifier = 0.01, weight = 0.25}, {modifier = 0.05, weight = 0.15}, {modifier = 0.1, weight = 0.05}},
    ['forest_location'] = {
        {modifier = 0.006, weight = 0.60},
        {modifier = 0.01, weight = 0.20},
        {modifier = 0.05, weight = 0.12},
        {modifier = 0.1, weight = 0.08}
    },
    ['forest_density'] = {{modifier = 0.01, weight = 0.8}, {modifier = 0.05, weight = 0.4}},
    --["forest_region"] = {{modifier = 0.001, weight = 1}, {modifier = 0.025, weight = 0.5}, {modifier = 0.02, weight = 0.025}}
    ['forest_region'] = {
        {modifier = 0.0005, weight = 0.85},
        {modifier = 0.005, weight = 0.25},
        {modifier = 0.01, weight = 0.15},
        {modifier = 0.05, weight = 0.05}
    }
}
local function get_noise(name, pos, seed)
    local noise = 0
    for _, n in pairs(noises[name]) do
        noise = noise + simplex_noise(pos.x * n.modifier, pos.y * n.modifier, seed) * n.weight
        seed = seed + 10000
    end
    return noise
end

local entities_to_convert = {
    ['coal'] = true,
    ['copper-ore'] = true,
    ['iron-ore'] = true,
    ['uranium-ore'] = true,
    ['stone'] = true,
    ['angels-ore1'] = true,
    ['angels-ore2'] = true,
    ['angels-ore3'] = true,
    ['angels-ore4'] = true,
    ['angels-ore5'] = true,
    ['angels-ore6'] = true,
    ['thorium-ore'] = true
}

local trees_to_remove = {
    ['dead-dry-hairy-tree'] = true,
    ['dead-grey-trunk'] = true,
    ['dead-tree-desert'] = true,
    ['dry-hairy-tree'] = true,
    ['dry-tree'] = true,
    ['tree-01'] = true,
    ['tree-02'] = true,
    ['tree-02-red'] = true,
    ['tree-03'] = true,
    ['tree-04'] = true,
    ['tree-05'] = true,
    ['tree-06'] = true,
    ['tree-06-brown'] = true,
    ['tree-07'] = true,
    ['tree-08'] = true,
    ['tree-08-brown'] = true,
    ['tree-08-red'] = true,
    ['tree-09'] = true,
    ['tree-09-brown'] = true,
    ['tree-09-red'] = true
}

local function process_entity(e)
    if not e.valid then
        return
    end
    if trees_to_remove[e.name] then
        e.destroy()
        return
    end
    if entities_to_convert[e.name] then
        if math_random(1, 100) > 33 then
            e.surface.create_entity({name = rocks[math_random(1, #rocks)], position = e.position})
        end
        e.destroy()
        return
    end
end

-- local nightmare_trees = {"tree-08-brown","tree-01","tree-04","tree-02-red"} // unused?

local function process_tile(surface, pos, tile, entities, seed)
    if tile.collides_with('player-layer') then
        return
    end
    if not surface.can_place_entity({name = 'tree-01', position = pos}) then
        return
    end

    if math_random(1, 100000) == 1 then
        local wrecks = {'big-ship-wreck-1', 'big-ship-wreck-2', 'big-ship-wreck-3'}
        local e = surface.create_entity {name = wrecks[math_random(1, #wrecks)], position = pos, force = 'neutral'}
        e.insert({name = 'raw-fish', count = math_random(3, 25)})
        if math_random(1, 3) == 1 then
            e.insert({name = 'wood', count = math_random(11, 44)})
        end
    end
    --

    --[[
    local noise_forest_location = get_noise("forest_location", pos, seed)

    if noise_forest_location > 0.095 then
        if not global.choppy_nightmare then
            if noise_forest_location > 0.6 then
                if math_random(1,100) > 42 then surface.create_entity({name = "tree-08-brown", position = pos}) end
            else
                if math_random(1,100) > 42 then surface.create_entity({name = "tree-01", position = pos}) end
            end
        else
            if math_random(1,100) > 56 then surface.create_entity({name = "tree-08-brown", position = pos}) end
        end
        surface.create_decoratives({check_collision=false, decoratives={{name = decos_inside_forest[math_random(1, #decos_inside_forest)], position = pos, amount = math_random(1, 2)}}})
        return
    end

    if noise_forest_location < -0.095 then
        if not global.choppy_nightmare then
            if noise_forest_location < -0.6 then
                if math_random(1,100) > 42 then surface.create_entity({name = "tree-04", position = pos}) end
            else
                if math_random(1,100) > 42 then surface.create_entity({name = "tree-02-red", position = pos}) end
            end
        else
            if math_random(1,100) > 56 then surface.create_entity({name = "tree-08-brown", position = pos}) end
        end
        surface.create_decoratives({check_collision=false, decoratives={{name = decos_inside_forest[math_random(1, #decos_inside_forest)], position = pos, amount = math_random(1, 2)}}})
        return
    end
    ]] local density =
        75

    local noise_forest_regionA = get_noise('forest_region', pos, seed)
    local noise_forest_regionB = get_noise('forest_region', pos, seed + 197)
    local noise_forest_area = get_noise('forest_location', pos, seed + 872)
    local noise_forest_dense = get_noise('forest_density', pos, seed + 1625)

    density = density + math.ceil(noise_forest_dense * 20)

    if noise_forest_regionA > 0.05 then
        if noise_forest_regionB > 0.05 then
            if noise_forest_area > 0.1 then
                if math_random(1, 100) > density then
                    entities[#entities + 1] = {name = 'tree-02-red', position = pos}
                end
            elseif noise_forest_area < -0.1 then
                --else
                if math_random(1, 100) > density then
                    entities[#entities + 1] = {name = 'tree-09-brown', position = pos}
                end
            end
        elseif noise_forest_regionB < -0.05 then
            if noise_forest_area > 0.1 then
                if math_random(1, 100) > density then
                    entities[#entities + 1] = {name = 'tree-04', position = pos}
                end
            elseif noise_forest_area < -0.1 then
                --else
                if math_random(1, 100) > density then
                    entities[#entities + 1] = {name = 'tree-08-red', position = pos}
                end
            end
        end
    elseif noise_forest_regionA < -0.05 then
        if noise_forest_regionB > 0.05 then
            if noise_forest_area > 0.1 then
                if math_random(1, 100) > density then
                    entities[#entities + 1] = {name = 'tree-01', position = pos}
                end
            elseif noise_forest_area < -0.1 then
                --else
                if math_random(1, 100) > density then
                    entities[#entities + 1] = {name = 'tree-05', position = pos}
                end
            end
        elseif noise_forest_regionB < -0.05 then
            if noise_forest_area > 0.1 then
                if math_random(1, 100) > density then
                    entities[#entities + 1] = {name = 'tree-08-brown', position = pos}
                end
            elseif noise_forest_area < -0.1 then
                --else
                if math_random(1, 100) > density then
                    entities[#entities + 1] = {name = 'tree-03', position = pos}
                end
            end
        end
    end

    if math_random(1, 3) == 1 then
        surface.create_decoratives(
            {
                check_collision = false,
                decoratives = {{name = decos[math_random(1, #decos)], position = pos, amount = math_random(1, 2)}}
            }
        )
    end
end

local function process_chunk(area)
    local left_top = area.left_top
    local tiles = {}
    local entities = {}
    local seed = game.surfaces[1].map_gen_settings.seed
    local surface = game.surfaces['nauvis']

    for _, e in pairs(surface.find_entities_filtered({area = area})) do
        process_entity(e)
    end

    for x = 0.5, 31.5, 1 do
        for y = 0.5, 31.5, 1 do
            local pos = {x = left_top.x + x, y = left_top.y + y}

            local tile = surface.get_tile(pos)
            if tile_replacements[tile.name] then
                tiles[#tiles + 1] = {name = tile_replacements[tile.name], position = pos}
            end

            process_tile(surface, pos, tile, entities, seed)
        end
    end
    surface.set_tiles(tiles, true)

    for _, e in pairs(surface.find_entities_filtered({area = area, type = 'unit-spawner'})) do
        for _, entity in pairs(e.surface.find_entities_filtered({area = {{e.position.x - 7, e.position.y - 7}, {e.position.x + 7, e.position.y + 7}}, force = 'neutral'})) do
            if entity.valid then
                entity.destroy()
            end
        end
    end

    for _, e in ipairs(entities) do
        local pos = e.position
        local name = e.name
        surface.create_entity {name = name, position = pos}
    end
    if global.spawn_generated then
        return
    end
    if left_top.x < 96 then
        return
    end

    for _, e in pairs(surface.find_entities_filtered({area = {{-50, -50}, {50, 50}}})) do
        local distance_to_center = math.sqrt(e.position.x ^ 2 + e.position.y ^ 2)
        if e.valid then
            if distance_to_center < 12 and e.type == 'tree' and math_random(1, 5) ~= 1 then
                e.destroy()
            end
        end
    end
    global.spawn_generated = true
end

local function process_chunk_queue()
    for k, area in pairs(global.chunk_queue) do
        process_chunk(area)
        table.remove(global.chunk_queue, k)
        return
    end
end

local function get_ore_from_entpos(entity)
    local seed = game.surfaces[1].map_gen_settings.seed
    local noise_forest_location = get_noise('forest_location', entity.position, seed)
    if noise_forest_location < -0.6 then
        return 'tree-04'
    end
    if noise_forest_location < -0.095 then
        return 'tree-02-red'
    end
    if noise_forest_location < 0.6 then
        return 'tree-01'
    end
    return 'tree-08-brown'
end

local function on_chunk_generated(event)
    if game.surfaces.nauvis.index ~= event.surface.index then
        return
    end
    local area = event.area

    if game.tick == 0 then
        process_chunk(area)
    else
        table.insert(global.chunk_queue, area)
    end
end

local function on_marked_for_deconstruction(event)
    if disabled_for_deconstruction[event.entity.name] then
        event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
    end
    if event.entity.type == 'tree' then
        event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if player.online_time == 0 then
        player.insert({name = 'pistol', count = 1})
        player.insert({name = 'firearm-magazine', count = 8})
    end

    -- game.print({"comfy.welcome"})

    if global.map_init_done then
        return
    end

    --game.map_settings.pollution.min_pollution_to_damage_trees = 1000000
    --game.map_settings.pollution.pollution_per_tree_damage = 0
    --game.map_settings.pollution.pollution_restored_per_tree_damage = 0

    --game.surfaces["nauvis"].ticks_per_day = game.surfaces["nauvis"].ticks_per_day * 2

    global.entity_yield = {
        ['tree-01'] = {'iron-ore'},
        ['tree-02-red'] = {'copper-ore'},
        ['tree-04'] = {'coal'},
        ['tree-08-brown'] = {'stone'},
        ['rock-big'] = {'uranium-ore'},
        ['rock-huge'] = {'uranium-ore'},
        ['tree-09-brown'] = {'stone', 'coal'},
        ['tree-08-red'] = {'copper-ore', 'iron-ore'},
        ['tree-03'] = {'coal', 'iron-ore'},
        ['tree-05'] = {'copper-ore', 'stone'}
    }

    if game.item_prototypes['angels-ore1'] then
        global.entity_yield['tree-01'] = {'angels-ore1', 'angels-ore2'}
        global.entity_yield['tree-02-red'] = {'angels-ore5', 'angels-ore6'}
        global.entity_yield['tree-04'] = {'coal'}
        global.entity_yield['tree-08-brown'] = {'angels-ore3', 'angels-ore4'}
    --else
    --game.map_settings.pollution.ageing = 0
    end

    if game.item_prototypes['thorium-ore'] then
        global.entity_yield['rock-big'] = {'uranium-ore', 'thorium-ore'}
        global.entity_yield['rock-huge'] = {'uranium-ore', 'thorium-ore'}
    end

    local surface = player.surface

    global.average_worm_amount_per_chunk = 2
    global.worm_distance = surface.map_gen_settings.starting_area * 300
    game.forces.player.technologies['landfill'].enabled = false
    game.forces.player.technologies['spidertron'].enabled = false

    if global.choppy_nightmare then
        surface.daytime = 0.5
        surface.freeze_daytime = true
    end

    game.map_settings.pollution.ageing = 0.05

    global.map_init_done = true
end

function choppy_debug()
    if not global.choppy_loaderswon then
        global.choppy_loaderswon = 0
    end
    if not global.choppy_veinsfound then
        global.choppy_veinsfound = 0
    end
    if not global.choppy_wormsdugup then
        global.choppy_wormsdugup = 0
    end
    game.print('veins   found :' .. global.choppy_veinsfound)
    game.print('loaders found :' .. global.choppy_loaderswon)
    game.print('worms  dug up :' .. global.choppy_wormsdugup)
end

local function get_amount(entity)
    local distance_to_center = math.sqrt(entity.position.x ^ 2 + entity.position.y ^ 2)
    local amount = 15 + (distance_to_center * 0.07)

    if global.choppy_nightmare then
        amount = 20 + (distance_to_center * 0.09)
    end

    if amount > 1000 then
        amount = 1000
    end
    amount = math.random(math.ceil(amount * 0.8), math.ceil(amount * 1.2))
    return amount
end

local function trap(entity)
    if math_random(1, 1024) == 1 then
        tick_tack_trap(entity.surface, entity.position)
        return
    end
    if math_random(1, 256) == 1 then
        unearthing_worm(entity.surface, entity.position)
        if not global.choppy_wormsdugup then
            global.choppy_wormsdugup = 0
        end
        global.choppy_wormsdugup = global.choppy_wormsdugup + 1
    end
    if math_random(1, 128) == 1 then
        unearthing_biters(entity.surface, entity.position, math_random(4, 8))
    end
end

local function treasure(player, amount)
    local prizes = {'loader'}

    --if amount > 80 then prizes = {"loader","loader","fast-loader"} end
    --if amount > 160 then prizes = {"loader","fast-loader","fast-loader"} end
    --if amount > 240 then prizes = {"fast-loader"} end
    --if amount > 300 then prizes = {"fast-loader","fast-loader","express-loader"} end
    --if amount > 360 then prizes = {"fast-loader","express-loader"} end
    --if amount > 420 then prizes = {"fast-loader","express-loader","express-loader"} end
    --if amount > 500 then prizes = {"express-loader"} end
    if amount > 500 then
        prizes = {'express-loader'}
    elseif amount > 420 then
        prizes = {'fast-loader', 'express-loader', 'express-loader'}
    elseif amount > 360 then
        prizes = {'fast-loader', 'express-loader'}
    elseif amount > 300 then
        prizes = {'fast-loader', 'fast-loader', 'express-loader'}
    elseif amount > 240 then
        prizes = {'fast-loader'}
    elseif amount > 160 then
        prizes = {'loader', 'fast-loader', 'fast-loader'}
    elseif amount > 80 then
        prizes = {'loader', 'loader', 'fast-loader'}
    end

    local prize = prizes[math_random(1, #prizes)]
    local give = 1

    local inserted_count = player.insert({name = prize, count = give})
    give = give - inserted_count
    if give > 0 then
        player.surface.spill_item_stack(player.position, {name = prize, count = give}, true)
    end

    if not global.choppy_loaderswon then
        global.choppy_loaderswon = 0
    end
    global.choppy_loaderswon = global.choppy_loaderswon + 1

    player.print("You notice a strange device underneath the roots of the tree. It's a " .. prize .. ', talk about lucky!!', {r = 0.98, g = 0.66, b = 0.22})
end

local function generate_treevein(entity, player)
    local surface = entity.surface
    --player.print("hmmmmmmm")
    local p = entity.position
    --local tile_distance_to_center = p.x^2 + p.y^2
    local ore_count = get_amount(entity)
    local mined_loot
    if not global.choppy_nightmare then
        mined_loot = global.entity_yield[entity.name][math_random(1, #global.entity_yield[entity.name])]
    else
        local ore = get_ore_from_entpos(entity)
        --game.print(ore)
        mined_loot = global.entity_yield[ore][math_random(1, #global.entity_yield[ore])]
    end
    --if	ore_count > 40 then
    local radius = 28
    --player.print("checking")
    if
        surface.count_entities_filtered {
            area = {{p.x - radius, p.y - radius}, {p.x + radius, p.y + radius}},
            name = {'iron-ore', 'copper-ore', 'coal', 'stone', 'uranium-ore'},
            limit = 1
        } == 0
     then
        --player.print("yes")
        --local size_raffle = {{"huge", 24, 40},{"big", 16, 28},{"small", 8, 18},{"tiny", 5, 10}}
        local size_raffle = {{'huge', 24, 40}, {'big', 16, 28}, {'small', 8, 18}}
        local size = size_raffle[math_random(1, #size_raffle)]
        player.print("You notice something underneath the roots of the tree. It's a " .. size[1] .. ' vein of ' .. mined_loot .. '!!', {r = 0.98, g = 0.66, b = 0.22})
        --tile_distance_to_center = math.sqrt(tile_distance_to_center)
        local ore_entities_placed = 0
        local modifier_raffle = {{0, -1}, {-1, 0}, {1, 0}, {0, 1}}
        local ores_to_place = math_random(size[2], size[3]) + math.floor(ore_count * 0.040)
        while ore_entities_placed < ores_to_place do
            local a = math.ceil(math_random(ore_count * 14, ore_count * 20) + ore_entities_placed * 8, 0)
            for x = 1, 150, 1 do
                local m = modifier_raffle[math_random(1, #modifier_raffle)]
                local pos = {x = p.x + m[1], y = p.y + m[2]}
                if surface.can_place_entity({name = mined_loot, position = pos, amount = a}) then
                    surface.create_entity {name = mined_loot, position = pos, amount = a}
                    p = pos
                    break
                end
            end
            ore_entities_placed = ore_entities_placed + 1
        end

        if not global.choppy_veinsfound then
            global.choppy_veinsfound = 0
        end
        global.choppy_veinsfound = global.choppy_veinsfound + 1

        return true
    end

    return false
    --end
end

local function on_player_mined_entity(event)
    local entity = event.entity
    if not entity.valid then
        return
    end

    if entity.type == 'tree' then
        trap(entity)
    end

    if global.entity_yield[entity.name] then
        if event.buffer then
            event.buffer.clear()
        end
        if not event.player_index then
            return
        end
        local amount = get_amount(entity)
        local second_item_amount = math_random(2, 5)
        local second_item = 'wood'

        local main_item
        if not global.choppy_nightmare then
            main_item = global.entity_yield[entity.name][math_random(1, #global.entity_yield[entity.name])]
        else
            local ore = get_ore_from_entpos(entity)
            --game.print(ore)
            main_item = global.entity_yield[ore][math_random(1, #global.entity_yield[ore])]
        end

        if entity.type == 'simple-entity' then
            main_item = 'uranium-ore'
            amount = amount * 2
            second_item_amount = math_random(8, 16)
            second_item = 'stone'
        end

        local player = game.players[event.player_index]

        if math_random(1, 200) == 1 then
            if amount > 22 then
                if generate_treevein(entity, player) then
                    return
                end
            end
        else
            local chance = math.ceil(1600 - amount * 0.60)
            if chance < 1100 then
                chance = 1100
            end
            if math_random(1, chance) == 1 then
                if amount > 28 then
                    treasure(player, amount)
                end
            end
        end

        --local main_item = global.entity_yield[entity.name][math_random(1,#global.entity_yield[entity.name])]

        entity.surface.create_entity(
            {
                name = 'flying-text',
                position = entity.position,
                text = '+' .. amount .. ' [item=' .. main_item .. '] +' .. second_item_amount .. ' [item=' .. second_item .. ']',
                color = {r = 0.8, g = 0.8, b = 0.8}
            }
        )

        local inserted_count = player.insert({name = main_item, count = amount})
        amount = amount - inserted_count
        if amount > 0 then
            entity.surface.spill_item_stack(entity.position, {name = main_item, count = amount}, true)
        end

        local inserted_count = player.insert({name = second_item, count = second_item_amount})
        second_item_amount = second_item_amount - inserted_count
        if second_item_amount > 0 then
            entity.surface.spill_item_stack(entity.position, {name = second_item, count = second_item_amount}, true)
        end
    end
end

local function on_research_finished(event)
    local team = event.research.force
    --character_resource_reach_distance_bonus
    --0.1 per lvl of mining_drill_productivity
    --bullet damage ammo modifier starts at 0, progresses 0.1x2 0.2x3 0.4xinfinity
    --10-20-40-60-080-120-160-200+40
    --20-40-60-80-100-120-140-160-180-200
    --bullet speed modifier stats 10x1 20x2 30x2 40x1   10-30-50-80-110-150
    --character_resource_reach_distance_bonus is bonus in tile distance
    --event.research.force.print(game.forces.player.mining_drill_productivity_bonus)
    --event.research.force.print(event.research.force.get_ammo_damage_modifier("bullet"))
    team.character_resource_reach_distance_bonus = math.ceil(team.get_gun_speed_modifier('bullet') * 7)
    team.character_inventory_slots_bonus = math.ceil(team.mining_drill_productivity_bonus * 500)
    if not team.technologies['steel-axe'].researched then
        return
    end
    --event.research.force.manual_mining_speed_modifier = 1 + game.forces.player.mining_drill_productivity_bonus * 2
    team.manual_mining_speed_modifier = 1 + team.get_ammo_damage_modifier('bullet')
end

local function on_entity_died(event)
    on_player_mined_entity(event)

    if not event.entity.valid then
        return
    end
    if event.entity.type == 'tree' then
        for _, entity in pairs(
            event.entity.surface.find_entities_filtered(
                {
                    area = {
                        {event.entity.position.x - 4, event.entity.position.y - 4},
                        {event.entity.position.x + 4, event.entity.position.y + 4}
                    },
                    name = 'fire-flame-on-tree'
                }
            )
        ) do
            if entity.valid then
                entity.destroy()
            end
        end
    end
end

local on_init = function()
    local T = Map.Pop_info()
    T.main_caption = 'Choppy'
    T.sub_caption = ''
    T.text =
        [[
    You are a lumberjack with a passion to chop.

    Different kinds of trees yield different kinds of ore and wood.
    Rocks seem to contain Uranium within the stone.
    The yield you get increases with distance.
    Sometimes you will find good things under them.

    Beware, sometimes there are some bugs hiding underneath the trees.
    Even dangerous traps have been encountered before.

    -Research Buffs-
    Bullet Damage gives a increase in mining speed
    Bullet Speed gives you extra mining reach
    Mining Productivity will give you extra Inventory space

    -Choppy Choppy Wood-
    Senario Created by MewMew - Tweeked By Neko Baron
]]

    T.main_caption_color = {r = 0, g = 120, b = 0}
    T.sub_caption_color = {r = 255, g = 0, b = 255}
    global.chunk_queue = {}
    game.difficulty_settings.technology_price_multiplier = 4
end

Event.on_init(on_init)
Event.on_nth_tick(25, process_chunk_queue)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
