local Public = require 'maps.mountain_fortress_v3.table'
local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Discord = require 'utils.discord'
local IC = require 'maps.mountain_fortress_v3.ic.table'
local ICMinimap = require 'maps.mountain_fortress_v3.ic.minimap'
local Group = require 'utils.gui.group'
local Server = require 'utils.server'
local Explosives = require 'modules.explosives'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local WD = require 'modules.wave_defense.table'
local LinkedChests = require 'maps.mountain_fortress_v3.icw.linked_chests'
local RPG = require 'modules.rpg.main'
local Score = require 'utils.gui.score'
local Poll = require 'utils.gui.poll'
local Collapse = require 'modules.collapse'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Task = require 'utils.task_token'
local BottomFrame = require 'utils.gui.bottom_frame'
local AntiGrief = require 'utils.antigrief'
local Misc = require 'utils.commands.misc'
local Modifiers = require 'utils.player_modifiers'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local JailData = require 'utils.datastore.jail_data'
local OfflinePlayers = require 'modules.clear_vacant_players'
local Beam = require 'modules.render_beam'
local Commands = require 'utils.commands'
local RocksYieldOreVeins = require 'maps.mountain_fortress_v3.rocks_yield_ore_veins'
local SpawnersContainBiters = require 'modules.spawners_contain_biters'
local Session = require 'utils.datastore.session_data'
local RPG_Settings = require 'utils.datastore.rpg_data'
local Core = require 'utils.core'

local send_ping_to_channel = Discord.channel_names.mtn_channel
local role_to_mention = Discord.role_mentions.mtn_fortress
local mapkeeper = '[color=blue]Mapkeeper:[/color]'

local abs = math.abs

local init_bonus_drill_force = function ()
    local bonus_drill = game.forces.bonus_drill
    local player = game.forces.player
    if not bonus_drill then
        bonus_drill = game.create_force('bonus_drill')
    end
    bonus_drill.set_friend('player', true)
    player.set_friend('bonus_drill', true)
    bonus_drill.mining_drill_productivity_bonus = 0.5
end

function Public.clear_old_surface(current_task)
    local old_surface = game.surfaces[current_task.starting_planet]
    if old_surface then
        game.delete_surface(old_surface.name)
        Public.set('active_surface_index', nil)
    end
    current_task.message = 'Cleared old fortress!'
    current_task.delay = game.tick + 5
    current_task.state = 'create_default_surface'
    Server.output_script_data('Cleared old fortress!')
end

function Public.create_default_surface(current_task)
    Public.set('active_surface_index', Public.create_surface(true))
    local active_surface_index = Public.get('active_surface_index')
    WD.set('surface_index', active_surface_index)

    local new_surface = game.get_surface(active_surface_index)
    if new_surface and new_surface.valid then
        Server.output_script_data('New surface created and set as active: ' .. new_surface.name)
    end

    local starting_planet = Public.get_planet()

    current_task.message = 'Created custom fortress surface!'
    current_task.delay = game.tick + 1
    current_task.starting_planet = starting_planet
    current_task.surface_index = active_surface_index
    current_task.state = 'move_players'
    Server.output_script_data('Created custom fortress surface!')
end

function Public.move_players(current_task)
    local surface = game.get_surface(current_task.surface_index)
    if not surface or not surface.valid then
        Server.output_script_data('Failed to get surface! This should not happen.')
        return
    end

    local players = Public.get('players')
    Core.iter_players(function (player)
        if not player.connected then
            player.clear_items_inside()
            players[player.index] = nil
            Session.clear_player(player)
            Server.output_script_data('Removing offline player from init task: ' .. player.name)
        end
        if player.character and player.character ~= nil then
            player.character.destroy()
        end
        player.set_controller { type = defines.controllers.spectator }
    end)

    game.remove_offline_players()

    Core.iter_connected_players(function (player)
        if current_task.surface_name == 'init' then
            player.zoom = 0.1
        end
        player.clear_items_inside()

        if player.controller_type == defines.controllers.god or player.controller_type == defines.controllers.spectator then
            Event.raise(
                ServerCommands.events.bottom_quickbar_respawn_raise,
                {
                    player_index = player.index
                }
            )
        end

        local pos = surface.find_non_colliding_position("character", { x = 0, y = 0 }, 5, 4)
        if pos then
            player.teleport(pos, surface)
        else
            player.teleport({ x = 0, y = 0 }, surface)
        end
        player.clear_items_inside()
    end)
    current_task.message = 'Moved players to initial surface!'
    current_task.state = 'pre_init_task'
    Server.output_script_data('Moved players to initial surface!')
