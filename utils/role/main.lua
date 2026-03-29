local Public = require 'utils.role.core'
local Event = require 'utils.event'
local Server = require 'utils.server'
local Token = require 'utils.token'
local Task = require 'utils.task'

local session_data_set = 'sessions'
local roles_data_set = 'roles'
local try_get_data = Server.try_get_data

local fetch_player =
    Token.register(
        function (data)
            local player_index = data.player_index
            local player = game.get_player(player_index)

            if player and player.valid then
                Public.update_role(player)
            end
        end
    )

local try_download_data_token =
    Token.register(
        function (data)
            local key = data.key
            local value = data.value
            if value then
                Public.give_role(key, value, 'Script')
            else
                Public.update_role(key)
                Task.set_timeout_in_ticks(10, fetch_player, { player_index = key })
            end
        end
    )

--- Tries to get data from the webpanel and updates the local table with values.
-- @param data_set player token
function Public.try_dl_data(key)
    key = tostring(key)
    local secs = Server.get_current_time()
    if not secs then
        return
    else
        try_get_data(roles_data_set, key, try_download_data_token)
    end
end

Event.add(
    Public.events.on_role_change,
    function (event)
        Task.set_timeout_in_ticks(5, fetch_player, { player_index = event.player_index })
    end
)

Event.add(
    defines.events.on_player_created,
    function (event)
        local player = game.get_player(event.player_index)
        Public.update_role(player)

        Task.set_timeout_in_ticks(5, fetch_player, { player_index = event.player_index })
    end
)

Event.add(
    defines.events.on_player_joined_game,
    function (event)
        local player = game.get_player(event.player_index)
        Public.try_dl_data(player.name)
    end
)

Event.on_init(
    function ()
        Public.set_permissions_on_init()
        Public.set_roles_on_init()

        Public.adjust_permission()
        Public.fix_roles()

        local settings = Public.get('settings')
        for _, role in pairs(settings.role) do
            local perm = game.permissions.create_group(role.name)
            for _, remove in pairs(role.disallow) do
                if role ~= nil then
                    perm.set_allows_action(defines.input_action[remove], false)
                end
            end
        end
    end
)

Event.on_nth_tick(
    3600,
    function ()
        local players = game.connected_players
        for i = 1, #players do
            local player = players[i]
            Task.set_timeout_in_ticks(5, fetch_player, { player_index = player.index })
        end
    end
)

Server.on_data_set_changed(
    session_data_set,
    function (data)
        Public.update_role(data.key)
    end
)

return Public
