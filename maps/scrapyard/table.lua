-- on table to rule them all!
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

function Public.reset_table()
    --for k, _ in pairs(this) do
    --  this[k] = nil
    --end
	this.game_lost = false
	this.game_won = false
	this.locomotive_health = 10000
	this.locomotive_max_health = 10000
	this.revealed_spawn = 0
end

function Public.get_table()
    return this
end

local on_init = function ()
    Public.reset_table()
end

Event.on_init(on_init)

return Public
