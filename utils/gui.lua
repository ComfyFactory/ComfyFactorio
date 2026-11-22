local Task = require 'utils.task_token'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Server = require 'utils.server'
local SpamProtection = require 'utils.spam_protection'
local Color = require 'utils.color_presets'
local Style = require 'utils.gui_style'
local format_number = require('util').format_number

local insert = table.insert
local tostring = tostring
local next = next
local gui_prefix = 'comfy_'

local GuiMetaMethods = {}

local Public =
{
    uid = 1000,
    events = {},
    defines = {},
    file_paths = {},
    debug_info = {},
    execute =
    {
        __call = function (self, parent, ...)
            local frame = self.render_frame(self.name, parent, ...)
            if self.render_style then
                if frame and frame.valid and frame.style then
                    self.render_style(frame.style, frame, ...)
                end
            end
            return frame
        end,
        __index = GuiMetaMethods
    }
}

local view_modes = { 'minimal', 'compact', 'full' }

local sections =
{
    { name = 'stats', tabs = { 'Players', 'Groups', 'Scoreboard', 'Statistics', 'Seasons', 'Highscore', 'Map Scores', 'MutagenLog' } },
    { name = 'server', tabs = { 'Map Info', 'Mods', 'Changelog' } },
    { name = 'controls', tabs = { 'Config', 'Admin', 'Spawn Controls', 'ChronoTrain' } }
}

-- local to this file
local local_settings =
{
    toggle_button = true
}
local main_gui_tabs = {}
local tab_captions = {}
local screen_elements = {}
local remove_data_recursively
local concat = table.concat
local names = {}
-- global
local data = {}
local removed_objects = {}
local settings =
{
    mod_gui_top_frame = true,
    disabled_tabs = {},
    disable_clear_invalid_data = true,
    menu_state = {}
}

Public.token =
    Global.register(
        { data = data, removed_objects = removed_objects, settings = settings },
        function (tbl)
            data = tbl.data
            removed_objects = tbl.removed_objects
            settings = tbl.settings
        end
    )

Public.names = names

local function menu_state(player)
    settings.menu_state = settings.menu_state or {}
    local state = settings.menu_state[player.index]
    if not state then
        state = { view = 'full' }
        settings.menu_state[player.index] = state
    end
    return state
end

Public.beam = 'file/utils/files/beam.png'
Public.beam_1 = 'file/utils/files/beam_1.png'
Public.beam_2 = 'file/utils/files/beam_2.png'
Public.settings_white_icon = 'file/utils/files/settings-white.png'
Public.settings_black_icon = 'file/utils/files/settings-black.png'
Public.pin_white_icon = 'file/utils/files/pin-white.png'
Public.pin_black_icon = 'file/utils/files/pin-black.png'
Public.infinite_icon = 'file/utils/files/infinity.png'
Public.arrow_up_icon = 'file/utils/files/arrow-up.png'
Public.arrow_down_icon = 'file/utils/files/arrow-down.png'
Public.tidal_icon = 'file/utils/files/tidal.png'
Public.spew_icon = 'file/utils/files/spew.png'
Public.berserk_icon = 'file/utils/files/berserk.png'
Public.warp_icon = 'file/utils/files/warp.png'
Public.x_icon = 'file/utils/files/x.png'
Public.info_icon = 'file/utils/files/info.png'
Public.mod_gui_button_enabled = false

function Public.sprite_style(size, padding, style)
    style = style or {}
    style.padding = padding or -2
    style.height = size
    style.width = size
    return style
end

Public.Styles =
{
    [20] = Public.sprite_style(20, 0),
    [22] = Public.sprite_style(20, nil, { right_margin = -3 }),
    [23] = Public.sprite_style(23, nil, { right_margin = -3 }),
    [32] = { height = 32, width = 32, left_margin = 1 },
    [40] = { height = 40, width = 40, left_margin = 1 },
    ['button'] =
    {
        font = 'default-semibold',
        height = 26,
        minimal_width = 26,
        top_padding = 0,
        bottom_padding = 0,
        left_padding = 2,
        right_padding = 2
    }
}

function Public.uid_name(prefix)
    if game then
        return error('This function is not allowed to be called in this context.', 2)
    end

    local info = debug.getinfo(2, 'Sl')
    local filepath = info.source:match('^@__level__/(.+)$'):sub(1, -5)
    local line = info.currentline

    local token = tostring(Task.uid(prefix))

    local name = concat { token, ' - ', filepath, ':line:', line }
    names[token] = name

    return token
end

local main_frame_name = Public.uid_name()
local main_toggle_button_name = Public.uid_name()
local main_button_name = Public.uid_name()
local close_button_name = Public.uid_name()
local dock_button_name = Public.uid_name()
local view_selector_name = Public.uid_name()
local section_selector_name = Public.uid_name()
local status_frame_name = 'comfy_fish_status'
local status_expand_button_name = Public.uid_name()
local status_fold_button_name = Public.uid_name()
local status_map_info_button_name = Public.uid_name()

if not Public.mod_gui_button_enabled then
    Public.button_style = nil
end

Public.top_main_gui_button = main_button_name
Public.main_frame_name = main_frame_name
Public.main_toggle_button_name = main_toggle_button_name
Public.frame_style = 'non_draggable_frame'
Public.button_style = 'mod_gui_button'
Public.top_flow_button_enabled_style = 'menu_button_continue'
Public.top_flow_button_disabled_style = Public.button_style

function GuiMetaMethods:add_style(object)
    if not object then
        return self
    end

    if type(object) == 'table' then
        if Public.debug_info[self.name] then
            Public.debug_info[self.name].render_style = object
            self.render_style = function (style)
                for key, value in pairs(object) do
                    style[key] = value
                end
            end
        end
    else
        if Public.debug_info[self.name] then
            Public.debug_info[self.name].render_style = 'Function'
            self.render_style = object
        end
    end

    return self
end

function GuiMetaMethods:raise_custom_event(event)
    local element = event.element
    if not element or not element.valid then
        return self
    end

    -- Get the event handler for this element
    local handler = self[event.name]
    if not handler then
        return self
    end

    -- Get the player for this event
    local player_index = event.player_index or element.player_index
    local player = game.get_player(player_index)
    if not player or not player.valid then
        return self
    end
    event.player = player

    handler(player, element, event)

    return self
end

function Public.new_frame(object)
    local element = setmetatable({}, Public.execute)

    local uid = Public.uid + 1
    Public.uid = uid
    local name = tostring(uid)
    element.name = name
    Public.debug_info[name] = { render_frame = 'None', style = 'None', events = {} }

    if type(object) == 'table' then
        Public.debug_info[name].render_frame = object
        object.name = name
        element.render_frame = function (_, parent)
            return parent.add(object)
        end
    else
        Public.debug_info[name].render_frame = 'Function'
        element.render_frame = object
    end

    local file_path = debug.getinfo(2, 'S').source:match('^@__level__/(.+)$'):sub(1, -5)
    Public.file_paths[name] = file_path
    Public.defines[name] = element

    return element
