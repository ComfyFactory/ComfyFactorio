local Global = require 'utils.global'
local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Server = require 'utils.server'
local Task = require 'utils.task_token'

local this = {}
local notice_frame_name = Gui.uid_name()
local save_button_name = Gui.uid_name()
local whisper_dataset = 'whisper_tos'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local Public = {}

local function get_player_data(player, remove)
    if remove and this[player.name] then
        this[player.name] = nil
        return
    end
    if not this[player.name] then
        this[player.name] = {}
    end
    return this[player.name]
end

local has_accepted_token =
    Task.register(
    function(data)
        local player_name = data.key
        local value = data.value
        if value and value.accepted then
            this[player_name] = {
                accepted_whisper_tos = true
            }
        end
    end
)

local function remove_target_frame(target_frame)
    Gui.remove_data_recursively(target_frame)
    target_frame.destroy()
end

local function draw_notice_frame(player)
    local main_frame, inside_table = Gui.add_main_frame_with_toolbar(player, 'screen', notice_frame_name, nil, nil, 'Notice', true, 2)

    if not main_frame or not inside_table then
        return
    end

    local main_frame_style = main_frame.style
    main_frame_style.width = 600
    main_frame.auto_center = true

    if player.character ~= nil then
        player.character.active = false
    end

    local content_flow = inside_table.add {type = 'flow', direction = 'horizontal'}
    content_flow.style.top_padding = 16
    content_flow.style.bottom_padding = 16
    content_flow.style.left_padding = 24
    content_flow.style.right_padding = 24
    content_flow.style.horizontally_stretchable = false

    local sprite_flow = content_flow.add {type = 'flow'}
    sprite_flow.style.vertical_align = 'center'
    sprite_flow.style.vertically_stretchable = true

    sprite_flow.add {type = 'sprite', sprite = 'utility/warning_icon'}

    local label_flow = content_flow.add {type = 'flow'}
    label_flow.style.horizontal_align = 'left'
    label_flow.style.top_padding = 10
    label_flow.style.left_padding = 24

    local warning_message =
        '[font=heading-2]Whisper notice![/font]\nIn order to provide our free services, ComfyFactorio must be entitled to access, monitor and/or review text chat, including "whisper" chat, in the event of complaints from other users or rule(s) violations.\n\nBy clicking the check box below, you agree that ComfyFactorio has the right to monitor and review personal messages you send or receive on our servers.\n\nComfyFactorio will [font=default-bold]not[/font] use the information for any reason other than pursuing such violations.'

    label_flow.style.horizontally_stretchable = true
    local label = label_flow.add {type = 'label', caption = warning_message}
    label.style.single_line = false

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_button_name, caption = 'OK'})
    save_button.style = 'confirm_button'

    player.opened = main_frame
end

local function on_console_command(event)
    if not event.player_index then
        return
    end

    local valid_commands = {
        ['r'] = true,
        ['whisper'] = true
    }

    if not valid_commands[event.command] then
        return
    end

    local secs = Server.get_current_time()
    if not secs then
        return
    end

    local player = game.get_player(event.player_index)

    local gui_data = get_player_data(player)

    if gui_data.accepted_whisper_tos then
        return
    end

    draw_notice_frame(player)
end

Event.add(defines.events.on_console_command, on_console_command)
Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local gui_data = get_player_data(player)
        if gui_data.accepted_whisper_tos then
            return
        end

        local secs = Server.get_current_time()

        if not secs then
            return
        else
            try_get_data(whisper_dataset, player.name, has_accepted_token)
        end
    end
)

Gui.on_click(
    save_button_name,
    function(event)
        local player = event.player
        if not player or not player.valid then
            return
        end

        local screen = player.gui.screen
        local frame = screen[notice_frame_name]

        local gui_data = get_player_data(player)

        if not gui_data.accepted_whisper_tos then
            gui_data.accepted_whisper_tos = true
        end

        if player.character ~= nil then
            player.character.active = true
        end
        local date = Server.get_current_date_with_time()
        set_data(whisper_dataset, player.name, {accepted = true, date = date})

        if frame and frame.valid then
            remove_target_frame(frame)
        end
    end
)

return Public
