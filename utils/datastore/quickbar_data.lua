-- created by Gerkiz for ComfyFactorio

local Task = require 'utils.task_token'
local Color = require 'utils.color_presets'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Core = require 'utils.core'
local Commands = require 'utils.commands'
local PlayerSettings = require 'utils.gui.player_settings'

local function quickbar_page_and_slot(player, index)
    local width = player.quick_bar_width
    if not width or width < 1 then width = 10 end
    local page = math.floor((index - 1) / width) + 1
    local slot = (index - 1) % width + 1
    return page, slot
end

local function get_quick_bar_slot(player, index)
    local page, slot = quickbar_page_and_slot(player, index)
    local value = player.get_quick_bar_slot(page, slot)
    if value and value.type == 'filter' and value.filter and value.filter.name then
        return value
    end
end

local function set_quick_bar_slot(player, index, filter)
    local page, slot = quickbar_page_and_slot(player, index)
    if type(filter) == 'table' and filter.name and not filter.type then
        local name = filter.name
        if type(name) ~= 'string' then
            name = name.name
        end
        if not name or not prototypes.item[name] then
            return
        end
        local quality = filter.quality or 'normal'
        if type(quality) ~= 'string' then
            quality = quality.name or 'normal'
        end
        if not (prototypes.quality and prototypes.quality[quality]) then
            quality = 'normal'
        end
        filter = {
            type = 'filter',
            filter = {
                name = name,
                quality = quality,
                comparator = filter.comparator or '='
            }
        }
    elseif type(filter) == 'string' and not prototypes.item[filter] then
        return
    end
    player.set_quick_bar_slot(page, slot, filter)
end

local is_game_modded = ServerCommands.is_game_modded()
local quickbar_dataset = is_game_modded and 'quickbar_modded' or 'quickbar'
local logistics_dataset = is_game_modded and 'logistics_modded' or 'logistics'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

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

local function is_legacy_logistics(saved_data)
    for _, slot in pairs(saved_data) do
        if type(slot) == 'string' or slot.name then
            return true
        end
    end
    return false
end

local function apply_logistic_network(player, saved_data)
    if not saved_data then
        return
    end
    if player.get_requester_point() then
        if is_legacy_logistics(saved_data) then
            local old_section = player.get_requester_point().get_section(1)
            local has_data = false
            if old_section then
                for i, slot in pairs(saved_data) do
                    local name = type(slot) == 'table' and slot.name or slot
                    if type(name) == 'string' and check_if_item_exists(name) then
                        has_data = true
                        local request = type(slot) == 'table' and slot or {}
                        local item_stack = { min = request.min or 1, max = request.max or 1, value = { comparator = request.comparator or '=', name = name, quality = request.quality or 'normal', type = request.type or prototypes.item[name].type } }
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
                if section.slots and section.group then
                    local new_section = player.get_requester_point().get_section(index) or player.get_requester_point().add_section()
                    new_section.group = section.group
                    new_section.active = section.active
                    for i, slot in pairs(section.slots) do
                        if slot and slot.name and check_if_item_exists(slot.name) then
                            local item_stack = { min = slot.min, max = slot.max, value = { comparator = slot.comparator or '=', name = slot.name, quality = slot.quality or 'normal', type = slot.type } }
                            pcall(new_section.set_slot, i, item_stack)
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

local function apply_quickbar(player, slots)
    for i, slot in pairs(slots) do
        if slot ~= '' then
            set_quick_bar_slot(player, i, slot)
        end
    end
end

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
                apply_quickbar(player, value)
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
    try_get_data(quickbar_dataset, player.name, fetch_quickbar)
end

--- Tries to get data from the webpanel and applies the value to the player.
-- @param LuaPlayer
function Public.fetch_logistics(player)
    try_get_data(logistics_dataset, player.name, fetch_logistics)
end

