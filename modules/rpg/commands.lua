local RPG = require 'modules.rpg.table'
local Utils = require 'utils.core'
local Color = require 'utils.color_presets'

local round = math.round

local validate_args = function(data)
    local player = data.player
    local target = data.target
    local rpg_t = RPG.get_value_from_player(target.index)

    if not target then
        return false
    end

    if not target.valid then
        return false
    end

    if not target.character then
        return false
    end

    if not target.connected then
        return false
    end

    if not game.players[target.index] then
        return false
    end

    if not player then
        return false
    end

    if not player.valid then
        return false
    end

    if not player.character then
        return false
    end

    if not player.connected then
        return false
    end

    if not game.players[player.index] then
        return false
    end

    if not target or not game.players[target.index] then
        Utils.print_to(player, 'Invalid name.')
        return false
    end

    if not rpg_t then
        Utils.print_to(player, 'Invalid target.')
        return false
    end

    return true
end

local print_stats = function(target)
    if not target then
        return
    end
    local rpg_t = RPG.get_value_from_player(target.index)
    if not rpg_t then
        return
    end

    local level = rpg_t.level
    local xp = round(rpg_t.xp)
    local strength = rpg_t.strength
    local magicka = rpg_t.magicka
    local dexterity = rpg_t.dexterity
    local vitality = rpg_t.vitality
    local output = '[color=blue]' .. target.name .. '[/color] has the following stats: \n'
    output = output .. '[color=green]Level:[/color] ' .. level .. '\n'
    output = output .. '[color=green]XP:[/color] ' .. xp .. '\n'
    output = output .. '[color=green]Strength:[/color] ' .. strength .. '\n'
    output = output .. '[color=green]Magic:[/color] ' .. magicka .. '\n'
    output = output .. '[color=green]Dexterity:[/color] ' .. dexterity .. '\n'
    output = output .. '[color=green]Vitality:[/color] ' .. vitality

    return output
end

commands.add_command(
    'stats',
    'Check what stats a user has!',
    function(cmd)
        local player = game.player

        if not player or not player.valid then
            return
        end

        local param = cmd.parameter
        if not param then
            return
        end

        if param == '' then
            return
        end

        local target = game.players[param]
        if not target or not target.valid then
            return
        end

        local data = {
            player = player,
            target = target
        }

        if validate_args(data) then
            local msg = print_stats(target)
            player.play_sound {path = 'utility/scenario_message', volume_modifier = 1}
            player.print(msg)
        else
            player.print('Please type a name of a player who is connected.', Color.warning)
        end
    end
)
