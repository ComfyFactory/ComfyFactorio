local Event = require 'utils.event'
local Session = require 'utils.datastore.session_data'

commands.add_command(
    'trust',
    'Promotes a player to trusted!',
    function(cmd)
        local trusted = Session.get_trusted_table()
        local player = game.player

        if player and player.valid then
            if not player.admin then
                player.print("You're not admin!", {r = 1, g = 0.5, b = 0.1})
                return
            end

            if cmd.parameter == nil then
                return
            end
            local target_player = game.get_player(cmd.parameter)
            if target_player then
                if trusted[target_player.name] then
                    game.print(target_player.name .. ' is already trusted!')
                    return
                end
                trusted[target_player.name] = true
                game.print(target_player.name .. ' is now a trusted player.', {r = 0.22, g = 0.99, b = 0.99})
                for _, a in pairs(game.connected_players) do
                    if a.admin and a.name ~= player.name then
                        a.print('[ADMIN]: ' .. player.name .. ' trusted ' .. target_player.name, {r = 1, g = 0.5, b = 0.1})
                    end
                end
            end
        else
            if cmd.parameter == nil then
                return
            end
            local target_player = game.get_player(cmd.parameter)
            if target_player then
                if trusted[target_player.name] == true then
                    game.print(target_player.name .. ' is already trusted!')
                    return
                end
                trusted[target_player.name] = true
                game.print(target_player.name .. ' is now a trusted player.', {r = 0.22, g = 0.99, b = 0.99})
            end
        end
    end
)

commands.add_command(
    'untrust',
    'Demotes a player from trusted!',
    function(cmd)
        local trusted = Session.get_trusted_table()
        local player = game.player

        if player and player.valid then
            if not player.admin then
                player.print("You're not admin!", {r = 1, g = 0.5, b = 0.1})
                return
            end

            if cmd.parameter == nil then
                return
            end
            local target_player = game.get_player(cmd.parameter)
            if target_player then
                if trusted[target_player.name] == false then
                    game.print(target_player.name .. ' is already untrusted!')
                    return
                end
                trusted[target_player.name] = false
                game.print(target_player.name .. ' is now untrusted.', {r = 0.22, g = 0.99, b = 0.99})
                for _, a in pairs(game.connected_players) do
                    if a.admin == true and a.name ~= player.name then
                        a.print('[ADMIN]: ' .. player.name .. ' untrusted ' .. target_player.name, {r = 1, g = 0.5, b = 0.1})
                    end
                end
            end
        else
            if cmd.parameter == nil then
                return
            end
            local target_player = game.get_player(cmd.parameter)
            if target_player then
                if trusted[target_player.name] == false then
                    game.print(target_player.name .. ' is already untrusted!')
                    return
                end
                trusted[target_player.name] = false
                game.print(target_player.name .. ' is now untrusted.', {r = 0.22, g = 0.99, b = 0.99})
            end
        end
    end
)

Event.add(
    defines.events.on_player_created,
    function(event)
        local player = game.get_player(event.player_index)
        if not (player and player.valid) then
            return
        end

        local is_single_player = not game.is_multiplayer()
        if is_single_player then
            Session.set_trusted_player(player)
        end
    end
)
