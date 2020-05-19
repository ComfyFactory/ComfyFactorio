-- on table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {
    disable_reset = false,
    players = {},
    offline_players = {}
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
    this.game_won = false
    this.energy = {}
    this.wave_counter = 0
    this.locomotive_health = 10000
    this.locomotive_max_health = 10000
    this.cargo_health = 10000
    this.cargo_max_health = 10000
    this.revealed_spawn = 0
    this.left_top = {
        x = 0,
        y = 0
    }
    this.train_upgrades = 0
    this.energy_purchased = false
    this.freeze_daytime = false
    this.offline_players = {}
    this.biter_pets = {}
    this.mined_scrap = 0
    this.biters_killed = 0
    this.locomotive_xp_aura = 40
    this.randomness = 0
    this.xp_points = 0
    this.xp_points_upgrade = 0
    this.aura_upgrades = 0
    this.health_upgrades = 0
    this.threat_upgrades = 0
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