--- Saves the players quickbar table to the webpanel.
-- @param LuaPlayer
local function save_quickbar_preset(player)
    local slots = {}

    for i = 1, 100 do
        local slot = get_quick_bar_slot(player, i)
        if slot and not ignored_items[slot.filter.name] then
            slots[i] = { name = slot.filter.name, quality = slot.filter.quality or "normal" }
        end
    end
    if next(slots) then
        set_data(quickbar_dataset, player.name, slots)
        return slots
    end
end

function Public.save_quickbar(player)
    if save_quickbar_preset(player) then
        player.print('Your quickbar has been saved.', { color = Color.success })
    end
end

--- Saves the players personal logistics table to the webpanel.
-- @param LuaPlayer
local function save_logistics_preset(player)
    local requester = player.get_requester_point()
    if not requester then
        return
    end

    local sections = {}
    local has_requests = false
    for sec = 1, 8 do
        local section = requester.get_section(sec)
        if section then
            local slots = {}
            for i = 1, 100 do
                local slot = section.get_slot(i)
                if slot and slot.value then
                    slots[i] = { name = slot.value.name, min = slot.min, max = slot.max, quality = slot.value.quality, type = slot.value.type, comparator = slot.value.comparator }
                    has_requests = true
                end
            end
            sections[section.index] = { group = section.group, active = section.active, slots = slots }
        end
    end

    if has_requests then
        set_data(logistics_dataset, player.name, sections)
        return sections
    end
end

function Public.save_logistics(player)
    if save_logistics_preset(player) then
        player.print('Your personal logistics has been saved.', { color = Color.success })
        return true
    end
    return false
end

--- Removes the quickbar key from the webpanel.
-- @param LuaPlayer
function Public.remove_quickbar(player)
    set_data(quickbar_dataset, player.name, nil)
    player.print('Your quickbar has been removed.', { color = Color.success })
end

--- Removes the logistics key from the webpanel.
-- @param LuaPlayer
local function remove_logistics_preset(player)
    set_data(logistics_dataset, player.name, nil)
    this.logistics[player.name] = nil
end

function Public.remove_logistics(player)
    remove_logistics_preset(player)
    player.print('Your personal logistics has been removed.', { color = Color.success })
end

local function describe_slots(lines, slots, limit, logistics)
    for i = 1, limit do
        local slot = slots[i]
        if type(slot) == 'string' and slot ~= '' then
            lines[#lines + 1] = i .. '. ' .. slot
        elseif type(slot) == 'table' and slot.name then
            local text = i .. '. ' .. slot.name .. ' (' .. (slot.comparator or '=') .. ' ' .. (slot.quality or 'normal') .. ')'
            if logistics then
                text = text .. '  ' .. tostring(slot.min or 0) .. '–' .. tostring(slot.max or '∞')
            end
            lines[#lines + 1] = text
        end
    end
end

PlayerSettings.register('quickbar', quickbar_dataset, {
    save = save_quickbar_preset,
    apply = apply_quickbar,
    describe = function (slots)
        local lines = {}
        describe_slots(lines, slots, 100)
        return table.concat(lines, '\n')
    end
})

PlayerSettings.register('logistics', logistics_dataset, {
    save = save_logistics_preset,
    remove = remove_logistics_preset,
    apply = function (player, value)
        if not player.get_requester_point() then
            return false
        end
        return apply_logistic_network(player, value)
    end,
    describe = function (sections)
        local lines = {}
        if is_legacy_logistics(sections) then
            describe_slots(lines, sections, 100, true)
        else
            for i = 1, 8 do
                local section = sections[i]
                if section and section.slots then
                    local title = 'Section ' .. i .. (section.group ~= '' and ' · ' .. section.group or '')
                    lines[#lines + 1] = title .. (section.active and '' or ' (inactive)')
                    describe_slots(lines, section.slots, 100, true)
                end
            end
        end
        return table.concat(lines, '\n')
    end
})

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
