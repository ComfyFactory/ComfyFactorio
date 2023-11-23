local Public = require 'modules.rpg.table'
local Gui = require 'utils.gui'
local P = require 'utils.player_modifiers'
local Session = require 'utils.datastore.session_data'

local settings_frame_name = Public.settings_frame_name
local close_settings_tooltip_frame = Public.close_settings_tooltip_frame
local settings_tooltip_frame = Public.settings_tooltip_frame
local settings_tooltip_name = Public.settings_tooltip_name
local save_button_name = Public.save_button_name
local discard_button_name = Public.discard_button_name
local spell_gui_button_name = Public.spell_gui_button_name
local spell_gui_frame_name = Public.spell_gui_frame_name
local enable_spawning_frame_name = Public.enable_spawning_frame_name
local spell1_button_name = Public.spell1_button_name
local spell2_button_name = Public.spell2_button_name
local spell3_button_name = Public.spell3_button_name
local spell4_button_name = Public.spell4_button_name
local spell5_button_name = Public.spell5_button_name
local spell6_button_name = Public.spell6_button_name

local settings_level = Public.gui_settings_levels

local comparators = {
    ['levels'] = function(a, b)
        return a.level < b.level
    end
}

local function get_comparator(sort_by)
    return comparators[sort_by]
end

local function create_input_element(frame, type, value, items, index, tooltip)
    if type == 'slider' then
        return frame.add({type = 'slider', value = value, minimum_value = 0, maximum_value = 1})
    end
    if type == 'boolean' then
        return frame.add({type = 'checkbox', state = value})
    end
    if type == 'label' then
        local label = frame.add({type = 'label', caption = value})
        label.style.font = 'default-listbox'
        label.tooltip = tooltip or ''
        return label
    end
    if type == 'dropdown' then
        return frame.add({type = 'drop-down', items = items, selected_index = index})
    end
    return frame.add({type = 'text-box', text = value})
end

local function create_custom_label_element(frame, sprite, localised_string, value, tooltip)
    local t = frame.add({type = 'flow'})
    t.add({type = 'label', caption = '[' .. sprite .. ']'})

    local heading = t.add({type = 'label', caption = localised_string})
    heading.tooltip = tooltip or ''
    heading.style.font = 'default-listbox'
    local subheading = t.add({type = 'label', caption = value})
    subheading.style.font = 'default-listbox'

    return subheading
end

local function create_bonus_label(player, setting_grid, caption, tooltip, modifier)
    local modifier_label =
        setting_grid.add(
        {
            type = 'label',
            caption = caption,
            tooltip = tooltip
        }
    )

    local modifier_label_style = modifier_label.style
    modifier_label_style.horizontally_stretchable = true
    modifier_label_style.height = 35
    modifier_label_style.vertical_align = 'center'

    local modifier_input = setting_grid.add({type = 'flow'})
    local modifier_input_style = modifier_input.style
    modifier_input_style.height = 35
    modifier_input_style.vertical_align = 'center'
    local status
    local bonus_modifier = P.get_single_disabled_modifier(player, modifier)
    if bonus_modifier then
        status = false
    else
        status = true
    end
    local modifier_gui_input = create_input_element(modifier_input, 'boolean', status)
    modifier_gui_input.tooltip = ({'rpg_settings.tooltip_check'})
    return modifier_gui_input
end

function Public.update_spell_gui_indicator(player)
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_t then
        return
    end
    local main_frame = player.gui.screen[spell_gui_frame_name]
    if not main_frame then
        return
    end
    local indicator = main_frame['spell_table']['indicator']
    indicator.sprite = 'virtual-signal/signal-' .. (rpg_t.enable_entity_spawn and 'green' or 'red')
end

