local Global = require 'utils.global'

local this = {
    settings = {
        chunk_load_tick = false,
        chunks_charted = {}
    }
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local Public = {}

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
    if key then
        if this[key] and this[key][sub_key] then
            this[key][sub_key] = nil
        elseif this[key] then
            this[key] = nil
        end
    end
end

return Public
