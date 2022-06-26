local Token = {}

local tokens = {}

local counter = 200

--- Assigns a unquie id for the given var.
-- This function cannot be called after on_init() or on_load() has run as that is a desync risk.
-- Typically this is used to register functions, so the id can be stored in the global table
-- instead of the function. This is becasue closures cannot be safely stored in the global table.
-- @param  var<any>
-- @return number the unique token for the variable.
function Token.register(var)
    if _LIFECYCLE == 8 then
        error('Calling Token.register after on_init() or on_load() has run is a desync risk.', 2)
    end

    counter = counter + 1

    tokens[counter] = var

    return counter
end

function Token.get(token_id)
    return tokens[token_id]
end

global.tokens = {
    index = {},
    counter = 0
}

function Token.register_global(var)
    if #global.tokens == 0 then
        return -- migration to newer version
    end

    local c = #global.tokens + 1

    global.tokens[c] = var

    return c
end

function Token.register_global_with_name(name, var)
    if not global.tokens[name] then
        global.tokens[name] = var
    end

    if not global.tokens.index[name] then
        global.tokens.counter = global.tokens.counter + 1
        global.tokens.index[name] = global.tokens.counter
    end

    return name
end

function Token.get_global_index(name)
    return global.tokens.index[name]
end

function Token.get_global_with_name(name)
    return global.tokens[name]
end

function Token.get_global(token_id)
    return global.tokens[token_id]
end

function Token.set_global(token_id, var)
    global.tokens[token_id] = var
end

local uid_counter = 100

function Token.uid()
    uid_counter = uid_counter + 1

    return uid_counter
end

return Token
