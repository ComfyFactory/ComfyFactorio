-- created by Gerkiz for ComfyFactorio
local Global = require 'utils.global'
local Core = require 'utils.core'
local Color = require 'utils.color_presets'
local Game = require 'utils.game'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Server = require 'utils.server'
local Event = require 'utils.event'
local table = require 'utils.table'

local set_timeout_in_ticks = Task.set_timeout_in_ticks
local session_data_set = 'sessions'
local session = {}
local online_track = {}
local trusted = {}
local settings = {
    -- local trusted_value = 2592000 -- 12h
    trusted_value = 5184000, -- 24h
    required_only_time_to_save_time = 36000, -- nearest prime to 10 minutes in ticks
    nth_tick = 18000 -- nearest prime to 5 minutes in ticks
}
local set_data = Server.set_data
local try_get_data = Server.try_get_data
local try_get_data_and_print = Server.try_get_data_and_print
local concat = table.concat

Global.register(
    {
        session = session,
        online_track = online_track,
        trusted = trusted,
        settings = settings
    },
    function(tbl)
        session = tbl.session
        online_track = tbl.online_track
        trusted = tbl.trusted
        settings = tbl.settings
    end
)

local Public = {
    events = {
        on_player_removed = Event.generate_event_name('on_player_removed')
    }
}

local try_download_data_token =
    Token.register(
    function(data)
        local player_index = data.key
        local value = data.value
        if value then
            session[player_index] = value
            if value > settings.trusted_value then
                trusted[player_index] = true
            end
        else
            local player = game.get_player(player_index)
            if not player or not player.valid then
                return
            end
            session[player_index] = 0
            trusted[player_index] = false
            -- we don't want to clutter the database with players less than 10 minutes played.
            if player.online_time >= settings.required_only_time_to_save_time then
                set_data(session_data_set, player_index, session[player_index])
            end
        end
    end
)

local try_upload_data_token =
    Token.register(
    function(data)
        local player_index = data.key
        if not player_index then
            return
        end
        local value = data.value
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        if value then
            -- we don't want to clutter the database with players less than 10 minutes played.
            if player.online_time <= settings.required_only_time_to_save_time then
                return
            end

            local old_time_ingame = value

            if not online_track[player_index] then
                online_track[player_index] = 0
            end

            if online_track[player_index] > player.online_time then
                -- instance has been reset but scenario owner did not clear the player.
                -- so we clear it here and return.
                online_track[player_index] = 0
                return
            end

            local new_time = old_time_ingame + player.online_time - online_track[player_index]
            if new_time <= 0 then
                new_time = old_time_ingame + player.online_time
                online_track[player_index] = 0
                print('[ERROR] ' .. player_index .. ' had new time set as negative value: ' .. new_time)
                return
            end
            if new_time > settings.trusted_value then
                trusted[player_index] = true
            end
            set_data(session_data_set, player_index, new_time)
            session[player_index] = new_time
            online_track[player_index] = player.online_time
        else
            if player.online_time >= settings.required_only_time_to_save_time then
                if not session[player_index] then
                    session[player_index] = 0
                end
                set_data(session_data_set, player_index, session[player_index])
            end
        end
    end
)

local get_total_playtime_token =
    Token.register(
    function(data)
        if not data then
            return
        end
        if not data.to_print then
            return
        end

        local player_index = data.key
        local value = data.value
        local to_print = data.to_print
        local player = game.get_player(to_print)
        if player and player.valid then
            if player_index then
                if value then
                    player.play_sound {path = 'utility/scenario_message', volume_modifier = 1}
                    player.print('[color=blue]' .. player_index .. '[/color] has a total playtime of: ' .. Core.get_formatted_playtime(value))
                else
                    player.play_sound {path = 'utility/cannot_build', volume_modifier = 1}
                    player.print('[color=red]' .. player_index .. '[/color] was not found.')
                end
            end
        end
    end
)

local nth_tick_token =
    Token.register(
    function(data)
        local player_name = data.name
        Public.try_ul_data(player_name)
    end
)

--- Uploads each connected players play time to the dataset
local function upload_data()
    local players = game.connected_players
    local count = 0
    for i = 1, #players do
        count = count + 10
        local player = players[i]
        set_timeout_in_ticks(count, nth_tick_token, {name = player.name})
    end
end

--- Prints out game.tick to real hour/minute
---@param ticks int
---@param h int
---@param m int
function Public.format_time(ticks, h, m)
    local seconds = ticks / 60
    local minutes = math.floor((seconds) / 60)
    local hours = math.floor((minutes) / 60)
    local min = math.floor(minutes - 60 * hours)
    if h and m then
        return string.format('%dh:%02dm', hours, minutes, min)
    elseif h then
        return string.format('%dh', hours)
    elseif m then
        return string.format('%02dm', minutes, min)
    end
