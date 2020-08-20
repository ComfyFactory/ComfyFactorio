local ic = require 'maps.mountain_fortress_v3.ic.table'
local Color = require 'utils.color_presets'
local Gui = require 'utils.gui'
local Tabs = require 'comfy_panel.main'

local Public = {}

--! Gui Frames
local save_button_name = Gui.uid_name()
local discard_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local main_toolbar_name = Gui.uid_name()

local function increment(t, k)
    t[k] = true
end

local function decrement(t, k)
    t[k] = nil
end

local function create_player_table(this, player)
    if not this.trust_system[player.index] then
        this.trust_system[player.index] = {}
    end
    return this.trust_system[player.index]
end

local function create_input_element(frame, type, value, items, index)
    if type == 'slider' then
        return frame.add({type = 'slider', value = value, minimum_value = 0, maximum_value = 1})
    end
    if type == 'boolean' then
        return frame.add({type = 'checkbox', state = value})
    end
    if type == 'dropdown' then
        return frame.add({type = 'drop-down', name = 'admin_player_select', items = items, selected_index = index})
    end
    return frame.add({type = 'text-box', text = value})
end

local function remove_main_frame(main_frame)
    Gui.remove_data_recursively(main_frame)
    main_frame.destroy()
end

local function draw_main_frame(player)
    local this = ic.get()
    local player_list = create_player_table(this, player)

    local main_frame =
        player.gui.screen.add(
        {
            type = 'frame',
            name = main_frame_name,
            caption = 'Car Settings',
            direction = 'vertical'
        }
    )
    main_frame.auto_center = true
    local main_frame_style = main_frame.style
    main_frame_style.width = 400
    main_frame_style.use_header_filler = true

    local inside_frame = main_frame.add {type = 'frame', style = 'inside_shallow_frame'}
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0
    local inside_table = inside_frame.add {type = 'table', column_count = 1}
    local inside_table_style = inside_table.style
    inside_table_style.vertical_spacing = 0

    inside_table.add({type = 'line'})

    local info_text = inside_table.add({type = 'label', caption = 'Trust List'})
    local info_text_style = info_text.style
    info_text_style.font = 'default-bold'
    info_text_style.padding = 0
    info_text_style.left_padding = 10
    info_text_style.horizontal_align = 'left'
    info_text_style.vertical_align = 'bottom'
    info_text_style.font_color = {0.55, 0.55, 0.99}

    inside_table.add({type = 'line'})

    local settings_frame = inside_table.add({type = 'scroll-pane'})
    local settings_style = settings_frame.style
    settings_style.vertically_squashable = true
    settings_style.bottom_padding = 5
    settings_style.left_padding = 5
    settings_style.right_padding = 5
    settings_style.top_padding = 5

    local settings_grid = settings_frame.add({type = 'table', column_count = 2})

    local accept_label =
        settings_grid.add(
        {
            type = 'label',
            caption = 'Add a trusted player.',
            tooltip = ''
        }
    )
    accept_label.tooltip = 'This will allow the given player to join your vehicle.'

    local players = game.connected_players

    local allowed = {}
    for _, p in pairs(players) do
        if not player_list[p.name] then
            allowed[#allowed + 1] = tostring(p.name)
        end
    end

    local accept_label_style = accept_label.style
    accept_label_style.horizontally_stretchable = true
    accept_label_style.height = 35
    accept_label_style.vertical_align = 'center'

    local name_input = settings_grid.add({type = 'flow'})
    local name_input_style = name_input.style
    name_input_style.height = 35
    name_input_style.vertical_align = 'center'
    local trusted_players_input = create_input_element(name_input, 'dropdown', false, allowed, 1)

    local denied = {}
    local deny_players_input
    if next(player_list) then
        for _, p in pairs(player_list) do
            denied[#denied + 1] = p
        end

        local deny_label =
            settings_grid.add(
            {
                type = 'label',
                caption = 'Remove a trusted player.',
                tooltip = ''
            }
        )
        deny_label.tooltip = 'This will instantly kick the player from your vehicle.'

        local deny_label_style = deny_label.style
        deny_label_style.horizontally_stretchable = true
        deny_label_style.height = 35
        deny_label_style.vertical_align = 'center'

        local deny_input = settings_grid.add({type = 'flow'})
        local deny_input_style = deny_input.style
        deny_input_style.height = 35
        deny_input_style.vertical_align = 'center'
        deny_players_input = create_input_element(deny_input, 'dropdown', false, denied, 1)
    end

    local data = {
        trusted_players_input = trusted_players_input
    }

    if deny_players_input then
        data.deny_players_input = deny_players_input
    end

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = discard_button_name, caption = 'Discard changes'})
    close_button.style = 'back_button'

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_button_name, caption = 'Save changes'})
    save_button.style = 'confirm_button'

    Gui.set_data(save_button, data)

    player.opened = main_frame
