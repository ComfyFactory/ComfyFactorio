local ComfyGui = require 'utils.gui'
local Session = require 'utils.datastore.session_data'
local P = require 'utils.player_modifiers'
local Gui = require 'utils.gui'
local Color = require 'utils.color_presets'
local SpamProtection = require 'utils.spam_protection'

--RPG Modules
local Public = require 'modules.rpg.table'
local classes = Public.classes

--RPG Settings
local experience_levels = Public.experience_levels

--RPG Frames
local main_frame_name = Public.main_frame_name
local draw_main_frame_name = Public.draw_main_frame_name
local close_main_frame_name = Public.close_main_frame_name
local settings_button_name = Public.settings_button_name
local settings_tooltip_frame = Public.settings_tooltip_frame
local close_settings_tooltip_frame = Public.close_settings_tooltip_frame
local settings_tooltip_name = Public.settings_tooltip_name
local settings_frame_name = Public.settings_frame_name
local discard_button_name = Public.discard_button_name
local save_button_name = Public.save_button_name
local enable_spawning_frame_name = Public.enable_spawning_frame_name
local spell_gui_button_name = Public.spell_gui_button_name
local spell_gui_frame_name = Public.spell_gui_frame_name
local spell1_button_name = Public.spell1_button_name
local spell2_button_name = Public.spell2_button_name
local spell3_button_name = Public.spell3_button_name

local round = math.round
local floor = math.floor

function Public.draw_gui_char_button(player)
    if ComfyGui.get_mod_gui_top_frame() then
        local b =
            ComfyGui.add_mod_button(
            player,
            {
                type = 'sprite-button',
                name = draw_main_frame_name,
                caption = '[RPG]',
                tooltip = 'RPG',
                style = Gui.button_style
            }
        )
        if b then
            b.style.font_color = {165, 165, 165}
            b.style.font = 'heading-3'
            b.style.minimal_height = 38
            b.style.maximal_height = 38
            b.style.minimal_width = 50
            b.style.padding = 0
            b.style.margin = 0
        end
    else
        if player.gui.top[draw_main_frame_name] then
            return
        end
        local b =
            player.gui.top.add(
            {
                type = 'sprite-button',
                name = draw_main_frame_name,
                caption = '[RPG]',
                tooltip = 'RPG',
                style = Gui.button_style
            }
        )
        b.style.font_color = {0, 0, 0}
        b.style.font = 'heading-3'
        b.style.minimal_height = 38
        b.style.maximal_height = 38
        b.style.minimal_width = 50
        b.style.padding = 0
        b.style.margin = 0
    end
end

function Public.update_char_button(player)
    local rpg_t = Public.get_value_from_player(player.index)

    if ComfyGui.get_mod_gui_top_frame() then
        if not ComfyGui.get_button_flow(player)[draw_main_frame_name] or not ComfyGui.get_button_flow(player)[draw_main_frame_name].valid then
            Public.draw_gui_char_button(player)
        end
        if rpg_t.points_left > 0 then
            ComfyGui.get_button_flow(player)[draw_main_frame_name].style.font_color = {245, 0, 0}
        else
            ComfyGui.get_button_flow(player)[draw_main_frame_name].style.font_color = {0, 0, 0}
        end
    else
        if not player.gui.top[draw_main_frame_name] then
            Public.draw_gui_char_button(player)
        end
        if rpg_t.points_left > 0 then
            player.gui.top[draw_main_frame_name].style.font_color = {245, 0, 0}
        else
            player.gui.top[draw_main_frame_name].style.font_color = {0, 0, 0}
        end
    end
end

local function get_class(player)
    local rpg_t = Public.get_value_from_player(player.index)
    local average = (rpg_t.strength + rpg_t.magicka + rpg_t.dexterity + rpg_t.vitality) / 4
    local high_attribute = 0
    local high_attribute_name = ''
    for _, attribute in pairs({'strength', 'magicka', 'dexterity', 'vitality'}) do
        if rpg_t[attribute] > high_attribute then
            high_attribute = rpg_t[attribute]
            high_attribute_name = attribute
        end
    end
    if high_attribute < average + average * 0.25 then
        high_attribute_name = 'engineer'
    end
    return classes[high_attribute_name]
end

