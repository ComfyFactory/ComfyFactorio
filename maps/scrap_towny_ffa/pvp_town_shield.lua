local Public = {}

local math_floor = math.floor
local math_sqrt = math.sqrt

local Score = require 'maps.scrap_towny_ffa.score'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local PvPShield = require 'maps.scrap_towny_ffa.pvp_shield'
local Team = require 'maps.scrap_towny_ffa.team'
local Event = require 'utils.event'

Public.offline_shield_size = (ScenarioTable.league_balance_shield_size() - 1)

local shield_radius = (ScenarioTable.league_balance_shield_size() - 1) / 2

function Public.get_town_control_range(town_center)
    return math.min(150 + town_center.evolution.worms * 140,
        ScenarioTable.min_distance_between_towns() - ScenarioTable.league_balance_shield_size() / 2 - 5)
end

function Public.enemy_players_near_town(town_center, max_distance, min_league)
    local market = town_center.market
    return Public.enemy_players_nearby(market.position, market.surface, market.force, max_distance, min_league)
end

function Public.enemy_players_nearby(position, surface, force, max_distance, min_league)
    for _, player in pairs(game.connected_players) do
        if player.surface == surface then
            local distance = math_floor(math_sqrt((player.position.x - position.x) ^ 2 + (player.position.y - position.y) ^ 2))
            if distance < max_distance and not Team.is_friendly_towards(player.force, force) then
                if (not min_league or Score.get_player_league(player) > min_league) and (player.character or player.driving) then
                    return true
                end
            end
        end
    end
    return false
end

local function update_pvp_shields_display()
    local this = ScenarioTable.get_table()
    for _, town_center in pairs(this.town_centers) do
        if town_center.pvp_shield_mgmt then
            local town_control_range = Public.get_town_control_range(town_center)
            local info_enemies
            local color
            if Public.enemy_players_near_town(town_center, town_control_range) then
                info_enemies = "Enemies"
                color = { 255, 0, 0 }

                if not town_center.enemies_warning_status then
                    town_center.market.force.print("Enemies have been spotted near your town. Your offline PvP shield can not activate now.", { r = 1, g = 0, b = 0 })
                    town_center.enemies_warning_status = 1
                end
            elseif Public.enemy_players_near_town(town_center, town_control_range + 10) then
                info_enemies = "Enemies"
                color = { 255, 255, 0 }
            else
                info_enemies = "No enemies"
                color = { 0, 255, 0 }
                town_center.enemies_warning_status = nil
            end
            info_enemies = info_enemies .. " (" .. string.format('%.0f', town_control_range) .. " tiles)"
            town_center.pvp_shield_mgmt.enemies_info = info_enemies
            town_center.pvp_shield_mgmt.enemies_color = color
        end
    end
end

local function town_shields_researched(force)
    return force.technologies["automation"].researched
end

