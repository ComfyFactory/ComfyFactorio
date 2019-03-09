local DebugView = require 'utils.debug.main_view'

commands.add_command(
    'debug',
    'Opens the debugger',
    function(_, player)
        local player = game.player
        local p
        if player then
            p = player.print
            if not player.admin then
                p('Only admins can use this command.')
                return
            end
        else
            p = player.print
        end
		DebugView.open_dubug(player)
    end
)
