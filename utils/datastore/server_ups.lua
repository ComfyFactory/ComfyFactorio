local Server = require 'utils.server'
local GUI = require 'utils.gui'
local Event = require 'utils.event'
local Color = require 'utils.color_presets'

local ups_label = GUI.uid_name()

local function validate_player(player)
    if not player or not player.valid then
        return false
    end
    return true
end

local function set_location(event)
    local player = game.get_player(event.player_index)
    local gui = player.gui
    local label = gui.screen[ups_label]
    local res = player.display_resolution
    local uis = player.display_scale
    label.location = {x = res.width - 423 * uis, y = 30 * uis}
end

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        local ups = Server.get_ups()
        local sUPS = 'SUPS = ' .. ups

        local label = player.gui.screen[ups_label]

        if not label or not label.valid then
            label =
                player.gui.screen.add(
                {
                    type = 'label',
                    name = ups_label,
                    caption = sUPS
                }
            )
            local style = label.style
            style.font = 'default-game'
        end
        set_location(event)
        label.visible = false
    end
)

-- Update the value each second
Event.on_nth_tick(
    60,
    function()
        local ups = Server.get_ups()
        local caption = 'SUPS = ' .. ups
        local players = game.connected_players
        for _, player in pairs(players) do
            local label = player.gui.screen[ups_label]
            if label and label.valid then
                label.caption = caption
            end
        end
    end
)

commands.add_command(
    'server-ups',
    'Toggle the server UPS display!',
    function()
        local player = game.player

        local secs = Server.get_current_time()

        if validate_player(player) then
            if not secs then
                return player.print('Not running on Comfy backend.', Color.warning)
            end

            local label = player.gui.screen[ups_label]
            if not label or not label.valid then
                return
            end

            if label.visible then
                label.visible = false
            else
                label.visible = true
            end
        end
    end
)

Event.add(defines.events.on_player_display_resolution_changed, set_location)
Event.add(defines.events.on_player_display_scale_changed, set_location)
