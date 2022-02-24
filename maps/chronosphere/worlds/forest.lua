local random = math.random
local abs = math.abs
local Functions = require 'maps.chronosphere.world_functions'
local Raffle = require 'maps.chronosphere.raffles'
local Chrono_table = require 'maps.chronosphere.table'

local function process_tile(p, seed, entities)
    local objective = Chrono_table.get_table()
    local biters = objective.world.variant.biters
    local noise1 = Functions.get_noise('forest_location', p, seed)
    local f_density = (math.min(Functions.distance(p.x, p.y) / 500, 1)) * 0.3
    local handicap = math.max(0, 160 - objective.chronojumps * 20)
    if noise1 > 0.095 + f_density then
        if noise1 > 0.6 then
            if random(1, 100) > 42 then
                entities[#entities + 1] = {name = 'tree-08-brown', position = p}
            end
        else
            if random(1, 100) > 42 then
                entities[#entities + 1] = {name = 'tree-01', position = p}
            end
        end
        return
    elseif noise1 < -(0.095 + f_density) then
        if noise1 < -0.6 then
            if random(1, 100) > 42 then
                entities[#entities + 1] = {name = 'tree-04', position = p}
            end
        else
            if random(1, 100) > 42 then
                entities[#entities + 1] = {name = 'tree-02-red', position = p}
            end
        end
        return
    else
        if random(1, 202 + handicap - biters) == 1 and Functions.distance(p.x, p.y) > 150 + handicap then
            entities[#entities + 1] = {name = Raffle.spawners[random(1, #Raffle.spawners)], position = p, spawn_decorations = true}
        end
    end
end

local function normal_chunk(surface, left_top)
    local entities = {}
    local seed = surface.map_gen_settings.seed
    for y = 0, 31, 1 do
        for x = 0, 31, 1 do
            local p = {x = left_top.x + x, y = left_top.y + y}
            process_tile(p, seed, entities)
        end
    end
    Functions.spawn_entities(surface, entities)
end

local function empty_chunk(surface, left_top)
    local entities = {}
    local seed = surface.map_gen_settings.seed

    for y = 0, 31, 1 do
        for x = 0, 31, 1 do
            local p = {x = left_top.x + x, y = left_top.y + y}
            process_tile(p, seed, entities)
        end
    end
    Functions.replace_water(surface, left_top)
end

local function forest(_, surface, left_top)
    if abs(left_top.y) <= 31 and abs(left_top.x) <= 31 then
        empty_chunk(surface, left_top)
        return
    end
    if abs(left_top.y) > 31 or abs(left_top.x) > 31 then
        normal_chunk(surface, left_top)
        return
    end
end

return forest
