local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {}
local Public = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

function Public.debug_module()
    this.next_wave = 1000
    this.wave_interval = 500
    this.wave_enforced = true
end

function Public.reset_wave_defense()
    this.boss_wave = false
    this.boss_wave_warning = false
    this.side_target_count = 0
    this.active_biters = {}
    this.active_biter_count = 0
    this.active_biter_threat = 0
    this.average_unit_group_size = 128
    this.biter_raffle = {}
    this.debug = false
    this.game_lost = false
    this.get_random_close_spawner_attempts = 5
    this.group_size = 2
    this.last_wave = game.tick
    this.max_active_biters = 1280
    this.max_active_unit_groups = 6
    this.max_biter_age = 3600 * 60
    this.nests = {}
    this.nest_building_density = 48
    this.next_wave = game.tick + 3600 * 15
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
    this.unit_groups = {}
    this.index = 0
    this.random_group = nil
    this.unit_group_command_delay = 3600 * 25
    this.unit_group_command_step_length = 15
    this.unit_group_last_command = {}
    this.wave_interval = 3600
    this.wave_enforced = false
    this.wave_number = 0
    this.worm_building_chance = 3
    this.worm_building_density = 16
    this.worm_raffle = {}
    this.clear_corpses = false
    this.biter_health_boost = 1
    this.alert_boss_wave = false
    this.remove_entities = false
    this.enable_threat_log = true
    this.check_collapse_position = true
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key)
    if key then
        return this[key]
    else
        return this
    end
end

Public.get_table = Public.get

function Public.clear_corpses(value)
    if value then
        this.clear_corpses = value
    else
        this.clear_corpses = false
    end
    return this.clear_corpses
end

function Public.get_wave()
    return this.wave_number
end

function Public.alert_boss_wave(value)
    if value then
        this.alert_boss_wave = value
    else
        this.alert_boss_wave = false
    end
    return this.alert_boss_wave
end

function Public.set_spawn_position(value)
    if type(value) == 'table' then
        this.spawn_position = value
    else
        error('Value must be of type table.')
    end
    return this.spawn_position
end

function Public.remove_entities(value)
    if value then
        this.remove_entities = value
    else
        this.remove_entities = false
    end
    return this.remove_entities
end

function Public.enable_threat_log(value)
    if value then
        this.enable_threat_log = value
    else
        this.enable_threat_log = false
    end
    return this.enable_threat_log
end

function Public.check_collapse_position(value)
    if value then
        this.check_collapse_position = value
    else
        this.check_collapse_position = false
    end
    return this.check_collapse_position
end

function Public.set_biter_health_boost(value)
    if value and type(value) == 'number' then
        this.biter_health_boost = value
    else
        this.biter_health_boost = 1
    end
    return this.biter_health_boost
end

local on_init = function()
    Public.reset_wave_defense()
end

Event.on_init(on_init)

return Public
