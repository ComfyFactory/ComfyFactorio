local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local Color = require 'utils.color_presets'
local RPG = require 'modules.rpg.main'
local IC_Gui = require 'maps.mountain_fortress_v3.ic.gui'
local IC = require 'maps.mountain_fortress_v3.ic.functions'
local IC_Minimap = require 'maps.mountain_fortress_v3.ic.minimap'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Gui = require 'utils.gui'
local SpamProtection = require 'utils.spam_protection'
local Polls = require 'utils.gui.poll'
local BottomFrame = require 'utils.gui.bottom_frame'
local Core = require 'utils.core'

local format_number = require 'util'.format_number

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()

local spectate_button_name = Gui.uid_name()
local spectate_main_frame_name = Gui.uid_name()
local spectate_ready_to_button_name = Gui.uid_name()
local spectate_close_button_name = Gui.uid_name()
local spectate_surface_picker_name = Gui.uid_name()
local mystical_chest_button_name = Gui.uid_name()

local floor = math.floor
local on_player_changed_surface

local function validate_entity(entity)
    if not (entity and entity.valid) then
        return false
    end

    return true
end

local function get_player_gui_settings(player)
    local player_gui_settings = Public.get('player_gui_settings')
    if not player_gui_settings[player.index] then
        player_gui_settings[player.index] =
        {
            info_button = true,
            wd = true,
            info_detailed = true
        }
    end
    return player_gui_settings[player.index]
end

local function remove_player_gui_settings(player_index)
    local player_gui_settings = Public.get('player_gui_settings')
    player_gui_settings[player_index] = nil
end

local function get_top_frame(player)
    if Gui.get_mod_gui_top_frame() then
        return Gui.get_button_flow(player)[main_frame_name]
    else
        return player.gui.top[main_frame_name]
    end
end

local function get_top_frame_custom(player, name)
    if Gui.get_mod_gui_top_frame() then
        return Gui.get_button_flow(player)[name]
    else
        return player.gui.top[name]
    end
end

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

local function create_button(player)
    if Gui.get_mod_gui_top_frame() then
        local b =
            Gui.add_mod_button(
                player,
                {
                    type = 'sprite-button',
                    name = main_button_name,
                    sprite = 'utility/expand',
                    tooltip = 'Shows statistics!',
                    style = Gui.button_style
                }
            )
        if b then
            b.style.font_color = { 165, 165, 165 }
            b.style.font = 'default-semibold'
            b.style.minimal_height = 36
            b.style.maximal_height = 36
            b.style.minimal_width = 40
            b.style.padding = -2
        end
    else
        local b =
            player.gui.top.add(
                {
                    type = 'sprite-button',
                    name = main_button_name,
                    sprite = 'utility/expand',
                    tooltip = 'Shows statistics!',
                    style = Gui.button_style
                }
            )
        b.style.minimal_height = 38
        b.style.maximal_height = 38
    end
end

local function spectate_button(player)
    if get_top_frame_custom(player, spectate_button_name) then
        return
    end


    if Public.get('final_battle') then
        return
    end

    local tooltip = 'Spectate!\nThis will kill your character.'
    local sprite = 'utility/create_ghost_on_entity_death_modifier_icon'

    if Gui.get_mod_gui_top_frame() then
        local b =
            Gui.add_mod_button(
                player,
                {
                    type = 'sprite-button',
                    name = spectate_button_name,
                    sprite = sprite,
                    tooltip = tooltip,
                    style = Gui.button_style
                }
            )
        if b then
            b.style.font_color = { 165, 165, 165 }
            b.style.font = 'default-semibold'
            b.style.minimal_height = 36
            b.style.maximal_height = 36
            b.style.minimal_width = 40
            b.style.padding = -2
        end
    else
        local b =
            player.gui.top.add
            {
                type = 'sprite-button',
                name = spectate_button_name,
                sprite = sprite,
                tooltip = tooltip,
                style = Gui.button_style
            }

        b.style.maximal_height = 38
    end
end

local function spacer(frame)
    local flow = frame.add({ type = 'flow' })
    flow.style.minimal_height = 2
end

local function add_line(frame)
    frame.add({ type = 'line', direction = 'vertical' })
end

