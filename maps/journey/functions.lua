--luacheck: ignore
local Map_functions = require 'utils.tools.map_functions'
local Server = require 'utils.server'
local Get_noise = require 'utils.get_noise'
local Autostash = require 'modules.autostash'
local Misc = require 'utils.commands.misc'
local BottomFrame = require 'utils.gui.bottom_frame'
local Constants = require 'maps.journey.constants'
local Unique_modifiers = require 'maps.journey.unique_modifiers'
local Vacants = require 'modules.clear_vacant_players'
local math_sqrt = math.sqrt
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs

local Public = {}
local mixed_ores = {'copper-ore', 'iron-ore', 'stone', 'coal'}

local function clear_selectors(journey)
    for k, world_selector in pairs(journey.world_selectors) do
        for _, ID in pairs(world_selector.texts) do
            rendering.destroy(ID)
        end
        journey.world_selectors[k].texts = {}
        journey.world_selectors[k].activation_level = 0
    end
    for _, ID in pairs(journey.reroll_selector.texts) do
        rendering.destroy(ID)
    end
    journey.reroll_selector.texts = {}
    journey.reroll_selector.activation_level = 0
end

local function protect(entity, operable)
    entity.minable = false
    entity.destructible = false
    entity.operable = operable
end

function Public.place_mixed_ore(event, journey)
    if math_random(1, 192) ~= 1 then
        return
    end
    local surface = event.surface
    local x = event.area.left_top.x + math_random(0, 31)
    local y = event.area.left_top.y + math_random(0, 31)
    local base_amount = 1000 + math_sqrt(x ^ 2 + y ^ 2) * 5
    local richness = journey.mixed_ore_richness
    Map_functions.draw_rainbow_patch({x = x, y = y}, surface, math_random(17, 22), base_amount * richness + 100)
end

local function place_teleporter(journey, surface, position, build_beacon)
    local tiles = {}
    for x = -2, 2, 1 do
        for y = -2, 2, 1 do
            local pos = {x = position.x + x, y = position.y + y}
            table.insert(tiles, {name = Constants.teleporter_tile, position = pos})
        end
    end
    surface.set_tiles(tiles, false)
    surface.create_entity({name = 'electric-beam-no-sound', position = position, source = {x = position.x - 1.5, y = position.y - 1.5}, target = {x = position.x + 2.5, y = position.y - 1.0}})
    surface.create_entity({name = 'electric-beam-no-sound', position = position, source = {x = position.x + 2.5, y = position.y - 1.5}, target = {x = position.x + 2.5, y = position.y + 3.0}})
    surface.create_entity({name = 'electric-beam-no-sound', position = position, source = {x = position.x + 2.5, y = position.y + 2.5}, target = {x = position.x - 1.5, y = position.y + 3.0}})
    surface.create_entity({name = 'electric-beam-no-sound', position = position, source = {x = position.x - 1.5, y = position.y + 2.5}, target = {x = position.x - 1.5, y = position.y - 1.0}})
    surface.destroy_decoratives({area = {{position.x - 3, position.y - 3}, {position.x + 3, position.y + 3}}})
    if build_beacon then
        local beacon = surface.create_entity({name = 'beacon', position = {x = position.x, y = position.y}, force = 'player'})
        journey.beacon_objective_health = 10000
        beacon.operable = false
        beacon.minable = false
        beacon.active = false
        rendering.draw_text {
            text = {'journey.teleporter'},
            surface = surface,
            target = beacon,
            target_offset = {0, -1.5},
            color = {0, 1, 0},
            scale = 0.90,
            font = 'default-game',
            alignment = 'center',
            scale_with_zoom = false
        }
        local hp =
            rendering.draw_text {
            text = {'journey.beacon_hp', journey.beacon_objective_health},
            surface = surface,
            target = beacon,
            target_offset = {0, -1.0},
            color = {0, 1, 0},
            scale = 0.90,
            font = 'default-game',
            alignment = 'center',
            scale_with_zoom = false
        }
        journey.beacon_objective = beacon
        journey.beacon_objective_hp_label = hp
    end
end

local function destroy_teleporter(journey, surface, position)
    local tiles = {}
    for x = -2, 2, 1 do
        for y = -2, 2, 1 do
            local pos = {x = position.x + x, y = position.y + y}
            table.insert(tiles, {name = 'lab-dark-1', position = pos})
        end
    end
    surface.set_tiles(tiles, true)
    for _, e in pairs(surface.find_entities_filtered({name = 'electric-beam-no-sound', area = {{position.x - 3, position.y - 3}, {position.x + 3, position.y + 3}}})) do
        e.destroy()
    end
end

local function drop_player_items(journey, player)
    local character = player.character
    if not character then
        return
    end
    if not character.valid then
        return
    end

    player.clear_cursor()

    for i = 1, player.crafting_queue_size, 1 do
        if player.crafting_queue_size > 0 then
            player.cancel_crafting {index = 1, count = 99999999}
        end
    end

    local surface = player.surface
    local spill_blockage = surface.create_entity {name = 'oil-refinery', position = journey.beacon_objective.position or player.position}

    for _, define in pairs({defines.inventory.character_main, defines.inventory.character_guns, defines.inventory.character_ammo, defines.inventory.character_armor, defines.inventory.character_vehicle, defines.inventory.character_trash}) do
        local inventory = character.get_inventory(define)
        if inventory and inventory.valid then
            for i = 1, #inventory, 1 do
                local slot = inventory[i]
                if slot.valid and slot.valid_for_read then
                    surface.spill_item_stack(player.position, slot, true, nil, false)
                end
            end
            inventory.clear()
        end
    end

    spill_blockage.destroy()
end

function Public.clear_player(player)
    local character = player.character
    if not character then
        return
    end
    if not character.valid then
        return
    end
    player.character.destroy()
    player.set_controller({type = defines.controllers.god})
    player.create_character()
    player.clear_items_inside()
end

local function remove_offline_players(maximum_age_in_hours)
    local maximum_age_in_ticks = maximum_age_in_hours * 216000
    local t = game.tick - maximum_age_in_ticks
    if t < 0 then
        return
    end
    local players_to_remove = {}
    for _, player in pairs(game.players) do
        if player.last_online < t then
            table.insert(players_to_remove, player)
        end
    end
    game.remove_offline_players(players_to_remove)
end

local function calc_modifier(journey, name)
    return journey.world_modifiers[name] * (journey.world_specials[name] or 1)
end

local function set_map_modifiers(journey)
    local mgs = game.surfaces.nauvis.map_gen_settings
    for _, name in pairs({'iron-ore', 'copper-ore', 'uranium-ore', 'coal', 'stone', 'crude-oil'}) do
        mgs.autoplace_controls[name].richness = calc_modifier(journey, name)
        mgs.autoplace_controls[name].size = calc_modifier(journey, 'ore_size')
        mgs.autoplace_controls[name].frequency = calc_modifier(journey, 'ore_frequency')
    end
    journey.mixed_ore_richness = calc_modifier(journey, 'mixed_ore')

    mgs.autoplace_controls['trees'].richness = calc_modifier(journey, 'trees_richness')
    mgs.autoplace_controls['trees'].size = calc_modifier(journey, 'trees_size')
    mgs.autoplace_controls['trees'].frequency = calc_modifier(journey, 'trees_frequency')
    mgs.autoplace_controls['enemy-base'].richness = calc_modifier(journey, 'enemy_base_richness')
    mgs.autoplace_controls['enemy-base'].size = calc_modifier(journey, 'enemy_base_size')
    mgs.autoplace_controls['enemy-base'].frequency = calc_modifier(journey, 'enemy_base_frequency')
    mgs.starting_area = calc_modifier(journey, 'starting_area')
    mgs.cliff_settings.cliff_elevation_interval = calc_modifier(journey, 'cliff_frequency')
    mgs.cliff_settings.richness = calc_modifier(journey, 'cliff_continuity')
    mgs.water = calc_modifier(journey, 'water')
    game.map_settings.enemy_evolution['time_factor'] = calc_modifier(journey, 'time_factor')
    game.map_settings.enemy_evolution['destroy_factor'] = calc_modifier(journey, 'destroy_factor')
    game.map_settings.enemy_evolution['pollution_factor'] = calc_modifier(journey, 'pollution_factor')
    game.map_settings.enemy_expansion.min_expansion_cooldown = calc_modifier(journey, 'expansion_cooldown')
    game.map_settings.enemy_expansion.max_expansion_cooldown = calc_modifier(journey, 'expansion_cooldown') * 4
    game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = calc_modifier(journey, 'enemy_attack_pollution_consumption_modifier')
    game.map_settings.pollution.ageing = calc_modifier(journey, 'ageing')
    game.map_settings.pollution.diffusion_ratio = calc_modifier(journey, 'diffusion_ratio')
    game.map_settings.pollution.min_pollution_to_damage_trees = calc_modifier(journey, 'tree_durability') * 6
    game.map_settings.pollution.pollution_restored_per_tree_damage = calc_modifier(journey, 'tree_durability')
    game.map_settings.unit_group.max_unit_group_size = calc_modifier(journey, 'max_unit_group_size')
    game.difficulty_settings.technology_price_multiplier = calc_modifier(journey, 'technology_price_multiplier')
    game.surfaces.nauvis.map_gen_settings = mgs
