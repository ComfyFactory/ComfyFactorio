local Token = require 'utils.token'
local Event = require 'utils.event'
local Global = require 'utils.global'
local mod_gui = require('__core__/lualib/mod-gui')
local Server = require 'utils.server'
local SpamProtection = require 'utils.spam_protection'

local tostring = tostring
local next = next

local Public = {}

-- local to this file
local main_gui_tabs = {}
local screen_elements = {}
local on_visible_handlers = {}
local on_pre_hidden_handlers = {}

-- global
local data = {}
local element_map = {}
local settings = {
    mod_gui_top_frame = false,
    disabled_tabs = {}
}

Public.token =
    Global.register(
    {data = data, element_map = element_map, settings = settings},
    function(tbl)
        data = tbl.data
        element_map = tbl.element_map
        settings = tbl.settings
    end
)

Public.settings_white_icon = 'file/utils/files/settings-white.png'
Public.settings_black_icon = 'file/utils/files/settings-black.png'
Public.pin_white_icon = 'file/utils/files/pin-white.png'
Public.pin_black_icon = 'file/utils/files/pin-black.png'
Public.infinite_icon = 'file/utils/files/infinity.png'
Public.arrow_up_icon = 'file/utils/files/arrow-up.png'
Public.arrow_down_icon = 'file/utils/files/arrow-down.png'
Public.info_icon = 'file/utils/files/info.png'

function Public.uid_name()
    return tostring(Token.uid())
end

function Public.uid()
    return Token.uid()
end

local main_frame_name = Public.uid_name()
local main_button_name = Public.uid_name()
local close_button_name = Public.uid_name()

-- Associates data with the LuaGuiElement. If data is nil then removes the data
function Public.set_data(element, value)
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

        values[element.index] = value
    end
end
local set_data = Public.set_data

-- Gets the Associated data with this LuaGuiElement if any.
function Public.get_data(element)
    if not element then
        return
    end

    local player_index = element.player_index

    local values = data[player_index]
    if not values then
        return nil
    end

    return values[element.index]
end

-- Adds a gui that is alike the factorio native gui.
function Public.add_main_frame_with_toolbar(player, align, set_frame_name, set_settings_button_name, close_main_frame_name, name, info)
    if not align then
        return
    end
    local main_frame
    if align == 'left' then
        main_frame = player.gui.left.add {type = 'frame', name = set_frame_name, direction = 'vertical'}
    elseif align == 'center' then
        main_frame = player.gui.center.add {type = 'frame', name = set_frame_name, direction = 'vertical'}
    elseif align == 'screen' then
        main_frame = player.gui.screen.add {type = 'frame', name = set_frame_name, direction = 'vertical'}
    end

    local titlebar = main_frame.add {type = 'flow', name = 'titlebar', direction = 'horizontal'}
    titlebar.style.horizontal_spacing = 8
    titlebar.style = 'horizontal_flow'

    if align == 'screen' then
        titlebar.drag_target = main_frame
    end

    titlebar.add {
        type = 'label',
        name = 'main_label',
        style = 'frame_title',
        caption = name,
        ignored_by_interaction = true
    }
    local widget = titlebar.add {type = 'empty-widget', style = 'draggable_space', ignored_by_interaction = true}
    widget.style.left_margin = 4
    widget.style.right_margin = 4
    widget.style.height = 24
    widget.style.horizontally_stretchable = true

    if set_settings_button_name then
        if not info then
            titlebar.add {
                type = 'sprite-button',
                name = set_settings_button_name,
                style = 'frame_action_button',
                sprite = Public.settings_white_icon,
                mouse_button_filter = {'left'},
                hovered_sprite = Public.settings_black_icon,
                clicked_sprite = Public.settings_black_icon,
                tooltip = 'Settings',
                tags = {
                    action = 'open_settings_gui'
                }
            }
        else
            titlebar.add {
                type = 'sprite-button',
                name = set_settings_button_name,
                style = 'frame_action_button',
                sprite = Public.info_icon,
                mouse_button_filter = {'left'},
                hovered_sprite = Public.info_icon,
                clicked_sprite = Public.info_icon,
                tooltip = 'Info',
                tags = {
                    action = 'open_settings_gui'
                }
            }
        end
    end

    if close_main_frame_name then
        titlebar.add {
            type = 'sprite-button',
            name = close_main_frame_name,
            style = 'frame_action_button',
            mouse_button_filter = {'left'},
            sprite = 'utility/close_white',
            hovered_sprite = 'utility/close_black',
            clicked_sprite = 'utility/close_black',
            tooltip = 'Close',
            tags = {
                action = 'close_main_frame_gui'
            }
        }
    end

    local inside_frame =
        main_frame.add {
        type = 'frame',
        style = 'inside_shallow_frame'
    }

    local inside_frame_style = inside_frame.style
    inside_frame_style.vertically_stretchable = true
    inside_frame_style.maximal_height = 800

    local inside_table =
        inside_frame.add {
        type = 'table',
        column_count = 1,
        name = 'inside_frame'
    }
    inside_table.style.padding = 3

    return main_frame, inside_table
end