local function create_spectate_main_frame(player, redraw)
    local main_player_frame = player.gui.screen[spectate_main_frame_name]
    if main_player_frame then
        Gui.remove_data_recursively(main_player_frame)
        main_player_frame.destroy()
        if not redraw then
            return
        end
    end

    local data = {}

    local frame = player.gui.screen.add { type = 'frame', name = spectate_main_frame_name, caption = { 'spectate.title' }, direction = 'vertical' }
    if Gui.get_mod_gui_top_frame() then
        frame.location = { x = 0, y = 67 }
    else
        frame.location = { x = 1, y = 45 }
    end
    frame.style.maximal_height = 700
    frame.style.minimal_width = 300
    frame.style.maximal_width = 400
    local spectate_table = frame.add { type = 'table', column_count = 2 }
    spectate_table.style.horizontally_stretchable = true

    local spectate_left_flow = spectate_table.add({ type = 'flow' })
    spectate_left_flow.style.horizontal_align = 'left'
    spectate_left_flow.style.horizontally_stretchable = true

    if player.character ~= nil then
        spectate_left_flow.add({ type = 'label', caption = { 'spectate.ready-to-spectate' }, tooltip = { 'spectate.ready-to-spectate-tooltip' } })
        spectate_left_flow.style.font = 'heading-1'
    else
        spectate_left_flow.add({ type = 'label', caption = { 'spectate.ready-to-play' }, tooltip = { 'spectate.ready-to-play-tooltip' } })
        spectate_left_flow.style.font = 'heading-1'
    end

    add_line(frame)

    local spectate_right_flow = spectate_table.add({ type = 'flow' })
    spectate_right_flow.style.horizontal_align = 'right'
    spectate_right_flow.style.horizontally_stretchable = true

    if player.character ~= nil then
        data.spectate_hold_button = spectate_right_flow.add({ type = 'button', name = spectate_ready_to_button_name, caption = { 'spectate.spectate-button' }, tooltip = { 'spectate.spectate-button-tooltip' } })
    else
        local spectate = Public.get('spectate')

        if spectate and spectate[player.index] and spectate[player.index].delay and spectate[player.index].delay > game.tick then
            local cooldown = floor((spectate[player.index].delay - game.tick) / 60) + 1 .. ' seconds!'
            data.spectate_hold_button = spectate_right_flow.add({ type = 'button', enabled = false, name = spectate_ready_to_button_name, caption = cooldown, tooltip = { 'spectate.hold-button-tooltip', cooldown } })
        else
            data.spectate_hold_button = spectate_right_flow.add({ type = 'button', name = spectate_ready_to_button_name, caption = { 'spectate.play-button' }, tooltip = { 'spectate.play-button-tooltip' } })
        end
    end

    if player.character == nil then
        spacer(frame)

        local spectate_surface_picker_table = frame.add { type = 'table', column_count = 2 }
        spectate_surface_picker_table.style.horizontally_stretchable = true

        local surface_picker_left_flow = spectate_surface_picker_table.add({ type = 'flow' })
        surface_picker_left_flow.style.horizontal_align = 'left'
        surface_picker_left_flow.style.horizontally_stretchable = true

        surface_picker_left_flow.add({ type = 'label', caption = { 'spectate.surface_picker' }, tooltip = { 'spectate.surface_picker_tooltip' } })
        add_line(frame)
        local surface_picker_right_flow = spectate_surface_picker_table.add({ type = 'flow' })
        surface_picker_right_flow.style.horizontal_align = 'right'
        surface_picker_right_flow.style.horizontally_stretchable = true

        local surfaces = {}
        for _, surface in pairs(game.surfaces) do
            if surface.name ~= 'nauvis' then
                table.insert(surfaces, surface.name)
            end
        end

        data.surface_picker_label = surface_picker_right_flow.add({ name = spectate_surface_picker_name, type = 'drop-down', items = surfaces, selected_index = 1 })
        spacer(frame)
    end

    -- warn players
    spacer(frame)
    add_line(frame)
    spacer(frame)

    local close = frame.add({ type = 'button', name = spectate_close_button_name, caption = 'Close' })
    close.style.horizontally_stretchable = true
    Gui.set_data(frame, data)
end

