local Public = {}

local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Event = require 'utils.event'
local Score = require 'maps.scrap_towny_ffa.score'
local Team = require 'maps.scrap_towny_ffa.team'
local TownCenter = require 'maps.scrap_towny_ffa.town_center'
local Reset = require 'maps.scrap_towny_ffa.reset'
local mod_gui = require('mod-gui')
local Gui = require 'utils.gui'

local button_id = 'towny-score-button'
local survival_mode = ScenarioTable.mode('win_condition') == 'survival'
local survival_points_enabled = ScenarioTable.score('survival_points')

local survival_col_widths = { 52, 240, 96 }
local survival_col_align = { 'center', 'left', 'right' }
local points_col_widths = { 52, 160, 56, 72, 72, 64 }
local points_col_align = { 'center', 'left', 'center', 'right', 'right', 'right' }
local research_col_widths = { 52, 240, 56, 112 }
local research_col_align = { 'center', 'left', 'center', 'right' }

local function style_table_column(label, column, widths, alignments)
    label.style.horizontal_align = alignments[column]
    label.style.minimal_width = widths[column]
    if column == 2 then
        label.style.horizontally_stretchable = true
    end
end

local function add_table_label(table_element, column, caption, widths, alignments)
    local label = table_element.add { type = 'label', caption = caption }
    style_table_column(label, column, widths, alignments)
    return label
end

local function spairs(t, order)
    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
    end
    if order then
        table.sort(keys, function (a, b) return order(t, a, b) end)
    else
        table.sort(keys, function (a, b) return t[b] < t[a] end)
    end
    local i = 0
    return function ()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function Public.add_score_button(player)
    local existing
    if Gui.get_mod_gui_top_frame() then
        existing = Gui.get_button_flow(player)[button_id]
    else
        existing = player.gui.top[button_id]
    end
    if existing and existing.valid then
        existing.destroy()
    end
    local caption = survival_mode and 'Survival' or 'Towns'
    local tooltip = survival_mode and 'Toggle town survival leaderboard' or 'Toggle town leaderboard'
    local button
    if Gui.get_mod_gui_top_frame() then
        button = Gui.add_mod_button(player,
            {
                type = 'sprite-button',
                caption = caption,
                name = button_id,
                tooltip = tooltip,
                style = Gui.button_style
            })
        if button then
            button.style.font = 'default-bold'
            button.style.font_color = { r = 1, g = 0.7, b = 0.1 }
            button.style.minimal_height = 36
            button.style.maximal_height = 36
            button.style.minimal_width = 80
            button.style.padding = -2
        end
    else
        button = player.gui.top.add { type = 'sprite-button', caption = caption, name = button_id, tooltip = tooltip }
        button.style.font = 'default-bold'
        button.style.font_color = { r = 1, g = 0.7, b = 0.1 }
        button.style.minimal_height = 38
        button.style.minimal_width = 80
    end
end

function Public.close_panel(player)
    local this = ScenarioTable.get_table()
    local frame = this.score_gui_frame and this.score_gui_frame[player.index]
    if frame and frame.valid then
        frame.visible = false
    end
end

local function on_gui_click(event)
    local element = event.element
    if not element or not element.valid or element.name ~= button_id then
        return
    end
    local player = game.get_player(event.player_index)
    local this = ScenarioTable.get_table()
    local saved_frame = this.score_gui_frame[player.index]
    if saved_frame and saved_frame.valid then
        if saved_frame.visible then
            saved_frame.visible = false
        else
            require('maps.scrap_towny_ffa.town_status').close_panel(player)
            saved_frame.visible = true
        end
    end
end

local function init_score_board(player)
    local this = ScenarioTable.get_table()
    local player_index = player.index
    local saved_frame = this.score_gui_frame[player_index]
    if saved_frame and saved_frame.valid then
        return
    end
    local caption = survival_mode and 'Town survival' or 'Town leaderboard'
    local flow = mod_gui.get_frame_flow(player)
    local frame = flow.add { type = 'frame', style = mod_gui.frame_style, caption = caption, direction = 'vertical', name = 'towny_leaderboard_frame' }
    frame.style.vertically_stretchable = false
    this.score_gui_frame[player_index] = frame
