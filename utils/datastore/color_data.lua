local Token = require 'utils.token'
local Color = require 'utils.color_presets'
local Server = require 'utils.server'
local Event = require 'utils.event'

local color_data_set = 'colors'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

local Public = {}

local fetch =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        local player = game.players[key]
        if not player then
            return
        end
        if value then
            player.color = value.color[1]
            player.chat_color = value.chat[1]
        end
    end
)

--- Tries to get data from the webpanel and applies the value to the player.
-- @param data_set player token
function Public.fetch(key)
    local secs = Server.get_current_time()
    if secs == nil then
        return
    else
        try_get_data(color_data_set, key, fetch)
    end
end

local fetcher = Public.fetch

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player then
            return
        end
        fetcher(player.name)
    end
)

commands.add_command(
    'save-color',
    'Save your personal color preset so it´s always the same whenever you join.',
    function()
        local player = game.player
        if not player or not player.valid then
            return
        end

        local secs = Server.get_current_time()
        if not secs then
            return
        end

        local color = player.color
        local chat = player.chat_color

        set_data(color_data_set, player.name, {color = {color}, chat = {chat}})
        player.print('Your personal color has been saved to the datastore.', Color.success)
    end
)

commands.add_command(
    'remove-color',
    'Removes your saved color from the datastore.',
    function()
        local player = game.player
        if not player or not player.valid then
            return
        end

        local secs = Server.get_current_time()
        if not secs then
            return
        end

        set_data(color_data_set, player.name, nil)
        player.print('Your personal color has been removed from the datastore.', Color.success)
    end
)

return Public