local function create_main_frame(player)
    local label
    local line
    if get_top_frame_custom(player, 'wave_defense') then
        get_top_frame_custom(player, 'wave_defense').visible = true
    end

    local frame

    if Gui.get_mod_gui_top_frame() then
        frame =
            Gui.add_mod_button(
                player,
                {
                    type = 'frame',
                    name = main_frame_name,
                }
            )
        frame.location = { x = 1, y = 38 }
        frame.style.minimal_height = 36
        frame.style.maximal_height = 36
    else
        frame = player.gui.top.add({ type = 'frame', name = main_frame_name })
        frame.location = { x = 1, y = 40 }
        frame.style.minimal_height = 38
        frame.style.maximal_height = 38
    end

    frame.style.top_padding = 6
    frame.style.right_padding = 12
    frame.style.bottom_padding = 5
    frame.style.left_padding = 12

    label = frame.add({ type = 'label', caption = ' ', name = 'label' })
    label.style.font_color = { r = 0.88, g = 0.88, b = 0.88 }
    label.style.font = 'default-bold'

    label = frame.add({ type = 'label', caption = ' ', name = 'global_pool' })
    label.style.font_color = { r = 0.88, g = 0.88, b = 0.88 }
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({ type = 'line', direction = 'vertical' })
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({ type = 'label', caption = ' ', name = 'scrap_mined' })
    label.style.font_color = { r = 0.88, g = 0.88, b = 0.88 }
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({ type = 'line', direction = 'vertical' })
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({ type = 'label', caption = ' ', name = 'pickaxe_tier' })
    label.style.font_color = { r = 0.88, g = 0.88, b = 0.88 }
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({ type = 'line', direction = 'vertical' })
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({ type = 'label', caption = ' ', name = 'biters_killed' })
    label.style.font_color = { r = 0.88, g = 0.88, b = 0.88 }
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({ type = 'line', direction = 'vertical' })
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({ type = 'label', caption = ' ', name = 'landmine' })
    label.style.font_color = { r = 0.88, g = 0.88, b = 0.88 }
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({ type = 'line', direction = 'vertical' })
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({ type = 'label', caption = ' ', name = 'flame_turret' })
    label.style.font_color = { r = 0.88, g = 0.88, b = 0.88 }
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({ type = 'line', direction = 'vertical' })
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({ type = 'label', caption = ' ', name = 'train_upgrade_contribution' })
    label.style.font_color = { r = 0.88, g = 0.88, b = 0.88 }
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({ type = 'line', direction = 'vertical' })
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({ type = 'label', caption = ' ', name = 'defense_enabled' })
    label.style.font_color = { r = 0.88, g = 0.88, b = 0.88 }
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({ type = 'line', direction = 'vertical' })
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({ type = 'label', caption = ' ', name = mystical_chest_button_name })
    label.style.font_color = { r = 0.88, g = 0.88, b = 0.88 }
    label.style.font = 'default-bold'
    label.style.right_padding = 4
end

local function hide_all_gui(player)
    if Gui.get_mod_gui_top_frame() then
        for _, child in pairs(player.gui.top.mod_gui_top_frame.mod_gui_inner_frame.children) do
            if child.name ~= spectate_button_name and child.name ~= 'minimap_button' and child.name ~= 'wave_defense' then
                child.visible = false
            end
        end
    else
        for _, child in pairs(player.gui.top.children) do
            if child.name ~= spectate_button_name and child.name ~= 'minimap_button' and child.name ~= 'wave_defense' then
                child.visible = false
            end
        end
    end
end

local function show_all_gui(player)
    if Gui.get_mod_gui_top_frame() then
        for _, child in pairs(player.gui.top.mod_gui_top_frame.mod_gui_inner_frame.children) do
            if child.name ~= spectate_button_name and child.name ~= 'minimap_button' then
                child.visible = true
            end
        end
    else
        for _, child in pairs(player.gui.top.children) do
            if child.name ~= spectate_button_name and child.name ~= 'minimap_button' then
                child.visible = true
            end
        end
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if not player then
        return
    end

    if not get_top_frame_custom(player, spectate_button_name) then
        spectate_button(player)
    end

    if not get_top_frame_custom(player, main_button_name) then
        create_button(player)
    end
end