end

local function toggle(player, recreate)
    local screen = player.gui.screen
    local main_frame = screen[main_frame_name]

    if recreate and main_frame then
        local location = main_frame.location
        remove_main_frame(main_frame)
        draw_main_frame(player, location)
        return
    end
    if main_frame then
        remove_main_frame(main_frame)
        Tabs.comfy_panel_restore_left_gui(player)
    else
        Tabs.comfy_panel_clear_left_gui(player)
        draw_main_frame(player)
    end
end

local function add_toolbar(player, remove)
    if remove then
        if player.gui.top[main_toolbar_name] then
            player.gui.top[main_toolbar_name].destroy()
            return
        end
    end
    if player.gui.top[main_toolbar_name] then
        return
    end

    local tooltip = 'Control who may enter your vehicle.'
    local b =
        player.gui.top.add(
        {
            type = 'sprite-button',
            sprite = 'item/spidertron',
            name = main_toolbar_name,
            tooltip = tooltip
        }
    )
    b.style.font_color = {r = 0.11, g = 0.8, b = 0.44}
    b.style.font = 'heading-1'
    b.style.minimal_height = 38
    b.style.minimal_width = 38
    b.style.maximal_height = 38
    b.style.maximal_width = 38
    b.style.padding = 1
    b.style.margin = 0
end

local function remove_toolbar(player)
    local screen = player.gui.screen
    local main_frame = screen[main_frame_name]

    if main_frame and main_frame.valid then
        remove_main_frame(main_frame)
    end

    if player.gui.top[main_toolbar_name] then
        player.gui.top[main_toolbar_name].destroy()
        return
    end
end

Gui.on_click(
    save_button_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local this = ic.get()

        local player_list = this.trust_system[player.index]

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        local data = Gui.get_data(event.element)
        local trusted_players_input = data.trusted_players_input
        local deny_players_input = data.deny_players_input

        if frame and frame.valid then
            if trusted_players_input and trusted_players_input.valid and trusted_players_input.selected_index then
                local index = trusted_players_input.selected_index
                if not index then
                    return
                end

                local target = game.players[index]
                if not target or not target.valid then
                    return player.print('Target player was not valid.', Color.warning)
                end
                local name = target.name

                if target.index == player.index then
                    return player.print('Target player is not valid.', Color.warning)
                end
                if not player_list[name] then
                    player.print(name .. ' was added to your vehicle.', Color.info)
                    increment(this.trust_system[player.index], name)
                end
            end

            if deny_players_input and deny_players_input.valid and deny_players_input.selected_index then
                local index = deny_players_input.selected_index
                if not index then
                    return
                end
                local target = game.players[index]
                if not target or not target.valid then
                    player.print('Target player was not valid.', Color.warning)
                    return
                end
                local name = target.name

                if target.index == player.index then
                    return player.print('Target player is not valid.', Color.warning)
                end
                if player_list[name] then
                    player.print(name .. ' was removed from your vehicle.', Color.info)
                    decrement(this.trust_system[player.index], name)
                end
            end

            remove_main_frame(event.element)

            if player.gui.screen[main_frame_name] then
                toggle(player, true)
            end
        end
    end
)

Gui.on_click(
    discard_button_name,
    function(event)
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not player or not player.valid or not player.character then
            return
        end
        if frame and frame.valid then
            frame.destroy()
        end
    end
)

Gui.on_click(
    main_toolbar_name,
    function(event)
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not player or not player.valid or not player.character then
            return
        end

        if frame and frame.valid then
            frame.destroy()
        else
            draw_main_frame(player)
        end
    end
)

Public.draw_main_frame = draw_main_frame
Public.toggle = toggle
Public.add_toolbar = add_toolbar
Public.remove_toolbar = remove_toolbar

return Public
