local Gui = require 'utils.gui'
local Token = require 'utils.token'

local module_name = Gui.uid_name()

local Public = {}

local mod_name_width = 280
local version_width = 120

local function build_mod_list_gui(data)
    local frame = data.frame
    local total_height = (frame.style.minimal_height or 500) - 60

    frame.clear()

    local t = frame.add({ type = 'table', column_count = 2 })
    local label =
        t.add
        {
            type = 'label',
            caption = 'Current active mods'
        }

    label.style.font = 'heading-2'
    label.style.font_color = { r = 0.98, g = 0.66, b = 0.22 }
    label.style.horizontal_align = 'center'

    local line = frame.add({ type = 'line' })
    line.style.top_margin = 8
    line.style.bottom_margin = 8

    local scroll_pane = frame.add(
        {
            type = 'scroll-pane',
            name = 'mod_list_scroll_pane',
            direction = 'vertical',
            horizontal_scroll_policy = 'never',
            vertical_scroll_policy = 'auto'
        }
    )
    scroll_pane.style.maximal_height = total_height - 50
    scroll_pane.style.minimal_height = total_height - 50

    t = scroll_pane.add({ type = 'table', name = 'mod_list_table', column_count = 2 })

    local mod_label = t.add({ type = 'label', caption = 'Mod' })
    mod_label.style.font_color = { r = 0.98, g = 0.66, b = 0.22 }
    mod_label.style.font = 'heading-2'
    mod_label.style.top_padding = 6
    mod_label.style.minimal_height = 40
    mod_label.style.minimal_width = mod_name_width
    mod_label.style.maximal_width = mod_name_width
    mod_label.style.horizontal_align = 'left'

    local version_label = t.add({ type = 'label', caption = 'Version' })
    version_label.style.font_color = { r = 0.98, g = 0.66, b = 0.22 }
    version_label.style.font = 'heading-2'
    version_label.style.top_padding = 6
    version_label.style.minimal_height = 40
    version_label.style.minimal_width = version_width
    version_label.style.maximal_width = version_width
    version_label.style.horizontal_align = 'center'

    local names = {}
    for name in pairs(script.active_mods) do
        names[#names + 1] = name
    end
    table.sort(names)

    local row_color = { r = 0.90, g = 0.90, b = 0.90 }
    for _, name in ipairs(names) do
        local version = script.active_mods[name]
        local l = t.add({ type = 'label', caption = name })
        l.style.top_padding = 8
        l.style.bottom_padding = 8
        l.style.minimal_width = mod_name_width
        l.style.maximal_width = mod_name_width
        l.style.font = 'default-semibold'
        l.style.font_color = row_color
        l.style.horizontal_align = 'left'
        l = t.add({ type = 'label', caption = version })
        l.style.top_padding = 8
        l.style.bottom_padding = 8
        l.style.minimal_width = version_width
        l.style.maximal_width = version_width
        l.style.font = 'default-semibold'
        l.style.font_color = row_color
        l.style.horizontal_align = 'center'
    end
end

local build_mod_list_gui_token = Token.register(build_mod_list_gui)

Gui.add_tab_to_gui({ name = module_name, caption = 'Mods', id = build_mod_list_gui_token, admin = false })

Gui.on_click(
    module_name,
    function (event)
        local player = event.player
        Gui.reload_active_tab(player, nil, 'Mods')
    end
)

return Public
