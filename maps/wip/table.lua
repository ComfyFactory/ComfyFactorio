-- one table to rule them all!
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

function Public.reset_main_table()
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

function Public.remove(key, sub_key)
    if key and sub_key then
        if this[key] and this[key][sub_key] then
            this[key][sub_key] = nil
        end
    elseif key then
        if this[key] then
            this[key] = nil
        end
    end
end

Event.on_init(Public.reset_main_table)

return Public
