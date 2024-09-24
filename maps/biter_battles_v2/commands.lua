--luacheck:ignore
local Server = require 'utils.server'
local mapkeeper = '[color=blue]Mapkeeper:[/color]'

commands.add_command(
    'scenario',
    'Usable only for admins - controls the scenario!',
    function (cmd)
        local p
        local player = game.player

        if not player or not player.valid then
            p = log
        else
            p = player.print
            if not player.admin then
                return
            end
        end

        local param = cmd.parameter

        if param == 'restart' or param == 'shutdown' or param == 'restartnow' then
            goto continue
        else
            p('[ERROR] Arguments are:\nrestart\nshutdown\nrestartnow')
            return
        end

        ::continue::

        if not storage.reset_are_you_sure then
            storage.reset_are_you_sure = true
            p('[WARNING] This command will disable the soft-reset feature, run this command again if you really want to do this!')
            return
        end

        if param == 'restart' then
            if storage.restart then
                storage.reset_are_you_sure = nil
                storage.restart = false
                storage.soft_reset = true
                p('[SUCCESS] Soft-reset is enabled.')
                return
            else
                storage.reset_are_you_sure = nil
                storage.restart = true
                storage.soft_reset = false
                if storage.shutdown then
                    storage.shutdown = false
                end
                p('[WARNING] Soft-reset is disabled! Server will restart from scenario.')
                return
            end
        elseif param == 'restartnow' then
            storage.reset_are_you_sure = nil
            p(player.name .. ' has restarted the game.')
            Server.start_scenario('Biter_Battles')
            return
        elseif param == 'shutdown' then
            if storage.shutdown then
                storage.reset_are_you_sure = nil
                storage.shutdown = false
                storage.soft_reset = true
                p('[SUCCESS] Soft-reset is enabled.')
                return
            else
                storage.reset_are_you_sure = nil
                storage.shutdown = true
                storage.soft_reset = false
                if storage.restart then
                    storage.restart = false
                end
                p('[WARNING] Soft-reset is disabled! Server will shutdown.')
                return
            end
        end
    end
)
