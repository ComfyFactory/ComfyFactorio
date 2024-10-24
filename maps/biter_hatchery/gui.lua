local Public = {}
local Team = require 'maps.biter_hatchery.team'
local Server = require 'utils.server'

function Public.spectate_button(player)
    if player.gui.top.spectate_button then
        return
    end
    local button = player.gui.top.add({ type = 'button', name = 'spectate_button', caption = 'Spectate' })
    button.style.font = 'default-bold'
    button.style.font_color = { r = 0.0, g = 0.0, b = 0.0 }
    button.style.minimal_height = 38
    button.style.minimal_width = 38
    button.style.top_padding = 2
    button.style.left_padding = 4
    button.style.right_padding = 4
    button.style.bottom_padding = 2
end

function Public.unit_health_buttons(player)
    if player.gui.top.health_boost_west then
        return
    end
    local button = player.gui.top.add({ type = 'sprite-button', name = 'health_boost_west', caption = 1, tooltip = 'Health modfier of west side biters.\nIncreases by feeding.' })
    button.style.font = 'heading-1'
    button.style.font_color = { r = 0, g = 180, b = 0 }
    button.style.minimal_height = 38
    button.style.minimal_width = 78
    button.style.padding = 2
    button = player.gui.top.add({ type = 'sprite-button', name = 'health_boost_east', caption = 1, tooltip = 'Health modfier of east side biters.\nIncreases by feeding.' })
    button.style.font = 'heading-1'
    button.style.font_color = { r = 180, g = 180, b = 0 }
    button.style.minimal_height = 38
    button.style.minimal_width = 78
    button.style.padding = 2
end

function Public.update_health_boost_buttons(player)
    local gui = player.gui.top
    gui.health_boost_west.caption = math.round(storage.map_forces.west.unit_health_boost * 100, 1) .. '%'
    gui.health_boost_east.caption = math.round(storage.map_forces.east.unit_health_boost * 100, 1) .. '%'
end

local function create_spectate_confirmation(player)
    if player.gui.center.spectate_confirmation_frame then
        return
    end
    local frame = player.gui.center.add({ type = 'frame', name = 'spectate_confirmation_frame', caption = 'Are you sure you want to spectate this round?' })
    frame.style.font = 'default'
    frame.style.font_color = { r = 0.3, g = 0.65, b = 0.3 }
    frame.add({ type = 'button', name = 'confirm_spectate', caption = 'Spectate' })
    frame.add({ type = 'button', name = 'cancel_spectate', caption = 'Cancel' })
end

function Public.rejoin_question(hatchery)
    if game.tick % 90 ~= 0 then
        return
    end
    for _, player in pairs(game.forces.spectator.players) do
        if not player.gui.center.rejoin_question_frame then
            local frame = player.gui.center.add({ type = 'frame', name = 'rejoin_question_frame', caption = 'Rejoin the game?' })
            frame.style.font = 'default'
            frame.style.font_color = { r = 0.3, g = 0.65, b = 0.3 }
            frame.add({ type = 'button', name = 'confirm_rejoin', caption = 'Rejoin' })
            frame.add({ type = 'button', name = 'cancel_rejoin', caption = 'Cancel' })
        end
    end
    hatchery.reset_counter = hatchery.reset_counter + 1
    local message = 'Biter Hatchery round #' .. hatchery.reset_counter .. ' has begun!'
    game.print(message, { 180, 0, 250 })
    Server.to_discord_bold(table.concat { '*** ', message, ' ***' })
    for _, player in pairs(game.connected_players) do
        player.play_sound { path = 'utility/new_objective', volume_modifier = 0.85 }
    end
    hatchery.gamestate = 'game_in_progress'
    print(hatchery.gamestate)
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

    if event.element.name == 'confirm_rejoin' then
        player.gui.center['rejoin_question_frame'].destroy()
        Team.assign_force_to_player(player)
        Team.teleport_player_to_spawn(player)
        Team.add_player_to_team(player)
        game.print(player.name .. ' has rejoined the game!')
        return
    end
    if event.element.name == 'cancel_rejoin' then
        player.gui.center['rejoin_question_frame'].destroy()
        return
    end

    if player.force.name == 'spectator' then
        return
    end
    if event.element.name == 'cancel_spectate' then
        player.gui.center['spectate_confirmation_frame'].destroy()
        return
    end
    if event.element.name == 'confirm_spectate' then
        player.gui.center['spectate_confirmation_frame'].destroy()
        Team.set_player_to_spectator(player)
        game.print(player.name .. ' has turned into a spectator ghost.')
        return
    end
    if event.element.name == 'spectate_button' then
        if player.gui.center['spectate_confirmation_frame'] then
            player.gui.center['spectate_confirmation_frame'].destroy()
        else
            create_spectate_confirmation(player)
        end
        return
    end
end

local event = require 'utils.event'
event.add(defines.events.on_gui_click, on_gui_click)

return Public
