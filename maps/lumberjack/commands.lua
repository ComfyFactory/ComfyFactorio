local Color = require 'utils.color_presets'
local WPT = require 'maps.lumberjack.table'
local Task = require 'utils.task'

local grandmaster = '[color=blue]Grandmaster:[/color]'

commands.add_command(
    'rainbow_mode',
    'This will prevent new tiles from spawning when walking',
    function()
        local player = game.player
        local this = WPT.get_table()
        if player and player.valid then
            if this.players[player.index].tiles_enabled == false then
                this.players[player.index].tiles_enabled = true
                player.print('Rainbow mode: ON', Color.green)
                return
            end
            if this.players[player.index].tiles_enabled == true then
                this.players[player.index].tiles_enabled = false
                player.print('Rainbow mode: OFF', Color.warning)
                return
            end
        end
    end
)

commands.add_command(
    'reset_game',
    'Usable only for admins - resets the game!',
    function()
        local p
        local player = game.player
        local reset_map = require 'maps.lumberjack.main'.reset_map

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
        game.print(grandmaster .. ' ' .. player.name .. ', has reset the game!', {r = 0.98, g = 0.66, b = 0.22})

        reset_map()
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
