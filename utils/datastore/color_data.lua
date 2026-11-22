-- created by Gerkiz for ComfyFactorio
local Token = require 'utils.token'
local Color = require 'utils.color_presets'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Commands = require 'utils.commands'
local PlayerSettings = require 'utils.gui.player_settings'
local ColorPicker = require 'utils.gui.color_picker'

local color_data_set = 'colors'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

local Public = {}

local function apply_color(player, value)
    if value then
        player.color = value.color[1]
        player.chat_color = value.chat[1]
    end
end

local function save_color(player)
    local value = { color = { player.color }, chat = { player.chat_color } }
    set_data(color_data_set, player.name, value)
    return value
end

local function color_text(color)
    return string.format('%.3g, %.3g, %.3g, %.3g', color.r, color.g, color.b, color.a or 1)
end

PlayerSettings.register('colors', color_data_set, {
    input_hint = 'colors_edit',
    update_tooltip = 'colors_update_tooltip',
    apply_tooltip = 'colors_apply_tooltip',
    add_input_controls = function (controls, value, player, width, editable)
        local color = value and value.color[1] or player.color
        local chat = value and value.chat[1] or player.chat_color
        ColorPicker.add(controls, width, editable, color, chat)
    end,
    read_input = ColorPicker.get_colors,
    save = function (player, colors)
        if not colors then
            return
        end
        player.color = colors[1]
        player.chat_color = colors[2]
        return save_color(player)
    end,
    apply = apply_color,
    describe = function (value)
        return 'Player (RGBA)  ' .. color_text(value.color[1]) .. '\nChat (RGBA)  ' .. color_text(value.chat[1])
    end
})

local fetch =
    Token.register(
        function (data)
            local key = data.key
            local value = data.value
            local player = game.players[key]
            if not player then
                return
            end
            apply_color(player, value)
        end
    )

--- Tries to get data from the webpanel and applies the value to the player.
-- @param data_set player token
function Public.fetch(key)
    local secs = Server.get_current_time()
    if secs == nil or secs == false then
        return
    else
        try_get_data(color_data_set, key, fetch)
    end
end

local fetcher = Public.fetch

Event.add(
    defines.events.on_player_joined_game,
    function (event)
        local player = game.get_player(event.player_index)
        if not player then
            return
        end
        fetcher(player.name)
    end
)


Commands.new('save-color', "Save your personal color preset so it's always the same whenever you join.")
    :require_backend()
    :callback(
        function (player)
            save_color(player)
            player.print('Your personal color has been saved to the datastore.', { color = Color.success })
        end
    )

Commands.new('remove-color', 'Removes your saved color from the datastore.')
    :require_backend()
    :callback(
        function (player)
            set_data(color_data_set, player.name, nil)
            player.print('Your personal color has been removed from the datastore.', { color = Color.success })
        end
    )


return Public
