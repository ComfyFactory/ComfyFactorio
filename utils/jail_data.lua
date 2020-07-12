local Global = require 'utils.global'
local Session = require 'utils.session_data'
local Game = require 'utils.game'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Utils = require 'utils.core'

local jailed_data_set = 'jailed'
local jailed = {}
local votejail = {}
local votefree = {}
local votejail_count = 3
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
    {
        jailed = jailed,
        votejail = votejail,
        votefree = votefree
    },
    function(t)
        jailed = t.jailed
        votejail = t.votejail
        votefree = t.votefree
    end
)

local Public = {}

local validate_args = function(player, griefer)
    if not game.players[griefer] then
        Utils.print_to(player, 'Invalid name.')
        return false
    end

    if votejail[player.name] and not player.admin then
        Utils.print_to(player, 'You are currently being investigated since you have griefed.')
        return false
    end

    if votefree[player.name] and not player.admin then
        Utils.print_to(player, 'You are currently being investigated since you have griefed.')
        return false
    end

    if jailed[player.name] and not player.admin then
        Utils.print_to(player, 'You are jailed, you can´t run this command.')
        return false
    end

    if player.name == griefer then
        Utils.print_to(player, 'You can´t select yourself.')
        return false
    end

    if game.players[griefer].admin and not player.admin then
        Utils.print_to(player, 'You can´t select an admin.')
        return false
    end

    return true
end

local vote_to_jail = function(player, griefer)
    if not votejail[griefer] then
        votejail[griefer] = {index = 0}
        local message = player.name .. ' has started a vote to jail player ' .. griefer
        Utils.print_to(nil, message)
    end
    if not votejail[griefer][player.name] then
        votejail[griefer][player.name] = true
        votejail[griefer].index = votejail[griefer].index + 1
        Utils.print_to(player, 'You have voted to jail player ' .. griefer .. '.')
        if
            votejail[griefer].index >= votejail_count or
                (votejail[griefer].index == #game.connected_players - 1 and
                    #game.connected_players > votejail[griefer].index)
         then
            Public.try_ul_data(griefer, true)
        end
    else
        Utils.print_to(player, 'You have already voted to kick ' .. griefer .. '.')
    end
end

local vote_to_free = function(player, griefer)
    if votejail[griefer] and not votefree[griefer] then
        votefree[griefer] = {index = 0}
        local message = player.name .. ' has started a vote to free player ' .. griefer
        Utils.print_to(nil, message)
    end
    if not votefree[griefer][player.name] then
        votefree[griefer][player.name] = true
        votefree[griefer].index = votefree[griefer].index + 1

        Utils.print_to(player, 'You have voted to free player ' .. griefer .. '.')
        if
            votefree[griefer].index >= votejail_count or
                (votefree[griefer].index == #game.connected_players - 1 and
                    #game.connected_players > votefree[griefer].index)
         then
            Public.try_ul_data(griefer, false)
            votejail[griefer] = nil
            votefree[griefer] = nil
        end
    else
        Utils.print_to(player, 'You have already voted to free ' .. griefer .. '.')
    end
    return
end

local jail = function(player, griefer)
    player = player or 'script'
    if jailed[griefer] then
        Utils.print_to(player, griefer .. ' is already jailed!')
        return false
    end

    if not game.players[griefer] then
        return
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
    permission_group.add_player(griefer)
    local message = griefer .. ' has been jailed by ' .. player .. '. ' .. jail_messages[math.random(1, #jail_messages)]

    if
        game.players[griefer].character and game.players[griefer].character.valid and
            game.players[griefer].character.driving
     then
        game.players[griefer].character.driving = false
    end

    jailed[griefer] = {jailed = true, actor = player}
    set_data(jailed_data_set, griefer, {jailed = true, actor = player})

    Utils.print_to(nil, message)
    Utils.action_warning_embed('{Jailed}', message)
    Utils.print_admins('Jailed ' .. griefer, player)

    game.players[griefer].clear_console()
    Utils.print_to(griefer, message)
    return true
end

local free = function(player, griefer)
    player = player or 'script'
    if not jailed[griefer] then
        Utils.print_to(player, griefer .. ' is not jailed!')
        return false
    end

    if not game.players[griefer] then
        return
    end

    local permission_group = game.permissions.get_group('Default')
    permission_group.add_player(griefer)
    local message =
        griefer ..
        ' was set free from jail by ' .. player .. '. ' .. freedom_messages[math.random(1, #freedom_messages)]

    jailed[griefer] = nil

    set_data(jailed_data_set, griefer, nil)

    if votejail[griefer] then
        votejail[griefer] = nil
    end
    if votefree[griefer] then
        votefree[griefer] = nil
    end

    Utils.print_to(nil, message)
    Utils.action_warning_embed('{Jailed}', message)
    Utils.print_admins('Free´d ' .. griefer .. ' from jail.', player)
    return true
end

local is_jailed =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        if value then
            if value.jailed then
                jail(value.actor, key)
            end
        end
    end
)

local update_jailed =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value or false
        local player = data.player or 'script'
        if value then
            jail(player, key)
        else
            free(player, key)
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

    local data = {
        key = key,
        value = value,
        player = player
    }

    Task.set_timeout_in_ticks(1, update_jailed, data)
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
        if not player or not player.valid then
            return
        end

        Public.try_dl_data(player.name)
    end
)

Event.add(
    defines.events.on_console_command,
    function(event)
        local tracker = Session.get_session_table()
        local cmd = event.command
        local _10d = 51840000 -- 10d
        local _12h = 2592000 --  12h

        if not valid_commands[cmd] then
            return
        end

        local griefer = event.parameters
        if not griefer then
            return
        end

        if event.player_index then
            local player = game.players[event.player_index]
            local playtime = player.online_time

            local success = validate_args(player, griefer)

            if not success then
                return
            end

            if tracker[player.name] then
                playtime = player.online_time + tracker[player.name]
            end

            if game.players[griefer] then
                griefer = game.players[griefer].name
            end

            if playtime >= _12h and playtime < _10d and not player.admin then
                if cmd == 'jail' then
                    vote_to_jail(player, griefer)
                    return
                elseif cmd == 'free' then
                    vote_to_free(player, griefer)
                    return
                end
            elseif playtime < _10d and not player.admin then
                return Utils.print_to(player, 'You are not trusted enough to run this command.')
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
        if data and data.value then
            if data.value.jailed and data.value.actor then
                jail(data.value.actor, data.key)
            end
        else
            free('script', data.key)
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