function Public.update_spell_gui(player, spell_index)
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_t then
        return
    end
    local main_frame = player.gui.screen[spell_gui_frame_name]
    if not main_frame then
        return
    end
    local spell_table = main_frame['spell_table']
    if spell_index then
        if spell_index == 1 then
            rpg_t.dropdown_select_name = rpg_t.dropdown_select_name_1
            rpg_t.dropdown_select_index = rpg_t.dropdown_select_index_1
        elseif spell_index == 2 then
            rpg_t.dropdown_select_name = rpg_t.dropdown_select_name_2
            rpg_t.dropdown_select_index = rpg_t.dropdown_select_index_2
        elseif spell_index == 3 then
            rpg_t.dropdown_select_name = rpg_t.dropdown_select_name_3
            rpg_t.dropdown_select_index = rpg_t.dropdown_select_index_3
        elseif spell_index == 4 then
            rpg_t.dropdown_select_name = rpg_t.dropdown_select_name_4
            rpg_t.dropdown_select_index = rpg_t.dropdown_select_index_4
        elseif spell_index == 5 then
            rpg_t.dropdown_select_name = rpg_t.dropdown_select_name_5
            rpg_t.dropdown_select_index = rpg_t.dropdown_select_index_5
        elseif spell_index == 6 then
            rpg_t.dropdown_select_name = rpg_t.dropdown_select_name_6
            rpg_t.dropdown_select_index = rpg_t.dropdown_select_index_6
        end
    end

    local spell_1_data = Public.get_spell_by_name(rpg_t, rpg_t.dropdown_select_name_1)
    local spell_2_data = Public.get_spell_by_name(rpg_t, rpg_t.dropdown_select_name_2)
    local spell_3_data = Public.get_spell_by_name(rpg_t, rpg_t.dropdown_select_name_3)
    local spell_4_data = Public.get_spell_by_name(rpg_t, rpg_t.dropdown_select_name_4)
    local spell_5_data = Public.get_spell_by_name(rpg_t, rpg_t.dropdown_select_name_5)
    local spell_6_data = Public.get_spell_by_name(rpg_t, rpg_t.dropdown_select_name_6)

    spell_table[spell1_button_name].tooltip = spell_1_data and spell_1_data.name or '---'
    spell_table[spell1_button_name].sprite = spell_1_data and spell_1_data.sprite
    spell_table[spell2_button_name].tooltip = spell_2_data and spell_2_data.name or '---'
    spell_table[spell2_button_name].sprite = spell_2_data.sprite
    spell_table[spell3_button_name].tooltip = spell_3_data and spell_3_data.name or '---'
    spell_table[spell3_button_name].sprite = spell_3_data.sprite
    spell_table[spell4_button_name].tooltip = spell_4_data and spell_4_data.name or '---'
    spell_table[spell4_button_name].sprite = spell_4_data.sprite
    spell_table[spell5_button_name].tooltip = spell_5_data and spell_5_data.name or '---'
    spell_table[spell5_button_name].sprite = spell_5_data.sprite
    spell_table[spell6_button_name].tooltip = spell_6_data and spell_6_data.name or '---'
    spell_table[spell6_button_name].sprite = spell_6_data.sprite

    if rpg_t.dropdown_select_index_1 == rpg_t.dropdown_select_index then
        spell_table[spell1_button_name].enabled = false
        spell_table[spell1_button_name].number = 1
    else
        spell_table[spell1_button_name].enabled = true
        spell_table[spell1_button_name].number = nil
    end
    if rpg_t.dropdown_select_index_2 == rpg_t.dropdown_select_index then
        spell_table[spell2_button_name].enabled = false
        spell_table[spell2_button_name].number = 1
    else
        spell_table[spell2_button_name].enabled = true
        spell_table[spell2_button_name].number = nil
    end
    if rpg_t.dropdown_select_index_3 == rpg_t.dropdown_select_index then
        spell_table[spell3_button_name].enabled = false
        spell_table[spell3_button_name].number = 1
    else
        spell_table[spell3_button_name].enabled = true
        spell_table[spell3_button_name].number = nil
    end
    if rpg_t.dropdown_select_index_4 == rpg_t.dropdown_select_index then
        spell_table[spell4_button_name].enabled = false
        spell_table[spell4_button_name].number = 1
    else
        spell_table[spell4_button_name].enabled = true
        spell_table[spell4_button_name].number = nil
    end
    if rpg_t.dropdown_select_index_5 == rpg_t.dropdown_select_index then
        spell_table[spell5_button_name].enabled = false
        spell_table[spell5_button_name].number = 1
    else
        spell_table[spell5_button_name].enabled = true
        spell_table[spell5_button_name].number = nil
    end
    if rpg_t.dropdown_select_index_6 == rpg_t.dropdown_select_index then
        spell_table[spell6_button_name].enabled = false
        spell_table[spell6_button_name].number = 1
    else
        spell_table[spell6_button_name].enabled = true
        spell_table[spell6_button_name].number = nil
    end

    local active_spell = Public.get_spell_by_name(rpg_t, rpg_t.dropdown_select_name)
    spell_table['mana-cost'].caption = active_spell.mana_cost
    spell_table['mana'].caption = math.floor(rpg_t.mana)
    spell_table['maxmana'].caption = math.floor(rpg_t.mana_max)

    Public.update_spell_gui_indicator(player)
