local Color = require 'utils.color_presets'
local Task = require 'utils.task'
local WPT = require 'maps.lumberjack.table'

local grandmaster = '[color=blue]Grandmaster:[/color]'

commands.add_command(
    'reset_game',
    'Usable only for admins - resets the game!',
    function()
        local p
        local player = game.player
        local reset_map = require 'maps.lumberjack.main'.reset_map
        local this = WPT.get_table()

        if player then
            if player ~= nil then
                p = player.print
                if not player.admin then
                    p("[ERROR] You're not admin!", Color.fail)
                    return
                end
            else
                p = log
            end
        end
        if not this.reset_are_you_sure then
            this.reset_are_you_sure = true
            player.print(
                '[WARNING] This command will reset the current game, run this command again if you really want to do this!',
                Color.yellow
            )
            return
        end

        game.print(grandmaster .. ' ' .. player.name .. ', has reset the game!', {r = 0.98, g = 0.66, b = 0.22})
        this.reset_are_you_sure = nil
        reset_map()
    end
)

commands.add_command(
    'disable_reset_game',
    'Usable only for admins - disables the auto-reset of map!',
    function(cmd)
        local p
        local player = game.player
        local this = WPT.get_table()
        local param = tostring(cmd.parameter)

        if player then
            if player ~= nil then
                p = player.print
                if not player.admin then
                    p("[ERROR] You're not admin!", Color.fail)
                    return
                end
            else
                p = log
            end
        end
        if not param then
            p('[ERROR] Arguments are true/false', Color.yellow)
            return
        end

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
    end
)

if _DEBUG then
    commands.add_command(
        'get_queue_speed',
        'Debug only, return the current task queue speed!',
        function()
            local player = game.player

            if player then
                if player ~= nil then
                    if not player.admin then
                        return
                    end
                end
            end
            game.print(Task.get_queue_speed())
        end
    )
end
