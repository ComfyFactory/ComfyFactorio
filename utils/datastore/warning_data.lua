-- created by Gerkiz for ComfyFactorio
local Global = require 'utils.global'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Utils = require 'utils.core'
local Gui = require 'utils.gui'
local Commands = require 'utils.commands'
local Token = require 'utils.token'
local Discord = require 'utils.discord'
local DiscordHandler = require 'utils.discord_handler'

local module_name = '[Warning handler] '

local warning_data_set = 'warnings'
local warnings = {}

local set_data = Server.set_data
local try_get_data = Server.try_get_data

local warning_frame_name = Gui.uid_name()
local ok_button_name = Gui.uid_name()

Global.register(
    {
        warnings = warnings
    },
    function (t)
        warnings = t.warnings
    end
)

local Public = {}

local function generate_warning_id()
    return game.tick .. '_' .. math.random(1000, 9999)
end

local function set_character_state(player, state)
    if not player or not player.valid then
        return false
    end

    if player.character ~= nil then
        player.character.active = state
    end

    return true
end

local function draw_warning_frame(player, warning_data)
    local main_frame, inside_table = Gui.add_main_frame_with_toolbar(player, 'screen', warning_frame_name, nil, nil, 'Warning', true, 2)

    if not main_frame or not inside_table then
        return
    end

    main_frame.style.width = 500
    main_frame.auto_center = true

    local content_flow = inside_table.add
        {
            type = 'flow',
            direction = 'vertical'
        }
    content_flow.style.top_padding = 16
    content_flow.style.bottom_padding = 16
    content_flow.style.left_padding = 24
    content_flow.style.right_padding = 24
    content_flow.style.vertical_spacing = 12

    local top_row = content_flow.add
        {
            type = 'flow',
            direction = 'horizontal'
        }

    local sprite_flow = top_row.add { type = 'flow' }
    sprite_flow.style.vertical_align = 'center'
    sprite_flow.add { type = 'sprite', sprite = 'utility/warning_icon' }

    local label_flow = top_row.add { type = 'flow' }
    label_flow.style.left_padding = 24
    label_flow.style.top_padding = 6

    local warning_message = '[font=heading-2]You have received a warning[/font]\n' .. (warning_data.reason or 'No reason provided.')

    local label = label_flow.add
        {
            type = 'label',
            caption = warning_message
        }
    label.style.single_line = false
    label.style.width = 400

    local notice_message = '[font=heading-2]Breaking our rules multiple times will result in a ban.[/font]'

    local notice_label = content_flow.add
        {
            type = 'label',
            caption = notice_message
        }
    notice_label.style.single_line = false
    notice_label.style.width = 400

    local bottom_flow = main_frame.add
        {
            type = 'flow',
            direction = 'horizontal'
        }

    local right_flow = bottom_flow.add { type = 'flow' }
    right_flow.style.horizontally_stretchable = true
    right_flow.style.horizontal_align = 'right'

    set_character_state(player, false)

    local ok_button = right_flow.add
        {
            type = 'button',
            name = ok_button_name,
            caption = 'OK',
            style = 'confirm_button'
        }

    Gui.set_data(ok_button, { warning_id = warning_data.id })

    player.opened = main_frame
end

local function show_next_warning(player)
    if not warnings[player.name] then
        return
    end

    local player_warnings = warnings[player.name]
    for _, warning in ipairs(player_warnings) do
        if not warning.accepted then
            draw_warning_frame(player, warning)
            return
        end
    end
end


local function send_warning_discord_message(offender_name, admin_name, reason, accepted)
    local data = Server.build_embed_data()
    data.username = offender_name
    data.admin = admin_name
    data.reason = reason
    data.accepted = accepted or false

    local message = offender_name .. ' has ' .. (accepted and 'accepted' or 'received') .. ' a warning from ' .. admin_name .. '. Reason: ' .. reason
    DiscordHandler.send_notification(
        {
            title = 'Warning',
            description = message,
            color = 'warning'
        })
end

