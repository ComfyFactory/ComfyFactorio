local Public = {}
local insert = table.insert
local remove = table.remove
local random = math.random
local sqrt = math.sqrt
local floor = math.floor
local atan2 = math.atan2

--[[
rand_range - Return random integer within the range.
@param start - Start range.
@param stop - Stop range.
--]]
Public.rand_range = function(start, stop)
    return random(start, stop)
end

--[[
for_bounding_box_extra - Execute function per every position within bb with parameter.
@param surf - LuaSurface, that will be given into func.
@param bb - BoundingBox
@param func - User supplied callback that will be executed.
@param args - User supplied arguments.
--]]
Public.for_bounding_box_extra = function(surf, bb, func, args)
    for x = bb.left_top.x, bb.right_bottom.x do
        for y = bb.left_top.y, bb.right_bottom.y do
            func(surf, x, y, args)
        end
    end
end

--[[
for_bounding_box - Execute function per every position within bb.
@param surf - LuaSurface, that will be given into func.
@param bb - BoundingBox
@param func - User supplied callback that will be executed.
--]]
Public.for_bounding_box = function(surf, bb, func)
    for x = bb.left_top.x, bb.right_bottom.x do
        for y = bb.left_top.y, bb.right_bottom.y do
            func(surf, x, y)
        end
    end
end

local function safe_get(t, k)
    local res, value =
        pcall(
        function()
            return t[k]
        end
    )
    if res then
        return value
    end

    return nil
end

--[[
get_axis - Extract axis value from any point format.
@param point - Table with or without explicity axis members.
@param axis - Single character string describing the axis.
--]]
Public.get_axis = function(point, axis)
    if point.position then
        return Public.get_axis(point.position, axis)
    end

    if point[axis] then
        return point[axis]
    end

    if safe_get(point, 'target') then
        return Public.get_axis(point.target, axis)
    end

    if #point ~= 2 then
        log('get_axis: invalid point format')
        return nil
    end

    if axis == 'x' then
        return point[1]
    end

    return point[2]
end

--[[
get_close_random_position - Gets randomized close position to origin,
@param origin - Position that will be taken as relative
                point for calculation.
@param radius - Radius space.
--]]
Public.get_close_random_position = function(origin, radius)
    local x = Public.get_axis(origin, 'x')
    local y = Public.get_axis(origin, 'y')

    x = Public.rand_range(x - radius, x + radius)
    y = Public.rand_range(y - radius, y + radius)

    return {x = x, y = y}
end

--[[
get_distance - Returns distance in tiles between 2 points.
@param a - Position, first point.
@param b - Position, second point.
--]]
Public.get_distance = function(a, b)
    local h = (Public.get_axis(a, 'x') - Public.get_axis(b, 'x')) ^ 2
    local v = (Public.get_axis(a, 'y') - Public.get_axis(b, 'y')) ^ 2

    return sqrt(h + v)
end

--[[
point_in_bounding_box - Check whatever point is within bb.
@param point - Position
@param bb - BoundingBox
--]]
Public.point_in_bounding_box = function(point, bb)
    local x = Public.get_axis(point, 'x')
    local y = Public.get_axis(point, 'y')

    if bb.left_top.x <= x and bb.right_bottom.x >= x and bb.left_top.y <= y and bb.right_bottom.y >= y then
        return true
    end

    return false
end

Public.direction_lookup = {
    [-1] = {
        [1] = defines.direction.southwest,
        [0] = defines.direction.west,
        [-1] = defines.direction.northwest
    },
    [0] = {
        [1] = defines.direction.south,
        [-1] = defines.direction.north
    },
    [1] = {
        [1] = defines.direction.southeast,
        [0] = defines.direction.east,
        [-1] = defines.direction.northeast
    }
}

--[[
get_readable_direction - Return readable direction from point a to b.
@param a - Position A
@param b - Position B
--]]
Public.get_readable_direction = function(a, b)
    local a_x = Public.get_axis(a, 'x')
    local a_y = Public.get_axis(a, 'y')
    local b_x = Public.get_axis(b, 'x')
    local b_y = Public.get_axis(b, 'y')
    local h, v

    if a_x < b_x then
        h = 1
    elseif a_x > b_x then
        h = -1
    else
        h = 0
    end

    if a_y < b_y then
        v = 1
    elseif a_y > b_y then
        v = -1
    else
        v = 0
    end

    local mapping = {
        [defines.direction.southwest] = 'south-west',
        [defines.direction.west] = 'west',
        [defines.direction.northwest] = 'north-west',
        [defines.direction.south] = 'south',
        [defines.direction.north] = 'north',
        [defines.direction.southeast] = 'south-east',
        [defines.direction.east] = 'east',
        [defines.direction.northeast] = 'north-east'
    }
    return mapping[Public.direction_lookup[h][v]]
end

