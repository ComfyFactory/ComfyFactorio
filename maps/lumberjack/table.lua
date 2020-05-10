-- on table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {
    train_reveal = true,
    energy_shared = true
}
local Public = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

function Public.reset_table()
    --for k, _ in pairs(this) do
    --  this[k] = nil
    --end
    this.lo_energy = nil
    this.ow_energy = nil
    this.dummy = nil
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
    this.mined_scrap = 0
    this.biters_killed = 0
    this.locomotive_xp_aura = 40
end

function Public.get_table()
    return this
end

function Public.init(args)
    if args then
        this.train_reveal = args.train_reveal
        this.energy_shared = args.energy_shared
    else
        return error('Not a valid init argument', 2)
    end
end

local on_init = function()
    Public.reset_table()
end

Event.on_init(on_init)

return Public
