--luacheck: ignore
require 'modules.no_turrets'
require 'modules.no_acid_puddles'
local CoreGui = require 'utils.gui'
require 'maps.biter_hatchery.share_chat'
local Map_score = require 'utils.gui.map_score'
local unit_raffle = require 'maps.biter_hatchery.raffle_tables'
local Terrain = require 'maps.biter_hatchery.terrain'
local Gui = require 'maps.biter_hatchery.gui'
local Team = require 'maps.biter_hatchery.team'
local Unit_health_booster = require 'modules.biter_health_booster'
local Map = require 'modules.map_info'
local Global = require 'utils.global'
local Server = require 'utils.server'

local math_random = math.random

local hatchery = {}
Global.register(
    hatchery,
    function (tbl)
        hatchery = tbl
    end
)

local m = 2
local health_boost_food_values = {
    ['automation-science-pack'] = 0.000001 * m,
    ['logistic-science-pack'] = 0.000003 * m,
    ['military-science-pack'] = 0.00000822 * m,
    ['chemical-science-pack'] = 0.00002271 * m,
    ['production-science-pack'] = 0.00009786 * m,
    ['utility-science-pack'] = 0.00010634 * m,
    ['space-science-pack'] = 0.00041828 * m
}

local worm_turret_spawn_radius = 25
local worm_turret_vectors = {}
worm_turret_vectors.west = {}
for x = 0, worm_turret_spawn_radius, 1 do
    for y = worm_turret_spawn_radius * -1, worm_turret_spawn_radius, 1 do
        local d = math.sqrt(x ^ 2 + y ^ 2)
        if d <= worm_turret_spawn_radius and d > 3 then
            table.insert(worm_turret_vectors.west, { x, y })
        end
    end
end
worm_turret_vectors.east = {}
for x = worm_turret_spawn_radius * -1, 0, 1 do
    for y = worm_turret_spawn_radius * -1, worm_turret_spawn_radius, 1 do
        local d = math.sqrt(x ^ 2 + y ^ 2)
        if d <= worm_turret_spawn_radius and d > 3 then
            table.insert(worm_turret_vectors.east, { x, y })
        end
    end
end

