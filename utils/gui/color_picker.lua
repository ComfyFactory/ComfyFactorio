-- created by Gerkiz
local Gui = require 'utils.gui'
local Style = require 'utils.gui_style'

local Public = {}

local selectors_name = Gui.uid_name()
local button_name = Gui.uid_name()
local channels =
{
    { key = 'r', label = 'R', style = 'red_slider' },
    { key = 'g', label = 'G', style = 'green_slider' },
    { key = 'b', label = 'B', style = 'blue_slider' },
    { key = 'a', label = 'A', style = 'slider', tooltip = { 'gui.player_settings_color_alpha' } }
}
for _, channel in ipairs(channels) do
    channel.slider_name = Gui.uid_name()
end

local function to_byte(value)
    return math.floor(value * 255 + 0.5)
end

local function format_color(color)
    return string.format('#%02X%02X%02X%02X', to_byte(color.r), to_byte(color.g), to_byte(color.b), to_byte(color.a or 1))
end

local function copy_color(color)
    return { r = color.r, g = color.g, b = color.b, a = color.a or 1 }
end

local function update_preview(state)
    for index, swatch in ipairs(state.swatches) do
        local color = state.colors[index]
        swatch.style.color = { r = color.r, g = color.g, b = color.b, a = 1 }
        swatch.tooltip = format_color(color)
    end
    if state.selected then
        for key, controls in pairs(state.channels) do
            local value = to_byte(state.colors[state.selected][key])
            if controls.slider.slider_value ~= value then
                controls.slider.slider_value = value
            end
            controls.number.caption = tostring(value)
        end
    end
end

function Public.add(parent, width, enabled, player_color, chat_color)
    local selectors = parent.add({ type = 'flow', name = selectors_name, direction = 'horizontal' })
    selectors.style.horizontal_spacing = Style.spacing.sm
    selectors.style.vertical_align = 'center'

    local state = { colors = { copy_color(player_color), copy_color(chat_color) }, swatches = {}, buttons = {}, channels = {} }
    for index, key in ipairs({ 'player', 'chat' }) do
        local group = Style.toolbar(selectors)
        group.style.horizontal_spacing = Style.spacing.xs
        local label = { 'gui.player_settings_color_' .. key }
        local swatch = group.add({ type = 'progressbar', value = 1 })
        swatch.style.width = 16
        swatch.style.bar_width = 14
        state.swatches[index] = swatch

        local button = Style.action_button(group, {
            name = button_name, sprite = 'utility/color_picker', tooltip = { 'gui.player_settings_color_pick' },
            tags = { color_index = index }, enabled = enabled
        })
        state.buttons[index] = button
        group.add({ type = 'label', caption = label })
    end

    local editor = parent.add({ type = 'table', column_count = 3, visible = false })
    editor.style.horizontal_spacing = Style.spacing.xs
    editor.style.vertical_spacing = Style.spacing.xs
    state.editor = editor
    for _, channel in ipairs(channels) do
        local label = editor.add({ type = 'label', caption = channel.label, tooltip = channel.tooltip })
        label.style.width = 16
        local slider = editor.add({
            type = 'slider', name = channel.slider_name, style = channel.style,
            minimum_value = 0, maximum_value = 255, value_step = 1, discrete_slider = true
        })
        slider.style.width = width - 16 - 40 - 2 * Style.spacing.xs
        local number = editor.add({ type = 'label' })
        number.style.width = 40
        number.style.horizontal_align = 'right'
        state.channels[channel.key] = { slider = slider, number = number }
    end

    Gui.set_data(selectors, state)
    Gui.set_data(editor, state)
    update_preview(state)
end

function Public.get_colors(parent)
    local state = Gui.get_data(parent[selectors_name])
    return state and state.colors
end

Gui.on_click(button_name, function (event)
    local button = event.element
    local state = Gui.get_data(button.parent.parent)
    if not state or not button.enabled then
        return
    end
    local index = button.tags.color_index
    if state.selected == index then
        state.selected = nil
    else
        state.selected = index
    end
    state.editor.visible = state.selected ~= nil
    for i, picker in ipairs(state.buttons) do
        picker.toggled = state.selected == i
    end
    update_preview(state)
end)

for _, channel in ipairs(channels) do
    local key = channel.key
    Gui.on_value_changed(channel.slider_name, function (event)
        local slider = event.element
        local state = Gui.get_data(slider.parent)
        if not state or not state.selected then
            return
        end
        state.colors[state.selected][key] = slider.slider_value / 255
        update_preview(state)
    end)
end

return Public
