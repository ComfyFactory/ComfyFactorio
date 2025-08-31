local Token = {}

local tokens = {}

local counter = 200
local alternative_counter = 20000
local custom_prefix = 'comfy_'

--- Assigns a unique id for the given var.
-- This function cannot be called after on_init() or on_load() has run as that is a desync risk.
-- Typically this is used to register functions, so the id can be stored in the global table
-- instead of the function. This is because closures cannot be safely stored in the global table.
---@param var any
---@param sarg boolean|nil
---@return number -- the unique token for the variable.
function Token.register(var, sarg)
    if _LIFECYCLE == 8 then
        error('Calling Token.register after on_init() or on_load() has run is a desync risk.', 2)
    end

    if sarg then
        alternative_counter = alternative_counter + 1
        tokens[alternative_counter] = var
        return alternative_counter
    end

    counter = counter + 1

    tokens[counter] = var

    return counter
end

--- @return function|nil
function Token.get(token_id)
    return tokens[token_id]
end

local uid_counter = 100

--- Returns a unique id for the given prefix.
-- If no prefix is provided, the id will be prefixed with 'comfy_'.
---@alias Token.uid_prefix string
---@param prefix? Token.uid_prefix
---@return string
function Token.uid(prefix)
    uid_counter = uid_counter + 1
    return prefix and prefix .. '_' .. uid_counter or custom_prefix .. uid_counter
end

return Token
