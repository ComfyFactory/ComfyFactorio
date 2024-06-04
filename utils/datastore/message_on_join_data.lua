-- created by Gerkiz for ComfyFactorio
local Token = require 'utils.token'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Commands = require 'utils.commands'

local message_dataset = 'regulars'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

local Public = {}

local fetch =
    Token.register(
        function (data)
            local key = data.key
            local value = data.value
            local player = game.players[key]
            if not player or not player.valid then
                return
            end
            if type(value) == 'table' then
                game.print('>> ' .. player.name .. ' << ' .. value.msg, value.color) -- we want the player name to be printed.
            end
        end
    )

--- Tries to get data from the webpanel and applies the value to the player.
-- @param data_set player token
function Public.fetch(key)
    local secs = Server.get_current_time()
    if not secs then
        local player = game.players[key]
        if not player or not player.valid then
            return
        end
        return
    else
        try_get_data(message_dataset, key, fetch)
    end
end

Commands.new('save-message', 'Sets your custom join message. "{name}" will be replaced with your username.')
    :require_backend()
    :add_parameter('message', false, 'string')
    :callback(
        function (player, message)
            if message == '' or message == 'Name' then
                player.print('You did not specify a message.')
                return false
            end
            if string.len(message) > 64 then
                player.print('Message is too long. 64 characters maximum.')
                return false
            end
            set_data(message_dataset, player.name, { msg = message, color = player.color })
            player.print('You message has been saved.')
        end
    )

Commands.new('remove-message', 'Removes your custom join message.')
    :require_backend()
    :callback(
        function (player)
            set_data(message_dataset, player.name, nil)
            player.print('Your message has been removed.')
        end
    )

Event.add(
    defines.events.on_player_joined_game,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        Public.fetch(player.name)
    end
)

return Public