end

--raw == true returns directly the number
--raw == false returs ratio compared to default
local function get_modifier(name, journey, raw)
    local value = calc_modifier(journey, name)
    if raw then
        return value
    else
        return value * (1 / (Constants.modifiers[name].base or 1))
    end
end

local function delete_nauvis_chunks(journey)
    local surface = game.surfaces.nauvis
    if not journey.nauvis_chunk_positions then
        journey.nauvis_chunk_positions = {}
        for chunk in surface.get_chunks() do
            table.insert(journey.nauvis_chunk_positions, {chunk.x, chunk.y})
        end
        journey.size_of_nauvis_chunk_positions = #journey.nauvis_chunk_positions
        for _, e in pairs(surface.find_entities_filtered {type = 'radar'}) do
            e.destroy()
        end
        for _, player in pairs(game.players) do
            local button = player.gui.top.add({type = 'sprite-button', name = 'chunk_progress', caption = ''})
            button.style.font = 'heading-1'
            button.style.font_color = {222, 222, 222}
            button.style.minimal_height = 38
            button.style.maximal_height = 38
            button.style.minimal_width = 240
            button.style.padding = -2
        end
    end

    if journey.size_of_nauvis_chunk_positions == 0 then
        return
    end

    for c = 1, 12, 1 do
        local chunk_position = journey.nauvis_chunk_positions[journey.size_of_nauvis_chunk_positions]
        if chunk_position then
            surface.delete_chunk(chunk_position)
            journey.size_of_nauvis_chunk_positions = journey.size_of_nauvis_chunk_positions - 1
        else
            break
        end
    end

    local caption = {'journey.chunks_delete', journey.size_of_nauvis_chunk_positions}
    for _, player in pairs(game.connected_players) do
        if player.gui.top.chunk_progress then
            player.gui.top.chunk_progress.caption = caption
        end
    end
    return true
end

function Public.mothership_message_queue(journey)
    local text = journey.mothership_messages[1]
    if not text then
        return
    end
    if text ~= '' then
        game.print({'journey.mothership_format', text})
    end
    table.remove(journey.mothership_messages, 1)
end

function Public.deny_building(event)
    local entity = event.created_entity
    if not entity.valid then
        return
    end
    if entity.surface.name ~= 'mothership' then
        return
    end
    if Constants.build_type_whitelist[entity.type] then
        entity.destructible = false
        return
    end
    entity.die()
end

function Public.register_built_silo(event, journey)
    local entity = event.created_entity
    if not entity.valid then
        return
    end
    if entity.surface.index ~= 1 then
        return
    end
    if entity.type ~= 'rocket-silo' then
        return
    end
    entity.auto_launch = false
    table.insert(journey.rocket_silos, entity)
end

local function cargo_gui(name, itemname, tooltip, value, hidden)
    for _, player in pairs(game.connected_players) do
        if not player.gui.top[name] then
            local frame = player.gui.top.add({type = 'frame', name = name})
            frame.style.left_margin = 0
            frame.style.padding = 0
            local sprite = frame.add({type = 'sprite', sprite = 'item/' .. itemname, name = name .. '_sprite', resize_to_sprite = false})
            sprite.style.minimal_width = 28
            sprite.style.minimal_height = 28
            sprite.style.maximal_width = 28
            sprite.style.maximal_height = 28
            sprite.style.margin = 0
            sprite.style.padding = 0
            local progressbar = frame.add({type = 'progressbar', name = name .. '_progressbar', value = 0})
            progressbar.style = 'achievement_progressbar'
            progressbar.style.minimal_width = 100
            progressbar.style.maximal_width = 100
            progressbar.style.top_margin = 2
            progressbar.style.right_margin = 6
        end
        local frame = player.gui.top[name]
        frame.tooltip = tooltip
        local sprite = player.gui.top[name][name .. '_sprite']
        sprite.sprite = 'item/' .. itemname
        sprite.tooltip = tooltip
        local progressbar = player.gui.top[name][name .. '_progressbar']
        progressbar.value = value
        progressbar.tooltip = tooltip
        if hidden then
            frame.visible = false
        else
            frame.visible = true
        end
    end
end

function Public.update_tooltips(journey)
    local modiftt = {''}
    for k, v in pairs(Constants.modifiers) do
        modiftt = {'', modiftt, {'journey.tooltip_modifier', v.name, math.round(get_modifier(k, journey) * 100)}}
    end
    journey.tooltip_modifiers = modiftt

    local capsulett = {''}
    local c = 0
    for k, v in pairs(journey.bonus_goods) do
        local str = '    '
        local v2 = tostring(v)
        v = string.sub(str, 1, -string.len(v2)) .. v2
        c = c + 1
        if c % 3 == 0 then
            capsulett = {'', capsulett, {'journey.tooltip_capsule2', v, k}}
        else
            capsulett = {'', capsulett, {'journey.tooltip_capsule', v, k}}
        end
    end
    journey.tooltip_capsules = capsulett
end

function Public.draw_gui(journey)
    local surface = game.surfaces.nauvis
    local mgs = surface.map_gen_settings
    local caption = {'journey.world', journey.world_number, Constants.unique_world_traits[journey.world_trait].name}
    local tooltip = {'journey.world_tooltip', Constants.unique_world_traits[journey.world_trait].desc, journey.tooltip_modifiers, journey.tooltip_capsules}

    for _, player in pairs(game.connected_players) do
        if not player.gui.top.journey_button then
            local element = player.gui.top.add({type = 'sprite-button', name = 'journey_button', caption = ''})
            element.style.font = 'heading-1'
            element.style.font_color = {222, 222, 222}
            element.style.minimal_height = 38
            element.style.maximal_height = 38
            element.style.minimal_width = 250
            element.style.padding = -2
        end
        local gui = player.gui.top.journey_button
        gui.caption = caption
        gui.tooltip = tooltip
    end

    local fuel_requirement = journey.mothership_cargo_space['uranium-fuel-cell']
    local value
    if fuel_requirement == 0 then
        value = 1
    else
        value = journey.mothership_cargo['uranium-fuel-cell'] / fuel_requirement
    end
    cargo_gui('journey_fuel', 'uranium-fuel-cell', {'journey.tooltip_fuel', fuel_requirement, journey.mothership_cargo['uranium-fuel-cell']}, value)

    local max_satellites = journey.mothership_cargo_space['satellite']
    local value2 = journey.mothership_cargo['satellite'] / max_satellites
    cargo_gui('journey_satellites', 'satellite', {'journey.tooltip_satellite', journey.mothership_cargo['satellite'], max_satellites}, value2)

    local max_emergency_fuel = journey.mothership_cargo_space['nuclear-reactor']
    local value3 = journey.mothership_cargo['nuclear-reactor'] / max_emergency_fuel
    cargo_gui('journey_emergency', 'nuclear-reactor', {'journey.tooltip_nuclear_fuel', journey.mothership_cargo['nuclear-reactor'], max_emergency_fuel}, value3)

    local item = journey.speedrun.item
    local time = math.round(journey.speedrun.time / 6) / 10
    local speedgoal = journey.mothership_cargo_space[item] or 1
    local value4 = (journey.mothership_cargo[item] or 0) / speedgoal
    if journey.speedrun.enabled then
        cargo_gui('journey_delivery', item, {'journey.tooltip_delivery', journey.mothership_cargo[item] or 0, speedgoal, time}, value4)
    else
        cargo_gui('journey_delivery', item, {'journey.tooltip_delivery', journey.mothership_cargo[item] or 0, speedgoal, time}, value4, true)
    end
