
local Public = {}

local Global = require 'utils.global'
local Event = require 'utils.event'

local config =
{
    win_condition = 'score',
    map_mode = 'procedural',
    laser_limits = 'slots',
    outlander_forces = 'shared',
    chat_mode = 'global',
    damage_pipeline = 'towny',
    game_mode = 2,
    survival =
    {
        hours = 72,
    },
    wreckage =
    {
        amount_scale = 0.5,
        scrap_amount_modifier = 1.5,
    },
    pvp_shield =
    {
        upkeep_coins_per_minute = 3,
        league_upkeep_coins_per_minute = 0,
        min_coins_to_activate = 30,
        low_balance_warning_minutes = 30,
    },
    features =
    {
        pvp_offline_shield = true,
        pvp_league_shield = true,
        pvp_afk_shield = true,
        pvp_shield_upkeep = true,
        market_enemy_display = true,
        cease_fire_fish = true,
        kick_town_member = true,
        new_spawn_command = true,
        individual_outlander_peace_with_biters = true,
        biter_chatter = true,
        research_balance = true,
        dynamic_damage_modifier = true,
        town_rest_bonus = true,
        tech_gating = true,
        bulldozer_mode = true,
        tank_combat_tweaks = true,
        turrets_shoot_empty_vehicles = true,
        slowdown_capsule_disabled = true,
        logistics_raiding = true,
        pvp_shield_build_zones = true,
        ghost_turret_blueprint_block = true,
        map_edge_build_restrictions = true,
        rich_scoreboard = true,
        hud_research_cost = true,
        hud_damage = true,
        hud_last_winner = true,
        market_afk_offer = true,
        auto_reset_on_win = true,
        persist_last_winner = true,
        score_milestone_announcements = true,
        boss_swarms_respect_afk = true,
        boss_swarms_online_only = true,
        fluids_are_explosive = true,
        explosives_are_explosive = true,
        evolution_smell_hint = true,
        vehicles_force_handling = true,
    },
}

local exclusive_modes =
{
    win_condition = { 'survival', 'score' },
    map_mode = { 'procedural', 'fixed' },
    laser_limits = { 'slots', 'building_limits' },
    outlander_forces = { 'shared', 'individual' },
    chat_mode = { 'global', 'alliance' },
    damage_pipeline = { 'towny', 'extended' },
}

for key, allowed in pairs(exclusive_modes) do
    local value = config[key]
    local valid = false
    for _, option in ipairs(allowed) do
        if value == option then
            valid = true
            break
        end
    end
    if not valid then
        error('Invalid config.' .. key .. ' = ' .. tostring(value) .. '. Allowed: ' .. table.concat(allowed, ', '), 2)
    end
end

function Public.mode(key)
    return config[key]
end

function Public.enabled(name)
    local features = config.features
    if not features then
        return false
    end
    return features[name] == true
end

local wreckage_defaults =
{
    amount_scale = 1,
    scrap_amount_modifier = 3,
}

function Public.wreckage(key)
    if config.wreckage and config.wreckage[key] ~= nil then
        return config.wreckage[key]
    end
    return wreckage_defaults[key]
end

local pvp_shield_defaults =
{
    upkeep_coins_per_minute = 3,
    league_upkeep_coins_per_minute = 0,
    min_coins_to_activate = 30,
    low_balance_warning_minutes = 30,
}

function Public.pvp_shield(key)
    if config.pvp_shield and config.pvp_shield[key] ~= nil then
        return config.pvp_shield[key]
    end
    return pvp_shield_defaults[key]
end

function Public.apply_survival_hours(this)
    if config.survival and config.survival.hours then
        this.required_time_to_win = config.survival.hours
        this.required_time_to_win_in_ticks = config.survival.hours * 60 * 60 * 60
    end
end

local league_sizes_by_game_mode = { 101, 141, 141 }

local function game_mode_index()
    return config.game_mode or (storage and storage.game_mode) or 2
end

function Public.league_balance_shield_size()
    return league_sizes_by_game_mode[game_mode_index()]
end

function Public.higher_league_activation_range()
    return Public.league_balance_shield_size() + 50
end

function Public.min_distance_between_towns()
    return Public.higher_league_activation_range() + 2 + 50
end

local this = {}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

function Public.reset_table()
    this.key = {}
    this.rocket_launches = {}
    this.requests = {}
    this.player_prefs = {}
    this.town_centers = {}
    this.cooldowns_town_placement = {}
    this.last_respawn = {}
    this.last_death = {}
    this.strikes = {}
    this.score_gui_frame = {}
    this.town_status_gui_frame = {}
    this.testing_mode = false
    this.spawn_point = {}
    this.buffs = {}
    this.players = 0
    this.towns_enabled = true
    this.nuke_tick_schedule = {}
    this.swarms = {}
    this.explosion_schedule = {}
    this.fluid_explosion_schedule = {}
    this.spaceships = {}
    this.suicides = {}
    this.required_time_to_win = 72
    this.required_time_to_win_in_ticks = 15552000
    if not this.surface_terrain then
        this.surface_terrain = 'desert'
    end
    this.shuffle_random_victory_time = false
    this.announced_message = nil
    this.soft_reset = true
    this.winner = nil
    this.pvp_shields = {}
    this.previous_leagues = {}
    this.town_evo_warned = {}
    this.labs_destroy_events = {}
    this.laser_turrets_destroy_events = {}
    this.uranium_patch_location = nil
    this.entity_labels = {}
    this.last_damage_multiplier_shown = {}
    this.next_high_score_announcement = 0
    this.town_kill_message = {}
    this.game_end_sequence_start = nil
end

function Public.get_table()
    return this
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

Event.on_init(
    function ()
        Public.reset_table()
    end
)

return Public
