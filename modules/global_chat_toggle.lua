local Gui = require 'utils.gui'

local function get_chat_button(player)
    if Gui.get_mod_gui_top_frame() then
        return Gui.get_button_flow(player).global_chat_toggle
    end
    return player.gui.top.global_chat_toggle
end

local function toggle(player)
    local button = get_chat_button(player)
    if not button then
        return
    end

    if button.caption == 'Global Chat' then
        button.caption = 'Team Chat'
        button.tooltip = 'Chat messages are only sent to your team.'
        button.style.font_color = {r = 0.77, g = 0.77, b = 0.0}
        return
    end

    button.caption = 'Global Chat'
    button.tooltip = 'Chat messages are sent to everyone.'
    button.style.font_color = {r = 0.0, g = 0.77, b = 0.0}
end

local function create_gui_button(player)
    if get_chat_button(player) then
        return
    end
    local b
    if Gui.get_mod_gui_top_frame() then
        b =
            Gui.add_mod_button(
                player,
                {
                    type = 'sprite-button',
                    name = 'global_chat_toggle',
                    caption = '',
                    style = Gui.button_style
                }
            )
        if b then
            b.style.font = 'default-semibold'
            b.style.minimal_width = 100
            b.style.minimal_height = 36
            b.style.maximal_height = 36
            b.style.padding = -2
            b.style.margin = 0
        end
    else
        b =
            player.gui.top.add(
                {
                    type = 'sprite-button',
                    name = 'global_chat_toggle',
                    caption = '',
                    style = Gui.button_style
                }
            )
        b.style.font = 'heading-2'
        b.style.minimal_width = 100
        b.style.minimal_height = 38
        b.style.maximal_height = 38
        b.style.padding = 1
        b.style.margin = 0
    end
    toggle(player)
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    create_gui_button(player)
end

local function on_gui_click(event)
    if not event then
        return
    end
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    local player = game.players[event.element.player_index]
    if event.element.name ~= 'global_chat_toggle' then
        return
    end
    toggle(player)
end

local function on_console_chat(event)
    if not event.message then
        return
    end
    if not event.player_index then
        return
    end
    local player = game.players[event.player_index]
    local button = get_chat_button(player)
    if not button then
        return
    end
    if button.caption ~= 'Global Chat' then
        return
    end
    for _, force in pairs(game.forces) do
        if force.name ~= player.force.name then
            force.print(player.name .. ' ' .. player.tag .. ': ' .. event.message, player.chat_color)
        end
    end
end

local Event = require 'utils.event'
Event.add(defines.events.on_console_chat, on_console_chat)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)