end

function Public.spell_gui_settings(player)
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_t then
        return
    end
    local spells, names = Public.get_all_spells_filtered(rpg_t)
    local main_frame = player.gui.screen[spell_gui_frame_name]
    if not main_frame or not main_frame.valid then
        main_frame =
            player.gui.screen.add(
            {
                type = 'frame',
                name = spell_gui_frame_name,
                caption = ({'rpg_settings.spell_name'}),
                direction = 'vertical'
            }
        )
        main_frame.auto_center = true
        local table = main_frame.add({type = 'table', column_count = 4, name = 'spell_table'})
        table.add(
            {
                type = 'sprite-button',
                sprite = 'item/raw-fish',
                name = enable_spawning_frame_name,
                tooltip = ({'rpg_settings.toggle_cast_spell_label'})
            }
        )
        table.add(
            {
                type = 'sprite-button',
                sprite = spells[rpg_t.dropdown_select_index_1].sprite,
                name = spell1_button_name,
                tooltip = names[rpg_t.dropdown_select_index_1] or '---'
            }
        )
        table.add(
            {
                type = 'sprite-button',
                sprite = spells[rpg_t.dropdown_select_index_2].sprite,
                name = spell2_button_name,
                tooltip = names[rpg_t.dropdown_select_index_2] or '---'
            }
        )
        table.add(
            {
                type = 'sprite-button',
                sprite = spells[rpg_t.dropdown_select_index_3].sprite,
                name = spell3_button_name,
                tooltip = names[rpg_t.dropdown_select_index_3] or '---'
            }
        )
        table.add({type = 'sprite-button', name = 'placeholder', enabled = false})
        table.add(
            {
                type = 'sprite-button',
                sprite = spells[rpg_t.dropdown_select_index_4].sprite,
                name = spell4_button_name,
                tooltip = names[rpg_t.dropdown_select_index_4] or '---'
            }
        )

        table.add(
            {
                type = 'sprite-button',
                sprite = spells[rpg_t.dropdown_select_index_5].sprite,
                name = spell5_button_name,
                tooltip = names[rpg_t.dropdown_select_index_5] or '---'
            }
        )
        table.add(
            {
                type = 'sprite-button',
                sprite = spells[rpg_t.dropdown_select_index_6].sprite,
                name = spell6_button_name,
                tooltip = names[rpg_t.dropdown_select_index_6] or '---'
            }
        )
        table.add({type = 'sprite-button', name = 'indicator', enabled = false})
        local b1 = table.add({type = 'sprite-button', name = 'mana-cost', tooltip = {'rpg_settings.mana_cost'}, caption = 0})
        local b2 = table.add({type = 'sprite-button', name = 'mana', tooltip = {'rpg_settings.mana'}, caption = 0})
        local b3 = table.add({type = 'sprite-button', name = 'maxmana', tooltip = {'rpg_settings.mana_max'}, caption = 0})
        b1.style.font_color = {r = 0.98, g = 0.98, b = 0.98}
        b2.style.font_color = {r = 0.98, g = 0.98, b = 0.98}
        b3.style.font_color = {r = 0.98, g = 0.98, b = 0.98}
        Public.update_spell_gui(player, nil)
    else
        main_frame.destroy()
    end
end

