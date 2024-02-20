-- created by Gerkiz for ComfyFactorio
local Event = require 'utils.event'
local Server = require 'utils.server'
local Token = require 'utils.token'

local Public = {}

local ban_by_join_enabled = false

local try_get_ban = Server.try_get_ban

local valid_commands = {
    ['ban'] = true
}

local try_get_is_banned_token =
    Token.register(
    function(data)
        if not data then
            return
        end

        local username = data.username
        if not username then
            return
        end

        local state = data.state

        if state == true then
            game.ban_player(data.username, data.reason)
        end
    end
)

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        if not ban_by_join_enabled then
            return
        end

        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local secs = Server.get_current_time()
        if secs == nil or secs == false then
            return
        else
            try_get_ban(player.name, try_get_is_banned_token)
        end
    end
)

Event.add(
    defines.events.on_console_command,
    function(event)
        if valid_commands[event.command] then
            Server.ban_handler(event)
        end
    end
)

return Public