end

function Public.pre_init_task(current_task)
    local this = Public.get()
    game.speed = 1

    if this.health_text and this.health_text.valid then this.health_text.destroy() end
    if this.caption and this.caption.valid then this.caption.destroy() end
    if this.circle and this.circle.valid then this.circle.destroy() end
    if this.current_season and this.current_season.valid then this.current_season.destroy() end
    if this.counter and this.counter.valid then this.counter.destroy() end
    if this.direction_attack and this.direction_attack.valid then this.direction_attack.destroy() end
    if this.zone1_text1 and this.zone1_text1.valid then this.zone1_text1.destroy() end
    if this.zone1_text2 and this.zone1_text2.valid then this.zone1_text2.destroy() end
    if this.zone1_text3 and this.zone1_text3.valid then this.zone1_text3.destroy() end

    for i = 1, 5 do
        if this['direction_' .. i] and this['direction_' .. i].valid then
            this['direction_' .. i].destroy()
        end
    end

    local force = game.forces.player
    force.manual_mining_speed_modifier = 0
    force.character_running_speed_modifier = 0
    force.manual_crafting_speed_modifier = 0
    force.friendly_fire = true

    RocksYieldOreVeins.remove_from_raffle({ 'calcite', 'tungsten-ore' })
    RocksYieldOreVeins.remove_from_mixed_ores({ 'calcite', 'tungsten-ore' })

    local next_planet = Public.get_stateful_settings('next_planet')
    if next_planet then
        Public.set_stateful_settings('current_planet', next_planet)
        Server.output_script_data('Setting current planet to next planet: ' .. next_planet)
    end

    for _, s in pairs(game.surfaces) do
        if s and s.valid then
            SpawnersContainBiters.add_surface(s.name)
        end
    end

    WD.reset_wave_defense()
    WD.alert_boss_wave(true)
    WD.enable_side_target(false)
    WD.remove_entities(true)
    WD.enable_threat_log(false)
    WD.check_collapse_position(true)
    WD.set_disable_threat_below_zero(true)
    WD.increase_boss_health_per_wave(true)
    WD.increase_damage_per_wave(true)
    WD.increase_health_per_wave(true)
    WD.increase_average_unit_group_size(true)
    WD.increase_max_active_unit_groups(true)
    WD.enable_random_spawn_positions(true)
    WD.set_track_bosses_only(true)
    WD.set_pause_waves_custom_callback(Public.pause_waves_custom_callback_token)
    WD.set_threat_event_custom_callback(Public.check_if_spawning_near_train_custom_callback)
    WD.set_es_enabled(true)
    WD.set_es('force_name', 'aggressors')
    BiterHealthBooster.set_module_state(true)

    RPG.set_x_marks_the_spot_custom_callback(Public.x_marks_the_spot_custom_callback_token)
    RPG.set_magicka_custom_callback(Public.magicka_custom_callback_token)
    -- RPG.set_strength_custom_callback(Public.strength_custom_callback_token)
    -- RPG.set_dexterity_custom_callback(Public.dexterity_custom_callback_token)
    -- RPG.set_vitality_custom_callback(Public.vitality_custom_callback_token)

    WD.set('nest_building_density', 32)
    WD.set('spawn_position', { x = 0, y = 84 })
    WD.set('game_lost', true)

    for _, player in pairs(game.players) do
        Score.init_player_table(player, true)
        Misc.insert_all_items(player)
        Modifiers.reset_player_modifiers(player)
        if player.gui.left['mvps'] then
            player.gui.left['mvps'].destroy()
        end
        WD.destroy_wave_gui(player)
        ICMinimap.kill_minimap(player)
        Event.raise(Public.events.reset_map, { player_index = player.index })
    end

    Public.reset_func_table()
    RPG.reset_table()
    Public.stateful.clear_all_frames()
    Public.sr_reset_forces()
    WD.set('wave_interval', 4500)
    Public.set_threat_values()
    Public.set_unit_raffle()
    Public.set_worm_raffle()
    if Public.is_modded then
        Public.set_xp_yield()
    end
    RPG.set_extra('modded_hotkeys', true)
    RPG.set_x_position(700)
    Public.clear_all_chart_tags()
    Explosives.disable(false)

    RPG.set_surface_validation_token(Public.surface_validation_token)

    current_task.message = 'Pre init done!'
    current_task.state = 'init_stateful'
    Server.output_script_data('Pre init done!')
