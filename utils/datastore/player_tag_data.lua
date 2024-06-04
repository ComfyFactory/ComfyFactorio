-- created by Gerkiz for ComfyFactorio
local Token = require 'utils.token'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Commands = require 'utils.commands'

local tag_dataset = 'tags'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

local Public = {}

local fetch =
    Token.register(
        function (data)
            if not data then
                return
            end

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

local alphanumeric = function (str)
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

Commands.new('save-tag', 'Sets your custom tag that is persistent.')
    :add_parameter('tag', false, 'The tag you want to set.')
    :require_backend()
    :callback(
        function (player, tag)
            if alphanumeric(tag) then
                player.print('Tag is not valid.')
                return false
            end

            if tag == '' or tag == 'Name' then
                player.print('You did not specify a tag.')
                return false
            end

            if string.len(tag) > 32 then
                player.print('Tag is too long. 64 characters maximum.')
                return false
            end

            set_data(tag_dataset, player.name, tag)
            player.tag = '[' .. tag .. ']'
            player.print('Your tag has been saved.')
        end
    )

Commands.new('remove-tag', 'Removes your custom tag.')
    :require_backend()
    :callback(
        function (player)
            set_data(tag_dataset, player.name, nil)
            player.print('Your tag has been removed.')
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
