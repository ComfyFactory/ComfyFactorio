local Public = require 'maps.mountain_fortress_v3.table'
local Task = require 'utils.task_token'
local Server = require 'utils.server'
local Collapse = require 'modules.collapse'
local WD = require 'modules.wave_defense.table'
local Discord = require 'utils.discord_handler'
local Commands = require 'utils.commands'
local mapkeeper = '[color=blue]Mapkeeper:[/color]'
local scenario_name = Public.scenario_name

local gather_time_token =
    Task.register(
        function ()
            local stateful = Public.get_stateful()
            stateful.collection.gather_time_timer = 0
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
                    Discord.send_notification_raw(scenario_name, player.name .. ' has enabled soft-reset!')
                    player.print('Soft-reset is enabled.')
                else
                    this.reset_are_you_sure = nil
                    this.restart = true
                    this.soft_reset = false
                    if this.shutdown then
                        this.shutdown = false
                    end
                    Discord.send_notification_raw(scenario_name, player.name .. ' has disabled soft-reset! Restart will happen from scenario.')
                    player.print('Soft-reset is disabled! Server will restart from scenario to load new changes.')
                end
            elseif action == 'restartnow' then
                this.reset_are_you_sure = nil
                Server.start_scenario('Mountain_Fortress_v3')
                Discord.send_notification_raw(scenario_name, player.name .. ' restarted the scenario.')
                player.print('Restarted the scenario.')
            elseif action == 'shutdown' then
                if this.shutdown then
                    this.reset_are_you_sure = nil
                    this.shutdown = false
                    this.soft_reset = true
                    Discord.send_notification_raw(scenario_name,
                        player.name .. ' has enabled soft-reset. Server will NOT shutdown!')

                    player.print('Soft-reset is enabled.')
                else
                    this.reset_are_you_sure = nil
                    this.shutdown = true
                    this.soft_reset = false
                    if this.restart then
                        this.restart = false
                    end

                    Discord.send_notification_raw(scenario_name, player.name .. ' has disabled soft-reset. Server will shutdown!')
                    player.print('Soft-reset is disabled! Server will shutdown.')
                end
            elseif action == 'reset' then
                this.reset_are_you_sure = nil
                if player and player.valid then
                    game.print(mapkeeper .. ' ' .. player.name .. ', has reset the game!',
                        { r = 0.98, g = 0.66, b = 0.22 })
                    Discord.send_notification_raw(scenario_name, player.name .. ' has reset the game!')
                else
                    game.print(mapkeeper .. ' server, has reset the game!', { r = 0.98, g = 0.66, b = 0.22 })
                    Discord.send_notification_raw(scenario_name, 'Server has reset the game!')
                end
                Public.reset_map()
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
            Discord.send_notification_raw(scenario_name, player.name .. ' set the queue speed to: ' .. speed)
            player.print('Queue speed set to: ' .. speed)
        end
    )

Commands.new('mtn_complete_quests', 'Usable only for admins - sets the queue speed of this map!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            Discord.send_notification_raw(scenario_name, player.name .. ' completed all the quest via command.')
            local stateful = Public.get_stateful()
            stateful.objectives_completed_count = 6
            Task.set_timeout_in_ticks(50, gather_time_token, {})
            game.print(mapkeeper .. player.name .. ', has forced completed all quests!', { r = 0.98, g = 0.66, b = 0.22 })
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
            Discord.send_notification_raw(scenario_name, player.name .. ' reversed the map.')
            Public.reset_map()
            log(serpent.block('resetting map'))
            game.print(mapkeeper .. player.name .. ', has reverse the map and reset the game!',
                { r = 0.98, g = 0.66, b = 0.22 })
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
                Discord.send_notification_raw(scenario_name, player.name .. ' disabled the wave defense module.')
                game.print(mapkeeper .. ' ' .. player.name .. ', has disabled the wave_defense module!',
                    { r = 0.98, g = 0.66, b = 0.22 })
                tbl.game_lost = true
            else
                Discord.send_notification_raw(scenario_name, player.name .. ' enabled the wave defense module.')
                game.print(mapkeeper .. ' ' .. player.name .. ', has enabled the wave_defense module!',
                    { r = 0.98, g = 0.66, b = 0.22 })
                tbl.game_lost = false
            end
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
                Discord.send_notification_raw(scenario_name, player.name .. ' disabled the orbital strike module.')
                game.print(mapkeeper .. ' ' .. player.name .. ', has disabled the orbital_strikes module!',
                    { r = 0.98, g = 0.66, b = 0.22 })
                this.orbital_strikes.enabled = false
            else
                Discord.send_notification_raw(scenario_name, player.name .. ' enabled the orbital strike module.')
                game.print(mapkeeper .. ' ' .. player.name .. ', has enabled the orbital_strikes module!',
                    { r = 0.98, g = 0.66, b = 0.22 })
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
                Discord.send_notification_raw(scenario_name, player.name .. ' has enabled collapse.')
                game.print(mapkeeper .. ' ' .. player.name .. ', has enabled collapse!', { r = 0.98, g = 0.66, b = 0.22 })
            else
                Collapse.start_now(false, true)
                Discord.send_notification_raw(scenario_name, player.name .. ' has disabled collapse.')
                game.print(mapkeeper .. ' ' .. player.name .. ', has disabled collapse!',
                    { r = 0.98, g = 0.66, b = 0.22 })
            end
        end
    )

return Public
