local Public = {}

local math_max = math.max
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Event = require 'utils.event'

local score_to_win = ScenarioTable.score('research_points_to_win')
Public.score_to_win = score_to_win

local max_survival_time_score = 80
local max_survival_time_score_lower_leagues = 30
local l4_offline_min_period_hours = 2
local l4_offline_min_period_ticks = l4_offline_min_period_hours * 60 * 60 * 60

local function survival_points_enabled()
    return ScenarioTable.survival_points_enabled()
end

local function max_research_score()
    return survival_points_enabled() and 60 or score_to_win
end

local function age_score_factor()
    return ScenarioTable.game_mode('age_score_factor')
end

local function research_evo_score_factor()
    return ScenarioTable.score('research_evo_score_factor') or ScenarioTable.game_mode('research_evo_score_factor')
end

local function l4_score_only_offline()
    return ScenarioTable.game_mode('l4_score_only_offline')
end

function Public.research_score(town_center)
    return math.min(town_center.evolution.worms * research_evo_score_factor(), max_research_score())
end

function Public.survival_time_h(town_center)
    return (town_center.survival_time_ticks or 0) / 60 / 3600
end

function Public.total_score(town_center)
    if survival_points_enabled() then
        return Public.research_score(town_center) + Public.survival_score(town_center)
    end
    return Public.research_score(town_center)
end

function Public.survival_score(town_center)
    return math.min(Public.survival_time_h(town_center) * age_score_factor(), max_survival_time_score)
end

local function format_score(score)
    return string.format('%.1f', math.floor(score * 10) / 10)
end
Public.format_score = format_score

local function format_town_with_player_names(town_center)
    local player_names = ""
    local player_in_town_name = false
    for _, player in pairs(town_center.market.force.players) do
        if not string.find(town_center.town_name, player.name) then
            if player_names ~= "" then
                player_names = player_names .. ", "
            end
            player_names = player_names .. player.name
        else
            player_in_town_name = true
        end
    end
    if player_names ~= "" then
        if player_in_town_name then
            player_names = "+" .. player_names
        end
        player_names = " (" .. player_names .. ")"
    end
    return town_center.town_name .. player_names
end

function Public.get_town_league(town_center)
    local score = Public.total_score(town_center)
    local tank_researched = town_center.market.force.technologies['tank'].researched

    if score >= 60 then return 4 end
    if score >= 35 then return 3 end
    if score >= 15 or tank_researched then return 2 end
    return 1
end

function Public.get_player_league(player)
    local this = ScenarioTable.get_table()
    local town_center = this.town_centers[player.force.name]

    local league
    if player.character and player.character.vehicle and player.character.vehicle.name == "tank" then
        league = 2
    else
        league = 1
    end

    if town_center then
        local town_league = Public.get_town_league(town_center)
        league = math_max(town_league, league)
    end

    return league
end

local function update_scoring_last_online(this)
    for _, town_center1 in pairs(this.town_centers) do
        if #town_center1.market.force.connected_players > 0 then
            town_center1.scoring_last_online = game.tick
        end
        for _, town_center2 in pairs(this.town_centers) do
            local tc2_force = town_center2.market.force
            if #tc2_force.connected_players > 0 and town_center1.market.force.get_friend(tc2_force) then
                town_center1.scoring_last_online = game.tick
            end
        end
    end
end

local function should_increment_survival_time(town_center, shield)
    if not survival_points_enabled() then
        return false
    end

    if l4_score_only_offline() then
        if shield then
            return false
        end
        if Public.get_town_league(town_center) >= 4
            and game.tick - (town_center.scoring_last_online or 0) <= l4_offline_min_period_ticks then
            return false
        end
        if Public.get_town_league(town_center) < 4
            and Public.survival_score(town_center) >= max_survival_time_score_lower_leagues then
            return false
        end
        return true
    end

    local force = town_center.market.force
    return #force.connected_players > 0 and not town_center.marked_afk
end

local score_update_loop_interval = 60
local function update_score()
    local this = ScenarioTable.get_table()

    if survival_points_enabled() and l4_score_only_offline() then
        update_scoring_last_online(this)
    end

    local town_highest_score = 0
    local town_total_scores = {}
    for _, town_center in pairs(this.town_centers) do
        local market = town_center.market
        local force = market.force
        local shield = this.pvp_shields and this.pvp_shields[force.name]

        if should_increment_survival_time(town_center, shield) then
            town_center.survival_time_ticks = (town_center.survival_time_ticks or 0) + score_update_loop_interval
        end

        town_total_scores[town_center] = Public.total_score(town_center)
        if town_total_scores[town_center] > town_highest_score then
            town_highest_score = town_total_scores[town_center]
        end

        if town_total_scores[town_center] >= score_to_win and this.winner == nil then
            this.winner = town_center.town_name
            local town_with_player_names = format_town_with_player_names(town_center)

            game.print(town_with_player_names .. " has won the game!", { 255, 255, 0 })

            storage.last_winner_name = town_with_player_names
            log("WINNER_STORE=\"" .. town_with_player_names .. "\"")
            if ScenarioTable.enabled('persist_last_winner') then
                ScenarioTable.persist_settings()
            end
            if storage.auto_reset_enabled then
                storage.game_end_sequence_start = game.tick + 600
            else
                game.print("Automatic map restart is disabled, please wait for an admin to start a new game", { 255, 255, 0 })
            end
        end
    end

    if ScenarioTable.enabled('score_milestone_announcements') then
        if this.next_high_score_announcement == 0 then
            this.next_high_score_announcement = 70
        end
        if town_highest_score >= this.next_high_score_announcement then
            local score_name = survival_points_enabled() and " score." or " research progress."
            local end_name = survival_points_enabled() and " score" or " research progress"
            game.print("A town has reached " .. format_score(town_highest_score) .. score_name ..
                " The game ends at " .. score_to_win .. end_name, { 255, 255, 0 })
            if town_highest_score >= 70 then
                this.next_high_score_announcement = 80
            end
            if town_highest_score >= 80 then
                this.next_high_score_announcement = 90
            end
            if town_highest_score >= 90 then
                this.next_high_score_announcement = 95
            end
            if town_highest_score >= 95 then
                this.next_high_score_announcement = 9999
            end
        end
    end
end

Event.on_nth_tick(score_update_loop_interval, update_score)

return Public