local function add_gui_description(element, value, width, tooltip, min_height, max_height)
    local e = element.add({type = 'label', caption = value})
    e.tooltip = tooltip or ''
    e.style.single_line = false
    e.style.maximal_width = width
    e.style.minimal_width = width
    e.style.maximal_height = max_height or 40
    e.style.minimal_height = min_height or 38
    e.style.font = 'default-bold'
    e.style.font_color = {175, 175, 200}
    e.style.horizontal_align = 'right'
    e.style.vertical_align = 'center'
    return e
end

local function add_gui_stat(element, value, width, tooltip, name, color)
    local e = element.add({type = 'sprite-button', name = name or nil, caption = value})
    e.tooltip = tooltip or ''
    e.style.maximal_width = width
    e.style.minimal_width = width
    e.style.maximal_height = 38
    e.style.minimal_height = 38
    e.style.font = 'default-bold'
    e.style.horizontal_align = 'center'
    e.style.vertical_align = 'center'
    e.style.font_color = color or {222, 222, 222}
    return e
end

local function add_gui_increase_stat(element, name, player)
    local rpg_t = Public.get_value_from_player(player.index)
    local sprite = 'virtual-signal/signal-red'
    local symbol = '✚'
    if rpg_t.points_left <= 0 then
        sprite = 'virtual-signal/signal-black'
    end
    local e = element.add({type = 'sprite-button', name = name, caption = symbol, sprite = sprite})
    e.style.maximal_height = 38
    e.style.minimal_height = 38
    e.style.maximal_width = 38
    e.style.minimal_width = 38
    e.style.font = 'default-large-semibold'
    e.style.font_color = {0, 0, 0}
    e.style.horizontal_align = 'center'
    e.style.vertical_align = 'center'
    e.style.padding = 0
    e.style.margin = 0
    e.tooltip = ({'rpg_gui.allocate_info', tostring(Public.points_per_level)})

    return e
end

local function add_separator(element, width)
    local e = element.add({type = 'line'})
    e.style.maximal_width = width
    e.style.minimal_width = width
    e.style.minimal_height = 12
    return e
end

local function remove_target_frame(target_frame)
    Gui.remove_data_recursively(target_frame)
    target_frame.destroy()
end

local function remove_main_frame(main_frame, screen)
    Gui.remove_data_recursively(main_frame)
    main_frame.destroy()

    local settings_frame = screen[settings_frame_name]
    if settings_frame and settings_frame.valid then
        remove_target_frame(settings_frame)
    end
end

local function toggle_state(player, label, modifier)
    if label and label.valid then
        if not label.state then
            P.disable_single_modifier(player, modifier, true)
            P.update_player_modifiers(player)
        elseif label.state then
            P.disable_single_modifier(player, modifier, false)
            P.update_player_modifiers(player)
        end
    end
end