local function update_pvp_shields()
    local this = ScenarioTable.get_table()
    local offline_shield_max_duration_ticks = 24 * 60 * 60 * 60
    local league_shield_activation_range = ScenarioTable.higher_league_activation_range()

    for _, town_center in pairs(this.town_centers) do
        local market = town_center.market
        local force = market.force
        local shield = this.pvp_shields[force.name]
        local shields_researched = town_shields_researched(force)
        local town_league = Score.get_town_league(town_center)
        local town_offline_or_afk = #force.connected_players == 0 or town_center.marked_afk
        local abandoned = false
        local high_league_no_shield = town_league >= 4

        local higher_league_nearby = Public.enemy_players_near_town(town_center, league_shield_activation_range, town_league)
        if higher_league_nearby then
            town_center.last_higher_league_nearby = game.tick
        end

        if town_offline_or_afk then
            if shields_researched and not high_league_no_shield then
                local is_init_now = false
                if town_center.pvp_shield_mgmt.offline_shield_eligible_until == nil then
                    is_init_now = true
                    town_center.pvp_shield_mgmt.offline_shield_eligible_until = game.tick + offline_shield_max_duration_ticks
                end
                local remaining_offline_shield_time = town_center.pvp_shield_mgmt.offline_shield_eligible_until - game.tick
                abandoned = remaining_offline_shield_time <= 0

                if (not shield or (shield and shield.shield_type == PvPShield.SHIELD_TYPE.OFFLINE_POST)) and not abandoned then
                    local min_coins = PvPShield.min_coins_for_shield()
                    if min_coins > 0 and town_center.coin_balance < min_coins then
                        if not town_center.pvp_shield_mgmt.insufficient_coins_hint
                            or game.tick - town_center.pvp_shield_mgmt.insufficient_coins_hint >= 60 * 60 then
                            town_center.pvp_shield_mgmt.insufficient_coins_hint = game.tick
                            force.print("Your offline PvP shield needs at least " .. min_coins
                                .. " town coins (deposit at the market). Balance: " .. town_center.coin_balance, { 255, 0, 0 })
                        end
                    elseif not Public.enemy_players_near_town(town_center, Public.get_town_control_range(town_center)) then
                        if is_init_now and not town_center.marked_afk then

                            game.print("The offline PvP Shield of " .. town_center.town_name .. " is activating now." ..
                                " It will last up to " .. PvPShield.format_lifetime_str(remaining_offline_shield_time) .. ".", { 255, 255, 0 })
                        end
                        if not shield then
                            PvPShield.add_shield(market.surface, market.force, market.position, Public.offline_shield_size,
                                game.tick + remaining_offline_shield_time, 0.5 * 60 * 60, PvPShield.SHIELD_TYPE.OFFLINE)
                        else
                            PvPShield.swap_shield_type(shield, PvPShield.SHIELD_TYPE.OFFLINE)
                            shield.expiry_time = game.tick + remaining_offline_shield_time
                        end
                    end
                end
            end
        else
            town_center.pvp_shield_mgmt.offline_shield_eligible_until = nil

            if shield and shield.shield_type == PvPShield.SHIELD_TYPE.OFFLINE then
                local delay_mins = 1
                force.print("Welcome back. Your offline protection will expire in " .. delay_mins .. " minute."
                    .. " After everyone in your town leaves, you will get a new shield for "
                    .. PvPShield.format_lifetime_str(offline_shield_max_duration_ticks), { 255, 255, 0 })
                PvPShield.swap_shield_type(shield, PvPShield.SHIELD_TYPE.OFFLINE_POST)
                shield.expiry_time = game.tick + delay_mins * 60 * 60
            end

            if shield and shield.shield_type == PvPShield.SHIELD_TYPE.OFFLINE_POST then
                local remaining_shield_time = shield.expiry_time - game.tick
                if not shield.last_hint or game.tick - shield.last_hint >= 60 * 10 then
                    shield.last_hint = game.tick
                    force.print("Time to shield deactivation: "
                        .. PvPShield.format_lifetime_str(remaining_shield_time), { 255, 255, 0 })
                end
            end

            if not town_center.pvp_shield_mgmt.displayed_offline_hint and shields_researched then
                local upkeep_hint = ''
                if ScenarioTable.enabled('pvp_shield_upkeep') then
                    local cost = PvPShield.upkeep_coins_per_minute(PvPShield.SHIELD_TYPE.OFFLINE)
                    local min_coins = PvPShield.min_coins_for_shield()
                    if cost > 0 then
                        upkeep_hint = " Deposit coins at the market — shields cost " .. cost
                            .. " coins/min (minimum " .. min_coins .. " to activate)."
                    end
                end
                force.print("Your town is now advanced enough to deploy PvP shields."
                    .. " Once all of your town members leave, your town will be protected from enemy players"
                    .. " for up to " .. PvPShield.format_lifetime_str(offline_shield_max_duration_ticks) .. "."
                    .. upkeep_hint
                    .. " However, biters will always be able to attack your town! Open Info (top bar) for details.", { 255, 255, 0 })
                town_center.pvp_shield_mgmt.displayed_offline_hint = true
            end
        end

        if higher_league_nearby and not abandoned and not high_league_no_shield then
            if shields_researched then

                if not shield or (shield and shield.shield_type ~= PvPShield.SHIELD_TYPE.LEAGUE_BALANCE) then
                    force.print("Your town deploys a Balancing PvP Shield because there are players of a higher league nearby", { 255, 255, 0 })
                    if not shield then
                        PvPShield.add_shield(market.surface, market.force, market.position,
                            ScenarioTable.league_balance_shield_size(), nil, 13 * 60, PvPShield.SHIELD_TYPE.LEAGUE_BALANCE)
                    else
                        PvPShield.swap_shield_type(shield, PvPShield.SHIELD_TYPE.LEAGUE_BALANCE)
                        shield.expiry_time = nil
                    end
                    update_pvp_shields_display()
                end
            else
                if town_center.last_higher_league_nearby_hint == nil or game.tick - town_center.last_higher_league_nearby_hint > 60 * 60 then
                    force.print("There are enemy players of a higher league, " ..
                        "but your town can't deploy a shield without automation research", { 255, 0, 0 })
                    town_center.last_higher_league_nearby_hint = game.tick
                end
            end
        end

        if high_league_no_shield and shield then
            PvPShield.remove_shield(shield)
            shield = nil
        end

        local protect_time_after_nearby = 3 * 60 * 60
        if shield and shield.shield_type == PvPShield.SHIELD_TYPE.LEAGUE_BALANCE and not higher_league_nearby and game.tick - town_center.last_higher_league_nearby > protect_time_after_nearby then
            if town_offline_or_afk then
                PvPShield.swap_shield_type(shield, PvPShield.SHIELD_TYPE.OFFLINE)
                shield.expiry_time = town_center.pvp_shield_mgmt.offline_shield_eligible_until
            else
                PvPShield.remove_shield(shield)
                shield = nil
            end
        end

        local shield_info = 'League ' .. town_league
        if shield then
            shield_info = shield_info .. ', PvP Shield: '
            local lifetime_str = PvPShield.format_lifetime_str(PvPShield.remaining_lifetime(shield))
            if shield.shield_type == PvPShield.SHIELD_TYPE.OFFLINE or shield.shield_type == PvPShield.SHIELD_TYPE.OFFLINE_POST then
                shield_info = shield_info .. 'While offline/afk, max ' .. lifetime_str
            elseif shield.shield_type == PvPShield.SHIELD_TYPE.LEAGUE_BALANCE then
                shield_info = shield_info .. 'League balance'
            end
            local upkeep = PvPShield.upkeep_coins_per_minute(shield.shield_type)
            if upkeep > 0 then
                shield_info = shield_info .. ', ' .. upkeep .. ' coins/min'
            end
        else
            if abandoned then
                shield_info = shield_info .. ', Abandoned town'
            elseif high_league_no_shield then
                shield_info = shield_info .. ', No shield (League 4)'
            elseif not shields_researched then
                shield_info = shield_info .. ', Shield not researched'
            else
                local min_coins = PvPShield.min_coins_for_shield()
                if min_coins > 0 and town_center.coin_balance < min_coins then
                    shield_info = shield_info .. ', Need ' .. min_coins .. ' coins for shield'
                else
                    shield_info = shield_info .. ', Shield standby'
                end
            end
        end
        town_center.pvp_shield_mgmt.shield_info = shield_info
        town_center.pvp_shield_mgmt.is_abandoned = abandoned
    end
