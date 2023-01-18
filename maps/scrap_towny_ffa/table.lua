local Public = {}

-- one table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

function Public.reset_table()
    this.key = {}
    this.rocket_launches = {}
    this.requests = {}
    this.town_centers = {}
    this.cooldowns_town_placement = {}
    this.last_respawn = {}
    this.last_death = {}
    this.strikes = {}
    this.score_gui_frame = {}
    this.testing_mode = false
    this.spawn_point = {}
    this.buffs = {}
    this.players = 0
    this.towns_enabled = true
    this.nuke_tick_schedule = {}
    this.swarms = {}
    this.explosion_schedule = {}
    this.fluid_explosion_schedule = {}
    this.mining = {}
    this.mining_entity = {}
    this.mining_target = {}
    this.spaceships = {}
    this.suicides = {}
    this.required_time_to_win = 168
    this.required_time_to_win_in_ticks = 36288000
    this.shuffle_random_victory_time = false
    this.announced_message = nil
    this.soft_reset = true
    this.winner = nil
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
    function()
        Public.reset_table()
    end
)

return Public
