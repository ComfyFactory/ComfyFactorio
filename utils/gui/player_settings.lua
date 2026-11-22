-- created by gerkiz
local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Server = require 'utils.server'
local Style = require 'utils.gui_style'
local Task = require 'utils.task_token'

local Public = {}
local presets = {}
local by_dataset = {}
local action_names =
{
    save = Gui.uid_name(),
    apply = Gui.uid_name(),
    delete = Gui.uid_name(),
    details = Gui.uid_name()
}
local read_timeout = 600
local cache_duration = 30 * 60 -- maybe heavy on backend?
local write_interval = 180
local button_width = 82

local this =
{
    pending = {},
    last_write = {},
    cache = {}
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local function cache_preset(player_name, dataset, value)
    local cached_presets = this.cache[player_name] or {}
    this.cache[player_name] = cached_presets
    cached_presets[dataset] = { value = value, expires_at = game.tick + cache_duration }
end

function Public.register(id, dataset, preset)
    preset.id = id
    preset.dataset = dataset
    presets[#presets + 1] = preset
    by_dataset[dataset] = preset
end

local function caption(key, ...)
    return { 'gui.player_settings_' .. key, ... }
end

local function backend_available()
    return game.is_multiplayer() and not not Server.get_current_time()
end

local function get_backend_section(player)
    local frame = Gui.get_player_active_frame(player)
    return frame and frame.comfy_config_server
end

local function can_edit(player, preset)
    return not preset.can_edit or preset.can_edit(player)
end

local function add_action(toolbar, action, label, enabled, tooltip)
    local button = Style.button(toolbar.add(
        {
            type = 'button',
            name = action_names[action],
            caption = caption(label),
            tooltip = tooltip and caption(tooltip),
            enabled = enabled,
            mouse_button_filter = { 'left' }
        }))
    button.style.width = button_width
end

local function draw_preset(player, card, preset, entry, status)
    Gui.clear(card)
    local width = card.tags.row_width
    local stacked = width < 375
    local column_count = width >= 570 and 4 or 2
    local controls_width = button_width * column_count + Style.spacing.xs * (column_count - 1)
    local text_width = stacked and width or width - controls_width - Style.spacing.sm
    local columns = stacked and card.add({ type = 'flow', direction = 'vertical' }) or Style.toolbar(card)
    if preset.add_input_controls and not stacked then
        columns.style.vertical_align = 'top'
    end
    columns.name = 'columns'
    local summary = columns.add({ type = 'flow', direction = 'vertical' })
    summary.style.width = text_width
    local value = entry.value
    Style.table_heading(Style.text(summary, caption(preset.id), text_width))
    Style.text(summary, caption(status or (value ~= nil and 'saved' or 'empty')), text_width, Style.colors.muted)
    if status then
        return
    end

    local editable = can_edit(player, preset)
    if not editable then
        Style.text(summary, caption('supporter_only'), text_width, Style.colors.muted)
    end
    local hint = preset.input_hint or (preset.apply and not preset.input and preset.id .. '_edit')
    if hint then
        Style.text(summary, caption(hint), text_width, Style.colors.muted)
    end
    local controls = columns.add({ type = 'flow', direction = 'vertical', name = 'preset_controls' })
    controls.style.width = controls_width
    controls.style.vertical_spacing = Style.spacing.xs
    if preset.add_input_controls then
        preset.add_input_controls(controls, value, player, controls_width, editable)
    elseif preset.input then
        local input = controls.add(
            {
                type = 'textfield',
                name = 'preset_value',
                text = preset.input(value, player),
                enabled = editable
            })
        input.style.width = controls_width
    end

    local toolbar = controls.add({
        type = 'table', name = 'actions', column_count = column_count, tags = { dataset = preset.dataset }
    })
    toolbar.style.horizontal_spacing = Style.spacing.xs
    toolbar.style.vertical_spacing = Style.spacing.xs
    if value ~= nil then
        local update_tooltip = preset.update_tooltip or (preset.input and 'update_input_tooltip' or 'update_tooltip')
        add_action(toolbar, 'save', 'update', editable, update_tooltip)
        if preset.apply then
            add_action(toolbar, 'apply', 'apply', editable, preset.apply_tooltip or 'apply_tooltip')
        end
        add_action(toolbar, 'delete', 'delete', editable)
        if preset.describe then
            add_action(toolbar, 'details', 'details', true)
        end
    else
        add_action(toolbar, 'save', 'save', editable)
    end
end

local read_result =
    Task.register(function (data)
        local pending = this.pending[data.key]
        if not pending or not pending[data.data_set] then
            return
        end
        pending[data.data_set] = nil
        if not next(pending) then
            this.pending[data.key] = nil
        end

        local value = data.value or nil
        if not data.cancelled then
            cache_preset(data.key, data.data_set, value)
        end

        local player = backend_available() and game.get_player(data.key)
        local preset = by_dataset[data.data_set]
        local backend = player and get_backend_section(player)
        local card = backend and backend.settings_rows and preset and backend.settings_rows[preset.id]
        if card then
            local entry = Gui.get_data(card)
            entry.ready = not data.cancelled
            entry.value = value
            draw_preset(player, card, preset, entry, data.cancelled and 'timeout' or nil)
        end
    end, true
    )

local expire_reads =
    Task.register(function (request)
        local pending = this.pending[request.name]
        if not pending then
            return
        end
        for _, dataset in ipairs(request.datasets) do
            if pending[dataset] == request.tick then
                Server.cancel_try_get_data(dataset, request.name, read_result)
            end
        end
    end, true
    )

function Public.refresh(player, section)
    local online = backend_available()
    local tags = section.tags
    if tags.online == online then
        return
    end
    tags.online = online
    section.tags = tags
    Gui.destroy(section.settings_rows)
    local rows = Style.settings_table(section, 'settings_rows', tags.width)
    local row_width = rows.tags.row_width
    if not online then
        local message = Style.text(rows, { 'gui.config_server_unavailable' }, row_width, Style.colors.muted)
        message.style.width = row_width
        return
    end

    local pending = this.pending[player.name] or {}
    local cached_presets = this.cache[player.name] or {}
    local datasets = {}
    for _, preset in ipairs(presets) do
        if not preset.available or preset.available() then
            local card = rows.add({ type = 'flow', direction = 'vertical', name = preset.id, tags = { row_width = row_width } })
            card.style.width = row_width
            card.style.vertical_spacing = Style.spacing.xs
            local dataset = preset.dataset
            local cached = cached_presets[dataset]
            local ready = cached ~= nil and game.tick < cached.expires_at
            local entry = { ready = ready, value = ready and cached.value or nil }
            Gui.set_data(card, entry)
            draw_preset(player, card, preset, entry, not ready and 'loading' or nil)
            if not ready and not pending[dataset] then
                this.pending[player.name] = pending
                pending[dataset] = game.tick
                datasets[#datasets + 1] = dataset
                Server.try_get_data_cancelable(dataset, player.name, read_result)
            end
        end
    end
    if #datasets > 0 then
        Task.set_timeout_in_ticks(read_timeout, expire_reads, { name = player.name, datasets = datasets, tick = game.tick })
    end
end

Event.on_nth_tick(120, function ()
    local cache = this.cache
    for player_name, cached_presets in pairs(cache) do
        for dataset, cached in pairs(cached_presets) do
            if game.tick >= cached.expires_at then
                cached_presets[dataset] = nil
            end
        end
        if not next(cached_presets) then
            cache[player_name] = nil
        end
    end

    for _, player in pairs(game.connected_players) do
        local section = get_backend_section(player)
        if section then
            Public.refresh(player, section)
        end
    end
end)

local function notify(card, message)
    if card.result then
        card.result.caption = message
    else
        local result = Style.text(card, message, card.tags.row_width)
        result.name = 'result'
    end
end

local function handle_action(event, action)
    local player = event.player
    local backend = get_backend_section(player)
    local toolbar = event.element.parent
    local preset = by_dataset[toolbar.tags.dataset]
    local card = backend and backend.settings_rows and preset and backend.settings_rows[preset.id]
    local controls = card and card.columns.preset_controls
    if not controls or toolbar ~= controls.actions then
        return
    end
    if not backend_available() then
        Public.refresh(player, backend)
        return
    end

    local entry = Gui.get_data(card)
    if not entry or not entry.ready or (preset.available and not preset.available()) then
        return
    end

    if action == 'details' then
        if card.details then
            card.details.destroy()
            event.element.caption = caption('details')
        elseif entry.value ~= nil then
            local details = card.add({ type = 'text-box', name = 'details', text = preset.describe(entry.value) })
            details.read_only = true
            details.word_wrap = true
            details.style.horizontally_stretchable = true
            details.style.height = 100
            event.element.caption = caption('hide_details')
        end
        return
    end

    if not can_edit(player, preset) then
        return notify(card, caption('supporter_only'))
    end
    if action == 'delete' and not entry.confirm_delete then
        entry.confirm_delete = true
        event.element.caption = caption('confirm_delete')
        return
    end

    local last_write = this.last_write
    local remaining = write_interval - (game.tick - (last_write[player.index] or -write_interval))
    if remaining > 0 then
        return notify(card, caption('rate_limit', math.ceil(remaining / 60)))
    end

    local status
    if action == 'save' then
        local input
        if preset.read_input then
            input = preset.read_input(controls)
        elseif controls.preset_value then
            input = controls.preset_value.text
        end
        local value, failure = preset.save(player, input)
        if value == nil then
            return notify(card, failure or caption('nothing_to_save'))
        end
        entry.value = value
        cache_preset(player.name, preset.dataset, value)
        status = 'saved_status'
    elseif action == 'delete' then
        if preset.remove then
            preset.remove(player)
        else
            Server.set_data(preset.dataset, player.name, nil)
        end
        entry.value = nil
        cache_preset(player.name, preset.dataset, nil)
        status = 'deleted_status'
    else
        if not preset.apply or preset.apply(player, entry.value) == false then
            return notify(card, caption('cannot_apply'))
        end
        status = 'applied_status'
    end
    last_write[player.index] = game.tick
    entry.confirm_delete = nil
    draw_preset(player, card, preset, entry)
    notify(card, caption(status, caption(preset.id)))
end

for action, name in pairs(action_names) do
    Gui.on_click(name, function (event)
        handle_action(event, action)
    end)
end

Event.add(defines.events.on_player_removed, function (event)
    this.last_write[event.player_index] = nil
end)

return Public
