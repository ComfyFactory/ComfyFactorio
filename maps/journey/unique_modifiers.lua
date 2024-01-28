--luacheck: ignore 212/journey
local Get_noise = require 'utils.get_noise'
local BiterRaffle = require 'utils.functions.biter_raffle'
local LootRaffle = require 'utils.functions.loot_raffle'
local math_random = math.random
local math_abs = math.abs
local math_floor = math.floor
local math_sqrt = math.sqrt
local rock_raffle = {'sand-rock-big', 'sand-rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-huge'}
local size_of_rock_raffle = #rock_raffle
local ore_raffle = {}
for i = 1, 25, 1 do
    table.insert(ore_raffle, 'iron-ore')
end
for i = 1, 17, 1 do
    table.insert(ore_raffle, 'copper-ore')
end
for i = 1, 15, 1 do
    table.insert(ore_raffle, 'coal')
end
local size_of_ore_raffle = #ore_raffle
local ore_raffle_2 = {}
for i = 1, 15, 1 do
    table.insert(ore_raffle_2, 'iron-ore')
end
for i = 1, 9, 1 do
    table.insert(ore_raffle_2, 'copper-ore')
end
for i = 1, 7, 1 do
    table.insert(ore_raffle_2, 'coal')
end
for i = 1, 5, 1 do
    table.insert(ore_raffle_2, 'stone')
end
local size_of_ore_raffle_2 = #ore_raffle_2
local rock_yield = {
    ['rock-big'] = 1,
    ['rock-huge'] = 2,
    ['sand-rock-big'] = 1
}
local solid_tiles = {
    ['concrete'] = true,
    ['hazard-concrete-left'] = true,
    ['hazard-concrete-right'] = true,
    ['refined-concrete'] = true,
    ['refined-hazard-concrete-left'] = true,
    ['refined-hazard-concrete-right'] = true,
    ['stone-path'] = true,
    ['lab-dark-1'] = true,
    ['lab-dark-2'] = true
}
local wrecks = {
    'crash-site-spaceship-wreck-big-1',
    'crash-site-spaceship-wreck-big-2',
    'crash-site-spaceship-wreck-medium-1',
    'crash-site-spaceship-wreck-medium-2',
    'crash-site-spaceship-wreck-medium-3'
}
local size_of_wrecks = #wrecks

local tarball_minable = {
    ['entity-ghost'] = true,
    ['tile-ghost'] = true,
    ['container'] = true,
    ['wall'] = true,
    ['gate'] = true,
    ['pipe'] = true,
    ['pipe-to-ground'] = true
}

local Public = {}

Public.lush = {}

Public.eternal_day = {
    on_world_start = function(journey)
        game.surfaces.nauvis.daytime = 0
        game.surfaces.nauvis.freeze_daytime = true
    end,
    clear = function(journey)
        local surface = game.surfaces.nauvis
        surface.freeze_daytime = false
    end
}

Public.eternal_night = {
    on_world_start = function(journey)
        local surface = game.surfaces.nauvis
        surface.daytime = 0.44
        surface.freeze_daytime = true
        surface.solar_power_multiplier = 5
    end,
    clear = function(journey)
        local surface = game.surfaces.nauvis
        surface.freeze_daytime = false
        surface.solar_power_multiplier = 1
    end
}

Public.pitch_black = {
    on_world_start = function(journey)
        local surface = game.surfaces.nauvis
        surface.daytime = 0.44
        surface.freeze_daytime = true
        surface.solar_power_multiplier = 3
        surface.min_brightness = 0
        surface.brightness_visual_weights = {0.8, 0.8, 0.8, 1}
    end,
    clear = function(journey)
        local surface = game.surfaces.nauvis
        surface.freeze_daytime = false
        surface.solar_power_multiplier = 1
        surface.min_brightness = 0.15
        surface.brightness_visual_weights = {0, 0, 0, 1}
    end
}

