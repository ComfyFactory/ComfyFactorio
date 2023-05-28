local Token = require 'utils.token'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Gui = require 'utils.gui'

local dataset = 'warnings'
local set_data = Server.set_data
local try_get_data = Server.try_get_data
local warning_frame_name = Gui.uid_name()
local discard_button_name = Gui.uid_name()

local Public = {}

local function draw_warning_frame(player, message)
    local main_frame, inside_table = Gui.add_main_frame_with_toolbar(player, 'screen', warning_frame_name, nil, nil, 'Warning', true, 2)

    if not main_frame or not inside_table then
        return
    end

    local main_frame_style = main_frame.style
    main_frame_style.width = 400
    main_frame.auto_center = true

    local content_flow = inside_table.add {type = 'flow', direction = 'horizontal'}
    content_flow.style.top_padding = 16
    content_flow.style.bottom_padding = 16
    content_flow.style.left_padding = 24
    content_flow.style.right_padding = 24
    content_flow.style.horizontally_stretchable = false

    local sprite_flow = content_flow.add {type = 'flow'}
    sprite_flow.style.vertical_align = 'center'
    sprite_flow.style.vertically_stretchable = false

    sprite_flow.add {type = 'sprite', sprite = 'utility/warning_icon'}

    local label_flow = content_flow.add {type = 'flow'}
    label_flow.style.horizontal_align = 'left'
    label_flow.style.top_padding = 10
    label_flow.style.left_padding = 24

    local warning_message = '[font=heading-2]Message from Comfy to: ' .. player.name .. '[/font]\n' .. message

    label_flow.style.horizontally_stretchable = false
    local label = label_flow.add {type = 'label', caption = warning_message}
    label.style.single_line = false

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = discard_button_name, caption = 'Understood'})
    close_button.style = 'back_button'

    player.opened = main_frame
end

local fetch =
    Token.register(
    function(data)
        local key = data.key
        if not key then
            return
        end

        local value = data.value
        if not value then
            return
        end

        local player = game.get_player(key)
        if not player or not player.valid then
            return
        end
        draw_warning_frame(player, value)
    end
)

--- Tries to get data from the webpanel and applies the value to the player.
-- @param data_set player token
function Public.fetch(key)
    local secs = Server.get_current_time()
    if not secs then
        local player = game.players[key]
        if not player or not player.valid then
            return
        end
        return
    else
        try_get_data(dataset, key, fetch)
    end
end

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        Public.fetch(player.name)
    end
)

Gui.on_click(
    discard_button_name,
    function(event)
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[warning_frame_name]
        if not player or not player.valid then
            return
        end

        if frame and frame.valid then
            frame.destroy()
            set_data(dataset, player.name)
        end
    end
)

Server.on_data_set_changed(
    dataset,
    function(data)
        if not data then
            return
        end

        local key = data.key
        local value = data.value
        local player = game.get_player(key)
        if not player or not player.valid then
            return
        end
        draw_warning_frame(player, value)
    end
)

return Public
