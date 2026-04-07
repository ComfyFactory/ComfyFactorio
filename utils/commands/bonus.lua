local Event = require 'utils.event'
local Global = require 'utils.global'
local Modifiers = require 'utils.player_modifiers'
local Color = require 'utils.color_presets'
local SessionData = require 'utils.datastore.session_data'
local Commands = require 'utils.commands'

local Public = {}

local this =
{
    bonuses = {}
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

function Public.get_table()
    return this
end

local settings =
{
    [1] = { key = 'character_build_distance_bonus', scale = 20 },
    [2] = { key = 'character_crafting_speed_modifier', scale = 3 },
    [3] = { key = 'character_health_bonus', scale = 0 },
    [4] = { key = 'character_inventory_slots_bonus', scale = 200 },
    [5] = { key = 'character_item_drop_distance_bonus', scale = 0 },
    [6] = { key = 'character_item_pickup_distance_bonus', scale = 0 },
    [7] = { key = 'character_loot_pickup_distance_bonus', scale = 0 },
    [8] = { key = 'character_mining_speed_modifier', scale = 3 },
    [9] = { key = 'character_reach_distance_bonus', scale = 20 },
    [10] = { key = 'character_resource_reach_distance_bonus', scale = 0 },
    [11] = { key = 'character_maximum_following_robot_count_bonus', scale = 0 },
    [12] = { key = 'character_running_speed_modifier', scale = 3 }
}

Commands.new('bonus', 'Set your player bonus (speed, mining etc)')
    :require_role('bonus-limit')
    :require_role('bonus')
    :add_parameter('bonus', false, 'integer')
    :callback(function (player, bonus)
        local limit = 50
        local player_role = SessionData.get_role(player)
        if player_role.name == 'Casual' then
            limit = 25
        end
        if not bonus or bonus < 0 or bonus > limit then
            if not SessionData.allowed(player, 'bonus-override') then
                player.print('Invalid range. Valid range is between 0 - ' .. limit .. '.', Color.fail)
                return
            end
        end
        for _, setting in pairs(settings) do
            Modifiers.update_single_modifier(player, setting.key, 'bonus', setting.scale * math.floor(bonus) * 0.01)
            player[setting.key] = setting.scale * math.floor(bonus) * 0.01
        end
        Modifiers.update_player_modifiers(player)
        this.bonuses[player.index] = bonus
        player.print('Bonus set to: ' .. math.floor(bonus) .. '%', Color.success)
    end)

Event.add(
    defines.events.on_player_respawned,
    function (event)
        local player = game.players[event.player_index]
        local bonus = this.bonuses[player.index]
        if bonus then
            for _, setting in pairs(settings) do
                player[setting.key] = setting.scale * math.floor(bonus) * 0.01
            end
        end
    end
)

Event.add(
    defines.events.on_pre_player_died,
    function (event)
        local player = game.players[event.player_index]
        if SessionData.allowed(player, 'bonus-respawn') then
            player.ticks_to_respawn = 120
        end
    end
)

return Public
