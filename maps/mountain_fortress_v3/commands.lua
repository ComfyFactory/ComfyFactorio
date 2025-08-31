local Public = require 'maps.mountain_fortress_v3.table'
local Task = require 'utils.task_token'
local Server = require 'utils.server'
local Collapse = require 'modules.collapse'
local WD = require 'modules.wave_defense.table'
local Discord = require 'utils.discord_handler'
local Commands = require 'utils.commands'
local mapkeeper = '[color=blue]Mapkeeper:[/color]'
local CommandColor = { r = 0.98, g = 0.66, b = 0.22 }


local gather_time_token =
    Task.register(
        function (event)
            local stateful = Public.get_stateful()
            if event.instant_win then
                stateful.objectives_completed_count = stateful.tasks_required_to_win
                stateful.collection.gather_time_timer = 0
                stateful.collection.gather_time = 0
                stateful.collection.survive_for = 0
                stateful.collection.survive_for_timer = 0
            else
                stateful.collection.gather_time_timer = 0
            end
        end
    )

Commands.new('scenario', 'Usable only for admins - controls the scenario!')
    :require_admin()
    :require_validation()
    :add_parameter('restart/shutdown/reset/restartnow', false, 'string')
    :callback(
        function (player, action)
            local this = Public.get()

            if action == 'restart' or action == 'shutdown' or action == 'reset' or action == 'restartnow' then
                goto continue
            else
                player.print('Invalid action.')
                return false
            end

            ::continue::

            if action == 'restart' then
                if this.restart then
                    this.reset_are_you_sure = nil
                    this.restart = false
                    this.soft_reset = true
                    Discord.send_notification_raw(Public.discord_name, player.name .. ' has enabled soft-reset!')
                    player.print('Soft-reset is enabled.')
                else
                    this.reset_are_you_sure = nil
                    this.restart = true
                    this.soft_reset = false
                    if this.shutdown then
                        this.shutdown = false
                    end
                    Discord.send_notification_raw(Public.discord_name, player.name .. ' has disabled soft-reset! Restart will happen from scenario.')
                    player.print('Soft-reset is disabled! Server will restart from scenario to load new changes.')
                end
            elseif action == 'restartnow' then
                this.reset_are_you_sure = nil
                Server.start_scenario('Mountain_Fortress_v3')
                Discord.send_notification_raw(Public.discord_name, player.name .. ' restarted the scenario.')
                player.print('Restarted the scenario.')
            elseif action == 'shutdown' then
                if this.shutdown then
                    this.reset_are_you_sure = nil
                    this.shutdown = false
                    this.soft_reset = true
                    Discord.send_notification_raw(Public.discord_name,
                        player.name .. ' has enabled soft-reset. Server will NOT shutdown!')

                    player.print('Soft-reset is enabled.')
                else
                    this.reset_are_you_sure = nil
                    this.shutdown = true
                    this.soft_reset = false
                    if this.restart then
                        this.restart = false
                    end

                    Discord.send_notification_raw(Public.discord_name, player.name .. ' has disabled soft-reset. Server will shutdown!')
                    player.print('Soft-reset is disabled! Server will shutdown.')
                end
            elseif action == 'reset' then
                this.reset_are_you_sure = nil
                if player and player.valid then
                    game.print(mapkeeper .. ' ' .. player.name .. ', has reset the game!',
                        { color = CommandColor })
                    Discord.send_notification_raw(Public.discord_name, player.name .. ' has reset the game!')
                else
                    game.print(mapkeeper .. ' server, has reset the game!', { color = CommandColor })
                    Discord.send_notification_raw(Public.discord_name, 'Server has reset the game!')
                end
                Public.set_task('move_players', 'Init')
                player.print('Game has been reset!')
            end
        end
    )

Commands.new('mtn_set_queue_speed', 'Usable only for admins - sets the queue speed of this map!')
    :require_admin()
    :require_validation()
    :add_parameter('speed', true, 'number')
    :callback(
        function (player, speed)
            Task.set_queue_speed(speed)
            Discord.send_notification_raw(Public.discord_name, player.name .. ' set the queue speed to: ' .. speed)
            player.print('Queue speed set to: ' .. speed)
        end
    )

Commands.new('mtn_complete_quests', 'Usable only for admins - completes all the quests!')
    :require_admin()
    :require_validation()
    :add_parameter('no_grace', true, 'boolean')
    :add_parameter('instant_win', true, 'boolean')
    :callback(
        function (player, no_grace, instant_win)
            Discord.send_notification_raw(Public.discord_name, player.name .. ' completed all the quest via command.')
            local stateful = Public.get_stateful()
            stateful.objectives_completed_count = stateful.tasks_required_to_win
            if no_grace and not instant_win then
                Task.set_timeout_in_ticks(20, gather_time_token, {})
                game.print(mapkeeper .. player.name .. ', has forced completed all quests with no grace period!', { color = CommandColor })
            elseif instant_win then
                Task.set_timeout_in_ticks(100, gather_time_token, { instant_win = true })
                Task.set_timeout_in_ticks(120, gather_time_token, { instant_win = true })
                game.print(mapkeeper .. player.name .. ', has forced completed all quests with instant win!', { color = CommandColor })
            end
            player.print('Quests completed.')
        end
    )

