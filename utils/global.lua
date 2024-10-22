local Event = require 'utils.event_core'
local Global = {
    names = {},
    index = 0,
    filepath = {}
}

storage.tokens = {}

local concat = table.concat

--- Validates if a global table exists
--- Returns a new table index if original table exists.
---@param filepath string
---@return string
local function validate_entry(filepath)
    if storage.tokens[filepath] then
        if not storage.tokens[filepath].token_index then
            storage.tokens[filepath].token_index = 1
        else
            storage.tokens[filepath].token_index = storage.tokens[filepath].token_index + 1
        end
        local index = storage.tokens[filepath].token_index
        filepath = filepath .. '_' .. index
    end
    return filepath
end

--- Sets a new global
---@param tbl any
---@return integer
---@return string
function Global.set_global(tbl)
    local filepath = debug.getinfo(3, 'S').source:match('^@__level__/(.+)$'):sub(1, -5):gsub('/', '_')
    filepath = validate_entry(filepath)

    Global.index = Global.index + 1
    Global.filepath[filepath] = Global.index
    Global.names[filepath] = concat { Global.filepath[filepath], ' - ', filepath }

    storage.tokens[filepath] = tbl

    return Global.index, filepath
end

--- Gets a global from global
---@param token number|string
---@return any|nil
function Global.get_global(token)
    if storage.tokens[token] then
        return storage.tokens[token]
    end
end

function Global.register(tbl, callback)
    local token, filepath = Global.set_global(tbl)

    Event.on_load(
        function ()
            if storage.tokens[token] then
                callback(Global.get_global(token))
            else
                callback(Global.get_global(filepath))
            end
        end
    )

    return filepath
end

function Global.register_init(tbl, init_handler, callback)
    local token, filepath = Global.set_global(tbl)

    Event.on_init(
        function ()
            init_handler(tbl)
            callback(tbl)
        end
    )

    Event.on_load(
        function ()
            if storage.tokens[token] then
                callback(Global.get_global(token))
            else
                callback(Global.get_global(filepath))
            end
        end
    )
    return filepath
end

return Global
