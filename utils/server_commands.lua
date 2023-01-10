local Poll = {
    send_poll_result_to_discord = function()
    end
}
local Token = require 'utils.token'
local Server = require 'utils.server'
local branch_version = '1.1' -- define what game version we're using
local sub = string.sub

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
ServerCommands.get_tracked_data_sets = Server.get_tracked_data_sets

function ServerCommands.server_started()
    script.raise_event(Server.events.on_server_started, {})
end

function ServerCommands.changes_detected()
    script.raise_event(Server.events.on_changes_detected, {})
end

ServerCommands.set_time = Server.set_time
ServerCommands.set_ups = Server.set_ups
ServerCommands.get_ups = Server.get_ups
ServerCommands.export_stats = Server.export_stats
ServerCommands.set_start_data = Server.set_start_data
ServerCommands.set_instances = Server.set_instances
ServerCommands.query_online_players = Server.query_online_players
ServerCommands.ban_handler = Server.ban_handler

local SC_Interface = {
    get_ups = function()
        return ServerCommands.get_ups()
    end,
    set_ups = function(tick)
        if tick then
            ServerCommands.set_ups(tick)
        else
            error("Remote call parameter to ServerCommands set_ups can't be nil.")
        end
    end
}

if not remote.interfaces['ServerCommands'] then
    remote.add_interface('ServerCommands', SC_Interface)
end

function get_game_version()
    local get_active_branch = sub(game.active_mods.base, 3, 4)
    local is_branch_experimental = sub(branch_version, 3, 4)
    if get_active_branch >= is_branch_experimental then
        return true
    else
        return false
    end
end

function is_loaded(module)
    local res = _G.package.loaded[module]
    if res then
        return res
    else
        return false
    end
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

function is_mod_loaded(module)
    if not module then
        return false
    end

    local res = game.active_mods[module]
    if res then
        return true
    else
        return false
    end
end

return ServerCommands
