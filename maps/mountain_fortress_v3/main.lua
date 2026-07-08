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

local Alert = require 'utils.alert'

Alert.filters =
{
    xp = 'notify_xp',
    coins = 'notify_coins',
    vmg = 'notify_vmg'
}

local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Public = require 'maps.mountain_fortress_v3.core'
local Autostash = require 'modules.autostash'
local PL = require 'utils.gui.player_list'
local Server = require 'utils.server'
local Explosives = require 'modules.explosives'
local WD = require 'modules.wave_defense.table'
local Map = require 'modules.map_info'
local RPG = require 'modules.rpg.main'
local Collapse = require 'modules.collapse'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Task = require 'utils.task_token'
local Config = require 'utils.gui.config'
local Color = require 'utils.color_presets'
local BottomFrame = require 'utils.gui.bottom_frame'
local AntiGrief = require 'utils.antigrief'
local Misc = require 'utils.commands.misc'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local RPG_Progression = require 'utils.datastore.rpg_prestige_data'
local RobotLimits = require 'modules.robot_limits'


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
    local current_task = Public.get('current_task')
    if not current_task.done then
        return
    end

    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        if player.connected and player.controller_type == defines.controllers.god then
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
                local current_task = Public.get('current_task')
                Public.set_task(current_task.default_task)
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
            Alert.alert_all_players_location(collapse_position, message, nil, nil, 'global')
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
    Public.set_wd_surface_index()
end

local nth_1000_tick = function ()
    if game.tick < 500 then return end
    local game_won = Public.get('game_won')
    if game_won then
        return
    end
    Public.set_difficulty()
    Public.is_creativity_mode_on()
    Public.check_for_spawners_on_train()
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
    Explosives.set_destructible_tile('oil-ocean-shallow', 1000)

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

Event.on_nth_tick(40, nth_40_tick)
Event.on_nth_tick(250, nth_250_tick)
Event.on_nth_tick(1000, nth_1000_tick)
Event.on_init(function ()
    Public.init_mtn()
    Public.create_minerals_lookup_table()
    Public.create_enemies_lookup_table()
end)

Config.register_scenario_module(
    {
        id = 'alert_notifications',
        admin_only = false,
        gui_rows = Config.register_token(
            function (player, frame)
                local prefs = Alert.get_notify_prefs(player)

                local switch_state = 'left'
                if prefs.notify_xp == false then
                    switch_state = 'right'
                end
                Config.add_switch(frame, switch_state, 'alert_notify_xp_toggle', { 'alert.notify_xp_label' }, { 'alert.notify_xp_tooltip' })
                frame.add({ type = 'line' })

                switch_state = 'left'
                if prefs.notify_coins == false then
                    switch_state = 'right'
                end
                Config.add_switch(frame, switch_state, 'alert_notify_coins_toggle', { 'alert.notify_coins_label' }, { 'alert.notify_coins_tooltip' })
                frame.add({ type = 'line' })

                switch_state = 'left'
                if prefs.notify_vmg == false then
                    switch_state = 'right'
                end
                Config.add_switch(frame, switch_state, 'alert_notify_vmg_toggle', { 'alert.notify_vmg_label' }, { 'alert.notify_vmg_tooltip' })
                frame.add({ type = 'line' })
            end),
        handlers =
        {
            ['alert_notify_xp_toggle'] = Config.register_token(
                function (player, event)
                    if event.element.switch_state == 'left' then
                        Alert.set_notify_pref(player, 'notify_xp', true)
                        player.print('XP notifications enabled.', { color = Color.green })
                    else
                        Alert.set_notify_pref(player, 'notify_xp', false)
                        player.print('XP notifications disabled.', { color = Color.red })
                    end
                end),
            ['alert_notify_coins_toggle'] = Config.register_token(
                function (player, event)
                    if event.element.switch_state == 'left' then
                        Alert.set_notify_pref(player, 'notify_coins', true)
                        player.print('Coin notifications enabled.', { color = Color.green })
                    else
                        Alert.set_notify_pref(player, 'notify_coins', false)
                        player.print('Coin notifications disabled.', { color = Color.red })
                    end
                end),
            ['alert_notify_vmg_toggle'] = Config.register_token(
                function (player, event)
                    if event.element.switch_state == 'left' then
                        Alert.set_notify_pref(player, 'notify_vmg', true)
                        player.print('VMG notifications enabled.', { color = Color.green })
                    else
                        Alert.set_notify_pref(player, 'notify_vmg', false)
                        player.print('VMG notifications disabled.', { color = Color.red })
                    end
                end)
        }
    })

return Public
