local Token = require 'utils.token'
local Global = require 'utils.global'
local Server = require 'utils.server'
local Event = require 'utils.event'
local table = require 'utils.table'

local supporters_dataset = 'supporters'

local Public = {}

local this = {
    supporters = {}
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

--- Checks if a player is a supporter
-- @param player_name <string>
-- @return <boolean>
function Public.is_supporter(key)
    return this.supporters[key] ~= nil or false, this.supporters[key]
end

--- Writes the data called back from the server into the supporter table, clearing any previous entries
local sync_supporters_callback =
    Token.register(
    function(data)
        table.clear_table(this.supporters)
        for k, v in pairs(data.entries) do
            this.supporters[k] = v
        end
    end
)

--- Signals the server to retrieve the supporters dataset
function Public.sync_supporters()
    Server.try_get_all_data(supporters_dataset, sync_supporters_callback)
end

Server.on_data_set_changed(
    supporters_dataset,
    function(data)
        this.supporters[data.key] = data.value
    end
)

Event.add(
    Server.events.on_server_started,
    function()
        Public.sync_supporters()
    end
)

return Public