end

local function is_mothership(position)
    if math.abs(position.x) > Constants.mothership_radius then
        return false
    end
    if math.abs(position.y) > Constants.mothership_radius then
        return false
    end
    local p = {x = position.x, y = position.y}
    if p.x > 0 then
        p.x = p.x + 1
    end
    if p.y > 0 then
        p.y = p.y + 1
    end
    local d = math.sqrt(p.x ^ 2 + p.y ^ 2)
    if d < Constants.mothership_radius then
        return true
    end
end

function Public.on_mothership_chunk_generated(event)
    local left_top = event.area.left_top
    local surface = event.surface
    local seed = surface.map_gen_settings.seed
    local tiles = {}
    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local position = {x = left_top.x + x, y = left_top.y + y}
            if is_mothership(position) then
                table.insert(tiles, {name = 'black-refined-concrete', position = position})
            else
                table.insert(tiles, {name = 'out-of-map', position = position})
            end
        end
    end
    surface.set_tiles(tiles, true)
end

function Public.export_journey(journey, import_flag)
    local data = {
        world_number = journey.world_number,
        world_modifiers = journey.world_modifiers,
        bonus_goods = journey.bonus_goods,
        world_selectors = journey.world_selectors,
        mothership_cargo = journey.mothership_cargo,
        mothership_cargo_space = journey.mothership_cargo_space
    }
    local secs = Server.get_current_time()
    if not secs then
        return
    else
        Server.set_data('scenario_settings', 'journey_data', data)
        Server.set_data('scenario_settings', 'journey_updating', import_flag)
        game.print('Journey data exported...')
    end
end

function Public.import_journey(journey)
    local state = journey.game_state
    if state == 'world' or state == 'dispatch_goods' or state == 'mothership_waiting_for_players' then
        log('Can run import command only during world selection stages')
        return
    end
    local secs = Server.get_current_time()
    if not secs then
        return
    else
        Server.try_get_data('scenario_settings', 'journey_data', journey.import)
        Server.set_data('scenario_settings', 'journey_updating', false)
    end
end

local function check_if_restarted(journey)
    local secs = Server.get_current_time()
    if not secs or journey.import_checked then
        return
    else
        Server.try_get_data('scenario_settings', 'journey_updating', journey.check_import)
    end
end

function Public.restart_server(journey)
    local state = journey.game_state
    if state == 'world' or state == 'dispatch_goods' or state == 'mothership_waiting_for_players' then
        log('Can force restart only during world selection stages')
        return
    end
    game.print({'journey.cmd_server_restarting'}, {r = 255, g = 255, b = 0})
    Public.export_journey(journey, true)
    Server.start_scenario('Journey')
    return
end

function Public.hard_reset(journey)
    if journey.restart_from_scenario then
        game.print({'journey.cmd_server_restarting'}, {r = 255, g = 255, b = 0})
        Public.export_journey(journey, false)
        Server.start_scenario('Journey')
        return
    end
    Vacants.reset()
    BottomFrame.activate_custom_buttons(true)
    BottomFrame.reset()
    Autostash.insert_into_furnace(true)
    Autostash.bottom_button(true)
    Misc.bottom_button(true)
    if game.surfaces.mothership and game.surfaces.mothership.valid then
        game.delete_surface(game.surfaces.mothership)
    end

    game.forces.enemy.character_inventory_slots_bonus = 9999

    game.map_settings.enemy_expansion.enabled = true
    game.map_settings.enemy_expansion.max_expansion_distance = 20
    game.map_settings.enemy_expansion.settler_group_min_size = 5
    game.map_settings.enemy_expansion.settler_group_max_size = 50

    game.map_settings.pollution.enabled = true
    game.map_settings.pollution.min_to_diffuse = 75
    game.map_settings.pollution.expected_max_per_chunk = 300

    game.map_settings.enemy_expansion.max_expansion_distance = 5 --default 7
    game.map_settings.enemy_expansion.friendly_base_influence_radius = 1 --default 2
    game.map_settings.enemy_expansion.enemy_building_influence_radius = 5 --default 2
    game.map_settings.enemy_expansion.building_coefficient = 0.02 --default 0.1
    game.map_settings.enemy_expansion.neighbouring_chunk_coefficient = 0.25 --defualt 0.5
    game.map_settings.enemy_expansion.neighbouring_base_chunk_coefficient = 0.25 --default 0.4

    local surface = game.surfaces[1]

    surface.clear(true)
    surface.daytime = math.random(1, 100) * 0.01

    if journey.world_selectors and journey.world_selectors[1].border then
        for k, world_selector in pairs(journey.world_selectors) do
            for _, ID in pairs(world_selector.rectangles) do
                rendering.destroy(ID)
            end
            rendering.destroy(world_selector.border)
        end
    end

    journey.world_selectors = {}
    journey.reroll_selector = {activation_level = 0}
    for i = 1, 3, 1 do
        journey.world_selectors[i] = {activation_level = 0, texts = {}}
    end
    journey.mothership_speed = 0.5
    journey.characters_in_mothership = 0
    journey.world_color_filters = {}
    journey.mixed_ore_richness = 1
    journey.mothership_messages = {}
    journey.mothership_cargo = {}
    journey.mothership_cargo['uranium-fuel-cell'] = 10
    journey.mothership_cargo['satellite'] = 1
    journey.mothership_cargo['nuclear-reactor'] = 60
    journey.mothership_cargo_space = {
        ['satellite'] = 1,
        ['uranium-fuel-cell'] = 0,
        ['nuclear-reactor'] = 60
    }
    journey.bonus_goods = {}
    journey.tooltip_capsules = ''
    journey.tooltip_modifiers = ''
    journey.nauvis_chunk_positions = nil
    journey.beacon_objective_health = 10000
    journey.beacon_objective_resistance = 0.9
    journey.beacon_timer = 0
    journey.world_number = 0
    journey.world_trait = 'lush'
    journey.world_modifiers = {}
    journey.world_specials = {}
    journey.emergency_triggered = false
    journey.emergency_selected = false
    journey.game_state = 'create_mothership'
    journey.speedrun = {enabled = false, time = 0, item = 'iron-stick'}
    journey.vote_minimum = 1
    journey.mothership_messages_last_damage = game.tick
    for k, modifier in pairs(Constants.modifiers) do
        journey.world_modifiers[k] = modifier.base
    end
    Public.update_tooltips(journey)
end

function Public.create_mothership(journey)
    local surface = game.create_surface('mothership', Constants.mothership_gen_settings)
    surface.request_to_generate_chunks({x = 0, y = 0}, 6)
    surface.force_generate_chunk_requests()
    surface.freeze_daytime = true
    journey.game_state = 'draw_mothership'
end

