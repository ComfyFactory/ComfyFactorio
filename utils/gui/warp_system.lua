local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Color = require 'utils.color_presets'
local SessionData = require 'utils.datastore.session_data'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Utils = require 'utils.utils'

local warp_entities =
{
    { 'small-lamp', -3, -2 },
    { 'small-lamp', -3, 2 },
    { 'small-lamp', 3, -2 },
    { 'small-lamp', 3, 2 },
    { 'small-lamp', -2, -3 },
    { 'small-lamp', 2, -3 },
    { 'small-lamp', -2, 3 },
    { 'small-lamp', 2, 3 },
    { 'small-electric-pole', -3, -3 },
    { 'small-electric-pole', 3, 3 },
    { 'small-electric-pole', -3, 3 },
    { 'small-electric-pole', 3, -3 }
}
local warp_tiles =
{
    { -3, -2 },
    { -3, -1 },
    { -3, 0 },
    { -3, 1 },
    { -3, 2 },
    { 3, -2 },
    { 3, -1 },
    { 3, 0 },
    { 3, 1 },
    { 3, 2 },
    { -2, -3 },
    { -1, -3 },
    { 0, -3 },
    { 1, -3 },
    { 2, -3 },
    { -2, 3 },
    { -1, 3 },
    { 0, 3 },
    { 1, 3 },
    { 2, 3 }
}

local radius = 4
local warp_tile = 'tutorial-grid'
local warp_item = 'discharge-defense-equipment'
local global_offset = { x = 0, y = 0 }

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local create_warp_button_name = Gui.uid_name()
local confirmed_button_name = Gui.uid_name()
local edit_warp_func_name = Gui.uid_name()
local create_warp_func_name = Gui.uid_name()
local create_warp_is_shared = Gui.uid_name()
local edit_warp_button_name = Gui.uid_name()
local remove_warp_button_name = Gui.uid_name()
local close_main_frame_name = Gui.uid_name()
local cancel_button_name = Gui.uid_name()
local show_only_player_warps = Gui.uid_name()
local warp_icon_name = Gui.uid_name()
local click_to_view_on_map_name = Gui.uid_name()

