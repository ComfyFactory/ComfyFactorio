-- created by Gerkiz for ComfyFactorio

local Gui = require 'utils.gui'
local Style = require 'utils.gui_style'
local Task = require 'utils.task_token'
local StatData = require 'utils.datastore.statistics'
local format_number = require 'util'.format_number
local Server = require 'utils.server'
local Event = require 'utils.event'

local Public = {}

local module_name = Gui.uid_name()
local tab_name = 'Statistics'

local ignored_stats =
{
    ['name'] = true,
    ['tick'] = true
}

local normalized_names = StatData.normalized_names

local function statistic_caption(value)
    return type(value) == 'number' and format_number(value, true) or value
end

local function draw_score(player, frame, stats, state)
    frame.clear()
    if not state then
        state = {}
        Gui.set_data(frame, state)
    end

    local width = Style.content_width(player, frame)
    Style.heading(frame, 'Your statistics')
    state.warning = Style.text(frame, 'Statistics are temporary - disconnected from Comfy backend.', width, Style.colors.muted)
    state.warning.visible = not Server.get_current_time()

    local names = {}
    for name in pairs(stats) do
        if not ignored_stats[name] and normalized_names[name] then
            names[#names + 1] = name
        end
    end
    table.sort(names)

    local proportions = width >= 590 and { 1, 1, 1 } or width >= 320 and { 1, 1 } or { 1 }
    local widths = Style.column_widths(width, proportions, Style.spacing.md)
    local columns = #widths
    local grid = frame.add({ type = 'table', column_count = columns })
    grid.style.minimal_width = width
    grid.style.horizontal_spacing = Style.spacing.md
    grid.style.vertical_spacing = Style.spacing.sm
    local rows = {}
    for index, name in ipairs(names) do
        local stat = stats[name]
        local info = normalized_names[name]
        local _, label = Style.metric(grid, info.name or name, statistic_caption(stat), info.tooltip, widths[(index - 1) % columns + 1])
        rows[name] = { label = label, value = stat }
    end
    state.rows = rows
    state.count = #names
end

local function show_score(data)
    local frame = data.frame
    draw_score(data.player, frame, StatData.get_data(data.player), Gui.get_data(frame))
end

local function update_score(player, frame)
    local state = Gui.get_data(frame)
    local stats = StatData.get_data(player)
    if not state or not state.warning.valid then
        draw_score(player, frame, stats, state)
        return
    end

    local count = 0
    for name, value in pairs(stats) do
        if not ignored_stats[name] and normalized_names[name] then
            local row = state.rows[name]
            if not row or not row.label.valid then
                draw_score(player, frame, stats, state)
                return
            end
            count = count + 1
            if row.value ~= value then
                row.label.caption = statistic_caption(value)
                row.value = value
            end
        end
    end
    if count ~= state.count then
        draw_score(player, frame, stats, state)
        return
    end

    local disconnected = not Server.get_current_time()
    if state.warning.visible ~= disconnected then
        state.warning.visible = disconnected
    end
end

local function refresh_statistics()
    for _, player in pairs(game.connected_players) do
        local frame = Gui.get_player_active_frame(player)
        if frame and frame.valid and frame.name == tab_name then
            update_score(player, frame)
        end
    end
end

local show_stats_token = Task.register(show_score)

Gui.add_tab_to_gui({ name = module_name, caption = tab_name, id = show_stats_token, admin = false })

Gui.on_click(
    module_name,
    function (event)
        local player = event.player
        Gui.reload_active_tab(player, nil, tab_name)
    end
)

Event.on_nth_tick(60, refresh_statistics)

return Public
