local Session = require 'utils.session_data'
local Server = require 'utils.server'
local Event = require 'utils.event'

local function admin_only_message(str)
    for _, player in pairs(game.connected_players) do
        if player.admin == true then
            player.print('Admins-only-message: ' .. str, {r = 0.88, g = 0.88, b = 0.88})
        end
    end
end

local jail_messages = {
    'You´re done bud!',
    'Busted!'
}

local freedom_messages = {
    'Yaay!',
    'Welcome back!'
}

local function jail(target_player, source_player)
    local group = game.permissions.get_group('prisoner')
    if not group then
        group = game.permissions.create_group('prisoner')
        for action_name, _ in pairs(defines.input_action) do
            group.set_allows_action(defines.input_action[action_name], false)
        end
        group.set_allows_action(defines.input_action.write_to_console, true)
        group.set_allows_action(defines.input_action.gui_click, true)
        group.set_allows_action(defines.input_action.gui_selection_state_changed, true)
    end

    if group and group.players then
        for k, v in pairs(group.players) do
            if target_player.name == v.name then
                if source_player and source_player.valid then
                    source_player.print(target_player.name .. ' is already jailed.', {r = 0.98, g = 0.66, b = 0.22})
                else
                    print(target_player.name .. ' is already jailed.', {r = 0.98, g = 0.66, b = 0.22})
                end
                return
            end
        end
    end

    group.add_player(target_player.name)
    game.print(
        target_player.name .. ' has been jailed. ' .. jail_messages[math.random(1, #jail_messages)],
        {r = 0.98, g = 0.66, b = 0.22}
    )
    if source_player and source_player.valid then
        admin_only_message(target_player.name .. ' was jailed by ' .. source_player.name)
        Server.to_discord_bold(
            table.concat {'[Jailed] ' .. target_player.name .. ' has been jailed by ' .. source_player.name .. '!'}
        )
    else
        admin_only_message(target_player.name .. ' was jailed by Server')
        Server.to_discord_bold(table.concat {'[Jailed] ' .. target_player.name .. ' has been jailed by Server!'})
    end
end

local function free(target_player, source_player)
    local group = game.permissions.get_group('Default')
    if group and group.players then
        for k, v in pairs(group.players) do
            if target_player.name == v.name then
                if source_player and source_player.valid then
                    source_player.print(target_player.name .. ' is already free.', {r = 0.98, g = 0.66, b = 0.22})
                else
                    print(target_player.name .. ' is already free.', {r = 0.98, g = 0.66, b = 0.22})
                end
                return
            end
        end
    end
    group.add_player(target_player.name)
    game.print(
        target_player.name .. ' was set free from jail. ' .. freedom_messages[math.random(1, #freedom_messages)],
        {r = 0.98, g = 0.66, b = 0.22}
    )
    if source_player and source_player.valid then
        admin_only_message(source_player.name .. ' set ' .. target_player.name .. ' free from jail')
        Server.to_discord_bold(
            table.concat {'[Unjailed] ' .. target_player.name .. ' has been unjailed by ' .. source_player.name .. '!'}
        )
    else
        admin_only_message('Server set ' .. target_player.name .. ' free from jail')
        Server.to_discord_bold(table.concat {'[Unjailed] ' .. target_player.name .. ' has been unjailed by Server!'})
    end
end

commands.add_command(
    'jail',
    'Sends the player to gulag!',
    function(cmd)
        local trusted = Session.get_trusted_table()
        local total_time = Session.get_session_table()
        local player = game.player
        local p

        if player then
            if player ~= nil then
                p = player.print
                if not total_time[player.name] then
                    goto continue
                end
                if total_time[player.name] < 51900000 then
                    if not player.admin then
                        p("You're not admin nor are you trusted enough to run this command!", {r = 1, g = 0.5, b = 0.1})
                        return
                    end
                end
            end

            if cmd.parameter == nil then
                return
            end
            local target_player = game.players[cmd.parameter]
            if target_player then
                if target_player.name == player.name then
                    player.print("You can't jail yourself!", {r = 1, g = 0.5, b = 0.1})
                    return
                end
                trusted[target_player.name] = false
                jail(target_player, player)
                return
            end
        else
            if cmd.parameter == nil then
                return
            end
            local target_player = game.players[cmd.parameter]
            if target_player then
                trusted[target_player.name] = false
                jail(target_player, 'Server')
                return
            end
        end
        ::continue::
    end
)

commands.add_command(
    'unjail',
    'Brings back the player from gulag.',
    function(cmd)
        local player = game.player
        local total_time = Session.get_session_table()
        local p

        if player then
            if player ~= nil then
                p = player.print
                if not total_time[player.name] then
                    goto continue
                end
                if total_time[player.name] < 51900000 then
                    if not player.admin then
                        p("You're not admin nor are you trusted enough to run this command!", {r = 1, g = 0.5, b = 0.1})
                        return
                    end
                end
            end

            if cmd.parameter == nil then
                return
            end
            local target_player = game.players[cmd.parameter]
            if target_player then
                if target_player.name == player.name then
                    player.print("You can't unjail yourself!", {r = 1, g = 0.5, b = 0.1})
                    return
                end
                free(target_player, player)
                return
            end
        else
            if cmd.parameter == nil then
                return
            end
            local target_player = game.players[cmd.parameter]
            if target_player then
                free(target_player, 'Server')
                return
            end
        end
        ::continue::
    end
)

local function on_console_command(event)
    local cmd = event.command
    if not event.player_index then
        return
    end
    local player = game.players[event.player_index]
    local reason = event.parameters
    if not reason then
        return
    end
    if not player.admin then
        return
    end
    if cmd == 'ban' then
        if player then
            Server.to_banned_embed(table.concat {player.name .. ' banned ' .. reason})
            return
        else
            Server.to_banned_embed(table.concat {'Server banned ' .. reason})
            return
        end
    elseif cmd == 'unban' then
        if player then
            Server.to_banned_embed(table.concat {player.name .. ' unbanned ' .. reason})
            return
        else
            Server.to_banned_embed(table.concat {'Server unbanned ' .. reason})
            return
        end
    end
end

Event.add(defines.events.on_console_command, on_console_command)
