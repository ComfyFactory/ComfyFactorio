--[[

Mountain Fortress v3 is maintained by Gerkiz and hosted by Comfy.

Want to host it? Ask Gerkiz at discord!

]]

if not script.active_mods['MtnFortressAddons'] then
    error('Mtn Fortress Addons mod is not enabled! Please download it from the mod website.')
end

require 'modules.shotgun_buff'
require 'modules.no_deconstruction_of_neutral_entities'
require 'maps.mountain_fortress_v3.ic.main'
require 'modules.wave_defense.main'
require 'modules.melee_mode'

local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Public = require 'maps.mountain_fortress_v3.core'
local Discord = require 'utils.discord'
local IC = require 'maps.mountain_fortress_v3.ic.table'
local ICMinimap = require 'maps.mountain_fortress_v3.ic.minimap'
local Autostash = require 'modules.autostash'
local Group = require 'utils.gui.group'
local PL = require 'utils.gui.player_list'
local Server = require 'utils.server'
local Explosives = require 'modules.explosives'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local WD = require 'modules.wave_defense.table'
local LinkedChests = require 'maps.mountain_fortress_v3.icw.linked_chests'
local Map = require 'modules.map_info'
local RPG = require 'modules.rpg.main'
local Score = require 'utils.gui.score'
local Poll = require 'utils.gui.poll'
local Collapse = require 'modules.collapse'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Task = require 'utils.task_token'
local Alert = require 'utils.alert'
local BottomFrame = require 'utils.gui.bottom_frame'
local AntiGrief = require 'utils.antigrief'
local Misc = require 'utils.commands.misc'
local Modifiers = require 'utils.player_modifiers'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local JailData = require 'utils.datastore.jail_data'
local RPG_Progression = require 'utils.datastore.rpg_data'
local OfflinePlayers = require 'modules.clear_vacant_players'
local Beam = require 'modules.render_beam'
local Commands = require 'utils.commands'
local RobotLimits = require 'modules.robot_limits'
local CustomEvents = require 'utils.created_events'
local RocksYieldOreVeins = require 'maps.mountain_fortress_v3.rocks_yield_ore_veins'
local SpawnersContainBiters = require 'modules.spawners_contain_biters'

local send_ping_to_channel = Discord.channel_names.mtn_channel
local role_to_mention = Discord.role_mentions.mtn_fortress
local mapkeeper = '[color=blue]Mapkeeper:[/color]'

local floor = math.floor
local remove = table.remove
local abs = math.abs
RPG.disable_cooldowns_on_spells()
Gui.mod_gui_button_enabled = true
Gui.button_style = 'mod_gui_button'
Gui.set_mod_gui_top_frame(true)

local collapse_kill =
{
    entities =
    {
        ['laser-turret'] = true,
        ['flamethrower-turret'] = true,
        ['gun-turret'] = true,
        ['artillery-turret'] = true,
        ['land-mine'] = true,
        ['locomotive'] = true,
        ['cargo-wagon'] = true,
        ['character'] = true,
        ['car'] = true,
        ['tank'] = true,
        ['assembling-machine'] = true,
        ['furnace'] = true,
        ['steel-chest'] = true
    },
    callback = Public.fishy_callback_token,
    enabled = true
}

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

local is_position_near_tbl = function (position, tbl)
    local status = false
    local function inside(pos)
        return pos.x >= position.x and pos.y >= position.y and pos.x <= position.x and pos.y <= position.y
    end

    for i = 1, #tbl do
        if inside(tbl[i]) then
            status = true
        end
    end

    return status
end

local is_locomotive_valid = function ()
    local locomotive = Public.get('locomotive')
    if game.ticks_played < 1000 then return end
    if not locomotive or not locomotive.valid then
        Public.game_is_over()
    end
end

local is_player_valid = function ()
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        if player.connected and player.controller_type == 2 then
            player.set_controller { type = defines.controllers.god }
            player.create_character()
        end
    end
end

