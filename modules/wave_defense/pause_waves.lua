local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Public = require 'modules.wave_defense.table'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Server = require 'utils.server'
local SpamProtection = require 'utils.spam_protection'

local main_frame_name = Gui.uid_name()
local save_button_name = Gui.uid_name()
local discard_button_name = Gui.uid_name()
local random = math.random

local random_greetings = {
    'Dear defender',
    'Defenders',
    'Dear players',
    'Fellow players'
}

local random_greetings_size = #random_greetings

function Public.main_gui(player, text)
    local main_frame = player.gui.screen[main_frame_name]
    if main_frame and main_frame.valid then
        main_frame.destroy()
    end
    main_frame =
        player.gui.screen.add(
        {
            type = 'frame',
            name = main_frame_name,
            caption = 'A stretch is needed.',
            direction = 'vertical'
        }
    )
    main_frame.auto_center = true
    local main_frame_style = main_frame.style
    main_frame_style.width = 500

    local inside_frame = main_frame.add {type = 'frame', style = 'inside_shallow_frame'}
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0
    local inside_table = inside_frame.add {type = 'table', column_count = 1}
    local inside_table_style = inside_table.style
    inside_table_style.vertical_spacing = 0

    inside_table.add({type = 'line'})

    local info_main =
        inside_table.add(
        {
            type = 'label',
            caption = '[color=yellow]' .. text .. ',[/color]'
        }
    )
    local info_main_style = info_main.style
    info_main_style.font = 'default-large-bold'
    info_main_style.padding = 0
    info_main_style.left_padding = 10
    info_main_style.horizontal_align = 'left'
    info_main_style.vertical_align = 'bottom'
    info_main_style.single_line = false
    info_main_style.font_color = {0.55, 0.55, 0.99}

    inside_table.add({type = 'line'})

    local info_sub =
        inside_table.add(
        {
            type = 'label',
            caption = 'We have played for ' .. Server.format_time(game.ticks_played) .. ' now.\nIf you want to take a quick break,\nplease vote to pause the waves for 5 minutes.'
        }
    )
    local info_sub_style = info_sub.style
    info_sub_style.font = 'default-game'
    info_sub_style.padding = 0
    info_sub_style.left_padding = 10
    info_sub_style.horizontal_align = 'left'
    info_sub_style.vertical_align = 'bottom'
    info_sub_style.single_line = false

    inside_table.add({type = 'line'})

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = discard_button_name, caption = 'I cannot rest!'})
    close_button.style = 'back_button'

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_button_name, caption = 'I need to stretch'})
    save_button.style = 'confirm_button'

    player.opened = main_frame
end

function Public.display_pause_wave(player, text)
    if not player then
        return
    end
    if not text then
        return
    end
    return Public.main_gui(player, text)
end

local function pause_waves_state(state)
    if state then
        game.print('[color=blue][Wave Defense][/color] New waves will not spawn for 5 minutes!', {r = 0.98, g = 0.66, b = 0.22})
        Public.set('paused', true)
        Public.set('last_pause', game.tick)
        Public.set('paused_waves_for', game.tick + 18000)

        local next_wave = Public.get('next_wave')
        Public.set('next_wave', next_wave + 18000)
    else
        game.print('[color=blue][Wave Defense][/color] Waves will spawn normally again.', {r = 0.98, g = 0.66, b = 0.22})
        Public.set('paused', false)
        Public.set('paused_waves_for', nil)
        Public.set('last_pause', nil)
    end
end

local pause_waves_state_token = Token.register(pause_waves_state)

function Public.toggle_pause_wave()
    local greeting = random_greetings[random(1, random_greetings_size)]

    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        Public.display_pause_wave(player, greeting)
    end
end

Gui.on_click(
    save_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'WD Save Button')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local total_players = #game.connected_players
        local pause_waves = Public.get('pause_waves')
        if not pause_waves[player.index] then
            pause_waves[player.index] = true
            pause_waves.index = pause_waves.index + 1
        end

        local divided = total_players / 2

        if pause_waves.index >= divided then
            Public.set('pause_waves', {index = 0})
            local players = game.connected_players
            for i = 1, #players do
                local p = players[i]
                local screen = p.gui.screen
                local frame = screen[main_frame_name]
                p.surface.play_sound({path = 'utility/new_objective', position = p.position, volume_modifier = 0.75})

                if frame and frame.valid then
                    Gui.remove_data_recursively(frame)
                    frame.destroy()
                end
            end
            pause_waves_state(true)
            Task.set_timeout_in_ticks(18000, pause_waves_state_token, false) -- 5 minutes
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]

        if frame and frame.valid then
            Gui.remove_data_recursively(frame)
            frame.destroy()
        end
    end
)

Gui.on_click(
    discard_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'WD Discard Button')
        if is_spamming then
            return
        end
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not player or not player.valid or not player.character then
            return
        end
        if frame and frame.valid then
            Gui.remove_data_recursively(frame)
            frame.destroy()
        end
    end
)

Event.on_nth_tick(
    216000, -- 1 hour
    function()
        if game.ticks_played < 100 then
            return
        end

        if Server.format_time(game.ticks_played) == 0 then
            return
        end

        local paused = Public.get('paused')
        if paused then
            return
        end

        Public.toggle_pause_wave()
    end
)

commands.add_command(
    'wave_defense_pause_waves',
    'Usable only for admins - pauses the wave defense waves!',
    function()
        local player = game.player

        if player and player.valid then
            if not player.admin then
                return
            end

            local paused = Public.get('paused')
            if paused then
                return
            end

            print('[Wave Defense] ' .. player.name .. ' paused wave defense.')

            Public.toggle_pause_wave()
        end
    end
)

return Public
