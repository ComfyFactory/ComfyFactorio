--[[
Comfy Panel

To add a tab, insert into the "main_gui_tabs" table.

Example: main_gui_tabs["mapscores"] = {gui = draw_map_scores, admin = false}
if admin = true, then tab is visible only for admins (usable for map-specific settings)

draw_map_scores would be a function with the player and the frame as arguments

]]
local Event = require 'utils.event'
local Server = require 'utils.server'
local SpamProtection = require 'utils.spam_protection'
local Token = require 'utils.token'
local Global = require 'utils.global'
local Gui = require 'utils.gui'

local main_gui_tabs = {}
local Public = {}
local screen_elements = {}
local this = {
    settings = {
        mod_gui_top_frame = false
    }
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

--- This adds the given gui to the top gui.
---@param player <userdata>
---@param frame <object>
---@param name <string>
function Public.add_mod_button(player, frame)
    if Gui.get_button_flow(player)[frame.name] then
        if Gui.get_button_flow(player)[frame.name].valid then
            return
        else
            Gui.get_button_flow(player)[frame.name] = nil
        end
    end
    Gui.get_button_flow(player).add(frame)
end

---@param state <bool>
--- If we should use the new mod gui or not
function Public.set_mod_gui_top_frame(state)
    this.settings.mod_gui_top_frame = state or false
end

--- Get mod_gui_top_frame
function Public.get_mod_gui_top_frame()
    return this.settings.mod_gui_top_frame
end

--- This adds the given gui to the main gui.
---@param tbl
function Public.add_tab_to_gui(tbl)
    if not tbl then
        return
    end
    if not tbl.name then
        return
    end
    if not tbl.id then
        return
    end
    local admin = tbl.admin or false
    local only_server_sided = tbl.only_server_sided or false

    if not main_gui_tabs[tbl.name] then
        main_gui_tabs[tbl.name] = {id = tbl.id, admin = admin, only_server_sided = only_server_sided}
    else
        error('Given name: ' .. tbl.name .. ' already exists in table.')
    end
end

function Public.screen_to_bypass(elem)
    screen_elements[elem] = true
    return screen_elements
end

--- Fetches the main gui tabs. You are forbidden to write as this is local.
---@param key
function Public.get(key)
    if key then
        return main_gui_tabs[key]
    else
        return main_gui_tabs
    end
end

function Public.comfy_panel_clear_gui(player)
    for _, child in pairs(player.gui.left.children) do
        child.destroy()
    end
    for _, child in pairs(player.gui.screen.children) do
        if not screen_elements[child.name] then
            child.destroy()
        end
    end
end

function Public.comfy_panel_get_active_frame(player)
    local main_frame = player.gui.left.comfy_panel
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

function Public.comfy_panel_refresh_active_tab(player)
    local frame = Public.comfy_panel_get_active_frame(player)
    if not frame then
        return
    end

    local tab = main_gui_tabs[frame.name]
    if not tab then
        return
    end
    local id = tab.id
    if not id then
        return
    end
    local func = Token.get(id)

    local data = {
        player = player,
        frame = frame
    }

    return func(data)
end

local function top_button(player)
    if this.settings.mod_gui_top_frame then
        Public.add_mod_button(player, {type = 'sprite-button', name = 'comfy_panel_top_button', sprite = 'item/raw-fish'}, 'comfy_panel_top_button')
    else
        if player.gui.top['comfy_panel_top_button'] then
            return
        end
        local button = player.gui.top.add({type = 'sprite-button', name = 'comfy_panel_top_button', sprite = 'item/raw-fish'})
        button.style.minimal_height = 38
        button.style.maximal_height = 38
        button.style.minimal_width = 40
        button.style.padding = -2
    end
end

local function main_frame(player)
    local tabs = main_gui_tabs
    Public.comfy_panel_clear_gui(player)

    local frame = player.gui.left.comfy_panel
    if not frame or not frame.valid then
        frame = player.gui.left.add({type = 'frame', name = 'comfy_panel'})
    end

    frame.style.margin = 6

    local tabbed_pane = frame.add({type = 'tabbed-pane', name = 'tabbed_pane'})

    for name, func in pairs(tabs) do
        if func.only_server_sided then
            local secs = Server.get_current_time()
            if secs then
                local tab = tabbed_pane.add({type = 'tab', caption = name, name = 'tab_' .. name})
                local name_frame = tabbed_pane.add({type = 'frame', name = name, direction = 'vertical'})
                name_frame.style.minimal_height = 480
                name_frame.style.maximal_height = 480
                name_frame.style.minimal_width = 800
                name_frame.style.maximal_width = 800
                tabbed_pane.add_tab(tab, name_frame)
            end
        elseif func.admin == true then
            if player.admin then
                local tab = tabbed_pane.add({type = 'tab', caption = name, name = 'tab_' .. name})
                local name_frame = tabbed_pane.add({type = 'frame', name = name, direction = 'vertical'})
                name_frame.style.minimal_height = 480
                name_frame.style.maximal_height = 480
                name_frame.style.minimal_width = 800
                name_frame.style.maximal_width = 800
                tabbed_pane.add_tab(tab, name_frame)
            end
        else
            local tab = tabbed_pane.add({type = 'tab', caption = name, name = 'tab_' .. name})
            local name_frame = tabbed_pane.add({type = 'frame', name = name, direction = 'vertical'})
            name_frame.style.minimal_height = 480
            name_frame.style.maximal_height = 480
            name_frame.style.minimal_width = 800
            name_frame.style.maximal_width = 800
            tabbed_pane.add_tab(tab, name_frame)
        end
    end

    local tab = tabbed_pane.add({type = 'tab', name = 'comfy_panel_close', caption = 'X'})
    tab.style.maximal_width = 32
    local t_frame = tabbed_pane.add({type = 'frame', direction = 'vertical'})
    tabbed_pane.add_tab(tab, t_frame)

    for _, child in pairs(tabbed_pane.children) do
        child.style.padding = 8
        child.style.left_padding = 2
        child.style.right_padding = 2
    end

    Public.comfy_panel_refresh_active_tab(player)
end

function Public.comfy_panel_call_tab(player, name)
    main_frame(player)
    local tabbed_pane = player.gui.left.comfy_panel.tabbed_pane
    for key, v in pairs(tabbed_pane.tabs) do
        if v.tab.caption == name then
            tabbed_pane.selected_tab_index = key
            Public.comfy_panel_refresh_active_tab(player)
        end
    end
end

local function on_player_joined_game(event)
    local player = game.get_player(event.player_index)
    top_button(player)
end

local function on_gui_click(event)
    local element = event.element
    if not element or not element.valid then
        return
    end

    local player = game.get_player(event.player_index)

    local name = element.name

    if name == 'comfy_panel_top_button' then
        local is_spamming = SpamProtection.is_spamming(player, nil, 'Comfy Main GUI Click')
        if is_spamming then
            return
        end
        if player.gui.left.comfy_panel then
            player.gui.left.comfy_panel.destroy()
            return
        else
            main_frame(player)
            return
        end
    end

    if element.caption == 'X' and name == 'comfy_panel_close' then
        local is_spamming = SpamProtection.is_spamming(player, nil, 'Comfy Main Gui Close Button')
        if is_spamming then
            return
        end
        player.gui.left.comfy_panel.destroy()
        return
    end

    if not element.caption then
        return
    end
    if element.type ~= 'tab' then
        return
    end

    Public.comfy_panel_refresh_active_tab(player)
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_created, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)

return Public