local function draw_main_frame(player, location)
    if not player.character then
        return
    end

    local main_frame, inside_frame = Gui.add_main_frame_with_toolbar(player, 'screen', main_frame_name, settings_button_name, close_main_frame_name, 'RPG')

    if location then
        main_frame.location = location
    else
        if ComfyGui.get_mod_gui_top_frame() then
            main_frame.location = {x = 1, y = 55}
        else
            main_frame.location = {x = 1, y = 45}
        end
    end

    local data = {}
    local rpg_extra = Public.get('rpg_extra')
    local rpg_t = Public.get_value_from_player(player.index)

    local scroll_pane =
        inside_frame.add {
        type = 'scroll-pane',
        vertical_scroll_policy = 'never',
        horizontal_scroll_policy = 'never'
    }
    local scroll_style = scroll_pane.style
    scroll_style.vertically_squashable = true
    scroll_style.bottom_padding = 2
    scroll_style.left_padding = 2
    scroll_style.right_padding = 2
    scroll_style.top_padding = 2

    --!top table
    local main_table = scroll_pane.add({type = 'table', column_count = 2})
    local player_name = add_gui_stat(main_table, player.name, 200, ({'rpg_gui.player_name', player.name}))
    player_name.style.font_color = player.chat_color
    player_name.style.font = 'default-large-bold'
    local rank = add_gui_stat(main_table, get_class(player), 200, ({'rpg_gui.class_info', get_class(player)}))
    rank.style.font = 'default-large-bold'

    add_separator(scroll_pane, 400)

    --!sub top table
    local scroll_table = scroll_pane.add({type = 'table', column_count = 4})
    scroll_table.style.cell_padding = 1

    add_gui_description(scroll_table, ({'rpg_gui.level_name'}), 80)
    if rpg_extra.level_limit_enabled then
        local level_tooltip = ({'rpg_gui.level_limit', Public.level_limit_exceeded(player, true)})
        add_gui_stat(scroll_table, rpg_t.level, 80, level_tooltip)
    else
        add_gui_stat(scroll_table, rpg_t.level, 80)
    end

    add_gui_description(scroll_table, ({'rpg_gui.experience_name'}), 100)
    local exp_gui = add_gui_stat(scroll_table, floor(rpg_t.xp), 125, ({'rpg_gui.gain_info_tooltip'}))
    data.exp_gui = exp_gui

    add_gui_description(scroll_table, ' ', 75)
    add_gui_description(scroll_table, ' ', 75)

    add_gui_description(scroll_table, ({'rpg_gui.next_level_name'}), 100)
    add_gui_stat(scroll_table, experience_levels[rpg_t.level + 1], 125, ({'rpg_gui.gain_info_tooltip'}))

    add_separator(scroll_pane, 400)

    --!bottom table
    local bottom_table = scroll_pane.add({type = 'table', column_count = 2})
    local left_bottom_table = bottom_table.add({type = 'table', column_count = 3})
    left_bottom_table.style.cell_padding = 1
    local w0 = 2
    local w1 = 85
    local w2 = 63

    local duped_items = rpg_t.duped_items or 0

    add_gui_description(left_bottom_table, ({'rpg_gui.strength_name'}), w1, ({'rpg_gui.strength_tooltip'}))
    add_gui_stat(left_bottom_table, rpg_t.strength, w2, ({'rpg_gui.strength_tooltip'}))
    add_gui_increase_stat(left_bottom_table, 'strength', player)

    add_gui_description(left_bottom_table, ({'rpg_gui.magic_name'}), w1, ({'rpg_gui.magic_tooltip'}))
    add_gui_stat(left_bottom_table, rpg_t.magicka, w2, ({'rpg_gui.magic_tooltip'}))
    add_gui_increase_stat(left_bottom_table, 'magicka', player)

    add_gui_description(left_bottom_table, ({'rpg_gui.dexterity_name'}), w1, ({'rpg_gui.dexterity_tooltip', duped_items}))
    add_gui_stat(left_bottom_table, rpg_t.dexterity, w2, ({'rpg_gui.dexterity_tooltip', duped_items}))

    add_gui_increase_stat(left_bottom_table, 'dexterity', player)

    add_gui_description(left_bottom_table, ({'rpg_gui.vitality_name'}), w1, ({'rpg_gui.vitality_tooltip'}))
    add_gui_stat(left_bottom_table, rpg_t.vitality, w2, ({'rpg_gui.vitality_tooltip'}))
    add_gui_increase_stat(left_bottom_table, 'vitality', player)

    add_gui_description(left_bottom_table, ({'rpg_gui.points_to_dist'}), w1)
    add_gui_stat(left_bottom_table, rpg_t.points_left, w2, nil, nil, {200, 0, 0})
    add_gui_description(left_bottom_table, ' ', w2)

    add_gui_description(left_bottom_table, ' ', 40)
    add_gui_description(left_bottom_table, ' ', 40)
    add_gui_description(left_bottom_table, ' ', 40)

    add_gui_description(left_bottom_table, ({'rpg_gui.life_name'}), w1, ({'rpg_gui.life_tooltip'}))
    local health_gui = add_gui_stat(left_bottom_table, floor(player.character.health), w2, ({'rpg_gui.life_increase'}))
    data.health = health_gui
    add_gui_stat(left_bottom_table, floor(player.character.prototype.max_health + player.character_health_bonus + player.force.character_health_bonus), w2, ({'rpg_gui.life_maximum'}))

    local shield = 0
    local shield_max = 0
    local shield_desc_tip = ({'rpg_gui.shield_no_shield'})
    local shield_tip = ({'rpg_gui.shield_no_armor'})
    local shield_max_tip = shield_tip

    local i = player.character.get_inventory(defines.inventory.character_armor)
    if not i.is_empty() then
        if i[1].grid then
            shield = floor(i[1].grid.shield)
            shield_max = floor(i[1].grid.max_shield)
            shield_desc_tip = ({'rpg_gui.shield_tooltip'})
            shield_tip = ({'rpg_gui.shield_current'})
            shield_max_tip = ({'rpg_gui.shield_max'})
            add_gui_description(left_bottom_table, ({'rpg_gui.shield_name'}), w1, shield_desc_tip)
            local shield_gui = add_gui_stat(left_bottom_table, shield, w2, shield_tip)
            local shield_max_gui = add_gui_stat(left_bottom_table, shield_max, w2, shield_max_tip)

            data.shield = shield_gui
            data.shield_max = shield_max_gui
        end
    else
        add_gui_description(left_bottom_table, ({'rpg_gui.shield_name'}), w1, shield_desc_tip)
        add_gui_stat(left_bottom_table, shield, w2, shield_tip)
        add_gui_stat(left_bottom_table, shield_max, w2, shield_max_tip)
    end

    if rpg_extra.enable_mana then
        local mana = rpg_t.mana
        local mana_max = rpg_t.mana_max

        local mana_tip = ({'rpg_gui.mana_tooltip'})
        add_gui_description(left_bottom_table, ({'rpg_gui.mana_name'}), w1, mana_tip)
        local mana_regen_tip = ({'rpg_gui.mana_regen_current'})
        local mana_max_regen_tip
        if rpg_t.mana_max >= rpg_extra.mana_limit then
            mana_max_regen_tip = ({'rpg_gui.mana_max_limit'})
        else
            mana_max_regen_tip = ({'rpg_gui.mana_max'})
        end
        local mana_gui = add_gui_stat(left_bottom_table, mana, w2, mana_regen_tip)
        local mana_max_gui = add_gui_stat(left_bottom_table, mana_max, w2, mana_max_regen_tip)
        data.mana = mana_gui
        data.mana_max = mana_max_gui
    end

    local right_bottom_table = bottom_table.add({type = 'table', column_count = 3})
    right_bottom_table.style.cell_padding = 1

    add_gui_description(right_bottom_table, ' ', w0)
    add_gui_description(right_bottom_table, ({'rpg_gui.mining_name'}), w1)
    local mining_speed_value = round((player.force.manual_mining_speed_modifier + player.character_mining_speed_modifier + 1) * 100) .. '%'
    add_gui_stat(right_bottom_table, mining_speed_value, w2)

    add_gui_description(right_bottom_table, ' ', w0)
    add_gui_description(right_bottom_table, ({'rpg_gui.slot_name'}), w1)
    local slot_bonus_value = '+ ' .. round(player.force.character_inventory_slots_bonus + player.character_inventory_slots_bonus)
    add_gui_stat(right_bottom_table, slot_bonus_value, w2)

    add_gui_description(right_bottom_table, ' ', w0)
    add_gui_description(right_bottom_table, ({'rpg_gui.melee_name'}), w1)
    local melee_damage_value = round(100 * (1 + Public.get_melee_modifier(player))) .. '%'
    local melee_damage_tooltip
    if rpg_extra.enable_aoe_punch then
        melee_damage_tooltip = ({
            'rpg_gui.aoe_punch_chance',
            Public.get_life_on_hit(player),
            Public.get_aoe_punch_chance(player),
            Public.get_extra_following_robots(player)
        })
    else
        melee_damage_tooltip = ({'rpg_gui.aoe_punch_disabled'})
    end
    add_gui_stat(right_bottom_table, melee_damage_value, w2, melee_damage_tooltip)

    add_gui_description(right_bottom_table, '', w0, '', nil, 5)
    add_gui_description(right_bottom_table, '', w0, '', nil, 5)
    add_gui_description(right_bottom_table, '', w0, '', nil, 5)

    local reach_distance_value = '+ ' .. (player.force.character_reach_distance_bonus + player.character_reach_distance_bonus)
    local reach_bonus_tooltip = ({
        'rpg_gui.bonus_tooltip',
        player.character_reach_distance_bonus,
        player.character_build_distance_bonus,
        player.character_item_drop_distance_bonus,
        player.character_loot_pickup_distance_bonus,
        player.character_item_pickup_distance_bonus,
        player.character_resource_reach_distance_bonus,
        Public.get_magicka(player)
    })

    add_gui_description(right_bottom_table, ' ', w0)
    add_gui_description(right_bottom_table, ({'rpg_gui.reach_distance'}), w1)
    add_gui_stat(right_bottom_table, reach_distance_value, w2, reach_bonus_tooltip)

    add_gui_description(right_bottom_table, '', w0, '', nil, 10)
    add_gui_description(right_bottom_table, '', w0, '', nil, 10)
    add_gui_description(right_bottom_table, '', w0, '', nil, 10)

    add_gui_description(right_bottom_table, ' ', w0)
    add_gui_description(right_bottom_table, ({'rpg_gui.crafting_speed'}), w1)
    local crafting_speed_value = round((player.force.manual_crafting_speed_modifier + player.character_crafting_speed_modifier + 1) * 100) .. '%'
    add_gui_stat(right_bottom_table, crafting_speed_value, w2)

    add_gui_description(right_bottom_table, ' ', w0)
    add_gui_description(right_bottom_table, ({'rpg_gui.running_speed'}), w1)
    local running_speed_value = round((player.force.character_running_speed_modifier + player.character_running_speed_modifier + 1) * 100) .. '%'
    add_gui_stat(right_bottom_table, running_speed_value, w2)

    add_gui_description(right_bottom_table, ' ', w0)
    add_gui_description(right_bottom_table, ({'rpg_gui.health_bonus_name'}), w1)
    local health_bonus_value = '+ ' .. round((player.force.character_health_bonus + player.character_health_bonus))
    local health_tooltip = ({'rpg_gui.health_tooltip', Public.get_heal_modifier(player)})
    add_gui_stat(right_bottom_table, health_bonus_value, w2, health_tooltip)

    add_gui_description(right_bottom_table, ' ', w0)

    if rpg_extra.enable_mana then
        add_gui_description(right_bottom_table, ({'rpg_gui.mana_bonus'}), w1)
        local mana_bonus_value = '+ ' .. (floor(Public.get_mana_modifier(player) * 10) / 10)
        local mana_bonus_tooltip = ({
            'rpg_gui.mana_regen_bonus',
            (floor(Public.get_mana_modifier(player) * 10) / 10)
        })
        add_gui_stat(right_bottom_table, mana_bonus_value, w2, mana_bonus_tooltip)
    end

    add_separator(scroll_pane, 400)

    Public.update_char_button(player)
    data.frame = main_frame

    Gui.set_data(main_frame, data)
