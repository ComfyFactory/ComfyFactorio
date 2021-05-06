-- one table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {
    players = {},
    offline_players = {},
    hidden_dimension = {
        logistic_research_level = 0,
        reset_counter = 1
    },
    power_sources = {},
    refill_turrets = {index = 1},
    magic_crafters = {index = 1},
    magic_fluid_crafters = {index = 1},
    breached_wall = 1,
    entity_limits = {},
    traps = {}
}
local Public = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

function Public.reset_table()
    this.chunk_queue = {}
    this.game_has_ended = false
    this.game_reset = false
    this.spawn_area_generated = false
    this.results_sent = false
    this.explosive_bullets_unlocked = false
    this.bouncy_shells_unlocked = false
    this.trapped_capsules_unlocked = false
    this.ultra_mines_unlocked = false
    this.laser_pointer_unlocked = false
    this.railgun_enhancer_unlocked = false
    this.crumbly_walls_unlocked = false
    this.vehicle_nanobots_unlocked = false
    this.game_restart_timer = nil
    this.wave_count = 1
    this.market = nil
    this.wave_limit = 9999
    this.market_age = nil
    this.last_reset = game.tick
    this.wave_interval = 3600
    this.wave_grace_period = game.tick + 3600 * 20
    this.boss_biters = {}
    this.acid_lines_delay = {}
    this.entity_limits = {
        ['gun-turret'] = {placed = 1, limit = 1, str = 'gun turret', slot_price = 75},
        ['laser-turret'] = {placed = 0, limit = 1, str = 'laser turret', slot_price = 300},
        ['artillery-turret'] = {placed = 0, limit = 1, str = 'artillery turret', slot_price = 500},
        ['flamethrower-turret'] = {placed = 0, limit = 0, str = 'flamethrower turret', slot_price = 50000},
        ['land-mine'] = {placed = 0, limit = 1, str = 'mine', slot_price = 1}
    }
    this.comfylatron_habitat = {
        left_top = {x = -1500, y = -1500},
        right_bottom = {x = -80, y = 1500}
    }
    this.map_height = 96
    this.shotgun_shell_damage_modifier_old = {}
    this.flame_boots = {}
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

local on_init = function()
    Public.reset_table()
end

Event.on_init(on_init)

return Public
