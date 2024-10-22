-- created by Gerkiz for ComfyFactorio

local Gui = require 'utils.gui'
local Task = require 'utils.task_token'
local StatData = require 'utils.datastore.statistics'
local format_number = require 'util'.format_number
local Server = require 'utils.server'

local Public = {}

local module_name = Gui.uid_name()

local ignored_stats = {
    ['name'] = true,
    ['tick'] = true
}

local normalized_names = StatData.normalized_names

local function show_score(data)
    local player = data.player
    local frame = data.frame
    frame.clear()

    local t = frame.add { type = 'table', column_count = 2 }

    local tooltip = 'Your statistics that are gathered throughout Comfy servers.'
    local secs = Server.get_current_time()
    if not secs then
        tooltip = 'Not currently connected to any backend. Statistics will reset.'
    end

    local label =
        t.add {
            type = 'label',
            caption = tooltip
        }

    label.style.font = 'heading-2'
    label.style.font_color = { r = 0.98, g = 0.66, b = 0.22 }
    label.style.minimal_width = 125
    label.style.horizontal_align = 'center'

    local line = frame.add { type = 'line' }
    line.style.top_margin = 8
    line.style.bottom_margin = 8

    local stat_data = StatData.get_data(player)

    local scroll_pane =
        frame.add(
            {
                type = 'scroll-pane',
                name = 'score_scroll_pane',
                direction = 'vertical',
                horizontal_scroll_policy = 'never',
                vertical_scroll_policy = 'auto'
            }
        )
    scroll_pane.style.maximal_height = 400
    local column_table = scroll_pane.add { type = 'table', column_count = 4 }

    for name, stat in pairs(stat_data) do
        if not ignored_stats[name] and normalized_names[name] then
            local c = stat
            if stat and type(stat) == 'number' then
                c = format_number(stat, true)
            end
            local lines = {
                { caption = normalized_names[name] and normalized_names[name].name or name, tooltip = normalized_names[name].tooltip or '' },
                { caption = c }
            }
            local default_color = { r = 0.9, g = 0.9, b = 0.9 }

            for _, column in ipairs(lines) do
                local l =
                    column_table.add {
                        type = 'label',
                        caption = column.caption,
                        tooltip = column.tooltip,
                        color = column.color or default_color
                    }
                l.style.font = 'default-semibold'
                l.style.minimal_width = 175
                l.style.maximal_width = 175
                l.style.horizontal_align = 'left'
            end
        end
    end
end

local show_stats_token = Task.register(show_score)

Gui.add_tab_to_gui({ name = module_name, caption = 'Statistics', id = show_stats_token, admin = false })

Gui.on_click(
    module_name,
    function (event)
        local player = event.player
        Gui.reload_active_tab(player)
    end
)

return Public
