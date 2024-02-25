local Event = require 'utils.event'
local Server = require 'utils.server'
local Timestamp = require 'utils.timestamp'
local Discord = require 'utils.discord_handler'

local format = string.format

local function on_console_command(event)
    local cmd = event.command

    local commands = {
        ['editor'] = true,
        ['command'] = true,
        ['silent-command'] = true,
        ['sc'] = true,
        ['debug'] = true
    }

    if not commands[cmd] then
        return
    end
    local param = event.parameters

    local server_time = Server.get_current_time()
    if server_time then
        server_time = format(' (Server time: %s)', Timestamp.to_string(server_time))
    else
        server_time = ' at tick: ' .. game.tick
    end

    if string.len(param) <= 0 then
        param = nil
    end

    local server_name = Server.get_server_name() or 'CommandHandler'

    if event.player_index then
        local player = game.get_player(event.player_index)

        if not player.admin then
            return
        end

        if param then
            Discord.send_notification_raw(server_name, player.name .. ' ran: ' .. cmd .. ' "' .. param .. '" ' .. server_time)
            print('[COMMAND HANDLER] ' .. player.name .. ' ran: ' .. cmd .. ' "' .. param .. '" ' .. server_time)
            return
        else
            Discord.send_notification_raw(server_name, player.name .. ' ran: ' .. cmd .. server_time)
            print('[COMMAND HANDLER] ' .. player.name .. ' ran: ' .. cmd .. server_time)
            return
        end
    end

    if param then
        Discord.send_notification_raw(server_name, cmd .. ' "' .. param .. '" ' .. server_time)
        print('[COMMAND HANDLER] ran: ' .. cmd .. ' "' .. param .. '" ' .. server_time)
        return
    else
        Discord.send_notification_raw(server_name, cmd .. server_time)
        print('[COMMAND HANDLER] ran: ' .. cmd .. server_time)
        return
    end
end

Event.add(defines.events.on_console_command, on_console_command)

Event.add(
    defines.events.on_player_promoted,
    function(event)
        local player = game.get_player(event.player_index)
        local server_name = Server.get_server_name() or 'CommandHandler'
        Discord.send_notification_raw(server_name, player.name .. ' was promoted.')
    end
)

Event.add(
    defines.events.on_player_demoted,
    function(event)
        local player = game.get_player(event.player_index)
        local server_name = Server.get_server_name() or 'CommandHandler'
        Discord.send_notification_raw(server_name, player.name .. ' was demoted.')
    end
)

Event.add(
    defines.events.on_player_kicked,
    function(event)
        local player = game.get_player(event.player_index)
        local server_name = Server.get_server_name() or 'CommandHandler'
        Discord.send_notification_raw(server_name, player.name .. ' was kicked.')
    end
)
