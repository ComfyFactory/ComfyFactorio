-- toggle your flashlight -- by mewmew

local Event = require 'utils.event'
local Gui = require 'utils.gui'
local message_color = { r = 200, g = 200, b = 0 }

local function on_gui_click(event)
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    if not event.element.name then
        return
    end
    if event.element.name ~= 'flashlight_toggle' then
        return
    end
    local player = game.players[event.player_index]

    if storage.flashlight_enabled[player.name] == true then
        player.character.disable_flashlight()
        player.print('Flashlight disabled.', message_color)
        storage.flashlight_enabled[player.name] = false
        return
    end

    if storage.flashlight_enabled[player.name] == false then
        player.character.enable_flashlight()
        player.print('Flashlight enabled.', message_color)
        storage.flashlight_enabled[player.name] = true
        return
    end
end

local function on_player_respawned(event)
    local player = game.players[event.player_index]
    if storage.flashlight_enabled[player.name] == false then
        player.character.disable_flashlight()
        return
    end
    if storage.flashlight_enabled[player.name] == true then
        player.character.enable_flashlight()
        return
    end
end

local function on_player_joined_game(event)
    if not storage.flashlight_enabled then
        storage.flashlight_enabled = {}
    end
    local player = game.players[event.player_index]
    storage.flashlight_enabled[player.name] = true
    if player.gui.top['flashlight_toggle'] then
        return
    end
    local b = player.gui.top.add({ type = 'sprite-button', name = 'flashlight_toggle', sprite = 'item/small-lamp', tooltip = 'Toggle flashlight', style = Gui.button_style })
    b.style.minimal_height = 38
    b.style.maximal_height = 38
    b.style.minimal_width = 38
    b.style.top_padding = 2
    b.style.left_padding = 4
    b.style.right_padding = 4
    b.style.bottom_padding = 2
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_gui_click, on_gui_click)
