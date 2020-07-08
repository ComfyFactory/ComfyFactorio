local Global = require 'utils.global'
local Session = require 'utils.session_data'
local Game = require 'utils.game'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Server = require 'utils.server'
local Event = require 'utils.event'
local table = require 'utils.table'

local jailed_data_set = 'jailed'
local jailed = {}
local set_data = Server.set_data
local try_get_data = Server.try_get_data
local concat = table.concat

local jail_messages = {
    'You´re done bud!',
    'Busted!'
}

local freedom_messages = {
    'Yaay!',
    'Welcome back!'
}

local valid_commands = {
    ['free'] = true,
    ['jail'] = true
}

Global.register(
    jailed,
    function(t)
        jailed = t
    end
)

local Public = {}

local function admin_only_message(str)
    for _, player in pairs(game.connected_players) do
        if player.admin == true then
            player.print('Admins-only-message: ' .. str, {r = 0.88, g = 0.88, b = 0.88})
        end
    end
end

local jail = function(target_player, player)
    if jailed[target_player] then
        if player then
            game.players[player].print(target_player .. ' is already jailed!', {r = 1, g = 0.5, b = 0.1})
            return false
        else
            return false
        end
    end
    local permission_group = game.permissions.get_group('prisoner')
    if not permission_group then
        permission_group = game.permissions.create_group('prisoner')
        for action_name, _ in pairs(defines.input_action) do
            permission_group.set_allows_action(defines.input_action[action_name], false)
        end
        permission_group.set_allows_action(defines.input_action.write_to_console, true)
        permission_group.set_allows_action(defines.input_action.gui_click, true)
        permission_group.set_allows_action(defines.input_action.gui_selection_state_changed, true)
    end
    permission_group.add_player(target_player)
    local message
    if player then
        message =
            target_player .. ' has been jailed by ' .. player .. '. ' .. jail_messages[math.random(1, #jail_messages)]
    else
        message =
            target_player ..
            ' has been jailed automatically since they have griefed. ' .. jail_messages[math.random(1, #jail_messages)]
    end

    if
        game.players[target_player].character and game.players[target_player].character.valid and
            game.players[target_player].character.driving
     then
        game.players[target_player].character.driving = false
    end

    jailed[target_player] = true

    game.print(message, {r = 0.98, g = 0.66, b = 0.22})
    Server.to_discord_embed(
        table.concat {
            message
        }
    )
    admin_only_message(target_player .. ' was jailed by ' .. player)
    return true
end

local free = function(target_player, player)
    if not jailed[target_player] then
        if player then
            game.players[player].print(target_player .. ' is not jailed!', {r = 1, g = 0.5, b = 0.1})
            return false
        else
            return false
        end
    end
    local permission_group = game.permissions.get_group('Default')
    permission_group.add_player(target_player)
    local messsage
    if player then
        messsage =
            target_player ..
            ' was set free from jail by ' .. player .. '. ' .. freedom_messages[math.random(1, #freedom_messages)]
    else
        messsage = target_player .. ' was set free from jail. ' .. freedom_messages[math.random(1, #freedom_messages)]
    end

    jailed[target_player] = nil
    game.print(messsage, {r = 0.98, g = 0.66, b = 0.22})
    Server.to_discord_embed(
        table.concat {
            messsage
        }
    )

    admin_only_message(player .. ' set ' .. target_player .. ' free from jail')
    return true
end

local is_jailed =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        if value then
            jail(key)
            jailed[key] = value
        end
    end
)

local update_jailed =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        local player = data.player
        if value then
            set_data(jailed_data_set, key, value)
            jail(key, player)
            jailed[key] = value
        else
            set_data(jailed_data_set, key, nil)
            free(key, player)
            jailed[key] = value
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
        try_get_data(jailed_data_set, key, is_jailed)
    end
end

--- Tries to get data from the webpanel and updates the local table with values.
-- @param data_set player token
function Public.try_ul_data(key, value, player)
    key = tostring(key)
    local secs = Server.get_current_time()
    local data = {
        key = key,
        value = value,
        player = player or nil
    }
    if not secs then
        if value then
            jail(key, player)
            return true
        else
            free(key, player)
            return true
        end
    else
        Task.set_timeout_in_ticks(1, update_jailed, data)
    end
end

--- Checks if a player exists within the table
-- @param player_name <string>
-- @return <boolean>
function Public.exists(player_name)
    return jailed[player_name] ~= nil
end

--- Prints a list of all players in the player_jailed table.
function Public.print_jailed()
    local result = {}

    for k, _ in pairs(jailed) do
        result[#result + 1] = k
    end

    result = concat(result, ', ')
    Game.player_print(result)
end

--- Returns the table of jailed
-- @return <table>
function Public.get_jailed_table()
    return jailed
end

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        local secs = Server.get_current_time()
        if not secs then
            return
        end
        if not player or player.valid then
            return
        end

        if game.is_multiplayer() then
            Public.try_dl_data(player.name)
        end
    end
)

Event.add(
    defines.events.on_console_command,
    function(event)
        local trusted = Session.get_trusted_table()
        local tracker = Session.get_session_table()
        local p
        local cmd = event.command

        if not valid_commands[cmd] then
            return
        end

        local griefer = event.parameters
        if not griefer then
            return
        end

        if not game.players[griefer] then
            return
        end

        if event.player_index then
            local player = game.players[event.player_index]
            p = player.print

            local playtime = player.online_time
            if tracker[player.name] then
                playtime = player.online_time + tracker[player.name]
            end
            if playtime < 25920000 then -- 5 days
                return p('You are not trusted enough to run this command.', {r = 1, g = 0.5, b = 0.1})
            end

            if jailed[player.name] and not player.admin then
                return p('You are jailed, there is nothing to be done.', {r = 1, g = 0.5, b = 0.1})
            end

            if not trusted[player.name] then
                if not player.admin then
                    p("You're not admin nor are you trusted enough to run this command!", {r = 1, g = 0.5, b = 0.1})
                    return
                end
            end
            if player.name == griefer then
                return p("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
            end

            if game.players[griefer].admin and not player.admin then
                return p("You can't sadly jail an admin!", {r = 1, g = 0.5, b = 0.1})
            end

            if cmd == 'jail' then
                Public.try_ul_data(griefer, true, player.name)
                return
            elseif cmd == 'free' then
                Public.try_ul_data(griefer, false, player.name)
                return
            end
        else
            if cmd == 'jail' then
                Public.try_ul_data(griefer, true)
                return
            elseif cmd == 'free' then
                Public.try_ul_data(griefer, false)
                return
            end
        end
    end
)

Server.on_data_set_changed(
    jailed_data_set,
    function(data)
        jailed[data.key] = data.value
        if data and data.value then
            jail(data.key)
        else
            free(data.key)
        end
    end
)

commands.add_command(
    'jail',
    'Sends the player to gulag!',
    function()
        return
    end
)

commands.add_command(
    'free',
    'Brings back the player from gulag.',
    function()
        return
    end
)

return Public
