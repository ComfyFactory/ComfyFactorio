--Central to add all player modifiers together.
--Will overwrite character stats from other mods.

local Event = require 'utils.event'
local Global = require 'utils.global'

local round = math.round

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

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
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
    local player_modifiers = this.modifiers[player.index]
    if not player_modifiers then
        return
    end

    local disabled_modifiers = this.disabled_modifier[player.index]
    if not disabled_modifiers then
        return
    end

    for k, modifier in pairs(modifiers) do
        local sum_value = 0
        for _, value in pairs(player_modifiers[k]) do
            sum_value = sum_value + value
        end
        if player.character then
            if disabled_modifiers and disabled_modifiers[k] then
                player[modifier] = 0
            else
                player[modifier] = round(sum_value, 8)
            end
        end
    end
end

function Public.update_single_modifier(player, modifier, category, value)
    local player_modifiers = this.modifiers[player.index]
    if not player_modifiers then
        return
    end
    if not modifier then
        return
    end
    for k, _ in pairs(player_modifiers) do
        if modifiers[k] == modifier and player_modifiers[k] then
            if category then
                if not player_modifiers[k][category] then
                    player_modifiers[k][category] = {}
                end
                player_modifiers[k][category] = value
            else
                player_modifiers[k] = value
            end
        end
    end
end

function Public.disable_single_modifier(player, modifier, value)
    local disabled_modifiers = this.disabled_modifier[player.index]
    if not disabled_modifiers then
        return
    end
    if not modifier then
        return
    end
    for k, _ in pairs(modifiers) do
        if modifiers[k] == modifier then
            if value then
                disabled_modifiers[k] = value
            else
                disabled_modifiers[k] = nil
            end
        end
    end
end

function Public.get_single_modifier(player, modifier, category)
    local player_modifiers = this.modifiers[player.index]
    if not player_modifiers then
        return
    end
    if not modifier then
        return
    end
    for k, _ in pairs(player_modifiers) do
        if modifiers[k] == modifier then
            if category then
                if player_modifiers[k] and player_modifiers[k][category] then
                    return player_modifiers[k][category]
                end
            else
                if player_modifiers[k] then
                    return player_modifiers[k]
                end
            end
            return false
        end
    end
    return false
end

function Public.get_single_disabled_modifier(player, modifier, category)
    local disabled_modifiers = this.disabled_modifier[player.index]
    if not disabled_modifiers then
        return
    end
    if not modifier then
        return
    end
    for k, _ in pairs(disabled_modifiers) do
        if modifiers[k] == modifier then
            if category then
                if disabled_modifiers[k] and disabled_modifiers[k][category] then
                    return disabled_modifiers[k][category]
                end
            else
                if disabled_modifiers[k] then
                    return disabled_modifiers[k]
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

local function on_player_removed(event)
    if this.modifiers[event.player_index] then
        this.modifiers[event.player_index] = nil
    end
    if this.disabled_modifier[event.player_index] then
        this.disabled_modifier[event.player_index] = nil
    end
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_removed, on_player_removed)

return Public