local function spawn_worm_turret(surface, force_name)
    local r_max = surface.count_entities_filtered({ type = 'turret', force = force_name }) + 1
    if r_max > 256 then
        return
    end
    if math_random(1, r_max) ~= 1 then
        return
    end
    local vectors = worm_turret_vectors[force_name]
    local vector = vectors[math_random(1, #vectors)]
    local worm = 'small-worm-turret'
    local position = { x = storage.map_forces[force_name].hatchery.position.x, y = storage.map_forces[force_name].hatchery.position.y }
    position.x = position.x + vector[1]
    position.y = position.y + vector[2]
    position = surface.find_non_colliding_position('biter-spawner', position, 16, 1)
    if not position then
        return
    end
    surface.create_entity({ name = worm, position = position, force = force_name })
    surface.create_entity({ name = 'blood-explosion-huge', position = position })
    surface.create_decoratives { check_collision = false, decoratives = { { name = 'enemy-decal', position = position, amount = 1 } } }
end

local function spawn_units(belt, food_item, removed_item_count)
    local count_per_flask = unit_raffle[food_item][2]
    local raffle = unit_raffle[food_item][1]
    local team = storage.map_forces[belt.force.name]
    team.unit_health_boost = team.unit_health_boost + (health_boost_food_values[food_item] * removed_item_count)
    for _ = 1, removed_item_count, 1 do
        for _ = 1, count_per_flask, 1 do
            local name = raffle[math_random(1, #raffle)]
            local unit = belt.surface.create_entity({ name = name, position = belt.position, force = belt.force })
            unit.ai_settings.allow_destroy_when_commands_fail = false
            unit.ai_settings.allow_try_return_to_spawner = false
            Unit_health_booster.add_unit(unit, team.unit_health_boost)
            team.units[unit.unit_number] = unit
            team.unit_count = team.unit_count + 1
        end
    end
    if math_random(1, 8) == 1 then
        spawn_worm_turret(belt.surface, belt.force.name)
    end
end

local function get_belts(spawner)
    local belts =
        spawner.surface.find_entities_filtered(
            {
                type = 'transport-belt',
                area = { { spawner.position.x - 5, spawner.position.y - 3 }, { spawner.position.x + 4, spawner.position.y + 3 } },
                force = spawner.force
            }
        )
    return belts
end

local nom_msg = { 'munch', 'munch', 'yum', 'nom' }

local function feed_floaty_text(entity)
    entity.surface.create_entity({ name = 'flying-text', position = entity.position, text = nom_msg[math_random(1, 4)], color = { math_random(50, 100), 0, 255 } })
    local position = { x = entity.position.x - 0.75, y = entity.position.y - 1 }
    local b = 1.35
    for _ = 1, math_random(0, 2), 1 do
        local p = { (position.x + 0.4) + (b * -1 + math_random(0, b * 20) * 0.1), position.y + (b * -1 + math_random(0, b * 20) * 0.1) }
        entity.surface.create_entity({ name = 'flying-text', position = p, text = '♥', color = { math_random(150, 255), 0, 255 } })
    end
end

local function eat_food_from_belt(belt)
    for i = 1, 2, 1 do
        local line = belt.get_transport_line(i)
        for food_item, _ in pairs(unit_raffle) do
            if storage.map_forces[belt.force.name].unit_count > storage.map_forces[belt.force.name].max_unit_count then
                return
            end
            local removed_item_count = line.remove_item({ name = food_item, count = 8 })
            if removed_item_count > 0 then
                feed_floaty_text(belt)
                spawn_units(belt, food_item, removed_item_count)
            end
        end
    end
end

local function nom()
    for _, force in pairs(storage.map_forces) do
        if not force.hatchery then
            return
        end
        force.hatchery.health = force.hatchery.health + 1
        local belts = get_belts(force.hatchery)
        for _, belt in pairs(belts) do
            eat_food_from_belt(belt)
        end
    end
    for _, player in pairs(game.connected_players) do
        Gui.update_health_boost_buttons(player)
    end
end

local function get_units(force_name)
    local units = {}
    local count = 1
    for _, unit in pairs(storage.map_forces[force_name].units) do
        if unit.valid and not unit.unit_group then
            if math_random(1, 3) ~= 1 then
                units[count] = unit
                count = count + 1
            end
        end
    end
    return units
end

local function alert_bubble(force_name, entity)
    if force_name == 'west' then
        force_name = 'east'
    else
        force_name = 'west'
    end
    for _, player in pairs(game.forces[force_name].connected_players) do
        player.add_custom_alert(entity, { type = 'item', name = 'tank' }, 'Incoming enemy units!', true)
    end
end

local function send_unit_groups()
    local surface = game.surfaces.nauvis
    for key, force in pairs(storage.map_forces) do
        local units = get_units(key)
        if #units > 0 then
            alert_bubble(key, units[1])
            local vectors = worm_turret_vectors[key]
            local vector = vectors[math_random(1, #vectors)]
            local position = { x = force.hatchery.position.x + vector[1], y = force.hatchery.position.y + vector[2] }
            local unit_group = surface.create_unit_group({ position = position, force = key })
            for _, unit in pairs(units) do
                unit_group.add_member(unit)
            end
            if not force.target then
                return
            end
            if not force.target.valid then
                return
            end
            unit_group.set_command(
                {
                    type = defines.command.compound,
                    structure_type = defines.compound_command.return_last,
                    commands = {
                        {
                            type = defines.command.attack_area,
                            destination = { x = force.target.position.x, y = force.target.position.y },
                            radius = 6,
                            distraction = defines.distraction.by_anything
                        },
                        {
                            type = defines.command.attack,
                            target = force.target,
                            distraction = defines.distraction.by_enemy
                        }
                    }
                }
            )
            unit_group.start_moving()
        end
    end
end

local border_teleport = {
    ['east'] = 1,
    ['west'] = -1
}

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
    if not player.character then
        return
    end
    if not player.character.valid then
        return
    end
    if player.position.x > -4 and player.position.x < 4 then
        if not border_teleport[player.force.name] then
            return
        end
        if player.character.driving then
            player.character.driving = false
        end
        player.teleport({ player.position.x + border_teleport[player.force.name], player.position.y }, game.surfaces.nauvis)
    end
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if storage.game_reset_tick then
        return
    end

    if entity.type == 'unit' then
        local team = storage.map_forces[entity.force.name]
        team.unit_count = team.unit_count - 1
        team.units[entity.unit_number] = nil
        return
    end

    if entity.type ~= 'unit-spawner' then
        return
    end

    if entity.force.name == 'east' then
        game.print('East lost their Hatchery.', { 100, 100, 100 })
        game.forces.east.play_sound { path = 'utility/game_lost', volume_modifier = 0.85 }

        local message = '>>>> WEST TEAM HAS WON THE GAME!!! <<<<'
        Server.to_discord_bold(table.concat { '*** ', message, ' ***' })
        game.print(message, { 250, 120, 0 })

        game.forces.west.play_sound { path = 'utility/game_won', volume_modifier = 0.85 }

        for _, player in pairs(game.forces.west.connected_players) do
            if storage.map_forces.east.player_count > 0 then
                Map_score.set_score(player, Map_score.get_score(player) + 1)
            end
        end
    else
        game.print('West lost their Hatchery.', { 100, 100, 100 })
        game.forces.west.play_sound { path = 'utility/game_lost', volume_modifier = 0.85 }

        local message = '>>>> EAST TEAM HAS WON THE GAME!!! <<<<'
        Server.to_discord_bold(table.concat { '*** ', message, ' ***' })
        game.print(message, { 250, 120, 0 })

        game.forces.east.play_sound { path = 'utility/game_won', volume_modifier = 0.85 }

        for _, player in pairs(game.forces.east.connected_players) do
            if storage.map_forces.west.player_count > 0 then
                Map_score.set_score(player, Map_score.get_score(player) + 1)
            end
        end
    end

    game.print('Map rerolling in 2 minutes.', { 150, 150, 150 })

    game.forces.spectator.play_sound { path = 'utility/game_won', volume_modifier = 0.85 }

    storage.game_reset_tick = game.tick + 7200

    for _, player in pairs(game.connected_players) do
        for _, child in pairs(player.gui.left.children) do
            child.destroy()
        end
        CoreGui.call_existing_tab(player, 'Map Scores')
    end

    for _, e in pairs(entity.surface.find_entities_filtered({ type = 'unit' })) do
        e.active = false
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]

    Gui.unit_health_buttons(player)
    Gui.spectate_button(player)
    Gui.update_health_boost_buttons(player)

    if player.force.name == 'player' then
        if player.character and player.character.valid then
            player.character.destroy()
        end
        player.character = nil
        player.spectator = true
        player.set_controller({ type = defines.controllers.spectator })
        if hatchery.gamestate == 'game_in_progress' or hatchery.gamestate == 'rejoin_question' then
            Team.assign_force_to_player(player)
            Team.add_player_to_team(player)
            Team.teleport_player_to_spawn(player)
        end
    end
end

--Construction Robot Restriction
local robot_build_restriction = {
    ['east'] = function (x)
        if x < 0 then
            return true
        end
    end,
    ['west'] = function (x)
        if x > 0 then
            return true
        end
    end
}

local function on_robot_built_entity(event)
    if not robot_build_restriction[event.robot.force.name] then
        return
    end
    if not robot_build_restriction[event.robot.force.name](event.created_entity.position.x) then
        return
    end
    local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
    inventory.insert({ name = event.created_entity.name, count = 1 })
    event.robot.surface.create_entity({ name = 'explosion', position = event.created_entity.position })
    game.print('Team ' .. event.robot.force.name .. "'s construction drone had an accident.", { r = 200, g = 50, b = 100 })
    event.created_entity.destroy()
end

local function on_entity_damaged(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if entity.type ~= 'unit-spawner' then
        return
    end
    local cause = event.cause
    if cause then
        if cause.valid then
            if cause.type == 'unit' then
                if math_random(1, 16) == 1 then
                    return
                end
            end
        end
    end
    entity.health = entity.health + event.final_damage_amount
end

local function on_player_used_spider_remote(event)
    local vehicle = event.vehicle
    local position = event.position
    local success = event.success
    if not success then
        return
    end
    if vehicle.force.name == 'west' then
        if position.x < -3 then
            return
        end
    else
        if position.x > 3 then
            return
        end
    end
    vehicle.autopilot_destination = nil
end

local function game_in_progress(hatchery)
    local game_tick = game.tick
    if game_tick % 30 ~= 0 then
        return
    end
    if game_tick % 240 == 0 then
        local surface = game.surfaces.nauvis
        local west = game.forces.west
        local east = game.forces.east
        local area = { { -320, -161 }, { 319, 160 } }
        west.chart(surface, area)
        east.chart(surface, area)
        local r = 64
        for _, player in pairs(west.connected_players) do
            east.chart(surface, { { player.position.x - r, player.position.y - r }, { player.position.x + r, player.position.y + r } })
        end
        for _, player in pairs(east.connected_players) do
            west.chart(surface, { { player.position.x - r, player.position.y - r }, { player.position.x + r, player.position.y + r } })
        end
    end
    if storage.game_reset_tick then
        if storage.game_reset_tick < game_tick then
            storage.game_reset_tick = nil
            hatchery.gamestate = 'init'
        end
        return
    end
    if game_tick % 1200 == 0 then
        send_unit_groups()
    end
    nom()
end

local no_mirror_states = {
    ['init'] = true,
    ['reset_nauvis'] = true,
    ['prepare_east'] = true,
    ['clear_west'] = true
}

local function on_chunk_generated(event)
    local surface = event.surface
    if event.surface.index ~= 1 then
        return
    end

    local left_top = event.area.left_top

    if Terrain.is_out_of_map_chunk(left_top) then
        Terrain.out_of_map(surface, left_top)
        return
    end

    if left_top.x < 0 and not no_mirror_states[hatchery.gamestate] then
        table.insert(hatchery.mirror_queue, { { left_top.x, left_top.y }, 1 })
        Terrain.out_of_map(surface, left_top)
        return
    end

    surface.request_to_generate_chunks({ x = ((left_top.x * -1) - 32) + 16, y = left_top.y + 16 }, 0)
    Terrain.out_of_map_area(surface, left_top)
    Terrain.combat_area(event)
end

local gamestates = {
    ['init'] = Team.init,
    ['reset_nauvis'] = Terrain.reset_nauvis,
    ['prepare_east'] = Terrain.prepare_east,
    ['clear_west'] = Terrain.clear_west,
    ['prepare_west'] = Terrain.prepare_west,
    ['draw_team_nests'] = Terrain.draw_team_nests,
    ['draw_border_beams'] = Terrain.draw_border_beams,
    ['spawn_players'] = Team.spawn_players,
    ['rejoin_question'] = Gui.rejoin_question,
    ['game_in_progress'] = game_in_progress
}

local function on_tick()
    Terrain.mirror_queue(hatchery)
    gamestates[hatchery.gamestate](hatchery)
end

local function on_init()
    hatchery.gamestate = 'init'
    hatchery.reset_counter = 0
    hatchery.mirror_queue = {}

    game.permissions.get_group('Default').set_allows_action(defines.input_action.open_blueprint_library_gui, false)
    game.permissions.get_group('Default').set_allows_action(defines.input_action.import_blueprint_string, false)

    game.difficulty_settings.technology_price_multiplier = 0.5
    game.map_settings.enemy_evolution.destroy_factor = 0
    game.map_settings.enemy_evolution.pollution_factor = 0
    game.map_settings.enemy_evolution.time_factor = 0
    game.map_settings.enemy_expansion.enabled = false
    game.map_settings.pollution.enabled = false
    storage.map_forces = {
        ['west'] = {},
        ['east'] = {}
    }

    local T = Map.Pop_info()
    T.main_caption = 'Biter Hatchery'
    T.sub_caption = '*nibble nibble nom nom*'
    T.text =
        table.concat(
            {
                'Defeat the enemy teams nest.\n',
                'Feed your hatchery science flasks to breed biters!\n',
                'They will soon after swarm to the opposing teams nest!\n',
                '\n',
                'Lay transport belts to your hatchery and they will happily nom the science juice off the conveyor.\n',
                'Higher tier flasks will breed stronger biters!\n',
                '\n',
                'Player turrets are disabled.\n',
                'Feeding may spawn friendly worm turrets.\n',
                'The center river may not be crossed.\n',
                'Construction robots may not build over the river.\n'
            }
        )
    T.main_caption_color = { r = 150, g = 0, b = 255 }
    T.sub_caption_color = { r = 0, g = 250, b = 150 }

    Team.create_forces()
    Team.reset_forces()
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_player_used_spider_remote, on_player_used_spider_remote)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