end

--- Tries to get data from the webpanel and prints it out to the player
---@param player LuaPlayer
---@param target_player string
function Public.get_and_print_to_player(player, target_player)
    if not (player and player.valid) then
        return
    end

    local p = player.print

    if not target_player then
        p('[ERROR] No player was provided.', Color.fail)
        return
    end

    if not player.admin then
        p("[ERROR] You're not admin.", Color.fail)
        return
    end

    local secs = Server.get_current_time()
    if secs == nil or secs == false then
        return
    else
        try_get_data_and_print(session_data_set, target_player, player.name, get_total_playtime_token)
    end
end

--- Tries to get data from the webpanel and updates the local table with values.
---@param player_index string
function Public.try_dl_data(player_index)
    player_index = tostring(player_index)
    local secs = Server.get_current_time()
    if secs == nil or secs == false then
        session[player_index] = game.get_player(player_index).online_time
        return
    else
        try_get_data(session_data_set, player_index, try_download_data_token)
    end
end

--- Tries to get data from the webpanel and updates the local table with values.
---@param player_index string
function Public.try_ul_data(player_index)
    player_index = tostring(player_index)
    local secs = Server.get_current_time()
    if secs == nil or secs == false then
        return
    else
        try_get_data(session_data_set, player_index, try_upload_data_token)
    end
end

--- Checks if a player exists within the table
---@param player_name string
---@return boolean
function Public.exists(player_name)
    return session[player_name] ~= nil
end

--- Prints a list of all players in the player_session table.
function Public.print_sessions()
    local result = {}

    for k, _ in pairs(session) do
        result[#result + 1] = k
    end

    result = concat(result, ', ')
    Game.player_print(result)
end

--- Returns the table of session
---@return table
function Public.get_session_table()
    return session
end

--- Returns the table of online_track
---@return table
function Public.get_tracker_table()
    return online_track
end

--- Returns the table of trusted
---@return table
function Public.get_trusted_table()
    return trusted
end

--- Returns the table of trusted
---@param player LuaPlayer
---@return table|boolean
function Public.get_trusted_player(player)
    return trusted and player and player.valid and trusted[player.name] or false
end

--- Set a player as trusted
---@param player LuaPlayer
function Public.set_trusted_player(player)
    if trusted and player and player.valid then
        trusted[player.name] = true
    end
end

--- Set a player as untrusted
---@param player LuaPlayer
function Public.set_untrusted_player(player)
    if trusted and player and player.valid then
        trusted[player.name] = nil
    end
end

--- Returns the table of session
---@param player LuaPlayer
---@return table|boolean
function Public.get_session_player(player)
    return session and player and player.valid and session[player.name] or false
end

--- Returns the table of settings
---@return table
function Public.get_settings_table()
    return settings
end

--- Clears a given player from the session tables.
---@param player LuaPlayer?
function Public.clear_player(player)
    if player and player.valid then
        local name = player.name
        local connected = player.connected

        if not connected then
            session[name] = nil
            online_track[name] = nil
            trusted[name] = nil
        end
    end
end

--- Resets a given player from the online_track table.
---@param player LuaPlayer
function Public.reset_online_track(player)
    local name = player.name
    online_track[name] = 0
end

--- It's vital that we reset the online_track so we
--- don't calculate the values wrong.
Event.add(
    Public.events.on_player_removed,
    function()
        for name, _ in pairs(online_track) do
            local player = game.get_player(name)
            Public.clear_player(player)
        end
    end
)

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        Public.try_dl_data(player.name)
    end
)

Event.add(
    defines.events.on_player_left_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        Public.try_ul_data(player.name)
    end
)

Event.on_nth_tick(settings.nth_tick, upload_data)

Server.on_data_set_changed(
    session_data_set,
    function(data)
        local player = game.get_player(data.key)
        if player and player.valid then
            session[data.key] = data.value
            if data.value > settings.trusted_value then
                trusted[data.key] = true
            else
                if trusted[data.key] then
                    trusted[data.key] = false
                end
            end
        end
    end
)

commands.add_command(
    'playtime',
    'Fetches a player total playtime or nil.',
    function(cmd)
        local player = game.player
        if not (player and player.valid) then
            return
        end

        local p = player.print

        local param = cmd.parameter
        if not param then
            p('[ERROR] No player was provided.', Color.fail)
            return
        end

        Public.get_and_print_to_player(player, param)
    end
)

Public.upload_data = upload_data

return Public
