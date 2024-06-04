local DebugView = require 'utils.debug.main_view'
local Commands = require 'utils.commands'
local Gui = require 'utils.gui'

Commands.new('debug', 'Usable only for admins - opens the debugger!')
    :require_admin()
    :callback(
        function (player)
            local screen = player.gui.screen
            local frame = screen[DebugView.main_frame_name]
            if frame and frame.valid then
                Gui.destroy(frame)
            end

            DebugView.open_debug(player)
        end
    )

if _DEBUG then
    local Model = require 'model'

    local loadstring = loadstring
    local pcall = pcall
    local dump = Model.dump
    local log = log

    Commands.new('dump-log', 'Dumps value to log')
        :require_admin()
        :add_parameter('value', false, 'string')
        :callback(
            function (player, value)
                local func, err = loadstring('return ' .. value)

                if not func then
                    player.print(err)
                    return false
                end

                local suc, v = pcall(func)

                if not suc then
                    player.print(v)
                    return false
                end

                log(dump(v))
            end
        )

    Commands.new('dump-file', 'Dumps value to dump.lua')
        :require_admin()
        :add_parameter('value', false, 'string')
        :callback(
            function (player, value)
                local func, err = loadstring('return ' .. value)

                if not func then
                    player.print(err)
                    return false
                end

                local suc, v = pcall(func)

                if not suc then
                    player.print(v)
                    return false
                end

                v = dump(v)
                game.write_file('dump.lua', v, false)
            end
        )
end
