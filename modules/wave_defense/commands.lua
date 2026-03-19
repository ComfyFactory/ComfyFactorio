local Public = require 'modules.wave_defense.table'
local Commands = require 'utils.commands'
local module_name = '[WD]'

-- Skip grace time
Commands.new('wd_skip_grace', 'Usable only for admins - skips wave defense grace time!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            Public.get('enable_grace_time').enabled = false
            player.print(module_name .. ' grace skipped!')
            return true
        end
    )

-- Toggle ES (Evolution System)
Commands.new('wd_toggle_es', 'Usable only for admins - toggles wave defense ES!')
    :require_admin()
    :require_validation()
    :add_parameter('state', true, 'boolean')
    :callback(
        function (player, state)
            Public.set_es_enabled(state or false)
            player.print(module_name .. ' ES has been toggled to: ' .. tostring(state or false))
            return true
        end
    )

-- Toggle ES boss tracking
Commands.new('wd_toggle_es_boss', 'Usable only for admins - toggles wave defense ES boss tracking!')
    :require_admin()
    :require_validation()
    :add_parameter('state', true, 'boolean')
    :callback(
        function (player, state)
            Public.set_track_bosses_only(state or false)
            player.print(module_name .. ' ES bosses has been toggled to: ' .. tostring(state or false))
            return true
        end
    )

-- Spawn current wave
Commands.new('wd_spawn_wave', 'Usable only for admins - spawns the current wave!')
    :require_admin()
    :require_validation()
    :add_parameter('wave count', true, 'number')
    :add_parameter('bosses', true, 'boolean')
    :callback(
        function (player, number, bosses)
            if number then
                for _ = 1, number, 1 do
                    Public.set_next_wave()
                end
                Public.spawn_unit_group({ true }, bosses or false)
            else
                Public.set_next_wave()
                Public.spawn_unit_group({ true }, bosses or false)
            end
            player.print(module_name .. ' wave spawned!')
            return true
        end
    )

-- Spawn current wave
Commands.new('wd_set_wave', 'Usable only for admins - sets the wave number!')
    :require_admin()
    :require_validation()
    :add_parameter('wave number', true, 'number')
    :callback(
        function (player, number)
            Public.set('threat', 0)
            Public.set('wave_number', number)
            player.print(module_name .. ' wave number set to: ' .. number)
            return true
        end
    )


-- Toggle debug logging
Commands.new('wd_toggle_debug', 'Usable only for admins - toggles wave defense debug logging!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            Public.toggle_debug()
            player.print(module_name .. ' debug toggled!')
            return true
        end
    )

-- Toggle debug health mode
Commands.new('wd_debug_health', 'Usable only for admins - toggles wave defense debug health mode!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            Public.toggle_debug_health()
            local this = Public.get()

            this.next_wave = 1000
            this.wave_interval = 200
            this.wave_enforced = true
            this.debug_only_on_wave_500 = true
            player.print(module_name .. ' debug health toggled!')
            return true
        end
    )

return Public