local function changed_surface(player)
    local main_toggle_button_name = Gui.main_toggle_button_name
    local poll_button = Polls.main_button_name
    local rpg_button = RPG.draw_main_frame_name
    local rpg_frame = RPG.main_frame_name
    local rpg_settings = RPG.settings_frame_name
    local main = Public.get('locomotive')
    if not main or not main.valid then return end
    local icw_locomotive = Public.get('icw_locomotive')
    if not icw_locomotive then
        return
    end

    local wagon_surface = icw_locomotive.surface
    local main_toggle_button = get_top_frame_custom(player, main_toggle_button_name)
    local info_button = get_top_frame_custom(player, main_button_name)
    local wd = get_top_frame_custom(player, 'wave_defense')
    local info_detailed = get_top_frame_custom(player, main_frame_name)
    local spectate = get_top_frame_custom(player, spectate_button_name)
    local minimap_button = get_top_frame_custom(player, 'minimap_button')
    local rpg_b = get_top_frame_custom(player, rpg_button)
    local poll_b = get_top_frame_custom(player, poll_button)
    local rpg_f = player.gui.screen[rpg_frame]
    local rpg_s = player.gui.screen[rpg_settings]
    local diff = get_top_frame_custom(player, Difficulty.top_button_name)
    local charging = get_top_frame_custom(player, 'charging_station')
    local charging_frame = BottomFrame.get_section(player, 'charging_station')
    local frame = get_top_frame(player)
    local spell_gui_frame_name = RPG.spell_gui_frame_name
    local spell_cast_buttons = player.gui.screen[spell_gui_frame_name]

    local gui_data = get_player_gui_settings(player)

    if main_toggle_button and main_toggle_button.sprite == 'utility/expand_dots' then
        goto no_gui
    end

    if info_button then
        info_button.tooltip = ({ 'gui.info_tooltip' })
        info_button.sprite = 'utility/expand'
    end

    if not main then
        return
    end
    if not main.valid then
        return
    end

    if not wagon_surface then
        return
    end
    if not wagon_surface.valid then
        return
    end

    if (player.physical_surface == main.surface and player.physical_position.x < 700) then
        local minimap = player.gui.left.icw_main_frame
        if main_toggle_button and not main_toggle_button.visible then
            main_toggle_button.visible = true
        end
        if minimap and minimap.visible then
            minimap.visible = false
        end
        if rpg_b and not rpg_b.visible then
            rpg_b.visible = true
        end
        if poll_b and not poll_b.visible then
            poll_b.visible = true
        end
        if minimap_button and not minimap_button.visible then
            minimap_button.visible = false
        end
        if spell_cast_buttons and not spell_cast_buttons.visible then
            spell_cast_buttons.visible = true
        end
        if diff and not diff.visible then
            diff.visible = true
        end

        if wd then
            wd.visible = gui_data.wd
        end

        if spectate and not spectate.visible then
            spectate.visible = true
        end
        if charging and not charging.visible then
            charging.visible = true
        end
        if charging_frame and not charging_frame.enabled then
            charging_frame.enabled = true
        end
        if info_button then
            info_button.tooltip = ({ 'gui.info_tooltip' })
            info_button.visible = true
            if wd then
                wd.visible = gui_data.wd or gui_data.info_detailed
            end

            if info_detailed then
                info_detailed.visible = gui_data.info_detailed
            end

            if not (wd and wd.visible) or not (info_detailed and info_detailed.visible) then
                info_button.sprite = 'utility/expand'
            else
                info_button.sprite = 'utility/collapse'
            end
        end

        return
    elseif (player.physical_surface == wagon_surface or player.physical_position.x > 700) then
        if main_toggle_button and main_toggle_button.visible then
            main_toggle_button.visible = false
        end
        if wd then
            wd.visible = false
        end
        if spectate then
            spectate.visible = false
        end
        if minimap_button and not minimap_button.visible then
            minimap_button.visible = false
        end
        if rpg_b then
            rpg_b.visible = false
        end
        if poll_b then
            poll_b.visible = false
        end
        if spell_cast_buttons and spell_cast_buttons.visible then
            spell_cast_buttons.visible = false
        end
        if rpg_f then
            rpg_f.destroy()
        end
        if rpg_s then
            rpg_s.destroy()
        end
        if diff then
            diff.visible = false
        end
        if charging then
            charging.visible = false
        end
        if charging_frame and charging_frame.enabled then
            charging_frame.enabled = false
        end
        if info_button then
            info_button.tooltip = ({ 'gui.hide_minimap' })
            info_button.sprite = 'utility/map'
            info_button.visible = false
        end
        if info_detailed and info_detailed.visible then
            info_detailed.visible = false
        end
        if get_top_frame(player) then
            if frame then
                frame.visible = false
                return
            end
        end
        return
    elseif IC.get_player_surface(player) then
        if main_toggle_button and main_toggle_button.visible then
            main_toggle_button.visible = false
        end
        if wd then
            wd.visible = false
        end
        if spectate then
            spectate.visible = false
        end
        if minimap_button and not minimap_button.visible then
            minimap_button.visible = false
        end
        if rpg_b then
            rpg_b.visible = false
        end
        if poll_b then
            poll_b.visible = false
        end
        if spell_cast_buttons and spell_cast_buttons.visible then
            spell_cast_buttons.visible = false
        end
        if rpg_f then
            rpg_f.destroy()
        end
        if rpg_s then
            rpg_s.destroy()
        end
        if diff then
            diff.visible = false
        end
        if charging then
            charging.visible = false
        end
        if charging_frame and charging_frame.enabled then
            charging_frame.enabled = false
        end
        if info_button and info_button.visible then
            info_button.visible = false
        end
        if info_detailed and info_detailed.visible then
            info_detailed.visible = false
        end

        return
    end

    ::no_gui::

    if poll_b then
        poll_b.visible = false
    end
    if rpg_b then
        rpg_b.visible = false
    end
    if info_button and info_button.visible then
        info_button.visible = false
    end
    if info_detailed and info_detailed.visible then
        info_detailed.visible = false
    end
    if wd and wd.visible then
        wd.visible = false
    end
