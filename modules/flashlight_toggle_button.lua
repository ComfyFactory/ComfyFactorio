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
    if not player or not player.valid then
        return
    end

    if player.character == nil then
        return
    end

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
    if not player or not player.valid then
        return
    end

    if player.character == nil then
        return
    end

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
    local existing
    if Gui.get_mod_gui_top_frame() then
        existing = Gui.get_button_flow(player)['flashlight_toggle']
    else
        existing = player.gui.top['flashlight_toggle']
    end
    if existing then
        return
    end
    local b
    if Gui.get_mod_gui_top_frame() then
        b =
            Gui.add_mod_button(
                player,
                {
                    type = 'sprite-button',
                    name = 'flashlight_toggle',
                    sprite = 'item/small-lamp',
                    tooltip = 'Toggle flashlight',
                    style = Gui.button_style
                }
            )
        if b then
            b.style.minimal_height = 36
            b.style.maximal_height = 36
            b.style.minimal_width = 40
            b.style.padding = -2
        end
    else
        b = player.gui.top.add({ type = 'sprite-button', name = 'flashlight_toggle', sprite = 'item/small-lamp', tooltip = 'Toggle flashlight', style = Gui.button_style })
        b.style.minimal_height = 38
        b.style.maximal_height = 38
        b.style.minimal_width = 38
        b.style.top_padding = 2
        b.style.left_padding = 4
        b.style.right_padding = 4
        b.style.bottom_padding = 2
    end
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_gui_click, on_gui_click)