Public.matter_anomaly = {
    on_world_start = function(journey)
        local force = game.forces.player
        for i = 1, 4, 1 do
            force.technologies['mining-productivity-' .. i].researched = true
        end
        for i = 1, 6, 1 do
            force.technologies['mining-productivity-4'].researched = true
        end
    end,
    on_robot_built_entity = function(event)
        local entity = event.created_entity
        if not entity.valid then
            return
        end
        if entity.surface.index ~= 1 then
            return
        end
        if entity.type == 'electric-turret' then
            entity.die()
        end
    end,
    on_built_entity = function(event)
        local entity = event.created_entity
        if not entity.valid then
            return
        end
        if entity.surface.index ~= 1 then
            return
        end
        if entity.type == 'electric-turret' then
            entity.die()
        end
    end
}

Public.quantum_anomaly = {
    on_world_start = function(journey)
        local force = game.forces.player
        for i = 1, 6, 1 do
            force.technologies['research-speed-' .. i].researched = true
        end
        journey.world_specials['technology_price_multiplier'] = 0.5
    end
}

Public.mountainous = {
    on_world_start = function(journey)
        local force = game.forces.player
        force.character_loot_pickup_distance_bonus = 2
    end,
    on_player_mined_entity = function(event)
        local entity = event.entity
        if not entity.valid then
            return
        end
        if not rock_yield[entity.name] then
            return
        end
        local surface = entity.surface
        event.buffer.clear()
        local ore = ore_raffle[math_random(1, size_of_ore_raffle)]
        local count = math_floor(math_sqrt(entity.position.x ^ 2 + entity.position.y ^ 2) * 0.05) + math_random(25, 75)
        local ore_amount = math_floor(count * 0.85)
        local stone_amount = math_floor(count * 0.15)
        surface.spill_item_stack(entity.position, {name = ore, count = ore_amount}, true)
        surface.spill_item_stack(entity.position, {name = 'stone', count = stone_amount}, true)
    end,
    on_chunk_generated = function(event, journey)
        local surface = event.surface
        local seed = surface.map_gen_settings.seed
        local left_top_x = event.area.left_top.x
        local left_top_y = event.area.left_top.y
        local position
        local noise
        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                if math_random(1, 3) ~= 1 then
                    position = {x = left_top_x + x, y = left_top_y + y}
                    if surface.can_place_entity({name = 'coal', position = position}) then
                        noise = math_abs(Get_noise('scrapyard', position, seed))
                        if noise < 0.025 or noise > 0.50 then
                            surface.create_entity({name = rock_raffle[math_random(1, size_of_rock_raffle)], position = position})
                        end
                    end
                end
            end
        end
    end
}

Public.replicant_fauna = {
    on_entity_died = function(event)
        local entity = event.entity
        if not entity.valid then
            return
        end
        local cause = event.cause
        if not cause then
            return
        end
        if not cause.valid then
            return
        end
        if cause.force.index == 2 then
            cause.surface.create_entity({name = BiterRaffle.roll('mixed', game.forces.enemy.evolution_factor), position = entity.position, force = 'enemy'})
        end
    end
}

Public.tarball = {
    on_robot_built_entity = function(event)
        local entity = event.created_entity
        if not entity.valid then
            return
        end
        if entity.surface.index ~= 1 then
            return
        end
        if tarball_minable[entity.type] then
            return
        end
        entity.minable = false
    end,
    on_built_entity = function(event)
        local entity = event.created_entity
        if not entity.valid then
            return
        end
        if entity.surface.index ~= 1 then
            return
        end
        if tarball_minable[entity.type] then
            return
        end
        entity.minable = false
    end,
    on_chunk_generated = function(event, journey)
        table.insert(
            journey.world_color_filters,
            rendering.draw_sprite(
                {
                    sprite = 'tile/lab-dark-1',
                    x_scale = 32,
                    y_scale = 32,
                    target = event.area.left_top,
                    surface = event.surface,
                    tint = {r = 0.0, g = 0.0, b = 0.0, a = 0.45},
                    render_layer = 'ground'
                }
            )
        )
    end,
    clear = function(journey)
        for _, id in pairs(journey.world_color_filters) do
            rendering.destroy(id)
        end
        journey.world_color_filters = {}
    end
}

