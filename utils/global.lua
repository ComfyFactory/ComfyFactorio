local Event = require 'utils.event_core'
local Global = {
    names = {},
    index = 0,
    filepath = {}
}

global.tokens = {}

local concat = table.concat

--- Validates if a global table exists
--- Returns a new table index if original table exists.
---@param filepath string
---@return string
local function validate_entry(filepath)
    if global.tokens[filepath] then
        if not global.tokens[filepath].token_index then
            global.tokens[filepath].token_index = 1
        else
            global.tokens[filepath].token_index = global.tokens[filepath].token_index + 1
        end
        local index = global.tokens[filepath].token_index
        filepath = filepath .. '_' .. index
    end
    return filepath
end

--- Sets a new global
---@param tbl any
---@return integer
---@return string
function Global.set_global(tbl)
    local filepath = debug.getinfo(3, 'S').source:match('^.+/currently%-playing/(.+)$'):sub(1, -5):gsub('/', '_')
    filepath = validate_entry(filepath)

    Global.index = Global.index + 1
    Global.filepath[filepath] = Global.index
    Global.names[filepath] = concat {Global.filepath[filepath], ' - ', filepath}

    global.tokens[filepath] = tbl

    return Global.index, filepath
end

--- Gets a global from global
---@param token number|string
---@return any|nil
function Global.get_global(token)
    if global.tokens[token] then
        return global.tokens[token]
    end
end

function Global.register(tbl, callback)
    local token, filepath = Global.set_global(tbl)

    Event.on_load(
        function()
            if global.tokens[token] then
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
        function()
            init_handler(tbl)
            callback(tbl)
        end
    )

    Event.on_load(
        function()
            if global.tokens[token] then
                callback(Global.get_global(token))
            else
                callback(Global.get_global(filepath))
            end
        end
    )
    return filepath
end

return Global
