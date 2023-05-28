local Public = require 'modules.wave_defense.table'
local module_name = '[WD]'

commands.add_command(
    'wd_debug_module',
    '',
    function(cmd)
        local p
        local player = game.player

        if not player or not player.valid then
            p = print
        else
            p = player.print
            if not player.admin then
                return
            end
        end

        local param = tostring(cmd.parameter)
        if param == nil then
            return
        end

        if param == 'skip' then
            Public.get('enable_grace_time').enabled = false
            p(module_name .. ' grace skipped!')
            return
        end

        if param == 'toggle_es' then
            Public.set_module_status()
            p(module_name .. ' ES has been toggled!')
            return
        end

        if param == 'spawn_wave' then
            Public.spawn_unit_group(true, true)
            p(module_name .. ' wave spawned!')
            return
        end

        if param == 'next_wave' then
            Public.set_next_wave()
            Public.spawn_unit_group(true, true)
            p(module_name .. ' wave spawned!')
            return
        end

        if param == 'set_next_50' then
            for _ = 1, 50 do
                Public.set_next_wave()
            end
            Public.spawn_unit_group(true, true)
            p(module_name .. ' wave spawned!')
            return
        end

        if param == 'set_wave_1500' then
            for _ = 1, 1500 do
                Public.set_next_wave()
            end
            Public.spawn_unit_group(true, true)
            p(module_name .. ' wave spawned!')
            return
        end

        if param == 'log_all' then
            Public.toggle_debug()
            p(module_name .. ' debug toggled!')
            return
        end

        if param == 'debug_health' then
            local this = Public.get()

            Public.toggle_debug_health()

            this.next_wave = 1000
            this.wave_interval = 200
            this.wave_enforced = true
            this.debug_only_on_wave_500 = true
            p(module_name .. ' debug health toggled!')
        end
    end
)

return Public
