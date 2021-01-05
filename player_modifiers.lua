--Central to add all player modifiers together.
--Will overwrite character stats from other mods.

local Global = require 'utils.global'

local this = {
    disabled_modifier = {}
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local Public = {}

function Public.get_table()
    return this
end

local modifiers = {
    'character_build_distance_bonus',
    'character_crafting_speed_modifier',
    'character_health_bonus',
    'character_inventory_slots_bonus',
    'character_item_drop_distance_bonus',
    'character_item_pickup_distance_bonus',
    'character_loot_pickup_distance_bonus',
    'character_mining_speed_modifier',
    'character_reach_distance_bonus',
    'character_resource_reach_distance_bonus',
    'character_maximum_following_robot_count_bonus',
    'character_running_speed_modifier'
}

function Public.update_player_modifiers(player)
    for _, modifier in pairs(modifiers) do
        local sum_value = 0
        for _, value in pairs(this[player.index][modifier]) do
            sum_value = sum_value + value
        end
        if player.character then
            if this.disabled_modifier[player.index] and this.disabled_modifier[player.index][modifier] then
                player[modifier] = 0
            else
                player[modifier] = sum_value
            end
        end
    end
end

function Public.reset_player_modifiers(player)
    if player and player.valid then
        this[player.index] = {}
        if this.disabled_modifier[player.index] then
            this.disabled_modifier[player.index] = {}
        end
        for _, modifier in pairs(modifiers) do
            this[player.index][modifier] = {}
        end
        Public.update_player_modifiers(player)
    end
end

local function on_player_joined_game(event)
    local player = game.get_player(event.player_index)
    if this[player.index] then
        Public.update_player_modifiers(player)
        return
    end
    Public.reset_player_modifiers(player)
end

local function on_player_respawned(event)
    Public.update_player_modifiers(game.players[event.player_index])
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)

return Public
