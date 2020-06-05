local Event = require 'utils.event'
local Timestamp = require 'utils.timestamp'
local Server = require 'utils.server'
local Color = require 'utils.color_presets'
local Task = require 'utils.task'
local WPT = require 'maps.mountain_fortress_v3.table'

local mapkeeper = '[color=blue]Mapkeeper:[/color]'
local format = string.format

commands.add_command(
    'reset_game',
    'Usable only for admins - resets the game!',
    function()
        local p
        local player = game.player
        local reset_map = require 'maps.mountain_fortress_v3.main'.reset_map
        local this = WPT.get()

        if player then
            if player ~= nil then
                p = player.print
                if not player.admin then
                    p("[ERROR] You're not admin!", Color.fail)
                    return
                end
                if not this.reset_are_you_sure then
                    this.reset_are_you_sure = true
                    player.print(
                        '[WARNING] This command will reset the current game, run this command again if you really want to do this!',
                        Color.yellow
                    )
                    return
                end

                game.print(mapkeeper .. ' ' .. player.name .. ', has reset the game!', {r = 0.98, g = 0.66, b = 0.22})
                this.reset_are_you_sure = nil
                reset_map()
            else
                p = log
                if not this.reset_are_you_sure then
                    this.reset_are_you_sure = true
                    p(
                        '[WARNING] This command will reset the current game, run this command again if you really want to do this!'
                    )
                    return
                end

                game.print(mapkeeper .. ' server, has reset the game!', {r = 0.98, g = 0.66, b = 0.22})
                this.reset_are_you_sure = nil
                reset_map()
            end
        end
    end
)

commands.add_command(
    'disable_reset_game',
    'Usable only for admins - disables the auto-reset of map!',
    function(cmd)
        local p
        local player = game.player
        local this = WPT.get()
        local param = cmd.parameter

        if player then
            if player ~= nil then
                p = player.print
                if not player.admin then
                    p("[ERROR] You're not admin!", Color.fail)
                    return
                end

                if param == 'true' or param == 'false' then
                    goto continue
                else
                    p('[ERROR] Arguments are true or false', Color.yellow)
                    return
                end

                ::continue::

                if not this.reset_are_you_sure then
                    this.reset_are_you_sure = true
                    player.print(
                        '[WARNING] This command will disable the auto-reset feature, run this command again if you really want to do this!',
                        Color.yellow
                    )
                    return
                end

                if param == 'true' then
                    if this.disable_reset then
                        this.reset_are_you_sure = nil
                        return p('[WARNING] Reset is already disabled!', Color.fail)
                    end

                    this.disable_reset = true

                    p('[SUCCESS] Auto-reset is disabled!', Color.success)
                    this.reset_are_you_sure = nil
                elseif param == 'false' then
                    if not this.disable_reset then
                        this.reset_are_you_sure = nil
                        return p('[WARNING] Reset is already enabled!', Color.fail)
                    end

                    this.disable_reset = false
                    p('[SUCCESS] Auto-reset is enabled!', Color.success)
                    this.reset_are_you_sure = nil
                end
            else
                p = log
                if param == 'true' or param == 'false' then
                    goto continue
                else
                    p('[ERROR] Arguments are true/false')
                    return
                end

                ::continue::

                if not this.reset_are_you_sure then
                    this.reset_are_you_sure = true
                    p(
                        '[WARNING] This command will disable the auto-reset feature, run this command again if you really want to do this!'
                    )
                    return
                end

                if param == 'true' then
                    if this.disable_reset then
                        this.reset_are_you_sure = nil
                        return p('[WARNING] Reset is already disabled!')
                    end

                    this.disable_reset = true

                    p('[SUCCESS] Auto-reset is disabled!')
                    this.reset_are_you_sure = nil
                elseif param == 'false' then
                    if not this.disable_reset then
                        this.reset_are_you_sure = nil
                        return p('[WARNING] Reset is already enabled!')
                    end

                    this.disable_reset = false
                    p('[SUCCESS] Auto-reset is enabled!')
                    this.reset_are_you_sure = nil
                end
            end
        end
    end
)

commands.add_command(
    'set_queue_speed',
    'Usable only for admins - sets the queue speed of this map!',
    function(cmd)
        local p
        local player = game.player
        local param = tonumber(cmd.parameter)

        if player then
            if player ~= nil then
                p = player.print
                if not player.admin then
                    p("[ERROR] You're not admin!", Color.fail)
                    return
                end
                if not param then
                    return
                end
                p('Queue speed set to: ' .. param)
                Task.set_queue_speed(param)
            else
                p = log
                p('Queue speed set to: ' .. param)
                Task.set_queue_speed(param)
            end
        end
    end
)

commands.add_command(
    'get_queue_speed',
    'Usable only for admins - gets the queue speed of this map!',
    function()
        local p
        local player = game.player

        if player then
            if player ~= nil then
                p = player.print
                if not player.admin then
                    p("[ERROR] You're not admin!", Color.fail)
                    return
                end
                p(Task.get_queue_speed())
            else
                p = log
                p(Task.get_queue_speed())
            end
        end
    end
)

local function on_console_command(event)
    local cmd = event.command
    if not event.player_index then
        return
    end
    local player = game.players[event.player_index]
    local param = event.parameters

    if not player.admin then
        return
    end

    local server_time = Server.get_current_time()
    if server_time then
        server_time = format('(Server time: %s)', Timestamp.to_string(server_time))
    else
        server_time = game.tick
    end

    if player then
        if param then
            print(player.name .. ' used command: ' .. cmd .. ' with param: ' .. param .. ' at tick: ' .. server_time)
            return
        else
            print(player.name .. ' used command: ' .. cmd .. ' at tick: ' .. server_time)
            return
        end
    else
        if param then
            print('used command: ' .. cmd .. ' with param: ' .. param .. ' at tick: ' .. server_time)
            return
        else
            print('used command: ' .. cmd .. ' at tick: ' .. server_time)
            return
        end
    end
end

Event.add(defines.events.on_console_command, on_console_command)