end

function Public.init_stateful(current_task)
    ICW.reset()
    Public.reset_main_table()
    Public.stateful.enable(true)
    Public.stateful.reset_stateful(false, true)
    Public.stateful.apply_startup_settings()

    -- if Public.is_modded then
    --     for _, player in pairs(game.connected_players) do
    --         Public.on_player_created({ player_index = player.index })
    --     end
    -- end

    current_task.message = 'Initialized stateful!'
    current_task.state = 'reset_map'
    Server.output_script_data('Initialized stateful!')
end

function Public.reset_map(current_task)
    local this = Public.get()
    local force = game.forces.player

    Misc.reset()

    LinkedChests.reset()

    BottomFrame.reset()
    Public.reset_buried_biters()
    Poll.reset()
    ICW.set('default_surface', this.default_surface)
    IC.reset()
    IC.allowed_surface(game.surfaces[current_task.surface_index].name)
    game.reset_time_played()

    OfflinePlayers.init(current_task.surface_index)
    OfflinePlayers.set_enabled(true)
    -- OfflinePlayers.set_offline_players_surface_removal(true)

    Group.reset_groups()
    Group.alphanumeric_only(false)

    Public.disable_tech()

    local surface = game.surfaces[current_task.surface_index]

    if this.winter_mode then
        surface.daytime = 0.45
    end

    local current_planet = Public.get_planet()
    if current_planet == 'nauvis' then
        game.surfaces['nauvis'].clear()
    end

    current_task.starting_planet = current_planet


    surface.ignore_surface_conditions = true
    force.technologies['planet-discovery-fortress'].researched = true
    force.technologies['planet-discovery-gleba'].researched = true
    force.technologies['planet-discovery-vulcanus'].researched = true
    force.technologies['planet-discovery-fulgora'].researched = true
    force.technologies['planet-discovery-aquilo'].researched = true
    -- force.recipes['lightning-rod'].enabled = true -- how else will players deal with lightning?

    -- surface.brightness_visual_weights = { 0.7, 0.7, 0.7 }

    JailData.set_valid_surface(tostring(surface.name))
    JailData.reset_vote_table()
    Explosives.set_surface_whitelist({ [surface.name] = true })
    Beam.reset_valid_targets()
    BiterHealthBooster.set_active_surface(tostring(surface.name))

    -- AntiGrief.whitelist_types('tree', true)

    AntiGrief.decon_surface_blacklist(surface.name)

    Score.reset_tbl()

    Difficulty.reset_difficulty_poll({ closing_timeout = game.tick + 36000 })
    Collapse.set_max_line_size(620, true)
    Collapse.set_speed(8)
    Collapse.set_amount(1)
    Collapse.set_force_mode(false)
    Collapse.set_surface_index(surface.index)
    Collapse.start_now(false)
    Collapse.reverse_start_now(false, false)

    init_bonus_drill_force()

    Public.init_enemy_weapon_damage()

    force.set_ammo_damage_modifier('artillery-shell', -0.95)
    force.worker_robots_battery_modifier = 4
    force.worker_robots_storage_bonus = 15

    -- WD.set_es_unit_limit(400) -- moved to stateful
    Event.raise(ServerCommands.events.on_game_reset, {})

    Public.set_difficulty()
    Public.disable_creative()
    Public.boost_difficulty()
    Commands.restore_states()

    if this.adjusted_zones.reversed then
        if not surface.is_chunk_generated({ x = -20, y = -22 }) then
            surface.request_to_generate_chunks({ x = -20, y = -22 }, 1)
            surface.force_generate_chunk_requests()
        end
        game.forces.player.set_spawn_position({ x = -27, y = -25 }, surface)
        WD.set_spawn_position({ x = -16, y = -80 })
        WD.enable_inverted(true)
    else
        if not surface.is_chunk_generated({ x = -20, y = 22 }) then
            surface.request_to_generate_chunks({ x = -20, y = 22 }, 1)
            surface.force_generate_chunk_requests()
        end
        game.forces.player.set_spawn_position({ x = -27, y = 25 }, surface)
        WD.set_spawn_position({ x = -16, y = 80 })
        WD.enable_inverted(false)
    end

    if this.space_age then
        surface.destroy_decoratives({ name = "brown-cup", invert = true })
        surface.destroy_decoratives({ name = "small-sand-rock", invert = true })
    end

    Task.set_queue_speed(16)

    Public.get_scores()

    this.chunk_load_tick = game.tick + 400
    this.force_chunk = true
    this.market_announce = game.tick + 1200
    this.game_lost = false

    RPG.enable_health_and_mana_bars(true)
    RPG.enable_wave_defense(true)
    RPG.enable_mana(true)
    RPG.personal_tax_rate(0.4)
    RPG.enable_stone_path(true)
    RPG.enable_aoe_punch(true)
    RPG.enable_aoe_punch_globally(false)
    RPG.enable_range_buffs(true)
    RPG.enable_auto_allocate(true)
    RPG.enable_explosive_bullets_globally(true)
    RPG.enable_explosive_bullets(false)

    RPG.set_surface_name({ game.surfaces[this.active_surface_index].name })

    if _DEBUG then
        Collapse.start_now(false)
        WD.disable_spawning_biters(true)
    end

    game.forces.enemy.set_friend('player', false)
    game.forces.aggressors.set_friend('player', false)
    game.forces.aggressors_frenzy.set_friend('player', false)

    game.forces.player.set_friend('enemy', false)
    game.forces.player.set_friend('aggressors', false)
    game.forces.player.set_friend('aggressors_frenzy', false)

    current_task.message = 'Reset map done!'
    current_task.delay = game.tick + 50
    current_task.state = 'post_init_task'
    Server.output_script_data('Reset map done!')
