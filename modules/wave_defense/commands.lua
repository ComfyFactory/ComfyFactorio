local Public = require 'modules.wave_defense.table'

commands.add_command(
    'wd_debug_module',
    '',
    function(cmd)
        local player = game.player
        local param = tostring(cmd.parameter)
        if param == nil then
            return
        end

        if not (player and player.valid) then
            return
        end

        if not player.admin then
            return
        end

        if param == 'spawn_wave' then
            return Public.spawn_unit_group(true, true)
        end

        if param == 'set_next_wave' then
            for _ = 1, 100 do
                Public.set_next_wave()
            end
            return Public.spawn_unit_group(true, true)
        end

        if param == 'set_wave_1500' then
            for _ = 1, 1500 do
                Public.set_next_wave()
            end
            return Public.spawn_unit_group(true, true)
        end

        if param == 'log_all' then
            return Public.toggle_debug()
        end

        if param == 'debug_health' then
            local this = Public.get()

            Public.toggle_debug_health()

            this.next_wave = 1000
            this.wave_interval = 200
            this.wave_enforced = true
            this.debug_only_on_wave_500 = true
        end
    end
)

return Public
