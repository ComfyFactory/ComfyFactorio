if _DEBUG then
    local Public = require 'modules.wave_defense.table'

    commands.add_command(
        'debug_wd_module',
        '',
        function()
            local player = game.player

            if not (player and player.valid) then
                return
            end

            if not player.admin then
                return
            end

            Public.toggle_debug()
        end
    )

    commands.add_command(
        'debug_wd_health',
        '',
        function()
            local player = game.player

            if not (player and player.valid) then
                return
            end

            if not player.admin then
                return
            end

            Public.toggle_debug_health()
        end
    )

    commands.add_command(
        'debug_wd_spawn_wave',
        '',
        function()
            local player = game.player

            if not (player and player.valid) then
                return
            end

            if not player.admin then
                return
            end

            WDM.spawn_unit_group(true)
        end
    )
end