function Public.extra_settings(player)
    local rpg_extra = Public.get('rpg_extra')
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_t then
        return
    end
    local trusted = Session.get_trusted_table()

    local main_frame, inside_table = Gui.add_main_frame_with_toolbar(player, 'screen', settings_frame_name, settings_tooltip_name, nil, 'RPG Settings', true)
    if not main_frame then
        return
    end
    if not inside_table then
        return
    end

    local data = {}

    local main_frame_style = main_frame.style
    main_frame_style.width = 500
    main_frame.auto_center = true

    local info_text = inside_table.add({type = 'label', caption = ({'rpg_settings.info_text_label'})})
    local info_text_style = info_text.style
    info_text_style.font = 'default-bold'
    info_text_style.padding = 0
    info_text_style.left_padding = 10
    info_text_style.horizontal_align = 'left'
    info_text_style.vertical_align = 'bottom'
    info_text_style.font_color = {0.55, 0.55, 0.99}

    inside_table.add({type = 'line'})

    local scroll_pane = inside_table.add({type = 'scroll-pane'})
    local scroll_style = scroll_pane.style
    scroll_style.vertically_squashable = true
    scroll_style.maximal_height = 400
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
                caption = ({'rpg_settings.health_text_label'})
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
        health_bar_gui_input = create_input_element(health_bar_input, 'boolean', rpg_t.show_bars)
        health_bar_gui_input.tooltip = ({'rpg_settings.tooltip_check'})
        if not rpg_extra.enable_mana then
            health_bar_label.caption = ({'rpg_settings.health_only_text_label'})
        end
    end

    local reset_label =
        setting_grid.add(
        {
            type = 'label',
            caption = ({'rpg_settings.reset_text_label'}),
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

    if not rpg_t.reset then
        if not trusted[player.name] then
            reset_gui_input.enabled = false
            reset_gui_input.tooltip = ({'rpg_settings.not_trusted'})
            goto continue
        end
        if rpg_t.level < settings_level['reset_text_label'] then
            reset_gui_input.enabled = false
            reset_gui_input.tooltip = ({'rpg_settings.low_level', 50})
            reset_label.tooltip = ({'rpg_settings.low_level', 50})
        else
            reset_gui_input.enabled = true
            reset_gui_input.tooltip = ({'rpg_settings.reset_tooltip'})
            reset_label.tooltip = ({'rpg_settings.reset_tooltip'})
        end
    else
        reset_gui_input.enabled = false
        reset_gui_input.tooltip = ({'rpg_settings.used_up'})
    end
    data.reset_gui_input = reset_gui_input

    ::continue::

    data.character_build_distance_bonus = create_bonus_label(player, setting_grid, ({'rpg_settings.build_dist_label'}), ({'rpg_settings.build_dist_tooltip'}), 'character_build_distance_bonus')
    data.character_crafting_speed_modifier = create_bonus_label(player, setting_grid, ({'rpg_settings.craft_speed_label'}), ({'rpg_settings.craft_speed_tooltip'}), 'character_crafting_speed_modifier')
    data.character_health_bonus = create_bonus_label(player, setting_grid, ({'rpg_settings.health_bonus_label'}), ({'rpg_settings.health_bonus_tooltip'}), 'character_health_bonus')
    data.character_inventory_slots_bonus = create_bonus_label(player, setting_grid, ({'rpg_settings.inv_slots_label'}), ({'rpg_settings.inv_slots_tooltip'}), 'character_inventory_slots_bonus')
    data.character_item_drop_distance_bonus = create_bonus_label(player, setting_grid, ({'rpg_settings.drop_dist_label'}), ({'rpg_settings.drop_dist_tooltip'}), 'character_item_drop_distance_bonus')
    data.character_item_pickup_distance_bonus = create_bonus_label(player, setting_grid, ({'rpg_settings.reach_text_label'}), ({'rpg_settings.reach_text_tooltip'}), 'character_item_pickup_distance_bonus')
    data.character_loot_pickup_distance_bonus = create_bonus_label(player, setting_grid, ({'rpg_settings.loot_pickup_label'}), ({'rpg_settings.loot_pickup_tooltip'}), 'character_loot_pickup_distance_bonus')
    data.character_mining_speed_modifier = create_bonus_label(player, setting_grid, ({'rpg_settings.mining_speed_label'}), ({'rpg_settings.mining_speed_tooltip'}), 'character_mining_speed_modifier')
    data.character_reach_distance_bonus = create_bonus_label(player, setting_grid, ({'rpg_settings.char_reach_label'}), ({'rpg_settings.char_reach_tooltip'}), 'character_reach_distance_bonus')
    data.character_resource_reach_distance_bonus = create_bonus_label(player, setting_grid, ({'rpg_settings.resource_reach_label'}), ({'rpg_settings.resource_reach_tooltip'}), 'character_resource_reach_distance_bonus')
    data.character_running_speed_modifier = create_bonus_label(player, setting_grid, ({'rpg_settings.mov_speed_label'}), ({'rpg_settings.mov_speed_tooltip'}), 'character_running_speed_modifier')

    local enable_entity_gui_input
    local conjure_gui_input
    local spell_gui_input1
    local spell_gui_input2
    local spell_gui_input3
    local spell_gui_input4
    local spell_gui_input5
    local spell_gui_input6
    local explosive_bullets_gui_input
    local stone_path_gui_input
    local aoe_punch_gui_input
    local auto_allocate_gui_input

    if rpg_extra.enable_stone_path then
        local stone_path_label =
            setting_grid.add(
            {
                type = 'label',
                caption = ({'rpg_settings.stone_path_label'}),
                tooltip = ({'rpg_settings.stone_path_tooltip'})
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
        if rpg_t.stone_path then
            stone_path = rpg_t.stone_path
        else
            stone_path = false
        end
        stone_path_gui_input = create_input_element(stone_path_input, 'boolean', stone_path)

        if rpg_t.level < settings_level['stone_path_label'] then
            stone_path_gui_input.enabled = false
            stone_path_gui_input.tooltip = ({'rpg_settings.low_level', 20})
            stone_path_label.tooltip = ({'rpg_settings.low_level', 20})
        else
            stone_path_gui_input.enabled = true
            stone_path_gui_input.tooltip = ({'rpg_settings.tooltip_check'})
        end
    end

    if rpg_extra.enable_aoe_punch then
        local aoe_punch_label =
            setting_grid.add(
            {
                type = 'label',
                caption = ({'rpg_settings.aoe_punch_label'}),
                tooltip = ({'rpg_settings.aoe_punch_tooltip'})
            }
        )

        local aoe_punch_label_style = aoe_punch_label.style
        aoe_punch_label_style.horizontally_stretchable = true
        aoe_punch_label_style.height = 35
        aoe_punch_label_style.vertical_align = 'center'

        local aoe_punch_input = setting_grid.add({type = 'flow'})
        local aoe_punch_input_style = aoe_punch_input.style
        aoe_punch_input_style.height = 35
        aoe_punch_input_style.vertical_align = 'center'
        local aoe_punch
        if rpg_t.aoe_punch then
            aoe_punch = rpg_t.aoe_punch
        else
            aoe_punch = false
        end
        aoe_punch_gui_input = create_input_element(aoe_punch_input, 'boolean', aoe_punch)

        if rpg_extra.enable_aoe_punch_globally then
            aoe_punch_gui_input.state = true
            aoe_punch_gui_input.enabled = false
            aoe_punch_gui_input.tooltip = ({'rpg_settings.aoe_punch_globally'})
        else
            if rpg_t.level < settings_level['aoe_punch_label'] then
                aoe_punch_gui_input.enabled = false
                aoe_punch_gui_input.tooltip = ({'rpg_settings.low_level', 30})
            else
                aoe_punch_gui_input.enabled = true
                aoe_punch_gui_input.tooltip = ({'rpg_settings.tooltip_check'})
            end
        end
    end

    if rpg_extra.enable_explosive_bullets_globally then
        local explosive_bullets_label =
            setting_grid.add(
            {
                type = 'label',
                caption = ({'rpg_settings.explosive_bullets_label'}),
                tooltip = ({'rpg_settings.explosive_bullets_tooltip'})
            }
        )

        local explosive_bullets_label_style = explosive_bullets_label.style
        explosive_bullets_label_style.horizontally_stretchable = true
        explosive_bullets_label_style.height = 35
        explosive_bullets_label_style.vertical_align = 'center'

        local explosive_bullet_input = setting_grid.add({type = 'flow'})
        local explosive_bullet_input_style = explosive_bullet_input.style
        explosive_bullet_input_style.height = 35
        explosive_bullet_input_style.vertical_align = 'center'
        local explosive_bullets
        if rpg_t.explosive_bullets then
            explosive_bullets = rpg_t.explosive_bullets
        else
            explosive_bullets = false
        end
        explosive_bullets_gui_input = create_input_element(explosive_bullet_input, 'boolean', explosive_bullets)

        if rpg_t.level < settings_level['explosive_bullets_label'] then
            explosive_bullets_gui_input.enabled = false
            explosive_bullets_gui_input.tooltip = ({'rpg_settings.low_level', 50})
            explosive_bullets_label.tooltip = ({'rpg_settings.low_level', 50})
        else
            explosive_bullets_gui_input.enabled = true
            explosive_bullets_gui_input.tooltip = ({'rpg_settings.explosive_bullets_tooltip'})
        end
    end

    if rpg_extra.enable_mana then
        local mana_frame = inside_table.add({type = 'scroll-pane'})
        local mana_style = mana_frame.style
        mana_style.vertically_squashable = true
        mana_style.maximal_height = 400
        mana_style.bottom_padding = 5
        mana_style.left_padding = 5
        mana_style.right_padding = 5
        mana_style.top_padding = 5

        mana_frame.add({type = 'line'})

        local label = mana_frame.add({type = 'label', caption = ({'rpg_settings.mana_label'})})
        label.style.font = 'default-bold'
        label.style.padding = 0
        label.style.left_padding = 10
        label.style.horizontal_align = 'left'
        label.style.vertical_align = 'bottom'
        label.style.font_color = {0.55, 0.55, 0.99}

        mana_frame.add({type = 'line'})

        local setting_grid_2 = mana_frame.add({type = 'table', column_count = 2})

        local mana_grid = mana_frame.add({type = 'table', column_count = 2})

        local enable_entity =
            setting_grid_2.add(
            {
                type = 'label',
                caption = ({'rpg_settings.magic_label'}),
                tooltip = ({'rpg_settings.magic_tooltip'})
            }
        )

        local enable_entity_style = enable_entity.style
        enable_entity_style.horizontally_stretchable = true
        enable_entity_style.height = 35
        enable_entity_style.vertical_align = 'center'

        local entity_input = setting_grid_2.add({type = 'flow'})
        local entity_input_style = entity_input.style
        entity_input_style.height = 35
        entity_input_style.vertical_align = 'center'
        entity_input_style.horizontal_align = 'right'
        local entity_mod
        if rpg_t.enable_entity_spawn then
            entity_mod = rpg_t.enable_entity_spawn
        else
            entity_mod = false
        end
        enable_entity_gui_input = create_input_element(entity_input, 'boolean', entity_mod)

        if not trusted[player.name] then
            enable_entity_gui_input.enabled = false
            enable_entity_gui_input.tooltip = ({'rpg_settings.not_trusted'})
        else
            enable_entity_gui_input.enabled = true
            enable_entity_gui_input.tooltip = ({'rpg_settings.tooltip_check'})
        end

        local conjure_label =
            mana_grid.add(
            {
                type = 'label',
                caption = ({'rpg_settings.magic_spell'}),
                tooltip = 'Check the info button at upper right for more information\nOnly spells that you can cast are listed here.'
            }
        )

        local spells, names = Public.get_all_spells_filtered(rpg_t)

        local conjure_label_style = conjure_label.style
        conjure_label_style.horizontally_stretchable = true
        conjure_label_style.height = 35
        conjure_label_style.vertical_align = 'center'

        local conjure_input = mana_grid.add({type = 'flow'})
        local conjure_input_style = conjure_input.style
        conjure_input_style.height = 35
        conjure_input_style.vertical_align = 'center'
        local index = Public.get_spell_by_index(rpg_t, rpg_t.dropdown_select_name)
        if not index then
            index = rpg_t.dropdown_select_index
        end
        conjure_gui_input = create_input_element(conjure_input, 'dropdown', false, names, index)

        if not spells[rpg_t.dropdown_select_index_1] then
            rpg_t.dropdown_select_index_1 = 1
        end
        if not spells[rpg_t.dropdown_select_index_2] then
            rpg_t.dropdown_select_index_2 = 1
        end
        if not spells[rpg_t.dropdown_select_index_3] then
            rpg_t.dropdown_select_index_3 = 1
        end

        mana_frame.add({type = 'label', caption = {'rpg_settings.spell_gui_setup'}, tooltip = {'rpg_settings.spell_gui_tooltip'}})
        local spell_grid = mana_frame.add({type = 'table', column_count = 4, name = 'spell_grid_table'})
        local index1 = Public.get_spell_by_index(rpg_t, rpg_t.dropdown_select_name_1)
        if not index1 then
            index1 = rpg_t.dropdown_select_index_1
        end
        spell_gui_input1 = create_input_element(spell_grid, 'dropdown', false, names, index1)
        spell_gui_input1.style.maximal_width = 135
        local index2 = Public.get_spell_by_index(rpg_t, rpg_t.dropdown_select_name_2)
        if not index2 then
            index2 = rpg_t.dropdown_select_index_2
        end
        spell_gui_input2 = create_input_element(spell_grid, 'dropdown', false, names, index2)
        spell_gui_input2.style.maximal_width = 135
        local index3 = Public.get_spell_by_index(rpg_t, rpg_t.dropdown_select_name_3)
        if not index3 then
            index3 = rpg_t.dropdown_select_index_3
        end
        spell_gui_input3 = create_input_element(spell_grid, 'dropdown', false, names, index3)
        spell_gui_input3.style.maximal_width = 135
        spell_grid.add({type = 'sprite-button', name = spell_gui_button_name, sprite = 'item/raw-fish'})

        local index4 = Public.get_spell_by_index(rpg_t, rpg_t.dropdown_select_name_4)
        if not index4 then
            index4 = rpg_t.dropdown_select_index_4
        end
        spell_gui_input4 = create_input_element(spell_grid, 'dropdown', false, names, index4)
        spell_gui_input4.style.maximal_width = 135

        local index5 = Public.get_spell_by_index(rpg_t, rpg_t.dropdown_select_name_5)
        if not index5 then
            index5 = rpg_t.dropdown_select_index_5
        end
        spell_gui_input5 = create_input_element(spell_grid, 'dropdown', false, names, index5)
        spell_gui_input5.style.maximal_width = 135

        local index6 = Public.get_spell_by_index(rpg_t, rpg_t.dropdown_select_name_6)
        if not index6 then
            index6 = rpg_t.dropdown_select_index_6
        end
        spell_gui_input6 = create_input_element(spell_grid, 'dropdown', false, names, index6)
        spell_gui_input6.style.maximal_width = 135

        spell_grid.add({type = 'sprite-button', name = 'placeholder', enabled = false})
    end

    if rpg_extra.enable_auto_allocate then
        local allocate_frame = inside_table.add({type = 'scroll-pane'})
        local allocate_style = allocate_frame.style
        allocate_style.vertically_squashable = true
        allocate_style.bottom_padding = 5
        allocate_style.left_padding = 5
        allocate_style.right_padding = 5
        allocate_style.top_padding = 5

        allocate_frame.add({type = 'line'})

        local a_label = allocate_frame.add({type = 'label', caption = ({'rpg_settings.allocation_settings_label'})})
        a_label.style.font = 'default-bold'
        a_label.style.padding = 0
        a_label.style.left_padding = 10
        a_label.style.horizontal_align = 'left'
        a_label.style.vertical_align = 'bottom'
        a_label.style.font_color = {0.55, 0.55, 0.99}

        allocate_frame.add({type = 'line'})

        local allocate_grid = allocate_frame.add({type = 'table', column_count = 2})

        local allocate_label =
            allocate_grid.add(
            {
                type = 'label',
                caption = ({'rpg_settings.allocation_label'}),
                tooltip = ''
            }
        )
        allocate_label.tooltip = ({'rpg_settings.allocation_tooltip'})

        local names = Public.auto_allocate_nodes

        local allocate_label_style = allocate_label.style
        allocate_label_style.horizontally_stretchable = true
        allocate_label_style.height = 35
        allocate_label_style.vertical_align = 'center'

        local name_input = allocate_grid.add({type = 'flow'})
        local name_input_style = name_input.style
        name_input_style.height = 35
        name_input_style.vertical_align = 'center'
        auto_allocate_gui_input = create_input_element(name_input, 'dropdown', false, names, rpg_t.allocate_index)
    end

    if rpg_extra.enable_health_and_mana_bars then
        data.health_bar_gui_input = health_bar_gui_input
    end

    if rpg_extra.enable_mana then
        data.conjure_gui_input = conjure_gui_input
        data.spell_gui_input1 = spell_gui_input1
        data.spell_gui_input2 = spell_gui_input2
        data.spell_gui_input3 = spell_gui_input3
        data.spell_gui_input4 = spell_gui_input4
        data.spell_gui_input5 = spell_gui_input5
        data.spell_gui_input6 = spell_gui_input6
        data.enable_entity_gui_input = enable_entity_gui_input
    end

    if rpg_extra.enable_explosive_bullets_globally then
        data.explosive_bullets_gui_input = explosive_bullets_gui_input
    end

    if rpg_extra.enable_stone_path then
        data.stone_path_gui_input = stone_path_gui_input
    end

    if rpg_extra.enable_aoe_punch then
        data.aoe_punch_gui_input = aoe_punch_gui_input
    end

    if rpg_extra.enable_auto_allocate then
        data.auto_allocate_gui_input = auto_allocate_gui_input
    end

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = discard_button_name, caption = ({'rpg_settings.discard_changes'})})
    close_button.style = 'back_button'

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_button_name, caption = ({'rpg_settings.save_changes'})})
    save_button.style = 'confirm_button'

    Gui.set_data(save_button, data)

    if not main_frame or not main_frame.valid then
        return
    end
    main_frame.auto_center = true
    player.opened = main_frame
