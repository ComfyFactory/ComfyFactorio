local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'

local Public = require 'maps.mountain_fortress_v3.stateful.table'

local ceil = math.ceil
local queue_task = Task.queue_task
local tiles_per_call = 8
local total_calls = ceil(1024 / tiles_per_call)
local regen_decoratives = false
local generate_map = require 'maps.mountain_fortress_v3.stateful.terrain'.heavy_functions

-- Simple "loop" that is UPS friendly.
local function get_position(data)
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

    data.position = {x = data.top_x + data.xv, y = data.top_y + data.yv}
end

local function do_tile_inner(tiles, tile, pos)
    if type(tile) == 'string' then
        tiles[#tiles + 1] = {name = tile, position = pos}
    end
end

local function do_tile(x, y, data, shape)
    local pos = {x, y}

    -- local coords need to be 'centered' to allow for correct rotation and scaling.
    local tile = shape(data)

    if type(tile) == 'table' then
        do_tile_inner(data.tiles, tile.tile, pos)

        local hidden_tile = tile.hidden_tile
        if hidden_tile then
            data.hidden_tiles[#data.hidden_tiles + 1] = {tile = hidden_tile, position = pos}
        end

        local entities = tile.entities
        if entities then
            for _, entity in ipairs(entities) do
                if not entity.position then
                    entity.position = pos
                end
                data.entities[#data.entities + 1] = entity
            end
        end

        local buildings = tile.buildings
        if buildings then
            for _, entity in ipairs(buildings) do
                if not entity.position then
                    entity.position = pos
                end
                data.buildings[#data.buildings + 1] = entity
            end
        end

        local decoratives = tile.decoratives
        if decoratives then
            for _, decorative in ipairs(decoratives) do
                data.decoratives[#data.decoratives + 1] = decorative
            end
        end
    else
        do_tile_inner(data.tiles, tile, pos)
    end
end

local function do_row(row, data, shape)
    local y = data.top_y + row
    local top_x = data.top_x
    local tiles = data.tiles

    data.y = y

    for x = top_x, top_x + 31 do
        data.x = x
        local pos = {data.x, data.y}

        get_position(data)

        -- local coords need to be 'centered' to allow for correct rotation and scaling.
        local tile = shape(data)

        if type(tile) == 'table' then
            do_tile_inner(tiles, tile.tile, pos)

            local hidden_tile = tile.hidden_tile
            if hidden_tile then
                data.hidden_tiles[#data.hidden_tiles + 1] = {tile = hidden_tile, position = pos}
            end

            local entities = tile.entities
            if entities then
                for _, entity in ipairs(entities) do
                    if not entity.position then
                        entity.position = pos
                    end
                    data.entities[#data.entities + 1] = entity
                end
            end

            local buildings = tile.buildings
            if buildings then
                for _, entity in ipairs(buildings) do
                    if not entity.position then
                        entity.position = pos
                    end
                    data.buildings[#data.buildings + 1] = entity
                end
            end

            local decoratives = tile.decoratives
            if decoratives then
                for _, decorative in ipairs(decoratives) do
                    if not decorative.position then
                        decorative.position = pos
                    end
                    data.decoratives[#data.decoratives + 1] = decorative
                end
            end
        else
            do_tile_inner(tiles, tile, pos)
        end
    end
end

local function do_place_tiles(data)
    local surface = data.surface
    surface.set_tiles(data.tiles, true)
end

local function do_place_hidden_tiles(data)
    local surface = data.surface
    surface.set_tiles(data.hidden_tiles, true)
end

local function do_place_decoratives(data)
    local surface = data.surface
    if regen_decoratives then
        surface.regenerate_decorative(nil, {{data.top_x / 32, data.top_y / 32}})
    end

    local dec = data.decoratives
    if #dec > 0 then
        surface.create_decoratives({check_collision = true, decoratives = dec})
    end
end

local function do_place_buildings(data)
    local surface = data.surface
    local entity
    local callback
    for _, e in ipairs(data.buildings) do
        if e.e_type then
            local p = e.position
            if
                surface.count_entities_filtered {
                    area = {{p.x - 32, p.y - 32}, {p.x + 32, p.y + 32}},
                    type = e.e_type,
                    limit = 1
                } == 0
             then
                entity = surface.create_entity(e)
                if entity and entity.valid then
                    if e.direction then
                        entity.direction = e.direction
                    end
                    if e.force then
                        entity.force = e.force
                    end
                    if e.callback then
                        local c = e.callback.callback
                        if c then
                            local d = {callback_data = e.callback.data}
                            if not d then
                                callback = Token.get(c)
                                callback(entity)
                            else
                                callback = Token.get(c)
                                callback(entity, d)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function do_place_entities(data)
    local surface = data.surface
    local entity
    local callback
    for _, e in ipairs(data.entities) do
        if e.collision then
            if surface.can_place_entity(e) then
                entity = surface.create_entity(e)
                if entity then
                    if e.direction then
                        entity.direction = e.direction
                    end
                    if e.active ~= nil then
                        entity.active = e.active
                    end
                    if e.destructible ~= nil then
                        entity.destructible = e.destructible
                    end
                    if e.force then
                        entity.force = e.force
                    end
                    if e.amount then
                        entity.amount = e.amount
                    end
                    if e.callback then
                        callback = Token.get(e.callback)
                        callback({entity = entity})
                    end
                end
            end
        else
            entity = surface.create_entity(e)
            if entity then
                if e.direction then
                    entity.direction = e.direction
                end
                if e.active ~= nil then
                    entity.active = e.active
                end
                if e.destructible ~= nil then
                    entity.destructible = e.destructible
                end
                if e.force then
                    entity.force = e.force
                end
                if e.amount then
                    entity.amount = e.amount
                end
                if e.callback then
                    callback = Token.get(e.callback)
                    callback({entity = entity})
                end
            end
        end
    end
end

local function map_gen_action(data)
    local state = data.y

    if state < 32 then
        local shape = generate_map
        if shape == nil then
            return false
        end

        if not data.surface.valid then
            return
        end

        local count = tiles_per_call

        local y = state + data.top_y
        local x = data.x

        local max_x = data.top_x + 32

        data.y = y

        repeat
            count = count - 1
            get_position(data)
            do_tile(x, y, data, shape)

            x = x + 1

            if x == max_x then
                y = y + 1
                if y == data.top_y + 32 then
                    break
                end
                x = data.top_x
                data.y = y
            end

            data.x = x
        until count == 0

        data.y = y - data.top_y
        return true
    elseif state == 32 then
        do_place_tiles(data)
        data.y = 33
        return true
    elseif state == 33 then
        do_place_hidden_tiles(data)
        data.y = 34
        return true
    elseif state == 34 then
        do_place_entities(data)
        data.y = 35
        return true
    elseif state == 35 then
        do_place_decoratives(data)
        data.y = 36
        return false
    end
end

local map_gen_action_token = Token.register(map_gen_action)

--- Adds generation of a Chunk of the map to the queue
-- @param event <table> the event table from on_chunk_generated
local function schedule_chunk(event)
    local surface = event.surface
    local shape = generate_map

    if event.tick < 1 then
        return
    end

    if not surface.valid then
        return
    end

    if not shape then
        return
    end

    local area = event.area

    local data = {
        yv = -0,
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
        buildings = {},
        decoratives = {},
        markets = {},
        treasure = {}
    }

    if not data.surface or not data.surface.valid then
        return
    end

    queue_task(map_gen_action_token, data, total_calls)
end

--- Generates a Chunk of map when called
-- @param event <table> the event table from on_chunk_generated
local function do_chunk(event)
    local surface = event.surface
    local shape = generate_map

    if not surface.valid then
        return
    end

    if not shape then
        return
    end

    local area = event.area

    local data = {
        yv = -0,
        xv = 0,
        area = area,
        top_x = area.left_top.x,
        top_y = area.left_top.y,
        surface = surface,
        tiles = {},
        hidden_tiles = {},
        entities = {},
        buildings = {},
        decoratives = {},
        markets = {},
        treasure = {}
    }

    if not data.surface.valid then
        return
    end

    for row = 0, 31 do
        do_row(row, data, shape)
    end

    do_place_tiles(data)
    do_place_hidden_tiles(data)
    do_place_entities(data)
    do_place_buildings(data)
    do_place_decoratives(data)
end

local function on_chunk(event)
    local force_chunk = Public.get_stateful('force_chunk')
    local stop_chunk = Public.get_stateful('stop_chunk')
    if stop_chunk then
        return
    end

    if force_chunk then
        do_chunk(event)
    else
        schedule_chunk(event)
    end
end

Event.add(defines.events.on_chunk_generated, on_chunk)

return Public
