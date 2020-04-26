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
    for k, _ in pairs(this) do
      this[k] = nil
    end
	this.game_lost = true
	this.game_won = false
	this.max_health = 10000
	this.health = 10000
end

function Public.get_table()
    return this
end

local on_init = function ()
    Public.reset_table()
end

Event.on_init(on_init)

return Public