end

local function update_leagues()
    if game.tick == 0 then return end

    local this = ScenarioTable.get_table()
    for _, player in pairs(game.connected_players) do
        if player.character then
            local league = Score.get_player_league(player)

            if this.previous_leagues[player.index] ~= nil and league ~= this.previous_leagues[player.index] then
                player.print("You are now in League " .. league, { 255, 255, 0 })
                if league == 4 and this.previous_leagues[player.index] < 4 then
                    player.print(" --> Your town can not deploy offline PvP shields anymore", { 255, 0, 0 })
                    if Score.l4_score_only_offline then
                        player.print(" --> Your town only gets survival score while you are offline (Game mode setting)", { 255, 0, 0 })
                    end
                end
            end
            this.previous_leagues[player.index] = league
        end
    end
end

local function get_shield_max_area(position)
    return { { position.x - shield_radius, position.y - shield_radius }, { position.x + shield_radius, position.y + shield_radius } }
end

local function all_players_near_center(town_center)
    local market = town_center.market
    local force = market.force

    for _, player in pairs(force.connected_players) do
        local pp = player.position
        local mp = market.position
        if math.sqrt((pp.x - mp.x) ^ 2 + (pp.y - mp.y) ^ 2) > 10 then
            return false
        end
    end
    return true
end

function Public.request_afk_shield(town_center, player)
    local market = town_center.market
    local this = ScenarioTable.get()
    local force = market.force
    local surface = market.surface
    local town_control_range = Public.get_town_control_range(town_center)

    if all_players_near_center(town_center) then
        if not Public.enemy_players_near_town(town_center, town_control_range) then
            if town_shields_researched(force) then
                if surface.count_entities_filtered(
                        { area = get_shield_max_area(market.position),
                            type = "unit", force = game.forces.enemy, limit = 1
                        }) == 0 then
                    town_center.marked_afk = true
                    local shield = this.pvp_shields[force.name]
                    if shield then
                        PvPShield.remove_shield(shield)
                    end
                    surface.play_sound({ path = 'utility/scenario_message', position = player.position, volume_modifier = 1 })
                    force.print("You have enabled AFK mode. Move away from the town center to end it.", { 255, 255, 0 })
                    update_pvp_shields()
                else
                    player.print("Biters are within the town range, can't enter AFK mode", { 255, 0, 0 })
                end
            else
                player.print("You need to research automation to enable shields", { 255, 0, 0 })
            end
        else
            player.print("Enemy players are too close, can't enter AFK mode", { 255, 0, 0 })
        end
    else
        player.print("To activate AFK mode, all players need to gather near the town center", { 255, 0, 0 })
    end
end

local function update_afk_shields()
    local this = ScenarioTable.get()

    for _, town_center in pairs(this.town_centers) do
        local force = town_center.market.force
        if town_center.marked_afk then
            local players_online = #force.connected_players > 0
            if players_online and not all_players_near_center(town_center) then
                town_center.marked_afk = false
                force.print("AFK mode has ended because players moved", { 255, 255, 0 })
                local shield = this.pvp_shields[force.name]
                if shield then
                    PvPShield.remove_shield(shield)
                end
            elseif not players_online then
                town_center.marked_afk = false
            end
        end
    end
end

local function on_player_left_game()
    update_pvp_shields()
end

function Public.init_town()
    update_pvp_shields()
end

Event.on_nth_tick(31, update_pvp_shields_display)
Event.on_nth_tick(31, update_pvp_shields)
Event.on_nth_tick(31, update_leagues)
Event.on_nth_tick(13, update_afk_shields)
Event.add(defines.events.on_player_left_game, on_player_left_game)

return Public
