local Public = require 'maps.mountain_fortress_v3.table'
local Orient = require 'maps.mountain_fortress_v3.orientation'
local Task = require 'utils.task_token'
local Server = require 'utils.server'
local Collapse = require 'modules.collapse'
local WD = require 'modules.wave_defense.table'
local Discord = require 'utils.discord_handler'
local Commands = require 'utils.commands'
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

Commands.new('scenario', { 'mtn_v3_commands.scenario_help' })
    :require_admin()
    :require_validation()
    :add_parameter('restart/shutdown/reset/restartnow', false, 'string')
    :callback(
        function (player, action)
            local this = Public.get()

            if action == 'restart' or action == 'shutdown' or action == 'reset' or action == 'restartnow' then
                goto continue
            else
                player.print({ 'mtn_v3_commands.invalid_action' })
                return false
            end

            ::continue::

            if action == 'restart' then
                if this.restart then
                    this.reset_are_you_sure = nil
                    this.restart = false
                    this.soft_reset = true
                    Discord.send_notification(
                        {
                            title = "Soft-reset enabled",
                            description = player.name .. ' has enabled soft-reset!',
                            color = "info",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                    player.print({ 'mtn_v3_commands.soft_reset_is_enabled' })
                else
                    this.reset_are_you_sure = nil
                    this.restart = true
                    this.soft_reset = false
                    if this.shutdown then
                        this.shutdown = false
                    end
                    Discord.send_notification(
                        {
                            title = "Soft-reset disabled",
                            description = player.name .. ' has disabled soft-reset! Restart will happen from scenario.',
                            color = "warning",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                    player.print({ 'mtn_v3_commands.soft_reset_disabled_restart' })
                end
            elseif action == 'restartnow' then
                this.reset_are_you_sure = nil
                Server.start_scenario('Mountain_Fortress_v3')
                Discord.send_notification(
                    {
                        title = "Scenario restarted",
                        description = player.name .. ' restarted the scenario.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                player.print({ 'mtn_v3_commands.restarted_the_scenario' })
            elseif action == 'shutdown' then
                if this.shutdown then
                    this.reset_are_you_sure = nil
                    this.shutdown = false
                    this.soft_reset = true
                    Discord.send_notification(
                        {
                            title = "Soft-reset enabled",
                            description = player.name .. ' has enabled soft-reset. Server will NOT shutdown!',
                            color = "success",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })

                    player.print({ 'mtn_v3_commands.soft_reset_is_enabled' })
                else
                    this.reset_are_you_sure = nil
                    this.shutdown = true
                    this.soft_reset = false
                    if this.restart then
                        this.restart = false
                    end

                    Discord.send_notification(
                        {
                            title = "Soft-reset disabled",
                            description = player.name .. ' has disabled soft-reset. Server will shutdown!',
                            color = "warning",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                    player.print({ 'mtn_v3_commands.soft_reset_disabled_shutdown' })
                end
            elseif action == 'reset' then
                this.reset_are_you_sure = nil
                if player and player.valid then
                    game.print({ 'mtn_v3_commands.player_reset', player.name },
                        { color = CommandColor })
                    Discord.send_notification(
                        {
                            title = "Game reset",
                            description = player.name .. ' has reset the game!',
                            color = "success",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                else
                    game.print({ 'mtn_v3_commands.server_reset' }, { color = CommandColor })
                    Discord.send_notification(
                        {
                            title = "Game reset",
                            description = 'Server has reset the game!',
                            color = "success",
                            fields =
                            {
                                {
                                    title = "Server",
                                    description = Public.discord_name,
                                    inline = "false"
                                }
                            }
                        })
                end
                local current_task = Public.get('current_task')
                Public.set_task(current_task.default_task)
                player.print({ 'mtn_v3_commands.game_has_been_reset' })
            end
        end
    )

Commands.new('mtn_set_queue_speed', { 'mtn_v3_commands.set_queue_speed_help' })
    :require_admin()
    :require_validation()
    :add_parameter('speed', true, 'number')
    :callback(
        function (player, speed)
            Task.set_queue_speed(speed)
            Discord.send_notification(
                {
                    title = "Queue speed set",
                    description = player.name .. ' set the queue speed to: ' .. speed,
                    color = "success",
                    fields =
                    {
                        {
                            title = "Server",
                            description = Public.discord_name,
                            inline = "false"
                        }
                    }
                })
            player.print({ 'mtn_v3_commands.queue_speed_set_to', speed })
        end
    )

Commands.new('mtn_complete_quests', { 'mtn_v3_commands.complete_quests_help' })
    :require_admin()
    :require_validation()
    :add_parameter('no_grace', true, 'boolean')
    :add_parameter('instant_win', true, 'boolean')
    :callback(
        function (player, no_grace, instant_win)
            Discord.send_notification(
                {
                    title = "Quests completed",
                    description = player.name .. ' completed all the quest via command.',
                    color = "success",
                    fields =
                    {
                        {
                            title = "Server",
                            description = Public.discord_name,
                            inline = "false"
                        }
                    }
                })
            local stateful = Public.get_stateful()
            stateful.objectives_completed_count = stateful.tasks_required_to_win
            if no_grace and not instant_win then
                Task.set_timeout_in_ticks(20, gather_time_token, {})
                game.print({ 'mtn_v3_commands.quests_skipped_grace', player.name }, { color = CommandColor })
            elseif instant_win then
                Task.set_timeout_in_ticks(100, gather_time_token, { instant_win = true })
                Task.set_timeout_in_ticks(120, gather_time_token, { instant_win = true })
                game.print({ 'mtn_v3_commands.quests_instant_win', player.name }, { color = CommandColor })
            end
            player.print({ 'mtn_v3_commands.quests_completed' })
        end
    )

Commands.new('mtn_reverse_map', { 'mtn_v3_commands.reverse_map_help' })
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            local reversed = Public.get_stateful_settings('reversed')
            Public.set_stateful_settings('reversed', not reversed)
            Discord.send_notification(
                {
                    title = "Map reversed",
                    description = player.name .. ' reversed the map.',
                    color = "success",
                    fields =
                    {
                        {
                            title = "Server",
                            description = Public.discord_name,
                            inline = "false"
                        }
                    }
                })
            local current_task = Public.get('current_task')
            Public.set_task(current_task.default_task)
            game.print({ 'mtn_v3_commands.reversed_map_and_reset', player.name },
                { color = CommandColor })
            player.print({ 'mtn_v3_commands.map_reversed' })
        end
    )

Commands.new('mtn_set_direction', { 'mtn_v3_commands.set_direction_help' })
    :require_admin()
    :require_validation()
    :add_parameter('north/south/east/west', false, 'string')
    :callback(
        function (player, direction)
            if not Orient.valid_directions[direction] then
                player.print({ 'mtn_v3_commands.invalid_direction' })
                return
            end
            Public.set_stateful_settings('direction', direction)
            Discord.send_notification(
                {
                    title = "Map direction",
                    description = player.name .. ' set the map direction to ' .. direction .. '.',
                    color = "success",
                    fields =
                    {
                        {
                            title = "Server",
                            description = Public.discord_name,
                            inline = "false"
                        }
                    }
                })
            local current_task = Public.get('current_task')
            Public.set_task(current_task.default_task)
            game.print({ 'mtn_v3_commands.set_direction_and_reset', player.name, { 'mtn_v3_map.' .. direction } },
                { color = CommandColor })
            player.print({ 'mtn_v3_commands.map_direction_set_to', { 'mtn_v3_map.' .. direction } })
        end
    )

Commands.new('mtn_disable_biters', { 'mtn_v3_commands.toggle_wave_defense_help' })
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            local tbl = WD.get()

            if not tbl.game_lost then
                Discord.send_notification(
                    {
                        title = "Wave defense disabled",
                        description = player.name .. ' disabled the wave defense module.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                game.print({ 'mtn_v3_commands.has_disabled_the_wave_defense_module', player.name },
                    { color = CommandColor })
                tbl.game_lost = true
            else
                Discord.send_notification(
                    {
                        title = "Wave defense enabled",
                        description = player.name .. ' enabled the wave defense module.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                game.print({ 'mtn_v3_commands.has_enabled_the_wave_defense_module', player.name },
                    { color = CommandColor })
                tbl.game_lost = false
            end
        end
    )

Commands.new('mtn_toggle_darkness', { 'mtn_v3_commands.toggle_darkness_help' })
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
                game.print({ 'mtn_v3_commands.darkness_is_now_disabled' })
                Discord.send_notification(
                    {
                        title = "Surface darkness disabled",
                        description = player.name .. ' disabled surface darkness.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                surface.brightness_visual_weights = { a = 1, b = 0, g = 0, r = 0 }
            else
                Public.set_stateful_settings('darkness', true)
                game.print({ 'mtn_v3_commands.darkness_is_now_enabled' })
                Discord.send_notification(
                    {
                        title = "Surface darkness enabled",
                        description = player.name .. ' enabled surface darkness.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                surface.brightness_visual_weights = { a = 1, b = 0.7, g = 0.7, r = 0.7 }
            end
        end
    )

Commands.new('mtn_grant_permanent_buff', { 'mtn_v3_commands.grant_permanent_buff_help' })
    :require_admin()
    :require_validation({ 'mtn_v3_commands.permanent_buff_confirmation' })
    :callback(
        function (player)
            local buff = Public.grant_non_limit_reached_buff()
            local stateful = Public.get_stateful()
            stateful.permanent_buffs[#stateful.permanent_buffs + 1] = buff
            Discord.send_notification(
                {
                    title = "Permanent buff granted",
                    description = player.name .. ' granted the team a permanent buff: ' .. buff.discord,
                    color = "success",
                    fields =
                    {
                        {
                            title = "Server",
                            description = Public.discord_name,
                            inline = "false"
                        }
                    }
                })
            game.print({ 'mtn_v3_commands.has_granted_the_permanent_buff', player.name, { '?', { 'mtn_v3_buffs.' .. buff.name .. '_description' }, buff.discord } }, { color = CommandColor })
            Public.apply_permanent_buffs()
        end
    )


Commands.new('mtn_toggle_orbital_strikes',
    { 'mtn_v3_commands.toggle_orbital_strikes_help' })
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            local this = Public.get()

            if this.orbital_strikes.enabled then
                Discord.send_notification(
                    {
                        title = "Orbital strikes disabled",
                        description = player.name .. ' disabled the orbital strike module.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                game.print({ 'mtn_v3_commands.has_disabled_the_orbital_strikes_module', player.name },
                    { color = CommandColor })
                this.orbital_strikes.enabled = false
            else
                Discord.send_notification(
                    {
                        title = "Orbital strikes enabled",
                        description = player.name .. ' enabled the orbital strike module.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                game.print({ 'mtn_v3_commands.has_enabled_the_orbital_strikes_module', player.name },
                    { color = CommandColor })
                this.orbital_strikes.enabled = true
            end
        end
    )

Commands.new('mtn_get_queue_speed', { 'mtn_v3_commands.get_queue_speed_help' })
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            player.print(Task.get_queue_speed())
        end
    )

Commands.new('mtn_disable_collapse', { 'mtn_v3_commands.toggle_collapse_help' })
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            if not Collapse.has_collapse_started() then
                Collapse.start_now(true, false)
                Discord.send_notification(
                    {
                        title = "Collapse enabled",
                        description = player.name .. ' has enabled collapse.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                game.print({ 'mtn_v3_commands.has_enabled_collapse', player.name }, { color = CommandColor })
            else
                Collapse.start_now(false, true)
                Discord.send_notification(
                    {
                        title = "Collapse disabled",
                        description = player.name .. ' has disabled collapse.',
                        color = "success",
                        fields =
                        {
                            {
                                title = "Server",
                                description = Public.discord_name,
                                inline = "false"
                            }
                        }
                    })
                game.print({ 'mtn_v3_commands.has_disabled_collapse', player.name },
                    { color = CommandColor })
            end
        end
    )

Commands.new('mtn_grant_fake_buff', { 'mtn_v3_commands.debug_buff_help' })
    :require_admin()
    :require_validation()
    :require_offline_mode()
    :callback(
        function ()
            local Core = require('utils.core')
            Public.set('buff_selection', { buffs = {} })
            local b = Public.grant_non_limit_reached_buff(3)
            Public.init_buff_selection(b)

            Core.iter_connected_players(function (p)
                if p and p.valid then
                    Public.buff_main_frame(p)
                end
            end)
        end
    )

return Public
