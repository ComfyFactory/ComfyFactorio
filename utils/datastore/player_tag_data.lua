local Token = require 'utils.token'
local Color = require 'utils.color_presets'
local Server = require 'utils.server'
local Event = require 'utils.event'

local tag_dataset = 'tags'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

local Public = {}

local fetch =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        local player = game.players[key]
        if not player or not player.valid then
            return
        end

        if type(value) == 'string' then
            player.tag = '[' .. value .. ']'
        end
    end
)

local alphanumeric = function(str)
    return (string.match(str, '[^%w]') ~= nil)
end

--- Tries to get data from the webpanel and applies the value to the player.
-- @param data_set player token
function Public.fetch(key)
    local secs = Server.get_current_time()
    if not secs then
        return
    else
        try_get_data(tag_dataset, key, fetch)
    end
end

commands.add_command(
    'save-tag',
    'Sets your custom tag that is persistent.',
    function(cmd)
        local player = game.player
        if not player or not player.valid then
            return
        end

        local secs = Server.get_current_time()
        if not secs then
            return
        end

        local param = cmd.parameter

        if param then
            if alphanumeric(param) then
                player.print('Tag is not valid.', {r = 0.90, g = 0.0, b = 0.0})
                return
            end

            if param == '' or param == 'Name' then
                return player.print('You did not specify a tag.', Color.warning)
            end

            if string.len(param) > 32 then
                player.print('Tag is too long. 64 characters maximum.', {r = 0.90, g = 0.0, b = 0.0})
                return
            end

            set_data(tag_dataset, player.name, param)
            player.tag = '[' .. param .. ']'
            player.print('Your tag has been saved.', Color.success)
        else
            player.print('You did not specify a tag.', Color.warning)
        end
    end
)

commands.add_command(
    'remove-tag',
    'Removes your custom tag.',
    function()
        local player = game.player
        if not player or not player.valid then
            return
        end

        set_data(tag_dataset, player.name, nil)
        player.print('Your tag has been removed.', Color.success)
    end
)

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        Public.fetch(player.name)
    end
)

return Public
