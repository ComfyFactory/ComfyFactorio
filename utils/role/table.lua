local Global = require 'utils.global'
local Event = require 'utils.event'

local Public = {}

local this =
{
    settings =
    {
        role = {},
        group = {},
        meta = {},
        old = {},
        players =
        {
            ['gerkiz'] = 'Overlord'
        },
        enforce_color = false
    }
}

Public.events =
{
    on_role_change = Event.generate_event_name('on_role_change')
}

Global.register(
    this,
    function (t)
        this = t
    end
)

-- @usage debugStr('something')
function Public.debugStr(string)
    if not _DEBUG then
        return
    end
    return log('RAW: ' .. serpent.block(string))
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

return Public