end

function Public.settings_tooltip(player)
    local rpg_extra = Public.get('rpg_extra')

    local main_frame, inside_table = Gui.add_main_frame_with_toolbar(player, 'center', settings_tooltip_frame, nil, close_settings_tooltip_frame, 'Spell info')
    if not main_frame then
        return
    end
    if not inside_table then
        return
    end

    local inside_table_style = inside_table.style
    inside_table_style.width = 530

    local info_text = inside_table.add({type = 'label', caption = ({'rpg_settings.spellbook_label'})})
    local info_text_style = info_text.style
    info_text_style.font = 'heading-2'
    info_text_style.padding = 0
    info_text_style.left_padding = 10
    info_text_style.horizontal_align = 'left'
    info_text_style.vertical_align = 'bottom'
    info_text_style.font_color = {0.55, 0.55, 0.99}

    if rpg_extra.enable_mana then
        local normal_spell_pane = inside_table.add({type = 'scroll-pane'})
        local ns = normal_spell_pane.style
        ns.vertically_squashable = true
        ns.bottom_padding = 5
        ns.left_padding = 5
        ns.right_padding = 5
        ns.top_padding = 5

        normal_spell_pane.add({type = 'line'})

        local entity_spells = normal_spell_pane.add({type = 'label', caption = ({'rpg_settings.entity_spells_label'})})
        local entity_spells_style = entity_spells.style
        entity_spells_style.font = 'heading-3'
        entity_spells_style.padding = 0
        entity_spells_style.left_padding = 10
        entity_spells_style.horizontal_align = 'left'
        entity_spells_style.font_color = {0.55, 0.55, 0.99}

        local normal_spell_grid = normal_spell_pane.add({type = 'table', column_count = 2})

        local spells = Public.rebuild_spells()

        local comparator = get_comparator('levels')
        table.sort(spells, comparator)

        for _, entity in pairs(spells) do
            if entity.enabled then
                local cooldown = (entity.cooldown / 60) .. 's'
                if entity.type == 'item' then
                    local text = '[item=' .. entity.entityName .. '] ▪️ Level: [font=default-bold]' .. entity.level .. '[/font] Mana: [font=default-bold]' .. entity.mana_cost .. '[/font].  Cooldown: [font=default-bold]' .. cooldown .. '[/font]'
                    create_input_element(normal_spell_grid, 'label', text, nil, nil, entity.tooltip)
                elseif entity.type == 'entity' then
                    local text = '[entity=' .. entity.entityName .. '] ▪️ Level: [font=default-bold]' .. entity.level .. '[/font] Mana: [font=default-bold]' .. entity.mana_cost .. '[/font].  Cooldown: [font=default-bold]' .. cooldown .. '[/font]'
                    create_input_element(normal_spell_grid, 'label', text, nil, nil, entity.tooltip)
                end
            end
        end

        local special_spell_pane = inside_table.add({type = 'scroll-pane'})
        local ss = special_spell_pane.style
        ss.vertically_squashable = true
        ss.bottom_padding = 5
        ss.left_padding = 5
        ss.right_padding = 5
        ss.top_padding = 5

        normal_spell_pane.add({type = 'line'})

        local special_spells = special_spell_pane.add({type = 'label', caption = ({'rpg_settings.special_spells_label'})})
        local special_spells_style = special_spells.style
        special_spells_style.font = 'heading-3'
        special_spells_style.padding = 0
        special_spells_style.left_padding = 10
        special_spells_style.horizontal_align = 'left'
        special_spells_style.font_color = {0.55, 0.55, 0.99}

        local special_spell_grid = special_spell_pane.add({type = 'table', column_count = 1})

        for _, entity in pairs(spells) do
            if entity.enabled then
                local cooldown = (entity.cooldown / 60) .. 's'
                if entity.type == 'special' then
                    local text = '▪️ Level: [font=default-bold]' .. entity.level .. '[/font] Mana: [font=default-bold]' .. entity.mana_cost .. '[/font]. Cooldown: [font=default-bold]' .. cooldown .. '[/font]'
                    create_custom_label_element(special_spell_grid, entity.special_sprite, entity.name, text, entity.tooltip)
                end
            end
        end
    end

    player.opened = main_frame
end
