local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Enemy = require 'maps.scrap_towny_ffa.enemy'
local Building = require 'maps.scrap_towny_ffa.building'

local Public = {}

local table_size = table.size
local table_insert = table.insert
local math_random = math.random
local math_rad = math.rad
local math_sin = math.sin
local math_cos = math.cos
local math_floor = math.floor

local spawn_point_town_buffer = 256

local spawn_point_safety = 16

local spawn_point_incremental_distance = 16

local function force_load(position, surface, radius)
    surface.request_to_generate_chunks(position, radius)

    surface.force_generate_chunk_requests()
end

local function get_area(position, w, h)
    local x1 = math_floor(w / 2)
    local x2 = w - x1
    local y1 = math_floor(h / 2)
    local y2 = h - y1
    return { { position.x - x1, position.y - y1 }, { position.x + x2, position.y + y2 } }
end

local function clear_spawn(position, surface, w, h)
    local area = get_area(position, w, h)
    for _, e in pairs(surface.find_entities_filtered({ area = area })) do
        if e.type ~= 'character' then
            e.destroy()
        end
    end
end

local function has_pollution(position, surface)
    local result = surface.get_pollution(position) > 0.0

    return result
end

local function in_use(position)
    local this = ScenarioTable.get_table()
    local result = false
    if position.x == 0 and position.y == 0 then
        return true
    end

    for _, v in pairs(this.spawn_point) do
        if v == position then
            result = true
        end
    end

    return result
end

local function is_position_near(area)
    local status = false
    local function inside(pos)
        local lt = area.left_top
        local rb = area.right_bottom

        return pos.x >= lt.x and pos.y >= lt.y and pos.x <= rb.x and pos.y <= rb.y
    end

    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        if inside(player.physical_position) then
            status = true
        end
    end

    return status
end

local function is_empty(position, surface)
    local chunk_position = {}
    chunk_position.x = math_floor(position.x / 32)
    chunk_position.y = math_floor(position.y / 32)
    if not surface.is_chunk_generated(chunk_position) then
        surface.request_to_generate_chunks(position, 0)
        surface.force_generate_chunk_requests()
    end
    local entity_radius = 3
    local tile_radius = 2
    local entities = surface.find_entities_filtered({ position = position, radius = entity_radius })

    if #entities > 0 then
        return false
    end
    local tiles = surface.count_tiles_filtered({ position = position, radius = tile_radius, collision_mask = 'water_tile' })

    if tiles > 0 then
        return false
    end
    local result = surface.can_place_entity({ name = 'character', position = position })

    return result
end

local function find_valid_spawn_point(player, force_name, surface)
    local this = ScenarioTable.get_table()

    local position = { x = 0, y = 0 }

    force_load(position, surface, 1)

    if not in_use(position) then
        if Building.near_another_town(force_name, position, surface, spawn_point_town_buffer) == false then
            if is_empty(position, surface) == true then
                return position
            end
        end
    end

    local r = 55
    local area =
    {
        left_top = { x = player.physical_position.x - r, y = player.physical_position.y - r },
        right_bottom = { x = player.physical_position.x + r, y = player.physical_position.y + r }
    }

    if not is_position_near(area) then
        if is_empty(position, surface) == true then
            return position
        end
    end

    local keyset = {}
    for town_name, _ in pairs(this.town_centers) do
        table_insert(keyset, town_name)
    end
    local count = table_size(keyset)
    if count > 0 then
        local town_name = keyset[math_random(1, count)]
        local town_center = this.town_centers[town_name]
        if town_center ~= nil then
            position = town_center.market.position
        end
    end

    local tries = 0
    local radius = spawn_point_town_buffer
    local angle
    while (tries < 100) do
        for _ = 1, 8 do
            angle = math_random(0, 360)
            local t = math_rad(angle)
            local x = math_floor(position.x + math_cos(t) * radius)
            local y = math_floor(position.y + math_sin(t) * radius)
            local target = { x = x, y = y }

            force_load(position, surface, 1)
            if in_use(target) == false then
                if has_pollution(target, surface) == false then
                    if Building.near_another_town(force_name, target, surface, spawn_point_town_buffer) == false then
                        if is_empty(target, surface) == true then
                            position = target
                            return position
                        end
                    end
                end
            end
        end

        radius = radius + math_random(1, spawn_point_incremental_distance)
        tries = tries + 1
    end
    return { x = 0, y = 0 }
end

function Public.get_new_spawn_point(player, surface)
    local this = ScenarioTable.get_table()

    local position = { 0, 0 }
    if player ~= nil then
        local force = player.force
        if force ~= nil then
            local force_name = force.name
            position = find_valid_spawn_point(player, force_name, surface)
        end
    end

    this.spawn_point[player.index] = position

    return position
end

function Public.get_spawn_point(player, surface)
    local this = ScenarioTable.get_table()
    local position = this.spawn_point[player.index]

    if position ~= nil and this.strikes[player.name] < 3 then
        if surface.can_place_entity({ name = 'character', position = position }) then
            return position
        else
            position = surface.find_non_colliding_position('character', position, 0, 0.25)
            return position
        end
    end

    return Public.get_new_spawn_point(player, surface)
end

function Public.clear_spawn_point(position, surface)
    Enemy.clear_worms(position, surface, spawn_point_safety)
    Enemy.clear_enemies(position, surface, spawn_point_safety)
    clear_spawn(position, surface, 7, 9)
end

if ScenarioTable.enabled('new_spawn_command') then
    commands.add_command(
        'new-spawn',
        'Set up a new spawn point for the next spawn',
        function (cmd)
            local player = game.players[cmd.player_index]
            if not player or not player.valid then
                return
            end
            Public.get_new_spawn_point(player, player.surface)
            player.print('New spawn is set up and will be used when you die', { 255, 255, 0 })
        end
    )
end

return Public
