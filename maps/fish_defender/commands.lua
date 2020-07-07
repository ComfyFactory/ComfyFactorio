local Server = require 'utils.server'
local FDT = require 'maps.fish_defender.table'

local mapkeeper = '[color=blue]Mapkeeper:[/color]'

commands.add_command(
    'fishy_commands',
    'Usable only for admins - controls the scenario!',
    function(cmd)
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

        local this = FDT.get()
        local reset_map = require 'maps.fish_defender.main'.on_init
        local param = cmd.parameter

        if param == 'reset' or param == 'restartnow' then
            goto continue
        else
            p('[ERROR] Arguments are:\nreset\nrestartnow')
            return
        end

        ::continue::

        if not this.reset_are_you_sure then
            this.reset_are_you_sure = true
            p(
                '[WARNING] This command will disable the soft-reset feature, run this command again if you really want to do this!'
            )
            return
        end

        if param == 'restartnow' then
            this.reset_are_you_sure = nil
            p(player.name .. ' has restarted the game.')
            Server.start_scenario('Fish_defense')
            return
        elseif param == 'reset' then
            this.reset_are_you_sure = nil
            if player and player.valid then
                game.print(mapkeeper .. ' ' .. player.name .. ', has reset the game!', {r = 0.98, g = 0.66, b = 0.22})
            else
                game.print(mapkeeper .. ' server, has reset the game!', {r = 0.98, g = 0.66, b = 0.22})
            end
            reset_map()
            p('[WARNING] Game has been reset!')
            return
        end
    end
)
