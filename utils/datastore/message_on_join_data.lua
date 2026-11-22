-- created by Gerkiz for ComfyFactorio
local Token = require 'utils.token'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Commands = require 'utils.commands'
local Supporters = require 'utils.datastore.supporters'
local PlayerSettings = require 'utils.gui.player_settings'

local message_dataset = 'regulars'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

local Public = {}

local function can_edit(player)
    return player.admin or Supporters.is_supporter(player.name)
end

local function save_message(player, message)
    if message == '' or message == 'Name' or #message > 64 then
        return nil, { 'gui.player_settings_invalid_message' }
    end
    local value = { msg = message, color = player.color }
    set_data(message_dataset, player.name, value)
    return value
end

PlayerSettings.register('join_message', message_dataset, {
    can_edit = can_edit,
    input = function (value) return value and value.msg or '' end,
    save = save_message
})

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

Commands.new('set-join-message', 'Sets your custom join message. "{name}" will be replaced with your username.')
    :require_backend()
    :add_parameter('message', false, 'string')
    :callback(
        function (player, message)
            if not can_edit(player) then
                player.print('To get access to this command, please become a supporter.')
                player.print('You can become a supporter by donating either via ko-fi or patreon.')
                return false
            end

            local value, err = save_message(player, message)
            if not value then
                player.print(err)
                return false
            end
            player.print('Your message has been saved.')
        end
    )

Commands.new('remove-join-message', 'Removes your custom join message.')
    :require_backend()
    :callback(
        function (player)
            if not can_edit(player) then
                player.print('To get access to this command, please become a supporter.')
                player.print('You can become a supporter by donating either via ko-fi or patreon.')
                return false
            end

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