local function assign_warning(offender_name, admin_name, reason)
    if not offender_name or not reason then
        return false
    end

    local offender = game.get_player(offender_name)
    local date = Server.get_current_date_with_time()
    local warning_id = generate_warning_id()

    local warning_data =
    {
        id = warning_id,
        reason = reason,
        admin = admin_name,
        date = date,
        accepted = false
    }

    if not warnings[offender_name] then
        warnings[offender_name] = {}
    end

    table.insert(warnings[offender_name], warning_data)

    set_data(warning_data_set, offender_name, warnings[offender_name])

    send_warning_discord_message(offender_name, admin_name, reason, false)

    if offender and offender.valid then
        local frame = offender.gui.screen[warning_frame_name]
        if not frame or not frame.valid then
            draw_warning_frame(offender, warning_data)
        end
    end

    return true
end

local function accept_warning(player_name, warning_id)
    if not warnings[player_name] then
        return false
    end

    local player_warnings = warnings[player_name]
    local warning_data = nil

    for _, warning in ipairs(player_warnings) do
        if warning.id == warning_id then
            warning_data = warning
            break
        end
    end

    if not warning_data then
        return false
    end

    warning_data.accepted = true
    warning_data.accepted_date = Server.get_current_date_with_time()

    set_data(warning_data_set, player_name, player_warnings)

    warnings[player_name] = player_warnings

    send_warning_discord_message(player_name, warning_data.admin, warning_data.reason, true)

    local p = game.get_player(player_name)
    if p and p.valid then
        set_character_state(p, true)
    end

    return true
end

local load_warning_token =
    Token.register(
        function (data)
            local key = data.key
            local value = data.value

            if not key or not value then
                return
            end

            local player = game.get_player(key)
            if not player or not player.valid then
                return
            end

            if type(value) ~= 'table' then
                return
            end

            if not value[1] and value.id then
                value = { value }
            end

            if not value[1] then
                return
            end

            local needs_save = false
            for _, warning in ipairs(value) do
                if not warning.id then
                    warning.id = generate_warning_id()
                    needs_save = true
                end
            end

            warnings[key] = value

            if needs_save then
                set_data(warning_data_set, key, value)
            end

            show_next_warning(player)
        end
    )

function Public.try_dl_data(key)
    key = tostring(key)

    local secs = Server.get_current_time()
    if not secs then
        return
    else
        try_get_data(warning_data_set, key, load_warning_token)
    end
end

Commands.new('warn', 'Assigns a warning to a player.')
    :add_parameter('offender', false, 'player')
    :add_parameter('reason', false, 'string')
    :require_backend()
    :callback(function (player, offender, reason)
        if not offender then
            Utils.print_to(player, module_name .. 'No valid player given.')
            return false
        end

        if not reason or string.len(reason) <= 0 then
            Utils.print_to(player, module_name .. 'No valid reason was given.')
            return false
        end

        if string.len(reason) < 10 then
            Utils.print_to(player, module_name .. 'Reason is too short.')
            return false
        end

        if assign_warning(offender.name, player.name, reason) then
            Utils.print_to(player, module_name .. 'Warning assigned to ' .. offender.name .. '.')
            return true
        else
            Utils.print_to(player, module_name .. 'Failed to assign warning.')
            return false
        end
    end)

Event.add(
    defines.events.on_player_joined_game,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        Public.try_dl_data(player.name)
    end
)

Gui.on_click(
    ok_button_name,
    function (event)
        local player = event.player
        if not player or not player.valid then
            return
        end

        local screen = player.gui.screen
        local frame = screen[warning_frame_name]
        if not frame or not frame.valid then
            return
        end

        local data = Gui.get_data(event.element)
        if not data or not data.warning_id then
            return
        end

        accept_warning(player.name, data.warning_id)

        frame.destroy()

        show_next_warning(player)
    end
)

Server.on_data_set_changed(
    warning_data_set,
    function (data)
        if not data then
            return
        end

        local key = data.key
        local value = data.value

        if not key or not value then
            return
        end

        if type(value) ~= 'table' then
            warnings[key] = nil
            return
        end

        if not value[1] and value.id then
            value = { value }
        end

        if not value[1] then
            warnings[key] = nil
            return
        end

        for _, warning in ipairs(value) do
            if not warning.id then
                warning.id = generate_warning_id()
            end
        end

        warnings[key] = value

        local player = game.get_player(key)
        if player and player.valid then
            local frame = player.gui.screen[warning_frame_name]
            if not frame or not frame.valid then
                show_next_warning(player)
            end
        end
    end
)

Public.assign_warning = assign_warning
Public.accept_warning = accept_warning
Public.get_warnings = function ()
    return warnings
end

return Public