end

local function on_gui_click(event)
    local element = event.element
    if not element.valid then
        return
    end

    local name = element.name

    if name == main_button_name then
        local player = game.players[event.player_index]
        if not validate_player(player) then
            return
        end
        local is_spamming = SpamProtection.is_spamming(player, nil, 'Mtn Gui Click')
        if is_spamming then
            return
        end

        local locomotive = Public.get('locomotive')
        if not validate_entity(locomotive) then
            return
        end

        if not player or not player.valid then
            return
        end
        if not player.physical_surface or not player.physical_surface.valid then
            return
        end
        local gui_data = get_player_gui_settings(player)

        if (player.physical_surface ~= locomotive.surface or player.physical_position.x > 700) then
            local minimap = player.gui.left.icw_main_frame
            if minimap and minimap.visible then
                minimap.visible = false
                return
            elseif minimap and not minimap.visible then
                minimap.visible = true
                return
            end
            return
        end
        if get_top_frame(player) then
            local info_detailed = get_top_frame(player)
            local info_button = get_top_frame_custom(player, main_button_name)
            local wd = get_top_frame_custom(player, 'wave_defense')
            local diff = get_top_frame_custom(player, Difficulty.top_button_name)

            if info_detailed and info_detailed.visible then
                if wd then
                    wd.visible = false
                    gui_data.wd = false
                end
                if diff then
                    diff.visible = false
                end
                info_detailed.visible = false
                gui_data.info_detailed = false
                if info_button then
                    info_button.sprite = 'utility/expand'
                end
                return
            elseif wd and not wd.visible then
                for _, child in pairs(player.gui.left.children) do
                    child.destroy()
                end
                if wd then
                    wd.visible = true
                    gui_data.wd = true
                end
                if diff then
                    diff.visible = true
                end
                return
            elseif info_detailed and not info_detailed.visible then
                for _, child in pairs(player.gui.left.children) do
                    child.destroy()
                end
                if wd then
                    wd.visible = true
                    gui_data.wd = true
                end
                if diff then
                    diff.visible = true
                end
                info_detailed.visible = true
                gui_data.info_detailed = true
                if info_button then
                    info_button.sprite = 'utility/collapse'
                end
                return
            end
        else
            for _, child in pairs(player.gui.left.children) do
                child.destroy()
            end
            create_main_frame(player)
        end
    end
end

on_player_changed_surface = function (event)
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end
    local surface = game.get_surface(event.surface_index or player.surface.index)
    if surface.name == 'Init' then return end
    changed_surface(player)
end