end

function Public.draw_level_text(player)
    if not player.character then
        return
    end

    local rpg_t = Public.get_value_from_player(player.index)

    if not rpg_t then
        return
    end

    if rpg_t.text then
        rendering.destroy(rpg_t.text)
        rpg_t.text = nil
    end

    local players = game.connected_players
    if #players == 0 then
        return
    end

    rpg_t.text =
        rendering.draw_text {
        text = 'lvl ' .. rpg_t.level,
        surface = player.surface,
        target = player.character,
        target_offset = {0, -3.25},
        color = {
            r = player.color.r * 0.6 + 0.25,
            g = player.color.g * 0.6 + 0.25,
            b = player.color.b * 0.6 + 0.25,
            a = 1
        },
        players = players,
        scale = 1.00,
        font = 'default-large-semibold',
        alignment = 'center',
        scale_with_zoom = false
    }
end

function Public.toggle(player, recreate)
    local screen = player.gui.screen
    local main_frame = screen[main_frame_name]

    if recreate and main_frame then
        local location = main_frame.location
        remove_main_frame(main_frame, screen)
        draw_main_frame(player, location)
        return
    end
    if main_frame then
        remove_main_frame(main_frame, screen)
    else
        ComfyGui.clear_all_active_frames(player)
        draw_main_frame(player)
    end
