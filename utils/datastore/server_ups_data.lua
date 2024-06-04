-- created by Gerkiz for ComfyFactorio
local Server = require 'utils.server'
local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Commands = require 'utils.commands'

local ups_label = 'ups_label'

local function set_location(player)
    local gui = player.gui
    local label = gui.screen[ups_label]
    if not label or not label.valid then
        return
    end
    local res = player.display_resolution
    local uis = player.display_scale
    label.location = { x = res.width - 423 * uis, y = 30 * uis }
end

local function create_label(player)
    local ups = Server.get_ups()
    local sUPS = 'SUPS = ' .. ups

    local label =
        player.gui.screen.add(
            {
                type = 'label',
                name = ups_label,
                caption = sUPS
            }
        )
    local style = label.style
    style.font = 'default-game'
    return label
end

Event.add(
    defines.events.on_player_joined_game,
    function (event)
        local player = game.get_player(event.player_index)

        local label = player.gui.screen[ups_label]

        if not label or not label.valid then
            label = create_label(player)
        end
        set_location(player)
        label.visible = false
    end
)

-- Update the value each second
Event.on_nth_tick(
    60,
    function ()
        local ups = Server.get_ups()
        local caption = 'SUPS = ' .. ups
        local players = game.connected_players
        for i = 1, #players do
            local player = players[i]
            local label = player.gui.screen[ups_label]
            if label and label.valid then
                label.caption = caption
                set_location(player)
            end
        end
    end
)

Commands.new('server-ups', 'Toggle the server UPS display!')
    :require_backend()
    :callback(
        function (player)
            local label = player.gui.screen[ups_label]
            if not label or not label.valid then
                label = create_label(player)
            end

            if label.visible then
                label.visible = false
                player.print('Removed Server-UPS label.')
            else
                label.visible = true
                set_location(player)
                player.print('Added Server-UPS label.')
            end
        end
    )

Gui.screen_to_bypass(ups_label)

Event.add(
    defines.events.on_player_display_resolution_changed,
    function (event)
        local player = game.get_player(event.player_index)
        set_location(player)
    end
)

Event.add(
    defines.events.on_player_display_scale_changed,
    function (event)
        local player = game.get_player(event.player_index)
        set_location(player)
    end
)