local function enable_guis(event)
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end

    local main_toggle_button_name = Gui.main_toggle_button_name
    local main_toggle_button = get_top_frame_custom(player, main_toggle_button_name)
    local rpg_button = RPG.draw_main_frame_name
    local info = get_top_frame_custom(player, main_button_name)
    local wd = get_top_frame_custom(player, 'wave_defense')
    local spectate = get_top_frame_custom(player, spectate_button_name)
    local rpg_b = get_top_frame_custom(player, rpg_button)
    local diff = get_top_frame_custom(player, Difficulty.top_button_name)
    local charging = get_top_frame_custom(player, 'charging_station')
    local charging_frame = BottomFrame.get_section(player, 'charging_station')

    IC_Gui.remove_toolbar(player)
    IC_Minimap.toggle_button(player)

    if info then
        info.tooltip = ({ 'gui.info_tooltip' })
        info.sprite = 'utility/expand'
    end

    if main_toggle_button and not main_toggle_button.visible then
        main_toggle_button.visible = false
    end

    local minimap = player.gui.left.icw_main_frame
    if minimap and minimap.visible then
        minimap.visible = false
    end

    if rpg_b and not rpg_b.visible then
        rpg_b.visible = true
    end

    if diff and not diff.visible then
        diff.visible = true
    end
    if wd and not wd.visible then
        wd.visible = true
    end
    if spectate and not spectate.visible then
        spectate.visible = true
    end
    if charging and not charging.visible then
        charging.visible = true
    end
    if charging_frame and not charging_frame.enabled then
        charging_frame.enabled = true
    end
    if info then
        info.tooltip = ({ 'gui.info_tooltip' })
        info.sprite = 'utility/expand'
        info.visible = true
    end
end

function Public.update_gui(player)
    if not validate_player(player) then
        return
    end

    if not get_top_frame(player) then
        return
    end

    if not get_top_frame(player).visible then
        return
    end
    local gui = get_top_frame(player)

    local rpg_extra = RPG.get('rpg_extra')
    local mined_scrap = Public.get('mined_scrap')
    local biters_killed = Public.get('biters_killed')
    local upgrades = Public.get('upgrades')

    if rpg_extra.global_pool == 0 then
        gui.global_pool.caption = 'XP: 0'
        gui.global_pool.tooltip = ({ 'gui.global_pool_tooltip' })
    elseif rpg_extra.global_pool >= 0 then
        gui.global_pool.caption = 'XP: ' .. format_number(floor(rpg_extra.global_pool), true)
        gui.global_pool.tooltip = ({ 'gui.global_pool_amount', floor(rpg_extra.global_pool) })
    end

    gui.scrap_mined.caption = ' [img=entity.tree-01][img=entity.huge-rock]: ' .. format_number(mined_scrap, true)
    gui.scrap_mined.tooltip = ({ 'gui.amount_harvested' })

    local pickaxe_upgrades = Public.pickaxe_upgrades
    local pick_tier = pickaxe_upgrades[upgrades.pickaxe_tier]
    local speed = math.round((player.force.manual_mining_speed_modifier + player.character_mining_speed_modifier + 1) * 100)
    local train_upgrade_contribution = upgrades.train_upgrade_contribution
    if upgrades.train_upgrade_contribution > 0 then
        train_upgrade_contribution = upgrades.train_upgrade_contribution / 1000
    end

    gui.pickaxe_tier.caption = ' [img=utility.expand]: ' .. pick_tier .. ' (' .. upgrades.pickaxe_tier .. ')'
    gui.pickaxe_tier.tooltip = ({ 'gui.current_pickaxe_tier', pick_tier, speed })

    gui.biters_killed.caption = ' [img=entity.small-biter]: ' .. format_number(biters_killed, true)
    gui.biters_killed.tooltip = ({ 'gui.biters_killed' })

    gui.landmine.caption = ' [img=entity.land-mine]: ' .. format_number(upgrades.landmine.built, true) .. ' / ' .. format_number(upgrades.landmine.limit, true)
    gui.landmine.tooltip = ({ 'gui.land_mine_placed' })

    gui.flame_turret.caption = ' [img=entity.flamethrower-turret]: ' .. format_number(upgrades.flame_turret.built, true) .. ' / ' .. format_number(upgrades.flame_turret.limit, true)
    gui.flame_turret.tooltip = ({ 'gui.flamethrowers_placed' })

    gui.train_upgrade_contribution.caption = ' [img=entity.locomotive]: ' .. train_upgrade_contribution .. 'k'
    gui.train_upgrade_contribution.tooltip = ({ 'gui.train_upgrade_contribution' })

    local robotics_deployed = Public.get('robotics_deployed')

    if robotics_deployed then
        gui.defense_enabled.caption = ' [img=item.destroyer-capsule]: Deployed'
        gui.defense_enabled.tooltip = ({ 'gui.robotics_deployed' })
    else
        gui.defense_enabled.caption = ' [img=item.destroyer-capsule]: Standby'
        gui.defense_enabled.tooltip = ({ 'gui.robotics_standby' })
    end

    local mystical_chest = Public.get('mystical_chest')
    if mystical_chest then
        local prices = Public.get('mystical_chest_price')
        local mystical_chest_price_init = Public.get('mystical_chest_price_init')

        local items_tooltip = ''
        local items_needed = 0
        local items_completed = 0

        -- Count total items originally needed
        for _, _ in pairs(mystical_chest_price_init) do
            items_needed = items_needed + 1
        end

        -- Count remaining items still needed
        local remaining_items = 0
        for _, item in pairs(prices) do
            remaining_items = remaining_items + 1
            items_tooltip = items_tooltip .. 'Item: [img=item.' .. item.value.name .. '] (' .. item.value.name .. ')\nNeeded: ' .. item.min .. '\n\n'
        end

        -- Calculate completed items: total needed - remaining needed
        items_completed = items_needed - remaining_items

        -- Clean up tooltip (remove extra newlines at the end)
        if items_tooltip ~= '' then
            items_tooltip = items_tooltip:sub(1, -2)
            items_tooltip = items_tooltip:sub(1, -2)
        end

        log(serpent.block(items_tooltip))

        gui[mystical_chest_button_name].caption = ' [img=item.requester-chest]: ' .. items_completed .. '/' .. items_needed
        gui[mystical_chest_button_name].tooltip = items_tooltip
    else
        gui[mystical_chest_button_name].caption = ' [img=item.requester-chest]: 0/0'
        gui[mystical_chest_button_name].tooltip = ({ 'gui.mystical_chest' })
    end
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(Public.events.reset_map, enable_guis)

