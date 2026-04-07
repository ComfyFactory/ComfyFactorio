---@diagnostic disable: lowercase-global
local Event = require 'utils.event'

--- This module is for the web server to call functions and raise events.
-- Not intended to be called by scripts.
-- Needs to be in the _G table so it can be accessed by the web server.
ServerCommands = {}

--- This module is used to raise events that can be used throughout the game.
-- Without the need of requiring other modules.
ServerCommands.events =
{
    on_entity_mined = Event.generate_event_name('on_entity_mined'),
    custom_on_entity_died = Event.generate_event_name('custom_on_entity_died'),
    remove_surface = Event.generate_event_name('remove_surface'),
    reset_game = Event.generate_event_name('reset_game'),
    init_surfaces = Event.generate_event_name('init_surfaces'),
    on_spell_cast_success = Event.generate_event_name('on_spell_cast_success'),
    on_spell_cast_failure = Event.generate_event_name('on_spell_cast_failure'),
    on_wave_created = Event.generate_event_name('on_wave_created'),
    on_unit_group_created = Event.generate_event_name('on_unit_group_created'),
    on_evolution_factor_changed = Event.generate_event_name('on_evolution_factor_changed'),
    on_game_reset = Event.generate_event_name('on_game_reset'),
    on_target_aquired = Event.generate_event_name('on_target_aquired'),
    on_primary_target_missing = Event.generate_event_name('on_primary_target_missing'),
    on_entity_created = Event.generate_event_name('on_entity_created'),
    on_biters_evolved = Event.generate_event_name('on_biters_evolved'),
    on_spawn_unit_group = Event.generate_event_name('on_spawn_unit_group'),
    on_spawn_unit_group_simple = Event.generate_event_name('on_spawn_unit_group_simple'),
    on_gui_removal = Event.generate_event_name('on_gui_removal'),
    on_gui_closed_main_frame = Event.generate_event_name('on_gui_closed_main_frame'),
    on_player_removed = Event.generate_event_name('on_player_removed'),

    -- rpg
    on_rpg_callback_added = Event.generate_event_name('on_rpg_callback_added'),

    -- config events
    on_config_changed = Event.generate_event_name('on_config_changed'),

    -- server events
    on_server_started = Event.generate_event_name('on_server_started'),
    on_changes_detected = Event.generate_event_name('on_changes_detected'),
    on_player_banned = Event.generate_event_name('on_player_banned'),
    on_player_jailed = Event.generate_event_name('on_player_jailed'),
    on_player_unjailed = Event.generate_event_name('on_player_unjailed'),

    -- bottom frame events
    bottom_quickbar_respawn_raise = Event.generate_event_name('bottom_quickbar_respawn_raise'),
    bottom_quickbar_location_changed = Event.generate_event_name('bottom_quickbar_location_changed'),

    -- poll events
    on_poll_complete = Event.generate_event_name('on_poll_complete'),
    on_poll_created = Event.generate_event_name('on_poll_created'),

    -- session data events
    on_player_trusted = Event.generate_event_name('on_player_trusted'),
    on_player_untrusted = Event.generate_event_name('on_player_untrusted'),

    -- role events
    on_role_change = Event.generate_event_name('on_role_change'),
}

local Poll =
{
    send_poll_result_to_discord = function ()
    end
}
local Token = require 'utils.token'
local Server = require 'utils.server'
local DevServer = require 'utils.dev_server'

ServerCommands.get_poll_result = Poll.send_poll_result_to_discord

function ServerCommands.raise_callback(func_token, data)
    local func = Token.get(func_token)
    func(data)
end

ServerCommands.raise_data_set = Server.raise_data_set
ServerCommands.raise_admins = Server.raise_admins
ServerCommands.get_tracked_data_sets = Server.get_tracked_data_sets

ServerCommands.raise_scenario_changed = Server.raise_scenario_changed
ServerCommands.get_tracked_scenario = Server.get_tracked_scenario

function ServerCommands.server_started()
    script.raise_event(ServerCommands.events.on_server_started, {})
end

function ServerCommands.changes_detected()
    script.raise_event(ServerCommands.events.on_changes_detected, {})
end

ServerCommands.set_time = Server.set_time
ServerCommands.set_output = Server.set_output
ServerCommands.set_ups = Server.set_ups
ServerCommands.get_ups = Server.get_ups
ServerCommands.export_stats = Server.export_stats
ServerCommands.set_start_data = Server.set_start_data
ServerCommands.set_instances = Server.set_instances
ServerCommands.query_online_players = Server.query_online_players
ServerCommands.ban_handler = Server.ban_handler
ServerCommands.pause_game = Server.pause_game
ServerCommands.is_dev_server = DevServer.is_dev_server

function ServerCommands.is_loaded(module)
    if not module then return end
    module = ServerCommands.normalize_path(module)
    local res = _G.package.loaded[module]
    if res then
        return res
    end

    return false
end

function ServerCommands.is_loaded_bool(module)
    if not module then return end
    module = ServerCommands.normalize_path(module)
    local res = _G.package.loaded[module]
    if res then
        return true
    end

    return false
end

function ServerCommands.is_game_modded()
    local active_mods = script.active_mods
    local i = 0
    for _, _ in pairs(active_mods) do
        i = i + 1
        if i > 1 then
            return true
        end
    end
    return false
end

function ServerCommands.has_space_age()
    local active_mods = script.active_mods['space-age'] ~= nil
    if active_mods then return true end
    return false
end

function ServerCommands.normalize_path(path)
    local level_path = '__level__/' .. path
    return string.gsub(level_path, "%.", "/") .. ".lua"
end

return ServerCommands
