-- created by Gerkiz
local Server = require 'utils.server'
local Scheduler = require 'utils.scheduler'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Color = require 'utils.color_presets'
local Commands = require 'utils.commands'
local Discord = require 'utils.discord_handler'

local Public = {}

local this =
{
    shutdown_in_ticks = 60 * 60 * 60 * 4, -- 4 hours
    interval_in_ticks = 5 * 60 * 60, -- 5 minutes
    dev_server = false,
}

local valid_dev_names =
{
    'developer',
    'dev_server',
    'test',
    'test_server',
    'dev',
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local shutdown_server_token =
    Scheduler.register_function(
        'shutdown_server_token',
        function ()
            Discord.send_notification(
                {
                    title = 'Server is shutting down',
                    description = 'Time has been reached, shutting down server from script.',
                    color = 'success',
                    fields =
                    {
                        {
                            title = 'Server',
                            description = Server.get_server_name(),
                            inline = 'false'
                        }
                    }
                })
            this.shutdown_task_uid = nil
            this.notify_task_uid = nil
            Server.output_script_data('Time has been reached, shutting down server from script.')
            Server.stop_scenario()
        end)

local function get_shutdown_time_message()
    local ticks_remaining = this.shutdown_in_ticks - game.tick
    if ticks_remaining < 0 then ticks_remaining = 0 end
    local total_minutes = math.floor(ticks_remaining / 3600)
    local hours = math.floor(total_minutes / 60)
    local minutes = total_minutes % 60

    local message = '[Script Handler] Server is shutting down in '
    if hours > 0 then
        message = message .. hours .. ' hour' .. (hours > 1 and 's' or '')
        if minutes > 0 then
            message = message .. ' and ' .. minutes .. ' minute' .. (minutes > 1 and 's' or '')
        end
    else
        message = message .. minutes .. ' minute' .. (minutes > 1 and 's' or '')
    end
    message = message .. '...'
    return message
end

local function get_shutdown_time_remaining()
    local ticks_remaining = this.shutdown_in_ticks - game.tick
    if ticks_remaining < 0 then ticks_remaining = 0 end
    return ticks_remaining
end

local notify_players_token =
    Scheduler.register_function(
        'notify_players_token',
        function ()
            local message = get_shutdown_time_message()

            local players = game.connected_players
            for i = 1, #players do
                local player = players[i]
                player.print(message, { color = Color.warning })
            end
        end)

Event.add(defines.events.on_player_joined_game, function (event)
    if not this.dev_server then
        return
    end

    local player = game.get_player(event.player_index)

    if _DEBUG then
        player.print('[color=yellow][Script Handler][/color] This is a development server running with [color=orange]_DEBUG[/color] enabled.')
    else
        player.print('[color=yellow][Script Handler][/color] This is a development server.')
    end

    local message = get_shutdown_time_message()

    if player then
        player.print(message, { color = Color.warning })
    end
end)

Event.add(ServerCommands.events.on_server_started, function ()
    if this.shutdown_task_uid then
        return
    end

    local server_name_matches = false
    for _, name in pairs(valid_dev_names) do
        if Server.check_server_name(name) then
            server_name_matches = true
            break
        end
    end

    if server_name_matches then
        this.dev_server = true
        Server.output_script_data('Server is a developer server, shutting down in 4 hours...')
        local task = Scheduler.new(this.shutdown_in_ticks, shutdown_server_token)
        this.shutdown_task_uid = task._uid

        local notify_task = Scheduler.new_interval(this.interval_in_ticks, task._tick, notify_players_token)
        this.notify_task_uid = notify_task._uid
    else
        if this.shutdown_task_uid then
            local task = Scheduler.get_task_by_uid(this.shutdown_task_uid)
            if task then
                task:cancel_task()
            end
            this.shutdown_task_uid = nil
        end

        if this.notify_task_uid then
            local task = Scheduler.get_task_by_uid(this.notify_task_uid)
            if task then
                task:cancel_task()
            end
            this.notify_task_uid = nil
        end
    end
end)

Commands.new('change_shutdown_time', 'Changes the shutdown time for the developer server.')
    :require_admin()
    :require_validation()
    :add_parameter('time in hours', false, 'number')
    :callback(
        function (player, time)
            if not this.dev_server then
                player.print('This server is not a developer server.', { color = Color.warning })
                return
            end

            if time < 1 then
                player.print('Shutdown time cannot be less than 1 hour.', { color = Color.warning })
                return
            end
            if time > 74 then
                player.print('Shutdown time cannot be greater than 74 hours.', { color = Color.warning })
                return
            end

            if not this.shutdown_task_uid then
                player.print('Shutdown task not found, please restart the server.', { color = Color.warning })
                return
            end


            local task = Scheduler.get_task_by_uid(this.shutdown_task_uid)
            local notify_task = Scheduler.get_task_by_uid(this.notify_task_uid)
            if task and notify_task then
                this.shutdown_in_ticks = 60 * 60 * 60 * time

                task:set_delay(this.shutdown_in_ticks)
                notify_task._until_tick = task._tick
                player.print('[Script Handler] Shutdown time has been changed to ' .. time .. ' hour(s).')
            end
        end
    )

Commands.new('change_interval_time', 'Changes how often the server will notify players that it is shutting down.')
    :require_admin()
    :require_validation()
    :add_parameter('time in minutes', false, 'number')
    :callback(
        function (player, time)
            if not this.dev_server then
                player.print('This server is not a developer server.', { color = Color.warning })
                return
            end

            if time < 1 then
                player.print('Interval time cannot be less than 1 minute.', { color = Color.warning })
                return
            end
            if time > 60 then
                player.print('Interval time cannot be greater than 60 minutes.', { color = Color.warning })
                return
            end

            if not this.notify_task_uid then
                player.print('Shutdown task not found, please restart the server.', { color = Color.warning })
                return
            end

            local task = Scheduler.get_task_by_uid(this.shutdown_task_uid)
            local notify_task = Scheduler.get_task_by_uid(this.notify_task_uid)

            if task and notify_task then
                this.interval_in_ticks = time * 60 * 60
                notify_task:set_interval(this.interval_in_ticks, task._tick)
                player.print('[Script Handler] Interval time has been changed to ' .. time .. ' minute(s).')
            end
        end
    )

function Public.is_dev_server()
    return this.dev_server
end

function Public.get_shutdown_time_remaining()
    return get_shutdown_time_remaining()
end

return Public