Event.add(defines.events.on_player_removed, function (event)
    if not event.player_index then
        return
    end
    remove_player_gui_settings(event.player_index)
end)

Gui.on_click(
    spectate_button_name,
    function (event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Mtn v3 Spectate Button')
        if is_spamming then
            return
        end

        local player = event.player
        if not player or not player.valid then
            return
        end

        if Public.get('spectate_button_disable') then
            player.print('Spectate button is disabled until a bug has been fixed in the base game.', { color = Color.yellow })
            return
        end

        create_spectate_main_frame(player)
    end
)

Gui.on_click(
    mystical_chest_button_name,
    function (event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Mtn v3 Mystical Chest Button')
        if is_spamming then
            return
        end

        local player = event.player
        if not player or not player.valid then
            return
        end

        local mystical_chest = Public.get('mystical_chest')
        if mystical_chest then
            local prices = Public.get('mystical_chest_price')

            local player_inv = player.get_inventory(defines.inventory.character_main)
            local can_complete = false

            for _, item in pairs(prices) do
                local player_count = player_inv.get_item_count(item.value.name)
                if player_count > 0 then
                    can_complete = true
                    break
                end
            end
            if not can_complete then
                player.print('[Mystical Chest] You need at least some of the required items to complete the mystical chest.', { color = Color.warning })
                return
            end

            local locomotive = Public.get('locomotive')
            if not locomotive then
                return
            end
            if not locomotive.valid then
                return
            end

            local keys_to_remove = {}

            for key, item in pairs(prices) do
                local player_count = player_inv.get_item_count(item.value.name)
                if player_count > 0 and item.min > 0 then
                    local consume_amount = math.min(player_count, item.min)
                    player_inv.remove({ name = item.value.name, count = consume_amount })
                    item.min = item.min - consume_amount

                    if item.min > 0 then
                        player.print('[Mystical Chest] Consumed ' .. consume_amount .. ' ' .. item.value.name .. '. Still need ' .. item.min .. ' more.', { color = Color.info })
                    else
                        player.print('[Mystical Chest] Consumed ' .. consume_amount .. ' ' .. item.value.name .. '. Requirement fulfilled!', { color = Color.success })
                        table.insert(keys_to_remove, key)
                    end
                elseif item.min <= 0 then
                    table.insert(keys_to_remove, key)
                end
            end

            for i = #keys_to_remove, 1, -1 do
                local key = keys_to_remove[i]
                if prices[key] then
                    local item_name = prices[key].value.name
                    table.remove(prices, key)
                    player.print('[Mystical Chest] ' .. item_name .. ' requirement fulfilled!', { color = Color.success })
                end
            end

            local all_complete = true
            for _, item in pairs(prices) do
                if item.min > 0 then
                    all_complete = false
                    break
                end
            end

            if all_complete then
                Public.init_price_check(locomotive)
                Public.mystical_chest_reward(player)
                local mystical_chest_completed = Public.get('mystical_chest_completed')
                Public.set('mystical_chest_completed', mystical_chest_completed + 1)
            end
            Public.update_gui(player)
        end
    end
)

Gui.on_click(
    spectate_ready_to_button_name,
    function (event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Mtn v3 Spectate Ready Button')
        if is_spamming then
            return
        end

        local player = event.player
        if not player or not player.valid then
            return
        end

        if Public.get('spectate_button_disable') then
            player.print('Spectate button is disabled until a bug has been fixed in the base game.', { color = Color.yellow })
            return
        end

        if player.character and player.character.valid then
            local success = Public.set_player_to_spectator(player)
            if success then
                create_spectate_main_frame(player, true)
                hide_all_gui(player)
            end
        else
            local success = Public.set_player_to_god(player)
            if success then
                create_spectate_main_frame(player, true)
                show_all_gui(player)
            end
        end
    end
)

Gui.on_selection_state_changed(
    spectate_surface_picker_name,
    function (event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Mtn v3 Spectate Surface Picker')
        if is_spamming then
            return
        end

        local player = event.player
        if not player or not player.valid then
            return
        end

        local surface_picker = event.element
        if not surface_picker or not surface_picker.valid then
            return
        end

        local surface_name = surface_picker.items[surface_picker.selected_index]
        if not surface_name then
            return
        end

        player.teleport({ x = 0, y = 0 }, surface_name)
    end
)

Gui.on_click(
    spectate_close_button_name,
    function (event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Mtn v3 Spectate Close Button')
        if is_spamming then
            return
        end

        local player = event.player
        if not player or not player.valid then
            return
        end

        if Public.get('spectate_button_disable') then
            player.print('Spectate button is disabled until a bug has been fixed in the base game.', { color = Color.yellow })
            return
        end

        local main_player_frame = player.gui.screen[spectate_main_frame_name]
        if main_player_frame then
            Gui.remove_data_recursively(main_player_frame)
            main_player_frame.destroy()
        end
    end
)

Public.changed_surface = changed_surface

Event.on_nth_tick(10, function ()
    local spectate = Public.get('spectate')
    Core.iter_connected_players(function (player)
        changed_surface(player)


        local f = player.gui.screen[spectate_main_frame_name]
        local data = Gui.get_data(f)

        if spectate and spectate[player.index] and spectate[player.index].delay and spectate[player.index].delay > game.tick then
            local cooldown = floor((spectate[player.index].delay - game.tick) / 60) + 1 .. ' seconds!'
            if data and data.spectate_hold_button and data.spectate_hold_button.valid then
                data.spectate_hold_button.caption = cooldown
                data.spectate_hold_button.tooltip = { 'spectate.hold-button-tooltip', cooldown }
            end
        else
            if data and data.spectate_hold_button and data.spectate_hold_button.valid then
                data.spectate_hold_button.enabled = true
                if player.character ~= nil then
                    data.spectate_hold_button.caption = { 'spectate.spectate-button' }
                    data.spectate_hold_button.tooltip = { 'spectate.spectate-button-tooltip' }
                else
                    data.spectate_hold_button.caption = { 'spectate.play-button' }
                    data.spectate_hold_button.tooltip = { 'spectate.play-button-tooltip' }
                end
            end
        end
    end)
end)

return Public