--[[
create_bounding_box_by_points - Construct a BoundingBox using points
from any array of objects such as bounding boxes.
@param objects - Array of objects.
--]]
Public.create_bounding_box_by_points = function(objects)
    local box = {
        left_top = {
            x = Public.get_axis(objects[1], 'x'),
            y = Public.get_axis(objects[1], 'y')
        },
        right_bottom = {
            x = Public.get_axis(objects[1], 'x'),
            y = Public.get_axis(objects[1], 'y')
        }
    }

    for i = 2, #objects do
        local object = objects[i]
        if object.bounding_box then
            local bb = object.bounding_box
            if box.left_top.x > bb.left_top.x then
                box.left_top.x = bb.left_top.x
            end

            if box.right_bottom.x < bb.right_bottom.x then
                box.right_bottom.x = bb.right_bottom.x
            end

            if box.left_top.y > bb.left_top.y then
                box.left_top.y = bb.left_top.y
            end

            if box.right_bottom.y < bb.right_bottom.y then
                box.right_bottom.y = bb.right_bottom.y
            end
        else
            local x = Public.get_axis(object, 'x')
            local y = Public.get_axis(object, 'y')

            if box.left_top.x > x then
                box.left_top.x = x
            elseif box.right_bottom.x < x then
                box.right_bottom.x = x
            end

            if box.left_top.y > y then
                box.left_top.y = y
            elseif box.right_bottom.y < y then
                box.right_bottom.y = y
            end
        end
    end

    box.left_top.x = box.left_top.x - 1
    box.left_top.y = box.left_top.y - 1
    box.right_bottom.x = box.right_bottom.x + 1
    box.right_bottom.y = box.right_bottom.y + 1
    return box
end

--[[
enlare_bounding_box - Performs enlargement operation on the bounding box.
@param bb - BoundingBox
@param size - By how many tiles to enlarge.
--]]
Public.enlarge_bounding_box = function(bb, size)
    bb.left_top.x = bb.left_top.x - size
    bb.left_top.y = bb.left_top.y - size
    bb.right_bottom.x = bb.right_bottom.x + size
    bb.right_bottom.y = bb.right_bottom.y + size
end

--[[
merge_bounding_boxes - Merge array of BoundingBox objects into a single
object.
@param bbs - Array of BoundingBox objects.
--]]
Public.merge_bounding_boxes = function(bbs)
    if bbs == nil then
        log('common.merge_bounding_boxes: bbs is nil')
        return
    end

    if #bbs <= 0 then
        log('common.merge_bounding_boxes: bbs is empty')
        return
    end

    local box = {
        left_top = {
            x = bbs[1].left_top.x,
            y = bbs[1].left_top.y
        },
        right_bottom = {
            x = bbs[1].right_bottom.x,
            y = bbs[1].right_bottom.y
        }
    }
    for i = 2, #bbs do
        local bb = bbs[i]
        if box.left_top.x > bb.left_top.x then
            box.left_top.x = bb.left_top.x
        end

        if box.right_bottom.x < bb.right_bottom.x then
            box.right_bottom.x = bb.right_bottom.x
        end

        if box.left_top.y > bb.left_top.y then
            box.left_top.y = bb.left_top.y
        end

        if box.right_bottom.y < bb.right_bottom.y then
            box.right_bottom.y = bb.right_bottom.y
        end
    end

    return box
end

--[[
get_time - Return strigified time of a tick.
@param ticks - Just a ticks.
--]]
Public.get_time = function(ticks)
    local seconds = floor((ticks / 60) % 60)
    local minutes = floor((ticks / 60 / 60) % 60)
    local hours = floor(ticks / 60 / 60 / 60)

    local time
    if hours > 0 then
        time = string.format('%02d:%01d:%02d', hours, minutes, seconds)
    elseif minutes > 0 then
        time = string.format('%02d:%02d', minutes, seconds)
    else
        time = string.format('00:%02d', seconds)
    end

    return time
end

--[[
polygon_insert - Append vertex in clockwise order.
@param vertex - Point to insert,
@param vertices - Tables of vertices.
--]]
Public.polygon_append_vertex = function(vertices, vertex)
    insert(vertices, vertex)

    local x_avg, y_avg = 0, 0
    for _, v in pairs(vertices) do
        x_avg = x_avg + Public.get_axis(v, 'x')
        y_avg = y_avg + Public.get_axis(v, 'y')
    end
    x_avg = x_avg / #vertices
    y_avg = y_avg / #vertices

    local delta_x, delta_y, rad1, rad2
    for i = 1, #vertices, 1 do
        for j = 1, #vertices - i do
            local v = vertices[j]
            delta_x = Public.get_axis(v, 'x') - x_avg
            delta_y = Public.get_axis(v, 'y') - y_avg
            rad1 = ((atan2(delta_x, delta_y) * (180 / 3.14)) + 360) % 360

            v = vertices[j + 1]
            delta_x = Public.get_axis(v, 'x') - x_avg
            delta_y = Public.get_axis(v, 'y') - y_avg
            rad2 = ((atan2(delta_x, delta_y) * (180 / 3.14)) + 360) % 360
            if rad1 > rad2 then
                vertices[j], vertices[j + 1] = vertices[j + 1], vertices[j]
            end
        end
    end