end

local function update_points_scoreboard()
    local this = ScenarioTable.get_table()
    local outlander_online = 0
    for _, player in pairs(game.players) do
        if Team.is_outlander(player.force) and player.connected then
            outlander_online = outlander_online + 1
        end
    end

    for _, player in pairs(game.connected_players) do
        local frame = this.score_gui_frame[player.index]
        if not (frame and frame.valid) then
            init_score_board(player)
            frame = this.score_gui_frame[player.index]
        end
        if frame and frame.valid then
            frame.clear()
            local inner_frame = frame.add { type = 'frame', style = 'inside_shallow_frame', direction = 'vertical' }
            local subheader = inner_frame.add { type = 'frame', style = 'subheader_frame' }
            subheader.style.horizontally_stretchable = true
            local caption = 'Reach ' .. Score.score_to_win .. ' points to win!   Players online: ' .. #game.connected_players
            if not survival_points_enabled then
                caption = 'Reach ' .. Score.score_to_win .. ' research progress to win!   Players online: ' .. #game.connected_players
            end
            subheader.add { type = 'label', style = 'subheader_label', caption = caption }

            local column_count = survival_points_enabled and 6 or 4
            local col_widths = survival_points_enabled and points_col_widths or research_col_widths
            local col_align = survival_points_enabled and points_col_align or research_col_align
            local ranking_table = inner_frame.add { type = 'table', column_count = column_count, style = 'bordered_table' }
            ranking_table.style.margin = 4
            ranking_table.style.horizontally_stretchable = true
            local header_captions = survival_points_enabled and { 'Rank', 'Town', 'League', 'Research', 'Survival', 'Score' }
                or { 'Rank', 'Town', 'League', 'Research Progress' }
            for i = 1, column_count do
                local header = add_table_label(ranking_table, i, header_captions[i], col_widths, col_align)
                header.style.font = 'default-bold'
            end

            local town_total_scores = {}
            for _, town_center in pairs(this.town_centers) do
                town_total_scores[town_center] = Score.total_score(town_center)
            end

            local rank = 1
            for town_center, _ in spairs(town_total_scores, function (t, a, b) return t[b] < t[a] end) do
                local force = town_center.market.force
                local position = add_table_label(ranking_table, 1, '#' .. rank, col_widths, col_align)
                if town_center == this.town_centers[player.force.name] then
                    position.style.font = 'default-semibold'
                    position.style.font_color = { r = 1, g = 1 }
                end
                local label_extra = ''
                if town_center.marked_afk then
                    label_extra = ' (AFK)'
                end
                if town_center.pvp_shield_mgmt and town_center.pvp_shield_mgmt.is_abandoned then
                    label_extra = label_extra .. ' (Abandoned)'
                end
                local label = add_table_label(ranking_table, 2, town_center.town_name .. ' (' .. #force.connected_players .. '/' .. #force.players .. ')' .. label_extra, col_widths, col_align)
                label.style.font = 'default-semibold'
                label.style.font_color = town_center.color
                if ScenarioTable.enabled('town_rest_bonus') and town_center.town_rest then
                    label.tooltip = 'Town rest bonus: ' .. TownCenter.format_rest_modifier(town_center.town_rest.current_modifier or 0)
                end
                add_table_label(ranking_table, 3, tostring(Score.get_town_league(town_center)), col_widths, col_align)
                add_table_label(ranking_table, 4, Score.format_score(Score.research_score(town_center)), col_widths, col_align)
                if survival_points_enabled then
                    add_table_label(ranking_table, 5, string.format('%.1fh', Score.survival_time_h(town_center)), col_widths, col_align)
                    add_table_label(ranking_table, 6, Score.format_score(town_total_scores[town_center]), col_widths, col_align)
                end
                rank = rank + 1
            end

            add_table_label(ranking_table, 1, '-', col_widths, col_align)
            add_table_label(ranking_table, 2, 'Outlanders (' .. outlander_online .. ')', col_widths, col_align)
            add_table_label(ranking_table, 3, '-', col_widths, col_align)
            add_table_label(ranking_table, 4, '-', col_widths, col_align)
            if survival_points_enabled then
                add_table_label(ranking_table, 5, '-', col_widths, col_align)
                add_table_label(ranking_table, 6, '-', col_widths, col_align)
            end
        end
    end
end

local function update_survival_scoreboard()
    local this = ScenarioTable.get_table()
    for _, player in pairs(game.connected_players) do
        if this.winner then
            Reset.show_mvps(player)
        else
            local frame = this.score_gui_frame[player.index]
            if not (frame and frame.valid) then
                init_score_board(player)
            end
            frame = this.score_gui_frame[player.index]
            if frame and frame.valid then
                frame.clear()
                local inner_frame = frame.add { type = 'frame', style = 'inside_shallow_frame', direction = 'vertical' }
                local subheader = inner_frame.add { type = 'frame', style = 'subheader_frame' }
                subheader.style.horizontally_stretchable = true
                subheader.style.vertical_align = 'center'
                local days = this.required_time_to_win / 24
                subheader.add
                {
                    type = 'label',
                    style = 'subheader_label',
                    caption = 'Survive for ' .. days .. ' days (' .. this.required_time_to_win .. 'h) to win!'
                }
                local information_table = inner_frame.add { type = 'table', column_count = 3, style = 'bordered_table' }
                information_table.style.margin = 4
                information_table.style.horizontally_stretchable = true
                local header_captions = { 'Rank', 'Town (players online/total)', 'Survival time' }
                for i = 1, 3 do
                    local header = add_table_label(information_table, i, header_captions[i], survival_col_widths, survival_col_align)
                    header.style.font = 'default-bold'
                end
                local town_ages = {}
                for _, town_center in pairs(this.town_centers) do
                    if town_center ~= nil then
                        town_ages[town_center] = game.tick - town_center.creation_tick
                    end
                end
                local rank = 1
                for town_center, age in spairs(town_ages) do
                    local position = add_table_label(information_table, 1, '#' .. rank, survival_col_widths, survival_col_align)
                    if town_center == this.town_centers[player.force.name] then
                        position.style.font = 'default-semibold'
                        position.style.font_color = { r = 1, g = 1 }
                    end
                    local label = add_table_label(
                        information_table,
                        2,
                        town_center.town_name .. ' (' .. #town_center.market.force.connected_players .. '/' .. #town_center.market.force.players .. ')',
                        survival_col_widths,
                        survival_col_align
                    )
                    label.style.font = 'default-semibold'
                    label.style.font_color = town_center.color
                    local age_hours = age / 60 / 3600
                    local total_age = string.format('%.1f', age_hours)
                    add_table_label(information_table, 3, total_age .. 'h', survival_col_widths, survival_col_align)
                    rank = rank + 1
                    if tonumber(total_age) >= this.required_time_to_win then
                        this.winner =
                        {
                            name = town_center.town_name,
                            research_counter = town_center.research_counter,
                            upgrades = town_center.upgrades,
                            health = town_center.health,
                            coin_balance = town_center.coin_balance
                        }
                    end
                end
                add_table_label(information_table, 1, '-', survival_col_widths, survival_col_align)
                local outlander_on = #game.forces['player'].connected_players + #game.forces['rogue'].connected_players
                local outlander_total = #game.forces['player'].players + #game.forces['rogue'].players
                local outlander_label = add_table_label(information_table, 2, 'Outlanders (' .. outlander_on .. '/' .. outlander_total .. ')', survival_col_widths, survival_col_align)
                outlander_label.style.font_color = { 170, 170, 170 }
                add_table_label(information_table, 3, '-', survival_col_widths, survival_col_align)
            end
        end
    end
end

local function update_score_board()
    if survival_mode then
        update_survival_scoreboard()
    else
        update_points_scoreboard()
    end
end

Event.add(defines.events.on_gui_click, on_gui_click)
Event.on_nth_tick(60, update_score_board)

return Public
