local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {}
local Public = {}
Public.events = {
    on_wave_created = Event.generate_event_name('on_wave_created'),
    on_unit_group_created = Event.generate_event_name('on_unit_group_created'),
    on_evolution_factor_changed = Event.generate_event_name('on_evolution_factor_changed'),
    on_game_reset = Event.generate_event_name('on_game_reset'),
    on_target_aquired = Event.generate_event_name('on_target_aquired'),
    on_entity_created = Event.generate_event_name('on_entity_created')
}
local insert = table.insert

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

Public.group_size_modifier_raffle = {}
local group_size_chances = {
    {4, 0.4},
    {5, 0.5},
    {6, 0.6},
    {7, 0.7},
    {8, 0.8},
    {9, 0.9},
    {10, 1},
    {9, 1.1},
    {8, 1.2},
    {7, 1.3},
    {6, 1.4},
    {5, 1.5},
    {4, 1.6},
    {3, 1.7},
    {2, 1.8}
}

for _, v in pairs(group_size_chances) do
    for _ = 1, v[1], 1 do
        insert(Public.group_size_modifier_raffle, v[2])
    end
end
Public.group_size_modifier_raffle_size = #Public.group_size_modifier_raffle

function Public.reset_wave_defense()
    this.boss_wave = false
    this.boss_wave_warning = false
    this.boost_spawner_sizes_wave_is_above = 1000
    this.boost_units_when_wave_is_above = 200
    this.boost_bosses_when_wave_is_above = 50
    this.side_target_count = 0
    this.active_biter_count = 0
    this.active_biter_threat = 0
    this.average_unit_group_size = 24
    this.biter_raffle = {}
    this.debug = false
    this.debug_health = false
    this.log_wave_to_discord = true
    this.paused = false
    this.pause_without_votes = true
    this.pause_wave_in_ticks = 18000 -- 5 minutes
    this.game_lost = false
    this.get_random_close_spawner_attempts = 5
    this.group_size = 2
    this.last_wave = game.tick
    this.max_active_biters = 1280
    this.max_active_unit_groups = 32
    this.max_biter_age = 3600 * 60
    this.nest_building_density = 48
    this.next_wave = game.tick + 3600 * 20
    this.enable_grace_time = {
        enabled = true,
        set = nil
    }
    this.side_targets = {}
    this.simple_entity_shredding_cost_modifier = 0.009
    this.spawn_position = {x = 0, y = 64}
    this.spitter_raffle = {}
    this.surface_index = 1
    this.target = nil
    this.threat = 0
    this.threat_gain_multiplier = 2
    this.threat_log = {}
    this.threat_log_index = 0
    this.tick_to_spawn_unit_groups = 200 -- this defines how often we spawn a unit group
    this.unit_groups_size = 0
    this.index = 0
    this.random_group = nil
    this.unit_group_command_delay = 3600 * 20
    this.unit_group_command_step_length = 15
    this.search_side_targets = {'simple-entity', 'tree', 'car', 'spider-vehicle', 'character'}
    this.wave_interval = 3600
    this.wave_enforced = false
    this.wave_number = 0
    this.worm_building_chance = 3
    this.worm_building_density = 16
    this.worm_raffle = {}
    this.alert_boss_wave = false
    this.remove_entities = false
    this.pause_waves = {
        index = 0
    }
    this.enable_random_spawn_positions = false
    this.enable_side_target = false
    this.enable_threat_log = true
    this.disable_threat_below_zero = false
    this.check_collapse_position = true
    this.resolve_pathing = true
    this.increase_damage_per_wave = false
    this.increase_boss_health_per_wave = true
    this.increase_average_unit_group_size = false
    this.increase_max_active_unit_groups = false
    this.increase_health_per_wave = false
    this.fill_tiles_so_biter_can_path = true
    this.modified_unit_health = {
        current_value = 1.2,
        limit_value = 150,
        health_increase_per_boss_wave = 0.5 -- wave % 25 == 0 at wave 2k boost is at 41.2
    }
    this.modified_boss_unit_health = {
        current_value = 2,
        limit_value = 500,
        health_increase_per_boss_wave = 4 -- wave % 25 == 0 at wave 2k boost is at 322
    }
    this.generated_units = {
        active_biters = {},
        unit_groups = {},
        unit_group_last_command = {},
        unit_group_pos = {
            index = 0,
            positions = {}
        },
        nests = {}
    }
    this.unit_settings = {
        scale_units_by_health = {
            ['small-biter'] = 1,
            ['medium-biter'] = 0.75,
            ['big-biter'] = 0.5,
            ['behemoth-biter'] = 0.25,
            ['small-spitter'] = 1,
            ['medium-spitter'] = 0.75,
            ['big-spitter'] = 0.5,
            ['behemoth-spitter'] = 0.25
        }
    }
    this.worm_unit_settings = {
        -- note that final health modifier isn't lower than 1
        scale_units_by_health = {
            ['land-mine'] = 0.5, -- not active as of now
            ['gun-turret'] = 0.5, -- not active as of now
            ['flamethrower-turret'] = 0.4, -- not active as of now
            ['artillery-turret'] = 0.25, -- not active as of now
            ['small-worm-turret'] = 0.8,
            ['medium-worm-turret'] = 0.6,
            ['big-worm-turret'] = 0.3,
            ['behemoth-worm-turret'] = 0.3
        }
    }
    this.valid_enemy_forces = {
        ['enemy'] = true,
        ['aggressors'] = true,
        ['aggressors_frenzy'] = true
    }
