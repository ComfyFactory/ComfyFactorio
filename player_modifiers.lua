--Central to add all player modifiers together.
--Will overwrite character stats from other mods.

local Global = require 'utils.global'

local this = {
    modifiers = {},
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
    [1] = 'character_build_distance_bonus',
    [2] = 'character_crafting_speed_modifier',
    [3] = 'character_health_bonus',
    [4] = 'character_inventory_slots_bonus',
    [5] = 'character_item_drop_distance_bonus',
    [6] = 'character_item_pickup_distance_bonus',
    [7] = 'character_loot_pickup_distance_bonus',
    [8] = 'character_mining_speed_modifier',
    [9] = 'character_reach_distance_bonus',
    [10] = 'character_resource_reach_distance_bonus',
    [11] = 'character_maximum_following_robot_count_bonus',
    [12] = 'character_running_speed_modifier'
}

function Public.update_player_modifiers(player)
    for k, modifier in pairs(modifiers) do
        local sum_value = 0
        for _, value in pairs(this.modifiers[player.index][k]) do
            sum_value = sum_value + value
        end
        if player.character then
            if this.disabled_modifier[player.index] and this.disabled_modifier[player.index][k] then
                player[modifier] = 0
            else
                player[modifier] = sum_value
            end
        end
    end
end

function Public.update_single_modifier(player, modifier, category, value)
    if not this.modifiers[player.index] then
        return
    end
    if not modifier then
        return
    end
    for k, _ in pairs(this.modifiers[player.index]) do
        if modifiers[k] == modifier and this.modifiers[player.index][k] then
            if category then
                if not this.modifiers[player.index][k][category] then
                    this.modifiers[player.index][k][category] = {}
                end
                this.modifiers[player.index][k][category] = value
            else
                this.modifiers[player.index][k] = value
            end
        end
    end
end

function Public.disable_single_modifier(player, modifier, value)
    if not this.disabled_modifier[player.index] then
        return
    end
    if not modifier then
        return
    end
    for k, _ in pairs(modifiers) do
        if modifiers[k] == modifier then
            if value then
                this.disabled_modifier[player.index][k] = value
            else
                this.disabled_modifier[player.index][k] = nil
            end
        end
    end
end

function Public.get_single_modifier(player, modifier, category)
    if not this.modifiers[player.index] then
        return
    end
    if not modifier then
        return
    end
    for k, _ in pairs(this.modifiers[player.index]) do
        if modifiers[k] == modifier then
            if category then
                if this.modifiers[player.index][k] and this.modifiers[player.index][k][category] then
                    return this.modifiers[player.index][k][category]
                end
            else
                if this.modifiers[player.index][k] then
                    return this.modifiers[player.index][k]
                end
            end
            return false
        end
    end
    return false
end

function Public.get_single_disabled_modifier(player, modifier, category)
    if not this.disabled_modifier[player.index] then
        return
    end
    if not modifier then
        return
    end
    for k, _ in pairs(this.disabled_modifier[player.index]) do
        if modifiers[k] == modifier then
            if category then
                if this.disabled_modifier[player.index][k] and this.disabled_modifier[player.index][k][category] then
                    return this.disabled_modifier[player.index][k][category]
                end
            else
                if this.disabled_modifier[player.index][k] then
                    return this.disabled_modifier[player.index][k]
                end
            end
            return false
        end
    end
    return false
end

function Public.reset_player_modifiers(player)
    if player and player.valid then
        this.modifiers[player.index] = {}
        this.disabled_modifier[player.index] = {}
        for k, _ in pairs(modifiers) do
            this.modifiers[player.index][k] = {}
        end
        Public.update_player_modifiers(player)
    end
end

local function on_player_joined_game(event)
    local player = game.get_player(event.player_index)
    if this.modifiers[player.index] then
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
