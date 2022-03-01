local Public = {}

-- one table to rule them all!
local Global = require 'utils.global'
local ffatable = {
    map_seed = 3747269588
}
Global.register(
    ffatable,
    function(tbl)
        ffatable = tbl
    end
)

function Public.reset_table()
    for k, _ in pairs(ffatable) do
        ffatable[k] = nil
    end
end

function Public.get_table()
    return ffatable
end

function Public.get(key)
    if key then
        return ffatable[key]
    else
        return ffatable
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        ffatable[key] = value
        return ffatable[key]
    elseif key then
        return ffatable[key]
    else
        return ffatable
    end
end

local on_init = function()
    Public.reset_table()
end

local Event = require 'utils.event'
Event.on_init(on_init)

return Public
