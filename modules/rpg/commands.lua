local Public = require 'modules.rpg.table'
local Utils = require 'utils.core'
local Color = require 'utils.color_presets'
local Commands = require 'utils.commands'

local round = math.round

local validate_args = function (data)
    local player = data.player
    local target = data.target
    local rpg_t = Public.get_value_from_player(target.index)

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

local print_stats = function (target)
    if not target then
        return
    end
    local rpg_t = Public.get_value_from_player(target.index)
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

Commands.new('stats', 'Check what stats a user has!')
    :add_parameter('player', false, 'player')
    :callback(
        function (player, target)
            local data = {
                player = player,
                target = target
            }

            if validate_args(data) then
                local msg = print_stats(target)
                player.play_sound { path = 'utility/scenario_message', volume_modifier = 1 }
                player.print(msg)
            else
                player.print('[Stats] Please type a name of a player who is connected.', Color.warning)
                return false
            end
        end
    )


if _DEBUG then
    Commands.new('give_xp', 'Give a player XP!')
        :require_admin()
        :add_parameter('amount', false, 'number')
        :callback(
            function (_, amount)
                Public.give_xp(amount)
                game.print('Distributed ' .. amount .. ' of xp.')
            end
        )

    Commands.new('rpg_debug_module', 'Toggle debug mode for RPG module!')
        :require_admin()
        :callback(
            function ()
                Public.toggle_debug()
            end
        )

    Commands.new('rpg_debug_aoe_punch', 'Toggle debug mode for RPG module!')
        :require_admin()
        :callback(
            function ()
                Public.toggle_debug_aoe_punch()
            end
        )

    Commands.new('rpg_cheat_stats', 'Cheat stats for testing purposes!')
        :require_admin()
        :callback(
            function ()
                local data = Public.get('rpg_t')
                for k, _ in pairs(data) do
                    data[k].dexterity = 999
                    data[k].enable_entity_spawn = true
                    data[k].explosive_bullets = true
                    data[k].level = 1000
                    data[k].magicka = 999
                    data[k].mana = 50000
                    data[k].mana_max = 50000
                    data[k].debug_mode = true
                    data[k].aoe_punch = true
                    data[k].stone_path = true
                    data[k].strength = 3000
                    data[k].vitality = 3000
                    data[k].xp = 456456
                    local p = game.get_player(k)
                    if p and p.valid then
                        Public.update_player_stats(p)
                    end
                end
            end
        )
end

local RPG_Interface = {
    rpg_reset_player = function (player_name)
        if player_name then
            local player = game.get_player(player_name)
            if player and player.valid then
                return Public.rpg_reset_player(player)
            else
                error('Remote call parameter to RPG rpg_reset_player must be a valid player name and not nil.')
            end
        else
            error('Remote call parameter to RPG rpg_reset_player must be a valid player name and not nil.')
        end
    end,
    give_xp = function (amount)
        if type(amount) == 'number' then
            return Public.give_xp(amount)
        else
            error('Remote call parameter to RPG give_xp must be number and not nil.')
        end
    end,
    gain_xp = function (player_name, amount)
        if player_name then
            local player = game.get_player(player_name)
            if player and player.valid and type(amount) == 'number' then
                return Public.gain_xp(player, amount)
            else
                error('Remote call parameter to RPG give_xp must be a valid player name and contain amount(number) and not nil.')
            end
        else
            error('Remote call parameter to RPG give_xp must be a valid player name and contain amount(number) and not nil.')
        end
    end
}

if not remote.interfaces['RPG'] then
    remote.add_interface('RPG', RPG_Interface)
end

return Public
