local Gui = require 'utils.gui'
local Style = require 'utils.gui_style'
local Token = require 'utils.token'

local module_name = Gui.uid_name()

local Public = {}

local version_width = 88
local cell_padding = Style.spacing.md
local table_border_width = 8

local function add_columns(list, name, version, name_width)
    local name_label = list.add({ type = 'label', caption = name })
    name_label.style.width = name_width
    name_label.style.single_line = true

    local version_label = list.add({ type = 'label', caption = version })
    version_label.style.width = version_width
    version_label.style.single_line = true
    version_label.style.horizontal_align = 'right'
    return name_label, version_label
end

local function build_mod_list_gui(data)
    local frame = data.frame
    frame.clear()

    local names = {}
    for name in pairs(script.active_mods) do
        names[#names + 1] = name
    end
    table.sort(names)

    local heading = Style.heading(frame, { 'gui.comfy_active_mods', #names })
    heading.style.bottom_margin = Style.spacing.xs

    local name_width = math.max(80, Style.content_width(data.player, frame) - version_width - 4 * cell_padding - table_border_width)
    local list = frame.add({ type = 'table', name = 'mod_list_table', column_count = 2, style = 'bordered_table' })
    list.style.horizontal_spacing = 0
    list.style.vertical_spacing = 0
    list.style.top_cell_padding = 1
    list.style.bottom_cell_padding = 1
    list.style.left_cell_padding = cell_padding
    list.style.right_cell_padding = cell_padding

    local name_header, version_header = add_columns(list, { 'gui-manage-mods.name-column-header' }, { 'gui-manage-mods.version-column-header' }, name_width)
    Style.table_heading(name_header)
    Style.table_heading(version_header)

    for _, name in ipairs(names) do
        local version = script.active_mods[name]
        local name_label, version_label = add_columns(list, name, version, name_width)
        name_label.tooltip = name
        name_label.style.font_color = Style.colors.text
        version_label.tooltip = version
        version_label.style.font_color = Style.colors.muted
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