Public.swamps = {
    set_specials = function(journey)
        journey.world_specials['water'] = 2
    end,
    on_chunk_generated = function(event, journey)
        local surface = event.surface
        local seed = surface.map_gen_settings.seed
        local left_top_x = event.area.left_top.x
        local left_top_y = event.area.left_top.y

        local tiles = {}
        for _, tile in pairs(surface.find_tiles_filtered({name = {'water', 'deepwater'}, area = event.area})) do
            table.insert(tiles, {name = 'water-shallow', position = tile.position})
        end

        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                local position = {x = left_top_x + x, y = left_top_y + y}
                local noise = Get_noise('journey_swamps', position, seed)
                if noise > 0.45 or noise < -0.65 then
                    table.insert(tiles, {name = 'water-shallow', position = {x = position.x, y = position.y}})
                end
            end
        end
        surface.set_tiles(tiles, true, false, false, false)

        for _, tile in pairs(tiles) do
            if math_random(1, 32) == 1 then
                surface.create_entity({name = 'fish', position = tile.position})
            end
        end
    end
}

Public.wasteland = {
    on_chunk_generated = function(event, journey)
        local surface = event.surface
        local left_top_x = event.area.left_top.x
        local left_top_y = event.area.left_top.y
        local tiles = {}
        for _, tile in pairs(surface.find_tiles_filtered({name = {'water'}, area = event.area})) do
            table.insert(tiles, {name = 'water-green', position = tile.position})
        end
        for _, tile in pairs(surface.find_tiles_filtered({name = {'deepwater'}, area = event.area})) do
            table.insert(tiles, {name = 'deepwater-green', position = tile.position})
        end
        surface.set_tiles(tiles, true, false, false, false)
        if math_random(1, 3) ~= 1 then
            return
        end
        for _ = 1, math_random(0, 5), 1 do
            local name = wrecks[math_random(1, size_of_wrecks)]
            local position = surface.find_non_colliding_position(name, {left_top_x + math_random(0, 31), left_top_y + math_random(0, 31)}, 16, 1)
            if position then
                local e = surface.create_entity({name = name, position = position, force = 'neutral'})
                if math_random(1, 4) == 1 then
                    local slots = game.entity_prototypes[e.name].get_inventory_size(defines.inventory.chest)
                    local blacklist = LootRaffle.get_tech_blacklist(0.2)
                    local item_stacks = LootRaffle.roll(math_random(16, 64), slots, blacklist)
                    for _, item_stack in pairs(item_stacks) do
                        e.insert(item_stack)
                    end
                end
            end
        end
    end,
    on_world_start = function(journey)
        local surface = game.surfaces.nauvis
        local mgs = surface.map_gen_settings
        mgs.terrain_segmentation = 2.7
        mgs.water = mgs.water + 1
        surface.map_gen_settings = mgs
        surface.clear(true)
    end,
    clear = function(journey)
        local surface = game.surfaces.nauvis
        local mgs = surface.map_gen_settings
        mgs.water = mgs.water - 1
        surface.map_gen_settings = mgs
    end
}

Public.oceanic = {
    on_world_start = function(journey)
        local surface = game.surfaces.nauvis
        local mgs = surface.map_gen_settings
        mgs.terrain_segmentation = 0.5
        mgs.water = mgs.water + 6
        surface.map_gen_settings = mgs
        surface.clear(true)
    end,
    on_robot_built_entity = function(event)
        local entity = event.created_entity
        if not entity.valid then
            return
        end
        if entity.surface.index ~= 1 then
            return
        end
        if entity.type == 'fluid-turret' then
            entity.die()
        end
    end,
    on_built_entity = function(event)
        local entity = event.created_entity
        if not entity.valid then
            return
        end
        if entity.surface.index ~= 1 then
            return
        end
        if entity.type == 'fluid-turret' then
            entity.die()
        end
    end,
    clear = function(journey)
        local surface = game.surfaces.nauvis
        local mgs = surface.map_gen_settings
        mgs.water = mgs.water - 6
        surface.map_gen_settings = mgs
    end
}