local has_the_game_ended = function ()
    local game_reset_tick = Public.get('game_reset_tick')
    if game_reset_tick then
        if game_reset_tick < 0 then
            return
        end

        local this = Public.get()

        this.game_reset_tick = this.game_reset_tick - 30
        if this.game_reset_tick % 600 == 0 then
            if this.game_reset_tick > 0 then
                local cause_msg
                if this.restart then
                    cause_msg = 'restart'
                elseif this.shutdown then
                    cause_msg = 'shutdown'
                elseif this.soft_reset then
                    cause_msg = 'soft-reset'
                end

                game.print(({ 'main.reset_in', cause_msg, this.game_reset_tick / 60 }), { color = { r = 0.22, g = 0.88, b = 0.22 } })
            end

            if this.soft_reset and this.game_reset_tick == 0 then
                this.game_reset_tick = nil
                Public.set_scores()
                Public.set_task('move_players', 'Init')
                return
            end

            if this.restart and this.game_reset_tick == 0 then
                if not this.announced_message then
                    Public.set_scores()
                    game.print(({ 'entity.notify_restart' }), { color = { r = 0.22, g = 0.88, b = 0.22 } })
                    local message = 'Soft-reset is disabled! Server will restart from scenario to load new changes.'
                    Server.to_discord_bold(table.concat { '*** ', message, ' ***' })
                    Server.start_scenario('Mountain_Fortress_v3')
                    this.announced_message = true
                    return
                end
            end
            if this.shutdown and this.game_reset_tick == 0 then
                if not this.announced_message then
                    Public.set_scores()
                    game.print(({ 'entity.notify_shutdown' }), { color = { r = 0.22, g = 0.88, b = 0.22 } })
                    local message = 'Soft-reset is disabled! Server will shutdown. Most likely because of updates.'
                    Server.to_discord_bold(table.concat { '*** ', message, ' ***' })
                    Server.stop_scenario()
                    this.announced_message = true
                    return
                end
            end
        end
    end
end

local chunk_load = function ()
    local chunk_load_tick = Public.get('chunk_load_tick')
    local tick = game.tick
    if chunk_load_tick then
        if chunk_load_tick < tick then
            Public.set('force_chunk', false)
            Public.remove('chunk_load_tick')
            Task.set_queue_speed(8)
        end
    end
end

local collapse_message =
    Task.register(
        function (data)
            local pos = data.position
            local message = data.message
            local collapse_position =
            {
                position = pos
            }
            Alert.alert_all_players_location(collapse_position, message)
        end
    )

