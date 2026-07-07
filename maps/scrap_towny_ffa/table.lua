
local Public = {}

local Global = require 'utils.global'
local Event = require 'utils.event'
local Server = require 'utils.server'
local Token = require 'utils.token'

local settings_dataset = 'scenario_settings'
local settings_dataset_key = 'scrap_towny_ffa'
local settings_dataset_key_dev = 'scrap_towny_ffa_dev'

local settings_defaults =
{
    last_winner_name = '',
    auto_reset_enabled = true,
}

local Constant =
{
    ShortMode = 1,
    SurvivalMode = 2,
    LongSurvivalMode = 3,

    ScoreWin = 'score',
    SurvivalWin = 'survival',

    ProceduralMap = 'procedural',
    FixedMap = 'fixed',

    SlotsLimits = 'slots',
    BuildingLimits = 'building_limits',

    SharedForces = 'shared',
    IndividualForces = 'individual',

    GlobalChat = 'global',
    AllianceChat = 'alliance',

    TownyDamage = 'towny',
    ExtendedDamage = 'extended',
}

Public.Constant = Constant

local config =
{
    win_condition = Constant.ScoreWin,
    map_mode = Constant.ProceduralMap,
    laser_limits = Constant.SlotsLimits,
    outlander_forces = Constant.SharedForces,
    chat_mode = Constant.GlobalChat,
    damage_pipeline = Constant.TownyDamage,
    game_mode = Constant.ShortMode,
    game_modes =
    {
        [Constant.ShortMode] =
        {
            name = 'Short War',
            tech_price_multiplier = 0.2,
            starter_ore_scale = 0.25,
            league_shield_size = 101,
            age_score_factor = 10.0,
            research_evo_score_factor = 150,
            survival_points = true,
            l4_score_only_offline = false,
            disable_production_utility_science = true,
            survival_hours = 6,
        },
        [Constant.SurvivalMode] =
        {
            name = 'Survival',
            tech_price_multiplier = 0.35,
            starter_ore_scale = 0.5,
            league_shield_size = 141,
            age_score_factor = 2.4,
            research_evo_score_factor = 65,
            survival_points = true,
            l4_score_only_offline = true,
            disable_production_utility_science = false,
            survival_hours = 48,
        },
        [Constant.LongSurvivalMode] =
        {
            name = 'Long Survival',
            tech_price_multiplier = 0.75,
            starter_ore_scale = 1.0,
            league_shield_size = 141,
            age_score_factor = 1.2,
            research_evo_score_factor = 65,
            survival_points = true,
            l4_score_only_offline = true,
            disable_production_utility_science = false,
            survival_hours = 120,
        },
    },
    score =
    {
        research_points_to_win = 100,
        research_evo_score_factor = 100,
    },
    wreckage =
    {
        amount_scale = 0.5,
        scrap_amount_modifier = 1.5,
        rare = true,
        rare_spawn_divisor = 35,
        rare_reward_multiplier = 5,
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
        pvp_offline_shield = false,
        pvp_league_shield = true,
        pvp_afk_shield = false,
        pvp_shield_upkeep = true,
        market_enemy_display = true,
        cease_fire_fish = true,
        kick_town_member = true,
        new_spawn_command = true,
        individual_outlander_peace_with_biters = true,
        biter_chatter = true,
        research_balance = true,
        dynamic_damage_modifier = true,
        town_rest_bonus = false,
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
        market_afk_offer = false,
        auto_reset_on_win = true,
        persist_last_winner = true,
        score_milestone_announcements = true,
        boss_swarms_respect_afk = false,
        boss_swarms_online_only = true,
        fluids_are_explosive = true,
        explosives_are_explosive = true,
        evolution_smell_hint = true,
        vehicles_force_handling = true,
    },
}

