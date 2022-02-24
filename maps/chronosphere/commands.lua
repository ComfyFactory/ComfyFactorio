local Color = require 'utils.color_presets'
local Server = require 'utils.server'
local Chrono_table = require 'maps.chronosphere.table'

local function scenario(p, parameter)
    local objective = Chrono_table.get_table()
    if parameter == 'resetmap' then
        if objective.restart_confirm == 'resetmap' then
            game.print({'chronosphere.cmd_game_restarting'}, Color.warning)
            objective.game_lost = true
            script.raise_event(Chrono_table.events['reset_map'], {})
            return
        else
            p({'chronosphere.cmd_reset_map_confirm'}, Color.warning)
            objective.restart_confirm = 'resetmap'
            return
        end
    elseif parameter == 'hardreset' then
        if objective.restart_hard then
            p({'chronosphere.cmd_hardreset_disabled'}, Color.success)
            objective.restart_hard = false
            return
        else
            p({'chronosphere.cmd_hardreset_enabled'}, Color.success)
            objective.restart_hard = true
            return
        end
    elseif parameter == 'hardresetnow' then
        if objective.restart_confirm == 'hardreset' then
            game.print({'chronosphere.cmd_server_restarting'}, Color.warning)
            Server.start_scenario('Chronosphere')
            return
        else
            p({'chronosphere.cmd_hardreset_confirm'}, Color.warning)
            objective.restart_confirm = 'hardreset'
            return
        end
    else
        p({'chronosphere.command_scenario'}, Color.info)
        objective.restart_confirm = nil
    end
end

local function cmd_handler(cmd)
    local p
    if not cmd.player_index then
        p = log
    else
        local player = game.get_player(cmd.player_index)
        if not player or not player.valid then
            p = log
        else
            p = player.print
            if not player.admin then
                p({'chronosphere.cmd_not_admin'}, Color.fail)
                return
            end
        end
    end
    local command_name = cmd.name
    if command_name == 'scenario' then
        scenario(p, cmd.parameter)
    elseif command_name == 'chronojump' then
        script.raise_event(Chrono_table.events['chronojump'], {cmd.parameter})
    end
end


commands.add_command('scenario', {'chronosphere.command_scenario'}, function(cmd) cmd_handler(cmd) end)
if _DEBUG then
    commands.add_command('chronojump', 'Weeeeee!', function(cmd) cmd_handler(cmd) end)
end
