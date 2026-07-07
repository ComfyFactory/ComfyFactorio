local Event = require 'utils.event'
local Gui = require 'utils.gui'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local PvPShield = require 'maps.scrap_towny_ffa.pvp_shield'

local Public = {}

local info = [[This is Comfy Towny. Who will survive?

In this mode, players build towns and fight against other towns and the biters.
The winner is the first town to reach the research progress goal.
Offline time does not add progress.
The Comfy gui has been disabled since it contains too many goodies.

Have fun ^.^]]

local function pvp_shield_help_text()
    local offline_enabled = ScenarioTable.enabled('pvp_offline_shield') or ScenarioTable.enabled('pvp_afk_shield')
    local league_enabled = ScenarioTable.enabled('pvp_league_shield')
    local help = 'Requires Automation research.\n'
    if offline_enabled then
        help = help .. 'Offline shield: when all town members leave (or AFK mode is on), enemy players cannot attack or build inside the shield for up to 24 hours total.\n'
            .. 'Biters are never blocked. Shield will not activate if enemy players are near your town.\n'
    else
        help = help .. 'Offline and AFK PvP shields are disabled in this game mode.\n'
    end
    if league_enabled then
        help = help .. 'League balance shield deploys when higher-league enemies are nearby. League 4 towns cannot use PvP shields.'
    end
    if not ScenarioTable.enabled('pvp_shield_upkeep') then
        return help
    end
    local offline_cost = PvPShield.upkeep_coins_per_minute(PvPShield.SHIELD_TYPE.OFFLINE)
    local league_cost = PvPShield.upkeep_coins_per_minute(PvPShield.SHIELD_TYPE.LEAGUE_BALANCE)
    local min_coins = PvPShield.min_coins_for_shield()
    local upkeep_line = '\nShields cost town coins while active. To drop coins in the market, use a loader.'
    if offline_enabled and offline_cost > 0 then
        upkeep_line = upkeep_line .. ' Offline shield: ' .. offline_cost .. ' coins/min.'
    end
    if league_enabled and league_cost > 0 then
        upkeep_line = upkeep_line .. ' League balance shield: ' .. league_cost .. ' coins/min.'
    end
    if offline_enabled and min_coins > 0 then
        upkeep_line = upkeep_line .. ' Minimum ' .. min_coins .. ' coins to activate.'
    end
    return help .. upkeep_line
end

local function pvp_info_enabled()
    return ScenarioTable.enabled('pvp_offline_shield') or ScenarioTable.enabled('pvp_league_shield')
        or ScenarioTable.enabled('pvp_afk_shield')
end

local function get_info_button(player)
    if Gui.get_mod_gui_top_frame() then
        return Gui.get_button_flow(player)['towny_map_intro_button']
    end
    return player.gui.top['towny_map_intro_button']
end

function Public.toggle_button(player)
    if get_info_button(player) then
        return
    end
    local b
    if Gui.get_mod_gui_top_frame() then
        b =
            Gui.add_mod_button(
                player,
                {
                    type = 'sprite-button',
                    caption = 'Info',
                    name = 'towny_map_intro_button',
                    tooltip = 'Show Info',
                    style = Gui.button_style
                }
            )
        if b then
            b.style.font_color = { r = 0.5, g = 0.3, b = 0.99 }
            b.style.font = 'default-semibold'
            b.style.minimal_height = 36
            b.style.maximal_height = 36
            b.style.minimal_width = 60
            b.style.padding = -2
        end
    else
        b = player.gui.top.add({ type = 'sprite-button', caption = 'Info', name = 'towny_map_intro_button', tooltip = 'Show Info', style = Gui.button_style })
        b.style.font_color = { r = 0.5, g = 0.3, b = 0.99 }
        b.style.font = 'heading-1'
        b.style.minimal_height = 38
        b.style.maximal_height = 38
        b.style.minimal_width = 80
        b.style.top_padding = 1
        b.style.left_padding = 1
        b.style.right_padding = 1
        b.style.bottom_padding = 1
    end
