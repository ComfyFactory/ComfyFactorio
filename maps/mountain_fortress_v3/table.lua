-- on table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {
    disable_reset = false,
    players = {},
    offline_players = {},
    power_sources = {},
    refill_turrets = {index = 1},
    magic_crafters = {index = 1},
    magic_fluid_crafters = {index = 1},
    breached_wall = 1,
    entity_limits = {},
    ore_loot = {
        limit = 10000,
        divisor = 10,
        ore_list = {'iron-ore', 'copper-ore', 'coal'}
    }
}
local Public = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

function Public.reset_table()
    this.locomotive_index = nil
    this.loco_surface = nil
    this.game_lost = false
    this.locomotive_health = 10000
    this.locomotive_max_health = 10000
    this.cargo_health = 10000
    this.cargo_max_health = 10000
    this.train_upgrades = 0
    this.offline_players = {}
    this.biter_pets = {}
    this.power_sources = {}
    this.flamethrower_damage = {}
    this.refill_turrets = {index = 1}
    this.magic_crafters = {index = 1}
    this.magic_fluid_crafters = {index = 1}
    this.mined_scrap = 0
    this.biters_killed = 0
    this.locomotive_xp_aura = 40
    this.xp_points = 0
    this.xp_points_upgrade = 0
    this.upgrades = {
        showed_text = false,
        landmine = {
            limit = 0,
            built = 0
        },
        flame_turret = {
            limit = 0,
            built = 0
        },
        unit_number = {
            landmine = {},
            flame_turret = {}
        }
    }
    this.aura_upgrades = 0
    this.health_upgrades = 0
    this.threat_upgrades = 0
    this.breached_wall = 1
    this.entity_limits = {}
    this.offline_players_enabled = false
    this.left_top = {
        x = 0,
        y = 0
    }
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