end

--- Verifies if a frame is valid and destroys it.
---@param align userdata
---@param frame userdata
local function validate_frame_and_destroy(align, frame)
    local get_frame = align[frame]
    if get_frame and get_frame.valid then
        remove_data_recursively(frame)
        get_frame.destroy()
    end
end

local function get_button_flow(player)
    local gui = player.gui.top

    if gui.mod_gui_button_flow then
        return gui.mod_gui_button_flow
    end

    local frame = gui.mod_gui_top_frame or gui.add { type = 'frame', name = 'mod_gui_top_frame', direction = 'horizontal', style = 'slot_window_frame' }
    return frame.mod_gui_inner_frame or frame.add { type = 'frame', name = 'mod_gui_inner_frame', style = 'mod_gui_inside_deep_frame' }
end

local function hide_button_flow(player)
    local gui = player.gui.top
    local button_flow = gui.mod_gui_button_flow
    if not button_flow then
        return
    end
    button_flow.visible = false
end

local function show_button_flow(player)
    local gui = player.gui.top
    local button_flow = gui.mod_gui_button_flow
    if not button_flow then
        return
    end
    button_flow.visible = true
end

-- Returns the sections and tabs for the GUI.
function Public.sections(visible_tabs)
    local groups, known = {}, {}
    for _, section in ipairs(sections) do
        local tabs = {}
        for _, caption in ipairs(section.tabs) do
            known[caption] = true
            if visible_tabs[caption] then
                tabs[#tabs + 1] = caption
            end
        end
        if #tabs > 0 then
            groups[#groups + 1] = { name = section.name, tabs = tabs }
        end
    end

    local extra = {}
    for caption in pairs(visible_tabs) do
        if not known[caption] then
            extra[#extra + 1] = caption
        end
    end
    if #extra > 0 then
        table.sort(extra)
        groups[#groups + 1] = { name = 'scenario', tabs = extra }
    end
    return groups
end

-- Associates data with the LuaGuiElement. If data is nil then removes the data
function Public.set_data(element, value)
    if not element or not element.valid then
        return
    end

    local player_index = element.player_index
    local values = data[player_index]

    if value == nil then
        if not values then
            return
        end

        values[element.index] = nil

        if next(values) == nil then
            data[player_index] = nil
        end
    else
        if not values then
            values = {}
            data[player_index] = values
        end

        local registration_number = script.register_on_object_destroyed(element)
        removed_objects[registration_number] = player_index

        values[element.index] = { value = value, name = element.name, registration_number = registration_number }
    end
end

local set_data = Public.set_data

-- Associates data with the LuaGuiElement. If data is nil then removes the data
function Public.set_data_parent(parent, element, value)
    local player_index = parent.player_index
    local values = data[player_index]

    if value == nil then
        if not values then
            return
        end

        values[parent.index] = nil

        if next(values) == nil then
            data[player_index] = nil
        end
    else
        if not values then
            values = {}
            data[player_index] = values
        end

        if not values[parent.index] then
            values[parent.index] = {}
        end

        values[parent.index][element.index] = { value = value, name = element.name }
    end
end

-- Gets the Associated data with this LuaGuiElement if any.
function Public.get_data(element)
    if not element then
        return
    end

    if not element.index then
        return
    end

    local player_index = element.player_index

    local values = data[player_index]
    local entry = values and values[element.index]
    return entry and entry.value
end

-- Gets the Associated data with this LuaGuiElement if any.
function Public.get_data_parent(parent, element)
    if not parent then
        return
    end
    if not element then
        return
    end

    local player_index = parent.player_index

    local values = data[player_index]
    if not values then
        return nil
    end

    values = values[parent.index]
    if not values then
        return nil
    end

    return values[element.index].value
end

-- Adds a gui that is alike the factorio native gui.
function Public.add_main_frame_with_toolbar(player, align, set_frame_name, set_settings_button_name, close_main_frame_name, name, info, inside_table_count)
    if not align then
        return
    end
    local main_frame
    if align == 'left' then
        validate_frame_and_destroy(player.gui.left, set_frame_name)
        main_frame = player.gui.left.add { type = 'frame', name = set_frame_name, direction = 'vertical' }
    elseif align == 'center' then
        validate_frame_and_destroy(player.gui.center, set_frame_name)
        main_frame = player.gui.center.add { type = 'frame', name = set_frame_name, direction = 'vertical' }
    elseif align == 'screen' then
        validate_frame_and_destroy(player.gui.screen, set_frame_name)
        main_frame = player.gui.screen.add { type = 'frame', name = set_frame_name, direction = 'vertical' }
    end

    local titlebar = main_frame.add { type = 'flow', name = 'titlebar', direction = 'horizontal', style = 'horizontal_flow' }
    titlebar.style.horizontal_spacing = Style.spacing.sm
    titlebar.style.vertical_align = 'center'

    if align == 'screen' then
        titlebar.drag_target = main_frame
    end

    titlebar.add
    {
        type = 'label',
        name = 'main_label',
        style = 'frame_title',
        caption = name,
        ignored_by_interaction = true
    }
    local widget = titlebar.add { type = 'empty-widget', style = 'draggable_space', ignored_by_interaction = true }
    widget.style.left_margin = 4
    widget.style.right_margin = 4
    widget.style.height = 20
    widget.style.horizontally_stretchable = true

    if set_settings_button_name then
        local alternate = info and Public.info_icon or Public.settings_black_icon
        Style.action_button(titlebar, {
            name = set_settings_button_name,
            sprite = info and Public.info_icon or Public.settings_white_icon,
            hovered_sprite = alternate,
            clicked_sprite = alternate,
            tooltip = info and 'Info' or 'Settings',
            tags = { action = 'open_settings_gui' }
        })
    end

    local close_button
    if close_main_frame_name then
        close_button = Style.action_button(titlebar, {
            name = close_main_frame_name,
            sprite = 'utility/close',
            hovered_sprite = 'utility/close_fat',
            clicked_sprite = 'utility/close_fat',
            tooltip = 'Close',
            tags = { action = 'close_main_frame_gui' }
        })
    end

    local inside_frame =
        main_frame.add
        {
            type = 'table',
            column_count = 1 or inside_table_count,
            name = 'inside_frame'
        }

    return main_frame, inside_frame, close_button
end

function Public.add_main_frame(parent, parent_frame_name, frame_name, frame_tooltip, max_height, min_width)
    local main_frame = parent[parent_frame_name]
    if main_frame then
        return main_frame
    end
    main_frame =
        parent.add(
            {
                type = 'frame',
                name = parent_frame_name,
                caption = frame_name,
                tooltip = frame_tooltip,
            }
        )
    main_frame.style.padding = 9
    main_frame.style.use_header_filler = true
    main_frame.style.maximal_height = max_height or 500
    main_frame.style.maximal_width = 500
    main_frame.style.minimal_width = min_width or 250

    local frame =
        main_frame.add
        {
            type = 'frame',
            direction = 'vertical',
            style = 'inside_shallow_frame_packed'
        }
    frame.style.padding = 4
    frame.style.horizontally_stretchable = true
    frame.style.maximal_height = max_height or 500
    frame.style.maximal_width = 500
    frame.style.minimal_width = min_width or 250

    return frame, main_frame
end

-- Removes data associated with LuaGuiElement and its children recursively.
function Public.remove_data_recursively(element)
    set_data(element, nil)

    local children = element.children

    if not children then
        return
    end

    for _, child in next, children do
        if child.valid then
            remove_data_recursively(child)
        end
    end
end

remove_data_recursively = Public.remove_data_recursively

local remove_children_data
function Public.remove_children_data(element)
    local children = element.children

    if not children then
        return
    end

    for _, child in next, children do
        if child.valid then
            set_data(child, nil)
            remove_children_data(child)
        end
    end
end

remove_children_data = Public.remove_children_data

function Public.destroy(element)
    if not element then
        return
    end
    remove_data_recursively(element)
    element.destroy()
end

function Public.clear(element)
    remove_children_data(element)
    element.clear()
end

local function handler_factory(event_id)
    local handlers

    local function on_event(event)
        local element = event.element
        if not element or not element.valid then
            return
        end

        local handler = handlers[element.name]
        if not handler then
            return
        end

        local player = game.get_player(event.player_index)
        if not (player and player.valid) then
            return
        end

        event.player = player

        if type(handler) == 'function' then
            handler(event)
        else
            for i = 1, #handler do
                local callback = handler[i]
                if callback then
                    callback(event)
                end
            end
        end
    end

    return function (element_name, handler)
        if not element_name then
            return error('Element name is required when passing it onto the handler_factory.', 2)
        end
        if not handler or not type(handler) == 'function' then
            return error('Handler is required when passing it onto the handler_factory and needs to be of type function.', 2)
        end

        if not handlers then
            handlers = {}
            Event.add(event_id, on_event)
        end

        if handlers[element_name] then
            local old = handlers[element_name]
            handlers[element_name] = {}
            insert(handlers[element_name], old)
            insert(handlers[element_name], handler)
        else
            handlers[element_name] = handler
        end
    end
end

local function event_handler_factory(event_name)
    Event.add(
        event_name,
        function (event)
            local element = event.element
            if not element or not element.valid then
                return
            end
            local element_define = Public.defines[element.name]
            if not element_define then
                return
            end

            element_define:raise_custom_event(event)
        end
    )

    return function (self, handler)
        insert(Public.debug_info[self.name].events, debug.getinfo(1, 'n').name)
        self[event_name] = handler
        return self
    end
end


--luacheck: ignore custom_raise
---@diagnostic disable-next-line: unused-function, unused-local
local function custom_raise(handlers, element, player)
    local handler = handlers[element.name]
    if not handler then
        return
    end

    handler({ element = element, player = player })
end

-- Disabled the handler so it does not clean then data table of invalid data.
function Public.set_disable_clear_invalid_data(value)
    settings.disable_clear_invalid_data = value or false
end

-- Gets state if the cleaner handler is active or false
function Public.get_disable_clear_invalid_data()
    return settings.disable_clear_invalid_data
end

-- Disable a gui.
---@param frame_name string
---@param state boolean?
function Public.set_disabled_tab(frame_name, state)
    if not frame_name then
        return
    end

    settings.disabled_tabs[tab_captions[frame_name] or frame_name] = state or false
end

-- Fetches if a gui is disabled.
---@param frame_name string
function Public.get_disabled_tab(frame_name)
    if not frame_name then
        return
    end

    return settings.disabled_tabs[tab_captions[frame_name] or frame_name]
end

-- Returns the menu's content container.
function Public.get_main_frame(player)
    local frame = Public.get_parent_frame(player)
    return frame and frame.inside_frame or false
end

-- Returns the floating or docked menu, including an older docked instance.
function Public.get_parent_frame(player)
    if not player then
        return false
    end

    local frame = player.gui.screen[main_frame_name] or player.gui.left[main_frame_name]

    if frame and frame.valid then
        return frame
    end
    return false
end

--- This adds the given gui to the top gui.
---@param player LuaPlayer
---@param frame userdata|table
function Public.add_mod_button(player, frame)
    if get_button_flow(player)[frame.name] and get_button_flow(player)[frame.name].valid then
        return get_button_flow(player)[frame.name]
    end

    return get_button_flow(player).add(frame)
end

---@param state boolean
--- If we should use the new mod gui or not
function Public.set_mod_gui_top_frame(state)
    settings.mod_gui_top_frame = state or false
end

--- Get mod_gui_top_frame
function Public.get_mod_gui_top_frame()
    return settings.mod_gui_top_frame
end

---@param state boolean
--- If we should show the toggle button or not
function Public.set_toggle_button(state)
    if _LIFECYCLE == 8 then
        error('Calling Gui.set_toggle_button after on_init() or on_load() has run is a desync risk.', 2)
    end
    local_settings.toggle_button = state or false
end

--- Get toggle_button state
function Public.get_toggle_button()
    if _LIFECYCLE == 8 then
        error('Calling Gui.get_toggle_button after on_init() or on_load() has run is a desync risk.', 2)
    end
    return local_settings.toggle_button
end

--- This adds the given gui to the main gui.
---@param tbl table
function Public.add_tab_to_gui(tbl)
    if _LIFECYCLE == 8 then
        error('Calling Gui.add_tab_to_gui after on_init() or on_load() has run is a desync risk.', 2)
    end
    if not tbl then
        return
    end

    if not tbl.name then
        return
    end

    if not tbl.caption then
        return
    end

    if not tbl.id then
        return
    end

    local admin = tbl.admin or false
    local only_server_sided = tbl.only_server_sided or false

    if not main_gui_tabs[tbl.caption] then
        main_gui_tabs[tbl.caption] = { id = tbl.id, name = tbl.name, admin = admin, only_server_sided = only_server_sided, localised_caption = tbl.localised_caption }
        tab_captions[tbl.name] = tbl.caption
    else
        error('Given name: ' .. tbl.caption .. ' already exists in table.')
    end
end

function Public.screen_to_bypass(elem)
    screen_elements[elem] = true
    return screen_elements
end

--- Fetches the main gui tabs. You are forbidden to write as this is local.
---@param key string
function Public.get(key)
    if key then
        return main_gui_tabs[key]
    else
        return main_gui_tabs
    end
end

local function get_status_frame(player)
    return player.gui.left[status_frame_name]
end

local function hide_status(player)
    local frame = get_status_frame(player)
    if frame then
        frame.destroy()
    end
end

function Public.clear_main_frame(player)
    if not player then
        return
    end
    local frame = Public.get_parent_frame(player)
    if frame then
        remove_data_recursively(frame)
        frame.destroy()
    end
    hide_status(player)
end

function Public.clear_all_center_frames(player)
    for _, child in pairs(player.gui.center.children) do
        remove_data_recursively(child)
        if child.name:find(gui_prefix) then
            child.destroy()
        end
    end
end

function Public.clear_all_screen_frames(player)
    for _, child in pairs(player.gui.screen.children) do
        if not screen_elements[child.name] and child.name:find(gui_prefix) then
            remove_data_recursively(child)
            child.destroy()
        end
    end
end

function Public.clear_all_left_frames(player)
    for _, child in pairs(player.gui.left.children) do
        if child.name ~= status_frame_name and child.name:find(gui_prefix) then
            remove_data_recursively(child)
            child.destroy()
        end
    end
end

function Public.clear_all_active_frames(player)
    Event.raise(ServerCommands.events.on_gui_closed_main_frame, { player_index = player.index })
    for _, child in pairs(player.gui.left.children) do
        if child.name ~= status_frame_name and child.name:find(gui_prefix) then
            remove_data_recursively(child)
            child.destroy()
        end
    end
    for _, child in pairs(player.gui.screen.children) do
        if not screen_elements[child.name] and child.name:find(gui_prefix) then
            remove_data_recursively(child)
            child.destroy()
        end
    end
    for _, child in pairs(player.gui.center.children) do
        if child.name:find(gui_prefix) then
            remove_data_recursively(child)
            child.destroy()
        end
    end
end

local function get_tab_body(content)
    if content.type == 'frame' then
        local body = content.children[1]
        if body and body.type == 'scroll-pane' and body.name == content.name then
            return body
        end
    end
    return content
end

function Public.get_player_active_frame(player)
    local panel = Public.get_content(player)
    local active = panel and panel.tabs[panel.selected_tab_index or 1]
    return active and get_tab_body(active.content) or false
end

local function get_player_active_tab(player)
    local panel = Public.get_content(player)
    local active = panel and panel.tabs[panel.selected_tab_index or 1]
    if active then
        return active.tab, get_tab_body(active.content)
    end
end

local function tab_is_available(player, state, caption, tab, server_data)
    local disabled = state.disabled_tabs and state.disabled_tabs[caption]
    if disabled == nil then
        disabled = Public.get_disabled_tab(caption)
    end
    return tab and not disabled and (not tab.only_server_sided or server_data)
        and (not tab.admin or (player.admin and (not server_data or Server.get_admins_data()[player.name])))
end

function Public.reload_active_tab(player, forced, tab_name)
    local is_spamming = SpamProtection.is_spamming(player, nil, 'Reload active tab')
    if is_spamming and not forced then
        return
    end

    local body = Public.get_player_active_frame(player)
    if not body or (tab_name and body.name ~= tab_name) then
        return
    end
    local caption = body.name
    local tab = main_gui_tabs[caption]
    if not tab_is_available(player, menu_state(player), caption, tab, Server.get_current_time()) then
        return
    end
    local id = tab.id
    if not id then
        return
    end
    local callback = Task.get(id)

    local d =
    {
        player = player,
        frame = body
    }

    return callback(d)
end

local function resize_top_buttons(player)
    if player.gui.top.mod_gui_top_frame and player.gui.top.mod_gui_top_frame.valid and player.gui.top.mod_gui_top_frame.mod_gui_inner_frame and player.gui.top.mod_gui_top_frame.mod_gui_inner_frame.valid then
        for _, frame in pairs(player.gui.top.mod_gui_top_frame.mod_gui_inner_frame.children) do
            if frame and frame.valid then
                frame.style.minimal_height = 36
                frame.style.maximal_height = 36
            end
        end
    end
end

local function get_main_button(player)
    local top = player.gui.top
    local flow = top.mod_gui_button_flow or (top.mod_gui_top_frame and top.mod_gui_top_frame.mod_gui_inner_frame)
    return (flow and flow[main_button_name]) or top[main_button_name]
end

local function main_button_tooltip(player)
    local state = settings.menu_state and settings.menu_state[player.index]
    return { state and state.map_info and 'gui.comfy_menu_map_info' or 'gui.comfy_menu' }
end

local function add_status_frame(player, collapsed)
    local frame = player.gui.left.add({
        type = 'frame', name = status_frame_name, direction = 'vertical', style = 'non_draggable_frame'
    })
    frame.style.padding = Style.spacing.xs

    local toolbar = Style.toolbar(frame)
    toolbar.name = 'toolbar'
    local online = toolbar.add({ type = 'label', name = 'online', tooltip = { 'gui.comfy_online_tooltip' } })
    Style.table_heading(online)
    Style.button(toolbar.add({ type = 'button', name = status_expand_button_name, caption = { 'gui.comfy_view_compact' },
        tooltip = { 'gui.comfy_open_compact' } }))
    Style.button(toolbar.add({ type = 'button', name = status_fold_button_name, caption = collapsed and '+' or '−',
        tooltip = { collapsed and 'gui.comfy_show_status' or 'gui.comfy_hide_status' } }))

    local details = Style.toolbar(frame)
    details.name = 'details'
    details.style.left_padding = Style.spacing.xs
    details.visible = not collapsed
    details.add({ type = 'label', name = 'service', tooltip = { 'gui.comfy_server_tooltip' } })
    local rockets = details.add({ type = 'label', name = 'rockets', tooltip = { 'gui.comfy_rockets_tooltip' } })
    rockets.style.font_color = Style.colors.muted
    Style.button(frame.add({ type = 'button', name = status_map_info_button_name, caption = { 'gui.comfy_map_info' } }))
    return frame
end

local function update_status(player, online, server_data)
    local frame = get_status_frame(player)
    if not frame then
        return
    end
    if not frame[status_map_info_button_name] then
        local collapsed = not frame.details.visible
        frame.destroy()
        frame = add_status_frame(player, collapsed)
    end

    frame.toolbar.online.caption = { 'gui.comfy_online', online }
    frame.details.service.caption = { server_data and 'gui.comfy_server_hosted' or 'gui.comfy_server_local' }
    frame.details.service.style.font_color = server_data and Style.colors.heading or Style.colors.muted
    frame.details.rockets.caption = { 'gui.comfy_rockets', format_number(player.force.rockets_launched, true) }
    frame[status_map_info_button_name].visible = menu_state(player).map_info == true and frame.details.visible
end

function Public.note_map_info(player)
    menu_state(player).map_info = true
    local button = get_main_button(player)
    if button then
        button.tooltip = main_button_tooltip(player)
    end
    update_status(player, #game.connected_players, Server.get_current_time())
end

local function top_button(player)
    if settings.mod_gui_top_frame then
        local button = Public.add_mod_button(player, { type = 'sprite-button', name = main_button_name, sprite = 'item/raw-fish', style = Public.button_style })
        if button then
            button.tooltip = main_button_tooltip(player)
            button.style.minimal_height = 36
            button.style.maximal_height = 36
            button.style.minimal_width = 40
            button.style.padding = -2
        end
    else
        if player.gui.top[main_button_name] then
            player.gui.top[main_button_name].tooltip = main_button_tooltip(player)
            return
        end
        local button =
            player.gui.top.add(
                {
                    type = 'sprite-button',
                    name = main_button_name,
                    sprite = 'item/raw-fish',
                    tooltip = main_button_tooltip(player),
                    style = Public.button_style
                }
            )
        button.style.minimal_height = 38
        button.style.maximal_height = 38
        button.style.minimal_width = 40
        button.style.padding = -2
    end
end

local function top_toggle_button(player)
    if not player or not player.valid then
        return
    end

    if Public.get_mod_gui_top_frame() then
        local b =
            Public.add_mod_button(
                player,
                {
                    type = 'sprite-button',
                    name = main_toggle_button_name,
                    sprite = 'utility/preset',
                    tooltip = 'Click to hide top buttons!',
                    style = Public.button_style
                }
            )
        if b then
            b.style.font_color = { 165, 165, 165 }
            b.style.font = 'default-semibold'
            b.style.minimal_height = 36
            b.style.maximal_height = 36
            b.style.minimal_width = 15
            b.style.maximal_width = 15
            b.style.padding = -2
        end
    else
        local b =
            player.gui.top.add(
                {
                    type = 'sprite-button',
                    name = main_toggle_button_name,
                    sprite = 'utility/preset',
                    style = Public.button_style,
                    tooltip = 'Click to hide top buttons!'
                }
            )
        b.style.padding = 2
        b.style.width = 20
        b.style.maximal_height = 38
    end
end

local function place_main_frame(player, frame, limits)
    if player.gui.screen[main_frame_name] == frame then
        local positions = settings.main_frame_positions
        local saved = positions and positions[player.index]
        local resolution, scale = player.display_resolution, player.display_scale
        local max_x = math.max(0, resolution.width - math.ceil(limits.width * scale))
        local max_y = math.max(0, resolution.height - math.ceil(limits.height * scale))
        frame.location =
        {
            x = saved and math.max(0, math.min(saved.x, max_x)) or math.floor(max_x / 2),
            y = saved and math.max(0, math.min(saved.y, max_y)) or math.floor(max_y / 2)
        }
    end
end

local function layout_main_frame(player, frame)
    local inside = frame.inside_frame
    local limits = Style.window(frame, inside, player)
    local compact = frame.tags.comfy_view == 'compact'
    local titlebar = frame.titlebar
    titlebar.main_label.visible = limits.width >= (compact and 360 or 250)
    titlebar.main_label.style.maximal_width = math.max(50, limits.width - (compact and 325 or 220))
    local narrow = limits.width < 430
    titlebar.style.horizontal_spacing = narrow and 2 or Style.spacing.sm
    titlebar.children[2].visible = not narrow
    local section_selector = titlebar[section_selector_name]
    if section_selector then
        section_selector.style.width = math.min(124, math.max(64, limits.width - 190))
    end
    for _, entry in ipairs(inside.tabbed_pane.tabs) do
        Style.apply_tab(get_tab_body(entry.content), limits)
    end
    place_main_frame(player, frame, limits)
end

local function remember_tab(player)
    local selected = get_player_active_tab(player)
    if not selected then
        return
    end
    local state = menu_state(player)
    state.tab = tab_captions[selected.name] or selected.caption
    if state.tab == 'Map Info' and state.map_info then
        state.map_info = nil
        local button = get_main_button(player)
        if button then
            button.tooltip = main_button_tooltip(player)
        end
    end
end

local function close_main_frame(player)
    if Public.get_parent_frame(player) then
        local active = Public.get_player_active_frame(player)
        Event.raise(ServerCommands.events.on_gui_closed_main_frame, { player_index = player.index, element = active or nil })
    end
    Public.clear_main_frame(player)
end

local function available_tabs(player, state)
    local visible = {}
    local server_data = Server.get_current_time()
    for caption, tab in pairs(main_gui_tabs) do
        if tab_is_available(player, state, caption, tab, server_data) then
            visible[caption] = tab
        end
    end
    return visible
end

local function add_selector(titlebar, close_button, name, width, items, selected, tooltip, tags)
    local selector = titlebar.add({
        type = 'drop-down', name = name, items = items, selected_index = selected,
        index = close_button.get_index_in_parent(), tooltip = tooltip, tags = tags
    })
    selector.style.width = width
    selector.style.height = Style.dimensions.button_height
end

local function build_titlebar(frame, close_button, view, groups, section_index, docked)
    local titlebar = frame.titlebar
    titlebar.style.vertical_align = 'center'
    local titlebar_filler = titlebar.children[2]
    if docked then
        titlebar_filler.style = 'empty_widget'
        titlebar_filler.style.horizontally_stretchable = true
    else
        titlebar.tooltip = { 'gui.comfy_menu_drag' }
        titlebar_filler.style.height = 16
    end

    if view == 'compact' and #groups > 1 then
        local labels, targets = {}, {}
        for i, group in ipairs(groups) do
            labels[i] = { 'gui.comfy_section_' .. group.name }
            targets[i] = group.tabs[1]
        end
        add_selector(titlebar, close_button, section_selector_name, 124, labels, section_index,
            { 'gui.comfy_choose_section' }, { tabs = targets })
    end

    local mode_labels = {}
    for i, name in ipairs(view_modes) do
        mode_labels[i] = { 'gui.comfy_view_' .. name }
    end
    add_selector(titlebar, close_button, view_selector_name, 110, mode_labels, view == 'compact' and 2 or 3,
        { 'gui.comfy_choose_view' })

    Style.action_button(titlebar, {
        name = dock_button_name, index = close_button.get_index_in_parent(),
        sprite = Public.pin_white_icon, hovered_sprite = Public.pin_black_icon, clicked_sprite = Public.pin_black_icon,
        tooltip = { docked and 'gui.comfy_menu_undock' or 'gui.comfy_menu_dock' }
    })
end

local function add_menu_tabs(pane, groups, view, section_index, selected_caption)
    local index = 0
    for i, group in ipairs(groups) do
        if view == 'full' or i == section_index then
            for _, caption in ipairs(group.tabs) do
                local tab = pane.add({
                    type = 'tab', caption = main_gui_tabs[caption].localised_caption or caption, name = main_gui_tabs[caption].name, style = 'slightly_smaller_tab'
                })
                local content = pane.add({
                    type = 'frame', name = caption, direction = 'vertical', style = 'deep_frame_in_tabbed_pane'
                })
                content.style.horizontally_stretchable = true
                content.add({
                    type = 'scroll-pane', name = caption, style = 'naked_scroll_pane', tags = { comfy_view = view },
                    horizontal_scroll_policy = 'auto', vertical_scroll_policy = 'auto-and-reserve-space'
                })
                pane.add_tab(tab, content)
                index = index + 1
                if caption == selected_caption then
                    pane.selected_tab_index = index
                end
            end
        end
    end
end

local function draw_main_frame(player, selected_caption, view)
    local state = menu_state(player)
    view = view or (state.view == 'compact' and 'compact' or 'full')
    local visible = available_tabs(player, state)
    local groups = Public.sections(visible)
    selected_caption = selected_caption or state.tab
    local section_index = 1
    for i, group in ipairs(groups) do
        for _, caption in ipairs(group.tabs) do
            if caption == selected_caption then
                section_index = i
            end
        end
    end

    close_main_frame(player)
    state.view = view

    local title = ServerCommands.is_dev_server() and 'Comfy Panel (Dev)' or 'Comfy Panel'
    local docked = settings.main_frame_docked and settings.main_frame_docked[player.index]
    local align = docked and 'left' or 'screen'
    local frame, default_inside, close_button = Public.add_main_frame_with_toolbar(player, align, main_frame_name, nil, close_button_name, title)
    default_inside.destroy()
    frame.tags = { comfy_view = view }
    build_titlebar(frame, close_button, view, groups, section_index, docked)

    local inside = frame.add({
        type = 'scroll-pane', name = 'inside_frame', style = 'naked_scroll_pane',
        horizontal_scroll_policy = 'auto', vertical_scroll_policy = 'never'
    })
    local pane = inside.add({ type = 'tabbed-pane', name = 'tabbed_pane' })
    pane.style.top_margin = 0
    if #groups == 0 then
        inside.add({ type = 'label', caption = { 'gui.comfy_no_tabs' } })
    else
        add_menu_tabs(pane, groups, view, section_index, selected_caption)
    end
    layout_main_frame(player, frame)
    player.opened = frame
    Public.reload_active_tab(player, true)
    remember_tab(player)
    return frame, inside
end

local function show_status(player)
    close_main_frame(player)
    local state = menu_state(player)
    state.view = 'minimal'
    add_status_frame(player, state.collapsed)
    update_status(player, #game.connected_players, Server.get_current_time())
end

local function on_object_destroyed(event)
    local player_index = removed_objects[event.registration_number]
    if not player_index then
        return
    end

    local element_index = event.useful_id
    removed_objects[event.registration_number] = nil

    local player_data = data[player_index]
    if player_data then
        player_data[element_index] = nil
    end
end

function Public.get_content(player)
    local inside = Public.get_main_frame(player)
    return inside and inside.tabbed_pane or false
end

function Public.refresh(player)
    local frame = get_player_active_tab(player)
    if not frame then
        return false
    end

    local tabbed_pane = Public.get_content(player)

    for _, tab in pairs(tabbed_pane.tabs) do
        local body = get_tab_body(tab.content)
        if tab.tab ~= frame and #body.children > 0 then
            remove_data_recursively(body)
            body.clear()
            Event.raise(ServerCommands.events.on_gui_removal, { player_index = player.index })
        end
    end

    Public.reload_active_tab(player, true)
    return true
end

function Public.toggle_top_buttons(player, state)
    if not player or not player.valid then
        return
    end
    local mod_gui_top_frame = player.gui.top.mod_gui_top_frame
    if not mod_gui_top_frame or not mod_gui_top_frame.valid then
        return
    end
    local mod_gui_inner_frame = mod_gui_top_frame.mod_gui_inner_frame
    if not mod_gui_inner_frame or not mod_gui_inner_frame.valid then
        return
    end

    for _, gui_data in pairs(mod_gui_inner_frame.children) do
        if gui_data and gui_data.valid then
            gui_data.enabled = state
        end
    end
end

function Public.set_tab(player, tab_name, status)
    local state = menu_state(player)
    state.disabled_tabs = state.disabled_tabs or {}
    state.disabled_tabs[tab_captions[tab_name] or tab_name] = status == true
    if Public.get_parent_frame(player) then
        draw_main_frame(player)
    end
end

function Public.bar(frame, width)
    if not frame or not frame.valid then
        return
    end

    local line =
        frame.add
        {
            type = 'progressbar',
            size = 1,
            value = 1
        }
    line.style.height = 3
    line.style.width = width or 10
    line.style.color = Color.white
    return line
end

function Public.call_existing_tab(player, name)
    draw_main_frame(player, name)
end

function Public.get_player_from_element(element)
    if not element or not element.valid then
        return
    end
    return game.players[element.player_index]
end

function Public.apply_direction_button_style(button)
    local button_style = button.style
    button_style.width = 24
    button_style.height = 24
    button_style.top_padding = 0
    button_style.bottom_padding = 0
    button_style.left_padding = 0
    button_style.right_padding = 0
    button_style.font = 'default-listbox'
end

function Public.apply_button_style(button)
    local button_style = button.style
    button_style.font = 'default-semibold'
    button_style.height = 26
    button_style.minimal_width = 26
    button_style.top_padding = 0
    button_style.bottom_padding = 0
    button_style.left_padding = 2
    button_style.right_padding = 2
end

--------------------------------------------------------------------------------
-- GUI Functions
--------------------------------------------------------------------------------
Public.my_fixed_width_style =
{
    minimal_width = 450,
    maximal_width = 450
}
Public.my_label_style =
{
    single_line = false,
    font_color = { r = 1, g = 1, b = 1 },
    top_padding = 0,
    bottom_padding = 0,
    font = 'default-listbox'
}
Public.my_label_header_style =
{
    single_line = false,
    font = 'default-game',
    font_color = { r = 1, g = 1, b = 1 },
    top_padding = 0,
    bottom_padding = 0
}
Public.my_label_header_grey_style =
{
    single_line = false,
    font = 'heading-1',
    font_color = { r = 0.6, g = 0.6, b = 0.6 },
    top_padding = 0,
    bottom_padding = 0
}
Public.my_note_style =
{
    single_line = false,
    font = 'default-small-semibold',
    font_color = { r = 1, g = 0.5, b = 0.5 },
    top_padding = 0,
    bottom_padding = 0
}
Public.my_warning_style =
{
    single_line = false,
    font_color = { r = 1, g = 0.1, b = 0.1 },
    top_padding = 0,
    bottom_padding = 0
}
Public.my_spacer_style =
{
    minimal_height = 2,
    top_padding = 0,
    bottom_padding = 0
}
Public.my_small_button_style =
{
    font = 'default-small-semibold'
}
Public.my_player_list_fixed_width_style =
{
    minimal_width = 200,
    maximal_width = 400,
    maximal_height = 200
}
Public.my_player_list_admin_style =
{
    font = 'default-semibold',
    font_color = { r = 1, g = 0.5, b = 0.5 },
    minimal_width = 200,
    top_padding = 0,
    bottom_padding = 0,
    single_line = false
}
Public.my_player_list_style =
{
    font = 'default-semibold',
    minimal_width = 200,
    top_padding = 0,
    bottom_padding = 0,
    single_line = false
}
Public.my_player_list_offline_style =
{
    font_color = { r = 0.5, g = 0.5, b = 0.5 },
    minimal_width = 200,
    top_padding = 0,
    bottom_padding = 0,
    single_line = false
}
Public.my_player_list_style_spacer =
{
    minimal_height = 20
}
Public.my_color_red = { r = 1, g = 0.1, b = 0.1 }

Public.my_longer_label_style =
{
    maximal_width = 600,
    single_line = false,
    font_color = { r = 1, g = 1, b = 1 },
    top_padding = 0,
    bottom_padding = 0
}
Public.my_longer_warning_style =
{
    maximal_width = 600,
    single_line = false,
    font_color = { r = 1, g = 0.1, b = 0.1 },
    top_padding = 0,
    bottom_padding = 0
}


-- Apply a style option to a GUI
function Public.ApplyStyle(guiIn, styleIn)
    for k, v in pairs(styleIn) do
        guiIn.style[k] = v
    end
end

-- Shorter way to add a label with a style
function Public.AddLabel(guiIn, name, message, style)
    local g =
        guiIn.add
        {
            name = name,
            type = 'label',
            caption = message
        }
    if (type(style) == 'table') then
        Public.ApplyStyle(g, style)
    else
        g.style = style
    end
end

function Public.AddLabelCaption(guiIn, name, style)
    local g =
        guiIn.add
        {
            type = 'label',
            caption = name
        }
    if (type(style) == 'table') then
        Public.ApplyStyle(g, style)
    else
        g.style = style
    end
end

-- Shorter way to add a spacer
function Public.AddSpacer(guiIn)
    Public.ApplyStyle(guiIn.add { type = 'label', caption = ' ' }, Public.my_spacer_style)
end

function Public.AddSpacerLine(guiIn)
    Public.ApplyStyle(guiIn.add { type = 'line', direction = 'horizontal' }, Public.my_spacer_style)
end

Public.get_button_flow = get_button_flow
Public.mod_button = get_button_flow
Public.hide_button_flow = hide_button_flow
Public.show_button_flow = show_button_flow

-- Register a handler for the on_gui_checked_state_changed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Public.on_checked_state_changed = handler_factory(defines.events.on_gui_checked_state_changed)

-- Register a handler for the on_gui_click event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Public.on_click = handler_factory(defines.events.on_gui_click)

-- Register a handler for the on_gui_closed event for a custom LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Public.on_custom_close = handler_factory(defines.events.on_gui_closed)

-- Register a handler for the on_gui_elem_changed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Public.on_elem_changed = handler_factory(defines.events.on_gui_elem_changed)

-- Register a handler for the on_gui_selection_state_changed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Public.on_selection_state_changed = handler_factory(defines.events.on_gui_selection_state_changed)

-- Register a handler for the on_gui_text_changed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Public.on_text_changed = handler_factory(defines.events.on_gui_text_changed)

-- Register a handler for the on_gui_value_changed event for LuaGuiElements with element_name.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Public.on_value_changed = handler_factory(defines.events.on_gui_value_changed)

--- Called when the player opens a GUI.
-- @tparam function handler the event handler which will be called
-- @usage element_define:on_open(function(event)
--  event.player.print(table.inspect(event))
--end)
GuiMetaMethods.on_open = event_handler_factory(defines.events.on_gui_opened)

--- Called when the player closes the GUI they have open.
-- @tparam function handler the event handler which will be called
-- @usage element_define:on_close(function(event)
--  event.player.print(table.inspect(event))
--end)
GuiMetaMethods.on_close = event_handler_factory(defines.events.on_gui_closed)

--- Called when LuaGuiElement is clicked.
-- @tparam function handler the event handler which will be called
-- @usage element_define:on_click(function(event)
--  event.player.print(table.inspect(event))
--end)
GuiMetaMethods.on_click = event_handler_factory(defines.events.on_gui_click)

--- Called when a LuaGuiElement is confirmed, for example by pressing Enter in a textfield.
-- @tparam function handler the event handler which will be called
-- @usage element_define:on_confirmed(function(event)
--  event.player.print(table.inspect(event))
--end)
GuiMetaMethods.on_confirmed = event_handler_factory(defines.events.on_gui_confirmed)

--- Called when LuaGuiElement checked state is changed (related to checkboxes and radio buttons).
-- @tparam function handler the event handler which will be called
-- @usage element_define:on_checked_changed(function(event)
--  event.player.print(table.inspect(event))
--end)
GuiMetaMethods.on_checked_changed = event_handler_factory(defines.events.on_gui_checked_state_changed)

--- Called when LuaGuiElement element value is changed (related to choose element buttons).
-- @tparam function handler the event handler which will be called
-- @usage element_define:on_elem_changed(function(event)
--  event.player.print(table.inspect(event))
--end)
GuiMetaMethods.on_elem_changed = event_handler_factory(defines.events.on_gui_elem_changed)

--- Called when LuaGuiElement element location is changed (related to frames in player.gui.screen).
-- @tparam function handler the event handler which will be called
-- @usage element_define:on_location_changed(function(event)
--  event.player.print(table.inspect(event))
--end)
GuiMetaMethods.on_location_changed = event_handler_factory(defines.events.on_gui_location_changed)

--- Called when LuaGuiElement selected tab is changed (related to tabbed-panes).
-- @tparam function handler the event handler which will be called
-- @usage element_define:on_tab_changed(function(event)
--  event.player.print(table.inspect(event))
--end)
GuiMetaMethods.on_tab_changed = event_handler_factory(defines.events.on_gui_selected_tab_changed)

--- Called when LuaGuiElement selection state is changed (related to drop-downs and listboxes).
-- @tparam function handler the event handler which will be called
-- @usage element_define:on_selection_changed(function(event)
--  event.player.print(table.inspect(event))
--end)
GuiMetaMethods.on_selection_changed = event_handler_factory(defines.events.on_gui_selection_state_changed)

--- Called when LuaGuiElement switch state is changed (related to switches).
-- @tparam function handler the event handler which will be called
-- @usage element_define:on_switch_changed(function(event)
--  event.player.print(table.inspect(event))
--end)
GuiMetaMethods.on_switch_changed = event_handler_factory(defines.events.on_gui_switch_state_changed)

--- Called when LuaGuiElement text is changed by the player.
-- @tparam function handler the event handler which will be called
-- @usage element_define:on_text_changed(function(event)
--  event.player.print(table.inspect(event))
--end)
GuiMetaMethods.on_text_changed = event_handler_factory(defines.events.on_gui_text_changed)

--- Called when LuaGuiElement slider value is changed (related to the slider element).
-- @tparam function handler the event handler which will be called
-- @usage element_define:on_value_changed(function(event)
--  event.player.print(table.inspect(event))
--end)
GuiMetaMethods.on_value_changed = event_handler_factory(defines.events.on_gui_value_changed)

Public.on_click(dock_button_name, function (event)
    local player = event.player
    local frame = Public.get_parent_frame(player)
    if frame and event.element.parent == frame.titlebar then
        settings.main_frame_docked = settings.main_frame_docked or {}
        settings.main_frame_docked[player.index] = player.gui.screen[main_frame_name] == frame or nil
        draw_main_frame(player)
    end
end)

Public.on_selection_state_changed(view_selector_name, function (event)
    local player = event.player
    local frame = Public.get_parent_frame(player)
    local view = view_modes[event.element.selected_index]
    if frame and event.element.parent == frame.titlebar and view then
        if view == 'minimal' then
            show_status(player)
        elseif frame.tags.comfy_view ~= view then
            draw_main_frame(player, nil, view)
        end
    end
end)

Public.on_selection_state_changed(section_selector_name, function (event)
    local player = event.player
    local frame = Public.get_parent_frame(player)
    if frame and event.element.parent == frame.titlebar then
        local caption = event.element.tags.tabs[event.element.selected_index]
        if caption then
            draw_main_frame(player, caption, 'compact')
        end
    end
end)

Public.on_click(status_expand_button_name, function (event)
    local player = event.player
    local frame = get_status_frame(player)
    if frame and event.element.parent == frame.toolbar then
        draw_main_frame(player, nil, 'compact')
    end
end)

Public.on_click(status_fold_button_name, function (event)
    local player = event.player
    local frame = get_status_frame(player)
    if frame and event.element.parent == frame.toolbar then
        local state = menu_state(player)
        state.collapsed = not state.collapsed
        frame.details.visible = not state.collapsed
        event.element.caption = state.collapsed and '+' or '−'
        event.element.tooltip = { state.collapsed and 'gui.comfy_show_status' or 'gui.comfy_hide_status' }
        update_status(player, #game.connected_players, Server.get_current_time())
    end
end)

Public.on_click(status_map_info_button_name, function (event)
    if event.element.parent == get_status_frame(event.player) then
        draw_main_frame(event.player, 'Map Info', 'compact')
    end
end)

Event.add(defines.events.on_gui_location_changed, function (event)
    local frame = event.element
    if frame and frame.valid and frame.name == main_frame_name and frame.location then
        settings.main_frame_positions = settings.main_frame_positions or {}
        settings.main_frame_positions[event.player_index] = frame.location
    end
end)

Public.on_click(
    main_button_name,
    function (event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Main button')
        if is_spamming then
            return
        end
        local player = event.player
        if Public.get_parent_frame(player) or get_status_frame(player) then
            close_main_frame(player)
            Event.raise(ServerCommands.events.on_gui_removal, { player_index = player.index })
        elseif menu_state(player).view == 'minimal' then
            show_status(player)
        else
            draw_main_frame(player)
        end
    end
)

Public.on_click(
    close_button_name,
    function (event)
        close_main_frame(event.player)
    end
)

Public.on_custom_close(
    main_frame_name,
    function (event)
        close_main_frame(event.player)
    end
)

Public.on_click(
    main_toggle_button_name,
    function (event)
        local button = event.element
        local player = event.player
        local top = player.gui.top

        if button.sprite == 'utility/preset' then
            if Public.get_mod_gui_top_frame() then
                for _, ele in pairs(top.mod_gui_top_frame.mod_gui_inner_frame.children) do
                    if ele and ele.valid and ele.name ~= main_toggle_button_name then
                        ele.visible = false
                    end
                end
            else
                for _, ele in pairs(top.children) do
                    if ele and ele.valid and ele.name ~= main_toggle_button_name then
                        ele.visible = false
                    end
                end
            end

            Public.clear_all_active_frames(player)
            hide_status(player)

            button.sprite = 'utility/expand_dots'
            button.tooltip = 'Click to show top buttons!'
        else
            if Public.get_mod_gui_top_frame() then
                for _, ele in pairs(top.mod_gui_top_frame.mod_gui_inner_frame.children) do
                    if ele and ele.valid and ele.name ~= main_toggle_button_name then
                        ele.visible = true
                    end
                end
            else
                for _, ele in pairs(top.children) do
                    if ele and ele.valid and ele.name ~= main_toggle_button_name then
                        ele.visible = true
                    end
                end
            end

            button.sprite = 'utility/preset'
            button.tooltip = 'Click to hide top buttons!'
        end
    end
)

Event.add(defines.events.on_gui_selected_tab_changed, function (event)
    local player = game.get_player(event.player_index)
    local pane = Public.get_content(player)
    if pane and event.element == pane then
        Public.refresh(player)
        remember_tab(player)
        local frame = Public.get_parent_frame(player)
        if frame then
            place_main_frame(player, frame, Style.limits(player, frame.tags.comfy_view))
        end
    end
end)

local function resize_main_frame(event)
    local player = game.get_player(event.player_index)
    local frame = Public.get_parent_frame(player)
    if frame and frame.inside_frame and frame.inside_frame.type == 'scroll-pane' then
        local width = frame.style.minimal_width
        layout_main_frame(player, frame)
        if width ~= frame.style.minimal_width then
            Public.reload_active_tab(player, true)
        end
    end
end

Event.add(defines.events.on_player_display_resolution_changed, resize_main_frame)
Event.add(defines.events.on_player_display_scale_changed, resize_main_frame)

local function refresh_admin_tabs(event)
    local player = game.get_player(event.player_index)
    if Public.get_parent_frame(player) then
        draw_main_frame(player)
    end
end

Event.add(defines.events.on_player_promoted, refresh_admin_tabs)
Event.add(defines.events.on_player_demoted, refresh_admin_tabs)

Event.add(defines.events.on_player_removed, function (event)
    if settings.main_frame_positions then
        settings.main_frame_positions[event.player_index] = nil
    end
    if settings.main_frame_docked then
        settings.main_frame_docked[event.player_index] = nil
    end
    if settings.menu_state then
        settings.menu_state[event.player_index] = nil
    end
end)

local function refresh_status_panels()
    local players = game.connected_players
    local server_data = Server.get_current_time()
    for _, player in pairs(players) do
        update_status(player, #players, server_data)
    end
end

Event.add(defines.events.on_player_joined_game, refresh_status_panels)
Event.add(defines.events.on_player_left_game, refresh_status_panels)
Event.on_nth_tick(120, refresh_status_panels)

Event.add(
    defines.events.on_player_created,
    function (event)
        local player = game.get_player(event.player_index)
        if local_settings.toggle_button then
            top_toggle_button(player)
        end
        top_button(player)
    end
)

Event.add(
    defines.events.on_player_joined_game,
    function (event)
        local player = game.get_player(event.player_index)
        Public.destroy(player.gui.screen.comfy_player_settings)
        Public.destroy(player.gui.left.comfy_player_settings)
        local menu = Public.get_parent_frame(player)
        if menu then
            Public.destroy(menu.titlebar.comfy_player_settings_button)
        end
        resize_top_buttons(player)
        top_button(player)
    end
)

Event.add(defines.events.on_object_destroyed, on_object_destroyed)

function Public.data()
    return data
end

return Public
