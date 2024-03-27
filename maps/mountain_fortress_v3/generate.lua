local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local Task = require 'utils.task_token'
local WD = require 'modules.wave_defense.table'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'

local random = math.random
local abs = math.abs
local ceil = math.ceil
local round = math.round
local queue_task = Task.queue_task
local tiles_per_call = 12
local total_calls = ceil(1024 / tiles_per_call)
local regen_decoratives = false
local generate_map = Public.heavy_functions

local winter_mode = false
local wintery_type = {
    ['simple-entity'] = true,
    ['tree'] = true,
    ['fish'] = true,
    ['market'] = true,
    ['locomotive'] = true,
    ['cargo-wagon'] = true
}

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

    data.position = {x = (data.top_x + data.xv), y = (data.top_y + data.yv)}
end

local function do_tile_inner(tiles, tile, pos)
    if type(tile) == 'string' then
        tiles[#tiles + 1] = {name = tile, position = pos}
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

            local markets = tile.markets
            if markets then
                for _, t in ipairs(markets) do
                    if not t.position then
                        t.position = pos
                    end
                    data.markets[#data.markets + 1] = t
                end
            end

            local treasure = tile.treasure
            if treasure then
                for _, t in ipairs(treasure) do
                    if not t.position then
                        t.position = pos
                    end
                    data.treasure[#data.treasure + 1] = t
                end
            end
        else
            do_tile_inner(tiles, tile, pos)
        end
    end
end

local function do_place_treasure(data)
    local surface = data.surface
    if not surface or not surface.valid then
        return
    end
    local treasure = data.treasure

    if #treasure == 0 then
        return
    end

    for _, e in ipairs(data.treasure) do
        if random(1, 6) == 1 then
            e.chest = 'iron-chest'
        end
        if
            surface.count_entities_filtered {
                area = {{e.position.x - 2, e.position.y - 2}, {e.position.x + 2, e.position.y + 2}},
                name = 'market',
                limit = 1
            } == 0
         then
            Public.add_loot(surface, e.position, e.chest)
        else
            Public.add_loot(surface, e.position, e.chest, true)
        end
    end
end

local function do_place_markets(data)
    local markets = data.markets
    local surface = data.surface
    if not surface or not surface.valid then
        return
    end

    if #markets == 0 then
        return
    end

    local pos = markets[random(1, #markets)]
    if
        surface.count_entities_filtered {
            area = {{pos.x - 96, pos.y - 96}, {pos.x + 96, pos.y + 96}},
            name = 'market',
            limit = 1
        } == 0
     then
        local market = Public.mountain_market(surface, pos, abs(pos.y) * 0.004)
        market.destructible = false
    end
end

local function do_place_tiles(data)
    local surface = data.surface
    if not surface or not surface.valid then
        return
    end

    surface.set_tiles(data.tiles)
end

local function do_place_hidden_tiles(data)
    local surface = data.surface
    if not surface or not surface.valid then
        return
    end
    surface.set_tiles(data.hidden_tiles)
end

local function do_place_decoratives(data)
    local surface = data.surface
    if not surface or not surface.valid then
        return
    end
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
    if not surface or not surface.valid then
        return
    end
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
                e.create_build_effect_smoke = false
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
                                callback = Task.get(c)
                                callback(entity)
                            else
                                callback = Task.get(c)
                                callback(entity, d)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function wintery(ent, extra_lights)
    if not winter_mode then
        return false
    end
    local colors = {{255, 0, 0}, {0, 255, 0}, {0, 0, 255}}
    local function add_light(e)
        local color = colors[math.random(1, 3)]
        local scale = extra_lights or 1
        rendering.draw_light(
            {
                sprite = 'utility/light_small',
                orientation = 1,
                scale = scale,
                intensity = 1,
                minimum_darkness = 0,
                oriented = false,
                color = color,
                target = e,
                target_offset = {0, -0.5},
                surface = e.surface
            }
        )
    end
    if not (ent and ent.valid) then
        return
    end
    if wintery_type[ent.type] then
        if ent.type == 'simple-entity' then
            if random(1, 64) == 1 then
                return add_light(ent)
            end
        else
            if random(1, 4) == 1 then
                return add_light(ent)
            end
        end
    end
    return true
end

local function do_place_entities(data)
    local surface = data.surface
    if not surface or not surface.valid then
        return
    end
    local entity
    local callback
    for _, e in ipairs(data.entities) do
        if e.collision then
            if surface.can_place_entity(e) then
                e.create_build_effect_smoke = false
                entity = surface.create_entity(e)
                if entity then
                    if e.note then -- flamethrower-turret and artillery-turret are at default health, only gun-turret is modified
                        local modified_unit_health = WD.get('modified_unit_health')
                        local final_health = round(modified_unit_health.current_value * 0.5, 3)
                        if final_health < 1 then
                            final_health = 1
                        end
                        BiterHealthBooster.add_unit(entity, final_health)
                    end
                    wintery(entity)
                    if e.direction then
                        entity.direction = e.direction
                    end
                    if e.force then
                        entity.force = e.force
                    end
                    if e.amount then
                        entity.amount = e.amount
                    end
                    if e.callback then
                        local c = e.callback.callback
                        if not c then
                            return
                        end
                        local d = {callback_data = e.callback.data}
                        if not d then
                            callback = Task.get(c)
                            callback(entity)
                        else
                            callback = Task.get(c)
                            callback(entity, d)
                        end
                    end
                end
            end
        else
            e.create_build_effect_smoke = false
            entity = surface.create_entity(e)
            if entity then
                if e.note then -- small-worm-turret, medium-worm-turret, big-worm-turret, behemoth-worm-turret
                    local modified_unit_health = WD.get('modified_unit_health')
                    local worm_unit_settings = WD.get('worm_unit_settings')
                    local final_health = round(modified_unit_health.current_value * worm_unit_settings.scale_units_by_health[entity.name], 3)
                    if final_health < 1 then
                        final_health = 1
                    end
                    BiterHealthBooster.add_unit(entity, final_health)
                end
                wintery(entity)
                if e.direction then
                    entity.direction = e.direction
                end
                if e.force then
                    entity.force = e.force
                end
                if e.amount then
                    entity.amount = e.amount
                end
                if e.callback then
                    local c = e.callback.callback
                    if c then
                        local d = {callback_data = e.callback.data}
                        if not d then
                            callback = Task.get(c)
                            callback(entity)
                        else
                            callback = Task.get(c)
                            callback(entity, d)
                        end
                    end
                end
            end
        end
    end
end

local function run_chart_update(data)
    local x = data.top_x / 32
    local y = data.top_y / 32
    local surface = data.surface
    if not surface or not surface.valid then
        return
    end
    if game.forces.player.is_chunk_charted(surface, {x, y}) then
        -- Don't use full area, otherwise adjacent chunks get charted
        game.forces.player.chart(
            surface,
            {
                {data.top_x, data.top_y},
                {data.top_x + 1, data.top_y + 1}
            }
        )
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
            shape(data)

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
        data.y = 34
        return true
    elseif state == 34 then
        do_place_hidden_tiles(data)
        data.y = 35
        return true
    elseif state == 35 then
        do_place_entities(data)
        data.y = 36
        return true
    elseif state == 36 then
        do_place_buildings(data)
        data.y = 37
        return true
    elseif state == 37 then
        do_place_markets(data)
        data.y = 38
        return true
    elseif state == 38 then
        do_place_treasure(data)
        data.y = 39
        return true
    elseif state == 39 then
        do_place_decoratives(data)
        data.y = 40
        return true
    elseif state == 40 then
        run_chart_update(data)
        return false
    end
end

local map_gen_action_token = Task.register(map_gen_action)

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
local function force_do_chunk(event)
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
    do_place_markets(data)
    do_place_treasure(data)
end

local function on_chunk(event)
    local final_battle = Public.get('final_battle')
    if final_battle then
        return
    end

    local force_chunk = Public.get('force_chunk')
    local stop_chunk = Public.get('stop_chunk')
    if stop_chunk then
        return
    end

    if force_chunk then
        force_do_chunk(event)
    else
        schedule_chunk(event)
    end
end

Event.add(defines.events.on_chunk_generated, on_chunk)

Public.wintery = wintery

return Public
