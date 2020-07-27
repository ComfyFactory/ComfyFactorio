local RPG = require 'modules.rpg.table'
local Gui = require 'utils.gui'
local P = require 'player_modifiers'
local Session = require 'utils.session_data'
local reset_tooltip = 'ONE-TIME reset if you picked the wrong path (this will keep your points)'

local Public = {}

local settings_frame_name = RPG.settings_frame_name
local save_button_name = RPG.save_button_name
local discard_button_name = RPG.discard_button_name

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

function Public.extra_settings(player)
    local player_modifiers = P.get_table()
    local rpg_extra = RPG.get('rpg_extra')
    local rpg_t = RPG.get('rpg_t')
    local trusted = Session.get_trusted_table()
    local conjure_items = RPG.get_spells()
    local main_frame =
        player.gui.screen.add(
        {
            type = 'frame',
            name = settings_frame_name,
            caption = 'RPG Settings',
            direction = 'vertical'
        }
    )
    main_frame.auto_center = true

    local main_frame_style = main_frame.style
    main_frame_style.width = 500

    local info_text =
        main_frame.add({type = 'label', caption = 'Common RPG settings. These settings are per player basis.'})
    local info_text_style = info_text.style
    info_text_style.single_line = false
    info_text_style.bottom_padding = 5
    info_text_style.left_padding = 5
    info_text_style.right_padding = 5
    info_text_style.top_padding = 5
    info_text_style.width = 370

    local scroll_pane = main_frame.add({type = 'scroll-pane'})
    local scroll_style = scroll_pane.style
    scroll_style.vertically_squashable = true
    scroll_style.maximal_height = 800
    scroll_style.bottom_padding = 5
    scroll_style.left_padding = 5
    scroll_style.right_padding = 5
    scroll_style.top_padding = 5

    local setting_grid = scroll_pane.add({type = 'table', column_count = 2})

    local health_bar_gui_input
    if rpg_extra.enable_health_and_mana_bars then
        local health_bar_label =
            setting_grid.add(
            {
                type = 'label',
                caption = 'Show health/mana bar?'
            }
        )

        local style = health_bar_label.style
        style.horizontally_stretchable = true
        style.height = 35
        style.vertical_align = 'center'

        local health_bar_input = setting_grid.add({type = 'flow'})
        local input_style = health_bar_input.style
        input_style.height = 35
        input_style.vertical_align = 'center'
        health_bar_gui_input = create_input_element(health_bar_input, 'boolean', rpg_t[player.index].show_bars)
        health_bar_gui_input.tooltip = 'Checked = true\nUnchecked = false'
        if not rpg_extra.enable_mana then
            health_bar_label.caption = 'Show health bar?'
        end
    end

    local reset_label =
        setting_grid.add(
        {
            type = 'label',
            caption = 'Reset your skillpoints?',
            tooltip = ''
        }
    )

    local reset_label_style = reset_label.style
    reset_label_style.horizontally_stretchable = true
    reset_label_style.height = 35
    reset_label_style.vertical_align = 'center'

    local reset_input = setting_grid.add({type = 'flow'})
    local reset_input_style = reset_input.style
    reset_input_style.height = 35
    reset_input_style.vertical_align = 'center'
    local reset_gui_input = create_input_element(reset_input, 'boolean', false)

    if not rpg_t[player.index].reset then
        if not trusted[player.name] then
            reset_gui_input.enabled = false
            reset_gui_input.tooltip = 'Not trusted.\nChecked = true\nUnchecked = false'
            goto continue
        end
        if rpg_t[player.index].level <= 50 then
            reset_gui_input.enabled = false
            reset_gui_input.tooltip = 'Level requirement: 50\nChecked = true\nUnchecked = false'
            reset_label.tooltip = 'Level requirement: 50\nCan only reset once.'
        else
            reset_gui_input.enabled = true
            reset_gui_input.tooltip = reset_tooltip
            reset_label.tooltip = reset_tooltip
        end
    else
        reset_gui_input.enabled = false
        reset_gui_input.tooltip = 'All used up!'
    end

    ::continue::
    local magic_pickup_label =
        setting_grid.add(
        {
            type = 'label',
            caption = 'Enable item reach distance bonus?',
            tooltip = 'Don´t feeling like picking up others people loot?\nYou can toggle it here.'
        }
    )

    local magic_pickup_label_style = magic_pickup_label.style
    magic_pickup_label_style.horizontally_stretchable = true
    magic_pickup_label_style.height = 35
    magic_pickup_label_style.vertical_align = 'center'

    local magic_pickup_input = setting_grid.add({type = 'flow'})
    local magic_pickup_input_style = magic_pickup_input.style
    magic_pickup_input_style.height = 35
    magic_pickup_input_style.vertical_align = 'center'
    local reach_mod
    if
        player_modifiers.disabled_modifier[player.index] and
            player_modifiers.disabled_modifier[player.index].character_item_pickup_distance_bonus
     then
        reach_mod = not player_modifiers.disabled_modifier[player.index].character_item_pickup_distance_bonus
    else
        reach_mod = true
    end
    local magic_pickup_gui_input = create_input_element(magic_pickup_input, 'boolean', reach_mod)
    magic_pickup_gui_input.tooltip = 'Checked = true\nUnchecked = false'

    local movement_speed_label =
        setting_grid.add(
        {
            type = 'label',
            caption = 'Enable movement speed bonus?',
            tooltip = 'Don´t feeling like running like the flash?\nYou can toggle it here.'
        }
    )

    local movement_speed_label_style = movement_speed_label.style
    movement_speed_label_style.horizontally_stretchable = true
    movement_speed_label_style.height = 35
    movement_speed_label_style.vertical_align = 'center'

    local movement_speed_input = setting_grid.add({type = 'flow'})
    local movement_speed_input_style = movement_speed_input.style
    movement_speed_input_style.height = 35
    movement_speed_input_style.vertical_align = 'center'
    local speed_mod
    if
        player_modifiers.disabled_modifier[player.index] and
            player_modifiers.disabled_modifier[player.index].character_running_speed_modifier
     then
        speed_mod = not player_modifiers.disabled_modifier[player.index].character_running_speed_modifier
    else
        speed_mod = true
    end
    local movement_speed_gui_input = create_input_element(movement_speed_input, 'boolean', speed_mod)
    movement_speed_gui_input.tooltip = 'Checked = true\nUnchecked = false'

    local enable_entity_gui_input
    local conjure_gui_input
    local flame_boots_gui_input
    local stone_path_gui_input
    local one_punch_gui_input

    if rpg_extra.enable_stone_path then
        local stone_path_label =
            setting_grid.add(
            {
                type = 'label',
                caption = 'Enable stone-path when mining?',
                tooltip = 'Enabling this will automatically create stone-path when you mine.'
            }
        )

        local stone_path_label_style = stone_path_label.style
        stone_path_label_style.horizontally_stretchable = true
        stone_path_label_style.height = 35
        stone_path_label_style.vertical_align = 'center'

        local stone_path_input = setting_grid.add({type = 'flow'})
        local stone_path_input_style = stone_path_input.style
        stone_path_input_style.height = 35
        stone_path_input_style.vertical_align = 'center'
        local stone_path
        if rpg_t[player.index].stone_path then
            stone_path = rpg_t[player.index].stone_path
        else
            stone_path = false
        end
        stone_path_gui_input = create_input_element(stone_path_input, 'boolean', stone_path)

        if rpg_t[player.index].level <= 20 then
            stone_path_gui_input.enabled = false
            stone_path_gui_input.tooltip = 'Level requirement: 20\nChecked = true\nUnchecked = false'
            stone_path_label.tooltip = 'Level requirement: 20'
        else
            stone_path_gui_input.enabled = true
            stone_path_gui_input.tooltip = 'Checked = true\nUnchecked = false'
        end
    end

    if rpg_extra.enable_one_punch then
        local one_punch_label =
            setting_grid.add(
            {
                type = 'label',
                caption = 'Enable one-punch?',
                tooltip = 'Enabling this will have a chance of one-punching biters.'
            }
        )

        local one_punch_label_style = one_punch_label.style
        one_punch_label_style.horizontally_stretchable = true
        one_punch_label_style.height = 35
        one_punch_label_style.vertical_align = 'center'

        local one_punch_input = setting_grid.add({type = 'flow'})
        local one_punch_input_style = one_punch_input.style
        one_punch_input_style.height = 35
        one_punch_input_style.vertical_align = 'center'
        local one_punch
        if rpg_t[player.index].one_punch then
            one_punch = rpg_t[player.index].one_punch
        else
            one_punch = false
        end
        one_punch_gui_input = create_input_element(one_punch_input, 'boolean', one_punch)

        if rpg_extra.enable_one_punch_globally then
            one_punch_gui_input.state = true
            one_punch_gui_input.enabled = false
            one_punch_gui_input.tooltip = 'Enabled globally.'
        else
            if rpg_t[player.index].level <= 50 then
                one_punch_gui_input.enabled = false
                one_punch_gui_input.tooltip = 'Level requirement: 30\nChecked = true\nUnchecked = false'
            else
                one_punch_gui_input.enabled = true
                one_punch_gui_input.tooltip = 'Checked = true\nUnchecked = false'
            end
        end
    end

    if rpg_extra.enable_flame_boots then
        local flame_boots_label =
            setting_grid.add(
            {
                type = 'label',
                caption = 'Enable flame boots?',
                tooltip = 'When the bullets simply don´t bite.'
            }
        )

        local flame_boots_label_style = flame_boots_label.style
        flame_boots_label_style.horizontally_stretchable = true
        flame_boots_label_style.height = 35
        flame_boots_label_style.vertical_align = 'center'

        local flame_boots_input = setting_grid.add({type = 'flow'})
        local flame_boots_input_style = flame_boots_input.style
        flame_boots_input_style.height = 35
        flame_boots_input_style.vertical_align = 'center'
        local flame_mod
        if rpg_t[player.index].flame_boots then
            flame_mod = rpg_t[player.index].flame_boots
        else
            flame_mod = false
        end
        flame_boots_gui_input = create_input_element(flame_boots_input, 'boolean', flame_mod)

        if rpg_t[player.index].mana > 50 then
            if rpg_t[player.index].level <= 100 then
                flame_boots_gui_input.enabled = false
                flame_boots_gui_input.tooltip = 'Level requirement: 100\nChecked = true\nUnchecked = false'
                flame_boots_label.tooltip = 'Level requirement: 100'
            else
                flame_boots_gui_input.enabled = true
                flame_boots_gui_input.tooltip = 'Checked = true\nUnchecked = false'
            end
        else
            flame_boots_gui_input.enabled = false
            flame_boots_gui_input.tooltip = 'Not enough mana.\nChecked = true\nUnchecked = false'
        end
    end
    if rpg_extra.enable_mana then
        local enable_entity =
            setting_grid.add(
            {
                type = 'label',
                caption = 'Enable spawning with raw-fish?',
                tooltip = 'When simply constructing items is not enough.\nNOTE! Use Raw-fish to cast spells.'
            }
        )

        local enable_entity_style = enable_entity.style
        enable_entity_style.horizontally_stretchable = true
        enable_entity_style.height = 35
        enable_entity_style.vertical_align = 'center'

        local entity_input = setting_grid.add({type = 'flow'})
        local entity_input_style = entity_input.style
        entity_input_style.height = 35
        entity_input_style.vertical_align = 'center'
        local entity_mod
        if rpg_t[player.index].enable_entity_spawn then
            entity_mod = rpg_t[player.index].enable_entity_spawn
        else
            entity_mod = false
        end
        enable_entity_gui_input = create_input_element(entity_input, 'boolean', entity_mod)

        local conjure_label =
            setting_grid.add(
            {
                type = 'label',
                caption = 'Select what entity to spawn',
                tooltip = ''
            }
        )

        local names = {}

        for _, items in pairs(conjure_items) do
            names[#names + 1] = items.name
        end

        local conjure_label_style = conjure_label.style
        conjure_label_style.horizontally_stretchable = true
        conjure_label_style.height = 35
        conjure_label_style.vertical_align = 'center'

        local conjure_input = setting_grid.add({type = 'flow'})
        local conjure_input_style = conjure_input.style
        conjure_input_style.height = 35
        conjure_input_style.vertical_align = 'center'
        conjure_gui_input =
            create_input_element(conjure_input, 'dropdown', false, names, rpg_t[player.index].dropdown_select_index)

        for _, entity in pairs(conjure_items) do
            if entity.type == 'item' then
                conjure_label.tooltip =
                    conjure_label.tooltip ..
                    '[item=' ..
                        entity.obj_to_create ..
                            '] requires ' .. entity.mana_cost .. ' mana to cast. Level: ' .. entity.level .. '\n'
            elseif entity.type == 'entity' then
                conjure_label.tooltip =
                    conjure_label.tooltip ..
                    '[entity=' ..
                        entity.obj_to_create ..
                            '] requires ' .. entity.mana_cost .. ' mana to cast. Level: ' .. entity.level .. '\n'
            elseif entity.type == 'special' then
                conjure_label.tooltip =
                    conjure_label.tooltip ..
                    entity.name .. ' requires ' .. entity.mana_cost .. ' mana to cast. Level: ' .. entity.level .. '\n'
            end
        end
    end

    local data = {
        reset_gui_input = reset_gui_input,
        magic_pickup_gui_input = magic_pickup_gui_input,
        movement_speed_gui_input = movement_speed_gui_input
    }

    if rpg_extra.enable_health_and_mana_bars then
        data.health_bar_gui_input = health_bar_gui_input
    end

    if rpg_extra.enable_mana then
        data.conjure_gui_input = conjure_gui_input
        data.enable_entity_gui_input = enable_entity_gui_input
    end

    if rpg_extra.enable_flame_boots then
        data.flame_boots_gui_input = flame_boots_gui_input
    end

    if rpg_extra.enable_stone_path then
        data.stone_path_gui_input = stone_path_gui_input
    end

    if rpg_extra.enable_one_punch then
        data.one_punch_gui_input = one_punch_gui_input
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

return Public
