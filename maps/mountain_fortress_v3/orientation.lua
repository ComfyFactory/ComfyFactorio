local Public = require 'maps.mountain_fortress_v3.table'

local Orient = {}

local valid_directions =
{
    north = true,
    south = true,
    east = true,
    west = true
}

local opposite =
{
    north = 'south',
    south = 'north',
    east = 'west',
    west = 'east'
}

local entity_dirs =
{
    south = defines.direction.south,
    north = defines.direction.north,
    east = defines.direction.east,
    west = defines.direction.west
}

local loco_dirs =
{
    south = defines.direction.north,
    north = defines.direction.south,
    east = defines.direction.west,
    west = defines.direction.east
}

local collapse_dirs =
{
    south = 'north',
    north = 'south',
    east = 'west',
    west = 'east'
}

local arrow_text =
{
    south = '▼',
    north = '▲',
    east = '▶',
    west = '◀'
}

function Orient.get_direction()
    local direction = Public.get_stateful_settings('direction')
    if direction and valid_directions[direction] then
        return direction
    end
    local adjusted = Public.get('adjusted_zones')
    if adjusted and adjusted.direction and valid_directions[adjusted.direction] then
        return adjusted.direction
    end
    if Public.get_stateful_settings('reversed') then
        return 'north'
    end
    return 'south'
end

function Orient.is_horizontal()
    local direction = Orient.get_direction()
    return direction == 'east' or direction == 'west'
end

function Orient.is_reversed()
    local direction = Orient.get_direction()
    return direction == 'north' or direction == 'west'
end

function Orient.sign()
    if Orient.is_reversed() then
        return -1
    end
    return 1
end

function Orient.opposite(direction)
    return opposite[direction] or 'north'
end

function Orient.progression(pos)
    if Orient.is_horizontal() then
        return pos.x
    end
    return pos.y
end

function Orient.lateral(pos)
    if Orient.is_horizontal() then
        return pos.y
    end
    return pos.x
end

function Orient.world(lateral, progression)
    if Orient.is_horizontal() then
        return { x = progression, y = lateral }
    end
    return { x = lateral, y = progression }
end

function Orient.to_logical(pos)
    local x = pos.x or pos[1]
    local y = pos.y or pos[2]
    if Orient.is_horizontal() then
        return { x = y, y = x }
    end
    return { x = x, y = y }
end

function Orient.to_world(pos)
    if not pos then
        return pos
    end
    local x = pos.x or pos[1]
    local y = pos.y or pos[2]
    if x == nil or y == nil then
        return pos
    end
    if Orient.is_horizontal() then
        return { x = y, y = x }
    end
    return { x = x, y = y }
end

function Orient.offset(pos, d_lat, d_prog)
    return Orient.world(Orient.lateral(pos) + d_lat, Orient.progression(pos) + d_prog)
end

function Orient.chunk_progression(top_x, top_y)
    if Orient.is_horizontal() then
        return top_x
    end
    return top_y
end

function Orient.in_chunk_progression(xv, yv)
    if Orient.is_horizontal() then
        return xv
    end
    return yv
end

function Orient.collapse_direction()
    return collapse_dirs[Orient.get_direction()] or 'north'
end

function Orient.entity_direction()
    return entity_dirs[Orient.get_direction()] or defines.direction.south
end

function Orient.loco_direction()
    return loco_dirs[Orient.get_direction()] or defines.direction.north
end

function Orient.rail_direction()
    if Orient.is_horizontal() then
        return defines.direction.east
    end
    return defines.direction.north
end

function Orient.arrow_text()
    return arrow_text[Orient.get_direction()] or '▼'
end

function Orient.in_map_width(pos)
    local lat = Orient.lateral(pos)
    local half = Public.zone_settings.zone_width / 2
    return lat < half and lat >= -half
end

function Orient.zone_index(pos, size)
    return math.floor((math.abs(Orient.progression(pos) / Public.zone_settings.zone_depth)) % size) + 1
end

function Orient.aabb(lat1, prog1, lat2, prog2)
    local a = Orient.world(lat1, prog1)
    local b = Orient.world(lat2, prog2)
    local min_x = math.min(a.x, b.x)
    local min_y = math.min(a.y, b.y)
    local max_x = math.max(a.x, b.x)
    local max_y = math.max(a.y, b.y)
    return { { min_x, min_y }, { max_x, max_y } }
end

function Orient.named_aabb(lat1, prog1, lat2, prog2)
    local area = Orient.aabb(lat1, prog1, lat2, prog2)
    return
    {
        left_top = { x = area[1][1], y = area[1][2] },
        right_bottom = { x = area[2][1], y = area[2][2] }
    }
end

Orient.valid_directions = valid_directions

return Orient