Public.volcanic = {
    on_chunk_generated = function(event, journey)
        table.insert(
            journey.world_color_filters,
            rendering.draw_sprite(
                {
                    sprite = 'tile/lab-dark-2',
                    x_scale = 32,
                    y_scale = 32,
                    target = event.area.left_top,
                    surface = event.surface,
                    tint = {r = 0.55, g = 0.0, b = 0.0, a = 0.25},
                    render_layer = 'ground'
                }
            )
        )
    end,
    on_player_changed_position = function(event)
        local player = game.players[event.player_index]
        if player.driving then
            return
        end
        local surface = player.surface
        if surface.index ~= 1 then
            return
        end
        if solid_tiles[surface.get_tile(player.position).name] then
            return
        end
        surface.create_entity({name = 'fire-flame', position = player.position})
    end,
    on_world_start = function(journey)
        local surface = game.surfaces.nauvis
        surface.request_to_generate_chunks({x = 0, y = 0}, 3)
        surface.force_generate_chunk_requests()
        surface.spill_item_stack({0, 0}, {name = 'stone-brick', count = 4096}, true)
        for x = -24, 24, 1 do
            for y = -24, 24, 1 do
                if math.sqrt(x ^ 2 + y ^ 2) < 24 then
                    surface.set_tiles({{name = 'stone-path', position = {x, y}}}, true)
                end
            end
        end
    end,
    clear = function(journey)
        for _, id in pairs(journey.world_color_filters) do
            rendering.destroy(id)
        end
        journey.world_color_filters = {}
    end
}

Public.chaotic_resources = {
    on_chunk_generated = function(event, journey)
        local surface = event.surface
        for _, ore in pairs(surface.find_entities_filtered({area = event.area, name = {'iron-ore', 'copper-ore', 'coal', 'stone'}})) do
            surface.create_entity({name = ore_raffle_2[math_random(1, size_of_ore_raffle_2)], position = ore.position, amount = ore.amount})
            ore.destroy()
        end
    end
}

Public.infested = {
    on_chunk_generated = function(event, journey)
        table.insert(
            journey.world_color_filters,
            rendering.draw_sprite(
                {
                    sprite = 'tile/lab-dark-2',
                    x_scale = 32,
                    y_scale = 32,
                    target = event.area.left_top,
                    surface = event.surface,
                    tint = {r = 0.8, g = 0.0, b = 0.8, a = 0.25},
                    render_layer = 'ground'
                }
            )
        )
    end,
    set_specials = function(journey)
        journey.world_specials['trees_size'] = 4
        journey.world_specials['trees_richness'] = 2
        journey.world_specials['trees_frequency'] = 2
    end,
    clear = function(journey)
        for _, id in pairs(journey.world_color_filters) do
            rendering.destroy(id)
        end
        journey.world_color_filters = {}
    end,
    on_entity_died = function(event)
        local entity = event.entity
        if not entity.valid then
            return
        end
        if entity.force.index ~= 3 then
            return
        end
        if entity.type ~= 'simple-entity' and entity.type ~= 'tree' then
            return
        end
        entity.surface.create_entity({name = BiterRaffle.roll('mixed', game.forces.enemy.evolution_factor + 0.1), position = entity.position, force = 'enemy'})
    end,
    on_player_mined_entity = function(event)
        if math_random(1, 2) == 1 then
            return
        end
        local entity = event.entity
        if not entity.valid then
            return
        end
        if entity.force.index ~= 3 then
            return
        end
        if entity.type ~= 'simple-entity' and entity.type ~= 'tree' then
            return
        end
        entity.surface.create_entity({name = BiterRaffle.roll('mixed', game.forces.enemy.evolution_factor + 0.1), position = entity.position, force = 'enemy'})
    end,
    on_robot_mined_entity = function(event)
        local entity = event.entity
        if not entity.valid then
            return
        end
        if entity.force.index ~= 3 then
            return
        end
        if entity.type ~= 'simple-entity' and entity.type ~= 'tree' then
            return
        end
        entity.surface.create_entity({name = BiterRaffle.roll('mixed', game.forces.enemy.evolution_factor + 0.1), position = entity.position, force = 'enemy'})
    end
}