Commands.new('mtn_reverse_map', 'Usable only for admins - reverses the map!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            local reversed = Public.get_stateful_settings('reversed')
            Public.set_stateful_settings('reversed', not reversed)
            Discord.send_notification_raw(Public.discord_name, player.name .. ' reversed the map.')
            Public.set_task('move_players', 'Init')
            game.print(mapkeeper .. player.name .. ', has reverse the map and reset the game!',
                { color = CommandColor })
            player.print('Map reversed.')
        end
    )

Commands.new('mtn_disable_biters', 'Usable only for admins - disables wave defense!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            local tbl = WD.get()

            if not tbl.game_lost then
                Discord.send_notification_raw(Public.discord_name, player.name .. ' disabled the wave defense module.')
                game.print(mapkeeper .. ' ' .. player.name .. ', has disabled the wave_defense module!',
                    { color = CommandColor })
                tbl.game_lost = true
            else
                Discord.send_notification_raw(Public.discord_name, player.name .. ' enabled the wave defense module.')
                game.print(mapkeeper .. ' ' .. player.name .. ', has enabled the wave_defense module!',
                    { color = CommandColor })
                tbl.game_lost = false
            end
        end
    )

Commands.new('mtn_toggle_darkness', 'Usable only for admins - toggles the darkness!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            local darkness = Public.get_stateful_settings('darkness')
            local active_surface_index = Public.get('active_surface_index')
            local surface = game.surfaces[active_surface_index]
            if not surface then
                return
            end
            if darkness then
                Public.set_stateful_settings('darkness', false)
                game.print('Darkness is now disabled!')
                Discord.send_notification_raw(Public.discord_name, player.name .. ' disabled surface darkness.')
                surface.brightness_visual_weights = { a = 1, b = 0, g = 0, r = 0 }
            else
                Public.set_stateful_settings('darkness', true)
                game.print('Darkness is now enabled!')
                Discord.send_notification_raw(Public.discord_name, player.name .. ' enabled surface darkness.')
                surface.brightness_visual_weights = { a = 1, b = 0.7, g = 0.7, r = 0.7 }
            end
        end
    )

Commands.new('mtn_grant_permanent_buff', 'Usable only for admins - grants a permanent buff!')
    :require_admin()
    :require_validation('Warning: This command gets logged to discord so please use it wisely!')
    :callback(
        function (player)
            local buff = Public.grant_non_limit_reached_buff()
            local stateful = Public.get_stateful()
            stateful.permanent_buffs[#stateful.permanent_buffs + 1] = buff
            Discord.send_notification_raw(Public.discord_name, player.name .. ' granted the team a permanent buff: ' .. buff.discord)
            game.print(mapkeeper .. ' ' .. player.name .. ', has granted the permanent buff: ' .. buff.discord .. '!', { color = CommandColor })
            Public.apply_permanent_buffs()
        end
    )


Commands.new('mtn_toggle_orbital_strikes',
    'Usable only for admins - toggles orbital strikes!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            local this = Public.get()

            if this.orbital_strikes.enabled then
                Discord.send_notification_raw(Public.discord_name, player.name .. ' disabled the orbital strike module.')
                game.print(mapkeeper .. ' ' .. player.name .. ', has disabled the orbital_strikes module!',
                    { color = CommandColor })
                this.orbital_strikes.enabled = false
            else
                Discord.send_notification_raw(Public.discord_name, player.name .. ' enabled the orbital strike module.')
                game.print(mapkeeper .. ' ' .. player.name .. ', has enabled the orbital_strikes module!',
                    { color = CommandColor })
                this.orbital_strikes.enabled = true
            end
        end
    )

Commands.new('mtn_get_queue_speed', 'Usable only for admins - gets the queue speed of this map!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            player.print(Task.get_queue_speed())
        end
    )

Commands.new('mtn_disable_collapse', 'Usable only for admins - toggles the collapse feature!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            if not Collapse.has_collapse_started() then
                Collapse.start_now(true, false)
                Discord.send_notification_raw(Public.discord_name, player.name .. ' has enabled collapse.')
                game.print(mapkeeper .. ' ' .. player.name .. ', has enabled collapse!', { color = CommandColor })
            else
                Collapse.start_now(false, true)
                Discord.send_notification_raw(Public.discord_name, player.name .. ' has disabled collapse.')
                game.print(mapkeeper .. ' ' .. player.name .. ', has disabled collapse!',
                    { color = CommandColor })
            end
        end
    )

return Public