local this =
{
    warps = {},
    player_settings = {},
    surface_name = 'nauvis'
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local Public = {}

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not player.character then
        return false
    end
    if not player.connected then
        return false
    end
    if not game.players[player.name] then
        return false
    end
    return true
end

local function validate_data(new, player, p)
    if new == '' or new == 'Spawn' or new == 'Name:' or new == 'Warp name:' then
        player.print('[Warp] Warp name is not valid.', Color.fail)
        return false
    end

    if string.find(new:lower(), 'spawn') or string.find(new:lower(), 'warp') or string.find(new:lower(), 'name') then
        player.print('[Warp] Warp name is not valid.', Color.fail)
        return false
    end

    if string.len(new) > 30 then
        player.print('[Warp] Warp name is too long!', Color.fail)
        return false
    end

    if string.len(new) < 6 then
        p.frame.new_name.text = ''
        player.print('[Warp] Warp name is too short!', Color.fail)
        return false
    end
    return true
end

local function get_player_data(player)
    if not this.player_settings[player.index] then
        this.player_settings[player.index] =
        {
            creating = false,
            editing = false,
            removing = false,
            frame = nil,
            spam = 100,
            only_my_warps = false
        }
    end
    return this.player_settings[player.index]
end

function Public.get_warp_by_name(name)
    for _, data in pairs(this.warps) do
        if name == data.name then
            return data
        end
    end
    return false
end

function Public.remove_warp_by_name(name)
    for index, data in pairs(this.warps) do
        if name == data.name then
            this.warps[index] = nil
        end
    end
    return false
end

function Public.remove_player(index)
    for _, data in pairs(this.warps) do
        if data.created_by == index then
            Public.remove_warp_point(data.index)
        end
    end
end

function Public.remove_warp_point(index)
    local warp = Public.get_warp_by_name(index)
    if not warp then
        return
    end
    local surface_index = warp.surface
    local surface = game.get_surface(surface_index)
    if warp.name == 'Spawn' then
        return
    end


    local shared = warp.shared

    if warp.entities then
        for _, entity in pairs(warp.entities) do
            entity.destroy()
        end
    end

    if warp.old_tiles then
        surface.set_tiles(warp.old_tiles, true, false)
    end

    if warp.tag then
        warp.tag.destroy()
    end
    Public.remove_warp_by_name(index)
    return shared
end

function Public.make_warp_point(player, position, surface, icon, force, name, shared)
    if Public.get_warp_by_name(name) then
        return
    end

    local offset = { x = math.floor(position.x), y = math.floor(position.y) }
    local old_tiles = {}
    local base_tiles = {}
    local tiles = {}
    local entities = {}

    local _shared = shared or false

    if not string.find(surface.name, 'platform') then
        -- makes the base template to make the warp point
        for x = -radius - 2, radius + 2 do
            for y = -radius - 2, radius + 2 do
                if x ^ 2 + y ^ 2 < radius ^ 2 then
                    local old_tile = surface.get_tile({ x + offset.x, y + offset.y })
                    if old_tile and (old_tile.name ~= warp_tile) then
                        old_tiles[#old_tiles + 1] = { name = old_tile.name, position = old_tile.position }
                    end
                    base_tiles[#base_tiles + 1] = { name = warp_tile, position = { x + offset.x, y + offset.y } }
                end
            end
        end
        surface.set_tiles(base_tiles)


        -- adds the patterns and entities
        for _, p in pairs(warp_tiles) do
            local old_tile = surface.get_tile({ p[1] + offset.x + global_offset.x, p[2] + offset.y + global_offset.y })
            if old_tile and (old_tile.name ~= warp_tile) then
                old_tiles[#old_tiles + 1] = { name = old_tile.name, position = old_tile.position }
            end
            tiles[#tiles + 1] =
            {
                name = warp_tile,
                position = { p[1] + offset.x + global_offset.x, p[2] + offset.y + global_offset.y }
            }
        end

        surface.set_tiles(tiles)
        for _, e in pairs(warp_entities) do
            local entity =
                surface.create_entity
                {
                    name = e[1],
                    position = { e[2] + offset.x + global_offset.x, e[3] + offset.y + global_offset.y },
                    force = 'neutral'
                }
            entity.destructible = false
            entity.health = 0
            entity.minable_flag = false
            entity.rotatable = false
            entities[#entities + 1] = entity
        end
    end

    local tag =
        force.add_chart_tag(
            surface,
            {
                position = { offset.x + 0.5, offset.y + 0.5 },
                text = 'Warp: ' .. name,
                icon = { type = icon.type, name = icon.name }
            }
        )
    if not tag then
        return
    end

    local created_by = player.index

    local index = #this.warps + 1
    this.warps[index] =
    {
        tag = tag,
        position = tag.position,
        surface = surface.index,
        icon = icon,
        name = name,
        index = index,
        old_tiles = old_tiles,
        created_by = created_by,
        entities = entities,
        shared = _shared
    }
    return true
end

function Public.edit_warp_point(surface, icon, force, old_name, new_name, shared)
    local warp = Public.get_warp_by_name(old_name)
    if not warp then
        return
    end

    local old_tag = warp.tag
    if not old_tag then
        old_tag = warp
    end

    local tag =
        force.add_chart_tag(
            surface,
            {
                position = { old_tag.position.x + 0.5, old_tag.position.y + 0.5 },
                text = 'Warp: ' .. new_name,
                icon = { type = icon.type, name = icon.name }
            }
        )

    local new_icon = icon

    if warp.tag then
        warp.tag.destroy()
    end

    warp.tag = tag
    warp.icon = new_icon
    warp.name = new_name
    warp.shared = shared

    return true
end

function Public.make_tag(name, pos, shared)
    local get_surface = this.surface_name
    local surface = game.surfaces[get_surface]
    local data = {}
    if data.forces then
        data.forces = nil
    end
    for _, v in pairs(game.forces) do
        data.forces = v
    end
    local created_by = 'script'
    local v =
        data.forces.add_chart_tag(
            surface,
            {
                position = pos,
                text = 'Warp: ' .. name,
                icon = { type = 'item', name = warp_item }
            }
        )

    local index = #this.warps + 1
    this.warps[index] =
    {
        tag = v,
        position = pos,
        name = name,
        index = index,
        icon = { type = 'item', name = warp_item },
        surface = surface.index,
        created_by = created_by,
        shared = shared
    }
    return data
end

function Public.create_warp_button(player)
    if not SessionData.allowed(player, 'show-warp') then
        if Gui.get_button_flow(player)[main_button_name] then
            Gui.get_button_flow(player)[main_button_name].destroy()
        end
        return
    end
    if Gui.get_button_flow(player)[main_button_name] then
        return
    end
    local button = Gui.get_button_flow(player).add
        {
            type = 'sprite-button',
            sprite = 'item/discharge-defense-equipment',
            name = main_button_name,
            tooltip = 'Warp to places!',
            style = Gui.button_style
        }
    if button then
        button.style.font_color = { 165, 165, 165 }
        button.style.font = 'default-semibold'
        button.style.minimal_height = 36
        button.style.maximal_height = 36
        button.style.minimal_width = 40
        button.style.padding = -2
    end
end

local function draw_create_warp(parent, player)
    local position = player.position
    local posx = position.x
    local posy = position.y
    local dist2 = 100 ^ 2
    local p = get_player_data(player)
    if not SessionData.allowed(player, 'always-warp') then
        for _, warp in pairs(this.warps) do
            local pos = warp.position
            if (posx - pos.x) ^ 2 + (posy - pos.y) ^ 2 < dist2 then
                player.print('[Warp] Too close to another warp: ' .. warp.name, Color.fail)
                p.creating = false
                return
            end
        end
    end

    local x =
        parent.add
        {
            type = 'table',
            name = 'wp_table',
            column_count = 4
        }

    local elem =
        x.add
        {
            name = warp_icon_name,
            type = 'choose-elem-button',
            elem_type = 'signal',
            signal = { type = 'item', name = warp_item },
            tooltip = 'Choose the tag-icon'
        }
    local elem_style = elem.style
    elem_style.height = 32
    elem_style.width = 32

    local textfield =
        x.add
        {
            type = 'textfield',
            name = 'wp_text',
            text = 'Warp name:',
            numeric = false,
            allow_decimal = false,
            allow_negative = false
        }
    p.shared = true
    textfield.style.minimal_width = 100
    textfield.style.maximal_width = 150
    textfield.style.height = 24
    p.frame = { new_name = textfield }

    local _flow =
        x.add
        {
            type = 'flow'
        }
    _flow.style.horizontal_align = 'right'
    _flow.style.horizontally_stretchable = true

    local checkbox =
        _flow.add
        {
            type = 'checkbox',
            name = create_warp_is_shared,
            tooltip = 'Do you want to share this warp?',
            state = true
        }
    checkbox.style.top_margin = 5

    local btn =
        _flow.add
        {
            type = 'sprite-button',
            name = create_warp_func_name,
            tooltip = 'Creates a new warp point.',
            sprite = 'utility/confirm_slot',
            style = 'shortcut_bar_button_green'
        }
    btn.style.height = 23
    btn.style.width = 23
    btn.style.padding = -2
end

local function draw_edit_warp(parent, player)
    local p = get_player_data(player)
    local data = Public.get_warp_by_name(p.edit_warp_name)
    if not data then
        return
    end

    local x =
        parent.add
        {
            type = 'table',
            name = 'wp_table',
            column_count = 4
        }

    p.icon = data.icon

    local elem =
        x.add
        {
            name = warp_icon_name,
            type = 'choose-elem-button',
            elem_type = 'signal',
            signal = { type = data.icon.type, name = data.icon.name },
            tooltip = 'Choose the tag-icon'
        }
    local elem_style = elem.style
    elem_style.height = 32
    elem_style.width = 32

    local textfield =
        x.add
        {
            type = 'textfield',
            name = 'wp_text',
            text = data.name,
            numeric = false,
            allow_decimal = false,
            allow_negative = false
        }
    textfield.focus()
    p.shared = true
    textfield.style.minimal_width = 80
    textfield.style.maximal_width = 150
    textfield.style.height = 24
    p.frame = { new_name = textfield }

    local _flow =
        x.add
        {
            type = 'flow'
        }
    _flow.style.horizontal_align = 'right'
    _flow.style.horizontally_stretchable = true

    local checkbox =
        _flow.add
        {
            type = 'checkbox',
            name = create_warp_is_shared,
            tooltip = 'Do you want to share this warp?',
            state = data.shared
        }
    checkbox.style.top_margin = 5

    local cancel_btn =
        _flow.add
        {
            type = 'sprite-button',
            name = cancel_button_name,
            tooltip = 'Cancel editing',
            style = 'shortcut_bar_button_blue',
            sprite = 'utility/reset'
        }
    cancel_btn.style.height = 23
    cancel_btn.style.width = 23
    cancel_btn.style.padding = -2

    local edit_btn =
        _flow.add
        {
            type = 'sprite-button',
            name = edit_warp_func_name,
            tooltip = 'Edit the current warp point.',
            sprite = 'utility/confirm_slot',
            style = 'shortcut_bar_button_green'
        }
    edit_btn.style.height = 23
    edit_btn.style.width = 23
    edit_btn.style.padding = -2
end

local function draw_remove_warp(parent, player)
    parent.clear()
    if player.admin or SessionData.allowed(player, 'remove-warp') then
        local btn =
            parent.add
            {
                type = 'sprite-button',
                name = confirmed_button_name,
                tooltip = 'Do you really want to remove: ' .. parent.name,
                style = 'shortcut_bar_button_red',
                sprite = 'utility/confirm_slot'
            }
        btn.style.height = 23
        btn.style.width = 23
        btn.style.padding = -2
    else
        local btn =
            parent.add
            {
                type = 'sprite-button',
                name = confirmed_button_name,
                enabled = 'false',
                tooltip = 'You have not grown accustomed to this technology yet',
                style = 'shortcut_bar_button_red',
                sprite = 'utility/confirm_slot'
            }
        btn.style.height = 23
        btn.style.width = 23
        btn.style.padding = -2
    end
    local btn =
        parent.add
        {
            type = 'sprite-button',
            name = cancel_button_name,
            tooltip = 'Cancel deletion of: ' .. parent.name,
            style = 'shortcut_bar_button_blue',
            sprite = 'utility/reset'
        }
    btn.style.height = 23
    btn.style.width = 23
    btn.style.padding = -2
end

local warp_icon_button

local function draw_player_warp_only(player, p, frame_tbl, sub_table, name, warp, e)
    if not warp.tag or not warp.tag.valid then
        local surface = game.get_surface(warp.surface)
        for _, v in pairs(game.forces) do
            v.add_chart_tag(
                surface,
                {
                    position = warp.position,
                    text = 'Warp: ' .. name,
                    icon = { type = 'item', name = warp_item }
                }
            )
        end
    end
    local flow =
        frame_tbl.add
        {
            type = 'flow',
            caption = warp.name
        }
    warp_icon_button(flow, warp)

    local created_by_player_name

    local created_by_player = game.get_player(warp.created_by)
    if not created_by_player or not created_by_player.valid then
        created_by_player_name = warp.created_by
    else
        created_by_player_name = created_by_player.name
    end

    local subflow =
        frame_tbl.add
        {
            type = 'flow'
        }
    subflow.style.horizontal_align = 'left'
    subflow.style.horizontally_stretchable = true

    local info_label_tooltip = 'Click to view on map'

    if player.admin then
        info_label_tooltip = 'Created by: ' ..
            created_by_player_name .. '\nShared: ' .. tostring(warp.shared) .. '\nClick to view on map'
    end

    subflow.add
    {
        type = 'label',
        caption = name,
        name = click_to_view_on_map_name,
        style = 'caption_label',
        tooltip = info_label_tooltip
    }

    local _flows3 = frame_tbl.add { type = 'flow' }
    _flows3.style.horizontal_align = 'right'
    _flows3.style.horizontally_stretchable = true

    local bottom_warp_flow = frame_tbl.add { type = 'flow', name = name }

    if bottom_warp_flow.name ~= 'Spawn' and (warp.created_by == player.index or SessionData.allowed(player, 'warp-override')) then
        local tooltip
        if warp.created_by == player.index then
            tooltip = 'Edit warp: ' .. bottom_warp_flow.name
        else
            tooltip = 'Edit warp created by: ' .. created_by_player_name .. ' with name: ' .. bottom_warp_flow.name
        end
        local edit_warp_button =
            bottom_warp_flow.add
            {
                type = 'sprite-button',
                name = edit_warp_button_name,
                tooltip = tooltip,
                style = Gui.button_style,
                sprite = Gui.settings_white_icon,
                hovered_sprite = Gui.settings_black_icon,
                clicked_sprite = Gui.settings_black_icon
            }
        edit_warp_button.style.padding = -2
        edit_warp_button.style.height = 23
        edit_warp_button.style.width = 23

        local remove_warp_flow =
            bottom_warp_flow.add
            {
                type = 'sprite-button',
                name = remove_warp_button_name,
                tooltip = 'Removes warp: ' .. bottom_warp_flow.name,
                style = Gui.button_style,
                sprite = 'utility/trash'
            }
        remove_warp_flow.style.padding = -2
        remove_warp_flow.style.height = 23
        remove_warp_flow.style.width = 23
    end

    if p.editing then
        draw_edit_warp(sub_table, player)
        p.editing = false
    end

    if p.creating then
        draw_create_warp(sub_table, player)
        p.creating = false
    end

    if p.removing then
        if bottom_warp_flow.name == e then
            draw_remove_warp(bottom_warp_flow, player)
            p.removing = false
        end
    end
end

local function draw_main_frame(player, left, are_you_sure)
    local e = are_you_sure
    local p = get_player_data(player)

    local frame = Gui.add_main_frame(left, main_frame_name, 'Warps', 'Warp to places!')

    local tbl = frame.add { type = 'table', column_count = 1 }

    local _flows1 = tbl.add { type = 'flow' }
    _flows1.style.horizontally_stretchable = true

    local warp_list =
        _flows1.add
        {
            type = 'scroll-pane',
            direction = 'vertical',
            horizontal_scroll_policy = 'never',
            vertical_scroll_policy = 'auto',
            style = 'scroll_pane_under_subheader'
        }
    local scroll_style = warp_list.style
    scroll_style.padding = { 1, 3 }
    scroll_style.maximal_height = 200
    scroll_style.minimal_height = 200
    scroll_style.horizontally_stretchable = true

    local frame_tbl = warp_list.add { type = 'table', column_count = 4 }

    local sub_table = warp_list.add { type = 'table', column_count = 4 }
    sub_table.style.cell_padding = 4

    for _, warp in pairs(this.warps) do
        if p.edit_warp_name then
            if (warp.created_by == 'script') then
                draw_player_warp_only(player, p, frame_tbl, sub_table, warp.name, warp, e)
            end
        else
            if p.only_my_warps then
                if (warp.created_by == player.index or warp.created_by == 'script') then
                    draw_player_warp_only(player, p, frame_tbl, sub_table, warp.name, warp, e)
                end
            else
                if (warp.created_by == player.index and not warp.shared) then
                    draw_player_warp_only(player, p, frame_tbl, sub_table, warp.name, warp, e)
                elseif warp.shared == true then
                    draw_player_warp_only(player, p, frame_tbl, sub_table, warp.name, warp, e)
                end
            end
        end
    end

    local bottom_flow = frame.add { type = 'flow', direction = 'horizontal' }

    bottom_flow.add
    {
        type = 'checkbox',
        state = p.only_my_warps,
        name = show_only_player_warps,
        caption = 'Show only my warps.'
    }

    local bottom_bottom_flow = frame.add { type = 'flow', direction = 'horizontal' }

    local left_flow = bottom_bottom_flow.add { type = 'flow' }
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add { type = 'button', name = close_main_frame_name, caption = 'Close' }
    Gui.apply_button_style(close_button)

    local button_flow = left_flow.add { type = 'flow' }
    button_flow.style.horizontal_align = 'right'
    button_flow.style.horizontally_stretchable = true

    if SessionData.allowed(player, 'create-warp') or player.admin then
        local button = button_flow.add { type = 'button', name = create_warp_button_name, caption = 'Create Warp' }
        Gui.apply_button_style(button)
    else
        local button =
            button_flow.add
            {
                type = 'button',
                name = create_warp_button_name,
                caption = 'Create Warp.',
                enabled = false,
                tooltip = 'You have not grown accustomed to this technology yet.'
            }
        Gui.apply_button_style(button)
    end
end

function Public.toggle(player)
    local gui = player.gui
    local left = gui.left
    local main_frame = left[main_frame_name]

    if not validate_player(player) then
        return
    end

    if main_frame and main_frame.valid then
        Gui.clear_all_left_frames(player)
    else
        Gui.clear_all_active_frames(player)
        draw_main_frame(player, left)
    end
end

function Public.refresh_gui_player(player, are_you_sure, close)
    local e = are_you_sure
    local gui = player.gui
    local left = gui.left
    local main_frame = left[main_frame_name]

    if not validate_player(player) then
        return
    end

    if main_frame then
        Public.close_gui_player(main_frame)
        if not close then
            draw_main_frame(player, left, e)
        end
    end
end

function Public.close_gui_player(frame)
    if frame and frame.valid then
        frame.destroy()
    end
end

function Public.is_spam(p, player)
    if p.spam > game.tick then
        player.print(
            '[Warp] Please wait ' ..
            math.ceil((p.spam - game.tick) / 60) .. ' seconds before trying to warp or add warps again.', Color.warning)
        return true
    end
    return false
end

function Public.clear_player_table(player)
    local p = get_player_data(player)
    if p.removing == true then
        p.removing = false
    end
    if p.creating == true then
        p.creating = false
    end

    p.edit_warp_name = nil

    if p.frame then
        p.frame = nil
    end
    if p.icon then
        p.icon = nil
    end
    if p.shared then
        p.shared = nil
    end
end

function Public.refresh_gui()
    for _, player in pairs(game.connected_players) do
        local gui = player.gui
        local left = gui.left

        if not validate_player(player) then
            return
        end

        local main_frame = left[main_frame_name]

        if not player.connected then
            Public.close_gui_player(main_frame)
            return
        end

        if main_frame then
            Public.close_gui_player(main_frame)
            draw_main_frame(player, left)
        end
    end
end

local function on_player_joined_game(event)
    local player = game.get_player(event.player_index)

    if not validate_player(player) then
        return
    end

    get_player_data(player)

    Public.create_warp_button(player)
end

local function on_player_left_game(event)
    local player = game.get_player(event.player_index)

    if not validate_player(player) then
        return
    end

    Gui.clear_all_left_frames(player)
end

local function on_player_died(event)
    local player = game.get_player(event.player_index)

    if not validate_player(player) then
        return
    end

    local p = player.gui.left[main_frame_name]

    if not p then
        return
    end

    Public.close_gui_player(p)
end


Gui.on_click(
    main_button_name,
    function (event)
        local element = event.element
        if not element then
            return
        end
        local player = Gui.get_player_from_element(element)
        if not validate_player(player) then
            return
        end

        Public.clear_player_table(player)
        Public.toggle(player)
    end
)

Gui.on_click(
    close_main_frame_name,
    function (event)
        local player = game.get_player(event.player_index)

        if not validate_player(player) then
            return
        end

        Public.clear_player_table(player)
        Public.toggle(player)
    end
)

Gui.on_click(
    edit_warp_button_name,
    function (event)
        local player = game.get_player(event.player_index)

        if not validate_player(player) then
            return
        end

        local element = event.element
        local p = get_player_data(player)

        Public.clear_player_table(player)

        if p.editing == false then
            p.edit_warp_name = element.parent.name
            p.editing = true
        end

        Public.refresh_gui_player(player)
    end
)

Gui.on_click(
    click_to_view_on_map_name,
    function (event)
        local player = game.get_player(event.player_index)

        if not validate_player(player) then
            return
        end

        local element = event.element

        Public.clear_player_table(player)

        local warp_name = element.caption
        local warp = Public.get_warp_by_name(warp_name)
        if not warp then
            return
        end

        local position = warp.position
        player.zoom_to_world(position, 1.5)

        Public.refresh_gui_player(player)
    end
)

Gui.on_click(
    remove_warp_button_name,
    function (event)
        local player = game.get_player(event.player_index)

        if not validate_player(player) then
            return
        end

        local are_you_sure = event.element.parent.name

        local p = get_player_data(player)

        if not p then
            return
        end

        if not p.removing == true then
            p.removing = true
            Public.refresh_gui_player(player, are_you_sure)
        end
    end
)

Gui.on_click(
    create_warp_is_shared,
    function (event)
        local player = game.get_player(event.player_index)

        if not validate_player(player) then
            return
        end

        local p = get_player_data(player)

        if not p then
            return
        end

        p.shared = event.element.state
    end
)

Gui.on_click(
    show_only_player_warps,
    function (event)
        local player = game.get_player(event.player_index)

        if not validate_player(player) then
            return
        end

        local p = get_player_data(player)

        if not p then
            return
        end

        Public.clear_player_table(player)
        p.only_my_warps = event.element.state
        Public.refresh_gui_player(player)
    end
)

Gui.on_click(
    cancel_button_name,
    function (event)
        local player = game.get_player(event.player_index)

        if not validate_player(player) then
            return
        end

        Public.clear_player_table(player)
        Public.refresh_gui_player(player)
    end
)

Gui.on_click(
    confirmed_button_name,
    function (event)
        local player = game.get_player(event.player_index)
        local element = event.element
        if not element or not element.valid then
            return
        end

        if not validate_player(player) then
            return
        end

        local p = get_player_data(player)

        if not p then
            return
        end

        local shared = Public.remove_warp_point(element.parent.name)
        if shared then
            game.print('[Warp] ' .. player.name .. ' removed warp: ' .. element.parent.name, Color.warning)
        else
            player.print('[Warp] Removed warp: ' .. element.parent.name, Color.warning)
        end
        Public.refresh_gui()
        Public.clear_player_table(player)
    end
)

Gui.on_click(
    create_warp_button_name,
    function (event)
        local player = game.get_player(event.player_index)

        if not validate_player(player) then
            return
        end

        local p = get_player_data(player)

        Public.clear_player_table(player)

        if p.creating == false then
            p.creating = true
        end

        Public.refresh_gui_player(player)
    end
)

local set_remote_controller_token =
    Token.register(
        function (data)
            local player_index = data.player_index
            local player = game.get_player(player_index)
            if player and player.valid then
                player.set_controller({ type = defines.controllers.remote })
                player.enter_space_platform(player.surface.platform)
            end
        end,
        99999
    )

warp_icon_button =
    Gui.new_frame(
        function (event_trigger, parent, warp)
            local warp_position = warp.position
            -- Draw the element
            local sprite = warp.icon.type .. '/' .. warp.icon.name
            if warp.icon.type == 'virtual' then
                sprite = 'virtual-signal/' .. warp.icon.name
            end

            return parent.add
                {
                    name = event_trigger,
                    type = 'sprite-button',
                    sprite = sprite,
                    tooltip = 'Go to: x:' .. warp_position.x .. ' y: ' .. warp_position.y,
                    style = 'slot_button'
                }
        end
    ):add_style(Gui.Styles[32]):on_click(
        function (player, element, event)
            local p = get_player_data(player)

            if not p then
                return
            end

            element = element.parent.caption

            local warp

            local position

            if not SessionData.allowed(player, 'always-warp') then
                if Public.is_spam(p, player) then
                    return
                end

                warp = Public.get_warp_by_name(element)
                if not warp then
                    return
                end

                position = player.position

                local area =
                {
                    left_top = { x = position.x - 5, y = position.y - 5 },
                    right_bottom = { x = position.x + 5, y = position.y + 5 }
                }

                if not Utils.contains_positions(this.warps, area) then
                    player.print('[Warp] You are not standing on a warp platform.', Color.warning)
                    return
                end

                if (warp.position.x - position.x) ^ 2 + (warp.position.y - position.y) ^ 2 < 1024 then
                    player.print('[Warp] Destination is near source warp: ' .. element, Color.fail)
                    return
                end
            else
                warp = Public.get_warp_by_name(element)
                if not warp then
                    return
                end
            end

            if player.vehicle then
                player.vehicle.set_driver(nil)
            end
            if player.vehicle then
                player.vehicle.set_passenger(nil)
            end
            if player.vehicle then
                return
            end

            local surface = game.get_surface(warp.surface)

            local button = event.button -- int
            if button == defines.mouse_button_type.right then
                Task.set_timeout_in_ticks(5, set_remote_controller_token, { player_index = player.index })
                p.char = player.character
            elseif button == defines.mouse_button_type.left then
                if not player.character then
                    player.set_controller({ type = defines.controllers.character, character = p.char })
                end
            end

            local non_col = surface.find_non_colliding_position('character', warp.position, 32, 1)
            if non_col then
                player.teleport(non_col, surface)
                player.print('[Warp] Warped you over to: ' .. element, Color.success)
                player.play_sound { path = 'utility/armor_insert', volume_modifier = 1 }
                p.spam = game.tick + 900
            end

            Public.clear_player_table(player)

            Public.refresh_gui_player(player, nil, true)
        end
    )

Gui.on_click(
    create_warp_func_name,
    function (event)
        local player = game.get_player(event.player_index)

        if not validate_player(player) then
            return
        end

        local p = get_player_data(player)

        local position = player.position
        if not SessionData.allowed(player, 'always-warp') then
            if Public.is_spam(p, player) then
                return
            end

            local area =
            {
                left_top = { x = position.x - 100, y = position.y - 100 },
                right_bottom = { x = position.x + 100, y = position.y + 100 }
            }

            if Utils.contains_positions(this.warps, area) then
                player.print('[Warp] You are too close to another warp!', Color.warning)
                return
            end
        end

        local offset = { x = math.floor(position.x), y = math.floor(position.y) }
        local i = 0
        if not player.surface.name:find('platform') then
            for x = -radius - 2, radius + 2 do
                for y = -radius - 2, radius + 2 do
                    if x ^ 2 + y ^ 2 < radius ^ 2 then
                        local check_entities =
                            player.surface.find_entities_filtered
                            {
                                area = { { x + offset.x - 1, y + offset.y - 1 }, { x + offset.x, y + offset.y } }
                            }
                        if check_entities then
                            for _, entity in pairs(check_entities) do
                                if entity.name ~= 'character' then
                                    i = i + 1
                                end
                            end
                            if i >= 1 then
                                player.print('[Warp] There are entities nearby and warp cannot be created.', Color.warning)
                                return
                            end
                        end
                    end
                end
            end
        end

        local shared = p.shared
        local icon = p.icon
        if not icon then
            icon = { type = 'item', name = warp_item }
        end

        local new = p.frame.new_name.text

        if not validate_data(new, player, p) then
            return
        end

        local player_position = player.position
        p.spam = game.tick + 900
        Public.make_warp_point(player, player_position, player.surface, icon, player.force, new, shared)

        if p.shared == true then
            game.print('[Warp] ' .. player.name .. ' created warp: ' .. new, Color.success)
        elseif p.shared == false then
            player.print('[Warp] You created warp: ' .. new, Color.success)
        end
        Public.clear_player_table(player)
        Public.refresh_gui()
    end
)

Gui.on_click(
    edit_warp_func_name,
    function (event)
        local player = game.get_player(event.player_index)

        if not validate_player(player) then
            return
        end

        local p = get_player_data(player)

        local shared = p.shared
        local icon = p.icon
        if not icon then
            icon = { type = p.icon.type, name = p.icon.name }
        end

        local new = p.frame.new_name.text

        if not validate_data(new, player, p) then
            return
        end

        p.spam = game.tick + 900
        Public.edit_warp_point(player.surface, icon, player.force, p.edit_warp_name, new, shared)

        if p.shared == true then
            game.print('[Warp] ' .. player.name .. ' edited warp: ' .. new, Color.success)
        elseif p.shared == false then
            player.print('[Warp] You edited warp: ' .. new, Color.success)
        end
        Public.clear_player_table(player)
        Public.refresh_gui()
    end
)

Gui.on_elem_changed(
    warp_icon_name,
    function (event)
        local player = game.get_player(event.player_index)

        if not validate_player(player) then
            return
        end

        local element = event.element

        if not (element and element.valid) then
            return
        end

        local p = get_player_data(player)
        if not element.elem_value then
            return
        end

        p.icon = { type = element.elem_value.type or 'item', name = element.elem_value.name }
    end
)

local reassign_warp_button =
    Token.register(
        function (data)
            local player_index = data.player_index
            local player = game.get_player(player_index)
            if player and player.valid then
                Public.create_warp_button(player)
            end
        end
    )



Event.add(
    defines.events.on_tick,
    function ()
        if game.tick == 50 then
            Public.make_tag('Spawn', { x = 0, y = 0 }, true)
        end
    end
)

Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_player_created, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(
    ServerCommands.events.on_role_change,
    function (event)
        Task.set_timeout_in_ticks(10, reassign_warp_button, { player_index = event.player_index })
    end
)

Event.add(
    defines.events.on_player_removed,
    function (event)
        Public.remove_player(event.player_index)
    end
)

--- Sets surface name for warp system to use
---@param name string
function Public.set_surface_name(name)
    this.surface_name = name or 'nauvis'
end

return Public
