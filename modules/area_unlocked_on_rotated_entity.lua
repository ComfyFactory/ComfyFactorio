--luacheck: ignore
--unlocks areas when the entity at the position is rotated
--define the entities by position like this:
-- storage.level_unlocks = {
--			["x:0.5 y:0.5"] = {left_top = {x = 0,y = 0}, right_bottom = {x = 50, y = 50}, tile = "dirt-4", unlocked = false},
--			["x:0.5 y:1.5"] = {left_top = {x = 0,y = 0}, right_bottom = {x = 50, y = 50}, tile = "grass-2", unlocked = false}
--		}

local event = require 'utils.event'
local math_random = math.random

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math_random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local particles = { 'coal-particle', 'copper-ore-particle', 'iron-ore-particle', 'stone-particle' }

local function create_particles(surface, position)
    local particle = particles[math_random(1, #particles)]
    local m = math_random(10, 30)
    local m2 = m * 0.005
    for i = 1, 75, 1 do
        surface.create_entity(
            {
                name = particle,
                position = position,
                frame_speed = 0.1,
                vertical_speed = 0.1,
                height = 0.1,
                movement = { m2 - (math_random(0, m) * 0.01), m2 - (math_random(0, m) * 0.01) }
            }
        )
    end
end

local function on_player_rotated_entity(event)
    if not storage.level_unlocks then
        return
    end
    local position_string = 'x:' .. tostring(event.entity.position.x)
    position_string = position_string .. ' y:'
    position_string = position_string .. tostring(event.entity.position.y)

    if not storage.level_unlocks[position_string] then
        return
    end
    if storage.level_unlocks[position_string].unlocked then
        return
    end
    storage.level_unlocks[position_string].unlocked = true

    if not storage.area_tiles_unlock_schedule then
        storage.area_tiles_unlock_schedule = {}
    end

    local level_unlocked = 0
    for _, level in pairs(storage.level_unlocks) do
        if level.unlocked == true then
            level_unlocked = level_unlocked + 1
        end
    end
    game.print(game.players[event.player_index].name .. ' unlocked the path to Chapter ' .. tostring(level_unlocked) .. '!')

    for x = storage.level_unlocks[position_string].left_top.x, storage.level_unlocks[position_string].right_bottom.x, 1 do
        for y = storage.level_unlocks[position_string].left_top.y, storage.level_unlocks[position_string].right_bottom.y, 1 do
            storage.area_tiles_unlock_schedule[#storage.area_tiles_unlock_schedule + 1] = {
                surface = event.entity.surface,
                tile = {
                    name = storage.level_unlocks[position_string].tile,
                    position = { x = event.entity.position.x + x, y = event.entity.position.y + y }
                }
            }
        end
    end
    storage.area_tiles_unlock_schedule = shuffle(storage.area_tiles_unlock_schedule)

    for _, player in pairs(game.connected_players) do
        player.play_sound { path = 'utility/new_objective', volume_modifier = 0.4 }
    end
end

local function on_tick(event)
    if not storage.area_tiles_unlock_schedule then
        return
    end

    storage.area_tiles_unlock_schedule[#storage.area_tiles_unlock_schedule].surface.set_tiles({ storage.area_tiles_unlock_schedule[#storage.area_tiles_unlock_schedule].tile }, true)
    create_particles(
        storage.area_tiles_unlock_schedule[#storage.area_tiles_unlock_schedule].surface,
        storage.area_tiles_unlock_schedule[#storage.area_tiles_unlock_schedule].tile.position
    )

    storage.area_tiles_unlock_schedule[#storage.area_tiles_unlock_schedule] = nil
    if #storage.area_tiles_unlock_schedule == 0 then
        storage.area_tiles_unlock_schedule = nil
    end
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_player_rotated_entity, on_player_rotated_entity)

--storage.area_tiles_unlock_schedule[#storage.area_tiles_unlock_schedule].surface.create_entity({name = "blood-explosion-huge", position = storage.area_tiles_unlock_schedule[#storage.area_tiles_unlock_schedule].tile.position})
