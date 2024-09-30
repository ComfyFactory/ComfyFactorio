local Module = {}

---Returns cartesian distance between pos1 and pos2
---@param pos1 MapPosition|{x:double,y:double}
---@param pos2 MapPosition|{x:double,y:double}
---@return number
function Module.distance(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    return math.sqrt(dx * dx + dy * dy)
end

---Returns true if position is closer to pos1 than to pos2
---@param pos1 MapPosition|{x:double,y:double}
---@param pos2 MapPosition|{x:double,y:double}
---@param position MapPosition|{x:double,y:double}
---@return boolean
function Module.is_closer(position, pos1, pos2)
    return Module.distance(pos1, position) < Module.distance(pos2, position)
end

---Returns true if the position is inside the area
---@param position MapPosition|{x:double,y:double}|nil
---@param area BoundingBox|{left_top:MapPosition, right_bottom:MapPosition}
---@return boolean
function Module.inside(position, area)
    if not position then
        return false
    end

    local lt = area.left_top
    local rb = area.right_bottom

    return position.x >= lt.x and position.y >= lt.y and position.x <= rb.x and position.y <= rb.y
end

---rounds number (num) to certain number of decimal places (idp)
function math.round(num, idp)
    local mult = 10 ^ (idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function math.clamp(num, min, max)
    if num < min then
        return min
    elseif num > max then
        return max
    else
        return num
    end
end

function Module.print_except(msg, player)
    for _, p in pairs(game.players) do
        if p.connected and p ~= player then
            p.print(msg)
        end
    end
end

function Module.print_admins(msg)
    for _, p in pairs(game.players) do
        if p.connected and p.admin then
            p.print(msg)
        end
    end
end

function Module.get_actor()
    if game.player then
        return game.player.name
    end
    return '<server>'
end

function Module.cast_bool(var)
    if var then
        return true
    else
        return false
    end
end

function Module.get_formatted_playtime(x)
    if x < 5184000 then
        local y = x / 216000
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

        local m = x % 216000
        m = m / 3600
        m = math.floor(m)
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
        local y = x / 5184000
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

        local m = x % 5184000
        m = m / 216000
        m = math.floor(m)
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

function Module.find_entities_by_last_user(player, surface, filters)
    if type(player) == 'string' or not player then
        error("bad argument #1 to '" .. debug.getinfo(1, 'n').name .. "' (number or LuaPlayer expected, got " .. type(player) .. ')', 1)
        return
    end
    if type(surface) ~= 'table' and type(surface) ~= 'number' then
        error("bad argument #2 to '" .. debug.getinfo(1, 'n').name .. "' (number or LuaSurface expected, got " .. type(surface) .. ')', 1)
        return
    end
    local entities = {}
    filters = filters or {}
    if type(surface) == 'number' then
        surface = game.surfaces[surface]
    end
    if type(player) == 'number' then
        player = game.players[player]
    end
    filters.force = player.force.name
    for _, e in pairs(surface.find_entities_filtered(filters)) do
        if e.last_user == player then
            table.insert(entities, e)
        end
    end
    return entities
end

function Module.ternary(c, t, f)
    if c then
        return t
    else
        return f
    end
end

local minutes_to_ticks = 60 * 60
local hours_to_ticks = 60 * 60 * 60
local ticks_to_minutes = 1 / minutes_to_ticks
local ticks_to_hours = 1 / hours_to_ticks
function Module.format_time(ticks)
    local result = {}

    local hours = math.floor(ticks * ticks_to_hours)
    if hours > 0 then
        ticks = ticks - hours * hours_to_ticks
        table.insert(result, hours)
        if hours == 1 then
            table.insert(result, 'hour')
        else
            table.insert(result, 'hours')
        end
    end

    local minutes = math.floor(ticks * ticks_to_minutes)
    table.insert(result, minutes)
    if minutes == 1 then
        table.insert(result, 'minute')
    else
        table.insert(result, 'minutes')
    end

    return table.concat(result, ' ')
end

-- Convert date from 1999/01/01
function Module.convert_date(year, month, day)
    year = tonumber(year)
    month = tonumber(month)
    day = tonumber(day)
    local function sub(n, d)
        local a, b = 1, 1
        if n < 0 then
            a = -1
        end
        if d < 0 then
            b = -1
        end
        return a * b * (math.abs(n) / math.abs(d))
    end
    local d

    if (year < 0) or (month < 1) or (month > 12) or (day < 1) or (day > 31) then
        return
    end
    d = sub(month - 14, 12)
    return (day - 32075 + sub(1461 * (year + 4800 + d), 4) + sub(367 * (month - 2 - d * 12), 12) - sub(3 * sub(year + 4900 + d, 100), 4)) - 2415021
end

return Module