end

function Public.remove_frame(player)
    local screen = player.gui.screen
    local main_frame = screen[main_frame_name]

    if main_frame then
        remove_main_frame(main_frame, screen)
    end
end

function Public.clear_settings_frames(player)
    local screen = player.gui.screen
    local center = player.gui.center

    local setting_tooltip_frame = center[settings_tooltip_frame]
    local setting_frame = screen[settings_frame_name]

    if setting_tooltip_frame then
        remove_target_frame(setting_tooltip_frame)
    end
    if setting_frame then
        remove_target_frame(setting_frame)
    end
end

local toggle = Public.toggle
Public.remove_main_frame = remove_main_frame

Gui.on_click(
    draw_main_frame_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'RPG Main Frame')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        toggle(player)
    end
)

Gui.on_click(
    save_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'RPG Save Button')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[settings_frame_name]
        local data = Gui.get_data(event.element)
        if not data then
            return
        end

        local health_bar_gui_input = data.health_bar_gui_input
        local reset_gui_input = data.reset_gui_input
        local conjure_gui_input = data.conjure_gui_input
        local spell_gui_input1 = data.spell_gui_input1
        local spell_gui_input2 = data.spell_gui_input2
        local spell_gui_input3 = data.spell_gui_input3
        local explosive_bullets_gui_input = data.explosive_bullets_gui_input
        local enable_entity_gui_input = data.enable_entity_gui_input
        local stone_path_gui_input = data.stone_path_gui_input
        local aoe_punch_gui_input = data.aoe_punch_gui_input
        local auto_allocate_gui_input = data.auto_allocate_gui_input

        local character_build_distance_bonus = data.character_build_distance_bonus
        local character_crafting_speed_modifier = data.character_crafting_speed_modifier
        local character_health_bonus = data.character_health_bonus
        local character_inventory_slots_bonus = data.character_inventory_slots_bonus
        local character_item_drop_distance_bonus = data.character_item_drop_distance_bonus
        local character_item_pickup_distance_bonus = data.character_item_pickup_distance_bonus
        local character_loot_pickup_distance_bonus = data.character_loot_pickup_distance_bonus
        local character_mining_speed_modifier = data.character_mining_speed_modifier
        local character_reach_distance_bonus = data.character_reach_distance_bonus
        local character_resource_reach_distance_bonus = data.character_resource_reach_distance_bonus
        local character_running_speed_modifier = data.character_running_speed_modifier

        local rpg_t = Public.get_value_from_player(player.index)

        if frame and frame.valid then
            if auto_allocate_gui_input and auto_allocate_gui_input.valid and auto_allocate_gui_input.selected_index then
                rpg_t.allocate_index = auto_allocate_gui_input.selected_index
            end

            if aoe_punch_gui_input and aoe_punch_gui_input.valid then
                if not aoe_punch_gui_input.state then
                    rpg_t.aoe_punch = false
                elseif aoe_punch_gui_input.state then
                    rpg_t.aoe_punch = true
                end
            end

            if stone_path_gui_input and stone_path_gui_input.valid then
                if not stone_path_gui_input.state then
                    rpg_t.stone_path = false
                elseif stone_path_gui_input.state then
                    rpg_t.stone_path = true
                end
            end

            if enable_entity_gui_input and enable_entity_gui_input.valid then
                if not enable_entity_gui_input.state then
                    rpg_t.enable_entity_spawn = false
                elseif enable_entity_gui_input.state then
                    rpg_t.enable_entity_spawn = true
                end
            end

            if explosive_bullets_gui_input and explosive_bullets_gui_input.valid then
                if not explosive_bullets_gui_input.state then
                    rpg_t.explosive_bullets = false
                elseif explosive_bullets_gui_input.state then
                    rpg_t.explosive_bullets = true
                end
            end

            toggle_state(player, character_build_distance_bonus, 'character_build_distance_bonus')
            toggle_state(player, character_crafting_speed_modifier, 'character_crafting_speed_modifier')
            toggle_state(player, character_health_bonus, 'character_health_bonus')
            toggle_state(player, character_inventory_slots_bonus, 'character_inventory_slots_bonus')
            toggle_state(player, character_item_drop_distance_bonus, 'character_item_drop_distance_bonus')
            toggle_state(player, character_item_pickup_distance_bonus, 'character_item_pickup_distance_bonus')
            toggle_state(player, character_loot_pickup_distance_bonus, 'character_loot_pickup_distance_bonus')
            toggle_state(player, character_mining_speed_modifier, 'character_mining_speed_modifier')
            toggle_state(player, character_reach_distance_bonus, 'character_reach_distance_bonus')
            toggle_state(player, character_resource_reach_distance_bonus, 'character_resource_reach_distance_bonus')
            toggle_state(player, character_running_speed_modifier, 'character_running_speed_modifier')

            local spell_index = nil

            if conjure_gui_input and conjure_gui_input.valid and conjure_gui_input.selected_index then
                local items = conjure_gui_input.items
                local spell_name = items[conjure_gui_input.selected_index]
                spell_name = spell_name and spell_name[1] or spell_name

                if spell_name then
                    rpg_t.dropdown_select_name = spell_name
                end

                rpg_t.dropdown_select_index = conjure_gui_input.selected_index
            end
            if spell_gui_input1 and spell_gui_input1.valid and spell_gui_input1.selected_index then
                local items = spell_gui_input1.items
                local spell_name = items[spell_gui_input1.selected_index]
                spell_name = spell_name and spell_name[1] or spell_name

                if spell_name then
                    if rpg_t.dropdown_select_name == rpg_t.dropdown_select_name_1 and rpg_t.dropdown_select_name_1 ~= spell_name then
                        rpg_t.dropdown_select_name = spell_name
                        rpg_t.dropdown_select_index = spell_gui_input1.selected_index
                        spell_index = 1
                    end

                    rpg_t.dropdown_select_name_1 = spell_name
                end

                rpg_t.dropdown_select_index_1 = spell_gui_input1.selected_index
            end
            if spell_gui_input2 and spell_gui_input2.valid and spell_gui_input2.selected_index then
                local items = spell_gui_input2.items
                local spell_name = items[spell_gui_input2.selected_index]
                spell_name = spell_name and spell_name[1] or spell_name

                if spell_name then
                    if rpg_t.dropdown_select_name == rpg_t.dropdown_select_name_2 and rpg_t.dropdown_select_name_2 ~= spell_name then
                        rpg_t.dropdown_select_name = spell_name
                        rpg_t.dropdown_select_index = spell_gui_input2.selected_index
                        spell_index = 2
                    end

                    rpg_t.dropdown_select_name_2 = spell_name
                end

                rpg_t.dropdown_select_index_2 = spell_gui_input2.selected_index
            end
            if spell_gui_input3 and spell_gui_input3.valid and spell_gui_input3.selected_index then
                local items = spell_gui_input3.items
                local spell_name = items[spell_gui_input3.selected_index]
                spell_name = spell_name and spell_name[1] or spell_name

                if spell_name then
                    if rpg_t.dropdown_select_name == rpg_t.dropdown_select_name_3 and rpg_t.dropdown_select_name_3 ~= spell_name then
                        rpg_t.dropdown_select_name = spell_name
                        rpg_t.dropdown_select_index = spell_gui_input3.selected_index
                        spell_index = 3
                    end

                    rpg_t.dropdown_select_name_3 = spell_name
                end

                rpg_t.dropdown_select_index_3 = spell_gui_input3.selected_index
            end

            if player.gui.screen[spell_gui_frame_name] then
                Public.update_spell_gui(player, spell_index)
            end

            if reset_gui_input and reset_gui_input.valid and reset_gui_input.state then
                if not rpg_t.reset then
                    rpg_t.allocate_index = 1
                    rpg_t.reset = true
                    Public.rpg_reset_player(player, true)
                end
            end
            if health_bar_gui_input and health_bar_gui_input.valid then
                if not health_bar_gui_input.state then
                    rpg_t.show_bars = false
                    Public.update_health(player)
                    Public.update_mana(player)
                elseif health_bar_gui_input.state then
                    rpg_t.show_bars = true
                    Public.update_health(player)
                    Public.update_mana(player)
                end
            end

            remove_target_frame(event.element)

            if player.gui.screen[main_frame_name] then
                toggle(player, true)
            end
        end
    end
)

