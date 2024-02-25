local Token = require 'utils.token'
local Task = require 'utils.task'
local Global = require 'utils.global'
local Event = require 'utils.event'
local Print = require('utils.print_override')

-- local constants
local floor = math.floor
local ceil = math.ceil
local insert = table.insert
local concat = table.concat
local serialize = serpent.serialize
local remove = table.remove
local tostring = tostring
local len = string.len
local gmatch = string.gmatch
local newline = '\n'

local raw_print = Print.raw_print
local minutes_to_ticks = 60 * 60
local hours_to_ticks = 60 * 60 * 60
local ticks_to_minutes = 1 / minutes_to_ticks
local ticks_to_hours = 1 / hours_to_ticks

local serialize_options = {sparse = true, compact = true}

local Public = {}

local server_time = {secs = nil, tick = 0}
local server_ups = {ups = 60}
local start_data = {server_id = nil, server_name = nil, start_time = nil}
local instances = {
    data = {}
}
local requests = {}
local jailed_data_set = 'jailed'
local data_set_handlers = {}
local scenario_handlers = {}

Global.register(
    {
        server_time = server_time,
        server_ups = server_ups,
        start_data = start_data,
        requests = requests,
        instances = instances
    },
    function(tbl)
        server_time = tbl.server_time
        server_ups = tbl.server_ups
        start_data = tbl.start_data
        requests = tbl.requests
        instances = tbl.instances
    end
)

--- Web panel framework.
local discord_tag = '[DISCORD]'
local discord_raw_tag = '[DISCORD-RAW]'
local discord_bold_tag = '[DISCORD-BOLD]'
local discord_admin_tag = '[DISCORD-ADMIN]'
local discord_banned_tag = '[DISCORD-BANNED]'
local discord_banned_embed_tag = '[DISCORD-BANNED-EMBED]'
local discord_unbanned_tag = '[DISCORD-UNBANNED]'
local discord_unbanned_embed_tag = '[DISCORD-UNBANNED-EMBED]'
local discord_jailed_tag = '[DISCORD-JAILED]'
local discord_jailed_embed_tag = '[DISCORD-JAILED-EMBED]'
local discord_unjailed_tag = '[DISCORD-UNJAILED]'
local discord_unjailed_embed_tag = '[DISCORD-UNJAILED-EMBED]'
local discord_jailed_named_embed_tag = '[DISCORD-JAILED-NAMED-EMBED]'
local discord_unjailed_named_embed_tag = '[DISCORD-UNJAILED-NAMED-EMBED]'
local discord_admin_raw_tag = '[DISCORD-ADMIN-RAW]'
local discord_embed_parsed_tag = '[DISCORD-EMBED-PARSED]'
local discord_embed_tag = '[DISCORD-EMBED]'
local discord_embed_raw_tag = '[DISCORD-EMBED-RAW]'
local discord_admin_embed_tag = '[DISCORD-ADMIN-EMBED]'
local discord_admin_embed_raw_tag = '[DISCORD-ADMIN-EMBED-RAW]'
local discord_named_tag = '[DISCORD-NAMED]'
local discord_named_raw_tag = '[DISCORD-NAMED-RAW]'
local discord_named_bold_tag = '[DISCORD-NAMED-BOLD]'
local discord_named_embed_tag = '[DISCORD-NAMED-EMBED]'
local discord_named_embed_parsed_tag = '[DISCORD-NAMED-EMBED-PARSED]'
local discord_named_embed_raw_tag = '[DISCORD-NAMED-EMBED-RAW]'
local start_scenario_tag = '[START-SCENARIO]'
local stop_scenario_tag = '[STOP-SCENARIO]'
local ping_tag = '[PING]'
local data_set_tag = '[DATA-SET]'
local ban_get_tag = '[BAN-GET]'
local data_get_tag = '[DATA-GET]'
local data_get_and_print_tag = '[DATA-GET-AND-PRINT]'
local data_get_all_tag = '[DATA-GET-ALL]'
local data_tracked_tag = '[DATA-TRACKED]'
local scenario_tag = '[SCENARIO-TRACKED]'
local ban_sync_tag = '[BAN-SYNC]'
local unbanned_sync_tag = '[UNBANNED-SYNC]'
local query_players_tag = '[QUERY-PLAYERS]'
local player_join_tag = '[PLAYER-JOIN]'
local player_leave_tag = '[PLAYER-LEAVE]'
local antigrief_tag = '[ANTIGRIEF-LOG]'

Public.raw_print = raw_print

local function output_data(primary, secondary)
    if start_data and start_data.output then
        local write = game.write_file
        write(start_data.output, primary .. (secondary or '') .. newline, true, 0)
    else
        raw_print(primary .. (secondary or ''))
    end
end

local function assert_non_empty_string_and_no_spaces(str, argument_name)
    if type(str) ~= 'string' then
        error(argument_name .. ' must be a string', 3)
    end

    if #str == 0 then
        error(argument_name .. ' must not be an empty string', 3)
    end

    if str:match(' ') then
        error(argument_name .. " must not contain space ' ' character.", 3)
    end
end

local function get_online_admins()
    local online = game.connected_players
    local i = 0
    for _, p in pairs(online) do
        if p.admin then
            i = i + 1
        end
    end
    return i
end

local function build_embed_data()
    local d = {
        time = Public.format_time(game.ticks_played),
        onlinePlayers = #game.connected_players,
        totalPlayers = #game.players,
        onlineAdmins = get_online_admins()
    }
    return d
end