end

function Public.post_init_task(current_task)
    Public.stateful.increase_enemy_damage_and_health()

    current_task.message = 'Post init done!'
    current_task.state = 'create_locomotive'
    Server.output_script_data('Post init done!')
end

function Public.create_locomotive(current_task)
    if Public.get('disable_startup_notification') then return end
    local adjusted_zones = Public.get('adjusted_zones')
    local spawn_near_collapse = Public.get('spawn_near_collapse')
    local surface_index = Public.get('active_surface_index')
    local surface = game.surfaces[surface_index]
    if not surface or not surface.valid then return end

    if adjusted_zones.reversed then
        Explosives.check_growth_below_void(false)
        spawn_near_collapse.compare = abs(spawn_near_collapse.compare)
        Collapse.set_position({ 0, -130 })
        Collapse.set_direction('south')
        Public.locomotive_spawn(surface, { x = -18, y = -25 }, adjusted_zones.reversed)
    else
        Explosives.check_growth_below_void(true)
        spawn_near_collapse.compare = abs(spawn_near_collapse.compare) * -1
        Collapse.set_position({ 0, 130 })
        Collapse.set_direction('north')
        Public.locomotive_spawn(surface, { x = -18, y = 25 }, adjusted_zones.reversed)
    end

    Public.render_train_hp()
    Public.render_direction(surface, adjusted_zones.reversed)

    local locomotive = Public.get('locomotive')
    if locomotive and locomotive.valid then
        WD.set_main_target(locomotive)
        Core.iter_connected_players(function (player)
            player.teleport(locomotive.position, surface)
        end)
    end

    current_task.message = 'Created locomotive!'
    current_task.delay = game.tick + 100
    current_task.state = 'announce_new_map'
    Server.output_script_data('Created locomotive!')