local remove_data_recursively
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
    remove_data_recursively(element)
    element.destroy()
end

function Public.clear(element)
    remove_children_data(element)
    element.clear()
end

local function clear_invalid_data()
    if settings.disable_clear_invalid_data then
        return
    end

    for _, player in pairs(game.players) do
        local player_index = player.index
        local values = data[player_index]
        if values then
            for k, element in next, values do
                if type(element) == 'table' then
                    for key, obj in next, element do
                        if type(obj) == 'table' and obj.valid ~= nil then
                            if not obj.valid then
                                element[key] = nil
                            end
                        end
                    end
                    if type(element) == 'userdata' and not element.valid then
                        values[k] = nil
                    end
                end
            end
        end
    end
end
Event.on_nth_tick(300, clear_invalid_data)

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

        handler(event)
    end

    return function(element_name, handler)
        if not handlers then
            handlers = {}
            Event.add(event_id, on_event)
        end

        handlers[element_name] = handler
    end
end

local function custom_handler_factory(handlers)
    return function(element_name, handler)
        handlers[element_name] = handler
    end
end

--luacheck: ignore custom_raise
---@diagnostic disable-next-line: unused-function, unused-local
local function custom_raise(handlers, element, player)
    local handler = handlers[element.name]
    if not handler then
        return
    end

    handler({element = element, player = player})
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

    settings.disabled_tabs[frame_name] = state or false
end

-- Fetches if a gui is disabled.
---@param frame_name string
function Public.get_disabled_tab(frame_name)
    if not frame_name then
        return
    end

    return settings.disabled_tabs[frame_name]
end

-- Fetches the main frame name
function Public.get_main_frame(player)
    if not player then
        return false
    end

    local left = player.gui.left
    local frame = left[main_frame_name]

    if frame and frame.valid then
        local inside_frame = frame.children[2]
        if inside_frame and inside_frame.valid then
            local inside_table = inside_frame.children[1]
            if inside_table and inside_table.valid then
                return inside_table
            end
        end
        return false
    end
    return false
end

-- Fetches the parent frame name
function Public.get_parent_frame(player)
    if not player then
        return false
    end

    local left = player.gui.left
    local frame = left[main_frame_name]

    if frame and frame.valid then
        return frame
    end
    return false
end

--- This adds the given gui to the top gui.
---@param player userdata
---@param frame userdata
function Public.add_mod_button(player, frame)
    if Public.get_button_flow(player)[frame.name] and Public.get_button_flow(player)[frame.name].valid then
        return
    end

    Public.get_button_flow(player).add(frame)
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

--- This adds the given gui to the main gui.
---@param tbl table
function Public.add_tab_to_gui(tbl)
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
        main_gui_tabs[tbl.caption] = {id = tbl.id, name = tbl.name, admin = admin, only_server_sided = only_server_sided}
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

function Public.clear_main_frame(player)
    if not player then
        return
    end
    local frame = Public.get_main_frame(player)
    if frame then
        frame.destroy()
    end
end

function Public.clear_all_center_frames(player)
    for _, child in pairs(player.gui.center.children) do
        child.destroy()
    end
end

function Public.clear_all_screen_frames(player)
    for _, child in pairs(player.gui.screen.children) do
        if not screen_elements[child.name] then
            child.destroy()
        end
    end
end

function Public.clear_all_active_frames(player)
    for _, child in pairs(player.gui.left.children) do
        child.destroy()
    end
    for _, child in pairs(player.gui.screen.children) do
        if not screen_elements[child.name] then
            child.destroy()
        end
    end
end

function Public.get_player_active_frame(player)
    local main_frame = Public.get_main_frame(player)
    if not main_frame then
        return false
    end

    local panel = main_frame.tabbed_pane
    if not panel then
        return
    end
    local index = panel.selected_tab_index
    if not index then
        return panel.tabs[1].content
    end

    return panel.tabs[index].content
end

local function get_player_active_tab(player)
    local main_frame = Public.get_main_frame(player)
    if not main_frame then
        return false
    end

    local panel = main_frame.tabbed_pane
    if not panel then
        return
    end
    local index = panel.selected_tab_index
    if not index then
        return panel.tabs[1].tab, panel.tabs[1].content
    end

    return panel.tabs[index].tab, panel.tabs[index].content
end

function Public.reload_active_tab(player, forced)
    local is_spamming = SpamProtection.is_spamming(player, nil, 'Reload active tab')
    if is_spamming and not forced then
        return
    end

    local frame, main_tab = get_player_active_tab(player)
    if not frame then
        return
    end

    local tab = main_gui_tabs[frame.caption]
    if not tab then
        return
    end
    local id = tab.id
    if not id then
        return
    end
    local func = Token.get(id)

    local d = {
        player = player,
        frame = main_tab
    }

    return func(d)
end

local function top_button(player)
    if settings.mod_gui_top_frame then
        Public.add_mod_button(player, {type = 'sprite-button', name = main_button_name, sprite = 'item/raw-fish'})
    else
        if player.gui.top[main_button_name] then
            return
        end
        local button = player.gui.top.add({type = 'sprite-button', name = main_button_name, sprite = 'item/raw-fish'})
        button.style.minimal_height = 38
        button.style.maximal_height = 38
        button.style.minimal_width = 40
        button.style.padding = -2
    end