--- The event id for the on_server_started event.
-- The event is raised whenever the server goes from the starting state to the running state.
-- It provides a good opportunity to request data from the web server.
-- Note that if the server is stopped then started again, this event will be raised again.
-- @usage
-- local Server = require 'utils.server'
-- local Event = require 'utils.event'
--
-- Event.add(Server.events.on_server_started,
-- function()
--      Server.try_get_all_data('regulars', callback)
-- end)
-- Event.add(Server.events.on_changes_detected,
-- function()
--      Trigger some sort of automated restart whenever the game ends.
-- end)
Public.events = {on_server_started = Event.generate_event_name('on_server_started'), on_changes_detected = Event.generate_event_name('on_changes_detected')}

--- Sends a message to the linked discord channel. The message is sanitized of markdown server side.
-- @param  message<string> message to send.
-- @usage
-- local Server = require 'utils.server'
-- Server.to_discord('Hello from scenario script!')
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_discord(message, locale)
    if locale then
        print(message, discord_tag)
    else
        output_data(discord_tag .. message)
    end
end

--- Sends a message to the linked discord channel. The message is not sanitized of markdown.
-- @param  message<string> message to send.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_discord_raw(message, locale)
    if locale then
        print(message, discord_raw_tag)
    else
        output_data(discord_raw_tag .. message)
    end
end

--- Sends a message to the linked discord channel. The message is sanitized of markdown server side, then made bold.
-- @param  message<string> message to send.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_discord_bold(message, locale)
    if locale then
        print(message, discord_bold_tag)
    else
        output_data(discord_bold_tag .. message)
    end
end

--- Sends a message to the named discord channel. The message is sanitized of markdown server side.
-- @param  message<string> message to send.
function Public.to_discord_named(channel_name, message)
    assert_non_empty_string_and_no_spaces(channel_name, 'channel_name')
    output_data(concat({discord_named_tag, channel_name, ' ', message}))
end

--- Sends a message to the named discord channel. The message is not sanitized of markdown.
-- @param  message<string> message to send.
function Public.to_discord_named_raw(channel_name, message)
    assert_non_empty_string_and_no_spaces(channel_name, 'channel_name')
    output_data(concat({discord_named_raw_tag, channel_name, ' ', message}))
end

--- Sends a message to the named discord channel. The message is sanitized of markdown server side, then made bold.
-- @param  message<string> message to send.
function Public.to_discord_named_bold(channel_name, message)
    assert_non_empty_string_and_no_spaces(channel_name, 'channel_name')
    output_data(concat({discord_named_bold_tag, channel_name, ' ', message}))
end

--- Sends an embed message to the named discord channel. The message is sanitized of markdown server side.
-- @param  message<string> the content of the embed.
function Public.to_discord_named_embed(channel_name, message)
    assert_non_empty_string_and_no_spaces(channel_name, 'channel_name')
    output_data(concat({discord_named_embed_tag, channel_name, ' ', message}))
end

--- Sends an embed message that is parsed to the named discord channel. The message is sanitized of markdown server side.
-- @param  message<string> the content of the embed.
function Public.to_discord_named_parsed_embed(channel_name, message)
    assert_non_empty_string_and_no_spaces(channel_name, 'channel_name')
    local table_to_json = game.table_to_json

    if not type(message) == 'table' then
        return
    end

    if not message.title then
        return
    end
    if not message.description then
        return
    end

    message.channelName = channel_name

    output_data(discord_named_embed_parsed_tag, table_to_json(message))
end

--- Sends an embed message to the named discord channel. The message is not sanitized of markdown.
-- @param  message<string> the content of the embed.
function Public.to_discord_named_embed_raw(channel_name, message)
    assert_non_empty_string_and_no_spaces(channel_name, 'channel_name')
    output_data(concat({discord_named_embed_raw_tag, channel_name, ' ', message}))
end

--- Sends a message to the linked admin discord channel. The message is sanitized of markdown server side.
-- @param  message<string> message to send.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_admin(message, locale)
    if locale then
        print(message, discord_admin_tag)
    else
        output_data(discord_admin_tag .. message)
    end
end

--- Sends a message to the linked banned discord channel. The message is sanitized of markdown server side.
-- @param  message<string> message to send.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_banned(message, locale)
    if locale then
        print(message, discord_banned_tag)
    else
        output_data(discord_banned_tag .. message)
    end
end
--- Sends a message to the linked banned discord channel. The message is sanitized of markdown server side.
-- @param  message<string> message to send.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_unbanned(message, locale)
    if locale then
        print(message, discord_unbanned_tag)
    else
        output_data(discord_unbanned_tag .. message)
    end
end

--- Sends a message to the linked connected discord channel. The message is sanitized of markdown server side.
-- @param  message<string> message to send.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_jailed(message, locale)
    if locale then
        print(message, discord_jailed_tag)
    else
        output_data(discord_jailed_tag .. message)
    end
end
--- Sends a message to the linked connected discord channel. The message is sanitized of markdown server side.
-- @param  message<string> message to send.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_unjailed(message, locale)
    if locale then
        print(message, discord_unjailed_tag)
    else
        output_data(discord_unjailed_tag .. message)
    end
end

--- Sends a message to the linked admin discord channel. The message is not sanitized of markdown.
-- @param  message<string> message to send.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_admin_raw(message, locale)
    if locale then
        print(message, discord_admin_raw_tag)
    else
        output_data(discord_admin_raw_tag .. message)
    end
end

--- Sends a embed message to the linked discord channel. The message is sanitized/parsed of markdown server side.
-- @param  message<table> the content of the embed.
function Public.to_discord_embed_parsed(message)
    local table_to_json = game.table_to_json
    if not type(message) == 'table' then
        return
    end

    if not message.title then
        return
    end
    if not message.description then
        return
    end
    output_data(discord_embed_parsed_tag .. table_to_json(message))
