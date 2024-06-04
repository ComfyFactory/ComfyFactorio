local Public = require 'modules.wave_defense.table'
local Commands = require 'utils.commands'
local module_name = '[WD]'

Commands.new('wd_debug_module', 'Usable only for admins - controls wave defense module!')
    :require_admin()
    :require_validation()
    :add_parameter('skip/toggle_es/toggle_es_boss/spawn/next/next_50/next_1500/log_all/debug_health', false, 'string')
    :callback(
        function (player, action)
            if action == 'skip' then
                Public.get('enable_grace_time').enabled = false
                player.print(module_name .. ' grace skipped!')
                return true
            end

            if action == 'toggle_es' then
                Public.set_module_status()
                player.print(module_name .. ' ES has been toggled!')
                return true
            end

            if action == 'toggle_es_boss' then
                Public.set_track_bosses_only()
                player.print(module_name .. ' ES bosses has been toggled!')
                return true
            end

            if action == 'spawn' then
                Public.spawn_unit_group({ true }, true)
                player.print(module_name .. ' wave spawned!')
                return true
            end

            if action == 'next' then
                Public.set_next_wave()
                Public.spawn_unit_group({ true }, true)
                player.print(module_name .. ' wave spawned!')
                return true
            end

            if action == 'next_50' then
                for _ = 1, 50 do
                    Public.set_next_wave()
                end
                Public.spawn_unit_group({ true }, true)
                player.print(module_name .. ' wave spawned!')
                return true
            end

            if action == 'next_1500' then
                for _ = 1, 1500 do
                    Public.set_next_wave()
                end
                Public.spawn_unit_group({ true }, true)
                player.print(module_name .. ' wave spawned!')
                return true
            end

            if action == 'log_all' then
                Public.toggle_debug()
                player.print(module_name .. ' debug toggled!')
                return true
            end

            if action == 'debug_health' then
                Public.toggle_debug_health()
                local this = Public.get()

                this.next_wave = 1000
                this.wave_interval = 200
                this.wave_enforced = true
                this.debug_only_on_wave_500 = true
                player.print(module_name .. ' debug health toggled!')
                return true
            end
        end
    )

return Public
