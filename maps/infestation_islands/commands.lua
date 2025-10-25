local Public = require 'maps.infestation_islands.table'
local Server = require 'utils.server'
local Color = require 'utils.color_presets'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Scheduler = require 'utils.scheduler'
local Commands = require 'utils.commands'
local Discord = require 'utils.discord_handler'

Commands.new('toggle_auto_create_islands', 'Toggles the autogenerate islands.')
    :require_admin()
    :require_validation('Utilize this only when testing the map generation!')
    :add_parameter('state', false, 'boolean')
    :callback(
        function (player, state)
            if not state then
                Public.set('auto_create_islands', false)
                player.print('The autogenerate islands has been disabled!', { color = Color.warning })
                return
            end

            Public.set('auto_create_islands', true)
            player.print('The autogenerate islands has been enabled!', { color = Color.warning })
            local this = Public.get()
            if this.market_target then
                this.position = this.market_target.position
            else
                this.position = { x = 0, y = 0 }
            end
            this.current_level = this.current_level + 1
            this.attack_grace_period = game.tick + 54000
            this.cooldown_complete_level = game.tick + (60 * 60)
            this.alive_enemies = 999
            Scheduler.new(1, Public.init_next_island_token)
                :set_data({ surface = game.surfaces[1], position = this.position })
        end
    )


Commands.new('show_centered_gps', 'Shows the centered points of the map.')
    :require_admin()
    :callback(
        function (player)
            local this = Public.get()
            for level, point in pairs(this.islands_data) do
                player.print('Level ' .. level .. ':')
                player.print('[gps=' .. point.position.x .. ',' .. point.position.y .. ',' .. player.surface.name .. ']')
            end
        end
    )

Commands.new('set_biter_count', 'Sets the biter count.')
    :require_admin()
    :add_parameter('count', false, 'number')
    :callback(
        function (player, count)
            local this = Public.get()
            this.max_biters_per_island = count
            player.print('The biter count has been set to ' .. count .. '!', { color = Color.warning })
        end
    )

Commands.new('send_enemies', 'Sends enemies to the market.')
    :require_admin()
    :callback(
        function (player)
            Public.set_multi_command()
            player.print('Enemies have been sent to the market!', { color = Color.warning })
            return true
        end
    )

Commands.new('toggle_drift_corpses_toward_beach', 'Toggles the drift corpses toward beach.')
    :require_admin()
    :add_parameter('state', false, 'boolean')
    :callback(
        function (player, state)
            Public.set('drift_corpses_toward_beach_enabled', state)
            player.print('The drift corpses toward beach has been ' .. (state and 'enabled' or 'disabled') .. '!', { color = Color.warning })
        end
    )

Commands.new('set_infinite_ammo_tick', 'Sets the infinite ammo tick.')
    :require_admin()
    :add_parameter('tick', false, 'number')
    :callback(
        function (player, tick)
            if tick < 10 then
                return player.print('The infinite ammo tick must be at least 10 ticks!', { color = Color.warning })
            end
            if tick > 100 then
                return player.print('The infinite ammo tick must be less than 100 ticks!', { color = Color.warning })
            end
            Public.set('infinite_ammo_tick', tick)
            player.print('The infinite ammo tick has been set to ' .. tick .. '!', { color = Color.warning })
        end
    )

Commands.new('skip_difficulty_vote', 'Skips the difficulty vote.')
    :require_admin()
    :callback(
        function (player)
            Difficulty.set_poll_closing_timeout(game.tick)
            player.print('The difficulty vote has been skipped!', { color = Color.warning })
        end
    )

Commands.new('skip_voting_to_progress', 'Toggles the voting to progress.')
    :require_admin()
    :add_parameter('state', false, 'boolean')
    :callback(
        function (player, state)
            if not state then
                Public.set('voting_to_progress_enabled', true)
                player.print('The voting to progress has been enabled!', { color = Color.warning })
                return
            end

            Public.set('voting_to_progress_enabled', false)
            player.print('The voting to progress has been disabled!', { color = Color.warning })
        end
    )

Commands.new('reward_level', 'Rewards the level.')
    :require_admin()
    :callback(
        function (player)
            local level = Public.get('current_level')
            local center_position = Public.get('islands_data')[level]
            if not center_position then
                center_position =
                {
                    position = { x = 0, y = 0 }
                }
            end
            Public.reward_level(game.surfaces[1], center_position)
            player.print('Level ' .. level .. ' has been rewarded!', { color = Color.warning })
        end
    )

Commands.new('set_clear_items_on_ground', 'Sets the clear items on ground state.')
    :require_admin()
    :add_parameter('state', false, 'boolean')
    :callback(
        function (player, state)
            Public.set('clear_items_on_ground_state', state)
            player.print('Clear items on ground has been ' .. (state and 'enabled' or 'disabled') .. '!', { color = Color.warning })
        end
    )