end

--- Sends a embed message to the linked discord channel. The message is sanitized of markdown server side.
-- @param  message<string> the content of the embed.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_discord_embed(message, locale)
    if locale then
        print(message, discord_embed_tag)
    else
        output_data(discord_embed_tag .. message)
    end
end

--- Sends a embed message to the linked discord channel. The message is not sanitized of markdown.
-- @param  message<string> the content of the embed.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_discord_embed_raw(message, locale)
    if locale then
        print(message, discord_embed_raw_tag)
    else
        output_data(discord_embed_raw_tag .. message)
    end
end

--- Sends a embed message to the linked admin discord channel. The message is sanitized of markdown server side.
-- @param  message<string> the content of the embed.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_admin_embed(message, locale)
    if locale then
        print(message, discord_admin_embed_tag)
    else
        output_data(discord_admin_embed_tag .. message)
    end
end

--- Sends a embed message to the linked banned discord channel. The message is sanitized of markdown server side.
-- @param  message<tbl> the content of the embed.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_banned_embed(message, locale)
    local table_to_json = game.table_to_json
    if not type(message) == 'table' then
        return
    end
    if locale then
        print(message, discord_banned_embed_tag)
    else
        if not message.username then
            return
        end
        if not message.reason then
            return
        end
        if not message.admin then
            return
        end
        output_data(discord_banned_embed_tag .. table_to_json(message))
    end
end

--- Sends a embed message to the linked banned discord channel. The message is sanitized of markdown server side.
-- @param  message<tbl> the content of the embed.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_unbanned_embed(message, locale)
    local table_to_json = game.table_to_json
    if not type(message) == 'table' then
        return
    end
    if locale then
        print(message, discord_unbanned_embed_tag)
    else
        if not message.username then
            return
        end
        if not message.admin then
            return
        end
        output_data(discord_unbanned_embed_tag .. table_to_json(message))
    end
end

--- Sends a embed message to the linked connected discord channel. The message is sanitized of markdown server side.
-- @param  message<tbl> the content of the embed.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_jailed_embed(message, locale)
    local table_to_json = game.table_to_json
    if not type(message) == 'table' then
        return
    end

    if locale then
        print(message, discord_jailed_embed_tag)
    else
        if not message.username then
            return
        end
        if not message.reason then
            return
        end
        if not message.admin then
            return
        end
        output_data(discord_jailed_embed_tag .. table_to_json(message))
    end
end

--- Sends a embed message to the jailed discord channel. The message is sanitized of markdown server side.
-- @param  message<tbl> the content of the embed.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_jailed_named_embed(message, locale)
    local table_to_json = game.table_to_json
    if not type(message) == 'table' then
        return
    end

    if locale then
        print(message, discord_jailed_named_embed_tag)
    else
        if not message.username then
            return
        end
        if not message.reason then
            return
        end
        if not message.admin then
            return
        end
        output_data(discord_jailed_named_embed_tag .. table_to_json(message))
    end
end

--- Sends a embed message to the linked connected discord channel. The message is sanitized of markdown server side.
-- @param  message<tbl> the content of the embed.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_unjailed_embed(message, locale)
    local table_to_json = game.table_to_json
    if not type(message) == 'table' then
        return
    end
    if locale then
        print(message, discord_unjailed_embed_tag)
    else
        if not message.username then
            return
        end
        if not message.admin then
            return
        end
        output_data(discord_unjailed_embed_tag .. table_to_json(message))
    end
end

--- Sends a embed message to the linked connected discord channel. The message is sanitized of markdown server side.
-- @param  message<tbl> the content of the embed.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_unjailed_named_embed(message, locale)
    local table_to_json = game.table_to_json
    if not type(message) == 'table' then
        return
    end
    if locale then
        print(message, discord_unjailed_named_embed_tag)
    else
        if not message.username then
            return
        end
        if not message.admin then
            return
        end
        output_data(discord_unjailed_named_embed_tag .. table_to_json(message))
    end
end

--- Sends a embed message to the linked admin discord channel. The message is not sanitized of markdown.
-- @param  message<string> the content of the embed.
-- @param  locale<boolean> if the message should be handled as localized.
function Public.to_admin_embed_raw(message, locale)
    if locale then
        print(message, discord_admin_embed_raw_tag)
    else
        output_data(discord_admin_embed_raw_tag .. message)
    end
end

--- Stops and saves the factorio server and starts the named scenario.
-- @param  scenario_name<string> The name of the scenario as appears in the scenario table on the panel.
-- @usage
-- local Server = require 'utils.server'
-- Server.start_scenario('my_scenario_name')
function Public.start_scenario(scenario_name)
    if type(scenario_name) ~= 'string' then
        game.print('start_scenario - scenario_name ' .. tostring(scenario_name) .. ' must be a string.')
        return
    end

    local message = start_scenario_tag .. scenario_name

    output_data(message)
end

--- Stops and saves the factorio server.
-- @usage
-- local Server = require 'utils.server'
-- Server.stop_scenario()
function Public.stop_scenario()
    local message = stop_scenario_tag

    output_data(message)
end

local default_ping_token =
    Token.register(
    function(sent_tick)
        local now = game.tick
        local diff = now - sent_tick

        local message = concat({'Pong in ', diff, ' tick(s) ', 'sent tick: ', sent_tick, ' received tick: ', now})
        game.print(message)
    end
)

