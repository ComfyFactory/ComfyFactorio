local Task = require 'utils.task_token'

local Public = {}

local ceil = math.ceil
local queue_task = Task.queue_task
local tiles_per_call = 12
local total_calls = ceil(1024 / tiles_per_call)

Public.register = Task.register
Public.tiles_per_call = tiles_per_call
Public.total_calls = total_calls

function Public.queue(func_token, data, weight)
    queue_task(func_token, data, weight or 1)
end

function Public.new_chunk_data(surface, area)
    return
    {
        yv = 0,
        xv = 0,
        y = 0,
        x = area.left_top.x,
        area = area,
        top_x = area.left_top.x,
        top_y = area.left_top.y,
        surface = surface,
        tiles = {},
        hidden_tiles = {},
        entities = {},
        rocks = {},
        buildings = {},
        decoratives = {},
        markets = {},
        treasure = {}
    }
end

function Public.get_position(data)
    data.yv = data.yv + 1

    if data.yv == 32 then
        if data.xv == 32 then
            data.xv = 0
        end
        if data.yv == 32 then
            data.yv = 0
        end
        data.xv = data.xv + 1
    end

    data.position = { x = data.top_x + data.xv, y = data.top_y + data.yv }
end

function Public.do_tile_inner(tiles, tile, pos)
    if type(tile) == 'string' then
        tiles[#tiles + 1] = { name = tile, position = pos }
    end
end

function Public.do_place_tiles(data)
    local surface = data.surface
    if not surface or not surface.valid then
        return
    end
    surface.set_tiles(data.tiles, true)
end

function Public.do_place_hidden_tiles(data)
    local surface = data.surface
    if not surface or not surface.valid then
        return
    end
    surface.set_tiles(data.hidden_tiles, true)
end

function Public.do_place_decoratives(data)
    local surface = data.surface
    if not surface or not surface.valid then
        return
    end
    local dec = data.decoratives
    if #dec > 0 then
        surface.create_decoratives({ check_collision = true, decoratives = dec })
    end
end

function Public.do_place_entities(data)
    local surface = data.surface
    if not surface or not surface.valid then
        return
    end
    for _, e in pairs(data.entities) do
        if e.name then
            if not e.collision or surface.can_place_entity(e) then
                local entity = surface.create_entity(e)
                if entity and entity.valid then
                    if e.direction then
                        entity.direction = e.direction
                    end
                    if e.force then
                        entity.force = e.force
                    end
                    if e.amount then
                        entity.amount = e.amount
                    end
                end
            end
        end
    end
end

function Public.run_chart_update(data)
    local surface = data.surface
    if not surface or not surface.valid then
        return
    end
    local x = data.top_x / 32
    local y = data.top_y / 32
    if game.forces.player.is_chunk_charted(surface, { x, y }) then
        game.forces.player.chart(
            surface,
            {
                { data.top_x, data.top_y },
                { data.top_x + 1, data.top_y + 1 }
            }
        )
    end
end

function Public.schedule_action(func_token, data, weight)
    Public.queue(func_token, data, weight or total_calls)
end

return Public
