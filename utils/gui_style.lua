-- created by Gerkiz
local Public = {}

Public.spacing = { xs = 3, sm = 6, md = 8 }
Public.dimensions = { button_height = 24, row_height = 28 }
Public.colors =
{
    heading = { 0.98, 0.83, 0.62 },
    text = { 0.92, 0.91, 0.89 },
    muted = { 0.74, 0.73, 0.71 },
    danger = { 0.46, 0.12, 0.10 }
}

local window_padding = 8
local tab_inset = 12
local tab_padding = 6
local scrollbar_gutter = 12
local window_chrome_height = 48
local tab_chrome_height = 68
local view_sizes =
{
    compact = { width = 660, height = 380, width_fraction = 0.68, height_fraction = 0.54 },
    full = { width = 860, height = 510, width_fraction = 0.75, height_fraction = 0.60 }
}

function Public.limits(player, view)
    local resolution, scale = player.display_resolution, player.display_scale
    local size = view_sizes[view] or view_sizes.compact
    local width = math.floor(resolution.width / scale)
    local height = math.floor(resolution.height / scale)
    return
    {
        width = math.min(size.width, width, math.max(305, math.floor(width * size.width_fraction))),
        height = math.min(size.height, height, math.max(170, math.floor(height * size.height_fraction)))
    }
end

function Public.content_width(player, frame)
    local tags = frame and frame.tags
    return math.max(1, Public.limits(player, tags and tags.comfy_view).width - 2 * (window_padding + tab_inset + tab_padding) - scrollbar_gutter)
end

function Public.column_widths(width, proportions, spacing)
    local available = math.max(0, width - (spacing or 0) * (#proportions - 1) - #proportions)
    local total = 0
    for _, portion in ipairs(proportions) do
        total = total + portion
    end

    local widths = {}
    local used, cumulative = 0, 0
    for index, portion in ipairs(proportions) do
        cumulative = cumulative + portion
        local edge = math.floor(available * cumulative / total)
        widths[index] = 1 + edge - used
        used = edge
    end
    return widths
end

function Public.window(frame, inside, player)
    local limits = Public.limits(player, frame.tags.comfy_view)
    frame.style.width = limits.width
    frame.style.maximal_height = limits.height
    frame.style.padding = window_padding
    frame.style.horizontally_stretchable = false
    frame.style.vertically_stretchable = false

    inside.style.width = limits.width - 2 * window_padding
    inside.style.maximal_height = limits.height - window_chrome_height
    inside.style.padding = 0
    inside.style.top_margin = Public.spacing.xs
    inside.style.horizontally_stretchable = false
    inside.style.vertically_stretchable = false
    inside.tabbed_pane.style.minimal_width = limits.width - 2 * window_padding
    return limits
end

function Public.action_button(parent, spec)
    spec.type = 'sprite-button'
    spec.style = 'frame_action_button'
    spec.mouse_button_filter = { 'left' }
    local button = parent.add(spec)
    button.style.width = Public.dimensions.button_height
    button.style.height = Public.dimensions.button_height
    return button
end

function Public.apply_tab(tab, limits)
    local style = tab.style
    style.padding = tab_padding
    style.width = limits.width - 2 * (window_padding + tab_inset)
    style.maximal_height = limits.height - window_chrome_height - tab_chrome_height
    style.horizontally_stretchable = true
    style.vertically_stretchable = false
end

function Public.heading(parent, caption)
    local heading = parent.add({ type = 'label', caption = caption })
    heading.style.font = 'default-bold'
    heading.style.font_color = Public.colors.heading
    return heading
end

function Public.text(parent, caption, width, color)
    local label = parent.add({ type = 'label', caption = caption })
    label.style.font_color = color or Public.colors.text
    label.style.single_line = false
    label.style.maximal_width = width
    return label
end

function Public.surface(parent, name, width)
    local surface = parent.add({ type = 'frame', name = name, direction = 'vertical', style = 'inside_shallow_frame_with_padding' })
    surface.style.padding = Public.spacing.md
    surface.style.horizontally_stretchable = true
    if width then
        surface.style.minimal_width = width
    end
    return surface
end

function Public.toolbar(parent)
    local toolbar = parent.add({ type = 'flow', direction = 'horizontal' })
    toolbar.style.horizontal_spacing = Public.spacing.sm
    toolbar.style.vertical_align = 'center'
    return toolbar
end

function Public.metric(parent, caption, value, tooltip, width)
    local metric = Public.toolbar(parent)
    metric.style.right_padding = Public.spacing.md
    local label = metric.add({ type = 'label', caption = caption, tooltip = tooltip })
    label.style.font_color = Public.colors.muted
    if width then
        metric.style.width = width
        label.style.horizontally_stretchable = true
    end
    local number = metric.add({ type = 'label', caption = value, tooltip = tooltip })
    number.style.font = 'default-semibold'
    number.style.font_color = Public.colors.text
    return metric, number
end

function Public.button(button, variant)
    if variant == 'danger' then
        button.style.font_color = Public.colors.danger
    end
    local style = button.style
    style.height = Public.dimensions.button_height
    style.minimal_width = Public.dimensions.button_height
    style.left_padding = Public.spacing.md
    style.right_padding = Public.spacing.md
    return button
end

function Public.table_heading(label)
    label.style.font = 'default-semibold'
    label.style.font_color = Public.colors.heading
    return label
end

function Public.settings_table(parent, name, width)
    local padding = Public.spacing.md
    local rows = parent.add({
        type = 'table', name = name, column_count = 1, style = 'bordered_table',
        tags = { row_width = width - 2 * padding - 8 }
    })
    rows.style.left_cell_padding = padding
    rows.style.right_cell_padding = padding
    rows.style.top_cell_padding = Public.spacing.xs
    rows.style.bottom_cell_padding = Public.spacing.xs
    rows.style.vertical_spacing = 0
    return rows
end

return Public
