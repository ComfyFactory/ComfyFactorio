-- Dependencies
local Game = require 'utils.game'
local Color = require 'utils.color_presets'
local Server = require 'utils.server'

-- localized functions
local random = math.random
local sqrt = math.sqrt
local floor = math.floor
local ceil = math.ceil
local format = string.format
local match = string.match
local insert = table.insert
local concat = table.concat

-- local constants
local prefix = '## - '
local warning_prefix = '## NOTE ## - '
local minutes_to_ticks = 60 * 60
local hours_to_ticks = 60 * 60 * 60
local ticks_to_minutes = 1 / minutes_to_ticks
local ticks_to_hours = 1 / hours_to_ticks

-- local vars
local Public = {}

--- Measures distance between pos1 and pos2
function Public.distance(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    return sqrt(dx * dx + dy * dy)
end

--- Takes msg and prints it to all players except provided player
-- @param msg <string|table> table if locale is used
-- @param player <LuaPlayer> the player not to send the message to
-- @param color <table> the color to use for the message, defaults to white
function Public.print_except(msg, player, color)
    if not color then
        color = Color.white
    end

    for _, p in pairs(game.connected_players) do
        if p ~= player then
            p.print(msg, color)
        end
    end
end

function Public.print_to(player_ident, msg, color)
    local player = Public.validate_player(player_ident)
    color = color or Color.yellow

    if player then
        player.print(prefix .. msg, color)
    else
        game.print(prefix .. msg, color)
    end
end

function Public.warning(player_ident, msg, color)
    local player = Public.validate_player(player_ident)
    color = color or Color.comfy

    if player then
        player.print(warning_prefix .. msg, color)
    else
        game.print(warning_prefix .. msg, color)
    end
end

--- Prints a message to all online admins
-- @param msg <string|table> table if locale is used
-- @param source <LuaPlayer|string|nil> string must be the name of a player, nil for server.
function Public.print_admins(msg, source)
    local source_name
    local chat_color
    if source and game.players[source] then
        if type(source) == 'string' then
            source_name = source
            chat_color = game.players[source].chat_color
        else
            source_name = source.name
            chat_color = source.chat_color
        end
    else
        source_name = 'Server'
        chat_color = Color.yellow
    end
    local formatted_msg = prefix .. '(ADMIN) ' .. source_name .. ': ' .. msg
    print(formatted_msg)
    for _, p in pairs(game.connected_players) do
        if p.admin then
            p.print(formatted_msg, chat_color)
        end
    end
end

--- Returns a valid string with the name of the actor of a command.
function Public.get_actor()
    if game.player then
        return game.player.name
    end
    return '<server>'
end

function Public.cast_bool(var)
    if var then
        return true
    else
        return false
    end
end

function Public.find_entities_by_last_user(player, surface, filters)
    if type(player) == 'string' or not player then
        error("bad argument #1 to '" .. debug.getinfo(1, 'n').name .. "' (number or LuaPlayer expected, got " .. type(player) .. ')', 1)
        return
    end
    if type(surface) ~= 'table' and type(surface) ~= 'number' then
        error("bad argument #2 to '" .. debug.getinfo(1, 'n').name .. "' (number or LuaSurface expected, got " .. type(surface) .. ')', 1)
        return
    end
    local entities = {}
    local filter = filters or {}
    if type(surface) == 'number' then
        surface = game.surfaces[surface]
    end
    if type(player) == 'number' then
        player = game.get_player(player)
    end
    filter.force = player.force.name
    for _, e in pairs(surface.find_entities_filtered(filter)) do
        if e.last_user == player then
            insert(entities, e)
        end
    end
    return entities
end

function Public.ternary(c, t, f)
    if c then
        return t
    else
        return f
    end
end

local function CurrentDate(z)
    z = floor(z / 86400) + 719468
    local era = floor(z / 146097)
    local doe = floor(z - era * 146097)
    local yoe = floor((doe - doe / 1460 + doe / 36524 - doe / 146096) / 365)
    local y = floor(yoe + era * 400)
    local doy = doe - floor((365 * yoe + yoe / 4 - yoe / 100))
    local mp = floor((5 * doy + 2) / 153)
    local d = ceil(doy - (153 * mp + 2) / 5 + 1)
    local m = floor(mp + (mp < 10 and 3 or -9))
    return y + (m <= 2 and 1 or 0), m, d
end

function Public.CurrentTime(epoch)
    if not epoch then
        return
    end

    local unixTime = floor(epoch) - (60 * 60 * (-2))

    local hours = floor(unixTime / 3600 % 12)
    local minutes = floor(unixTime / 60 % 60)
    local seconds = floor(unixTime % 60)

    local year, month, day = CurrentDate(unixTime)

    month = tonumber(month)
    month = 0 .. month

    day = tonumber(day)
    if day < 10 then
        day = 0 .. day
    end

    return {
        year = year,
        month = month,
        day = day,
        hours = hours,
        minutes = minutes < 10 and '0' .. minutes or minutes,
        seconds = seconds < 10 and '0' .. seconds or seconds
    }
end

local CurrentTime = Public.CurrentTime

function Public.get_current_date(pretty)
    local server_time = Server.get_current_time()
    if not server_time then
        return false
    end

    local date = CurrentTime(server_time)
    if pretty then
        return tonumber(date.year .. '-' .. date.month .. '-' .. date.day)
    else
        return tonumber(date.year .. date.month .. date.day)
    end
end

function Public.get_current_date_with_time()
    local server_time = Server.get_current_time()
    if not server_time then
        return false
    end

    local date = CurrentTime(server_time)
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

--- Takes a time and returns it in days, hours, minutes etc.
function Public.get_formatted_playtime(ticks)
    if ticks < 5184000 then
        local y = ticks / 216000
        y = tostring(y)
        local h = ''
        for i = 1, 10, 1 do
            local z = string.sub(y, i, i)

            if z == '.' then
                break
            else
                h = h .. z
            end
        end

        local m = ticks % 216000
        m = m / 3600
        m = floor(m)
        m = tostring(m)

        if h == '0' then
            local str = m .. ' minutes'
            return str
        else
            local str = h .. ' hours '
            str = str .. m
            str = str .. ' minutes'
            return str
        end
    else
        local y = ticks / 5184000
        y = tostring(y)
        local h = ''
        for i = 1, 10, 1 do
            local z = string.sub(y, i, i)

            if z == '.' then
                break
            else
                h = h .. z
            end
        end

        local m = ticks % 5184000
        m = m / 216000
        m = floor(m)
        m = tostring(m)

        if h == '0' then
            local str = m .. ' days'
            return str
        else
            local str = h .. ' days '
            str = str .. m
            str = str .. ' hours'
            return str
        end
    end
end

--- Prints a message letting the player know they cannot run a command
-- @param name string name of the command
function Public.cant_run(name)
    Game.player_print("Can't run command (" .. name .. ') - insufficient permission.')
end

--- Logs the use of a command and its user
-- @param actor string with the actor's name (usually acquired by calling get_actor)
-- @param command the command's name as table element
-- @param parameters the command's parameters as a table (optional)
function Public.log_command(actor, command, parameters)
    local action = concat {'[Admin-Command] ', actor, ' used: ', command}
    if parameters then
        action = concat {action, ' ', parameters}
    end
    print(action)
end

function Public.comma_value(n) -- credit http://richard.warburton.it
    local left, num, right = match(n, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

--- Asserts the argument is one of type arg_types
-- @param arg the variable to check
-- @param arg_types the type as a table of sings
-- @return boolean
function Public.verify_mult_types(arg, arg_types)
    for _, arg_type in pairs(arg_types) do
        if type(arg) == arg_type then
            return true
        end
    end
    return false
end

--- Returns a random RGB color as a table
function Public.random_RGB()
    return {r = random(0, 255), g = random(0, 255), b = random(0, 255)}
end

--- Sets a table element to value while also returning value.
-- @param tbl table to change the element of
-- @param key string
-- @param value nil|boolean|number|string|table to set the element to
-- @return value
function Public.set_and_return(tbl, key, value)
    tbl[key] = value
    return value
end

--- Takes msg and prints it to all players. Also prints to the log and discord
-- @param msg <string> The message to print
-- @param warning_prefixes <string> The name of the module/warning
function Public.action_warning(warning_prefixes, msg)
    game.print(prefix .. msg, Color.yellow)
    msg = format('%s %s', warning_prefixes, msg)
    print(msg)
    Server.to_discord_bold(msg)
end

--- Takes msg and prints it to all players. Also prints to the log and discord
-- @param msg <string> The message to print
-- @param warning_prefixes <string> The name of the module/warning
function Public.action_warning_embed(warning_prefixes, msg)
    game.print(prefix .. msg, Color.yellow)
    msg = format('%s %s', warning_prefixes, msg)
    print(msg)
    Server.to_discord_embed(msg)
end

--- Takes msg and prints it to the log and discord.
-- @param msg <string> The message to print
-- @param warning_prefixes <string> The name of the module/warning
function Public.action_to_discord(warning_prefixes, msg)
    msg = format('%s %s', warning_prefixes, msg)
    print(msg)
    Server.to_discord_bold(msg)
end

--- Takes msg and prints it to all players except provided player. Also prints to the log and discord
-- @param msg <string> The message to print
-- @param warning_prefixes <string> The name of the module/warning
-- @param player <LuaPlayer> the player not to send the message to
function Public.silent_action_warning(warning_prefixes, msg, player)
    Public.print_except(prefix .. msg, player, Color.yellow)
    msg = format('%s %s', warning_prefixes, msg)
    print(msg)
    Server.to_discord_bold(msg)
end

--- Takes msg and logs it.
-- @param msg <string> The message to print
-- @param warning_prefixes <string> The name of the module/warning
function Public.log_msg(warning_prefixes, msg)
    msg = format('%s %s', warning_prefixes, msg)
    print(msg)
end

--- Takes a string, number, or LuaPlayer and returns a valid LuaPlayer or nil.
-- Intended for commands as there are extra checks in place.
-- @param <string|number|LuaPlayer>
-- @return <LuaPlayer|nil> <string|nil> <number|nil> the LuaPlayer, their name, and their index
function Public.validate_player(player_ident)
    local data_type = type(player_ident)
    local player

    if data_type == 'table' and player_ident.valid then
        local is_player = player_ident.is_player()
        if is_player then
            player = player_ident
        end
    elseif data_type == 'number' or data_type == 'string' then
        player = game.get_player(player_ident)
    else
        return
    end

    if not player or not player.valid then
        return
    end

    return player, player.name, player.index
end

-- add utility functions that exist in base factorio/util
require 'util'

--- Moves a position according to the parameters given
-- Notice: only accepts cardinal directions as direction
-- @param position <table> table containing a map position
-- @param direction <defines.direction> north, east, south, west
-- @param distance <number>
-- @return <table> modified position
Public.move_position = util.moveposition

--- Takes a direction and gives you the opposite
-- @param direction <defines.direction> north, east, south, west, northeast, northwest, southeast, southwest
-- @return <number> representing the direction
Public.opposite_direction = util.oppositedirection

--- Takes the string of a module and returns whether is it available or not
-- @param name <string> the name of the module (ex. 'utils.core')
-- @return <boolean>
Public.is_module_available = util.ismoduleavailable

return Public
