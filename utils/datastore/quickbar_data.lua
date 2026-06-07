-- created by Gerkiz for ComfyFactorio

local Task = require 'utils.task_token'
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
local is_game_modded = ServerCommands.is_game_modded()

local this =
{
    logistics = {}
}

local ignored_items =
{
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

local function check_if_item_exists(item)
    if not prototypes.item[item] then
        return false
    end
    return true
end

local function apply_logistic_network(player, saved_data)
    if not saved_data then
        return
    end
    if player.get_requester_point() then
        if saved_data[1] and (saved_data[1].name or not saved_data[1].group) then
            local old_section = player.get_requester_point().get_section(1)
            local has_data = false
            if old_section then
                for i, slot in pairs(saved_data) do
                    if slot and (slot.name or slot) and check_if_item_exists(slot.name or slot) then
                        has_data = true
                        local item = prototypes.item[slot.name or slot]
                        local item_stack = { min = slot.min or 1, max = slot.max or 1, value = { comparator = "=", name = slot.name or slot, quality = slot.quality or "normal", type = slot.type or item.type or nil } }
                        pcall(old_section.set_slot, i, item_stack)
                    end
                end
            end
            if has_data then
                old_section.group = 'Migrated from old format'
                old_section.active = true
            end

            return true
        else
            for index, section in pairs(saved_data) do
                local new_section = player.get_requester_point().get_section(index) or player.get_requester_point().add_section()

                if section and new_section then
                    local slots = section.slots
                    if not slots or not section.group then
                        Server.output_script_data('[ERROR] Invalid data format for section ' .. index .. ' for player ' .. player.name)
                        return false
                    end
                    new_section.group = section.group
                    new_section.active = section.active
                    if slots and type(slots) == 'table' then
                        for i, slot in pairs(slots) do
                            if slot and slot.name and check_if_item_exists(slot.name) then
                                local item_stack = { min = slot.min, max = slot.max, value = { comparator = "=", name = slot.name, quality = slot.quality or "normal", type = slot.type or nil } }
                                pcall(new_section.set_slot, i, item_stack)
                            end
                        end
                    end
                end
            end
            return true
        end
    else
        if this.logistics[player.name] and this.logistics[player.name] == 1 then
            return false
        end

        this.logistics[player.name] = saved_data
    end
end

local function apply_stash(player)
    local saved_data = this.logistics[player.name]
    apply_logistic_network(player, saved_data)
    this.logistics[player.name] = nil
end

local post_apply_token =
    Task.register(
        function ()
            Core.iter_connected_players(
                function (player)
                    apply_stash(player)
                end
            )
        end
    )

local fetch_quickbar =
    Task.register(
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
    Task.register(
        function (data)
            local key = data.key
            local saved_data = data.value
            local player = game.get_player(key)
            if not player or not player.valid then
                return
            end
            if saved_data then
                apply_logistic_network(player, saved_data)
            end
        end
    )

--- Tries to get data from the webpanel and applies the value to the player.
-- @param LuaPlayer
function Public.fetch_quickbar(player)
    local dataset = quickbar_dataset
    if is_game_modded then
        dataset = quickbar_dataset_modded
    end

    try_get_data(dataset, player.name, fetch_quickbar)
end

--- Tries to get data from the webpanel and applies the value to the player.
-- @param LuaPlayer
function Public.fetch_logistics(player)
    local dataset = logistics_dataset
    if is_game_modded then
        dataset = logistics_dataset_modded
    end

    try_get_data(dataset, player.name, fetch_logistics)
end

--- Saves the players quickbar table to the webpanel.
-- @param LuaPlayer
function Public.save_quickbar(player)
    local dataset = quickbar_dataset

    if is_game_modded then
        dataset = quickbar_dataset_modded
    end

    local slots = {}

    for i = 1, 100 do
        local slot = player.get_quick_bar_slot(i)
        if slot ~= nil and not ignored_items[slot.name] then
            slots[i] = { name = slot.name, quality = slot.quality or "normal" }
        end
    end
    if next(slots) then
        set_data(dataset, player.name, slots)
        player.print('Your quickbar has been saved.', { color = Color.success })
    end
end

--- Saves the players personal logistics table to the webpanel.
-- @param LuaPlayer
function Public.save_logistics(player)
    local dataset = logistics_dataset

    if not player.get_requester_point() then
        return false
    end

    if is_game_modded then
        dataset = logistics_dataset_modded
    end

    local sections = {}

    for sec = 1, 8 do
        local section = player.get_requester_point().get_section(sec)
        if section then
            if not sections[section.index] then
                sections[section.index] = {}
            end
            local slots = {}
            for i = 1, 100 do
                local slot = section.get_slot(i)
                if slot and next(slot) then
                    slots[i] = { name = slot.value.name, min = slot.min, max = slot.max, quality = slot.value.quality, type = slot.value.type, comparator = slot.value.comparator }
                end
            end
            if next(slots) then
                sections[section.index].group = section.group
                sections[section.index].active = section.active
                sections[section.index].slots = slots
            end
        end
    end

    if next(sections) then
        set_data(dataset, player.name, sections)
        player.print('Your personal logistics has been saved.', { color = Color.success })
        return true
    else
        return false
    end
end

--- Removes the quickbar key from the webpanel.
-- @param LuaPlayer
function Public.remove_quickbar(player)
    local dataset = quickbar_dataset

    if is_game_modded then
        dataset = quickbar_dataset_modded
    end

    set_data(dataset, player.name, nil)
    player.print('Your quickbar has been removed.', { color = Color.success })
end

--- Removes the logistics key from the webpanel.
-- @param LuaPlayer
function Public.remove_logistics(player)
    local dataset = logistics_dataset

    if is_game_modded then
        dataset = logistics_dataset_modded
    end

    set_data(dataset, player.name, nil)
    player.print('Your personal logistics has been removed.', { color = Color.success })
end

local fetch_quickbar_on_join = Public.fetch_quickbar
local fetch_logistics_on_join = Public.fetch_logistics
local save_quickbar = Public.save_quickbar
local save_logistics = Public.save_logistics
local remove_quickbar = Public.remove_quickbar
local remove_logistics = Public.remove_logistics

Commands.new('save-quickbar', 'Save your personal quickbar preset so it´s always the same.')
    :callback(
        function (player)
            save_quickbar(player)
            player.print('Quickbar saved.', { color = Color.success })
        end
    )

Commands.new('restore-quickbar', 'Restores your personal quickbar preset from the datastore.')
    :callback(
        function (player)
            fetch_quickbar_on_join(player)
            player.print('Quickbar restored.', { color = Color.success })
        end)

Commands.new('save-logistics', 'Save your personal logistics preset so it´s always the same.')
    :require_backend()
    :callback(
        function (player)
            local success = save_logistics(player)
            if not success then
                player.print('An error occured while trying to save your logistics slots.', { color = { color = Color.warning } })
                return false
            end
            player.print('Notice: only 8 sections are saved.', { color = { color = Color.warning } })
            player.print('Logistics saved.', { color = Color.success })
        end
    )

Commands.new('restore-logistics', 'Restores your personal logistics preset from the datastore.')
    :callback(
        function (player)
            fetch_logistics_on_join(player)
            player.print('Logistics restored.', { color = Color.success })
        end
    )

Commands.new('remove-quickbar', 'Removes your personal quickbar preset from the datastore.')
    :require_backend()
    :callback(
        function (player)
            remove_quickbar(player)
            player.print('Quickbar removed.', { color = Color.success })
        end
    )

Commands.new('remove-logistics', 'Removes your personal logistics preset from the datastore.')
    :require_backend()
    :callback(
        function (player)
            remove_logistics(player)
            player.print('Logistics removed.', { color = Color.success })
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
            Task.set_timeout_in_ticks(10, post_apply_token)
        end
    end
)

return Public