--- Pings the web server.
-- @param  func_token<token> The function that is called when the web server replies.
-- The function is passed the tick that the ping was sent.
function Public.ping(func_token)
    local message = concat({ping_tag, func_token or default_ping_token, ' ', game.tick})
    output_data(message)
end

--- The backend sets instances with data so a player
-- can easily connect to another one via in-game.
-- @param  data<table>
function Public.set_instances(data)
    if not data then
        return
    end
    if not type(data) == 'table' then
        return
    end
    instances.data = {}
    for id, tbl in pairs(data) do
        instances.data[id] = tbl
    end
end

--- Gets each available/non-available instance
function Public.get_instances()
    return instances.data
end

local function double_escape(str)
    -- Excessive escaping because the data is serialized twice.
    if not str then
        return ''
    end

    return str:gsub('\\', '\\\\\\\\'):gsub('"', '\\\\\\"'):gsub('\n', '\\\\n')
end

--- Sets the web server's persistent data storage. If you pass nil for the value removes the data.
-- Data set this will by synced in with other server if they choose to.
-- There can only be one key for each data_set.
-- @param  data_set<string>
-- @param  key<string>
-- @param  value<nil|boolean|number|string|table> Any type that is not a function. set to nil to remove the data.
-- @usage
-- local Server = require 'utils.server'
-- Server.set_data('my data set', 'key 1', 123)
-- Server.set_data('my data set', 'key 2', 'abc')
-- Server.set_data('my data set', 'key 3', {'some', 'data', ['is_set'] = true})
--
-- Server.set_data('my data set', 'key 1', nil) -- this will remove 'key 1'
-- Server.set_data('my data set', 'key 2', 'def') -- this will change the value for 'key 2' to 'def'
function Public.set_data(data_set, key, value)
    if type(data_set) ~= 'string' then
        error('data_set must be a string', 2)
    end
    if type(key) ~= 'string' then
        error('key must be a string', 2)
    end

    data_set = double_escape(data_set)
    key = double_escape(key)

    local message
    local vt = type(value)
    if vt == 'nil' then
        message = concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '"}'})
    elseif vt == 'string' then
        value = double_escape(value)

        message = concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '",value:"\\"', value, '\\""}'})
    elseif vt == 'number' then
        message = concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '",value:"', value, '"}'})
    elseif vt == 'boolean' then
        message = concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, '",value:"', tostring(value), '"}'})
    elseif vt == 'function' then
        error('value cannot be a function', 2)
    else -- table
        value = serialize(value, serialize_options)

        -- Less escaping than the string case as serpent provides one level of escaping.
        -- Need to escape single quotes as serpent uses double quotes for strings.
        value = value:gsub('\\', '\\\\'):gsub("'", "\\'")

        message = concat({data_set_tag, '{data_set:"', data_set, '",key:"', key, "\",value:'", value, "'}"})
    end

    output_data(message)
end

local function validate_arguments(data_set, key, callback_token)
    if type(data_set) ~= 'string' then
        error('data_set must be a string', 3)
    end
    if type(key) ~= 'string' then
        error('key must be a string', 3)
    end
    if type(callback_token) ~= 'number' then
        error('callback_token must be a number', 3)
    end
end

local function validate_arguments_of_ban(username, callback_token)
    if type(username) ~= 'string' then
        error('username must be a string', 3)
    end

    if type(callback_token) ~= 'number' then
        error('callback_token must be a number', 3)
    end
end

local function send_try_get_data(data_set, key, callback_token)
    data_set = double_escape(data_set)
    key = double_escape(key)

    local message = concat {data_get_tag, callback_token, ' {', 'data_set:"', data_set, '",key:"', key, '"}'}
    output_data(message)
end

local function send_try_get_ban(username, callback_token)
    username = double_escape(username)

    local message = concat {ban_get_tag, callback_token, ' {', 'username:"', username, '"}'}
    output_data(message)
end

local function send_try_get_data_and_print(data_set, key, to_print, callback_token)
    data_set = double_escape(data_set)
    key = double_escape(key)
    to_print = double_escape(to_print)

    local message = concat {data_get_and_print_tag, callback_token, ' {', 'data_set:"', data_set, '",key:"', key, '",to_print:"', to_print, '"}'}
    output_data(message)
end

local function log_antigrief_data(category, action)
    category = double_escape(category)
    action = double_escape(action)

    local message = concat {antigrief_tag, '{', 'category:"', category, '",action:"', action, '"}'}
    output_data(message)
end

local cancelable_callback_token =
    Token.register(
    function(data)
        local data_set = data.data_set
        local keys = requests[data_set]
        if not keys then
            return
        end

        local key = data.key
        local callbacks = keys[key]
        if not callbacks then
            return
        end

        keys[key] = nil

        for c, _ in next, callbacks do
            local func = Token.get(c)
            func(data)
        end
    end
)

--- Gets data from the web server's persistent data storage.
-- The callback is passed a table {data_set: string, key: string, value: any}.
-- If the value is nil, it means there is no stored data for that data_set key pair.
-- @param  data_set<string>
-- @param  key<string>
-- @param  callback_token<token>
-- @usage
-- local Server = require 'utils.server'
-- local Token = require 'utils.token'
--
-- local callback =
--     Token.register(
--     function(data)
--         local data_set = data.data_set
--         local key = data.key
--         local value = data.value -- will be nil if no data
--
--         game.print(data_set .. ':' .. key .. ':' .. tostring(value))
--     end
-- )
--
-- Server.try_get_data('my data set', 'key 1', callback)
function Public.try_get_data(data_set, key, callback_token)
    validate_arguments(data_set, key, callback_token)

    send_try_get_data(data_set, key, callback_token)
end

