local Functions = require 'maps.dungeons.functions'
local BiterRaffle = require 'utils.functions.biter_raffle'
local DungeonsTable = require 'maps.dungeons.table'

local table_shuffle_table = table.shuffle_table
local math_random = math.random
local math_sqrt = math.sqrt
local math_floor = math.floor

local function add_enemy_units(surface, room)
    local dungeontable = DungeonsTable.get_dungeontable()
    for _, tile in pairs(room.room_tiles) do
        if math_random(1, 2) == 1 then
            local name = BiterRaffle.roll('spitter', Functions.get_dungeon_evolution_factor(surface.index) * 1.5)
            surface.create_entity({name = name, position = tile.position, force = dungeontable.enemy_forces[surface.index]})
        end
    end
end

local function acid_zone(surface, room)
    local dungeontable = DungeonsTable.get_dungeontable()
    for _, tile in pairs(room.path_tiles) do
        surface.set_tiles({{name = 'concrete', position = tile.position}}, true)
    end

    if not room.room_border_tiles[1] then
        return
    end

    table_shuffle_table(room.room_tiles)
    for key, tile in pairs(room.room_tiles) do
        surface.set_tiles({{name = 'green-refined-concrete', position = tile.position}}, true)
        if math_random(1, 16) == 1 then
            surface.create_entity({name = 'uranium-ore', position = tile.position, amount = Functions.get_common_resource_amount(surface.index)})
        end
        if math_random(1, 96) == 1 then
            surface.create_entity({name = Functions.roll_worm_name(surface.index), position = tile.position, force = dungeontable.enemy_forces[surface.index]})
        end
        if math_random(1, 128) == 1 then
            Functions.crash_site_chest(surface, tile.position)
        end
        if key % 128 == 1 and math_random(1, 3) == 1 then
            Functions.set_spawner_tier(surface.create_entity({name = 'spitter-spawner', position = tile.position, force = dungeontable.enemy_forces[surface.index]}), surface.index)
        end
    end

    if room.center then
        if math_random(1, 4) == 1 then
            local r = math_floor(math_sqrt(#room.room_tiles) * 0.125) + 1
            for x = r * -1, r, 1 do
                for y = r * -1, r, 1 do
                    local p = {room.center.x + x, room.center.y + y}
                    surface.set_tiles({{name = 'water-green', position = p}})
                    if math_random(1, 12) == 1 then
                        surface.create_entity({name = 'fish', position = p})
                    end
                end
            end
        end
    end

    table_shuffle_table(room.room_border_tiles)
    for key, tile in pairs(room.room_border_tiles) do
        surface.set_tiles({{name = 'refined-hazard-concrete-left', position = tile.position}}, true)
    end

    for key, tile in pairs(room.room_border_tiles) do
        if key % 8 == 1 then
            Functions.place_border_rock(surface, tile.position)
        end
    end

    add_enemy_units(surface, room)
end

return acid_zone