Gui.on_click(
    discard_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'RPG Discard Button')
        if is_spamming then
            return
        end
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[settings_frame_name]
        if not player or not player.valid or not player.character then
            return
        end
        if frame and frame.valid then
            Gui.remove_data_recursively(frame)
            frame.destroy()
        end
    end
)

Gui.on_click(
    close_main_frame_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'RPG Close Button')
        if is_spamming then
            return
        end
        local player = event.player
        local screen = player.gui.screen
        if not player or not player.valid or not player.character then
            return
        end

        local main_frame = screen[main_frame_name]
        if main_frame and main_frame.valid then
            remove_target_frame(main_frame)
        end
        local settings_frame = screen[settings_frame_name]
        if settings_frame and settings_frame.valid then
            remove_target_frame(settings_frame)
        end
    end
)

Gui.on_click(
    close_settings_tooltip_frame,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'RPG Close Button')
        if is_spamming then
            return
        end
        local player = event.player
        local center = player.gui.center
        if not player or not player.valid or not player.character then
            return
        end

        local main_frame = center[settings_tooltip_frame]
        if main_frame and main_frame.valid then
            remove_target_frame(main_frame)
        end
    end
)

Gui.on_click(
    settings_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'RPG Settings Button')
        if is_spamming then
            return
        end
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[settings_frame_name]
        if not player or not player.valid or not player.character then
            return
        end

        if not Public.check_is_surface_valid(player) then
            return
        end

        if frame and frame.valid then
            Gui.remove_data_recursively(frame)
            frame.destroy()
        else
            ComfyGui.clear_all_center_frames(player)
            Public.extra_settings(player)
        end
    end
)