function Public.draw_mothership(journey)
    local surface = game.surfaces.mothership

    local positions = {}
    for x = Constants.mothership_radius * -1, Constants.mothership_radius, 1 do
        for y = Constants.mothership_radius * -1, Constants.mothership_radius, 1 do
            local position = {x = x, y = y}
            if is_mothership(position) then
                table.insert(positions, position)
            end
        end
    end

    table.shuffle_table(positions)

    for _, position in pairs(positions) do
        if surface.count_tiles_filtered({area = {{position.x - 1, position.y - 1}, {position.x + 2, position.y + 2}}, name = 'out-of-map'}) > 0 then
            local e = surface.create_entity({name = 'stone-wall', position = position, force = 'player'})
            protect(e, true)
        end
        if surface.count_tiles_filtered({area = {{position.x - 1, position.y - 1}, {position.x + 2, position.y + 2}}, name = 'lab-dark-1'}) < 4 then
            surface.set_tiles({{name = 'lab-dark-1', position = position}}, true)
        end
    end

    for _, tile in pairs(
        surface.find_tiles_filtered({area = {{Constants.mothership_teleporter_position.x - 2, Constants.mothership_teleporter_position.y - 2}, {Constants.mothership_teleporter_position.x + 2, Constants.mothership_teleporter_position.y + 2}}})
    ) do
        surface.set_tiles({{name = 'lab-dark-1', position = tile.position}}, true)
    end

    for k, area in pairs(Constants.world_selector_areas) do
        journey.world_selectors[k].rectangles = {}
        local position = area.left_top
        local rectangle =
            rendering.draw_rectangle {
            width = 1,
            filled = true,
            surface = surface,
            left_top = position,
            right_bottom = {position.x + Constants.world_selector_width, position.y + Constants.world_selector_height},
            color = Constants.world_selector_colors[k],
            draw_on_ground = true,
            only_in_alt_mode = false
        }
        table.insert(journey.world_selectors[k].rectangles, rectangle)
        journey.world_selectors[k].border =
            rendering.draw_rectangle {
            width = 8,
            filled = false,
            surface = surface,
            left_top = position,
            right_bottom = {position.x + Constants.world_selector_width, position.y + Constants.world_selector_height},
            color = {r = 100, g = 100, b = 100, a = 255},
            draw_on_ground = true,
            only_in_alt_mode = false
        }
    end

    journey.reroll_selector.rectangle =
        rendering.draw_rectangle {
        width = 8,
        filled = true,
        surface = surface,
        left_top = Constants.reroll_selector_area.left_top,
        right_bottom = Constants.reroll_selector_area.right_bottom,
        color = Constants.reroll_selector_area_color,
        draw_on_ground = true,
        only_in_alt_mode = false
    }
    journey.reroll_selector.border =
        rendering.draw_rectangle {
        width = 8,
        filled = false,
        surface = surface,
        left_top = Constants.reroll_selector_area.left_top,
        right_bottom = Constants.reroll_selector_area.right_bottom,
        color = {r = 100, g = 100, b = 100, a = 255},
        draw_on_ground = true,
        only_in_alt_mode = false
    }

    for k, item_name in pairs({'arithmetic-combinator', 'constant-combinator', 'decider-combinator', 'programmable-speaker', 'red-wire', 'green-wire', 'small-lamp', 'substation', 'pipe', 'gate', 'stone-wall', 'transport-belt'}) do
        local chest = surface.create_entity({name = 'infinity-chest', position = {-7 + k, Constants.mothership_radius - 3}, force = 'player'})
        chest.set_infinity_container_filter(1, {name = item_name, count = game.item_prototypes[item_name].stack_size})
        protect(chest, false)
        local loader = surface.create_entity({name = 'express-loader', position = {-7 + k, Constants.mothership_radius - 4}, force = 'player'})
        protect(loader, true)
        loader.direction = 4
    end

    for m = -1, 1, 2 do
        local inter = surface.create_entity({name = 'electric-energy-interface', position = {11 * m, Constants.mothership_radius - 4}, force = 'player'})
        protect(inter, true)
        local sub = surface.create_entity({name = 'substation', position = {9 * m, Constants.mothership_radius - 4}, force = 'player'})
        protect(sub, true)
    end

    for m = -1, 1, 2 do
        local x = Constants.mothership_radius - 3
        if m > 0 then
            x = x - 1
        end
        local y = Constants.mothership_radius * 0.5 - 7
        local turret = surface.create_entity({name = 'artillery-turret', position = {x * m, y}, force = 'player'})
        turret.direction = 4
        protect(turret, false)
        local ins = surface.create_entity({name = 'burner-inserter', position = {(x - 1) * m, y}, force = 'player'})
        ins.direction = 4 + m * 2
        ins.rotatable = false
        protect(ins, false)
        local chest = surface.create_entity({name = 'infinity-chest', position = {(x - 2) * m, y}, force = 'player'})
        chest.set_infinity_container_filter(1, {name = 'solid-fuel', count = 50})
        chest.set_infinity_container_filter(2, {name = 'artillery-shell', count = 1})
        protect(chest, false)
    end

    for _ = 1, 3, 1 do
        local comp = surface.create_entity({name = 'compilatron', position = Constants.mothership_teleporter_position, force = 'player'})
        comp.destructible = false
    end
    Public.draw_gui(journey)
    surface.daytime = 0.5

    journey.game_state = 'set_world_selectors'
end

function Public.teleport_players_to_mothership(journey)
    local surface = game.surfaces.mothership
    for _, player in pairs(game.connected_players) do
        if player.surface.name ~= 'mothership' then
            Public.clear_player(player)
            player.teleport(surface.find_non_colliding_position('character', {0, 0}, 32, 0.5), surface)
            journey.characters_in_mothership = journey.characters_in_mothership + 1
            table.insert(journey.mothership_messages, 'Welcome home ' .. player.name .. '!')
            return
        end
    end
end

function Public.set_minimum_to_vote(journey)
    --server_id returns only on Comfy server
    --therefore on Comfy, there is minimum of 3 players to vote for a world.
    --in any multiplayer there is minimum of 2 players
    --in singleplayer the minimum is 1
    --this does change only behaviour if there is less players connected than the minimum
    --the minimum should actualize on player join or when mothership builds the selectors
    if Server.get_server_id() ~= '' then
        journey.vote_minimum = 3
    elseif game.is_multiplayer() then
        journey.vote_minimum = 2
    else
        journey.vote_minimum = 1
    end
    local surface = game.surfaces.mothership
    if #game.connected_players <= journey.vote_minimum and surface and surface.daytime <= 0.5 then
        table.insert(journey.mothership_messages, {'journey.message_min_players', journey.vote_minimum})
    end
end

