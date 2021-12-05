local Event = require 'utils.event'
local Server = require 'utils.server'
local Timestamp = require 'utils.timestamp'
local format = string.format

local function on_console_command(event)
    local cmd = event.command
    if not event.player_index then
        return
    end
    local player = game.players[event.player_index]
    local param = event.parameters

    if not player.admin then
        return
    end

    local server_time = Server.get_current_time()
    if server_time then
        server_time = format(' (Server time: %s)', Timestamp.to_string(server_time))
    else
        server_time = ' at tick: ' .. game.tick
    end

    if string.len(param) <= 0 then
        param = nil
    end

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

    if player then
        if param then
            print('[COMMAND HANDLER] ' .. player.name .. ' ran: ' .. cmd .. ' "' .. param .. '" ' .. server_time)
            return
        else
            print('[COMMAND HANDLER] ' .. player.name .. ' ran: ' .. cmd .. server_time)
            return
        end
    else
        if param then
            print('[COMMAND HANDLER] ran: ' .. cmd .. ' "' .. param .. '" ' .. server_time)
            return
        else
            print('[COMMAND HANDLER] ran: ' .. cmd .. server_time)
            return
        end
    end
end

Event.add(defines.events.on_console_command, on_console_command)
