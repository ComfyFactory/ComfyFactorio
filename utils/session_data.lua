-- luacheck: ignore

local Global = require 'utils.global'
local Game = require 'utils.game'
local Token = require 'utils.token'
local Server = require 'utils.server'
local Event = require 'utils.event'
local table = require 'utils.table'
local Print = require('utils.print_override')
local raw_print = Print.raw_print

local session_data_set = 'player_session'
local playsession = {}
local done_fetching = nil
local set_data = Server.set_data
local try_get_data = Server.try_get_data
local concat = table.concat
local nth_tick = 54001 -- nearest prime to 15 minutes in ticks

Global.register(
    playsession,
    function(tbl)
        playsession = tbl
    end
)

local Public = {}

if _DEBUG then
printinfo =
    Token.register(
    function(data)
        game.print(serpent.block(data))
    end
)
end

--- Sends back data to data.key with data.value
local callback =
    Token.register(
    function(data)
        local p_name = data.key
        local player = game.get_player(p_name)
        local name = player.name
        local change = player.online_time
        local value = data.value
        set_data(session_data_set, name, {value[1] + change})
    end
)

--- Writes the data called back from the server into the session table
local sync_session_callback =
    Token.register(
    function(data)
        for k, v in pairs(data.entries) do
            playsession[k] = v
        end
        raw_print("[DATA-TRACKED] Done fetching all data.")
        done_fetching = true
    end
)

local function tick()
    for _, p in pairs(game.connected_players) do
        local session = playsession[p.name]

        if session then
            Public.update(p.name)
        else
            Public.set(p.name, {p.online_time})
        end
    end
end

--- Tries to get data from the webpanel and updates the dataset with values.
function Public.update(key)
    try_get_data(session_data_set, key, callback)
end

--- Stores data in the webpanel
-- @param set(key, value)
function Public.set(key, value)
    set_data(session_data_set, key, value)
end

--- Checks if a player exists within the table
-- @param player_name <string>
-- @return <boolean>
function Public.exists(player_name)
    return playsession[player_name] ~= nil
end

--- Signals the server to retrieve the session data-set
function Public.sync_session()
    Server.try_get_all_data(session_data_set, sync_session_callback)
end

--- Prints a list of all players in the player_session table.
function Public.print_sessions()
    local result = {}

    for k, _ in pairs(playsession) do
        result[#result + 1] = k
    end

    result = concat(result, ', ')
    Game.player_print(result)
end

--- Returns the table of player_session
-- @return <table>
function Public.get_session_table()
    return playsession
end

Event.add(
    Server.events.on_server_started,
    function()
        Public.sync_session()
    end
)
Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player then
            return
        end

        local session = playsession[player.name]

        if not session then
        playsession[player.name] = {player.online_time} return end
    end
)

Event.add(
    defines.events.on_player_left_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player then
            return
        end

        local session = playsession[player.name]

        if done_fetching then
            if session then
                Public.update(player.name)
            else
                Public.set(player.name, {player.online_time})
            end
        end

    end
)

Event.on_nth_tick(nth_tick, tick)

Server.on_data_set_changed(
    session_data_set,
    function(data)
        playsession[data.key] = data.value
    end
)

return Public