local exclusive_modes =
{
    win_condition = { Constant.SurvivalWin, Constant.ScoreWin },
    map_mode = { Constant.ProceduralMap, Constant.FixedMap },
    laser_limits = { Constant.SlotsLimits, Constant.BuildingLimits },
    outlander_forces = { Constant.SharedForces, Constant.IndividualForces },
    chat_mode = { Constant.GlobalChat, Constant.AllianceChat },
    damage_pipeline = { Constant.TownyDamage, Constant.ExtendedDamage },
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

if config.game_mode ~= Constant.ShortMode
    and config.game_mode ~= Constant.SurvivalMode
    and config.game_mode ~= Constant.LongSurvivalMode then
    error('Invalid config.game_mode = ' .. tostring(config.game_mode), 2)
end

if not config.game_modes[config.game_mode] then
    error('Missing config.game_modes entry for game_mode = ' .. tostring(config.game_mode), 2)
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
    rare = false,
    rare_spawn_divisor = 4,
    rare_reward_multiplier = 2,
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

local score_defaults =
{
    research_points_to_win = 100,
    research_evo_score_factor = nil,
}

function Public.score(key)
    if config.score and config.score[key] ~= nil then
        return config.score[key]
    end
    return score_defaults[key]
end

function Public.apply_survival_hours(this)
    local hours = Public.game_mode('survival_hours')
    if hours then
        this.required_time_to_win = hours
        this.required_time_to_win_in_ticks = hours * 60 * 60 * 60
    end
end

function Public.game_mode(key)
    local settings = config.game_modes[config.game_mode]
    if not settings then
        return nil
    end
    if key then
        return settings[key]
    end
    return settings
end

function Public.survival_points_enabled()
    local mode_setting = Public.game_mode('survival_points')
    if mode_setting ~= nil then
        return mode_setting == true
    end
    return false
end

local function disable_techs(force, starting_from_list, inputs_to_disable)
    local targets = {}
    for _, name in ipairs(starting_from_list) do
        targets[name] = true
    end

    local function is_prerequisite_or_input(tech)
        if targets[tech.name] then return true end
        for _, ingredient in pairs(tech.research_unit_ingredients) do
            if inputs_to_disable[ingredient.name] then return true end
        end
        if tech.prerequisites then
            for prerequisite_name, _ in pairs(tech.prerequisites) do
                if targets[prerequisite_name] or is_prerequisite_or_input(force.technologies[prerequisite_name]) then
                    return true
                end
            end
        end
        return false
    end

    for _, tech in pairs(force.technologies) do
        if is_prerequisite_or_input(tech) then
            tech.enabled = false
        end
    end
end

function Public.disable_game_mode_techs(force)
    if Public.game_mode('disable_production_utility_science') then
        disable_techs(force, { 'production-science-pack', 'utility-science-pack' }, {
            ['production-science-pack'] = true,
            ['utility-science-pack'] = true,
        })
    end
end

function Public.league_balance_shield_size()
    return Public.game_mode('league_shield_size')
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
    local survival_hours = Public.game_mode('survival_hours') or 72
    this.required_time_to_win = survival_hours
    this.required_time_to_win_in_ticks = survival_hours * 60 * 60 * 60
    if not this.surface_terrain then
        this.surface_terrain = 'forest'
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

function Public.collect_settings(tbl)
    return {
        required_time_to_win = tbl.required_time_to_win,
        required_time_to_win_in_ticks = tbl.required_time_to_win_in_ticks,
        surface_terrain = tbl.surface_terrain,
        last_winner_name = storage.last_winner_name or '',
        auto_reset_enabled = storage.auto_reset_enabled,
    }
end

function Public.apply_settings(tbl, value)
    if not value then
        return
    end
    if value.required_time_to_win then
        tbl.required_time_to_win = value.required_time_to_win
        tbl.required_time_to_win_in_ticks = value.required_time_to_win_in_ticks
            or value.required_time_to_win * 60 * 60 * 60
    end
    if value.surface_terrain then
        tbl.surface_terrain = value.surface_terrain
    end
    if Public.enabled('persist_last_winner') and value.last_winner_name then
        storage.last_winner_name = value.last_winner_name
    end
    if value.auto_reset_enabled ~= nil then
        storage.auto_reset_enabled = value.auto_reset_enabled
    end
end

function Public.toggle_next_round(tbl)
    if tbl.required_time_to_win == 48 then
        tbl.required_time_to_win = 72
        tbl.required_time_to_win_in_ticks = 15552000
    else
        tbl.required_time_to_win = 48
        tbl.required_time_to_win_in_ticks = 10368000
    end
    if tbl.surface_terrain == 'forest' then
        tbl.surface_terrain = 'desert'
    else
        tbl.surface_terrain = 'forest'
    end
end

function Public.persist_settings(server_name_matches)
    local settings = Public.collect_settings(this)
    if server_name_matches == nil then
        server_name_matches = Server.check_server_name('Towny')
    end
    if server_name_matches then
        Server.set_data(settings_dataset, settings_dataset_key, settings)
    else
        Server.set_data(settings_dataset, settings_dataset_key_dev, settings)
    end
end

function Public.apply_map_reset(server_name_matches)
    Public.toggle_next_round(this)
    Public.persist_settings(server_name_matches)
end

function Public.load_defaults()
    storage.game_mode = Public.mode('game_mode')

    if Public.enabled('persist_last_winner') or Public.enabled('auto_reset_on_win') then
        storage.last_winner_name = settings_defaults.last_winner_name
        storage.auto_reset_enabled = Public.enabled('auto_reset_on_win') and settings_defaults.auto_reset_enabled
    else
        storage.last_winner_name = storage.last_winner_name or ''
        storage.auto_reset_enabled = false
    end
end

local load_settings_token =
    Token.register(
        function (data)
            if not data or not data.value then
                if this.shuffle_random_victory_time and math.random(1, 32) == 1 then
                    this.required_time_to_win = 48
                    this.required_time_to_win_in_ticks = 10368000
                    this.surface_terrain = 'forest'
                end
            else
                Public.apply_settings(this, data.value)
                Public.toggle_next_round(this)
            end

            Public.persist_settings(Server.check_server_name('Towny'))
        end
    )

Event.add(
    ServerCommands.events.on_server_started,
    function ()
        if this.settings_applied then
            return
        end

        local server_name_matches = Server.check_server_name('Towny')

        this.settings_applied = true

        if server_name_matches then
            Server.try_get_data(settings_dataset, settings_dataset_key, load_settings_token)
        else
            Server.try_get_data(settings_dataset, settings_dataset_key_dev, load_settings_token)
            this.test_mode = true
        end
    end
)

Event.on_init(
    function ()
        Public.reset_table()
    end
)

return Public
