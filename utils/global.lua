local Event = require 'utils.event_core'
local Token = require 'utils.token'

local Global = {}

local names = {}
Global.names = names
local concat = table.concat

function Global.register(tbl, callback)
    local filepath = debug.getinfo(2, 'S').source:match('^.+/currently%-playing/(.+)$'):sub(1, -5)
    local name = filepath:gsub('/', '_')
    local token = Token.register_global(tbl)
    local token_name = Token.register_global_with_name(name, tbl)

    if token then
        names[token] = concat {token, ' - ', filepath}
    else
        names[token_name] = concat {Token.get_global_index(token_name), ' - ', filepath}
    end

    Event.on_load(
        function()
            if token then
                callback(Token.get_global(token))
            else
                callback(Token.get_global_with_name(name))
            end
        end
    )

    if token then
        return token
    else
        return token_name
    end
end

function Global.register_init(tbl, init_handler, callback)
    local filepath = debug.getinfo(2, 'S').source:match('^.+/currently%-playing/(.+)$'):sub(1, -5)
    local name = filepath:gsub('/', '_')
    local token = Token.register_global(tbl)
    local token_name = Token.register_global_with_name(name, tbl)

    if token then
        names[token] = concat {token, ' - ', filepath}
    else
        names[token_name] = concat {Token.get_global_index(token_name), ' - ', filepath}
    end

    Event.on_init(
        function()
            init_handler(tbl)
            callback(tbl)
        end
    )

    Event.on_load(
        function()
            if token then
                callback(Token.get_global(token))
            else
                callback(Token.get_global_with_name(name))
            end
        end
    )
    if token then
        return token
    else
        return token_name
    end
end

return Global