--- Same as try_get_data returns if a user is banned.
function Public.try_get_ban(username, callback_token)
    validate_arguments_of_ban(username, callback_token)

    send_try_get_ban(username, callback_token)
end

--- Same as try_get_data but prints the returned value to the given player who ran the command.
function Public.try_get_data_and_print(data_set, key, to_print, callback_token)
    validate_arguments(data_set, key, callback_token)

    send_try_get_data_and_print(data_set, key, to_print, callback_token)
end

local function try_get_data_cancelable(data_set, key, callback_token)
    local keys = requests[data_set]
    if not keys then
        keys = {}
        requests[data_set] = keys
    end

    local callbacks = keys[key]
    if not callbacks then
        callbacks = {}
        keys[key] = callbacks
    end

    if callbacks[callback_token] then
        return
    end

    if next(callbacks) then
        callbacks[callback_token] = true
    else
        callbacks[callback_token] = true
        send_try_get_data(data_set, key, cancelable_callback_token)
    end
end

--- Same Server.try_get_data but the request can be cancelled by calling
-- Server.cancel_try_get_data(data_set, key, callback_token)
-- If the request is cancelled before it is complete the callback will be called with data.cancelled = true.
-- It is safe to cancel a non-existent or completed request, in either case the callback will not be called.
-- There can only be one request per data_set, key, callback_token combo. If there is already an ongoing request
-- an attempt to make a new one will be ignored.
-- @param  data_set<string>
-- @param  key<string>
-- @param  callback_token<token>
function Public.try_get_data_cancelable(data_set, key, callback_token)
    validate_arguments(data_set, key, callback_token)

    try_get_data_cancelable(data_set, key, callback_token)
end

local function cancel_try_get_data(data_set, key, callback_token)
    local keys = requests[data_set]
    if not keys then
        return false
    end

    local callbacks = keys[key]
    if not callbacks then
        return false
    end

    if callbacks[callback_token] then
        callbacks[callback_token] = nil

        local func = Token.get(callback_token)
        local data = {data_set = data_set, key = key, cancelled = true}
        func(data)

        return true
    else
        return false
    end
end

--- Cancels the request. Returns false if the request could not be canceled, either because there is no request
-- to cancel or it has been completed or canceled already. Otherwise returns true.
-- If the request is cancelled before it is complete the callback will be called with data.cancelled = true.
-- It is safe to cancel a non-existent or completed request, in either case the callback will not be called.
-- @param  data_set<string>
-- @param  key<string>
-- @param  callback_token<token>
function Public.cancel_try_get_data(data_set, key, callback_token)
    validate_arguments(data_set, key, callback_token)

    return cancel_try_get_data(data_set, key, callback_token)
end

local timeout_token =
    Token.register(
    function(data)
        cancel_try_get_data(data.data_set, data.key, data.callback_token)
    end
)

--- Same as Server.try_get_data but the request is cancelled if the timeout expires before the request is complete.
-- If the request is cancelled before it is complete the callback will be called with data.cancelled = true.
-- There can only be one request per data_set, key, callback_token combo. If there is already an ongoing request
-- an attempt to make a new one will be ignored.
-- @param  data_set<string>
-- @param  key<string>
-- @param  callback_token<token>
-- @usage
-- local Server = require 'utils.server'
-- local Token = require 'utils.token'
--
-- local callback =
--     Token.register(
--     function(data)
--         local data_set = data.data_set
--         local key = data.key
--
--          game.print('data_set: ' .. data_set .. ', key: ' .. key)
--
--         if data.cancelled then
--             game.print('Timed out')
--             return
--         end
--
--         local value = data.value -- will be nil if no data
--
--         game.print('value: ' .. tostring(value))
--     end
-- )
--
-- Server.try_get_data_timeout('my data set', 'key 1', callback, 60)
function Public.try_get_data_timeout(data_set, key, callback_token, timeout_ticks)
    validate_arguments(data_set, key, callback_token)

    try_get_data_cancelable(data_set, key, callback_token)

    Task.set_timeout_in_ticks(timeout_ticks, timeout_token, {data_set = data_set, key = key, callback_token = callback_token})
end

--- Gets all the data for the data_set from the web server's persistent data storage.
-- The callback is passed a table {data_set: string, entries: {dictionary key -> value}}.
-- If there is no data stored for the data_set entries will be nil.
-- @param  data_set<string>
-- @param  callback_token<token>
-- @usage
-- local Server = require 'utils.server'
-- local Token = require 'utils.token'
--
-- local callback =
--     Token.register(
--     function(data)
--         local data_set = data.data_set
--         local entries = data.entries -- will be nil if no data
--         local value2 = entries['key 2']
--         local value3 = entries['key 3']
--     end
-- )
--
-- Server.try_get_all_data('my data set', callback)
function Public.try_get_all_data(data_set, callback_token)
    if type(data_set) ~= 'string' then
        error('data_set must be a string', 2)
    end
    if type(callback_token) ~= 'number' then
        error('callback_token must be a number', 2)
    end

    data_set = double_escape(data_set)

    local message = concat {data_get_all_tag, callback_token, ' {', 'data_set:"', data_set, '"}'}
    output_data(message)
end

local function data_set_changed(data)
    local handlers = data_set_handlers[data.data_set]
    if handlers == nil then
        return
    end

    if _DEBUG then
        for _, handler in ipairs(handlers) do
            local success, err = pcall(handler, data)
            if not success then
                log(err)
                error(err, 2)
            end
        end
    else
        for _, handler in ipairs(handlers) do
            local success, err = pcall(handler, data)
            if not success then
                log(err)
            end
        end
    end
