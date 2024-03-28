local Poll = {
    send_poll_result_to_discord = function()
    end
}
local Token = require 'utils.token'
local Server = require 'utils.server'

--- This module is for the web server to call functions and raise events.
-- Not intended to be called by scripts.
-- Needs to be in the _G table so it can be accessed by the web server.
ServerCommands = {}

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
    script.raise_event(Server.events.on_server_started, {})
end

function ServerCommands.changes_detected()
    script.raise_event(Server.events.on_changes_detected, {})
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

function is_loaded(module)
    local res = _G.package.loaded[module]
    if res then
        return res
    end

    return false
end

function is_loaded_bool(module)
    local res = _G.package.loaded[module]
    if res then
        return true
    end

    return false
end

function is_game_modded()
    local active_mods = game.active_mods
    local i = 0
    for _, _ in pairs(active_mods) do
        i = i + 1
        if i > 1 then
            return true
        end
    end
    return false
end

return ServerCommands