end

function Public.show(player)
    if player.gui.center['towny_map_intro_frame'] then
        player.gui.center['towny_map_intro_frame'].destroy()
    end
    local frame = player.gui.center.add { type = 'frame', name = 'towny_map_intro_frame' }
    frame = frame.add { type = 'frame', direction = 'vertical' }

    local t = frame.add { type = 'table', column_count = 2 }

    local label = t.add { type = 'label', caption = 'COMFY Towny' }
    label.style.font = 'heading-1'
    label.style.font_color = { r = 0.85, g = 0.85, b = 0.85 }
    label.style.right_padding = 8

    frame.add { type = 'line' }
    local l2 = frame.add { type = 'label', caption = info }
    l2.style.single_line = false
    l2.style.font = 'heading-2'
    l2.style.font_color = { r = 0.8, g = 0.7, b = 0.99 }
    if pvp_info_enabled() then
        frame.add { type = 'line' }
        local help_title = frame.add { type = 'label', caption = 'About PvP shields' }
        help_title.style.font = 'default-bold'
        help_title.style.top_margin = 4
        local help = frame.add { type = 'label', caption = pvp_shield_help_text() }
        help.style.single_line = false
        help.style.font_color = { r = 0.75, g = 0.75, b = 0.75 }
    end
end

function Public.close(event)
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    local parent = event.element.parent
    for _ = 1, 4, 1 do
        if not parent then
            return
        end
        if parent.name == 'towny_map_intro_frame' then
            parent.destroy()
            return
        end
        parent = parent.parent
    end
end

function Public.toggle(event)
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    if event.element.name == 'towny_map_intro_button' then
        local player = game.players[event.player_index]
        if player.gui.center['towny_map_intro_frame'] then
            player.gui.center['towny_map_intro_frame'].destroy()
        else
            Public.show(player)
        end
    end
end

local function get_last_winner_button(player)
    if Gui.get_mod_gui_top_frame() then
        return Gui.get_button_flow(player)['towny_map_last_winner']
    end
    return player.gui.top['towny_map_last_winner']
end

function Public.update_last_winner_name(player)
    local element = get_last_winner_button(player)
    if not storage.last_winner_name or storage.last_winner_name == '' then
        if element and element.valid then
            element.destroy()
        end
        return
    end
    if element and element.valid then
        element.caption = 'Last round winner: ' .. storage.last_winner_name
    else
        Public.add_last_winner_button(player)
    end
end

function Public.add_last_winner_button(player)
    if not storage.last_winner_name or storage.last_winner_name == '' then
        local element = get_last_winner_button(player)
        if element and element.valid then
            element.destroy()
        end
        return
    end
    local existing = get_last_winner_button(player)
    if existing and existing.valid then
        existing.caption = 'Last round winner: ' .. storage.last_winner_name
        return
    end
    if Gui.get_mod_gui_top_frame() then
        local button = Gui.add_mod_button(player,
            {
                type = 'sprite-button',
                caption = 'Last round winner: ' .. storage.last_winner_name,
                name = 'towny_map_last_winner',
                style = Gui.button_style,
            })
        if button then
            button.style.font_color = { r = 1, g = 0.7, b = 0.1 }
            button.style.minimal_height = 36
            button.style.maximal_height = 36
            button.style.maximal_width = 480
            button.style.padding = -2
        end
    else
        local button = player.gui.top.add
            {
                type = 'sprite-button',
                caption = 'Last round winner: ' .. storage.last_winner_name,
                name = 'towny_map_last_winner'
            }
        button.style.font_color = { r = 1, g = 0.7, b = 0.1 }
        button.style.minimal_height = 36
        button.style.minimal_width = 480
    end
end

local function on_gui_click(event)
    Public.close(event)
    Public.toggle(event)
end

Event.add(defines.events.on_gui_click, on_gui_click)

return Public
