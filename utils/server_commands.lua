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
ServerCommands.get_tracked_data_sets = Server.get_tracked_data_sets

function ServerCommands.server_started()
    script.raise_event(Server.events.on_server_started, {})
end

ServerCommands.set_time = Server.set_time
ServerCommands.set_ups = Server.set_ups
ServerCommands.get_ups = Server.get_ups
ServerCommands.export_stats = Server.export_stats
ServerCommands.set_start_data = Server.set_start_data
ServerCommands.query_online_players = Server.query_online_players

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

return ServerCommands