end

local function draw_main_frame(player)
    local tabs = main_gui_tabs
    Public.clear_all_active_frames(player)

    if Public.get_main_frame(player) then
        Public.get_main_frame(player).destroy()
    end

    local frame, inside_frame = Public.add_main_frame_with_toolbar(player, 'left', main_frame_name, nil, close_button_name, 'Comfy Panel')

    local tabbed_pane = inside_frame.add({type = 'tabbed-pane', name = 'tabbed_pane'})

    for name, func in pairs(tabs) do
        if not settings.disabled_tabs[name] then
            if func.only_server_sided then
                local secs = Server.get_current_time()
                if secs then
                    local tab = tabbed_pane.add({type = 'tab', caption = name, name = func.name})
                    local name_frame = tabbed_pane.add({type = 'frame', name = name, direction = 'vertical'})
                    name_frame.style.minimal_height = 480
                    name_frame.style.maximal_height = 480
                    name_frame.style.minimal_width = 800
                    name_frame.style.maximal_width = 800
                    tabbed_pane.add_tab(tab, name_frame)
                end
            elseif func.admin == true then
                if player.admin then
                    local tab = tabbed_pane.add({type = 'tab', caption = name, name = func.name})
                    local name_frame = tabbed_pane.add({type = 'frame', name = name, direction = 'vertical'})
                    name_frame.style.minimal_height = 480
                    name_frame.style.maximal_height = 480
                    name_frame.style.minimal_width = 800
                    name_frame.style.maximal_width = 800
                    tabbed_pane.add_tab(tab, name_frame)
                end
            else
                local tab = tabbed_pane.add({type = 'tab', caption = name, name = func.name})
                local name_frame = tabbed_pane.add({type = 'frame', name = name, direction = 'vertical'})
                name_frame.style.minimal_height = 480
                name_frame.style.maximal_height = 480
                name_frame.style.minimal_width = 800
                name_frame.style.maximal_width = 800
                tabbed_pane.add_tab(tab, name_frame)
            end
        end
    end

    for _, child in pairs(tabbed_pane.children) do
        child.style.padding = 8
        child.style.left_padding = 2
        child.style.right_padding = 2
    end

    Public.reload_active_tab(player, true)
    return frame, inside_frame
end

function Public.call_existing_tab(player, name)
    local frame, inside_frame = draw_main_frame(player)
    if not frame then
        return
    end
    local tabbed_pane = inside_frame.tabbed_pane
    for key, v in pairs(tabbed_pane.tabs) do
        if v.tab.caption == name then
            tabbed_pane.selected_tab_index = key
            Public.reload_active_tab(player, true)
        end
    end
end

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

-- Register a handler for when the player shows the top LuaGuiElements with element_name.
-- Assuming the element_name has been added with Public.allow_player_to_toggle_top_element_visibility.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Public.on_player_show_top = custom_handler_factory(on_visible_handlers)

-- Register a handler for when the player hides the top LuaGuiElements with element_name.
-- Assuming the element_name has been added with Public.allow_player_to_toggle_top_element_visibility.
-- Can only have one handler per element name.
-- Guarantees that the element and the player are valid when calling the handler.
-- Adds a player field to the event table.
Public.on_pre_player_hide_top = custom_handler_factory(on_pre_hidden_handlers)

if _DEBUG then
    local concat = table.concat

    local names = {}
    Public.names = names

    function Public.uid_name()
        local info = debug.getinfo(2, 'Sl')
        local filepath = info.source:match('^.+/currently%-playing/(.+)$'):sub(1, -5)
        local line = info.currentline

        local token = tostring(Token.uid())

        local name = concat {token, ' - ', filepath, ':line:', line}
        names[token] = name

        return token
    end

    function Public.set_data(element, value)
        local player_index = element.player_index
        local values = data[player_index]

        if value == nil then
            if not values then
                return
            end

            local index = element.index
            values[index] = nil
            element_map[index] = nil

            if next(values) == nil then
                data[player_index] = nil
            end
        else
            if not values then
                values = {}
                data[player_index] = values
            end

            local index = element.index
            values[index] = value
            element_map[index] = element
        end
    end
    set_data = Public.set_data

    function Public.data()
        return data
    end

    function Public.element_map()
        return element_map
    end
end

Public.get_button_flow = mod_gui.get_button_flow
Public.mod_button = mod_gui.get_button_flow

Public.on_click(
    main_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Main button')
        if is_spamming then
            return
        end
        local player = event.player
        local frame = Public.get_parent_frame(player)
        if frame then
            frame.destroy()
        else
            draw_main_frame(player)
        end
    end
)

Public.on_click(
    close_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Main button')
        if is_spamming then
            return
        end
        local player = event.player
        local frame = Public.get_parent_frame(player)
        if frame then
            frame.destroy()
        end
    end
)

Event.add(
    defines.events.on_player_created,
    function(event)
        local player = game.get_player(event.player_index)
        top_button(player)
    end
)

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        top_button(player)
    end
)

return Public
