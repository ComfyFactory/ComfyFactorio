local Public = require 'modules.wave_defense.table'
local Gui = require 'utils.gui'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'

local floor = math.floor

local function get_top_frame_custom(player, name)
    if Gui.get_mod_gui_top_frame() then
        return Gui.get_button_flow(player)[name]
    else
        return player.gui.top[name]
    end
end

local function create_gui(player)
    local frame

    if Gui.get_mod_gui_top_frame() then
        frame =
            Gui.add_mod_button(
            player,
            {
                type = 'frame',
                name = 'wave_defense',
                style = 'finished_game_subheader_frame'
            }
        )
        frame.style.maximal_height = 36
    else
        frame = player.gui.top.add({type = 'frame', name = 'wave_defense', style = 'finished_game_subheader_frame'})
        frame.style.maximal_height = 38
    end

    local label = frame.add({type = 'label', caption = ' ', name = 'label'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

    local wave_number_label = frame.add({type = 'label', caption = ' ', name = 'wave_number'})
    wave_number_label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    wave_number_label.style.font = 'default-bold'
    wave_number_label.style.right_padding = 4
    wave_number_label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

    local progressbar = frame.add({type = 'progressbar', name = 'progressbar', value = 0})
    progressbar.style = 'achievement_progressbar' ---@class LuaGuiElementStyle
    progressbar.style.minimal_width = 96
    progressbar.style.maximal_width = 96
    progressbar.style.padding = -1
    progressbar.style.top_padding = 1

    local line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    local threat_label = frame.add({type = 'label', caption = ' ', name = 'threat', tooltip = {'wave_defense.tooltip_1'}})
    threat_label.style.font = 'default-bold'
    threat_label.style.left_padding = 4
    threat_label.style.font_color = {r = 150, g = 0, b = 255}

    local threat_value_label = frame.add({type = 'label', caption = ' ', name = 'threat_value', tooltip = {'wave_defense.tooltip_1'}})
    threat_value_label.style.font = 'default-bold'
    threat_value_label.style.right_padding = 1
    threat_value_label.style.minimal_width = 10
    threat_value_label.style.font_color = {r = 150, g = 0, b = 255}

    local threat_gains_label = frame.add({type = 'label', caption = ' ', name = 'threat_gains', tooltip = {'wave_defense.tooltip_2'}})
    threat_gains_label.style.font = 'default'
    threat_gains_label.style.left_padding = 1
    threat_gains_label.style.right_padding = 1
end

--display threat gain/loss per minute during last 15 minutes
local function get_threat_gain()
    local threat_log_index = Public.get('threat_log_index')
    local threat_log = Public.get('threat_log')
    local past_index = threat_log_index - 900
    if past_index < 1 then
        past_index = 1
    end
    local gain = floor((threat_log[threat_log_index] - threat_log[past_index]) / 15)
    return gain
end

function Public.update_gui(player)
    local final_battle = Public.get('final_battle')
    if final_battle then
        if get_top_frame_custom(player, 'wave_defense') and get_top_frame_custom(player, 'wave_defense').valid then
            get_top_frame_custom(player, 'wave_defense').destroy()
        end
        return
    end

    if not get_top_frame_custom(player, 'wave_defense') then
        create_gui(player)
    end
    local gui = get_top_frame_custom(player, 'wave_defense')

    local biter_health_boost = 1
    local biter_health_boosts = BiterHealthBooster.get('biter_health_boost')
    if biter_health_boost then
        biter_health_boost = biter_health_boosts
    end

    local paused = Public.get('paused')
    local paused_waves_for = Public.get('paused_waves_for')
    local last_pause = Public.get('last_pause')
    local wave_number = Public.get('wave_number')
    local next_wave = Public.get('next_wave')
    local last_wave = Public.get('last_wave')
    local max_active_biters = Public.get('max_active_biters')
    local threat = Public.get('threat')
    local enable_threat_log = Public.get('enable_threat_log')

    gui.label.caption = {'wave_defense.gui_2'}
    if not paused then
        gui.wave_number.caption = wave_number
        if wave_number == 0 then
            gui.label.caption = {'wave_defense.gui_1'}
            gui.label.tooltip = 'Next pause will occur in: ' .. floor((Public.get('next_pause_interval') - game.tick) / 60 / 60) + 1 .. ' minute(s)'
            gui.wave_number.caption = floor((next_wave - game.tick) / 60) + 1 .. 's'
        end
        local interval = next_wave - last_wave
        local value = 1 - (next_wave - game.tick) / interval
        if value < 0 then
            value = 0
        elseif value > 1 then
            value = 1
        end
        gui.progressbar.value = value
    else
        gui.label.caption = {'wave_defense.gui_4'}
        gui.label.tooltip = 'Wave: ' .. wave_number
        local pause_for = floor((paused_waves_for - game.tick) / 60) + 1
        if pause_for < 0 then
            pause_for = 0
        end
        gui.wave_number.caption = pause_for .. 's'
        gui.wave_number.tooltip = 'Wave: ' .. wave_number

        local interval = paused_waves_for - last_pause
        local value = 1 - (paused_waves_for - game.tick) / interval
        if value < 0 then
            value = 0
        elseif value > 1 then
            value = 1
        end
        gui.progressbar.value = value
        return
    end

    gui.threat.caption = {'wave_defense.gui_3'}
    gui.threat.tooltip = {'wave_defense.tooltip_1', biter_health_boost * 100, max_active_biters}
    ---@diagnostic disable-next-line: param-type-mismatch
    gui.threat_value.caption = floor(threat)
    gui.threat_value.tooltip = {
        'wave_defense.tooltip_1',
        biter_health_boost * 100,
        max_active_biters
    }

    if wave_number == 0 then
        gui.threat_gains.caption = ''
        return
    end
    if enable_threat_log then
        local gain = get_threat_gain()
        local d = wave_number / 75

        if gain >= 0 then
            gui.threat_gains.caption = ' (+' .. gain .. ')'
            local g = 255 - floor(gain / d)
            if g < 0 then
                g = 0
            end
            gui.threat_gains.style.font_color = {255, g, 0}
        else
            gui.threat_gains.caption = ' (' .. gain .. ')'
            local r = 255 - floor(math.abs(gain) / d)
            if r < 0 then
                r = 0
            end
            gui.threat_gains.style.font_color = {r, 255, 0}
        end
    end
end

return Public