Public.undead_plague = {
    on_entity_died = function(event)
        local entity = event.entity
        if not entity.valid then
            return
        end
        if entity.force.index ~= 2 then
            return
        end
        if math_random(1, 2) == 1 then
            return
        end
        if entity.type ~= 'unit' then
            return
        end
        entity.surface.create_entity({name = entity.name, position = entity.position, force = 'enemy'})
    end
}

Public.low_mass = {
    on_world_start = function(journey)
        local force = game.forces.player
        force.character_running_speed_modifier = 0.5
        for i = 1, 6, 1 do
            force.technologies['worker-robots-speed-' .. i].researched = true
        end
    end
}

Public.dense_atmosphere = {
    on_robot_built_entity = function(event)
        local entity = event.created_entity
        if not entity.valid then
            return
        end
        if entity.surface.index ~= 1 then
            return
        end
        if entity.type == 'roboport' then
            entity.die()
        end
    end,
    on_built_entity = function(event)
        local entity = event.created_entity
        if not entity.valid then
            return
        end
        if entity.surface.index ~= 1 then
            return
        end
        if entity.type == 'roboport' then
            entity.die()
        end
    end
}

local function update_lazy_bastard(journey, count)
    journey.lazy_bastard_machines = journey.lazy_bastard_machines + count
    local speed = journey.lazy_bastard_machines * -0.1
    if speed < -1 then
        speed = -1
    end
    game.forces.player.manual_crafting_speed_modifier = speed
end

Public.lazy_bastard = {
    on_robot_built_entity = function(event, journey)
        local entity = event.created_entity
        if not entity.valid then
            return
        end
        if entity.surface.index ~= 1 then
            return
        end
        if entity.type == 'assembling-machine' then
            update_lazy_bastard(journey, 1)
        end
    end,
    on_built_entity = function(event, journey)
        local entity = event.created_entity
        if not entity.valid then
            return
        end
        if entity.surface.index ~= 1 then
            return
        end
        if entity.type == 'assembling-machine' then
            update_lazy_bastard(journey, 1)
        end
    end,
    on_entity_died = function(event, journey)
        local entity = event.entity
        if not entity.valid then
            return
        end
        if entity.surface.index ~= 1 then
            return
        end
        if entity.type == 'assembling-machine' then
            update_lazy_bastard(journey, -1)
        end
    end,
    on_player_mined_entity = function(event, journey)
        local entity = event.entity
        if not entity.valid then
            return
        end
        if entity.surface.index ~= 1 then
            return
        end
        if entity.type == 'assembling-machine' then
            update_lazy_bastard(journey, -1)
        end
    end,
    on_robot_mined_entity = function(event, journey)
        local entity = event.entity
        if not entity.valid then
            return
        end
        if entity.surface.index ~= 1 then
            return
        end
        if entity.type == 'assembling-machine' then
            update_lazy_bastard(journey, -1)
        end
    end,
    on_world_start = function(journey)
        journey.lazy_bastard_machines = 0
    end,
    clear = function(journey)
        game.forces.player.manual_crafting_speed_modifier = 0
    end
}