end

local function scenario_changed(data)
    local handlers = scenario_handlers[data.scenario]
    if handlers == nil then
        return
    end

    if _DEBUG then
        for _, handler in ipairs(handlers) do
            local success, err = pcall(handler, data)
            if not success then
                log(err)
                error(err, 2)
            end
        end
    else
        for _, handler in ipairs(handlers) do
            local success, err = pcall(handler, data)
            if not success then
                log(err)
            end
        end
    end
end

--- Register a handler to be called when the data_set changes.
-- The handler is passed a table {data_set:string, key:string, value:any}
-- If value is nil that means the key was removed.
-- The handler may be called even if the value hasn't changed. It's up to the implementer
-- to determine if the value has changed, or not care.
-- To prevent desyncs the same handlers must be registered for all clients. The easiest way to do this
-- is in the control stage, i.e before on_init or on_load would be called.
-- @param  data_set<string>
-- @param  handler<function>
-- @usage
-- local Server = require 'utils.server'
-- Server.on_data_set_changed(
--     'my data set',
--     function(data)
--         local data_set = data.data_set
--         local key = data.key
--         local value = data.value -- will be nil if data was removed.
--     end
-- )
function Public.on_data_set_changed(data_set, handler)
    if _LIFECYCLE == _STAGE.runtime then
        error('cannot call during runtime', 2)
    end
    if type(data_set) ~= 'string' then
        error('data_set must be a string', 2)
    end

    local handlers = data_set_handlers[data_set]
    if handlers == nil then
        handlers = {handler}
        data_set_handlers[data_set] = handlers
    else
        handlers[#handlers + 1] = handler
    end
end

--- Register a handler to be called when a scenarios changes.
-- The handler is passed a table {scenario:string}
-- @param  scenario<string>
-- @param  handler<function>
-- @usage
-- local Server = require 'utils.server'
-- Server.on_scenario_changed(
--     'scenario name',
--     function(data)
--         local scenario = data.scenario
--     end
-- )
function Public.on_scenario_changed(scenario, handler)
    if _LIFECYCLE == _STAGE.runtime then
        error('cannot call during runtime', 2)
    end
    if type(scenario) ~= 'string' then
        error('scenario must be a string', 2)
    end

    local handlers = scenario_handlers[scenario]
    if handlers == nil then
        handlers = {handler}
        scenario_handlers[scenario] = handlers
    else
        handlers[#handlers + 1] = handler
    end
end

--- Called by the web server to notify the client that a data_set has changed.
Public.raise_data_set = data_set_changed

--- Called by the web server to notify the client that the subscribed scenario has changed.
Public.raise_scenario_changed = scenario_changed

-- Tracks antigrief and sends them to a specific log channel.
Public.log_antigrief_data = log_antigrief_data

--- Called by the web server to determine which data_sets are being tracked.
function Public.get_tracked_data_sets()
    local message = {data_tracked_tag, '['}

    for k, _ in pairs(data_set_handlers) do
        k = double_escape(k)

        local message_length = #message
        message[message_length + 1] = '"'
        message[message_length + 2] = k
        message[message_length + 3] = '"'
        message[message_length + 4] = ','
    end

    if message[#message] == ',' then
        remove(message)
    end

    message[#message + 1] = ']'

    message = concat(message)
    output_data(message)
end

--- Called by the web server to determine which scenarios is being tracked.
function Public.get_tracked_scenario()
    local message = {scenario_tag, ''}

    for k, _ in pairs(scenario_handlers) do
        k = double_escape(k)

        local message_length = #message
        message[message_length + 1] = k
        message[message_length + 2] = ','
    end

    if message[#message] == ',' then
        remove(message)
    end

    message = concat(message)
    output_data(message)
end

local function escape(str)
    return str:gsub('\\', '\\\\'):gsub('"', '\\"')
end

local statistics = {
    'item_production_statistics',
    'fluid_production_statistics',
    'kill_count_statistics',
    'entity_build_count_statistics'
}
function Public.export_stats()
    local table_to_json = game.table_to_json
    local stats = {
        game_tick = game.tick,
        player_count = #game.connected_players,
        game_flow_statistics = {
            pollution_statistics = {
                input = game.pollution_statistics.input_counts,
                output = game.pollution_statistics.output_counts
            }
        },
        rockets_launched = {},
        force_flow_statistics = {}
    }
    for _, force in pairs(game.forces) do
        local flow_statistics = {}
        for _, statName in pairs(statistics) do
            flow_statistics[statName] = {
                input = force[statName].input_counts,
                output = force[statName].output_counts
            }
        end
        stats.rockets_launched[force.name] = force.rockets_launched

        stats.force_flow_statistics[force.name] = flow_statistics
    end
    rcon.print(table_to_json(stats))
end

--- Called by the web server to set the server start data.
function Public.set_start_data(data)
    start_data.server_id = data.server_id
    start_data.server_name = data.server_name

    local start_time = start_data.start_time
    if not start_time then
        -- Only set start time if it has not been set already, so that we keep the first start time.
        start_data.start_time = data.start_time
    end
end

-- This is the current server's id, in the case the save has been loaded on multiple servers.
-- @return string
function Public.get_server_id()
    return start_data.server_id or ''
end

--- Gets the server's name. Empty string if not known.
-- This is the current server's name, in the case the save has been loaded on multiple servers.
-- @return string
function Public.get_server_name()
    return start_data.server_name or nil
end

--- Gets the server's name and matches it against a string.
-- This is the current server's name, in the case the save has been loaded on multiple servers.
-- @param string
-- @return string
function Public.check_server_name(string)
    if start_data.server_name then
        local server_name = start_data.server_name
        local str = string.match(server_name, string)
        if str then
            return true
        end
    end
    return false
end

--- Gets the server's start time as a unix epoch timestamp. nil if not known.
-- @return number?
function Public.get_start_time()
    return start_data.start_time
end

--- If the player exists bans the player.
-- Regardless of whether or not the player exists the name is synchronized with other servers
-- and stored in the database.
-- @param  username<string>
-- @param  reason<string?> defaults to empty string.
-- @param  admin<string?> admin's name, defaults to '<script>'
function Public.ban_sync(username, reason, admin)
    if type(username) ~= 'string' then
        error('username must be a string', 2)
    end

    if reason == nil then
        reason = ''
    elseif type(reason) ~= 'string' then
        error('reason must be a string or nil', 2)
    end

    if admin == nil then
        admin = '<script>'
    elseif type(admin) ~= 'string' then
        error('admin must be a string or nil', 2)
    end

    -- game.ban_player errors if player not found.
    -- However we may still want to use this function to ban player names.
    local player = game.players[username]
    if player then
        game.ban_player(player, reason)
    end

    username = escape(username)
    reason = escape(reason)
    admin = escape(admin)

    local message = concat({ban_sync_tag, '{username:"', username, '",reason:"', reason, '",admin:"', admin, '"}'})
    output_data(message)
end

--- If the player exists bans the player else throws error.
-- The ban is not synchronized with other servers or stored in the database.
-- @param  PlayerSpecification
-- @param  reason<string?> defaults to empty string.
function Public.ban_non_sync(PlayerSpecification, reason)
    game.ban_player(PlayerSpecification, reason)
end

--- If the player exists unbans the player.
-- Regardless of whether or not the player exists the name is synchronized with other servers
-- and removed from the database.
-- @param  username<string>
-- @param  admin<string?> admin's name, defaults to '<script>'. This name is stored in the logs for who removed the ban.
function Public.unban_sync(username, admin)
    if type(username) ~= 'string' then
        error('username must be a string', 2)
    end

    if admin == nil then
        admin = '<script>'
    elseif type(admin) ~= 'string' then
        error('admin must be a string or nil', 2)
    end

    -- game.unban_player errors if player not found.
    -- However we may still want to use this function to unban player names.
    local player = game.players[username]
    if player then
        game.unban_player(username)
    end

    username = escape(username)
    admin = escape(admin)

    local message = concat({unbanned_sync_tag, '{username:"', username, '",admin:"', admin, '"}'})
    output_data(message)
end

--- If the player exists unbans the player else throws error.
-- The ban is not synchronized with other servers or removed from the database.
-- @param  PlayerSpecification
function Public.unban_non_sync(PlayerSpecification)
    game.unban_player(PlayerSpecification)
end

--- Called by the web server to set the server time.
-- @param  secs<number> unix epoch timestamp
function Public.set_time(secs)
    server_time.secs = secs
    server_time.tick = game.tick
end

--- Called by the web server to set output location.
-- @param  data<string>
function Public.set_output(data)
    start_data.output = data
end

--- Gets a table {secs:number?, tick:number} with secs being the unix epoch timestamp
-- for the server time and ticks the number of game ticks ago it was set.
-- @return table
function Public.get_time_data_raw()
    return server_time
end

--- Called by the web server to set the ups value.
-- @param  tick<number> tick
function Public.set_ups(tick)
    server_ups.ups = tick
end

--- Gets a the estimated UPS from the web panel that is sent to the server.
-- This is calculated and measured in the wrapper.
-- @return number
function Public.get_ups()
    return server_ups.ups
end

--- Gets an estimate of the current server time as a unix epoch timestamp.
-- If the server time has not been set returns nil.
-- The estimate may be slightly off if within the last minute the game has been paused, saving or overwise,
-- or the game speed has been changed.
-- @return number?
function Public.get_current_time()
    local secs = server_time.secs
    if secs == nil then
        return false
    end

    local diff = game.tick - server_time.tick
    return math.floor(secs + diff / game.speed / 60)
end

--- Converts from epoch to yymmddhhmm.
-- @param epoch<number>
-- @return date?
function Public.convertFromEpoch(epoch)
    if not epoch then
        return
    end

    local function date(z)
        z = floor(z / 86400) + 719468
        local era = floor(z / 146097)
        local doe = floor(z - era * 146097)
        local yoe = floor((doe - doe / 1460 + doe / 36524 - doe / 146096) / 365)
        local y = floor(yoe + era * 400)
        local doy = doe - floor((365 * yoe + yoe / 4 - yoe / 100))
        local mp = floor((5 * doy + 2) / 153)
        local d = ceil(doy - (153 * mp + 2) / 5 + 1)
        local m = floor(mp + (mp < 10 and 3 or -9))
        return y + (m <= 2 and 1 or 0), tonumber(m), tonumber(d)
    end

    local unixTime = floor(epoch) - (60 * 60 * (-1))
    if unixTime < 0 then
        return
    end

    local hours = floor(unixTime / 3600 % 24)
    local minutes = floor(unixTime / 60 % 60)
    local seconds = floor(unixTime % 60)

    local year, month, day = date(unixTime)

    return {
        year = year,
        month = month < 10 and '0' .. month or month,
        day = day < 10 and '0' .. day or day,
        hours = hours < 10 and '0' .. hours or hours,
        minutes = minutes < 10 and '0' .. minutes or minutes,
        seconds = seconds < 10 and '0' .. seconds or seconds
    }
end

-- Returns the current date.
-- @param pretty<boolean>
-- @param as_table<boolean>
-- @param current_time<number>
-- @return date|tuple?
function Public.get_current_date(pretty, as_table, current_time)
    local s = current_time or Public.get_current_time()
    if not s then
        return false
    end

    local date = Public.convertFromEpoch(s)
    if not date then
        return
    end

    if as_table then
        return {year = date.year, month = date.month, day = date.day}
    elseif pretty then
        return tonumber(date.year .. '-' .. date.month .. '-' .. date.day)
    else
        return tonumber(date.year .. date.month .. date.day)
    end
end

-- Returns the total played time in yymmddhhmm.
-- @return date?
function Public.get_current_date_with_time()
    local s = Public.get_current_time()
    if not s then
        return false
    end

    local date = Public.convertFromEpoch(s)
    if not date then
        return
    end
    return date.year .. '-' .. date.month .. '-' .. date.day .. ' ' .. date.hours .. ':' .. date.minutes
end

--- Takes a time in ticks and returns a string with the time in format "x hour(s) x minute(s)"
function Public.format_time(ticks)
    local result = {}

    local hours = floor(ticks * ticks_to_hours)
    if hours > 0 then
        ticks = ticks - hours * hours_to_ticks
        insert(result, hours)
        if hours == 1 then
            insert(result, 'hour')
        else
            insert(result, 'hours')
        end
    end

    local minutes = floor(ticks * ticks_to_minutes)
    insert(result, minutes)
    if minutes == 1 then
        insert(result, 'minute')
    else
        insert(result, 'minutes')
    end

    return concat(result, ' ')
end

--- Called by the web server to re sync which players are online.
function Public.query_online_players()
    local message = {query_players_tag, '['}

    for _, p in ipairs(game.connected_players) do
        message[#message + 1] = '"'
        local name = escape(p.name)
        message[#message + 1] = name
        message[#message + 1] = '",'
    end

    if message[#message] == '",' then
        message[#message] = '"'
    end

    message[#message + 1] = ']'

    message = concat(message)
    output_data(message)
end

function Public.ban_handler(event)
    local cmd = event.command

    local user = event.parameters
    if not user then
        return
    end

    if len(user) <= 1 then
        return
    end

    local t = {}
    for i in gmatch(user, '%S+') do
        insert(t, i)
    end

    local target = t[1]

    if not target then
        return print('[on_console_command] - target was undefined.')
    end

    if cmd == 'ban' then
        Public.set_data(jailed_data_set, target, nil) -- this is added here since we don't want to clutter the jail dataset.
    end
end

local function command_handler(callback, ...)
    if type(callback) == 'function' then
        local success, err = pcall(callback, ...)
        return success, err
    else
        local success, err = pcall(loadstring(callback), ...)
        return success, err
    end
end

--- The command 'cc' is only used by the server so it can communicate through the web-panel api to the instances that it starts.
-- Doing this, enables achievements and the web-panel can communicate without any interruptions.
commands.add_command(
    'cc',
    'Evaluate command',
    function(cmd)
        local player = game.player
        if player then
            return
        end

        local callback = cmd.parameter
        if not callback then
            return
        end
        if not string.find(callback, '%s') and not string.find(callback, 'return') then
            callback = 'return ' .. callback
        end
        local success, err = command_handler(callback)
        if not success and type(err) == 'string' then
            local _end = string.find(err, 'stack traceback')
            if _end then
                err = string.sub(err, 0, _end - 2)
            end
        end
        if err or err == false then
            output_data(err)
        end
    end
)

--- The [JOIN] and [LEAVE] messages Factorio sends to stdout aren't sent in all cases of
--  players joining or leaving. So we send our own [PLAYER-JOIN] and [PLAYER-LEAVE] tags.
Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local secs = server_time.secs
        if secs == nil then
            return false
        end

        output_data(player_join_tag .. player.name)
    end
)

local leave_reason_map = {
    [defines.disconnect_reason.quit] = '',
    [defines.disconnect_reason.dropped] = ' (Dropped)',
    [defines.disconnect_reason.reconnect] = ' (Reconnect)',
    [defines.disconnect_reason.wrong_input] = ' (Wrong input)',
    [defines.disconnect_reason.desync_limit_reached] = ' (Desync limit reached)',
    [defines.disconnect_reason.cannot_keep_up] = ' (Cannot keep up)',
    [defines.disconnect_reason.afk] = ' (AFK)',
    [defines.disconnect_reason.kicked] = ' (Kicked)',
    [defines.disconnect_reason.kicked_and_deleted] = ' (Kicked)',
    [defines.disconnect_reason.banned] = ' (Banned)',
    [defines.disconnect_reason.switching_servers] = ' (Switching servers)'
}

Event.add(
    defines.events.on_player_left_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player then
            return
        end

        local secs = server_time.secs
        if secs == nil then
            return false
        end

        local reason = leave_reason_map[event.reason] or ''
        output_data(player_leave_tag .. player.name .. reason)
    end
)

Event.add(
    defines.events.on_player_died,
    function(event)
        local player = game.get_player(event.player_index)

        if not player or not player.valid then
            return
        end

        local secs = server_time.secs
        if secs == nil then
            return false
        end

        local cause = event.cause

        local message = {discord_bold_tag, player.name}
        if cause and cause.valid then
            message[#message + 1] = ' was killed by '

            local name = cause.name
            if name == 'character' and cause.player then
                name = cause.player.name
            end

            message[#message + 1] = name
            message[#message + 1] = '.'
        else
            message[#message + 1] = ' has died.'
        end

        message = concat(message)
        output_data(message)
    end
)

Public.build_embed_data = build_embed_data

return Public
