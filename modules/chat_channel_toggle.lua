local Gui = require 'utils.gui'

storage.chat_modes = storage.chat_modes or {}

local CHAT_MODES = { GLOBAL = 1, TEAM = 2, ALLIANCE = 3 }
local BUTTON_PROPERTIES = {
    [CHAT_MODES.GLOBAL] = { 'Global Chat', 'Chat messages are sent to everyone.', { r = 0.0, g = 0.77, b = 0.0 } },
    [CHAT_MODES.TEAM] = { 'Team Chat', 'Chat messages are only sent to your team.', { r = 0.77, g = 0.77, b = 0.0 } },
    [CHAT_MODES.ALLIANCE] = { 'Alliance Chat', 'Chat messages are only sent to your alliance.', { r = 0.5, g = 0.6, b = 0.9 } },
}

local function get_chat_button(player)
    if Gui.get_mod_gui_top_frame() then
        return Gui.get_button_flow(player).global_chat_toggle
    end
    return player.gui.top.global_chat_toggle
end

local function set_chat_mode(player, mode)
    storage.chat_modes[player.index] = mode
    local button = get_chat_button(player)
    if not button or not button.valid then
        return
    end
    local properties = BUTTON_PROPERTIES[mode]
    button.caption = properties[1]
    button.tooltip = properties[2]
    button.style.font_color = properties[3]
end

local function toggle(player)
    local button = get_chat_button(player)
    if not button or not button.valid then
        return
    end
    local current_mode = storage.chat_modes[player.index] or CHAT_MODES.GLOBAL
    if current_mode == CHAT_MODES.GLOBAL then
        set_chat_mode(player, CHAT_MODES.TEAM)
    elseif current_mode == CHAT_MODES.TEAM then
        set_chat_mode(player, CHAT_MODES.ALLIANCE)
    else
        set_chat_mode(player, CHAT_MODES.GLOBAL)
    end
end

local function create_gui_button(player)
    if get_chat_button(player) then
        return
    end
    local button
    if Gui.get_mod_gui_top_frame() then
        button =
            Gui.add_mod_button(
                player,
                {
                    type = 'sprite-button',
                    name = 'global_chat_toggle',
                    caption = '',
                    style = Gui.button_style,
                }
            )
        if button then
            button.style.font = 'default-semibold'
            button.style.minimal_width = 100
            button.style.minimal_height = 36
            button.style.maximal_height = 36
            button.style.padding = -2
            button.style.margin = 0
        end
    else
        button =
            player.gui.top.add(
                {
                    type = 'sprite-button',
                    name = 'global_chat_toggle',
                    caption = '',
                    style = Gui.button_style,
                }
            )
        button.style.font = 'heading-2'
        button.style.minimal_width = 100
        button.style.minimal_height = 38
        button.style.maximal_height = 38
        button.style.padding = 1
        button.style.margin = 0
    end
    set_chat_mode(player, CHAT_MODES.GLOBAL)
end

local function on_player_joined_game(event)
    create_gui_button(game.players[event.player_index])
end

local function on_gui_click(event)
    if not event or not event.element or not event.element.valid then
        return
    end
    if event.element.name ~= 'global_chat_toggle' then
        return
    end
    toggle(game.players[event.element.player_index])
end

local function get_recipients(current_mode, sender)
    if current_mode == CHAT_MODES.GLOBAL then
        return game.connected_players
    end
    if current_mode == CHAT_MODES.TEAM then
        return sender.force.connected_players
    end
    local recipients = {}
    for _, force in pairs(game.forces) do
        if force == sender.force or force.get_friend(sender.force) then
            for _, recipient in pairs(force.connected_players) do
                table.insert(recipients, recipient)
            end
        end
    end
    return recipients
end

local function on_console_chat(event)
    if not event.message or not event.player_index then
        return
    end
    local sender = game.players[event.player_index]
    local button = get_chat_button(sender)
    if not button or not button.valid then
        return
    end
    local current_mode = storage.chat_modes[sender.index] or CHAT_MODES.GLOBAL
    if current_mode == CHAT_MODES.GLOBAL then
        return
    end
    local prefix_color = BUTTON_PROPERTIES[current_mode][3]
    local color_string = string.format('#%02X%02X%02X', prefix_color.r * 255, prefix_color.g * 255, prefix_color.b * 255)
    local mode_prefixes = { [CHAT_MODES.GLOBAL] = 'Global', [CHAT_MODES.TEAM] = 'Team', [CHAT_MODES.ALLIANCE] = 'Alliance' }
    local prefix = '[color=' .. color_string .. ']' .. mode_prefixes[current_mode] .. '[/color]'
    local message = prefix .. ' ' .. sender.name .. ' ' .. sender.tag .. ': ' .. event.message
    for _, player in pairs(get_recipients(current_mode, sender)) do
        if player ~= sender then
            player.print(message, sender.chat_color)
        end
    end
end

local Event = require 'utils.event'
Event.add(defines.events.on_console_chat, on_console_chat)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)