Public.ribbon = {
    on_chunk_generated = function(event, journey)
        local surface = event.surface
        local left_top_x = event.area.left_top.x
        local left_top_y = event.area.left_top.y
        if (left_top_x + left_top_y) ^ 2 <= 256 then
            local oils = surface.count_entities_filtered {name = 'crude-oil', position = {x = 0, y = 0}, radius = 256}
            if math.random(1, 10 + oils * 10) == 1 then
                local pos = surface.find_non_colliding_position_in_box('oil-refinery', event.area, 0.1, true)
                if pos then
                    surface.create_entity({name = 'crude-oil', position = pos, amount = 60000})
                end
            end
        end
    end,
    on_world_start = function(journey)
        local surface = game.surfaces.nauvis
        local mgs = surface.map_gen_settings
        mgs.height = 256
        surface.map_gen_settings = mgs
        surface.clear(true)
    end,
    clear = function(journey)
        local surface = game.surfaces.nauvis
        local mgs = surface.map_gen_settings
        mgs.height = nil
        surface.map_gen_settings = mgs
    end
}

Public.abandoned_library = {
    on_world_start = function(journey)
        game.permissions.get_group('Default').set_allows_action(defines.input_action.open_blueprint_library_gui, false)
        game.permissions.get_group('Default').set_allows_action(defines.input_action.import_blueprint_string, false)
    end,
    clear = function(journey)
        game.permissions.get_group('Default').set_allows_action(defines.input_action.open_blueprint_library_gui, true)
        game.permissions.get_group('Default').set_allows_action(defines.input_action.import_blueprint_string, true)
    end
}

Public.railworld = {
    set_specials = function(journey)
        journey.world_specials['ore_size'] = 4
        journey.world_specials['ore_frequency'] = 0.25
        journey.world_specials['coal'] = 4
        journey.world_specials['stone'] = 4
        journey.world_specials['copper-ore'] = 4
        journey.world_specials['iron-ore'] = 4
        journey.world_specials['uranium-ore'] = 4
        journey.world_specials['crude-oil'] = 4
        journey.world_specials['enemy_base_frequency'] = 0.25
        journey.world_specials['enemy_base_size'] = 2
        journey.world_specials['enemy_base_richness'] = 2
        journey.world_specials['water'] = 1.5
        journey.world_specials['starting_area'] = 3
    end
}

local delivery_options = {
    'solar-panel',
    'beacon',
    'assembling-machine-3',
    'low-density-structure',
    'heat-pipe',
    'express-transport-belt',
    'logistic-robot',
    'power-armor'
}

Public.resupply_station = {
    on_world_start = function(journey)
        local pick = delivery_options[math.random(1, #delivery_options)]
        journey.speedrun = {enabled = true, time = 0, item = pick}
        journey.mothership_cargo_space[pick] = game.item_prototypes[pick].stack_size
    end,
    clear = function(journey)
        journey.mothership_cargo_space[journey.speedrun.item] = nil
        journey.mothership_cargo[journey.speedrun.item] = 0
        journey.speedrun.enabled = false
    end
}

Public.crazy_science = {
    set_specials = function(journey)
        journey.world_specials['technology_price_multiplier'] = 50
        journey.world_specials['starting_area'] = 3
        journey.world_specials['copper-ore'] = 2
        journey.world_specials['iron-ore'] = 4
    end,
    on_world_start = function(journey)
        game.forces.player.laboratory_productivity_bonus = 5
        game.forces.player.laboratory_speed_modifier = 10
    end,
    on_research_finished = function(event, journey)
        local name = 'technology_price_multiplier'
        local force = event.research.force
        journey.world_specials[name] = math.max(0.1, journey.world_specials[name] * 0.95)
        game.difficulty_settings.technology_price_multiplier = journey.world_modifiers[name] * (journey.world_specials[name] or 1)
        force.laboratory_productivity_bonus = math.max(0.1, force.laboratory_productivity_bonus * 0.95)
    end
}

return Public