end

--- This gets values from our table
-- @param key <string>
function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

--- This sets values to our table
-- use with caution.
-- @param key <string>
-- @param value <string/boolean/int>
function Public.set(key, value)
    if key and (value or value == false or value == 'nil') then
        if value == 'nil' then
            this[key] = nil
        else
            this[key] = value
        end
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

--- Legacy, to be removed
Public.get_table = Public.get

--- This gets the status of the current wave
-- @param <null>
function Public.get_wave()
    return this.wave_number
end

--- This gets the status of disable_threat_below_zero
-- @param <null>
function Public.get_disable_threat_below_zero()
    return this.disable_threat_below_zero
end

--- This sets if we should disable threat below zero
-- @param <boolean>
function Public.set_disable_threat_below_zero(boolean)
    if (boolean or boolean == false) then
        this.disable_threat_below_zero = boolean
    end
    return this.disable_threat_below_zero
end

--- This gets the status of alert_boss_wave
-- @param <null>
function Public.get_alert_boss_wave()
    return this.get_alert_boss_wave
end

--- This sets if we should alert the players
-- when we spawn a boss wave
-- @param <boolean>
function Public.alert_boss_wave(boolean)
    if (boolean or boolean == false) then
        this.alert_boss_wave = boolean
    end
    return this.alert_boss_wave
end

--- This sets the spawning position of where
-- we will spawn the entities.
-- @param <tbl>
function Public.set_spawn_position(tbl)
    if type(tbl) == 'table' then
        this.spawn_position = tbl
    else
        error('Tbl must be of type table.')
    end
    return this.spawn_position
end

--- This sets if we should remove colliding entities
-- when we spawn entities.
-- @param <boolean>
function Public.remove_entities(boolean)
    if (boolean or boolean == false) then
        this.remove_entities = boolean
    end
    return this.remove_entities
end

--- This sets if the threat gui should be present for the players
-- Warning - this creates a lot of entries in the global table
-- and makes save/load heavy.
-- @param <boolean>
function Public.enable_threat_log(boolean)
    if (boolean or boolean == false) then
        this.enable_threat_log = boolean
    end
    return this.enable_threat_log
end

--- This sets if random spawn positions should be enabled.
-- @param <boolean>
function Public.enable_random_spawn_positions(boolean)
    if (boolean or boolean == false) then
        this.enable_random_spawn_positions = boolean
    end
    return this.enable_random_spawn_positions
end

--- This sets if we should spawn the unit near collapse
-- That is, if collapse module is enabled
-- @param <boolean>
function Public.check_collapse_position(boolean)
    if (boolean or boolean == false) then
        this.check_collapse_position = boolean
    end
    return this.check_collapse_position
