-- created by Gerkiz for ComfyFactorio

local Token = require 'utils.token'
local Color = require 'utils.color_presets'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Core = require 'utils.core'
local Commands = require 'utils.commands'

local quickbar_dataset = 'quickbar'
local quickbar_dataset_modded = 'quickbar_modded'
local logistics_dataset = 'logistics'
local logistics_dataset_modded = 'logistics_modded'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

local this = {
    logistics = {}
}

local ignored_items = {
    ['blueprint'] = true,
    ['blueprint-book'] = true,
    ['deconstruction-planner'] = true,
    ['spidertron-remote'] = true,
    ['upgrade-planner'] = true
}

Global.register(
    this,
    function (t)
        this = t
    end
)

local Public = {}

local function apply_stash(player)
    local stash = this.logistics[player.name]
    if stash then
        for i, slot in pairs(stash) do
            if slot and slot.name then
                player.set_personal_logistic_slot(i, { name = slot.name, min = slot.min, max = slot.max })
            end
        end
        this.logistics[player.name] = nil
    end
end

local fetch_quickbar =
    Token.register(
        function (data)
            local key = data.key
            local value = data.value
            local player = game.players[key]
            if not player or not player.valid then
                return
            end
            if value then
                for i, slot in pairs(value) do
                    if slot and slot ~= '' then
                        player.set_quick_bar_slot(i, slot)
                    end
                end
            end
        end
    )

local fetch_logistics =
    Token.register(
        function (data)
            local key = data.key
            local value = data.value
            local player = game.players[key]
            if not player or not player.valid then
                return
            end
            local tech = player.force.technologies['logistic-robotics'].researched
            if value then
                for i, slot in pairs(value) do
                    if slot and slot.name then
                        if tech then
                            player.set_personal_logistic_slot(i, { name = slot.name, min = slot.min, max = slot.max })
                        else
                            if not this.logistics[player.name] then
                                this.logistics[player.name] = {}
                            end
                            this.logistics[player.name][i] = { name = slot.name, min = slot.min, max = slot.max }
                        end
                    end
                end
            end
        end
    )

--- Tries to get data from the webpanel and applies the value to the player.
-- @param LuaPlayer
function Public.fetch_quickbar(player)
    local dataset = quickbar_dataset
    local game_has_mods = is_game_modded()
    if game_has_mods then
        dataset = quickbar_dataset_modded
    end

    try_get_data(dataset, player.name, fetch_quickbar)
end

--- Tries to get data from the webpanel and applies the value to the player.
-- @param LuaPlayer
function Public.fetch_logistics(player)
    local dataset = logistics_dataset
    local game_has_mods = is_game_modded()
    if game_has_mods then
        dataset = logistics_dataset_modded
    end

    try_get_data(dataset, player.name, fetch_logistics)
end

--- Saves the players quickbar table to the webpanel.
-- @param LuaPlayer
function Public.save_quickbar(player)
    local dataset = quickbar_dataset

    local game_has_mods = is_game_modded()
    if game_has_mods then
        dataset = quickbar_dataset_modded
    end

    local slots = {}

    for i = 1, 100 do
        local slot = player.get_quick_bar_slot(i)
        if slot ~= nil and not ignored_items[slot.name] then
            slots[i] = slot.name
        end
    end
    if next(slots) then
        set_data(dataset, player.name, slots)
        player.print('Your quickbar has been saved.', Color.success)
    end
end

--- Saves the players personal logistics table to the webpanel.
-- @param LuaPlayer
function Public.save_logistics(player)
    local dataset = logistics_dataset

    local game_has_mods = is_game_modded()
    if game_has_mods then
        dataset = logistics_dataset_modded
    end

    local slots = {}

    for i = 1, 400 do
        local slot = player.get_personal_logistic_slot(i)
        if slot and slot.name then
            slots[i] = { name = slot.name, min = slot.min, max = slot.max }
        end
    end
    if next(slots) then
        set_data(dataset, player.name, slots)
        player.print('Your personal logistics has been saved.', Color.success)
    end
end

--- Removes the quickbar key from the webpanel.
-- @param LuaPlayer
function Public.remove_quickbar(player)
    local dataset = quickbar_dataset

    local game_has_mods = is_game_modded()
    if game_has_mods then
        dataset = quickbar_dataset_modded
    end

    set_data(dataset, player.name, nil)
    player.print('Your quickbar has been removed.', Color.success)
end

--- Removes the logistics key from the webpanel.
-- @param LuaPlayer
function Public.remove_logistics(player)
    local dataset = logistics_dataset

    local game_has_mods = is_game_modded()
    if game_has_mods then
        dataset = logistics_dataset_modded
    end

    set_data(dataset, player.name, nil)
    player.print('Your personal logistics has been removed.', Color.success)
end

local fetch_quickbar_on_join = Public.fetch_quickbar
local fetch_logistics_on_join = Public.fetch_logistics
local save_quickbar = Public.save_quickbar
local save_logistics = Public.save_logistics
local remove_quickbar = Public.remove_quickbar
local remove_logistics = Public.remove_logistics

Commands.new('save-quickbar', 'Save your personal quickbar preset so it´s always the same.')
    :require_backend()
    :callback(
        function (player)
            save_quickbar(player)
            player.print('Quickbar saved.')
        end
    )

Commands.new('save-logistics', 'Save your personal logistics preset so it´s always the same.')
    :require_backend()
    :callback(
        function (player)
            local success, _ = pcall(save_logistics, player)
            player.print('Notice: only the first 400 slots are saved.', Color.warning)
            if not success then
                player.print('An error occured while trying to save your logistics slots.', Color.warning)
                return false
            end
            player.print('Logistics saved.')
        end
    )

Commands.new('remove-quickbar', 'Removes your personal quickbar preset from the datastore.')
    :require_backend()
    :callback(
        function (player)
            remove_quickbar(player)
            player.print('Quickbar removed.')
        end
    )

Commands.new('remove-logistics', 'Removes your personal logistics preset from the datastore.')
    :require_backend()
    :callback(
        function (player)
            remove_logistics(player)
            player.print('Logistics removed.')
        end
    )


Event.add(
    defines.events.on_player_joined_game,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local secs = Server.get_current_time()
        if not secs then
            return
        end

        fetch_quickbar_on_join(player)
        fetch_logistics_on_join(player)
    end
)

Event.add(
    defines.events.on_research_finished,
    function (event)
        local research = event.research
        if research.name == 'logistic-robotics' then
            Core.iter_connected_players(
                function (player)
                    apply_stash(player)
                end
            )
        end
    end
)

return Public
