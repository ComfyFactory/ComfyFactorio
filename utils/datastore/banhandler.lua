local Event = require 'utils.event'
local Server = require 'utils.server'
local Token = require 'utils.token'
local Game = require 'utils.game'

local len = string.len
local gmatch = string.gmatch
local insert = table.insert

local try_get_ban = Server.try_get_ban

--- Jail dataset.
local jailed_data_set = 'jailed'

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
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local secs = Server.get_current_time()
        if secs == nil then
            return
        else
            try_get_ban(player.name, try_get_is_banned_token)
        end
    end
)

Event.add(
    defines.events.on_console_command,
    function(event)
        local cmd = event.command

        local user = event.parameters
        if not user then
            return
        end

        if len(user) <= 2 then
            return
        end

        local player_index
        local reason
        local str = ''

        local t = {}
        for i in gmatch(user, '%S+') do
            insert(t, i)
        end

        player_index = t[1]

        for i = 2, #t do
            str = str .. t[i] .. ' '
            reason = str
        end

        if not player_index then
            return print('[on_console_command] - player_index was undefined.')
        end

        local target
        if game.get_player(player_index) then
            target = game.get_player(player_index)
        else
            return
        end

        if event.player_index then
            local player = game.get_player(event.player_index)
            if player and player.valid and player.admin then
                -- if target.index == player.index then
                --     return
                -- end

                local data = Server.build_embed_data()
                data.username = target.name
                data.admin = player.name

                if cmd == 'ban' then
                    Server.set_data(jailed_data_set, target.name, nil) -- this is added here since we don't want to clutter the jail dataset.
                    if not reason then
                        data.reason = 'Not specified.'
                        Server.to_banned_embed(data)
                        return
                    else
                        data.reason = reason
                        Server.to_banned_embed(data)
                        return
                    end
                elseif cmd == 'unban' then
                    Server.to_unbanned_embed(data)
                    return
                end
            end
        else
            local data = Server.build_embed_data()
            data.username = target.name
            data.admin = '<Server>'

            if cmd == 'ban' then
                Server.set_data(jailed_data_set, target.name, nil) -- this is added here since we don't want to clutter the jail dataset.
                if not reason then
                    data.reason = 'Not specified.'
                    Server.to_banned_embed(data)
                    return
                else
                    data.reason = reason
                    Server.to_banned_embed(data)
                    return
                end
            elseif cmd == 'unban' then
                Server.to_unbanned_embed(data)
                return
            end
        end
    end
)