end

--[[
positions_equal - Checks if given positions are equal.
@param a - Position a
@param b - Position b
--]]
Public.positions_equal = function(a, b)
    local p1 = Public.get_axis(a, 'x')
    local p2 = Public.get_axis(b, 'x')

    if p1 ~= p2 then
        return false
    end

    p1 = Public.get_axis(a, 'y')
    p2 = Public.get_axis(b, 'y')

    if p1 ~= p2 then
        return false
    end

    return true
end

local function rev(array, index)
    if index == nil then
        index = 0
    end

    index = #array - index
    return array[index]
end

--[[
deepcopy - Makes a deep copy of an object.
@param orig - Object to copy.
--]]
Public.deepcopy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Public.deepcopy(orig_key)] = Public.deepcopy(orig_value)
        end
        setmetatable(copy, Public.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function convex_hull_turn(a, b, c)
    local x1, x2, x3, y1, y2, y3
    x1 = Public.get_axis(a, 'x')
    x2 = Public.get_axis(b, 'x')

    y1 = Public.get_axis(a, 'y')
    y2 = Public.get_axis(b, 'y')

    if c then
        x3 = Public.get_axis(c, 'x')
        y3 = Public.get_axis(c, 'y')
        return (x2 - x1) * (y3 - y1) - (y2 - y1) * (x3 - x1)
    end

    return (x1 * y2) - (y1 * x2)
end

--[[
convex_hull - Generate convex hull out of given vertices.
@param vertices - Table of positions.
--]]
Public.get_convex_hull = function(_vertices)
    if #_vertices == 0 then
        return {}
    end

    local vertices = Public.deepcopy(_vertices)

    -- Get the lowest point
    local v, y1, y2, x1, x2, lowest_index
    local lowest = vertices[1]
    for i = 2, #vertices do
        v = vertices[i]
        y1 = Public.get_axis(v, 'y')
        y2 = Public.get_axis(lowest, 'y')

        if y1 < y2 then
            lowest = v
            lowest_index = i
        elseif y1 == y2 then
            x1 = Public.get_axis(v, 'x')
            x2 = Public.get_axis(lowest, 'x')
            if x1 < x2 then
                lowest = v
                lowest_index = i
            end
        end
    end

    remove(vertices, lowest_index)
    x1 = Public.get_axis(lowest, 'x')
    y1 = Public.get_axis(lowest, 'y')

    -- Sort by angle to horizontal axis.
    local rad1, rad2, dist1, dist2

    local i, j = 1, 1
    while i <= #vertices do
        while j <= #vertices - i do
            v = vertices[j]
            x2 = Public.get_axis(v, 'x')
            y2 = Public.get_axis(v, 'y')
            rad1 = (atan2(y2 - y1, x2 - x1) * (180 / 3.14) + 320) % 360

            v = vertices[j + 1]
            x2 = Public.get_axis(v, 'x')
            y2 = Public.get_axis(v, 'y')
            rad2 = (atan2(y2 - y1, x2 - x1) * (180 / 3.14) + 320) % 360

            if rad1 > rad2 then
                vertices[j + 1], vertices[j] = vertices[j], vertices[j + 1]
            elseif rad1 == rad2 then
                dist1 = Public.get_distance(lowest, vertices[j])
                dist2 = Public.get_distance(lowest, vertices[j + 1])
                if dist1 > dist2 then
                    remove(vertices, j + 1)
                else
                    remove(vertices, j)
                end
            end

            j = j + 1
        end

        i = i + 1
    end

    if #vertices <= 3 then
        return {}
    end

    -- Traverse points.
    local stack = {
        vertices[1],
        vertices[2],
        vertices[3]
    }
    local point
    for ii = 4, #vertices do
        point = vertices[ii]

        while #stack > 1 and convex_hull_turn(point, rev(stack, 1), rev(stack)) >= 0 do
            remove(stack)
        end

        insert(stack, point)
    end

    insert(stack, lowest)
    return stack
end

--[[
get_closest_neighbour - Return object whose is closest to given position.
@param position - Position, origin point
@param object - Table of objects that have any sort of position datafield.
--]]
Public.get_closest_neighbour = function(position, objects)
    local closest = objects[1]
    local min_dist = Public.get_distance(position, closest)

    local object, dist
    for i = #objects, 1, -1 do
        object = objects[i]
        if object and not object.player then
            dist = Public.get_distance(position, object)
            if dist < min_dist then
                closest = object
                min_dist = dist
            end
        end
    end

    return closest
end

return Public