Gui.on_click(
    settings_tooltip_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'RPG Settings Tooltip Button')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        if not Public.check_is_surface_valid(player) then
            return
        end

        local center = player.gui.center
        local main_frame = center[settings_tooltip_frame]
        if main_frame and main_frame.valid then
            remove_target_frame(main_frame)
        else
            ComfyGui.clear_all_center_frames(player)
            ComfyGui.clear_all_screen_frames(player)
            Public.settings_tooltip(player)
        end
    end
)

Gui.on_click(
    enable_spawning_frame_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'RPG Enable Spawning')
        if is_spamming then
            return
        end
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[spell_gui_frame_name]
        if not player or not player.valid or not player.character then
            return
        end

        if not Session.get_trusted_player(player) then
            player.print({'rpg_settings.not_trusted'}, Color.fail)
            return player.play_sound({path = 'utility/cannot_build', volume_modifier = 0.75})
        end

        if frame and frame.valid then
            local rpg_t = Public.get_value_from_player(player.index)
            if not rpg_t.enable_entity_spawn then
                player.print({'rpg_settings.cast_spell_enabled_label'}, Color.success)
                player.play_sound({path = 'utility/armor_insert', volume_modifier = 0.75})
                rpg_t.enable_entity_spawn = true
            else
                player.print({'rpg_settings.cast_spell_disabled_label'}, Color.warning)
                player.play_sound({path = 'utility/cannot_build', volume_modifier = 0.75})
                rpg_t.enable_entity_spawn = false
            end
            Public.update_spell_gui_indicator(player)
        end
    end
)