end

function Public.announce_new_map(current_task)
    if Public.get('disable_startup_notification') then return end
    local server_name = Server.check_server_name(Public.discord_name)
    if server_name then
        Server.to_discord_named_raw(send_ping_to_channel, role_to_mention .. ' ** Mtn Fortress was just reset! **')
    end
    local starting_planet = Public.get_planet()
    current_task.message = 'Announced new map!'
    current_task.state = 'to_fortress'
    current_task.surface_name = starting_planet
    current_task.delay = game.tick + 250
    Server.output_script_data('Announced new map!')
end

function Public.to_fortress(current_task)
    WD.set('game_lost', false)
    local surface = game.get_surface(current_task.surface_name)
    if not surface or not surface.valid then
        Server.output_script_data('To Fortress: Surface not valid - please check this out!')
        return
    end
    local adjusted_zones = Public.get('adjusted_zones')
    local position

    if adjusted_zones.reversed then
        game.forces.player.set_spawn_position({ -27, -25 }, surface)
        position = game.forces.player.get_spawn_position(surface)

        if not position then
            game.forces.player.set_spawn_position({ -27, -25 }, surface)
            position = game.forces.player.get_spawn_position(surface)
        end
    else
        game.forces.player.set_spawn_position({ -27, 25 }, surface)
        position = game.forces.player.get_spawn_position(surface)

        if not position then
            game.forces.player.set_spawn_position({ -27, 25 }, surface)
            position = game.forces.player.get_spawn_position(surface)
        end
    end

    RPG.rpg_reset_all_players()
    local starting_items = Public.get_func('starting_items')


    Core.iter_connected_players(function (player)
        local pos = surface.find_non_colliding_position('character', position, 5, 4)
        if pos then
            player.teleport({ x = pos.x, y = pos.y }, surface)
        else
            player.teleport({ x = position.x, y = position.y }, surface)
        end
        Public.add_player_to_permission_group(player, 'near_locomotive', true)

        RPG_Settings.fetch_rpg_settings(player)

        if player.controller_type == defines.controllers.god or player.controller_type == defines.controllers.spectator then
            player.set_controller { type = defines.controllers.god }
            player.create_character()
            Event.raise(
                ServerCommands.events.bottom_quickbar_respawn_raise,
                {
                    player_index = player.index
                }
            )
        end

        for _, ele in pairs(player.gui.top.children) do
            if ele and ele.valid and ele.name ~= Gui.main_toggle_button_name then
                ele.visible = true
            end
        end
        Public.equip_players(player, starting_items, false)
    end)

    Public.stateful.activate_delayed_techs(game.forces.player)

    current_task.message = 'Moved players back to fortress!'
    current_task.done = true
    Server.output_script_data('Moved players back to fortress!')
end

local scenario_manager = function ()
    local current_task = Public.get('current_task')
    if not current_task then return end

    if #game.connected_players == 0 then
        return
    end

    if current_task.delay then
        if game.tick < current_task.delay then
            return
        end
    end

    if Public[current_task.state] then
        local old_task = current_task.state
        current_task.state = 'idle'
        Public[old_task](current_task)
        if current_task.message and current_task.show_messages then
            game.print(mapkeeper .. ' ' .. current_task.message)
        end
    end
end

Event.add(defines.events.on_tick, scenario_manager)

return Public