end

--- This sets if the units/bosses should try to pick side-targets.
-- @param <boolean>
function Public.enable_side_target(boolean)
    if (boolean or boolean == false) then
        this.enable_side_target = boolean
    end
    return this.enable_side_target
end

--- This sets if the units health should increase.
-- @param <boolean>
function Public.increase_health_per_wave(boolean)
    if (boolean or boolean == false) then
        this.increase_health_per_wave = boolean
    end
    return this.increase_health_per_wave
end

--- This sets if the average unit group size should increase.
-- @param <boolean>
function Public.increase_average_unit_group_size(boolean)
    if (boolean or boolean == false) then
        this.increase_average_unit_group_size = boolean
    end
    return this.increase_average_unit_group_size
end

--- This sets if the max unit groups should increase.
-- @param <boolean>
function Public.increase_max_active_unit_groups(boolean)
    if (boolean or boolean == false) then
        this.increase_max_active_unit_groups = boolean
    end
    return this.increase_max_active_unit_groups
end

--- This sets if the bosses health should increase.
-- @param <boolean>
function Public.increase_boss_health_per_wave(boolean)
    if (boolean or boolean == false) then
        this.increase_boss_health_per_wave = boolean
    end
    return this.increase_boss_health_per_wave
end

--- This checks if units are stuck, if they are - act.
-- @param <boolean>
function Public.resolve_pathing(boolean)
    if (boolean or boolean == false) then
        this.resolve_pathing = boolean
    end
    return this.resolve_pathing
end

--- Enables non-placeable tiles to be switched to placable-tiles.
-- @param <boolean>
function Public.fill_tiles_so_biter_can_path(boolean)
    if (boolean or boolean == false) then
        this.fill_tiles_so_biter_can_path = boolean
    end
    return this.fill_tiles_so_biter_can_path
end

--- Sets the wave defense units damage increase.
-- @param <boolean>
function Public.increase_damage_per_wave(boolean)
    if (boolean or boolean == false) then
        this.increase_damage_per_wave = boolean
    end
    return this.increase_damage_per_wave
end

--- Sets the wave defense units health at start current.
-- @param <int>
function Public.set_normal_unit_current_health(int)
    this.modified_unit_health.current_value = int or 1.2
end

--- Sets the wave defense boss health increment.
-- @param <int>
function Public.set_boss_unit_current_health(int)
    this.modified_boss_unit_health.current_value = int or 2
end

--- Sets the wave defense units health at start current.
-- @param <int>
function Public.set_unit_health_increment_per_wave(int)
    this.modified_unit_health.health_increase_per_boss_wave = int or 0.5
end

--- Sets the wave defense boss health increment.
-- @param <int>
function Public.set_boss_health_increment_per_wave(int)
    this.modified_boss_unit_health.health_increase_per_boss_wave = int or 4
end

--- Sets when we should spawn a unit_group.
-- @param <int> in ticks
function Public.set_tick_to_spawn_unit_groups(int)
    this.tick_to_spawn_unit_groups = int or 200
end

--- Sets the pause length in ticks.
-- @param <int> in ticks
function Public.set_pause_wave_in_ticks(int)
    this.pause_wave_in_ticks = int or 18000
end

--- Pauses the wave defense module
-- @param null
function Public.pause(boolean)
    this.paused = boolean or false
end

--- Toggle debug - when you need to troubleshoot.
-- @param <null>
function Public.toggle_debug()
    if this.debug then
        this.debug = false
    else
        this.debug = true
    end

    return this.debug
end

--- Toggle debug - when you need to troubleshoot.
-- @param <null>
function Public.toggle_debug_health()
    if this.debug_health then
        this.debug_health = false
    else
        this.debug_health = true
    end

    return this.debug_health
end

--- Toggle grace time, for when you want to waves to start instantly
-- @param <boolean>
function Public.enable_grace_time(boolean)
    this.enable_grace_time.enabled = boolean or false

    return this.debug_health
end

-- Event.on_nth_tick(30, Public.debug_module)

Event.on_init(
    function()
        Public.reset_wave_defense()
    end
)

return Public