Gui.on_click(
    spell_gui_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'RPG Spell Gui')
        if is_spamming then
            return
        end
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[spell_gui_frame_name]
        if not player or not player.valid or not player.character then
            return
        end

        if not Public.check_is_surface_valid(player) then
            return
        end

        if frame and frame.valid then
            Gui.remove_data_recursively(frame)
            frame.destroy()
        else
            Public.spell_gui_settings(player)
        end
    end
)

Gui.on_click(
    spell1_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'RPG Spell_1 Button')
        if is_spamming then
            return
        end
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[spell_gui_frame_name]
        if not player or not player.valid or not player.character then
            return
        end

        if not Public.check_is_surface_valid(player) then
            return
        end

        if frame and frame.valid then
            Public.update_spell_gui(player, 1)
        end
    end
)

Gui.on_click(
    spell2_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'RPG Spell_2 Button')
        if is_spamming then
            return
        end
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[spell_gui_frame_name]
        if not player or not player.valid or not player.character then
            return
        end

        if not Public.check_is_surface_valid(player) then
            return
        end

        if frame and frame.valid then
            Public.update_spell_gui(player, 2)
        end
    end
)

Gui.on_click(
    spell3_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'RPG Spell_3 Button')
        if is_spamming then
            return
        end
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[spell_gui_frame_name]
        if not player or not player.valid or not player.character then
            return
        end

        if not Public.check_is_surface_valid(player) then
            return
        end

        if frame and frame.valid then
            Public.update_spell_gui(player, 3)
        end
    end
)

ComfyGui.screen_to_bypass(spell_gui_frame_name)

return Public