local lock_locomotive_positions = function ()
    local locomotive = Public.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    local function check_position(tbl, pos)
        for i = 1, #tbl do
            if tbl[i].x == pos.x and tbl[i].y == pos.y then
                return true
            end
        end
        return false
    end

    local locomotive_positions = Public.get('locomotive_pos')
    local p = { x = floor(locomotive.position.x), y = floor(locomotive.position.y) }
    local success = is_position_near_tbl(locomotive.position, locomotive_positions.tbl)
    if not success and not check_position(locomotive_positions.tbl, p) then
        locomotive_positions.tbl[#locomotive_positions.tbl + 1] = { x = p.x, y = p.y }
    end

    local total_pos = #locomotive_positions.tbl
    if total_pos > 30 then
        remove(locomotive_positions.tbl, 1)
    end
end

local compare_collapse_and_train = function ()
    local collapse_pos = Collapse.get_position()
    local locomotive = Public.get('locomotive')
    if not (locomotive and locomotive.valid) then
        return
    end

    local c_y = abs(collapse_pos.y)
    local t_y = abs(locomotive.position.y)
    local result = abs(c_y - t_y)
    local gap_between_zones = Public.get('gap_between_zones')
    local pre_final_battle = Public.get('pre_final_battle')
    if pre_final_battle then
        local reverse_collapse_pos = Collapse.get_reverse_position()
        if reverse_collapse_pos then
            local r_c_y = abs(reverse_collapse_pos.y)
            local reverse_result = abs(r_c_y - t_y)
            if reverse_result > 200 then
                Collapse.reverse_start_now(true, false)
                Collapse.set_speed(1)
                Collapse.set_amount(40)
            else
                if Collapse.has_reverse_collapse_started() then
                    Collapse.reverse_start_now(false, true)
                    Public.find_void_tiles_and_replace()
                end
            end
        end

        if result > 200 then
            Collapse.start_now(true, false)
            Collapse.set_speed(1)
            Collapse.set_amount(40)
        else
            if Collapse.has_collapse_started() then
                Collapse.start_now(false, true)
            end
        end
        return
    end

    local distance = result > gap_between_zones.gap
    if not distance then
        Collapse.set_force_mode(false)
        Public.set_difficulty()
    else
        Collapse.set_force_mode(false)
        Collapse.set_speed(1)
        Collapse.set_amount(10)
        Collapse.set_force_mode(true)
    end
end

local collapse_after_wave_200 = function ()
    local final_battle = Public.get('final_battle')
    if final_battle then
        return
    end

    local collapse_grace = Public.get('collapse_grace')
    if not collapse_grace then
        return
    end

    if Collapse.has_collapse_started() then
        return
    end

    if WD.get('paused') then
        return
    end

    local wave_number = WD.get_wave()

    if wave_number >= 200 and not Collapse.has_collapse_started() then
        Collapse.start_now(true)
        local data =
        {
            position = Collapse.get_position()
        }
        data.message = ({ 'breached_wall.collapse_start' })
        Task.set_timeout_in_ticks(100, collapse_message, data)
    end
end

local handle_changes = function ()
    Public.set('restart', true)
    Public.set('soft_reset', false)
    Server.output_script_data('Received new changes from backend.')
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
        current_task.step = current_task.step + 1
        Public[old_task](current_task)
        if current_task.message and current_task.show_messages then
            game.print(mapkeeper .. ' ' .. current_task.message)
        end
    end
end

local nth_40_tick = function ()
    if game.tick < 30 then return end
    local update_gui = Public.update_gui
    local players = game.connected_players

    for i = 1, #players do
        local player = players[i]
        update_gui(player)
    end
    lock_locomotive_positions()
    is_player_valid()
    is_locomotive_valid()
    has_the_game_ended()
    chunk_load()
end

local nth_250_tick = function ()
    if game.tick < 500 then return end
    local game_won = Public.get('game_won')
    if game_won then
        return
    end
    compare_collapse_and_train()
    collapse_after_wave_200()
    Public.set_spawn_position()
end

local nth_1000_tick = function ()
    if game.tick < 500 then return end
    local game_won = Public.get('game_won')
    if game_won then
        return
    end
    Public.set_difficulty()
    Public.is_creativity_mode_on()
end

function Public.move_players(current_task)
    local surface = game.get_surface(current_task.surface_name)
    if not surface or not surface.valid then
        return
    end

    for _, player in pairs(game.players) do
        if current_task.surface_name == 'Init' then
            player.zoom = 0.1
        end
        local pos = surface.find_non_colliding_position("character", { x = 0, y = 0 }, 5, 4)
        if pos then
            player.teleport(pos, surface)
        else
            player.teleport({ x = 0, y = 0 }, surface)
        end
        player.clear_items_inside()
    end
    local starting_planet = Public.get_planet()
    current_task.message = 'Moved players to initial surface!'
    current_task.delay = game.tick + 1
    current_task.state_id = 1
    current_task.starting_planet = starting_planet
    current_task.state = 'pre_init_task'
end

function Public.pre_init_task(current_task)
    local this = Public.get()
    game.speed = 1

    local active_surface_index = Public.get('active_surface_index')
    if active_surface_index then
        local surface = game.surfaces[active_surface_index]
        if surface and surface.valid then
            game.delete_surface(surface.name)
        end
    end

    current_task.done = nil
    current_task.step = 1

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

    local current_planet = Public.get_planet()
    SpawnersContainBiters.add_surface(current_planet)

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

    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        Score.init_player_table(player, true)
        Misc.insert_all_items(player)
        Modifiers.reset_player_modifiers(player)
        if player.gui.left['mvps'] then
            player.gui.left['mvps'].destroy()
        end
        WD.destroy_wave_gui(player)
        ICMinimap.kill_minimap(player)
        Event.raise(Public.events.reset_map, { player_index = player.index })
        Public.add_player_to_permission_group(player, 'init_island', true)
        player.print(mapkeeper .. ' Map is resetting, please wait a moment. All GUI buttons are disabled at the moment.')
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
    current_task.state_id = 2
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
    current_task.state = 'clear_fortress'
    current_task.state_id = 3
end

function Public.clear_fortress(current_task)
    local surface = game.surfaces[current_task.starting_planet]
    if surface then
        game.delete_surface(surface.name)
        -- surface.request_to_generate_chunks({ x = -20, y = -22 }, 1)
        -- surface.force_generate_chunk_requests()
        Public.set('active_surface_index', nil)
    end

    current_task.state = 'create_custom_fortress_surface'
    current_task.delay = game.tick + 100
    current_task.message = 'Cleared fortress!'
    current_task.state_id = 4
end

function Public.create_custom_fortress_surface(current_task)
    Public.set('active_surface_index', Public.create_surface(true))
    local active_surface_index = Public.get('active_surface_index')

    WD.set('surface_index', active_surface_index)
    current_task.message = 'Created custom fortress surface!'
    current_task.delay = game.tick + 100
    current_task.state = 'reset_map'
    current_task.state_id = 5
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
    IC.allowed_surface(game.surfaces[this.active_surface_index].name)
    game.reset_time_played()

    OfflinePlayers.init(this.active_surface_index)
    OfflinePlayers.set_enabled(true)
    -- OfflinePlayers.set_offline_players_surface_removal(true)

    Group.reset_groups()
    Group.alphanumeric_only(false)

    Public.disable_tech()

    local surface = game.surfaces[this.active_surface_index]

    if this.winter_mode then
        surface.daytime = 0.45
    end

    if surface.name == 'fulgora' then
        force.technologies['planet-discovery-fulgora'].researched = true
    elseif surface.name == 'vulcanus' then
        force.technologies['planet-discovery-vulcanus'].researched = true
    elseif surface.name == 'gleba' then
        force.technologies['planet-discovery-gleba'].researched = true
    elseif surface.name == 'aquilo' then
        force.technologies['planet-discovery-aquilo'].researched = true
    elseif surface.name == 'fortress' then
        surface.ignore_surface_conditions = true
        if Public.is_modded_pt2 then
            force.technologies['planet-discovery-fortress'].researched = true
            force.technologies['planet-discovery-gleba'].researched = true
            force.technologies['planet-discovery-vulcanus'].researched = true
            force.technologies['planet-discovery-fulgora'].researched = true
            force.technologies['planet-discovery-aquilo'].researched = true
            force.recipes['lightning-rod'].enabled = true -- how else will players deal with lightning?
        end
    end

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
    Event.raise(CustomEvents.events.on_game_reset, {})

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
    current_task.delay = game.tick + 100
    current_task.state = 'post_init_task'
    current_task.state_id = 6
end

function Public.post_init_task(current_task)
    Public.stateful.increase_enemy_damage_and_health()

    current_task.message = 'Post init done!'
    current_task.state = 'create_locomotive'
    current_task.state_id = 7
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

    Server.output_script_data('Created locomotive!')

    Public.render_train_hp()
    Public.render_direction(surface, adjusted_zones.reversed)

    local locomotive = Public.get('locomotive')
    if locomotive and locomotive.valid then
        WD.set_main_target(locomotive)
    end

    current_task.message = 'Created locomotive!'
    current_task.delay = game.tick + 100
    current_task.state = 'announce_new_map'
    current_task.state_id = 8
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
    current_task.delay = game.tick + 100
    current_task.state_id = 9
end

function Public.to_fortress(current_task)
    local surface = game.get_surface(current_task.surface_name)
    if not surface or not surface.valid then
        return
    end
    local adjusted_zones = Public.get('adjusted_zones')
    local position

    WD.set('game_lost', false)

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

    for _, player in pairs(game.connected_players) do
        local pos = surface.find_non_colliding_position('character', position, 5, 4)
        if pos then
            player.teleport({ x = pos.x, y = pos.y }, surface)
        else
            player.teleport({ x = position.x, y = position.y }, surface)
        end
        Public.add_player_to_permission_group(player, 'near_locomotive', true)
    end

    RPG.rpg_reset_all_players()
    local starting_items = Public.get_func('starting_items')
    Public.equip_players(starting_items, false)

    Public.stateful.activate_delayed_techs(game.forces.player)

    current_task.message = 'Moved players back to fortress!'
    current_task.state_id = 10
    current_task.done = true
end

function Public.init_mtn()
    Misc.bottom_button(true)
    BottomFrame.activate_custom_buttons(true)
    Autostash.bottom_button(true)
    Autostash.insert_into_furnace(true)
    Autostash.insert_into_wagon(true)
    Difficulty.set_gui_width(20)
    Difficulty.show_gui(false)


    RPG_Progression.toggle_module(false)
    RPG_Progression.set_dataset('mtn_v3_rpg_prestige')

    if Public.get('prestige_system_enabled') then
        RPG_Progression.restore_xp_on_reset()
    end

    WD.alert_boss_wave(true)
    WD.enable_side_target(false)
    WD.remove_entities(true)
    WD.enable_threat_log(false) -- creates waaaay to many entries in the global table
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

    RobotLimits.enable(false)

    Explosives.slow_explode(true)
    BiterHealthBooster.acid_nova(true)
    BiterHealthBooster.check_on_entity_died(true)
    BiterHealthBooster.boss_spawns_projectiles(true)
    BiterHealthBooster.enable_boss_loot(false)
    BiterHealthBooster.enable_randomize_stun_and_slowdown_sticker(true)
    AntiGrief.enable_capsule_warning(false)
    AntiGrief.enable_capsule_cursor_warning(false)
    AntiGrief.enable_jail(true)
    AntiGrief.damage_entity_threshold(20)
    AntiGrief.filtered_types_on_decon({ 'tree', 'simple-entity', 'fish' })
    AntiGrief.set_limit_per_table(2000)
    PL.show_roles_in_list(true)
    PL.rpg_enabled(true)
    Collapse.set_kill_specific_entities(collapse_kill)

    Public.create_landing_surface()

    local tooltip =
    {
        [1] = ({ 'main.diff_tooltip', '500', '50%', '15%', '15%', '1', '12', '50', '10000', '100%', '15', '10' }),
        [2] = ({ 'main.diff_tooltip', '300', '25%', '10%', '10%', '2', '10', '50', '7000', '75%', '8', '8' }),
        [3] = ({ 'main.diff_tooltip', '50', '0%', '0%', '0%', '4', '3', '10', '5000', '50%', '5', '6' })
    }
    Difficulty.set_tooltip(tooltip)

    local T = Map.get_map_information()
    T.localised_category = 'mountain_fortress_v3'
    T.main_caption_color = { r = 150, g = 150, b = 0 }
    T.sub_caption_color = { r = 0, g = 150, b = 0 }

    Explosives.set_destructible_tile('out-of-map', 1500)
    Explosives.set_destructible_tile('void-tile', 1500)
    Explosives.set_destructible_tile('snow-tile', 1500)
    Explosives.set_destructible_tile('water', 1000)
    Explosives.set_destructible_tile('water-green', 1000)
    Explosives.set_destructible_tile('deepwater-green', 1000)
    Explosives.set_destructible_tile('deepwater', 1000)
    Explosives.set_destructible_tile('water-shallow', 1000)
    Explosives.set_destructible_tile('water-mud', 1000)
    Explosives.set_destructible_tile('lab-dark-2', 1000)
    Explosives.set_destructible_tile('lava', 500)
    Explosives.set_destructible_tile('lava-hot', 500)
    Explosives.set_destructible_tile('wetland-dead-skin', 1000)
    Explosives.set_destructible_tile('wetland-light-dead-skin', 1000)
    Explosives.set_destructible_tile('wetland-green-slime', 1000)
    Explosives.set_destructible_tile('wetland-light-green-slime', 1000)
    Explosives.set_destructible_tile('wetland-red-tentacle', 1000)
    Explosives.set_destructible_tile('wetland-pink-tentacle', 1000)
    Explosives.set_destructible_tile('wetland-blue-slime', 1000)
    Explosives.set_destructible_tile('wetland-yumako', 1000)
    Explosives.set_destructible_tile('wetland-jellynut', 1000)
    Explosives.set_destructible_tile('brash-ice', 1000)
    Explosives.set_destructible_tile('ammoniacal-ocean', 1000)
    Explosives.set_destructible_tile('ammoniacal-ocean-2', 1000)
    Explosives.set_destructible_tile('gleba-deep-lake', 1000)

    Explosives.set_whitelist_entity('straight-rail')
    Explosives.set_whitelist_entity('curved-rail-a')
    Explosives.set_whitelist_entity('curved-rail-b')
    Explosives.set_whitelist_entity('half-diagonal-rail')
    Explosives.set_whitelist_entity('character')
    Explosives.set_whitelist_entity('spidertron')
    Explosives.set_whitelist_entity('car')
    Explosives.set_whitelist_entity('tank')
end

Server.on_scenario_changed(
    'Mountain_Fortress_v3',
    function (data)
        local scenario = data.scenario
        if scenario == 'Mountain_Fortress_v3' then
            handle_changes()
            -- Server.save_hot_patch()
        end
    end
)

Event.add(defines.events.on_tick, scenario_manager)
Event.on_nth_tick(40, nth_40_tick)
Event.on_nth_tick(250, nth_250_tick)
Event.on_nth_tick(1000, nth_1000_tick)
Event.on_init(function ()
    Public.init_mtn()
    Public.create_lookup_table()
end)

return Public