Commands.new('toggle_check_surface_daytime', 'Checks the surface daytime if an attack towards the market should be sent.')
    :require_admin()
    :add_parameter('state', false, 'boolean')
    :callback(
        function (player, state)
            Public.set('check_surface_daytime_for_attacks', state)
            player.print('The check surface daytime has been ' .. (state and 'enabled' or 'disabled') .. '!', { color = Color.warning })
        end
    )

Commands.new('toggle_disable_multi_command_attack', 'Disables waves of enemies from being sent to the market.')
    :require_admin()
    :add_parameter('state', false, 'boolean')
    :callback(
        function (player, state)
            Public.set('disable_multi_command_attack', state)
            player.print('The disable multi command attack has been ' .. (state and 'enabled' or 'disabled') .. '!', { color = Color.warning })
        end
    )

Commands.new('scenario', 'Usable only for admins - controls the scenario!')
    :require_admin()
    :require_validation()
    :add_parameter('reset', false, 'string')
    :callback(
        function (player, action)
            local this = Public.get()

            if action == 'reset' then
                goto continue
            else
                player.print('Invalid action.')
                return false
            end

            ::continue::

            if action == 'reset' then
                this.reset_are_you_sure = nil
                if player and player.valid then
                    game.print(Public.island_keeper .. player.name .. ', has reset the game!',
                        { color = Public.command_color })
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
                    game.print(Public.island_keeper .. 'server, has reset the game!', { color = Public.command_color })
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
                this.game_lost = true
                this.game_reset_tick = 1
                player.print('Game has been reset!')
            end
        end
    )

Commands.new('server', 'Usable only for admins - controls the server!')
    :require_admin()
    :require_validation()
    :add_parameter('restart/shutdown/restart-now', false, 'string')
    :callback(
        function (player, action)
            local this = Public.get()

            if action == 'restart' or action == 'shutdown' or action == 'restart-now' then
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
                    player.print('Soft-reset is enabled.')
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
                    player.print('Soft-reset is disabled! Server will restart from scenario to load new changes.')
                end
            elseif action == 'restart-now' then
                this.reset_are_you_sure = nil
                Server.start_scenario('Infestation_Islands')
                Discord.send_notification(
                    {
                        title = "Server restarted",
                        description = player.name .. ' restarted the server.',
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
                player.print('Restarted the server.')
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

                    player.print('Soft-reset is enabled.')
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
                    player.print('Soft-reset is disabled! Server will shutdown.')
                end
            end
        end
    )

Commands.new('switch_game_mode', 'Switches the game mode - for admins.')
    :require_admin()
    :add_parameter('state', false, 'boolean')
    :callback(
        function (player, state)
            if state then
                Public.set('game_over_if_market_dies', true)
                player.print('Game mode switched!')
                player.print('The game will be over if any market dies!', { color = Color.warning })
            else
                Public.set('game_over_if_market_dies', false)
                player.print('Game mode switched!')
                player.print('The biters will try to conquer islands, but the game will not be over if any market dies unless it\'s the last one!', { color = Color.warning })
            end
        end
    )

Commands.new('do_buried_biters', 'Spawns some biters at a given explored level!')
    :require_admin()
    :add_parameter('level', false, 'number')
    :add_parameter('count', false, 'number')
    :callback(
        function (player, level, count)
            Public.do_buried_biters(level)
            local islands_data = Public.get('islands_data')
            local last_level = Public.get('current_level')
            local position = islands_data[level] and islands_data[level].position
            if not position then
                return player.print('Level ' .. level .. ' has not been explored yet!', { color = Color.warning })
            end

            if level > last_level then
                return player.print('Level ' .. level .. ' is not the last level!', { color = Color.warning })
            end

            Public.buried_biter(game.surfaces[1], position, count, 'enemy', Public.qualities[math.random(1, #Public.qualities)])
            player.print('Buried biters have been spawned at level ' .. level .. '!', { color = Color.warning })
        end
    )


Commands.new('reverse_start_position', 'Reverses the start position from where the snake should start at.')
    :require_admin()
    :add_parameter('state', false, 'boolean')
    :callback(
        function (player, state)
            Public.set('reverse_start_position', state)
            if not state then
                return player.print('The snake will start from the parent island and move towards the new island!', { color = Color.warning })
            else
                return player.print('The snake will start from the new island and move towards the parent island!', { color = Color.warning })
            end
        end
    )

Commands.new('set_auto_generate_upon_idle', 'Sets whether the next island should be automatically generated upon idle.')
    :require_admin()
    :add_parameter('state', false, 'boolean')
    :callback(
        function (player, state)
            if not state then
                Public.set('auto_generate_upon_idle', false)
                player.print('New islands will not be automatically generated upon idle!', { color = Color.warning })
            else
                Public.set('auto_generate_upon_idle', true)
                player.print('New islands will be automatically generated upon idle!', { color = Color.warning })
            end
        end
    )
