-- created by Gerkiz for ComfyFactorio
local Token = require 'utils.token'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Commands = require 'utils.commands'
local Supporters = require 'utils.datastore.supporters'
local PlayerSettings = require 'utils.gui.player_settings'

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

local function can_edit(player)
    return player.admin or Supporters.is_supporter(player.name)
end

local function save_tag(player, tag)
    if tag == '' or tag == 'Name' or #tag > 32 or tag:find('[^%w]') then
        return nil, { 'gui.player_settings_invalid_tag' }
    end
    set_data(tag_dataset, player.name, tag)
    player.tag = '[' .. tag .. ']'
    return tag
end

local function remove_tag(player)
    set_data(tag_dataset, player.name, nil)
    player.tag = ''
end

PlayerSettings.register('tag', tag_dataset, {
    can_edit = can_edit,
    input = function (value) return value or '' end,
    save = save_tag,
    remove = remove_tag
})

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

Commands.new('set-player-tag', 'Sets your custom tag that is persistent.')
    :add_parameter('tag', false, 'string')
    :require_backend()
    :callback(
        function (player, tag)
            if not can_edit(player) then
                player.print('To get access to this command, please become a supporter.')
                player.print('You can become a supporter by donating either via ko-fi or patreon.')
                return false
            end

            local value, err = save_tag(player, tag)
            if not value then
                player.print(err)
                return false
            end

            player.print('Your tag has been saved.')
        end
    )

Commands.new('remove-player-tag', 'Removes your custom tag.')
    :require_backend()
    :callback(
        function (player)
            if not can_edit(player) then
                player.print('To get access to this command, please become a supporter.')
                player.print('You can become a supporter by donating either via ko-fi or patreon.')
                return false
            end

            remove_tag(player)
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
