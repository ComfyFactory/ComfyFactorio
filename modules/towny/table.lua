-- one table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'

local townytable = {}
local Public = {}

Global.register(
    townytable,
    function(tbl)
        townytable = tbl
    end
)

function Public.reset_table()
    for k, _ in pairs(townytable) do
        townytable[k] = nil
    end
    townytable.requests = {}
    townytable.request_cooldowns = {}
    townytable.town_centers = {}
    townytable.cooldowns = {}
    townytable.size_of_town_centers = 0
    townytable.swarms = {}
    townytable.town_buttons = {}
end

function Public.get_table()
    return townytable
end

local on_init = function()
    Public.reset_table()
end

Event.on_init(on_init)

return Public