local function get_activation_level(journey, surface, area)
    local player_count_in_area = surface.count_entities_filtered({area = area, name = 'character'})
    local player_count_for_max_activation = math.max(#game.connected_players, journey.vote_minimum) * (2 / 3)
    local level = player_count_in_area / player_count_for_max_activation
    level = math.round(level, 2)
    return level
end

local function animate_selectors(journey)
    for k, world_selector in pairs(journey.world_selectors) do
        local activation_level = journey.world_selectors[k].activation_level
        if activation_level < 0.2 then
            activation_level = 0.2
        end
        if activation_level > 1 then
            activation_level = 1
        end
        for _, rectangle in pairs(world_selector.rectangles) do
            local color = Constants.world_selector_colors[k]
            rendering.set_color(rectangle, {r = color.r * activation_level, g = color.g * activation_level, b = color.b * activation_level, a = 255})
        end
    end
    local activation_level = journey.reroll_selector.activation_level
    if activation_level < 0.2 then
        activation_level = 0.2
    end
    if activation_level > 1 then
        activation_level = 1
    end
    local color = Constants.reroll_selector_area_color
    rendering.set_color(journey.reroll_selector.rectangle, {r = color.r * activation_level, g = color.g * activation_level, b = color.b * activation_level, a = 255})
end

local function draw_background(journey, surface)
    if journey.characters_in_mothership == 0 then
        return
    end
    local speed = journey.mothership_speed
    for c = 1, 16 * speed, 1 do
        local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
        surface.create_entity({name = 'shotgun-pellet', position = position, target = {position[1], position[2] + Constants.mothership_radius * 2}, speed = speed})
    end
    for c = 1, 16 * speed, 1 do
        local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
        surface.create_entity({name = 'piercing-shotgun-pellet', position = position, target = {position[1], position[2] + Constants.mothership_radius * 2}, speed = speed})
    end
    for c = 1, 2 * speed, 1 do
        local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
        surface.create_entity({name = 'cannon-projectile', position = position, target = {position[1], position[2] + Constants.mothership_radius * 2}, speed = speed})
    end
    for c = 1, 1 * speed, 1 do
        local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
        surface.create_entity({name = 'uranium-cannon-projectile', position = position, target = {position[1], position[2] + Constants.mothership_radius * 2}, speed = speed})
    end
    if math.random(1, 32) == 1 then
        local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
        surface.create_entity({name = 'explosive-uranium-cannon-projectile', position = position, target = {position[1], position[2] + Constants.mothership_radius * 3}, speed = speed})
    end
    if math.random(1, 90) == 1 then
        local position_x = math.random(64, 160)
        local position_y = math.random(64, 160)
        if math.random(1, 2) == 1 then
            position_x = position_x * -1
        end
        if math.random(1, 2) == 1 then
            position_y = position_y * -1
        end
        surface.create_entity({name = 'big-worm-turret', position = {position_x, position_y}, force = 'enemy'})
    end
end

local function roll_bonus_goods(journey, trait, amount)
    local loot = Constants.unique_world_traits[trait].loot
    local bonus_goods = {}
    while #bonus_goods < (amount or 3) do
        for key, numbers in pairs(loot) do
            local loot_table = Constants.starter_goods_pool[key]
            if #bonus_goods < (amount or 3) and math.random(numbers[1], numbers[2]) >= 1 then
                local item = loot_table[math.random(1, #loot_table)]
                bonus_goods[#bonus_goods + 1] = {item[1], math.random(item[2], item[3])}
            end
        end
    end
    return bonus_goods
end

function Public.set_world_selectors(journey)
    local surface = game.surfaces.mothership
    local x = Constants.reroll_selector_area.left_top.x + 3.2
    journey.reroll_selector.texts = {
        rendering.draw_text {
            text = journey.mothership_cargo.satellite .. ' x ',
            surface = surface,
            target = {x, Constants.reroll_selector_area.left_top.y - 1.5},
            color = {255, 255, 255, 255},
            scale = 1.5,
            font = 'default-large-bold',
            alignment = 'center',
            scale_with_zoom = false
        },
        rendering.draw_sprite {
            sprite = 'item/satellite',
            surface = surface,
            y_scale = 1.5,
            x_scale = 1.5,
            target = {x + 1.6, Constants.reroll_selector_area.left_top.y - 1}
        }
    }

    local modifier_names = {}
    for k, v in pairs(Constants.modifiers) do
        if not v.static then
            table.insert(modifier_names, k)
        end
    end

    local unique_world_traits = {}
    for k, _ in pairs(Constants.unique_world_traits) do
        table.insert(unique_world_traits, k)
    end
    table.shuffle_table(unique_world_traits)

    for k, world_selector in pairs(journey.world_selectors) do
        if not journey.importing then
            table.shuffle_table(modifier_names)
            world_selector.modifiers = {}
            world_selector.bonus_goods = {}
            world_selector.world_trait = unique_world_traits[k]
            world_selector.fuel_requirement = math.random(25, 50)
        end
        local position = Constants.world_selector_areas[k].left_top
        local texts = world_selector.texts
        local modifiers = world_selector.modifiers
        local y_modifier = -11.3
        local limits = {6, Constants.unique_world_traits[world_selector.world_trait].mods}
        local counts = {0, 0}
        local i = 1
        if journey.importing then
            goto skip_reroll
        end
        while (limits[1] + limits[2] > counts[1] + counts[2]) and i < #modifier_names do
            local modifier = modifier_names[i]
            local data = Constants.modifiers[modifier]
            local v
            if journey.world_modifiers[modifier] >= data.max then
                if data.dmin > 0 and counts[2] < limits[2] then
                    --at max, so we lower it as a positive modifier
                    v = math.floor(math.random(data.dmin, data.dmax) * -0.5)
                    counts[2] = counts[2] + 1
                    modifiers[i] = {name = modifier, value = v, neg = false}
                elseif data.dmin < 0 and counts[1] < limits[1] then
                    --at max, but it is good modifier, so lower it as negative modifier
                    v = math.floor(math.random(data.dmin, data.dmax))
                    counts[1] = counts[1] + 1
                    modifiers[i] = {name = modifier, value = v, neg = true}
                end
            elseif journey.world_modifiers[modifier] <= data.min then
                if data.dmin < 0 and counts[1] < limits[1] then
                    --at min, but good to have it min, so we grow it as negative modifier
                    v = math.floor(math.random(data.dmin, data.dmax))
                    counts[1] = counts[1] + 1
                    modifiers[i] = {name = modifier, value = v, neg = true}
                elseif data.dmin > 0 and counts[2] < limits[2] then
                    --at min, but min is bad, so we grow it as positive modifier
                    v = math.floor(math.random(data.dmin, data.dmax) * -0.5)
                    counts[2] = counts[2] + 1
                    modifiers[i] = {name = modifier, value = v, neg = false}
                end
            else
                --somewhere in middle, we first try to fill the positives then negatives. table is shuffled so it should be fine
                if counts[2] < limits[2] then
                    v = math.floor(math.random(data.dmin, data.dmax) * -0.5)
                    counts[2] = counts[2] + 1
                    modifiers[i] = {name = modifier, value = v, neg = false}
                elseif counts[1] < limits[1] then
                    v = math.floor(math.random(data.dmin, data.dmax))
                    counts[1] = counts[1] + 1
                    modifiers[i] = {name = modifier, value = v, neg = true}
                end
            end
            i = i + 1
        end
        world_selector.bonus_goods = roll_bonus_goods(journey, world_selector.world_trait)
        ::skip_reroll::

        table.insert(
            texts,
            rendering.draw_text {
                text = Constants.unique_world_traits[world_selector.world_trait].name,
                surface = surface,
                target = {position.x + Constants.world_selector_width * 0.5, position.y + y_modifier},
                color = {100, 0, 255, 255},
                scale = 1.25,
                font = 'default-large-bold',
                alignment = 'center',
                scale_with_zoom = false
            }
        )

        for k2, modifier in pairs(modifiers) do
            y_modifier = y_modifier + 0.8
            local text = ''
            if modifier.value > 0 then
                text = text .. '+'
            end
            text = text .. modifier.value .. '% '
            text = text .. Constants.modifiers[modifier.name].name

            local color
            if modifier.neg then
                color = {200, 0, 0, 255}
            else
                color = {0, 200, 0, 255}
            end

            table.insert(
                texts,
                rendering.draw_text {
                    text = text,
                    surface = surface,
                    target = {position.x + Constants.world_selector_width * 0.5, position.y + y_modifier},
                    color = color,
                    scale = 1.25,
                    font = 'default-large',
                    alignment = 'center',
                    scale_with_zoom = false
                }
            )
        end

        y_modifier = y_modifier + 0.85
        table.insert(
            texts,
            rendering.draw_text {
                text = 'Fuel requirement +' .. world_selector.fuel_requirement,
                surface = surface,
                target = {position.x + Constants.world_selector_width * 0.5, position.y + y_modifier},
                color = {155, 155, 0, 255},
                scale = 1.25,
                font = 'default-large',
                alignment = 'center',
                scale_with_zoom = false
            }
        )
        table.insert(
            texts,
            rendering.draw_sprite {
                sprite = 'item/uranium-fuel-cell',
                surface = surface,
                target = {position.x + Constants.world_selector_width * 0.5 + 3.7, position.y + y_modifier + 0.5}
            }
        )

        y_modifier = y_modifier + 1.1
        local x_modifier = -0.5

        for k2, good in pairs(world_selector.bonus_goods) do
            local render_id =
                rendering.draw_text {
                text = '+' .. good[2],
                surface = surface,
                target = {position.x + x_modifier, position.y + y_modifier},
                color = {200, 200, 0, 255},
                scale = 1.25,
                font = 'default-large',
                alignment = 'center',
                scale_with_zoom = false
            }
            table.insert(texts, render_id)

            x_modifier = x_modifier + 0.95
            if good[2] >= 10 then
                x_modifier = x_modifier + 0.18
            end
            if good[2] >= 100 then
                x_modifier = x_modifier + 0.18
            end

            local render_id =
                rendering.draw_sprite {
                sprite = 'item/' .. good[1],
                surface = surface,
                target = {position.x + x_modifier, position.y + 0.5 + y_modifier}
            }
            table.insert(texts, render_id)

            x_modifier = x_modifier + 1.70
        end
    end

    destroy_teleporter(journey, game.surfaces.nauvis, Constants.mothership_teleporter_position)
    destroy_teleporter(journey, surface, Constants.mothership_teleporter_position)
    if journey.restart_from_scenario then
        Public.restart_server(journey)
    end

    Server.to_discord_embed('World ' .. journey.world_number + 1 .. ' selection has started!')
    Public.set_minimum_to_vote(journey)
    journey.importing = false

    journey.game_state = 'delete_nauvis_chunks'
end

function Public.delete_nauvis_chunks(journey)
    local surface = game.surfaces.mothership
    Public.teleport_players_to_mothership(journey)
    draw_background(journey, surface)
    if delete_nauvis_chunks(journey) then
        return
    end
    for _, player in pairs(game.players) do
        if player.gui.top.chunk_progress then
            player.gui.top.chunk_progress.destroy()
        end
    end

    journey.game_state = 'mothership_world_selection'
end

function Public.reroll_worlds(journey)
    local surface = game.surfaces.mothership
    Public.teleport_players_to_mothership(journey)
    draw_background(journey, surface)
    animate_selectors(journey)
    local reroll_selector_activation_level = get_activation_level(journey, surface, Constants.reroll_selector_area)
    journey.reroll_selector.activation_level = reroll_selector_activation_level
    for i = 1, 3, 1 do
        local activation_level = get_activation_level(journey, surface, Constants.world_selector_areas[i])
        journey.world_selectors[i].activation_level = activation_level
    end
    if reroll_selector_activation_level > 1 then
        journey.mothership_speed = journey.mothership_speed + 0.025
        if journey.mothership_speed > 4 then
            journey.mothership_speed = 4
            clear_selectors(journey)
            journey.mothership_cargo.satellite = journey.mothership_cargo.satellite - 1
            Public.draw_gui(journey)
            table.insert(journey.mothership_messages, 'New lands have been discovered!')
            journey.game_state = 'set_world_selectors'
        end
    else
        journey.mothership_speed = journey.mothership_speed - 0.25
        if journey.mothership_speed < 0.35 then
            table.insert(journey.mothership_messages, 'Aborting..')
            journey.game_state = 'mothership_world_selection'
            journey.mothership_speed = 0.35
        end
    end
end

function Public.importing_world(journey)
    local surface = game.surfaces.mothership
    Public.teleport_players_to_mothership(journey)
    draw_background(journey, surface)
    animate_selectors(journey)
    clear_selectors(journey)
    Public.update_tooltips(journey)
    Public.draw_gui(journey)
    table.insert(journey.mothership_messages, 'Restoring the last saved position...')
    journey.game_state = 'set_world_selectors'
end

function Public.mothership_world_selection(journey)
    Public.teleport_players_to_mothership(journey)
    check_if_restarted(journey)
    local surface = game.surfaces.mothership
    local daytime = surface.daytime
    daytime = daytime - 0.025
    if daytime < 0 then
        daytime = 0
    end
    surface.daytime = daytime

    local reroll_selector_activation_level = get_activation_level(journey, surface, Constants.reroll_selector_area)
    journey.reroll_selector.activation_level = reroll_selector_activation_level

    if journey.emergency_triggered then
        if not journey.emergency_selected then
            journey.selected_world = math.random(1, 3)
            table.insert(journey.mothership_messages, 'Emergency destination selected..')
            journey.emergency_selected = true
        end
    else
        journey.selected_world = false
        for i = 1, 3, 1 do
            local activation_level = get_activation_level(journey, surface, Constants.world_selector_areas[i])
            journey.world_selectors[i].activation_level = activation_level
            if activation_level > 1 then
                journey.selected_world = i
            end
        end
        if reroll_selector_activation_level > 1 and journey.mothership_speed == 0.35 and journey.mothership_cargo.satellite > 0 then
            journey.game_state = 'reroll_worlds'
            table.insert(journey.mothership_messages, 'Dispatching satellite..')
            return
        end
    end

    if journey.selected_world then
        if not journey.mothership_advancing_to_world then
            table.insert(journey.mothership_messages, 'Advancing to selected world.')
            journey.mothership_advancing_to_world = game.tick + math.random(60 * 45, 60 * 75)
        else
            local seconds_left = math.floor((journey.mothership_advancing_to_world - game.tick) / 60)
            if seconds_left <= 0 then
                journey.mothership_advancing_to_world = false
                table.insert(journey.mothership_messages, 'Arriving at targeted destination!')
                journey.game_state = 'mothership_arrives_at_world'
                return
            end
            if seconds_left % 15 == 0 then
                table.insert(journey.mothership_messages, 'Estimated arrival in ' .. seconds_left .. ' seconds.')
            end
        end

        journey.mothership_speed = journey.mothership_speed + 0.1
        if journey.mothership_speed > 4 then
            journey.mothership_speed = 4
        end
    else
        if journey.mothership_advancing_to_world then
            table.insert(journey.mothership_messages, 'Aborting travelling sequence.')
            journey.mothership_advancing_to_world = false
        end
        journey.mothership_speed = journey.mothership_speed - 0.25
        if journey.mothership_speed < 0.35 then
            journey.mothership_speed = 0.35
        end
    end

    draw_background(journey, surface)
    animate_selectors(journey)
    Public.update_tooltips(journey)
end

function Public.mothership_arrives_at_world(journey)
    local surface = game.surfaces.mothership

    Public.teleport_players_to_mothership(journey)

    if journey.mothership_speed == 0.15 then
        for _ = 1, 16, 1 do
            table.insert(journey.mothership_messages, '')
        end
        table.insert(journey.mothership_messages, '[img=item/uranium-fuel-cell] Fuel cells depleted ;_;')
        for _ = 1, 16, 1 do
            table.insert(journey.mothership_messages, '')
        end
        table.insert(journey.mothership_messages, 'Refuel via supply rocket required!')

        for i = 1, 3, 1 do
            journey.world_selectors[i].activation_level = 0
        end
        animate_selectors(journey)

        journey.game_state = 'clear_modifiers'
    else
        journey.mothership_speed = journey.mothership_speed - 0.15
    end

    if journey.mothership_speed < 0.15 then
        journey.mothership_speed = 0.15
    end
    journey.beacon_objective_resistance = 0.90 - (0.03 * journey.world_number)
    journey.emergency_triggered = false
    journey.emergency_selected = false
    journey.import_checked = false
    draw_background(journey, surface)
    Public.update_tooltips(journey)
end

function Public.clear_modifiers(journey)
    local unique_modifier = Unique_modifiers[journey.world_trait]
    local clear = unique_modifier.clear
    if clear then
        clear(journey)
    end
    journey.world_specials = {}
    local force = game.forces.player
    force.reset()
    force.reset_technologies()
    force.reset_technology_effects()
    for a = 1, 7, 1 do
        force.technologies['refined-flammables-' .. a].enabled = false
    end
    journey.game_state = 'create_the_world'
    Public.update_tooltips(journey)
end

function Public.create_the_world(journey)
    local surface = game.surfaces.nauvis
    local mgs = surface.map_gen_settings
    mgs.seed = math.random(1, 4294967295)
    mgs.terrain_segmentation = math.random(10, 20) * 0.1
    mgs.peaceful_mode = false

    local modifiers = journey.world_selectors[journey.selected_world].modifiers
    for _, modifier in pairs(modifiers) do
        local m = (100 + modifier.value) * 0.01
        local name = modifier.name
        local extremes = {Constants.modifiers[name].min, Constants.modifiers[name].max}
        journey.world_modifiers[name] = math.round(math.min(extremes[2], math.max(extremes[1], journey.world_modifiers[name] * m)) * 100000, 5) / 100000
    end
    surface.map_gen_settings = mgs
    journey.world_trait = journey.world_selectors[journey.selected_world].world_trait

    local unique_modifier = Unique_modifiers[journey.world_trait]
    local set_specials = unique_modifier.set_specials
    if set_specials then
        set_specials(journey)
    end
    set_map_modifiers(journey)
    surface.clear(false)

    journey.nauvis_chunk_positions = nil
    journey.rocket_silos = {}
    journey.mothership_cargo['uranium-fuel-cell'] = 0
    journey.world_number = journey.world_number + 1
    local max_satellites = math_floor(journey.world_number * 0.334) + 1
    if max_satellites > Constants.max_satellites then
        max_satellites = Constants.max_satellites
    end
    journey.mothership_cargo_space['satellite'] = max_satellites
    journey.mothership_cargo_space['uranium-fuel-cell'] = journey.mothership_cargo_space['uranium-fuel-cell'] + journey.world_selectors[journey.selected_world].fuel_requirement

    game.forces.enemy.reset_evolution()

    for _, good in pairs(journey.world_selectors[journey.selected_world].bonus_goods) do
        if journey.bonus_goods[good[1]] then
            journey.bonus_goods[good[1]] = journey.bonus_goods[good[1]] + good[2]
        else
            journey.bonus_goods[good[1]] = good[2]
        end
    end
    journey.goods_to_dispatch = {}
    for k, v in pairs(journey.bonus_goods) do
        table.insert(journey.goods_to_dispatch, {k, v})
    end
    table.shuffle_table(journey.goods_to_dispatch)
    Public.update_tooltips(journey)
    journey.game_state = 'wipe_offline_players'
end

function Public.wipe_offline_players(journey)
    remove_offline_players(96)
    for _, player in pairs(game.players) do
        if not player.connected then
            player.force = game.forces.enemy
        end
    end
    journey.game_state = 'set_unique_modifiers'
end

function Public.notify_discord(journey)
    if journey.disable_discord_notifications then
        return
    end
    local caption = 'World ' .. journey.world_number .. ' | ' .. Constants.unique_world_traits[journey.world_trait].name
    local modifier_message = ''
    for _, mod in pairs(journey.world_selectors[journey.selected_world].modifiers) do
        local sign = ''
        if mod.value > 0 then
            sign = '+'
        end
        modifier_message = modifier_message .. sign .. mod.value .. '% ' .. mod.name .. '\n'
    end
    local capsules = ''
    for _, cap in pairs(journey.world_selectors[journey.selected_world].bonus_goods) do
        capsules = capsules .. cap[2] .. 'x ' .. cap[1] .. '\n'
    end
    local message = {
        title = 'World advanced',
        description = 'Arriving at target destination!',
        color = 'warning',
        field1 = {
            text1 = 'World level:',
            text2 = caption,
            inline = 'true'
        },
        field2 = {
            text1 = 'World description:',
            text2 = Constants.unique_world_traits[journey.world_trait].desc,
            inline = 'true'
        },
        field3 = {
            text1 = 'Satellites in mothership cargo:',
            text2 = journey.mothership_cargo['satellite'] .. ' / ' .. journey.mothership_cargo_space['satellite'],
            inline = 'false'
        },
        field4 = {
            text1 = 'Modifiers changed:',
            text2 = modifier_message,
            inline = 'false'
        },
        field5 = {
            text1 = 'Capsules gained:',
            text2 = capsules,
            inline = 'false'
        }
    }
    Server.to_discord_embed_parsed(message)
end

function Public.set_unique_modifiers(journey)
    local unique_modifier = Unique_modifiers[journey.world_trait]
    local on_world_start = unique_modifier.on_world_start
    if on_world_start then
        on_world_start(journey)
    end
    Public.update_tooltips(journey)
    Public.draw_gui(journey)
    Public.notify_discord(journey)
    journey.game_state = 'place_teleporter_into_world'
end

function Public.place_teleporter_into_world(journey)
    local surface = game.surfaces.nauvis
    surface.request_to_generate_chunks({x = 0, y = 0}, 3)
    surface.force_generate_chunk_requests()
    place_teleporter(journey, surface, Constants.mothership_teleporter_position, true)
    journey.game_state = 'make_it_night'
end

function Public.make_it_night(journey)
    draw_background(journey, game.surfaces.mothership)
    local surface = game.surfaces.mothership
    local daytime = surface.daytime
    daytime = daytime + 0.02
    surface.daytime = daytime
    if daytime > 0.5 then
        clear_selectors(journey)
        game.reset_time_played()
        place_teleporter(journey, surface, Constants.mothership_teleporter_position, false)
        table.insert(journey.mothership_messages, 'Teleporter deployed. [gps=' .. Constants.mothership_teleporter_position.x .. ',' .. Constants.mothership_teleporter_position.y .. ',mothership]')
        journey.game_state = 'dispatch_goods'
    end
end

function Public.dispatch_goods(journey)
    draw_background(journey, game.surfaces.mothership)

    if journey.characters_in_mothership == #game.connected_players then
        return
    end

    local goods_to_dispatch = journey.goods_to_dispatch
    local size_of_goods_to_dispatch = #goods_to_dispatch
    if size_of_goods_to_dispatch == 0 then
        for _ = 1, 30, 1 do
            table.insert(journey.mothership_messages, '')
        end
        table.insert(journey.mothership_messages, 'Capsule storage depleted.')
        for _ = 1, 30, 1 do
            table.insert(journey.mothership_messages, '')
        end
        table.insert(journey.mothership_messages, 'Good luck on your adventure! ^.^')
        journey.game_state = 'world'
        return
    end

    if journey.dispatch_beacon and journey.dispatch_beacon.valid then
        return
    end

    local surface = game.surfaces.nauvis

    if journey.dispatch_beacon_position then
        local good = goods_to_dispatch[journey.dispatch_key]
        surface.spill_item_stack(journey.dispatch_beacon_position, {name = good[1], count = good[2]}, true, nil, false)
        table.remove(journey.goods_to_dispatch, journey.dispatch_key)
        journey.dispatch_beacon = nil
        journey.dispatch_beacon_position = nil
        journey.dispatch_key = nil
        return
    end

    local chunk = surface.get_random_chunk()
    if math.abs(chunk.x) > 4 or math.abs(chunk.y) > 4 then
        return
    end

    local position = {x = chunk.x * 32 + math.random(0, 31), y = chunk.y * 32 + math.random(0, 31)}
    position = surface.find_non_colliding_position('rocket-silo', position, 32, 1)
    if not position then
        return
    end

    journey.dispatch_beacon = surface.create_entity({name = 'stone-wall', position = position, force = 'neutral'})
    journey.dispatch_beacon.minable = false
    journey.dispatch_beacon_position = {x = position.x, y = position.y}
    journey.dispatch_key = math.random(1, size_of_goods_to_dispatch)

    local good = goods_to_dispatch[journey.dispatch_key]
    table.insert(journey.mothership_messages, 'Capsule containing ' .. good[2] .. 'x [img=item/' .. good[1] .. '] dispatched. [gps=' .. position.x .. ',' .. position.y .. ',nauvis]')
    if journey.announce_capsules then
        Server.to_discord_embed('A capsule containing ' .. good[2] .. 'x ' .. good[1] .. ' was spotted at: x=' .. position.x .. ', y=' .. position.y .. '!')
    end

    surface.create_entity({name = 'artillery-projectile', position = {x = position.x - 256 + math.random(0, 512), y = position.y - 256}, target = position, speed = 0.2})
end

function Public.world(journey)
    if journey.mothership_cargo['uranium-fuel-cell'] then
        if journey.mothership_cargo['uranium-fuel-cell'] >= journey.mothership_cargo_space['uranium-fuel-cell'] then
            table.insert(journey.mothership_messages, '[img=item/uranium-fuel-cell] Refuel operation successful!! =^.^=')
            Server.to_discord_embed('Refuel operation complete!')
            journey.game_state = 'mothership_waiting_for_players'
        end
    end
    draw_background(journey, game.surfaces.mothership)
    if journey.speedrun.enabled then
        local item = journey.speedrun.item
        local time = math.round(journey.speedrun.time / 6) / 10
        if journey.mothership_cargo[item] and journey.mothership_cargo[item] >= journey.mothership_cargo_space[item] then
            local amount = 6
            local brackets = {120, 120, 240, 480, 960, 1920}
            local timer = time
            for i = 1, 6, 1 do
                if timer >= brackets[i] then
                    timer = timer - brackets[i]
                    amount = amount - 1
                else
                    break
                end
            end
            table.insert(journey.mothership_messages, {'journey.message_delivery_done', item, time, amount})
            Server.to_discord_embed({'journey.message_delivery_done', item, time, amount}, true)
            local bonus_goods = roll_bonus_goods(journey, 'resupply_station', amount)
            for _, good in pairs(bonus_goods) do
                if journey.bonus_goods[good[1]] then
                    journey.bonus_goods[good[1]] = journey.bonus_goods[good[1]] + good[2]
                else
                    journey.bonus_goods[good[1]] = good[2]
                end
                table.insert(journey.mothership_messages, {'journey.message_delivered', good[1], good[2]})
            end
            Public.update_tooltips(journey)
            journey.speedrun.enabled = false
        end
        if game.tick % 60 == 0 then
            journey.speedrun.time = journey.speedrun.time + 1
            time = math.round(journey.speedrun.time / 6) / 10
            local speedgoal = journey.mothership_cargo_space[item] or 1
            local value = (journey.mothership_cargo[item] or 0) / speedgoal
            cargo_gui('journey_delivery', item, {'journey.tooltip_delivery', journey.mothership_cargo[item] or 0, speedgoal, time}, value)
        end
    end

    if game.tick % 1800 ~= 0 then
        return
    end
    for k, silo in pairs(journey.rocket_silos) do
        if not silo or not silo.valid then
            table.remove(journey.rocket_silos, k)
            break
        end
        local inventory = silo.get_inventory(defines.inventory.rocket_silo_rocket) or {}
        local slot = inventory[1]
        if slot and slot.valid and slot.valid_for_read then
            local name = slot.name
            local count = slot.count
            local needs = (journey.mothership_cargo_space[name] or 0) - (journey.mothership_cargo[name] or 0)
            if needs > 0 and count >= math.min(game.item_prototypes[name].stack_size, needs) then
                if silo.launch_rocket() then
                    table.insert(journey.mothership_messages, {'journey.message_rocket_launched', count, name, silo.position.x, silo.position.y})
                end
            end
        end
    end
end

function Public.mothership_waiting_for_players(journey)
    if journey.characters_in_mothership > #game.connected_players * 0.5 then
        journey.game_state = 'set_world_selectors'
        Vacants.reset()
        return
    end

    if math.random(1, 2) == 1 then
        return
    end
    local tick = game.tick % 3600
    if tick == 0 then
        local messages = Constants.mothership_messages.waiting
        table.insert(journey.mothership_messages, messages[math.random(1, #messages)])
    end
end

function Public.teleporters(journey, player)
    if not player.character then
        return
    end
    if not player.character.valid then
        return
    end
    local surface = player.surface
    local tile = surface.get_tile(player.position)
    if tile.name ~= Constants.teleporter_tile and tile.hidden_tile ~= Constants.teleporter_tile then
        return
    end
    local base_position = {0, 0}
    if surface.index == 1 then
        drop_player_items(journey, player)
        local position = game.surfaces.mothership.find_non_colliding_position('character', base_position, 32, 0.5)
        if position then
            player.teleport(position, game.surfaces.mothership)
        else
            player.teleport(base_position, game.surfaces.mothership)
        end
        journey.characters_in_mothership = journey.characters_in_mothership + 1
        return
    end
    if surface.name == 'mothership' then
        Public.clear_player(player)
        local position = game.surfaces.nauvis.find_non_colliding_position('character', base_position, 32, 0.5)
        if position then
            player.teleport(position, game.surfaces.nauvis)
        else
            player.teleport(base_position, game.surfaces.nauvis)
        end

        journey.characters_in_mothership = journey.characters_in_mothership - 1
        return
    end
end

function Public.deal_damage_to_beacon(journey, incoming_damage)
    if journey.game_state ~= 'world' then
        return
    end
    local resistance = journey.beacon_objective_resistance
    journey.beacon_objective_health = math.floor(journey.beacon_objective_health - (incoming_damage * (1 - resistance)))
    rendering.set_text(journey.beacon_objective_hp_label, {'journey.beacon_hp', journey.beacon_objective_health})
    if journey.beacon_objective_health < 5000 and game.tick > journey.mothership_messages_last_damage + 900 then --under 50%, once every 15 seconds max
        table.insert(journey.mothership_messages, 'The personal teleporter is being damaged, preparing for emergency departure.')
        journey.mothership_messages_last_damage = game.tick
    end
    if journey.beacon_objective_health <= 0 then
        table.insert(journey.mothership_messages, 'Beaming everyone up, triggerring emergency departure.')
        table.insert(journey.mothership_messages, '[img=item/nuclear-reactor] Emergency power plant burned down ;_;')
        journey.mothership_cargo['nuclear-reactor'] = journey.mothership_cargo['nuclear-reactor'] - 30
        if journey.mothership_cargo['nuclear-reactor'] < 0 then
            table.insert(journey.mothership_messages, 'Aborting, there is not enough emergency fuel. Shutting systems off...')
            for _ = 1, #journey.mothership_messages, 1 do
                Public.mothership_message_queue(journey)
            end
            Public.hard_reset(journey)
        else
            journey.emergency_triggered = true
            journey.game_state = 'set_world_selectors'
            Public.update_tooltips(journey)
            Public.draw_gui(journey)
        end
    end
end

function Public.lure_biters(journey, position)
    if journey.game_state ~= 'world' or not journey.beacon_objective.valid then
        return
    end
    local beacon = journey.beacon_objective
    local surface = beacon.surface
    local biters = surface.find_entities_filtered {position = position or beacon.position, radius = 80, force = 'enemy', type = 'unit'}
    if #biters > 0 then
        for _, biter in pairs(biters) do
            biter.set_command({type = defines.command.attack_area, destination = beacon.position, radius = 10, distraction = defines.distraction.by_anything})
        end
    end
    --return (#biters or 0)
end

function Public.lure_far_biters(journey)
    -- if journey.game_state ~= 'world' or not journey.beacon_objective.valid then return end
    -- if journey.beacon_timer < journey.world_modifiers['beacon_irritation'] then
    -- 	journey.beacon_timer = journey.beacon_timer + 10
    -- 	return
    -- end
    -- local surface = journey.beacon_objective.surface
    -- local chunk_position = surface.get_random_chunk()
    -- local lured = 0
    -- for _ = 1, 25, 1 do
    -- 	lured = lured + Public.lure_biters(journey, {x = chunk_position.x * 32, y = chunk_position.y * 32})
    -- end
    -- game.print('lured ' .. lured .. 'biters at tick ' .. game.tick)
    -- journey.beacon_timer = journey.beacon_timer - lured
end

return Public
