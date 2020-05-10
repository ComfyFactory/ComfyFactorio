local Color = require 'utils.color_presets'
local WPT = require 'maps.scrapyard.table'

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

if _DEBUG then
    commands.add_command(
        'reset_game',
        'Debug only, reset the game!',
        function()
            local reset_map = require 'maps.scrapyard.main'.reset_map

            local player = game.player

            if player then
                if player ~= nil then
                    if not player.admin then
                        return
                    end
                end
            end
            reset_map()
        end
    )
end
