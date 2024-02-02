local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random

local drop_raffle = {}
for _ = 1, 32, 1 do
    table_insert(drop_raffle, 'coin')--金币
end
for _ = 1, 16, 1 do
    table_insert(drop_raffle, 'iron-ore')--铁矿
end
for _ = 1, 12, 1 do
    table_insert(drop_raffle, 'copper-ore')--铜矿
end
for _ = 1, 8, 1 do
    table_insert(drop_raffle, 'stone')--石矿
end
for _ = 1, 4, 1 do
    table_insert(drop_raffle, 'wood')--木头
end
for _ = 1, 2, 1 do
    table_insert(drop_raffle, 'coal')--煤矿
end
for _ = 1, 2, 1 do
    table_insert(drop_raffle, 'uranium-ore')--铀矿
end
local size_of_drop_raffle = #drop_raffle

local drop_vectors = {}
for x = -2, 2, 0.1 do
    for y = -2, 2, 0.1 do
        table_insert(drop_vectors, {x, y})
    end
end
local size_of_drop_vectors = #drop_vectors

local drop_values = {
    ['small-spitter'] = 1,
    ['small-biter'] = 1,
    ['medium-spitter'] = 1,
    ['medium-biter'] = 1,
    ['big-spitter'] = 2,
    ['big-biter'] = 2,
    ['behemoth-spitter'] = 3,
    ['behemoth-biter'] = 3,
    ['small-worm-turret'] = 1,
    ['medium-worm-turret'] = 2,
    ['big-worm-turret'] = 3,
    ['behemoth-worm-turret'] = 4,
    ['biter-spawner'] = 8,
    ['spitter-spawner'] = 8
}--数值越大，循环次数越多，也就越卡~

local function on_tick()
    for key, entry in pairs(global.biters_drop_ore) do
        local surface = game.surfaces[entry[3]]
        for _ = 1, 3, 1 do
            local vector = drop_vectors[math_random(1, size_of_drop_vectors)]
            surface.spill_item_stack({entry[1][1] + vector[1], entry[1][2] + vector[2]}, {name = drop_raffle[math_random(1, size_of_drop_raffle)], count = 1}, true)
            global.biters_drop_ore[key][2] = global.biters_drop_ore[key][2] - 1
            if global.biters_drop_ore[key][2] <= 0 then
                table_remove(global.biters_drop_ore, key)
                break
            end
        end
    end
end

local function on_entity_died(event)
    local entity = event.entity
    if not drop_values[entity.name] then
        return
    end
    table_insert(global.biters_drop_ore, {{entity.position.x, entity.position.y}, drop_values[entity.name], entity.surface.index})
end

local function on_init()
    global.biters_drop_ore = {}
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_tick, on_tick)
